// Human token smart contract.
// Developed by Phenom.Team <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b6dfd8d0d9f6c6ded3d8d9db98c2d3d7db">[email&#160;protected]</a>>
pragma solidity ^0.4.21;


/**
 *   @title SafeMath
 *   @dev Math operations with safety checks that throw on error
 */

library SafeMath {

    function mul(uint a, uint b) internal constant returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal constant returns(uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal constant returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal constant returns(uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 *   @title ERC20
 *   @dev Standart ERC20 token interface
 */

contract ERC20 {
    uint public totalSupply = 0;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}


/**
 *   @title HumanToken
 *   @dev Human token smart-contract
 */
contract HumanToken is ERC20 {
    using SafeMath for uint;
    string public name = "Human";
    string public symbol = "Human";
    uint public decimals = 18;
    uint public voteCost = 10**18;

    // Owner address
    address public owner;
    address public eventManager;

    mapping (address => bool) isActiveEvent;
            
    //events        
    event EventAdded(address _event);
    event Contribute(address _event, address _contributor, uint _amount);
    event Vote(address _event, address _contributor, bool _proposal);
    
    // Allows execution by the contract owner only
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Allows execution by the event manager only
    modifier onlyEventManager {
        require(msg.sender == eventManager);
        _;
    }

   // Allows contributing and voting only to human events 
    modifier onlyActive(address _event) {
        require(isActiveEvent[_event]);
        _;
    }


   /**
    *   @dev Contract constructor function sets owner address
    *   @param _owner        owner address
    */
    function HumanToken(address _owner, address _eventManager) public {
       owner = _owner;
       eventManager = _eventManager;
    }


   /**
    *   @dev Function to add a new event from TheHuman team
    *   @param _event       a new event address
    */   
    function  addEvent(address _event) external onlyEventManager {
        require (!isActiveEvent[_event]);
        isActiveEvent[_event] = true;
        EventAdded(_event);
    }

   /**
    *   @dev Function to change vote cost, by default vote cost equals 1 Human token
    *   @param _voteCost     a new vote cost
    */
    function setVoteCost(uint _voteCost) external onlyEventManager {
        voteCost = _voteCost;
    }
    
   /**
    *   @dev Function to donate for event
    *   @param _event     address of event
    *   @param _amount    donation amount    
    */
    function donate(address _event, uint _amount) public onlyActive(_event) {
        require (transfer(_event, _amount));
        require (HumanEvent(_event).contribute(msg.sender, _amount));
        Contribute(_event, msg.sender, _amount);
        
    }

   /**
    *   @dev Function voting for the success of the event
    *   @param _event     address of event
    *   @param _proposal  true - event completed successfully, false - otherwise
    */
    function vote(address _event, bool _proposal) public onlyActive(_event) {
        require(transfer(_event, voteCost));
        require(HumanEvent(_event).vote(msg.sender, _proposal));
        Vote(_event, msg.sender, _proposal);
    }
    
    


   /**
    *   @dev Function to mint tokens
    *   @param _holder       beneficiary address the tokens will be issued to
    *   @param _value        number of tokens to issue
    */
    function mintTokens(address _holder, uint _value) external onlyOwner {
       require(_value > 0);
       balances[_holder] = balances[_holder].add(_value);
       totalSupply = totalSupply.add(_value);
       Transfer(0x0, _holder, _value);
    }

  
   /**
    *   @dev Get balance of tokens holder
    *   @param _holder        holder&#39;s address
    *   @return               balance of investor
    */
    function balanceOf(address _holder) constant returns (uint) {
         return balances[_holder];
    }

   /**
    *   @dev Send coins
    *   throws on any error rather then return a false flag to minimize
    *   user errors
    *   @param _to           target address
    *   @param _amount       transfer amount
    *
    *   @return true if the transfer was successful
    */
    function transfer(address _to, uint _amount) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

   /**
    *   @dev An account/contract attempts to get the coins
    *   throws on any error rather then return a false flag to minimize user errors
    *
    *   @param _from         source address
    *   @param _to           target address
    *   @param _amount       transfer amount
    *
    *   @return true if the transfer was successful
    */
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }


   /**
    *   @dev Allows another account/contract to spend some tokens on its behalf
    *   throws on any error rather then return a false flag to minimize user errors
    *
    *   also, to minimize the risk of the approve/transferFrom attack vector
    *   approve has to be called twice in 2 separate transactions - once to
    *   change the allowance to 0 and secondly to change it to the new allowance
    *   value
    *
    *   @param _spender      approved address
    *   @param _amount       allowance amount
    *
    *   @return true if the approval was successful
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

   /**
    *   @dev Function to check the amount of tokens that an owner allowed to a spender.
    *
    *   @param _owner        the address which owns the funds
    *   @param _spender      the address which will spend the funds
    *
    *   @return              the amount of tokens still avaible for the spender
    */
    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }

    /** 
    *   @dev Allows owner to transfer out any accidentally sent ERC20 tokens
    *   @param tokenAddress  token address
    *   @param tokens        transfer amount
    */
    function transferAnyTokens(address tokenAddress, uint tokens) 
        public
        onlyOwner 
        returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}

 contract HumanEvent {
    using SafeMath for uint;    
    uint public totalRaised;
    uint public softCap;
    uint public positiveVotes;
    uint public negativeVotes;

    address public alternative;
    address public owner;
    HumanToken public human;

    mapping (address => uint) public contributions;
    mapping (address => bool) public voted;
    mapping (address => bool) public claimed;
    


    // Allows execution by the contract owner only
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Allows execution by the contract owner only
    modifier onlyHuman {
        require(msg.sender == address(human));
        _;
    }


    // Possible Event statuses
    enum StatusEvent {
        Created,
        Fundraising,
        Failed,
        Evaluating,
        Voting,
        Finished
    }
    StatusEvent public statusEvent = StatusEvent.Created;

    
    function HumanEvent(
        address _owner, 
        uint _softCap,
        address _alternative,
        address _human
    ) public {
        owner = _owner;
        softCap = _softCap;
        alternative = _alternative;
        human = HumanToken(_human);
    }

    function startFundraising() public onlyOwner {
        require(statusEvent == StatusEvent.Created);
        statusEvent = StatusEvent.Fundraising;
        
    }
    

    function startEvaluating() public onlyOwner {
        require(statusEvent == StatusEvent.Fundraising);
        
        if (totalRaised >= softCap) {
            statusEvent = StatusEvent.Evaluating;
        } else {
            statusEvent = StatusEvent.Failed;
        }
    }

    function startVoting() public onlyOwner {
        require(statusEvent == StatusEvent.Evaluating);
        statusEvent = StatusEvent.Voting;
    }

    function finish() public onlyOwner {
        require(statusEvent == StatusEvent.Voting);
        if (positiveVotes >= negativeVotes) {
            statusEvent = StatusEvent.Finished;
        } else {
            statusEvent = StatusEvent.Failed;
        }
    }
    
    
    function claim() public {
        require(!claimed[msg.sender]);        
        claimed[msg.sender] = true;
        uint contribution;

        if (statusEvent == StatusEvent.Failed) {
            contribution = contribution.add(contributions[msg.sender]);
            contributions[msg.sender] = 0;
        }

        if(voted[msg.sender] && statusEvent != StatusEvent.Voting) {
            uint _voteCost = human.voteCost();
            contribution = contribution.add(_voteCost);
        }
        require(contribution > 0);
        require(human.transfer(msg.sender, contribution));
    }

    
    function vote(address _voter, bool _proposal) external onlyHuman returns (bool) {
        require(!voted[_voter] && statusEvent == StatusEvent.Voting);
        voted[_voter] = true;
        
        if (_proposal) {
            positiveVotes++;
        } else {
            negativeVotes++;
        }
        return true;
    }


    function contribute(address _contributor, uint _amount) external onlyHuman returns(bool) {
        require (statusEvent == StatusEvent.Fundraising);
        contributions[_contributor] =  contributions[_contributor].add(_amount);
        totalRaised = totalRaised.add(_amount);
        return true;
    }
    
    function  withdraw() external onlyOwner {
        require (statusEvent == StatusEvent.Finished);
        require (human.transfer(alternative, totalRaised));
    }

}