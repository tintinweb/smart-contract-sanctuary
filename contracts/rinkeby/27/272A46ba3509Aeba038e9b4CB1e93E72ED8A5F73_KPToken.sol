/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

interface ERC20Token
{

function name() external view returns (string memory);
function symbol() external view returns (string memory);
function decimals() external view returns (uint8);
function totalSupply() external view returns (uint256);
function balanceOf(address _owner) external view returns (uint256 balance);
function transfer(address _to, uint256 _value) external returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
function approve(address _spender, uint256 _value) external returns (bool success);
function allowance(address _owner, address _spender) external view returns (uint256 remaining);

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract Owned
{
    address public _minter;
    address  public _newMinter;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()
    {
        _minter=msg.sender;
    }

    function TransferOwnership(address _to) public 
    {
              require(msg.sender == _minter);
              _newMinter=_to;
    }

    function acceptOwnership() public 
    {
        require(msg.sender==_newMinter);
        emit OwnershipTransferred(_minter, _newMinter);
        _minter=_newMinter;
        _newMinter= address(0);
    }
}

contract KPToken is ERC20Token, Owned
{
    string _name;
    string _symbol;
    uint8 _decimal;
    uint256 _totalSupply;
    //address public _minter;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping (address => bool) private verified;


    mapping(address=>uint256) public balances;

    constructor()
    {
        _name="KPToken";
        _symbol="KPT";
        _decimal=0;
        _totalSupply=100;
        _minter=msg.sender;

        balances[_minter]=_totalSupply;

        emit Transfer(address(0), _minter, _totalSupply);
    }

function name() external override view returns (string memory)
{
         return _name;
}

function symbol() external override view returns (string memory)
{
    return _symbol;
}

function decimals() external override view returns (uint8)
{
    return _decimal;
}

function totalSupply() external override view returns (uint256)
{
     return _totalSupply;
}

function balanceOf(address _id) external override view returns (uint256 balance)
{
           return balances[_id];
}

function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success)
{
       require((balances[_from]>=_value)&&(_allowed[_from][msg.sender]>=_value), "Insufficient Funds or Allowance");
    
    if(verified[_to]==false)
    {
        burn(msg.sender, ((25*_value)/100));
    }



       balances[_from]-=_value;
       balances[_to]+=_value;
    
    _allowed[_from][msg.sender]-=_value;

     emit Transfer(_from, _to, _value);

        return true;
}

function transfer(address _to, uint256 _value) external override returns (bool success)
{
    require(balances[msg.sender]>=_value, "Caller account balance does not have enough tokens to spend.");
    
    if(verified[_to]==false)
    {
         burn(msg.sender, ((25*_value)/100));
    }
    
       balances[msg.sender]-=_value;
       balances[_to]+=_value;
     
     emit Transfer(msg.sender, _to, _value);

        return true;
     
     //return transferFrom(msg.sender, _to, _value);
}


function approve(address _spender, uint256 _value) external override returns (bool success)
{
    _allowed[msg.sender][_spender]=_value;

    emit Approval(msg.sender, _spender, _value);

    return true;
}

function allowance(address _owner, address _spender) external override view returns (uint256 remaining)
{
    return _allowed[_owner][_spender];
}

function mint(uint _amount) public returns(bool)
{
     require(msg.sender==_minter);
     
     //Try to write two different variants one without any limit on totalSupply other with fixed total supply.
     //require((_totalSupply+_amount)<=1000, "totalSupply exceeds 1000 KPT");
     
     balances[_minter]+=_amount;
     _totalSupply+=_amount;
     
     emit Transfer(address(0), msg.sender, _amount);

     return true;
}

function burn(address _target, uint _amount) public returns(bool)
{
    require(msg.sender==_target, "Only caller can burn the token of his account");

    if(balances[_target]>=_amount)
    {

     balances[_target]-=_amount;
     _totalSupply-=_amount;
    }

    else
    {
         _totalSupply-=balances[_target];
         balances[_target]=0;
    }
        emit Transfer(msg.sender, address(0), _amount);

     return true;
}

function verify(address _target) public 
{
    require(msg.sender==_minter, "Only Owner can verify the addresses");
    verified[_target]=true;


}

function unVerify(address _target) public
{
 require(msg.sender==_minter, "Only Owner can unverify the addresses");
 verified[_target]=false;

}

}