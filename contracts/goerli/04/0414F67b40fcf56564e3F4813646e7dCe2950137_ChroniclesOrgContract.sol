/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ChroniclesOrgContract {

//  string graphQlEndpoint = '';
//  uint8 graphQlId = '';

  event PublishCall(
    string graphQlEndpoint,
    uint8 graphQlId
  );

  constructor() {}

  function fireEvent(string calldata _graphQlEndpoint, uint8 _graphQlId) public {
    emit PublishCall(_graphQlEndpoint,_graphQlId);
  }
}