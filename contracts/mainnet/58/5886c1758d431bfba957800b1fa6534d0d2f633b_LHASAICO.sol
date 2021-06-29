/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.4.26;

// ----------------------------------------------------------------------------
// LHASA ICO contract
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe math
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// Ownership contract
// _newOwner is address of new owner
// ----------------------------------------------------------------------------
contract Owned {
    
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // transfer Ownership to other address
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0));
        emit OwnershipTransferred(owner,_newOwner);
        owner = _newOwner;
    }
    
}


// ----------------------------------------------------------------------------
// LHASAToken interface
// ----------------------------------------------------------------------------
contract LHASAToken {
    
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}


// ----------------------------------------------------------------------------
// LHASAICO smart contract
// ----------------------------------------------------------------------------
contract LHASAICO is Owned {

    using SafeMath for uint256;
    
    enum State {
        PrivateSale,
        PreSale,
        Successful
    }
    
    // public variables
    State public state; // Set initial stage
    uint256 public totalRaised; // eth in wei
    uint256 public totalDistributed; // tokens distributed
    LHASAToken public LHASA; // LHASA token address
    
    // caps
    uint256 public hardcap_PrivateSale = 37.5 ether;
    uint256 public hardcap_PreSale = 116 ether;
    uint256 public currentcap_PrivateSale;
    uint256 public currentcap_PreSale;

    // events for log
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(address _creator);
    event LogContributorsPayout(address _addr, uint _amount);
    
    // To determine whether the ICO is running or stopped
    modifier onlyIfNotFinished {
        require(state != State.Successful);
        _;
    }
    
    
    // ----------------------------------------------------------------------------
    // LHASAICO constructor
    // _addressOfToken is the token totalDistributed
    // ----------------------------------------------------------------------------
    constructor(LHASAToken _addressOfToken) public {
        require(_addressOfToken != address(0)); // should have valid address
        LHASA = LHASAToken(_addressOfToken);
        state = State.PrivateSale;
        emit LogFunderInitialized(owner);
    }
    
    
    // ----------------------------------------------------------------------------
    // Function to handle eth transfers
    // It invokes when someone sends ETH to this contract address.
    // Requires enough gas for the execution otherwise it'll throw out of gas error.
    // tokens are transferred to user
    // ETH are transferred to current owner
    // ----------------------------------------------------------------------------
    function() public payable {
        contribute();
    }


    // ----------------------------------------------------------------------------
    // Acceptes ETH and send equivalent LHASA with bonus if any.
    // ----------------------------------------------------------------------------
    function contribute() onlyIfNotFinished public payable {
        
        uint256 tokenBought; // Variable to store amount of tokens bought
        uint256 tokenPrice;
        
        // Token allocation calculation
        if (state == State.PrivateSale){
            // check min and max investment
            require(msg.value >= 0.1 ether && msg.value <= 2 ether, "Private sale investment should be between 0.1 - 2 ETH");
            
            // token price
            tokenPrice = 4000000000000; // 1 ETH = 4 Trillions
            
            // increase current cap
            currentcap_PrivateSale = currentcap_PrivateSale.add(msg.value);
            
            // check hardcap 
            require(currentcap_PrivateSale <= hardcap_PrivateSale, "PrivateSale hardcap reached");
        } 
        else if (state == State.PreSale){
            // check min and max investment
            require(msg.value >= 0.1 ether && msg.value <= 5 ether, "Pre sale investment should be between 0.1 - 5 ETH");
            
            // token price
            tokenPrice = 3000000000000; // 1 ETH = 3 Trillions
            
            // increase current cap
            currentcap_PreSale = currentcap_PreSale.add(msg.value);
            
            // check hardcap 
            require(currentcap_PreSale <= hardcap_PreSale, "PreSale hardcap reached");
        } 
        else {
            revert();
        }
    
        tokenBought = (msg.value).mul(tokenPrice).div(10 ** 9);
        
        // this smart contract should have enough tokens to distribute
        require(LHASA.balanceOf(this) >= tokenBought);
        
        totalRaised = totalRaised.add(msg.value); // Save the total eth totalRaised (in wei)
        totalDistributed = totalDistributed.add(tokenBought); //Save to total tokens distributed
        
        LHASA.transfer(msg.sender,tokenBought); // Send Tokens to user
        owner.transfer(msg.value); // Send ETH to owner
        
        // LOGS
        emit LogContributorsPayout(msg.sender,tokenBought); // Log investor paid event
        emit LogBeneficiaryPaid(owner); // Log owner paid event
        emit LogFundingReceived(msg.sender, msg.value, totalRaised); // Log funding event
    }
    
    
    function finished() onlyOwner public { 
        
        uint256 remainder = LHASA.balanceOf(this); //Remaining tokens on contract
        
        // Funds send to creator if any
        if(address(this).balance > 0) {
            owner.transfer(address(this).balance);
            emit LogBeneficiaryPaid(owner);
        }
 
        LHASA.transfer(owner,remainder); //remainder tokens send to creator
        emit LogContributorsPayout(owner, remainder);
        
        state = State.Successful; // updating the state
    }
    
    // ------------------------------------------------------------------------
    // Move to next ICO state
    // ------------------------------------------------------------------------
    function nextState() onlyOwner public {
        require(state != State.PreSale);
        state = State(uint(state) + 1);
    }
    
    // ------------------------------------------------------------------------
    // Move to previous ICO state
    // ------------------------------------------------------------------------
    function previousState() onlyOwner public {
        require(state != State.PrivateSale);
        state = State(uint(state) - 1);
    }

    // ----------------------------------------------------------------------------
    // Function to claim any token stuck on contract
    // ----------------------------------------------------------------------------
    function claimTokens() onlyOwner public {
        uint256 remainder = LHASA.balanceOf(this); //Check remainder tokens
        LHASA.transfer(owner,remainder); //Transfer tokens to owner
    }
    
}