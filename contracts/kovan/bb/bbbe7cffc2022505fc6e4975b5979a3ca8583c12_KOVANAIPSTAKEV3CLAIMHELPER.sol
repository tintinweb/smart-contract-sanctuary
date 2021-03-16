/**
 *Submitted for verification at Etherscan.io on 2021-03-16
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
  function initialize(
    address slashingAdmin,
    address cooldownPauseAdmin,
    address claimHelper,
    uint256 maxSlashablePercentage,
    string calldata name,
    string calldata symbol,
    uint8 decimals
  ) external;
}


contract KOVANAIPSTAKEV3CLAIMHELPER {
  event ProposalExecuted();
  IAaveDistributionManager public constant STK_AAVE_TOKEN =
    IAaveDistributionManager(0xf2fbf9A6710AfDa1c4AaB2E922DE9D69E0C97fd2);
    
  // 3 months of amission
  uint256 public constant NEW_ALLOWANCE = 50_000 ether;
  // 550 per day
  uint128 public constant NEW_EMISSION_PER_SECOND = 0.006365740740740741 ether;

  function executeChangeImplem(address implem) external {
    STK_AAVE_TOKEN.upgradeTo(implem);

    emit ProposalExecuted();
  }
  function executeInitialize(address claimHelper) external{
    STK_AAVE_TOKEN.initialize(
        0xCC5ecBC7d3880365D7bCF8acf932c6A8aB7e7B32,
        0xCC5ecBC7d3880365D7bCF8acf932c6A8aB7e7B32,
        claimHelper,
        3000,
        '',
        '',
        0
    );
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