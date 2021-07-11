/**
 *Submitted for verification at Etherscan.io on 2021-07-11
*/

pragma solidity ^0.5.0;

contract Token {

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

  

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

   
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}