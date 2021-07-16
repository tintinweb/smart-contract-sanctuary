//SourceUnit: Agate.sol

pragma solidity ^0.5.8;

import "./SafeMath.sol";
import "./BaseTRC20.sol";

contract AgateNetwork is BaseTRC20, Ownable {
    using SafeMath for uint;

    struct Record {
        uint256 total;
        uint256 minted;
    }

    uint64 private _mintRemain = 5e12;
    mapping(address => Record) private minters;

    event SetMinter(address indexed from, address indexed to, uint256 indexed addation, uint256 total);

    constructor () BaseTRC20("Agate Network", "AGA", 6) public {

    }

    function setName(string calldata str) onlyOwner external returns(bool) {
        _setName(str);
        return true;
    }

    function setSymbol(string calldata str) onlyOwner external returns(bool) {
        _setSymbol(str);
        return true;
    }

    function setMinter(address _minter, uint256 _amount) onlyOwner external returns(uint256){
        (uint256 total, uint256 minted) = mintInfo(_minter);
        total = _amount.max(minted);
        require(total > 0 && total <= _mintRemain, "total overflows");
        minters[_minter] = Record(total, minted);
        emit SetMinter(msg.sender, _minter, _amount, total);
        return total;
    }

    function mint(address _to, uint256 _amount) external returns(uint256){
        require(_amount < 2**64, "_amount overflows");
        (uint256 total, uint256 minted) = mintInfo(_to);

        uint256 remain = uint256(_mintRemain);
        uint256 trueAmount = _amount.min(total.sub(minted));
        trueAmount = trueAmount.min(remain);
        if (trueAmount > 0){
            _mintRemain -= uint64(trueAmount);
            minters[_to] = Record(total, trueAmount + minted);
            _mint(_to, trueAmount);
        }
        return trueAmount;
    }

    function mintInfo(address _minter) public view returns(uint256 total, uint256 minted){
        Record memory data = minters[_minter];
        return (data.total, data.minted);
    }

    function mintRemain() public view returns (uint) {
        return uint(_mintRemain);
    }
}



//SourceUnit: BaseTRC20.sol

pragma solidity ^0.5.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract BaseTRC20 is MintERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    uint private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function _setName(string memory str) internal {
        _name = str;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function _setSymbol(string memory str) internal {
        _symbol = str;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        emit Mint(msg.sender, account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}



//SourceUnit: IERC20.sol

pragma solidity >= 0.4.24;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract MintERC20 is IERC20 {
    event Mint(address indexed caller, address indexed to, uint256 value);

    function mint(address to, uint256 amount) external returns(uint256);
}

//SourceUnit: Ownable.sol

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SourceUnit: SafeMath.sol

pragma solidity >= 0.4.24;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");
        return c;
    }

    function mul(uint256 a, uint256 b, string memory errMsg) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errMsg);
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function div(uint256 a, uint256 b, string memory errMsg) internal pure returns (uint256) {
        require(b > 0, errMsg); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a - b;
        require(c <= a, "SafeMath#sub: UNDERFLOW");
        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b, string memory errMsg) internal pure returns (uint256) {
        uint256 c = a - b;
        require(c <= a, errMsg);
        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b, string memory errMsg) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errMsg);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b, string memory errMsg) internal pure returns (uint256) {
        require(b != 0, errMsg);
        return a % b;
    }

    /**
     * @dev Returns the minimum of a and b
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256 z) {
        z = a <= b ? a : b;
    }

    /**
     * @dev Returns the maximum value in a and b
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256 z) {
        z = a >= b ? a : b;
    }

    /**
    * @dev Check the value is excatly uint32
    * reverts when >= 2**32.
    */
    function safe32(uint n) internal pure returns (uint32) {
        require(n < 2**32, "SafeMath#safe32: OVERFLOW");
        return uint32(n);
    }

    /**
    * @dev Check the value is excatly uint32
    * reverts when >= 2**32.
    */
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /**
    * @dev Check the value is excatly uint96
    * reverts when >= 2**96.
    */
    function safe96(uint n) internal pure returns (uint96) {
        require(n < 2**96, "SafeMath#safe96: OVERFLOW");
        return uint96(n);
    }

    /**
    * @dev Check the value is excatly uint96
    * reverts when >= 2**96.
    */
    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    /**
    * @dev Check the value is excatly uint112
    * reverts when >= 2**112.
    */
    function safe112(uint n) internal pure returns (uint112) {
        require(n < 2**112, "SafeMath#safe112: OVERFLOW");
        return uint112(n);
    }

    /**
    * @dev Check the value is excatly uint112
    * reverts when >= 2**112.
    */
    function safe112(uint n, string memory errorMessage) internal pure returns (uint112) {
        require(n < 2**112, errorMessage);
        return uint112(n);
    }
}