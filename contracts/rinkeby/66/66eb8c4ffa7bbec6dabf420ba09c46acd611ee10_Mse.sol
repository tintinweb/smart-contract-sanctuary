/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-13
*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
 interface  ERC20Interface {
    function totalSupply() external  view returns (uint);
    function balanceOf(address tokenOwner) external  view returns (uint balance);
    function allowance(address tokenOwner, address spender) external  view returns (uint remaining);
    function transfer(address to, uint tokens) external  returns (bool success);
    function approve(address spender, uint tokens) external  returns (bool success);
    function transferFrom(address from, address to, uint tokens) external  returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20
//
// ----------------------------------------------------------------------------

contract Mse is ERC20Interface, Owned {
    using SafeMath for uint;

    string public constant name = "MSE-COIN";
    string public constant symbol = "MSE";
    uint8 public constant _decimals = 5;

    uint constant private  DECIMALS_5 = uint(10) ** _decimals;
    uint constant private CONSTANT_TOTAL_SUPPLY = 10000000000 * DECIMALS_5;
    uint public _totalSupply    = 10000000000 * DECIMALS_5;

    constructor()  {
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

// ----------------------------------------------------------------------------
// mappings for implementing ERC20
// ERC20 standard functions
// ----------------------------------------------------------------------------

    // Balances for each account
    mapping(address => uint) public balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping(address => uint)) public allowed;

    function totalSupply() public override  view returns (uint) {
        return _totalSupply;
    }

    // Get the token balance for account `tokenOwner`
    function balanceOf(address tokenOwner) public override  view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override  view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function _transfer(address _from, address _toAddress, uint _tokens) private {
        balances[_from] = balances[_from].sub(_tokens);
        addToBalance(_toAddress, _tokens);
        emit Transfer(_from, _toAddress, _tokens);
    }

    // Transfer the balance from owner's account to another account
    function transfer(address _add, uint _tokens) public override  returns (bool success) {
        require(_add != address(0));
        require(_tokens <= balances[msg.sender]);
        _transfer(msg.sender, _add, _tokens);
        return true;
    }

    /*
        Allow `spender` to withdraw from your account, multiple times,
        up to the `tokens` amount.If this function is called again it
        overwrites the current allowance with _value.
    */
    function approve(address spender, uint tokens) public override  returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /*
        Send `tokens` amount of tokens from address `from` to address `to`
        The transferFrom method is used for a withdraw workflow,
        allowing contracts to send tokens on your behalf,
        for example to "deposit" to a contract address and/or to charge
        fees in sub-currencies; the command should fail unless the _from
        account has deliberately authorized the sender of the message via
        some mechanism; we propose these standardized APIs for approval:
    */
    function transferFrom(address from, address _toAddr, uint tokens) public override  returns (bool success) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _transfer(from, _toAddr, tokens);
        return true;
    }


    // address not null
    modifier addressNotNull(address _addr){
        require(_addr != address(0));
        _;
    }

    // Add to balance
    function addToBalance(address _address, uint _amount) internal {
    	balances[_address] = balances[_address].add(_amount);
    }

	 /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public override  onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function mint(address recipient, uint256 amount) public onlyOwner {
        require(recipient != address(0), "ERC20: mint to the zero address");
        require(_totalSupply.add(amount) >= _totalSupply); // Overflow check

        _totalSupply = _totalSupply.add(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(address(0), recipient, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        require(amount <= balances[msg.sender]);
        require(CONSTANT_TOTAL_SUPPLY <= _totalSupply.sub(amount));

        _totalSupply = _totalSupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }


}