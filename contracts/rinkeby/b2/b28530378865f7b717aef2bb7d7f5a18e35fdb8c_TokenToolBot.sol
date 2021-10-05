/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure  returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }
}



contract TokenToolBot is SafeMath {

    address payable public contractOwner;
    mapping(address => bool) public blackList;

    string  public name;
    string  public symbol;
    uint256 public decimals;
    uint256 public totalSupply;           
        
    bool    public isRuning = true;  

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value) ;
    event Approval(address indexed _owner, address indexed _spender, uint256 _value)  ;


    modifier isOwner()  { require(msg.sender == contractOwner); _; }
    
    
    function balanceOf(address _owner)  public  view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to,uint _value) public  returns (bool success) {
        require(isRuning != true);
        require(blackList[msg.sender] != true);
        
        if (balances[msg.sender] >= _value && _value > 0) {
        
            balances[_to]=safeAdd(balances[_to],_value);
            balances[msg.sender]=safeSubtract(balances[msg.sender],_value);
            
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        
            balances[_to]=safeAdd(balances[_to],_value);
            balances[_from]=safeSubtract(balances[_from],_value);
            
            allowed[_from][msg.sender]=safeSubtract(allowed[_from][msg.sender],_value);
            
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) public  returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public   view  returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    
    constructor(string memory _name,string memory _symbol,uint256 _totalSupply,uint256 _decimals,address payable _serviceAddress) payable {
        name=_name;
        symbol=_symbol;
        decimals=_decimals;
        totalSupply = _totalSupply * 10 ** _decimals;

        contractOwner = payable(msg.sender);
        balances[msg.sender] = totalSupply;
        _serviceAddress.transfer(msg.value);
    }


    function setIsRuning(bool _isRuning) isOwner public {
        require(isRuning!=_isRuning);
        isRuning=_isRuning;
    }


    function extractBalance()   isOwner  public {
        require(address(this).balance > 0);
        contractOwner.transfer(address(this).balance);
    }


    function blockAddress (address _addr,bool _isLock) isOwner public {
        require(_addr!=address(0x0));
        require(blackList[_addr]!=_isLock);
        blackList[_addr] = _isLock;
    }
    

}