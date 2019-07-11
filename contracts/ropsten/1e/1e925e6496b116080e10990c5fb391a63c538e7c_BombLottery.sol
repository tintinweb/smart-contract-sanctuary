/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.10;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
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
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
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

}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
}

interface IBOMBLET {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function mint(address to, uint256 value) external returns (bool);
  function burn(address from, uint256 value) external  returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BombLottery is Pausable {
    
    using SafeMath for uint;
    
    address public BOMB_ADDR;
    address public BOMBLET_ADDR; 
    
    mapping (address => uint) bombBalance;
    mapping (address => uint) bombletBalance;
    
    IERC20 internal Bomb;
    IBOMBLET internal Bomblet;
    
    modifier hasTickets{
        require(Bomblet.balanceOf(msg.sender) > 0 );
        _;
    }
    
    
    event TicketPurchased(uint lotIndex, uint ticketNumber, address player, uint ticketPrice);
    event TicketWon(uint lotIndex, uint ticketNumber, address player, uint win);

    uint curLotIndex = 0;
    uint public roundsPlayed = 0;
    uint public ticketsSold = 0;
    uint public ticketPrice = 1;
    uint public playersLimit = 10;
    uint public ticketsPerPlayerLimit = 10;
    
    
    uint public percentRate = 100;
    uint public feePercent = 1;
    address public feeWallet = 0x47259b700a4360146E4F359CE29Ed8a7ef79a830;
    



    struct Lottery {
        uint summaryInvested;
        uint rewardBase;
        uint ticketsCount;
        uint playersCount;
        address winner;
        mapping(address => uint) ticketsCounts;
        mapping(uint => address) tickets;
        mapping(address => uint) invested;
        address[] players;
    }

    Lottery[] public lots;

    modifier notContract(address to) {
        uint codeLength;
        assembly {
            codeLength := extcodesize(to)
        }
        require(codeLength == 0, "Contracts not supported!");
        _;
    }
    
    function findOnePercent(uint256 value) public view returns (uint256)  {
        uint256 roundValue = value.ceil(percentRate);
        uint256 onePercent = roundValue.mul(percentRate).div(10000);
        return onePercent;
    }

    function setTicketsPerPlayerLimit(uint newTicketsPerPlayerLimit) public onlyOwner {
        ticketsPerPlayerLimit = newTicketsPerPlayerLimit;
    }

    function setFeeWallet(address newFeeWallet) public onlyOwner {
        feeWallet = newFeeWallet;
    }

    function setTicketPrice(uint newTicketPrice) public onlyOwner {
        ticketPrice = newTicketPrice;
    }

    function setFeePercent(uint newFeePercent) public onlyOwner {
        feePercent = newFeePercent;
    }

    function setPlayerLimit(uint newPlayersLimit) public onlyOwner {
        playersLimit = newPlayersLimit;
    }
    
    function setBombAddress(address newBombContract) public onlyOwner {
        BOMB_ADDR = newBombContract;
    }

    function setBombletAddress(address newBombletContract) public onlyOwner {
        BOMBLET_ADDR = newBombletContract;
    }

    function playlotto(uint _tickets) public payable notContract(msg.sender) {
        require(Bomblet.balanceOf(msg.sender) >= _tickets, "No tickets Left!!");
        require(Bomblet.transferFrom(msg.sender, address(this), _tickets));

        if (lots.length == 0) {
            lots.length = 1;
        }

        Lottery storage lot = lots[curLotIndex];

        uint numTicketsToBuy =_tickets;
        ticketsSold += _tickets;

        if (numTicketsToBuy > ticketsPerPlayerLimit) {
            numTicketsToBuy = ticketsPerPlayerLimit;
        }

        uint toInvest = ticketPrice.mul(numTicketsToBuy);

        if (lot.invested[msg.sender] == 0) {
            lot.players.push(msg.sender);
            lot.playersCount = lot.playersCount.add(1);
        }

        lot.invested[msg.sender] = lot.invested[msg.sender].add(toInvest);

        for (uint i = 0; i < numTicketsToBuy; i++) {
            lot.tickets[lot.ticketsCount] = msg.sender;
            emit TicketPurchased(curLotIndex, lot.ticketsCount, msg.sender, ticketPrice);
            lot.ticketsCount = lot.ticketsCount.add(1);
            lot.ticketsCounts[msg.sender]++;
        }

        lot.summaryInvested = lot.summaryInvested.add(toInvest);

        if (lot.playersCount >= playersLimit) {
            uint number = uint(keccak256(abi.encodePacked(block.number))) % lot.ticketsCount;
            address winner = lot.tickets[number];
            lot.winner = winner;
            uint fee = findOnePercent(lot.summaryInvested);
            Bomblet.transfer(feeWallet, fee);
            lot.rewardBase = lot.summaryInvested.sub(fee);
            Bomblet.transfer(winner, lot.rewardBase);
            emit TicketWon(curLotIndex, number, lot.winner, lot.rewardBase);
            curLotIndex++;
            roundsPlayed++;
        }
    }

    // Removed, This could be nefariously used to transfer Bomb/Bomblets. 
    // Any tokens transferred to this address will just be lost forever. 
    // function retrieveTokens(address tokenAddr, address to) public onlyOwner {
    //     IERC20 token = IERC20(tokenAddr);
    //     token.transfer(to, token.balanceOf(address(this)));
    // }
    
    constructor(address _bomb, address _bomblet) public {
        BOMB_ADDR = _bomb;
        BOMBLET_ADDR = _bomblet;
        Bomb = IERC20(BOMB_ADDR);
        Bomblet = IBOMBLET(BOMBLET_ADDR);
        
    }
    
    
    function depositBomb(uint _amount) external returns(bool){
        // require(Bomb.approve(address(this), _amount));
        require(Bomb.transferFrom(msg.sender, address(this), _amount));
        
        uint bombAmount = _amount.sub(findOnePercent(_amount));
        uint mintAmount = bombAmount.mul(10);
        
        require(Bomblet.mint(msg.sender, mintAmount));

        bombBalance[msg.sender] = bombBalance[msg.sender].add(bombAmount);
        bombletBalance[msg.sender] += mintAmount;
        
        return true;
    }
    
    function withdrawBomb(uint _amount) external returns(bool){
        uint _bomblets = _amount.mul(10);
        require(_amount > 2,&#39;Burn Rate requires more than 1 Bomb!&#39;);
        require(bombBalance[msg.sender] >= _amount );
        require(bombletBalance[msg.sender] >= _bomblets);
        require(Bomb.transfer(msg.sender, _amount));
        require(Bomblet.burn(msg.sender, _amount.mul(10))) ;
        
        bombBalance[msg.sender] = bombBalance[msg.sender].sub(_amount);
        bombletBalance[msg.sender] = Bomblet.balanceOf(msg.sender);
        
    }


    function() external{
        revert(); //lets not chance getting any ETH accidentally.
    }

}