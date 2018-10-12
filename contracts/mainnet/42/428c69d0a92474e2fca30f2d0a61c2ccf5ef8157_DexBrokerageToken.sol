pragma solidity ^0.4.25;

// ---------------------------------------------------------------------
// Dex Brokerage Token - DEXB : https://dexbrokerage.com
//
// Symbol      : DEXB
// Name        : Dex Brokerage Token
// Total supply: 200,000,000
// Decimals    : 18
//
// Author: Radek Ostrowski / https://startonchain.com
// ---------------------------------------------------------------------

/**
 * @title DexBrokerage
 * @dev Interface function called from `approveAndDeposit` depositing the tokens onto the exchange
 */
contract DexBrokerage {
    function receiveTokenDeposit(address token, address from, uint256 amount) public;
}

/**
 * @title ApproveAndCall
 * @dev Interface function called from `approveAndCall` notifying that the approval happened
 */
contract ApproveAndCall {
    function receiveApproval(address _from, uint256 _amount, address _tokenContract, bytes _data) public returns (bool);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

/**
 * @title Dex Brokerage Token
 * @dev Burnable ERC20 token with initial transfers blocked
 */
contract DexBrokerageToken is Ownable {
    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event TransfersEnabled();
    event TransferRightGiven(address indexed _to);
    event TransferRightCancelled(address indexed _from);
    event WithdrawnERC20Tokens(address indexed _tokenContract, address indexed _owner, uint256 _balance);
    event WithdrawnEther(address indexed _owner, uint256 _balance);

    string public constant name = "Dex Brokerage Token";
    string public constant symbol = "DEXB";
    uint8 public constant decimals = 18;
    uint256 public constant initialSupply = 200000000 * (10 ** uint256(decimals));
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    //This mapping is used for the token owner and crowdsale contract to
    //transfer tokens before they are transferable
    mapping(address => bool) public transferGrants;
    //This flag controls the global token transfer
    bool public transferable;

    /**
     * @dev Modifier to check if tokens can be transferred.
     */
    modifier canTransfer() {
        require(transferable || transferGrants[msg.sender]);
        _;
    }

    /**
     * @dev The constructor sets the original `owner` of the contract
     * to the sender account and assigns them all tokens.
     */
    constructor() public {
        totalSupply = initialSupply;
        balances[owner] = totalSupply;
        transferGrants[owner] = true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) canTransfer public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
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
    function increaseApproval(address _spender, uint _addedValue) canTransfer public returns (bool) {
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
    function decreaseApproval(address _spender, uint _subtractedValue) canTransfer public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Function to approve the transfer of the tokens and to call another contract in one step
     * @param _recipient The target contract for tokens and function call
     * @param _value The amount of tokens to send
     * @param _data Extra data to be sent to the recipient contract function
     */
    function approveAndCall(address _recipient, uint _value, bytes _data) canTransfer public returns (bool) {
        allowed[msg.sender][_recipient] = _value;
        ApproveAndCall(_recipient).receiveApproval(msg.sender, _value, address(this), _data);
        emit Approval(msg.sender, _recipient, allowed[msg.sender][_recipient]);
        return true;
    }

    /**
     * @dev Function to approve the transfer of the tokens and deposit them to DexBrokerage in one step
     * @param _exchange DexBrokerage exchange address to deposit the tokens to
     * @param _value The amount of tokens to send
     */
    function approveAndDeposit(DexBrokerage _exchange, uint _value) public returns (bool) {
        allowed[msg.sender][_exchange] = _value;
        emit Approval(msg.sender, _exchange, _value);
        _exchange.receiveTokenDeposit(address(this), msg.sender, _value);
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) canTransfer public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(burner, address(0), _value);
    }

    /**
     * @dev Enables the transfer of tokens for everyone
     */
    function enableTransfers() onlyOwner public {
        require(!transferable);
        transferable = true;
        emit TransfersEnabled();
    }

    /**
     * @dev Assigns the special transfer right, before transfers are enabled
     * @param _to The address receiving the transfer grant
     */
    function grantTransferRight(address _to) onlyOwner public {
        require(!transferable);
        require(!transferGrants[_to]);
        require(_to != address(0));
        transferGrants[_to] = true;
        emit TransferRightGiven(_to);
    }

    /**
     * @dev Removes the special transfer right, before transfers are enabled
     * @param _from The address that the transfer grant is removed from
     */
    function cancelTransferRight(address _from) onlyOwner public {
        require(!transferable);
        require(transferGrants[_from]);
        transferGrants[_from] = false;
        emit TransferRightCancelled(_from);
    }

    /**
     * @dev Allows to transfer out the balance of arbitrary ERC20 tokens from the contract.
     * @param _token The contract address of the ERC20 token.
     */
    function withdrawERC20Tokens(ERC20 _token) onlyOwner public {
        uint256 totalBalance = _token.balanceOf(address(this));
        require(totalBalance > 0);
        _token.transfer(owner, totalBalance);
        emit WithdrawnERC20Tokens(address(_token), owner, totalBalance);
    }

    /**
     * @dev Allows to transfer out the ether balance that was forced into this contract, e.g with `selfdestruct`
     */
    function withdrawEther() onlyOwner public {
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0);
        owner.transfer(totalBalance);
        emit WithdrawnEther(owner, totalBalance);
    }
}