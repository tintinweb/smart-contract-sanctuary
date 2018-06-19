pragma solidity ^0.4.17;

// ----------------------------------------------------------------------------
// BLU ICO contract
//
// BLU mainnet token address : 0x362a95215564d895f27021a7d7314629db2e1649
// RATE = 4000 => 1 ETH = 4000 BLU
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

    function Owned() public {
        owner = 0x0567cB7c5A688401Aab87093058754E096C4d37E;
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
// BlupassToken interface
// ----------------------------------------------------------------------------
contract BlupassToken {
    
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    
}


// ----------------------------------------------------------------------------
// Blupass ICO smart contract
// ----------------------------------------------------------------------------
contract BlupassICO is Owned {

    using SafeMath for uint256;
    
    // public Variables
    uint256 public totalRaised; //eth in wei
    uint256 public totalDistributed; //tokens distributed
    uint256 public RATE; // RATE of the BLU
    BlupassToken public BLU; // BLU token address
    bool public isStopped = false; // ICO start/stop
    
    mapping(address => bool) whitelist; // whitelisting for KYC verified users

    // events for log
    event LogWhiteListed(address _addr);
    event LogBlackListed(address _addr);
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(address _creator);
    event LogContributorsPayout(address _addr, uint _amount);
    
    // To determine whether the ICO is running or stopped
    modifier onlyWhenRunning {
        require(!isStopped);
        _;
    }
    
    // To determine whether the user is whitelisted 
    modifier onlyifWhiteListed {
        require(whitelist[msg.sender]);
        _;
    }
    
    // ----------------------------------------------------------------------------
    // BlupassICO constructor
    // _addressOfToken is the token totalDistributed
    // ----------------------------------------------------------------------------
    function BlupassICO (BlupassToken _addressOfToken) public {
        require(_addressOfToken != address(0)); // should have valid address
        RATE = 4000;
        BLU = BlupassToken(_addressOfToken);
        emit LogFunderInitialized(owner);
    }
    
    
    // ----------------------------------------------------------------------------
    // Function to handle eth transfers
    // It invokes when someone sends ETH to this contract address.
    // Requires enough gas for the execution otherwise it&#39;ll throw out of gas error.
    // tokens are transferred to user
    // ETH are transferred to current owner
    // minimum 1 ETH investment
    // ----------------------------------------------------------------------------
    function() public payable {
        contribute();
    }


    // ----------------------------------------------------------------------------
    // Acceptes ETH and send equivalent BLU with bonus if any.
    // NOTE: Add user to whitelist by invoking addToWhiteList() function.
    // Only whitelisted users can buy tokens.
    // For Non-whitelisted/Blacklisted users transaction will be reverted. 
    // ----------------------------------------------------------------------------
    function contribute() onlyWhenRunning onlyifWhiteListed public payable {
        
        require(msg.value >= 1 ether); // min 1 ETH investment
        
        uint256 tokenBought; // Variable to store amount of tokens bought
        uint256 bonus; // Variable to store bonus if any

        totalRaised = totalRaised.add(msg.value); // Save the total eth totalRaised (in wei)
        tokenBought = msg.value.mul(RATE); // Token calculation according to RATE
        
        // Bonus for  5+ ETH investment
        
        // 20 % bonus for 5 to 9 ETH investment
        if (msg.value >= 5 ether && msg.value <= 9 ether) {
            bonus = (tokenBought.mul(20)).div(100); // 20 % bonus
            tokenBought = tokenBought.add(bonus);
        } 
        
        // 40 % bonus for 10+ ETH investment
        if (msg.value >= 10 ether) {
            bonus = (tokenBought.mul(40)).div(100); // 40 % bonus
            tokenBought = tokenBought.add(bonus);
        }

        // this smart contract should have enough tokens to distribute
        require(BLU.balanceOf(this) >= tokenBought);
        
        totalDistributed = totalDistributed.add(tokenBought); //Save to total tokens distributed
        BLU.transfer(msg.sender,tokenBought); //Send Tokens to user
        owner.transfer(msg.value); // Send ETH to owner
        
        //LOGS
        emit LogContributorsPayout(msg.sender,tokenBought); // Log investor paid event
        emit LogBeneficiaryPaid(owner); // Log owner paid event
        emit LogFundingReceived(msg.sender, msg.value, totalRaised); // Log funding event
    }


    // ----------------------------------------------------------------------------
    // function to whitelist user if KYC verified
    // returns true if whitelisting is successful else returns false
    // ----------------------------------------------------------------------------
    function addToWhiteList(address _userAddress) onlyOwner public returns(bool) {
        require(_userAddress != address(0)); // user address must be valid
        // if not already in the whitelist
        if (!whitelist[_userAddress]) {
            whitelist[_userAddress] = true;
            emit LogWhiteListed(_userAddress); // Log whitelist event
            return true;
        } else {
            return false;
        }
    }
    
    
    // ----------------------------------------------------------------------------
    // function to remove user from whitelist
    // ----------------------------------------------------------------------------
    function removeFromWhiteList(address _userAddress) onlyOwner public returns(bool) {
        require(_userAddress != address(0)); // user address must be valid
        // if in the whitelist
        if(whitelist[_userAddress]) {
           whitelist[_userAddress] = false; 
           emit LogBlackListed(_userAddress); // Log blacklist event
           return true;
        } else {
            return false;
        }
        
    }
    
    
    // ----------------------------------------------------------------------------
    // function to check if user is whitelisted
    // ----------------------------------------------------------------------------
    function checkIfWhiteListed(address _userAddress) view public returns(bool) {
        return whitelist[_userAddress];
    }
    
    
    // ----------------------------------------------------------------------------
    // function to stop the ICO
    // ----------------------------------------------------------------------------
    function stopICO() onlyOwner public {
        isStopped = true;
    }
    
    
    // ----------------------------------------------------------------------------
    // function to resume the ICO
    // ----------------------------------------------------------------------------
    function resumeICO() onlyOwner public {
        isStopped = false;
    }


    // ----------------------------------------------------------------------------
    // Function to claim any token stuck on contract
    // ----------------------------------------------------------------------------
    function claimTokens() onlyOwner public {
        uint256 remainder = BLU.balanceOf(this); //Check remainder tokens
        BLU.transfer(owner,remainder); //Transfer tokens to owner
    }
    
}