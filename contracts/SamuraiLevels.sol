// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SamuraiLevels is Ownable, Pausable, ReentrancyGuard {
  struct UserInfo {
    uint256 experience;
    uint256 lastClaimed;
    uint256 streak;
  }
  mapping(address => UserInfo) public users;
  uint256 public rewardRate;
  uint256 public streakCap;

  IERC20 public xhnr;
  IERC721 public hnrNodes;

  using SafeMath for uint256;

  constructor(
    address _xhnr,
    address _hnrNodes,
    uint256 _rewardRate,
    uint256 _streakCap
  ) {
    xhnr = IERC20(_xhnr);
    hnrNodes = IERC721(_hnrNodes);
    rewardRate = _rewardRate;
    streakCap = _streakCap;
  }

  function levelUp(uint256 _data) external whenNotPaused nonReentrant {
    require(_data <= 20, "Contract: too many questions!");

    address sender = msg.sender;
    require(hnrNodes.balanceOf(sender) >= 1, "Contract: not a holder!");

    UserInfo storage user = users[sender];

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
    uint256 reward = (rewardRate * _data * user.streak) / 2;

    user.experience += newXp;
    user.lastClaimed = blockTimeNow;

    xhnr.transfer(sender, reward);
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

  function setRewardRate(uint256 _rewardRate) external onlyOwner {
    rewardRate = _rewardRate;
  }

  function setStreakCap(uint256 _streakCap) external onlyOwner {
    streakCap = _streakCap;
  }

  function pause(bool en) external onlyOwner {
    en ? _pause() : _unpause();
  }
}
