// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";
import type { ContractFactory } from "ethers";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const SamuraiSwap = await ethers.getContractFactory("SamuraiSwap");
  const samuraiSwap = await upgrades.deployProxy(
    SamuraiSwap as ContractFactory,
    [
      "0x36667966c79dEC0dCDA0E2a41370fb58857F5182",
      "0xd5aa2a5AcFC000c08E8dab3Af830ed4f09120478",
    ],
    { initializer: "initialize" }
  );
  await samuraiSwap.deployed();
  console.log("Swap Deployed!");

  console.log(
    "TransferProxy SamuraiSwap Contract deployed to:",
    samuraiSwap.address
  );
  console.log(
    "Implementation Contract: ",
    await upgrades.erc1967.getImplementationAddress(samuraiSwap.address)
  );
  console.log(
    "ProxyAdmin Contract: ",
    await upgrades.erc1967.getAdminAddress(samuraiSwap.address)
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
