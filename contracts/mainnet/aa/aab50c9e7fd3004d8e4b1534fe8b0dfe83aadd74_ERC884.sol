/**
 *Submitted for verification at Etherscan.io on 2020-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

abstract contract ERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    
    uint256 _totalSupply;
    uint256 funds;
    uint8 decimals;
    
    uint256 dateDeploy;
    uint256 blockYears;
    
    address owner;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) alloweds;

    constructor () {
        name = "iZiFoodToken";
        symbol = "IZFO";
        _totalSupply = 1000000;
        funds = 510000;
        decimals = 0;
        owner = msg.sender;
        balances[owner] = _totalSupply - funds;
        dateDeploy = block.timestamp;
        blockYears = dateDeploy + 730 days;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can use this function");
        _;
    }
    
    modifier blockedTime {
        require(block.timestamp >= blockYears, "This funds are blocked for 2 years");
        _;
    }
    
    function totalSupply () public view returns (uint256 total) {
        return _totalSupply;
    }
    
    function balanceOf (address _address) public view returns (uint256 balance) {
        require(_address != address(0x0));
        return balances[_address];
    }
    
    function transfer(address _to, uint256 _value) public virtual returns (bool success) {
        require(_to != msg.sender, "Can't send tokens to the same address");
        require(_to != address(0x0), "Can't send to a null address");
        require(_value > 0, "Can't send a negative amount of tokens");
        require(balances[msg.sender] >= _value, "Insufficient balance");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] =  balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != msg.sender, "Can't approve tokens to the same address");
        require(balances[msg.sender] >= _value,"Insufficient amount of tokens");
        require(_spender != address(0x0),"Can't approve a null address");

        alloweds[msg.sender][_spender] = alloweds[msg.sender][_spender].add(_value);

        emit Approval(msg.sender, _spender, _value);

        return true;
    }
    
    function disapprove(address _spender, uint256 _value) public returns (bool success){
        require(alloweds[msg.sender][_spender] >= _value, "Can't disapprove more than the approved");
        require(_spender != address(0x0), "Can't disapprove a null address");

        alloweds[msg.sender][_spender] = alloweds[msg.sender][_spender].sub(_value);

        emit Desapproval(msg.sender, _spender, _value);

        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success) {
        require(balances[_from] >= _value,"Insufficient balance");
        require(alloweds[_from][msg.sender] >= _value,"Insufficient allowance");
        require(_value > 0,"Can't send a negative amount of tokens");
        require(_to != address(0x0),"Can't send to a null address");
        require(_from != address(0x0),"Can't send from a null address");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        alloweds[_from][msg.sender] =  alloweds[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }
    
    function requestFunds() public onlyOwner blockedTime returns (bool success) {
        require(funds > 0, "Funds have already been transferred");

        balances[owner] = balances[owner].add(funds);
        funds = 0;
        
        return true;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Desapproval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC884 is ERC20 {
    mapping(address => bytes32) private verified;
    mapping(address => address) private cancellations;
    mapping(address => uint256) private holderIndices;
    
    address[] private shareholders;
    
    modifier isVerifiedAddress(address _addr) {
        require(verified[_addr] != bytes32(0), "The address isn't in verified list");
        _;
    }

    modifier isShareholder(address _addr) {
        require(holderIndices[_addr] != 0, "The address isn't in a shareholder");
        _;
    }

    modifier isNotShareholder(address _addr) {
        require(holderIndices[_addr] == 0, "The address is a shareholder");
        _;
    }

    modifier isNotCancelled(address _addr) {
        require(cancellations[_addr] == address(0x0));
        _;
    }
    
    function addVerified(address _addr, bytes32 _hash) public onlyOwner isNotCancelled(_addr) {
        require(_addr != address(0x0), "Can't add a null address");
        require(_hash != bytes32(0), "Can't set a null hash");
        require(verified[_addr] == bytes32(0), "Can't add same address");
        
        verified[_addr] = _hash;
        
        emit VerifiedAddressAdded(_addr, _hash, msg.sender);
    }

    function removeVerified(address _addr) public onlyOwner {
        require(_addr != address(0x0), "Can't remove a null address");
        require(balances[_addr] == 0, "Can't remove an address that has tokens");
        
        if(verified[_addr] != bytes32(0)) {
            verified[_addr] = bytes32(0);
            emit VerifiedAddressRemoved(_addr, msg.sender);
        }
    }
    
    function updateVerified(address _addr, bytes32 _hash) public onlyOwner isVerifiedAddress(_addr) {
        require(_hash != bytes32(0), "The hash is required");
        
        bytes32 oldHash = verified[_addr];
        
        if(oldHash != _hash) {
            verified[_addr] = _hash;
            emit VerifiedAddressUpdated(_addr, oldHash, _hash, msg.sender);
        }
    }
    
    function cancelAndReissue(address _original, address _replacement) public onlyOwner isShareholder(_original) isNotShareholder(_replacement) isVerifiedAddress(_replacement) returns (bool success) {
        verified[_original] = bytes32(0);
        cancellations[_original] = _replacement;

        uint256 holderIndex = holderIndices[_original] - 1;
        shareholders[holderIndex] = _replacement;

        holderIndices[_replacement] = holderIndices[_original];
        holderIndices[_original] = 0;

        balances[_replacement] = balances[_original];
        balances[_original] = 0;

        emit VerifiedAddressSuperseded(_original, _replacement, msg.sender);

        return true;
    }

    function transfer(address _to, uint256 _value) override public isVerifiedAddress(_to) returns (bool success) {
        updateShareholders(_to);
        pruneShareholders(msg.sender, _value);
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) override public isVerifiedAddress(_to) returns (bool success) {
        updateShareholders(_to);
        pruneShareholders(_from, _value);
        return super.transferFrom(_from, _to, _value);
    }
    
    function isVerified(address _addr) public view returns (bool verifiedAddress) {
        require(_addr != address(0x0), "Can't verify a null address");
        
        return verified[_addr] != bytes32(0);
    }

    function isHolder(address _addr) public view returns (bool holder) {
        require(_addr != address(0x0), "Can't verify a null address");
        
        return holderIndices[_addr] != 0;
    }

    function hasHash(address _addr, bytes32 _hash) public view returns (bool hash) {
        require(_addr != address(0x0), "Can't verify a null address");
        require(_hash != bytes32(0), "Can't verify a null hash");

        if (_addr == address(0x0)) {
            return false;
        }

        return verified[_addr] == _hash;
    }

    function holderCount() public view returns (uint256 totalHolders) {
        return shareholders.length;
    }

    function holderAt(uint256 _index) public view onlyOwner returns (address holder) {
        require(_index < shareholders.length, "The index must be less than the size of the array");

        return shareholders[_index];
    }

    function isSuperseded(address addr) public view onlyOwner returns (bool superseded) {
        return cancellations[addr] != address(0x0);
    }

    function getCurrentFor(address _addr) public view onlyOwner returns (address) {
        return findCurrentFor(_addr);
    }

    function findCurrentFor(address _addr) internal view returns (address) {
        address candidate = cancellations[_addr];
        if (candidate == address(0x0)) {
            return _addr;
        }
        return findCurrentFor(candidate);
    }
    
    function updateShareholders(address _addr) internal {
        if (holderIndices[_addr] == 0) {
            shareholders.push(_addr);
            holderIndices[_addr] = shareholders.length;
        }
    }
    
    function pruneShareholders(address _addr, uint256 _value) internal {
        uint256 balance = balances[_addr] - _value;

        if (balance > 0) {
            return;
        }
        uint256 holderIndex = holderIndices[_addr] - 1;
        uint256 lastIndex = shareholders.length - 1;

        address lastHolder = shareholders[lastIndex];

        shareholders[holderIndex] = lastHolder;
        holderIndices[lastHolder] = holderIndices[_addr];

        shareholders.pop();
        holderIndices[_addr] = 0;
    }

    event VerifiedAddressAdded(address indexed _addr, bytes32 _hash, address indexed _sender);

    event VerifiedAddressRemoved(address indexed _addr, address indexed _sender);
    
    event VerifiedAddressUpdated(address indexed _addr, bytes32 _oldHash, bytes32 _hash, address indexed _sender);
    
    event VerifiedAddressSuperseded(address indexed _original, address indexed _replacement, address indexed _sender);
}