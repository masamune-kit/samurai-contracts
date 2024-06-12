// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SamuraiMultiChainSender is Ownable, ReentrancyGuard {
  IERC20 public xHnr;

  mapping(address => uint256) public swaps;
  event SwapSend(
    address destination,
    uint256 amount,
    uint256 timestamp,
    uint256 blocknum,
    string origin
  );

  constructor(address _xHnr) {
    xHnr = IERC20(_xHnr);
  }

  function sendMultiChain(
    address destination,
    uint256 amount,
    uint256 originTimestamp,
    uint256 originBlock,
    string calldata origin
  ) external onlyOwner nonReentrant {
    swaps[destination] += amount;
    xHnr.transfer(destination, amount);

    emit SwapSend(destination, amount, originTimestamp, originBlock, origin);
  }

  function getSwapByAddress(address swapper) external view returns (uint256) {
    return swaps[swapper];
  }
}
