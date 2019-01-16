pragma solidity ^0.4.25;

/**
 *                                     * oneperday - distribution contract *
 * 
 *  - Growth of 1% in 24 hours (every 5900 blocks)
 * 
 * Distribution: *
 * - 5% Advertising, promotion
 * - 5% Referral program
 * - 5% Cashback
 * - 5% for developers and technical support
 *
 * Usage rules *
 *  Holding:
 *   1. Send any amount of ether but not less than 0.01 THD to make a contribution.
 *   2. Send 0 ETH at any time to get profit from the Deposit.
 *  
 *  - You can make a profit at any time. Consider your transaction costs (GAS).
 *  
 * Affiliate program *
  * - * - Affiliate fees will come from each referral&#39;s Deposit as long as it doesn&#39;t change your wallet address Ethereum on the other.
 * 1. The depositor in the transfer of funds indicates the DATA in your e-wallet Ethereum.
 * 2. After successful transfer you will be charged 5% of the amount of his Deposit.
 * * 3. Your partner receives a "Refback bonus" in the amount of 5% of his contribution.
 * 
 *  
 * 
 *
 * RECOMMENDED GAS LIMIT: 250000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 * The contract has been tested for vulnerabilities!
 *
 */ 

contract oneperday{

    mapping (address => uint256) public invested;

    mapping (address => uint256) public payments; 
     
    mapping (address => address) public investedRef;
    
    mapping (address => uint256) public atBlock;
    
    mapping (address => uint256) public cashBack;
    
    mapping (address => uint256) public cashRef;
    
    mapping (address => uint256) public admComiss;
    
    using SafeMath for uint;
    using ToAddress for *;
    using Zero for *;
    
    address private adm_addr; //NB!
    uint256 private start_block;
    uint256 private constant dividends = 100;           // 1%
    uint256 private constant adm_comission = 10;        // 10%
    uint256 private constant ref_bonus = 5;            // 5%
    uint256 private constant ref_cashback = 5;          // 5%
    uint256 private constant block_of_24h = 5900;       // ~24 hour
    uint256 private constant min_invesment = 10 finney; // 0.01 eth
    
    //Statistics
    uint256 private all_invest_users_count = 0;
    uint256 private all_invest = 0;
    uint256 private all_payments = 0;
    uint256 private all_cash_back_payments = 0;
    uint256 private all_ref_payments = 0;
    uint256 private all_adm_payments = 0;
    uint256 private all_reinvest = 0;
    address private last_invest_addr = 0;
    uint256 private last_invest_amount = 0;
    uint256 private last_invest_block = 0;
    
    constructor() public {
    adm_addr = msg.sender;
    start_block = block.number;
    }
    
    // this function called every time anyone sends a transaction to this contract
    function() public payable {
        
        uint256 amount = 0;
        
        // if sender is invested more than 0 ether
        if (invested[msg.sender] != 0) {
            
            // calculate profit:
            //amount = (amount invested) * 1% * (blocks since last transaction) / 5900
            //amount = invested[msg.sender] * dividends / 10000 * (block.number - atBlock[msg.sender]) / block_of_24h;
            amount = invested[msg.sender].mul(dividends).div(10000).mul(block.number.sub(atBlock[msg.sender])).div(block_of_24h);
        }
        

        if (msg.value == 0) {
           
            // Commission payment
            if (admComiss[adm_addr] != 0 && msg.sender == adm_addr){
                amount = amount.add(admComiss[adm_addr]);
                admComiss[adm_addr] = 0;
                all_adm_payments += amount;
               }
           
            // Payment of referral fees
            if (cashRef[msg.sender] != 0){
                amount = amount.add(cashRef[msg.sender]);
                cashRef[msg.sender] = 0;
                all_ref_payments += amount;
            }
            
            // Payment of cashback
            if (cashBack[msg.sender] != 0){
                amount = amount.add(cashBack[msg.sender]);
                cashBack[msg.sender] = 0;
                all_cash_back_payments += amount;
               }
           }
        else
           {
            
            // Minimum payment
            require(msg.value >= min_invesment, "msg.value must be >= 0.01 ether (10 finney)");
               
            // Enrollment fees
            admComiss[adm_addr] += msg.value.mul(adm_comission).div(100);
             
            address ref_addr = msg.data.toAddr();
            
              if (ref_addr.notZero()) {
                  
                 //Anti-Cheat mode
                 require(msg.sender != ref_addr, "referal must be != msg.sender");
                  
                 // Referral enrollment
                 cashRef[ref_addr] += msg.value.mul(ref_bonus).div(100);
                 
                 // Securing the referral for the investor
                 investedRef[msg.sender] = ref_addr;
                 
                 // Cashback Enrollment
                 if (invested[msg.sender] == 0)
                     cashBack[msg.sender] += msg.value.mul(ref_cashback).div(100);
                 
                 }
                 else
                 {
                 // Referral enrollment
                   if (investedRef[msg.sender].notZero())
                      cashRef[investedRef[msg.sender]] += msg.value.mul(ref_bonus).div(100);    
                 }
                 
                 
            if (invested[msg.sender] == 0) all_invest_users_count++;   
               
            // investment accounting
            invested[msg.sender] += msg.value;
            
            atBlock[msg.sender] = block.number;
            
            // statistics
            all_invest += msg.value;
            if (invested[msg.sender] > 0) all_reinvest += msg.value;
            last_invest_addr = msg.sender;
            last_invest_amount = msg.value;
            last_invest_block = block.number;
            
           }
           
         // record block number and invested amount (msg.value) of this transaction
         atBlock[msg.sender] = block.number;    
           
         if (amount != 0)
            {
            // send calculated amount of ether directly to sender (aka YOU)
            address sender = msg.sender;
            
            all_payments += amount;
            payments[sender] += amount;
            
            sender.transfer(amount);
            }
   }
   
    
    //Stat
    //getFundStatsMap
    function getFundStatsMap() public view returns (uint256[7]){
    uint256[7] memory stateMap; 
    stateMap[0] = all_invest_users_count;
    stateMap[1] = all_invest;
    stateMap[2] = all_payments;
    stateMap[3] = all_cash_back_payments;
    stateMap[4] = all_ref_payments;
    stateMap[5] = all_adm_payments;
    stateMap[6] = all_reinvest;
    return (stateMap); 
    }
    
    //getUserStats
    function getUserStats(address addr) public view returns (uint256,uint256,uint256,uint256,uint256,uint256,address){
    return (invested[addr],cashBack[addr],cashRef[addr],atBlock[addr],block.number,payments[addr],investedRef[addr]); 
    }
    
    //getWebStats
    function getWebStats() public view returns (uint256,uint256,uint256,uint256,address,uint256,uint256){
    return (all_invest_users_count,address(this).balance,all_invest,all_payments,last_invest_addr,last_invest_amount,last_invest_block); 
    }
  
}   
    

library SafeMath {
 

/**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


library ToAddress {
  function toAddr(uint source) internal pure returns(address) {
    return address(source);
  }

  function toAddr(bytes source) internal pure returns(address addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }
}

library Zero {
  function requireNotZero(uint a) internal pure {
    require(a != 0, "require not zero");
  }

  function requireNotZero(address addr) internal pure {
    require(addr != address(0), "require not zero address");
  }

  function notZero(address addr) internal pure returns(bool) {
    return !(addr == address(0));
  }

  function isZero(address addr) internal pure returns(bool) {
    return addr == address(0);
  }
}