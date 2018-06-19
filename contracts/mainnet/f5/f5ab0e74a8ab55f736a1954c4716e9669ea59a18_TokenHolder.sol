pragma solidity 0.4.15;

/**
 * Basic interface for contracts, following ERC20 standard
 */
contract ERC20Token {
    

    /**
     * Triggered when tokens are transferred.
     * @param from - address tokens were transfered from
     * @param to - address tokens were transfered to
     * @param value - amount of tokens transfered
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Triggered whenever allowance status changes
     * @param owner - tokens owner, allowance changed for
     * @param spender - tokens spender, allowance changed for
     * @param value - new allowance value (overwriting the old value)
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * Returns total supply of tokens ever emitted
     * @return totalSupply - total supply of tokens ever emitted
     */
    function totalSupply() constant returns (uint256 totalSupply);

    /**
     * Returns `owner` balance of tokens
     * @param owner address to request balance for
     * @return balance - token balance of `owner`
     */
    function balanceOf(address owner) constant returns (uint256 balance);

    /**
     * Transfers `amount` of tokens to `to` address
     * @param  to - address to transfer to
     * @param  value - amount of tokens to transfer
     * @return success - `true` if the transfer was succesful, `false` otherwise
     */
    function transfer(address to, uint256 value) returns (bool success);

    /**
     * Transfers `value` tokens from `from` address to `to`
     * the sender needs to have allowance for this operation
     * @param  from - address to take tokens from
     * @param  to - address to send tokens to
     * @param  value - amount of tokens to send
     * @return success - `true` if the transfer was succesful, `false` otherwise
     */
    function transferFrom(address from, address to, uint256 value) returns (bool success);

    /**
     * Allow spender to withdraw from your account, multiple times, up to the value amount.
     * If this function is called again it overwrites the current allowance with `value`.
     * this function is required for some DEX functionality
     * @param spender - address to give allowance to
     * @param value - the maximum amount of tokens allowed for spending
     * @return success - `true` if the allowance was given, `false` otherwise
     */
    function approve(address spender, uint256 value) returns (bool success);

    /**
     * Returns the amount which `spender` is still allowed to withdraw from `owner`
     * @param  owner - tokens owner
     * @param  spender - addres to request allowance for
     * @return remaining - remaining allowance (token count)
     */
    function allowance(address owner, address spender) constant returns (uint256 remaining);
}



/**
 * @title Token Holder
 * Given a ERC20 compatible Token allows holding for a certain amount of time
 * after that time, the beneficiar can acquire his Tokens
 */
 contract TokenHolder {
    
    
    

    uint256 constant MIN_TOKENS_TO_HOLD = 1000;

    /**
     * A single token deposit for a certain amount of time for a certain beneficiar
     */
    struct TokenDeposit {
        uint256 tokens;
        uint256 releaseTime;
    }

    /** Emited when Tokens where put on hold
     * @param tokens - amount of Tokens
     * @param beneficiar - the address that will be able to claim Tokens in the future
     * @param depositor - the address deposited tokens
     * @param releaseTime - timestamp of a moment which `beneficiar` would be able to claim Tokens after
     */
    event Deposited(address indexed depositor, address indexed beneficiar, uint256 tokens, uint256 releaseTime);

    /** Emited when Tokens where claimed back
     * @param tokens - amount of Tokens claimed
     * @param beneficiar - who claimed the Tokens
     */
    event Claimed(address indexed beneficiar, uint256 tokens);

    /** all the deposits made */
    mapping(address => TokenDeposit[]) deposits;

    /** Tokens contract instance */
    ERC20Token public tokenContract;

    /**
     * Creates the Token Holder with the specifief `ERC20` Token Contract instance
     * @param _tokenContract `ERC20` Token Contract instance to use
     */
    function TokenHolder (address _tokenContract)   {  
        tokenContract = ERC20Token(_tokenContract);
    }

    /**
     * Puts some amount of Tokens on hold to be retrieved later
     * @param  tokenCount - amount of tokens
     * @param  tokenBeneficiar - will be able to retrieve tokens in the future
     * @param  depositTime - time to hold in seconds
     */
    function depositTokens (uint256 tokenCount, address tokenBeneficiar, uint256 depositTime)   {  
        require(tokenCount >= MIN_TOKENS_TO_HOLD);
        require(tokenContract.allowance(msg.sender, address(this)) >= tokenCount);

        if(tokenContract.transferFrom(msg.sender, address(this), tokenCount)) {
            deposits[tokenBeneficiar].push(TokenDeposit(tokenCount, now + depositTime));
            Deposited(msg.sender, tokenBeneficiar, tokenCount, now + depositTime);
        }
    }

    /**
     * Returns the amount of deposits for `beneficiar`
     */
    function getDepositCount (address beneficiar)   constant   returns (uint count) {  
        return deposits[beneficiar].length;
    }

    /**
     * returns the `idx` deposit for `beneficiar`
     */
    function getDeposit (address beneficiar, uint idx)   constant   returns (uint256 deposit_dot_tokens, uint256 deposit_dot_releaseTime) {  
TokenDeposit memory deposit;

        require(idx < deposits[beneficiar].length);
        deposit = deposits[beneficiar][idx];
    deposit_dot_tokens = uint256(deposit.tokens);
deposit_dot_releaseTime = uint256(deposit.releaseTime);}

    /**
     * Transfers all the Tokens already unlocked to `msg.sender`
     */
    function claimAllTokens ()   {  
        uint256 toPay = 0;

        TokenDeposit[] storage myDeposits = deposits[msg.sender];

        uint idx = 0;
        while(true) {
            if(idx >= myDeposits.length) { break; }
            if(now > myDeposits[idx].releaseTime) {
                toPay += myDeposits[idx].tokens;
                myDeposits[idx] = myDeposits[myDeposits.length - 1];
                myDeposits.length--;
            } else {
                idx++;
            }
        }

        if(toPay > 0) {
            tokenContract.transfer(msg.sender, toPay);
            Claimed(msg.sender, toPay);
        }
    }
}