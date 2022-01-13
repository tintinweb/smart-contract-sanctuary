// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './PapStaking.sol';

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

contract PAPpool {
    using SafeERC20 for IERC20Extented;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 constant DELAY = 3 days;

    address public owner;

    IERC20Extented lotteryToken;
    IERC20Extented poolToken;
    PapStaking papStaking;

    struct Pool {
        uint256 poolID;
        uint256 timeStart;
        uint256 timeEnd;
        uint256 minAllocation;
        uint256 maxAllocation;
        uint256 tokensAmount;
        uint256 swapPriceNumerator;
        uint256 swapPriceDenominator;
        bool finished;
    }

    struct infoParticipants {
        address _participationAddress;
        uint256 _participatedAmount;
        PapStaking.Tier _tier;
        bool _didWin;
        bool _claimedBack;
        bool _didParticipate;
    }

    mapping(address => infoParticipants) public participants;

    mapping(PapStaking.Tier => Pool) public pool;
    mapping(PapStaking.Tier => uint256) totalSupply;
    mapping(PapStaking.Tier => uint256) raised;
    mapping(PapStaking.Tier => address[]) winners;
    mapping(PapStaking.Tier => address[]) participantsAddressesByTier;
    mapping(PapStaking.Tier => EnumerableSet.AddressSet) private addressSet;

    constructor(
        Pool memory _Tier1,
        Pool memory _Tier2,
        Pool memory _Tier3,
        address _owner,
        address _lotteryTokenAddress,
        address _poolTokenAddress,
        address _papStakingAddress
    ) {
        owner = _owner;

        lotteryToken = IERC20Extented(_lotteryTokenAddress);

        poolToken = IERC20Extented(_poolTokenAddress);
        papStaking = PapStaking(_papStakingAddress);

        pool[PapStaking.Tier.TIER1] = _Tier1;
        pool[PapStaking.Tier.TIER2] = _Tier2;
        pool[PapStaking.Tier.TIER3] = _Tier3;

        totalSupply[PapStaking.Tier.TIER1] = _Tier1.tokensAmount;
        totalSupply[PapStaking.Tier.TIER2] = _Tier2.tokensAmount;
        totalSupply[PapStaking.Tier.TIER3] = _Tier3.tokensAmount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Restricted only to owner');
        _;
    }

    function participate(uint256 _amount) public {
        // Retrieving Information about participant and pool
        PapStaking.StakeInstance memory info = papStaking.UserInfo(msg.sender);

        PapStaking.Tier _tier = info.tier;
        Pool storage _pool = pool[_tier];

        require(
            _tier != PapStaking.Tier.NOTIER,
            "participate: you don't have a valid tier"
        );
        require(block.timestamp <= _pool.timeEnd, 'participate: pool already ended');
        require(_pool.timeStart <= block.timestamp, 'participate: pool not started');

        uint256 _maxParticipationAmount = _pool.maxAllocation;
        uint256 _minParticipationAmount = _pool.minAllocation;

        uint256 amountInLotteryTokens = ((_amount * _pool.swapPriceNumerator) *
            10**lotteryToken.decimals()) /
            _pool.swapPriceDenominator /
            10**poolToken.decimals();
        require(
            (_maxParticipationAmount >= amountInLotteryTokens) &&
                (amountInLotteryTokens >= _minParticipationAmount),
            'participate: amoutn is out of range'
        );

        require(
            amountInLotteryTokens <= totalSupply[_tier],
            'participate : amount value in lottery tokens is bigger that remained tokens'
        );

        require(
            participants[msg.sender]._didParticipate == false,
            'participate: you have already participated'
        );

        poolToken.safeTransferFrom(msg.sender, address(this), _amount);
        totalSupply[_tier] -= amountInLotteryTokens;

        // Updating participationBook information
        participants[msg.sender]._participationAddress = msg.sender;
        participants[msg.sender]._participatedAmount = _amount;

        // Updating participation status
        participants[msg.sender]._didParticipate = true;
        participants[msg.sender]._tier = _tier;
        //Adding to addressSet
        addressSet[_tier].add(msg.sender);

        participantsAddressesByTier[_tier].push(msg.sender);
    }

    function _generateRandom(uint256 range) internal view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) %
            range;
    }

    // declaring winners w.r.t pools
    //add time to declareWinner?
    function declareWinner(PapStaking.Tier _tier) public onlyOwner {
        Pool storage _pool = pool[_tier];
        uint256 poolTokenToClaim;

        // Only when poolEnds
        require(block.timestamp >= _pool.timeEnd, 'declareWinner: pool not ended yet');
        require(
            block.timestamp >= _pool.timeStart,
            'declareWinner: pool was not started'
        );
        require(
            _tier != PapStaking.Tier.NOTIER,
            'declareWinner: it is not a valid tier!'
        );
        if (block.timestamp >= _pool.timeEnd + DELAY) {
            require(_pool.finished == false, 'declareWinner: declare winner is blocked');
            lotteryToken.safeTransfer(msg.sender, lotteryToken.balanceOf(address(this)));
            _pool.finished = true;
            return;
        }
        require(_pool.finished == false, 'declareWinner: claim already started');

        uint256 _numberOfWinners = _pool.tokensAmount / _pool.maxAllocation; // check it on maxAllocation: 0;

        uint256 numberOfParticipants = participantsAddressesByTier[_tier].length; //change it to separate arrays
        if (numberOfParticipants <= _numberOfWinners) {
            for (uint256 i = 0; i < numberOfParticipants; i++) {
                participants[participantsAddressesByTier[_tier][i]]._didWin = true;
                poolTokenToClaim =
                    poolTokenToClaim +
                    participants[participantsAddressesByTier[_tier][i]]
                        ._participatedAmount;
                winners[_tier].push(participantsAddressesByTier[_tier][i]);
            }
        } else {
            for (uint256 i = 0; i < _numberOfWinners; i++) {
                uint256 _randomIndex = _generateRandom(addressSet[_tier].length());
                address _selectedAddress = addressSet[_tier].at(_randomIndex);
                poolTokenToClaim =
                    poolTokenToClaim +
                    participants[_selectedAddress]._participatedAmount;
                participants[_selectedAddress]._didWin = true;
                addressSet[_tier].remove(_selectedAddress);
                winners[_tier].push(_selectedAddress);
            }
        }
        uint256 lotteryTokenToReturn = _pool.tokensAmount -
            (((poolTokenToClaim * _pool.swapPriceNumerator) *
                10**lotteryToken.decimals()) /
                _pool.swapPriceDenominator /
                10**poolToken.decimals());
        raised[_tier] = poolTokenToClaim;
        lotteryToken.safeTransfer(msg.sender, lotteryTokenToReturn);
        poolToken.safeTransfer(msg.sender, poolTokenToClaim);
        _pool.finished = true;
    }

    function claimWinToken() public {
        require(
            participants[msg.sender]._didParticipate == true,
            'claimWinToken: you did not participate'
        );

        PapStaking.Tier _tier = participants[msg.sender]._tier;
        require(_tier != PapStaking.Tier.NOTIER, 'claimWinToken: not valid tier');

        //      checking winner or not:
        require(
            participants[msg.sender]._didWin == true,
            'claimWinToken: you did not win'
        );
        require(
            participants[msg.sender]._claimedBack == false,
            'claimWinToken: you already claimed'
        );

        require(pool[_tier].finished == true, 'Pool has not finished');

        //      claiming amount amoutput * swap price

        uint256 amountWon = ((participants[msg.sender]._participatedAmount *
            pool[_tier].swapPriceNumerator) * 10**lotteryToken.decimals()) /
            pool[_tier].swapPriceDenominator /
            10**poolToken.decimals();

        lotteryToken.safeTransfer(msg.sender, amountWon);

        participants[msg.sender]._claimedBack = true;
    }

    function claimPoolToken() public {
        //      checking if it is winner
        //      getting msg.sender if pariticpated or not
        require(
            participants[msg.sender]._didParticipate == true,
            'You did not participate'
        );

        // Getting User Tier
        PapStaking.Tier _tier = participants[msg.sender]._tier;
        require(_tier != PapStaking.Tier.NOTIER, 'claimPoolToken: not valid tier');

        // if admin did not declareWinner in time
        if (block.timestamp <= pool[_tier].timeEnd + DELAY) {
            require(pool[_tier].finished == true, 'claimPoolToken: pool has not ended');
        }

        //      checking winner or not:
        require(
            participants[msg.sender]._claimedBack == false,
            'claimPoolToken: You already claimed'
        );
        require(participants[msg.sender]._didWin == false, 'claimPoolToken: You Won');

        uint256 refundamount = participants[msg.sender]._participatedAmount;

        poolToken.safeTransfer(msg.sender, refundamount);
        participants[msg.sender]._claimedBack = true;
    }

    struct PapPoolInfo {
        Pool[3] pools;
        uint256[3] supplies;
        uint256[3] raised;
        address lotteryToken;
        address poolToken;
        address papStaking;
        uint256 delay;
    }

    function getPapPoolInfo() external view returns (PapPoolInfo memory info) {
        info = PapPoolInfo({
            pools: [
                pool[PapStaking.Tier.TIER1],
                pool[PapStaking.Tier.TIER2],
                pool[PapStaking.Tier.TIER3]
            ],
            supplies: [
                totalSupply[PapStaking.Tier.TIER1],
                totalSupply[PapStaking.Tier.TIER2],
                totalSupply[PapStaking.Tier.TIER3]
            ],
            raised: [
                raised[PapStaking.Tier.TIER1],
                raised[PapStaking.Tier.TIER2],
                raised[PapStaking.Tier.TIER3]
            ],
            lotteryToken: address(lotteryToken),
            poolToken: address(poolToken),
            papStaking: address(papStaking),
            delay: DELAY
        });
    }

    function getWinners(PapStaking.Tier _tier)
        external
        view
        returns (address[] memory _winners)
    {
        _winners = winners[_tier];
    }

    //mapping(address => participationRegistration) public didParticipate;
    function getUserInfo(address user)
        external
        view
        returns (infoParticipants memory userInfo)
    {
        return participants[user];
    }
}

contract CreatePapPool is Ownable {
    using SafeERC20 for IERC20Extented;

    PAPpool[] public papAddressPool;
    address public papStakingAddress;
    address public lastPool;

    // For individual pap address, there is index(incremented) that stores address
    mapping(address => address[]) public OwnerPoolBook;
    // Array that will store all the PAP addresses, regardless of Owner
    mapping(address => bool) public poolAdmin;

    constructor(address _papStaking) {
        transferOwnership(msg.sender);
        papStakingAddress = _papStaking;
    }

    modifier isAdmin() {
        require(poolAdmin[msg.sender] == true, 'restricted to Admins!');
        _;
    }

    function setAdmin(address _address) public onlyOwner {
        require(poolAdmin[_address] == false, 'Already Admin');
        poolAdmin[_address] = true;
    }

    function revokeAdmin(address _address) public onlyOwner {
        require(poolAdmin[_address] == true, 'Not Admin');
        poolAdmin[_address] = false;
    }

    /** 
        @dev Creates a PAPpool contract;  
        @param _Tier1: Array of parameter(from front end), that is passed as transaction that will create pool
        @param _Tier2: Array of parameter(from front end), that is passed as transaction that will create pool
        @param _Tier3: Array of parameter(from front end), that is passed as transaction that will create pool
        @param _lotteryToken: Address of lotteryToken,
        @param _poolToken: Address of poolToken,
    */

    function createPool(
        PAPpool.Pool memory _Tier1,
        PAPpool.Pool memory _Tier2,
        PAPpool.Pool memory _Tier3,
        address _lotteryToken,
        address _poolToken
    ) external isAdmin {
        require(
            _Tier1.timeStart < _Tier1.timeEnd &&
                _Tier2.timeStart < _Tier2.timeEnd &&
                _Tier3.timeStart < _Tier3.timeEnd,
            'createPool : endTime to be more than startTime'
        );
        require(
            _Tier1.timeStart > block.timestamp &&
                _Tier2.timeStart > block.timestamp &&
                _Tier3.timeStart > block.timestamp,
            'createPool: invalid timeStart!'
        );
        require(
            _Tier1.maxAllocation >= _Tier1.minAllocation &&
                _Tier2.maxAllocation >= _Tier2.minAllocation &&
                _Tier3.maxAllocation >= _Tier3.minAllocation,
            'createPool: maxAllocation should be >= minAllocation'
        );
        require(
            _Tier1.maxAllocation > 0 &&
                _Tier2.maxAllocation > 0 &&
                _Tier3.maxAllocation > 0,
            'createPool: maxAllocation > 0'
        );
        require(
            _Tier1.tokensAmount > _Tier1.maxAllocation &&
                _Tier2.tokensAmount > _Tier2.maxAllocation &&
                _Tier3.tokensAmount > _Tier3.maxAllocation,
            'createPool: tokensAmount > 0'
        );
        require(
            (_Tier1.swapPriceDenominator * _Tier1.swapPriceNumerator > 0) &&
                (_Tier2.swapPriceDenominator * _Tier2.swapPriceNumerator > 0) &&
                (_Tier3.swapPriceDenominator * _Tier3.swapPriceNumerator > 0),
            'createPool: swapNumerator != 0 and swapDenominator != 0 '
        );
        require(
            (_lotteryToken != address(0)) && (_poolToken != address(0)),
            'createPool: address cant be 0x0!'
        );
        _Tier1.finished = false;
        _Tier2.finished = false;
        _Tier3.finished = false;

        PAPpool pappool = new PAPpool(
            _Tier1,
            _Tier2,
            _Tier3,
            msg.sender,
            _lotteryToken,
            _poolToken,
            papStakingAddress
        );
        uint256 _idoToDeposit = _Tier1.tokensAmount +
            _Tier2.tokensAmount +
            _Tier3.tokensAmount;
        IERC20Extented(_lotteryToken).safeTransferFrom(
            msg.sender,
            address(this),
            _idoToDeposit
        );
        IERC20Extented(_lotteryToken).safeTransfer(address(pappool), _idoToDeposit);
        papAddressPool.push(pappool);
        lastPool = address(pappool);
        OwnerPoolBook[msg.sender].push(address(pappool));
    }

    function PAPAddresses() public view returns (PAPpool[] memory) {
        return papAddressPool;
    }

    //need to check
    function getPoolsInfo(PAPpool[] memory pools)
        external
        view
        returns (PAPpool.PapPoolInfo[] memory infos)
    {
        infos = new PAPpool.PapPoolInfo[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            infos[i] = pools[i].getPapPoolInfo();
        }
    }

    function getUserInfo(address[] memory pools, address user)
        external
        view
        returns (PAPpool.infoParticipants[] memory userInfo)
    {
        uint256 len = pools.length;
        userInfo = new PAPpool.infoParticipants[](len);
        for (uint256 i = 0; i < len; i++) {
            userInfo[i] = PAPpool(pools[i]).getUserInfo(user);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
pragma solidity ^0.8.0;

/**
 * @title PAPStaking
 * @author gotbit.io
 */

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


contract PapStaking is Ownable {
    IERC20 public DFTY;

    uint256 public TIER1_MIN_VALUE;
    uint256 public TIER2_MIN_VALUE;
    uint256 public TIER3_MIN_VALUE;

    uint256 public COOLDOWN_TO_UNSTAKE;
    uint256 public APY;
    // uint256 public YEAR = 360 days; //for mainnet
    uint256 public YEAR = 36 days;

    enum Tier {
        NOTIER,
        TIER1,
        TIER2,
        TIER3
    }

    struct StakeInstance {
        uint256 amount;
        uint256 lastInteracted;
        uint256 lastStaked; //For staking coolDown
        uint256 rewards;
        Tier tier;
    }

    mapping(address => StakeInstance) private stakes;

    event Staked(uint256 indexed timeStamp, uint256 amount, address indexed user);
    event Unstaked(uint256 indexed timeStamp, uint256 amount, address indexed user);
    event RewardsClaimed(uint256 indexed timeStamp, uint256 amount, address indexed user);

    /**
        @dev Creates PapStaking contract
        @param TOKEN_ERC20 address of DFTY token, which user could stake to get Tier and rewards in DFTY
        @param cooldownToUnstake There is cooldown for unstake after user stake tokens. In days
        @param tier1Value value in DFTY tokens, after this user can get Tier 3, or bigger, if less then user will get NOTIER, which doesn't allow to participate in Deftify IDO pools
        @param tier2Value value in DFTY tokens, after this user can get Tier 2, or bigger
        @param tier3Value value in DFTY tokens, after this user can get Tier 1
        @param apy APY in format: x% * 100, only two digits after comma precision for x is allowed! Example: for 20,87% apy is 2087
     */
    constructor(
        address TOKEN_ERC20,
        uint256 cooldownToUnstake,
        uint256 tier1Value,
        uint256 tier2Value,
        uint256 tier3Value,
        uint256 apy
    ) {
        DFTY = IERC20(TOKEN_ERC20);
        require(
            tier1Value >= tier2Value && tier2Value >= tier3Value,
            'TierMinValues should be: tier1 >= tier2 >= tier3'
        );
        TIER1_MIN_VALUE = tier1Value;
        TIER2_MIN_VALUE = tier2Value;
        TIER3_MIN_VALUE = tier3Value;

        COOLDOWN_TO_UNSTAKE = cooldownToUnstake;

        APY = apy;

        transferOwnership(msg.sender);
    }

    /**
        @notice Stake DFTY tokens to get Tier and be allowed to participate in Deftify PAP Pools.
        @dev Allows msg.sender to stake DFTY tokens (transfer DFTY from this contract to msg.sender) to get Tier, which allows to participate in Deftify IDO pools. If user stakes amount more than TIERX_MIN_VALUE he gets this TIER;
        @param amount Amount to stake in wei
     */
    function stake(uint256 amount) external {
        require(
            DFTY.balanceOf(msg.sender) >= amount,
            "You don't have enough money to stake"
        );
        require(amount > 0, 'Amount must be grater than zero');

        StakeInstance storage userStake = stakes[msg.sender];
        Tier userTier;

        uint256 pending = getPendingRewards(msg.sender);
        if (pending > 0) {
            userStake.rewards += pending;
            userStake.lastInteracted = block.timestamp;
            require(
                DFTY.transfer(msg.sender, userStake.rewards),
                'Transfer DFTY rewards failed!'
            );
            userStake.rewards = 0;
        }

        userStake.lastInteracted = block.timestamp;

        DFTY.transferFrom(msg.sender, address(this), amount);
        if (userStake.amount + amount >= TIER1_MIN_VALUE) {
            userTier = Tier.TIER1;
        } else if (userStake.amount + amount >= TIER2_MIN_VALUE) {
            userTier = Tier.TIER2;
        } else if (userStake.amount + amount >= TIER3_MIN_VALUE) {
            userTier = Tier.TIER3;
        } else userTier = Tier.NOTIER;

        userStake.amount += amount;
        userStake.lastStaked = block.timestamp;
        userStake.tier = userTier;
        emit Staked(block.timestamp, amount, msg.sender);
    }

    /**
        @notice Unstake DFTY tokens
        @dev This function allows user to unstake (transfer DFTY from this contract to msg.sender) amount of DFTY tokens, checks if COOLDOWN_TO_UNSTAKE
        is passed since user last stake (userStake.lastStaked), updates user rewards in DFTY tokens.
        If user unstake DFTY, and if remaining amount of staked tokens will be less than TIER minimal
        amount user's Tier can decrease (Tier1 => Tier2 => Tier3 => NoTier)
        @param amount amount in wei of DFTY tokens to unstake, can't be bigger than userStake.amount
     */
    function unstake(uint256 amount) external {
        require(amount > 0, 'Cannot unstake 0');
        StakeInstance storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, 'Cannot unstake amount more than available');
        require(
            block.timestamp >= userStake.lastStaked + COOLDOWN_TO_UNSTAKE,
            'Cooldown for unstake is not finished yet!'
        ); //for test in seconds now
        Tier userTier;
        uint256 pending = getPendingRewards(msg.sender);
        if (pending > 0) {
            userStake.rewards += pending;
            userStake.lastInteracted = block.timestamp;
            require(
                DFTY.transfer(msg.sender, userStake.rewards),
                'Transfer DFTY rewards failed!'
            );
            userStake.rewards = 0;
        }

        userStake.lastInteracted = block.timestamp;

        DFTY.transfer(msg.sender, amount);

        if (userStake.amount - amount >= TIER1_MIN_VALUE) {
            userTier = Tier.TIER1;
        } else if (userStake.amount - amount >= TIER2_MIN_VALUE) {
            userTier = Tier.TIER2;
        } else if (userStake.amount - amount >= TIER3_MIN_VALUE) {
            userTier = Tier.TIER3;
        } else userTier = Tier.NOTIER;
        userStake.amount -= amount;
        userStake.tier = userTier;
        emit Unstaked(block.timestamp, amount, msg.sender);
    }

    /**
        @notice Claim reward in DFTY tokens for participating in staking programm
        @dev Allows user to claim his rewards. Reward = stakes[user].amount + pendingRewards since last time interacted with this contract;
     */
    function claimRewards() external {
        uint256 pending = getPendingRewards(msg.sender);
        uint256 amount = stakes[msg.sender].rewards + pending;
        require(amount > 0, 'Nothing to claim now');
        require(DFTY.transfer(msg.sender, amount), 'ERC20: transfer issue');
        stakes[msg.sender].lastInteracted = block.timestamp;
        stakes[msg.sender].rewards = 0;
        emit RewardsClaimed(block.timestamp, amount, msg.sender);
    }

    /**
        @notice Get full info of user's stake
        @dev Returns a StakeInstance structure
        @param user address of user
        @return StakeInstance structure
     */
    function UserInfo(address user) external view returns (StakeInstance memory) {
        return stakes[user];
    }

    /**
        @notice Get current rewards amount of a user
        @dev This function need for UI, returns current rewards amount of a user at this point in time
        @param user address of a user
        @return uint256 : rewards amount in wei
     */
    function getRewardInfo(address user) external view returns (uint256) {
        uint256 amount = getPendingRewards(user) + stakes[user].rewards;
        return amount;
    }

    /**
        @notice Get pending rewards at this point of time
        @dev Returns rewards of user based on his staked amount, APY and time passed since last time he interacted with a stake: used functions as a claimRewards, stake, unstake;
        @param user address of a user
        @return uint256 user's pending rewards
     */
    function getPendingRewards(address user) internal view returns (uint256) {
        StakeInstance memory userStake = stakes[user];
        uint256 timePassed = block.timestamp - userStake.lastInteracted;
        uint256 pending = (userStake.amount * APY * timePassed) / (1 * YEAR) / 10000;
        return pending;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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