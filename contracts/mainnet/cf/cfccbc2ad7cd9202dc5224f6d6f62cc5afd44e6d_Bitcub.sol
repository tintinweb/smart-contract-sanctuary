pragma solidity ^0.4.18;

library SafeMath {
    //SafeMath library for preventing overflow when dealing with uint256 in solidity

   /**
   * @dev Multiplies two numbers, throws on overflow.
   */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20 {
    //ERC20 contract used as an interface. Implementation of functions provided in the derived contract.

    string public NAME;
    string public SYMBOL;
    uint8 public DECIMALS = 18; // 18 DECIMALS is the strongly suggested default, avoid changing it

    //total supply (TOTALSUPPLY) is declared private and can be accessed via totalSupply()
    uint private TOTALSUPPLY;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    //This is a mapping of a mapping
    // This mapping keeps track of the allowances given
    mapping(address => mapping (address => uint256)) allowed;

                 //*** ERC20 FUNCTIONS ***//
    //1
    //Allows an instance of a contract to calculate and return the total amount
    //of the token that exists.
    function totalSupply() public constant returns (uint256 _totalSupply);

    //2
    //Allows a contract to store and return the balance of the provided address (parameter)
    function balanceOf(address _owner) public constant returns (uint256 balance);

    //3
    //Lets the caller send a given amount(_amount) of the token to another address(_to).
    //Note: returns a boolean indicating whether transfer was successful
    function transfer(address _to, uint256 _value) public returns (bool success);

    //4
    //Owner "approves" the given address to withdraw instances of the tokens from the owners address
    function approve(address _spender, uint256 _value) public returns (bool success);

    //5
    //Lets an "approved" address transfer the approved amount from the address that called approve()
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    //6
    //returns the amount of tokens approved by the owner that can *Still* be transferred
    //to the spender&#39;s account using the transferFrom method.
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

            //***ERC20 Events***//
    //Event 1
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //Event 2
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    //Event triggered when owner address is changed.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract Bitcub is Ownable, ERC20 {
    using SafeMath for uint256;

    string public constant NAME = "Bitcub";
    string public constant SYMBOL = "BCU";
    uint8 public constant DECIMALS = 18; // 18 DECIMALS is the strongly suggested default, avoid changing it

    //total supply (TOTALSUPPLY) is declared private and constant and can be accessed via totalSupply()
    uint private constant TOTALSUPPLY = 500000000*(10**18);

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    //This is a mapping of a mapping
    // This mapping keeps track of the allowances given
    mapping(address => mapping (address => uint256)) allowed;

    //Constructor FOR BITCUB TOKEN
    constructor() public {
        //establishes ownership of the contract upon creation
        Ownable(msg.sender);

        /* IMPLEMENTING ALLOCATION OF TOKENS */
        balances[0xaf0A558783E92a1aEC9dd2D10f2Dc9b9AF371212] = 150000000*(10**18);
        /* Transfer Events for the allocations */
        emit Transfer(address(0), 0xaf0A558783E92a1aEC9dd2D10f2Dc9b9AF371212, 150000000*(10**18));

        //sends all the unallocated tokens (350,000,000 tokens) to the address of the contract creator (The Crowdsale Contract)
        balances[msg.sender] = TOTALSUPPLY.sub(150000000*(10**18)); 
        //Transfer event for sending tokens to Crowdsale Contract
        emit Transfer(address(0), msg.sender, TOTALSUPPLY.sub(150000000*(10**18)));
    }

                 //*** ERC20 FUNCTIONS ***//
    //1
    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public constant returns (uint256 _totalSupply) {
        //set the named return variable as the global variable totalSupply
        _totalSupply = TOTALSUPPLY;
    }

    //2
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    //3
    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    //Note: returns a boolean indicating whether transfer was successful
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)); //not sending to burn address
        require(_value <= balances[msg.sender]); // If the sender has sufficient funds to send
        require(_value>0);// and the amount is not zero or negative

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    //4
    //Owner "approves" the given address to withdraw instances of the tokens from the owners address
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
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //5
    //Lets an "approved" address transfer the approved amount from the address that called approve()
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    //6
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    //additional functions for altering allowances
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

              //***ERC20 Events***//
    //Event 1
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //Event 2
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

}


//Using OpenZeppelin Crowdsale contract as a reference and altered, also using ethereum.org/Crowdsale as a reference.
/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.

 //The original OpenZeppelin contract requires a MintableToken that will be
 * minted as contributions arrive, note that the crowdsale contract
 * must be owner of the token in order to be able to mint it.
 //This version does not use a MintableToken.
 */
contract BitcubCrowdsale is Ownable {
    using SafeMath for uint256;

    // The token being sold
    Bitcub public token;

    //The amount of the tokens remaining that are unsold.
    uint256 remainingTokens = 350000000 *(10**18);

    // start and end timestamps where investments are allowed (inclusive), as well as timestamps for beginning and end of presale tiers
    uint256 public startTime;
    uint256 public endTime;
    uint256 public tier1Start;
    uint256 public tier1End;
    uint256 public tier2Start;
    uint256 public tier2End;

    // address where funds are collected
    address public etherWallet;
    // address where unsold tokens are sent
    address public tokenWallet;

    // how many token units a buyer gets per wei
    uint256 public rate = 100;

    // amount of raised money in wei
    uint256 public weiRaised;

    //minimum purchase for an buyer in amount of ether (1 token)
    uint256 public minPurchaseInEth = 0.01 ether;
  
    //maximum investment for an investor in amount of tokens
    //To set max investment to 5% of total, it is 25,000,000 tokens, which is 250000 ETH
    uint256 public maxInvestment = 250000 ether;
  
    //mapping to keep track of the amount invested by each address.
    mapping (address => uint256) internal invested;


    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    //Constructor for crowdsale.
    constructor() public {
        //hard coded times and wallets 
        startTime = now ;
        tier1Start = startTime ;
        tier1End = 1528416000 ; //midnight on 2018-06-08 GMT
        tier2Start = tier1End;
        tier2End = 1532131200 ; //midnight on 2018-07-21 GMT
        endTime = 1538265600 ; //midnight on 2018-09-30 GMT
        etherWallet = 0xaf0A558783E92a1aEC9dd2D10f2Dc9b9AF371212;
        tokenWallet = 0xaf0A558783E92a1aEC9dd2D10f2Dc9b9AF371212;

        require(startTime >= now);
        require(endTime >= startTime);
        require(etherWallet != address(0));

        //establishes ownership of the contract upon creation
        Ownable(msg.sender);

        //calls the function to create the token contract itself.
        token = createTokenContract();
    }

    function createTokenContract() internal returns (Bitcub) {
      // Create Token contract
      // The amount for sale will be assigned to the crowdsale contract, the reserves will be sent to the Bitcub Wallet
        return new Bitcub();
    }

    // fallback function can be used to buy tokens
    //This function is called whenever ether is sent to this contract address.
    function () external payable {
        //calls the buyTokens function with the address of the sender as the beneficiary address
        buyTokens(msg.sender);
    }

    //This function is called after the ICO has ended to send the unsold Tokens to the specified address
    function finalizeCrowdsale() public onlyOwner returns (bool) {
        require(hasEnded());
        require(token.transfer(tokenWallet, remainingTokens));
        return true;
    }

    // low level token purchase function
    //implements the logic for the token buying
    function buyTokens(address beneficiary) public payable {
        //tokens cannot be burned by sending to 0x0 address
        require(beneficiary != address(0));
        //token must adhere to the valid restrictions of the validPurchase() function, ie within time period and buying tokens within max/min limits
        require(validPurchase(beneficiary));

        uint256 weiAmount = msg.value;

        // calculate token amount to be bought
        uint256 tokens = getTokenAmount(weiAmount);

        //Logic so that investors must purchase at least 1 token.
        require(weiAmount >= minPurchaseInEth); 

        //Token transfer
        require(token.transfer(beneficiary, tokens));

        // update state
        //increment the total ammount raised by the amount of this transaction
        weiRaised = weiRaised.add(weiAmount);
        //decrease the amount of remainingTokens by the amount of tokens sold
        remainingTokens = remainingTokens.sub(tokens);
        //increase the investment total of the buyer
        invested[beneficiary] = invested[beneficiary].add(msg.value);

        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        //transfer the ether received to the specified recipient address
        forwardFunds();
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    // Function to have a way to add business logic to your crowdsale when buying
    function getTokenAmount(uint256 weiAmount) internal returns(uint256) {
        //Logic for pricing based on the Tiers of the crowdsale
        // These bonus amounts and the number of tiers itself can be changed
        /*This means that:
            - If you purchase within the tier 1 ICO (earliest tier)
            you receive a 20% bonus in your token purchase.
            - If you purchase within the tier 2 ICO (later tier)
            you receive a 10% bonus in your token purchase.
            - If you purchase outside of any of the defined bonus tiers then you
            receive the original rate of tokens (1 token per 0.01 ether)
            */
        if (now>=tier1Start && now < tier1End) {
            rate = 120;
        }else if (now>=tier2Start && now < tier2End) {
            rate = 110;
        }else {
            rate = 100;
        }

        return weiAmount.mul(rate);
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        etherWallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase(address beneficiary) internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool withinMaxInvestment = ( invested[beneficiary].add(msg.value) <= maxInvestment );

        return withinPeriod && nonZeroPurchase && withinMaxInvestment;
    }

}