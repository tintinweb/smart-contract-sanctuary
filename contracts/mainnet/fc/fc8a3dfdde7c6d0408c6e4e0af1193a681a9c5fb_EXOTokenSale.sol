pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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


//Abstract contract for Calling ERC20 contract
contract AbstractCon {
    function allowance(address _owner, address _spender)  public pure returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function decimals() public returns (uint8);
    //function approve(address _spender, uint256 _value) public returns (bool); //test
    //function transfer(address _to, uint256 _value) public returns (bool); //test
    
}

//...
contract EXOTokenSale is Ownable {
    using SafeMath for uint256;

    string public constant name = "EXO_TOKEN_SALE";

    ///////////////////////
    // DATA STRUCTURES  ///
    ///////////////////////
    enum StageName {Pause, PreSale, Sale, Ended, Refund}
    struct StageProperties {
        uint256 planEndDate;
        address tokenKeeper;
    }
    
    StageName public currentStage;
    mapping(uint8   => StageProperties) public campaignStages;
    mapping(address => uint256)         public deposited;
    
    uint256 public weiRaised=0; //All raised ether
    uint256 public token_rate=1600; // decimal part of token per wei (0.3$ if 480$==1ETH)
    uint256 public minimum_token_sell=1000; // !!! token count - without decimals!!!
    uint256 public softCap=1042*10**18;//    500 000$ if 480$==1ETH
    uint256 public hardCap=52083*10**18;//25 000 000$ if 480$==1ETH
    address public wallet ; 
    address public ERC20address;

    ///////////////////////
    /// EVENTS     ///////
    //////////////////////
    event Income(address from, uint256 amount, uint64 timestamp);
    event NewTokenRate(uint256 rate);
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 weivalue, uint256 tokens);
    event FundsWithdraw(address indexed who, uint256 amount , uint64 timestamp);
    event Refunded(address investor, uint256 depositedValue);
    
    //20180501 = 1525132800
    //20180901 = 1535760000
    //20181231 = 1546214400

    function EXOTokenSale(address _wallet, address _preSaleTokenKeeper , address _SaleTokenKeeper) public {
        //costructor
        require(_wallet != address(0));
        wallet = _wallet;
        campaignStages[uint8(StageName.PreSale)] = StageProperties(1525132800, _preSaleTokenKeeper);
        campaignStages[uint8(StageName.Sale)]    = StageProperties(1535760000, _SaleTokenKeeper);
        currentStage = StageName.Pause;
    }

    //For disable transfers from incompatible wallet (Coinbase) 
    // or from a non ERC-20 compatible wallet
    //it may be purposefully comment this fallback function and recieve
    // Ether  direct through exchangeEtherOnTokens()
    function() public payable {
        exchangeEtherOnTokens(msg.sender);
    }

        // low level token purchase function
    function exchangeEtherOnTokens(address beneficiary) public payable  {
        emit Income(msg.sender, msg.value, uint64(now));
        require(currentStage == StageName.PreSale || currentStage == StageName.Sale);
        uint256 weiAmount = msg.value; //local
        uint256 tokens = getTokenAmount(weiAmount);
        require(beneficiary != address(0));
        require(token_rate > 0);//implicit enabling sell
        AbstractCon ac = AbstractCon(ERC20address);
        require(tokens >= minimum_token_sell.mul(10 ** uint256(ac.decimals())));
        require(ac.transferFrom(campaignStages[uint8(currentStage)].tokenKeeper, beneficiary, tokens));
        checkCurrentStage();
        weiRaised = weiRaised.add(weiAmount);
        deposited[beneficiary] = deposited[beneficiary].add(weiAmount);
        emit TokenPurchase(msg.sender, beneficiary, msg.value, tokens);
        if (weiRaised >= softCap) 
            withdrawETH();
    }

    //Stage time and conditions control
    function checkCurrentStage() internal {
        if  (campaignStages[uint8(currentStage)].planEndDate <= now) {
            // Allow refund if softCap is not reached during PreSale stage
            if  (currentStage == StageName.PreSale 
                 && (weiRaised + msg.value) < softCap
                ) {
                    currentStage = StageName.Refund;
                    return;
            }
            currentStage = StageName.Pause;
        }
        //Finish tokensale campaign when hardCap will reached
        if (currentStage == StageName.Sale 
            && (weiRaised + msg.value) >= hardCap
            ) { 
               currentStage = StageName.Ended;
        }
    }

    //for all discount logic
    function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(token_rate);
    }

    function withdrawETH() internal {
        emit FundsWithdraw(wallet, this.balance, uint64(now));
        wallet.transfer(this.balance);// or weiAmount
    }

    //Set current stage of campaign manually
    function setCurrentStage(StageName _name) external onlyOwner  {
        currentStage = _name;
    }

    //Manually stages control
    function setStageProperties(
        StageName _name, 
        uint256 _planEndDate, 
        address _tokenKeeper 
        ) external onlyOwner {
        campaignStages[uint8(_name)] = StageProperties(_planEndDate, _tokenKeeper);
    } 

    //set   erc20 address for token process  with check of allowance 
    function setERC20address(address newERC20contract)  external onlyOwner {
        require(address(newERC20contract) != 0);
        AbstractCon ac = AbstractCon(newERC20contract);
        require(ac.allowance(campaignStages[uint8(currentStage)].tokenKeeper, address(this))>0);
        ERC20address = newERC20contract;
    }
    
    //refund if not softCapped
    function refund(address investor) external {
        require(currentStage == StageName.Refund);
        require(investor != address(0));
        assert(msg.data.length >= 32 + 4);  //Short Address Attack
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }

    function setTokenRate(uint256 newRate) external onlyOwner {
        token_rate = newRate;
        emit NewTokenRate(newRate);
    }

    function setSoftCap(uint256 _val) external onlyOwner {
        softCap = _val;
    }

    function setHardCap(uint256 _val) external onlyOwner {
        hardCap = _val;
    }


    function setMinimumTokenSell(uint256 newNumber) external onlyOwner {
        minimum_token_sell = newNumber;
    }

    function setWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    } 

    function destroy()  external onlyOwner {
      if  (weiRaised >= softCap)
          selfdestruct(owner);
  } 

}              
//***************************************************************
  // Designed by by IBERGroup, email:<span class="__cf_email__" data-cfemail="ef828e979c869582808d86838aaf868d8a9dc1889d809a9f">[email&#160;protected]</span>; 
  //     Telegram: https://t.me/msmobile
  //               https://t.me/alexamuek
  // Code released under the MIT License(see git root).
  //// SafeMath and Ownable part of this contract based on 
  //// https://github.com/OpenZeppelin/zeppelin-solidity
  ////**************************************************************