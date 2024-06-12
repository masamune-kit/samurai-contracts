// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SamuraiSwap is
  Initializable,
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  IERC20 public HNR;
  IERC20 public xHNR;

  function initialize(address _hnr, address _xhnr) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    PausableUpgradeable.__Pausable_init();

    HNR = IERC20(_hnr);
    xHNR = IERC20(_xhnr);
  }

  function swap(uint256 amount) external nonReentrant whenNotPaused {
    require(amount > 0, "Can't transfer zero amounts");
    HNR.transferFrom(msg.sender, address(this), amount);
    xHNR.transfer(msg.sender, amount);
  }

  function releaseToken(bool isHNR) external onlyOwner {
    IERC20 token = isHNR ? HNR : xHNR;
    token.transfer(owner(), token.balanceOf(address(this)));
  }

  function setPause(bool isPaused) external onlyOwner {
    isPaused ? _pause() : _unpause();
  }
}
