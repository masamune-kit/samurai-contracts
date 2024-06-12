// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.13;

interface ISamuraiLottery {
  function play(uint256 seed, address player) external returns (bool);

  function playTaxFree(uint256 seed, address player) external returns (bool);
}
