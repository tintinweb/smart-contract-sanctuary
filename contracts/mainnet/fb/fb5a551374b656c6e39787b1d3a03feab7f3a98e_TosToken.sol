/**
 * Copyright 2018 TosChain Foundation.
 */

pragma solidity ^0.4.16;

/** Owner permissions */
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

/// ERC20 standard，Define the minimum unit of money to 18 decimal places,
/// transfer out, destroy coins, others use your account spending pocket money.
contract TokenERC20 {
    uint256 public totalSupply;
    // This creates an array with all balances.
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt.
    event Burn(address indexed from, uint256 value);

    /**
     * Internal transfer, only can be called by this contract.
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead.
        require(_to != 0x0);
        // Check if the sender has enough.
        require(balanceOf[_from] >= _value);
        // Check for overflows.
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future.
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender.
        balanceOf[_from] -= _value;
        // Add the same to the recipient.
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail.
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account.
     *
     * @param _to The address of the recipient.
     * @param _value the amount to send.
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address.
     *
     * Send `_value` tokens to `_to` in behalf of `_from`.
     *
     * @param _from The address of the sender.
     * @param _to The address of the recipient.
     * @param _value the amount to send.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Check allowance
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address.
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf.
     *
     * @param _spender The address authorized to spend.
     * @param _value the max amount they can spend.
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify.
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it.
     *
     * @param _spender The address authorized to spend.
     * @param _value the max amount they can spend.
     * @param _extraData some extra information to send to the approved contract.
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly.
     *
     * @param _value the amount of money to burn.
     */
    function burn(uint256 _value) public returns (bool success) {
        // Check if the sender has enough
        require(balanceOf[msg.sender] >= _value);
        // Subtract from the sender
        balanceOf[msg.sender] -= _value;
        // Updates totalSupply
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account.
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender.
     * @param _value the amount of money to burn.
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        // Check if the targeted balance is enough.
        require(balanceOf[_from] >= _value);
        // Check allowance
        require(_value <= allowance[_from][msg.sender]);
        // Subtract from the targeted balance.
        balanceOf[_from] -= _value;
        // Subtract from the sender&#39;s allowance.
        allowance[_from][msg.sender] -= _value;
        // Update totalSupply
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       TOS TOKEN STARTS HERE       */
/******************************************/

/// @title TOS Protocol Token.
contract TosToken is owned, TokenERC20 {

    /// The full name of the TOS token.
    string public constant name = "ThingsOpreatingSystem";
    /// Symbol of the TOS token.
    string public constant symbol = "TOS";
    /// 18 decimals is the strongly suggested default, avoid changing it.
    uint8 public constant decimals = 18;


    uint256 public totalSupply = 1000000000 * 10 ** uint256(decimals);
    /// Amount of TOS token to first issue.
    uint256 public MAX_FUNDING_SUPPLY = totalSupply * 500 / 1000;

    /**
     *  Locked tokens system
     */
    /// Stores the address of the locked tokens.
    address public lockJackpots;
    /// Reward for depositing the TOS token into a locked tokens.
    /// uint256 public totalLockReward = totalSupply * 50 / 1000;
    /// Remaining rewards in the locked tokens.
    uint256 public remainingReward;

    /// The start time to lock tokens. 2018/03/15 0:0:0
    uint256 public lockStartTime = 1521043200;
    /// The last time to lock tokens. 2018/04/29 0:0:0
    uint256 public lockDeadline = 1524931200;
    /// Release tokens lock time,Timestamp format 1544803200 ==  2018/12/15 0:0:0
    uint256 public unLockTime = 1544803200;

    /// Reward factor for locked tokens 
    uint public constant NUM_OF_PHASE = 3;
    uint[3] public lockRewardsPercentages = [
        1000,   //100%
        500,    //50%
        300    //30%
    ];

    /// Locked account details
    mapping (address => uint256) public lockBalanceOf;

    /**
     *  Freeze the account system
     */
    /* This generates a public event on the blockchain that will notify clients. */
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract. */
    function TosToken() public {
        /// Give the creator all initial tokens.
        balanceOf[msg.sender] = totalSupply;
    }

    /**
     * transfer token for a specified address.
     *
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public {
        /// Locked account can not complete the transfer.
        require(!(lockJackpots != 0x0 && msg.sender == lockJackpots));

        /// Transponding the TOS token to a locked tokens account will be deemed a lock-up activity.
        if (lockJackpots != 0x0 && _to == lockJackpots) {
            _lockToken(_value);
        }
        else {
            /// To unlock the time, automatically unlock tokens.
            if (unLockTime <= now && lockBalanceOf[msg.sender] > 0) {
                lockBalanceOf[msg.sender] = 0;
            }

            _transfer(msg.sender, _to, _value);
        }
    }

    /**
     * transfer token for a specified address.Internal transfer, only can be called by this contract.
     *
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead.
        require(_to != 0x0);
        //Check for overflows.
        require(lockBalanceOf[_from] + _value > lockBalanceOf[_from]);
        // Check if the sender has enough.
        require(balanceOf[_from] >= lockBalanceOf[_from] + _value);
        // Check for overflows.
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Check if sender is frozen.
        require(!frozenAccount[_from]);
        // Check if recipient is frozen.
        require(!frozenAccount[_to]);
        // Subtract from the sender.
        balanceOf[_from] -= _value;
        // Add the same to the recipient.
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }

    /**
     * `freeze? Prevent | Allow` `target` from sending & receiving tokens.
     *
     * @param target Address to be frozen.
     * @param freeze either to freeze it or not.
     */
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /**
     * Increase the token reward.
     *
     * @param _value Increase the amount of tokens awarded.
     */
    function increaseLockReward(uint256 _value) public{
        require(_value > 0);
        _transfer(msg.sender, lockJackpots, _value * 10 ** uint256(decimals));
        _calcRemainReward();
    }

    /**
     * Locked tokens, in the locked token reward calculation and distribution.
     *
     * @param _lockValue Lock token reward.
     */
    function _lockToken(uint256 _lockValue) internal {
        /// Lock the tokens necessary safety checks.
        require(lockJackpots != 0x0);
        require(now >= lockStartTime);
        require(now <= lockDeadline);
        require(lockBalanceOf[msg.sender] + _lockValue > lockBalanceOf[msg.sender]);
        /// Check account tokens must be sufficient.
        require(balanceOf[msg.sender] >= lockBalanceOf[msg.sender] + _lockValue);

        uint256 _reward =  _lockValue * _calcLockRewardPercentage() / 1000;
        /// Distribute bonus tokens.
        _transfer(lockJackpots, msg.sender, _reward);

        /// Save locked accounts and rewards.
        lockBalanceOf[msg.sender] += _lockValue + _reward;
        _calcRemainReward();
    }

    uint256 lockRewardFactor;
    /* Calculate locked token reward percentage，Actual value: rewardFactor/1000 */
    function _calcLockRewardPercentage() internal returns (uint factor){

        uint phase = NUM_OF_PHASE * (now - lockStartTime)/( lockDeadline - lockStartTime);
        if (phase  >= NUM_OF_PHASE) {
            phase = NUM_OF_PHASE - 1;
        }
    
        lockRewardFactor = lockRewardsPercentages[phase];
        return lockRewardFactor;
    }

    /** The activity is over and the token in the prize pool is sent to the manager for fund development. */
    function rewardActivityEnd() onlyOwner public {
        /// The activity is over.
        require(unLockTime < now);
        /// Send the token from the prize pool to the manager.
        _transfer(lockJackpots, owner, balanceOf[lockJackpots]);
        _calcRemainReward();
    }

    function() payable public {}

    /**
     * Set lock token address,only once.
     *
     * @param newLockJackpots The lock token address.
     */
    function setLockJackpots(address newLockJackpots) onlyOwner public {
        require(lockJackpots == 0x0 && newLockJackpots != 0x0 && newLockJackpots != owner);
        lockJackpots = newLockJackpots;
        _calcRemainReward();
    }

    /** Remaining rewards in the locked tokens. */
    function _calcRemainReward() internal {
        remainingReward = balanceOf[lockJackpots];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Check allowance
        require(_from != lockJackpots);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(msg.sender != lockJackpots);
        return super.approve(_spender, _value);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        require(msg.sender != lockJackpots);
        return super.approveAndCall(_spender, _value, _extraData);
    }

    function burn(uint256 _value) public returns (bool success) {
        require(msg.sender != lockJackpots);
        return super.burn(_value);
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_from != lockJackpots);
        return super.burnFrom(_from, _value);
    }
}