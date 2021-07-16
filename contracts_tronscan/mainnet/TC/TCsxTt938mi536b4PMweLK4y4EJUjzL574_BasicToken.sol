//SourceUnit: basic_token.sol

pragma solidity >=0.5.9;

import './trc20.sol';

contract BasicToken is TRC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowance;

    address public owner;

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address guy) public view returns (uint) {
        return _balances[guy];
    }

    function allowance(address src, address guy) public view returns (uint) {
        return _allowance[src][guy];
    }

    event Burn(address indexed from, uint256 value);

    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
        owner = msg.sender;
        _totalSupply = initialSupply * 10 ** uint256(decimals);
        _balances[owner] = _totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address src, address dst, uint wad) internal returns (bool) {
        require(dst != address(0));
        require(_balances[src] >= wad);
        require(_balances[dst] + wad >= _balances[dst]);
        uint previousBalances = _balances[src] + _balances[dst];
        _balances[src] -= wad;
        _balances[dst] += wad;
        emit Transfer(src, dst, wad);
        assert(_balances[src] + _balances[dst] == previousBalances);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
       return  _transfer(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public returns (bool success) {
        require(wad <= _allowance[src][msg.sender]);
        _allowance[src][msg.sender] -= wad;
        _transfer(src, dst, wad);
        return true;
    }

    function approve(address guy, uint256 wad) public
        returns (bool success) {
        _allowance[msg.sender][guy] = wad;
        return true;
    }

    function burn(uint256 wad) public returns (bool success) {
        require(_balances[msg.sender] >= wad);
        _balances[msg.sender] -= wad;
        _totalSupply -= wad;
        emit Burn(msg.sender, wad);
        return true;
    }

    function burnFrom(address src, uint256 wad) public returns (bool success) {
        require(_balances[src] >= wad);
        require(wad <= _allowance[src][msg.sender]);
        _balances[src] -= wad;
        _allowance[src][msg.sender] -= wad;
        _totalSupply -= wad;
        emit Burn(src, wad);
        return true;
    }
}

//SourceUnit: trc20.sol

/// TRC20.sol -- API for the TRC20 token standard

// See <https://github.com/tronprotocol/tips/blob/master/tip-20.md>.

// This file likely does not meet the threshold of originality
// required for copyright to apply.  As a result, this is free and
// unencumbered software belonging to the public domain.

pragma solidity >=0.5.9;

contract TRC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract TRC20 is TRC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}