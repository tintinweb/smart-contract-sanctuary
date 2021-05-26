/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/ERC20.sol

pragma solidity ^0.8.0;



/**
 * @title ERC20
 * @dev Create and manage ERC20 standard tokens
 */
 
 contract CustomERC20 is IERC20, Pausable{
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    address public owner;
    address public minter;
    address public pauser;
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    
    constructor(address minterAddress, address pauserAddress) {
        _name = "CustERC20Token";
        _symbol = "CERC";
        _totalSupply = 10000;
        _balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        minter = minterAddress;
        pauser = pauserAddress;
    }
    
    function name() public view returns(string memory){
        return _name;
    }
    
    function symbol() public view returns(string memory){
        return _symbol;
    }
    /**
    * @dev Returns the value of {_totalSupply}
    * totalSupply function
    */
    function totalSupply() public view override returns(uint256){
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns(uint256){
        return _balances[account];
    }
    
    function allowance(address provider, address account) public view override returns(uint256){
        return _allowances[provider][account];
    }
    
    function pause() public returns(bool){
        require(msg.sender == pauser || msg.sender == owner, "Only Pauser or Owner can Mint Tokens");
        _pause();
        return true;
    }
    function unPause() public returns(bool){
        require(msg.sender == pauser || msg.sender == owner, "Only Pauser or Owner can Mint Tokens");
        _unpause();
        return true;
    }
    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address receiver, uint256 amount) public override whenNotPaused returns(bool){
        _transfer(sender,receiver,amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    function mint(address toAddress, uint256 amount) public whenNotPaused whenNotPaused returns (bool) {
        _mint(toAddress, amount);
        return true;
    }
    function burn(address fromAddress, uint256 amount) public whenNotPaused returns (bool) {
        _burn(fromAddress, amount);
        return true;
    }

    function _transfer(address fromAddress, address toAddress, uint256 amount) internal whenNotPaused returns(bool){
        require(_balances[fromAddress] >= amount, "Insufficient balance.");
        require(toAddress != address(0), "Invalid address given.");
        _balances[fromAddress] = _balances[fromAddress] - (amount); 
        _balances[toAddress] = _balances[toAddress] + (amount); 
        emit Transfer(fromAddress, toAddress, amount);
        return true;
    }
    function _approve(address provider, address spender, uint256 amount) internal whenNotPaused {
        require(provider != address(0), "Invalid address");
        require(spender != address(0), "Invalid address");

        _allowances[provider][spender] = amount;
        emit Approval(provider, spender, amount);
    }
    function _mint(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), "Zero address given");
        require(msg.sender == minter || msg.sender == owner, "Only Minter or Owner can Mint Tokens");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), "Zero address");
        require(msg.sender == minter || msg.sender == owner, "Only Minter or Owner can Burn Tokens");
        
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
}