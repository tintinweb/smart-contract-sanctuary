pragma solidity ^0.4.19;

/**
 * EIP-20 standard token interface, as defined at
 * ttps://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract Token {
    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function decimals() public constant returns (uint8);
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender)
        public constant returns (uint256);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * Allows one to lock EIP-20 tokens until certain time arrives.
 * Copyright &#169; 2018 by ABDK Consulting https://abdk.consulting/
 * Author: Mikhail Vladimirov <mikhail.vladimirov[at]gmail.com>
 */
contract TokenTimeLock {
    /**
     * Create new Token Time Lock with given donation address.
     *
     * @param _donationAddress donation address
     */
    function TokenTimeLock (address _donationAddress) public {
        donationAddress = _donationAddress;
    }

    /**
     * Lock given amount of given EIP-20 tokens until given time arrives, after
     * this time allow the tokens to be transferred to given beneficiary.  This
     * contract should be allowed to transfer at least given amount of tokens
     * from msg.sender.
     *
     * @param _token EIP-20 token contract managing tokens to be locked
     * @param _beneficiary beneficiary to receive tokens after unlock time
     * @param _amount amount of tokens to be locked
     * @param _unlockTime unlock time
     *
     * @return time lock ID
     */
    function lock (
        Token _token, address _beneficiary, uint256 _amount,
        uint256 _unlockTime) public returns (uint256) {
        require (_amount > 0);

        uint256 id = nextLockID++;

        TokenTimeLockInfo storage lockInfo = locks [id];

        lockInfo.token = _token;
        lockInfo.beneficiary = _beneficiary;
        lockInfo.amount = _amount;
        lockInfo.unlockTime = _unlockTime;

        Lock (id, _token, _beneficiary, _amount, _unlockTime);

        require (_token.transferFrom (msg.sender, this, _amount));

        return id;
    }

    /**
     * Unlock tokens locked under time lock with given ID and transfer them to
     * corresponding beneficiary.
     *
     * @param _id time lock ID to unlock tokens locked under
     */
    function unlock (uint256 _id) public {
        TokenTimeLockInfo memory lockInfo = locks [_id];
        delete locks [_id];

        require (lockInfo.amount > 0);
        require (lockInfo.unlockTime <= block.timestamp);

        Unlock (_id);

        require (
            lockInfo.token.transfer (
                lockInfo.beneficiary, lockInfo.amount));
    }

    /**
     * If you like this contract, you may send some ether to this address and
     * it will be used to develop more useful contracts available to everyone.
     */
    address public donationAddress;

    /**
     * Next time lock ID to be used.
     */
    uint256 private nextLockID = 0;

    /**
     * Maps time lock ID to TokenTimeLockInfo structure encapsulating time lock
     * information.
     */
    mapping (uint256 => TokenTimeLockInfo) public locks;

    /**
     * Encapsulates information abount time lock.
     */
    struct TokenTimeLockInfo {
        /**
         * EIP-20 token contract managing locked tokens.
         */
        Token token;

        /**
         * Beneficiary to receive tokens once they are unlocked.
         */
        address beneficiary;

        /**
         * Amount of locked tokens.
         */
        uint256 amount;

        /**
         * Unlock time.
         */
        uint256 unlockTime;
    }

    /**
     * Logged when tokens were time locked.
     *
     * @param id time lock ID
     * @param token EIP-20 token contract managing locked tokens
     * @param beneficiary beneficiary to receive tokens once they are unlocked
     * @param amount amount of locked tokens
     * @param unlockTime unlock time
     */
    event Lock (
        uint256 indexed id, Token indexed token, address indexed beneficiary,
        uint256 amount, uint256 unlockTime);

    /**
     * Logged when tokens were unlocked and sent to beneficiary.
     *
     * @param id time lock ID
     */
    event Unlock (uint256 indexed id);
}