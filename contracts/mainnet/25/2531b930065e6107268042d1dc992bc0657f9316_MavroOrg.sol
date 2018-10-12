pragma solidity 0.4.25;

/**
*
* MAVRO.ORG
*
* YouTube          - https://www.youtube.com/mavroorg
* Telegram_channel - https://t.me/MavroOrg
* Twitter          - https://twitter.com/Sergey_Mavrody
* VK               - https://vk.com/mavro_official
*
*  - GAIN PER 24 HOURS:
*     -- Contract balance  < 200 Ether: 0.7 %
*     -- Contract balance >= 200 Ether: 0.8 %
*     -- Contract balance >= 400 Ether: 0.9 %
*     -- Contract balance >= 600 Ether: 1 %
*     -- Contract balance >= 800 Ether: 1.1 %
*     -- Contract balance >= 1000 Ether: 1.2 %
*  - Life-long payments
*  - Minimal contribution 0.01 eth
*  - Currency and payment - ETH
*  - Contribution allocation schemes:
*    -- 85% payments
*    -- 15% Marketing + Operating Expenses
*
* ---How to use:
*  1. Send from ETH wallet to the smart contract address
*     any amount from 0.01 ETH.
*  2. Verify your transaction in the history of your application or etherscan.io, specifying the address
*     of your wallet.
*  3. Claim your profit by sending 0 ether transaction (every day, every week, i don&#39;t care unless you&#39;re
*      spending too much on GAS)
*
* RECOMMENDED GAS LIMIT: 150000
* RECOMMENDED GAS PRICE: https://ethgasstation.info/
* You can check the payments on the etherscan.io site, in the "Internal Txns" tab of your wallet.
*
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

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library Percent {

  struct percent {
    uint num;
    uint den;
  }
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }
}

contract MavroOrg{

    using SafeMath for uint;
    using Percent for Percent.percent;
    // array containing information about beneficiaries
    mapping (address => uint) public balances;
    //array containing information about the time of payment
    mapping (address => uint) public time;

    //The marks of the balance on the contract after which the percentage of payments will change
    uint step1 = 200;
    uint step2 = 400;
    uint step3 = 600;
    uint step4 = 800;
    uint step5 = 1000;

    //the time through which dividends will be paid
    uint dividendsTime = 1 days;

    event NewInvestor(address indexed investor, uint deposit);
    event PayOffDividends(address indexed investor, uint value);
    event NewDeposit(address indexed investor, uint value);

    uint public allDeposits;
    uint public allPercents;
    uint public allBeneficiaries;
    uint public lastPayment;

    uint public constant minInvesment = 10 finney;

    address public commissionAddr = 0x2eB660298263C5dd82b857EA26360dacd5fbB34d;

    Percent.percent private m_adminPercent = Percent.percent(15, 100);

    /**
     * The modifier checking the positive balance of the beneficiary
    */
    modifier isIssetRecepient(){
        require(balances[msg.sender] > 0, "Deposit not found");
        _;
    }

    /**
     * modifier checking the next payout time
     */
    modifier timeCheck(){
         require(now >= time[msg.sender].add(dividendsTime), "Too fast payout request. The time of payment has not yet come");
         _;
    }

    function getDepositMultiplier()public view returns(uint){
        uint percent = getPercent();

        uint rate = balances[msg.sender].mul(percent).div(10000);

        uint depositMultiplier = now.sub(time[msg.sender]).div(dividendsTime);

        return(rate.mul(depositMultiplier));
    }

    function receivePayment()isIssetRecepient timeCheck private{

        uint depositMultiplier = getDepositMultiplier();
        time[msg.sender] = now;
        msg.sender.transfer(depositMultiplier);

        allPercents+=depositMultiplier;
        lastPayment =now;
        emit PayOffDividends(msg.sender, depositMultiplier);
    }

    /**
     * @return bool
     */
    function authorizationPayment()public view returns(bool){

        if (balances[msg.sender] > 0 && now >= (time[msg.sender].add(dividendsTime))){
            return (true);
        }else{
            return(false);
        }
    }

    /**
     * @return uint percent
     */
    function getPercent() public view returns(uint){

        uint contractBalance = address(this).balance;

        uint balanceStep1 = step1.mul(1 ether);
        uint balanceStep2 = step2.mul(1 ether);
        uint balanceStep3 = step3.mul(1 ether);
        uint balanceStep4 = step4.mul(1 ether);
        uint balanceStep5 = step5.mul(1 ether);

        if(contractBalance < balanceStep1){
            return(70);
        }
        if(contractBalance >= balanceStep1 && contractBalance < balanceStep2){
            return(80);
        }
        if(contractBalance >= balanceStep2 && contractBalance < balanceStep3){
            return(90);
        }
        if(contractBalance >= balanceStep3 && contractBalance < balanceStep4){
            return(100);
        }
        if(contractBalance >= balanceStep4 && contractBalance < balanceStep5){
            return(110);
        }
        if(contractBalance >= balanceStep5){
            return(120);
        }
    }

    function createDeposit() private{

        if(msg.value > 0){

            require(msg.value >= minInvesment, "msg.value must be >= minInvesment");

            if (balances[msg.sender] == 0){
                emit NewInvestor(msg.sender, msg.value);
                allBeneficiaries+=1;
            }

            // commission
            commissionAddr.transfer(m_adminPercent.mul(msg.value));

            if(getDepositMultiplier() > 0 && now >= time[msg.sender].add(dividendsTime) ){
                receivePayment();
            }

            balances[msg.sender] = balances[msg.sender].add(msg.value);
            time[msg.sender] = now;

            allDeposits+=msg.value;
            emit NewDeposit(msg.sender, msg.value);

        }else{
            receivePayment();
        }
    }

    /**
     * function that is launched when transferring money to a contract
     */
    function() external payable{
        createDeposit();
    }
}