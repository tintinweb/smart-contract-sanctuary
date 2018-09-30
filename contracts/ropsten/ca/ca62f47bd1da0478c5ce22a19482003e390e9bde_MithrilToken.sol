pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Owned
 * @dev Ownership model
 */
contract Owned {
    address public owner;

    event OwnershipTransfered(address indexed owner);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
        OwnershipTransfered(owner);
    }
}

/**
 * @title ERC20Token
 * @dev Interface for erc20 standard
 */
contract ERC20Token {

    using SafeMath for uint256;

    string public constant name = "Mithril Token";
    string public constant symbol = "MITH";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, uint256 value, address indexed to, bytes extraData);

    function ERC20Token() public {
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address from, address to, uint256 value) internal {
        // Check if the sender has enough balance
        require(balanceOf[from] >= value);

        // Check for overflow
        require(balanceOf[to] + value > balanceOf[to]);

        // Save this for an amount double check assertion
        uint256 previousBalances = balanceOf[from].add(balanceOf[to]);

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);

        Transfer(from, to, value);

        // Asserts for duplicate check. Should never fail.
        assert(balanceOf[from].add(balanceOf[to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `value` tokens to `to` from your account
     *
     * @param to The address of the recipient
     * @param value the amount to send
     */
    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `value` tokens to `to` in behalf of `from`
     *
     * @param from The address of the sender
     * @param to The address of the recipient
     * @param value the amount to send
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `spender` to spend no more than `value` tokens in your behalf
     *
     * @param spender The address authorized to spend
     * @param value the max amount they can spend
     * @param extraData some extra information to send to the approved contract
     */
    function approve(address spender, uint256 value, bytes extraData) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, value, spender, extraData);
        return true;
    }
}

/**
 * @title MithrilToken
 * @dev MithrilToken
 */
contract MithrilToken is Owned, ERC20Token {

    // Address where funds are collected.
    address public vault;
    address public wallet;

    function MithrilToken() public {
    }

    function init(uint256 _supply, address _vault, address _wallet) public onlyOwner {
        require(vault == 0x0);
        require(_vault != 0x0);

        totalSupply = _supply;
        vault = _vault;
        wallet = _wallet;
        balanceOf[vault] = totalSupply;
    }

    function () payable public {
        wallet.transfer(msg.value);
    }
}