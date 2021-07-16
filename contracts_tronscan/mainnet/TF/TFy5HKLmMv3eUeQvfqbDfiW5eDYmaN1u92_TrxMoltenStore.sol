//SourceUnit: tron.sol

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

    uint256 public constant ONE_DAY = 28800;

    address payable public dev;
    uint256 public saving;
    uint256 public reserve;
    uint256 internal totalReserve;
    uint256 public totalPrize;

    uint256 public rounds = 1;

    uint256 public fullJoined;

    uint256 internal initialBlock;
    uint256 internal lastRiskBlock;

    event SavingWithdraw(address indexed account, uint256 amount);
    event ReserveWithdraw(address indexed account, uint256 amount);
    event PrizeWithdraw(address indexed account, uint256 amount, uint256 blockNumber);

    constructor() public {
        initialBlock = block.number;
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

    function savingDeposit(uint256 amount) internal {
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
        totalPrize = totalPrize.add(amount);
    }
    function prizeWithdraw(address account, uint256 amount) internal {
        totalPrize = totalPrize.sub(amount);

        saving = saving.add(amount);

        emit PrizeWithdraw(account, amount, block.number);
    }

    function withdrawSaving(uint256 amount) external onlyOwner {
        require(amount <= saving, "amount must less than saving amount");
        saving = saving.sub(amount);
        msg.sender.transfer(amount);
    }
    function depositSaving() external payable onlyOwner {
        saving = saving.add(msg.value);
    }

    function withdrawReserve(uint256 amount) external onlyOwner {
        require(amount <= reserve, "amount must less than reserve amount");
        reserve = reserve.sub(amount);
        msg.sender.transfer(amount);
    }
    function depositReserve() external payable onlyOwner {
        reserve = reserve.add(msg.value);
    }

    function withdrawPrize(uint256 amount) external onlyOwner {
        require(amount <= totalPrize, "amount must less than totalPrize amount");
        totalPrize = totalPrize.sub(amount);

        msg.sender.transfer(amount);
    }
    function depositPrize() external payable onlyOwner {
        totalPrize = totalPrize.add(msg.value);
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
        uint256 amount;
        uint256 lastJoinAmount;
        uint256 rounds;
        address referrer;

        address[] invitee;

        uint256 staticDebt;
        uint256 staticWithdrawn;
        uint256 historyStaticWithdrawn;

        uint256 inviteeReward;
        uint256 inviteWithdrawn;
        uint256 historyInviteWithdrawn;

        uint256 allInviteeReward;
        uint256 allInviteWithdrawn;
        uint256 historyAllInviteWithdrawn;

        uint256 systemReward;
        uint256 systemWithdrawn;
        uint256 historySystemWithdrawn;

        uint256 withdrawRounds;

        uint256 joinBlock;
        uint256 outBlock;
    }

    uint256 public constant MIN_AMOUNT_FIRST = 100 trx;
    uint256 public constant OLD_MIN_AMOUNT_FIRST = 10000 trx;
    uint256 public constant WITHDRAW_FEE = 5 trx;
    uint256 private constant MIN_AMOUNT_RISK = 100000 trx;

    mapping(address => User) users;
    mapping(address => bool) private userJoined;
    mapping(address => bool) public oldUser;
    uint256 public holdUserNum;

    uint256 public totalWithdraw;

    uint256 private lastPublishBlock;

    event Deposit(address indexed user, address referrer, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 fee, uint256 blockNumber);
    event EmitRisk(uint256 indexed rounds, uint256 savingAmount, uint256 blockNumber);

    constructor() public {
        lastRiskBlock = block.number;
    }

    function sync(address account, uint256 amount, address referrer, address[] memory invitee) public onlyAdmin {
        require(referrer != account, 'TrxMoltenStore: Referrer not be self');

        users[account].account = account;
        users[account].amount = amount;
        users[account].lastJoinAmount = amount;
        users[account].rounds = rounds;
        users[account].referrer = referrer;

        users[account].invitee = invitee;

        users[account].withdrawRounds = rounds;

        users[account].joinBlock = block.number;

        oldUser[account] = true;

        userJoined[account] = true;
        holdUserNum++;

        emit Deposit(account, referrer, amount);
    }

    function deposit(address _referrer) external payable {
        if (isOutWithRisk(msg.sender)) {
            _clearMe();
            if (block.number.sub(users[msg.sender].outBlock) > ONE_DAY) {
                delete users[msg.sender].inviteeReward;
                delete users[msg.sender].allInviteeReward;
                delete users[msg.sender].systemReward;
            }
        }

        require(userJoined[_referrer] || _referrer == address(0x0), "TrxMoltenStore: user not join");

        uint256 amount = msg.value;

        if (oldUser[msg.sender]) {
            require(amount >= OLD_MIN_AMOUNT_FIRST, "First must greater than 10000 trx");
        } else {
            bool noJoin = users[msg.sender].amount == 0;
            if (noJoin) {
                require(amount >= MIN_AMOUNT_FIRST, "First must greater than 100 trx");
            } else {
                uint256 lastAmount = lastJoinAmount(msg.sender);
                require(amount >= lastAmount.mul(110).div(100), "Must 10% greater than last amount");
            }
        }

        poolDeposit(amount);

        if (users[msg.sender].outBlock != 0 && userJoined[msg.sender] && block.number.sub(users[msg.sender].outBlock) > ONE_DAY) {
            delete users[msg.sender].inviteeReward;
            delete users[msg.sender].allInviteeReward;
            delete users[msg.sender].systemReward;
        }

        users[msg.sender].staticDebt = pendingReward(msg.sender);
        users[msg.sender].account = msg.sender;
        users[msg.sender].amount = users[msg.sender].amount.add(amount);
        users[msg.sender].lastJoinAmount = amount;
        users[msg.sender].rounds = rounds;

        if (!userJoined[msg.sender] || (users[msg.sender].invitee.length == 0 && users[msg.sender].referrer == address(0x0))) {
            users[msg.sender].referrer = _referrer;
            users[_referrer].invitee.push(msg.sender);
        }

        address referrer = users[msg.sender].referrer;

        if (referrer != address(0x0) && canReward(referrer)) {
            if (!userJoined[msg.sender]) {
                users[referrer].inviteeReward = users[referrer].inviteeReward.add(amount.mul(10).div(100));
            } else {
                users[referrer].inviteeReward = users[referrer].inviteeReward.add(amount.mul(8).div(100));
            }
        }

        users[msg.sender].withdrawRounds = rounds;
        users[msg.sender].joinBlock = block.number;
        users[msg.sender].outBlock = 0;

        if (oldUser[msg.sender]) {
            delete oldUser[msg.sender];
        }

        if (!userJoined[msg.sender]) {
            userJoined[msg.sender] = true;
            holdUserNum++;
        }

        emit Deposit(msg.sender, referrer, amount);
    }

    function withdraw() external {
        require(fullJoined > 0, "No user join");

        if (isOutWithRisk(msg.sender)) {
            _clearMe();
            return;
        }

        uint256 _joinAmount = joinAmount(msg.sender);

        uint256 _pendingReward = pendingReward(msg.sender);
        uint256 _inviteReward = inviteReward(msg.sender);
        uint256 _allInviteReward = allInviteReward(msg.sender);
        uint256 _systemReward = systemReward(msg.sender);

        uint256 _reserveReward;

        if (rounds > users[msg.sender].withdrawRounds) {
            _reserveReward = _joinAmount.mul(totalReserve).div(fullJoined);
        }

        uint256 totalReward = _pendingReward.add(_inviteReward).add(_allInviteReward).add(_systemReward).add(_reserveReward);

        require(totalReward > 0, "Don't have reward");

        uint256 realReward = Math.min(totalReward, _joinAmount.mul(25).div(10));
        uint256 realPendingReward = _pendingReward.mul(realReward).div(totalReward);
        uint256 realInviteReward = _inviteReward.mul(realReward).div(totalReward);
        uint256 realAllInviteReward = _allInviteReward.mul(realReward).div(totalReward);
        uint256 realSystemReward = _systemReward.mul(realReward).div(totalReward);

        uint256 withdrawReward = realReward
            .sub(users[msg.sender].staticWithdrawn)
            .sub(users[msg.sender].inviteWithdrawn)
            .sub(users[msg.sender].allInviteWithdrawn)
            .sub(users[msg.sender].systemWithdrawn);

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
        users[msg.sender].systemWithdrawn = realSystemReward;

        savingWithdraw(msg.sender, withdrawReward);

        totalWithdraw = totalWithdraw.add(withdrawReward);

        users[msg.sender].withdrawRounds = rounds;

        emit Withdraw(msg.sender, withdrawReward, WITHDRAW_FEE, block.number);

        bool clearFlag;
        if (isOut(msg.sender)) {
            clearFlag = true;
            _clearMe();
        }

        if ((block.number - lastRiskBlock) > 30 * ONE_DAY && saving < MIN_AMOUNT_RISK.add(fullJoined.div(block.number.sub(initialBlock).div(ONE_DAY).add(100)))) {
            emitRisk();
            if (isOutWithRisk(msg.sender) && !clearFlag) {
                _clearMe();
            }
        }
    }

    function updateAllInviteeReward(address account, uint256 reward) private  {
        address parent = users[account].referrer;
        uint256 dis = 1;

        while(parent != address(0x0) && dis <= 21) {
            if (dis <= users[parent].invitee.length && users[parent].amount > 0 && canReward(parent)) {
                if (dis == 1) {
                    users[parent].allInviteeReward = users[parent].allInviteeReward
                        .add(reward.mul(30).div(100));
                } else if (dis == 2) {
                    users[parent].allInviteeReward = users[parent].allInviteeReward
                        .add(reward.mul(10).div(100));
                } else if (dis == 3) {
                    users[parent].allInviteeReward = users[parent].allInviteeReward
                        .add(reward.mul(5).div(100));
                } else if (dis <= 21) {
                    users[parent].allInviteeReward = users[parent].allInviteeReward
                        .add(reward.mul(3).div(100));
                }
            }

            parent = users[parent].referrer;
            dis++;
        }
    }

    function publishReward(address[] memory addresses, uint256[] memory amounts) public onlyAdmin {
        require(block.number - lastPublishBlock > ONE_DAY, 'TrxMoltenStore: must greater 1 day');
        require(addresses.length == amounts.length, 'TrxMoltenStore: address.length must eq amounts.length');

        for (uint256 i = 0; i < addresses.length; i++) {
            if (canReward(addresses[i])) {
                prizeWithdraw(addresses[i], amounts[i]);
                saving = saving.add(amounts[i]);
                users[addresses[i]].systemReward = users[addresses[i]].systemReward.add(amounts[i]);
            }
        }
    }

    function emitRisk() private {
        rounds++;
        lastRiskBlock = block.number;

        emit EmitRisk(rounds, saving, lastRiskBlock);
    }

    function _clearMe() private {
        address account = msg.sender;

        users[account].historyInviteWithdrawn = users[account].historyInviteWithdrawn.add(users[account].inviteWithdrawn);
        users[account].inviteeReward = users[account].inviteeReward.sub(users[account].inviteWithdrawn);
        delete users[account].inviteWithdrawn;

        users[account].historyAllInviteWithdrawn = users[account].historyAllInviteWithdrawn.add(users[account].allInviteWithdrawn);
        users[account].allInviteeReward = users[account].allInviteeReward.sub(users[account].allInviteWithdrawn);
        delete users[account].allInviteWithdrawn;

        users[account].historySystemWithdrawn = users[account].historySystemWithdrawn.add(users[account].systemWithdrawn);
        users[account].systemReward = users[account].systemReward.sub(users[account].systemWithdrawn);
        delete users[account].systemWithdrawn;

        users[account].historyStaticWithdrawn = users[account].historyStaticWithdrawn.add(users[account].staticWithdrawn);
        delete users[account].amount;
        delete users[account].lastJoinAmount;
        delete users[account].rounds;
        delete users[account].staticDebt;
        delete users[account].staticWithdrawn;

        users[account].outBlock = block.number;
    }

    function joinAmount(address account) public view returns(uint256) {
        return users[account].amount;
    }

    function lastJoinAmount(address account) public view returns(uint256) {
        return users[account].lastJoinAmount;
    }

    function isFirst(address account) external view returns(bool) {
        return users[account].amount == 0;
    }

    function historyTotalReward(address account) external view returns(uint256) {
        return users[account].historyStaticWithdrawn
            .add(users[account].historyInviteWithdrawn)
            .add(users[account].historyAllInviteWithdrawn)
            .add(users[account].historySystemWithdrawn);
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
    function historySystemReward(address account) external view returns(uint256) {
        return users[account].historySystemWithdrawn;
    }

    function freeReward(address account) public view returns(uint256) {
        return Math.min(joinAmount(account).mul(25).div(10), totalReward(account));
    }

    function frozenReward(address account) external view returns(uint256) {
        uint256 _joinAmount = joinAmount(account);
        uint256 _totalRewad = totalReward(account);

        return _joinAmount.mul(25).div(10)
            .sub(Math.min(_joinAmount.mul(25).div(10), _totalRewad));
    }

    function receivedReward(address account) public view returns(uint256) {
        return users[account].staticWithdrawn
            .add(users[account].inviteWithdrawn)
            .add(users[account].allInviteWithdrawn)
            .add(users[account].systemWithdrawn);
    }

    function toReceiveReward(address account) external view returns(uint256) {
        return freeReward(account).sub(receivedReward(account));
    }

    function totalReward(address account) public view returns(uint256) {
        return pendingReward(account)
            .add(inviteReward(account))
            .add(allInviteReward(account))
            .add(systemReward(account));
    }

    function withdrawableReward(address account) public view returns(uint256) {
        return totalReward(account)
            .sub(users[account].staticWithdrawn)
            .sub(users[account].inviteWithdrawn)
            .sub(users[account].allInviteWithdrawn)
            .sub(users[account].systemWithdrawn);
    }

    function pendingReward(address account) public view returns(uint256) {
        uint256 withdrawn = users[account].staticWithdrawn
            .add(users[account].inviteeReward)
            .add(users[account].allInviteeReward)
            .add(users[account].systemReward);
        uint256 _joinAmount = joinAmount(account);

        uint256 rewardPerDay;
        if (withdrawn >= _joinAmount.mul(25).div(10)) {
            rewardPerDay = 0;
        } else {
            if (oldUser[account]) {
                rewardPerDay = reserve
                .mul(2).div(100)
                .mul(_joinAmount.mul(25).div(10).sub(withdrawn).div(13))
                .div(reserve);
            } else {
                rewardPerDay = saving
                .mul(2).div(100)
                .mul(_joinAmount.mul(25).div(10).sub(withdrawn))
                .div(fullJoined.sub(totalWithdraw).mul(25).div(10));
            }
        }

        uint256 _reward = block.number.sub(users[account].joinBlock).div(ONE_DAY).mul(rewardPerDay).add(users[account].staticDebt);

        if (_reward < users[account].staticWithdrawn) {
            _reward = users[account].staticWithdrawn;
        }

        return _reward;
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
        return users[account].allInviteeReward;
    }
    function withdrawableAllInviteReward(address account) external view returns(uint256) {
        return allInviteReward(account).sub(users[account].allInviteWithdrawn);
    }

    function systemReward(address account) public view returns(uint256) {
        return users[account].systemReward;
    }
    function withdrawableSystemReward(address account) external view returns(uint256) {
        return systemReward(account).sub(users[account].systemWithdrawn);
    }

    function getUserReferrer(address account) public view returns(address) {
        return users[account].referrer;
    }

    function inviteeNum(address account) external view returns(uint256) {
        return users[account].invitee.length;
    }

    function withdrawed(address account) external view returns(uint256) {
        return users[account].staticWithdrawn
            .add(users[account].inviteWithdrawn)
            .add(users[account].allInviteWithdrawn)
            .add(users[account].systemWithdrawn);
    }

    function canReward(address account) public view returns(bool) {
        return joinAmount(account).mul(25).div(10) > totalReward(account);
    }

    function isOut(address account) public view returns(bool) {
        return joinAmount(account).mul(25).div(10) <= users[account].staticWithdrawn.add(users[account].inviteWithdrawn).add(users[account].allInviteWithdrawn).add(users[account].systemWithdrawn);
    }

    function isOutWithRisk(address account) public view returns(bool) {
        return (rounds > users[account].withdrawRounds) && (users[account].staticWithdrawn.add(users[account].inviteWithdrawn).add(users[account].allInviteWithdrawn).add(users[account].systemWithdrawn) >= joinAmount(account));
    }
}