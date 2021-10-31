pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;
import "./BankToken.sol";

contract CFTToken is BankToken {
    string public name;
    string public symbol;
    uint8 public decimals = 2;
   constructor( uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
       
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;   
        AccountOf[400000]=msg.sender;
        employeeinfo[msg.sender] = employee(msg.sender,100000,"Code Fever","[email protected]","9658452563","Chandrapur","442401","UID","8456321545632","Admin",block.timestamp,true);
        //customerinfo[msg.sender] = customers(msg.sender,"Code Fever","[email protected]","9658452563","Chandrapur","442401","UID","8456321545632","Current","Company",block.timestamp,true);
    }

}