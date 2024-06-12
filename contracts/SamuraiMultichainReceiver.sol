// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SamuraiMultichainReceiver is ReentrancyGuard {
  IERC20 public wxHnr;

  struct Transaction {
    address sender;
    uint256 timestamp;
  }

  Transaction[] public transactions;

  mapping(address => uint256) public swaps;
  event SwapReceive(
    address from,
    uint256 amount,
    uint256 timestamp,
    uint256 blocknum
  );

  constructor(address _wxHnr) {
    wxHnr = IERC20(_wxHnr);
  }

  function swap(uint256 amount) external nonReentrant {
    address sender = msg.sender;
    uint256 blocktime = block.timestamp;

    swaps[sender] += amount;
    Transaction memory newTx = Transaction({
      sender: sender,
      timestamp: blocktime
    });
    transactions.push(newTx);
    wxHnr.transferFrom(sender, address(this), amount);

    emit SwapReceive(sender, amount, blocktime, block.number);
  }

  function getSwapByAddress(address swapper) external view returns (uint256) {
    return swaps[swapper];
  }
}
