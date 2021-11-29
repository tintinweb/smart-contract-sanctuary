/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity 0.5.0;

contract XToken{

    string name_;
    string symbol_;
    uint8 decimals_;
    uint256 tsupply;

    constructor(uint256 _tsupply) public {
        tsupply = _tsupply;
        name_ = "XToken";
        symbol_ = "XNT0";
        decimals_ = 0;
        balances[msg.sender] = tsupply; // deployer
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
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender]>= _value, "Not enough tokens to send");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

}