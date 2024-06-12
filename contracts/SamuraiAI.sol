// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./IUniswapV2Router02.sol";
import "./IHonour.sol";

contract SamuraiAI is Initializable {
  IHonour public HNR;
  IUniswapV2Router02 public uniswapV2Router;
  address public manager;
  uint256 public serviceCost;

  event PaymentReceived(address from, uint256 amount);

  function initialize(
    address _hnr,
    address _uniswapV2Router,
    address _manager
  ) external initializer {
    HNR = IHonour(_hnr);
    uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    manager = _manager;
    serviceCost = 200 * 10**18;
  }

  // this function must be present to be able to receive FTM
  receive() external payable virtual {
    emit PaymentReceived(msg.sender, msg.value);
  }

  modifier onlyManager() {
    require(msg.sender == manager, "Not the manager!");
    _;
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

  function takeFeeForGeneration(address requester) external onlyManager {
    require(
      HNR.allowance(requester, address(this)) >= serviceCost,
      "Re-approve needed!"
    );
    HNR.transferFrom(requester, address(this), serviceCost);
    swapTokensForEth(serviceCost);
    payable(manager).transfer(address(this).balance);
  }
}
