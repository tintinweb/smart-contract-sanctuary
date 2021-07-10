/**
 *Submitted for verification at polygonscan.com on 2021-07-09
*/

// SPDX-License-Identifier: Unlinced

pragma solidity >=0.7.0 <0.9.0;

contract poopToken {
    
    //Warning: This token has many BUGS. Please don't consider it as a real financial token.
    
    string public name = unicode"💩";
    string public symbol = unicode"💩";
    uint8 public decimals = 18;
    uint256 public totalSupply = Ton * 10 ** uint256(decimals);
    uint public Ton = 1;

    mapping (address => uint256) public balanceOf;
    //IDK how to code allowance, so I left it. You can transfer the token from anyone else.
    
    event Transfer(address indexed from, address indexed to, uint256 _value);
    event Mint(address indexed from, uint256 _amount);
    event Flush(address indexed from, uint256 _amount);

    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    
    }

    function mint(uint256 _value) public returns (bool success){
        balanceOf[msg.sender] += _value;
        totalSupply += _value;
        emit Mint(msg.sender, _value);
        return true;
    }
    
    function flush(uint256 _value) public returns (bool success){
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Flush(msg.sender, _value);
        return true;
    }

}