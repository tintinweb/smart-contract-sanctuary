/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

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


interface IAaveDistributionManager {
  struct AssetConfigInput {
    uint128 emissionPerSecond;
    uint256 totalStaked;
    address underlyingAsset;
  }

  function configureAssets(AssetConfigInput[] calldata assetsConfigInput) external;
  function upgradeTo(address newImplementation) external payable;
}


contract KOVANAIPSTAKEV3 {
  event ProposalExecuted();
  address public constant implem = 0x10E55d67F37A9833837eB68ee7cF66D7b8e1A26A;
  IAaveDistributionManager public constant STK_AAVE_TOKEN =
    IAaveDistributionManager(0xf2fbf9A6710AfDa1c4AaB2E922DE9D69E0C97fd2);
    
  // 3 months of amission
  uint256 public constant NEW_ALLOWANCE = 50_000 ether;
  // 550 per day
  uint128 public constant NEW_EMISSION_PER_SECOND = 0.006365740740740741 ether;

  function executeLong() external {
    STK_AAVE_TOKEN.upgradeTo(implem);

    emit ProposalExecuted();
  }
  function executeShort() external {
    IAaveDistributionManager.AssetConfigInput[] memory config =
      new IAaveDistributionManager.AssetConfigInput[](1);
    config[0] = IAaveDistributionManager.AssetConfigInput({
      emissionPerSecond: NEW_EMISSION_PER_SECOND,
      totalStaked: IERC20(address(STK_AAVE_TOKEN)).totalSupply(),
      underlyingAsset: address(STK_AAVE_TOKEN)
    });
    STK_AAVE_TOKEN.configureAssets(config);

    emit ProposalExecuted();
  }
}