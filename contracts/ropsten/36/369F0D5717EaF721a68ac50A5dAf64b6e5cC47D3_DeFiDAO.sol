/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.5;

// proxy that will be used to update logic as needed
contract DeFiDAO {
    address internal implementation;
    
    event Received(address, uint);
    
    function setLogicContractAddress (address newAddress) private
    {
        implementation = newAddress;
    }
    
    function getLogicContractAddress () external view returns (address)
    {
        return implementation;
    }
    
   constructor (address _proxied) payable {
        implementation = _proxied;
    }
    /**
    * @notice contract can receive Ether.
    */
    receive() external payable {
        //
        emit Received(msg.sender, msg.value);
    }
    
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
    
    /**
     * Fallback function allowing to perform a delegatecall 
     * to the given implementation. This function will return 
     * whatever the implementation call returns
     */
    fallback () external payable {
        address addr = implementation;


        assembly {
            let freememstart := mload(0x40)
            calldatacopy(freememstart, 0, calldatasize())
            let success := delegatecall(not(0), addr, freememstart, calldatasize(), freememstart, 32)
            switch success
            case 0 { revert(freememstart, 32) }
            default { return(freememstart, 32) }
        }
    }    
}