// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract xHNR is Initializable, ERC20Upgradeable, OwnableUpgradeable {
  function initialize() external initializer {
    __ERC20_init("xHonour", "xHNR");
    OwnableUpgradeable.__Ownable_init();
  }

  function mint(uint256 amount) external onlyOwner {
    _mint(owner(), amount);
  }
}
