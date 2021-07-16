//SourceUnit: IERC20.sol


pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: SafeMath.sol


pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SourceUnit: SmartContractLott.sol


// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
import "./IERC20.sol";
import "./SafeMath.sol";
contract Type {
    IERC20 _token;
    using SafeMath for uint;
    address public _owner;
    address public _manager;
    struct UserTicket{
        uint number;
        uint ticketId;
        uint roundId;
    }
    struct Ticket {
        uint number;
        bool claimed;
        bool isExist;
        address user;
    }
    struct Round {
        uint curr;
        uint blockNumber;
        uint prizePool;
        uint[5] results;
        bool isExist;
        bool state;
        mapping(uint => Ticket) tickets;
    }
    struct User{
        uint balances;
        uint totalTicket;
        uint totalIncome;
        uint totalWin;
        address ref;
        bool isTier1;
        bool isExist;
        mapping(uint => bool) roundState;
        uint[] rounds;
        address[] refs;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    modifier onlyManager() {
        require(_manager == msg.sender, "Manage: caller is not the manager");
        _;
    }
    uint public roundNumber;
    uint public _ticketPrice;
    uint public currTier;
    uint public freeTierPercent; //5%
    uint public tier1Percent; //10%
    uint public realPercent = 85; //85%
    uint public tierBonusPercent = 5; //5%
    uint public prizePlusPercent = 80;
    uint public tier1Prize;
    uint public basePrize;
    uint public nextRoundBlock;
    uint[3] public rewards;
    mapping(address => User) public users;
    mapping(uint => Round) public rounds;
    mapping(uint => address) public tiers;
    
    event BuyTicket(uint indexed round,uint roundId,address indexed user,uint number,address indexed referral);
    event BuyTier(address indexed user,uint indexed amount);
    event Result(uint indexed round,uint indexed ticketSold,uint blockNumber,uint prizePool,uint indexed rawNumber,uint jackpot,uint w5,uint w4,uint w3);
    event ClaimRewards(uint indexed round,uint roundId,address indexed user,address indexed referral,uint amount,uint tier);
    event Withdrawal(address indexed user,uint indexed amount);
    //cat: 0 buyticket, 1 claimreward, 2 withdrawal
    event Referral(address indexed referral, uint indexed amount,uint indexed cat,address owner);
    event BuyTickets(address indexed user,uint indexed amount);
}
contract SmartContractLott is Type {
    constructor(
        address token,
        address owner,
        address manager
    ) public {
        _token = IERC20(token);
        roundNumber = 1;
        nextRoundBlock = 86400;
        rounds[1].blockNumber = block.number + nextRoundBlock;
        rounds[1].isExist = true;
        _ticketPrice = fakeNumber(1);
        freeTierPercent = 5; //5%
        tier1Percent = 10; //10%
        tier1Prize = fakeNumber(50);
        basePrize = fakeNumber(10000);
        rewards[0] = fakeNumber(3);
        rewards[1] = fakeNumber(30);
        rewards[2] = fakeNumber(100);
        _owner = owner;
        _manager = manager;
    }

    function getPercent(uint number,uint percent) pure public returns(uint) {
        uint result = number.mul(percent).div(100);
        return result;
    }
    function fakeNumber(uint number) pure public returns(uint){
        return number.mul(1000000);
    }
    function realNumber(uint number) pure public returns(uint){
        return number.div(1000000);
    }
    function ownerWithdrawal() public onlyOwner {
        uint balance;
        balance = _token.balanceOf(address(this));
        require(balance > 0,"Need balance");
        _token.transfer(_owner,balance);
    } 
    function ownerChangeManager(address manager) public onlyOwner {
        _manager = manager;
    }
    function ownerChangeOwner(address owner) public onlyOwner {
        _owner = owner;
    }
    function ownerChangeTicketPrice(uint price) public onlyOwner {
        _ticketPrice = fakeNumber(price);
    }
    function ownerChangeFreeReferralpercent(uint percent) public onlyOwner {
        freeTierPercent = percent;
    }
    function ownerChangePaidReferralPercent (uint percent) public onlyOwner {
        tier1Percent = percent;        
    }
    function ownerChangeRoundBlockNumber (uint blockNumber) public onlyOwner {
        nextRoundBlock = blockNumber;
    }
    function ownerChangePaidReferralPrice (uint price) public onlyOwner {
        tier1Prize = fakeNumber(price);
    }
    function ownerChangeBasePrice (uint price) public onlyOwner {
        basePrize = fakeNumber(price);
    }
    function ownerChangeRewards(uint[3] memory _rewards) public onlyOwner {
        rewards[0] = fakeNumber(_rewards[0]);
        rewards[1] = fakeNumber(_rewards[1]);
        rewards[2] = fakeNumber(_rewards[2]);         
    }
    function setResult(uint roundId,uint[5] memory results,uint blockNumber,uint rawNumber) public onlyManager {
        Round storage round = rounds[roundId];
        require(block.number > round.blockNumber,"Time not end");
        require(round.isExist && !round.state,"Require opening round");
        require(blockNumber >= round.blockNumber);
        uint prizePool;
        uint prizeSale = _ticketPrice*round.curr;
        round.results = results;
        round.state = true;
        roundNumber++;
        rounds[roundNumber].blockNumber = block.number + nextRoundBlock;
        rounds[roundNumber].isExist = true;
        if (results[1] == 0) {
            prizePool = results[2]*rewards[2] + results[3]*rewards[1] + results[4]*rewards[0];
            
            round.prizePool = prizePool;
            basePrize += prizeSale > prizePool ? getPercent(prizeSale - prizePool, prizePlusPercent) : 0;
        } else {
            prizePool = basePrize + prizeSale;
            round.prizePool = prizePool;
            basePrize = fakeNumber(10000);
        }
        emit Result(roundId,round.curr,blockNumber,prizePool,rawNumber,results[1],results[2],results[3],results[4]);
    }

    function buyTickets(uint[] memory tickets,address referral) public {
        uint length = tickets.length;
        uint roundId = roundNumber;
        Round storage round = rounds[roundId];
        uint curr = round.curr;
        User memory user = users[msg.sender];
        address ref = referral == msg.sender ? address(0) : referral;
        if (user.isExist){
            ref = user.ref;
        }
        require(tickets.length > 0,"Ticket empty");
        require(round.blockNumber > block.number,"Lottery period closed.");
        for (uint i = 0; i < length; i++){
            checkTicket(tickets[i]);
            curr++;
            round.tickets[curr]= Ticket(tickets[i],false,true,msg.sender);
            emit BuyTicket(roundNumber,curr,msg.sender,tickets[i],ref);
        }
        round.curr = curr;
        uint256 allowance = _token.allowance(msg.sender,address(this));
        uint256 amount = length * _ticketPrice;
        require(allowance >= amount,"Must allow transfer token");
        _token.transferFrom(msg.sender, address(this), amount);
        User storage referralUser = users[ref];
        uint bonus = referralUser.isTier1 ? tier1Percent : freeTierPercent;
        emit BuyTickets(msg.sender,amount);
        if ( ref != address(0)){
            emit Referral(ref,getPercent(amount,bonus),0,msg.sender);
        }
        referralUser.balances += getPercent(amount,bonus);
        referralUser.totalIncome += getPercent(amount,bonus);
        if (!user.isExist){
            users[msg.sender].ref = ref;
            users[msg.sender].isExist = true;
            users[ref].refs.push(msg.sender);
            // User memory newUser;
            // newUser = User({
            //     balances: 0,
            //     totalTicket: 0,
            //     totalIncome: 0,
            //     totalWin: 0,
            //     ref: ref,
            //     isTier1: false,
            //     isExist: true,
            //     rounds: new uint[](0)
            // });
            // users[msg.sender] = newUser;
        }
        users[msg.sender].totalTicket += amount;
        if (!users[msg.sender].roundState[roundId]){
            users[msg.sender].roundState[roundId] = true;
            users[msg.sender].rounds.push(roundId);
        }

    }
    function buyTier() public {
        User storage user = users[msg.sender];
        require(!user.isTier1,"Is buying");
        uint amount = tier1Prize;
        uint allowance = _token.allowance(msg.sender,address(this));
        require(allowance >= amount,"Must allow transfer token");
        _token.transferFrom(msg.sender,address(this),amount);
        user.isTier1 = true;
        tiers[currTier++] = msg.sender;
        emit BuyTier(msg.sender,amount);
    }
    function checkTicket(uint256 number) internal pure {
        uint256 n0 = (number >> 40) & 0xff;
        uint256 n1 = (number >> 32) & 0xff;
        uint256 n2 = (number >> 24) & 0xff;
        uint256 n3 = (number >> 16) & 0xff;
        uint256 n4 = (number >> 8) & 0xff;
        uint256 n5 = (number >> 0) & 0xff;
        require(n5 <= 45, "invalid number");
        require(n5 > n4, "invalid number");
        require(n4 > n3, "invalid number");
        require(n3 > n2, "invalid number");
        require(n2 > n1, "invalid number");
        require(n1 > n0, "invalid number");
        require(n0 >= 1, "invalid number");
    }
    function getPrizeLevel(uint256 number, uint[6] memory result) pure public returns (uint256) {
        uint256 hit = 0;
        uint256 n0 = result[0];
        uint256 n1 = result[1];
        uint256 n2 = result[2];
        uint256 n3 = result[3];
        uint256 n4 = result[4];
        uint256 n5 = result[5];
        for (uint256 i = 0; i <= 40; i += 8) {
            uint256 n = (number >> i) & 0xff;
            if (n < n3) {
                if (n == n0 || n == n1 || n == n2) {
                    ++hit;
                }
            } else {
                if (n == n3 || n == n4 || n == n5) {
                    ++hit;
                }
            }
        }
        if (hit < 3) {
            return 0;
        }
        return hit;
    }
    function claimReward(uint[] memory tickets) public {
        uint length = tickets.length;
        Round storage round = rounds[tickets[0]];
        uint[6] memory result = decodeNumberUint(round.results[0]);
        require(length >= 2,"Invalid tickets input");
        require(round.isExist && round.state,"Invalid round");
        uint prizes;
        address userReferral = users[msg.sender].ref;
        for (uint i = 1; i < length;i++){
            Ticket memory ticket = round.tickets[tickets[i]];
            if (!ticket.isExist || ticket.claimed){
                continue;
            }
            require(ticket.user == msg.sender,"Invalid user sender");
            uint count = getPrizeLevel(ticket.number,result);
            if (count == 0){
                continue;
            }
            uint prize;
            if (count == 6){
                uint jackpot = round.prizePool.div(round.results[1]);
                prize = getPercent(jackpot,realPercent);
                uint getTierBonus = getPercent(jackpot,tierBonusPercent);
                if (currTier > 0){
                    uint tier1Bonus = getTierBonus.div(currTier);
                    for (uint j = 0; j < currTier;j++){
                        emit Referral(tiers[j],tier1Bonus,1,msg.sender);
                        users[tiers[j]].balances += tier1Bonus;
                        users[tiers[j]].totalIncome += tier1Bonus;
                    }
                }
            } else if (count == 3){
                prize = rewards[0];
            } else if (count == 4){
                prize = rewards[1];
            } else if (count == 5){
                prize = rewards[2];
            }
            prizes += prize;
            round.tickets[tickets[i]].claimed = true;
            emit ClaimRewards(tickets[0],tickets[i],ticket.user,userReferral,prize,count);
        }
        users[msg.sender].totalWin += prizes;
        require(prizes > 0,"No rewards");
        uint thisBalance = _token.balanceOf(address(this));
        require(thisBalance >= prizes,"Not balances");
        _token.transfer(msg.sender,prizes);
    }
    function getClaimReward(uint[] memory tickets) view public returns(uint) {
        uint length = tickets.length;
        Round storage round = rounds[tickets[0]];
        uint[6] memory result = decodeNumberUint(round.results[0]);
        require(length >= 2,"Invalid tickets input");
        require(round.isExist && round.state,"Invalid round");
        uint prizes;
        for (uint i = 1; i < length;i++){
            Ticket memory ticket = round.tickets[tickets[i]];
            if (!ticket.isExist || ticket.claimed){
                continue;
            }
            require(ticket.user == msg.sender,"Invalid user sender");
            uint count = getPrizeLevel(ticket.number,result);
            if (count == 0){
                continue;
            }
            uint prize;
            if (count == 6){
                uint jackpot = round.prizePool.div(round.results[1]);
                prize = getPercent(jackpot,realPercent);
            } else if (count == 3){
                prize = rewards[0];
            } else if (count == 4){
                prize = rewards[1];
            } else if (count == 5){
                prize = rewards[2];
            }
            prizes += prize;
        }
        return prizes;
    }
    function userWithdrawal() public {
        uint bl = users[msg.sender].balances;
        require(bl > 0,"Need balances");
        users[msg.sender].balances = 0;      
        emit Withdrawal(msg.sender,bl);
        emit Referral(msg.sender,bl,2,msg.sender);
        _token.transfer(msg.sender,bl);
    }
    function decodeNumberUint(uint number) pure public returns (uint[6] memory){
        uint[6] memory numbers;
        numbers[5] = (number >> 0) & 0xff;
        numbers[4] = (number >> 8) & 0xff;
        numbers[3] = (number >> 16) & 0xff;
        numbers[2] = (number >> 24) & 0xff;
        numbers[1] = (number >> 32) & 0xff;
        numbers[0] = (number >> 40) & 0xff;
        return numbers;
    }
    function getTicketsInRound(uint start,uint end,uint roundId)view public returns(uint[] memory){
        uint c;
        uint realEnd = rounds[roundId].curr >  end ? end : rounds[roundId].curr;
        uint[] memory tickets = new uint[](realEnd-start);
        for (uint i = start+1;i <= realEnd;i++){
            tickets[c++] = rounds[roundId].tickets[i].number;
        }
        return tickets;
    }
    function getUserTicketsInRound(uint start,uint end,uint roundId,address user) view public returns (uint[] memory){
        uint c;
        uint[] memory tickets = new uint[]((end-start)*2);
        for (uint i = start+1;i <= end;i++){
            if (rounds[roundId].tickets[i].user == user){
                tickets[c++] = rounds[roundId].tickets[i].number;
                tickets[c++] = i;
            }
        }
        return tickets;
    }
    function getUserTicketsAndStateInRound(uint start,uint end, uint roundId,address user) view public returns(uint[] memory){
        uint c;
        uint[] memory tickets = new uint[]((end-start)*3);
        for (uint i = start+1;i <= end;i++){
            if (rounds[roundId].tickets[i].user == user){
                tickets[c++] = rounds[roundId].tickets[i].number;
                tickets[c++] = i;
                tickets[c++] = rounds[roundId].tickets[i].claimed == true ? 111 : 101;
            }
        }
        return tickets;
    }
    function getUserRound(address user) view public returns(uint[] memory){
        uint c;
        uint[] memory userRounds = new uint[](users[user].rounds.length);
        for (uint i = 0; i < users[user].rounds.length;i++){
            userRounds[c++] = users[user].rounds[i];
        }
        return userRounds;
    }
    function getRoundResult(uint roundId) view public returns(uint){
        uint result;
        result = rounds[roundId].results[0];
        return result;
    }
    function getAllUserRef(address user) view public returns(address[] memory){
        uint length;
        length = users[user].refs.length;
        address[] memory refs = new address[](length);
        for (uint i = 0; i < length;i++){
            refs[i] = users[user].refs[i];
        }
        return refs;
    }
}