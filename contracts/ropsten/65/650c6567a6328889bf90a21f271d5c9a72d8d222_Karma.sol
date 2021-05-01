/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// Copyright [2021] - [2021], [Shaun Reed] and [Karma] contributors
// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

// ----------------------------------------------------------------------------
// Import ERC Token Standard #20 Interface
//   ETH EIP repo: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------

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

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// ----------------------------------------------------------------------------
// Karma Contract
// ----------------------------------------------------------------------------
contract Karma is IERC20, Initializable
{
    // Avoid initializing fields in declarations
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#avoid-initial-values-in-field-declarations
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public _totalSupply;

    // Balances for each account; A hashmap using wallet address as key and uint as value
    mapping(address => uint) balances;
    
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping(address => uint)) allowed;
//
//    /**
//     * Constrctor function
//     *
//     * Initializes contract with initial supply tokens to the creator of the contract
//     */
//    constructor()
//    {
//        name = "Karma";    // Name of the token
//        symbol = "KRMA";         // Abbreviation of the token
//        decimals = 18;          // Number of decimals that can be used to split token
//
//
//        // FORMAT: <SUPPLY><DECIMALS>
//        // Where SUPPLY is the number of coins in base 10 decimal notation
//        // And DECIMALS is a trailing number of 0's; Count must match `decimals` value set above
//        // 1000 000 000 000000000000000000 == 1 billion total supply;
//        //  + trailing 0's represent the 18 decimal locations that can be used to send fractions
//        _totalSupply = 1000000000000000000000000000;
//
//
//        // Set the remaining balance of the contract owner to the total supply
//        balances[msg.sender] = _totalSupply; // msg.sender is the calling address for this constructor
//        // Transfer the total supply to the contract owner on initialization
//        emit Transfer(address(0), msg.sender, _totalSupply); // address(0) is used to represent a new TX
//    }

    function initialize() public initializer
    {
        // ERC20 Standard dictates names of these variables
        // https://ethereum.org/en/developers/docs/standards/tokens/erc-20/#body
        name = "Karma";    // Name of the token
        symbol = "KRMA";         // Abbreviation of the token
        decimals = 18;          // Number of decimals that can be used to split token


        // FORMAT: <SUPPLY><DECIMALS>
        // Where SUPPLY is the number of coins in base 10 decimal notation
        // And DECIMALS is a trailing number of 0's; Count must match `decimals` value set above
        // 1000 000 000 000000000000000000 == 1 billion total supply;
        //  + trailing 0's represent the 18 decimal locations that can be used to send fractions
        _totalSupply = 1000000000000000000000000000;


        // Set the remaining balance of the contract owner to the total supply
        balances[msg.sender] = _totalSupply; // msg.sender is the calling address for this constructor
        // Transfer the total supply to the contract owner on initialization
        emit Transfer(address(0), msg.sender, _totalSupply); // address(0) is used to represent a new TX
    }


    // Get the total circulating supply of the token 
    function totalSupply() public override view returns (uint)
    {
        // By subtracting from tokens held at address(0), we provide an address to 'burn' the supply
        return _totalSupply - balances[address(0)]; // Subtract from tokens held at address(0)
    }

    // Get the token balance for account `tokenOwner`
    function balanceOf(address tokenOwner) public override view returns (uint balance)
    {
        return balances[tokenOwner]; // Return the balance of the owner's address
    }

    // To initiate a transaction, we first approve an address to withdraw from our wallet
    //  + msg.sender is approving spender to withdraw from its balance _value tokens
    // Allow `spender` to withdraw from your account, multiple times, up to the `tokens`
    // If this function is called again it overwrites the current allowance with _value
    function approve(address spender, uint _value) public override returns (bool success)
    {
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        //if ((value != 0) && (allowed[msg.sender][spender] != 0)) throw;

        allowed[msg.sender][spender] = _value;
        emit Approval(msg.sender, spender, _value);
        return true;
    }

    // Helper to check the amount of tokens allowed for this spender at this address
    // @param tokenOwner The address of the account owning tokens
    // @param spender The address of the account able to transfer the tokens
    // returns Amount of remaining tokens allowed to spent
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining)
    {
        return allowed[tokenOwner][spender];
    }

    // Send `_value` amount of tokens from address `from` to address `to`
    function transferFrom(address from, address to, uint _value) public override returns (bool success)
    {
        // Set this wallet balance -= _value
        balances[from] = balances[from] - _value;

        // Update this wallet's approved balance for the withdrawing address
//        uint allowance = allowed[from][msg.sender];
        allowed[from][msg.sender] -= _value;

        // Add the amount of tokens to the balance at the receiving address
        balances[to] = balances[to] + _value;
        emit Transfer(from, to, _value);
        return true;
    }

    // Transfer the balance from owner's account to another account
    function transfer(address to, uint tokens) public override returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

}