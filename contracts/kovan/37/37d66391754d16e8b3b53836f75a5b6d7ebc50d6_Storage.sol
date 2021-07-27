/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

   address private owner;
    
    string [540] ruku;
    
    
                    //Contract Security 
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
      constructor() {
        owner = msg.sender; 
        emit OwnerSet(address(0), owner);
    }
        
        function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }
   
                    //Store Quran by Ruku
   
    function store(string  memory _data, uint256 _index) public isOwner{
        ruku[_index] = _data;
    }

   
   function ruku_0() public view returns (string memory){
        return ruku[0];
    }
    
    function ruku_1() public view returns (string memory){
        return ruku[1];
    }
}