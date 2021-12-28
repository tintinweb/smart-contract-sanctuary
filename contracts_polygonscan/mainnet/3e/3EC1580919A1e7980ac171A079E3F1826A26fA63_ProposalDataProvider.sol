/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// SPDX-License-Identifier: AGPL-3.0
// are we business license yet
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface IProposalDataProvider {
  function getPayload(uint256 id) external view returns (IProposalGenericExecutor.ProposalPayload memory);
}

interface IProposalGenericExecutor {
  struct ProposalPayload {
    address underlyingAsset;
    address interestRateStrategy;
    address oracle;
    uint256 ltv;
    uint256 lt;
    uint256 lb;
    uint256 rf;
    uint8 decimals;
    bool borrowEnabled;
    bool stableBorrowEnabled;
    string underlyingAssetName;
  }
  function execute() external;
}

contract ProposalDataProvider is IProposalDataProvider {
  
  IProposalGenericExecutor.ProposalPayload[] public proposalPayloads;

  constructor() public {
    proposalPayloads.push(IProposalGenericExecutor.ProposalPayload(
      0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7,
      0xBb480ae4e2cf28FBE80C9b61ab075f6e7C4dB468,
      0xe638249AF9642CdA55A92245525268482eE4C67b,
      2500,
      4500,
      11250,
      2000,
      18,
      true,
      false,
      'GHST'
    ));
    proposalPayloads.push(IProposalGenericExecutor.ProposalPayload(
      0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3,
      0x9025C2d672afA29f43cB59b3035CaCfC401F5D62,
      0x03CD157746c61F44597dD54C6f6702105258C722,
      2000,
      4500,
      11000,
      2000,
      18,
      true,
      false,
      'BAL'
    ));
    proposalPayloads.push(IProposalGenericExecutor.ProposalPayload(
      0x85955046DF4668e1DD369D2DE9f3AEB98DD2A369,
      0x6405F880E431403588e92b241Ca15603047ef8a4,
      0xC70aAF9092De3a4E5000956E672cDf5E996B4610,
      2000,
      4500,
      11000,
      2000,
      18,
      false,
      false,
      'DPI'
    ));
    proposalPayloads.push(IProposalGenericExecutor.ProposalPayload(
      0x172370d5Cd63279eFa6d502DAB29171933a610AF,
      0xBD67eB7e00f43DAe9e3d51f7d509d4730Fe5988e,
      0x1CF68C76803c9A415bE301f50E82e44c64B7F1D4,
      2000,
      4500,
      11000,
      2000,
      18,
      true,
      false,
      'CRV'
    ));
    proposalPayloads.push(IProposalGenericExecutor.ProposalPayload(
      0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a,
      0x835699Bf98f6a7fDe5713c42c118Fb80fA059737,
      0x17414Eb5159A082e8d41D243C1601c2944401431,
      2000,
      4500,
      11000,
      3500,
      18,
      false,
      false,
      'SUSHI'
    ));
    proposalPayloads.push(IProposalGenericExecutor.ProposalPayload(
      0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39,
      0x5641Bb58f4a92188A6F16eE79C8886Cf42C561d3,
      0xb77fa460604b9C6435A235D057F7D319AC83cb53,
      6500,
      7000,
      11000,
      1000,
      18,
      true,
      false,
      'LINK'
    ));
  }
  function getPayload(uint256 id) public view override returns (IProposalGenericExecutor.ProposalPayload memory) {
    return proposalPayloads[id];
  }
}