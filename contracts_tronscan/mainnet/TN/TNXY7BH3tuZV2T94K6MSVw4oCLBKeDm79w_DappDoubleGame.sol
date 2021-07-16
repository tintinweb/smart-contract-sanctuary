//SourceUnit: double.sol

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
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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

contract Constants {

    enum DepositType {X1, X2, X3, X4}

    // Info about particular deposit type
    struct DepositInfo {
        uint256 multiplier;
        uint256 prizeFee;
        uint256 referralFee;
        uint256 dividendFee;
        uint256 adminFee;
        bool isSet;
    }

    //Array of all deposit types info
    DepositInfo[4] public depositsInfo;

    // paid attempts data
    uint256 public playCostPercent = 10;
    uint256 public paidAttemptReferralFeePercentage = 10;
    uint256 public paidAttemptAdminFeePercentage = 20;
    uint256 public paidAttemptPrizeFeePercentage = 70;

    uint256 public dailyPoolPercentageToPlay = 25;

    uint256 public prizePoolPercentageForDaily = 20;

    constructor() internal {
        depositsInfo[uint256(DepositType.X1)].multiplier = 1;
        depositsInfo[uint256(DepositType.X1)].prizeFee = 10;
        depositsInfo[uint256(DepositType.X1)].referralFee = 2;
        depositsInfo[uint256(DepositType.X1)].dividendFee = 10;
        depositsInfo[uint256(DepositType.X1)].adminFee = 3;
        depositsInfo[uint256(DepositType.X1)].isSet = true;

        depositsInfo[uint256(DepositType.X2)].multiplier = 2;
        depositsInfo[uint256(DepositType.X2)].prizeFee = 20;
        depositsInfo[uint256(DepositType.X2)].referralFee = 4;
        depositsInfo[uint256(DepositType.X2)].dividendFee = 20;
        depositsInfo[uint256(DepositType.X2)].adminFee = 6;
        depositsInfo[uint256(DepositType.X2)].isSet = true;

        depositsInfo[uint256(DepositType.X3)].multiplier = 3;
        depositsInfo[uint256(DepositType.X3)].prizeFee = 30;
        depositsInfo[uint256(DepositType.X3)].referralFee = 6;
        depositsInfo[uint256(DepositType.X3)].dividendFee = 30;
        depositsInfo[uint256(DepositType.X3)].adminFee = 9;
        depositsInfo[uint256(DepositType.X3)].isSet = true;

        depositsInfo[uint256(DepositType.X4)].multiplier = 4;
        depositsInfo[uint256(DepositType.X4)].prizeFee = 40;
        depositsInfo[uint256(DepositType.X4)].referralFee = 8;
        depositsInfo[uint256(DepositType.X4)].dividendFee = 40;
        depositsInfo[uint256(DepositType.X4)].adminFee = 12;
        depositsInfo[uint256(DepositType.X4)].isSet = true;
    }

    // Contract Registry keys
    uint256 public constant CONTRACT_USER = 1;
    uint256 public constant CONTRACT_DIVIDEND = 2;
    uint256 public constant CONTRACT_GAME = 3;
    uint256 public constant CONTRACT_STATS = 4;

    string public constant ERROR_WRONG_AMOUNT = "ERROR_WRONG_AMOUNT";
    string public constant ERROR_NOT_AVAILABLE = "ERROR_NOT_AVAILABLE";
    string public constant ERROR_WRONG_USER_ADDRESS = "ERROR_WRONG_USER_ADDRESS";
    string public constant ERROR_ACCESS_DENIED = "ERROR_ACCESS_DENIED";

    string public constant ERROR_NO_CONTRACT = "ERROR_NO_CONTRACT";
}

contract DappDoubleManagement is Ownable, Constants {
    using SafeMath for uint256;

    // Contract Registry
    mapping(uint256 => address) public contractRegistry;

    // Per contract registry
    /* solium-disable-next-line max-len */
    mapping(address => mapping(uint256 => address)) public sourceContractRegistry;

    // Permissions
    mapping(address => mapping(uint256 => bool)) public permissions;

    event PermissionsSet(
        address subject,
        uint256 permission,
        bool value
    );

    event ContractRegistered(
        uint256 key,
        address source,
        address target
    );

    function setPermission(
        address _address,
        uint256 _permission,
        bool _value
    )
    public
    onlyOwner
    {
        permissions[_address][_permission] = _value;
        emit PermissionsSet(_address, _permission, _value);
    }

    function registerContract(
        uint256 _key,
        address _target
    )
    public
    onlyOwner
    {
        contractRegistry[_key] = _target;
        emit ContractRegistered(_key, address(0), _target);
    }

    function registerSourceContract(
        uint256 _key,
        address _source,
        address _target
    )
    public
    onlyOwner
    {
        sourceContractRegistry[_source][_key] = _target;
        emit ContractRegistered(_key, _source, _target);
    }
}

contract Managed is Ownable, Constants {
    using SafeMath for uint256;

    DappDoubleManagement public management;

    address payable public dappDoubleDevelopers;

    modifier requirePermission(uint256 _permissionBit) {
        require(
            hasPermission(msg.sender, _permissionBit),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier canCallOnlyRegisteredContract(uint256 _key) {
        require(
            msg.sender == management.contractRegistry(_key),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier requireContractExistsInRegistry(uint256 _key) {
        require(
            management.contractRegistry(_key) != address(0),
            ERROR_NO_CONTRACT
        );
        _;
    }

    constructor(
        address _managementAddress,
        address payable _dappDoubleDevelopers
    ) public {
        management = DappDoubleManagement(_managementAddress);
        dappDoubleDevelopers = _dappDoubleDevelopers;
    }

    function setManagementContract(address _management) public onlyOwner {
        require(address(0) != _management, ERROR_NO_CONTRACT);

        management = DappDoubleManagement(_management);
    }

    function hasPermission(address _subject, uint256 _permissionBit)
        internal
        view
        returns (bool)
    {
        return management.permissions(_subject, _permissionBit);
    }
}

contract DappDoubleBank is Managed {

    uint256 public statsAmount;
    uint256 public statsGAmount;
    uint256 public statsReferralSuns;

    struct UserData {
        bool exists;
        bool isWithdrawn;

        uint256 totalInAmount;
        uint256 totalOutAmount;

        uint256 depositAmount;
        uint256 totalAmount;
        uint256 generalPoolAmount;

        DepositType depositType;

        uint256 dividendFeeAmount;

        address referral;
        uint256 totalReferralSuns;
        mapping(address => uint256) referralsSuns;
        address[] referrals;
    }

    mapping(address => UserData) public users;

    event Deposit(uint256 time, address user, uint256 value);
    event Withdraw(uint256 time, address user, uint256 value);
    event Win(uint256 time, address user, uint256 value);

    constructor(address _management, address payable _admin) public Managed(_management, _admin) {}

    function getStats(
        address _user
    ) public view returns (uint256[] memory) {
        uint256[] memory stats = new uint256[](11);

        stats[0] = users[_user].exists == true ? 1 : 0;
        //userExists
        stats[1] = users[_user].isWithdrawn == true ? 1 : 0;
        //userIsWithdrawn

        stats[2] = users[_user].totalInAmount;
        //userTotalInAmount
        stats[3] = users[_user].totalOutAmount;
        //userTotalOutAmount

        stats[4] = users[_user].totalAmount;
        //userTotalAmount
        stats[5] = users[_user].generalPoolAmount;
        //userGeneralPoolAmount

        stats[6] = uint256(users[_user].depositType);
        //userDepositType
        stats[7] = users[_user].totalReferralSuns;
        //userTotalReferralSuns

        stats[8] = statsAmount;
        //statsAmount
        stats[9] = statsGAmount;
        //statsGAmount
        stats[10] = statsGAmount;
        //statsReferralSuns

        return stats;
    }

    function getUser(
        address _user
    ) public view returns (
        uint256 userTotalAmount,
        uint256 userDepositAmountWithMargin,
        address referralAddress
    ) {
        userTotalAmount = users[_user].totalAmount;
        userDepositAmountWithMargin = users[_user].depositAmount.mul(depositsInfo[uint256(
            users[_user].depositType
        )].multiplier);
        referralAddress = users[_user].referral;
    }

    function depositWithReferral(
        DepositType _depositType,
        address _referral,
        uint256 _referralRewardPercent
    )
        external
        payable
        requireContractExistsInRegistry(CONTRACT_GAME)
        requireContractExistsInRegistry(CONTRACT_DIVIDEND)
    {
        depositInternal(_depositType, _referral, _referralRewardPercent);
    }

    function deposit(
        DepositType _depositType
    )
        external
        payable
        requireContractExistsInRegistry(CONTRACT_GAME)
        requireContractExistsInRegistry(CONTRACT_DIVIDEND)
    {
        depositInternal(_depositType, address(0), 0);
    }

    function applyPaidAttemptReferral(
        address _user
    )
        external
        payable
        requireContractExistsInRegistry(CONTRACT_GAME)
        canCallOnlyRegisteredContract(CONTRACT_GAME)
    {
        address referral = users[_user].referral;
        users[referral].referralsSuns[msg.sender] = users[referral].referralsSuns[msg.sender].add(
            msg.value
        );

        users[referral].totalReferralSuns = users[referral].totalReferralSuns.add(msg.value);
        users[referral].generalPoolAmount = users[referral].generalPoolAmount.add(msg.value);
    }

    function calculateFees(
        uint256 _value,
        DepositType _depositType
    ) public view returns (
        uint256 prizeFee,
        uint256 referralFee,
        uint256 dividendFee,
        uint256 adminFee
    ) {
        prizeFee = _value.mul(depositsInfo[uint256(_depositType)].prizeFee).div(100);
        referralFee = _value.mul(depositsInfo[uint256(_depositType)].referralFee).div(100);
        dividendFee = _value.mul(depositsInfo[uint256(_depositType)].dividendFee).div(100);
        adminFee = _value.mul(depositsInfo[uint256(_depositType)].adminFee).div(100);
    }

    function depositInternal(DepositType _depositType, address _referral, uint256 _referralRewardPercent) internal {
        require(msg.value > 0, ERROR_WRONG_AMOUNT);
        require(depositsInfo[uint256(_depositType)].isSet, ERROR_NOT_AVAILABLE);

        if (users[msg.sender].exists) {
            require(
                users[msg.sender].isWithdrawn || _depositType == users[msg.sender].depositType,
                ERROR_WRONG_AMOUNT
            );
        }

        (
            uint256 prizeFee,
            uint256 referralFee,
            uint256 dividendFee,
            uint256 adminFee
        ) = calculateFees(msg.value, _depositType);

        uint256 fee = prizeFee.add(referralFee).add(dividendFee).add(adminFee);

        if (users[msg.sender].exists == true) {

            users[msg.sender].totalAmount = users[msg.sender].totalAmount.add(
                msg.value.mul(depositsInfo[uint256(_depositType)].multiplier).sub(fee)
            );

            users[msg.sender].generalPoolAmount = users[msg.sender].generalPoolAmount.add(
                msg.value.sub(fee)
            );

            users[msg.sender].depositAmount = users[msg.sender].depositAmount.add(
                msg.value
            );

            if (users[msg.sender].isWithdrawn == true) {
                users[msg.sender].isWithdrawn = false;
                users[msg.sender].depositType = _depositType;
            }
        } else {
            users[msg.sender].exists = true;
            users[msg.sender].totalAmount = msg.value.mul(depositsInfo[uint256(_depositType)].multiplier).sub(fee);
            users[msg.sender].depositAmount = msg.value;
            users[msg.sender].generalPoolAmount = msg.value.sub(fee);
            users[msg.sender].depositType = _depositType;
        }

        statsAmount = statsAmount.add(users[msg.sender].totalAmount);
        statsGAmount = statsGAmount.add(users[msg.sender].generalPoolAmount);

        users[msg.sender].totalInAmount = users[msg.sender].totalInAmount.add(msg.value);

        users[msg.sender].dividendFeeAmount = users[msg.sender].dividendFeeAmount.add(dividendFee);

        applyFees(
            prizeFee,
            referralFee,
            dividendFee,
            adminFee,
            _referral,
            _referralRewardPercent
        );

        emit Deposit(block.timestamp, msg.sender, msg.value);
    }

    function applyFees(
        uint256 _prizeFee,
        uint256 _referralFee,
        uint256 _dividendFee,
        uint256 _adminFee,

        address _referral,
        uint256 _referralRewardPercent
    ) internal {
        if (_referral == address(0) || _referralRewardPercent == 0) {
            _adminFee = _adminFee.add(_referralFee);
        } else {
            require(users[_referral].exists, ERROR_WRONG_USER_ADDRESS);

            proceedReferralFee(_referral, _referralRewardPercent, _referralFee);
        }

        DappDoubleDividendDistribution(management.contractRegistry(CONTRACT_DIVIDEND)).record(
            msg.sender,
            users[msg.sender].totalAmount,
            _dividendFee.div(2)
        );

        DappDoubleGame(management.contractRegistry(CONTRACT_GAME)).fillPrizePool(_prizeFee);

        dappDoubleDevelopers.transfer(_adminFee);
    }

    function proceedReferralFee(
        address _referral,
        uint256 _referralRewardPercent,
        uint256 _feeAmount
    ) internal {
        uint256 referralFeeAmount = _feeAmount.mul(_referralRewardPercent).div(100);

        if (users[_referral].referralsSuns[msg.sender] == 0) {
            users[_referral].referrals.push(msg.sender);
        }

        users[msg.sender].referral = _referral;

        users[_referral].referralsSuns[msg.sender] = users[_referral].referralsSuns[msg.sender].add(
            referralFeeAmount
        );

        users[_referral].totalReferralSuns = users[_referral].totalReferralSuns.add(referralFeeAmount);
        users[_referral].generalPoolAmount = users[_referral].generalPoolAmount.add(referralFeeAmount);

        users[msg.sender].generalPoolAmount = users[msg.sender].generalPoolAmount.add(
            _feeAmount.sub(referralFeeAmount)
        );
        statsReferralSuns = statsReferralSuns.add(referralFeeAmount);
    }

    function recordWinner(
        address payable _user
    )
        external
        requireContractExistsInRegistry(CONTRACT_GAME)
        canCallOnlyRegisteredContract(CONTRACT_GAME)
    {
        uint256 wonAmount = users[_user].totalAmount.mul(2);

        uint256 dailyPoolDecreaseValue = wonAmount.sub(users[_user].generalPoolAmount);

        DappDoubleDividendDistribution(management.contractRegistry(CONTRACT_DIVIDEND)).record(
            msg.sender,
            users[msg.sender].totalAmount,
            users[msg.sender].dividendFeeAmount.div(2)
        );

        wonAmount = wonAmount.add(
            DappDoubleDividendDistribution(management.contractRegistry(CONTRACT_DIVIDEND)).calculateDividendEarnedAmount(_user)
        );

        DappDoubleGame(management.contractRegistry(CONTRACT_GAME)).decreaseDailyPool(dailyPoolDecreaseValue);

        withdrawInternal(_user, wonAmount);

        emit Win(block.timestamp, _user, wonAmount);
    }

    function withdraw() public requireContractExistsInRegistry(CONTRACT_DIVIDEND) {
        require(users[msg.sender].exists == true, ERROR_ACCESS_DENIED);
        require(users[msg.sender].isWithdrawn == false, ERROR_ACCESS_DENIED);

        DappDoubleDividendDistribution(management.contractRegistry(CONTRACT_DIVIDEND)).record(
            msg.sender,
            0,
            users[msg.sender].dividendFeeAmount.div(2)
        );

        uint256 amount = users[msg.sender].generalPoolAmount.add(
            DappDoubleDividendDistribution(management.contractRegistry(CONTRACT_DIVIDEND)).calculateDividendEarnedAmount(msg.sender)
        );

        withdrawInternal(msg.sender, amount);
    }

    function withdrawInternal(address payable _user, uint256 _amount) internal {
        users[_user].isWithdrawn = true;

        uint256 userTotalAmount = users[_user].totalAmount;

        users[_user].generalPoolAmount = 0;
        users[_user].totalAmount = 0;
        users[_user].dividendFeeAmount = 0;
        users[_user].depositAmount = 0;
        users[_user].totalOutAmount = users[_user].totalOutAmount.add(_amount);
        DappDoubleDividendDistribution(management.contractRegistry(CONTRACT_DIVIDEND)).markWithdrawn(_user, userTotalAmount);

        _user.transfer(_amount);

        emit Withdraw(block.timestamp, _user, _amount);
    }

}

contract DappDoubleData is Managed {
    uint256 nonce;

    constructor(address _management, address payable _admin) public Managed(_management, _admin) {}

    function getStats(address _user) public view returns (uint256[] memory) {
        uint256[] memory gameStats = DappDoubleGame(management.contractRegistry(CONTRACT_GAME)).getStats(_user);
        uint256[] memory userStats = DappDoubleBank(management.contractRegistry(CONTRACT_USER)).getStats(_user);

        uint256[] memory stats = new uint256[](13);

        stats[0] = userStats[5];
        //depositAmount //userGeneralPoolAmount
        stats[1] = userStats[4];
        //userTotalAmount
        stats[2] = userStats[6];
        //marginType //userDepositType
        stats[3] = userStats[2];
        //totalInAmount //userTotalInAmount
        stats[4] = userStats[3];
        //totalOutAmount //userTotalOutAmount
        stats[5] = userStats[7];
        //totalReferralBonusReceived //userTotalReferralSuns
        stats[6] = userStats[0] == 1 && userStats[1] == 0 ? 0 : 1;
        //isMarginAllowedToChange //(userExists == true && userIsWithdrawn == false) ? false : true;
        stats[7] = address(management.contractRegistry(CONTRACT_USER)).balance;
        //currentContractBalance
        stats[8] = DappDoubleDividendDistribution(management.contractRegistry(CONTRACT_DIVIDEND)).calculateDividendEarnedAmount(_user);
        //dividendsAmount
        stats[9] = gameStats[0];
        //DailyPoolUserAttempts
        stats[10] = gameStats[1];
        //DailyPoolEndAt
        stats[11] = gameStats[2];
        //DailyPoolAmount
        stats[12] = gameStats[3];
        //prizePool

        return stats;
    }

    function isUserWon(
        address _user
    )
        external
        requireContractExistsInRegistry(CONTRACT_GAME)
        canCallOnlyRegisteredContract(CONTRACT_GAME)
        returns (bool)
    {
        uint256 userNumber = uint256(keccak256(abi.encodePacked(_user))) % 10;
        uint256 randNumber = pseudoRandom(_user);

        return userNumber == randNumber;
    }

    function pseudoRandom(address _user) private returns (uint256) {
        uint256[] memory userStats = getStats(_user);

        uint256 rand = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                nonce,
                _user,
                userStats[0],
                userStats[1],
                userStats[2],
                userStats[3],
                userStats[4],
                userStats[5],
                userStats[6],
                userStats[7],
                userStats[9],
                userStats[10]
            ))) % 10;

        nonce++;

        return rand;
    }

}

contract DappDoubleDividendDistribution is Managed {

    uint256[] public timestampIndex;

    struct Record {
        uint256 totalAmount;
        uint256 dividendFeeAmount;
    }

    mapping(uint256 => Record) public timedRecord;

    struct User {
        bool isWithdrawn;
        uint256 syncAtIndex;
        uint256 userTotalAmount;
        uint256 dividendEarnedAmount;
    }

    mapping(address => User) public userData;

    constructor(address _management, address payable _admin) public Managed(_management, _admin) {}

    function record(
        address _user,
        uint256 _userTotalAmount,
        uint256 _dividendFeeAmount
    )
        external
        requireContractExistsInRegistry(CONTRACT_USER)
        canCallOnlyRegisteredContract(CONTRACT_USER)
        returns (bool)
    {
        uint256 currentTotalAmount = getCurrentTotalAmount();

        uint256 index = timestampIndex.push(block.timestamp).sub(1);

        timedRecord[index].totalAmount = currentTotalAmount.add(_userTotalAmount);
        timedRecord[index].dividendFeeAmount = _dividendFeeAmount;

        return sync(_user, _userTotalAmount);
    }

    function markWithdrawn(
        address _user,
        uint256 _userTotalAmount
    )
        external
        requireContractExistsInRegistry(CONTRACT_USER)
        canCallOnlyRegisteredContract(CONTRACT_USER)
    {
        uint256 index = timestampIndex.length != 0 ? timestampIndex.length.sub(1) : 0;
        timedRecord[index].totalAmount = timedRecord[index].totalAmount.sub(_userTotalAmount);

        userData[_user].isWithdrawn = true;
    }

    function getCurrentTotalAmount() public view returns (uint256) {
        uint256 index = timestampIndex.length != 0 ? timestampIndex.length.sub(1) : 0;

        return timedRecord[index].totalAmount;
    }

    function isSynced(address _user) public view returns (bool) {
        if (timestampIndex.length < 2) {
            return false;
        }
        return userData[_user].syncAtIndex == timestampIndex.length.sub(1);
    }

    function calculateDividendEarnedAmount(address _user) public view returns (uint256) {
        if (userData[_user].isWithdrawn == true) {
            return 0;
        }

        if (isSynced(_user)) {
            return userData[_user].dividendEarnedAmount;
        }

        uint256 dividendEarnedAmountToAdd;
        uint256 lastIndex = timestampIndex.length;

        for (uint256 i = userData[_user].syncAtIndex.add(1); i < lastIndex; i++) {
            dividendEarnedAmountToAdd = dividendEarnedAmountToAdd.add(
                userData[_user].userTotalAmount.mul(
                    timedRecord[i].dividendFeeAmount
                ).div(
                    timedRecord[i].totalAmount
                )
            );
        }

        return userData[_user].dividendEarnedAmount.add(dividendEarnedAmountToAdd);
    }

    function sync(address _user, uint256 _userTotalAmount) internal returns (bool) {
        require(msg.sender != address(0), ERROR_WRONG_USER_ADDRESS);

        if (timestampIndex.length == 1) {
            userData[_user].userTotalAmount = _userTotalAmount;
            userData[_user].dividendEarnedAmount = timedRecord[0].dividendFeeAmount;
            return true;
        }

        if (isSynced(_user)) {
            return true;
        }

        if (userData[_user].isWithdrawn == true) {
            userData[_user].isWithdrawn = false;
            userData[_user].dividendEarnedAmount = 0;
        }

        userData[_user].userTotalAmount = userData[_user].userTotalAmount.add(_userTotalAmount);
        userData[_user].syncAtIndex = timestampIndex.length.sub(2);
        userData[_user].dividendEarnedAmount = calculateDividendEarnedAmount(_user);
        userData[_user].syncAtIndex = timestampIndex.length.sub(1);

        return true;
    }

}

contract DappDoubleGame is Managed {

    uint256 public prizePool;

    uint256 public dailyPoolPeriod = 1 days;

    DailyPool[] public dailyPools;

    struct DailyPool {
        uint256 endAt;
        uint256 amount;
        mapping(address => uint256) userAttempts;
    }

    constructor(
        address _management,
        address payable _admin,
        uint256 _dailyPoolStartAt
    ) public Managed(_management, _admin) {
        dailyPools.push(
            DailyPool(_dailyPoolStartAt.add(dailyPoolPeriod), 0)
        );
    }

    function getStats(
        address _user
    ) public view returns (uint256[] memory) {
        uint256[] memory stats = new uint256[](4);

        stats[0] = dailyPools[dailyPools.length.sub(1)].userAttempts[_user];
        //DailyPoolUserAttempts
        stats[1] = dailyPools[dailyPools.length.sub(1)].endAt;
        //DailyPoolEndAt
        stats[2] = dailyPools[dailyPools.length.sub(1)].amount;
        //DailyPoolAmount
        stats[3] = prizePool;

        return stats;
    }

    function fillPrizePool(
        uint256 _value
    )
        external
        requireContractExistsInRegistry(CONTRACT_USER)
        canCallOnlyRegisteredContract(CONTRACT_USER)
    {
        if (dailyPools[dailyPools.length.sub(1)].endAt < block.timestamp) {
            prizePool = prizePool.add(_value);
            checkAndStartDaily();
        } else {
            uint256 dailyToAdd = _value.mul(prizePoolPercentageForDaily).div(100);
            prizePool = prizePool.add(_value.sub(dailyToAdd));
            dailyPools[dailyPools.length.sub(1)].amount = dailyPools[dailyPools.length.sub(1)].amount.add(
                dailyToAdd
            );
        }
    }

    function decreaseDailyPool(
        uint256 _value
    )
        external
        requireContractExistsInRegistry(CONTRACT_USER)
        canCallOnlyRegisteredContract(CONTRACT_USER)
    {
        dailyPools[dailyPools.length.sub(1)].amount = dailyPools[dailyPools.length.sub(1)].amount.sub(_value);
    }

    function double()
        external
        payable
        requireContractExistsInRegistry(CONTRACT_USER)
        requireContractExistsInRegistry(CONTRACT_DIVIDEND)
        returns (bool)
    {
        checkAndStartDaily();
        require(dailyPools[dailyPools.length.sub(1)].endAt >= block.timestamp, ERROR_ACCESS_DENIED);

        (
            uint256 userTotalAmount,
            uint256 userDepositAmountWithMargin,
            address userReferral
        ) = DappDoubleBank(management.contractRegistry(CONTRACT_USER)).getUser(msg.sender);

        require(userTotalAmount > 0, ERROR_ACCESS_DENIED);

        if (dailyPools[dailyPools.length.sub(1)].userAttempts[msg.sender] > 0) {
            uint256 playCostAmount = userDepositAmountWithMargin.mul(playCostPercent).div(100);

            require(msg.value >= playCostAmount, ERROR_ACCESS_DENIED);

            applyPaidAttemptFee(playCostAmount, userReferral);
        }

        dailyPools[dailyPools.length.sub(1)].userAttempts[msg.sender] = dailyPools[
            dailyPools.length.sub(1)
        ].userAttempts[msg.sender].add(1);

        if (userTotalAmount > dailyPools[dailyPools.length.sub(1)].amount.mul(dailyPoolPercentageToPlay).div(100)) {
            return false;
        }

        return doubleInternal();
    }

    function checkAndStartDaily() public {
        if (dailyPools[dailyPools.length.sub(1)].endAt < block.timestamp) {
            uint256 prizeAmountForNewDaily = prizePool.mul(prizePoolPercentageForDaily).div(100);

            dailyPools.push(DailyPool(
                    dailyPools[dailyPools.length.sub(1)].endAt.add(dailyPoolPeriod),
                    dailyPools[dailyPools.length.sub(1)].amount.add(prizeAmountForNewDaily)
                ));
            prizePool = prizePool.sub(prizeAmountForNewDaily);
        }
    }

    function applyPaidAttemptFee(uint256 _fee, address _userReferral) internal {
        uint256 adminFee = _fee.mul(paidAttemptAdminFeePercentage).div(100);
        if (_userReferral == address(0)) {
            adminFee = _fee.mul(paidAttemptAdminFeePercentage.add(paidAttemptReferralFeePercentage)).div(100);
        } else {
            DappDoubleBank(management.contractRegistry(CONTRACT_USER))
            .applyPaidAttemptReferral
            .value(paidAttemptReferralFeePercentage)(msg.sender);
        }
        prizePool = prizePool.add(_fee.mul(paidAttemptPrizeFeePercentage).div(100));
        dappDoubleDevelopers.transfer(adminFee);
    }

    function doubleInternal() internal returns (bool) {
        bool isUserWon = DappDoubleData(management.contractRegistry(CONTRACT_STATS)).isUserWon(msg.sender);

        if (!isUserWon) {
            return false;
        }

        DappDoubleBank(management.contractRegistry(CONTRACT_USER)).recordWinner(
            msg.sender
        );

        return true;
    }

}