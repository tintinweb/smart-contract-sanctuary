/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface Token{
    function transferOwnership(address newOwner) external;
    function stop() external;
    function start() external;
    function close() external;
    function decimals() external view returns(uint256);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function mint( address to, uint256 value ) external returns (bool);
    function increaseApproval(address _spender, uint _addedValue) external returns (bool);
    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);
    function burn(uint256 _value) external;
    function burnTokens(address who,uint256 _value) external;
}

contract DynamicBulkTransfer{
    address public owner;

    // constructor 
    constructor () {
        owner = msg.sender;
    }
    
    // bulktransfer method
    function makeTransfer(address payable[] memory  addressArray, uint256[] memory  amountArray, address contactAddress) public{
        require(addressArray.length==amountArray.length,'Arrays must be of same size.');
        Token tokenInstance= Token(contactAddress);
        for(uint i=0;i<addressArray.length;i++){
            require(tokenInstance.balanceOf(owner)>=amountArray[i],'Owner has insufficient token balance.');
            tokenInstance.transferFrom(msg.sender, addressArray[i],amountArray[i]);
        }
        
    }
    
}