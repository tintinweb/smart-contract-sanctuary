pragma solidity ^0.4.18;

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


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

contract WillAlwaysLove is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // ------------------------------------------------------------

    uint256 public constant DEFAULT_INITIAL_COST = 0.025 ether;
    uint256 public constant DEFAULT_LOCK_COST_PER_HOUR = 0.0006 ether; // 10 szabo per minute
    uint256 public constant DEFAULT_MAX_LOCK_DURATION = 1 weeks;

    uint256 public constant DEVELOPER_CUT = 25; // %

    // ------------------------------------------------------------

    struct LoveStory {
        address owner;
        bytes32 loverName;
        bytes32 lovedOneName;
        uint256 transferCost;
        uint256 lockedUntil;
        string data;
    }

    // ------------------------------------------------------------

    uint256 public initialCost;
    uint256 public lockCostPerHour;
    uint256 public maxLockDuration;

    mapping(bytes16 => LoveStory) private loveStories;
    uint256 public loveStoriesCount;

    mapping (address => uint256) private pendingWithdrawals;

    // ------------------------------------------------------------

    event LoveStoryCreated(
        bytes16 id,
        address owner,
        bytes32 loverName,
        bytes32 lovedOneName,
        uint256 transferCost,
        uint256 lockedUntil,
        string data
    );

    event LoveStoryUpdated(
        bytes16 id,
        bytes32 loverName,
        bytes32 lovedOneName,
        string data
    );

    event LoveStoryTransferred(
        bytes16 id,
        address oldOwner,
        address newOwner,
        bytes32 newLoverName,
        bytes32 newLovedOneName,
        uint256 newtransferCost,
        uint256 lockedUntil,
        string data
    );

    event Withdrawal(
        address withdrawer,
        uint256 amount
    );

    // ------------------------------------------------------------

    modifier onlyForUnregisteredId(bytes16 _id) {
        require(!isIdRegistered(_id));
        _;
    }

    modifier onlyForRegisteredId(bytes16 _id) {
        require(isIdRegistered(_id));
        _;
    }

    modifier onlyForValidId(bytes16 _id) {
        require(isIdValid(_id));
        _;
    }

    modifier onlyWithPendingWithdrawal() {
        require(withdrawableAmount() != 0);
        _;
    }

    modifier onlyLoveStoryOwner(bytes16 _id) {
        require(loveStories[_id].owner == msg.sender);
        _;
    }

    // ------------------------------------------------------------

    constructor ()
        public
    {
        initialCost = DEFAULT_INITIAL_COST;
        lockCostPerHour = DEFAULT_LOCK_COST_PER_HOUR;
        maxLockDuration = DEFAULT_MAX_LOCK_DURATION;
    }

    function ()
        public
        payable
    {
    }

    function createCost(uint256 _lockDurationInHours)
        public
        view
        returns (uint256)
    {
        return initialCost.add(lockCostPerHour.mul(_lockDurationInHours));
    }

    function createLoveStory(bytes16 _id, bytes32 _loverName, bytes32 _lovedOneName, uint256 _lockDurationInHours)
        public
        payable
    {
        createLoveStoryWithData(_id, _loverName, _lovedOneName, _lockDurationInHours, "");
    }

    function createLoveStoryWithData(bytes16 _id, bytes32 _loverName, bytes32 _lovedOneName, uint256 _lockDurationInHours, string _data)
        public
        payable
        onlyForValidId(_id)
        onlyForUnregisteredId(_id)
    {
        require(msg.value >= createCost(_lockDurationInHours));

        _updateLoveStory(_id, _loverName, _lovedOneName, _lockDurationInHours, _data);
        loveStoriesCount = loveStoriesCount.add(1);

        pendingWithdrawals[owner] = pendingWithdrawals[owner].add(msg.value);

        LoveStory storage _loveStory = loveStories[_id];

        emit LoveStoryCreated (
            _id,
            _loveStory.owner,
            _loveStory.loverName,
            _loveStory.lovedOneName,
            _loveStory.transferCost,
            _loveStory.lockedUntil,
            _loveStory.data
        );
    }

    function updateLoveStory(bytes16 _id, bytes32 _loverName, bytes32 _lovedOneName)
        public
        onlyLoveStoryOwner(_id)
    {
        LoveStory storage _loveStory = loveStories[_id];

        _loveStory.loverName = _loverName;
        _loveStory.lovedOneName = _lovedOneName;

        emit LoveStoryUpdated (
            _id,
            _loveStory.loverName,
            _loveStory.lovedOneName,
            _loveStory.data
        );
    }

    function updateLoveStoryWithData(bytes16 _id, bytes32 _loverName, bytes32 _lovedOneName, string _data)
        public
        onlyLoveStoryOwner(_id)
    {
        LoveStory storage _loveStory = loveStories[_id];

        _loveStory.loverName = _loverName;
        _loveStory.lovedOneName = _lovedOneName;
        _loveStory.data = _data;

        emit LoveStoryUpdated (
            _id,
            _loveStory.loverName,
            _loveStory.lovedOneName,
            _loveStory.data
        );
    }

    function transferCost(bytes16 _id, uint256 _lockDurationInHours)
        public
        view
        onlyForValidId(_id)
        onlyForRegisteredId(_id)
        returns (uint256)
    {
        return loveStories[_id].transferCost.add(lockCostPerHour.mul(_lockDurationInHours));
    }

    function transferLoveStory(bytes16 _id, bytes32 _loverName, bytes32 _lovedOneName, uint256 _lockDurationInHours)
        public
        payable
        onlyForValidId(_id)
        onlyForRegisteredId(_id)
    {
        LoveStory storage _loveStory = loveStories[_id];
        transferLoveStoryWithData(_id, _loverName, _lovedOneName, _lockDurationInHours, _loveStory.data);
    }

    function transferLoveStoryWithData(bytes16 _id, bytes32 _loverName, bytes32 _lovedOneName, uint256 _lockDurationInHours, string _data)
        public
        payable
        onlyForValidId(_id)
        onlyForRegisteredId(_id)
    {
        LoveStory storage _loveStory = loveStories[_id];
        address _oldOwner = _loveStory.owner;

        require(_oldOwner != msg.sender);
        require(msg.value >= transferCost(_id, _lockDurationInHours));
        require(now >= _loveStory.lockedUntil);

        _updateLoveStory(_id, _loverName, _lovedOneName, _lockDurationInHours, _data);

        uint256 _developerPayment = msg.value.mul(DEVELOPER_CUT).div(100);
        uint256 _oldOwnerPayment = msg.value.sub(_developerPayment);

        require(msg.value == _developerPayment.add(_oldOwnerPayment));

        pendingWithdrawals[owner] = pendingWithdrawals[owner].add(_developerPayment);
        pendingWithdrawals[_oldOwner] = pendingWithdrawals[_oldOwner].add(_oldOwnerPayment);

        emit LoveStoryTransferred (
            _id,
            _oldOwner,
            _loveStory.owner,
            _loveStory.loverName,
            _loveStory.lovedOneName,
            _loveStory.transferCost,
            _loveStory.lockedUntil,
            _loveStory.data
        );
    }

    function readLoveStory(bytes16 _id)
        public
        view
        returns (address _loveStoryOwner, bytes32 _loverName, bytes32 _lovedOneName, uint256 _transferCost, uint256 _lockedUntil, string _data)
    {
        LoveStory storage _loveStory = loveStories[_id];

        _loveStoryOwner = _loveStory.owner;
        _loverName = _loveStory.loverName;
        _lovedOneName = _loveStory.lovedOneName;
        _transferCost = _loveStory.transferCost;
        _lockedUntil = _loveStory.lockedUntil;
        _data = _loveStory.data;
    }

    function isIdRegistered(bytes16 _id)
        public
        view
        returns (bool)
    {
        return loveStories[_id].owner != 0x0;
    }

    function isIdValid(bytes16 _id)
        public
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < 16; i = i.add(1))
        {
            if (i == 0)
            {
                // First char must be between &#39;a&#39; and &#39;z&#39;. It CAN&#39;T be NULL.
                if ( ! _isLowercaseLetter(_id[i]) )
                {
                    return false;
                }
            }
            else if (i == 15)
            {
                // Last char must between &#39;a&#39; and &#39;z&#39;. It can also be a terminating NULL.
                if ( !(_isLowercaseLetter(_id[i]) || _id[i] == 0) )
                {
                    return false;
                }
            }
            else
            {
                // In-between chars must between &#39;a&#39; and &#39;z&#39; or &#39;-&#39;. Otherwise, they should be the unset bytes.
                // The last part is verifiied by requiring that an in-bewteen char that is NULL
                // must *also* be follwed by a NULL.
                if ( !(_isLowercaseLetter(_id[i]) || (_id[i] == 0x2D && _id[i+1] != 0) || (_id[i] == _id[i+1] && _id[i] == 0)) )
                {
                    return false;
                }
            }
        }

        return true;
    }

    function withdrawableAmount()
        public
        view
        returns (uint256)
    {
        return pendingWithdrawals[msg.sender];
    }

    function withdraw()
        external
        nonReentrant
        onlyWithPendingWithdrawal
    {
        uint256 amount = pendingWithdrawals[msg.sender];

        pendingWithdrawals[msg.sender] = 0;

        msg.sender.transfer(amount);

        emit Withdrawal (
            msg.sender,
            amount
        );
    }

    function withdrawableAmountFor(address _withdrawer)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return pendingWithdrawals[_withdrawer];
    }

    function changeInitialCost(uint256 _initialCost)
        external
        onlyOwner
    {
        initialCost = _initialCost;
    }

    function changeLockCostPerHour(uint256 _lockCostPerHour)
        external
        onlyOwner
    {
        lockCostPerHour = _lockCostPerHour;
    }

    function changeMaxLockDuration(uint256 _maxLockDuration)
        external
        onlyOwner
    {
        maxLockDuration = _maxLockDuration;
    }

    // ------------------------------------------------------------

    function _updateLoveStory(bytes16 _id, bytes32 _loverName, bytes32 _lovedOneName, uint256 _lockDurationInHours, string _data)
        private
    {
        require(_lockDurationInHours * 1 hours <= maxLockDuration);

        LoveStory storage _loveStory = loveStories[_id];

        _loveStory.owner = msg.sender;
        _loveStory.loverName = _loverName;
        _loveStory.lovedOneName = _lovedOneName;
        _loveStory.transferCost = msg.value.mul(2);
        _loveStory.lockedUntil = now.add(_lockDurationInHours.mul(1 hours));
        _loveStory.data = _data;
    }

    function _isLowercaseLetter(byte _char)
        private
        pure
        returns (bool)
    {
        // Char must be a small case letter: [a-z]
        return _char >= 0x61 && _char <= 0x7A;
    }
}