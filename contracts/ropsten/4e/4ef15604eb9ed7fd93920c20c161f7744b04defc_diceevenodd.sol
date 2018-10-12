pragma solidity ^0.4.25;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public Publisher;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public{
        owner = msg.sender;
        Publisher = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
    * @dev return Owner address.
    */

    function OwnerAddress() public view returns(address){
        return owner;
    }
}


contract diceevenodd is Ownable{
    using SafeMath for uint256;

    struct participant{
        address addr;
        uint256 ticket;
    }

    // Address where funds are collected
    address public wallet;

    // Participant odd Address
    participant[] public participant_odds;
    uint256 index_odd;
    uint256 total_odd;

    // Participant even Address
    participant[] public participant_evens;
    uint256 index_even;
    uint256 total_even;

    // flag for game status 0:stop 1:run 2:result_wait
    uint256 public gamestatus;

    //10min 1:5sec
    uint256 public gameruningblock; 
    //10min 1:5sec
    uint256 public gamestartblock; 

    // flag for game  1~6
    uint256 public gameResult_num;

    // flag for game  0:even 1:odd
    uint256 public gameResult;

    // max game fee
    uint256 public ticketfee;    

    // ticketprice
    uint256 public ticketprice;

    // max game ticket
    uint256 public ticketcap;

    // max game joineven
    uint256 public joineven;

    // max game joinodd
    uint256 public joinodd;    

    // game enable
    uint256 public gameenable;
        
    event EchangeGameRuningblock(uint256 _gameruningblock);

    event EchangeGameEnable(uint256 _gameenable);

    event EchangeTicketFee(uint256 _ticketfee);

    event EchangeTicketCap(uint256 _ticketcap);

    event EchangeTickPrice(uint256 _ticketprice);

    event Eaddjoinlist_odd(address indexed _beneficiary, uint256 indexed _value);

    event Eaddjoinlist_even(address indexed _beneficiary, uint256 indexed _value);

    event ETotalOdd(uint256 _total_odd);
    event ETotalEven(uint256 _total_even);

    event EGameReuslt(uint256 _gameResult_num, uint256 _gameResult);
    event EGameStatus(uint256 _gamestatus);

    event Eout(address indexed outaddress, uint256 outvalue);

    constructor(address _wallet, uint256 _ticketprice, uint256 _ticketcap, uint256 _ticketfee, uint256 _gameenable) public {
        require(_wallet != address(0));

        ticketprice = _ticketprice;
        ticketcap = _ticketcap;
        wallet = _wallet;
        ticketfee = _ticketfee;
        gameenable = _gameenable;
        index_odd = 0;
        index_even = 0;
        total_odd = 0;
        total_even = 0;
        gameruningblock = 120;
        gamestatus = 0;
        gameResult_num = 0;
        gameResult = 0;
    }

    function () payable public{
        start();
    }
    
    function start() public payable {
        uint256 weiAmount = msg.value;
        address _beneficiary = msg.sender;
        uint256 tickets = 0;
        uint256 _oddeven = uint256(msg.data[0]);

        require(gameenable > 0);
        require(_beneficiary != address(0));
        require(weiAmount >= uint256(0));
        require(weiAmount >= ticketprice);


        if(gamestatus == 0) //최초 입금시 시작
        {
            gamestatus = 1;
            gamestartblock = block.number;
            gameResult_num = 0;
            gameResult = 0;            
        }



        // calculate token amount to be created
        tickets = calticket(weiAmount);

        if((_oddeven % uint256(2)) == uint256(1))
        {
            require(total_odd.add(tickets) < ticketcap);
            addjoinlist_odd(_beneficiary, tickets);
            total_odd = total_odd.add(tickets);
            emit ETotalOdd(total_odd);
        }
        else
        {
            require(total_even.add(tickets) < ticketcap);
            addjoinlist_even(_beneficiary, tickets);
            total_even = total_even.add(tickets);
            emit ETotalEven(total_odd);
        }

//        _forwardFunds();
    }

    function calticket(uint256 _weiAmount) internal view returns(uint256){
        uint256 tickets = 0;
        tickets = _weiAmount/ticketprice;
        return (tickets);
    }
    
    function addjoinlist_odd(address _beneficiary, uint256 _value) public {
        participant memory participant_odd = participant(_beneficiary, _value);       
        participant_odds.push(participant_odd);
        index_odd = index_odd.add(uint256(1));
        emit Eaddjoinlist_odd(_beneficiary, _value);
    }

    function addjoinlist_even(address _beneficiary, uint256 _value) public {
        participant memory participant_even = participant(_beneficiary, _value);       
        participant_evens.push(participant_even);
        index_even = index_even.add(uint256(1));
        emit Eaddjoinlist_even(_beneficiary, _value);
    }

    function check_result() public payable{
        participant memory tempuser;
        uint256 returnsvalue = 0;
        uint256 i = 0;

        require(block.number >= gameruningblock.add(gamestartblock));
        require(gamestatus == 1);
        require(index_even > 0 || index_odd > 0);

        gamestatus = 0; //stop
        gameResult_num = 0;
        gameResult = 0;

        gameResult_num = random();
        gameResult = gameResult % 2;

        uint256 total_value = total_odd.add(total_even).mul(ticketprice) - total_odd.add(total_even).mul(ticketfee);


        //divider value
        if(gameResult == 0) //even
        {
            for(i = 0;i < index_even;i = i.add(uint256(1)))
            {
                tempuser = participant_evens[i];

                //(( (((홀티켓+짝티켓) * 티켓값) - ((홀티켓+짝티켓) * 수수료값)) / 승리티켓 ) * 내 티켓)
                returnsvalue = total_value.div(total_even).mul(tempuser.ticket);
                tempuser.addr.transfer(returnsvalue);
                emit Eout(tempuser.addr, returnsvalue);
            }
        }
        else
        {
            for(i = 0;i < index_odd;i = i.add(uint256(1)))
            {
                tempuser = participant_odds[i];

                //(( (((홀티켓+짝티켓) * 티켓값) - ((홀티켓+짝티켓) * 수수료값)) / 승리티켓 ) * 내 티켓)
                returnsvalue = total_value.div(total_odd).mul(tempuser.ticket);
                tempuser.addr.transfer(returnsvalue);
                returnsvalue = total_value.div(total_odd).mul(tempuser.ticket);
                emit Eout(tempuser.addr, returnsvalue);
            }
        }

        //pay back bounus for check games 5%
        total_value = total_odd.add(total_even).mul(ticketfee);
        msg.sender.transfer(total_value.div(100).mul(5));
        //remaining value send wallet 5%is reserved
        wallet.transfer(total_value.div(100).mul(90));        
        gamestatus = uint256(0); //start again

        /////////////////////////reset game///////////////////////////////////////////////////////////////
        delete participant_odds;
        delete participant_evens;
        index_odd = 0;
        index_even = 0;
        total_odd = 0;
        total_even = 0;
        gamestatus = 0;

        emit EGameStatus(gamestatus);
        emit EGameReuslt(gameResult_num, gameResult);
    }

    function random() internal view returns (uint256) {
        require(block.number >= gameruningblock.add(gamestartblock));
        return uint256(uint256(blockhash(uint(gameruningblock.add(gamestartblock)))) % 6)+1; //1~6
    }

    function changeTickPrice(uint256 _ticketprice) public onlyOwner {        
        ticketprice = _ticketprice;
        emit EchangeTickPrice(ticketprice);
    }

    function changeTicketCap(uint256 _ticketcap) public onlyOwner {        
        ticketcap = _ticketcap;
        emit EchangeTicketCap(ticketcap);
    }

    function changeTicketFee(uint256 _ticketfee) public onlyOwner {        
        ticketfee = _ticketfee;
        emit EchangeTicketFee(ticketfee);
    }

    function changeGameEnable(uint256 _gameenable) public onlyOwner {        
        gameenable = _gameenable;
        emit EchangeGameEnable(gameenable);
    }    

    function changeGameRuningblock(uint256 _gameruningblock) public onlyOwner {        
        gameruningblock = _gameruningblock;
        emit EchangeGameRuningblock(_gameruningblock);
    }    

    function refundsall() public onlyOwner {        
        wallet.transfer(address(this).balance);
    }

    function deleteThisContract() public onlyOwner {        
        selfdestruct(OwnerAddress());
    }

}