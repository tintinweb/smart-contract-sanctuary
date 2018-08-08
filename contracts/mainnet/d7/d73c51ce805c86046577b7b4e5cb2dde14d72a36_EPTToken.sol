pragma solidity ^0.4.15;

contract ERC20 {
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);  
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */

    function transfer(address _to, uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }else {
            return false;
        }
    }
    

    /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
}


    /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */

    function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}

contract EPTToken is BasicToken {

    using SafeMath for uint256;

    string public name = "e-Pocket Token";                      //name of the token
    string public symbol = "EPT";                               //symbol of the token
    uint8 public decimals = 18;                                 //decimals
    uint256 public initialSupply = 64000000 * 10**18;           //total supply of Tokens

    //variables
    uint256 public totalAllocatedTokens;                         //variable to keep track of funds allocated
    uint256 public tokensAllocatedToCrowdFund;                   //funds allocated to crowdfund
    uint256 public foundersAllocation;                           //funds allocated to founder

    //addresses
    address public founderMultiSigAddress;                       //Multi sign address of founder
    address public crowdFundAddress;                             //Address of crowdfund contract

    //events
    event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);
    
    //modifierss

    modifier nonZeroAddress(address _to){
        require(_to != 0x0);
        _;
    }

    modifier onlyFounders(){
        require(msg.sender == founderMultiSigAddress);
        _;
    }

    modifier onlyCrowdfund(){
        require(msg.sender == crowdFundAddress);
        _;
    }

    /**
        @dev EPTToken Constructor to initiate the variables with some input argument
        @param _crowdFundAddress This is the address of the crowdfund which leads the distribution of tokens
        @param _founderMultiSigAddress This is the address of the founder which have the hold over the contract.
    
     */
    
    function EPTToken(address _crowdFundAddress, address _founderMultiSigAddress) {
        crowdFundAddress = _crowdFundAddress;
        founderMultiSigAddress = _founderMultiSigAddress;
    
        //token allocation
        tokensAllocatedToCrowdFund = 32 * 10**24;
        foundersAllocation = 32 * 10**24;

        // Assigned balances
        balances[crowdFundAddress] = tokensAllocatedToCrowdFund;
        balances[founderMultiSigAddress] = foundersAllocation;

        totalAllocatedTokens = balances[founderMultiSigAddress];
    }

    /**
        @dev changeTotalSupply is the function used to variate the variable totalAllocatedTokens
        @param _amount amount of tokens are sold out to increase the value of totalAllocatedTokens
     */

    function changeTotalSupply(uint256 _amount) onlyCrowdfund {
        totalAllocatedTokens += _amount;
    }


    /**
        @dev changeFounderMultiSigAddress function use to change the ownership of the contract
        @param _newFounderMultiSigAddress New address which will take the ownership of the contract
     */
    
    function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
        founderMultiSigAddress = _newFounderMultiSigAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
    }

  
}


contract EPTCrowdfund {
    
    using SafeMath for uint256;

    EPTToken public token;                                      // Token contract reference
    
    address public beneficiaryAddress;                          // Address where all funds get allocated 
    address public founderAddress;                              // Founders address
    uint256 public crowdfundStartTime = 1516579201;             // Monday, 22-Jan-18 00:00:01 UTC
    uint256 public crowdfundEndTime = 1518998399;               // Sunday, 18-Feb-18 23:59:59 UTC
    uint256 public presaleStartTime = 1513123201;               // Wednesday, 13-Dec-17 00:00:01
    uint256 public presaleEndTime = 1516579199;                 // Sunday, 21-Jan-18 23:59:59
    uint256 public ethRaised;                                   // Counter to track the amount raised
    bool private tokenDeployed = false;                         // Flag to track the token deployment -- only can be set once
    uint256 public tokenSold;                                   // Counter to track the amount of token sold
    uint256 private ethRate;
    
    
    //events
    event ChangeFounderAddress(address indexed _newFounderAddress , uint256 _timestamp);
    event TokenPurchase(address indexed _beneficiary, uint256 _value, uint256 _amount);
    event CrowdFundClosed(uint256 _timestamp);
    
    enum State {PreSale, CrowdSale, Finish}
    
    //Modifiers
    modifier onlyfounder() {
        require(msg.sender == founderAddress);
        _;
    }

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier onlyPublic() {
        require(msg.sender != founderAddress);
        _;
    }

    modifier nonZeroEth() {
        require(msg.value != 0);
        _;
    }

    modifier isTokenDeployed() {
        require(tokenDeployed == true);
        _;
    }

    modifier isBetween() {
        require(now >= presaleStartTime && now <= crowdfundEndTime);
        _;
    }

    /**
        @dev EPTCrowdfund Constructor used to initialize the required variable.
        @param _founderAddress Founder address 
        @param _ethRate Rate of ether in dollars at the time of deployment.
        @param _beneficiaryAddress Address that hold all funds collected from investors

     */

    function EPTCrowdfund(address _founderAddress, address _beneficiaryAddress, uint256 _ethRate) {
        beneficiaryAddress = _beneficiaryAddress;
        founderAddress = _founderAddress;
        ethRate = uint256(_ethRate);
    }
   
    /**
        @dev setToken Function used to set the token address into the contract.
        @param _tokenAddress variable that contains deployed token address 
     */

    function setToken(address _tokenAddress) nonZeroAddress(_tokenAddress) onlyfounder {
         require(tokenDeployed == false);
         token = EPTToken(_tokenAddress);
         tokenDeployed = true;
    }
    
    
    /**
        @dev changeFounderWalletAddress used to change the wallet address or change the ownership
        @param _newAddress new founder wallet address
     */

    function changeFounderWalletAddress(address _newAddress) onlyfounder nonZeroAddress(_newAddress) {
         founderAddress = _newAddress;
         ChangeFounderAddress(founderAddress,now);
    }

    
    /**
        @dev buyTokens function used to buy the tokens using ethers only. sale 
            is only processed between start time and end time. 
        @param _beneficiary address of the investor
        @return bool 
     */

    function buyTokens (address _beneficiary)
    isBetween
    onlyPublic
    nonZeroAddress(_beneficiary)
    nonZeroEth
    isTokenDeployed
    payable
    public
    returns (bool)
    {
         uint256 amount = msg.value.mul(((ethRate.mul(100)).div(getRate())));
    
        if (token.transfer(_beneficiary, amount)) {
            fundTransfer(msg.value);
            
            ethRaised = ethRaised.add(msg.value);
            tokenSold = tokenSold.add(amount);
            token.changeTotalSupply(amount); 
            TokenPurchase(_beneficiary, msg.value, amount);
            return true;
        }
        return false;
    }

    /**
        @dev setEthRate function used to set the ether Rate
        @param _newEthRate latest eth rate
        @return bool
     
     */

    function setEthRate(uint256 _newEthRate) onlyfounder returns (bool) {
        require(_newEthRate > 0);
        ethRate = _newEthRate;
        return true;
    }

    /**
        @dev getRate used to get the price of each token on weekly basis
        @return uint256 price of each tokens in dollar
    
     */

    function getRate() internal returns(uint256) {

        if (getState() == State.PreSale) {
            return 10;
        } 
        if(getState() == State.CrowdSale) {
            if (now >= crowdfundStartTime + 3 weeks && now <= crowdfundEndTime) {
                return 30;
             }
            if (now >= crowdfundStartTime + 2 weeks) {
                return 25;
            }
            if (now >= crowdfundStartTime + 1 weeks) {
                return 20;
            }
            if (now >= crowdfundStartTime) {
                return 15;
            }  
        } else {
            return 0;
        }
              
    }  

    /**
        @dev `getState` used to findout the state of the crowdfund
        @return State 
     */

    function getState() private returns(State) {
        if (now >= crowdfundStartTime && now <= crowdfundEndTime) {
            return State.CrowdSale;
        }
        if (now >= presaleStartTime && now <= presaleEndTime) {
            return State.PreSale;
        } else {
            return State.Finish;
        }

    }

    /**
        @dev endCrowdFund called only after the end time of crowdfund . use to end the sale.
        @return bool
     */

    function endCrowdFund() onlyfounder returns(bool) {
        require(now > crowdfundEndTime);
        uint256 remainingtoken = token.balanceOf(this);

        if (remainingtoken != 0) {
            token.transfer(founderAddress,remainingtoken);
            CrowdFundClosed(now);
            return true;
        }
        CrowdFundClosed(now);
        return false;    
 } 

    /**
        @dev fundTransfer used to transfer collected ether into the beneficary address
     */

    function fundTransfer(uint256 _funds) private {
        beneficiaryAddress.transfer(_funds);
    }

    // Crowdfund entry
    // send ether to the contract address
    // gas used 200000
    function () payable {
        buyTokens(msg.sender);
    }

}