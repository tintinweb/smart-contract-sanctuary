/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

pragma solidity >= 0.7.0;

// -------------------------------------------------------------------
// BTM token main contract (2021)
// 
// Symbol       : BTM
// Name         : ByTime
// Total supply : 1.000.000 (burnable)
// Decimals     : 18
// -------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// -------------------------------------------------------------------

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Ownable {
    event Pause(address indexed from);
    event Unpause(address indexed from);

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause(msg.sender);
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause(msg.sender);
    }
}

library SafeMath {
  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
}

contract BTM is IERC20, Ownable, Pausable {
    using SafeMath for uint;

    string  private constant _name        = "ByTime";
    string  private constant _symbol      = "BTM";
    string  private constant _version     = "ByTime v0.0.1";
    uint256 private          _totalSupply = 1_000_000E18; // 1 million tokens
    uint8   private constant _decimals    = 18;

    mapping (address => uint256)                   private _balanceOf;
    mapping (address => mapping (address => uint)) private _allowances;

    constructor() {
        _balanceOf[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _value) external override whenNotPaused returns (bool success) {
        require(balanceOf(msg.sender) >= _value);

        _balanceOf[msg.sender] -= _value;
        _balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external override whenNotPaused returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override whenNotPaused returns (bool success) {
        require(balanceOf(_from)             >=_value);
        require(allowance(_from, msg.sender) >=_value);

        _balanceOf[_from] -= _value;
        _balanceOf[_to]   += _value;
        _allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function burnTokens(uint amount) external onlyOwner returns (bool success) {
        require(amount < _balanceOf[msg.sender], "BTM::burnTokens: exceeds available amount");

        _balanceOf[owner] = _balanceOf[owner].safeSub(amount);
        _totalSupply      = _totalSupply.safeSub(amount);

        emit Transfer(owner, address(0), amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint) {
        return _balanceOf[account];
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    function version() external pure returns (string memory) {
        return _version;
    }
}