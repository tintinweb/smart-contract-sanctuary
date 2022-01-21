/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

pragma solidity 0.5.0;

contract ERC20 {

    // ERC20 token.

    string name_ ;
    string symbol_;
    uint8 decimals_;
    uint256 tsupply;
    constructor (string memory _name, string memory _symbol,
    uint8 _decimals, uint256 _tsupply) public {
        name_ = _name;
        symbol_ = _symbol;
        decimals_= _decimals;
        tsupply = _tsupply;
    }
    function name() public view returns (string memory) {
        return name_;
    }
    function symbol() public view returns (string memory){
        return symbol_;
    }
    function decimals() public view returns (uint8) {
        return decimals_;
    }
    function totalSupply() public view returns (uint256) {
        return tsupply;
    }
    mapping (address => uint256) balances;
    function balanceOf(address _to) public view returns (uint256 balance){
        require(_to!= address(0), "Invalid address" );
        return balances[_to];
    }
    event Transfer(address indexed Sender, address indexed To, uint256 NumToken);
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender]>=_value, "Insufficient tokens");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
 
}

contract AleemToken is ERC20 {

    constructor () ERC20("AleemToken","ALX",0,1000) public{
        balances[msg.sender] = tsupply;
       
    }

}