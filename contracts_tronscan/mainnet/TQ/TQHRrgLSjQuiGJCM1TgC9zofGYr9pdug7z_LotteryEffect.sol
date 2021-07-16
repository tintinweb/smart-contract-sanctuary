//SourceUnit: LotteryEffect.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;
import "./SafeMath.sol";
contract LotteryEffect{
    using SafeMath for uint256;
    uint256 constant public PRICE_TICKET = 5 trx;
    address payable public  owner;
    bool public isPaused;
    uint256 private idTicket;
    uint256[] public ticketsSoldCurrently;
    uint256[] public ticketsSold;
    string message;
    
    uint256 public totalRewardPaid;
    
    struct Winers {
        address player;
        uint256 ticket;
        uint256 date;
        uint256 amount;
    }
    
    struct TicketSold{
        address payable player;
        uint256 date;
    }
    
    mapping(uint256=>TicketSold) public tickets;
    
    Winers[] public winers;
    uint256[] public latestWinners;
    address payable public lastwinner;
    
    event BuyTicket(address _player, uint256 _ticket);
    event SelectWinner(address _wine);
    event Winner(address _wine,uint256 _ticket, uint256 _date, uint256 _amount);
    
    
    modifier onlyOwner{
        require(msg.sender==owner,"only owner");
        _;
    }
    modifier playIsPaused{
        require(!isPaused, "play is paused");
        _;
    }
    
    constructor(string memory _msg) public {
        isPaused = false;
        owner=msg.sender;
        idTicket=1;
        message=_msg;
    }
    function getPriceTicket() external pure returns(uint256){
        return PRICE_TICKET;
    }
    
    function buyTicketToAddress(address payable _address) external payable playIsPaused returns(uint256){            
        require(msg.value == PRICE_TICKET,message);
        return ticketHandler(_address);
    }
    
    function buyMultiTicketToAddress(address payable _address,uint256 numberOfTickets) external payable playIsPaused returns(uint256){            
        uint256 check = msg.value.div(numberOfTickets);
        require(check == PRICE_TICKET,message);
        for(uint256 i = 0; i < numberOfTickets;i++ ){
            ticketHandler(_address);
            }
    }
    function buyTicket() public payable playIsPaused returns(uint256){            
        require(msg.value == PRICE_TICKET,message);
        return ticketHandler(msg.sender);
    }
    
    function buyMultiTicket(uint256 numberOfTickets) public payable playIsPaused{            
        uint256 check = msg.value.div(numberOfTickets);
        require(check == PRICE_TICKET, message);
        for(uint256 i = 0; i < numberOfTickets;i++ ){
            ticketHandler(msg.sender);
            }
    }
    
    function selectWinner(uint256 randomSeed) public payable onlyOwner returns(uint256){
        uint256 _amount=getJackpot();
        require(_amount !=0,"empty Jackpot");
        isPaused =true;
        uint256 ramdom = uint256(keccak256(abi.encodePacked(now,randomSeed,msg.sender))) % ticketsSoldCurrently.length;
        uint256 ticketWiner =ticketsSoldCurrently[ramdom];
        address payable _winer =tickets[ticketWiner].player;
        totalRewardPaid=totalRewardPaid.add(_amount.mul(2));
        _winer.transfer(_amount);
        owner.transfer(address(this).balance);
        winers.push(Winers(_winer,ticketWiner,now,_amount));
        lastwinner=_winer;
        latestWinners.push(ticketWiner);
        delete ticketsSoldCurrently;
        emit Winner(_winer,ticketWiner,now,_amount);
        isPaused =false;
        return ticketWiner;
    }
    
    
    function ticketHandler(address payable  _address) internal playIsPaused returns(uint256) {
        ticketsSoldCurrently.push(idTicket);
        ticketsSold.push(idTicket);
        tickets[idTicket]=TicketSold(_address,block.timestamp);
        emit BuyTicket(_address,idTicket);
        uint256 _ticketSold=idTicket;
        idTicket++;
        return _ticketSold;
    }
    
    function getJackpot() public view returns(uint256){
        return (address(this).balance).div(2);
    } 
    function getJackpotRate() public view returns(uint256){
        return (address(this).balance).div(2).div(1e6);
    } 
    
    function getTicketsSold() public view returns(uint256[] memory){
        return ticketsSold;
    }
    function getLastTicketsSold() public view returns(uint256){
        return ticketsSoldCurrently.length;
    } 
    
    function getTicketsSoldCurrently() public view returns(uint256[] memory){
        return ticketsSoldCurrently;
    }
    function getLatestWinners() public view returns(uint256[] memory){
        return latestWinners;
    }
    
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}