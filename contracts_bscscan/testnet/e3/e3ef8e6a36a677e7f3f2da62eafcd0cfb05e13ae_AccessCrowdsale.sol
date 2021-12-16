/**
 *Submitted for verification at BscScan.com on 2021-12-16
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
 * To buy ADT user must be Whitelisted
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



contract AccessCrowdsale is Whitelisted {
    using SafeMath for uint256;
    
    address public beneficiary;
    uint256 public SoftCap;
    uint256 public HardCap;
    uint256 public amountRaised;
    uint256 public seedSaleStartdate;
    uint256 public seedSaleDeadline;
    uint256 public privateSale1Startdate;
    uint256 public privateSale1Deadline;
    uint256 public privateSale2Startdate;
    uint256 public privateSale2Deadline;
    uint256 public mainSaleStartdate;
    uint256 public mainSaleDeadline;
    uint256 public price;
    uint256 public fundTransferred;
    uint256 public tokenSold;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;
    bool returnFunds = false;
	
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    constructor() public {
        beneficiary = 0xe3fa577f6d00380e902bB02139eeC3cC31f53C5D;
        SoftCap = 2500000 ether;
        HardCap = 25000000 ether;
        seedSaleStartdate = 1638806536;
        seedSaleDeadline = 1639324936;
        privateSale1Startdate = 1639324936;
        privateSale1Deadline = 1639497736;
        privateSale2Startdate = 1639497736;
        privateSale2Deadline = 1639756936;
        mainSaleStartdate = 1639756936;
        mainSaleDeadline = 1640102536;
        price = 0.000002375 ether;
        tokenReward = token(0x4bc11808A49C93485CFCdbf9861B192a821824d7);
    }


    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        
        uint256 bonus = 0;
        uint256 amount;
        uint256 ethamount = msg.value;
        
        require(!crowdsaleClosed);
        // divide by price to get the actual adt token
        uint256 onlyAdt = ethamount.div(price);
        // multiply adt value with decimal of adt to get the wei adt
        uint256 weiAdt = SafeMath.mul(onlyAdt, 100000000000000);
    
        require(isValidUser(msg.sender, weiAdt));


        
        balanceOf[msg.sender] = balanceOf[msg.sender].add(ethamount);
        amountRaised = amountRaised.add(ethamount);
        
        //add bonus for funders
        if(now >= seedSaleStartdate && now <= seedSaleDeadline && now <= seedSaleDeadline / 2){
            amount =  ethamount.div(price);
            bonus = amount * 25 / 100;
            amount = amount.add(bonus);
        } 
        else if (now >= seedSaleStartdate && now <= seedSaleDeadline) {
            amount =  ethamount.div(price);
            bonus = amount * 23 / 100;
            amount = amount.add(bonus);
        }
        else if(now >= privateSale1Startdate && now <= privateSale1Deadline && now <= privateSale1Deadline / 2){
            amount =  ethamount.div(price);
            bonus = amount * 20 / 100;
            amount = amount.add(bonus);
        }
        else if(now >= privateSale1Startdate && now <= privateSale1Deadline){
            amount =  ethamount.div(price);
            bonus = amount * 18 / 100;
            amount = amount.add(bonus);
        }
        else if(now >= privateSale2Startdate && now <= privateSale2Deadline && now <= privateSale2Deadline / 2){
            amount =  ethamount.div(price);
            bonus = amount * 15 / 100;
            amount = amount.add(bonus);
        }
        else if(now >= privateSale2Startdate && now <= privateSale2Deadline){
            amount =  ethamount.div(price);
            bonus = amount * 12 / 100;
            amount = amount.add(bonus);
        }
        else if(now >= mainSaleStartdate && now <= mainSaleStartdate && now <= mainSaleStartdate / 2){
            amount =  ethamount.div(price);
            bonus = amount * 10/100;
            amount = amount.add(bonus);
        }
        else if(now >= mainSaleStartdate && now <= mainSaleStartdate){
            amount =  ethamount.div(price);
            bonus = amount * 5/100;
            amount = amount.add(bonus);
        } else {
            amount =  ethamount.div(price);
        }
        
        amount = amount.mul(100000000000000);
        tokenReward.transfer(msg.sender, amount);
        tokenSold = tokenSold.add(amount);
        
        resetUserWhiteListAmount();
        emit FundTransfer(msg.sender, ethamount, true);
    }

    modifier afterDeadline() {if (now >= mainSaleDeadline) _; }

    /**
     *ends the campaign after deadline
     */
     
    function endCrowdsale() public afterDeadline  onlyOwner {
        crowdsaleClosed = true;
    }
    
    function EnableReturnFunds() public onlyOwner {
        returnFunds = true;
    }
    
    function DisableReturnFunds() public onlyOwner {
        returnFunds = false;
    }
	
    function ChangePrice(uint256 _price) public onlyOwner {
        price = _price;	
    }

    function ChangeBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;	
    }
	 
    function SeedSaleDates(uint256 _seedSaleStartdate, uint256 _seedSaleDeadline) onlyOwner public{
        if(_seedSaleStartdate != 0){
            seedSaleStartdate = _seedSaleStartdate;
        }
        if(_seedSaleDeadline != 0){
            seedSaleDeadline = _seedSaleDeadline;
        }
        
        if(crowdsaleClosed == true){
            crowdsaleClosed = false;
        }
    }

    function ChangePrivateSale1Dates(uint256 _privateSale1Startdate, uint256 _privateSale1Deadline) onlyOwner public{
        if(_privateSale1Startdate != 0){
            privateSale1Startdate = _privateSale1Startdate;
        }
        if(_privateSale1Deadline != 0){
            privateSale1Deadline = _privateSale1Deadline;
        }
        
        if(crowdsaleClosed == true){
            crowdsaleClosed = false;
        }
    }

    function ChangePrivateSale2Dates(uint256 _privateSale2Startdate, uint256 _privateSale2Deadline) onlyOwner public{
        if(_privateSale2Startdate != 0){
            privateSale2Startdate = _privateSale2Startdate;
        }
        if(_privateSale2Deadline != 0){
            privateSale2Deadline = _privateSale2Deadline;
        }
        
        if(crowdsaleClosed == true){
            crowdsaleClosed = false;
        }
    }
    
    function ChangeMainSaleDates(uint256 _mainSaleStartdate, uint256 _mainSaleDeadline) onlyOwner public{
        if(_mainSaleStartdate != 0){
            mainSaleStartdate = _mainSaleStartdate;
        }
        if(_mainSaleDeadline != 0){
            mainSaleDeadline = _mainSaleDeadline; 
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
    
    function getResponse(uint256 val) public constant returns(uint256) {
        uint256 adtDec = 100000000000000;
        
        uint256 onlyAdt = val.div(price);
        // multiply adt value with decimal of adt to get the wei adt
        uint256 weiAdt = SafeMath.mul(onlyAdt, adtDec);
        
        return weiAdt;
    }

}