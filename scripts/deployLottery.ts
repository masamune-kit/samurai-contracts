// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";
import type { ContractFactory } from "ethers";

async function main() {
  const [deployer, distributionPool] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const SamuraiLottery = await ethers.getContractFactory("SamuraiLottery");
  const samuraiLottery = await upgrades.deployProxy(
    SamuraiLottery as ContractFactory,
    [
      distributionPool.address,
      "0x4f89c90E64AE57eaf805Ff2Abf868fE2aD6c55f3",
      "0x36667966c79dEC0dCDA0E2a41370fb58857F5182",
    ],
    { initializer: "initialize" }
  );
  await samuraiLottery.deployed();
  console.log("Lottery Deployed!");

  const HNR = new ethers.Contract(
    "0x36667966c79dEC0dCDA0E2a41370fb58857F5182",
    [
      "function approve(address spender, uint256 value) external returns (bool)",
    ],
    distributionPool
  );

  const approveTx = await HNR.approve(
    samuraiLottery.address,
    "999999999999999999999999999999999999",
    {
      gasPrice: 350000000000,
      gasLimit: 300000,
    }
  );

  await approveTx.wait();
  console.log("HNR Approved!");

  console.log(
    "TransferProxy HonourNodes Contract deployed to:",
    samuraiLottery.address
  );
  console.log(
    "Implementation Contract: ",
    await upgrades.erc1967.getImplementationAddress(samuraiLottery.address)
  );
  console.log(
    "ProxyAdmin Contract: ",
    await upgrades.erc1967.getAdminAddress(samuraiLottery.address)
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
