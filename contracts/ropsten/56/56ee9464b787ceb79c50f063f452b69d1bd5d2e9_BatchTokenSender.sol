pragma solidity ^0.4.17;

/**
 * Allows one to send EIP-20 tokens to multiple addresses cheaply.
 * Copyright &#169; 2019
 * Author: Andrey Shulepov <andrey.shulepov[at]gmail.com>
 */
contract BatchTokenSender {
    /**
     * Contract creator
     */
    address public creator;

    /**
     * Contract owner
     */
    address public owner;

    /**
     * Token address
     */
    Token public token;

    /**
     * Number of tokens in a lot
     */
    uint256 public lotSize;

    /**
     * Create new Batch Token Sender with lot size.
     *
     * @param _token token address
     */
    constructor (Token _token, uint256 _lotSize) public {
        token = _token;
        lotSize = _lotSize;
        owner = msg.sender;
        creator = msg.sender;
    }

    /**
     * Transfer ownership
     */
    function transfer(address newOwner) public {
        require (msg.sender == owner);
        owner = newOwner;
    }

    /**
     * Perform multiple token transfers from message sender&#39;s address.
     *
     * @param _addresses an array or addresses to perform
     */
    function batchSendLotFrom (address [] _addresses) public {
        require (msg.sender == owner);
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!token.transferFrom (msg.sender, _addresses [i], lotSize)) revert ();
        }
    }

    /**
     * Perform multiple token transfers from contract&#39;s address.
     *
     * @param _addresses an array or addresses to perform
     */
    function batchSendLot (address [] _addresses) public {
        require (msg.sender == owner);
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transfer (_addresses [i], lotSize);
        }
    }

    /**
     * Perform multiple token transfers from message sender&#39;s address.
     *
     * @param _transfers an array or encoded transfers to perform
     */
    function batchSendFrom (uint256 [] _transfers) public {
        require (msg.sender == owner);
        for (uint256 i = 0; i < _transfers.length; i++) {
            uint256 _value = _transfers [i] >> 160;
            address _to = address (_transfers [i] & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            if (!token.transferFrom (msg.sender, _to, _value)) revert ();
        }
    }

    /**
     * Perform multiple token transfers from contract&#39;s address.
     *
     * @param _transfers an array or encoded transfers to perform
     */
    function batchSend (uint256 [] _transfers) public payable {
        require (msg.sender == owner);
        for (uint256 i = 0; i < _transfers.length; i++) {
            uint256 _value = _transfers [i] >> 160;
            address _to = address (_transfers [i] & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            token.transfer (_to, _value);
        }
    }

    /**
     * Perform token transfer.
     *
     * @param _token EIP-20 token smart contract that manages tokens to be sent
     * @param _value Number of tokens
     * @param _to Receiver address
     */
    function transfer (Token _token, uint160 _value, address _to) public {
        require (msg.sender == owner);
        _token.transfer (_to, _value);
    }

    /**
      * Kill this smart contract.
      */
    function kill () public {
        require (msg.sender == owner);
        selfdestruct (owner);
    }
}

/**
 * EIP-20 standard token interface, as defined
 * <a href=&quot;https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md&quot;>here</a>.
 */
contract Token {
    /**
     * Get total number of tokens in circulation.
     *
     * @return total number of tokens in circulation
     */
    function totalSupply ()
    public constant returns (uint256 supply);

    /**
     * Get number of tokens currently belonging to given owner.
     *
     * @param _owner address to get number of tokens currently belonging to the
     *        owner of
     * @return number of tokens currently belonging to the owner of given
     *         address
     */
    function balanceOf (address _owner)
    public constant returns (uint256 balance);

    /**
     * Transfer given number of tokens from message sender to given recipient.
     *
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer to the owner of given address
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transfer (address _to, uint256 _value)
    public returns (bool success);

    /**
     * Transfer given number of tokens from given owner to given recipient.
     *
     * @param _from address to transfer tokens from the owner of
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer from given owner to given
     *        recipient
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transferFrom (address _from, address _to, uint256 _value)
    public returns (bool success);

    /**
     * Allow given spender to transfer given number of tokens from message
     * sender.
     *
     * @param _spender address to allow the owner of to transfer tokens from
     *        message sender
     * @param _value number of tokens to allow to transfer
     * @return true if token transfer was successfully approved, false otherwise
     */
    function approve (address _spender, uint256 _value)
    public returns (bool success);

    /**
     * Tell how many tokens given spender is currently allowed to transfer from
     * given owner.
     *
     * @param _owner address to get number of tokens allowed to be transferred
     *        from the owner of
     * @param _spender address to get number of tokens allowed to be transferred
     *        by the owner of
     * @return number of tokens given spender is currently allowed to transfer
     *         from given owner
     */
    function allowance (address _owner, address _spender)
    public constant returns (uint256 remaining);

    /**
     * Logged when tokens were transferred from one owner to another.
     *
     * @param _from address of the owner, tokens were transferred from
     * @param _to address of the owner, tokens were transferred to
     * @param _value number of tokens transferred
     */
    event Transfer (address indexed _from, address indexed _to, uint256 _value);

    /**
     * Logged when owner approved his tokens to be transferred by some spender.
     * @param _owner owner who approved his tokens to be transferred
     * @param _spender spender who were allowed to transfer the tokens belonging
     *        to the owner
     * @param _value number of tokens belonging to the owner, approved to be
     *        transferred by the spender
     */
    event Approval (
        address indexed _owner, address indexed _spender, uint256 _value);
}