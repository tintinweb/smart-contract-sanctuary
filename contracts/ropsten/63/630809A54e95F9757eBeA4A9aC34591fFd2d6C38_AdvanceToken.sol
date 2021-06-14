/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.26;

//Define a simple contract
contract ERC20Interface {
  string public name;//Define the token name
  string public symbol;//Define token symbol
  uint8 public  decimals;//The decimal place that defines the fewest units of token transaction
  uint public totalSupply;//Define the amount of tokens issued
  function transfer(address _to, uint256 _value) returns (bool success);//The transfer function
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);//Once an agent has access to a token delegate, it can transfer tokens from _from's address (the principal's address) to another person's address
  function approve(address _spender, uint256 _value) returns (bool success);//The management authority of the delegated asset, _spender, is the address of the delegated asset and _value is the limit of the delegated asset
  function allowance(address _owner, address _spender) view returns (uint256 remaining);//The amount of delegated quotas
  event Transfer(address indexed _from, address indexed _to, uint256 _value);//Trigger Transfer Event
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);//Trigger authorization events
}

//Define a contract that contains the underlying information
contract ERC20 is ERC20Interface {
    mapping(address => uint256) public balanceOf;//Mapping the balance
    mapping(address => mapping(address => uint256)) allowed;//Mapping Authorization Behavior
    
    //Define the constructor of the contract
    constructor(string _name) public {
       name = "SickleCoin";//Define the token name
       symbol = "SIC";//Define the token symbol
       decimals = 18;//Defining Transaction Accuracy
       totalSupply = 1000000000 * 10 ** uint256(decimals);//Define circulation
       balanceOf[msg.sender] = totalSupply;//Define balance as total circulation
    }
    
   //Define a transfer receiving function
  function transfer(address _to, uint256 _value) returns (bool success) {
      require(_to != address(0));//Verify that the target account cannot be empty
      require(balanceOf[msg.sender] >= _value);//The token sender needs to have a sufficient balance
      require(balanceOf[ _to] + _value >= balanceOf[ _to]);//Check for overflows, where the balance of the party receiving the token is greater than or equal to the original balance
      balanceOf[msg.sender] -= _value;//The token sender's balance decreases
      balanceOf[_to] += _value;//The balance of the party receiving the token increases
      emit Transfer(msg.sender, _to, _value);//Trigger Transfer Event
      return true;
  }
  
  //Defines the function to be emitted by the principal transfer
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      require(_to != address(0));//The sending account cannot be empty
      require(allowed[_from][msg.sender] >= _value);//Confirm that the client needs to have the authorized amount to pay the transfer. The authorized amount is greater than or equal to the amount transferred
      require(balanceOf[_from] >= _value);//At the same time, the total balance of the client must be greater than or equal to the amount transferred
      require(balanceOf[ _to] + _value >= balanceOf[ _to]);//Check for overflow
      balanceOf[_from] -= _value;//Issuer balance reduced
      balanceOf[_to] += _value;//Receiver balance increased
      allowed[_from][msg.sender] -= _value;//The authorized person's total authorization is reduced by transferring money
      emit Transfer(msg.sender, _to, _value);//Trigger the entrusted transfer event
      return true;
  }
  
  //Defines a function that authorizes behavior
  function approve(address _spender, uint256 _value) returns (bool success) {
      allowed[msg.sender][_spender] = _value;//Authorize a certain amount to the entrusted account
      emit Approval(msg.sender, _spender, _value);//trigger event
      return true;
  }
  
  //Defines a function for the delegate amount
  function allowance(address _owner, address _spender) view returns (uint256 remaining) {
      return allowed[_owner][_spender];//Return Authorization Limit
  }

}

//Define a manager contract that enables the manager to issue additional authority and transfer authority to others
contract owned {
    address public owner;    

    //Set permissions so that only the owner can call transferOwnerShip. The constructor saves the address at which the contract was created.
    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);//Determine whether the caller is the issuer
        _;
    }

    //Define transfer functions that only onlyOwner can call, and onlyOwner can transfer permissions to Newower
    function transferOwnerShip(address newOwer) public onlyOwner {
        owner = newOwer;
    }

}

//Construct a senior contract that includes the ability to issue new tokens, freeze accounts, and destroy tokens
contract AdvanceToken is ERC20, owned {
    mapping (address => bool) public frozenAccount;
    event AddSupply(uint amount);//Define secondary issue events
    event FrozenFunds(address target, bool frozen);//Define frozen account events
    event Burn(address target, uint amount);//Define Token Destruction Event
    constructor (string _name) ERC20(_name) public {
    }

    //Defines the function of mining, that is, the function of adding tokens
    function mine(address target, uint amount) public onlyOwner {
        totalSupply += amount;//Modify total circulation, amount is the number of mines
        balanceOf[target] += amount;//The amount of additional issuance is added to the initial balance
        emit AddSupply(amount);//Trigger the event
        emit Transfer(0, target, amount);//Trigger the event
    }

    //Define a freeze function that prevents the account from transferring money
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);//Trigger the event
    }

  //A function that defines whether the transfer receiver has received the token
  function transfer(address _to, uint256 _value) public returns (bool success) {
        success = _transfer(msg.sender, _to, _value);
  }

  //A function that defines whether the transfer sender's function issues a token
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _value);//Verify that the sending account exists
        success =  _transfer(_from, _to, _value);
        allowed[_from][msg.sender] -= _value;
  }

  //Defines a function for the transfer receiver to receive tokens
  function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
      require(_to != address(0));//Verify that the recipient account exists
      require(!frozenAccount[_from]);//Make sure the transfer account is not blocked
      require(balanceOf[_from] >= _value);//Confirm if the balance is sufficient to meet the consignment quantity
      require(balanceOf[ _to] + _value >= balanceOf[ _to]);//Verify that there is no overflow
      balanceOf[_from] -= _value;//The token issuer's balance is reduced by _value
      balanceOf[_to] += _value;//The token recipient's balance increases by _value
      emit Transfer(_from, _to, _value);//Trigger the event
      return true;
  }

    //Define the destroy token function
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);//Check if there is enough balance to destroy
        totalSupply -= _value;//Circulation decreases _value
        balanceOf[msg.sender] -= _value;//The amount of decrease in the account balance is _value
        emit Burn(msg.sender, _value);//Trigger a Token Destruction event
        return true;
    }

    //Define the entrusted token destruction function, the issuer can entrust other people to perform the destruction of the token operation
    function burnFrom(address _from, uint256 _value)  public returns (bool success) {
        require(balanceOf[_from] >= _value);//Verify that the entrusted account has sufficient balance
        require(allowed[_from][msg.sender] >= _value);//Verify that the amount of authorization is sufficient
        totalSupply -= _value;//The amount of circulation decreased is _value
        balanceOf[msg.sender] -= _value;//And the balance of the entrusted account minus _value
        allowed[_from][msg.sender] -= _value;//The amount of authorization minus _value
        emit Burn(msg.sender, _value);//Trigger a Token Destruction event
        return true;
    }
}

interface token {
    function transfer(address receiver, uint amount) external ;
}

//Define ICO Contracts
contract Ico {
    address public beneficiary;//Define the beneficiaries of crowdfunding
    uint public fundingGoal;//Define the goal of crowdfunding
    uint public amountRaised;//Define the amount of crowdfunding
    uint public deadline;//Define a deadline
    uint public price;//Define the crowdfunding price
    token public tokenReward;//Defines the number of tokens to send
    mapping(address => uint256) public balanceOf;//Mapping the balance of the participant's account
    bool crowdsaleClosed = false;//Define to turn off crowdfunding and assign false
    event GoalReached(address recipient, uint totalAmountRaised);//Define the events that achieve the goal
    event FundTransfer(address backer, uint amount, bool isContribution);//Define funds transfer events
    
    //Construct the crowdfunding function
    constructor (
        uint fundingGoalInEthers,//Name the target of the crowdfunding as Ethereum
        uint durationInMinutes,//The specified period is in minutes
        uint etherCostOfEachToken,//The price unit for the designated token is Ethereum
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = msg.sender;//The beneficiary is the creator of the contract
        fundingGoal = fundingGoalInEthers * 1 ether;//Assign a value to the crowdfunding target using the price of Ethereum
        deadline = now + durationInMinutes * 1 minutes;//Define a crowdfunding deadline
        price = etherCostOfEachToken * 1 ether;//Define the price at which tokens are settled on Ethereum
        tokenReward = token(addressOfTokenUsedAsReward);//Assign a value to the tokens that need to be exchanged
    }

    //Define the fallback function to implement the exchange with Ethereum. A user sends a certain amount of Ethereum and gets a certain amount of tokens
    function () public payable {
        require(!crowdsaleClosed);//Confirm if the crowdfunding is over and if it is, it cannot be executed
        uint amount = msg.value;  //The amount of Ethereum raised is Amount
        balanceOf[msg.sender] += amount;// Participants' account balances increase accordingly
        amountRaised += amount;//The amount of crowdfunding increases accordingly
        tokenReward.transfer(msg.sender, amount / price);//Return the tokens
        emit FundTransfer(msg.sender, amount, true);//Trigger the event
    }
    modifier afterDeadline() {
        if (now >= deadline) {
            _;
        }
    }

    //A function that defines whether the crowdfunding goal is achieved, and if the goal is achieved, the crowdfunding is turned off
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {//If the amount raised is greater than the target
            emit GoalReached(beneficiary, amountRaised);//Trigger the event
        }
        crowdsaleClosed = true;//Close all the raise
    }

    //Define the function of crowdfunding failure. If crowdfunding fails, the refund will be given, and the issuer will withdraw the money if crowdfunding succeeds
    function safeWithdrawal() public afterDeadline {
        if (amountRaised < fundingGoal) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);//Trigger the event
            }
        }

        if (fundingGoal <= amountRaised && beneficiary == msg.sender) {
            beneficiary.transfer(amountRaised);
            emit FundTransfer(beneficiary, amountRaised, false);//Trigger the event
        }
    }
}