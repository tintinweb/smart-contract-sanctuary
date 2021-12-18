/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// MIT
pragma solidity 0.8.10;

contract VToken {

    constructor (){
    name_ = "VToken";
    symbol_="VTX";
    decimals_= 0;
    tsupply = 1000;
    balances[msg.sender] = 1000; //deployer
    }

    string name_ ;
    function name() public view returns (string memory){
    return name_;
    }
    string symbol_;
    function symbol() public view returns (string memory){
        return symbol_;
    }
    uint8 decimals_;
    function decimals() public view returns (uint8){
        return decimals_;
    }
    uint256 tsupply;
    function totalSupply() public view returns (uint256) {
        return tsupply;
    }
    mapping (address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _valiue);

    function transfer (address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender] >= _value, "Insufficient Balance");
        balances[msg.sender] -= _value; // original balance of sender is being reduced by _value : a = a+1, a+=1
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

}