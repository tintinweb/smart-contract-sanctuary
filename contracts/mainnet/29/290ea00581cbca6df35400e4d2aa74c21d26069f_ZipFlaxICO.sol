pragma solidity ^0.4.20;

// ----------------------------------------------------------------------------
// ZipFlax ICO Crowdsale CONTRACT
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe math
// ----------------------------------------------------------------------------
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}


// ----------------------------------------------------------------------------
// Ownership contract
// _newOwner is address of new owner
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = 0xBF2B073fF018F6bF1Caee6cE716B833271C159ee;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0));
        emit OwnershipTransferred(owner,_newOwner);
        owner = _newOwner;
    }
    
}


// ----------------------------------------------------------------------------
// Token interface
// ----------------------------------------------------------------------------
contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    
}


// ----------------------------------------------------------------------------
// ZipFlax ICO smart contract
// ----------------------------------------------------------------------------
contract ZipFlaxICO is Owned{
    
    using SafeMath for uint256;
   
    enum State {
        PrivateSale,
        PreICO,
        ICO,
        Successful
    }
    
    //public variables
    uint256 tokenPrice;
    State public state; //Set initial stage
    uint256 public totalRaised; //eth in wei
    uint256 public totalDistributed; //tokens distributed
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
    
    
    // ----------------------------------------------------------------------------
    // constructor
    // _addressOfToken is the token totalDistributed
    // ----------------------------------------------------------------------------
    function ZipFlaxICO(token _addressOfTokenUsedAsReward) public {
        require(_addressOfTokenUsedAsReward != address(0));
        
        tokenPrice = 20000;
        state = State.PrivateSale;
        tokenReward = token(_addressOfTokenUsedAsReward);
        emit LogFunderInitialized(owner);
    }
    
    
    // ----------------------------------------------------------------------------
    // Function to handle eth transfers
    // It invokes when someone sends ETH to this contract address.
    // Requires enough gas for the execution otherwise it&#39;ll throw out of gas error.
    // tokens are transferred to user
    // ETH are transferred to current owner
    // ----------------------------------------------------------------------------
    function() public payable {
        contribute();
    }


    // ----------------------------------------------------------------------------
    // Acceptes ETH and send equivalent tokens with bonus if any.
    // ----------------------------------------------------------------------------
    function contribute() public notFinished payable {
        
        uint256 tokenBought; // Variable to store amount of tokens bought
        uint256 bonus; // Variable to store token bonus

        tokenBought = msg.value.mul(tokenPrice).mul(10 ** 8).div(10 ** 18);

        //Bonus calculation
        if (state == State.PrivateSale){
            bonus = tokenBought.mul(35).div(100); // 35 % bonus
        }
        
        if (state == State.PreICO){
            bonus = tokenBought.mul(25).div(100); // 25 % bonus
        }
        
        if (state == State.ICO){
            bonus = tokenBought.mul(20).div(100); // 20 % bonus
        }
        
        tokenBought = tokenBought.add(bonus); // Adding bonus
        
        // this smart contract should have enough tokens to distribute
        require(tokenReward.balanceOf(this) >= tokenBought);
        
        totalRaised = totalRaised.add(msg.value); //Save the total eth totalRaised (in wei)
        totalDistributed = totalDistributed.add(tokenBought); //Save to total tokens distributed
        
        tokenReward.transfer(msg.sender,tokenBought); //Send Tokens to user
        owner.transfer(msg.value); // Send ETH to owner
        
        //LOGS
        emit LogBeneficiaryPaid(owner);
        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit LogContributorsPayout(msg.sender,tokenBought);

    }


    // ----------------------------------------------------------------------------
    // To change to next stage
    // ----------------------------------------------------------------------------
    function nextState() onlyOwner public {
        require(state != State.ICO);
        state = State(uint(state) + 1);
    }
    
    
    // ----------------------------------------------------------------------------
    // To change to previous stage
    // ----------------------------------------------------------------------------
    function previousState() onlyOwner public {
        require(state != State.PrivateSale);
        state = State(uint(state) - 1);
    }
    
    
    // ----------------------------------------------------------------------------
    // To close the ICO and mark as Successful
    // ----------------------------------------------------------------------------
    function finished() onlyOwner public { 
        
        uint256 remainder = tokenReward.balanceOf(this); //Remaining tokens on contract
        
        //Funds send to creator if any
        if(address(this).balance > 0) {
            owner.transfer(address(this).balance);
            emit LogBeneficiaryPaid(owner);
        }
 
        tokenReward.transfer(owner,remainder); //remainder tokens send to creator
        emit LogContributorsPayout(owner, remainder);
        
        state = State.Successful; // updating the state
    }


    // ----------------------------------------------------------------------------
    // Function to claim any token stuck on contract
    // tokens is the amount to transfer tokens to the owner
    // ----------------------------------------------------------------------------
    function claimTokens(uint256 tokens) onlyOwner public {
        require(tokenReward.balanceOf(this) >= tokens); // should have enough tokens
        tokenReward.transfer(owner,tokens); // Transfer tokens to owner
    }

    
}