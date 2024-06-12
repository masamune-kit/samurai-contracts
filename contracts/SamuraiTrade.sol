// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SamuraiTrade is Ownable, ReentrancyGuard, Pausable {
  using SafeMath for uint256;

  uint256 public buyPrice;
  uint256 public sellPrice;
  bool public isBuyEnabled;

  IERC721 public hnrNodes;
  IERC20 public xHnr;

  event BuyNode(address nodeBuyer, uint256[] tokenIds, uint256 amount);
  event SellNode(address nodeSeller, uint256[] tokenIds, uint256 amount);

  constructor(
    uint256 _buyPrice,
    uint256 _sellPrice,
    address _hnrNodes,
    address _xHnr
  ) {
    buyPrice = _buyPrice;
    sellPrice = _sellPrice;
    hnrNodes = IERC721(_hnrNodes);
    xHnr = IERC20(_xHnr);
    isBuyEnabled = false;
  }

  // we need to check if the seller actually owns all the tokens and if the contract has them to sell
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

  function sell(uint256[] calldata _tokenIds)
    external
    whenNotPaused
    ownsAll(_tokenIds, false)
    nonReentrant
  {
    address nodeSeller = msg.sender;
    uint256 amount = uint256(_tokenIds.length).mul(sellPrice);
    // transfer token ids to contract
    batchTransfer(_tokenIds, true);
    xHnr.transfer(nodeSeller, amount);

    emit SellNode(nodeSeller, _tokenIds, amount);
  }

  function buy(uint256[] calldata _tokenIds)
    external
    ownsAll(_tokenIds, true)
    nonReentrant
  {
    require(isBuyEnabled, "Contract: Buy Not Enabled!");

    address nodeBuyer = msg.sender;
    uint256 quantity = _tokenIds.length;
    uint256 amount = quantity.mul(buyPrice);
    xHnr.transferFrom(nodeBuyer, address(this), amount);
    // transfer out tokenIds to the buyer
    batchTransfer(_tokenIds, false);

    emit BuyNode(nodeBuyer, _tokenIds, amount);
  }

  function setPause(bool _isPaused) external onlyOwner {
    _isPaused ? _pause() : _unpause();
  }

  function setBuyEnabled(bool _isEnabled) external onlyOwner {
    isBuyEnabled = _isEnabled;
  }

  function setBuyPrice(uint256 _buyPrice) external onlyOwner {
    buyPrice = _buyPrice;
  }

  function setSellPrice(uint256 _sellPrice) external onlyOwner {
    sellPrice = _sellPrice;
  }

  function release() external onlyOwner {
    uint256 totalBalance = xHnr.balanceOf(address(this));
    xHnr.transfer(owner(), totalBalance);
  }

  function batchTransfer(uint256[] calldata _tokenIds, bool isSell) internal {
    uint256 length = _tokenIds.length;
    address sender = msg.sender;
    address contractAddress = address(this);

    for (uint256 i = 0; i < length; i = uncheckedIncrement(i)) {
      isSell
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
