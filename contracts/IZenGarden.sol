pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IZenGarden {
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  struct PoolInfo {
    IERC20 erc20Token;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accumulatedHNRPerShare;
    uint256 maxStakingAmountPerUser;
  }

  event PaymentReceived(address from, uint256 amount);

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

  event EmergencyWithdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );
}
