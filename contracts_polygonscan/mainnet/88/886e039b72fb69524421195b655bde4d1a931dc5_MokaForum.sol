/**
 *Submitted for verification at polygonscan.com on 2021-10-17
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/DateTimeLibrary.sol


pragma solidity ^0.8.7;

library DateTimeLibrary {
  uint constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint constant SECONDS_PER_HOUR = 60 * 60;
  uint constant SECONDS_PER_MINUTE = 60;
  int constant OFFSET19700101 = 2440588;

  uint constant DOW_MON = 1;
  uint constant DOW_TUE = 2;
  uint constant DOW_WED = 3;
  uint constant DOW_THU = 4;
  uint constant DOW_FRI = 5;
  uint constant DOW_SAT = 6;
  uint constant DOW_SUN = 7;

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k-1;
      uint8 temp = (48 + uint8(_i - _i / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  // ------------------------------------------------------------------------
  // Calculate the number of days from 1970/01/01 to year/month/day using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and subtracting the offset 2440588 so that 1970/01/01 is day 0
  //
  // days = day
  //      - 32075
  //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
  //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
  //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
  //      - offset
  // ------------------------------------------------------------------------
  function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
    require(year >= 1970);
    int _year = int(year);
    int _month = int(month);
    int _day = int(day);

    int __days = _day
      - 32075
      + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
      + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
      - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
      - OFFSET19700101;

    _days = uint(__days);
  }

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
    int __days = int(_days);

    int L = __days + 68569 + OFFSET19700101;
    int N = 4 * L / 146097;
    L = L - (146097 * N + 3) / 4;
    int _year = 4000 * (L + 1) / 1461001;
    L = L - 1461 * _year / 4 + 31;
    int _month = 80 * L / 2447;
    int _day = L - 2447 * _month / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint(_year);
    month = uint(_month);
    day = uint(_day);
  }

  function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
  }
  function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
  }
  function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }
  function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
    secs = secs % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
    second = secs % SECONDS_PER_MINUTE;
  }
  function timestampToTimeBlocks(uint timestamp) internal pure returns (string memory monthBlock, string memory weekBlock, string memory dayBlock) {
    uint256 dayOfWeek = getDayOfWeek(timestamp);
    (uint year, uint month, uint day) = timestampToDate(timestamp);
    uint weekYear;
    uint weekMonth;
    uint weekDay;

    if (dayOfWeek > 1) {
      (weekYear, weekMonth, weekDay) = timestampToDate(subDays(timestamp, dayOfWeek - 1));
    } else {
      (weekYear, weekMonth, weekDay) = (year, month, day);
    }

    monthBlock = string(abi.encodePacked(uint2str(year), "-", uint2str(month)));
    weekBlock = string(abi.encodePacked(uint2str(weekYear), "-", uint2str(weekMonth), "-", uint2str(weekDay)));
    dayBlock = string(abi.encodePacked(uint2str(year), "-", uint2str(month), "-", uint2str(day)));
  }
  // 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
    uint256 _days = timestamp / SECONDS_PER_DAY;
    dayOfWeek = ((_days + 3) % 7) + 1;
  }
  function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _days * SECONDS_PER_DAY;
    require(newTimestamp <= timestamp);
  }
}
// File: contracts/MokaForumPosts.sol


pragma solidity ^0.8.7;

contract MokaForumPosts {
  uint64 public id;
  string public parentUid;
  address public mokaForumAddr;

  struct Post {
    uint64 id;
    uint32 upvotes;
    string monthBlock;
    string weekBlock;
    string dayBlock;
    uint timestamp;
    address user;
    string title;
    string desc;
    string url;
    string[] tags;
  }

  mapping(uint64 => Post) public posts;
  mapping(address => mapping(uint64 => bool)) public upvotes;

  event postCreated(uint64 id, Post post);
  event postUpvoted(uint64 postId, address voter);

  constructor(address _mokaForumAddr, string  memory _parentUid) {
    id = 0;
    parentUid = _parentUid;
    mokaForumAddr = _mokaForumAddr;
  }

  function createPost(
    string memory _monthBlock,
    string memory _weekBlock,
    string memory _dayBlock,
    address _creator,
    string memory _title,
    string memory _desc,
    string memory _url,
    string[] memory _tags
  ) public returns (bool) {
    require(msg.sender == mokaForumAddr, "Incorrect Forum Address");
    id += 1;
    Post memory post = Post(id, 0, _monthBlock, _weekBlock, _dayBlock, block.timestamp, _creator, _title, _desc, _url, _tags);
    posts[id] = post;
    emit postCreated(id, post);
    return true;
  }

  function upvotePost(uint64 _id, address _voter) public returns(bool, address) {
    require(msg.sender == mokaForumAddr, "Incorrect Forum Address");
    Post storage post = posts[_id];
    require(_voter != post.user, "Cannot Upvote Own Post");
    require(upvotes[_voter][_id] == false, "User Already Upvoted");
    upvotes[_voter][_id] = true;
    post.upvotes += 1;
    emit postUpvoted(_id, _voter);
    return (true, post.user);
  }

  function getPostCreator(uint64 _id) public view returns(address) {
    Post storage post = posts[_id];
    return post.user;
  }
}
// File: contracts/MokaForum.sol


pragma solidity ^0.8.7;





contract MokaForum is Ownable {
  uint8 public POST_PRICE;
  uint8 public VOTE_PRICE;
  string public uid;
  string public name;
  address public mokaERC20Contract;
  MokaForumPosts public postsContract;

  struct SettledPrizePost {
    string dateId;
    uint8 rank;
    uint256 prize;
    uint64 postId;
    address user;
  }

  mapping(string => uint32) public dailyPrizePool;
  mapping(string => uint32) public weeklyPrizePool;
  mapping(string => uint32) public monthlyPrizePool;
  mapping(address => uint32) public votesBy;
  mapping(address => uint32) public votesFor;

  mapping(string => SettledPrizePost[]) public settledDailyPrizePool;
  mapping(string => SettledPrizePost[]) public settledWeeklyPrizePool;
  mapping(string => SettledPrizePost[]) public settledMonthlyPrizePool;

  event PrizePoolIncreased(string dailyId, string weeklyId, string monthlyId, uint8 amount);
  event UserUpvotePost(address voterAddr, address postAddr, uint8 amount);
  event SettledDailyPrize(string dailyId, SettledPrizePost[]);
  event SettledWeeklyPrize(string weeklyId, SettledPrizePost[]);
  event SettledMonthlyPrize(string monthlyId, SettledPrizePost[]);

  constructor(uint8 _postPrice, uint8 _votePrice, string memory _uid, string memory _name, address _mokaERC20Contract) {
    POST_PRICE = _postPrice;
    VOTE_PRICE = _votePrice;
    uid = _uid;
    name = _name;
    mokaERC20Contract = _mokaERC20Contract;
    postsContract = new MokaForumPosts(address(this), _uid);
  }

  function create(uint8 _amount, address _creator, string memory _title, string memory _desc, string memory _url, string[] memory _tags) public returns (bool) {
    require(msg.sender == mokaERC20Contract, "ERC20 Contract Only");
    require(_amount == POST_PRICE, "Post Price Incorrect");
    (string memory monthBlock, string memory weekBlock, string memory dayBlock) = DateTimeLibrary.timestampToTimeBlocks(block.timestamp);
    bool addSuccess = postsContract.createPost(monthBlock, weekBlock, dayBlock, _creator, _title, _desc, _url, _tags);
    require(addSuccess, "Add Post Fail");
    monthlyPrizePool[monthBlock] += (_amount / 3);
    weeklyPrizePool[weekBlock] += (_amount / 3);
    dailyPrizePool[dayBlock] += (_amount / 3);
    emit PrizePoolIncreased(dayBlock, weekBlock, monthBlock, (_amount / 3));
    return true;
  }
  
  function upvote(uint8 _amount, address _voter, uint64 _postId) public returns (bool) {
    require(msg.sender == mokaERC20Contract, "ERC20 Contract Only");
    require(_amount == VOTE_PRICE, "Vote Price Incorrect");
    (bool voteSuccess, address creator) = postsContract.upvotePost(_postId, _voter);
    require(voteSuccess, "Vote Post Fail");
    votesBy[_voter] += _amount;
    votesFor[creator] += _amount;
    emit UserUpvotePost(_voter, creator, _amount);
    return true;
  }

  function getPostCreator(uint64 _postId) public view returns(address) {
    return postsContract.getPostCreator(_postId);
  }

  function settleDailyPrize(string memory _dailyId, SettledPrizePost[] memory settledPosts) public onlyOwner {
    require(settledDailyPrizePool[_dailyId].length == 0, "Pool Already Settled");

    for (uint8 i = 0; i < settledPosts.length; i++) {
      bool success = IERC20(mokaERC20Contract).transfer(settledPosts[i].user, settledPosts[i].prize);
      require(success, "Payment Failed");
      settledDailyPrizePool[_dailyId].push(settledPosts[i]);
    }

    emit SettledDailyPrize(_dailyId, settledPosts);
  }

  function settleWeeklyPrize(string memory _weeklyId, SettledPrizePost[] memory settledPosts) public onlyOwner {
    require(settledWeeklyPrizePool[_weeklyId].length == 0, "Pool Already Settled");

    for (uint8 i = 0; i < settledPosts.length; i++) {
      bool success = IERC20(mokaERC20Contract).transfer(settledPosts[i].user, settledPosts[i].prize);
      require(success, "Payment Failed");
      settledWeeklyPrizePool[_weeklyId].push(settledPosts[i]);
    }

    emit SettledWeeklyPrize(_weeklyId, settledPosts);
  }

  function settleMonthlyPrize(string memory _monthlyId, SettledPrizePost[] memory settledPosts) public onlyOwner {
    require(settledMonthlyPrizePool[_monthlyId].length == 0, "Pool Already Settled");

    for (uint8 i = 0; i < settledPosts.length; i++) {
      bool success = IERC20(mokaERC20Contract).transfer(settledPosts[i].user, settledPosts[i].prize);
      require(success, "Payment Failed");
      settledMonthlyPrizePool[_monthlyId].push(settledPosts[i]);
    }

    emit SettledMonthlyPrize(_monthlyId, settledPosts);
  }
}