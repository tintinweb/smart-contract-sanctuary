/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

/*
  Copyright 2019-2021 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
pragma solidity ^0.6.11;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) virtual external;

    /**
      Consumes a message that was sent from an L2 contract.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) virtual external;
}

/**
  Demo contract for L1 <-> L2 interaction between an L2 StarkNet contract and this L1 solidity
  contract.
*/
contract L1L2Example {
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    mapping (uint256 => mapping(uint256 => uint256)) public userBalances;
    mapping (address => uint256) public userIds;
    uint256 public userIndex=1;

    uint256 constant MESSAGE_WITHDRAW = 0;

    // The selector of the "deposit" l1_handler.
    uint256 constant DEPOSIT_SELECTOR =1302550609353484868110234813026153401035113359011827079263285698212883587005;

    /**
      Initializes the contract state.
    */
    constructor(
        IStarknetCore starknetCore_)
        public
    {
        starknetCore = starknetCore_;
    }
    
    function regist()external{
        require(userIds[msg.sender]==0,"id is exist");
        userIds[msg.sender]=userIndex;
        userIndex++;
    }
    
    function addAmount(uint256 amount,uint256 token_type)external{
        require(userIds[msg.sender]!=0,"id is not exist");
        userBalances[userIds[msg.sender]][token_type] += amount;
    }

 function withdraw(
        uint256 l2ContractAddress,
        uint256 token_type,
        uint256 amount)
        external
    {
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](4);
        payload[0] = MESSAGE_WITHDRAW;
        payload[1] = userIds[msg.sender];
        payload[2] = token_type;
        payload[3] = amount;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        // Update the L1 balance.
        userBalances[userIds[msg.sender]][token_type] += amount;
    }
   function deposit(
        uint256 l2ContractAddress,
        uint256 token_type,
        uint256 amount)
        external
    {
        require(amount < 2 ** 64, "Invalid amount.");
        require(amount <= userBalances[userIds[msg.sender]][token_type], "The user's balance is not large enough.");

        // Update the L1 balance.
        userBalances[userIds[msg.sender]][token_type] -= amount;

        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](3);
        payload[0] = userIds[msg.sender];
        payload[1] = token_type;
        payload[2] = amount;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.sendMessageToL2(l2ContractAddress, DEPOSIT_SELECTOR, payload);
    }
}