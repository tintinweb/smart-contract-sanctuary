/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.0;

contract ReceiveEther {
    /**
    * @notice contract can receive Ether.
    */
    receive() external payable {}
    
    /**
    * @dev transferring _amount Ether to 
    * the _recipient address from the contract.
    * 
    * requires: enough balance
    * 
    * @return true if transfer was successful
    */
    function transferEther(
        address payable _recipient, 
        uint _amount
    ) 
        external 
        returns (bool) 
    {
        require(address(this).balance >= _amount, 'Not enough Ether in contract!');
        _recipient.transfer(_amount);
        
        return true;
    }
    
    /**
    * @return contract balance
    */
    function contractBalance() external view returns (uint) {
        return address(this).balance;
    }
}