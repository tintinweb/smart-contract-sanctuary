// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface IPapStaking {
    enum Tier {
        NOTIER,
        TIER3,
        TIER2,
        TIER1
    }
    struct StakeInstance {
        uint256 amount;
        uint256 lastInteracted;
        uint256 lastStaked; //For staking coolDown
        uint256 rewards;
        Tier tier;
    }

    function UserInfo(address user) external view returns (StakeInstance memory);
}

contract PAPpool {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Declare a set state variable
    EnumerableSet.AddressSet private addressSet;

    address public owner;
    //    bool public poolStarted;
    uint256 public nextAtIndex;

    IERC20 lotteryToken;
    IERC20 poolToken;

    IPapStaking papStaking;

    // Pool infomation
    struct Pool {
        uint256 poolID;
        uint256 timeStart;
        uint256 timeEnd;
        uint256 minAllocation;
        uint256 maxAllocation;
        uint256 tokensAmount;
        uint256 swapPriceNumerator;
        uint256 swapPriceDenominator;
        bool poolStarted;
        bool poolEnded;
    }
    struct participationRegistration {
        uint256 participationId;
        bool participate;
    }

    struct infoParticipants {
        address _participationAddress;
        uint256 _participatedAmount;
        uint256 _tier;
        bool _didWin;
        bool _claimedBack;
    }

    // Mapping string with Pool's Information
    mapping(string => Pool) public pool;

    // Mapping to check user's participation Information
    mapping(uint256 => infoParticipants) public participationBook;

    // Participation index;
    mapping(address => participationRegistration) public didParticipate;

    // participation Array of addresses
    address[] public participationAddress;

    constructor(
        Pool memory _Tier1,
        Pool memory _Tier2,
        Pool memory _Tier3,
        address _owner,
        address _lotteryTokenAddress,
        address _poolTokenAddress,
        address _papStakingAddress
    ) {
        // Owner of the contract
        owner = _owner;

        // DAITokenInfo
        lotteryToken = IERC20(_lotteryTokenAddress);

        // poolTokenInfo
        poolToken = IERC20(_poolTokenAddress);
        papStaking = IPapStaking(_papStakingAddress);

        pool['tierOne'] = Pool({
            poolID: _Tier1.poolID,
            timeStart: _Tier1.timeStart,
            timeEnd: _Tier1.timeEnd,
            minAllocation: _Tier1.minAllocation,
            maxAllocation: _Tier1.maxAllocation,
            tokensAmount: _Tier1.tokensAmount,
            swapPriceNumerator: _Tier1.swapPriceNumerator,
            swapPriceDenominator: _Tier1.swapPriceDenominator,
            poolStarted: false,
            poolEnded: false
        });

        pool['tierTwo'] = Pool({
            poolID: _Tier2.poolID,
            timeStart: _Tier2.timeStart,
            timeEnd: _Tier2.timeEnd,
            minAllocation: _Tier2.minAllocation,
            maxAllocation: _Tier2.maxAllocation,
            tokensAmount: _Tier2.tokensAmount,
            swapPriceNumerator: _Tier2.swapPriceNumerator,
            swapPriceDenominator: _Tier2.swapPriceDenominator,
            poolStarted: false,
            poolEnded: false
        });

        pool['tierThree'] = Pool({
            poolID: _Tier3.poolID,
            timeStart: _Tier3.timeStart,
            timeEnd: _Tier3.timeEnd,
            minAllocation: _Tier3.minAllocation,
            maxAllocation: _Tier3.maxAllocation,
            tokensAmount: _Tier3.tokensAmount,
            swapPriceNumerator: _Tier3.swapPriceNumerator,
            swapPriceDenominator: _Tier3.swapPriceDenominator,
            poolStarted: false,
            poolEnded: false
        });
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Restricted only to owner');
        _;
    }

    function _getTierNumber(uint256 _tierNumber) private pure returns (string memory) {
        string memory _tierIdentifier;
        if (_tierNumber == 1) {
            _tierIdentifier = 'tierOne';
        }
        if (_tierNumber == 2) {
            _tierIdentifier = 'tierTwo';
        }
        if (_tierNumber == 3) {
            _tierIdentifier = 'tierThree';
        }
        return _tierIdentifier;
    }

    // function starting Pool
    function startTierPool(uint256 _TierNumber) public onlyOwner {
        // getting Amount to tansfer;
        string memory _tier = _getTierNumber(_TierNumber);
        require(pool[_tier].poolEnded == false, 'pool already ended');
        require(pool[_tier].poolStarted == false, 'pool already started');
        require(pool[_tier].timeStart <= block.timestamp, 'Too early to set');
        require(pool[_tier].timeEnd >= block.timestamp, 'Too late to set');
        uint256 _idoToDeposit = pool[_tier].tokensAmount;
        lotteryToken.safeTransferFrom(msg.sender, address(this), _idoToDeposit);
        pool[_tier].poolStarted = true;
    }

    function participate(uint256 _amount) public {
        // Retrieving Information about participant and pool
        IPapStaking.StakeInstance memory info = papStaking.UserInfo(msg.sender);
        uint256 _amountStaked = info.amount;
        uint256 _tierNumber = uint256(info.tier);
        require(_amountStaked != 0, "You don't have any staked amount");
        require(_tierNumber > 0, "You don't valid tier");

        string memory _tier = _getTierNumber(_tierNumber);

        uint256 _poolEndTime = pool[_tier].timeEnd;
        uint256 _poolStartTime = pool[_tier].timeStart;

        uint256 _maxParticipationAmount = pool[_tier].maxAllocation;
        uint256 _minParticipationAmount = pool[_tier].minAllocation;

        require(block.timestamp >= _poolStartTime, 'Pool not started');
        require(_poolEndTime >= block.timestamp, 'Pool already Ended');

        require(
            _maxParticipationAmount >=
                ((_amount * pool[_tier].swapPriceNumerator) /
                    pool[_tier].swapPriceDenominator) &&
                ((_amount * pool[_tier].swapPriceNumerator) /
                    pool[_tier].swapPriceDenominator) >=
                _minParticipationAmount,
            'Participation is out of range'
        );

        require(
            didParticipate[msg.sender].participate == false,
            'You have already participated'
        );

        poolToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Updating participationBook information
        participationBook[nextAtIndex]._participationAddress = msg.sender;
        participationBook[nextAtIndex]._participatedAmount = _amount;

        // Updating participation status
        didParticipate[msg.sender].participationId = nextAtIndex;
        didParticipate[msg.sender].participate = true;
        //Adding to addressSet
        addressSet.add(msg.sender);
        //adding msg.senders to address book
        participationAddress.push(msg.sender);
        nextAtIndex++;
    }

    function getParticipationAddress() public view returns (address[] memory) {
        return participationAddress;
    }

    function _generateRandom(uint256 range) internal view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) %
            range;
    }

    // declaring winners w.r.t pools
    function declareWinner(uint256 _tierNumber) public onlyOwner {
        string memory _tier = _getTierNumber(_tierNumber);

        uint256 amountOfDAIsToClaim;

        // Only when poolEnds
        require(block.timestamp >= pool[_tier].timeEnd, 'PoolTime not ended yet');
        require(pool[_tier].poolStarted == true, 'Pool was not started');
        require(pool[_tier].poolEnded == false, 'Pool Already Ended!');

        // Numbers of winners = TokenAmount / maxAllocation
        uint256 _numberOfWinners = pool[_tier].tokensAmount / pool[_tier].maxAllocation;

        uint256 numberOfParticipants = participationAddress.length;
        for (uint256 i = 0; i < numberOfParticipants; i++) {
            if (i < _numberOfWinners) {
                uint256 _randomIndex = _generateRandom(addressSet.length());
                // getting address at that index in addressSet
                address _selectedAddress = addressSet.at(_randomIndex);

                // getting Index of that selected address
                uint256 _winnerAddressId = didParticipate[_selectedAddress]
                    .participationId;
                amountOfDAIsToClaim =
                    amountOfDAIsToClaim +
                    participationBook[_winnerAddressId]._participatedAmount;

                participationBook[_winnerAddressId]._didWin = true;

                // Popping winning address
                addressSet.remove(_selectedAddress);
            } else {
                break;
            }
        }

        // leave awards to claim (in DAI) here and send the remaining balance of DAI back to Owner
        // dai to return = balance(dai) - (amountOfDAIsToClaim * swapprice)
        uint256 dai_return = lotteryToken.balanceOf(address(this)) -
            ((amountOfDAIsToClaim * pool[_tier].swapPriceNumerator) /
                pool[_tier].swapPriceDenominator); //check it later make it right
        //        console.log(lotteryToken.balanceOf(msg.sender));
        lotteryToken.safeTransfer(msg.sender, dai_return);
        //        console.log(lotteryToken.balanceOf(msg.sender));

        //      claim DFTY Token
        //        console.log('DFTY in Contract', poolToken.balanceOf(address(this)));
        //        console.log('But DFTY pool creator can claim', amountOfDAIsToClaim);
        //        console.log('IDO Token in pool', lotteryToken.balanceOf(address(this)));
        poolToken.safeTransfer(msg.sender, amountOfDAIsToClaim);
        //        console.log('DFTY in to return (remaining)', poolToken.balanceOf(address(this)));
        pool[_tier].poolEnded = true;
    }

    function claimWinToken() public {
        require(
            didParticipate[msg.sender].participate == true,
            'You did not participate'
        );
        //      getting participation ID
        uint256 Id = didParticipate[msg.sender].participationId;
        //        console.log('Id',Id);
        //      checking winner or not:
        require(participationBook[Id]._didWin == true, 'You Did not win');
        require(participationBook[Id]._claimedBack == false, 'You already claimed');
        require(
            participationBook[Id]._participationAddress == msg.sender,
            'You cannot claim'
        );

        // (, , uint256 _tierNumber) = papStaking.UserInfo(msg.sender);
        IPapStaking.StakeInstance memory info = papStaking.UserInfo(msg.sender);
        uint256 _tierNumber = uint256(info.tier);

        string memory _tier = _getTierNumber(_tierNumber);
        //      claiming amount amoutput * swap price
        require(pool[_tier].poolEnded == true, 'Pool has not Ended');

        uint256 amountWon = (participationBook[Id]._participatedAmount *
            pool[_tier].swapPriceNumerator) / pool[_tier].swapPriceDenominator;

        lotteryToken.safeTransfer(msg.sender, amountWon);
        //        console.log(lotteryToken.balanceOf(address(this)));
        //        console.log(amountWon);

        participationBook[Id]._claimedBack = true;
    }

    function claimPoolToken() public {
        //      checking if it is winner
        //      getting msg.sender if pariticpated or not
        require(
            didParticipate[msg.sender].participate == true,
            'You did not participate'
        );

        //      getting participation ID
        uint256 participationId = didParticipate[msg.sender].participationId;

        // Getting User Tier
        uint256 _tierNumber = participationBook[participationId]._tier;
        string memory _tier = _getTierNumber(_tierNumber);
        require(pool[_tier].poolEnded == true, 'Pool has not Ended');

        //      checking winner or not:
        require(
            participationBook[participationId]._claimedBack == false,
            'You already claimed'
        );
        require(participationBook[participationId]._didWin == false, 'You Won');
        require(
            participationBook[participationId]._participationAddress == msg.sender,
            'You cannot claim'
        );
        //      claiming amount amoutput * swap price
        uint256 refundamount = participationBook[participationId]._participatedAmount;
        //        console.log(poolToken.balanceOf(address(this)));
        poolToken.safeTransfer(msg.sender, refundamount);
        participationBook[participationId]._claimedBack = true;
        //        console.log(poolToken.balanceOf(address(this)));
    }
}

contract CreatePapPool is Ownable {
    using SafeERC20 for IERC20;
    struct Counter {
        uint256 counter;
    }

    PAPpool[] public papAddressPool;
    address public papStakingAddress;
    address public lastPool;

    // Indexing for each user separate PAP contract addresses
    mapping(address => Counter) public NextCounterAt;
    // For individual pap address, there is index(incremented) that stores address
    mapping(address => mapping(uint256 => address)) public OwnerPoolBook;
    // Array that will store all the PAP addresses, regardless of Owner

    event papStakingChanged(address newPapStaking, uint256 time);

    constructor(address _papStaking) {
        transferOwnership(msg.sender);
        setPapStaking(_papStaking);
    }

    mapping(address => bool) public poolAdmin;

    function setPapStaking(address _papStaking) public onlyOwner {
        require(_papStaking != address(0), "Can't set 0x0 address!");
        papStakingAddress = _papStaking;
        emit papStakingChanged(_papStaking, block.timestamp);
    }

    function setAdmin(address _address) public onlyOwner {
        require(poolAdmin[_address] == false, 'Already Admin');
        poolAdmin[_address] = true;
    }

    function revokeAdmin(address _address) public onlyOwner {
        require(poolAdmin[_address] == true, 'Not Admin');
        poolAdmin[_address] = false;
    }

    modifier isAdmin() {
        require(poolAdmin[msg.sender] == true, 'restricted to Admins!');
        _;
    }

    /*
    @dev: function to allocate information as per pool, this function can be called once. It will create all tire at once.
    @Params _Tier: Array of parameter(from front end), that is passed as transaction that will create pool
    */
    function createPool(
        PAPpool.Pool memory _Tier1,
        PAPpool.Pool memory _Tier2,
        PAPpool.Pool memory _Tier3,
        address _lotteryTokenAddress,
        address _poolTokenAddress
    ) external isAdmin {
        // checking Parameters length
        //        require(_Tier1.length == 6 && _Tier2.length == 6 && _Tier3.length == 6, 'Wrong Tier Parameters');
        // StartTime to be more than endTime
        require(
            _Tier1.timeStart <= _Tier1.timeEnd &&
                _Tier2.timeStart <= _Tier2.timeEnd &&
                _Tier3.timeStart <= _Tier3.timeEnd,
            'EndTime to be more than startTime'
        );
        // _timeStart Cannot be in past
        require(
            _Tier1.timeStart >= block.timestamp &&
                _Tier2.timeStart >= block.timestamp &&
                _Tier3.timeStart >= block.timestamp,
            'Time cannot be in Past'
        );
        // maxAllocation >= minAllocation
        require(
            _Tier1.maxAllocation >= _Tier1.minAllocation &&
                _Tier2.maxAllocation >= _Tier2.minAllocation &&
                _Tier3.maxAllocation >= _Tier3.minAllocation,
            'maxAllocation >= minAllocation'
        );
        //
        //        uint256 _tokenAmountT1 = (_Tier1.tokensAmount;
        //        uint256 _tokenAmountT2 = (_Tier2.maxAllocation * _Tier2.swapPriceNumerator) /
        //            _Tier2.swapPriceDenominator;
        //        uint256 _tokenAmountT3 = (_Tier3.maxAllocation * _Tier3.swapPriceNumerator) /
        //            _Tier3.swapPriceDenominator;

        // get current counter
        uint256 _nextCounter = NextCounterAt[msg.sender].counter;

        PAPpool pappool = new PAPpool(
            _Tier1,
            _Tier2,
            _Tier3,
            msg.sender,
            _lotteryTokenAddress,
            _poolTokenAddress,
            papStakingAddress
        );
        papAddressPool.push(pappool);
        lastPool = address(pappool);
        OwnerPoolBook[msg.sender][_nextCounter] = address(pappool);
        NextCounterAt[msg.sender].counter++;
    }

    //
    function PAPAddresses() public view returns (PAPpool[] memory) {
        return papAddressPool;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}