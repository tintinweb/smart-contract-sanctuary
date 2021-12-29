/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

pragma solidity ^0.4.25;

contract token {
    function transfer(address receiver, uint256 amount) public;
    function balanceOf(address _owner) public pure returns (uint256 balance);
    function burnFrom(address from, uint256 value) public;
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
  
}


/**
 * To buy AhouZ user must be Whitelisted
 * Add user address and value to Whitelist
 * Remove user address from Whitelist
 * Check if User is Whitelisted
 * Check if User have equal or greater value than Whitelisted
 */
 
library Whitelist {
    
    struct List {
        mapping(address => bool) registry;
        mapping(address => uint256) amount;
    }

    function addUserWithValue(List storage list, address _addr, uint256 _value)
        internal
    {
        list.registry[_addr] = true;
        list.amount[_addr] = _value;
    }
    
    function add(List storage list, address _addr)
        internal
    {
        list.registry[_addr] = true;
    }

    function remove(List storage list, address _addr)
        internal
    {
        list.registry[_addr] = false;
        list.amount[_addr] = 0;
    }

    function check(List storage list, address _addr)
        view
        internal
        returns (bool)
    {
        return list.registry[_addr];
    }

    function checkValue(List storage list, address _addr, uint256 _value)
        view
        internal
        returns (bool)
    {
        /** 
         * divided by  10^18 because bnb decimal is 18
         * and conversion to bnb to uint256 is carried out 
        */
         
        return list.amount[_addr] <= _value;
    }
}


contract owned {
    address public owner;

    constructor() public {
        owner = 0xe3fa577f6d00380e902bB02139eeC3cC31f53C5D;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


/**
 * Contract to whitelist User for buying token
 */
contract Whitelisted is owned {

    Whitelist.List private _list;
    uint256 decimals = 100000000000000;
    
    modifier onlyWhitelisted() {
        require(Whitelist.check(_list, msg.sender) == true);
        _;
    }

    event AddressAdded(address _addr);
    event AddressRemoved(address _addr);
    event AddressReset(address _addr);
    
    /**
     * Add User to Whitelist with bnb amount
     * @param _address User Wallet address
     * @param amount The amount of bnb user Whitelisted in wei
     */
    function addWhiteListAddress(address _address, uint256 amount)
    public {
        
        require(!isAddressWhiteListed(_address));
        
        Whitelist.addUserWithValue(_list, _address, amount);
        
        emit AddressAdded(_address);
    }
    
    /**
     * Set User's Whitelisted bnb amount to 0 so that 
     * during second buy transaction user won't need to 
     * validate for Whitelisted amount
     */
    function resetUserWhiteListAmount()
    internal {
        
        Whitelist.addUserWithValue(_list, msg.sender, 0);
        emit AddressReset(msg.sender);
    }


    /**
     * Disable User from Whitelist so user can't buy token
     * @param _addr User Wallet address
     */
    function disableWhitelistAddress(address _addr)
    public onlyOwner {
        
        Whitelist.remove(_list, _addr);
        emit AddressRemoved(_addr);
    }
    
    /**
     * Check if User is Whitelisted
     * @param _addr User Wallet address
     */
    function isAddressWhiteListed(address _addr)
    public
    view
    returns (bool) {
        
        return Whitelist.check(_list, _addr);
    }


    /**
     * Check if User has enough bnb amount in Whitelisted to buy token 
     * @param _addr User Wallet address
     * @param amount The amount of bnb user inputed
     */
    function isWhiteListedValueValid(address _addr, uint256 amount)
    public
    view
    returns (bool) {
        
        return Whitelist.checkValue(_list, _addr, amount);
    }


   /**
     * Check if User is valid to buy token 
     * @param _addr User Wallet address
     * @param amount The amount of bnb user inputed
     */
    function isValidUser(address _addr, uint256 amount)
    public
    view
    returns (bool) {
        
        return isAddressWhiteListed(_addr) && isWhiteListedValueValid(_addr, amount);
    }
    
    /**
     * returns the total amount of the address hold by the user during white list
     */
    function getUserAmount(address _addr) public constant returns (uint256) {
        
        require(isAddressWhiteListed(_addr));
        return _list.amount[_addr];
    }
    
}



contract AhouZCrowdsale is Whitelisted {
    using SafeMath for uint256;
    
    address public beneficiary;
    uint256 public SoftCap;
    uint256 public HardCap;
    uint256 public amountRaised;
    uint[4] public seedSaleDates;
    uint[4] public privateSale1Dates;
    uint[4] public privateSale2Dates;
    uint[4] public publicSaleDates;
    uint256 public fundTransferred;
    uint256 public tokenSold;
    uint256 public tokenSoldWithBonus;
    uint[4] public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public crowdsaleClosed = false;
    bool public returnFunds = false;
	
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    constructor() public {
        beneficiary = 0xe3fa577f6d00380e902bB02139eeC3cC31f53C5D;
        SoftCap = 4560 ether;
        HardCap = 136813 ether;
        seedSaleDates = [1640680055, 1641680055];
        privateSale1Dates = [1641680055, 1642680055];
        privateSale2Dates = [1642680055, 1644680055];
        publicSaleDates = [1644680055, 1654680055];

        // price should be in 10^18 format. 
        price = [910332271279, 1001365498406, 1092398725534, 1365921177241];
        tokenReward = token(0x4bc11808A49C93485CFCdbf9861B192a821824d7);
    }


    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        
        uint256 bonus = 0;
        uint256 bonusPercent = 0;
        uint256 amount = 0;
        uint256 amountWithBonus = 0;
        uint256 ethamount = msg.value;
        
        require(!crowdsaleClosed);

        require(isValidUser(msg.sender, ethamount));

        //add bonus for funders
        if(now >= seedSaleDates[0] && now <= seedSaleDates[1]){
            amount =  ethamount.div(price[0]);
            bonusPercent = now <= ((seedSaleDates[1] - seedSaleDates[0]) / 2  +  seedSaleDates[0]) ? 25 : 23;
        }
        else if(now >= privateSale1Dates[0] && now <= privateSale1Dates[1]){
            amount =  ethamount.div(price[1]);
            bonusPercent = now <= ((privateSale1Dates[1] - privateSale1Dates[0]) / 2  +  privateSale1Dates[0]) ? 20 : 18;
        }
        else if(now >= privateSale2Dates[0] && now <= privateSale2Dates[1]){
            amount =  ethamount.div(price[2]);
            bonusPercent = now <= ((privateSale2Dates[1] - privateSale2Dates[0]) / 2  +  privateSale2Dates[0]) ? 15 : 12;
        }
        else if(now >= publicSaleDates[0] && now <= publicSaleDates[1]){
            amount =  ethamount.div(price[3]);
            bonusPercent = now <= ((publicSaleDates[1] - publicSaleDates[0]) / 2  +  publicSaleDates[0]) ? 10 : 5;
        }

        bonus = amount * bonusPercent / 100;
        amountWithBonus = amount.add(bonus);

        balanceOf[msg.sender] = balanceOf[msg.sender].add(ethamount);
        amountRaised = amountRaised.add(ethamount);
        
        tokenReward.transfer(msg.sender, amountWithBonus.mul(100000000000000));
        tokenSold = tokenSold.add(amount.mul(100000000000000));
        tokenSoldWithBonus = tokenSoldWithBonus.add(amountWithBonus.mul(100000000000000));
        
        resetUserWhiteListAmount();
        emit FundTransfer(msg.sender, ethamount, true);
    }

    modifier afterDeadline() {if (now >= publicSaleDates[1]) _; }

    /**
     *ends the campaign after deadline
     */
     
    function endCrowdsale() public afterDeadline onlyOwner {
        crowdsaleClosed = true;
    }
    
    function EnableReturnFunds() public onlyOwner {
        returnFunds = true;
    }
    
    function DisableReturnFunds() public onlyOwner {
        returnFunds = false;
    }

    function bonusSent() view returns (uint256) {
        return tokenSoldWithBonus - tokenSold;
    }
	
    /**
     * seed sale price
     * private sale 1 price
     * private sale 2 price
     * public sale price
     */
    function ChangeSalePrices(uint256 _seed_price, uint256 _privatesale1_price, uint256 _privatesale2_price, uint256 _publicsale_price) public onlyOwner {
        price[0] = _seed_price;	
        price[1] = _privatesale1_price;	
        price[2] = _privatesale2_price;	
        price[3] = _publicsale_price;
    }

    function ChangeBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;	
    }
	 
    function SeedSaleDates(uint256 _seedSaleStartdate, uint256 _seedSaleDeadline) onlyOwner public{
        if(_seedSaleStartdate != 0){
            seedSaleDates[0] = _seedSaleStartdate;
        }
        if(_seedSaleDeadline != 0){
            seedSaleDates[1] = _seedSaleDeadline;
        }
        
        if(crowdsaleClosed == true){
            crowdsaleClosed = false;
        }
    }

    function ChangePrivateSale1Dates(uint256 _privateSale1Startdate, uint256 _privateSale1Deadline) onlyOwner public{
        if(_privateSale1Startdate != 0){
            privateSale1Dates[0] = _privateSale1Startdate;
        }
        if(_privateSale1Deadline != 0){
            privateSale1Dates[1] = _privateSale1Deadline;
        }
        
        if(crowdsaleClosed == true){
            crowdsaleClosed = false;
        }
    }

    function ChangePrivateSale2Dates(uint256 _privateSale2Startdate, uint256 _privateSale2Deadline) onlyOwner public{
        if(_privateSale2Startdate != 0){
            privateSale2Dates[0] = _privateSale2Startdate;
        }
        if(_privateSale2Deadline != 0){
            privateSale2Dates[1] = _privateSale2Deadline;
        }
        
        if(crowdsaleClosed == true){
            crowdsaleClosed = false;
        }
    }
    
    function ChangeMainSaleDates(uint256 _mainSaleStartdate, uint256 _mainSaleDeadline) onlyOwner public{
        if(_mainSaleStartdate != 0){
            publicSaleDates[0] = _mainSaleStartdate;
        }
        if(_mainSaleDeadline != 0){
            publicSaleDates[1] = _mainSaleDeadline; 
        }
        
        if(crowdsaleClosed == true){
            crowdsaleClosed = false;       
        }
    }
    
    /**
     * Get all the remaining token back from the contract
     */
    function getTokensBack() onlyOwner public{
        
        require(crowdsaleClosed);
        
        uint256 remaining = tokenReward.balanceOf(this);
        tokenReward.transfer(beneficiary, remaining);
    }
    
    /**
     * User can get their bnb back if crowdsale didn't meet it's requirement 
     */
    function safeWithdrawal() public afterDeadline {
        if (returnFunds) {
            uint amount = balanceOf[msg.sender];
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    emit FundTransfer(msg.sender, amount, false);
                    balanceOf[msg.sender] = 0;
                    fundTransferred = fundTransferred.add(amount);
                } 
            }
        }

        if (returnFunds == false && beneficiary == msg.sender) {
            uint256 ethToSend = amountRaised - fundTransferred;
            if (beneficiary.send(ethToSend)) {
                fundTransferred = fundTransferred.add(ethToSend);
            } 
        }
    }
    

}