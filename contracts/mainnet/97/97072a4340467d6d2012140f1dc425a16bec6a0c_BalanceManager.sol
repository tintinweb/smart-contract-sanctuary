/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: (c) Armor.Fi DAO, 2021

pragma solidity ^0.6.6;

interface IKeeperRecipient {
    function keep() external;
}

interface IArmorMaster {
    function registerModule(bytes32 _key, address _module) external;
    function getModule(bytes32 _key) external view returns(address);
    function keep() external;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * 
 * @dev Completely default OpenZeppelin.
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeOwnable() internal {
        require(_owner == address(0), "already initialized");
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }


    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;

    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingOwner, "only pending owner can call this function");
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private __gap;
}

library Bytes32 {
    function toString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

/**
 * @dev Each arCore contract is a module to enable simple communication and interoperability. ArmorMaster.sol is master.
**/
contract ArmorModule {
    IArmorMaster internal _master;

    using Bytes32 for bytes32;

    modifier onlyOwner() {
        require(msg.sender == Ownable(address(_master)).owner(), "only owner can call this function");
        _;
    }

    modifier doKeep() {
        _master.keep();
        _;
    }

    modifier onlyModule(bytes32 _module) {
        string memory message = string(abi.encodePacked("only module ", _module.toString()," can call this function"));
        require(msg.sender == getModule(_module), message);
        _;
    }

    /**
     * @dev Used when multiple can call.
    **/
    modifier onlyModules(bytes32 _moduleOne, bytes32 _moduleTwo) {
        string memory message = string(abi.encodePacked("only module ", _moduleOne.toString()," or ", _moduleTwo.toString()," can call this function"));
        require(msg.sender == getModule(_moduleOne) || msg.sender == getModule(_moduleTwo), message);
        _;
    }

    function initializeModule(address _armorMaster) internal {
        require(address(_master) == address(0), "already initialized");
        require(_armorMaster != address(0), "master cannot be zero address");
        _master = IArmorMaster(_armorMaster);
    }

    function changeMaster(address _newMaster) external onlyOwner {
        _master = IArmorMaster(_newMaster);
    }

    function getModule(bytes32 _key) internal view returns(address) {
        return _master.getModule(_key);
    }
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 * 
 * @dev Default OpenZeppelin
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


/**
 * @title Balance Expire Traker
 * @dev Keeps track of expiration of user balances.
**/
contract BalanceExpireTracker {
    
    using SafeMath for uint64;
    using SafeMath for uint256;
    
    // Don't want to keep typing address(0). Typecasting just for clarity.
    uint160 private constant EMPTY = uint160(address(0));
    
    // 3 days for each step.
    uint64 public constant BUCKET_STEP = 3 days;

    // indicates where to start from 
    // points where TokenInfo with (expiredAt / BUCKET_STEP) == index
    mapping(uint64 => Bucket) public checkPoints;

    struct Bucket {
        uint160 head;
        uint160 tail;
    }

    // points first active nft
    uint160 public head;
    // points last active nft
    uint160 public tail;

    // maps expireId to deposit info
    mapping(uint160 => ExpireMetadata) public infos; 
    
    // pack data to reduce gas
    struct ExpireMetadata {
        uint160 next; // zero if there is no further information
        uint160 prev;
        uint64 expiresAt;
    }

    function expired() internal view returns(bool) {
        if(infos[head].expiresAt == 0) {
            return false;
        }

        if(infos[head].expiresAt <= uint64(now)){
            return true;
        }

        return false;
    }

    // using typecasted expireId to save gas
    function push(uint160 expireId, uint64 expiresAt) 
      internal 
    {
        require(expireId != EMPTY, "info id address(0) cannot be supported");

        // If this is a replacement for a current balance, remove it's current link first.
        if (infos[expireId].expiresAt > 0) pop(expireId);

        uint64 bucket = uint64( (expiresAt.div(BUCKET_STEP)).mul(BUCKET_STEP) );
        if (head == EMPTY) {
            // all the nfts are expired. so just add
            head = expireId;
            tail = expireId;
            checkPoints[bucket] = Bucket(expireId, expireId);
            infos[expireId] = ExpireMetadata(EMPTY,EMPTY,expiresAt);
            
            return;
        }
            
        // there is active nft. we need to find where to push
        // first check if this expires faster than head
        if (infos[head].expiresAt >= expiresAt) {
            // pushing nft is going to expire first
            // update head
            infos[head].prev = expireId;
            infos[expireId] = ExpireMetadata(head, EMPTY,expiresAt);
            head = expireId;
            
            // update head of bucket
            Bucket storage b = checkPoints[bucket];
            b.head = expireId;
                
            if(b.tail == EMPTY) {
                // if tail is zero, this bucket was empty should fill tail with expireId
                b.tail = expireId;
            }
                
            // this case can end now
            return;
        }
          
        // then check if depositing nft will last more than latest
        if (infos[tail].expiresAt <= expiresAt) {
            infos[tail].next = expireId;
            // push nft at tail
            infos[expireId] = ExpireMetadata(EMPTY,tail,expiresAt);
            tail = expireId;
            
            // update tail of bucket
            Bucket storage b = checkPoints[bucket];
            b.tail = expireId;
            
            if(b.head == EMPTY) {
              // if head is zero, this bucket was empty should fill head with expireId
              b.head = expireId;
            }
            
            // this case is done now
            return;
        }
          
        // so our nft is somewhere in between
        if (checkPoints[bucket].head != EMPTY) {
            //bucket is not empty
            //we just need to find our neighbor in the bucket
            uint160 cursor = checkPoints[bucket].head;
        
            // iterate until we find our nft's next
            while(infos[cursor].expiresAt < expiresAt){
                cursor = infos[cursor].next;
            }
        
            infos[expireId] = ExpireMetadata(cursor, infos[cursor].prev, expiresAt);
            infos[infos[cursor].prev].next = expireId;
            infos[cursor].prev = expireId;
        
            //now update bucket's head/tail data
            Bucket storage b = checkPoints[bucket];
            
            if (infos[b.head].prev == expireId){
                b.head = expireId;
            }
            
            if (infos[b.tail].next == expireId){
                b.tail = expireId;
            }
        } else {
            //bucket is empty
            //should find which bucket has depositing nft's closest neighbor
            // step 1 find prev bucket
            uint64 prevCursor = uint64( bucket.sub(BUCKET_STEP) );
            
            while(checkPoints[prevCursor].tail == EMPTY){
              prevCursor = uint64( prevCursor.sub(BUCKET_STEP) );
            }
    
            uint160 prev = checkPoints[prevCursor].tail;
            uint160 next = infos[prev].next;
    
            // step 2 link prev buckets tail - nft - next buckets head
            infos[expireId] = ExpireMetadata(next,prev,expiresAt);
            infos[prev].next = expireId;
            infos[next].prev = expireId;
    
            checkPoints[bucket].head = expireId;
            checkPoints[bucket].tail = expireId;
        }
    }

    function pop(uint160 expireId) internal {
        uint64 expiresAt = infos[expireId].expiresAt;
        uint64 bucket = uint64( (expiresAt.div(BUCKET_STEP)).mul(BUCKET_STEP) );
        // check if bucket is empty
        // if bucket is empty, end
        if(checkPoints[bucket].head == EMPTY){
            return;
        }
        // if bucket is not empty, iterate through
        // if expiresAt of current cursor is larger than expiresAt of parameter, reverts
        for(uint160 cursor = checkPoints[bucket].head; infos[cursor].expiresAt <= expiresAt; cursor = infos[cursor].next) {
            ExpireMetadata memory info = infos[cursor];
            // if expiresAt is same of paramter, check if expireId is same
            if(info.expiresAt == expiresAt && cursor == expireId) {
                // if yes, delete it
                // if cursor was head, move head to cursor.next
                if(head == cursor) {
                    head = info.next;
                }
                // if cursor was tail, move tail to cursor.prev
                if(tail == cursor) {
                    tail = info.prev;
                }
                // if cursor was head of bucket
                if(checkPoints[bucket].head == cursor){
                    // and cursor.next is still in same bucket, move head to cursor.next
                    if(infos[info.next].expiresAt.div(BUCKET_STEP) == bucket.div(BUCKET_STEP)){
                        checkPoints[bucket].head = info.next;
                    } else {
                        // delete whole checkpoint if bucket is now empty
                        delete checkPoints[bucket];
                    }
                } else if(checkPoints[bucket].tail == cursor){
                    // since bucket.tail == bucket.haed == cursor case is handled at the above,
                    // we only have to handle bucket.tail == cursor != bucket.head
                    checkPoints[bucket].tail = info.prev;
                }
                // now we handled all tail/head situation, we have to connect prev and next
                infos[info.prev].next = info.next;
                infos[info.next].prev = info.prev;
                // delete info and end
                delete infos[cursor];
                return;
            }
            // if not, continue -> since there can be same expires at with multiple expireId
        }
        //changed to return for consistency
        return;
        //revert("Info does not exist");
    }

    uint256[50] private __gap;
}

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

interface IBalanceManager {
  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Loss(address indexed user, uint256 amount);
  event PriceChange(address indexed user, uint256 price);
  event AffiliatePaid(address indexed affiliate, address indexed referral, uint256 amount, uint256 timestamp);
  event ReferralAdded(address indexed affiliate, address indexed referral, uint256 timestamp);
  function deposit(address _referrer) external payable;
  function withdraw(uint256 _amount) external;
  function initialize(address _armormaster, address _devWallet) external;
  function balanceOf(address _user) external view returns (uint256);
  function perSecondPrice(address _user) external view returns(uint256);
  function changePrice(address user, uint64 _newPricePerSec) external;
}

interface IPlanManager {
  // Event to notify frontend of plan update.
  event PlanUpdate(address indexed user, address[] protocols, uint256[] amounts, uint256 endTime);
  function initialize(address _armorManager) external;
  function changePrice(address _scAddress, uint256 _pricePerAmount) external;
  function updatePlan(address[] calldata _protocols, uint256[] calldata _coverAmounts) external;
  function checkCoverage(address _user, address _protocol, uint256 _hacktime, uint256 _amount) external view returns (uint256, bool);
  function coverageLeft(address _protocol) external view returns(uint256);
  function getCurrentPlan(address _user) external view returns(uint128 start, uint128 end);
  function updateExpireTime(address _user, uint256 _expiry) external;
  function planRedeemed(address _user, uint256 _planIndex, address _protocol) external;
  function totalUsedCover(address _scAddress) external view returns (uint256);
}

interface IRewardDistributionRecipient {
    function notifyRewardAmount(uint256 reward) payable external;
}

interface IRewardManager is IRewardDistributionRecipient {
  function initialize(address _rewardToken, address _stakeManager) external;
  function stake(address _user, uint256 _coverPrice, uint256 _nftId) external;
  function withdraw(address _user, uint256 _coverPrice, uint256 _nftId) external;
  function getReward(address payable _user) external;
}

interface IUtilizationFarm is IRewardDistributionRecipient {
  function initialize(address _rewardToken, address _stakeManager) external;
  function stake(address _user, uint256 _coverPrice) external;
  function withdraw(address _user, uint256 _coverPrice) external;
  function getReward(address payable _user) external;
}
/**
 * @dev BorrowManager is where borrowers do all their interaction and it holds funds
 *      until they're sent to the StakeManager.
 **/
contract BalanceManager is ArmorModule, IBalanceManager, BalanceExpireTracker {

    using SafeMath for uint256;
    using SafeMath for uint128;

    // Wallet of the developers for if a developer fee is being paid.
    address public devWallet;

    // With lastTime and secondPrice we can determine balance by second.
    struct Balance {
        uint64 lastTime;
        uint64 perSecondPrice;
        uint128 lastBalance;
    }
    
    // keep track of monthly payments and start/end of those
    mapping (address => Balance) public balances;

    // user => referrer
    mapping (address => address) public referrers;

    // Percent of funds that go to development--start with 0 and can change.
    uint128 public devPercent;

    // Percent of funds referrers receive. 20 = 2%.
    uint128 public refPercent;

    // Percent of funds given to governance stakers.
    uint128 public govPercent;

    // Denominator used to when distributing tokens 1000 == 100%
    uint128 public constant DENOMINATOR = 1000;

    // True if utilization farming is still ongoing
    bool public ufOn;

    // Mapping of shields so we don't reward them for U.F.
    mapping (address => bool) public arShields;
     
    // Block withdrawals within 1 hour of depositing.
    modifier onceAnHour {
        require(block.timestamp >= balances[msg.sender].lastTime.add(1 hours), "You must wait an hour after your last update to withdraw.");
        _;
    }

    /**
     * @dev Call updateBalance before any action is taken by a user.
     * @param _user The user whose balance we need to update.
     **/
    modifier update(address _user)
    {
        uint256 _oldBal = _updateBalance(_user);
        _;
        _updateBalanceActions(_user, _oldBal);
    }

    /**
     * @dev Keep function can be called by anyone to balances that have been expired. This pays out addresses and removes used cover.
     *      This is external because the doKeep modifier calls back to ArmorMaster, which then calls back to here (and elsewhere).
    **/
    function keep() external {
        // Restrict each keep to 2 removes max.
        for (uint256 i = 0; i < 2; i++) {
        
            if (infos[head].expiresAt != 0 && infos[head].expiresAt <= now) {
                address oldHead = address(head);
                uint256 oldBal = _updateBalance(oldHead);
                _updateBalanceActions(oldHead, oldBal);
            } else return;
            
        }
    }

    /**
     * @param _armorMaster Address of the ArmorMaster contract.
     **/
    function initialize(address _armorMaster, address _devWallet)
      external
      override
    {
        initializeModule(_armorMaster);
        devWallet = _devWallet;
        devPercent = 0;     // 0 %
        refPercent = 25;    // 2.5%
        govPercent = 0;     // 0%
        ufOn = true;
    }

    /**
     * @dev Borrower deposits an amount of ETH to pay for coverage.
     * @param _referrer User who referred the depositor.
    **/
    function deposit(address _referrer) 
      external
      payable
      override
      doKeep
      update(msg.sender)
    {
        if ( referrers[msg.sender] == address(0) ) {
            referrers[msg.sender] = _referrer != address(0) ? _referrer : devWallet;
            emit ReferralAdded(_referrer, msg.sender, block.timestamp);
        }
        
        require(msg.value > 0, "No Ether was deposited.");

        balances[msg.sender].lastBalance = uint128(balances[msg.sender].lastBalance.add(msg.value));
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Borrower withdraws ETH from their balance.
     * @param _amount The amount of ETH to withdraw.
    **/
    function withdraw(uint256 _amount)
      external
      override
      onceAnHour
      doKeep
      update(msg.sender)
    {
        require(_amount > 0, "Must withdraw more than 0.");
        Balance memory balance = balances[msg.sender];

        // Since cost increases per second, it's difficult to estimate the correct amount. Withdraw it all in that case.
        if (balance.lastBalance > _amount) {
            balance.lastBalance = uint128( balance.lastBalance.sub(_amount) );
        } else {
            _amount = balance.lastBalance;
            balance.lastBalance = 0;
        }
        
        balances[msg.sender] = balance;
        msg.sender.transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @dev Find the current balance of a user to the second.
     * @param _user The user whose balance to find.
     **/
    function balanceOf(address _user)
      public
      view
      override
    returns (uint256)
    {
        Balance memory balance = balances[_user];

        // We adjust balance on chain based on how many blocks have passed.
        uint256 lastBalance = balance.lastBalance;

        uint256 timeElapsed = block.timestamp.sub(balance.lastTime);
        uint256 cost = timeElapsed.mul(balance.perSecondPrice);

        // If the elapsed time has brought balance to 0, make it 0.
        uint256 newBalance;
        if (lastBalance > cost) newBalance = lastBalance.sub(cost);
        else newBalance = 0;

        return newBalance;
    }

    /**
     * @dev Send funds to governanceStaker and rewardManager (don't want to have to send them with every transaction).
    **/
    function releaseFunds()
      public
    {
       uint256 govBalance = balances[getModule("GOVSTAKE")].lastBalance;
       // If staking contracts are sent too low of a reward, it can mess up distribution.
       if (govBalance >= 1 ether / 10) {
           IRewardManager(getModule("GOVSTAKE")).notifyRewardAmount{value: govBalance}(govBalance);
           balances[getModule("GOVSTAKE")].lastBalance = 0;
       }
       
       uint256 rewardBalance = balances[getModule("REWARD")].lastBalance;
       // If staking contracts are sent too low of a reward, it can mess up distribution.
       if (rewardBalance >= 1 ether / 10) {
           IRewardManager(getModule("REWARD")).notifyRewardAmount{value: rewardBalance}(rewardBalance);
           balances[getModule("REWARD")].lastBalance = 0;
       }
    }

    function perSecondPrice(address _user)
      external
      override
      view
    returns(uint256)
    {
        Balance memory balance = balances[_user];
        return balance.perSecondPrice;
    }
    
    /**
     * @dev PlanManager has the ability to change the price that a user is paying for their insurance.
     * @param _user The user whose price we are changing.
     * @param _newPrice the new price per second that the user will be paying.
     **/
    function changePrice(address _user, uint64 _newPrice)
      external
      override
      onlyModule("PLAN")
    {
        _updateBalance(_user);
        _priceChange(_user, _newPrice);
        if (_newPrice > 0) _adjustExpiry(_user, balances[_user].lastBalance.div(_newPrice).add(block.timestamp));
        else _adjustExpiry(_user, block.timestamp);
    }
    
    /**
     * @dev Update a borrower's balance to it's adjusted amount.
     * @param _user The address to be updated.
     **/
    function _updateBalance(address _user)
      internal
      returns (uint256 oldBalance)
    {
        Balance memory balance = balances[_user];

        oldBalance = balance.lastBalance;
        uint256 newBalance = balanceOf(_user);

        // newBalance should never be greater than last balance.
        uint256 loss = oldBalance.sub(newBalance);
    
        _payPercents(_user, uint128(loss));

        // Update storage balance.
        balance.lastBalance = uint128(newBalance);
        balance.lastTime = uint64(block.timestamp);
        emit Loss(_user, loss);
        
        balances[_user] = balance;
    }

    /**
     * @dev Actions relating to balance updates.
     * @param _user The user who we're updating.
     * @param _oldBal The original balance in the tx.
    **/
    function _updateBalanceActions(address _user, uint256 _oldBal)
      internal
    {
        Balance memory balance = balances[_user];
        if (_oldBal != balance.lastBalance && balance.perSecondPrice > 0) {
            _notifyBalanceChange(_user, balance.lastBalance, balance.perSecondPrice);
            _adjustExpiry(_user, balance.lastBalance.div(balance.perSecondPrice).add(block.timestamp));
        }
        if (balance.lastBalance == 0 && _oldBal != 0) {
            _priceChange(_user, 0);
        }
    }
    
    /**
     * @dev handle the user's balance change. this will interact with UFB
     * @param _user user's address
     * @param _newPrice user's new per sec price
     **/

    function _priceChange(address _user, uint64 _newPrice) 
      internal 
    {
        Balance memory balance = balances[_user];
        uint64 originalPrice = balance.perSecondPrice;
        
        if(originalPrice == _newPrice) {
            // no need to process
            return;
        }

        if (ufOn && !arShields[_user]) {
            if(originalPrice > _newPrice) {
                // price is decreasing
                IUtilizationFarm(getModule("UFB")).withdraw(_user, originalPrice.sub(_newPrice));
            } else {
                // price is increasing
                IUtilizationFarm(getModule("UFB")).stake(_user, _newPrice.sub(originalPrice));
            } 
        }
        
        balances[_user].perSecondPrice = _newPrice;
        emit PriceChange(_user, _newPrice);
    }
    
    /**
     * @dev Adjust when a balance expires.
     * @param _user Address of the user whose expiry we're adjusting.
     * @param _newExpiry New Unix timestamp of expiry.
    **/
    function _adjustExpiry(address _user, uint256 _newExpiry)
      internal
    {
        if (_newExpiry == block.timestamp) {
            BalanceExpireTracker.pop(uint160(_user));
        } else {
            BalanceExpireTracker.push(uint160(_user), uint64(_newExpiry));
        }
    }
    
    /**
     * @dev Balance has changed so PlanManager's expire time must be either increased or reduced.
    **/
    function _notifyBalanceChange(address _user, uint256 _newBalance, uint256 _newPerSec) 
      internal
    {
        uint256 expiry = _newBalance.div(_newPerSec).add(block.timestamp);
        IPlanManager(getModule("PLAN")).updateExpireTime(_user, expiry); 
    }
    
    /**
     * @dev Give rewards to different places.
     * @param _user User that's being charged.
     * @param _charged Amount of funds charged to the user.
    **/
    function _payPercents(address _user, uint128 _charged)
      internal
    {
        // percents: 20 = 2%.
        uint128 refAmount = referrers[_user] != address(0) ? _charged * refPercent / DENOMINATOR : 0;
        uint128 devAmount = _charged * devPercent / DENOMINATOR;
        uint128 govAmount = _charged * govPercent / DENOMINATOR;
        uint128 nftAmount = uint128( _charged.sub(refAmount).sub(devAmount).sub(govAmount) );
        
        if (refAmount > 0) {
            balances[ referrers[_user] ].lastBalance = uint128( balances[ referrers[_user] ].lastBalance.add(refAmount) );
            emit AffiliatePaid(referrers[_user], _user, refAmount, block.timestamp);
        }
        if (devAmount > 0) balances[devWallet].lastBalance = uint128( balances[devWallet].lastBalance.add(devAmount) );
        if (govAmount > 0) balances[getModule("GOVSTAKE")].lastBalance = uint128( balances[getModule("GOVSTAKE")].lastBalance.add(govAmount) );
        if (nftAmount > 0) balances[getModule("REWARD")].lastBalance = uint128( balances[getModule("REWARD")].lastBalance.add(nftAmount) );
    }
    
    /**
     * @dev Controller can change how much referrers are paid.
     * @param _newPercent New percent referrals receive from revenue. 100 == 10%.
    **/
    function changeRefPercent(uint128 _newPercent)
      external
      onlyOwner
    {
        require(_newPercent <= DENOMINATOR, "new percent cannot be bigger than DENOMINATOR");
        refPercent = _newPercent;
    }
    
    /**
     * @dev Controller can change how much governance is paid.
     * @param _newPercent New percent that governance will receive from revenue. 100 == 10%.
    **/
    function changeGovPercent(uint128 _newPercent)
      external
      onlyOwner
    {
        require(_newPercent <= DENOMINATOR, "new percent cannot be bigger than DENOMINATOR");
        govPercent = _newPercent;
    }
    
    /**
     * @dev Controller can change how much developers are paid.
     * @param _newPercent New percent that devs will receive from revenue. 100 == 10%.
    **/
    function changeDevPercent(uint128 _newPercent)
      external
      onlyOwner
    {
        require(_newPercent <= DENOMINATOR, "new percent cannot be bigger than DENOMINATOR");
        devPercent = _newPercent;
    }
    
    /**
     * @dev Toggle whether utilization farming should be on or off.
    **/
    function toggleUF()
      external
      onlyOwner
    {
        ufOn = !ufOn;
    }
    
    /**
     * @dev Toggle whether address is a shield.
    **/
    function toggleShield(address _shield)
      external
      onlyOwner
    {
        arShields[_shield] = !arShields[_shield];
    }

    // to reset the buckets
    function resetExpiry(uint160[] calldata _idxs) external onlyOwner {
        for(uint256 i = 0; i<_idxs.length; i++) {
            require(infos[_idxs[i]].expiresAt != 0, "not in linkedlist");
            BalanceExpireTracker.pop(_idxs[i]);
            BalanceExpireTracker.push(_idxs[i], infos[_idxs[i]].expiresAt);
        }
    }

    // set desired head and tail
    function _resetBucket(uint64 _bucket, uint160 _head, uint160 _tail) internal {
        require(_bucket % BUCKET_STEP == 0, "INVALID BUCKET");

        require(
            infos[infos[_tail].next].expiresAt >= _bucket + BUCKET_STEP &&
            infos[_tail].expiresAt < _bucket + BUCKET_STEP &&
            infos[_tail].expiresAt >= _bucket,
            "tail is not tail");
        require(
            infos[infos[_head].prev].expiresAt < _bucket &&
            infos[_head].expiresAt < _bucket + BUCKET_STEP &&
            infos[_head].expiresAt >= _bucket,
            "head is not head");
        checkPoints[_bucket].tail = _tail;
        checkPoints[_bucket].head = _head;
    }

    function resetBuckets(uint64[] calldata _buckets, uint160[] calldata _heads, uint160[] calldata _tails) external onlyOwner{
        for(uint256 i = 0 ; i < _buckets.length; i++){
            _resetBucket(_buckets[i], _heads[i], _tails[i]);
        }
    }
}