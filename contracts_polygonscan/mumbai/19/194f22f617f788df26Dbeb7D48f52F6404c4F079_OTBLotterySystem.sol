// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './Ownable.sol';
import './OTBLotteryTicketERC20.sol';
import './libraries/SafeMath.sol';
import './libraries/Decimal.sol';

contract OTBLotterySystem is OTBLotteryTicketERC20, Ownable {
    using SafeMath  for uint;
    using Decimal for uint;

    struct Ticket{
        uint8 position1;
        uint8 position2;
        uint8 position3;
        uint8 position4;
    }
    struct RewardRatio {
        uint8 matchAll;
        uint8 match3;
        uint8 match2;
        uint8 match1;
    }
    struct UserData {
        uint round;
        address user;
        Ticket[] tickets;
        uint8[] boughtTickets;
        bool claimed;
        uint reward;
    }
    struct RoundData {
        uint round;
        Ticket winningNumbers;
        uint reward;
        Ticket[] tickets;
        RewardRatio rewardRatio;
        uint8 match1;
        uint8 match2;
        uint8 match3;
        uint8 matchAll;
        bool noMatch;
    }
    address public rewardsToken;

    uint8 public rewardRatio = 4;
    uint public currentRound;
    mapping(uint => RoundData) internal roundHistory;
    mapping(uint => mapping(address=> UserData)) internal userRoundData;
    
    uint internal nonce;

    constructor(address _rewardsTokenAddress) {
        rewardsToken = _rewardsTokenAddress;
        currentRound = 1;
        nonce = 7638264823492;
        roundHistory[currentRound].rewardRatio.matchAll = 50;
        roundHistory[currentRound].rewardRatio.match3 = 30;
        roundHistory[currentRound].rewardRatio.match2 = 15;
        roundHistory[currentRound].rewardRatio.match1 = 5;
    }
    /**
     * @dev show the current round reward.  Return uint. 
     */
    function currentReward() external view returns(uint) {
        return roundHistory[currentRound].reward;
    }
    /**
     * @dev shows array of tickets that are in current round.
     */
    function ticketsInCurrentRound() external view returns(Ticket[] memory) {
        return roundHistory[currentRound].tickets;
    }
    /**
     * @dev This function shows round data by round number
     */
    function getRoundHistory(uint round) external view returns(RoundData memory) {
        return roundHistory[round];
    }
    /**
     * @dev This function calculates rewards & show userdata
     */
    function getUserRoundData(address user, uint round) external view returns(UserData memory) {
        uint totalRewards;
        if(round < currentRound) {
            uint8 matchAll; 
            uint8 match3; 
            uint8 match2; 
            uint8 match1;
            
            (matchAll, match3, match2, match1) = findWinningMatches(userRoundData[round][user].tickets, round);
            totalRewards = calculateTotalRewardsToBeClaimed(matchAll, match3, match2, match1, round);
        }
        UserData memory userData = UserData({
            round: userRoundData[round][user].round,
            user: userRoundData[round][user].user,
            tickets: new Ticket[](0),
            boughtTickets: new uint8[](userRoundData[round][user].tickets.length * 4),
            claimed: userRoundData[round][user].claimed,
            reward: totalRewards
        });
        for(uint8 i=0; i < userRoundData[round][user].tickets.length; i++) {
            userData.boughtTickets[i * 4 + 0] = userRoundData[round][user].tickets[i].position1;
            userData.boughtTickets[i * 4 + 1] = userRoundData[round][user].tickets[i].position2;
            userData.boughtTickets[i * 4 + 2] = userRoundData[round][user].tickets[i].position3;
            userData.boughtTickets[i * 4 + 3] = userRoundData[round][user].tickets[i].position4;
        }
        return userData;
    }
    /**
     * @dev mints OTBTICKET and sends it to the specified address.  
     * This will be used in the DEX contract whenever trades get fulfilled.
     */
    function mintTickets(address user, uint otbLotteryTicketAmount) external {
        require(user != address(0), 'OTBLotterySystem: ZERO_ADDRESS');
        require(otbLotteryTicketAmount > 0, 'OTBLotterySystem: ZERO_AMOUNT');
        _mint(user, otbLotteryTicketAmount);
    }
    /**
     * @dev This function mints OTBTICKET and sends it to the specified address.
     * User then has to pay a cost in OTBC, to purchase the ticket.  
     * The Reward for the current round will increment by the amount of OTBC’s that were sent to the contract.
     * rewardsAmount is being ERC20 token that accepts 18 decimal points so value need to be sent as value * (10 ** 18)
     * OTB Ticket does not support any decimals so based on ratio set it accepts integral value only.
     */
    function buyTickets(address user, uint rewardsAmount) external {
        require(user != address(0), 'OTBLotterySystem: ZERO_ADDRESS');
        require(rewardsAmount > 0, 'OTBLotterySystem: Rewards ZERO_AMOUNT');
        uint otbTicketAmount = (rewardsAmount / (10 ** IERC20(rewardsToken).decimals())) / rewardRatio;
        require(otbTicketAmount > 0, 'OTBLotterySystem: Ticket ZERO_AMOUNT');
        require(IERC20(rewardsToken).transferFrom(user, address(this), rewardsAmount), 
                                    'OTBLotterySystem: User then has to pay a cost in OTBC, to purchase the ticket');
        _mint(user, otbTicketAmount);
        roundHistory[currentRound].reward = roundHistory[currentRound].reward.decimalAddition(rewardsAmount);
    }
    /**
     * @dev user will submit the amount of tickets (OTBTICKETS) and they must have sufficient amount of tickets in their wallet. 
     * This will then create an entry with 4 random numbers between 0 - 9. 
     * Each ticket user submits grants them one entry with 4 different and random numbers between 0 - 9.
     * User can only submit the amount of tickets that is equivalent to the amount of OTBTICKET they have in their wallet.  
     * When user submits ticket(s), OTBTICKETs get burnt in the process.
     */
    function submitTicket(address user, uint amount) external {
        require(amount > 0, 'OTBLotterySystem: Amount is required to more than 0');
        userRoundData[currentRound][user].round = currentRound;
        userRoundData[currentRound][user].user = user;
        for(uint i=0; i < amount; i++) {
            Ticket memory ticket;
            ticket.position1 = generateRandomNumber();
            ticket.position2 = generateRandomNumber();
            ticket.position3 = generateRandomNumber();
            ticket.position4 = generateRandomNumber();

            userRoundData[currentRound][user].tickets.push(ticket);
            roundHistory[currentRound].tickets.push(ticket);
        }
        _burn(user, amount);
    }
    /**
     * @dev Admin can only use this function.  Adds OTBC rewards to the current round.
     */
    function addReward(uint rewardAmount) external onlyOwner {
        require(IERC20(rewardsToken).transferFrom(owner(), address(this), rewardAmount), 
                        'OTBLotterySystem: Reward amount could not be deposited to the Lottery contract for the round');
        roundHistory[currentRound].reward = roundHistory[currentRound].reward.decimalAddition(rewardAmount);
    }
    /**
     * @dev Admin can change the reward ratio.
     * This ratio represents how many OTBC required to buy 1 OTBTICKET
     */
    function setRewardRatio(uint8 ratio) external onlyOwner {
        require(ratio > 0, 'OTBLotterySystem: ZERO_AMOUNT');
        rewardRatio = ratio;
    }
    function setRewardToken(address _rewardsTokenAddress) external onlyOwner {
        require(_rewardsTokenAddress != address(0), 'Address Empty');
        rewardsToken = _rewardsTokenAddress;
    }
    /**
     * @dev Admin draws the 4 winning numbers.  (Random numbers between 0-9).
     * Stores data on chain and starts a new round. Updates the mapping for rounds.
     * Only Admin can execute this function.
     */
    function drawWinningNumber() external onlyOwner {
        roundHistory[currentRound].winningNumbers.position1 = generateRandomNumber();
        roundHistory[currentRound].winningNumbers.position2 = generateRandomNumber();
        roundHistory[currentRound].winningNumbers.position3 = generateRandomNumber();
        roundHistory[currentRound].winningNumbers.position4 = generateRandomNumber();

        (roundHistory[currentRound].matchAll,
            roundHistory[currentRound].match3,
            roundHistory[currentRound].match2,
            roundHistory[currentRound].match1) = findWinningMatches(roundHistory[currentRound].tickets, currentRound);
            
        if(roundHistory[currentRound].match1 == 0 && roundHistory[currentRound].match2 == 0 && 
                    roundHistory[currentRound].match3 == 0 && roundHistory[currentRound].matchAll == 0) {
            roundHistory[currentRound].noMatch = true;
        }
        currentRound++;
        roundHistory[currentRound].round = currentRound;
        roundHistory[currentRound].reward = calculateCarryForwardRewards(currentRound - 1);
        roundHistory[currentRound].rewardRatio.matchAll = roundHistory[currentRound - 1].rewardRatio.matchAll;
        roundHistory[currentRound].rewardRatio.match3 = roundHistory[currentRound - 1].rewardRatio.match3;
        roundHistory[currentRound].rewardRatio.match2 = roundHistory[currentRound - 1].rewardRatio.match2;
        roundHistory[currentRound].rewardRatio.match1 = roundHistory[currentRound - 1].rewardRatio.match1;
    }
    /**
     * @dev set nonce for randomize ticket generation.
     */
    function setNonce(uint _nonce) external onlyOwner {
        nonce = _nonce;
    }
    /**
     * @dev updates the reward allocation ratio for each pool.  Ratios must add up to 1.  
     * Example:  updateMatchPoolAllocation(0.5, 0.3, 0.15, 0.05)
     */
    function updateMatchPoolAllocation(uint8 matchAll, uint8 match3, uint8 match2, uint8 match1) external onlyOwner {
        require(matchAll + match3 + match2 + match1 == 100, 'Ratios must add up to 100%');
        roundHistory[currentRound].rewardRatio.matchAll = matchAll;
        roundHistory[currentRound].rewardRatio.match3 = match3;
        roundHistory[currentRound].rewardRatio.match2 = match2;
        roundHistory[currentRound].rewardRatio.match1 = match1;
    }
    /**
     * @dev claims rewards during the specified round if there are any to be claimed.
     */
    function claimRewards(address user, uint round) external {
        uint8 matchAll; 
        uint8 match3; 
        uint8 match2; 
        uint8 match1;
        
        (matchAll, match3, match2, match1) = findWinningMatches(userRoundData[round][user].tickets, round);
        uint totalRewards = calculateTotalRewardsToBeClaimed(matchAll, match3, match2, match1, round);
        userRoundData[round][user].reward = totalRewards;
        userRoundData[round][user].claimed = true;
        IERC20(rewardsToken).transfer(user, totalRewards);
    }
    /**
     * @dev Internal method. It finds number of different types of matches from list tickets in a specified round
     */
    function findWinningMatches(Ticket[] memory tickets, uint round) internal view returns 
                                                    (uint8 matchAll, uint8 match3, uint8 match2, uint8 match1) {
        for(uint i=0; i < tickets.length; i++) {
            if(tickets[i].position1 == roundHistory[round].winningNumbers.position1 &&
                    tickets[i].position2 == roundHistory[round].winningNumbers.position2 &&
                    tickets[i].position3 == roundHistory[round].winningNumbers.position3 &&
                    tickets[i].position4 == roundHistory[round].winningNumbers.position4) {
                matchAll++;
            } else if(tickets[i].position1 == roundHistory[round].winningNumbers.position1 &&
                    tickets[i].position2 == roundHistory[round].winningNumbers.position2 &&
                    tickets[i].position3 == roundHistory[round].winningNumbers.position3) {
                match3++;
            } else if(tickets[i].position1 == roundHistory[round].winningNumbers.position1 &&
                    tickets[i].position2 == roundHistory[round].winningNumbers.position2) {
                match2++;
            } else if(tickets[i].position1 == roundHistory[round].winningNumbers.position1) {
                match1++;
            }
        }
    }
    /**
     * @dev Internal function. It calculates carry forward not won rewards from previous round to next round.
     */
    function calculateCarryForwardRewards(uint round) internal view returns(uint) {
        if(roundHistory[round].noMatch) {
            return roundHistory[round].reward;
        }

        uint totalRewardToBeClaimed = calculateTotalRewardsToBeClaimed(roundHistory[round].matchAll, 
                                                                        roundHistory[round].match3,
                                                                        roundHistory[round].match2,
                                                                        roundHistory[round].match1, round);

        return roundHistory[round].reward.decimalSubtraction(totalRewardToBeClaimed);
    }
    /**
     * @dev Internal finction. It calculates total rewards that can be claimed by given number of matches for a specified round.
     */
    function calculateTotalRewardsToBeClaimed(uint8 matchAll, uint8 match3, uint8 match2, uint8 match1, uint round) internal view returns(uint) {
        uint matchAllTotalReward = roundHistory[round].reward.uintMultiply(roundHistory[round].rewardRatio.matchAll) / 100;
        uint match3TotalReward = roundHistory[round].reward.uintMultiply(roundHistory[round].rewardRatio.match3) / 100;
        uint match2TotalReward = roundHistory[round].reward.uintMultiply(roundHistory[round].rewardRatio.match2) / 100;
        uint match1TotalReward = roundHistory[round].reward.uintMultiply(roundHistory[round].rewardRatio.match1) / 100;

        uint totalRewards = 0;

        if(roundHistory[round].matchAll > 0 && matchAll > 0) {
            totalRewards += matchAllTotalReward.uintMultiply(matchAll) / roundHistory[round].matchAll;
        }
        if(roundHistory[round].match3 > 0 && match3 > 0) {
            totalRewards += match3TotalReward.uintMultiply(match3) / roundHistory[round].match3;
        }
        if(roundHistory[round].match2 > 0 && match2 > 0) {
            totalRewards += match2TotalReward.uintMultiply(match2) / roundHistory[round].match2;
        }
        if(roundHistory[round].match1 > 0 && match1 > 0) {
            totalRewards += match1TotalReward.uintMultiply(match1) / roundHistory[round].match1;
        }

        return totalRewards;
    }
    /**
     * @dev Internal function. It generates random number based on set nonce
     */
    function generateRandomNumber() internal returns (uint8){
        nonce += 3;
        return uint8(uint(keccak256(abi.encodePacked(blockhash(block.number), msg.sender, block.timestamp, nonce))) % 10);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './SafeMath.sol';

library Decimal {
    using SafeMath for uint;
    uint8 public constant decimals = 18;
    /**
     * @dev This method represents number of digits after decimal point supported
     */
    function multiplier() internal pure returns(uint) {
        return 10**decimals;
    }
    /**
     * @dev This method returns integer part of solidity decimal
     */
    function integer(uint _value) internal pure returns (uint) {
        return (_value / multiplier()) * multiplier(); // Can't overflow
    }
    /**
     * @dev This method returns fractional part of solidity decimal
     */
    function fractional(uint _value) internal pure returns (uint) {
        return _value.sub(integer(_value));
    }
    /**
     * @dev This method separates out solidity decimal to integral & fraction parts
     */
    function decimalFrom(uint _value) internal pure returns(uint, uint) {
        return ((_value / multiplier()), fractional(_value));
    }
    /**
     * @dev This method converts integral & fraction parts into solidity decimal
     */
    function decimalTo(uint _integral, uint _fractional) public pure returns(uint) {
        //return _integral.mul(multiplier()).add(_fractional.mul(multiplier()) / calculateFractionMultiplier(_fractional));
        return _integral.mul(multiplier()).add(_fractional);
    }

    function calculateFractionMultiplier(uint number) internal pure returns(uint) {
        uint fractionMultiplier = 1;
        while (number != 0) {
            number /= 10;
            fractionMultiplier = fractionMultiplier.mul(10);
        }
        return fractionMultiplier;
    }
    /**
     * @dev This method adds solidity decimal with integer value
     */
    function uintAddition(uint _value, uint x) internal pure returns(uint) {
        return _value.add(x.mul(multiplier()));
    }
    /**
     * @dev This method adds solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalAddition(uint _value, uint x) internal pure returns(uint) {
        return _value.add(x);
    }
    /**
     * @dev This method adds solidity decimal with integer value
     */
    function uintSubtraction(uint _value, uint x) internal pure returns(uint) {
        return _value.sub(x.mul(multiplier()));
    }
    /**
     * @dev This method adds solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalSubtraction(uint _value, uint x) internal pure returns(uint) {
        return _value.sub(x);
    }
    /**
     * @dev This method multiplies solidity decimal with integer value
     */
    function uintMultiply(uint _value, uint x) internal pure returns(uint) {
        return _value.mul(x);
    }
    /**
     * @dev This method multiplies solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalMultiply(uint _value, uint y) internal pure returns (uint) {
        if (_value == 0 || y == 0) return 0;

        // Separate into integer and fractional parts
        // x = x1 + x2, y = y1 + y2
        uint x1 = integer(_value);
        uint x2 = fractional(_value);
        uint y1 = integer(y);
        uint y2 = fractional(y);

        // (x1 + x2) * (y1 + y2) = (x1 * y1) + (x1 * y2) + (x2 * y1) + (x2 * y2)
        uint x1y1 = x1.mul(y1);
        uint x2y1 = x2.mul(y1);
        uint x1y2 = x1.mul(y2);
        uint x2y2 = x2.mul(y2);

        return (x1y1.add(x2y1).add(x1y2).add(x2y2)) / multiplier();
    }

    function reciprocal(uint x) internal pure returns (uint) {
        assert(x != 0);
        return multiplier() * multiplier() / x;
    }
    /**
     * @dev This method divides solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalDivide(uint _value, uint y) internal pure returns (uint) {
        assert(y != 0);
        return decimalMultiply(_value, reciprocal(y));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity=0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = tx.origin;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './interfaces/IERC20.sol';
import './libraries/SafeMath.sol';

contract OTBLotteryTicketERC20 {
    using SafeMath for uint;

    string public constant name = 'OTB Lottery Ticket Token';
    string public constant symbol = 'OTBTICKET';
    uint8 public constant decimals = 0;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function _mint(address to, uint value) internal {
        require(value <= type(uint).max - totalSupply, "OTBLotteryTicketERC20: Total supply exceeded max limit.");
        totalSupply = totalSupply.add(value);
        require(value <= type(uint).max - balanceOf[to], "OTBLotteryTicketERC20: Balance of minter exceeded max limit.");
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        require(from != address(0), "OTBLotteryTicketERC20: burn from the zero address");
        require(balanceOf[from] >= value, "OTBLotteryTicketERC20: burn amount exceeds balance of the holder");
        balanceOf[from] = balanceOf[from].sub(value);
        require(value <= totalSupply, "OTBLotteryTicketERC20: Insufficient total supply.");
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        require(spender != address(0), "OTBLotteryTicketERC20: approve to the invalid or zero address");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(from != address(0), "OTBLotteryTicketERC20: Invalid Sender Address");
        require(to != address(0), "OTBLotteryTicketERC20: Invalid Recipient Address");
        require(balanceOf[from] >= value, "OTBLotteryTicketERC20: Transfer amount exceeds balance of sender");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, "OTBLotteryTicketERC20: transfer amount exceeds allowance");
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}