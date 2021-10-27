/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}




/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount,address ref) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
   
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
}

// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function mint(address _addr,uint256 amount) external;
    function burn ( uint256 amount ) external;


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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


contract iBGLottery is Ownable {
    // Constants
    uint256 private FIRST_WINNER_PRIZE = 5000 * 1e18; // 25,000 iBG
    uint256 private SECOND_WINNER_PRIZE = 5000 * 1e18; // 25000 iBG
    uint256 public DURATION = 7 days;
    uint256 private TICKET_BASE_PRICE = 5 * 1e18; // 5 iBG per ticket
    uint256 private DISCOUNT_TIER_1 = 5; // 5% discount for 1st tier
    uint256 private DISCOUNT_TIER_2 = 10; // 10% discount for 2st tier
    uint256 private DISCOUNT_TIER_3 = 20; // 20% discount for 3st tier
    uint256 private SUPER_STAKER_PRICE = 1000 * 1e18; // 1000 iBG staked to claim a ticket

    // Global Variables
    IERC20 private ibg;
    IMasterChef private booster;
    uint256 public immutable startTime; 
    bool public closed;

    // Per Round Variables
    mapping(uint256 => address[]) private tickets;
    mapping(uint256 => mapping(address => uint256)) public numTicketsOf;
    mapping(uint256 => mapping(address => uint256)) public claimed;
    mapping(uint256 => Stats) private stats;
    
    struct Stats {
        uint256 sales;
        uint256 numParticipants;
        bool finalized;
        address firstWinner;
        address secondWinner;
    }

    event Ticket(uint256 indexed round, address indexed _player, uint256 _numTicket, uint256 _price);
    event Winner(uint256 indexed round, address _winner, uint256 _prize);

    constructor( uint256 _startTime) {
         ibg = IERC20(0x5c46c55A699A6359E451B2c99344138420c87261); 
         booster = IMasterChef(0xE8674316F5634f1F9Bdd230c6D378c7b12eF4A23);
        startTime = _startTime;
    }

    function getCurrentRound() public view returns (uint256) {
        return (block.timestamp - startTime) / DURATION;
    }
    
    function getTicketPrice(uint256 _numTicket) public view returns (uint256) {
        if(_numTicket >= 1000) {
            return TICKET_BASE_PRICE * _numTicket * (100 - DISCOUNT_TIER_3) / 100;
        } else if(_numTicket >= 100) {
            return TICKET_BASE_PRICE * _numTicket * (100 - DISCOUNT_TIER_2) / 100;
        } else if(_numTicket >= 10) {
            return TICKET_BASE_PRICE * _numTicket * (100 - DISCOUNT_TIER_1) / 100;
        } else {
            return TICKET_BASE_PRICE * _numTicket;
        }
    }
    
    
    

    function purchaseTicket(uint256 _numTicket) external returns (bool) {
        require(block.timestamp > startTime, "Lottery did not started yet");
        require(!closed, "Lottery has already closed");

        uint256 round = getCurrentRound();
        uint256 price = getTicketPrice(_numTicket);
        ibg.transferFrom(msg.sender, address(this), price);

        for(uint256 i = 0; i < _numTicket; i++) {
            tickets[round].push(msg.sender);
        }

        if(numTicketsOf[round][msg.sender] == 0) stats[round].numParticipants++;

        numTicketsOf[round][msg.sender] += _numTicket;
        stats[round].sales += price;

        emit Ticket(round, msg.sender, _numTicket, price);
        return true;
    }

    function claimTicket() external returns (bool) {
        require(!closed, "Lottery has already closed");

        uint256 staked = getSuperStaked(msg.sender);
        require(staked >= SUPER_STAKER_PRICE, "need super stake more than 1000 iBG");

        uint256 round = getCurrentRound();
        require(claimed[round][msg.sender] == 0, "tickets already claimed");

        uint256 numTicket = staked / SUPER_STAKER_PRICE;
        for(uint256 i = 0; i < numTicket; i++) {
            tickets[round].push(msg.sender);
        }
        claimed[round][msg.sender] = numTicket;

        if(numTicketsOf[round][msg.sender] == 0) stats[round].numParticipants++;

        numTicketsOf[round][msg.sender] += numTicket;

        emit Ticket(round, msg.sender, numTicket, 0);
        return true;
    }
    
    
    function _burnAll()internal{
        uint256 ibgBal = ibg.balanceOf(address(this));
        ibg.burn(ibgBal);
    }
    
    function finalize(uint256 _round) external onlyOwner returns (bool) {
        require(!closed, "Lottery has already closed");
        require(!stats[_round].finalized, "Lottery already finalized");
        require(block.timestamp > startTime + (_round + 1) * DURATION, "Specified round has not been ended");
        _burnAll();

        uint256 numTickets = tickets[_round].length;
        uint256 random1 = uint256(keccak256(abi.encodePacked(msg.sender, numTickets, block.timestamp)));
        uint256 firstWinner = random1 % numTickets;
        ibg.mint(tickets[_round][firstWinner], FIRST_WINNER_PRIZE);
        uint256 random2 = uint256(keccak256(abi.encodePacked(firstWinner, numTickets, block.timestamp)));
        uint256 secondWinner = random2 % numTickets;
        require(firstWinner != secondWinner, "The same address won 2 places. Try again");
        ibg.mint(tickets[_round][secondWinner], SECOND_WINNER_PRIZE);
        stats[_round].finalized = true;
        
        emit Winner(_round, tickets[_round][firstWinner], FIRST_WINNER_PRIZE);
        emit Winner(_round, tickets[_round][secondWinner], SECOND_WINNER_PRIZE);
        
        return true;
    }

    function getStats(uint256 _round) external view returns (uint256 _numTotalTickets, uint256 _numParticipants, uint256 _sales, bool _finalized, address _firstWinner, address _secondWinner) {
        Stats memory stat = stats[_round];
        return (tickets[_round].length, stat.numParticipants, stat.sales, stat.finalized, stat.firstWinner, stat.secondWinner);
    }
    
    function isEligibleForFeeTickets(address user) public view returns(bool) {
        if(claimed[getCurrentRound()][user] == 0){
            return false;
        }
        
        uint256 totalStaked = getSuperStaked(user);
        
        return totalStaked >= SUPER_STAKER_PRICE;
    }

    function getSuperStaked(address _addr) public view returns (uint256) {
        uint256 totalStaked;
        for(uint256 i = 0; i < 3; i++) {
            (uint256 staked,  ) = booster.userInfo(i, _addr);
            totalStaked += staked;
        }
        return totalStaked;
    }
}