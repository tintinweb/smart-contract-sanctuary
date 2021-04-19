/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

pragma solidity =0.6.0;

contract TavCoin {
    
    address owner;
    string name;
    string symbol;
    uint256 totalTavcoins;
    
    mapping (address => uint256) public balance;

    constructor (string memory _name, string memory _symbol, uint _totalTavcoins) public {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        totalTavcoins = _totalTavcoins;
        balance[owner] = totalTavcoins;
    }
    
    event Transfer (address indexed _from, address indexed _to, uint256 _value);
    
    function totalSupply() view public returns (uint256){
        return totalTavcoins;
    }
    
    function balanceOf (address _owner) view public returns (uint256){
        return balance[_owner];
    }
    
    function transfer (address _to, uint256 _value) public returns (bool){
        require (balance[msg.sender]> _value);
        address _from = msg.sender;
        owner = _to;
        emit Transfer(_from, _to, _value);
        balance[_from] = balance[_from] - _value;
        balance[_to] = balance[_to] + _value;
        return true;
        
        }
}