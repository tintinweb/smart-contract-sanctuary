//SourceUnit: tron_v2.sol

// Sources flattened with hardhat v2.0.5 https://hardhat.org

// File contracts/utils/Context.sol

pragma solidity >=0.4.22 <0.6.0;

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
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/utils/Ownable.sol

pragma solidity >=0.4.22 <0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor () internal {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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


// File contracts/utils/Adminable.sol

pragma solidity >=0.4.22 <0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 */
contract Adminable is Context {
    address private _admin;

    event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor () internal {
        _admin = _msgSender();
        emit AdminshipTransferred(address(0), _admin);
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(), "Adminable: caller is not the admin");
        _;
    }

    /**
     * @dev Returns true if the caller is the current admin.
     */
    function isAdmin() public view returns (bool) {
        return _msgSender() == _admin;
    }

    /**
     * @dev Leaves the contract without admin. It will not be possible to call
     * `onlyAdmin` functions anymore. Can only be called by the current admin.
     *
     * NOTE: Renouncing adminship will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function renounceAdminship() public onlyAdmin {
        emit AdminshipTransferred(_admin, address(0));
        _admin = address(0);
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function transferAdminship(address newAdmin) public onlyAdmin {
        _transferAdminship(newAdmin);
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     */
    function _transferAdminship(address newAdmin) internal {
        require(newAdmin != address(0), "Adminable: new admin is the zero address");
        emit AdminshipTransferred(_admin, newAdmin);
        _admin = newAdmin;
    }
}


// File contracts/utils/Address.sol

pragma solidity >=0.4.22 <0.6.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address  recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


// File contracts/utils/SafeMath.sol

pragma solidity >=0.4.22 <0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
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
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


// File contracts/Pool.sol

pragma solidity ^0.5.8;




contract Pool is Ownable, Adminable {
    using SafeMath for uint256;
    using Address for address;

    uint256 blockPerDay = 28800;
    uint256 startBlock;

    address payable public dev;
    uint256 public saving;
    uint256 public reserve;
    uint256 internal totalReserve;
    mapping(uint256 => uint256) public prize;
    uint256 public totalPrize;

    uint256 public rounds = 0;

    uint256 public fullJoined;

    uint256 internal lastRiskDay;

    event SavingWithdraw(address indexed account, uint256 amount);
    event ReserveWithdraw(address indexed account, uint256 amount);
    event PrizeWithdraw(address indexed account, uint256 amount, uint256 day);

    constructor() public {
        startBlock = block.number;
    }

    function setDev(address payable addr) public onlyOwner {
        dev = addr;
    }

    function poolDeposit(uint256 amount) internal {
        devDeposit(amount.mul(5).div(100));
        savingDeposit(amount.mul(86).div(100));
        reserveDeposit(amount.mul(3).div(100));
        prizeDeposit(amount.mul(6).div(100));

        fullJoined = fullJoined.add(amount);
    }

    function devDeposit(uint256 amount) private {
        dev.transfer(amount);
    }

    function savingDeposit(uint256 amount) private {
        saving = saving.add(amount);
    }

    function savingWithdraw(address payable account, uint256 amount) internal {
        require(amount <= saving, "Pool: saving amount not enougth");

        saving = saving.sub(amount);

        account.transfer(amount);

        emit SavingWithdraw(account, amount);
    }

    function reserveDeposit(uint256 amount) private {
        reserve = reserve.add(amount);
        totalReserve = totalReserve.add(amount);
    }
    function reserveWithdraw(address account, uint256 amount) internal {
        reserve = reserve.sub(amount);

        saving = saving.add(amount);

        emit ReserveWithdraw(account, amount);
    }

    function prizeDeposit(uint256 amount) private {
        uint256 _currentDay = currentDay();
        prize[_currentDay] = prize[_currentDay].add(amount);
        totalPrize = totalPrize.add(amount);
    }
    function prizeWithdraw(address account, uint256 amount, uint256 _day) internal {
        require(amount <= prize[_day], "Pool: prize amount not enougth");

        prize[_day] = prize[_day].sub(amount);
        totalPrize = totalPrize.sub(amount);

        saving = saving.add(amount);

        emit PrizeWithdraw(account, amount, _day);
    }

    function currentRate() public view returns(uint256) {
        return rate(rounds);
    }
    function rate(uint256 _rounds) public pure returns(uint256) {
        if (_rounds == 0) {
            return 200;
        } else if (_rounds == 1) {
            return 150;
        } else if (_rounds > 1) {
            return 100;
        }
    }

    function currentDay() public view returns(uint256) {
        return block.number.sub(startBlock).div(blockPerDay);
    }

    function withdrawReserve(uint256 amount) external onlyOwner {
        require(amount <= reserve, "amount must less than reserve amount");
        reserve = reserve.sub(amount);
        msg.sender.transfer(amount);
    }

    function withdrawPrize(uint256 amount) external onlyOwner {
        require(amount <= totalPrize, "amount must less than totalPrize amount");
        totalPrize = totalPrize.sub(amount);

        if (totalPrize < prize[currentDay()]) {
            prize[currentDay()] = totalPrize;
        }

        msg.sender.transfer(amount);
    }
}


// File contracts/utils/Math.sol

pragma solidity >=0.4.22 <0.6.0;

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File contracts/TrxMoltenStore.sol

pragma solidity ^0.5.8;



contract TrxMoltenStore is Pool {
    using SafeMath for uint256;
    using Address for address;

    struct User {
        address account;
        uint256[] amount;
        uint256[] joinDay;
        uint256[] rounds;
        address referrer;

        address[] invitee;
        uint256 inviteeAmount;

        uint256 deep;

        uint256 staticWithdrawn;
        uint256 historyStaticWithdrawn;

        uint256 inviteeReward;
        uint256 inviteWithdrawn;
        uint256 historyInviteWithdrawn;

        uint256 allInviteeReward;
        uint256 allInviteWithdrawn;
        uint256 historyAllInviteWithdrawn;

        uint256 systemReward;

        mapping(uint256 => uint256) dayInviteeAmount;

        uint256 withdrawRounds;
    }

    uint256 public constant MIN_AMOUNT_FIRST = 100 trx;
    uint256 public constant MAX_AMOUNT_FIRST = 100000 trx;
    uint256 public constant WITHDRAW_FEE = 5 trx;
    uint256 private constant MIN_AMOUNT_COMM_AMOUNT = 300000 trx;
    uint256 private constant MIN_AMOUNT_COMM_JOIN_AMOUNT = 100000 trx;
    uint256 private constant MIN_AMOUNT_RISK = 100000 trx;

    mapping(address => User) users;
    mapping(address => bool) private userJoined;
    uint256 public holdUserNum;

    mapping(uint256 => address[]) private inviteeRanking;
    mapping(uint256 => uint256) private inviteeRankingMinIndex;
    mapping(uint256 => mapping(address => bool)) private inviteeRankingKeys;

    mapping(uint256 => address[]) private allInviteeRanking;
    mapping(uint256 => uint256) private allInviteeRankingMinIndex;
    mapping(uint256 => mapping(address => bool)) private allInviteeRankingKeys;

    uint256 public totalWithdraw;

    mapping(uint256 => uint256) dayTotalWithdraw;

    event Deposit(address indexed user, address referrer, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 fee);
    event EmitRisk(uint256 indexed rounds, uint256 savingAmount, uint256 day);

    function deposit(address _referrer) external payable {
        if (isOut(msg.sender)) {
            _clearMe();
        }

        require(userJoined[_referrer] || _referrer == address(0x0), "Reward: user not join");

        uint256 amount = msg.value;
        uint256 _currentDay = currentDay();

        uint256 count = joinCount(msg.sender);
        bool hasJoin = count == 0;
        if (hasJoin) {
            require(amount >= MIN_AMOUNT_FIRST, "First must greater than 100 trx");
            require(amount <= MAX_AMOUNT_FIRST, "First must less than 100000 trx");
        } else {

            uint256 lastAmount = lastJoinAmount(msg.sender);
            require(amount >= lastAmount.mul(110).div(100), "Must 10% greater than last amount");
        }

        poolDeposit(amount);

        users[msg.sender].account = msg.sender;
        users[msg.sender].amount.push(amount);
        users[msg.sender].joinDay.push(_currentDay);
        users[msg.sender].rounds.push(rounds);
        if (!userJoined[msg.sender] || (users[msg.sender].invitee.length == 0 && users[msg.sender].referrer == address(0x0))) {
            users[msg.sender].referrer = _referrer;
            users[msg.sender].deep = users[_referrer].deep + 1;
            users[_referrer].invitee.push(msg.sender);
        }

        address referrer = users[msg.sender].referrer;

        if (referrer != address(0x0)) {
            users[referrer].dayInviteeAmount[_currentDay] = users[referrer].dayInviteeAmount[_currentDay].add(amount);
            users[referrer].inviteeAmount = users[referrer].inviteeAmount.add(amount);

            if (!userJoined[msg.sender]) {
                users[referrer].inviteeReward = users[referrer].inviteeReward.add(amount.mul(10).div(100));
            } else {
                users[referrer].inviteeReward = users[referrer].inviteeReward.add(amount.mul(8).div(100));
            }

            address[] storage currentDayRanking = inviteeRanking[_currentDay];
            if (!inviteeRankingKeys[_currentDay][referrer]) {
                if (currentDayRanking.length == 0) {
                    currentDayRanking.push(referrer);
                    inviteeRankingKeys[_currentDay][referrer] = true;
                    inviteeRankingMinIndex[_currentDay] = 0;
                } else if (currentDayRanking.length < 5) {
                    currentDayRanking.push(referrer);
                    inviteeRankingKeys[_currentDay][referrer] = true;
                    if (users[currentDayRanking[inviteeRankingMinIndex[_currentDay]]].dayInviteeAmount[_currentDay] > users[referrer].dayInviteeAmount[_currentDay]) {
                        inviteeRankingMinIndex[_currentDay] = currentDayRanking.length - 1;
                    }
                } else {
                    if (users[currentDayRanking[inviteeRankingMinIndex[_currentDay]]].dayInviteeAmount[_currentDay] < users[referrer].dayInviteeAmount[_currentDay]) {
                        inviteeRankingKeys[_currentDay][referrer] = true;
                        delete inviteeRankingKeys[_currentDay][currentDayRanking[inviteeRankingMinIndex[_currentDay]]];
                        currentDayRanking[inviteeRankingMinIndex[_currentDay]] = referrer;
                        setInviteeRankingMinIndex();
                    }
                }
            } else {
                setInviteeRankingMinIndex();
            }

            if (joinAmount(referrer) >= MIN_AMOUNT_COMM_JOIN_AMOUNT && users[referrer].inviteeAmount >= MIN_AMOUNT_COMM_AMOUNT) {
                address[] storage currentDayAllRanking = allInviteeRanking[_currentDay];
                if (!allInviteeRankingKeys[_currentDay][referrer]) {
                    if (currentDayAllRanking.length == 0) {
                        currentDayAllRanking.push(referrer);
                        allInviteeRankingKeys[_currentDay][referrer] = true;
                        allInviteeRankingMinIndex[_currentDay] = 0;
                    } else if (currentDayAllRanking.length < 20) {
                        currentDayAllRanking.push(referrer);
                        allInviteeRankingKeys[_currentDay][referrer] = true;
                        if (users[currentDayAllRanking[allInviteeRankingMinIndex[_currentDay]]].dayInviteeAmount[_currentDay] > users[referrer].dayInviteeAmount[_currentDay]) {
                            allInviteeRankingMinIndex[_currentDay] = currentDayAllRanking.length - 1;
                        }
                    } else {
                        if (users[currentDayAllRanking[allInviteeRankingMinIndex[_currentDay]]].dayInviteeAmount[_currentDay] < users[referrer].dayInviteeAmount[_currentDay]) {
                            allInviteeRankingKeys[_currentDay][referrer] = true;
                            delete allInviteeRankingKeys[_currentDay][currentDayAllRanking[allInviteeRankingMinIndex[_currentDay]]];
                            currentDayAllRanking[allInviteeRankingMinIndex[_currentDay]] = referrer;
                            setAllInviteeRankingMinIndex();
                        }
                    }
                } else {
                    setAllInviteeRankingMinIndex();
                }
            }
        }

        if (!userJoined[msg.sender]) {
            userJoined[msg.sender] = true;
            holdUserNum++;
        }

        users[msg.sender].withdrawRounds = rounds;

        emit Deposit(msg.sender, referrer, amount);
    }

    function setInviteeRankingMinIndex() private {
        uint256 _currentDay = currentDay();
        address[] memory currentDayRanking = inviteeRanking[_currentDay];
        uint256 index;
        for (uint256 i = 1; i < currentDayRanking.length; i ++) {
            if (users[currentDayRanking[i]].dayInviteeAmount[_currentDay] < users[currentDayRanking[index]].dayInviteeAmount[_currentDay]) {
                index = i;
            }
        }
        inviteeRankingMinIndex[_currentDay] = index;
    }
    function setAllInviteeRankingMinIndex() private {
        uint256 _currentDay = currentDay();
        address[] memory currentDayAllRanking = allInviteeRanking[_currentDay];
        uint256 index;
        for (uint256 i = 1; i < currentDayAllRanking.length; i ++) {
            if (users[currentDayAllRanking[i]].dayInviteeAmount[_currentDay] < users[currentDayAllRanking[index]].dayInviteeAmount[_currentDay]) {
                index = i;
            }
        }
        allInviteeRankingMinIndex[_currentDay] = index;
    }

    function withdraw() external {
        require(fullJoined > 0, "No user join");

        uint256 _currentDay = currentDay();

        if (isOut(msg.sender)) {
            _clearMe();
            return;
        }

        uint256 _joinAmount = joinAmount(msg.sender);

        uint256 _pendingReward = pendingReward(msg.sender);
        uint256 _inviteReward = inviteReward(msg.sender);
        uint256 _allInviteReward = allInviteReward(msg.sender);

        uint256 _reserveReward;

        if (rounds > users[msg.sender].withdrawRounds) {
            _reserveReward = _joinAmount.mul(totalReserve).div(fullJoined);
        }

        uint256 totalReward = _pendingReward.add(_inviteReward).add(_allInviteReward).add(_reserveReward);

        require(totalReward > 0, "Don't have reward");

        uint256 realReward = Math.min(totalReward, _joinAmount.mul(250).div(100));
        uint256 realPendingReward = _pendingReward.mul(realReward).div(totalReward);
        uint256 realInviteReward = _inviteReward.mul(realReward).div(totalReward);
        uint256 realAllInviteReward = _allInviteReward.mul(realReward).div(totalReward);

        uint256 withdrawReward = realReward
            .sub(users[msg.sender].staticWithdrawn)
            .sub(users[msg.sender].inviteWithdrawn)
            .sub(users[msg.sender].allInviteWithdrawn);

        if (withdrawReward > WITHDRAW_FEE) {
            withdrawReward = withdrawReward.sub(WITHDRAW_FEE);
        } else {
            withdrawReward = 0;
        }

        updateAllInviteeReward(
            msg.sender,
            realPendingReward.sub(users[msg.sender].staticWithdrawn)
        );

        users[msg.sender].staticWithdrawn = realPendingReward;
        users[msg.sender].inviteWithdrawn = realInviteReward;
        users[msg.sender].allInviteWithdrawn = realAllInviteReward;

        savingWithdraw(msg.sender, withdrawReward);

        totalWithdraw = totalWithdraw.add(withdrawReward);
        dayTotalWithdraw[_currentDay] = dayTotalWithdraw[_currentDay].add(withdrawReward);

        users[msg.sender].withdrawRounds = rounds;

        emit Withdraw(msg.sender, withdrawReward, WITHDRAW_FEE);

        if ((_currentDay - lastRiskDay) > 30 && saving < MIN_AMOUNT_RISK.add(fullJoined.div(_currentDay.add(100)))) {
            emitRisk();
            if (isOut(msg.sender)) {
                _clearMe();
                return;
            }
        }
    }

    function updateAllInviteeReward(address account, uint256 reward) private  {
        address parent = users[account].referrer;
        uint256 dis;

        while(parent != address(0x0) && dis <= 31) {
            dis = users[account].deep - users[parent].deep;

            if (dis == 1) {
                users[parent].allInviteeReward = users[parent].allInviteeReward
                    .add(reward.mul(30).div(100));
            } else if (dis == 2) {
                users[parent].allInviteeReward = users[parent].allInviteeReward
                    .add(reward.mul(10).div(100));
            } else if (dis == 3) {
                users[parent].allInviteeReward = users[parent].allInviteeReward
                    .add(reward.mul(5).div(100));
            } else if (dis <= 31) {
                users[parent].allInviteeReward = users[parent].allInviteeReward
                    .add(reward.mul(3).div(100));
            }

            parent = users[parent].referrer;
        }
    }

    function publishInviteeReward(uint256 _day) external onlyAdmin returns(address[] memory currentDayRanking, uint256[] memory rewardList) {
        require(inviteeRanking[_day].length > 0, "Can't to call this");

        currentDayRanking = inviteeRanking[_day];
        uint256 length = currentDayRanking.length;
        rewardList = new uint256[](length);

        uint256 amount;
        for (uint256 i = 0; i < length; i++) {
            amount = amount.add(users[currentDayRanking[i]].dayInviteeAmount[_day]);
        }

        uint256 total = prize[_day].mul(8).div(100).mul(length).div(5);

        for (uint256 i = 0; i < length; i++) {
            uint256 reward = total.mul(users[currentDayRanking[i]].dayInviteeAmount[_day]).div(amount);
            prizeWithdraw(currentDayRanking[i], reward, _day);
            users[currentDayRanking[i]].systemReward = users[currentDayRanking[i]].systemReward.add(reward);
            rewardList[i] = reward;
        }

        delete inviteeRanking[_day];

        return (currentDayRanking, rewardList);
    }

    function publishAllInviteeReward(uint256 _day) external onlyAdmin returns(address[] memory currentDayAllInviteeRanking, uint256[] memory rewardList) {
        require(allInviteeRanking[_day].length > 0, "Can't to call this");

        currentDayAllInviteeRanking = allInviteeRanking[_day];
        uint256 length = currentDayAllInviteeRanking.length;
        rewardList = new uint256[](length);

        uint256 amount = 0;
        for (uint256 i = 0; i < length; i++) {
            amount = amount.add(users[currentDayAllInviteeRanking[i]].dayInviteeAmount[_day]);
        }

        uint256 total = prize[_day].mul(30).div(100).mul(length).div(20);

        for (uint256 i = 0; i < length; i++) {
            uint256 reward = total.mul(users[currentDayAllInviteeRanking[i]].dayInviteeAmount[_day]).div(amount);
            prizeWithdraw(currentDayAllInviteeRanking[i], reward, _day);
            users[currentDayAllInviteeRanking[i]].systemReward = users[currentDayAllInviteeRanking[i]].systemReward.add(reward);
            rewardList[i] = reward;
        }

        delete allInviteeRanking[_day];

        return (currentDayAllInviteeRanking, rewardList);
    }

    function emitRisk() private {
        rounds++;
        lastRiskDay = currentDay();

        emit EmitRisk(rounds, saving, lastRiskDay);
    }

    function _clearMe() private {
        address account = msg.sender;

        if (users[account].referrer != address(0x0)) {
            users[users[account].referrer].inviteeAmount = users[users[account].referrer].inviteeAmount.sub(joinAmount(account));
        }

        users[account].historyInviteWithdrawn = users[account].historyInviteWithdrawn.add(users[account].inviteWithdrawn);
        users[account].inviteeReward = users[account].inviteeReward.sub(users[account].inviteWithdrawn);
        delete users[account].inviteWithdrawn;

        users[account].historyAllInviteWithdrawn = users[account].historyAllInviteWithdrawn.add(users[account].allInviteWithdrawn);
        users[account].allInviteeReward = users[account].allInviteeReward.sub(users[account].allInviteWithdrawn);
        delete users[account].allInviteWithdrawn;

        users[account].historyStaticWithdrawn = users[account].historyStaticWithdrawn.add(users[account].staticWithdrawn);
        delete users[account].amount;
        delete users[account].joinDay;
        delete users[account].rounds;
        delete users[account].staticWithdrawn;
    }

    function allInvitee(address account) external view returns(address[] memory) {
        (address[] memory list, uint256 len) = allInviteeList(account);

        address[] memory _returns = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            _returns[i] = list[i];
        }

        return _returns;
    }
    function allInviteeList(address account) private view returns(address[] memory, uint256) {
        address[] memory stack = new address[](1000);
        uint256 len;

        address[] memory all = new address[](1000);
        uint256 len1;

        stack[0] = account;
        len++;
        while (len > 0) {
            address temp = stack[len - 1];
            len--;

            if (len1 > 998 && users[temp].deep.sub(users[account].deep) > 31) {
                break;
            }

            if (account != temp) {
                all[len1++] = temp;
            }

            for (uint256 i = 0; i < users[temp].invitee.length; i++) {
                address addr = users[temp].invitee[i];
                stack[len] = addr;
                len++;
            }
        }

        return (all, len1);
    }

    function joinAmount(address account) public view returns(uint256) {
        uint256 _joinAmount = 0;
        for (uint256 i = 0; i < users[account].joinDay.length; i++) {
            _joinAmount = _joinAmount.add(joinAmountAtIndex(account, i));
        }

        return _joinAmount;
    }

    function joinAmountAtIndex(address account, uint256 index) private view returns(uint256) {
        return users[account].amount[index];
    }

    function joinCount(address account) public view returns(uint256) {
        return users[account].joinDay.length;
    }

    function lastJoinAmount(address account) public view returns(uint256) {
        uint256 count = joinCount(account);
        if (count > 0) {
            return joinAmountAtIndex(account, count.sub(1));
        } else {
            return 0;
        }
    }

    function isFirst(address account) external view returns(bool) {
        return joinCount(account) == 0;
    }

    function historyTotalReward(address account) external view returns(uint256) {
        return users[account].historyStaticWithdrawn
            .add(users[account].historyInviteWithdrawn)
            .add(users[account].historyAllInviteWithdrawn);
    }
    function historyStaticReward(address account) external view returns(uint256) {
        return users[account].historyStaticWithdrawn;
    }
    function historyInviteReward(address account) external view returns(uint256) {
        return users[account].historyInviteWithdrawn;
    }
    function historyAllInviteReward(address account) external view returns(uint256) {
        return users[account].historyAllInviteWithdrawn;
    }

    function freeReward(address account) public view returns(uint256) {
        return Math.min(joinAmount(account).mul(250).div(100), totalReward(account));
    }

    function frozenReward(address account) external view returns(uint256) {
        uint256 _joinAmount = joinAmount(account);
        uint256 _totalRewad = totalReward(account);

        return _joinAmount.mul(250).div(100)
            .sub(Math.min(_joinAmount.mul(250).div(100), _totalRewad));
    }

    function receivedReward(address account) public view returns(uint256) {
        return users[account].staticWithdrawn
            .add(users[account].inviteWithdrawn)
            .add(users[account].allInviteWithdrawn);
    }

    function toReceiveReward(address account) external view returns(uint256) {
        return freeReward(account).sub(receivedReward(account));
    }

    function totalReward(address account) public view returns(uint256) {
        return pendingReward(account)
            .add(inviteReward(account))
            .add(allInviteReward(account));
    }

    function withdrawableReward(address account) public view returns(uint256) {
        return totalReward(account)
            .sub(users[account].staticWithdrawn)
            .sub(users[account].inviteWithdrawn)
            .sub(users[account].allInviteWithdrawn);
    }

    function pendingReward(address account) public view returns(uint256) {
        uint256 _currentDay = currentDay();

        uint256 reward;
        for (uint256 i = 0; i < users[account].joinDay.length; i++) {
            uint256 joinDay = users[account].joinDay[i];
            uint256 amount = users[account].amount[i];
            uint256 rounds = users[account].rounds[i];
            uint256 num = _currentDay.sub(joinDay);
            uint256 _rate = rate(rounds);

            uint256 backDay = uint256(10000).div(_rate);

            uint256 rewardDay;
            if (num > backDay) {
                rewardDay = amount.mul(backDay.mul(_rate))
                    .add(amount.mul((num.sub(backDay)).mul(50)))
                    .div(10000);
            } else {
                rewardDay = amount.mul(num.mul(_rate)).div(10000);
            }

            if (rewardDay > amount.mul(250).div(100)) {
                rewardDay = amount.mul(250).div(100);
            }

            reward = reward.add(rewardDay);
        }

        return reward;
    }

    function withdrawablePendingReward(address account) external view returns(uint256) {
        return pendingReward(account).sub(users[account].staticWithdrawn);
    }


    function inviteReward(address account) public view returns(uint256) {
        return users[account].inviteeReward;
    }

    function withdrawableInviteReward(address account) external view returns(uint256) {
        return inviteReward(account).sub(users[account].inviteWithdrawn);
    }


    function allInviteReward(address account) public view returns(uint256) {
        return users[account].allInviteeReward.add(users[account].systemReward);
    }

    function withdrawableAllInviteReward(address account) external view returns(uint256) {
        return allInviteReward(account).sub(users[account].allInviteWithdrawn);
    }

    function getInviteeRanking(uint256 _day) public view returns(address[] memory) {
        return inviteeRanking[_day];
    }
    function getTodayInviteeRanking() external view returns(address[] memory) {
        return getInviteeRanking(currentDay());
    }

    function getAllInviteeRanking(uint256 _day) public view returns(address[] memory) {
        return allInviteeRanking[_day];
    }
    function getTodayAllInviteeRanking() external view returns(address[] memory) {
        return getAllInviteeRanking(currentDay());
    }

    function getUserReferrer(address account) public view returns(address) {
        return users[account].referrer;
    }

    function inviteeNum(address account) external view returns(uint256) {
        return users[account].invitee.length;
    }

    function allInviteeNum(address account) external view returns(uint256) {
        (, uint256 len) = allInviteeList(account);
        return len;
    }

    function withdrawed(address account) external view returns(uint256) {
        return users[account].staticWithdrawn
            .add(users[account].inviteWithdrawn)
            .add(users[account].allInviteWithdrawn);
    }

    function isOut(address account) public view returns(bool) {
        return (rounds > users[account].withdrawRounds) && (users[account].staticWithdrawn.add(users[account].inviteWithdrawn).add(users[account].allInviteWithdrawn) >= joinAmount(account));
    }

    function todayTotalWithdraw() external view returns(uint256) {
        return dayTotalWithdraw[currentDay()];
    }
}