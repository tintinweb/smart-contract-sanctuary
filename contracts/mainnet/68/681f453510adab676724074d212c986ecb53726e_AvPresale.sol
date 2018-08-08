pragma solidity ^0.4.17;

/// @author developers //NB!
/// @notice <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f784828787988583b7939281929b9887928584">[email&#160;protected]</a> //NB!
/// @title  Contract presale //NB!

contract AvPresale {

    string public constant RELEASE = "0.2.3_AviaTest";

    //config// 
    uint public constant PRESALE_START  = 5307620; /* 23.03.2018 17:19:00 +3GMT */ //NB!
    uint public constant PRESALE_END    = 5314027; /* 24.03.2018 20:00:00 +3GMT */ //NB!
    uint public constant WITHDRAWAL_END = 5314987; /* 25.03.2018 00:00:00 +3GMT */ //NB!

    address public constant OWNER = 0x32Bac79f4B6395DEa37f0c2B68b6e26ce24a59EA; //NB!

    uint public constant MIN_TOTAL_AMOUNT_GET_ETH = 1; //NB!
    uint public constant MAX_TOTAL_AMOUNT_GET_ETH = 2; //NB!
	//min send value 0.001 ETH (1 finney)
    uint public constant MIN_GET_AMOUNT_FINNEY = 10; //NB!

    string[5] private standingNames = ["BEFORE_START",  "PRESALE_RUNNING", "WITHDRAWAL_RUNNING", "MONEY_BACK_RUNNING", "CLOSED" ];
    enum State { BEFORE_START,  PRESALE_RUNNING, WITHDRAWAL_RUNNING, MONEY_BACK_RUNNING, CLOSED }

    uint public total_amount = 0;
    uint public total_money_back = 0;
    mapping (address => uint) public balances;

    uint private constant MIN_TOTAL_AMOUNT_GET = MIN_TOTAL_AMOUNT_GET_ETH * 1 ether;
    uint private constant MAX_TOTAL_AMOUNT_GET = MAX_TOTAL_AMOUNT_GET_ETH * 1 ether;
    uint private constant MIN_GET_AMOUNT = MIN_GET_AMOUNT_FINNEY * 1 finney;
    bool public isTerminated = false;
    bool public isStopped = false;


    function AvPresale () public checkSettings() { }


    //methods//
	
	//The transfer of money to the owner
    function sendMoneyOwner() external
	inStanding(State.WITHDRAWAL_RUNNING)
    onlyOwner
    noReentrancy
    {
        OWNER.transfer(this.balance);
    }
	
	//Money back to users
    function moneyBack() external
    inStanding(State.MONEY_BACK_RUNNING)
    noReentrancy
    {
        sendMoneyBack();
    }
	
    //payments
    function ()
    payable
    noReentrancy
    public
    {
        State state = currentStanding();
        if (state == State.PRESALE_RUNNING) {
            getMoney();
        } else if (state == State.MONEY_BACK_RUNNING) {
            sendMoneyBack();
        } else {
            revert();
        }
    }

    //Forced termination
    function termination() external
    inStandingBefore(State.MONEY_BACK_RUNNING)
    onlyOwner
    {
        isTerminated = true;
    }

    //Forced stop with the possibility of withdrawal
    function stop() external
    inStanding(State.PRESALE_RUNNING)
    onlyOwner
    {
        isStopped = true;
    }


    //Current status of the contract
    function standing() external constant
    returns (string)
    {
        return standingNames[ uint(currentStanding()) ];
    }

    //Method adding money to the user
    function getMoney() private notTooSmallAmountOnly {
      if (total_amount + msg.value > MAX_TOTAL_AMOUNT_GET) {
          var change_to_return = total_amount + msg.value - MAX_TOTAL_AMOUNT_GET;
          var acceptable_remainder = MAX_TOTAL_AMOUNT_GET - total_amount;
          balances[msg.sender] += acceptable_remainder;
          total_amount += acceptable_remainder;
          msg.sender.transfer(change_to_return);
      } else {
          balances[msg.sender] += msg.value;
          total_amount += msg.value;
      }
    }
	
	//Method of repayment users 
    function sendMoneyBack() private tokenHoldersOnly {
        uint amount_to_money_back = min(balances[msg.sender], this.balance - msg.value) ;
        balances[msg.sender] -= amount_to_money_back;
        total_money_back += amount_to_money_back;
        msg.sender.transfer(amount_to_money_back + msg.value);
    }

    //Determining the current status of the contract
    function currentStanding() private constant returns (State) {
        if (isTerminated) {
            return this.balance > 0
                   ? State.MONEY_BACK_RUNNING
                   : State.CLOSED;
        } else if (block.number < PRESALE_START) {
            return State.BEFORE_START;
        } else if (block.number <= PRESALE_END && total_amount < MAX_TOTAL_AMOUNT_GET && !isStopped) {
            return State.PRESALE_RUNNING;
        } else if (this.balance == 0) {
            return State.CLOSED;
        } else if (block.number <= WITHDRAWAL_END && total_amount >= MIN_TOTAL_AMOUNT_GET) {
            return State.WITHDRAWAL_RUNNING;
        } else {
            return State.MONEY_BACK_RUNNING;
        }
    }

    function min(uint a, uint b) pure private returns (uint) {
        return a < b ? a : b;
    }

    //Prohibition if the condition does not match
    modifier inStanding(State state) {
        require(state == currentStanding());
        _;
    }

    //Prohibition if the current state was not before
    modifier inStandingBefore(State state) {
        require(currentStanding() < state);
        _;
    }

    //Works on users&#39;s command
    modifier tokenHoldersOnly(){
        require(balances[msg.sender] > 0);
        _;
    }

    //Do not accept transactions with a sum less than the configuration limit
    modifier notTooSmallAmountOnly(){
        require(msg.value >= MIN_GET_AMOUNT);
        _;
    }

    //Prohibition of repeated treatment
    bool private lock = false;
    modifier noReentrancy() {
        require(!lock);
        lock = true;
        _;
        lock = false;
    }
	
	 //Prohibition if it does not match the settings
    modifier checkSettings() {
        if ( OWNER == 0x0
            || PRESALE_START == 0
            || PRESALE_END == 0
            || WITHDRAWAL_END ==0
            || PRESALE_START <= block.number
            || PRESALE_START >= PRESALE_END
            || PRESALE_END   >= WITHDRAWAL_END
            || MIN_TOTAL_AMOUNT_GET > MAX_TOTAL_AMOUNT_GET )
                revert();
        _;
    }
	
	//Works on owner&#39;s command
    modifier onlyOwner(){
        require(msg.sender == OWNER);
        _;
    }
}