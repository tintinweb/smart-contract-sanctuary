/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


interface ERC20 {
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

interface IAPN {
    /**
    Method to claim APN on native Apini chain,
    After calling this method _value of BEP-20 token will be burned from msg.sender address 
    and eventually deposited on native apini _pubkey wallet.
    Any execution after 01.01.2023 might be not respected
    */
    function claim(bytes32 _pubkey, uint256 _value) external returns (bool success);
    
    event ClaimEvent(bytes32 _pubkey, uint256 _value);
}

contract APN is ERC20, IAPN {
    string constant _name = "apini.io";
    string constant _symbol = "APN";
    uint8 constant _decimals = 18;
    
    uint256 constant _maxSupply = 7_275_000 ether;
    uint256 private supply = _maxSupply;
    
    mapping(address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    
    constructor() {
        balances[msg.sender] = _maxSupply;
        emit Transfer(address(0), msg.sender, _maxSupply);
    }
    
    function name() public pure override returns (string memory) {
        return _name;
    }
    
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns(uint256) {
        return supply;
    }
    
    function balanceOf(address _owner) public view override returns(uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
    
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function claim(bytes32 _pubkey, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        supply -= _value;
        emit Transfer(msg.sender, address(0), _value);
        emit ClaimEvent(_pubkey, _value);
        return true;
    }
}