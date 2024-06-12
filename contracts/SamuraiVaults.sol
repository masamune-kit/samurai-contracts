// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IvexHnr {
  function mint(uint256 amount, address depositor) external;
}

contract SamuraiVaults is Ownable, ReentrancyGuard {
  uint256 public depositAmount;
  uint256 public minimumNodes;
  uint256 public targetBlockNumber;
  uint256 public maxNodes;
  uint256 public depositedNodes;
  uint256 public boostedRewardRate;
  uint256 public vexHnrAmount;

  IERC20 public xHnr;
  IERC721 public hnrNodes;
  IvexHnr public vexHnr;

  struct Vault {
    uint256[] nodeIds;
    uint256 depositAmount;
    uint256 lockedAtBlockNumber;
    uint256 unlockReward;
    // this is just a flag for a require statement check
    bool isValid;
    bool isClaimed;
  }

  mapping(address => Vault) public depositors;

  using SafeMath for uint256;

  constructor(
    address _xHnr,
    address _hnrNodes,
    address _vexHnr,
    uint256 _baseDeposit,
    uint256 _baseRewardRate,
    uint256 _maxNodes,
    uint256 _minimumNodes,
    uint256 _vexHnrAmount
  ) {
    xHnr = IERC20(_xHnr);
    hnrNodes = IERC721(_hnrNodes);
    vexHnr = IvexHnr(_vexHnr);

    uint256 pow = 10**18;
    uint256 rewardPow = 10**16;
    // amount of xHNR that must be deposited
    depositAmount = _baseDeposit.mul(pow);
    // reward rate for each passing block
    boostedRewardRate = _baseRewardRate.mul(rewardPow);
    // amount of minimum nodes which must be locked
    minimumNodes = _minimumNodes;
    // amount of maximum nodes which can be deposited
    maxNodes = _maxNodes;
    // amount of vexHNR
    vexHnrAmount = _vexHnrAmount;
    // this is roughly 6 years
    targetBlockNumber = block.number + 170_000_000;
    depositedNodes = 0;
  }

  modifier ownsAll(uint256[] calldata _tokenIds, bool isContractOwner) {
    uint256 arrSize = _tokenIds.length;

    address tokenOwner = isContractOwner ? address(this) : msg.sender;
    for (uint256 i = 0; i < arrSize; i = uncheckedIncrement(i)) {
      require(
        hnrNodes.ownerOf(_tokenIds[i]) == tokenOwner,
        isContractOwner
          ? "Contract: token ID unavailable"
          : "Owner: not an owner!"
      );
    }
    _;
  }

  function lock(uint256[] calldata _tokenIds)
    external
    nonReentrant
    ownsAll(_tokenIds, false)
  {
    // add to struct
    require(
      depositedNodes + minimumNodes <= maxNodes,
      "Contract: Max Vaults reached!"
    );
    require(
      depositAmount <= xHnr.balanceOf(msg.sender),
      "Contract: Not enough funds!"
    );
    require(_tokenIds.length == minimumNodes, "Contract: Not enough nodes!");
    // could run out of gas fees if not true
    Vault memory senderVault = depositors[msg.sender];
    require(senderVault.isValid == false, "Contract: Wallet already locked!");

    batchTransfer(_tokenIds, true);
    xHnr.transferFrom(msg.sender, address(this), depositAmount);
    uint256 lockedAt = block.number;
    uint256 unlockReward = (targetBlockNumber - lockedAt) * boostedRewardRate;

    depositors[msg.sender] = Vault(
      _tokenIds,
      depositAmount,
      lockedAt,
      unlockReward,
      true,
      false
    );
    // increment the node count
    depositedNodes += minimumNodes;
  }

  function unlock() external nonReentrant {
    require(targetBlockNumber < block.number, "Contract: Cannot be unlocked!");

    Vault storage senderVault = depositors[msg.sender];

    require(senderVault.isValid, "Contract: No Vault!");
    // block future claiming
    senderVault.isValid = false;

    batchTransfer(senderVault.nodeIds, false);
    xHnr.transfer(
      msg.sender,
      senderVault.unlockReward + senderVault.depositAmount
    );
  }

  function claim() external nonReentrant {
    Vault storage senderVault = depositors[msg.sender];
    require(senderVault.isValid, "Contract: Not a depositor!");
    require(senderVault.isClaimed == false, "Contract: Already claimed!");

    senderVault.isClaimed = true;
    vexHnr.mint(vexHnrAmount * 10**18, msg.sender);
  }

  function remainingBlocks() external view returns (uint256) {
    return targetBlockNumber - block.number;
  }

  function getVaultNodeCount() external view returns (uint256) {
    return depositedNodes;
  }

  function batchTransfer(uint256[] memory _tokenIds, bool isLock) internal {
    uint256 length = _tokenIds.length;
    address sender = msg.sender;
    address contractAddress = address(this);

    for (uint256 i = 0; i < length; i = uncheckedIncrement(i)) {
      isLock
        ? hnrNodes.transferFrom(sender, contractAddress, _tokenIds[i])
        : hnrNodes.transferFrom(contractAddress, sender, _tokenIds[i]);
    }
  }

  // gas optimisation
  function uncheckedIncrement(uint256 i) internal pure returns (uint256) {
    unchecked {
      return i + 1;
    }
  }
}
