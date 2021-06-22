// SPDX-License-Identifier: UNLICENSED
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;

// Hardhat exposes a console.log which is very useful in development
// but make sure to remove it before deployment
// import "hardhat/console.sol";

// This is the main building block for smart contracts.
contract Token {
    // Some string type variables to identify the token.
    // The `public` modifier makes a variable readable from outside the contract.
    // 'private' means that the variable cannot be seen form outside,
    // but getter functions have been provided for each to return their value
    string private _name = "Jank";
    string private _symbol = "JANK";
    uint8 private _decimals = 18;

    // The fixed amount of tokens stored in an unsigned integer type variable.
    uint256 private _totalSupply = 1000000;

    // An address type variable is used to store ethereum accounts.
    address private _owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) private _balances;

    // Here is a mapping that gives how much accounts have been approved to spend 
    // from other accounts
    mapping(address => mapping(address => uint256)) private _allowances;

    event Approval(address owner, address spender, uint256 amount);
    event Transfer(address sender, address recipient, uint256 amount);

    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     */
    constructor() {
        // The totalSupply is assigned to transaction sender, which is the account
        // that is deploying the contract.
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
    }

    /**
     * A function to transfer tokens.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function transfer(address to, uint256 amount) external returns(bool) {
        // console.log("Sender balance is %s tokens", _balances[msg.sender]);
        // console.log("Trying to send %s tokens to %s", amount, to);
        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(_balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev returns the allowance the spender has been approved to spend 
     * from the owner
     * @param owner_ address: the address of the owner of the funds
     * @param spender address: the address of the spender
     */
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    /**
     * Read-only function to retrieve the total supply at the time queried
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * Read-only function to retrieve the decimals of the token
     */
    function decimals() public view returns (uint256) {
        return _decimals;
    }

    /**
     * Read-only function to retrieve the address of the owner
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * Read-only function to retrieve the name of the token
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * Read-only function to retrieve the symbol of the token
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * Allows a user to approve another account to spend their funds
     *
     * @param spender address: the address to be approved
     * @param amount uint256: the amount to approve
     */
    function approve(address spender, uint256 amount) public returns(bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * If approved, allows the user to send funds from another account
     *
     * @param from address: the address to send the funds from
     * @param to address: the address to send the funds to
     * @param amount uint256: the amount to send
     */
    function transferFrom(address from, address to, uint256 amount) public returns(bool) {
        require(_allowances[from][msg.sender] >= amount);
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * Mints tokens to a target address
     *
     * @param recipient address: the address to mint the token to
     * @param amount uint256: the amount of tokens to mint
     */
    function mint(address recipient, uint256 amount) public {
        _totalSupply += amount;
        _balances[recipient] += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    /**
     * Burns tokens from the user's account
     *
     * @param amount uint256: the amount of tokens to burn
     */
    function burn(uint256 amount) public {
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * If approved, allows a user to burn another user's tokens
     *
     * @param from address: the address to burn from
     * @param amount uint256: the amount of token to burn
     */
    function burnFrom(address from, uint256 amount) public {
        require(_allowances[from][msg.sender] >= amount);
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _totalSupply += amount;

        emit Transfer(from, address(0), amount);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}