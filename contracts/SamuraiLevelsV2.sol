// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IUniswapV2Router02.sol";

contract SamuraiLevelsV2 is Ownable, Pausable, ReentrancyGuard {
  struct UserInfo {
    uint256 experience;
    uint256 lastClaimed;
    uint256 streak;
  }
  mapping(address => UserInfo) public users;
  uint256 public rewardRate;
  uint256 public streakCap;
  uint256 public feeRate;
  uint256 public threshold;

  IERC20 public xhnr;
  IERC721 public hnrNodes;
  IUniswapV2Router02 public uniswapV2Router;

  using SafeMath for uint256;

  constructor(
    address _xhnr,
    address _hnrNodes,
    address _uniswapV2Router,
    uint256 _rewardRate,
    uint256 _streakCap,
    uint256 _feeRate,
    uint256 _threshold
  ) {
    xhnr = IERC20(_xhnr);
    hnrNodes = IERC721(_hnrNodes);
    uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    rewardRate = _rewardRate;
    streakCap = _streakCap;
    feeRate = _feeRate;
    threshold = _threshold;
  }

  receive() external payable virtual {
    //
  }

  function levelUp(uint256 _data, address _player)
    external
    whenNotPaused
    nonReentrant
    onlyOwner
  {
    require(_data <= 20, "Contract: too many questions!");
    require(
      hnrNodes.balanceOf(_player) >= threshold,
      "Contract: not a holder!"
    );

    UserInfo storage user = users[_player];

    uint256 blockTimeNow = block.timestamp;
    uint256 oneDay = 24 * 60 * 60;
    uint256 twoDays = oneDay * 2;
    uint256 timeDiff = blockTimeNow - user.lastClaimed;

    require(timeDiff >= oneDay, "Contract: not refreshed yet!");

    if (user.streak == 0) {
      user.streak = 1;
    } else {
      if (timeDiff <= twoDays && (user.streak + 1 <= streakCap)) {
        user.streak += 1;
      } else if (timeDiff > twoDays && user.streak > 1) {
        user.streak = 1;
      }
    }

    // 50 is the xp gain rate
    uint256 newXp = _data * 50 * user.streak;
    // multiply before divide
    uint256 reward = rewardRate.mul(_data).mul(user.streak).div(2);
    uint256 fee = reward.mul(feeRate).div(100);
    uint256 finalReward = reward.sub(fee);

    user.experience += newXp;
    user.lastClaimed = blockTimeNow;

    swapTokensForEth(fee);
    xhnr.transfer(_player, finalReward);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(xhnr);
    path[1] = uniswapV2Router.WETH();

    xhnr.approve(address(uniswapV2Router), tokenAmount);

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function getUserInfo()
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    UserInfo memory user = users[msg.sender];
    return (user.experience, user.lastClaimed, user.streak);
  }

  function checkEligible(uint256 _data, address _player)
    external
    view
    returns (bool)
  {
    UserInfo storage user = users[_player];

    uint256 blockTimeNow = block.timestamp;
    uint256 oneDay = 24 * 60 * 60;
    uint256 timeDiff = blockTimeNow - user.lastClaimed;

    if (
      _data > 20 || hnrNodes.balanceOf(_player) < threshold || timeDiff < oneDay
    ) {
      return false;
    }

    return true;
  }

  function setRewardRate(uint256 _rewardRate) external onlyOwner {
    rewardRate = _rewardRate;
  }

  function setStreakCap(uint256 _streakCap) external onlyOwner {
    streakCap = _streakCap;
  }

  function setFeeRate(uint256 _feeRate) external onlyOwner {
    feeRate = _feeRate;
  }

  function setThreshold(uint256 _threshold) external onlyOwner {
    threshold = _threshold;
  }

  function release() external onlyOwner {
    xhnr.transfer(owner(), xhnr.balanceOf(address(this)));
  }

  function releaseNative() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function pause(bool en) external onlyOwner {
    en ? _pause() : _unpause();
  }
}
