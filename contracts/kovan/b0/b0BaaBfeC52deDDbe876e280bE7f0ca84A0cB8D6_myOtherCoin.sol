/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity ^0.8.8;

contract myOtherCoin {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public total_supply;
    
    
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _total_supply) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    total_supply = _total_supply;
    balanceOf[msg.sender] = total_supply;
    }
    
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        transfer(msg.sender, _to, _value );
        return true;
    }
    
    function transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] =balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value );
    }

}