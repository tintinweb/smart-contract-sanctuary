/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title RegiCaster
 * @dev cast them coins everywhere. KEK.
 * Built by the REGI team
 */

contract RegiCaster {
    
    address public boss;
    
    constructor() public {
        boss=msg.sender;
    }
    
    function airdrop(address[] memory addresses, uint256 amount, address ercContract) public returns (bool){
        require(msg.sender==boss);
        for (uint i=0; i < addresses.length; i++){
            bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)",addresses[i],amount);
            ercContract.call(payload);
        }
        return true;
    }
    
    function transferOwner(address newOwner) public returns (bool) {
        require(msg.sender==boss); 
        boss=newOwner;
        return true;
    }
    
}