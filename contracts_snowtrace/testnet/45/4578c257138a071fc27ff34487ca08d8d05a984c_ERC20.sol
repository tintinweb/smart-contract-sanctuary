/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: New_contract/sc1.sol


// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;





contract ERC20 is Context, IERC20, IERC20Metadata {
    //ERC20 inherits from Context, IERC20 & IERC20Metadata
    
    //saves the balances of all token holders
    mapping(address => uint256) private _balances; 
    
    //saves the allownace of all token holders
    //an allowance is basically a loan allowing another address to use your tokens
    mapping(address => mapping(address => uint256)) private _allowances;

    //total amount of tokens
    uint256 private _totalSupply;

    //name & symbol representing the tokens
    string private _name;
    string private _symbol;
    
    address private _owner;
    
    //events to let the exterior know when changed from pause to unpause
    event Paused(address account);
    event Unpaused(address account);
    
    //stores the value of paused is true or false
    bool private _paused;

    //when you deploy the contract you suplly these three values
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        //owner starts out with all the balance
        _balances[msg.sender] = _totalSupply;
        //by default the contract will start as unpaused
        _paused = false;
        //the person who deploys the contract will be the initial owner
        _owner = msg.sender;
    }
    
    //function that gets called when eth is sent to the contract address
    receive() external payable {
        revert('Ether cannot me sent to this Contract');
    }
    
    
    function balance() public view returns(uint256) {
        return address(this).balance;
    }
    
    //only allows the function to continue if the owner calls it
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    
    //only allows function to continue when trading is not paused
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    //only allows function to continue when trading is pause
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    //returns name
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    //returns symbol
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    //number of decimals used for tokem
    //BE CAREFUL!!! If your token supply is 5000 and you have 3 deciamls, your token supply is actually 5
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    //returns total supply
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    //sees if the trading is currently paused or not
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    
    //sees who the owner of the contract is
    function owner() public view virtual returns(address) {
        return _owner;
    }
    
    //change the owner of the contract, only to be called by the owner
    function transferOwnership(address newOwner) public onlyOwner returns(bool) {
        _owner = newOwner;
        
        return true;
    }

    //returns balances
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    //executes a transfer between two accounts
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    //returns allowance
    function allowance(address allower, address spender) public view virtual override returns (uint256) {
        return _allowances[allower][spender];
    }

    //A address approves a certain amount of its funs to be used by another address
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    //an address transfers tokens from his allowance to another address
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        //first we check that the allowance is bigger than the amount that is wanted to send
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
         //we try to execute the transfer
        _transfer(sender, recipient, amount);
        
        //unchecked means that it wont check for underflows or overflows, since we know that currentAllowance > amount, this is no problem
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    //adding more tokens to an allowance
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    //taking away tokens from an allowance
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        //must have more tokens than the amount trying to be taken away
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    //sending tokens from one address to another
    function _transfer(address sender,address recipient,uint256 amount) internal virtual whenNotPaused {
        //both have to be valid address
        require(recipient != address(this), 'Cannot sned tokens to contract address!');
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
    
        //we check to see that the amount is inferior to the senders balance and then update their balances
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        //emitting an event so that the exterior can see that a transfer has taken place
        emit Transfer(sender, recipient, amount);

    }
    
    //function that updates the allowance that an address has given another address
    function _approve(address allower, address spender, uint256 amount) internal virtual {
        //both addess must be valid
        require(allower != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[allower][spender] = amount;
        //emitting an event so that the exterior can see that an allowance was created
        emit Approval(allower, spender, amount);
    }
    
    //pause the contract, only to be called by owner and when contract is not paused
    function _pause() internal virtual whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    //unpause the contract, only to be called by owner and when contract is paused
    function _unpause() internal virtual whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}