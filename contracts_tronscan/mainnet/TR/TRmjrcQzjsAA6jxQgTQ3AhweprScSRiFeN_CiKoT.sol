//SourceUnit: BlackListableToken.sol

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./ITRC20.sol";
import "./Ownable.sol";
import "./TRC20Token.sol";

contract BlackListableToken is Ownable, TRC20Token {

    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    mapping (address => bool) public isBlackListed;

    function addBlackList(address _evilUser) public onlyOwner {
        require(!isBlackListed[_evilUser], "_evilUser is already in black list");

        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        require(isBlackListed[_clearedUser], "_clearedUser isn't in black list");

        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds(address _blackListedUser) public onlyOwner {
        require(_blackListedUser != address(0x0), "_blackListedUser is the zero address");
        require(isBlackListed[_blackListedUser], "_blackListedUser isn't in black list");

        uint256 dirtyFunds = balanceOf(_blackListedUser);
        super._burn(_blackListedUser, dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address indexed _blackListedUser, uint256 _balance);

    event AddedBlackList(address indexed _user);

    event RemovedBlackList(address indexed _user);

}


//SourceUnit: CiKoT.sol

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./ITRC20.sol";
import "./Ownable.sol";
import "./TRC20Token.sol";
import "./TRC20Detailed.sol";
import "./BlackListableToken.sol";


contract CiKoT is TRC20Token, TRC20Detailed, BlackListableToken {

    string public constant TokenName = "CiKoT";
    string public constant TokenSymbol = "CKT";
    uint8 public constant TokenDecimals = 18;

    constructor () public TRC20Detailed(TokenName, TokenSymbol, TokenDecimals) {
        _mint(msg.sender, 100000000000 * (10 ** uint256(decimals())));
    }
}


//SourceUnit: ITRC20.sol

pragma solidity ^0.5.0;

interface ITRC20 {

   function totalSupply() external view returns (uint);

   function balanceOf(address account) external view returns (uint);

   function transfer(address recipient, uint amount) external returns (bool);

   function allowance(address owner, address spender) external view returns (uint);

   function approve(address spender, uint amount) external returns (bool);

   function transferFrom(address sender, address recipient, uint amount) external returns (bool);

   event Transfer(address indexed from, address indexed to, uint value);

   event Approval(address indexed owner, address indexed spender, uint value);
}


//SourceUnit: Ownable.sol

pragma solidity ^0.5.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint) {
        require(a + b >= a);
        return a + b;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        //require(a == b * c + a % b)
        return c;
    }

    function mod(uint a, uint b) internal pure returns (uint) {
        require(b != 0);
        return a % b;
    }
}


//SourceUnit: TRC20Detailed.sol

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./ITRC20.sol";
import "./Ownable.sol";


contract TRC20Detailed is ITRC20 {
   string private _name;
   string private _symbol;
   uint8 private _decimals;


   constructor(string memory name, string memory symbol, uint8 decimals) public {
       _name = name;
       _symbol = symbol;
       _decimals = decimals;
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
}


//SourceUnit: TRC20Token.sol

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./ITRC20.sol";
import "./Ownable.sol";


contract TRC20Token is ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}