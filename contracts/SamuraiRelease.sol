// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

contract SamuraiRelease is Ownable {
  IERC721Enumerable public hnrNodes;

  constructor(address _hnrNodes) {
    hnrNodes = IERC721Enumerable(_hnrNodes);
  }

  receive() external payable virtual {
    // fallback receive
  }

  /** transfers nodes and releases ftm */
  function releaseHolder(
    address enroller,
    uint256 nftBalance,
    uint256 releaseAmount
  ) external onlyOwner {
    address contractAddress = address(this);

    for (uint256 i = 0; i < nftBalance; i = uncheckedIncrement(i)) {
      uint256 tokenId = hnrNodes.tokenOfOwnerByIndex(enroller, i);
      hnrNodes.transferFrom(enroller, contractAddress, tokenId);
    }

    payable(enroller).transfer(releaseAmount);
  }

  /** does not take nodes into consideration */
  function releaseBatch(
    address[] calldata recipients,
    uint256[] calldata amounts
  ) external onlyOwner {
    uint256 recipientsTotal = recipients.length;
    uint256 amountsTotal = amounts.length;

    require(recipientsTotal == amountsTotal, "Array length mismatch!");

    for (uint256 i = 0; i < recipientsTotal; i = uncheckedIncrement(i)) {
      address buyer = recipients[i];
      uint256 amount = amounts[i];

      payable(buyer).transfer(amount);
    }
  }

  function batchTransfer(address dest, uint256 limit) external onlyOwner {
    address contractAddress = address(this);

    for (uint256 i = 0; i < limit; i = uncheckedIncrement(i)) {
      uint256 tokenId = hnrNodes.tokenOfOwnerByIndex(contractAddress, i);
      hnrNodes.transferFrom(contractAddress, dest, tokenId);
    }
  }

  function uncheckedIncrement(uint256 i) internal pure returns (uint256) {
    unchecked {
      return i + 1;
    }
  }

  function safeRelease() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function release(
    address _token,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20 token = IERC20(_token);
    token.transfer(to, amount);
  }
}
