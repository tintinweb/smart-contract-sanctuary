/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT
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
  bool crowdSaleStarted = false;

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) _balances;

  /** @dev Returns number of tokens owned by given address
   * @param _owner Address of token owner
   * @return Balance of owner
   */

    function balanceOf(address _owner) public view override returns (uint256) {
        return _balances[_owner];
    }

  /** @dev Transfers sender's tokens to a given address. Returns success
   * @param _to Address of token receiver
   * @param _value Number of tokens to transfer
   * @return success Was transfer successful?
   */

    function transfer(address _to, uint256 _value) public override onlyPayloadSize(2) returns (bool success) {
        if (_balances[msg.sender] >= _value && _value > 0 && _balances[_to].add(_value) > _balances[_to]) {
            _balances[msg.sender] = _balances[msg.sender].sub(_value);
            _balances[_to] = _balances[_to].add(_value);
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
        require(_value <= _balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
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

 /** 
   * @dev Internal function that burns an amount of the token of a given account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0),"Invalid account");
    require(value > 0, "Invalid Amount");
    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /** 
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public onlyOwner {
    _burn(msg.sender, _value);
  }
    /** 
   * @dev Internal function that burns an amount of the token of a given account.
   * @param value The amount that will be burnt.
   */
  function _burnForCrowdsale(uint256 value) internal {
    require(value > 0, "Invalid Amount");
    _totalSupply = _totalSupply.sub(value);
    _balances[owner()] = _balances[owner()].sub(value);
    emit Transfer(owner(), address(0), value);
  }
  
  /** 
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burnForCrowdsale(uint256 _value) public {
    _burnForCrowdsale(_value);
  }

  /** 
   * @dev Set crowsales status.
   * @param status status of crowdsale.
   */ 

   function setCrowdSalesStatus(bool status) public {
     crowdSaleStarted = status;
  }

}

contract Crowdsale is Ownable { 
 
  using SafeMath for uint256;
  uint256 constant CUSTOM_GASLIMIT = 150000;

  //Crowdsale Token Values
  uint256 public hardCap = 5500000000000000000000;
  uint256 public softCap = 200000000000000000000; 
    uint256 public tokensForCrowdSale = 14850000000000000000000000;
  
  uint256 public crowdSaleTokenSold = 0; 
  
  //Sale minimum maximum values
  uint256 public minimumTokensInCrowdSale = 0;
  uint256 public MaximumTokensInCrowdSale = 80000000000000000000000;

   //tokens per ETH in each sale 
  uint256 public crowdSaleTokensPerETH = 3200;
  
  uint256 userNum = 0;

  struct tokenInfo {
    address beneficiary;
    uint256 tokens;
  }

mapping (uint256 => tokenInfo) public tokenBook;

  // Address where funds are collected
  address payable wallet = payable(0xd09eCD04f035a0A07a2F16cf442d9fc37692cdb8);

  address public tokenContractAddress = address(0xa6630B22974F908a98a8139CB12Ec2EbABfbe9D4);

  bool public crowdSaleStarted = false;
  uint256 public totalRaisedInETH;
  StandardToken token = StandardToken(tokenContractAddress);
  enum Stages {CrowdSaleNotStarted, Pause, CrowdSaleStart, CrowdSaleEnd}

  Stages currentStage;
  Stages previousStage;
  bool public Paused;
   
  
   modifier CrowdsaleStarted(){
      require(crowdSaleStarted, "crowdsale not started yet");
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
   * @dev Function for setting token price by owner
   * @param _crowdSaleTokensPerETH token price
   */
  function setCrowdSaleTokenPrice(uint256 _crowdSaleTokensPerETH) public onlyOwner returns(bool){
    require(_crowdSaleTokensPerETH > 0, "Invalid Price");
    crowdSaleTokensPerETH = _crowdSaleTokensPerETH;
    return true;
  }

  /**
   * @dev Function to set minimum tokens
   * @param value to set the new min value
   */
  function setMinTokensInCrowdSale(uint256 value) public onlyOwner returns(bool){
    require(value > 0,"Invalid Value");
    minimumTokensInCrowdSale = value;
    return true;
  }

  
  /**
   * @dev Function to set maximum tokens
   * @param value to set the new max value
   */
  function setMaxTokensInCrowdSale(uint256 value) public onlyOwner returns(bool){
    require(value > 0,"Invalid Value");
    MaximumTokensInCrowdSale = value;
    return true;
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

    function startCrowdSale() public onlyOwner {
    require(!crowdSaleStarted, "Crowdsale already started");
      crowdSaleStarted = true;
      currentStage = Stages.CrowdSaleStart;
      token.setCrowdSalesStatus(true);
    }

    function endCrowdSale() public onlyOwner{
    require(currentStage == Stages.CrowdSaleStart, "Crowd sale not started");
    currentStage = Stages.CrowdSaleEnd;
    for(uint256 i=0; i < userNum; i++){
    token.transferFrom(owner(), tokenBook[i].beneficiary, tokenBook[i].tokens);
    tokenBook[i].tokens = 0;
    }
    userNum = 0;
    uint256 remainingTokens = tokensForCrowdSale.sub(crowdSaleTokenSold);
    token.burnForCrowdsale(remainingTokens);
    crowdSaleStarted = false;
    token.setCrowdSalesStatus(false);
    }


    function getStage() public view returns (string memory) {
    if (currentStage == Stages.CrowdSaleStart) return 'Crowd Sale Start';
    else if (currentStage == Stages.CrowdSaleEnd) return 'Crowd Sale End';
    else if (currentStage == Stages.Pause) return 'paused';
    else if (currentStage == Stages.CrowdSaleNotStarted) return 'CrowdSale Not Started';
    return 'Not Found';    
    }
    

   /**
   * @param beneficiary Address performing the token purchase
   */
   function buyTokens(address beneficiary) CrowdsaleStarted public payable {
    require(Paused != true);
    uint256 ETHAmount = msg.value;
    require(ETHAmount != 0);    
    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(ETHAmount);
    _preValidatePurchase(tokens);
    uint256 userId = userNum;
    tokenBook[userId] = tokenInfo(beneficiary, tokens);
    userNum++;
    _validateCapLimits(ETHAmount);
    wallet.transfer(msg.value);
    if (currentStage == Stages.CrowdSaleStart){
    crowdSaleTokenSold = crowdSaleTokenSold + tokens;   
    }
    emit TokenPurchase(msg.sender, beneficiary, ETHAmount, tokens);
   }
  
   /**
   * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
   * @param _ETH Value in ETH involved in the purchase
   */
   function _preValidatePurchase(uint256 _ETH) internal view { 

        require(_ETH >= minimumTokensInCrowdSale);
        require(_ETH <= MaximumTokensInCrowdSale);

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
   * @param _ETH Value in ETH to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _ETH
   */
    function _getTokenAmount(uint256 _ETH) CrowdsaleStarted internal view returns (uint256) {
      uint256 tokens;
      if (currentStage == Stages.CrowdSaleStart) {
         tokens = _ETH.mul(crowdSaleTokensPerETH);
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