// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IZenGarden.sol";

contract ZenGarden is Ownable, ReentrancyGuard, IZenGarden {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public HNR;
  PoolInfo[] public poolInfo;

  uint256 public HNRPerBlock;
  uint256 public maxHNRAvailableForFarming;
  uint256 public totalAllocation;
  uint256 public startBlock;
  uint256 public endBlock;

  mapping(address => bool) isErc20TokenWhitelisted;
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  constructor(
    IERC20 _HNR,
    uint256 _maxHNRAvailableForFarming,
    uint256 blocksPerDay,
    uint256 numberOfDays
  ) {
    require(
      address(_HNR) != address(0),
      "constructor: _HNR must not be zero address"
    );
    require(
      _maxHNRAvailableForFarming > 0,
      "constructor: _maxHNRAvailableForFarming must be greater than zero"
    );

    HNR = _HNR;
    maxHNRAvailableForFarming = _maxHNRAvailableForFarming;
    // start at the moment of the deploy + slight delay to ensure fairness
    startBlock = block.number + uint256(5000);
    endBlock = startBlock.add(blocksPerDay.mul(numberOfDays));

    uint256 numberOfBlocksForFarming = endBlock.sub(startBlock);
    HNRPerBlock = maxHNRAvailableForFarming.div(numberOfBlocksForFarming);
  }

  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  fallback() external payable {
    payable(owner()).transfer(msg.value);
  }

  function blockNumber() external view returns (uint256) {
    return block.number;
  }

  function numberOfPools() external view returns (uint256) {
    return poolInfo.length;
  }

  function add(
    uint256 _allocPoint,
    IERC20 _erc20Token,
    uint256 _maxStakingAmountPerUser,
    bool _withUpdate
  ) public onlyOwner {
    require(block.number < endBlock, "add: must be before end");
    address erc20TokenAddress = address(_erc20Token);
    require(
      erc20TokenAddress != address(0),
      "add: _erc20Token must not be zero address"
    );
    require(
      isErc20TokenWhitelisted[erc20TokenAddress] == false,
      "add: already whitelisted"
    );
    require(
      _maxStakingAmountPerUser > 0,
      "add: _maxStakingAmountPerUser must be greater than zero"
    );

    if (_withUpdate) {
      massUpdatePools();
    }

    uint256 lastRewardBlock = block.number > startBlock
      ? block.number
      : startBlock;
    totalAllocation = totalAllocation.add(_allocPoint);
    poolInfo.push(
      PoolInfo({
        erc20Token: _erc20Token,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accumulatedHNRPerShare: 0,
        maxStakingAmountPerUser: _maxStakingAmountPerUser
      })
    );

    isErc20TokenWhitelisted[erc20TokenAddress] = true;
  }

  function set(
    uint256 _pid,
    uint256 _allocPoint,
    uint256 _maxStakingAmountPerUser,
    bool _withUpdate
  ) public onlyOwner {
    require(block.number < endBlock, "set: must be before end");
    require(_pid < poolInfo.length, "set: invalid _pid");
    require(
      _maxStakingAmountPerUser > 0,
      "set: _maxStakingAmountPerUser must be greater than zero"
    );

    if (_withUpdate) {
      massUpdatePools();
    }

    totalAllocation = totalAllocation.sub(poolInfo[_pid].allocPoint).add(
      _allocPoint
    );

    poolInfo[_pid].allocPoint = _allocPoint;
    poolInfo[_pid].maxStakingAmountPerUser = _maxStakingAmountPerUser;
  }

  function pendingHNR(uint256 _pid, address _user)
    external
    view
    returns (uint256)
  {
    require(_pid < poolInfo.length, "pendingHNR: invalid _pid");

    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];

    uint256 accHNRPerShare = pool.accumulatedHNRPerShare;
    uint256 lpSupply = pool.erc20Token.balanceOf(address(this));

    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 maxEndBlock = block.number <= endBlock ? block.number : endBlock;
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, maxEndBlock);
      uint256 hnrReward = multiplier.mul(HNRPerBlock).mul(pool.allocPoint).div(
        totalAllocation
      );
      accHNRPerShare = accHNRPerShare.add(hnrReward.mul(1e18).div(lpSupply));
    }

    return user.amount.mul(accHNRPerShare).div(1e18).sub(user.rewardDebt);
  }

  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; pid = uncheckedIncrement(pid)) {
      updatePool(pid);
    }
  }

  function uncheckedIncrement(uint256 index) internal pure returns (uint256) {
    unchecked {
      return index + 1;
    }
  }

  function updatePool(uint256 _pid) public {
    require(_pid < poolInfo.length, "updatePool: invalid _pid");

    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }

    uint256 erc20Supply = pool.erc20Token.balanceOf(address(this));
    if (erc20Supply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }

    uint256 maxEndBlock = block.number <= endBlock ? block.number : endBlock;
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, maxEndBlock);

    if (multiplier == 0) {
      return;
    }

    uint256 hnrReward = multiplier.mul(HNRPerBlock).mul(pool.allocPoint).div(
      totalAllocation
    );

    pool.accumulatedHNRPerShare = pool.accumulatedHNRPerShare.add(
      hnrReward.mul(1e18).div(erc20Supply)
    );
    pool.lastRewardBlock = maxEndBlock;
  }

  function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    require(
      user.amount.add(_amount) <= pool.maxStakingAmountPerUser,
      "deposit: can not exceed max staking amount per user"
    );

    updatePool(_pid);

    if (user.amount > 0) {
      uint256 pending = user
        .amount
        .mul(pool.accumulatedHNRPerShare)
        .div(1e18)
        .sub(user.rewardDebt);
      if (pending > 0) {
        safeHNRTransfer(msg.sender, pending);
      }
    }

    if (_amount > 0) {
      pool.erc20Token.safeTransferFrom(
        address(msg.sender),
        address(this),
        _amount
      );
      user.amount = user.amount.add(_amount);
    }

    user.rewardDebt = user.amount.mul(pool.accumulatedHNRPerShare).div(1e18);
    emit Deposit(msg.sender, _pid, _amount);
  }

  function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    require(user.amount >= _amount, "withdraw: _amount not good");

    updatePool(_pid);

    uint256 pending = user
      .amount
      .mul(pool.accumulatedHNRPerShare)
      .div(1e18)
      .sub(user.rewardDebt);
    if (pending > 0) {
      safeHNRTransfer(msg.sender, pending);
    }

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      pool.erc20Token.safeTransfer(address(msg.sender), _amount);
    }

    user.rewardDebt = user.amount.mul(pool.accumulatedHNRPerShare).div(1e18);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  function emergencyWithdraw(uint256 _pid) external nonReentrant {
    require(_pid < poolInfo.length, "updatePool: invalid _pid");

    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;

    pool.erc20Token.safeTransfer(address(msg.sender), amount);
    emit EmergencyWithdraw(msg.sender, _pid, amount);
  }

  function safeHNRTransfer(address _to, uint256 _amount) private {
    uint256 hnrBalance = HNR.balanceOf(address(this));
    HNR.transfer(_to, _amount > hnrBalance ? hnrBalance : _amount);
  }

  function getMultiplier(uint256 _from, uint256 _to)
    private
    pure
    returns (uint256)
  {
    return _to.sub(_from);
  }

  function updateRewardPerBlockAndEndBlock(
    uint256 newRewardPerBlock,
    uint256 newEndBlock
  ) external onlyOwner {
    if (block.number >= startBlock) {
      massUpdatePools();
    }
    require(
      newEndBlock > block.number,
      "Owner: New endBlock must be after current block"
    );
    require(
      newEndBlock > startBlock,
      "Owner: New endBlock must be after start block"
    );

    endBlock = newEndBlock;
    HNRPerBlock = newRewardPerBlock;
  }

  function adminRewardWithdraw(uint256 amount) external onlyOwner {
    HNR.safeTransfer(msg.sender, amount);
  }
}
