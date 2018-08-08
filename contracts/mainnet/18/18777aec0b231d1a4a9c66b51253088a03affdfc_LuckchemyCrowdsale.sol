pragma solidity ^0.4.21;

contract LuckchemyCrowdsale {
    using SafeMath for uint256;

    //  Token for selling
    LuckchemyToken public token;

    /*
    *  Start and End date of investment process
    */

    // 2018-04-30 00:00:00 GMT - start time for public sale
    uint256 public constant START_TIME_SALE = 1525046400;

    // 2018-07-20 23:59:59 GMT - end time for public sale
    uint256 public constant END_TIME_SALE = 1532131199;

    // 2018-04-02 00:00:00 GMT - start time for private sale
    uint256 public constant START_TIME_PRESALE = 1522627200;

    // 2018-04-24 23:59:59 GMT - end time for private sale
    uint256 public constant END_TIME_PRESALE = 1524614399;


    // amount of already sold tokens
    uint256 public tokensSold = 0;

    //supply for crowdSale
    uint256 public totalSupply = 0;
    // hard cap
    uint256 public constant hardCap = 45360 ether;
    // soft cap
    uint256 public constant softCap = 2000 ether;

    // wei representation of collected fiat
    uint256 public fiatBalance = 0;
    // ether collected in wei
    uint256 public ethBalance = 0;

    //address of serviceAgent (it can calls  payFiat function)
    address public serviceAgent;

    // owner of the contract
    address public owner;

    //default token rate
    uint256 public constant RATE = 12500; // Token price in ETH - 0.00008 ETH  1 ETHER = 12500 tokens

    // 2018/04/30 - 2018/07/22  
    uint256 public constant DISCOUNT_PRIVATE_PRESALE = 80; // 80 % discount

    // 2018/04/30 - 2018/07/20
    uint256 public constant DISCOUNT_STAGE_ONE = 40;  // 40% discount

    // 2018/04/02 - 2018/04/24   
    uint256 public constant DISCOUNT_STAGE_TWO = 20; // 20% discount

    // 2018/04/30 - 2018/07/22  
    uint256 public constant DISCOUNT_STAGE_THREE = 0;




    //White list of addresses that are allowed to by a token
    mapping(address => bool) public whitelist;


    /**
     * List of addresses for ICO fund with shares in %
     * 
     */
    uint256 public constant LOTTERY_FUND_SHARE = 40;
    uint256 public constant OPERATIONS_SHARE = 50;
    uint256 public constant PARTNERS_SHARE = 10;

    address public constant LOTTERY_FUND_ADDRESS = 0x84137CB59076a61F3f94B2C39Da8fbCb63B6f096;
    address public constant OPERATIONS_ADDRESS = 0xEBBeAA0699837De527B29A03ECC914159D939Eea;
    address public constant PARTNERS_ADDRESS = 0x820502e8c80352f6e11Ce036DF03ceeEBE002642;

    /**
     * event for token ETH purchase  logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenETHPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    /**
     * event for token FIAT purchase  logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param amount amount of tokens purchased
     */
    event TokenFiatPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);

    /*
     * modifier which gives specific rights to owner
     */
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    /*
     * modifier which gives possibility to call payFiat function
     */
    modifier onlyServiceAgent(){
        require(msg.sender == serviceAgent);
        _;
    }

    /*
    *
    *modifier which gives possibility to purchase
    *
    */
    modifier onlyWhiteList(address _address){
        require(whitelist[_address] == true);
        _;
    }
    /*
     * Enum which defines stages of ICO
    */

    enum Stage {
        Private,
        Discount40,
        Discount20,
        NoDiscount
    }

    //current stage
    Stage public  currentStage;

    //pools of token for each stage
    mapping(uint256 => uint256) public tokenPools;

    //number of tokens per 1 ether for each stage
    mapping(uint256 => uint256) public stageRates;

    /*
    * deposit is amount in wei , which was sent to the contract
    * @ address - address of depositor
    * @ uint256 - amount
    */
    mapping(address => uint256) public deposits;

    /* 
    * constructor of contract 
    *  @ _service- address which has rights to call payFiat
    */
    function LuckchemyCrowdsale(address _service) public {
        require(START_TIME_SALE >= now);
        require(START_TIME_SALE > END_TIME_PRESALE);
        require(END_TIME_SALE > START_TIME_SALE);

        require(_service != 0x0);

        owner = msg.sender;
        serviceAgent = _service;
        token = new LuckchemyToken();
        totalSupply = token.CROWDSALE_SUPPLY();

        currentStage = Stage.Private;

        uint256 decimals = uint256(token.decimals());

        tokenPools[uint256(Stage.Private)] = 70000000 * (10 ** decimals);
        tokenPools[uint256(Stage.Discount40)] = 105000000 * (10 ** decimals);
        tokenPools[uint256(Stage.Discount20)] = 175000000 * (10 ** decimals);
        tokenPools[uint256(Stage.NoDiscount)] = 350000000 * (10 ** decimals);

        stageRates[uint256(Stage.Private)] = RATE.mul(10 ** decimals).mul(100).div(100 - DISCOUNT_PRIVATE_PRESALE);
        stageRates[uint256(Stage.Discount40)] = RATE.mul(10 ** decimals).mul(100).div(100 - DISCOUNT_STAGE_ONE);
        stageRates[uint256(Stage.Discount20)] = RATE.mul(10 ** decimals).mul(100).div(100 - DISCOUNT_STAGE_TWO);
        stageRates[uint256(Stage.NoDiscount)] = RATE.mul(10 ** decimals).mul(100).div(100 - DISCOUNT_STAGE_THREE);

    }

    /*
     * function to get amount ,which invested by depositor
     * @depositor - address ,which bought tokens
    */
    function depositOf(address depositor) public constant returns (uint256) {
        return deposits[depositor];
    }
    /*
     * fallback function can be used to buy  tokens
     */
    function() public payable {
        payETH(msg.sender);
    }


    /*
    * function for tracking ethereum purchases
    * @beneficiary - address ,which received tokens
    */
    function payETH(address beneficiary) public onlyWhiteList(beneficiary) payable {

        require(msg.value >= 0.1 ether);
        require(beneficiary != 0x0);
        require(validPurchase());
        if (isPrivateSale()) {
            processPrivatePurchase(msg.value, beneficiary);
        } else {
            processPublicPurchase(msg.value, beneficiary);
        }


    }

    /*
     * function for processing purchase in private sale
     * @weiAmount - amount of wei , which send to the contract
     * @beneficiary - address for receiving tokens
     */
    function processPrivatePurchase(uint256 weiAmount, address beneficiary) private {

        uint256 stage = uint256(Stage.Private);

        require(currentStage == Stage.Private);
        require(tokenPools[stage] > 0);

        //calculate number tokens
        uint256 tokensToBuy = (weiAmount.mul(stageRates[stage])).div(1 ether);
        if (tokensToBuy <= tokenPools[stage]) {
            //pool has enough tokens
            payoutTokens(beneficiary, tokensToBuy, weiAmount);

        } else {
            //pool doesn&#39;t have enough tokens
            tokensToBuy = tokenPools[stage];
            //left wei
            uint256 usedWei = (tokensToBuy.mul(1 ether)).div(stageRates[stage]);
            uint256 leftWei = weiAmount.sub(usedWei);

            payoutTokens(beneficiary, tokensToBuy, usedWei);

            //change stage to Public Sale
            currentStage = Stage.Discount40;

            //return left wei to beneficiary and change stage
            beneficiary.transfer(leftWei);
        }
    }
    /*
    * function for processing purchase in public sale
    * @weiAmount - amount of wei , which send to the contract
    * @beneficiary - address for receiving tokens
    */
    function processPublicPurchase(uint256 weiAmount, address beneficiary) private {

        if (currentStage == Stage.Private) {
            currentStage = Stage.Discount40;
            tokenPools[uint256(Stage.Discount40)] = tokenPools[uint256(Stage.Discount40)].add(tokenPools[uint256(Stage.Private)]);
            tokenPools[uint256(Stage.Private)] = 0;
        }

        for (uint256 stage = uint256(currentStage); stage <= 3; stage++) {

            //calculate number tokens
            uint256 tokensToBuy = (weiAmount.mul(stageRates[stage])).div(1 ether);

            if (tokensToBuy <= tokenPools[stage]) {
                //pool has enough tokens
                payoutTokens(beneficiary, tokensToBuy, weiAmount);

                break;
            } else {
                //pool doesn&#39;t have enough tokens
                tokensToBuy = tokenPools[stage];
                //left wei
                uint256 usedWei = (tokensToBuy.mul(1 ether)).div(stageRates[stage]);
                uint256 leftWei = weiAmount.sub(usedWei);

                payoutTokens(beneficiary, tokensToBuy, usedWei);

                if (stage == 3) {
                    //return unused wei when all tokens sold
                    beneficiary.transfer(leftWei);
                    break;
                } else {
                    weiAmount = leftWei;
                    //change current stage
                    currentStage = Stage(stage + 1);
                }
            }
        }
    }
    /*
     * function for actual payout in public sale
     * @beneficiary - address for receiving tokens
     * @tokenAmount - amount of tokens to payout
     * @weiAmount - amount of wei used
     */
    function payoutTokens(address beneficiary, uint256 tokenAmount, uint256 weiAmount) private {
        uint256 stage = uint256(currentStage);
        tokensSold = tokensSold.add(tokenAmount);
        tokenPools[stage] = tokenPools[stage].sub(tokenAmount);
        deposits[beneficiary] = deposits[beneficiary].add(weiAmount);
        ethBalance = ethBalance.add(weiAmount);

        token.transfer(beneficiary, tokenAmount);
        TokenETHPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
    }
    /*
     * function for change btc agent
     * can be called only by owner of the contract
     * @_newServiceAgent - new serviceAgent address
     */
    function setServiceAgent(address _newServiceAgent) public onlyOwner {
        serviceAgent = _newServiceAgent;
    }
    /*
     * function for tracking bitcoin purchases received by bitcoin wallet
     * each transaction and amount of tokens according to rate can be validated on public bitcoin wallet
     * public key - #
     * @beneficiary - address, which received tokens
     * @amount - amount tokens
     * @stage - number of the stage (80% 40% 20% 0% discount)
     * can be called only by serviceAgent address
     */
    function payFiat(address beneficiary, uint256 amount, uint256 stage) public onlyServiceAgent onlyWhiteList(beneficiary) {

        require(beneficiary != 0x0);
        require(tokenPools[stage] >= amount);
        require(stage == uint256(currentStage));

        //calculate fiat amount in wei
        uint256 fiatWei = amount.mul(1 ether).div(stageRates[stage]);
        fiatBalance = fiatBalance.add(fiatWei);
        require(validPurchase());

        tokenPools[stage] = tokenPools[stage].sub(amount);
        tokensSold = tokensSold.add(amount);

        token.transfer(beneficiary, amount);
        TokenFiatPurchase(msg.sender, beneficiary, amount);
    }


    /*
     * function for  checking if crowdsale is finished
     */
    function hasEnded() public constant returns (bool) {
        return now > END_TIME_SALE || tokensSold >= totalSupply;
    }

    /*
     * function for  checking if hardCapReached
     */
    function hardCapReached() public constant returns (bool) {
        return tokensSold >= totalSupply || fiatBalance.add(ethBalance) >= hardCap;
    }
    /*
     * function for  checking if crowdsale goal is reached
     */
    function softCapReached() public constant returns (bool) {
        return fiatBalance.add(ethBalance) >= softCap;
    }

    function isPrivateSale() public constant returns (bool) {
        return now >= START_TIME_PRESALE && now <= END_TIME_PRESALE;
    }

    /*
     * function that call after crowdsale is ended
     *          releaseTokenTransfer - enable token transfer between users.
     *          burn tokens which are left on crowsale contract balance
     *          transfer balance of contract to wallets according to shares.
     */
    function forwardFunds() public onlyOwner {
        require(hasEnded());
        require(softCapReached());

        token.releaseTokenTransfer();
        token.burn(token.balanceOf(this));

        //transfer token ownership to this owner of crowdsale
        token.transferOwnership(msg.sender);

        //transfer funds here
        uint256 totalBalance = this.balance;
        LOTTERY_FUND_ADDRESS.transfer((totalBalance.mul(LOTTERY_FUND_SHARE)).div(100));
        OPERATIONS_ADDRESS.transfer((totalBalance.mul(OPERATIONS_SHARE)).div(100));
        PARTNERS_ADDRESS.transfer(this.balance); // send the rest to partners (PARTNERS_SHARE)
    }
    /*
     * function that call after crowdsale is ended
     *          conditions : ico ended and goal isn&#39;t reached. amount of depositor > 0.
     *
     *          refund eth deposit (fiat refunds will be done manually)
     */
    function refund() public {
        require(hasEnded());
        require(!softCapReached() || ((now > END_TIME_SALE + 30 days) && !token.released()));
        uint256 amount = deposits[msg.sender];
        require(amount > 0);
        deposits[msg.sender] = 0;
        msg.sender.transfer(amount);

    }

    /*
        internal functions
    */

    /*
     *  function for checking period of investment and investment amount restriction for ETH purchases
     */
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = (now >= START_TIME_PRESALE && now <= END_TIME_PRESALE) || (now >= START_TIME_SALE && now <= END_TIME_SALE);
        return withinPeriod && !hardCapReached();
    }
    /*
     * function for adding address to whitelist
     * @_whitelistAddress - address to add
     */
    function addToWhiteList(address _whitelistAddress) public onlyServiceAgent {
        whitelist[_whitelistAddress] = true;
    }

    /*
     * function for removing address from whitelist
     * @_whitelistAddress - address to remove
     */
    function removeWhiteList(address _whitelistAddress) public onlyServiceAgent {
        delete whitelist[_whitelistAddress];
    }


}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


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
    Transfer(_from, _to, _value);
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
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
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
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract LuckchemyToken is BurnableToken, StandardToken, Claimable {

    bool public released = false;

    string public constant name = "Luckchemy";

    string public constant symbol = "LUK";

    uint8 public constant decimals = 8;

    uint256 public CROWDSALE_SUPPLY;

    uint256 public OWNERS_AND_PARTNERS_SUPPLY;

    address public constant OWNERS_AND_PARTNERS_ADDRESS = 0x603a535a1D7C5050021F9f5a4ACB773C35a67602;

    // Index of unique addresses
    uint256 public addressCount = 0;

    // Map of unique addresses
    mapping(uint256 => address) public addressMap;
    mapping(address => bool) public addressAvailabilityMap;

    //blacklist of addresses (product/developers addresses) that are not included in the final Holder lottery
    mapping(address => bool) public blacklist;

    // service agent for managing blacklist
    address public serviceAgent;

    event Release();
    event BlacklistAdd(address indexed addr);
    event BlacklistRemove(address indexed addr);

    /**
     * Do not transfer tokens until the crowdsale is over.
     *
     */
    modifier canTransfer() {
        require(released || msg.sender == owner);
        _;
    }

    /*
     * modifier which gives specific rights to serviceAgent
     */
    modifier onlyServiceAgent(){
        require(msg.sender == serviceAgent);
        _;
    }


    function LuckchemyToken() public {

        totalSupply_ = 1000000000 * (10 ** uint256(decimals));
        CROWDSALE_SUPPLY = 700000000 * (10 ** uint256(decimals));
        OWNERS_AND_PARTNERS_SUPPLY = 300000000 * (10 ** uint256(decimals));

        addAddressToUniqueMap(msg.sender);
        addAddressToUniqueMap(OWNERS_AND_PARTNERS_ADDRESS);

        balances[msg.sender] = CROWDSALE_SUPPLY;

        balances[OWNERS_AND_PARTNERS_ADDRESS] = OWNERS_AND_PARTNERS_SUPPLY;

        owner = msg.sender;

        Transfer(0x0, msg.sender, CROWDSALE_SUPPLY);

        Transfer(0x0, OWNERS_AND_PARTNERS_ADDRESS, OWNERS_AND_PARTNERS_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public canTransfer returns (bool success) {
        //Add address to map of unique token owners
        addAddressToUniqueMap(_to);

        // Call StandardToken.transfer()
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool success) {
        //Add address to map of unique token owners
        addAddressToUniqueMap(_to);

        // Call StandardToken.transferForm()
        return super.transferFrom(_from, _to, _value);
    }

    /**
    *
    * Release the tokens to the public.
    * Can be called only by owner which should be the Crowdsale contract
    * Should be called if the crowdale is successfully finished
    *
    */
    function releaseTokenTransfer() public onlyOwner {
        released = true;
        Release();
    }

    /**
     * Add address to the black list.
     * Only service agent can do this
     */
    function addBlacklistItem(address _blackAddr) public onlyServiceAgent {
        blacklist[_blackAddr] = true;

        BlacklistAdd(_blackAddr);
    }

    /**
    * Remove address from the black list.
    * Only service agent can do this
    */
    function removeBlacklistItem(address _blackAddr) public onlyServiceAgent {
        delete blacklist[_blackAddr];
    }

    /**
    * Add address to unique map if it is not added
    */
    function addAddressToUniqueMap(address _addr) private returns (bool) {
        if (addressAvailabilityMap[_addr] == true) {
            return true;
        }

        addressAvailabilityMap[_addr] = true;
        addressMap[addressCount++] = _addr;

        return true;
    }

    /**
    * Get address by index from map of unique addresses
    */
    function getUniqueAddressByIndex(uint256 _addressIndex) public view returns (address) {
        return addressMap[_addressIndex];
    }

    /**
    * Change service agent
    */
    function changeServiceAgent(address _addr) public onlyOwner {
        serviceAgent = _addr;
    }

}

library SafeMath {

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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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