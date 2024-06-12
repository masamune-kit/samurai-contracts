// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IUniswapV2Router02.sol";

contract SamuraiSubscription is Ownable, Pausable {
  IERC20 public xhnr;
  IERC721Enumerable public hnrNodes;
  IUniswapV2Router02 public uniswapV2Router;

  uint256 public threshold;
  uint256 public feeRate;
  uint256 public subscriptionCost;

  mapping(address => uint256) public subscriptions;

  using SafeMath for uint256;

  constructor(
    address _xhnr,
    address _hnrNodes,
    address _uniswapV2Router,
    uint256 _threshold,
    uint256 _feeRate,
    uint256 _subscriptionCost
  ) {
    xhnr = IERC20(_xhnr);
    hnrNodes = IERC721Enumerable(_hnrNodes);
    uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    threshold = _threshold;
    feeRate = _feeRate;
    subscriptionCost = _subscriptionCost;
  }

  receive() external payable virtual {
    //
  }

  function subscribe() external whenNotPaused {
    address sender = msg.sender;
    require(hnrNodes.balanceOf(sender) >= threshold, "Contract: not a holder!");
    uint256 timeNow = block.timestamp;
    uint256 existingSubscription = subscriptions[sender];
    require(
      timeNow > existingSubscription,
      "Contract: subscription already active!"
    );
    // charge the subscription
    xhnr.transferFrom(sender, address(this), subscriptionCost);
    uint256 fee = subscriptionCost.mul(feeRate).div(100);
    // take the fee
    swapTokensForEth(fee);
    // 28 days in seconds
    uint256 oneMonth = 28 * 24 * 60 * 60;
    uint256 subscriptionEnd = timeNow + oneMonth;

    subscriptions[sender] = subscriptionEnd;
  }

  function isSubscribed() external view returns (bool) {
    address sender = msg.sender;
    uint256 timeNow = block.timestamp;
    uint256 subscriptionEnd = subscriptions[sender];

    return timeNow <= subscriptionEnd;
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

  // owner related
  function setSubscriptionCost(uint256 _subscriptionCost) external onlyOwner {
    subscriptionCost = _subscriptionCost;
  }

  function setThreshold(uint256 _threshold) external onlyOwner {
    threshold = _threshold;
  }

  function setFeeRate(uint256 _feeRate) external onlyOwner {
    feeRate = _feeRate;
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
