/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

interface IProposalExecutor {
  function execute() external;
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
}

interface IProxyWithAdminActions {
  function changeAdmin(address newAdmin) external;
}

interface IAaveDistributionManager {
  struct AssetConfigInput {
    uint128 emissionPerSecond;
    uint256 totalStaked;
    address underlyingAsset;
  }

  function configureAssets(AssetConfigInput[] calldata assetsConfigInput) external;
}

interface IAaveReserveImpl {
  function initialize(address reserveController) external;

  function approve(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external;
}

interface IControllerAaveEcosystemReserve {
  function approve(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external;
}

contract AIP9 is IProposalExecutor {
  event ProposalExecuted();

  address public constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  address public constant LONG_EXECUTOR = 0x61910EcD7e8e942136CE7Fe7943f956cea1CC2f7;
  IAaveDistributionManager public constant STK_ABPT_TOKEN =
    IAaveDistributionManager(0xa1116930326D21fB917d5A27F1E9943A9595fb47);
  IProxyWithAdminActions public constant STK_ABPT_PROXY =
    IProxyWithAdminActions(0xa1116930326D21fB917d5A27F1E9943A9595fb47);
  IProxyWithAdminActions public constant ABPT_PROXY =
    IProxyWithAdminActions(0x41A08648C3766F9F9d85598fF102a08f4ef84F84);
  IControllerAaveEcosystemReserve public constant CONTROLLER_AAVE_RESERVE =
    IControllerAaveEcosystemReserve(0x1E506cbb6721B83B1549fa1558332381Ffa61A93);

  // 3 months of amission
  uint256 public constant NEW_ALLOWANCE = 50_000 ether;
  // 550 per day
  uint128 public constant NEW_EMISSION_PER_SECOND = 0.006365740740740741 ether;

  function execute() external override {
    STK_ABPT_PROXY.changeAdmin(LONG_EXECUTOR);

    ABPT_PROXY.changeAdmin(LONG_EXECUTOR);

    CONTROLLER_AAVE_RESERVE.approve(IERC20(AAVE_TOKEN), address(STK_ABPT_TOKEN), NEW_ALLOWANCE);

    IAaveDistributionManager.AssetConfigInput[] memory config =
      new IAaveDistributionManager.AssetConfigInput[](1);
    config[0] = IAaveDistributionManager.AssetConfigInput({
      emissionPerSecond: NEW_EMISSION_PER_SECOND,
      totalStaked: IERC20(address(STK_ABPT_TOKEN)).totalSupply(),
      underlyingAsset: address(STK_ABPT_TOKEN)
    });

    STK_ABPT_TOKEN.configureAssets(config);

    emit ProposalExecuted();
  }
}