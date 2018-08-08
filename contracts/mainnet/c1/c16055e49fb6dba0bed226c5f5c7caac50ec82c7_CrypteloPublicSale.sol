pragma solidity ^0.4.0;

contract CrypteloERC20{
  mapping (address => uint256) public balanceOf;
  function transfer(address to, uint amount);
  function burn(uint256 _value) public returns (bool success);
}

contract CrypteloPreSale{
  function isWhiteList(address _addr) public returns (uint _group);
}

contract TadamWhitelistPublicSale{
    function isWhiteListed(address _addr) returns (uint _group);
    mapping (address => uint) public PublicSaleWhiteListed;
}

contract CrypteloPublicSale{
    using SafeMath for uint256;
    mapping (address => bool) private owner;

    
    uint public contributorCounter = 0;
    mapping (uint => address) contributor;
    mapping (address => uint) contributorAmount;
    
    /*
        Public Sale Timings and bonuses
    */
    
    
    uint ICOstartTime = 0; 
    uint ICOendTime = now + 30 days;
    
    //first 7 days bonus 25%
    uint firstDiscountStartTime = ICOstartTime;
    uint firstDiscountEndTime = ICOstartTime + 7 days;
    
    //day 7 to day 14 bonus 20%
    uint secDiscountStartTime = ICOstartTime + 7 days;
    uint secDiscountEndTime = ICOstartTime + 14 days;
    
    //day 14 to day 21 bonus 15%
    uint thirdDiscountStartTime = ICOstartTime + 14 days;
    uint thirdDiscountEndTime = ICOstartTime + 21 days;
    
    //day 21 to day 28 bonus 10%
    uint fourthDiscountStartTime = ICOstartTime + 21 days;
    uint fourthDiscountEndTime = ICOstartTime + 28 days;

    /*
        External addresses
    */
    address public ERC20Address; 
    address public preSaleContract;
    address private forwardFundsWallet;
    address public whiteListAddress;
    
    event eSendTokens(address _addr, uint _amount);
    event eStateChange(bool state);
    event eLog(string str, uint no);
    event eWhiteList(address adr, uint group);
    
    function calculateBonus(uint _whiteListLevel) returns (uint _totalBonus){
        uint timeBonus = currentTimeBonus();
        uint totalBonus = 0;
        uint whiteListBonus = 0;
        if (_whiteListLevel == 1){
            whiteListBonus = whiteListBonus.add(5);
        }
        totalBonus = totalBonus.add(timeBonus).add(whiteListBonus);
        return totalBonus;
    }
    function currentTimeBonus () public returns (uint _bonus){
        uint bonus = 0;
        //ICO is running
        if (now >= firstDiscountStartTime && now <= firstDiscountEndTime){
            bonus = 25;
        }else if(now >= secDiscountStartTime && now <= secDiscountEndTime){
            bonus = 20;
        }else if(now >= thirdDiscountStartTime && now <= thirdDiscountEndTime){
            bonus = 15;
        }else if(now >= fourthDiscountStartTime && now <= fourthDiscountEndTime){
            bonus = 10;
        }else{
            bonus = 5;
        }
        return bonus;
    }
    
    function CrypteloPublicSale(address _ERC20Address, address _preSaleContract, address _forwardFundsWallet, address _whiteListAddress ){
        owner[msg.sender] = true;
        ERC20Address = _ERC20Address;
        preSaleContract = _preSaleContract;
        forwardFundsWallet = _forwardFundsWallet;
        whiteListAddress = _whiteListAddress;    
    }
    /*
        States are
            false - Paused - it doesn&#39;t accept payments
            true - Live - accepts payments and disburse tokens if conditions meet
    */
    bool public currentState = false;

    
    /*
        Financial Ratios 
    */
    uint hardCapTokens = addDecimals(8,187500000);
    uint raisedWei = 0;
    uint tokensLeft = hardCapTokens;
    uint reservedTokens = 0;
    uint minimumDonationWei = 100000000000000000;
    uint public tokensPerEther = addDecimals(8, 12500); //1250000000000
    uint public tokensPerMicroEther = tokensPerEther.div(1000000);
    
    function () payable {

        uint tokensToSend = 0;
        uint amountEthWei = msg.value;
        address sender = msg.sender;
        
        //check if its live
        
        require(currentState);
        eLog("state OK", 0);
        require(amountEthWei >= minimumDonationWei);
        eLog("amount OK", amountEthWei);
        
        uint whiteListedLevel = isWhiteListed(sender);
        require( whiteListedLevel > 0);

        tokensToSend = calculateTokensToSend(amountEthWei, whiteListedLevel);
        
        require(tokensLeft >= tokensToSend);
        eLog("tokens left vs tokens to send ok", tokensLeft);    
        eLog("tokensToSend", tokensToSend);
        
        //test for minus
        if (tokensToSend <= tokensLeft){
            tokensLeft = tokensLeft.sub(tokensToSend);    
        }
        
        addContributor(sender, tokensToSend);
        reservedTokens = reservedTokens.add(tokensToSend);
        eLog("send tokens ok", 0);
        
        forwardFunds(amountEthWei);
        eLog("forward funds ok", amountEthWei);
    }
    
    function  calculateTokensToSend(uint _amount_wei, uint _whiteListLevel) public returns (uint _tokensToSend){
        uint tokensToSend = 0;
        uint amountMicroEther = _amount_wei.div(1000000000000);
        uint tokens = amountMicroEther.mul(tokensPerMicroEther);
        
        eLog("tokens: ", tokens);
        uint bonusPerc = calculateBonus(_whiteListLevel); 
        uint bonusTokens = 0;
        if (bonusPerc > 0){
            bonusTokens = tokens.div(100).mul(bonusPerc);    
        }
        eLog("bonusTokens", bonusTokens); 
        
        tokensToSend = tokens.add(bonusTokens);

        eLog("tokensToSend", tokensToSend);  
        return tokensToSend;
    }
    
    function payContributorByNumber(uint _n) onlyOwner{
        require(now > ICOendTime);
        
        address adr = contributor[_n];
        uint amount = contributorAmount[adr];
        sendTokens(adr, amount);
        contributorAmount[adr] = 0;
    }
    
    function payContributorByAdress(address _adr) {
        require(now > ICOendTime);
        uint amount = contributorAmount[_adr];
        sendTokens(_adr, amount);
        contributorAmount[_adr] = 0;
    }
    
    function addContributor(address _addr, uint _amount) private{
        contributor[contributorCounter] = _addr;
        if (contributorAmount[_addr] > 0){
            contributorAmount[_addr] += _amount;
        }else{
            contributorAmount[_addr] = _amount;    
        }
        
        contributorCounter++;
    }
    function getContributorByAddress(address _addr) constant returns (uint _amount){
        return contributorAmount[_addr];
    }
    
    function getContributorByNumber(uint _n) constant returns (address _adr, uint _amount){
        address contribAdr = contributor[_n];
        uint amount = contributorAmount[contribAdr];
        return (contribAdr, amount);
        
    }
    
    function forwardFunds(uint _amountEthWei) private{
        raisedWei += _amountEthWei;
        forwardFundsWallet.transfer(_amountEthWei);  //find balance
    }
    
    function sendTokens(address _to, uint _amountCRL) private{
        //invoke call on token address
       CrypteloERC20 _tadamerc20;
        _tadamerc20 = CrypteloERC20(ERC20Address);
        _tadamerc20.transfer(_to, _amountCRL);
        eSendTokens(_to, _amountCRL);
    }
    
    function setCurrentState(bool _state) public onlyOwner {
        currentState = _state;
        eStateChange(_state);
    } 
    
    function burnAllTokens() public onlyOwner{
        CrypteloERC20 _tadamerc20;
        _tadamerc20 = CrypteloERC20(ERC20Address);
        uint tokensToBurn = _tadamerc20.balanceOf(this);
        require (tokensToBurn > reservedTokens);
        tokensToBurn -= reservedTokens;
        eLog("tokens burned", tokensToBurn);
        _tadamerc20.burn(tokensToBurn);
    }
    
    function isWhiteListed(address _address) returns (uint){
        
        /*
            return values :
            0 = not whitelisted at all,
            1 = white listed early (pre sale or before 15th of March)
            2 = white listed after 15th of March
        */
        uint256 whiteListedStatus = 0;
        
        TadamWhitelistPublicSale whitelistPublic;
        whitelistPublic = TadamWhitelistPublicSale(whiteListAddress);
        
        uint256 PSaleGroup = whitelistPublic.PublicSaleWhiteListed(_address);
        //if we have it in the PublicSale add it
        if (PSaleGroup > 0){
            whiteListedStatus = PSaleGroup;
        }else{
            CrypteloPreSale _testPreSale;
            _testPreSale = CrypteloPreSale(preSaleContract);
            if (_testPreSale.isWhiteList(_address) > 0){
                //exists in the pre-sale white list threfore give em early 1
                whiteListedStatus = 1;
            }else{
                //not found on either
                whiteListedStatus = 0;
            }
        }
        eWhiteList(_address, whiteListedStatus);
        return whiteListedStatus;
    }
    
    function addDecimals(uint _noDecimals, uint _toNumber) private returns (uint _finalNo) {
        uint finalNo = _toNumber * (10 ** _noDecimals);
        return finalNo;
    }
    
    function withdrawAllTokens() public onlyOwner{
        CrypteloERC20 _tadamerc20;
        _tadamerc20 = CrypteloERC20(ERC20Address);
        uint totalAmount = _tadamerc20.balanceOf(this);
        require(totalAmount > reservedTokens);
        uint toWithdraw = totalAmount.sub(reservedTokens);
        sendTokens(msg.sender, toWithdraw);
    }
    
    function withdrawAllEther() public onlyOwner{
        msg.sender.send(this.balance);
    }
     
    modifier onlyOwner(){
        require(owner[msg.sender]);
        _;
    }
    
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}