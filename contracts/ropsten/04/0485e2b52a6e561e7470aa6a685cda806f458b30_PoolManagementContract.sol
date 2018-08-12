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
interface ERC20 {
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
    address receiverAddress;

    // the token address for which this pool is setup for 
    address tokenAddress;
    
    // the interface to the required contract functions
    ERC20 token;
    
    // maximum ethers that this pool can accept
    uint maxPoolContribution;
    
    // minimum contribution possible for an individual address
    uint minIndividualContribution;

    // maximum contribution possible for an individual address
    uint maxIndividualContribution;

    // flag to determine whether this pool/ICO requires the contributors to be whitelisted or not
    bool isWhiteListingImplemented;

    // block numbers where a critical information is changed -- a reverse switch for investors if something fishy happens    
    uint addressChangeBlockForReceiver = 0;
    uint addressChangeBlockForToken= 0;
    
    // mapping for whitelisted users
    mapping(address=>bool) isUserWhiteListed;
    
    // default contract stage
    // 1 - The initial state. The owner is able to add addresses to the whitelist, and any whitelisted addresses can deposit or withdraw eth to the contract.
    // 2 - The owner has closed the contract for further deposits. Whitelisted addresses can still withdraw eth from the contract.
    // 3 - The eth is sent from the contract to the receiver. Unused eth can be claimed by contributors immediately. Once tokens are sent to the contract,
    //     the owner enables withdrawals and contributors can withdraw their tokens.
    uint contractStage = 1;
    
    // total ethers raised by the contract till now
    uint fundsRaised = 0;

    // the admins that can perform high authorization tasks for this pool
    address[] admins;

    
    // array containing eth amounts to be refunded in stage 3
    //uint[] public ethRefundAmount;
    
    // final balance of this contract which is sent to the receiver address
    // this is set at the time of submitting the pool
    uint finalBalance = 0;

    // the address liable for 0.25% of the tokens as a token gratitude for the creation of this platform
    address PlatformOwner = address(0xca35b7d915458ef540ade6068dfe2f44e8fa733c);

    // the total tokens received in the contract 
    // this is set after the pool is submitted and the receiver has sent the tokens to this contract
    uint totalTokensReceivedInContract = 0;

    // the tokens left in this contract for redemption by the contributors
    uint totalTokensLeftInContract = 0;
    
    // Flag to determine whether the tokens have been received by this address and are available for withdrawal
    bool public areTokenWithdrawalsEnabled = false;
    
    // Events triggered throughout contract execution
    // These can be watched via geth filters to keep up-to-date with the contract
    event ContributorBalanceChanged (address contributor, uint totalBalance);
    event ReceiverAddressSet ( address _addr);
    event TokenAddressSet ( address _addr);
    event PoolSubmitted (address receiver, uint amount);    
    event WithdrawalsOpen (address tokenAddr);
    event TokensWithdrawn (address receiver, address token, uint amount);
    event EthRefundReceived (address sender, uint amount);
    event EthRefunded (address receiver, uint amount);
    event ERC223Received (address token, uint value);


    // modifier that lets only the owner of this contract or the set admins to perform high authorization tasks on this pool
    modifier onlyOwnerOrAdmins() {
        require(msg.sender == owner || msg.sender == admins[0] || msg.sender == admins[1] || msg.sender== admins[2]);
        _;
    }
    
    // modifier to prevent re-entrancy exploits during contract > contract interaction
    bool locked;
    modifier noReentrancy() {
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
    // If token address and receiver address are set later on, the contract applies a mandatory wait of ~24 hours 
    // before the contributed amount is sent to the receiver
    // This is done so as to let the contributors withdraw their money in case something is fishy 
    // A maximum of 3 admins can be set for each pool
    // Maximum pool contribution, maximum individual contribution and minimum individual contribution should be greater than zero
    constructor(address _owner, address _receiverAddress, address _tokenAddress,
                uint _maxPoolContribution, uint _maxIndividualContribution, uint _minIndividualContribution,
                bool _whitelisting, address[] _admins, uint _feePctNumerator, uint _feePctDenominator) public 
    {
        require(_maxIndividualContribution >0 && _minIndividualContribution>0 && _maxPoolContribution>0);
        require(_admins.length<=3);
        owner = _owner;
        receiverAddress = _receiverAddress;
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
    function addAddressToWhitelist(address _whitelitedAddress) public onlyOwnerOrAdmins {
        require(contractStage == 1);
        require(isWhiteListingImplemented == true);
        isUserWhiteListed[_whitelitedAddress] = true;
    }

    // Whitelist multiple addressese so that they can contribute in this pool
    // can only be done by owner or the admins    
    // At max 255 addresses can be whitelisted at one time
    function addMultipleAddresseseToWhitelist(address[] _whitelitedAddresses) public onlyOwnerOrAdmins {
        require(contractStage == 1);
        require(isWhiteListingImplemented == true);
        require(_whitelitedAddresses.length<255);
        for (uint i=0;i<_whitelitedAddresses.length;i++)
        {
             isUserWhiteListed[_whitelitedAddresses[i]] = true;     
        }
    }
    
    // Change whether whitelisting is required for this pool or not
    // Can only be done by owner or admins
    function updateWhiteListImplementation (bool updatedWhitelistImplementation) public onlyOwnerOrAdmins {
        isWhiteListingImplemented = updatedWhitelistImplementation;
    }
    
    // This function is called whenever eth is sent into the contract.
    // The send will fail unless the contract is in stage one and the sender has been whitelisted.
    // The amount sent is added to the balance in the Contributor struct associated with the sending address.
    function () payable public {
        if (contractStage == 1) 
            _ethDeposit();
        else 
            revert();
    }

    // Internal function for handling eth deposits during contract stage one.
    function _ethDeposit () internal {
        assert (contractStage == 1);
        require(msg.value>0);
        require(msg.value<=maxIndividualContribution && msg.value>=minIndividualContribution);
        require (address(this).balance.add(msg.value) <= maxPoolContribution);
        if (isWhiteListingImplemented)
            require(isUserWhiteListed[msg.sender]);
        _contrInfo = contributor[msg.sender];
        _contrInfo.contributionAmount = _contrInfo.contributionAmount.add(msg.value);
        
        if (_contrInfo.maxContribution == 0)
            _contrInfo.maxContribution = maxIndividualContribution;
            
        require(_contrInfo.contributionAmount<=_contrInfo.maxContribution);
        contributor[msg.sender] = _contrInfo;
        fundsRaised = fundsRaised.add(msg.value);
        
        emit ContributorBalanceChanged (msg.sender, contributor[msg.sender].contributionAmount);
    }

    // Function to withdraw contribution by any contributor
    // It is necessary for the contract to not be in stage 3 i.e. when the ethers have been sent to receiver
    function withdrawContribution(uint amount) public 
    {
        require(contractStage<3);
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
    function modifyIndividualCap (address addr, uint cap) public onlyOwner {
        require (contractStage < 3);
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
    function modifyMaxContractBalance (uint amount) public onlyOwner {
        require (contractStage < 3);
        require (amount >= address(this).balance);
        maxPoolContribution = amount;
    }
  
    // This callable function returns the total pool cap, current balance and remaining balance to be filled.
    function checkPoolBalance () view public returns (uint poolCap, uint balance, uint remaining) {
        if (contractStage == 1) {
            remaining = maxPoolContribution.sub(address(this).balance);
        } else {
            remaining = 0;
        }
        return (maxPoolContribution,address(this).balance, remaining);
    }
    
    // Function to get pool information
    function getPoolInformation () public view returns(address _owner, address _receiverAddress, address _tokenAddress,
                uint _maxPoolContribution, uint _maxIndividualContribution, uint _minIndividualContribution,
                bool _whitelisting, address[] _admins, uint _feePctNumerator, uint _feePctDenominator) 
    {
        return (owner, receiverAddress, tokenAddress, maxPoolContribution, maxIndividualContribution, minIndividualContribution,
                isWhiteListingImplemented, admins, feePctNumerator, feePctDenominator);
    }
    
    // Function to get contributor information
    function getContributorInformation(address addr) public view returns (uint contributionAmount, uint maxContribution, uint tokensReceived)
    {
        return (contributor[addr].contributionAmount, contributor[addr].maxContribution, contributor[addr].tokensReceived);
    }
    
    // This function closes further contributions to the contract, advancing it to stage two.
    // It can only be called by the owner.  After this call has been made, whitelisted addresses
    // can still remove their eth from the contract but cannot contribute any more.
    function closeContributions () public onlyOwnerOrAdmins {
        require (contractStage == 1);
        contractStage = 2;
    }

    // This function reopens the contract to contributions and further whitelisting, returning it to stage one.
    // It can only be called by the owner during stage two.
    function reopenContributions () public onlyOwnerOrAdmins {
        require (contractStage == 2);
        contractStage = 1;
    }
  
    // This function sets the receiving address that the contract will send the pooled eth to.
    // It can only be called by the contract owner if the receiver address has not already been set.
    // After making this call, the contract will be unable to send the pooled eth for 6000 blocks.
    // This limitation is so that if the owner acts maliciously in making the change, all whitelisted
    // addresses have ~24 hours to withdraw their eth from the contract.
    function setReceiverAddress (address addr) public onlyOwner {
        require (addr != 0x00 && receiverAddress == 0x00);
        require (contractStage < 3);
        receiverAddress = addr;
        addressChangeBlockForReceiver = block.number;
        emit ReceiverAddressSet(addr);
    }
  
    // This function sets the receiving address that the contract will send the pooled eth to.
    // It can only be called by the contract owner if the receiver address has not already been set.
    // After making this call, the contract will be unable to send the pooled eth for 6000 blocks.
    // This limitation is so that if the owner acts maliciously in making the change, all whitelisted
    // addresses have ~24 hours to withdraw their eth from the contract.
    function setTokenAddress (address addr) public onlyOwner {
        require (addr != 0x00 && tokenAddress == 0x00);
        require (contractStage < 3);
        tokenAddress = addr;
        addressChangeBlockForToken = block.number;
        emit TokenAddressSet(addr);
    }
  
    // This function sends the pooled eth to the receiving address, calculates the % of unused eth to be returned,
    // and advances the contract to stage three. It can only be called by the contract owner during stages one or two.
    // The amount to send (given in wei) must be specified during the call. As this function can only be executed once,
    // it is VERY IMPORTANT not to get the amount wrong.
    function submitPool (uint amountInWei) public onlyOwner noReentrancy {
        require (contractStage < 3);
        require (receiverAddress != 0x00);
        require (block.number >= addressChangeBlockForReceiver.add(6000));
        require (block.number >= addressChangeBlockForToken.add(6000));
        require (minIndividualContribution <= amountInWei && amountInWei <= address(this).balance);
        finalBalance = address(this).balance;
        //require (icoAddress.call.value(amountInWei).gas(msg.gas.sub(5000))());
        require(receiverAddress.call.value(amountInWei)());
        //if (address(this).balance > 0) ethRefundAmount.push(address(this).balance);
        contractStage = 3;
        emit PoolSubmitted(receiverAddress, amountInWei);
    }
  
    // Function to enable the withdrawals of tokens
    // This can only happen after the tokens have been received by this pool
    // This function also transfers 0.25% of tokens to the platform owner and decided percentage to the pool creator
    function enableTokenWithdrawals() public onlyOwnerOrAdmins noReentrancy
    {
        require(contractStage == 3);
        require(ERC20(tokenAddress).balanceOf(address(this))>0);
        uint totalTokens = ERC20(tokenAddress).balanceOf(address(this));
        uint tokensForPoolOwner = totalTokens.mul(feePctNumerator).div(feePctDenominator);
        uint tokensForPlatformOwner = totalTokens.mul(25).div(1000); //0.25%
        
        ERC20(tokenAddress).transfer(owner,tokensForPoolOwner);
        ERC20(tokenAddress).transfer(PlatformOwner, tokensForPlatformOwner);
        
        totalTokensReceivedInContract = totalTokens.sub(tokensForPoolOwner.add(tokensForPlatformOwner));
        totalTokensLeftInContract = totalTokens.sub(tokensForPoolOwner.add(tokensForPlatformOwner));
        areTokenWithdrawalsEnabled = true;   
    }

    // Function to withdraw tokens by a contributor
    // This can only happen after the admin/owner have enabled token withdrawals
    function withdrawMyTokens() public 
    {
        require (areTokenWithdrawalsEnabled);
        uint amountContributed = contributor[msg.sender].contributionAmount;
        require(amountContributed>0);
        uint contributionPercentage = amountContributed.mul(100).div(finalBalance);
        uint tokens = totalTokensReceivedInContract.mul(contributionPercentage).div(100);
        ERC20(tokenAddress).transfer(msg.sender,tokens);
        totalTokensLeftInContract = totalTokensLeftInContract.sub(tokens);
    }
    
    // Function to force transfer tokens to a contributor by an admin
    // This can only happen after the admin/owner have enabled token withdrawals
    function forceWithdrawTokensToAnAddress(address addr) public onlyOwnerOrAdmins noReentrancy
    {
        require (areTokenWithdrawalsEnabled);
        uint amountContributed = contributor[addr].contributionAmount;
        require(amountContributed>0);
        uint contributionPercentage = amountContributed.mul(100).div(finalBalance);
        uint tokens = totalTokensReceivedInContract.mul(contributionPercentage).div(100);
        ERC20(tokenAddress).transfer(addr,tokens);
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
    constructor() public 
    {
       
    }
    
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
    
    
    function getPoolInformation(address pool) public view returns (address _owner, address _receiverAddress, address _tokenAddress,
                uint _maxPoolContribution, uint _maxIndividualContribution, uint _minIndividualContribution,
                bool _whitelisting, address[] _admins, uint _feePctNumerator, uint _feePctDenominator)
    {
        return _icoPools[pool].getPoolInformation();
    }
    
    function getUserPools(address user) public constant returns(address[])
    {
        return _myPools[user];
    }
}