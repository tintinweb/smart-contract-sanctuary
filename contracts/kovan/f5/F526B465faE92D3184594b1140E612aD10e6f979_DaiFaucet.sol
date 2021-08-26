/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

//First, we add the solidity version that the code will be compiled into the EVM.

pragma solidity ^0.5.9;

// To enable our faucet contract to recognize and interact with the Dai token contract we need to 
// write an interface that will map the Dai token functions that we’ll use. 
// In this case, that means the transfer() and balanceOf() functions, since we will need our 
// contract to transfer Dai to whomever requests it and also to check the balanceOf its Dai 
// holdings to know if it can transfer in the first place. 
// We will need to instantiate this interface later in the codebase.

// Adding only the ERC-20 function we need
interface DaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

// Now we will set up supporting contracts that will manage ownership and control of our faucet contract. 
// The owned contract sets up the contract creator as the one in control, it sets the DaiToken daitoken 
// variable and the owner variable. It creates the onlyOnwer modifier function that adds restrictions 
// to who can call other functions in our faucet contract.

// When we deploy our contract to the Kovan network, the constructor function will set the owner variable 
// to the address of the calling Ethereum account, and set the daitoken variable to the address of 
// the Dai token contract on the Kovan network, which is 0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa. 
// Now the DaiToken interface will link to the Dai token address on the kovan network. 
// So when we call the transfer or balanceOf functions, they will call the functions of the Dai 
// token contract.

contract owned {
    DaiToken daitoken;
    address owner;

    constructor() public{
        owner = msg.sender;
        daitoken = DaiToken(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }

    modifier onlyOwner {
        require(msg.sender == owner,
        "Only the contract owner can call this function");
        _;
    }
}

// Moving on, we will add another contract that will inherit the owned contract. 
// We will call it mortal, as in, we will give our contract a kill switch that will terminate it 
// and return any funds back to the owner. The destroy() function can only be called by the owner, 
// hence the onlyOwner modifier. Here you can see that we use the daitoken interface. 
// We transfer any remaining Dai funds of the faucet contract to the owner.
contract mortal is owned {
    // Only owner can shutdown this contract.
    function destroy() public onlyOwner {
        daitoken.transfer(owner, daitoken.balanceOf(address(this)));
        selfdestruct(msg.sender);
    }
}

// Finally, we are writing the faucet contract. 
// We can see that DaiFaucet inherits the mortal contract, which in turn inherits the owned contract. 
// This way, we have modularised our contracts for their specific functions and added our total 
// control over it. Inside the contract we have two events that will watch and log every time 
// there is a Withdrawal and a Deposit to/from this contract.
contract DaiFaucet is mortal {

    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);

    // We have added the withdraw function that will take care to send Dai to anyone who calls this function. 
    // As you can see, we have added 2 conditions for the withdrawal:
    // - Require that the withdraw_amount is less or equal to 0.1 Dai
    // - Require that we have more Dai in the faucet than the withdraw_amount.

    // Give out Dai to anyone who asks
    function withdraw(uint withdraw_amount) public {
        // Limit withdrawal amount
        require(withdraw_amount <= 0.1 ether);
        require(daitoken.balanceOf(address(this)) >= withdraw_amount,
            "Insufficient balance in faucet for withdrawal request");
            
        // And of course, we log this transaction with the Withdrawal event. 
        // Send the amount to the address that requested it
        daitoken.transfer(msg.sender, withdraw_amount);
        
        // Only after these conditions are met we can transfer 0.1 Dai to the function caller. 
        // And of course, we log this transaction with the Withdrawal event. 
        // The way we send Dai to the function caller is by using the above defined DaiToken 
        // interface to allow us to make the transfer.
        emit Withdrawal(msg.sender, withdraw_amount);
    }

    // The unnamed function is here to receive any incoming payments our contracts gets and 
    //log the Deposit event.


    // Accept any incoming amount
    function () external payable {
        emit Deposit(msg.sender, msg.value);
    }
}