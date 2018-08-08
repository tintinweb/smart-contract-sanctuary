pragma solidity ^0.4.13;

/**
 * Overflow aware uint math functions.
 *
 * Inspired by https://github.com/MakerDAO/maker-otc/blob/master/contracts/simple_market.sol
 */
contract SafeMath {
    //internals

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
}


/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
interface Token {

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is Token {

    /**
     * Reviewed:
     * - Integer overflow = OK, checked
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            //if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
}


/**
 * PIX crowdsale ICO contract.
 *
 * Security criteria evaluated against http://ethereum.stackexchange.com/questions/8551/methodological-security-review-of-a-smart-contract
 *
 *
 */
contract PIXToken is StandardToken, SafeMath {

    string public name = "PIX Token";
    string public symbol = "PIX";

    // Initial founder address (set in constructor)
    // This address is used as a controller address, in order to properly handle administration of the token.
    address public founder = 0x0;

    // Deposit Address - The funds will be sent here immediately after payments are made to the contract
    address public deposit = 0x0;

    /*
    Multi-stage sale contract.

    Notes:
    All token sales are tied to USD.  No token sales are for a fixed amount of Wei, this can shift and change over time.
    Due to this, the following needs to be paid attention to:
    1. The value of the token fluctuates in reference to the centsPerEth set on the contract.
    2. The tokens are priced in cents.  So all token purchases will be calculated out live at that time.

    Funding Stages:
    1. Pre-Sale, there will be 15M USD ( 125M tokens ) for sale. Bonus of 20%
    2. Day 1 sale, there will be 20M USD - the pre-sale amount of tokens for sale. (~166.6m tokens - Pre-Sale tokens) Bonus of 15%
    3. Day 2 sale, there will be 20M USD (~166.6m tokens) tokens for sale.  Bonus of 10%
    4. Days 3-10 sale, there will be 20M USD (~166.6m tokens) tokens for sale.  Bonus of 5%

    Post-Sale:
    1. 30% of the total token count is reserved for release every year, at 1/4th of the originally reserved value per year.
    2. 20% of the total token count [Minus the number of excess bonus tokens from the pre-sale] is issued out to the team when the sale has completed.
    3. Purchased tokens come available to be withdrawn 31 days after the sale has completed.
    */

    enum State { PreSale, Day1, Day2, Day3, Running, Halted } // the states through which this contract goes
    State state;

    // Pricing for the pre-sale in US Cents.
    uint public capPreSale = 15 * 10**8;  // 15M USD cap for pre-sale, this subtracts from day1 cap
    uint public capDay1 = 20 * 10**8;  // 20M USD cap for day 1
    uint public capDay2 = 20 * 10**8;  // 20M USD cap for day 2
    uint public capDay3 = 20 * 10**8;  // 20M USD cap for day 3 - 10

    // Token pricing information
    uint public weiPerEther = 10**18;
    uint public centsPerEth = 23000;
    uint public centsPerToken = 12;

    // Amount of funds raised in stages of pre-sale
    uint public raisePreSale = 0;  // USD raise during the pre-sale period
    uint public raiseDay1 = 0;  // USD raised on Day 1
    uint public raiseDay2 = 0;  // USD raised on Day 2
    uint public raiseDay3 = 0;  // USD raised during days 3-10

    // Block timing/contract unlocking information
    uint public publicSaleStart = 1502280000; // Aug 9, 2017 Noon UTC
    uint public day2Start = 1502366400; // Aug 10, 2017 Noon UTC
    uint public day3Start = 1502452800; // Aug 11, 2017 Noon UTC
    uint public saleEnd = 1503144000; // Aug 19, 2017 Noon UTC
    uint public coinTradeStart = 1505822400; // Sep 19, 2017 Noon UTC
    uint public year1Unlock = 1534680000; // Aug 19, 2018 Noon UTC
    uint public year2Unlock = 1566216000; // Aug 19, 2019 Noon UTC
    uint public year3Unlock = 1597838400; // Aug 19, 2020 Noon UTC
    uint public year4Unlock = 1629374400; // Aug 19, 2021 Noon UTC

    // Have the post-reward allocations been completed
    bool public allocatedFounders = false;
    bool public allocated1Year = false;
    bool public allocated2Year = false;
    bool public allocated3Year = false;
    bool public allocated4Year = false;

    // Token count information
    uint public totalTokensSale = 500000000; //total number of tokens being sold in the ICO, excluding bonuses, reserve, and team distributions
    uint public totalTokensReserve = 330000000;
    uint public totalTokensCompany = 220000000;

    bool public halted = false; //the founder address can set this to true to halt the crowdsale due to emergency.

    mapping(address => uint256) presaleWhitelist; // Pre-sale Whitelist

    event Buy(address indexed sender, uint eth, uint fbt);
    event Withdraw(address indexed sender, address to, uint eth);
    event AllocateTokens(address indexed sender);

    function PIXToken(address depositAddress) {
        /*
            Initialize the contract with a sane set of owners
        */
        founder = msg.sender;  // Allocate the founder address as a usable address separate from deposit.
        deposit = depositAddress;  // Store the deposit address.
    }

    function setETHUSDRate(uint centsPerEthInput) public {
        /*
            Sets the current ETH/USD Exchange rate in cents.  This modifies the token price in Wei.
        */
        require(msg.sender == founder);
        centsPerEth = centsPerEthInput;
    }

    /*
        Gets the current state of the contract based on the block number involved in the current transaction.
    */
    function getCurrentState() constant public returns (State) {

        if(halted) return State.Halted;
        else if(block.timestamp < publicSaleStart) return State.PreSale;
        else if(block.timestamp > publicSaleStart && block.timestamp <= day2Start) return State.Day1;
        else if(block.timestamp > day2Start && block.timestamp <= day3Start) return State.Day2;
        else if(block.timestamp > day3Start && block.timestamp <= saleEnd) return State.Day3;
        else return State.Running;
    }

    /*
        Gets the current amount of bonus per purchase in percent.
    */
    function getCurrentBonusInPercent() constant public returns (uint) {
        State s = getCurrentState();
        if (s == State.Halted) revert();
        else if(s == State.PreSale) return 20;
        else if(s == State.Day1) return 15;
        else if(s == State.Day2) return 10;
        else if(s == State.Day3) return 5;
        else return 0;
    }

    /*
        Get the current price of the token in WEI.  This should be the weiPerEther/centsPerEth * centsPerToken
    */
    function getTokenPriceInWEI() constant public returns (uint){
        uint weiPerCent = safeDiv(weiPerEther, centsPerEth);
        return safeMul(weiPerCent, centsPerToken);
    }

    /*
        Entry point for purchasing for one&#39;s self.
    */
    function buy() payable public {
        buyRecipient(msg.sender);
    }

    /*
        Main purchasing function for the contract
        1. Should validate the current state, from the getCurrentState() function
        2. Should only allow the founder to order during the pre-sale
        3. Should correctly calculate the values to be paid out during different stages of the contract.
    */
    function buyRecipient(address recipient) payable public {
        State current_state = getCurrentState(); // Get the current state of the contract.
        uint usdCentsRaise = safeDiv(safeMul(msg.value, centsPerEth), weiPerEther); // Get the current number of cents raised by the payment.

        if(current_state == State.PreSale)
        {
            require (presaleWhitelist[msg.sender] > 0);
            raisePreSale = safeAdd(raisePreSale, usdCentsRaise); //add current raise to pre-sell amount
            require(raisePreSale < capPreSale && usdCentsRaise < presaleWhitelist[msg.sender]); //ensure pre-sale cap, 15m usd * 100 so we have cents
            presaleWhitelist[msg.sender] = presaleWhitelist[msg.sender] - usdCentsRaise; // Remove the amount purchased from the pre-sale permitted for that user
        }
        else if (current_state == State.Day1)
        {
            raiseDay1 = safeAdd(raiseDay1, usdCentsRaise); //add current raise to pre-sell amount
            require(raiseDay1 < (capDay1 - raisePreSale)); //ensure day 1 cap, which is lower by the amount we pre-sold
        }
        else if (current_state == State.Day2)
        {
            raiseDay2 = safeAdd(raiseDay2, usdCentsRaise); //add current raise to pre-sell amount
            require(raiseDay2 < capDay2); //ensure day 2 cap
        }
        else if (current_state == State.Day3)
        {
            raiseDay3 = safeAdd(raiseDay3, usdCentsRaise); //add current raise to pre-sell amount
            require(raiseDay3 < capDay3); //ensure day 3 cap
        }
        else revert();

        uint tokens = safeDiv(msg.value, getTokenPriceInWEI()); // Calculate number of tokens to be paid out
        uint bonus = safeDiv(safeMul(tokens, getCurrentBonusInPercent()), 100); // Calculate number of bonus tokens

        if (current_state == State.PreSale) {
            // Remove the extra 5% from the totalTokensCompany, in order to keep the 550m on track.
            totalTokensCompany = safeSub(totalTokensCompany, safeDiv(bonus, 4));
        }

        uint totalTokens = safeAdd(tokens, bonus);

        balances[recipient] = safeAdd(balances[recipient], totalTokens);
        totalSupply = safeAdd(totalSupply, totalTokens);

        deposit.transfer(msg.value); // Send deposited Ether to the deposit address on file.

        Buy(recipient, msg.value, totalTokens);
    }

    /*
        Allocate reserved and founders tokens based on the running time and state of the contract.
     */
    function allocateReserveAndFounderTokens() {
        require(msg.sender==founder);
        require(getCurrentState() == State.Running);
        uint tokens = 0;

        if(block.timestamp > saleEnd && !allocatedFounders)
        {
            allocatedFounders = true;
            tokens = totalTokensCompany;
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year1Unlock && !allocated1Year)
        {
            allocated1Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year2Unlock && !allocated2Year)
        {
            allocated2Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year3Unlock && !allocated3Year)
        {
            allocated3Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year4Unlock && !allocated4Year)
        {
            allocated4Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else revert();

        AllocateTokens(msg.sender);
    }

    /**
     * Emergency Stop ICO.
     *
     *  Applicable tests:
     *
     * - Test unhalting, buying, and succeeding
     */
    function halt() {
        require(msg.sender==founder);
        halted = true;
    }

    function unhalt() {
        require(msg.sender==founder);
        halted = false;
    }

    /*
        Change founder address (Controlling address for contract)
    */
    function changeFounder(address newFounder) {
        require(msg.sender==founder);
        founder = newFounder;
    }

    /*
        Change deposit address (Address to which funds are deposited)
    */
    function changeDeposit(address newDeposit) {
        require(msg.sender==founder);
        deposit = newDeposit;
    }

    /*
        Add people to the pre-sale whitelist
        Amount should be the value in USD that the purchaser is allowed to buy
        IE: 100 is $100 is 10000 cents.  The correct value to enter is 100
    */
    function addPresaleWhitelist(address toWhitelist, uint256 amount){
        require(msg.sender==founder && amount > 0);
        presaleWhitelist[toWhitelist] = amount * 100;
    }

    /**
     * ERC 20 Standard Token interface transfer function
     *
     * Prevent transfers until freeze period is over.
     *
     * Applicable tests:
     *
     * - Test restricted early transfer
     * - Test transfer after restricted period
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(block.timestamp > coinTradeStart);
        return super.transfer(_to, _value);
    }
    /**
     * ERC 20 Standard Token interface transfer function
     *
     * Prevent transfers until freeze period is over.
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(block.timestamp > coinTradeStart);
        return super.transferFrom(_from, _to, _value);
    }

    function() payable {
        buyRecipient(msg.sender);
    }

}