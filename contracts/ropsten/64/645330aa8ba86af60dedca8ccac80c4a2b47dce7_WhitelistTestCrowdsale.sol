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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
        return list.amount[_addr] <= _value;
    }
}


contract Whitelisted {

    Whitelist.List private _list;
    
    modifier onlyWhitelisted() {
        require(Whitelist.check(_list, msg.sender) == true);
        _;
    }

    event AddressAdded(address _addr);
    event AddressRemoved(address _addr);
    
    function WhitelistedAddress(uint256 amount)
    public
    {
        require(!isWhitelistAddressListed(msg.sender));
        Whitelist.addUserWithValue(_list, msg.sender, amount);
    }

    function WhitelistAddressenable(address _addr)
        public
    {
        Whitelist.add(_list, _addr);
        emit AddressAdded(_addr);
    }

    function WhitelistAddressdisable(address _addr)
        public
    {
        Whitelist.remove(_list, _addr);
        emit AddressRemoved(_addr);
    }
    
    function isWhitelistAddressListed(address _addr)
    public
    view
    returns (bool)
    {
        return Whitelist.check(_list, _addr);
    }

    function checkWhitelistAddressValue(address _addr, uint256 amount)
    public
    view
    returns (bool)
    {
        return Whitelist.checkValue(_list, _addr, amount);
    }

    function isValidUser(address _addr, uint256 amount)
    public
    view
    returns (bool)
    {
        return Whitelist.check(_list, _addr) && Whitelist.checkValue(_list, _addr, amount);
    }
    
    function getWhitelistedAmount(address _address) public constant 
    returns (uint256){
        return _list.amount[_address];
    }
}


contract owned {
    address public owner;

    constructor() public {
        owner = 0x9E2DF609F768f2F95F1bC6a04E0E4C596c2FA611;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract WhitelistTestCrowdsale is owned, Whitelisted {
    using SafeMath for uint256;
    
    address public beneficiary;
    uint256 public SoftCap;
    uint256 public HardCap;
    uint256 public amountRaised;
    uint256 public preSaleStartdate;
    uint256 public preSaleDeadline;
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
        beneficiary = 0x9E2DF609F768f2F95F1bC6a04E0E4C596c2FA611;
        SoftCap = 15000 ether;
        HardCap = 150000 ether;
        preSaleStartdate = 1541030400;
        preSaleDeadline = 1543622399;
        mainSaleStartdate = 1543622400;
        mainSaleDeadline = 1551398399;
        price = 0.0004 ether;
        tokenReward = token(0x655bdb77ebE50Ff1159382ee4164961F662365A6);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(!crowdsaleClosed);
        require(isWhitelistAddressListed(msg.sender));
        require(checkWhitelistAddressValue(msg.sender, msg.value));


        uint256 bonus = 0;
        uint256 amount;
        uint256 ethamount = msg.value;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(ethamount);
        amountRaised = amountRaised.add(ethamount);
        
        //add bounus for funders
        if(now >= preSaleStartdate && now <= preSaleDeadline){
            amount =  ethamount.div(price);
            bonus = amount * 33 / 100;
            amount = amount.add(bonus);
        }
        else if(now >= mainSaleStartdate && now <= mainSaleStartdate + 30 days){
            amount =  ethamount.div(price);
            bonus = amount * 25/100;
            amount = amount.add(bonus);
        }
        else if(now >= mainSaleStartdate + 30 days && now <= mainSaleStartdate + 45 days){
            amount =  ethamount.div(price);
            bonus = amount * 15/100;
            amount = amount.add(bonus);
        }
        else if(now >= mainSaleStartdate + 45 days && now <= mainSaleStartdate + 60 days){
            amount =  ethamount.div(price);
            bonus = amount * 10/100;
            amount = amount.add(bonus);
        } else {
            amount =  ethamount.div(price);
            bonus = amount * 7/100;
            amount = amount.add(bonus);
        }
        
        amount = amount.mul(100000000000000);
        tokenReward.transfer(msg.sender, amount);
        tokenSold = tokenSold.add(amount);
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
	 
    function ChangePreSaleDates(uint256 _preSaleStartdate, uint256 _preSaleDeadline) onlyOwner public{
        if(_preSaleStartdate != 0){
            preSaleStartdate = _preSaleStartdate;
        }
        if(_preSaleDeadline != 0){
            preSaleDeadline = _preSaleDeadline;
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
    
    function getTokensBack() onlyOwner public{
        uint256 remaining = tokenReward.balanceOf(this);
        tokenReward.transfer(beneficiary, remaining);
    }
    
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