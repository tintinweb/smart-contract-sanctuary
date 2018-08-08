pragma solidity 0.4.15;

pragma solidity 0.4.15;

/**
 * @title MultiOwnable
 * allows creating contracts with up to 16 owners with their shares
 */
contract MultiOwnable {
    /** a single owner record */
    struct Owner {
        address recipient;
        uint share;
    }

    /** contract owners */
    Owner[] public owners;

    /**
     * Returns total owners count
     * @return count - owners count
     */
    function ownersCount ()   constant   returns (uint count) {  
        return owners.length;
    }

    /**
     * Returns owner&#39;s info
     * @param  idx - index of the owner
     * @return owner - owner&#39;s info
     */
    function owner (uint idx)   constant   returns (address owner_dot_recipient, uint owner_dot_share) {  
Owner memory owner;

        owner = owners[idx];
    owner_dot_recipient = address(owner.recipient);
owner_dot_share = uint(owner.share);}

    /** reverse lookup helper */
    mapping (address => bool) ownersIdx;

    /**
     * Creates the contract with up to 16 owners
     * shares must be > 0
     */
    function MultiOwnable (address[16] _owners_dot_recipient, uint[16] _owners_dot_share)   {  
Owner[16] memory _owners;

for(uint __recipient_iterator__ = 0; __recipient_iterator__ < _owners_dot_recipient.length;__recipient_iterator__++)
  _owners[__recipient_iterator__].recipient = address(_owners_dot_recipient[__recipient_iterator__]);
for(uint __share_iterator__ = 0; __share_iterator__ < _owners_dot_share.length;__share_iterator__++)
  _owners[__share_iterator__].share = uint(_owners_dot_share[__share_iterator__]);
        for(var idx = 0; idx < _owners_dot_recipient.length; idx++) {
            if(_owners[idx].recipient != 0) {
                owners.push(_owners[idx]);
                assert(owners[idx].share > 0);
                ownersIdx[_owners[idx].recipient] = true;
            }
        }
    }

    /**
     * Function with this modifier can be called only by one of owners
     */
    modifier onlyOneOfOwners() {
        require(ownersIdx[msg.sender]);
        _;
    }


}


pragma solidity 0.4.15;

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
 * @title Blind Croupier Token
 * WIN fixed supply Token, used for Blind Croupier TokenDistribution
 */
 contract WIN is ERC20Token {
    

    string public constant symbol = "WIN";
    string public constant name = "WIN";

    uint8 public constant decimals = 7;
    uint256 constant TOKEN = 10**7;
    uint256 constant MILLION = 10**6;
    uint256 public totalTokenSupply = 500 * MILLION * TOKEN;

    /** balances of each accounts */
    mapping(address => uint256) balances;

    /** amount of tokens approved for transfer */
    mapping(address => mapping (address => uint256)) allowed;

    /** Triggered when `owner` destroys `amount` tokens */
    event Destroyed(address indexed owner, uint256 amount);

    /**
     * Constucts the token, and supplies the creator with `totalTokenSupply` tokens
     */
    function WIN ()   { 
        balances[msg.sender] = totalTokenSupply;
    }

    /**
     * Returns total supply of tokens ever emitted
     * @return result - total supply of tokens ever emitted
     */
    function totalSupply ()  constant  returns (uint256 result) { 
        result = totalTokenSupply;
    }

    /**
    * Returns `owner` balance of tokens
    * @param owner address to request balance for
    * @return balance - token balance of `owner`
    */
    function balanceOf (address owner)  constant  returns (uint256 balance) { 
        return balances[owner];
    }

    /**
     * Transfers `amount` of tokens to `to` address
     * @param  to - address to transfer to
     * @param  amount - amount of tokens to transfer
     * @return success - `true` if the transfer was succesful, `false` otherwise
     */
    function transfer (address to, uint256 amount)   returns (bool success) { 
        if(balances[msg.sender] < amount)
            return false;

        if(amount <= 0)
            return false;

        if(balances[to] + amount <= balances[to])
            return false;

        balances[msg.sender] -= amount;
        balances[to] += amount;
        Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * Transfers `amount` tokens from `from` address to `to`
     * the sender needs to have allowance for this operation
     * @param  from - address to take tokens from
     * @param  to - address to send tokens to
     * @param  amount - amount of tokens to send
     * @return success - `true` if the transfer was succesful, `false` otherwise
     */
    function transferFrom (address from, address to, uint256 amount)   returns (bool success) { 
        if (balances[from] < amount)
            return false;

        if(allowed[from][msg.sender] < amount)
            return false;

        if(amount == 0)
            return false;

        if(balances[to] + amount <= balances[to])
            return false;

        balances[from] -= amount;
        allowed[from][msg.sender] -= amount;
        balances[to] += amount;
        Transfer(from, to, amount);
        return true;
    }

    /**
     * Allow spender to withdraw from your account, multiple times, up to the amount amount.
     * If this function is called again it overwrites the current allowance with `amount`.
     * this function is required for some DEX functionality
     * @param spender - address to give allowance to
     * @param amount - the maximum amount of tokens allowed for spending
     * @return success - `true` if the allowance was given, `false` otherwise
     */
    function approve (address spender, uint256 amount)   returns (bool success) { 
       allowed[msg.sender][spender] = amount;
       Approval(msg.sender, spender, amount);
       return true;
   }

    /**
     * Returns the amount which `spender` is still allowed to withdraw from `owner`
     * @param  owner - tokens owner
     * @param  spender - addres to request allowance for
     * @return remaining - remaining allowance (token count)
     */
    function allowance (address owner, address spender)  constant  returns (uint256 remaining) { 
        return allowed[owner][spender];
    }

     /**
      * Destroys `amount` of tokens permanently, they cannot be restored
      * @return success - `true` if `amount` of tokens were destroyed, `false` otherwise
      */
    function destroy (uint256 amount)   returns (bool success) { 
        if(amount == 0) return false;
        if(balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount;
        totalTokenSupply -= amount;
        Destroyed(msg.sender, amount);
    }
}

pragma solidity 0.4.15;

/**
 * @title Various Math utilities
 */
library Math {
     /** 1/1000, 1000 uint = 1 */

    /**
     * Returns `promille` promille of `value`
     * e.g. `takePromille(5000, 1) == 5`
     * @param value - uint to take promille value
     * @param promille - promille value
     * @return result - `value * promille / 1000`
     */
    function takePromille (uint value, uint promille)  constant  returns (uint result) { 
        result = value * promille / 1000;
    }

    /**
     * Returns `value` with added `promille` promille
     * @param value - uint to add promille to
     * @param promille - promille value to add
     * @return result - `value + value * promille / 1000`
     */
    function addPromille (uint value, uint promille)  constant  returns (uint result) { 
        result = value + takePromille(value, promille);
    }
}


/**
 * @title Blind Croupier TokenDistribution
 * It possesses some `WIN` tokens.
 * The distribution is divided into many &#39;periods&#39;.
 * The zero one is `Presale` with `TOKENS_FOR_PRESALE` tokens
 * It&#39;s ended when all tokens are sold or manually with `endPresale()` function
 * The length of first period is `FIRST_PERIOD_DURATION`.
 * The length of other periods is `PERIOD_DURATION`.
 * During each period, `TOKENS_PER_PERIOD` are offered for sale (`TOKENS_PER_FIRST_PERIOD` for the first one)
 * Investors send their money to the contract
 * and call `claimAllTokens()` function to get `WIN` tokens.
 * Period 0 Token price is `PRESALE_TOKEN_PRICE`
 * Period 1 Token price is `SALE_INITIAL_TOKEN_PRICE`
 * Period 2+ price is determined by the following rules:
 * If more than `TOKENS_TO_INCREASE_NEXT_PRICE * TOKENS_PER_PERIOD / 1000`
 * were sold during the period, the price of the Tokens for the next period
 * is increased by `PERIOD_PRICE_INCREASE` promille,
 * if ALL tokens were sold, price is increased by `FULLY_SOLD_PRICE_INCREASE` promille
 * Otherwise, the price remains the same.
 */
contract BlindCroupierTokenDistribution is MultiOwnable {
    
    
    
    
    
    

    uint256 constant TOKEN = 10**7;
    uint256 constant MILLION = 10**6;

    uint256 constant MINIMUM_DEPOSIT = 100 finney; /** minimum deposit accepted to bank */
    uint256 constant PRESALE_TOKEN_PRICE = 0.00035 ether / TOKEN;
    uint256 constant SALE_INITIAL_TOKEN_PRICE = 0.0005 ether / TOKEN;

    uint256 constant TOKENS_FOR_PRESALE = 5 * MILLION * TOKEN; /** 5M tokens */
    uint256 constant TOKENS_PER_FIRST_PERIOD = 15 * MILLION * TOKEN; /** 15M tokens */
    uint256 constant TOKENS_PER_PERIOD = 1 * MILLION * TOKEN; /** 1M tokens */
    uint256 constant FIRST_PERIOD_DURATION = 161 hours; /** duration of 1st sale period */
    uint256 constant PERIOD_DURATION = 23 hours; /** duration of all other sale periods */
    uint256 constant PERIOD_PRICE_INCREASE = 5; /** `next_token_price = old_token_price + old_token_price * PERIOD_PRICE_INCREASE / 1000` */
    uint256 constant FULLY_SOLD_PRICE_INCREASE = 10; /** to increase price if ALL tokens sold */
    uint256 constant TOKENS_TO_INCREASE_NEXT_PRICE = 800; /** the price is increased if `sold_tokens > period_tokens * TOKENS_TO_INCREASE_NEXT_PRICE / 1000` */

    uint256 constant NEVER = 0;
    uint16 constant UNKNOWN_COUNTRY = 0;

    /**
     * State of Blind Croupier crowdsale
     */
    enum State {
        NotStarted,
        Presale,
        Sale
    }

    uint256 public totalUnclaimedTokens; /** total amount of tokens, TokenDistribution owns to investors */
    uint256 public totalTokensSold; /** total amount of Tokens sold during the TokenDistribution */
    uint256 public totalTokensDestroyed; /** total amount of Tokens destroyed by this contract */

    mapping(address => uint256) public unclaimedTokensForInvestor; /** unclaimed tokens for each investor */

    /**
     * One token sale period information
     */
    struct Period {
        uint256 startTime;
        uint256 endTime;
        uint256 tokenPrice;
        uint256 tokensSold;
    }

    /**
     * Emited when `investor` sends `amount` of money to the Bank
     * @param investor - address, sending the money
     * @param amount - Wei sent
     */
    event Deposited(address indexed investor, uint256 amount, uint256 tokenCount);

    /**
     * Emited when a new period is opened
     * @param periodIndex - index of new period
     * @param tokenPrice - price of WIN Token in new period
     */
    event PeriodStarted(uint periodIndex, uint256 tokenPrice, uint256 tokensToSale, uint256 startTime, uint256 endTime, uint256 now);

    /**
     * Emited when `investor` claims `claimed` tokens
     * @param investor - address getting the Tokens
     * @param claimed - amount of Tokens claimed
     */
    event TokensClaimed(address indexed investor, uint256 claimed);

    /** current Token sale period */
    uint public currentPeriod = 0;

    /** information about past and current periods, by periods index, starting from `0` */
    mapping(uint => Period) periods;

    /** WIN tokens contract  */
    WIN public win;

    /** The state of the crowdsale - `NotStarted`, `Presale`, `Sale` */
    State public state;

    /** the counter of investment by a country code (3-digit ISO 3166 code) */
    mapping(uint16 => uint256) investmentsByCountries;

    /**
     * Returns amount of Wei invested by the specified country
     * @param country - 3-digit country code
     */
    function getInvestmentsByCountry (uint16 country)   constant   returns (uint256 investment) {  
        investment = investmentsByCountries[country];
    }

    /**
     * Returns the Token price in the current period
     * @return tokenPrice - current Token price
     */
    function getTokenPrice ()   constant   returns (uint256 tokenPrice) {  
        tokenPrice = periods[currentPeriod].tokenPrice;
    }

    /**
     * Returns the Token price for the period requested
     * @param periodIndex - the period index
     * @return tokenPrice - Token price for the period
     */
    function getTokenPriceForPeriod (uint periodIndex)   constant   returns (uint256 tokenPrice) {  
        tokenPrice = periods[periodIndex].tokenPrice;
    }

    /**
     * Returns the amount of Tokens sold
     * @param period - period index to get tokens for
     * @return tokensSold - amount of tokens sold
     */
    function getTokensSold (uint period)   constant   returns (uint256 tokensSold) {  
        return periods[period].tokensSold;
    }

    /**
     * Returns `true` if TokenDistribution has enough tokens for the current period
     * and thus going on
     * @return active - `true` if TokenDistribution is going on, `false` otherwise
     */
    function isActive ()   constant   returns (bool active) {  
        return win.balanceOf(this) >= totalUnclaimedTokens + tokensForPeriod(currentPeriod) - periods[currentPeriod].tokensSold;
    }

    /**
     * Accepts money deposit and makes record
     * minimum deposit is MINIMUM_DEPOSIT
     * @param beneficiar - the address to receive Tokens
     * @param countryCode - 3-digit country code
     * @dev if `msg.value < MINIMUM_DEPOSIT` throws
     */
    function deposit (address beneficiar, uint16 countryCode)   payable  {  
        require(msg.value >= MINIMUM_DEPOSIT);
        require(state == State.Sale || state == State.Presale);

        /* this should end any finished period before starting any operations */
        tick();

        /* check if have enough tokens for the current period
         * if not, the call fails until tokens are deposited to the contract
         */
        require(isActive());

        uint256 tokensBought = msg.value / getTokenPrice();

        if(periods[currentPeriod].tokensSold + tokensBought >= tokensForPeriod(currentPeriod)) {
            tokensBought = tokensForPeriod(currentPeriod) - periods[currentPeriod].tokensSold;
        }

        uint256 moneySpent = getTokenPrice() * tokensBought;

        investmentsByCountries[countryCode] += moneySpent;

        if(tokensBought > 0) {
            assert(moneySpent <= msg.value);

            /* return the rest */
            if(msg.value > moneySpent) {
                msg.sender.transfer(msg.value - moneySpent);
            }

            periods[currentPeriod].tokensSold += tokensBought;
            unclaimedTokensForInvestor[beneficiar] += tokensBought;
            totalUnclaimedTokens += tokensBought;
            totalTokensSold += tokensBought;
            Deposited(msg.sender, moneySpent, tokensBought);
        }

        /* if all tokens are sold, get to the next period */
        tick();
    }

    /**
     * See `deposit` function
     */
    function() payable {
        deposit(msg.sender, UNKNOWN_COUNTRY);
    }

    /**
     * Creates the contract and sets the owners
     * @param owners_dot_recipient - array of 16 owner records  (MultiOwnable.Owner.recipient fields)
* @param owners_dot_share - array of 16 owner records  (MultiOwnable.Owner.share fields)
     */
    function BlindCroupierTokenDistribution (address[16] owners_dot_recipient, uint[16] owners_dot_share)   MultiOwnable(owners_dot_recipient, owners_dot_share)  {  
MultiOwnable.Owner[16] memory owners;

for(uint __recipient_iterator__ = 0; __recipient_iterator__ < owners_dot_recipient.length;__recipient_iterator__++)
  owners[__recipient_iterator__].recipient = address(owners_dot_recipient[__recipient_iterator__]);
for(uint __share_iterator__ = 0; __share_iterator__ < owners_dot_share.length;__share_iterator__++)
  owners[__share_iterator__].share = uint(owners_dot_share[__share_iterator__]);
        state = State.NotStarted;
    }

    /**
     * Begins the crowdsale (presale period)
     * @param tokenContractAddress - address of the `WIN` contract (token holder)
     * @dev must be called by one of owners
     */
    function startPresale (address tokenContractAddress)   onlyOneOfOwners  {  
        require(state == State.NotStarted);

        win = WIN(tokenContractAddress);

        assert(win.balanceOf(this) >= tokensForPeriod(0));

        periods[0] = Period(now, NEVER, PRESALE_TOKEN_PRICE, 0);
        PeriodStarted(0,
            PRESALE_TOKEN_PRICE,
            tokensForPeriod(currentPeriod),
            now,
            NEVER,
            now);
        state = State.Presale;
    }

    /**
     * Ends the presale and begins period 1 of the crowdsale
     * @dev must be called by one of owners
     */
    function endPresale ()   onlyOneOfOwners  {  
        require(state == State.Presale);
        state = State.Sale;
        nextPeriod();
    }

    /**
     * Returns a time interval for a specific `period`
     * @param  period - period index to count interval for
     * @return startTime - timestamp of period start time (INCLUSIVE)
     * @return endTime - timestamp of period end time (INCLUSIVE)
     */
    function periodTimeFrame (uint period)   constant   returns (uint256 startTime, uint256 endTime) {  
        require(period <= currentPeriod);

        startTime = periods[period].startTime;
        endTime = periods[period].endTime;
    }

    /**
     * Returns `true` if the time for the `period` has already passed
     */
    function isPeriodTimePassed (uint period)   constant   returns (bool finished) {  
        require(periods[period].startTime > 0);

        uint256 endTime = periods[period].endTime;

        if(endTime == NEVER) {
            return false;
        }

        return (endTime < now);
    }

    /**
     * Returns `true` if `period` has already finished (time passed or tokens sold)
     */
    function isPeriodClosed (uint period)   constant   returns (bool finished) {  
        return period < currentPeriod;
    }

    /**
     * Returns `true` if all tokens for the `period` has been sold
     */
    function isPeriodAllTokensSold (uint period)   constant   returns (bool finished) {  
        return periods[period].tokensSold == tokensForPeriod(period);
    }

    /**
     * Returns unclaimed Tokens count for the caller
     * @return tokens - amount of unclaimed Tokens for the caller
     */
    function unclaimedTokens ()   constant   returns (uint256 tokens) {  
        return unclaimedTokensForInvestor[msg.sender];
    }

    /**
     * Transfers all the tokens stored for this `investor` to his address
     * @param investor - investor to claim tokens for
     */
    function claimAllTokensForInvestor (address investor)   {  
        assert(totalUnclaimedTokens >= unclaimedTokensForInvestor[investor]);
        totalUnclaimedTokens -= unclaimedTokensForInvestor[investor];
        win.transfer(investor, unclaimedTokensForInvestor[investor]);
        TokensClaimed(investor, unclaimedTokensForInvestor[investor]);
        unclaimedTokensForInvestor[investor] = 0;
    }

    /**
     * Claims all the tokens for the sender
     * @dev efficiently calling `claimAllForInvestor(msg.sender)`
     */
    function claimAllTokens ()   {  
        claimAllTokensForInvestor(msg.sender);
    }

    /**
     * Returns the total token count for the period specified
     * @param  period - period number
     * @return tokens - total tokens count
     */
    function tokensForPeriod (uint period)   constant   returns (uint256 tokens) {  
        if(period == 0) {
            return TOKENS_FOR_PRESALE;
        } else if(period == 1) {
            return TOKENS_PER_FIRST_PERIOD;
        } else {
            return TOKENS_PER_PERIOD;
        }
    }

    /**
     * Returns the duration of the sale (not presale) period
     * @param  period - the period number
     * @return duration - duration in seconds
     */
    function periodDuration (uint period)   constant   returns (uint256 duration) {  
        require(period > 0);

        if(period == 1) {
            return FIRST_PERIOD_DURATION;
        } else {
            return PERIOD_DURATION;
        }
    }

    /**
     * Finishes the current period and starts a new one
     */
    function nextPeriod() internal {
        uint256 oldPrice = periods[currentPeriod].tokenPrice;
        uint256 newPrice;
        if(currentPeriod == 0) {
            newPrice = SALE_INITIAL_TOKEN_PRICE;
        } else if(periods[currentPeriod].tokensSold  == tokensForPeriod(currentPeriod)) {
            newPrice = Math.addPromille(oldPrice, FULLY_SOLD_PRICE_INCREASE);
        } else if(periods[currentPeriod].tokensSold >= Math.takePromille(tokensForPeriod(currentPeriod), TOKENS_TO_INCREASE_NEXT_PRICE)) {
            newPrice = Math.addPromille(oldPrice, PERIOD_PRICE_INCREASE);
        } else {
            newPrice = oldPrice;
        }

        /* destroy unsold tokens */
        if(periods[currentPeriod].tokensSold < tokensForPeriod(currentPeriod)) {
            uint256 toDestroy = tokensForPeriod(currentPeriod) - periods[currentPeriod].tokensSold;
            /* do not destroy if we don&#39;t have enough to pay investors */
            uint256 balance = win.balanceOf(this);
            if(balance < toDestroy + totalUnclaimedTokens) {
                toDestroy = (balance - totalUnclaimedTokens);
            }
            win.destroy(toDestroy);
            totalTokensDestroyed += toDestroy;
        }

        /* if we are force ending the period set in the future or without end time,
         * set end time to now
         */
        if(periods[currentPeriod].endTime > now ||
            periods[currentPeriod].endTime == NEVER) {
            periods[currentPeriod].endTime = now;
        }

        uint256 duration = periodDuration(currentPeriod + 1);

        periods[currentPeriod + 1] = Period(
            periods[currentPeriod].endTime,
            periods[currentPeriod].endTime + duration,
            newPrice,
            0);

        currentPeriod++;

        PeriodStarted(currentPeriod,
            newPrice,
            tokensForPeriod(currentPeriod),
            periods[currentPeriod].startTime,
            periods[currentPeriod].endTime,
            now);
    }

    /**
     * To be called as frequently as required by any external party
     * Will check if 1 or more periods have finished and move on to the next
     */
    function tick ()   {  
        if(!isActive()) {
            return;
        }

        while(state == State.Sale &&
            (isPeriodTimePassed(currentPeriod) ||
            isPeriodAllTokensSold(currentPeriod))) {
            nextPeriod();
        }
    }

    /**
     * Withdraws the money to be spent to Blind Croupier Project needs
     * @param  amount - amount of Wei to withdraw (total)
     */
    function withdraw (uint256 amount)   onlyOneOfOwners  {  
        require(this.balance >= amount);

        uint totalShares = 0;
        for(var idx = 0; idx < owners.length; idx++) {
            totalShares += owners[idx].share;
        }

        for(idx = 0; idx < owners.length; idx++) {
            owners[idx].recipient.transfer(amount * owners[idx].share / totalShares);
        }
    }
}