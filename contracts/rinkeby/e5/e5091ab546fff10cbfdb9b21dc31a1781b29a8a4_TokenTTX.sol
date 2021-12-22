/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

pragma solidity 0.8.0;
contract TokenTTX{
        string Name;
        string symbol;
        uint256 Number;
        uint256 tsupply;
        mapping(address=>uint256)balances;
    constructor(uint256 _qty)public{
        tsupply=_qty;
        balances[msg.sender]=tsupply;
        Name="Tech";
        symbol="TTX";
        Number=0;
    }  
    function nameOfToken ()public view returns(string memory){
        return Name;
    }
    function symbolOfToken ()public view returns(string memory){
        return symbol;
    }
    function numberOfToken ()public view returns(uint256){
        return Number;
    }
    function tsupplyOfToken ()public view returns(uint256){
        return tsupply;
    }
    function balancesOf(address _owner) public view returns(uint256 balance){
        return balances[_owner];
    }
    event Transfer(address indexed _from,address indexed _to,uint256 value);
    function transferOfToken(address _to,uint256 value) public returns(bool Sucess){
        balances[msg.sender]-=value;
        balances[_to]+=value;
        emit Transfer(msg.sender,_to,value);
        return true;
    }
}