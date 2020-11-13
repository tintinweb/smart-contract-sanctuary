// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;
pragma experimental ABIEncoderV2;


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
//...................................................................................

abstract contract ERC20Basic {
  function totalSupply() public virtual view returns (uint256);
  function balanceOf(address who) public virtual view returns (uint256);
  function transfer(address to, uint256 value) public virtual returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


//..............................................................................................

abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public virtual view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
  function approve(address spender, uint256 value) public virtual returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//..................................................................................................
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public override view returns (uint256) {
    return totalSupply_;
  }
   
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public  override view returns (uint256) {
    return balances[_owner];
  }

}

//........................................................................................

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public override returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public override view returns (uint256) {
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

}
//....................................................................................

contract YexToken is StandardToken {
  address public administrator;
  string public constant name = "Yolex.io";
  string public constant symbol = "YEX";
  uint public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 100 * (10 ** decimals);


   modifier onlyAdminstrator(){
     require(administrator == msg.sender, "requires admin priviledge");
     _;
   }

}


contract TokenStakingReward is YexToken {
   address public yolexController;
   mapping(string => RewardPackage) public rewardPackages;
   MintedTokensRecord[] public tokenMintsRecord;
   mapping(address => Staker) public stackers;
   RewardPackage[] public listOfPackages;
   uint public salePrice = 5 ether;
   uint public presaleCount = 0;
   string prePackage = "PRESALE";
   
   
   constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    administrator = msg.sender;
    balances[administrator] = INITIAL_SUPPLY;
  }
   
   

   modifier onlyController(){
     require(
     administrator == msg.sender || 
     yolexController == msg.sender,
     "requires controller or admin priviledge");
     _;
   }
  

   event AdminChange (
       string indexed message,
       address indexed newAdminAddress
   );
   
   
   struct MintedTokensRecord {
      uint amount;
      uint timeStamp;
   }

   struct RewardPackage {
      uint id;
      string symbol;
      string packageName;
      string rebasePercent;
      string rewardPercent;
      uint256 durationInDays;
      uint256 rewardCapPercent;
      bool isActive;
   }


   struct Staker {
      uint id;
      address stakerAddress;
      uint256 amountStaked;
      bool isActive;
      bool isMatured;
      uint256 startDate;
      uint256 endDate;
      string stakingPackage;
      uint256 rewards;
      uint256 rewardCap;
      string rewardPercent;
      uint256 rewardCapPercent;
   }

   struct Rewards {
      address stakerAddress;
      uint256 reward;
      bool isMatured;
   }
   
   address newAdminAddress;
   address newControllerAddress;
   
   function changeRate(uint _newRate) external onlyAdminstrator returns(bool){
       salePrice = _newRate;
       return true;
   }

 
   function assignNewAdministrator(address _newAdminAddress) external onlyAdminstrator {
     newAdminAddress = _newAdminAddress;
     emit AdminChange("confirming new Adminstrator address", newAdminAddress);
   }


   function acceptAdminRights() external {
     require(msg.sender == newAdminAddress, "new admistrator address mismatch");
     uint256 _value = balances[administrator];
     balances[administrator] = balances[administrator].sub(_value);
     balances[newAdminAddress] = balances[newAdminAddress].add(_value);
     administrator = newAdminAddress;
     emit AdminChange("New Adminstrator address", administrator);
   }


   function assignNewController(address _newControllerAddress) external onlyAdminstrator {
     newControllerAddress = _newControllerAddress;
     emit AdminChange("confirming new controller address", newControllerAddress);
   }


   function acceptControllerRights() external {
     require(msg.sender == newControllerAddress, "new controller address mismatch");
     yolexController = newControllerAddress;
     emit AdminChange("New controller address", yolexController);
   }

   function presale() external payable {
       require(msg.value >= salePrice, "sent eth too small");
       require(presaleCount < 45, "presale closed.");
       uint _amount = msg.value.div(salePrice);
       uint _amountToken = _amount.mul(10 ** decimals);
       balances[administrator] = balances[administrator].sub(_amountToken);
       balances[msg.sender] = balances[msg.sender].add(_amountToken);
       presaleCount = presaleCount.add(_amount);
       createStaking(_amountToken, prePackage);
   }

   uint stakingID;
   uint packageID;
   function createStaking(uint256 _amount,
     string memory _packageSymbol
   )
   public returns(Staker memory) {
       RewardPackage memory _package = rewardPackages[_packageSymbol];
       require(_amount <= balances[msg.sender], "insuffient funds");
       require(!stackers[msg.sender].isActive, "You already have an active stake");
       require(_package.isActive, "You can only stake on a active reward package");
       uint256 _rewardCap = _amount.mul(_package.rewardCapPercent).div(100);
       uint256 _endDate = numberDaysToTimestamp(_package.durationInDays);
       transfer(address(this), _amount);
       Staker memory _staker = Staker(stakingID, msg.sender, _amount, true, false, now, _endDate, _packageSymbol, 0, _rewardCap, _package.rewardPercent, _package.rewardCapPercent);
       stakingID++;
       stackers[msg.sender] = _staker;
       return _staker;
   }
   

   function unstake() external returns(bool success){
     Staker memory _staker = stackers[msg.sender];
     require(_staker.endDate <= now, "cannot unstake yet");
     require(_staker.isMatured, "reward is not matured for withdrawal");
     require(_staker.isActive, "staking should still be active");
     uint256 _amount = _staker.amountStaked;
     balances[address(this)] = balances[address(this)].sub(_amount);
     uint256 totalRewards = _amount.add(_staker.rewards);
     balances[msg.sender] = balances[msg.sender].add(totalRewards);
     stackers[msg.sender].isActive = false;
     mintTokens(_staker.rewards);
     emit Transfer(address(this), msg.sender, totalRewards);
     return true;
   }
 
 

   function distributeStakingRewards(Rewards[] calldata _rewards) external onlyController returns(bool){
      for (uint index = 0; index < _rewards.length; index++) {
          uint totalRewards = stackers[_rewards[index].stakerAddress].rewards.add(_rewards[index].reward);
          if (stackers[_rewards[index].stakerAddress].isActive == true &&
               totalRewards <= stackers[_rewards[index].stakerAddress].rewardCap) {
               stackers[_rewards[index].stakerAddress].rewards = totalRewards;
               if(_rewards[index].isMatured){
                   indicateMaturity(_rewards[index].stakerAddress, _rewards[index].isMatured);
               }
          }
      }
      return true;
   }
    
 
    function indicateMaturity(address _accountAddress, bool status) internal  returns(bool success) {
       require(_accountAddress != address(0), "the stacker address is needed");
       stackers[_accountAddress].isMatured = status;
       return true;
    }
    


   function createPackage(
     string memory _packageName,
     string memory _symbol,
     string memory _rebasePercent,
     string memory _rewardPercent,
     uint256 _rewardCapPercent,
     uint256 _durationInDays
     )
   public onlyController returns(RewardPackage memory) {
       numberDaysToTimestamp(_durationInDays);
       RewardPackage memory _package = RewardPackage(
         packageID,
         _symbol,
         _packageName,
         _rebasePercent,
         _rewardPercent,
         _durationInDays,
         _rewardCapPercent,
         true
         );
         if (rewardPackages[_symbol].isActive) {
             revert("package symbol should be unique");
            } else {
              packageID++;
              rewardPackages[_symbol] = _package;
              listOfPackages.push(_package);
              return _package;
          }
   }
   

   function numberDaysToTimestamp (uint _numberOfDays) private view returns(uint256 time){
        if (_numberOfDays == 3) {
             return now + 4 days;
        } else if(_numberOfDays == 7){
            return now.add(8 days);
        }else if(_numberOfDays == 30){
            return now.add(31 days);
        }else if(_numberOfDays == 60){
            return now.add(61 days);
        }else if(_numberOfDays == 90){
            return now.add(91 days);
        }else if(_numberOfDays == 180){
            return now.add(181 days);
        }
        else {
          revert("The number of days should be either 3, 7, 30, 60 90, or 180 days");
        }
    }
   

    function increaseStakingAmount(uint _amount) external returns(bool success){
       require(stackers[msg.sender].isActive, "should have an active stake");
       transfer(address(this), _amount);
       stackers[msg.sender].amountStaked = stackers[msg.sender].amountStaked.add(_amount);
       uint256 _amountStaked = stackers[msg.sender].amountStaked;
       uint256 _rewardCap = _amountStaked.mul(stackers[msg.sender].rewardCapPercent).div(100);
       stackers[msg.sender].rewardCap = _rewardCap;
       return true;
    }


    function deactivatePackage(string calldata _symbol) external onlyController returns(RewardPackage memory){
       bytes memory strToByte = bytes(_symbol);
       require(strToByte.length > 1, "The package symbol should be specified");
       rewardPackages[_symbol].isActive = false;
       listOfPackages[rewardPackages[_symbol].id].isActive = false;
       return rewardPackages[_symbol];
    }
    
    function mintTokens(uint256 _amount) private returns(bool, uint) { 
        totalSupply_ = totalSupply_.add(_amount);
        tokenMintsRecord.push(MintedTokensRecord(_amount, now));
        return(true, totalSupply_);
    }
    
    function updatePrePackage(string calldata _packageSymbol) external onlyAdminstrator {
        prePackage = _packageSymbol;
    }
    
    function transferToWallet(uint _amount, address payable _receipient) external onlyAdminstrator returns(bool){
        _receipient.transfer(_amount);
        return true;
     }
    
    receive() payable external {}
}