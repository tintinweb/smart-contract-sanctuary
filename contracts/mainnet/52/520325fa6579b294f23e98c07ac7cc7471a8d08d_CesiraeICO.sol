pragma solidity ^0.4.17;

// ----------------------------------------------------------------------------
// CSE ICO contract
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
        owner = 0x3fCD36fcE4097245AB0f2bA50486BC01D2a3ee44;
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
// CesiraeToken interface
// ----------------------------------------------------------------------------
contract CesiraeToken {
    
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    
}


// ----------------------------------------------------------------------------
// CesiraeICO smart contract
// ----------------------------------------------------------------------------
contract CesiraeICO is Owned {

    using SafeMath for uint256;
    
    enum State {
        PrivatePreSale,
        PreICO,
        ICORound1,
        ICORound2,
        ICORound3,
        ICORound4,
        ICORound5,
        Successful
    }
    
    //public variables
    State public state; //Set initial stage
    uint256 public totalRaised; //eth in wei
    uint256 public totalDistributed; //tokens distributed
    CesiraeToken public CSE; // CSE token address
    
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
    modifier onlyIfNotFinished {
        require(state != State.Successful);
        _;
    }
    
    // To determine whether the user is whitelisted 
    modifier onlyIfWhiteListedOnPreSale {
        if(state == State.PrivatePreSale) {
          require(whitelist[msg.sender]);
        } 
        _;
    }
    
    // ----------------------------------------------------------------------------
    // CesiraeICO constructor
    // _addressOfToken is the token totalDistributed
    // ----------------------------------------------------------------------------
    function CesiraeICO (CesiraeToken _addressOfToken) public {
        require(_addressOfToken != address(0)); // should have valid address
        CSE = CesiraeToken(_addressOfToken);
        state = State.PrivatePreSale;
        emit LogFunderInitialized(owner);
    }
    
    
    // ----------------------------------------------------------------------------
    // Function to handle eth transfers
    // It invokes when someone sends ETH to this contract address.
    // Requires enough gas for the execution otherwise it&#39;ll throw out of gas error.
    // tokens are transferred to user
    // ETH are transferred to current owner
    // minimum 1 ETH investment
    // maxiumum 10 ETH investment
    // ----------------------------------------------------------------------------
    function() public payable {
        contribute();
    }


    // ----------------------------------------------------------------------------
    // Acceptes ETH and send equivalent CSE with bonus if any.
    // NOTE: Add user to whitelist by invoking addToWhiteList() function.
    // Only whitelisted users can buy tokens.
    // For Non-whitelisted/Blacklisted users transaction will be reverted. 
    // ----------------------------------------------------------------------------
    function contribute() onlyIfNotFinished onlyIfWhiteListedOnPreSale public payable {
        
        uint256 tokenBought; // Variable to store amount of tokens bought
        uint256 bonus; // Variable to store bonus if any
        uint256 tokenPrice;
        
        //Token allocation calculation
        if (state == State.PrivatePreSale){
            require(msg.value >= 2 ether); // min 2 ETH investment
            tokenPrice = 160000;
            tokenBought = msg.value.mul(tokenPrice);
            bonus = tokenBought; // 100 % bonus
        } 
        else if (state == State.PreICO){
            require(msg.value >= 1 ether); // min 1 ETH investment
            tokenPrice = 160000;
            tokenBought = msg.value.mul(tokenPrice);
            bonus = tokenBought.mul(50).div(100); // 50 % bonus
        } 
        else if (state == State.ICORound1){
            require(msg.value >= 0.7 ether); // min 0.7 ETH investment
            tokenPrice = 140000;
            tokenBought = msg.value.mul(tokenPrice);
            bonus = tokenBought.mul(40).div(100); // 40 % bonus
        } 
        else if (state == State.ICORound2){
            require(msg.value >= 0.5 ether); // min 0.5 ETH investment
            tokenPrice = 120000;
            tokenBought = msg.value.mul(tokenPrice);
            bonus = tokenBought.mul(30).div(100); // 30 % bonus
        } 
        else if (state == State.ICORound3){
            require(msg.value >= 0.3 ether); // min 0.3 ETH investment
            tokenPrice = 100000;
            tokenBought = msg.value.mul(tokenPrice);
            bonus = tokenBought.mul(20).div(100); // 20 % bonus
        } 
        else if (state == State.ICORound4){
            require(msg.value >= 0.2 ether); // min 0.2 ETH investment
            tokenPrice = 80000;
            tokenBought = msg.value.mul(tokenPrice);
            bonus = tokenBought.mul(10).div(100); // 10 % bonus
        } 
        else if (state == State.ICORound5){
            require(msg.value >= 0.1 ether); // min 0.1 ETH investment
            tokenPrice = 60000;
            tokenBought = msg.value.mul(tokenPrice);
            bonus = 0; // 0 % bonus
        } 

        tokenBought = tokenBought.add(bonus); // add bonus to the tokenBought
        
        // this smart contract should have enough tokens to distribute
        require(CSE.balanceOf(this) >= tokenBought);
        
        totalRaised = totalRaised.add(msg.value); // Save the total eth totalRaised (in wei)
        totalDistributed = totalDistributed.add(tokenBought); //Save to total tokens distributed
        
        CSE.transfer(msg.sender,tokenBought); //Send Tokens to user
        owner.transfer(msg.value); // Send ETH to owner
        
        //LOGS
        emit LogContributorsPayout(msg.sender,tokenBought); // Log investor paid event
        emit LogBeneficiaryPaid(owner); // Log owner paid event
        emit LogFundingReceived(msg.sender, msg.value, totalRaised); // Log funding event
    }
    
    
    function finished() onlyOwner public { 
        
        uint256 remainder = CSE.balanceOf(this); //Remaining tokens on contract
        
        //Funds send to creator if any
        if(address(this).balance > 0) {
            owner.transfer(address(this).balance);
            emit LogBeneficiaryPaid(owner);
        }
 
        CSE.transfer(owner,remainder); //remainder tokens send to creator
        emit LogContributorsPayout(owner, remainder);
        
        state = State.Successful; // updating the state
    }
    
    
    function nextState() onlyOwner public {
        require(state != State.ICORound5);
        state = State(uint(state) + 1);
    }
    
    
    function previousState() onlyOwner public {
        require(state != State.PrivatePreSale);
        state = State(uint(state) - 1);
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
    // Function to claim any token stuck on contract
    // ----------------------------------------------------------------------------
    function claimTokens() onlyOwner public {
        uint256 remainder = CSE.balanceOf(this); //Check remainder tokens
        CSE.transfer(owner,remainder); //Transfer tokens to owner
    }
    
}