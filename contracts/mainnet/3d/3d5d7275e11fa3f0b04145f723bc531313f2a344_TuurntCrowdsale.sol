pragma solidity ^0.4.23;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

/**
* @title TuurntToken 
* @dev The TuurntToken contract contains the information about 
* Tuurnt token.
*/





contract TuurntToken is StandardToken, DetailedERC20 {

    using SafeMath for uint256;

    // distribution variables
    uint256 public tokenAllocToTeam;
    uint256 public tokenAllocToCrowdsale;
    uint256 public tokenAllocToCompany;

    // addresses
    address public crowdsaleAddress;
    address public teamAddress;
    address public companyAddress;
    

    /**
    * @dev The TuurntToken constructor set the orginal crowdsaleAddress,teamAddress and companyAddress and allocate the
    * tokens to them.
    * @param _crowdsaleAddress The address of crowsale contract
    * @param _teamAddress The address of team
    * @param _companyAddress The address of company 
    */

    constructor(address _crowdsaleAddress, address _teamAddress, address _companyAddress, string _name, string _symbol, uint8 _decimals) public 
        DetailedERC20(_name, _symbol, _decimals)
    {
        require(_crowdsaleAddress != address(0));
        require(_teamAddress != address(0));
        require(_companyAddress != address(0));
        totalSupply_ = 500000000 * 10 ** 18;
        tokenAllocToTeam = (totalSupply_.mul(33)).div(100);     // 33 % Allocation
        tokenAllocToCompany = (totalSupply_.mul(33)).div(100);  // 33 % Allocation 
        tokenAllocToCrowdsale = (totalSupply_.mul(34)).div(100);// 34 % Allocation

        // Address      
        crowdsaleAddress = _crowdsaleAddress;
        teamAddress = _teamAddress;
        companyAddress = _companyAddress;
        

        // Allocations
        balances[crowdsaleAddress] = tokenAllocToCrowdsale;
        balances[companyAddress] = tokenAllocToCompany;
        balances[teamAddress] = tokenAllocToTeam; 
       
        //transfer event
        emit Transfer(address(0), crowdsaleAddress, tokenAllocToCrowdsale);
        emit Transfer(address(0), companyAddress, tokenAllocToCompany);
        emit Transfer(address(0), teamAddress, tokenAllocToTeam);
       
        
    }  
}

contract WhitelistInterface {
    function checkWhitelist(address _whiteListAddress) public view returns(bool);
}

/**
* @title TuurntCrowdsale
* @dev The Crowdsale contract holds the token for the public sale of token and 
* contains the function to buy token.  
*/






contract TuurntCrowdsale is Ownable {

    using SafeMath for uint256;

    TuurntToken public token;
    WhitelistInterface public whitelist;

    //variable declaration
    uint256 public MIN_INVESTMENT = 0.2 ether;
    uint256 public ethRaised;
    uint256 public ethRate = 524;
    uint256 public startCrowdsalePhase1Date;
    uint256 public endCrowdsalePhase1Date;
    uint256 public startCrowdsalePhase2Date;
    uint256 public endCrowdsalePhase2Date;
    uint256 public startCrowdsalePhase3Date;
    uint256 public endCrowdsalePhase3Date;
    uint256 public startPresaleDate;
    uint256 public endPresaleDate;
    uint256 public startPrivatesaleDate;
    uint256 public soldToken = 0;                                                           

    //addresses
    address public beneficiaryAddress;
    address public tokenAddress;

    bool private isPrivatesaleActive = false;
    bool private isPresaleActive = false;
    bool private isPhase1CrowdsaleActive = false;
    bool private isPhase2CrowdsaleActive = false;
    bool private isPhase3CrowdsaleActive = false;
    bool private isGapActive = false;

    event TokenBought(address indexed _investor, uint256 _token, uint256 _timestamp);
    event LogTokenSet(address _token, uint256 _timestamp);

    enum State { PrivateSale, PreSale, Gap, CrowdSalePhase1, CrowdSalePhase2, CrowdSalePhase3 }

    /**
    * @dev Transfer the ether to the beneficiaryAddress.
    * @param _fund The ether that is transferred to contract to buy tokens.  
    */
    function fundTransfer(uint256 _fund) internal returns(bool) {
        beneficiaryAddress.transfer(_fund);
        return true;
    }

    /**
    * @dev fallback function which accepts the ether and call the buy token function.
    */
    function () payable public {
        buyTokens(msg.sender);
    }

    /**
    * @dev TuurntCrowdsale constructor sets the original beneficiaryAddress and 
    * set the timeslot for the Pre-ICO and ICO.
    * @param _beneficiaryAddress The address to transfer the ether that is raised during crowdsale. 
    */
    constructor(address _beneficiaryAddress, address _whitelist, uint256 _startDate) public {
        require(_beneficiaryAddress != address(0));
        beneficiaryAddress = _beneficiaryAddress;
        whitelist = WhitelistInterface(_whitelist);
        startPrivatesaleDate = _startDate;
        isPrivatesaleActive = !isPrivatesaleActive;
    }

    /**
    * @dev Allow founder to end the Private sale.
    */
    function endPrivatesale() onlyOwner public {
        require(isPrivatesaleActive == true);
        isPrivatesaleActive = !isPrivatesaleActive;
    }

    /**
    * @dev Allow founder to set the token contract address.
    * @param _tokenAddress The address of token contract.
    */
    function setTokenAddress(address _tokenAddress) onlyOwner public {
        require(tokenAddress == address(0));
        token = TuurntToken(_tokenAddress);
        tokenAddress = _tokenAddress;
        emit LogTokenSet(token, now);
    }

     /**
    * @dev Allow founder to start the Presale.
    */
    function activePresale(uint256 _presaleDate) onlyOwner public {
        require(isPresaleActive == false);
        require(isPrivatesaleActive == false);
        startPresaleDate = _presaleDate;
        endPresaleDate = startPresaleDate + 2 days;
        isPresaleActive = !isPresaleActive;
    }
   
    /**
    * @dev Allow founder to start the Crowdsale phase1.
    */
    function activeCrowdsalePhase1(uint256 _phase1Date) onlyOwner public {
        require(isPresaleActive == true);
        require(_phase1Date > endPresaleDate);
        require(isPhase1CrowdsaleActive == false);
        startCrowdsalePhase1Date = _phase1Date;
        endCrowdsalePhase1Date = _phase1Date + 1 weeks;
        isPresaleActive = !isPresaleActive;
        isPhase1CrowdsaleActive = !isPhase1CrowdsaleActive;
    }

    /**
    * @dev Allow founder to start the Crowdsale phase2. 
    */

    function activeCrowdsalePhase2(uint256 _phase2Date) onlyOwner public {
        require(isPhase2CrowdsaleActive == false);
        require(_phase2Date > endCrowdsalePhase1Date);
        require(isPhase1CrowdsaleActive == true);
        startCrowdsalePhase2Date = _phase2Date;
        endCrowdsalePhase2Date = _phase2Date + 2 weeks;
        isPhase2CrowdsaleActive = !isPhase2CrowdsaleActive;
        isPhase1CrowdsaleActive = !isPhase1CrowdsaleActive;
    }

    /**
    * @dev Allow founder to start the Crowdsale phase3. 
    */
    function activeCrowdsalePhase3(uint256 _phase3Date) onlyOwner public {
        require(isPhase3CrowdsaleActive == false);
        require(_phase3Date > endCrowdsalePhase2Date);
        require(isPhase2CrowdsaleActive == true);
        startCrowdsalePhase3Date = _phase3Date;
        endCrowdsalePhase3Date = _phase3Date + 3 weeks;
        isPhase3CrowdsaleActive = !isPhase3CrowdsaleActive;
        isPhase2CrowdsaleActive = !isPhase2CrowdsaleActive;
    }
    /**
    * @dev Allow founder to change the minimum investment of ether.
    * @param _newMinInvestment The value of new minimum ether investment. 
    */
    function changeMinInvestment(uint256 _newMinInvestment) onlyOwner public {
        MIN_INVESTMENT = _newMinInvestment;
    }

     /**
    * @dev Allow founder to change the ether rate.
    * @param _newEthRate current rate of ether. 
    */
    function setEtherRate(uint256 _newEthRate) onlyOwner public {
        require(_newEthRate != 0);
        ethRate = _newEthRate;
    }

    /**
    * @dev Return the state based on the timestamp. 
    */

    function getState() view public returns(State) {
        
        if(now >= startPrivatesaleDate && isPrivatesaleActive == true) {
            return State.PrivateSale;
        }
        if (now >= startPresaleDate && now <= endPresaleDate) {
            require(isPresaleActive == true);
            return State.PreSale;
        }
        if (now >= startCrowdsalePhase1Date && now <= endCrowdsalePhase1Date) {
            require(isPhase1CrowdsaleActive == true);
            return State.CrowdSalePhase1;
        }
        if (now >= startCrowdsalePhase2Date && now <= endCrowdsalePhase2Date) {
            require(isPhase2CrowdsaleActive == true);
            return State.CrowdSalePhase2;
        }
        if (now >= startCrowdsalePhase3Date && now <= endCrowdsalePhase3Date) {
            require(isPhase3CrowdsaleActive == true);
            return State.CrowdSalePhase3;
        }
        return State.Gap;

    }
 
    /**
    * @dev Return the rate based on the state and timestamp.
    */

    function getRate() view public returns(uint256) {
        if (getState() == State.PrivateSale) {
            return 5;
        }
        if (getState() == State.PreSale) {
            return 6;
        }
        if (getState() == State.CrowdSalePhase1) {
            return 7;
        }
        if (getState() == State.CrowdSalePhase2) {
            return 8;
        }
        if (getState() == State.CrowdSalePhase3) {
            return 10;
        }
    }
    
    /**
    * @dev Calculate the number of tokens to be transferred to the investor address 
    * based on the invested ethers.
    * @param _investedAmount The value of ether that is invested.  
    */
    function getTokenAmount(uint256 _investedAmount) view public returns(uint256) {
        uint256 tokenRate = getRate();
        uint256 tokenAmount = _investedAmount.mul((ethRate.mul(100)).div(tokenRate));
        return tokenAmount;
    }

    /**
    * @dev Transfer the tokens to the investor address.
    * @param _investorAddress The address of investor. 
    */
    function buyTokens(address _investorAddress) 
    public 
    payable
    returns(bool)
    {   
        require(whitelist.checkWhitelist(_investorAddress));
        if ((getState() == State.PreSale) ||
            (getState() == State.CrowdSalePhase1) || 
            (getState() == State.CrowdSalePhase2) || 
            (getState() == State.CrowdSalePhase3) || 
            (getState() == State.PrivateSale)) {
            uint256 amount;
            require(_investorAddress != address(0));
            require(tokenAddress != address(0));
            require(msg.value >= MIN_INVESTMENT);
            amount = getTokenAmount(msg.value);
            require(fundTransfer(msg.value));
            require(token.transfer(_investorAddress, amount));
            ethRaised = ethRaised.add(msg.value);
            soldToken = soldToken.add(amount);
            emit TokenBought(_investorAddress,amount,now);
            return true;
        }else {
            revert();
        }
    }

    /**
    * @dev Allow founder to end the crowsale and transfer the remaining
    * tokens of crowdfund to the company address. 
    */
    function endCrowdfund(address companyAddress) onlyOwner public returns(bool) {
        require(isPhase3CrowdsaleActive == true);
        require(now >= endCrowdsalePhase3Date); 
        uint256 remaining = token.balanceOf(this);
        require(token.transfer(companyAddress, remaining));
    }

}