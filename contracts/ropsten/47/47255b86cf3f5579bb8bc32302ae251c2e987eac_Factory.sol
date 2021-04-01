/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

/**
 *Submitted for verification at Etherscan.io on 2020-04-20
*/

pragma solidity ^0.4.25;

/*
    Just the interface so solidity can compile properly
    We could skip this if we use generic call creation or abi.encodeWithSelector
*/
contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/*
    Generic Receiver Contract
*/
contract Receiver {

    address public owner;

    constructor() public {
        /* 
            Deployer's address ( Factory in our case )
            do not pass this as a constructor argument because 
            etherscan will have issues displaying our validated source code
        */
        owner = msg.sender;
    }

    /*
        @notice Send funds owned by this contract to another address
        @param tracker  - ERC20 token tracker ( DAI / MKR / etc. )
        @param amount   - Amount of tokens to send
        @param receiver - Address we're sending these tokens to
        @return true if transfer succeeded, false otherwise 
    */
    function sendFundsTo( address tracker, uint256 amount, address receiver) public returns ( bool ) {
        // callable only by the owner, not using modifiers to improve readability
        require(msg.sender == owner);

        // Transfer tokens from this address to the receiver
        return ERC20(tracker).transfer(receiver, amount);
    }

    // depending on your system,  you probably want to suicide this at some
    // point in the future, or reuse it for other clients
}

/*
    Factory Contract
*/

contract Factory {

    address public owner;
    mapping ( uint256 => address ) public receiversMap;
    uint256 receiverCount = 0;

    constructor() public {
        /* 
            Deployer's address ( Factory in our case )
            do not pass this as a constructor argument because 
            etherscan will have issues displaying our validated source code
        */
        owner = msg.sender;
    }

    /*
        @notice Create a number of receiver contracts
        @param number  - 0-255 
    */
    function createReceivers( uint8 number ) public {
        require(msg.sender == owner);

        for(uint8 i = 0; i < number; i++) {
            // Create and index our new receiver
            receiversMap[++receiverCount] = new Receiver();
        }
        // add event here if you need it
    }

    /*
        @notice Send funds in a receiver to another address
        @param ID       - Receiver indexed ID
        @param tracker  - ERC20 token tracker ( DAI / MKR / etc. )
        @param amount   - Amount of tokens to send
        @param receiver - Address we're sending tokens to
        @return true if transfer succeeded, false otherwise 
    */
    function sendFundsFromReceiverTo( uint256 ID, address tracker, uint256 amount, address receiver ) public returns (bool) {
        require(msg.sender == owner);
        return Receiver( receiversMap[ID] ).sendFundsTo( tracker, amount, receiver);
    }

    /*
        Batch Collection - Should support a few hundred transansfers

        @param tracker           - ERC20 token tracker ( DAI / MKR / etc. )
        @param receiver          - Address we're sending tokens to
        @param contractAddresses - we send an array of addresses instead of ids, so we don't need to read them ( lower gas cost )
        @param amounts           - array of amounts 

    */
    function batchCollect( address tracker, address receiver, address[] contractAddresses, uint256[] amounts ) public {
        require(msg.sender == owner);

        for(uint256 i = 0; i < contractAddresses.length; i++) {

            // add exception handling
            Receiver( contractAddresses[i] ).sendFundsTo( tracker, amounts[i], receiver);
        }
    }

}