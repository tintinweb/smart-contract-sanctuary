//SourceUnit: LotteryEffect2.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;
import "SafeMath.sol";
contract LotteryEffect2{
    using SafeMath for uint256;
    address payable public  owner;
    address payable public  dev;
    bool public isPaused;
    uint256 private idTicket;
    uint256 ticketsSoldCurrently;
    uint256 ticketsSold;
    string message;
    uint256 public totalRewardPaid;
    uint256 public price_ticket;
    
    struct Winner {
        uint256 ticket;
        uint256 date;
        uint256 amount;
    }
    
    struct TicketSold{
        address payable player;
        uint256 date;
    }
    
    mapping(uint256=>TicketSold) public tickets;
    mapping(uint256=>Winner) public winners;
    uint256 public winersCount;
    
    event BuyTicket(address _player, uint256 _ticket);
    event SelectedWinner(address _wine,uint256 _ticket, uint256 _date, uint256 _amount);
    
    modifier onlyOwner{
        require(msg.sender==owner,"only owner");
        _;
    }
    modifier playIsPaused{
        require(!isPaused, "play is paused");
        _;
    }
    
    constructor(address payable owner_, address payable dev_) public {
        isPaused = false;
        owner =owner_;
        dev = dev_;
        idTicket=1;
        message='Error Value ticket';
        price_ticket=10 trx ;
    }
    function setPriceTicket( uint256 price)  external onlyOwner payable returns(bool){
        price_ticket=price;
        return true;
    }
    
    function getPriceTicket() external view returns(uint256){
        return price_ticket;
    }
    
    function buyTicketToAddress(address payable _address) external payable playIsPaused returns(uint256){
        require(msg.value == price_ticket,message);
        return ticketHandler(_address);
    }
    
    function buyMultiTicketToAddress(address payable _address,uint256 numberOfTickets) external payable playIsPaused returns(uint256[] memory){ 
        uint256 check = msg.value.div(numberOfTickets);
        require(check == price_ticket,message);
        uint256[] memory purchasedTickets = new uint256[](numberOfTickets);
        for(uint256 i = 0; i < numberOfTickets;i++ ){
            purchasedTickets[i]=ticketHandler(_address);
            }
        return purchasedTickets;
    }
    function buyTicket() public payable playIsPaused returns(uint256){
        require(msg.value == price_ticket,message);
        return ticketHandler(msg.sender);
    }
    
    function buyMultiTicket(uint256 numberOfTickets) public payable playIsPaused returns(uint256[] memory){            
        uint256 check = msg.value.div(numberOfTickets);
        require(check == price_ticket, message);
        uint256[] memory purchasedTickets = new uint256[](numberOfTickets);
        for(uint256 i = 0; i < numberOfTickets;i++ ){
            purchasedTickets[i]=ticketHandler(msg.sender);
            }
        return purchasedTickets;
    }
    
    function ticketHandler(address payable  _address) internal playIsPaused returns(uint256) {
        uint256 _ticketSold;
        ticketsSoldCurrently++;
        ticketsSold++;
        idTicket++;
        TicketSold memory ticket_;
        ticket_.player = _address;
        ticket_.date = block.timestamp;
        tickets[idTicket]=ticket_;
        emit BuyTicket(_address,idTicket);
        _ticketSold=idTicket;
        return _ticketSold;
    }
    
    function selectWinner(uint256 randomSeed) public payable onlyOwner returns(uint256){
        uint256 _amount=getJackpot();
        require(_amount !=0,"empty Jackpot");
        isPaused =true;
        uint256 ramdom = uint256(keccak256(abi.encodePacked(now,randomSeed))) % ticketsSoldCurrently;
        uint256 ticketWiner =ticketsSold.sub(ticketsSoldCurrently).add(ramdom);
        address payable _winer =tickets[ticketWiner].player;
        totalRewardPaid=totalRewardPaid.add(_amount);
        _winer.transfer(_amount);
        owner.transfer(_amount.div(2));
        dev.transfer(address(this).balance);
        Winner memory currentWiner;
        currentWiner.ticket=ticketWiner;
        currentWiner.date=block.timestamp;
        currentWiner.amount = _amount;
        winners[winersCount]=currentWiner;
        winersCount++;
        delete ticketsSoldCurrently;
        emit SelectedWinner(_winer,ticketWiner,now,_amount);
        isPaused =false;
        return ticketWiner;
    }
    
    function getJackpot() public view returns(uint256){
        return (address(this).balance).div(2);
    }
    function lastWinner() public view returns(address  player_, uint256 amount_, uint256 date_){
        Winner memory lastWinner_;
        lastWinner_ =winners[winersCount.sub(1)];
        player_ =tickets[lastWinner_.ticket].player;
        amount_ = lastWinner_.amount;
        date_ = lastWinner_.date;
    }
    
    
    function lastPlayers() public view returns(address[] memory){
        uint256 init = ticketsSold.sub(ticketsSoldCurrently);
        address[] memory players = new address[](ticketsSoldCurrently);
        for(uint i= 0; i< ticketsSoldCurrently;i++){
            players[i]=tickets[init.add(i)].player;
        }
        return players;
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