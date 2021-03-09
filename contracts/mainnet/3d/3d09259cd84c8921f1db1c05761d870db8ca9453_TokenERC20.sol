/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity ^0.5.0;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenERC20 is IERC20 {
    using SafeMath for uint256;
    
    address public _owner;
    string private _name = "Bensonas";
    string private _symbol = "BNS";
    uint8 private _decimals = 8;
    uint256 private _totalSupply = 558000000000000;
	uint256 private _blockNumberStart = 0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor () public {
		_owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        _blockNumberStart = block.number;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function blockNumberStart() public view returns (uint256) {
        return _blockNumberStart;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        _unlockTokens();
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

	function burn(uint256 value) public {
        require(msg.sender != address(0), "ERC20: burn from the zero address");
        require(_owner == msg.sender, "ERC20: burn only owner address");

        _totalSupply = _totalSupply.sub(value);
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        emit Transfer(msg.sender, address(0), value);
    }
    
    function _mint(uint256 value) internal {
        _totalSupply = _totalSupply.add(value);
        _balances[_owner] = _balances[_owner].add(value);
        emit Transfer(address(0), _owner, value);
    }
    
    bool private _unlockTeam = true;
    bool private _unlockDao = true;
    uint256 private _daoTotal = 900000000000000;
    uint256 private _daoTotalUnloked = 0;

    function _unlockTokens() internal {
      // Unlocking team tokens after year (2425846 blocks after start, 1 block = 13 sec)
      if(_unlockTeam && block.number >= _blockNumberStart + 2425846){
        _unlockTeam = false;
        _mint(342000000000000);
      }

      // Unlock DAO, 5% per 6 month (1212923 blocks = 6 month, 1 block = 13 sec)
      if(_unlockDao){
        uint256 _amountToUnlock = 45000000000000;
        uint256 _amountTotalUnlocked = 0;

        for (uint i=1; i<=20; i++) {
          uint256 _blockNumberToUnlock = _blockNumberStart + (1212923 * i);
          if(block.number >= _blockNumberToUnlock){
            _amountTotalUnlocked = _amountTotalUnlocked.add(_amountToUnlock);
            if(_daoTotalUnloked < _amountTotalUnlocked){
              _daoTotalUnloked = _daoTotalUnloked.add(_amountToUnlock);
              _mint(_amountToUnlock);
            }
          }
        }

        if(_daoTotal == _daoTotalUnloked){
          _unlockDao = false;
        }
      }
    }
}