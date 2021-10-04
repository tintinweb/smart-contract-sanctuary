pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libraries/DecimalsConverter.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../management/Managed.sol";
import "../management/Constants.sol";

contract IDOPool is Managed {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address payable;

    event Deposite(address indexed sender, uint256 amount);
    event Harvest(address indexed sender, uint256 amount);
    event StartVesting(uint256 vestingStartDate);

    event WithdrawOwner(
        address indexed sender,
        address token,
        uint256 amount,
        uint256 fee
    );
    event SetTimePoint(
        uint256 saleStartDate,
        uint256 firstRoundStart,
        uint256 secondRoundStart,
        uint256 thirdRoundStart,
        uint256 saleEndDate
    );
    event SetVesting(
        bool withoutVesting,
        uint256 delayDuration,
        uint256 availiableImmediately,
        uint256 percentagePerBlock,
        uint256 blockDuration,
        uint256[] percentagePerMonth
    );
    event SetTierSetting(
        address[] _nft,
        uint256[] _allocationNFTForTier,
        uint256[] _allocationNFTPerNFT
    );
    event AddRewardsTokens(
        string[] _tokensName,
        address[] _rewardsTokens,
        uint256[] _tokenAmount
    );
    event SetTokenAmount(address token, uint256 amount);

    event EmergencyCall(address indexed sender);
    event SetTotalRaise(uint256 amount);
    event SetWhitelistNFT(address _nft, address[] _users, bool _value);

    struct RewardTokenInfo {
        uint256 amount;
        address token;
        string name;
    }

    struct NFTInfo {
        address nft;
        uint256 allocationForTier;
        uint256 allocationPerNFT;
        uint256 deposited;
    }

    mapping(address => mapping(address => uint256)) internal harvestPaid;

    uint256 internal saleStartDate;
    uint256 internal vestingStartDate;
    uint256 internal firstRoundDuration;
    uint256 internal secondRoundDuration;
    uint256 internal thirdRoundDuration;
    uint256 internal saleEndDate;

    uint256 internal delayDuration;
    bool internal noVesting;
    uint256 internal availiableImmediately;
    uint256 internal percentagePerBlock;
    uint256[] internal percentagePerMonth;

    string public name;
    bool public isContribute;
    address public immutable ownerRecipient;
    address public immutable depositeToken;
    address payable internal tresuary;
    uint256 public totalRaise;
    uint256 public totalDeposited;
    uint256 public immutable feePercentage;
    uint256 public blockDuration;

    mapping(address => uint256) internal deposited;
    mapping(address => mapping(address => uint256)) public depositedByNFT;

    RewardTokenInfo[] public rewardsTokenInfo;
    uint256 public depositeDecimals;
    EnumerableSet.AddressSet private nfts;

    mapping(address => NFTInfo) private nftInfos;
    mapping(address => mapping(address => bool)) public userByNft;

    modifier canDeposite(bool isETHStake) {
        require(
            (depositeToken == address(0)) == isETHStake,
            "Pool: deposit method not available"
        );
        require(_isSale(), "Pool: sale round is close");
        require(
            _inWhitelist(msg.sender, address(0)),
            "Pool: absence in whitelist"
        );
        _;
    }

    constructor(
        address _management,
        string memory _name,
        bool _isETHStake,
        address _depositeToken,
        address _ownerRecipient,
        uint256 _totalRaise,
        uint256 _feePercentage
    ) Managed(_management) {
        require(
            (_isETHStake && _depositeToken == address(0)) ||
                (!_isETHStake && _depositeToken != address(0)),
            "Pool: incorect setup type for deposite"
        );
        require(
            _ownerRecipient != address(0),
            "Pool: owner pecipient can't be zero"
        );
        require(_totalRaise > 0, "Pool: can't be zero");

        name = _name;

        ownerRecipient = _ownerRecipient;
        depositeToken = _depositeToken;
        totalRaise = _totalRaise;
        feePercentage = _feePercentage;
        if (_isETHStake) {
            depositeDecimals = 18;
        } else {
            depositeDecimals = IERC20Metadata(_depositeToken).decimals();
        }
    }

    function setDependency() external onlyOwner {
        tresuary = payable(management.contractRegistry(ADDRESS_TRESUARY));
    }

    function balanceOf(address _addr) external view returns (uint256) {
        return deposited[_addr];
    }

    function getAvailHarvest(address _sender)
        external
        view
        returns (RewardTokenInfo[] memory info, uint256[] memory availHarverst)
    {
        info = new RewardTokenInfo[](rewardsTokenInfo.length);
        availHarverst = new uint256[](rewardsTokenInfo.length);
        for (uint256 index = 0; index < rewardsTokenInfo.length; index++) {
            info[index] = rewardsTokenInfo[index];
            availHarverst[index] = _calculateAvailHarvest(
                _sender,
                rewardsTokenInfo[index]
            );
        }
    }

    function getAvailAllocation(address _sender)
        external
        view
        returns (address[] memory nft, uint256[] memory amount)
    {
        uint256 size = nfts.length();
        nft = new address[](size);
        amount = new uint256[](size);
        for (uint256 index = 0; index < nfts.length(); index++) {
            address addNFT = nfts.at(index);
            nft[index] = addNFT;
            amount[index] = _getAvailAllocation(_sender, addNFT);
        }
    }

    function getAllTimePoint()
        external
        view
        returns (
            uint256 saleStart,
            uint256 vestingStart,
            uint256 firstRoundStart,
            uint256 secondRoundStart,
            uint256 thirdRoundStart,
            uint256 saleEnd
        )
    {
        saleStart = saleStartDate;
        vestingStart = vestingStartDate;
        firstRoundStart = saleStartDate;
        secondRoundStart = saleStartDate + firstRoundDuration;
        thirdRoundStart = secondRoundStart + secondRoundDuration;
        saleEnd = saleEndDate;
    }

    function getVestingInfo()
        external
        view
        returns (
            bool withoutVesting,
            uint256 delay,
            uint256 availiableInStart,
            uint256 percentPerBlock,
            uint256 timeUnitDuration,
            uint256[] memory percentPerMonth
        )
    {
        withoutVesting = noVesting;
        delay = delayDuration;
        availiableInStart = availiableImmediately;
        percentPerBlock = percentagePerBlock;
        timeUnitDuration = blockDuration;
        percentPerMonth = new uint256[](percentagePerMonth.length);
        for (uint256 index = 0; index < percentagePerMonth.length; index++) {
            percentPerMonth[index] = percentagePerMonth[index];
        }
    }

    function getRewardsTokenInfo()
        external
        view
        returns (RewardTokenInfo[] memory rewardsInfo)
    {
        rewardsInfo = new RewardTokenInfo[](rewardsTokenInfo.length);
        for (uint256 index = 0; index < rewardsTokenInfo.length; index++) {
            rewardsInfo[index] = rewardsTokenInfo[index];
        }
    }

    function getTokenPriceInfo()
        external
        view
        returns (address[] memory tokens, uint256[] memory pricePerToken)
    {
        uint256 size = rewardsTokenInfo.length;
        tokens = new address[](size);
        pricePerToken = new uint256[](size);
        for (uint256 i = 0; i < rewardsTokenInfo.length; i++) {
            RewardTokenInfo memory info = rewardsTokenInfo[i];
            tokens[i] = info.token;
            pricePerToken[i] = (totalRaise * DECIMALS18) / info.amount;
        }
    }

    function harvest() external {
        require(
            vestingStartDate > 0 &&
                block.timestamp >= vestingStartDate + delayDuration,
            "Pool: Vesting can't be started"
        );
        for (uint256 i = 0; i < rewardsTokenInfo.length; i++) {
            RewardTokenInfo storage info = rewardsTokenInfo[i];
            uint256 availHarvest = _calculateAvailHarvest(msg.sender, info);
            if (availHarvest > 0) {
                harvestPaid[info.token][msg.sender] += availHarvest;

                IERC20(info.token).safeTransfer(
                    msg.sender,
                    DecimalsConverter.convertFrom18(
                        availHarvest,
                        IERC20Metadata(info.token).decimals()
                    )
                );
                emit Harvest(msg.sender, availHarvest);
            }
        }
    }

    function deposite(address _nftAddress, uint256 _amount)
        external
        requireKYCWhitelist(true)
        canDeposite(false)
    {
        require(
            IERC721(_nftAddress).balanceOf(msg.sender) > 0,
            "Pool: You don't have NFT"
        );
        require(_amount > 0, "Pool: Can't be zero");
        require(
            _getAvailAllocation(msg.sender, _nftAddress) >= _amount,
            "Pool: not enought allocation"
        );

        IERC20(depositeToken).safeTransferFrom(
            msg.sender,
            address(this),
            DecimalsConverter.convertFrom18(_amount, depositeDecimals)
        );

        if (_nftAddress != address(0)) {
            nftInfos[_nftAddress].deposited += _amount;
            depositedByNFT[_nftAddress][msg.sender] += _amount;
        }

        deposited[msg.sender] += _amount;
        totalDeposited += _amount;
        emit Deposite(msg.sender, _amount);
    }

    function depositeETH(address _nftAddress)
        external
        payable
        requireKYCWhitelist(true)
        canDeposite(true)
    {
        require(
            IERC721(_nftAddress).balanceOf(msg.sender) > 0,
            "Pool: You don't have NFT"
        );
        uint256 _amount = msg.value;
        require(_amount > 0, "Pool: Can't be zero");
        require(
            _getAvailAllocation(msg.sender, _nftAddress) >= _amount,
            "Pool: not enought allocation"
        );
        if (_nftAddress != address(0)) {
            nftInfos[_nftAddress].deposited += _amount;
            depositedByNFT[_nftAddress][msg.sender] += _amount;
        }

        deposited[msg.sender] += _amount;
        totalDeposited += _amount;

        emit Deposite(msg.sender, _amount);
    }

    function setWhitelistNFT(
        address _nft,
        address[] calldata _users,
        bool _value
    ) external requirePermission(ROLE_ADMIN) {
        for (uint256 i = 0; i < _users.length; i++) {
            userByNft[_nft][_users[i]] = _value;
        }
        emit SetWhitelistNFT(_nft, _users, _value);
    }

    function setTierSetting(
        address[] calldata _nfts,
        uint256[] calldata _allocationNFTForTier,
        uint256[] calldata _allocationNFTPerNFT
    ) external requirePermission(ROLE_ADMIN) {
        require(
            (_nfts.length == _allocationNFTForTier.length) &&
                (_allocationNFTForTier.length == _allocationNFTPerNFT.length),
            "Pool: Incorrect input"
        );

        for (uint256 i = 0; i < _nfts.length; i++) {
            NFTInfo storage info = nftInfos[_nfts[i]];
            info.allocationForTier = _allocationNFTForTier[i];
            info.allocationPerNFT = _allocationNFTPerNFT[i];
            info.nft = _nfts[i];
            require(nfts.add(_nfts[i]), "IDOPool: nft id exists");
        }

        emit SetTierSetting(_nfts, _allocationNFTForTier, _allocationNFTPerNFT);
    }

    function startVesting() external requirePermission(ROLE_ADMIN) {
        require(vestingStartDate == 0, "Pool: vesting already started");
        require(
            rewardsTokenInfo.length > 0,
            "Pool: not specified rewards tokens"
        );
        require(saleEndDate != 0, "Pool: not setup time point");

        vestingStartDate = Math.max(block.timestamp, saleEndDate);
        emit StartVesting(vestingStartDate);
    }

    function setRewardTokenAddress(
        uint256 _id,
        address _token,
        bool _isTransfer
    ) external requirePermission(ROLE_ADMIN) {
        RewardTokenInfo storage info = rewardsTokenInfo[_id];
        info.token = _token;
        if (_isTransfer)
            IERC20(_token).safeTransferFrom(
                msg.sender,
                address(this),
                DecimalsConverter.convertFrom18(
                    info.amount,
                    IERC20Metadata(_token).decimals()
                )
            );
    }

    function addRewardsTokens(
        string[] calldata _tokensName,
        address[] calldata _rewardsTokens,
        uint256[] calldata _tokenAmount,
        bool _isTransfer
    ) external requirePermission(ROLE_ADMIN) {
        require(
            _tokensName.length == _rewardsTokens.length,
            "Pool: Incorect input"
        );
        for (uint256 i = 0; i < _rewardsTokens.length; i++) {
            RewardTokenInfo memory info;

            info.amount = _tokenAmount[i];
            info.token = _rewardsTokens[i];
            info.name = _tokensName[i];

            rewardsTokenInfo.push(info);

            if (_isTransfer)
                IERC20(_rewardsTokens[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    DecimalsConverter.convertFrom18(
                        _tokenAmount[i],
                        IERC20Metadata(_rewardsTokens[i]).decimals()
                    )
                );
        }
        emit AddRewardsTokens(_tokensName, _rewardsTokens, _tokenAmount);
    }

    function setTotalRaise(uint256 _amount)
        external
        requirePermission(ROLE_ADMIN)
    {
        totalRaise = _amount;
        emit SetTotalRaise(_amount);
    }

    function setTokenAmount(
        uint256 _id,
        uint256 _amount,
        bool _isTransfer
    ) external requirePermission(ROLE_ADMIN) {
        RewardTokenInfo storage info = rewardsTokenInfo[_id];
        if (_isTransfer && info.token != address(0)) {
            if (_amount > info.amount) {
                IERC20(info.token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    DecimalsConverter.convertFrom18(
                        _amount - info.amount,
                        IERC20Metadata(info.token).decimals()
                    )
                );
            } else {
                IERC20(info.token).safeTransfer(
                    msg.sender,
                    DecimalsConverter.convertFrom18(
                        info.amount - _amount,
                        IERC20Metadata(info.token).decimals()
                    )
                );
            }
        }

        info.amount = _amount;
        emit SetTokenAmount(info.token, _amount);
    }

    function withdrawContributions() external {
        require(
            ownerRecipient == msg.sender,
            "Pool: you don't have permission's"
        );

        require(!isContribute, "Pool: You already contribute");
        require(saleEndDate < block.timestamp, "Pool: Sale not finished");

        isContribute = true;

        uint256 balance = address(this).balance;
        uint256 fee = (feePercentage * balance) / PERCENTAGE_100;

        if (balance > 0) {
            payable(ownerRecipient).sendValue(balance - fee);
            tresuary.sendValue(fee);
            emit WithdrawOwner(msg.sender, address(0), balance, fee);
        }

        IERC20 erc20 = IERC20(depositeToken);

        balance = erc20.balanceOf(address(this));
        fee = (feePercentage * balance) / PERCENTAGE_100;

        erc20.safeTransfer(ownerRecipient, balance - fee);
        erc20.safeTransfer(tresuary, fee);

        emit WithdrawOwner(msg.sender, depositeToken, balance, fee);

        uint256 finishPercentage = (totalDeposited * DECIMALS18) / totalRaise;

        for (uint256 index = 0; index < rewardsTokenInfo.length; index++) {
            RewardTokenInfo memory info = rewardsTokenInfo[index];
            uint256 unsoldTokens = info.amount -
                (info.amount * finishPercentage) /
                DECIMALS18;
            IERC20(info.token).safeTransfer(
                ownerRecipient,
                DecimalsConverter.convertFrom18(
                    unsoldTokens,
                    IERC20Metadata(info.token).decimals()
                )
            );
            emit WithdrawOwner(msg.sender, info.token, unsoldTokens, 0);
        }
    }

    function emergencyFunction() external requirePermission(ROLE_ADMIN) {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            payable(EMERGENCY_ADDRESS).sendValue(balance);
        }

        IERC20 erc20 = IERC20(depositeToken);

        balance = erc20.balanceOf(address(this));
        erc20.safeTransfer(EMERGENCY_ADDRESS, balance);

        for (uint256 index = 0; index < rewardsTokenInfo.length; index++) {
            RewardTokenInfo memory info = rewardsTokenInfo[index];
            erc20 = IERC20(info.token);
            erc20.safeTransfer(
                EMERGENCY_ADDRESS,
                erc20.balanceOf(address(this))
            );
        }

        emit EmergencyCall(msg.sender);
    }

    function setTimePoints(
        uint256 _saleStartDate,
        uint256 _firstRoundDuration,
        uint256 _secondRoundDuration,
        uint256 _thirdRoundDuration
    ) external requirePermission(ROLE_ADMIN) {
        require(
            _saleStartDate > 0 &&
                _firstRoundDuration > 0 &&
                _secondRoundDuration > 0 &&
                _thirdRoundDuration > 0,
            "Pool: round duration can't be zero"
        );

        saleStartDate = _saleStartDate;
        firstRoundDuration = _firstRoundDuration;
        secondRoundDuration = _secondRoundDuration;
        thirdRoundDuration = _thirdRoundDuration;
        saleEndDate =
            _saleStartDate +
            _firstRoundDuration +
            _secondRoundDuration +
            thirdRoundDuration;

        emit SetTimePoint(
            saleStartDate,
            saleStartDate,
            saleStartDate + firstRoundDuration,
            saleStartDate + firstRoundDuration + secondRoundDuration,
            saleEndDate
        );
    }

    function setVesting(
        bool _withoutVesting,
        uint256 _delayDuration,
        uint256 _availiableImmediately,
        uint256 _percentagePerBlock,
        uint256 _blockDuration,
        uint256[] calldata _percentagePerMonth
    ) external requirePermission(ROLE_ADMIN) {
        if (_withoutVesting) {
            noVesting = _withoutVesting;
            return;
        }
        require(
            !(_percentagePerBlock > 0 && _percentagePerMonth.length > 0),
            "Pool: cannot be set"
        );
        blockDuration = _blockDuration;
        delayDuration = _delayDuration;
        availiableImmediately = _availiableImmediately;
        percentagePerBlock = _percentagePerBlock;
        for (uint256 i = 0; i < _percentagePerMonth.length; i++) {
            percentagePerMonth.push(_percentagePerMonth[i]);
        }
        emit SetVesting(
            _withoutVesting,
            _delayDuration,
            _availiableImmediately,
            _percentagePerBlock,
            _blockDuration,
            _percentagePerMonth
        );
    }

    function _getAvailAllocation(address _sender, address _nftAddress)
        internal
        view
        returns (uint256)
    {
        if (!_inWhitelist(_sender, _nftAddress)) {
            if (!(_inWhitelist(_sender, address(0)) && isThirdRound())) {
                return 0;
            }
        }

        uint256 endFirstRound = saleStartDate + firstRoundDuration;

        if (
            block.timestamp > saleStartDate && block.timestamp <= endFirstRound
        ) {
            NFTInfo storage info = nftInfos[_nftAddress];
            return
                ((info.allocationPerNFT * totalRaise) / PERCENTAGE_100) -
                (depositedByNFT[_nftAddress][_sender]);
        } else if (
            block.timestamp > endFirstRound &&
            block.timestamp < endFirstRound + secondRoundDuration
        ) {
            NFTInfo storage info = nftInfos[_nftAddress];
            return
                ((info.allocationForTier * totalRaise) / PERCENTAGE_100) -
                info.deposited;
        } else if (isThirdRound()) {
            return totalRaise - totalDeposited;
        }

        return 0;
    }

    function _calculateAvailHarvest(
        address _sender,
        RewardTokenInfo memory _info
    ) internal view returns (uint256) {
        if (
            vestingStartDate == 0 ||
            block.timestamp < vestingStartDate + delayDuration
        ) return 0;
        uint256 canHarvestAmount = (deposited[_sender] *
            DECIMALS18 *
            _info.amount) /
            totalRaise /
            DECIMALS18;

        if (noVesting) {
            return canHarvestAmount - harvestPaid[_info.token][_sender];
        }

        uint256 amountImmediatelu = (availiableImmediately * canHarvestAmount) /
            PERCENTAGE_100;

        uint256 accruedAmount;

        if (percentagePerMonth.length > 0) {
            uint256 sumPercentByMonth = 0;
            uint256 monthCount = (block.timestamp -
                vestingStartDate -
                delayDuration) / 30 days;

            monthCount = Math.min(monthCount, percentagePerMonth.length);

            for (uint256 i = 0; i < monthCount; i++) {
                sumPercentByMonth += percentagePerMonth[i];
            }
            accruedAmount =
                (sumPercentByMonth * canHarvestAmount) /
                PERCENTAGE_100;
        } else {
            uint256 blockPassted = (block.timestamp -
                vestingStartDate -
                delayDuration) / blockDuration;
            accruedAmount =
                (blockPassted * percentagePerBlock * canHarvestAmount) /
                PERCENTAGE_100;
        }
        canHarvestAmount = Math.min(
            canHarvestAmount,
            amountImmediatelu + accruedAmount
        );

        return canHarvestAmount - harvestPaid[_info.token][_sender];
    }

    function _isSale() internal view returns (bool) {
        return
            block.timestamp >= saleStartDate && block.timestamp <= saleEndDate;
    }

    function isThirdRound() internal view returns (bool) {
        return
            block.timestamp <= saleEndDate &&
            block.timestamp >= saleEndDate - thirdRoundDuration;
    }

    function _inWhitelist(address _sender, address _nft)
        internal
        view
        returns (bool)
    {
        if (_nft == address(0)) {
            for (uint256 index = 0; index < nfts.length(); index++) {
                if (userByNft[nfts.at(index)][_sender]) {
                    return true;
                }
            }
        } else {
            return userByNft[_nft][_sender];
        }
        return false;
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Constants.sol";

contract Management is Ownable {
    using SafeMath for uint256;

    // Contract Registry
    mapping(uint256 => address payable) public contractRegistry;

    // Permissions
    mapping(address => mapping(uint256 => bool)) public permissions;

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

    function setPermission(
        address _address,
        uint256 _permission,
        bool _value
    ) external onlyOwner {
        permissions[_address][_permission] = _value;
        emit PermissionSet(_address, _permission, _value);
    }

    function setPermissions(
        address _address,
        uint256[] calldata _permissions,
        bool _value
    ) external onlyOwner {
        for (uint256 i = 0; i < _permissions.length; i++) {
            permissions[_address][_permissions[i]] = _value;
        }
        emit PermissionsSet(_address, _permissions, _value);
    }

    function registerContract(uint256 _key, address payable _target)
        external
        onlyOwner
    {
        contractRegistry[_key] = _target;
        emit ContractRegistered(_key, address(0), _target);
    }

    function setKycWhitelist(address _address, bool _value) external {
        require(
            permissions[msg.sender][CAN_SET_KYC_WHITELISTED],
            ERROR_ACCESS_DENIED
        );

        permissions[_address][WHITELISTED_KYC] = _value;

        emit PermissionSet(_address, WHITELISTED_KYC, _value);
    }

    function setKycWhitelists(address[] calldata _address, bool _value)
        external
    {
        require(
            permissions[msg.sender][CAN_SET_KYC_WHITELISTED],
            ERROR_ACCESS_DENIED
        );

        for (uint256 i = 0; i < _address.length; i++) {
            permissions[_address[i]][WHITELISTED_KYC] = _value;
        }
        emit UsersPermissionsSet(_address, WHITELISTED_KYC, _value);
    }

    function setPrivateWhitelists(address[] calldata _address, bool _value)
        external
    {
        require(
            permissions[msg.sender][CAN_SET_PRIVATE_WHITELISTED],
            ERROR_ACCESS_DENIED
        );

        for (uint256 i = 0; i < _address.length; i++) {
            permissions[_address[i]][WHITELISTED_PRIVATE] = _value;
        }

        emit UsersPermissionsSet(_address, WHITELISTED_PRIVATE, _value);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Constants.sol";
import "./Management.sol";

contract Managed is Ownable {
    using SafeMath for uint256;

    Management public management;

    modifier requirePermission(uint256 _permission) {
        require(
            hasPermission(msg.sender, _permission),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier requireKYCWhitelist(bool _isKYC) {
        if (_isKYC) {
            require(
                hasPermission(msg.sender, WHITELISTED_KYC),
                ERROR_ACCESS_DENIED
            );
        }
        _;
    }
    modifier requirePrivateWhitelist(bool _isPrivate) {
        if (_isPrivate) {
            require(
                hasPermission(msg.sender, WHITELISTED_PRIVATE),
                ERROR_ACCESS_DENIED
            );
        }
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

    constructor(address _managementAddress) {
        management = Management(_managementAddress);
    }

    function setManagementContract(address _management) public onlyOwner {
        require(address(0) != _management, ERROR_NO_CONTRACT);

        management = Management(_management);
    }

    function hasPermission(address _subject, uint256 _permission)
        internal
        view
        returns (bool)
    {
        return management.permissions(_subject, _permission);
    }

}

pragma solidity ^0.8.0;

uint256 constant DECIMALS = 18;
uint256 constant DECIMALS18 = 1e18;

uint256 constant MAX_UINT256 = type(uint256).max;
uint256 constant PERCENTAGE_100 = 10000;
uint256 constant PERCENTAGE_1 = 100;
uint256 constant MAX_FEE_PERCENTAGE = PERCENTAGE_100 - PERCENTAGE_1;
bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;

string constant ERROR_ACCESS_DENIED = "ERROR_ACCESS_DENIED";
string constant ERROR_NO_CONTRACT = "ERROR_NO_CONTRACT";
string constant ERROR_NOT_AVAILABLE = "ERROR_NOT_AVAILABLE";


address constant EMERGENCY_ADDRESS = 0x85CCc822A20768F50397BBA5Fd9DB7de68851D5B;

//permisionss
//WHITELIST
uint256 constant ROLE_ADMIN = 1;
uint256 constant ROLE_REGULAR = 5;

uint256 constant CAN_SET_KYC_WHITELISTED = 10;
uint256 constant CAN_SET_PRIVATE_WHITELISTED = 11;

uint256 constant WHITELISTED_KYC = 20;
uint256 constant WHITELISTED_PRIVATE = 21;

uint256 constant CAN_SET_REMAINING_SUPPLY = 29;

uint256 constant CAN_TRANSFER_NFT = 30;
uint256 constant CAN_MINT_NFT = 31;
uint256 constant CAN_BURN_NFT = 32;

uint256 constant CAN_ADD_STAKING = 43;
uint256 constant CAN_ADD_POOL = 45;

//REGISTER_ADDRESS
uint256 constant CONTRACT_MANAGEMENT = 0;
uint256 constant CONTRACT_KAISHI_TOKEN = 1;
uint256 constant CONTRACT_STAKE_FACTORY = 2;
uint256 constant CONTRACT_NFT_FACTORY = 3;
uint256 constant CONTRACT_LIQUIDITY_MINING_FACTORY = 4;
uint256 constant CONTRACT_STAKING_REGISTER = 5;
uint256 constant CONTRACT_POOL_REGISTER = 6;

uint256 constant ADDRESS_TRESUARY = 10;
uint256 constant ADDRESS_SIGNER = 11;
uint256 constant ADDRESS_OWNER = 12;

pragma solidity ^0.8.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}