/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    bool number;
    bytes32 byteStr= 0x7465737400000000000000000000000000000000000000000000000000000000;
    
    event Deposit(address indexed _from, bytes32 indexed _id, uint _value);
    /**
     * @dev Store value in variable
     * @param temp value to store
     */
     
    function store(bool temp) public returns(address){
        number = temp;
        return(msg.sender);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve () public view returns (bool){
        return number;
    }
    
    function multipleRetrieve() public view returns (bool, uint256, address,bytes32,bytes16) {
        
        return (number, 1, msg.sender,0x7465737400000000000000000000000000000000000000000000000000000000, 0x74657374000000000000000000000000);
    }
    
     
   function deposit(bytes32 _id) public payable {      
      emit Deposit(msg.sender, _id, msg.value);
   }
}