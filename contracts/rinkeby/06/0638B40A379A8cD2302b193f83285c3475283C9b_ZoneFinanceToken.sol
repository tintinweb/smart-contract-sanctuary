/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
or
https://eips.ethereum.org/EIPS/eip-20#abstract
.*/

pragma solidity ^0.4.21;


contract ZoneFinanceToken {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    
    string public contractVersion = "2021061101550000";
    

    // -----------------------------------------------------------------------------------
    // Required Events
    // -----------------------------------------------------------------------------------
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // -----------------------------------------------------------------------------------

    // -----------------------------------------------------------------------------------
    // Custom Events
    // -----------------------------------------------------------------------------------
    event RewardUpdated(address _administrator, uint64 _donationsPercent, uint64 _lastAwardDate);
    event Donated(address indexed _donor, uint256 _amount);
    // -----------------------------------------------------------------------------------

    // -----------------------------------------------------------------------------------
    // Required Fields
    // -----------------------------------------------------------------------------------
    mapping (address => uint256) internal balances;
    uint256                      internal theTotalSupply;
    mapping (address => mapping (address => uint256)) internal allowed;
    // -----------------------------------------------------------------------------------


    // -----------------------------------------------------------------------------------
    // Custom Fields
    // -----------------------------------------------------------------------------------
    address                      internal ownerWalletAddress;
    address                      internal donationWalletAddress;

    mapping (address => bool)    public administrativeAccount;
    mapping (address => uint256) public totalDonationBalance;
    mapping (address => uint256) public unAwardedDonationBalance;
    mapping (address => uint256) public totalAwardedByWallet;
    mapping (address => uint256) public lastClaimedAward;

    string  public messageToPublic;
    uint256 public totalAwarded;
    uint64  public lastAwardDate;
    uint64  public donationsPercent;

    uint256 public totalDonated;
    uint256 public totalDonationsUsed;
    uint256 public totalAvailableToPublic;
    // -----------------------------------------------------------------------------------

    // -----------------------------------------------------------------------------------
    // The constructor is called when the contract is created.
    // -----------------------------------------------------------------------------------
    constructor (
        uint256 _initialAmount
    ) public {
        balances[msg.sender] = _initialAmount;  // Give the creator all initial tokens
        theTotalSupply = _initialAmount;        // Update total supply 
        totalAvailableToPublic = 0;             // Since the owner has them all, NONE are out in the public yet.

        // Administrative settings. Make this account automatically an Administrative account
        // AND the owner pool account.
        ownerWalletAddress = msg.sender;
        // Default it to here. We can adjust this with function calls later.
        donationWalletAddress = msg.sender;
        administrativeAccount[msg.sender]=true;
    }
    // -----------------------------------------------------------------------------------

    // -----------------------------------------------------------------------------------
    // Required "Getter" functions as defined by EIP-20.     
    // -----------------------------------------------------------------------------------
    function name() public pure returns(string) {
        return "ZoneFinance";
    }
    function symbol() public pure returns(string) {
        return "ZF";
    }
    function decimals() public pure returns(uint8) {
        return 6;
    }
    function totalSupply() public view returns (uint256) {
        return theTotalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    // -----------------------------------------------------------------------------------
    
    // -----------------------------------------------------------------------------------
    // Functions that I have not altered.
    // -----------------------------------------------------------------------------------
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
        // -----------------------------------------------------------------------------------
    
    
    // -----------------------------------------------------------------------------------
    // The two kinds of transfers....
    // -----------------------------------------------------------------------------------
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient tokens.");
        require(msg.sender != _to, "You can not send to your own wallet. That wastes gas!");

        return doTransfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 tmpAllowed = allowed[_from][msg.sender];
    
        require(balances[_from] >= _value && tmpAllowed >= _value, "Unauthorized for that quantity or insufficient tokens.");
        require(_from != _to, "You can not send to your own wallet. That wastes gas!");

        return doTransfer(_from, _to, _value);
    }

    function doTransfer(address _from, address _to, uint256 _value)  private returns (bool) {
        balances[_from] -= _value;
        balances[_to]        += _value;
        
        bool isDonation = (_to == donationWalletAddress);

        if (_from == ownerWalletAddress || _from == donationWalletAddress)
        {
            totalAvailableToPublic += _value;
        }
        if (_to == ownerWalletAddress || _to == donationWalletAddress)
        {
            totalAvailableToPublic -= _value;
        }
        if (isDonation)
        {
            totalDonated += _value;
            unAwardedDonationBalance[_from] += _value;
            // Register the Donation on the blockchain.
            emit Donated(_from, _value);
        }

        // Register the transfer on the blockchain.
        emit Transfer(_from, _to, _value); 
        return true;
    }
    // -----------------------------------------------------------------------------------
    
    
    
    // -----------------------------------------------------------------------------------
    // Custom Functions
    // -----------------------------------------------------------------------------------
    function setPublicMessage(string _publicMessage) public returns (bool success) {
        require(administrativeAccount[msg.sender]==true,"You are not allowed to set the public message.");
        messageToPublic = _publicMessage;
        return true;
    }

    function giveFromZone(address _to, uint256 _value) public returns (bool success) {
        require(administrativeAccount[msg.sender] == true, "You must be an administrative account to allocate donated tokens.");
        require(balances[donationWalletAddress] >= _value, "Donation Account does not have enough tokens.");
        require(donationWalletAddress      != _to , "Donation Account cannot be the recipient. That wastes gas!");
        require(administrativeAccount[_to] != true, "Administrators cannot be the recipient.");

        balances[donationWalletAddress] -= _value;
        balances[_to]                += _value;
        totalDonationsUsed           += _value;
        totalAvailableToPublic       += _value;
        
        emit Transfer(donationWalletAddress, _to, _value);
        return true;
    }
    
    function setAdministrativeAccount(address _account, bool _isAdministrator) public returns (bool success) {
        require(administrativeAccount[msg.sender] == true, 
             "You must be an administrative account to set another administrative account.");
        administrativeAccount[_account] = _isAdministrator;
        return true;   
    }
    

    // The "Master Donation" wallet may need to change from time-to-time. 
    // This is how we can transfer the donation wallet seamlessly.
    function setDonationAccount(address _account) public returns (bool success) {
        require(administrativeAccount[msg.sender] == true, 
             "You must be an administrative account to set the donation account.");
        
        // Shift all of the tokens from the account.
        uint256 value = balances[donationWalletAddress];
        balances[donationWalletAddress]=0;
        balances[_account]=value;
        
        // Register the transfer on the blockchain for bookkeeping.
        emit Transfer(donationWalletAddress, _account, value);
        
        // Now replace it.
        donationWalletAddress = _account;
        
        return true;   
    }
    
    function transferOwnership(address _newownerWalletAddress, bool _shiftAllTokens) public returns (bool addressSet) {
        require(administrativeAccount[msg.sender] == true, "Only Zone administrators can transfer the base wallet.");
        uint256 value = 0;
        if (_shiftAllTokens)
        {
            // Shift all of the tokens from the account to the new owner.
            value = balances[ownerWalletAddress];
        }
        
        balances[_newownerWalletAddress] += value;
        balances[ownerWalletAddress] -= value;

        ownerWalletAddress = _newownerWalletAddress;
        // By default, this new address will BECOME an administrative account.
        administrativeAccount[_newownerWalletAddress]=true;

        emit Transfer(ownerWalletAddress, _newownerWalletAddress, value);
        return true;
    }

    // While everything else revolves around the decimals defined in the EIP20 interface, this revolves around a ___10-digit decimal-like integer___.
    // For example, 1000000000 is 1.0 and 0100000000 is 0.1, thus 0000000001 is 0.000000001 or 0.0000001%
    function setAwardPercent(uint64 _percentForDonations, uint64 _date) public returns (bool AwardSet) {
        require(administrativeAccount[msg.sender] == true, "Only Zone administrators can set the award percent.");
        uint64 pctDonationMax     = uint64(10) ** uint64(7);
        require(_percentForDonations  <= pctDonationMax, "The value for Donations is too large. Must be less than 0010000000.");

        donationsPercent = _percentForDonations;
        lastAwardDate  = _date;
        
        // Announce to the network when a Reward is posted.
        emit RewardUpdated(msg.sender, _percentForDonations, _date);
        return true;
    }
    
    function claimAward() public returns (bool AwardClaimed) {
        uint256 minimum = uint256(10) ** uint256(decimals());
        require(unAwardedDonationBalance[msg.sender] >= minimum, "To claim an award, you must have donated at least one full token.");
        require(lastClaimedAward[msg.sender] == 0 || lastClaimedAward[msg.sender] < lastAwardDate, "This account has claimed an award already since the award was last declared.");
        require(donationsPercent > 0, "No rewards to claim right now.");
        
        uint256 value = claimTokensDonated(msg.sender);
        
        require(value > 0, "You did not earn any reward at this time. Try again later after holding some tokens or making a donation.");
        
        balances[msg.sender] += value;
        // This money is just ... printed. From nowhere. And that
        // gets added to the totalSupply.
        theTotalSupply += value;
        totalAvailableToPublic += value;
        totalAwarded += value;
        totalAwardedByWallet[msg.sender] += value;

        unAwardedDonationBalance[msg.sender]=0;
        
        lastClaimedAward[msg.sender] = lastAwardDate;
        
        emit Transfer(donationWalletAddress, msg.sender, value);
        return true;
    }
    
    function claimTokensDonated(address _sender) private view returns (uint256)
    {
        // Despite the number of digits for the token, the percents are expected to have 10 decimal places.
        if (donationsPercent == 0) { return 0; }
        return unAwardedDonationBalance[_sender] * donationsPercent / 10000000000;
    }
    // -----------------------------------------------------------------------------------
}