pragma solidity ^0.4.22;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address and
 *      provides basic authorization control functions
 */
contract Ownable {
    // Public properties
    address public owner;

    // Log if ownership has been changed
    event ChangeOwnership(address indexed _owner, address indexed _newOwner);

    // Checks if address is an owner
    modifier OnlyOwner() {
        require(msg.sender == owner);

        _;
    }

    // The Ownable constructor sets the owner address
    function Ownable() public {
        owner = msg.sender;
    }

    // Transfer current ownership to the new account
    function transferOwnership(address _newOwner) public OnlyOwner {
        require(_newOwner != address(0x0));

        owner = _newOwner;

        emit ChangeOwnership(owner, _newOwner);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    /*
    * @dev Event to notify listeners about pause.
    * @param pauseReason  string Reason the token was paused for.
    */
    event Pause(string pauseReason);
    /*
    * @dev Event to notify listeners about pause.
    * @param unpauseReason  string Reason the token was unpaused for.
    */
    event Unpause(string unpauseReason);

    bool public isPaused;
    string public pauseNotice;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier IsNotPaused() {
        require(!isPaused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier IsPaused() {
        require(isPaused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    * @param _reason string The reason for the pause.
    */
    function pause(string _reason) OnlyOwner IsNotPaused public {
        isPaused = true;
        pauseNotice = _reason;
        emit Pause(_reason);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     * @param _reason string Reason for the un pause.
     */
    function unpause(string _reason) OnlyOwner IsPaused public {
        isPaused = false;
        pauseNotice = _reason;
        emit Unpause(_reason);
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns(uint256 theBalance);
    function transfer(address to, uint256 value) public returns(bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns(uint256 theAllowance);
    function transferFrom(address from, address to, uint256 value) public returns(bool success);
    function approve(address spender, uint256 value) public returns(bool success);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken without allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    // Balances for each account
    mapping(address => uint256) balances;

    /**
    * @dev Get the token balance for account
    * @param _address The address to query the balance of._address
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _address) public constant returns(uint256 theBalance){
        return balances[_address];
    }

    /**
    * @dev Transfer the balance from owner&#39;s account to another account
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return Returns true if transfer has been successful
    */
    function transfer(address _to, uint256 _value) public returns(bool success){
        require(_to != address(0x0) && _value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is BasicToken, ERC20 {
    // Owner of account approves the transfer of an amount to another account
    mapping (address => mapping (address => uint256)) allowed;

    /**
     * @dev Returns the amount of tokens approved by the owner that can be transferred to the spender&#39;s account
     * @param _owner The address which owns the funds.
     * @param _spender The address which will spend the funds.
     * @return An uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns(uint256 theAllowance){
        return allowed[_owner][_spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * To change the approve amount you first have to reduce the addresses`
     * allowance to zero by calling `approve(_spender, 0)` if it is not
     * already 0 to mitigate the race condition described here:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns(bool success){
        require(allowed[msg.sender][_spender] == 0 || _value == 0);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * Transfer from `from` account to `to` account using allowance in `from` account to the sender
     *
     * @param _from  Origin address
     * @param _to    Destination address
     * @param _value Amount of CHR tokens to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Burn(msg.sender, _value);
    }
}

/**
 * CHERR.IO is a standard ERC20 token with some additional functionalities:
 * - Transfers are only enabled after contract owner enables it (after the ICO)
 * - Contract sets 60% of the total supply as allowance for ICO contract
 */
contract Cherrio is StandardToken, BurnableToken, Ownable, Pausable {
    using SafeMath for uint256;

    // Metadata
    string  public constant name = "CHERR.IO";
    string  public constant symbol = "CHR";
    uint8   public constant decimals = 18;

    // Token supplies
    uint256 public constant INITIAL_SUPPLY =  200000000 * (10 ** uint256(decimals));
    uint256 public constant ADMIN_ALLOWANCE =  80000000 * (10 ** uint256(decimals));
    uint256 public constant CONTRACT_ALLOWANCE = INITIAL_SUPPLY - ADMIN_ALLOWANCE;

    // Funding cap in ETH. Change to equal $12M at time of token offering
    uint256 public constant FUNDING_ETH_HARD_CAP = 15000 ether;
    // Minimum cap in ETH. Change to equal $3M at time of token offering
    uint256 public constant MINIMUM_ETH_SOFT_CAP = 3750 ether;
    // Min contribution is 0.1 ether
    uint256 public constant MINIMUM_CONTRIBUTION = 100 finney;
    // Price of the tokens as in tokens per ether
    uint256 public constant RATE = 5333;
    // Price of the tokens in tier 1
    uint256 public constant RATE_TIER1 = 8743;
    // Price of the tokens in tier 2
    uint256 public constant RATE_TIER2 = 7306;
    // Price of the tokens in tier 3
    uint256 public constant RATE_TIER3 = 6584;
    // Price of the tokens in public sale for limited timeline
    uint256 public constant RATE_PUBLIC_SALE = 5926;
    // Maximum cap for tier 1 (60M CHR tokens)
    uint256 public constant TIER1_CAP = 60000000 * (10 ** uint256(decimals));
    // Maximum cap for tier 2 (36M CHR tokens)
    uint256 public constant TIER2_CAP = 36000000 * (10 ** uint256(decimals));

    // Maximum cap for each contributor in tier 1
    uint256 public participantCapTier1;
    // Maximum cap for each contributor in tier 2
    uint256 public participantCapTier2;

    // ETH cap for pool addres only in tier 1
    uint256 public poolAddressCapTier1;
    // ETH cap for pool addres only in tier 2
    uint256 public poolAddressCapTier2;

    // The address of the token admin
    address public adminAddress;
    // The address where ETH funds are collected
    address public beneficiaryAddress;
    // The address of the contract
    address public contractAddress;
    // The address of the pool who can send unlimited ETH to the contract
    address public poolAddress;

    // Enable transfers after conclusion of the token offering
    bool public transferIsEnabled;

    // Amount of raised in Wei
    uint256 public weiRaised;

    // Amount of CHR tokens sent to participant for presale and public sale
    uint256[4] public tokensSent;

    // Start of public pre-sale in timestamp
    uint256 startTimePresale;

    // Start and end time of public sale in timestamp
    uint256 startTime;
    uint256 endTime;

    // Discount period for public sale
    uint256 publicSaleDiscountEndTime;

    // End time limits in timestamp for each tier bonus
    uint256[3] public tierEndTime;

    //Check if contract address is already set
    bool contractAddressIsSet;

    struct Contributor {
        bool canContribute;
        uint8 tier;
        uint256 contributionInWeiTier1;
        uint256 contributionInWeiTier2;
        uint256 contributionInWeiTier3;
        uint256 contributionInWeiPublicSale;
    }

    struct Pool {
        uint256 contributionInWei;
    }

    enum Stages {
        Pending,
        PreSale,
        PublicSale,
        Ended
    }

    // The current stage of the offering
    Stages public stage;

    mapping(address => Contributor) public contributors;
    mapping(address => mapping(uint8 => Pool)) public pool;

    // Check if transfer is enabled
    modifier TransferIsEnabled {
        require(transferIsEnabled || msg.sender == adminAddress || msg.sender == contractAddress);

        _;
    }

    /**
     * @dev Check if address is a valid destination to transfer tokens to
     * - must not be zero address
     * - must not be the token address
     * - must not be the owner&#39;s address
     * - must not be the admin&#39;s address
     * - must not be the token offering contract address
     * - must not be the beneficiary address
     */
    modifier ValidDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        require(_to != owner);
        require(_to != address(adminAddress));
        require(_to != address(contractAddress));
        require(_to != address(beneficiaryAddress));

        _;
    }

    /**
     * Modifier that requires certain stage before executing the main function body
     *
     * @param _expectedStage Value that the current stage is required to match
     */
    modifier AtStage(Stages _expectedStage) {
        require(stage == _expectedStage);

        _;
    }

    // Check if ICO is live
    modifier CheckIfICOIsLive() {
        require(stage != Stages.Pending && stage != Stages.Ended);

        if(stage == Stages.PreSale) {
            require(
                startTimePresale > 0 &&
                now >= startTimePresale &&
                now <= tierEndTime[2]
            );
        }
        else {
            require(
                startTime > 0 &&
                now >= startTime &&
                now <= endTime
            );
        }

        _;
    }

    // Check if participant sent more then miniminum required contribution
    modifier CheckPurchase() {
        require(msg.value >= MINIMUM_CONTRIBUTION);

        _;
    }

    /**
     * Event for token purchase logging
     *
     * @param _purchaser Participant who paid for CHR tokens
     * @param _value     Amount in WEI paid for token
     * @param _tokens    Amount of tokens purchased
     */
    event TokenPurchase(address indexed _purchaser, uint256 _value, uint256 _tokens);

    /**
     * Event when token offering started
     *
     * @param _msg       Message
     * @param _startTime Start time in timestamp
     * @param _endTime   End time in timestamp
     */
    event OfferingOpens(string _msg, uint256 _startTime, uint256 _endTime);

    /**
     * Event when token offering ended and how much has been raised in wei
     *
     * @param _endTime        End time in timestamp
     * @param _totalWeiRaised Total raised funds in wei
     */
    event OfferingCloses(uint256 _endTime, uint256 _totalWeiRaised);

    /**
     * Cherrio constructor
     */
    function Cherrio() public {
        totalSupply = INITIAL_SUPPLY;

        // Mint tokens
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);

        // Aprove an allowance for admin account
        adminAddress = 0xe0509bB3921aacc433108D403f020a7c2f92e936;
        approve(adminAddress, ADMIN_ALLOWANCE);

        participantCapTier1 = 100 ether;
        participantCapTier2 = 100 ether;
        poolAddressCapTier1 = 2000 ether; 
        poolAddressCapTier2 = 2000 ether;

        weiRaised = 0;
        startTimePresale = 0;
        startTime = 0;
        endTime = 0;
        publicSaleDiscountEndTime = 0;
        transferIsEnabled = false;
        contractAddressIsSet = false;
    }

    /**
     * Add approved addresses
     *
     * @param _addresses Array of approved addresses
     * @param _tier      Tier
     */
    function addApprovedAddresses(address[] _addresses, uint8 _tier) external OnlyOwner {
        uint256 length = _addresses.length;

        for(uint256 i = 0; i < length; i++) {
            if(!contributors[_addresses[i]].canContribute) {
                contributors[_addresses[i]].canContribute = true;
                contributors[_addresses[i]].tier = _tier;
                contributors[_addresses[i]].contributionInWeiTier1 = 0;
                contributors[_addresses[i]].contributionInWeiTier2 = 0;
                contributors[_addresses[i]].contributionInWeiTier3 = 0;
                contributors[_addresses[i]].contributionInWeiPublicSale = 0;
            }
        }
    }

    /**
     * Add approved address
     *
     * @param _address Approved address
     * @param _tier    Tier
     */
    function addSingleApprovedAddress(address _address, uint8 _tier) external OnlyOwner {
        if(!contributors[_address].canContribute) {
            contributors[_address].canContribute = true;
            contributors[_address].tier = _tier;
            contributors[_address].contributionInWeiTier1 = 0;
            contributors[_address].contributionInWeiTier2 = 0;
            contributors[_address].contributionInWeiTier3 = 0;
            contributors[_address].contributionInWeiPublicSale = 0;
        }
    }

    /**
     * Set token offering address to approve allowance for offering contract to distribute tokens
     */
    function setTokenOffering() external OnlyOwner{
        require(!contractAddressIsSet);
        require(!transferIsEnabled);

        contractAddress = address(this);
        approve(contractAddress, CONTRACT_ALLOWANCE);

        beneficiaryAddress = 0xAec8c4242c8c2E532c6D6478A7de380263234845;
        poolAddress = 0x1A2C916B640520E1e93A78fEa04A49D8345a5aa9;

        pool[poolAddress][0].contributionInWei = 0;
        pool[poolAddress][1].contributionInWei = 0;
        pool[poolAddress][2].contributionInWei = 0;
        pool[poolAddress][3].contributionInWei = 0;

        tokensSent[0] = 0;
        tokensSent[1] = 0;
        tokensSent[2] = 0;
        tokensSent[3] = 0;

        stage = Stages.Pending;
        contractAddressIsSet = true;
    }

    /**
     * Set when presale starts
     *
     * @param _startTimePresale Start time of presale in timestamp
     */
    function startPresale(uint256 _startTimePresale) external OnlyOwner AtStage(Stages.Pending) {
        if(_startTimePresale == 0) {
            startTimePresale = now;
        }
        else {
            startTimePresale = _startTimePresale;
        }

        setTierEndTime();

        stage = Stages.PreSale;
    }

    /**
     * Set when public sale starts
     *
     * @param _startTime Start time of public sale in timestamp
     */
    function startPublicSale(uint256 _startTime) external OnlyOwner AtStage(Stages.PreSale) {
        if(_startTime == 0) {
            startTime = now;
        }
        else {
            startTime = _startTime;
        }

        endTime = startTime + 15 days;
        publicSaleDiscountEndTime = startTime + 3 days;

        stage = Stages.PublicSale;
    }

    // Fallback function can be used to buy CHR tokens
    function () public payable {
        buy();
    }

    function buy() public payable IsNotPaused CheckIfICOIsLive returns(bool _success) {
        uint8 currentTier = getCurrentTier();

        if(currentTier > 3) {
            revert();
        }

        if(!buyTokens(currentTier)) {
            revert();
        }

        return true;
    }

    /**
     * @param _tier Current Token Sale tier
     */
    function buyTokens(uint8 _tier) internal ValidDestination(msg.sender) CheckPurchase returns(bool _success) {
        if(weiRaised.add(msg.value) > FUNDING_ETH_HARD_CAP) {
            revert();
        }

        uint256 contributionInWei = msg.value;

        if(!checkTierCap(_tier, contributionInWei)) {
            revert();
        }

        uint256 rate = getTierTokens(_tier);
        uint256 tokens = contributionInWei.mul(rate);

        if(msg.sender != poolAddress) {
            if(stage == Stages.PreSale) {
                if(!checkAllowedTier(msg.sender, _tier)) {
                    revert();
                }
            }

            if(!checkAllowedContribution(msg.sender, contributionInWei, _tier)) {
                revert();
            }

            if(!this.transferFrom(owner, msg.sender, tokens)) {
                revert();
            }

            if(stage == Stages.PreSale) {
                if(_tier == 0) {
                    contributors[msg.sender].contributionInWeiTier1 = contributors[msg.sender].contributionInWeiTier1.add(contributionInWei);
                }
                else if(_tier == 1) {
                    contributors[msg.sender].contributionInWeiTier2 = contributors[msg.sender].contributionInWeiTier2.add(contributionInWei);
                }
                else if(_tier == 2) {
                    contributors[msg.sender].contributionInWeiTier3 = contributors[msg.sender].contributionInWeiTier3.add(contributionInWei);
                }
            }
            else {
                contributors[msg.sender].contributionInWeiPublicSale = contributors[msg.sender].contributionInWeiPublicSale.add(contributionInWei);
            }
        }
        else {
            if(!checkPoolAddressTierCap(_tier, contributionInWei)) {
                revert();
            }

            if(!this.transferFrom(owner, msg.sender, tokens)) {
                revert();
            }

            pool[poolAddress][_tier].contributionInWei = pool[poolAddress][_tier].contributionInWei.add(contributionInWei);
        }

        weiRaised = weiRaised.add(contributionInWei);
        tokensSent[_tier] = tokensSent[_tier].add(tokens);

        if(weiRaised >= FUNDING_ETH_HARD_CAP) {
            offeringEnded();
        }

        beneficiaryAddress.transfer(address(this).balance);
        emit TokenPurchase(msg.sender, contributionInWei, tokens);

        return true;
    }

    /**
     * Manually withdraw tokens to private investors
     *
     * @param _to    Address of private investor
     * @param _value The number of tokens to send to private investor
     */
    function withdrawCrowdsaleTokens(address _to, uint256 _value) external OnlyOwner ValidDestination(_to) returns (bool _success) {
        if(!this.transferFrom(owner, _to, _value)) {
            revert();
        }

        return true;
    }

    /**
     * Transfer from sender to another account
     *
     * @param _to    Destination address
     * @param _value Amount of CHR tokens to send
     */
    function transfer(address _to, uint256 _value) public ValidDestination(_to) TransferIsEnabled IsNotPaused returns(bool _success){
         return super.transfer(_to, _value);
    }

    /**
     * Transfer from `from` account to `to` account using allowance in `from` account to the sender
     *
     * @param _from  Origin address
     * @param _to    Destination address
     * @param _value Amount of CHR tokens to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public ValidDestination(_to) TransferIsEnabled IsNotPaused returns(bool _success){
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * Check if participant is allowed to contribute in current tier
     *
     * @param _address Participant address
     * @param _tier    Current tier
     */
    function checkAllowedTier(address _address, uint8 _tier) internal view returns (bool _allowed) {
        if(contributors[_address].tier <= _tier) {
            return true;
        }
        else{
          return false;
        }
    }

    /**
     * Check contribution cap for only tier 1 and 2
     *
     * @param _tier  Current tier
     * @param _value Participant contribution
     */
    function checkTierCap(uint8 _tier, uint256 _value) internal view returns (bool _success) {
        uint256 currentlyTokensSent = tokensSent[_tier];
        bool status = true;

        if(_tier == 0) {
            if(TIER1_CAP < currentlyTokensSent.add(_value)) {
                status = false;
            }
        }
        else if(_tier == 1) {
            if(TIER2_CAP < currentlyTokensSent.add(_value)) {
                status = false;
            }
        }

        return status;
    }
    
    /**
     * Check cap for pool address in tier 1 and 2
     *
     * @param _tier  Current tier
     * @param _value Pool contribution
     */
    function checkPoolAddressTierCap(uint8 _tier, uint256 _value) internal view returns (bool _success) {
        uint256 currentContribution = pool[poolAddress][_tier].contributionInWei;

        if((_tier == 0 && (poolAddressCapTier1 < currentContribution.add(_value))) || (_tier == 1 && (poolAddressCapTier2 < currentContribution.add(_value)))) {
            return false;
        }

        return true;
    }

    /**
     * Check cap for pool address in tier 1 and 2
     *
     * @param _address  Participant address
     * @param _value    Participant contribution
     * @param _tier     Current tier
     */
    function checkAllowedContribution(address _address, uint256 _value, uint8 _tier) internal view returns (bool _success) {
        bool status = false;

        if(contributors[_address].canContribute) {
            if(_tier == 0) {
                if(participantCapTier1 >= contributors[_address].contributionInWeiTier1.add(_value)) {
                    status = true;
                }
            }
            else if(_tier == 1) {
                if(participantCapTier2 >= contributors[_address].contributionInWeiTier2.add(_value)) {
                    status = true;
                }
            }
            else if(_tier == 2) {
                status = true;
            }
            else {
                status = true;
            }
        }

        return status;
    }
    
    /**
     * Get current tier tokens rate
     *
     * @param _tier     Current tier
     */
    function getTierTokens(uint8 _tier) internal view returns(uint256 _tokens) {
        uint256 tokens = RATE_TIER1;

        if(_tier == 1) {
            tokens = RATE_TIER2;
        }
        else if(_tier == 2) {
            tokens = RATE_TIER3;
        }
        else if(_tier == 3) {
            if(now <= publicSaleDiscountEndTime) {
                tokens = RATE_PUBLIC_SALE;
            }
            else {
                tokens = RATE;
            }
        }

        return tokens;
    }

    // Get current tier
    function getCurrentTier() public view returns(uint8 _tier) {
        uint8 currentTier = 3; // 3 is public sale

        if(stage == Stages.PreSale) {
            if(now <= tierEndTime[0]) {
                currentTier = 0;
            }
            else if(now <= tierEndTime[1]) {
                currentTier = 1;
            }
            else if(now <= tierEndTime[2]) {
                currentTier = 2;
            }
        }
        else {
            if(now > endTime) {
                currentTier = 4; // Token offering ended
            }
        }

        return currentTier;
    }

    // Set end time for each tier
    function setTierEndTime() internal AtStage(Stages.Pending) {
        tierEndTime[0] = startTimePresale + 1 days; 
        tierEndTime[1] = tierEndTime[0] + 2 days;   
        tierEndTime[2] = tierEndTime[1] + 6 days;   
    }

    // End the token offering
    function endOffering() public OnlyOwner {
        offeringEnded();
    }

    // Token offering is ended
    function offeringEnded() internal {
        endTime = now;
        stage = Stages.Ended;

        emit OfferingCloses(endTime, weiRaised);
    }

    // Enable transfers, burn unsold tokens & set tokenOfferingAddress to 0
    function enableTransfer() public OnlyOwner returns(bool _success){
        transferIsEnabled = true;
        uint256 tokensToBurn = allowed[msg.sender][contractAddress];

        if(tokensToBurn != 0){
            burn(tokensToBurn);
            approve(contractAddress, 0);
        }

        return true;
    }
    
    /**
     * Extend end time
     *
     * @param _addedTime Addtional time in secods
     */
    function extendEndTime(uint256 _addedTime) external OnlyOwner {
        endTime = endTime + _addedTime;
    }
    
    /**
     * Extend public sale discount time
     *
     * @param _addedPublicSaleDiscountEndTime Addtional time in secods
     */
    function extendPublicSaleDiscountEndTime(uint256 _addedPublicSaleDiscountEndTime) external OnlyOwner {
        publicSaleDiscountEndTime = publicSaleDiscountEndTime + _addedPublicSaleDiscountEndTime;
    }
    
    /**
     * Update pool cap for tier 1
     *
     * @param _poolAddressCapTier1 Tier cap
     */
    function updatePoolAddressCapTier1(uint256 _poolAddressCapTier1) external OnlyOwner {
        poolAddressCapTier1 = _poolAddressCapTier1;
    }
    
    /**
     * Update pool cap for tier 2
     *
     * @param _poolAddressCapTier2 Tier cap
     */
    function updatePoolAddressCapTier2(uint256 _poolAddressCapTier2) external OnlyOwner {
        poolAddressCapTier2 = _poolAddressCapTier2;
    }

    //
    
    /**
     * Update participant cap for tier 1
     *
     * @param _participantCapTier1 Tier cap
     */
    function updateParticipantCapTier1(uint256 _participantCapTier1) external OnlyOwner {
        participantCapTier1 = _participantCapTier1;
    }
    
    /**
     * Update participant cap for tier 2
     *
     * @param _participantCapTier2 Tier cap
     */
    function updateParticipantCapTier2(uint256 _participantCapTier2) external OnlyOwner {
        participantCapTier2 = _participantCapTier2;
    }
}