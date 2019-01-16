pragma solidity 0.5.0; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   &#39; /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_



██████╗ ███████╗██████╗  ██████╗ ███████╗██╗████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔════╝██║╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
██║  ██║█████╗  ██████╔╝██║   ██║███████╗██║   ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
██║  ██║██╔══╝  ██╔═══╝ ██║   ██║╚════██║██║   ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
██████╔╝███████╗██║     ╚██████╔╝███████║██║   ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
╚═════╝ ╚══════╝╚═╝      ╚═════╝ ╚══════╝╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝
                                                                                        



// ----------------------------------------------------------------------------
// &#39;Deposit Token 10% (DT10)&#39; contract with following functionalities:
//      => Higher control of owner
//      => SafeMath implementation 
//      => Referral system - 3 level
//
// Name             : Deposit Token 10%
// Symbol           : DT10
// Decimals         : 15
//
// Copyright (c) 2018 FIRST DECENTRALIZED DEPOSIT PLATFORM ( https://fddp.io )
// Contract designed by: EtherAuthority ( https://EtherAuthority.io ) 
// ----------------------------------------------------------------------------
*/ 


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

  function subsafe(uint256 a, uint256 b) internal pure returns (uint256) {
    if(b <= a){
        return a - b;
    }else{
        return 0;
    }
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}


contract DepositToken_10 {
    
    using SafeMath for uint;
    
    string public constant name = "Deposit Token 10%";
    
    string public constant symbol = "DT10";
    
    uint32 public constant decimals = 15;
    
    uint _money = 0;
    uint _tokens = 0;
    uint _sellprice;
    uint contractBalance;
    
    // Адрес контракта Акций
    address payable theStocksTokenContract;
    
    // сохранить баланс на счетах пользователя
    
    mapping (address => uint) balances;
    
    event FullEventLog(
        bytes32 status,
        uint sellprice,
        uint buyprice, 
        uint time,
        uint tokens,
        uint ethers);
        
    event OperationEvent(
        bytes32 status, 
        uint sellprice, 
        uint time);
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value);
        
    // OK
    constructor (address payable _tstc) public {
        uint s = 10**13; // start price
        _sellprice = s.mul(90).div(100);
        theStocksTokenContract = _tstc;
        
        /* 1000 token belongs to the contract */
        uint _value = 1000 * 10**15; 
        
        _tokens += _value;
        balances[address(this)] += _value;
        
        emit Transfer(address(0x0), address(this), _value);
    }
    function totalSupply () public view returns (uint256 tokens) {
        return _tokens;
    }
   
    function getTheStocksTokens () public view returns (address stAddress) {
        return theStocksTokenContract;
    }
    
    // OK
    function balanceOf(address addr) public view returns(uint){
        return balances[addr];
    }
    
    // OK
    function transfer(address _to, uint256 _value) public returns (bool success) {
        address addressContract = address(this);
        require(_to == addressContract);
        sell(_value);
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }
    
    // OK
    function () external payable {
        buy(address(0x0));
    }
    
    
    //***************************************************//
    //--------------- REFERAL SYSTEM CODE ---------------//
    //***************************************************//
    
    /** TECHNICAL SPECIFICATIONS
     * 
     * Because this is multi-level (3 level) referral system, we have to fix referrals.
     * Which means once a user is fixed under someone as referral, then that can not be changed.
     * Referral will be fixed at their first deposit.
     * This also means. If a person have used referral link to deposit and got fixed. Then if he does not use any links to deposit again, referral bonus paid to their referrers.
     * 
     * 
     * USE CASES
     * 
     * Case 1: depositor have used referral links, as well as depositor has existing direct referrer.
     * In this case, ether will be sent to existing referrer, it will ignore the new link he used.
     * 
     * Case 2: depositor has existing referrer/up-line/direct sponsor, but he did not use any referrer link or sent ether directly to smart contract.
     * In this case, ether will be sent to existing referrer.
     * 
     * Case 3: depositor does not have any existing direct referrer, but used referral link.
     * In this case, referral bonus will be paid to address in the referral link.
     * 
     * All other cases apart from above, referral bonus will not be paid to anyone.
     * And Entire platform fee (5% of deposit) will be sent to stock contract.
     */
    
    /* Mapping to track referrer. The second address is the address of referrer, the Up-line/ Sponsor */
    mapping (address => address payable) referrals;
    
    /* Events to track ether transfer to referrers */
    event ReferrerBonus(address indexed referer, address indexed depositor, uint256 depositAmount , uint256 etherReceived, uint256 timestamp );
    
    /* Function to distribute bonuses to referrers, as well as calculating finaPlatformFee */
    function distributeReferrerBonus(address payable _directReferrer, uint platformFee) internal returns (uint){
        
        // 40% of the Platform fee will be distributed to referrers, which is 2% of deposited ether
        uint finaPlatformFee = platformFee;
        
        // Sending ether to level 1 (direct) referrer and deducting that amount from platformFee
        uint256 _valueLevel1 = platformFee.mul(20).div(100);
        _directReferrer.transfer(_valueLevel1); //20% of Platform Fee
        finaPlatformFee = finaPlatformFee.sub(_valueLevel1);
        emit ReferrerBonus(_directReferrer, msg.sender, msg.value , _valueLevel1, now );
    
        
        // If there is level 2 referrer, then sending ether to him/her as well
        if(referrals[_directReferrer] != address(0x0)){
            // Sending ether to level 2 referrer and deducting that amount from platformFee
            uint256 _valueLevel2 = platformFee.mul(10).div(100);
            referrals[_directReferrer].transfer(_valueLevel2); //10% of Platform Fee
            finaPlatformFee = finaPlatformFee.sub(_valueLevel2);
            emit ReferrerBonus(referrals[_directReferrer], msg.sender, msg.value , _valueLevel2, now );
        }
        
        // If there is level 3 referrer, then sending ether to him/her as well
        if(referrals[referrals[_directReferrer]] != address(0x0)){
            // Sending ether to level 2 referrer and deducting that amount from platformFee
            uint256 _valueLevel3 = platformFee.mul(10).div(100);
            referrals[referrals[_directReferrer]].transfer(_valueLevel3); //10% of Platform Fee
            finaPlatformFee = finaPlatformFee.sub(_valueLevel3);
            emit ReferrerBonus(referrals[referrals[_directReferrer]], msg.sender, msg.value , _valueLevel3, now );
        }
        
        // Returns final platform fee which would be sent to stock contract
        return finaPlatformFee;
    }
    
    
    // OK
    function buy(address payable _referrer) public payable {
        uint _value = msg.value.mul(10**15).div(_sellprice.mul(100).div(90));
        
        // общий баланс Эфиров на контракте
        _money = _money.add(msg.value.mul(95).div(100));
        
        // Platform fee - 5% of the ether deposit
        uint platformFee = msg.value.mul(50).div(1000);
        
        // Final platform Fee, is after all the referrer payout deductions (as many as applicable).
        uint finaPlatformFee; 
        
        
        /** Processing referral system fund distribution **/
        // Case 1: depositor have used referral links, as well as depositor has existing direct referrer
        // In this case, ether will be sent to existing referrer, it will ignore the new link he used.
        if(_referrer != address(0x0) && referrals[msg.sender] != address(0x0)){
            finaPlatformFee = distributeReferrerBonus(referrals[msg.sender], platformFee);
        }
        
        // Case 2: depositor has existing referrer/up-line/direct sponsor, but he did not use any referrer link or sent ether directly to smart contract
        // In this case, ether will be sent to existing referrer
        else if(_referrer == address(0x0) && referrals[msg.sender] != address(0x0)){
            finaPlatformFee = distributeReferrerBonus(referrals[msg.sender], platformFee);
        }
        
        // Case 3: depositor does not have any existing direct referrer, but used referral link
        // In this case, referral bonus will be paid to address in the referral link
        else if(_referrer != address(0x0) && referrals[msg.sender] == address(0x0)){
            finaPlatformFee = distributeReferrerBonus(_referrer, platformFee);
        }
        
        // All other cases apart from above, referral bonus will not be paid to anyone
        // And Entire platform fee (5% of deposit) will be sent to stock contract
        else {
            finaPlatformFee = platformFee;
        }
        
        // отправить прибыль на контракт собствеников системы
        (bool success, bytes memory data) =    theStocksTokenContract.call.value(finaPlatformFee).gas(53000)("");
        
        // This checks if ether transfer to stock contract is successful, otherwise revert
        if(!success){  revert();  data = data; }
        
        // всего токенов в системе
        _tokens = _tokens.add(_value);
        
        // добавить токены, на баланс пользователя
        balances[msg.sender] = balances[msg.sender].add(_value);
        
        // Логируем событие с курсом / датой / 
        emit FullEventLog("buy", _sellprice, _sellprice.mul(100).div(95), now, _value, msg.value);
        
        _sellprice = _money.mul(10**15).mul(98).div(_tokens).div(100);
        
        emit OperationEvent("buy", _sellprice, now);
        
        address addressContract = address(this);
        emit Transfer(addressContract, msg.sender, _value);
    }

    // OK
    function sell (uint256 countTokens) public {
        // проверка на отрицательный баланс
        require(balances[msg.sender] >= countTokens);
        
        uint _value = countTokens.mul(_sellprice).div(10**15);
        
        _money = _money.sub(_value);
        
        _tokens = _tokens.subsafe(countTokens);
        
        balances[msg.sender] = balances[msg.sender].subsafe(countTokens);
        
        emit FullEventLog("sell", _sellprice, _sellprice.mul(100).div(95), now, countTokens, _value);
        
        if(_tokens > 0) {
            _sellprice = _money.mul(10**15).mul(98).div(_tokens).div(100);
        }
        emit OperationEvent("sell", _sellprice, now);
    	emit Transfer(msg.sender, address(this), countTokens);
        msg.sender.transfer(_value);
    }
    // OK
    function getPrice() public view returns (uint bid, uint ask) {
        bid = _sellprice.mul(100).div(90);
        ask = _sellprice;
    }
}