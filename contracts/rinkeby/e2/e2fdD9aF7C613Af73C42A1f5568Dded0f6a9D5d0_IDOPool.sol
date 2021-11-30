// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./libraries/DecimalsConverter.sol";
import "./management/ManagedUpgradeable.sol";
import "./management/Constants.sol";
import "./interfaces/IPoolIDO.sol";

contract IDOPool is IPoolIDO, ManagedUpgradeable {
    using DecimalsConverter for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    RewardTokenInfo[] public rewardsTokenInfo;
    mapping(address => mapping(address => uint256)) public depositedByNFT;
    mapping(address => mapping(address => bool)) public userByNft;

    uint256 internal _saleStartDate;
    uint256 internal _secondRoundStart;
    uint256 internal _thirdRoundStart;
    uint256 internal _saleEndDate;
    uint256 internal _vestingDate;
    uint256 internal _initialUnlockPercentage;
    uint256 internal _percentagePerBlock;
    uint256 internal _blockDuration;
    uint256 internal _totalRaise;
    uint256 internal _totalDeposited;
    uint256 internal _feePercentage;
    string internal _name;
    address internal _ownerRecipient;
    address internal _depositToken;
    bool internal _isKYC;
    bool internal _isContribute;
    uint256[] internal _percentagePerMonth;
    mapping(address => uint256) internal _decimals;
    mapping(address => uint256) internal _deposited;
    mapping(address => mapping(address => uint256)) internal _harvestPaid;
    EnumerableSet.AddressSet internal _nfts;
    mapping(address => NFTInfo) internal _nftInfos;

    modifier canDeposit(
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) {
        if (_isKYC) {
            require(
                management.isKYCPassed(msg.sender, _deadline, _v, _r, _s),
                ERROR_KYC_MISSING
            );
        }
        _;
    }

    function initialize(
        address management_,
        string memory name_,
        bool isKYC_,
        address depositeToken_,
        address ownerRecipient_,
        uint256 totalRaise_,
        uint256 feePercentage_
    ) external initializer {
        require(ownerRecipient_ != address(0), ERROR_INVALID_ADDRESS);
        require(totalRaise_ > 0, ERROR_AMOUNT_IS_ZERO);
        require(feePercentage_ < MAX_FEE_PERCENTAGE, ERROR_MORE_THEN_MAX);
        _isKYC = isKYC_;
        _name = name_;
        _ownerRecipient = ownerRecipient_;
        _depositToken = depositeToken_;
        _totalRaise = totalRaise_;
        _feePercentage = feePercentage_;
        if (depositeToken_ != address(0)) {
            _decimals[depositeToken_] = IERC20Metadata(depositeToken_)
                .decimals();
        }
        management = IManagement(management_);
        __Ownable_init();
    }

    function getInfo()
        external
        view
        returns (
            string memory name,
            bool isKYC,
            address depositeToken,
            uint256 totalRaise,
            uint256 totalDeposited,
            uint256 feePercentage
        )
    {
        name = _name;
        depositeToken = _depositToken;
        totalRaise = _totalRaise;
        totalDeposited = _totalDeposited;
        feePercentage = _feePercentage;
        isKYC = _isKYC;
    }

    function balanceOf(address _addr) external view returns (uint256) {
        return _deposited[_addr];
    }

    function getAvailHarvest(address _sender)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory availHarverst)
    {
        uint256 length = rewardsTokenInfo.length;
        rewardTokens = new address[](length);
        availHarverst = new uint256[](length);
        for (uint256 i; i < length; i++) {
            rewardTokens[i] = rewardsTokenInfo[i].token;
            availHarverst[i] = _calculateAvailHarvest(
                _sender,
                rewardsTokenInfo[i].token,
                rewardsTokenInfo[i].amount
            );
        }
    }

    function getAvailAllocation(address _sender)
        external
        view
        returns (address[] memory nft, uint256[] memory amount)
    {
        uint256 size = _nfts.length();
        nft = new address[](size);
        amount = new uint256[](size);
        for (uint256 i; i < size; i++) {
            nft[i] = _nfts.at(i);
            amount[i] = _getAvailAllocation(_sender, _nfts.at(i));
        }
    }

    function getAllTimePoint()
        external
        view
        returns (
            uint256 saleStartDate,
            uint256 secondRoundStartDate,
            uint256 thirdRoundStartDate,
            uint256 saleEndDate
        )
    {
        return (
            _saleStartDate,
            _secondRoundStart,
            _thirdRoundStart,
            _saleEndDate
        );
    }

    function getVestingInfo()
        external
        view
        returns (
            uint256 vestingDateStart,
            uint256 initialUnlockPercentage,
            uint256 blockDuration,
            uint256 percentPerBlock,
            uint256[] memory percentPerMonth
        )
    {
        percentPerMonth = new uint256[](_percentagePerMonth.length);
        for (uint256 i; i < _percentagePerMonth.length; i++) {
            percentPerMonth[i] = _percentagePerMonth[i];
        }
        return (
            _vestingDate,
            _initialUnlockPercentage,
            _blockDuration,
            _percentagePerBlock,
            percentPerMonth
        );
    }

    function getRewardsTokenInfo()
        external
        view
        returns (RewardTokenInfo[] memory rewardsInfo)
    {
        rewardsInfo = new RewardTokenInfo[](rewardsTokenInfo.length);
        for (uint256 i; i < rewardsTokenInfo.length; i++) {
            rewardsInfo[i] = rewardsTokenInfo[i];
        }
    }

    function getTokensPriceInfo()
        external
        view
        returns (address[] memory tokens, uint256[] memory pricePerToken)
    {
        uint256 size = rewardsTokenInfo.length;
        tokens = new address[](size);
        pricePerToken = new uint256[](size);
        for (uint256 i = 0; i < rewardsTokenInfo.length; i++) {
            tokens[i] = rewardsTokenInfo[i].token;
            pricePerToken[i] =
                (_totalRaise * DECIMALS18) /
                rewardsTokenInfo[i].amount;
        }
    }

    function harvest() external {
        for (uint256 i; i < rewardsTokenInfo.length; i++) {
            RewardTokenInfo storage info = rewardsTokenInfo[i];
            uint256 availHarvest = _calculateAvailHarvest(
                _msgSender(),
                info.token,
                info.amount
            );
            require(availHarvest > 0, ERROR_AMOUNT_IS_ZERO);
            _harvestPaid[info.token][_msgSender()] += availHarvest;
            _transfer(info.token, _msgSender(), availHarvest);
            emit Harvest(_msgSender(), availHarvest);
        }
    }

    function deposite(
        address _nftAddress,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_depositToken != address(0), ERROR_INCORRECT_CALL_METHOD);
        _deposite(_nftAddress, _amount, _deadline, _v, _r, _s);
    }

    function depositeETH(
        address _nftAddress,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        require(_depositToken == address(0), ERROR_INCORRECT_CALL_METHOD);
        _deposite(_nftAddress, msg.value, _deadline, _v, _r, _s);
    }

    function _deposite(
        address _nftAddress,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal canDeposit(_deadline, _v, _r, _s) {
        require(
            IERC721(_nftAddress).balanceOf(_msgSender()) > 0,
            ERROR_NOT_ENOUGH_NFT_IDS
        );
        require(_amount > 0, ERROR_AMOUNT_IS_ZERO);
        require(
            _getAvailAllocation(_msgSender(), _nftAddress) >= _amount,
            ERROR_HAVENT_ALLOCATION
        );
        if (_depositToken != address(0)) {
            _transferFrom(_depositToken, _amount);
        }
        _nftInfos[_nftAddress].deposited += _amount;
        depositedByNFT[_nftAddress][_msgSender()] += _amount;
        _deposited[_msgSender()] += _amount;
        _totalDeposited += _amount;
        emit Deposit(_msgSender(), _amount);
    }

    function setWhitelist(
        address _nft,
        address[] calldata _users,
        bool _value
    ) external requirePermission(ROLE_ADMIN) {
        for (uint256 i; i < _users.length; i++) {
            userByNft[_nft][_users[i]] = _value;
        }
        emit SetWhitelistNFT(_nft, _users, _value);
    }

    function setTierSetting(NFTInfo[] calldata info_)
        external
        requirePermission(ROLE_ADMIN)
    {
        for (uint256 i; i < info_.length; i++) {
            _nftInfos[info_[i].nft] = info_[i];
            _nfts.add(info_[i].nft);
        }
        emit SetTierSettings(info_);
    }

    function setTotalRaise(uint256 _amount)
        external
        requirePermission(ROLE_ADMIN)
    {
        _totalRaise = _amount;
        emit SetTotalRaise(_amount);
    }

    function addRewardToken(
        RewardTokenInfo calldata _info,
        uint256 _id,
        bool _isUpdate
    ) external override requirePermission(ROLE_ADMIN) {
        if (_isUpdate) {
            uint256 amount = rewardsTokenInfo[_id].amount;
            if (amount < _info.amount) {
                _transferFrom(_info.token, _info.amount - amount);
            } else {
                _transfer(_info.token, _msgSender(), amount - _info.amount);
            }
            rewardsTokenInfo[_id] = _info;
        } else {
            if (_decimals[_info.token] == 0) {
                _decimals[_info.token] = IERC20Metadata(_info.token).decimals();
                rewardsTokenInfo.push(_info);
            }
            if (_info.token != address(0)) {
                _transferFrom(_info.token, _info.amount);
            }
        }
        emit AddRewardToken(_info);
    }

    function withdrawContributions() external {
        require(_ownerRecipient == _msgSender(), ERROR_ACCESS_DENIED);
        require(!_isContribute, ERROR_ALREADY_CALL_METHOD);
        require(
            _saleEndDate != 0 && block.timestamp > _saleEndDate,
            ERROR_IS_NOT_SALE
        );
        _isContribute = true;
        uint256 balance;
        uint256 fee;
        address payable tresuary = management.contractRegistry(
            ADDRESS_TRESUARY
        );
        if (_depositToken == address(0)) {
            balance = address(this).balance;
            fee = (_feePercentage * balance) / PERCENTAGE_100;
            _sendValue(_ownerRecipient, balance - fee);
            if (fee > 0) {
                _sendValue(tresuary, fee);
            }
        } else {
            balance = IERC20Metadata(_depositToken).balanceOf(address(this));
            fee = (_feePercentage * balance) / PERCENTAGE_100;
            _transfer(_depositToken, _ownerRecipient, balance - fee);
            if (fee > 0) {
                _transfer(_depositToken, tresuary, fee);
            }
        }
        uint256 finishPercentage = (_totalDeposited * DECIMALS18) / _totalRaise;
        for (uint256 i; i < rewardsTokenInfo.length; i++) {
            RewardTokenInfo memory info = rewardsTokenInfo[i];
            uint256 unsoldTokens = info.amount -
                (info.amount * finishPercentage) /
                DECIMALS18;
            _transfer(info.token, _ownerRecipient, unsoldTokens);
            emit WithdrawOwner(
                _msgSender(),
                info.token,
                unsoldTokens,
                finishPercentage
            );
        }
        emit WithdrawOwner(_msgSender(), _depositToken, balance, fee);
    }

    function emergencyFunction() external requirePermission(ROLE_ADMIN) {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            _sendValue(EMERGENCY_ADDRESS, balance);
        }
        if (_depositToken != address(0)) {
            _transfer(
                _depositToken,
                EMERGENCY_ADDRESS,
                IERC20Metadata(_depositToken).balanceOf(address(this))
            );
        }
        for (uint256 i; i < rewardsTokenInfo.length; i++) {
            address token = rewardsTokenInfo[i].token;
            if (token != address(0)) {
                _transfer(
                    token,
                    EMERGENCY_ADDRESS,
                    IERC20Metadata(token).balanceOf(address(this))
                );
            }
        }
        emit EmergencyCall(_msgSender());
    }

    function setTimePoints(
        uint256 saleStartDate_,
        uint256 secondRoundDate_,
        uint256 thirdRoundDate_,
        uint256 saleEndDate_
    ) external requirePermission(ROLE_ADMIN) {
        require(
            saleStartDate_ < saleEndDate_ &&
                secondRoundDate_ > saleStartDate_ &&
                secondRoundDate_ < thirdRoundDate_ &&
                thirdRoundDate_ < saleEndDate_,
            ERROR_INCORRECT_DATE
        );
        _saleStartDate = saleStartDate_;
        _secondRoundStart = secondRoundDate_;
        _thirdRoundStart = thirdRoundDate_;
        _saleEndDate = saleEndDate_;
        emit SetTimePoints(
            saleStartDate_,
            secondRoundDate_,
            thirdRoundDate_,
            saleEndDate_
        );
    }

    function setKYC(bool value_) external requirePermission(ROLE_ADMIN) {
        _isKYC = value_;
    }

    function setVesting(
        uint256 vestingDate_,
        uint256 initialUnlockPercentage_,
        uint256 percentagePerBlock_,
        uint256 blockDuration_,
        uint256[] calldata percentagePerMonth_
    ) external override requirePermission(ROLE_ADMIN) {
        require(
            initialUnlockPercentage_ <= PERCENTAGE_100,
            ERROR_AMOUNT_IS_MORE_TS
        );
        if (initialUnlockPercentage_ < PERCENTAGE_100) {
            require(
                !(percentagePerBlock_ > 0 && percentagePerMonth_.length > 0),
                ERROR_FAIL
            );
            _blockDuration = blockDuration_;
            _percentagePerBlock = percentagePerBlock_;
            delete _percentagePerMonth;
            for (uint256 i; i < percentagePerMonth_.length; i++) {
                _percentagePerMonth.push(percentagePerMonth_[i]);
            }
        }
        _initialUnlockPercentage = initialUnlockPercentage_;
        _vestingDate = vestingDate_;
        emit SetVesting(
            vestingDate_,
            initialUnlockPercentage_,
            percentagePerBlock_,
            blockDuration_,
            percentagePerMonth_
        );
    }

    function _getAvailAllocation(address _sender, address _nftAddress)
        internal
        view
        returns (uint256)
    {
        if (
            !userByNft[_nftAddress][_sender] ||
            block.timestamp < _saleStartDate ||
            block.timestamp > _saleEndDate
        ) {
            return 0;
        }
        uint256 amount;
        if (block.timestamp > _thirdRoundStart) {
            amount = _totalRaise - _totalDeposited;
        } else if (block.timestamp > _secondRoundStart) {
            amount =
                (_nftInfos[_nftAddress].allocationForTier * _totalRaise) /
                PERCENTAGE_100 -
                depositedByNFT[_nftAddress][_sender];
        } else {
            amount =
                (_nftInfos[_nftAddress].allocationPerNFT * _totalRaise) /
                PERCENTAGE_100 -
                depositedByNFT[_nftAddress][_sender];
        }
        return
            amount > _totalRaise - _totalDeposited
                ? _totalRaise - _totalDeposited
                : amount;
    }

    function _calculateAvailHarvest(
        address _recipient,
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        if (_vestingDate != 0 && block.timestamp > _vestingDate) {
            uint256 canHarvestAmount = (_deposited[_recipient] *
                DECIMALS18 *
                _amount) /
                _totalRaise /
                DECIMALS18;
            if (_initialUnlockPercentage >= PERCENTAGE_100) {
                return canHarvestAmount - _harvestPaid[_token][_recipient];
            } else {
                uint256 amountImmediatelu = (_initialUnlockPercentage *
                    canHarvestAmount) / PERCENTAGE_100;
                uint256 accruedAmount;
                uint256 timePass = block.timestamp - _vestingDate;
                if (_percentagePerMonth.length > 0) {
                    for (
                        uint256 i;
                        i < timePass / 30 days &&
                            i < _percentagePerMonth.length;
                        i++
                    ) {
                        accruedAmount += _percentagePerMonth[i];
                    }
                } else {
                    accruedAmount =
                        (timePass / _blockDuration) *
                        _percentagePerBlock;
                }
                accruedAmount =
                    (accruedAmount * (canHarvestAmount - amountImmediatelu)) /
                    PERCENTAGE_100 +
                    amountImmediatelu;
                canHarvestAmount = canHarvestAmount > accruedAmount
                    ? accruedAmount
                    : canHarvestAmount;
                return canHarvestAmount - _harvestPaid[_token][_recipient];
            }
        }
        return 0;
    }

    function _transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        require(
            IERC20Metadata(_token).transfer(
                _to,
                _amount.convertFrom18(_decimals[_token])
            ),
            ERROR_ERC20_CALL_ERROR
        );
    }

    function _sendValue(address _recipient, uint256 _amount) internal {
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, ERROR_SEND_VALUE);
    }

    function _transferFrom(address _token, uint256 _amount) internal {
        require(
            IERC20Metadata(_token).transferFrom(
                _msgSender(),
                address(this),
                _amount.convertFrom18(_decimals[_token])
            ),
            ERROR_ERC20_CALL_ERROR
        );
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library DecimalsConverter {
    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount / (10**(baseDecimals - destinationDecimals));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount * (10**(destinationDecimals - baseDecimals));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, 18, destinationDecimals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IManagement.sol";
import "./Constants.sol";

contract ManagedUpgradeable is OwnableUpgradeable {
    IManagement public management;

    modifier requirePermission(uint256 _permission) {
        require(_hasPermission(_msgSender(), _permission), ERROR_ACCESS_DENIED);
        _;
    }

    function setManagementContract(address _management) external onlyOwner {
        require(address(0) != _management, ERROR_NO_CONTRACT);
        management = IManagement(_management);
    }

    function _hasPermission(address _subject, uint256 _permission)
        internal
        view
        returns (bool)
    {
        return management.permissions(_subject, _permission);
    }

    function __Managed_init(address _managementAddress) internal initializer {
        management = IManagement(_managementAddress);
        __Ownable_init();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

uint256 constant DECIMALS = 18;
uint256 constant DECIMALS18 = 1e18;

uint256 constant MAX_UINT256 = type(uint256).max;
uint256 constant PERCENTAGE_100 = 100 * DECIMALS18;
uint256 constant PERCENTAGE_1 = DECIMALS18;
uint256 constant MAX_FEE_PERCENTAGE = 99 * DECIMALS18;
bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;

string constant ERROR_ACCESS_DENIED = "0x1";
string constant ERROR_NO_CONTRACT = "0x2";
string constant ERROR_NOT_AVAILABLE = "0x3";
string constant ERROR_KYC_MISSING = "0x4";
string constant ERROR_INVALID_ADDRESS = "0x5";
string constant ERROR_INCORRECT_CALL_METHOD = "0x6";
string constant ERROR_AMOUNT_IS_ZERO = "0x7";
string constant ERROR_HAVENT_ALLOCATION = "0x8";
string constant ERROR_AMOUNT_IS_MORE_TS = "0x9";
string constant ERROR_ERC20_CALL_ERROR = "0xa";
string constant ERROR_DIFF_ARR_LENGTH = "0xb";
string constant ERROR_METHOD_DISABLE = "0xc";
string constant ERROR_SEND_VALUE = "0xd";
string constant ERROR_NOT_ENOUGH_NFT_IDS = "0xe";
string constant ERROR_INCORRECT_FEE = "0xf";
string constant ERROR_WRONG_IMPLEMENT_ADDRESS = "0x10";
string constant ERROR_INVALIG_SIGNER = "0x11";
string constant ERROR_NOT_FOUND = "0x12";
string constant ERROR_IS_EXISTS = "0x13";
string constant ERROR_IS_NOT_EXISTS = "0x14";
string constant ERROR_TIME_OUT = "0x15";
string constant ERROR_NFT_NOT_EXISTS = "0x16";
string constant ERROR_MINTING_COMPLETED = "0x17";
string constant ERROR_TOKEN_NOT_SUPPORTED = "0x18";
string constant ERROR_NOT_ENOUGH_NFT_FOR_SALE = "0x19";
string constant ERROR_NOT_ENOUGH_PREVIEUS_NFT = "0x1a";
string constant ERROR_FAIL = "0x1b";
string constant ERROR_MORE_THEN_MAX = "0x1c";
string constant ERROR_VESTING_NOT_START = "0x1d";
string constant ERROR_VESTING_IS_STARTED = "0x1e";
string constant ERROR_IS_SET = "0x1f";
string constant ERROR_ALREADY_CALL_METHOD = "0x20";
string constant ERROR_INCORRECT_DATE = "0x21";
string constant ERROR_IS_NOT_SALE = "0x22";

bytes32 constant KYC_CONTAINER_TYPEHASE = keccak256(
    "Container(address sender,uint256 deadline)"
);

bytes32 constant _GENESIS_CONTAINER_TYPEHASE = keccak256(
    "Container(string stakingName,bool isETHStake,bool isPrivate,bool isCanTakeReward,address stakedToken,uint256 startBlock,uint256 duration,uint256 nonce)"
);
bytes32 constant _LIQUIDITY_MINING_CONTAINER_TYPEHASE = keccak256(
    "Container(string stakingName,bool isPrivate,bool isCanTakeReward,address stakedToken,uint256 startBlock,uint256 duration,uint256 nonce)"
);

address constant EMERGENCY_ADDRESS = 0x85CCc822A20768F50397BBA5Fd9DB7de68851D5B;

//permisionss
//WHITELIST
uint256 constant ROLE_ADMIN = 1;
uint256 constant ROLE_REGULAR = 2;

uint256 constant MANAGEMENT_CAN_SET_KYC_WHITELISTED = 3;
uint256 constant MANAGEMENT_CAN_SET_PRIVATE_WHITELISTED = 4;
uint256 constant MANAGEMENT_WHITELISTED_KYC = 5;
uint256 constant MANAGEMENT_WHITELISTED_PRIVATE = 6;
uint256 constant MANAGEMENT_CAN_SET_POOL_OWNER = 7;

uint256 constant REGISTER_CAN_ADD_STAKING = 21;
uint256 constant REGISTER_CAN_REMOVE_STAKING = 22;
uint256 constant REGISTER_CAN_ADD_POOL = 30;
uint256 constant REGISTER_CAN_REMOVE_POOL = 31;

uint256 constant GENERAL_CAN_UPDATE_DEPENDENCY = 100;
uint256 constant NFT_CAN_TRANSFER_NFT = 101;
uint256 constant NFT_CAN_MINT_NFT = 102;

//REGISTER_ADDRESS
uint256 constant CONTRACT_MANAGEMENT = 0;
uint256 constant CONTRACT_KAISHI_TOKEN = 1;
uint256 constant CONTRACT_STAKING_REGISTER = 2;
uint256 constant CONTRACT_POOL_REGISTER = 3;
uint256 constant CONTRACT_NFT_FACTORY = 4;
uint256 constant ADDRESS_TRESUARY = 5;
uint256 constant ADDRESS_FACTORY_SIGNER = 6;
uint256 constant ADDRESS_PROXY_OWNER = 7;
uint256 constant ADDRESS_MANAGED_OWNER = 8;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IPool.sol";

interface IPoolIDO is IPool {
    struct NFTInfo {
        address nft;
        uint256 allocationForTier;
        uint256 allocationPerNFT;
        uint256 deposited;
    }

    event SetTimePoints(
        uint256 saleStartDate,
        uint256 secondRoundStart,
        uint256 thirdRoundStart,
        uint256 saleEndDate
    );

    event SetTierSettings(NFTInfo[] nftsInfo);

    event SetWhitelistNFT(address _nft, address[] _users, bool _value);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IManagement {
    event PoolOwnerSet(address indexed pool, address indexed owner, bool value);

    event PermissionsSet(
        address indexed subject,
        uint256[] indexed permissions,
        bool value
    );

    event UsersPermissionsSet(
        address[] indexed subject,
        uint256 indexed permissions,
        bool value
    );

    event PermissionSet(
        address indexed subject,
        uint256 indexed permission,
        bool value
    );

    event ContractRegistered(
        uint256 indexed key,
        address indexed source,
        address target
    );

    function isKYCPassed(
        address _address,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external view returns (bool);

    function requireAccess(address _address, address _pool)
        external
        view
        returns (bool);

    function contractRegistry(uint256 _key)
        external
        view
        returns (address payable);

    function permissions(address _address, uint256 _permission)
        external
        view
        returns (bool);

    function kycSigner() external view returns (address);

    function setPoolOwner(
        address _pool,
        address _owner,
        bool _value
    ) external;

    function setPermission(
        address _address,
        uint256 _permission,
        bool _value
    ) external;

    function setPermissions(
        address _address,
        uint256[] calldata _permissions,
        bool _value
    ) external;

    function registerContract(uint256 _key, address payable _target) external;

    function setKycWhitelists(address[] calldata _address, bool _value)
        external;

    function setPrivateWhitelists(address[] calldata _address, bool _value)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IPool {
    struct RewardTokenInfo {
        string name;
        address token;
        uint256 amount;
    }
    event Deposit(address indexed sender, uint256 amount);
    event Harvest(address indexed sender, uint256 amount);
    event WithdrawOwner(
        address indexed sender,
        address token,
        uint256 amount,
        uint256 fee
    );
    event SetVesting(
        uint256 delayDuration,
        uint256 availiableImmediately,
        uint256 percentagePerBlock,
        uint256 blockDuration,
        uint256[] percentagePerMonth
    );
    event AddRewardToken(RewardTokenInfo info);
    event EmergencyCall(address indexed sender);
    event SetTotalRaise(uint256 amount);

    function balanceOf(address _recipient) external returns (uint256);

    function getVestingInfo()
        external
        returns (
            uint256 delay,
            uint256 availiableInStart,
            uint256 percentPerBlock,
            uint256 timeUnitDuration,
            uint256[] memory percentPerMonth
        );

    function getRewardsTokenInfo()
        external
        returns (RewardTokenInfo[] memory rewardsInfo);

    function harvest() external;

    function addRewardToken(
        RewardTokenInfo calldata info,
        uint256 _id,
        bool _isUpdate
    ) external;

    function setTotalRaise(uint256 _amount) external;

    function withdrawContributions() external;

    function emergencyFunction() external;

    function setVesting(
        uint256 _delayDuration,
        uint256 _availiableImmediately,
        uint256 _percentagePerBlock,
        uint256 _blockDuration,
        uint256[] calldata _percentagePerMonth
    ) external;
}