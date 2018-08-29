pragma solidity 0.4.24;


library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
interface TokenContractInterface {
  function balanceOf(address _owner) external constant returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
}

contract ICOPool is Ownable
{
    using SafeMath for uint;
    
    // numerator and denominator to find the exact percentage of tokens that the pool creator will get
    uint feePctNumerator;
    uint feePctDenominator;

    // the address where the collected ethers would be sent to
    address icoAddress;

    // the token address for which this pool is setup for 
    address tokenAddress;
    
    // the interface to the required contract functions
    TokenContractInterface token;
    
    // maximum ethers that this pool can accept
    uint maxPoolContribution;
    
    // minimum contribution possible for an individual address
    uint minIndividualContribution;

    // maximum contribution possible for an individual address
    uint maxIndividualContribution;

    // flag to determine whether this pool/ICO requires the contributors to be whitelisted or not
    // whitelisting can only be done by the owner of the pool
    bool isWhiteListingImplemented;
    
    // mapping for whitelisted users
    mapping(address=>bool) isUserWhiteListed;
    
    // default contract stage
    // 1 - The initial state. The owner is able to add addresses to the whitelist, and any whitelisted addresses can deposit or withdraw eth to the contract.
    // 2 - The owner has closed the contract for further deposits. Whitelisted addresses can still withdraw eth from the contract.
    // 3 - The eth is sent from the contract to the receiver. Unused eth can be claimed by contributors immediately. Once tokens are sent to the contract,
    //     the owner enables withdrawals and contributors can withdraw their tokens.
    uint PoolState = 1;
    
    // total ethers raised by the contract till now
    uint fundsRaised = 0;

    // the admins that can perform high authorization tasks for this pool
    address[] admins;
    
    // final balance of this contract which is sent to the receiver address
    // this is set at the time of submitting the pool
    uint finalBalance = 0;

    // the address liable for 0.25% of the tokens as a token gratitude for the creation of this platform
    address PlatformOwner = address(0x961863188d6c78a63bd9bbed70c58cafadad7c18);

    // the total tokens received in the contract 
    // this is set after the pool is submitted and the receiver has sent the tokens to this contract
    uint totalTokensReceivedInContract = 0;

    // the tokens left in this contract for redemption by the contributors
    uint totalTokensLeftInContract = 0;
    
    // Flag to determine whether the tokens have been received by this address and are available for withdrawal
    bool public areTokenWithdrawalsEnabled = false;
    
    // Events marking the occurence of various important steps throughout the contract
    event ContributorBalanceChanged (address contributor, uint totalBalance);
    event ReceiverAddressSet ( address _addr);
    event TokenAddressSet ( address _addr);
    event FundsSentToReceiver (address receiver, uint amount);    


    // modifier that lets only the owner of this contract or the set admins to perform high authorization tasks on this pool
    modifier onlyOwnerOrAdmins() {
        require(msg.sender == owner || msg.sender == admins[0] || msg.sender == admins[1] || msg.sender== admins[2]);
        _;
    }
    
    // modifier to prevent a function from being executed twice
    bool locked;
    modifier onlyOnce() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    // structure that holds the contributor information
    struct ContributorInformation
    {
        uint contributionAmount;
        uint maxContribution;
        uint tokensReceived;
    }

    // mapping to hold a contributor&#39;s information against his/her address    
    mapping (address=>ContributorInformation) contributor;
    
    // intermediate object to handle internal operations
    ContributorInformation internal _contrInfo;
    
    
    // Pool initialization
    // Token address and receiver address can be set as 0x0 if they are unknown at the time of setting up pool
   
    constructor(address _owner, address _receiverAddress, address _tokenAddress,
                uint _maxPoolContribution, uint _maxIndividualContribution, uint _minIndividualContribution,
                bool _whitelisting, address[] _admins, uint _feePctNumerator, uint _feePctDenominator) public 
    {
        // Maximum pool contribution, maximum individual contribution and minimum individual contribution should be greater than zero
        require(_maxIndividualContribution >0 && _minIndividualContribution>0 && _maxPoolContribution>0);
        
        // A maximum of 3 admins can be set for each pool
        require(_admins.length<=3);
        
        // Maximum pool contribution should be greater than or equal to minimum individual contribution 
        // Maximum pool contribution should be lesser than or equal to max pool contribution 
        require(_maxIndividualContribution>=_minIndividualContribution && _maxIndividualContribution<=_maxPoolContribution);
        owner = _owner;
        icoAddress = _receiverAddress;
        tokenAddress = _tokenAddress;
        maxPoolContribution = _maxPoolContribution;
        maxIndividualContribution = _maxIndividualContribution;
        minIndividualContribution = _minIndividualContribution;
        isWhiteListingImplemented = _whitelisting;
        admins = _admins;
        feePctNumerator = _feePctNumerator;
        feePctDenominator = _feePctDenominator;
    }
    
    // Whitelist an address so that he/she can contribute in this pool
    // can only be done by owner or the admins
    function AddAddressToWhitelist(address _whitelitedAddress) public onlyOwnerOrAdmins {
        require(PoolState == 1);
        require(isWhiteListingImplemented == true);
        isUserWhiteListed[_whitelitedAddress] = true;
    }

    // Whitelist multiple addressese so that they can contribute in this pool
    // can only be done by owner or the admins    
    // At max 255 addresses can be whitelisted at one time to avoid infinite loops
    function AddMultipleAddresseseToWhitelist(address[] _whitelitedAddresses) public onlyOwnerOrAdmins {
        require(PoolState == 1);
        require(isWhiteListingImplemented == true);
        require(_whitelitedAddresses.length<255);
        for (uint i=0;i<_whitelitedAddresses.length;i++)
        {
             isUserWhiteListed[_whitelitedAddresses[i]] = true;     
        }
    }
    
    // Change whether whitelisting is required for this pool or not
    // Can only be done by owner or admins
    function UpdateWhiteListImplementation (bool updatedWhitelistImplementation) public onlyOwnerOrAdmins {
        isWhiteListingImplemented = updatedWhitelistImplementation;
    }
    
    // Fallback function -- called whenever ethers are sent to this contract address
    // The send will fail unless the contract is in stage one and the sender has been whitelisted.
    // The amount sent is added to the balance in the Contributor struct associated with the sending address.
    function () payable public {
        ContributeToPool();
    }

    // Function for contributing to the pool
    // This call would fail unless the contract is in stage one and the sender has been whitelisted
    // The amount sent is added to the balance in the Contributor struct associated with the sending address.
    function ContributeToPool () public payable {
        require (PoolState == 1);
        address sender = msg.sender;
        uint contributionAmt = msg.value;
        
        // if whitelisting is implemented, ensure the sender is approved to contribute to pool 
        if (isWhiteListingImplemented)
            require(isUserWhiteListed[sender]);
        
        require(contributionAmt>0);
        require(contributionAmt<=maxIndividualContribution && contributionAmt>=minIndividualContribution);
        require (address(this).balance.add(contributionAmt) <= maxPoolContribution);
        
        _contrInfo = contributor[msg.sender];
        _contrInfo.contributionAmount = _contrInfo.contributionAmount.add(msg.value);
        
        if (_contrInfo.maxContribution == 0)
            _contrInfo.maxContribution = maxIndividualContribution;
            
        require(_contrInfo.contributionAmount<=_contrInfo.maxContribution);
        contributor[sender] = _contrInfo;
        fundsRaised = fundsRaised.add(contributionAmt);
        
        emit ContributorBalanceChanged (sender, contributor[sender].contributionAmount);
    }

    // Function to withdraw contribution by any contributor
    // It is necessary for the contract to not be in stage 3 i.e. when the ethers have been sent to receiver
    function WithdrawContribution(uint amount) public 
    {
        require(PoolState<3);
        uint contributedAmount = contributor[msg.sender].contributionAmount;
        require(amount>0 && amount<=contributedAmount);
        
        // There are two possibilities: either the contributor wants to pull all of his contributions from this pool
        // or he wants to decrease his investment
        // The contributor should withdraw amount such that either his remaining amount is 0 or it is greater than minimum contribution
        require(contributedAmount.sub(amount) == 0 || contributedAmount.sub(amount)>=minIndividualContribution);
        
        contributor[msg.sender].contributionAmount = contributedAmount.sub(amount);
        fundsRaised = fundsRaised.sub(amount);
        
        msg.sender.transfer(amount);
        
        emit ContributorBalanceChanged (msg.sender, contributor[msg.sender].contributionAmount);
    }
    
    // This function is called by the owner to modify the contribution cap of a whitelisted address.
    // If the current contribution balance exceeds the new cap, the excess balance is refunded.
    function UpdateIndividualContributorCap (address addr, uint cap) public onlyOwnerOrAdmins {
        require (PoolState < 3);
        require(cap>minIndividualContribution);
        if (contributor[addr].contributionAmount > cap)
        {
            uint amountToReturn = contributor[addr].contributionAmount.sub(cap); 
            addr.transfer(amountToReturn);
            fundsRaised = fundsRaised.sub(amountToReturn);
            contributor[addr].contributionAmount = cap;
        }
        contributor[addr].maxContribution = cap;
    }
  
    // This function can be called during stages one or two to modify the maximum balance of the contract.
    // It can only be called by the owner. The amount cannot be set to lower than the current balance of the contract.
    function UpdatePoolTarget (uint amount) public onlyOwnerOrAdmins {
        require (PoolState < 3);
        require (amount >= address(this).balance);
        maxPoolContribution = amount;
    }
  
    // This function returns the remaining target needed for the pool
    function getRemainingTarget () view public returns (uint remaining) {
        if (PoolState == 1) 
            return maxPoolContribution.sub(address(this).balance);
        return 0;
    }
    
    // Function to get pool information
    function GetPoolInformation () public view returns(address _owner, address _receiverAddress, address _tokenAddress,
                uint _maxPoolContribution, uint _maxIndividualContribution, uint _minIndividualContribution,
                bool _whitelisting, address[] _admins, uint _feePctNumerator, uint _feePctDenominator) 
    {
        return (owner, icoAddress, tokenAddress, maxPoolContribution, maxIndividualContribution, minIndividualContribution,
                isWhiteListingImplemented, admins, feePctNumerator, feePctDenominator);
    }
    
    // Function to get contributor information
    function GetContributorInformation(address addr) public view returns (uint contributionAmount, uint maxContribution, uint tokensReceived)
    {
        return (contributor[addr].contributionAmount, contributor[addr].maxContribution, contributor[addr].tokensReceived);
    }
    
   
    // The owner or admins can end the contributions receiving stage
    function FinishReceivingContributions () public onlyOwnerOrAdmins {
        require (PoolState == 1);
        PoolState = 2;
    }

    // The owner or admins restart the contributions receiving stage after they ended it previously
    function RestartReceivingContributions () public onlyOwnerOrAdmins {
        require (PoolState == 2);
        PoolState = 1;
    }
  
    // function to update the receiver address if it was not set previously
    function UpdateICOAddress (address addr) public onlyOwnerOrAdmins {
        require (addr != 0x00 && icoAddress == 0x00);
        require (PoolState < 3);
        icoAddress = addr;
        emit ReceiverAddressSet(addr);
    }
  
    // function to update the token address if it was not set previously
    function UpdateTokenAddress (address addr) public onlyOwnerOrAdmins {
        require (addr != 0x00 && tokenAddress == 0x00);
        require (PoolState < 3);
        tokenAddress = addr;
        emit TokenAddressSet(addr);
    }
  
    // This function sends the collected ethers to the ico address and advances the contract to stage three. 
    // It can only be called by the contract owner during stages one or two.
    // This function is executed only once
    function SendFundsToReceiver (uint amount) public onlyOwner onlyOnce {
        require (PoolState < 3);
        require (icoAddress != 0x00 && tokenAddress != 0x0);
        require (minIndividualContribution <= amount && amount <= address(this).balance);
        finalBalance = address(this).balance;
        require(icoAddress.call.value(amount)());
        PoolState = 3;
        emit FundsSentToReceiver(icoAddress, amount);
    }
  
    // Function to enable the withdrawals of tokens
    // This can only happen after the tokens have been received by this pool
    // This function also transfers 0.25% of tokens to the platform owner and decided percentage to the pool creator
    function EnableTokenWithdrawals() public onlyOwnerOrAdmins onlyOnce
    {
        require(PoolState == 3);
        require(TokenContractInterface(tokenAddress).balanceOf(address(this))>0);
        uint totalTokens = TokenContractInterface(tokenAddress).balanceOf(address(this));
        uint tokensForPoolOwner = totalTokens.mul(feePctNumerator).div(feePctDenominator);
        uint tokensForPlatformOwner = totalTokens.mul(25).div(1000); //0.25%
        
        TokenContractInterface(tokenAddress).transfer(owner,tokensForPoolOwner);
        TokenContractInterface(tokenAddress).transfer(PlatformOwner, tokensForPlatformOwner);
        
        totalTokensReceivedInContract = totalTokens.sub(tokensForPoolOwner.add(tokensForPlatformOwner));
        totalTokensLeftInContract = totalTokens.sub(tokensForPoolOwner.add(tokensForPlatformOwner));
        areTokenWithdrawalsEnabled = true;   
    }

    // Function to withdraw tokens by a contributor
    // This can only happen after the admin/owner have enabled token withdrawals
    function WithdrawMyTokens() public 
    {
        require (areTokenWithdrawalsEnabled);
        uint amountContributed = contributor[msg.sender].contributionAmount;
        require(amountContributed>0);
        uint contributionPercentage = amountContributed.mul(100).div(finalBalance);
        uint tokens = totalTokensReceivedInContract.mul(contributionPercentage).div(100);
        TokenContractInterface(tokenAddress).transfer(msg.sender,tokens);
        totalTokensLeftInContract = totalTokensLeftInContract.sub(tokens);
    }
    
    // Function to force transfer tokens to a contributor by an admin
    // This can only happen after the admin/owner have enabled token withdrawals
    function ForceSendTokens(address addr) public onlyOwnerOrAdmins onlyOnce
    {
        require (areTokenWithdrawalsEnabled);
        uint amountContributed = contributor[addr].contributionAmount;
        require(amountContributed>0);
        uint contributionPercentage = amountContributed.mul(100).div(finalBalance);
        uint tokens = totalTokensReceivedInContract.mul(contributionPercentage).div(100);
        TokenContractInterface(tokenAddress).transfer(addr,tokens);
        totalTokensLeftInContract = totalTokensLeftInContract.sub(tokens);
    }
}

contract PoolManagementContract 
{
    using SafeMath for uint;
    address[] public _icoPoolsAddresses;
    mapping(address=>ICOPool) public _icoPools;
    mapping(address=>address[]) public _myPools;
    address[] internal poolsAddresses;
    
    constructor() public { }
    
    function CreateNewPool(address _receiverAddress, address _tokenAddress,
                uint _maxPoolContribution, uint _maxIndividualContribution, uint _minIndividualContribution,
                bool _whitelisting, address[] _admins, uint _feePctNumerator, uint _feePctDenominator) public 
    {
        require (_admins.length<=3);
        ICOPool pool = new ICOPool(msg.sender,_receiverAddress, _tokenAddress, _maxPoolContribution, _maxIndividualContribution
                                    , _minIndividualContribution, _whitelisting, _admins, _feePctNumerator,_feePctDenominator);
        _icoPoolsAddresses.push(address(pool));
        _icoPools[address(pool)] = pool;
        delete poolsAddresses;
        poolsAddresses = _myPools[msg.sender];
        poolsAddresses.push(address(pool));
        _myPools[msg.sender] = poolsAddresses;
    }
    
    
    function GetPoolInformation(address pool) public view returns (address _owner, address _receiverAddress, address _tokenAddress,
                uint _maxPoolContribution, uint _maxIndividualContribution, uint _minIndividualContribution,
                bool _whitelisting, address[] _admins, uint _feePctNumerator, uint _feePctDenominator)
    {
        return _icoPools[pool].GetPoolInformation();
    }
    
    function GetUserPools(address user) public constant returns(address[])
    {
        return _myPools[user];
    }
}