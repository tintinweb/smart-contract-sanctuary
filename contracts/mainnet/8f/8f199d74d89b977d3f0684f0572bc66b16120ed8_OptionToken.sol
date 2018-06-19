/**
 *  The Option token contract complies with the ERC20 standard.
 *  This contract implements american option.
 *  Holders of the Option tokens can make a purchase of the underlying asset
 *  at the price of Strike until the Expiration time.
 *  The Strike price and Expiration date are set once and can&#39;t be changed.
 *  Author: Alexey Bukhteyev
 **/

pragma solidity ^0.4.4;

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    function name() public constant returns(string);
    function symbol() public constant returns(string);

    function totalSupply() public constant returns(uint256 supply);
    function balanceOf(address _owner) public constant returns(uint256 balance);
    function transfer(address _to, uint256 _value) public returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
    function approve(address _spender, uint256 _value) public returns(bool success);
    function allowance(address _owner, address _spender) public constant returns(uint256 remaining);
    function decimals() public constant returns(uint8);
}

/*
    Allows to recreate OptionToken contract on the same address.
    Just create new TokenHolders(OptionToken) and reinitiallize OptionToken using it&#39;s address
*/
contract TokenHolders {
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /*
        TokenHolders contract is being connected to OptionToken on creation.
        Nobody can modify balanceOf and allowance except OptionToken
    */

    function validate() external constant returns (bool);

    function setBalance(address _to, uint256 _value) external;

    /* Send some of your tokens to a given address */
    function transfer(address _from, address _to, uint256 _value) public returns(bool success);

    /* Allow another contract or person to spend some tokens in your behalf */
    function approve(address _sender, address _spender, uint256 _value) public returns(bool success);

    /* A contract or  person attempts to get the tokens of somebody else.
     *  This is only allowed if the token holder approved. */
    function transferWithAllowance(address _origin, address _from, address _to, uint256 _value)
    public returns(bool success);
}

/*
    This ERC20 contract is a basic option contract that implements a token which
    allows to token holder to buy some asset for the fixed strike price before expiration date.
*/
contract OptionToken {
    string public standard = &#39;ERC20&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;

    // Option characteristics
    uint256 public expiration = 1512172800; //02.12.2017 Use unix timespamp
    uint256 public strike = 20000000000;

    ERC20 public baseToken;
    TokenHolders public tokenHolders;

    bool _initialized = false;


    /* This generates a public event on the blockchain that will notify clients */
    // ERC20 events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    // OptionToken events
    event Deposit(address indexed from, uint256 value);
    event Redeem(address indexed from, uint256 value, uint256 ethvalue);
    event Issue(address indexed issuer, uint256 value);

    // Only set owner on the constructor
    function OptionToken() public {
        owner = msg.sender;
    }

    // ERC20 functions
    function balanceOf(address _owner) public constant returns(uint256 balance) {
        return tokenHolders.balanceOf(_owner);
    }

    function totalSupply() public constant returns(uint256 supply) {
        // total supply is a balance of this contract in base tokens
        return baseToken.balanceOf(this);
    }

    /* Send some of your tokens to a given address */
    function transfer(address _to, uint256 _value) public returns(bool success) {
        if(now > expiration)
            return false;

        if(!tokenHolders.transfer(msg.sender, _to, _value))
            return false;

        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract or person to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public returns(bool success) {
        if(now > expiration)
            return false;

        if(!tokenHolders.approve(msg.sender, _spender, _value))
            return false;

        Approval(msg.sender, _spender, _value);
        return true;
    }


    /* A contract or  person attempts to get the tokens of somebody else.
     *  This is only allowed if the token holder approved. */
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        if(now > expiration)
            return false;

        if(!tokenHolders.transferWithAllowance(msg.sender, _from, _to, _value))
            return false;

        Transfer(_from, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns(uint256 remaining) {
        return tokenHolders.allowance(_owner, _spender);
    }

    // OptionToken functions

    /*
        Then we should pass base token contract address to init() function.
        Only contract creator can call init() and only once
    */
    function init(ERC20 _baseToken, TokenHolders _tokenHolders, string _name, string _symbol,
                uint256 _exp, uint256 _strike) public returns(bool success) {
        require(msg.sender == owner && !_initialized);

        baseToken = _baseToken;
        tokenHolders = _tokenHolders;

        // if baseToken.totalSupply() is zero - something is wrong
        assert(baseToken.totalSupply() != 0);
        // validate tokenHolders contract owner - it should be OptionToken
        assert(tokenHolders.validate());

        name = _name;
        symbol = _symbol;
        expiration = _exp;
        strike = _strike;

        decimals = baseToken.decimals();

        _initialized = true;
        return true;
    }

    /*
        Allows to increase totalSupply and get OptionTokens to their balance.
        Before calling depositTokens the caller should approve the transfer for this contract address
        using ERC20.approve().
        Actually should be called by contract owner, because no ETH payout will be done for token transfer.
    */
    function issue(uint256 _value) public returns(bool success) {
        require(now <= expiration && _initialized);

        uint256 receiver_balance = balanceOf(msg.sender) + _value;
        assert(receiver_balance >= _value);

        // check if transfer failed
        if(!baseToken.transferFrom(msg.sender, this, _value))
            revert();

        tokenHolders.setBalance(msg.sender, receiver_balance);
        Issue(msg.sender, receiver_balance);

        return true;
    }

    /*
        Buy base tokens for the strike price
    */
    function() public payable {
        require(now <= expiration && _initialized); // the contract should be initialized!
        uint256 available = balanceOf(msg.sender); // balance of option holder

        // check if there are tokens for sale
        require(available > 0);

        uint256 tokens = msg.value / (strike);
        assert(tokens > 0 && tokens <= msg.value);

        uint256 change = 0;
        uint256 eth_to_transfer = 0;

        if(tokens > available) {
            tokens = available; // send all available tokens
        }

        // calculate the change for the operation
        eth_to_transfer = tokens * strike;
        assert(eth_to_transfer >= tokens);
        change = msg.value - eth_to_transfer;
        assert(change < msg.value);

        if(!baseToken.transfer(msg.sender, tokens)) {
            revert(); // error, revert transaction
        }

        uint256 new_balance = balanceOf(msg.sender) - tokens;
        tokenHolders.setBalance(msg.sender, new_balance);

        // new balance should be less then old balance
        assert(balanceOf(msg.sender) < available);

        if(change > 0) {
            msg.sender.transfer(change); // return the change
        }

        if(eth_to_transfer > 0) {
            owner.transfer(eth_to_transfer); // transfer eth for tokens to the contract owner
        }

        Redeem(msg.sender, tokens, eth_to_transfer);
    }

    /*
        Allows the the contract owner to withdraw all unsold base tokens,
        also deinitializes the token
    */
    function withdraw() public returns(bool success) {
        require(msg.sender == owner);
        if(now <= expiration || !_initialized)
            return false;

        // transfer all tokens
        baseToken.transfer(owner, totalSupply());

        // perform deinitialization
        baseToken = ERC20(0);
        tokenHolders = TokenHolders(0);
        _initialized = false;
        return true;
    }
}