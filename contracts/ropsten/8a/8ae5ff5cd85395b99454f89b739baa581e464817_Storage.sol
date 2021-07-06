/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    struct ObjectString {
        string stringOne;
        string stringTwo;
        string stringThree;
        string stringFour;
        string stringFive;
    }
    
    ObjectString o;
    
    string stringSingle;
    
    address addrString;
    
    bytes32 bytesString;

    /**
     * @dev Store value in variable
     */
    function store(string memory strOne, string memory strTwo, string memory strThree, string memory strFour, string memory strFive ) public {
    
        o.stringOne = strOne;
        o.stringTwo = strTwo;
        o.stringThree = strThree;
        o.stringFour = strFour;
        o.stringFive = strFive;
        
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (ObjectString memory){
        return o;
    }
    
    
    function storeSingle(string memory strSingle) public {
        stringSingle = strSingle;
        
    }
    
    function retrieveSingle() public view returns (string memory){
        return stringSingle;
    }
    
    
    function storeAddr(address addr) public {
        addrString = addr;
    }
    
    function retrieveAddr() public view returns (address){
        return addrString;
    }
    
    
    function storeBytes(bytes32 b) public {
        bytesString = b;
    }
    
        function retrieveBytes() public view returns (bytes32){
        return bytesString;
    }
    

}