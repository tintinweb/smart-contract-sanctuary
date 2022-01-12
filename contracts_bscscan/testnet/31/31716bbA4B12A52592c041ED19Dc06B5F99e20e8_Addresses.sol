/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.0;

contract Addresses {
    
    mapping(uint16=>address) private addresses;
    
    //-----------------------------------------
    //  modifiers
    //-----------------------------------------
    modifier onlyManager() { require( checkManger(msg.sender) , "This address is not manager" ); _; }
    
    //-----------------------------------------
    //  pureFunctions
    //-----------------------------------------
    function checkManger(address _addr) public view returns ( bool ) {
        for( uint8 i = 0 ; i<10; i++ ) {
            if ( addresses[i] == _addr ) {
                return true;
            }     
        }   
        return false;
    }
    
    constructor() {
        addresses[0] = msg.sender;
    }
    
    function setAddress(uint16 _index,address _addr) external payable onlyManager {
        addresses[_index] = _addr;
    }

    function setAddresses(uint16[] memory _index, address[] memory _addr) external payable onlyManager {
        require(_index.length == _addr.length,"not same _index,_addr length");
        for ( uint16 i =0; i<_index.length; i++) {
            addresses[_index[i]] = _addr[i];
        }
    }
    
    function viewAddress(uint16 _index) external view returns (address) {
        return addresses[_index];
    }
}