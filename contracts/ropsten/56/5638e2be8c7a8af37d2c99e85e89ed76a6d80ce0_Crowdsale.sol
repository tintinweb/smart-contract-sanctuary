/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity  ^0.7.6;

interface IERC20 {
 
    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

  /**
   *  Public functions
   */
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  /** 
   *  Events
   */
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Burn(address indexed from, uint256 value);
  event SaleContractActivation(address saleContract, uint256 tokensForSale);
}

 abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}
  contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

  /*
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  * Functions for owner
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  */
  
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
  }

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
      require(!paused);
      _;
    }

    modifier whenPaused() {
      require(paused);
      _;
    }

    function pause() onlyOwner whenNotPaused public {
      paused = true;
      emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
      paused = false;
      emit Unpause();
    }
}


/**
 * @title SafeMath
 * @dev   Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    if (a == 0){
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b,"Calculation error");
    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256){
    // Solidity only automatically asserts when dividing by 0
    require(b > 0,"Calculation error");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256){
    require(b <= a,"Calculation error");
    uint256 c = a - b;
    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a + b;
    require(c >= a,"Calculation error");
    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256){
    require(b != 0,"Calculation error");
    return a % b;
  }
}


/**
 * @title Standard ERC20 token
 */
contract StandardToken is IERC20, Ownable {
  using SafeMath for uint256;

  string  private _name;                          // Name of the token.
  string  private _symbol;                        // symbol of the token.
  uint8   private _decimal;                      // variable to maintain decimal precision of the token.
  bool    private _stopped = false;               // state variable to check fail-safe for contract.
  uint256 _totalSupply = 100000000000000000000000000;

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) balances;

  /** @dev Returns number of tokens owned by given address
   * @param _owner Address of token owner
   * @return Balance of owner
   */

    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }

  /** @dev Transfers sender's tokens to a given address. Returns success
   * @param _to Address of token receiver
   * @param _value Number of tokens to transfer
   * @return success Was transfer successful?
   */

    function transfer(address _to, uint256 _value) public override onlyPayloadSize(2) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to].add(_value) > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value); // solhint-disable-line
            return true;
        } else {
            return false;
        }
    }

    /** @dev Allows allowed third party to transfer tokens from one address to another. Returns success
     * @param _from Address from where tokens are withdrawn
     * @param _to Address to where tokens are sent
     * @param _value Number of tokens to transfer
     * @return Was transfer successful?
     */

    function transferFrom(address _from, address _to, uint256 _value) public override onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value); // solhint-disable-line
        return true;
    }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */

    function approve(address _spender, uint256 _value) public override onlyPayloadSize(2) returns (bool) {
        require(_value == 0 || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); // solhint-disable-line
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        emit Approval(msg.sender, _spender, _newValue); // solhint-disable-line
        return true;
    }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowed[_owner][_spender];
    }

 function burn(address account, uint256 value) public onlyOwner{
    require(account != address(0),"Invalid account");
    require(value > 0, "Invalid Amount");
    _totalSupply = _totalSupply.sub(value);
    balances[account] = balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

}

contract Crowdsale is Ownable { 
  
  using SafeMath for uint256;
  uint256 constant CUSTOM_GASLIMIT = 150000;
  uint256 public updateTime = 0;

  //Crowdsale Token Values
  uint256 public hardCap = 25000000000000000000000000;
  uint256 public softCap = 300000000000000000000; 
  uint256 public tokensForSale = 100000000000000000000000000;
  uint256 public tokensForPreSale = 10000000000000000000000000;
  uint256 public tokensForPublicSale = 15000000000000000000000000;
  
  uint256 public preSaleTokenSold; 
  uint256 public publicSaleTokenSold = 0;

  //Sale minimum maximum values
  uint256 public minimumETHInPreSale = 100000000000000000;
  uint256 public MaximumETHInPreSale = 10000000000000000000;
  uint256 public minimumETHInPublicSale = 100000000000000000;
  uint256 public MaximumETHInPublicSale = 10000000000000000000;

   //tokens per ETH in each sale 
  uint256 public preSaleTokensPerETH = 3200000000000000000000;
  uint256 public publicSaleTokensPerETH = 3200000000000000000000;

  // Address where funds are collected
  address payable wallet = payable(0x111e465f00cA7Ec4585ef57ff475C4b5b8eF9F3B);

  address public tokenContractAddress = address(0xFaA099C28e52CF1170bdccbF4A90741EA3291454);

  bool public crowdSaleStarted = false;
  uint256 public totalRaisedInETH;
  StandardToken token = StandardToken(tokenContractAddress);
  enum Stages {CrowdSaleNotStarted, Pause, PreSaleStart,PreSaleEnd,PublicSaleStart,PublicSaleEnd}

  Stages currentStage;
  Stages previousStage;
  bool public Paused;
   
   // address vs state mapping (1 for exists , zero default);
   mapping (address => bool) public whitelistedContributors;
  
   modifier CrowdsaleStarted(){
      require(crowdSaleStarted);
      _;
   }
 
    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(){
        currentStage = Stages.CrowdSaleNotStarted;
    }
    
    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    receive () external payable {

        buyTokens(msg.sender); 

    }

    /**
    * @dev calling this function will pause the sale
    */
    
    function pause() public onlyOwner {
      require(Paused == false);
      require(crowdSaleStarted == true);
      previousStage=currentStage;
      currentStage=Stages.Pause;
      Paused = true;
    }
  
    function restartSale() public onlyOwner {
      require(currentStage == Stages.Pause);
      currentStage=previousStage;
      Paused = false;
    }

    function startPreSale() public onlyOwner {

    require(currentStage == Stages.PreSaleEnd);
    currentStage = Stages.PreSaleStart;
   
    }

    function endPreSale() public onlyOwner {

    require(currentStage == Stages.PublicSaleStart);
    currentStage = Stages.PreSaleEnd;
   
    }

    function startPublicSale() public onlyOwner {
    require(currentStage == Stages.PreSaleEnd);
    currentStage = Stages.PublicSaleStart;
    }

    function endPublicSale() public onlyOwner {
    require(currentStage == Stages.PublicSaleStart);
    currentStage = Stages.PublicSaleEnd;
    uint256 remainingTokens = tokensForPublicSale.sub(publicSaleTokenSold);
    publicSaleTokenSold = 0;
    token.burn(msg.sender, remainingTokens);
    }

    function getStage() public view returns (string memory) {
    if (currentStage == Stages.PreSaleStart) return 'Pre Sale Start';
    else if (currentStage == Stages.PreSaleEnd) return 'Pre Sale End';
    else if (currentStage == Stages.PublicSaleStart) return 'Public Sale Start';    
    else if (currentStage == Stages.PublicSaleEnd) return 'Public Sale End';   
    else if (currentStage == Stages.Pause) return 'paused';
    else if (currentStage == Stages.CrowdSaleNotStarted) return 'CrowdSale Not Started';
    return 'Not Found';    
    }
    

   /**
   * @param _beneficiary Address performing the token purchase
   */
   function buyTokens(address _beneficiary) CrowdsaleStarted public payable {
    require(Paused != true);
    uint256 ETHAmount = msg.value;
    require(ETHAmount != 0);    
    _preValidatePurchase(ETHAmount);
    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(ETHAmount);
    _validateCapLimits(ETHAmount);
    _processPurchase(_beneficiary,tokens);
    wallet.transfer(msg.value);
    if (currentStage == Stages.PublicSaleStart){
    publicSaleTokenSold+= tokens;   
    }
    emit TokenPurchase(msg.sender, _beneficiary, ETHAmount, tokens);
   }
  
   /**
   * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
   * @param _ETH Value in ETH involved in the purchase
   */
   function _preValidatePurchase(uint256 _ETH) internal view { 

     if (currentStage == Stages.PreSaleStart) {
        require(_ETH >= minimumETHInPreSale);
        require(_ETH <= MaximumETHInPreSale);

      }
      else if (currentStage == Stages.PublicSaleStart) {
        require(_ETH >= minimumETHInPublicSale);
        require(_ETH <= MaximumETHInPublicSale);

      }
    }
    
    /**
    * @dev Validation of the capped restrictions.
    * @param _ETH ETH amount
    */

    function _validateCapLimits(uint256 _ETH) internal {
     
      totalRaisedInETH = totalRaisedInETH.add(_ETH);
      require(totalRaisedInETH <= hardCap);
   }
   
   /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
   function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
      
     if (currentStage == Stages.PreSaleEnd) {
        require(token.transferFrom(owner(),_beneficiary,_tokenAmount));  

      }
      
      else if (currentStage == Stages.PublicSaleEnd) {
        require(token.transferFrom(owner(),_beneficiary,_tokenAmount));  
      }
    }

   /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
   function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
   }
  

  /**
   * @param _ETH Value in ETH to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _ETH
   */
    function _getTokenAmount(uint256 _ETH) CrowdsaleStarted internal view returns (uint256) {
      uint256 tokens;
      if (currentStage == Stages.PreSaleStart) {
         tokens = _ETH.mul(preSaleTokensPerETH);
      }
      else if (currentStage == Stages.PublicSaleStart) {
         tokens = _ETH.mul(publicSaleTokensPerETH);
      }
      return tokens;
    }
    

    function isSoftCapReached() public view returns(bool){
        if(totalRaisedInETH >= softCap){
            return true;
        }
        else {
            return false;
        }
    }

}