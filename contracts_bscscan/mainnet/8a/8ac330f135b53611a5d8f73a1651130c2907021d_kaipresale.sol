/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

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
  function transferOwnership(address newOwner)public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}


interface token {
    function balanceOf(address _owner) external constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
}



contract kaipresale is Ownable{

    using SafeMath for uint256;
    
    mapping(address => uint256) public amountInvested;
    
    enum State {
        Active,
        Dormant,
        Successful
    }
    
    //public variables
    State public state; //Set initial stage
    uint256 public tokenPrice; // token price
    uint256 public totalWEIRaised; //eth in wei
    uint256 public totalTokensDistributed; //tokens distributed
    token public tokenReward; //Address of the valid token used as reward

    //events for log
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(address _creator);
    event LogContributorsPayout(address _addr, uint _amount);


    modifier notFinished {
        require(state != State.Successful);
        _;
    }
    
    
    /**
    * @notice constructor
    */
    constructor() public {
        tokenReward = token(address(0xfd9e9220ECe1Ce92687A8f5FeE446B9f310Aa0d2));
        emit LogFunderInitialized(owner);
    }

    
    function changePrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
    }
    
    function startSale() onlyOwner public {
        state = State.Active;
    }
    
    function pauseSale() onlyOwner public {
        state = State.Dormant;
    }
    

    /**
    * @notice contribution handler
    */
    function contribute() public notFinished payable {
        require(msg.value >= 0.1 * 1 ether);
        
        uint256 tokenBought; 

        tokenBought = msg.value.mul(tokenPrice);

        totalWEIRaised = totalWEIRaised.add(msg.value);
        totalTokensDistributed = totalTokensDistributed.add(tokenBought);
        
        owner.transfer(msg.value); // Send ETH to owner
        tokenReward.transfer(msg.sender,tokenBought); //Send Tokens to user
        
        amountInvested[msg.sender] = msg.value;
        
        //LOGS
        emit LogBeneficiaryPaid(owner);
        emit LogFundingReceived(msg.sender, msg.value, tokenBought);
        emit LogContributorsPayout(msg.sender,tokenBought);

    }


    /**
    * @notice Function for closure handle
    */
    function finished() onlyOwner public { 
        
        uint256 remainder = tokenReward.balanceOf(this); //Remaining tokens on contract
        
        //Funds(ETH) send to creator if any
        if(address(this).balance > 0) {
            owner.transfer(address(this).balance);
            emit LogBeneficiaryPaid(owner);
        }
 
        tokenReward.transfer(owner,remainder);

        state = State.Successful; // updating the state
    }


    function tokensAvailable() public view returns(uint256) {
        return tokenReward.balanceOf(this)*10**18;
    }


    /**
    * @notice Function to handle eth transfers
    * @dev BEWARE: if a call to this functions doesn't have
    * enought gas, transaction could not be finished
    */
    function() public payable {
        contribute();
    }
    
}