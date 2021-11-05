/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  //function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

  function _msgSender() internal view returns (address) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

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
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}




/** 
* @title BETDEC - Decentralized Sports Betting
* @dev Implements a betting system on the decentralized blockchain.
*/
    
    
contract BetDec is Context, IBEP20 {
    /*bsc*/
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    address owner;

    constructor() {
        owner = msg.sender;

        _name = "Decentralized Betting Network";
        _symbol = "BETDEC";
        _decimals = 18;
        _totalSupply = 100000000000000000000000000000;
        _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "EPIC FAILURE - only the owner admin can run this");
        _;
    }

        /* BSC CODE */

        /**

    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
    */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
    * @dev See {BEP20-totalSupply}.
    */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev See {BEP20-balanceOf}.
    */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
    * @dev See {BEP20-transfer}.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
    * @dev See {BEP20-allowance}.
    */
    function allowance(address bscowner, address spender) external view override returns (uint256) {
        return _allowances[bscowner][spender];
    }

    /**
    * @dev See {BEP20-approve}.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
    * @dev See {BEP20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {BEP20};
    *
    * Requirements:
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `amount`.
    */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
    * @dev Atomically increases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {BEP20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
    * @dev Atomically decreases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {BEP20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    * - `spender` must have allowance for the caller of at least
    * `subtractedValue`.
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    /**
    * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
    * the total supply.
    *
    * Requirements
    *
    * - `msg.sender` must be the token owner
    */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
    function _approve(address bscowner, address spender, uint256 amount) internal {
        require(bscowner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[bscowner][spender] = amount;
        emit Approval(bscowner, spender, amount);
    }

    /**
    * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
    * from the caller's allowance.
    *
    * See {_burn} and {_approve}.
    */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }

    /* BETDEC CODE */
    
    /* EVM Log Events */
    event LogFailure(string message);
    event LogFailureNum(uint message);
    event TimestampLog(uint256 message);
    //event BettingEventCreated(uint id, string title, string league);
    event BettingEventCreated(uint id, string league);


    /* LEAGUES */
    //DELETE
    /*
    string[] NFLTeamsArray;
    string[] MLBTeamsArray;
    string[] NBATeamsArray;
    string[] NHLTeamsArray;
    string[] UFCTeamsArray;
    string[] PGATeamsArray;
    string[] TENNISTeamsArray;
    string[] SOCCERTeamsArray;
    string[] HORSETeamsArray;
    string[] POLITICSTeamsArray;
    */
    
    struct Bettor {
        uint betTeamId;
        uint betTimestamp;
        uint256 betAmount;
    }
    
    struct BettingEvent {
        
        // event info
        bool eventActive;
        //string eventTitle;
        string eventDescription;
        string eventDateTime;
        uint eventBetEndTimestamp;
        uint eventPayoutTimestamp;
        
        // league info
        string eventLeague;
        //string eligibleTeamsIndexes;
        
        uint256 eventPoolTotal;

        // bet fee
        uint betFee;    // In percent, ie 10 is a 10% fee to the owner address
        
        // teams allowed
        mapping (uint => bool) teamsAllowed;
        
        // winning team
        bool winningTeamSetBool;
        uint winningTeamId;

        // bets by bettors
        address[] bettorAddresses;
        mapping (address => Bettor) bettors;
    }
    
    /* EVENT METRICS */
    uint numEventsTotal;
    uint numEventsActive;
    uint numEventsEnded;
    
    
    /* MAPPINGS */
    
    //event mappings
    uint[] bettingEventIds;
    mapping (uint => BettingEvent) bettingEvents;
    
    //user mappings
    mapping(address => uint) public userTotalHistoricalBetAmount;
    mapping(address => uint) public userTotalActiveBets;
    mapping(address => uint[]) public userActiveEventIds;
    
    //winner array
    address[] tempWinnerAddresses;
    
    /* TEAM FUNCTIONS */
    //DELETE
    /*
    string[] emptyArray;
    */
    
    //DELETE
    /*
    function teamFilter(string memory _league) internal view returns(string[] storage){
        require(bytes(_league).length>0, "Missing league.");
        if (keccak256(bytes(_league)) == keccak256(bytes("NFL"))){return NFLTeamsArray;}
        if (keccak256(bytes(_league)) == keccak256(bytes("MLB"))){return MLBTeamsArray;}
        if (keccak256(bytes(_league)) == keccak256(bytes("NBA"))){return NBATeamsArray;}
        if (keccak256(bytes(_league)) == keccak256(bytes("NHL"))){return NHLTeamsArray;}
        if (keccak256(bytes(_league)) == keccak256(bytes("UFC"))){return UFCTeamsArray;}
        if (keccak256(bytes(_league)) == keccak256(bytes("PGA"))){return PGATeamsArray;}
        if (keccak256(bytes(_league)) == keccak256(bytes("TENNIS"))){return TENNISTeamsArray;}
        if (keccak256(bytes(_league)) == keccak256(bytes("SOCCER"))){return SOCCERTeamsArray;}
        if (keccak256(bytes(_league)) == keccak256(bytes("HORSE"))){return HORSETeamsArray;}
        if (keccak256(bytes(_league)) == keccak256(bytes("POLITICS"))){return POLITICSTeamsArray;}
        // return empty array
        return emptyArray;
    }
    
    //DELETE
    function addTeam(string memory _league, string memory _team) public onlyOwner {
        require(bytes(_league).length>0, "Missing league.");
        require(bytes(_team).length>0, "Missing team id.");
        teamFilter(_league).push(_team);
    }
    
    //DELETE
    function delTeam(string memory _league, uint _index) public onlyOwner {
        require(bytes(_league).length>0, "Missing league.");
        require(_index>0, "Missing team index.");
        string[] storage teamArray = teamFilter(_league);
        for (uint i = _index; i<teamArray.length-1; i++){
                teamArray[i] = teamArray[i+1];
        }
        delete teamArray[teamArray.length-1];
        teamArray.pop();
    }
    
    //DELETE
    function getTeams(string memory _league) public view returns (string[] memory) {
        require(bytes(_league).length>0, "Missing league.");
        string[] storage teamArray = teamFilter(_league);
        return teamArray;
    }
    
    //DELETE
    function getTeamByIndex(string memory _league, uint _index) public view returns (string memory) {
        require(bytes(_league).length>0, "Missing league.");
        require(_index>0, "Missing team index.");
        string[] storage teamArray = teamFilter(_league);
        return teamArray[_index];
    }
    */

    
    /* EVENT FUNCTIONS */

    function createBettingEvent(
                        bool _eventActive,
                        //string memory _eventTitle,
                        string memory _eventDescription,
                        string memory _eventDateTime,
                        uint _eventBetEndTimestamp,
                        uint _eventPayoutTimestamp,
                        string memory _eventLeague,
                        //string memory _eligibleTeamsIndexes,
                        uint256 _eventPoolTotal,
                        uint _betFee
                    ) public onlyOwner returns (uint bettingEventId) {
                            
        // Check to see if the auction deadline is in the future
        if (block.number >= _eventBetEndTimestamp) {
            emit LogFailure("This event has ended.  No more bets allowed.");
            revert();
        }
        

        bettingEventId = bettingEventIds.length;
        
        BettingEvent storage be = bettingEvents[bettingEventId];
        be.eventActive = _eventActive;
        //be.eventTitle = _eventTitle;
        be.eventDescription = _eventDescription;
        be.eventDateTime = _eventDateTime;
        be.eventBetEndTimestamp = _eventBetEndTimestamp;
        be.eventPayoutTimestamp = _eventPayoutTimestamp;
        be.eventLeague = _eventLeague;
        be.winningTeamSetBool = false;
        be.eventPoolTotal = _eventPoolTotal;
        be.betFee = _betFee;
        
        bettingEventIds.push(bettingEventId);
        
        //emit BettingEventCreated(bettingEventId, _eventTitle, _eventLeague);
        emit BettingEventCreated(bettingEventId, _eventLeague);
        
        return bettingEventId;
        
    }
    
    
    function getBettingEventById(uint _eventId) public view returns (string memory) {
        require(_eventId>0, "Missing event ID.");
        //return bettingEvents[_eventId].eventTitle;
        return bettingEvents[_eventId].eventDescription;
    }
    
    //DELETE
    /*
    // helper to look up if teamID exists
    function teamExists(string memory _league, uint _idToLookup) private view returns (bool){
        require(bytes(_league).length>0, "Missing league.");
        require(_idToLookup>0, "Missing idToLookup.");
        string[] storage teamArray = teamFilter(_league);
        for (uint i; i< teamArray.length;i++){
            if (i == _idToLookup)
            return true;
        }
        return false;
    }
    */
    
    //MODIFY - REQUIRED
    /*
    function addTeamIDToEvent(uint _eventId, string memory _league, uint _teamId) public onlyOwner {
        require(_eventId>0, "Missing event ID.");
        require(bytes(_league).length>0, "Missing league.");
        require(_teamId>0, "Missing team ID.");
        require(teamExists(_league, _teamId), "Team does not exist.");
        require(bettingEvents[_eventId].eventActive, "Event does not exist.");

        bettingEvents[_eventId].teamsAllowed[_teamId] = true;
    }
    */
    
    //MODIFY - REQUIRED
    /*
    function addAllTeamsToEvent(uint _eventId, string memory _league) public onlyOwner {
        require(bettingEvents[_eventId].eventActive, "Event does not exist.");
        require(_eventId>0, "Missing event ID.");
        require(bytes(_league).length>0, "Missing league.");
        string[] storage teamArray = teamFilter(_league);
        for (uint i; i< teamArray.length;i++){
            bettingEvents[_eventId].teamsAllowed[i] = true;
        }
    }
    */
    
    
    function bet(uint _eventId, uint _teamId) external payable {
        require(_eventId >= 0, "EventId is not set properly.");
        require(_teamId >= 0, "TeamID is not set properly.");
        require(msg.value > 0, "Zero Amount Error, You must send some ether along with the bet.");
        require(bettingEvents[_eventId].eventActive, "Event not active or has ended error.");
        require(block.timestamp < bettingEvents[_eventId].eventBetEndTimestamp, "Betting for this event has ended error.");

        emit TimestampLog(block.timestamp);
            
        uint256 existingBet = bettingEvents[_eventId].bettors[msg.sender].betAmount;
        uint256 totalBetAmount = existingBet + msg.value;
        bettingEvents[_eventId].bettors[msg.sender] = Bettor(totalBetAmount, _teamId, block.timestamp);

        // metrics
        userTotalHistoricalBetAmount[msg.sender] += msg.value;
        userTotalActiveBets[msg.sender] = userTotalActiveBets[msg.sender] + 1;
        userActiveEventIds[msg.sender].push(_eventId);
        
        bettingEvents[_eventId].eventPoolTotal = bettingEvents[_eventId].eventPoolTotal + msg.value;
            
    }
    
    // Admin Functions

    function eventAdminSetActive(uint _eventId, bool _eventActive) external onlyOwner {
        bettingEvents[_eventId].eventActive = _eventActive;
    }
    
    //function eventAdminSetTitle(uint _eventId, string memory _eventTitle) public onlyOwner {
    //    bettingEvents[_eventId].eventTitle = _eventTitle;
    //}
    
    function eventAdminSetDescription(uint _eventId, string memory _eventDescription) external onlyOwner {
        bettingEvents[_eventId].eventDescription = _eventDescription;
    }
    
    function eventAdminSetDateTime(uint _eventId, string memory _eventDateTime) external onlyOwner {
        bettingEvents[_eventId].eventDateTime = _eventDateTime;
    }
    
    function eventAdminSetPayoutTimestamp(uint _eventId, uint _eventPayoutTimestamp) external onlyOwner {
        bettingEvents[_eventId].eventPayoutTimestamp = _eventPayoutTimestamp;
    }
    
    function eventAdminSetBetFee(uint _eventId, uint _betFee) external onlyOwner {
        bettingEvents[_eventId].betFee = _betFee;
    }
    
    function eventAdminSetWinner(uint _eventId, uint _teamId) external onlyOwner {
        bettingEvents[_eventId].winningTeamId = _teamId;
        bettingEvents[_eventId].winningTeamSetBool = true;
    }
    
    // Public event getters
    
    function eventGetActive(uint _eventId) external view returns(bool) {
        return bettingEvents[_eventId].eventActive;
    }
    
    //function eventGetTitle(uint _eventId) public view returns(string memory) {
    //    return bettingEvents[_eventId].eventTitle;
    //}
    
    function eventGetDescription(uint _eventId) external view returns(string memory) {
        return bettingEvents[_eventId].eventDescription;
    }
    
    function eventGetDateTime(uint _eventId) external view returns(string memory) {
        return bettingEvents[_eventId].eventDateTime;
    }
    
    function eventGetPayoutTimestamp(uint _eventId) external view returns(uint){
        return bettingEvents[_eventId].eventPayoutTimestamp;
    }
    
    function eventGetBetFee(uint _eventId) external view returns(uint) {
        return bettingEvents[_eventId].betFee;
    }
    
    /* ADMIN PROCESS PAYMENTS */
    
    function adminProcessPayments() external payable onlyOwner {
        for (uint i = 0; i<bettingEventIds.length-1; i++){
            BettingEvent storage be = bettingEvents[i];
            if (be.eventActive == true && 
                be.winningTeamSetBool == true &&
                block.timestamp > be.eventPayoutTimestamp && 
                block.timestamp > be.eventBetEndTimestamp &&
                be.bettorAddresses.length > 0) {
                
                uint tempLosersPoolAmount;
                uint tempWinnersTotalBetAmount;
                uint tempWinnersPoolPayoutAmount;
                uint tempContractFee;
                
                // iterate over all bettors and separate the winners from losers
                for (uint b = 0; b<be.bettorAddresses.length-1; b++){
                    //if team has won that bettor bet against
                    address bettorAddr = be.bettorAddresses[b];
                    if (be.bettors[bettorAddr].betTimestamp < be.eventBetEndTimestamp &&
                        be.bettors[bettorAddr].betTeamId == be.winningTeamId){
                        //winner
                        tempWinnersTotalBetAmount += be.bettors[bettorAddr].betAmount;
                        tempWinnerAddresses.push(bettorAddr);
                        
                    }
                    //if team has lost that bettor bet against
                    if (be.bettors[bettorAddr].betTimestamp < be.eventBetEndTimestamp &&
                        be.bettors[bettorAddr].betTeamId != be.winningTeamId){
                        //loser
                        tempLosersPoolAmount += be.bettors[bettorAddr].betAmount;
                    }
                }
                // at this point we have winners isolated in array and the loser pool total amount
                tempContractFee = tempLosersPoolAmount * be.betFee / 100;
                tempWinnersPoolPayoutAmount = tempLosersPoolAmount - tempContractFee;
                
                //Find each winners share, and distribute
                for (uint winnerIndex = 0; winnerIndex<tempWinnerAddresses.length-1; winnerIndex++){
                    address winnerAddr = tempWinnerAddresses[winnerIndex];
                    uint winnerExistingBetAmount = be.bettors[winnerAddr].betAmount;
                    //check this?
                    uint winnerFinalPayout = calculatedPayout(
                        winnerExistingBetAmount, 
                        tempWinnersTotalBetAmount, 
                        tempWinnersPoolPayoutAmount
                    );
                    
                    //transfer payment 
                    payable(winnerAddr).transfer(winnerFinalPayout);
                }
                
                
                // make sure to delete all temp vars after each event iteration
                delete tempWinnerAddresses;
                delete tempLosersPoolAmount;
                delete tempWinnersTotalBetAmount;
                delete tempWinnersPoolPayoutAmount;
                delete tempContractFee;
            } // endif
        }
        
    }
    
    function calculatedPayout( 
            uint existingUserBetAmount, 
            uint winnersTotalBetAmount, 
            uint winnersPoolPayoutAmount
        ) public onlyOwner returns(uint) {
        uint divFactor = 10;
        if (existingUserBetAmount*1000 > winnersTotalBetAmount){
            divFactor = 1000;
        } else if (existingUserBetAmount*10000 > winnersTotalBetAmount){
            divFactor = 10000;
        } else if (existingUserBetAmount*100000 > winnersTotalBetAmount){
            divFactor = 100000;
        } else if (existingUserBetAmount*1000000 > winnersTotalBetAmount){
            divFactor = 1000000;
        } else if (existingUserBetAmount*10000000 > winnersTotalBetAmount){
            divFactor = 10000000;
        } else if (existingUserBetAmount*100000000 > winnersTotalBetAmount){
            divFactor = 100000000;
        } else if (existingUserBetAmount*1000000000 > winnersTotalBetAmount){
            divFactor = 1000000000;
        } else if (existingUserBetAmount*10000000000 > winnersTotalBetAmount){
            divFactor = 10000000000;
        } else if (existingUserBetAmount*100000000000 > winnersTotalBetAmount){
            divFactor = 100000000000;
        } else if (existingUserBetAmount*1000000000000 > winnersTotalBetAmount){
            divFactor = 1000000000000;
        } else if (existingUserBetAmount*10000000000000 > winnersTotalBetAmount){
            divFactor = 10000000000000;
        } else if (existingUserBetAmount*100000000000000 > winnersTotalBetAmount){
            divFactor = 100000000000000;
        } else {
            // send back original bet amount.
            return existingUserBetAmount;
        }
        uint payout = ((existingUserBetAmount*divFactor/winnersTotalBetAmount)*winnersPoolPayoutAmount)/divFactor;
        emit LogFailureNum(payout);
        return payout;
    }
    
    function refund(address _address, uint _amount) external onlyOwner returns(bool) {
        payable(_address).transfer(_amount);
        return true;
    }
    

}