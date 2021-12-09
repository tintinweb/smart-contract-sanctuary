/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity ^0.6.12;
//SPDX-License-Identifier: UNLICENSED

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);
}

/**
  Demo contract for L1 <-> L2 interaction between an L2 StarkNet contract and this L1 solidity
  contract.
*/
contract L1L2Example {
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    mapping(uint256=> uint256) public accountBalances;
    //so an ether address has a private key, but with cairo, you have abstract accounts, that have addresses generated randomly. So we want to set which AA address to send from an account. This is alright, but then how do we know what ethaddress to withdraw to? The easiest solution for that would be to specify that in the L2widthraw messagge

    uint256 constant MESSAGE_WITHDRAW = 0;

    // The selector of the "deposit" l1_handler.
    uint256 constant DEPOSIT_SELECTOR =
        352040181584456735608515580760888541466059565068553383579463728554843487745;

    /**
      Initializes the contract state.
    */
    constructor(IStarknetCore starknetCore_) public {
        starknetCore = starknetCore_;
    }

    function withdrawfroml2(
        uint256 l2ContractAddress,
        uint256 user, //this is a uint256 here, but it represents an address. So the javascript will have to do the conversion from address to uint256. This makes the gas fee lower.
        uint256 withdrawAddress,
        uint256 amount
    ) external {
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](5);
        
	//do the processing for cairo
	uint256 amountLow = amount % 2**128;
	uint256 amountHigh = amount / 2**128;

        payload[0] = MESSAGE_WITHDRAW;
        payload[1] = user;
        payload[2] = withdrawAddress;
        payload[3] = amountLow;
        payload[4] = amountHigh;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        // Update the L1 balance.
        accountBalances[withdrawAddress] += amount;
    }

    function withdrawfroml1(
        uint256 amount
    ) external {
        
        uint256 uintAddress = uint256(uint160(address(msg.sender)));    
        require(amount <= accountBalances[uintAddress], "Invalid amount.");
        
        // Update the L1 balance.
        accountBalances[uintAddress] -= amount;

        bool r = msg.sender.send(amount);
        if (!r){
          accountBalances[uintAddress] += amount;
        }
        //return r;
    }

    function deposit(
        uint256 l2ContractAddress,
        uint256 user
        //uint256 amount
    ) external payable {
        uint256 amount=msg.value;
        
	uint256 amountLow = amount % 2**128;
	uint256 amountHigh = amount / 2**128;
        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](3);
        payload[0] = user;
        payload[1] = amountLow;
        payload[2] = amountHigh;

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2ContractAddress, DEPOSIT_SELECTOR, payload);
    }
}