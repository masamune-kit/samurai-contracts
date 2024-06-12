// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract vexHNR is ERC20, Ownable {
  address public vault;

  constructor() ERC20("vexHonour", "vexHNR") {
    // do nothing
  }

  modifier onlyVault() {
    require(msg.sender == vault, "Contract: Not Vault");
    _;
  }

  function mint(uint256 amount, address depositor) external onlyVault {
    _mint(depositor, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);
    // only allow the vault to transfer
    if (from != address(0)) {
      require(from == vault, "Contract: Not Vault");
    }
  }

  function setVault(address _vault) external onlyOwner {
    vault = _vault;
  }
}
