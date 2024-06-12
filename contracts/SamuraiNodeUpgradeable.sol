// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// solhint-disable max-states-count
// solhint-disable not-rely-on-time
// solhint-disable var-name-mixedcase
// solhint-disable reason-string

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./IHonour.sol";
import "./IHonourNode.sol";
import "./IUniswapV2Router02.sol";
import "./ISamuraiLottery.sol";

contract HonourNodes is
  Initializable,
  IHonourNode,
  ERC721EnumerableUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeMathUpgradeable for uint256;
  using StringsUpgradeable for *;

  // unsettable
  uint256 public nodeCap;
  uint256 public minted;
  uint256 public bukeMinted;
  uint256 public mononofuMinted;
  uint256 public mushaMinted;
  uint256 public totalRewardsStaked;

  // settable
  string public rpcURI;
  string public baseURI;
  string public baseExtension;

  IHonour public HNR;
  IUniswapV2Router02 public uniswapV2Router;
  address public distributionPool;
  address public futurePool;
  bool public swapLiquify;
  uint256 public claimFee;

  mapping(uint256 => HonourNode) public nodeTraits;
  mapping(NodeType => HonourNodeState) public nodeInfo;

  uint256 public timestamp;
  bool public isClaimEnabled;
  ISamuraiLottery public samuraiLottery;
  uint256 public lotteryEntry;

  // events
  event PaymentReceived(address from, uint256 amount);
  event HNRTokenAddressChanged(address from, address to);
  event UniswapRouterChanged(address from, address to);
  event DistributionPoolChanged(address from, address to);
  event FuturePoolChanged(address from, address to);
  event LotteryGamePlayed(address player, bool result);

  function initialize(
    address _hnr,
    address _distributionPool,
    address _futurePool,
    address _uniswapV2Router,
    string memory _setBaseURI,
    string memory _rpcURI
  ) public initializer {
    __ERC721_init("Honour Nodes", "HONOUR");
    OwnableUpgradeable.__Ownable_init();
    PausableUpgradeable.__Pausable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    nodeCap = 200_000; // set node cap at 200k
    minted = 0;
    bukeMinted = 0;
    mononofuMinted = 0;
    mushaMinted = 0;

    rpcURI = _rpcURI;
    baseURI = _setBaseURI;
    baseExtension = ".json";

    HNR = IHonour(_hnr);
    distributionPool = _distributionPool;
    futurePool = _futurePool;
    claimFee = 10;
    swapLiquify = true;
    uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);

    // set node state information
    nodeInfo[NodeType.BUKE] = HonourNodeState("BUKE", 17500000000000000);
    nodeInfo[NodeType.MONONOFU] = HonourNodeState(
      "MONONOFU",
      140000000000000000
    );
    nodeInfo[NodeType.MUSHA] = HonourNodeState("MUSHA", 525000000000000000);
  }

  // this function must be present to be able to receive FTM
  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  function mintBuke(uint256 amount, string memory name)
    external
    onlyOwner
    whenNotPaused
  {
    require(minted + amount <= nodeCap, "Node Amount Exceeded");

    for (uint256 i = 0; i < amount; i++) {
      minted++;
      bukeMinted++;
      uint256 mintTimestamp = block.timestamp;
      nodeTraits[minted] = HonourNode(
        NodeType.BUKE,
        resolveName(name, minted),
        resolveRPC("ftm", minted),
        resolveRPC("avax", minted),
        resolveRPC("matic", minted),
        mintTimestamp,
        mintTimestamp
      );
      _safeMint(_msgSender(), minted);
    }
  }

  function mintMononofu(uint256 amount, string memory name)
    external
    onlyOwner
    whenNotPaused
  {
    require(minted + amount <= nodeCap, "Node Amount Exceeded");

    for (uint256 i = 0; i < amount; i++) {
      minted++;
      mononofuMinted++;
      uint256 mintTimestamp = block.timestamp;
      nodeTraits[minted] = HonourNode(
        NodeType.MONONOFU,
        resolveName(name, minted),
        resolveRPC("ftm", minted),
        resolveRPC("avax", minted),
        resolveRPC("matic", minted),
        mintTimestamp,
        mintTimestamp
      );
      _safeMint(_msgSender(), minted);
    }
  }

  function mintMusha(uint256 amount, string memory name)
    external
    onlyOwner
    whenNotPaused
  {
    require(minted + amount <= nodeCap, "Node Amount Exceeded");

    for (uint256 i = 0; i < amount; i++) {
      minted++;
      mushaMinted++;
      uint256 mintTimestamp = block.timestamp;
      nodeTraits[minted] = HonourNode(
        NodeType.MUSHA,
        resolveName(name, minted),
        resolveRPC("ftm", minted),
        resolveRPC("avax", minted),
        resolveRPC("matic", minted),
        mintTimestamp,
        mintTimestamp
      );
      _safeMint(_msgSender(), minted);
    }
  }

  function batchTransfer(address recipient, uint256[] calldata tokenIds)
    external
  {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      transferFrom(_msgSender(), recipient, tokenIds[i]);
    }
  }

  function resolveRPC(string memory chain, uint256 tokenId)
    internal
    view
    returns (string memory)
  {
    return string(abi.encodePacked(rpcURI, chain, "/nft/", tokenId.toString()));
  }

  function resolveName(string memory name, uint256 tokenId)
    internal
    view
    returns (string memory)
  {
    return string(abi.encodePacked(name, " #", tokenId.toString()));
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721: Nonexistent token");

    HonourNode memory _node = nodeTraits[tokenId];
    string memory currentBaseURI = _baseURI();

    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(
            currentBaseURI,
            nodeInfo[_node.tier].tier,
            "/",
            tokenId.toString(),
            baseExtension
          )
        )
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function getTierRewardRate(NodeType tier) external view returns (uint256) {
    if (tier == NodeType.BUKE) {
      return nodeInfo[NodeType.BUKE].rewardsRate;
    } else if (tier == NodeType.MONONOFU) {
      return nodeInfo[NodeType.MONONOFU].rewardsRate;
    } else {
      return nodeInfo[NodeType.MUSHA].rewardsRate;
    }
  }

  function getNodeTrait(uint256 tokenId)
    external
    view
    returns (HonourNode memory)
  {
    require(_exists(tokenId), "HonourNode: nonexistent token");
    return nodeTraits[tokenId];
  }

  function calculateDynamicRewards(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    require(_exists(tokenId), "HonourNode: nonexistent token");
    HonourNode memory nodeTrait = nodeTraits[tokenId];
    return (((block.timestamp - nodeTrait.lastClaimTime) *
      nodeInfo[nodeTrait.tier].rewardsRate) / 86400);
  }

  function calculateDynamicRewards(uint256 lastClaimTime, NodeType tier)
    private
    view
    returns (uint256)
  {
    return (((block.timestamp - lastClaimTime) * nodeInfo[tier].rewardsRate) /
      86400);
  }

  function calculateTotalDynamicRewards(uint256[] calldata tokenIds)
    external
    view
    returns (uint256)
  {
    uint256 totalRewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      totalRewards += calculateDynamicRewards(tokenIds[i]);
    }
    return totalRewards;
  }

  function syncNodeReward(uint256 tokenId) private returns (uint256) {
    uint256 blocktime = block.timestamp;
    HonourNode storage nodeTrait = nodeTraits[tokenId];
    if (nodeTrait.lastClaimTime < timestamp) {
      nodeTrait.lastClaimTime = blocktime;
      nodeTrait.rewardsClaimed = 0;
      return (0);
    }
    uint256 calculatedRewards = calculateDynamicRewards(
      nodeTrait.lastClaimTime,
      nodeTrait.tier
    );
    // restart the cycle & add to total rewards
    nodeTrait.lastClaimTime = blocktime;
    nodeTrait.rewardsClaimed += calculatedRewards;
    totalRewardsStaked += calculatedRewards;
    return (calculatedRewards);
  }

  function claimRewards(uint256 tokenId) external nonReentrant {
    require(isClaimEnabled, "HonourNode: Claims are not enabled");
    require(_exists(tokenId), "HonourNode: nonexistent token");
    address sender = _msgSender();
    require(sender == ownerOf(tokenId), "HonourNode: Not an NFT owner");
    require(sender != address(0));
    uint256 taxRate = calculateSlidingTaxRate(tokenId);
    uint256 rewardAmount = syncNodeReward(tokenId);
    if (rewardAmount > 0) {
      uint256 feeAmount = rewardAmount.mul(taxRate).div(100);
      if (swapLiquify && feeAmount > 0) {
        swapAndSendToFee(futurePool, feeAmount);
      }

      rewardAmount -= feeAmount;
      HNR.approve(address(distributionPool), rewardAmount);
      HNR.transferFrom(distributionPool, sender, rewardAmount);
    }
  }

  function claimAllRewards(uint256[] memory tokenIds) external nonReentrant {
    require(isClaimEnabled, "HonourNode: Claims are not enabled");
    require(tokenIds.length > 0, "HonourNode: no tokens to redeem");
    address sender = _msgSender();
    uint256 rewardAmount = 0;
    uint256 feeAmount = 0;
    require(sender != address(0));
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (_exists(tokenId) && (sender == ownerOf(tokenId))) {
        uint256 taxRate = calculateSlidingTaxRate(tokenId);
        uint256 nodeRewardAmount = syncNodeReward(tokenId);
        rewardAmount += nodeRewardAmount;
        feeAmount += nodeRewardAmount.mul(taxRate).div(100);
      }
    }
    if (rewardAmount > 0) {
      if (swapLiquify && feeAmount > 0) {
        swapAndSendToFee(futurePool, feeAmount);
      }

      rewardAmount -= feeAmount;
      HNR.approve(address(distributionPool), rewardAmount);
      HNR.transferFrom(distributionPool, sender, rewardAmount);
    }
  }

  function calculateSlidingTaxRate(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    uint256 blocktime = block.timestamp;
    HonourNode storage nodeTrait = nodeTraits[tokenId];
    uint256 numDays = (blocktime - nodeTrait.lastClaimTime).div(86400);
    if (numDays < 7) {
      return 50;
    } else if (numDays < 14) {
      return 40;
    } else if (numDays < 21) {
      return 30;
    } else if (numDays < 28) {
      return 20;
    } else {
      if (nodeTrait.tier == NodeType.BUKE) {
        return 5;
      } else if (nodeTrait.tier == NodeType.MONONOFU) {
        return 8;
      } else {
        return 10;
      }
    }
  }

  function play(uint256 seed)
    external
    whenNotPaused
    nonReentrant
    returns (bool)
  {
    address player = _msgSender();
    require(player != address(0));
    require(this.balanceOf(player) >= 1);
    bool result = samuraiLottery.play(seed, player);
    emit LotteryGamePlayed(player, result);
    return result;
  }

  function playTaxFree(uint256 seed, uint256[] memory tokenIds)
    external
    whenNotPaused
    nonReentrant
    returns (bool)
  {
    address player = _msgSender();
    require(tokenIds.length > 0);
    require(player != address(0));
    require(this.balanceOf(player) >= 1);

    uint256 unclaimedBalance = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (_exists(tokenId) && (player == ownerOf(tokenId))) {
        unclaimedBalance += calculateDynamicRewards(tokenId);
      }
      if (unclaimedBalance >= lotteryEntry) {
        break;
      }
    }

    require(unclaimedBalance >= lotteryEntry, "no funds");
    // reduce the claim rewards
    uint256 accumulator = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (_exists(tokenId) && (player == ownerOf(tokenId))) {
        uint256 tokenRewards = calculateDynamicRewards(tokenId);
        if (accumulator == lotteryEntry) {
          break;
        } else if (accumulator + tokenRewards < lotteryEntry) {
          accumulator += syncNodeReward(tokenId);
        } else {
          uint256 leftOver = lotteryEntry - accumulator;
          if (leftOver > 0) {
            HonourNode storage nodeTrait = nodeTraits[tokenId];
            uint256 timeDifference = ((leftOver * 86400) /
              nodeInfo[nodeTrait.tier].rewardsRate);
            nodeTrait.lastClaimTime += timeDifference;
            nodeTrait.rewardsClaimed += leftOver;
            totalRewardsStaked += leftOver;
            accumulator += leftOver;
          } else if (leftOver == 0) {
            break;
          }
        }
      }
    }
    // call the lottery
    bool result = samuraiLottery.playTaxFree(seed, player);
    emit LotteryGamePlayed(player, result);
    return result;
  }

  // pool related logic
  function swapAndSendToFee(address destination, uint256 tokens) private {
    uint256 initialETHBalance = address(this).balance;

    swapTokensForEth(tokens);
    uint256 newBalance = (address(this).balance).sub(initialETHBalance);
    payable(destination).transfer(newBalance);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(HNR);
    path[1] = uniswapV2Router.WETH();

    HNR.approve(address(uniswapV2Router), tokenAmount);

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
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

  // setters
  function setPause(bool _pauseState) external onlyOwner {
    _pauseState ? _pause() : _unpause();
  }

  function setBukeRewardRate(uint256 rate) external onlyOwner {
    HonourNodeState storage bukeNode = nodeInfo[NodeType.BUKE];
    bukeNode.rewardsRate = rate;
  }

  function setMononofuRewardRate(uint256 rate) external onlyOwner {
    HonourNodeState storage mononofuNode = nodeInfo[NodeType.MONONOFU];
    mononofuNode.rewardsRate = rate;
  }

  function setMushaRewardRate(uint256 rate) external onlyOwner {
    HonourNodeState storage mushaNode = nodeInfo[NodeType.MUSHA];
    mushaNode.rewardsRate = rate;
  }

  function setURIForRPC(string memory uri) external onlyOwner {
    rpcURI = uri;
  }

  function setURIForBase(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  function setFileTypeForExtension(string memory extension) external onlyOwner {
    baseExtension = extension;
  }

  function setHNR(address _hnr) external onlyOwner {
    emit HNRTokenAddressChanged(address(HNR), _hnr);
    HNR = IHonour(_hnr);
  }

  function setUniswap(address _uniswap) external onlyOwner {
    emit UniswapRouterChanged(address(uniswapV2Router), _uniswap);
    uniswapV2Router = IUniswapV2Router02(_uniswap);
  }

  function setDistributionPool(address _distributionPool) external onlyOwner {
    emit DistributionPoolChanged(distributionPool, _distributionPool);
    distributionPool = _distributionPool;
  }

  function setFuturePool(address _futurePool) external onlyOwner {
    emit FuturePoolChanged(futurePool, _futurePool);
    futurePool = _futurePool;
  }

  function setSwapLiquify(bool swapState) external onlyOwner {
    swapLiquify = swapState;
  }

  function setClaimFee(uint256 _fee) external onlyOwner {
    claimFee = _fee;
  }

  function setNodeCap(uint256 _cap) external onlyOwner {
    nodeCap = _cap;
  }

  function setTimestamp() external onlyOwner {
    timestamp = block.timestamp;
  }

  function setIsClaimEnabled(bool _isEnabled) external onlyOwner {
    isClaimEnabled = _isEnabled;
  }

  function debug(uint256[] calldata tokenIds, uint256 blocktime)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      HonourNode storage nodeTrait = nodeTraits[tokenId];
      nodeTrait.lastClaimTime = blocktime;
    }
  }

  function getBlocktime() external view returns (uint256) {
    return block.timestamp;
  }

  function setSamuraiLottery(address _lottery) external onlyOwner {
    samuraiLottery = ISamuraiLottery(_lottery);
  }

  function setLotteryEntry(uint256 _lotteryEntry) external onlyOwner {
    lotteryEntry = _lotteryEntry * 10**18;
  }
}
