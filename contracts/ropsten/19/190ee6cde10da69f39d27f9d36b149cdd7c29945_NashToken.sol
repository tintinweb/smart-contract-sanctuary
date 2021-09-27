/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract NashToken {
    string  public name = "NAsh Token";
    string  public symbol = "NASH";
    string  public standard = "NAsh Token v1.0";
    uint256 public totalSupply;


       event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
       event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );


mapping(address=> uint256) public balanceOf;
    constructor() public {
        
        totalSupply = 1000000 ;
    }

//transfer token one account to another from your account only 
  function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
 //transfer token one to another on behalf of other    
//   function approve(address _spender, uint256 _value) public returns (bool success) {
//         allowance[msg.sender][_spender] = _value;

//       emit Approval(msg.sender, _spender, _value);

//         return true;
//     }

}
        
 

    

//     mapping(address => uint256) public balanceOf;
//     mapping(address => mapping(address => uint256)) public allowance;

//     constructor (uint256 _initialSupply) public{
//         balanceOf[msg.sender] = _initialSupply;
//         totalSupply = _initialSupply;
//     }

  
 

//     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
//         require(_value <= balanceOf[_from]);
//         require(_value <= allowance[_from][msg.sender]);

//         balanceOf[_from] -= _value;
//         balanceOf[_to] += _value;

//         allowance[_from][msg.sender] -= _value;

//         Transfer(_from, _to, _value);

//         return true;
//     }
// }