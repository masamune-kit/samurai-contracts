// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IHonourNode is IERC721Upgradeable {
  enum NodeType {
    BUKE,
    MONONOFU,
    MUSHA
  }

  struct HonourNodeState {
    string tier;
    uint256 rewardsRate;
  }

  // struct to store each token's traits
  struct HonourNode {
    NodeType tier;
    string name;
    string fantomRPC;
    string avalancheRPC;
    string polygonRPC;
    uint256 lastClaimTime;
    uint256 rewardsClaimed;
  }
}
