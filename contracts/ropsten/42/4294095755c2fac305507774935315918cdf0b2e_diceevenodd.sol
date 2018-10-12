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

    // Participant even Address
    participant[] public participant_evens;
    uint256 index_even;

    // flag for game status 0:stop 1:run 2:result
    uint256 public gamestatus = 0;

    // flag for game  0~6
    uint256 public gameResult_num = 0;

    // flag for game  0:even 1:odd
    uint256 public gameResult = 0;

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

    event EchangeGameEnable(uint256 _gameenable);

    event EchangeTicketFee(uint256 _ticketfee);

    event EchangeTicketCap(uint256 _ticketcap);

    event EchangeTickPrice(uint256 _ticketprice);

    event Eaddjoinlist_odd(address indexed _beneficiary, uint256 indexed _value);

    event Eaddjoinlist_even(address indexed _beneficiary, uint256 indexed _value);


    constructor(address _wallet, uint256 _ticketprice, uint256 _ticketcap, uint256 _ticketfee, uint256 _gameenable) public {
        require(_wallet != address(0));

        ticketprice = _ticketprice;
        ticketcap = _ticketcap;
        wallet = _wallet;
        ticketfee = _ticketfee;
        gameenable = _gameenable;
        index_odd = 0;
        index_even = 0;
    }

    function joingames(uint256 _oddeven) public payable {

        uint256 weiAmount = msg.value;
        address _beneficiary = msg.sender;

        uint256 tickets = 0;

        require(gameenable > 0);
        require(_beneficiary != address(0));
        require(weiAmount >= uint256(0));
        require(weiAmount >= ticketprice);

        // calculate token amount to be created
        tickets = calticket(weiAmount);

        if((_oddeven % uint256(2)) == uint256(1))
        {
            addjoinlist_odd(_beneficiary, tickets);
            index_odd = index_odd.add(uint256(1));
        }
        else
        {
            addjoinlist_even(_beneficiary, tickets);
            index_even = index_even.add(uint256(1));
        }
    }

    function calticket(uint256 _weiAmount) internal view returns(uint256){
        uint256 tickets = 0;
        tickets = _weiAmount/ticketprice;
        return (tickets);
    }

    function getvaluejoinlist_odd(uint256 _index_odd) public view returns(address, uint256){
        return (participant_odds[_index_odd].addr, participant_odds[_index_odd].ticket);
    }
    
    function addjoinlist_odd(address _beneficiary, uint256 _value) public {
        participant memory participant_odd = participant(_beneficiary, _value);       
        participant_odds.push(participant_odd);

        emit Eaddjoinlist_odd(_beneficiary, _value);
    }

    function getvaluejoinlist_even(uint256 _index_even) public view returns(address, uint256){
        return (participant_evens[_index_even].addr, participant_evens[_index_even].ticket);
    }
    
    function addjoinlist_even(address _beneficiary, uint256 _value) public {
        participant memory participant_even = participant(_beneficiary, _value);       
        participant_evens.push(participant_even);

        emit Eaddjoinlist_even(_beneficiary, _value);
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

    function deleteThisContract() public onlyOwner {        
        selfdestruct(OwnerAddress());
    }

}