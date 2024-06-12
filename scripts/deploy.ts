// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";
import type { ContractFactory } from "ethers";

async function main() {
  const [deployer, distributionPool, futurePool] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);
  console.log(ethers.utils.formatUnits(await deployer.getGasPrice(), "gwei"));

  const HonourNodes = await ethers.getContractFactory("HonourNodes");
  const honourNodes = await upgrades.deployProxy(
    HonourNodes as ContractFactory,
    [
      "0x36667966c79dEC0dCDA0E2a41370fb58857F5182",
      distributionPool.address,
      futurePool.address,
      "0xF491e7B69E4244ad4002BC14e878a34207E38c29",
      "https://ipfs.io/ipfs/",
      "https://rpc.samurai.financial/",
    ],
    { initializer: "initialize" }
  );
  await honourNodes.deployed();
  console.log("Honour Deployed!");

  // approve the spendings
  const HNR = new ethers.Contract(
    "0x36667966c79dEC0dCDA0E2a41370fb58857F5182",
    [
      "function approve(address spender, uint256 value) external returns (bool)",
    ],
    distributionPool
  );

  const approveTx = await HNR.approve(
    honourNodes.address,
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
    honourNodes.address
  );
  console.log(
    "Implementation Contract: ",
    await upgrades.erc1967.getImplementationAddress(honourNodes.address)
  );
  console.log(
    "ProxyAdmin Contract: ",
    await upgrades.erc1967.getAdminAddress(honourNodes.address)
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
