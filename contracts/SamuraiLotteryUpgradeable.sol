// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./IHonour.sol";

contract SamuraiLottery is
  Initializable,
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeMathUpgradeable for uint256;

  IHonour public HNR;
  IERC721EnumerableUpgradeable public HNR_NODES;

  address public distributionPool;
  address public honourNodes;

  uint256 public winningReward;
  uint256 public entryAmount;

  uint256 private gamesPlayed;
  uint256 private wins;
  uint256 private losses;
  uint256 private odds;

  event LotteryGamePlayed(address player, bool result);

  function initialize(
    address _distributionPool,
    address _honourNodes,
    address _hnr
  ) public initializer {
    OwnableUpgradeable.__Ownable_init();
    PausableUpgradeable.__Pausable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    distributionPool = _distributionPool;
    honourNodes = _honourNodes;
    HNR = IHonour(_hnr);
    HNR_NODES = IERC721EnumerableUpgradeable(_honourNodes);

    // amount of winnable HNR
    winningReward = 1000 * 10**18;
    entryAmount = 500 * 10**18;

    gamesPlayed = 0;
    wins = 0;
    losses = 0;
  }

  function play(uint256 seed, address player)
    external
    whenNotPaused
    nonReentrant
    returns (bool)
  {
    address sender = _msgSender();
    require(
      sender == honourNodes,
      "SamuraiLottery: Call origin is not from a contract!"
    );
    require(
      HNR.balanceOf(player) >= 500,
      "SamuraiLottery: Not enough balance!"
    );

    gamesPlayed++;
    // generate the random hash
    uint256 hashedNum = random(seed);
    // take 500 HNR tokens from the player
    HNR.approve(player, entryAmount);
    HNR.transferFrom(player, address(this), entryAmount);
    bool result = false;
    if (hashedNum < odds) {
      // transfer 1000 tokens to the player if there is a winning chance
      HNR.approve(address(this), winningReward);
      HNR.transferFrom(address(this), player, winningReward);
      wins++;
      result = true;
    } else {
      losses++;
      result = false;
    }
    emit LotteryGamePlayed(player, result);
    return result;
  }

  function playTaxFree(uint256 seed, address player)
    external
    whenNotPaused
    nonReentrant
    returns (bool)
  {
    address sender = _msgSender();
    require(
      sender == honourNodes,
      "SamuraiLottery: Call origin is not from a contract!"
    );

    gamesPlayed++;
    // generate the random hash
    uint256 hashedNum = random(seed);
    bool result = false;
    if (hashedNum < odds) {
      // transfer 1000 tokens to the player if there is a winning chance
      HNR.approve(address(this), winningReward);
      HNR.transferFrom(address(this), player, winningReward);
      wins++;
      result = true;
    } else {
      losses++;
      result = false;
    }
    emit LotteryGamePlayed(player, result);
    return result;
  }

  function random(uint256 seed) private view returns (uint256) {
    uint256 randomHash = uint256(
      keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed))
    );
    return randomHash % 100;
  }

  function release(address _receiver) external onlyOwner {
    payable(_receiver).transfer(address(this).balance);
  }

  function releaseToken(address _tokenAddress, uint256 _amountTokens)
    external
    onlyOwner
    returns (bool success)
  {
    return IERC20(_tokenAddress).transfer(msg.sender, _amountTokens);
  }

  function sampleOdds(uint256 seed) external view onlyOwner returns (uint256) {
    return random(seed);
  }

  function getGamesPlayed() external view onlyOwner returns (uint256) {
    return gamesPlayed;
  }

  function getWins() external view onlyOwner returns (uint256) {
    return wins;
  }

  function getLosses() external view onlyOwner returns (uint256) {
    return losses;
  }

  function setOdds(uint256 _odds) external onlyOwner {
    odds = _odds;
  }

  function resetGameStats() external onlyOwner {
    gamesPlayed = 0;
    wins = 0;
    losses = 0;
  }

  function setTokenAddress(address _hnr) external onlyOwner {
    HNR = IHonour(_hnr);
  }
}
