pragma solidity 0.6.12;

import "../Governable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "../token/Lantti.sol";
import "./VaultyNft.sol";
import "./LanttiPools.sol";
import "./INftHub.sol";
import "../interfaces/IUpgradeSource.sol";
import "../ControllableInit.sol";
import "../upgradability/BaseProxyStorage.sol";

/**
 * @dev Contract for handling the NFT staking and set creation.
 */
contract NftHub is ControllableInit, BaseProxyStorage, IUpgradeSource, INftHub {
    using SafeMath for uint256;

    uint256 constant BONUS_PRECISION = 10**5;
    uint256 internal constant TYPE_MASK = uint256(uint128(~0)) << 128;

    event Stake(address indexed user, uint256[] nftIds);
    event Unstake(address indexed user, uint256[] nftIds);
    event Harvest(address indexed user, uint256 amount);

    struct NftSet {
        uint256[] nftIds;
        uint256 lanttiPerDayPerNft;
        uint256 bonusLanttiMultiplier;
        uint256[] poolBoosts; // Applicable if isBooster is true.Eg: [0,20000] = 0% boost for pool 1, 20% boost for pool 2
        uint256 bonusFullSetBoost; // Gives an additional boost if you stake all boosters of that set.
        bool isRemoved;
        bool isBooster; // False if the nft set doesn't give pool boost at lanttiPools
    }

    VaultyNft public nft;
    Lantti public lantti;
    LanttiPools public lanttiPools;

    uint256[] public nftSetList;
    //SetId mapped to all nft IDs in the set.
    mapping(uint256 => NftSet) public nftSets;
    //NftId to SetId mapping
    mapping(uint256 => uint256) public nftToSetId;
    mapping(uint256 => uint256) public maxNftStake;
    //Status of user's nfts staked mapped to the nftID
    mapping(address => mapping(uint256 => uint256)) public userNfts;
    //Last update time for a user's LANTTI rewards calculation
    mapping(address => uint256) public userLastUpdate;
    //Mapping data of booster of a user in a pool. 100% booster
    mapping(address => uint256) public boosterInfo;

    constructor() public {}

    function initialize(
        address _storage,
        VaultyNft _nft,
        Lantti _lantti
    ) public initializer {
        ControllableInit.initialize(_storage);

        nft = _nft;
        lantti = _lantti;
    }

    function setLanttiPools(LanttiPools _lanttiPools) public onlyGovernance {
        lanttiPools = _lanttiPools;
    }

    function setMultiplierOfAddress(address _address, uint256 _booster) public onlyGovernance {
        boosterInfo[_address] = _booster;
    }

    /**
     * @dev Utility function to check if a value is inside an array
     */
    function _isInArray(uint256 _value, uint256[] storage _array) internal view returns (bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_array[i] == _value) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Indexed boolean for whether a nft is staked or not. Index represents the nftId.
     */
    // function getNftsStakedOfAddress(address _user) public view returns (bool[] memory) {
    //     bool[] memory nftsStaked = new bool[](highestNftId + 1);
    //     for (uint256 i = 0; i < highestNftId + 1; ++i) {
    //         nftsStaked[i] = userNfts[_user][i];
    //     }
    //     return nftsStaked;
    // }

    /**
     * @dev Returns the list of nftIds which are part of a set
     */
    function getNftIdListOfSet(uint256 _setId) external view returns (uint256[] memory) {
        return nftSets[_setId].nftIds;
    }

    /**
     * @dev Returns the boosters associated with a nft Id per pool
     */
    function getBoostersOfNft(uint256 _nftId) external view returns (uint256[] memory) {
        return nftSets[nftToSetId[_nftId]].poolBoosts;
    }

    /**
     * @dev Indexed  boolean of each setId for which a user has a full set or not.
     */
    function getFullSetsOfAddress(address _user) public view returns (bool[] memory) {
        uint256 length = nftSetList.length;
        bool[] memory isFullSet = new bool[](length);
        for (uint256 i = 0; i < length; ++i) {
            uint256 setId = nftSetList[i];
            if (nftSets[setId].isRemoved) {
                isFullSet[i] = false;
                continue;
            }
            bool _fullSet = true;
            uint256[] memory _nftIds = nftSets[setId].nftIds;

            for (uint256 j = 0; j < _nftIds.length; ++j) {
                if (userNfts[_user][_nftIds[j]] == 0) {
                    _fullSet = false;
                    break;
                }
            }
            isFullSet[i] = _fullSet;
        }
        return isFullSet;
    }

    /**
     * @dev Returns the amount of NFTs staked by an address for a given set
     */
    function getNumOfNftsStakedForSet(address _user, uint256 _setId) public view returns (uint256) {
        uint256 nbStaked = 0;
        NftSet storage set = nftSets[_setId];
        if (set.isRemoved) {
            return 0;
        }

        uint256 length = set.nftIds.length;
        for (uint256 j = 0; j < length; ++j) {
            uint256 nftId = set.nftIds[j];
            if (userNfts[_user][nftId] != 0) {
                nbStaked = nbStaked.add(1);
            }
        }
        return nbStaked;
    }

    /**
     * @dev Returns the total amount of NFTs staked by an address across all sets
     */
    function getNumOfNftsStakedByAddress(address _user) public view returns (uint256) {
        uint256 nbStaked = 0;
        for (uint256 i = 0; i < nftSetList.length; ++i) {
            nbStaked = nbStaked.add(getNumOfNftsStakedForSet(_user, nftSetList[i]));
        }
        return nbStaked;
    }

    /**
     * @dev Returns the total lantti pending for a given address. Can include the bonus from NFT boosters,
     * if second param is set to true.
     */
    function totalPendingLanttiOfAddress(address _user, bool _includeLanttiBooster)
        public
        view
        returns (uint256)
    {
        uint256 totalLanttiPerDay = 0;
        uint256 length = nftSetList.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 setId = nftSetList[i];

            NftSet storage set = nftSets[setId];
            if (set.isRemoved) {
                continue;
            }

            uint256 nftLength = set.nftIds.length;
            bool isFullSet = true;
            uint256 setLanttiPerDay = 0;

            for (uint256 j = 0; j < nftLength; ++j) {
                uint256 nftsStaked = userNfts[_user][set.nftIds[j]];
                if (nftsStaked == 0) {
                    isFullSet = false;
                    continue;
                }
                setLanttiPerDay = setLanttiPerDay.add(set.lanttiPerDayPerNft.mul(nftsStaked));
            }

            if (isFullSet) {
                setLanttiPerDay = setLanttiPerDay
                    .mul(set.bonusLanttiMultiplier.add(BONUS_PRECISION))
                    .div(BONUS_PRECISION);
            }

            totalLanttiPerDay = totalLanttiPerDay.add(setLanttiPerDay);
        }

        if (_includeLanttiBooster) {
            uint256 boostMult = boosterInfo[_user].add(BONUS_PRECISION);
            totalLanttiPerDay = totalLanttiPerDay.mul(boostMult).div(BONUS_PRECISION);
        }

        uint256 lastUpdate = userLastUpdate[_user];
        uint256 blockTime = block.timestamp;

        return blockTime.sub(lastUpdate).mul(totalLanttiPerDay.div(24 hours));
    }

    /**
     * @dev Returns the applicable booster of a user, for a pool, from a staked NFT set.
     */
    function getBoosterForUser(address _user, uint256 _pid)
        external
        view
        override
        returns (uint256)
    {
        _pid = _pid.sub(1);

        uint256 totalBooster = 0;
        uint256 length = nftSetList.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 setId = nftSetList[i];
            NftSet storage set = nftSets[setId];
            if (!set.isBooster) {
                continue;
            }

            if (set.poolBoosts.length < _pid.add(1)) {
                continue;
            }

            if (set.poolBoosts[_pid] == 0) {
                continue;
            }

            uint256 nftLength = set.nftIds.length;
            bool isFullSet = true;
            uint256 setBooster = 0;

            for (uint256 j = 0; j < nftLength; ++j) {
                uint256 nftsStaked = userNfts[_user][set.nftIds[j]];
                if (nftsStaked == 0) {
                    isFullSet = false;
                    continue;
                }

                setBooster = setBooster.add(set.poolBoosts[_pid].mul(maxNftStake[nftsStaked]));
            }

            if (isFullSet) {
                setBooster = setBooster.add(set.bonusFullSetBoost);
            }

            totalBooster = totalBooster.add(setBooster);
        }
        return totalBooster;
    }

    /**
     * @dev Manually sets the highestNftId, if it goes out of sync.
     * Required calculate the range for iterating the list of staked nfts for an address.
     */
    // function setHighestNftId(uint256 _highestId) public onlyGovernance {
    //     require(_highestId > 0, "Set if minimum 1 nft is staked.");
    //     highestNftId = _highestId;
    // }

    /**
     * @dev Adds a nft set with the input param configs. Removes an existing set if the id exists.
     */
    function addNftSet(
        uint256 _setId,
        uint256[] memory _nftIds,
        uint256[] memory _max,
        uint256 _bonusLanttiMultiplier,
        uint256 _lanttiPerDayPerNft,
        uint256[] memory _poolBoosts,
        uint256 _bonusFullSetBoost,
        bool _isBooster
    ) public onlyGovernance {
        require(_nftIds.length == _max.length);

        removeNftSet(_setId);
        uint256 length = _nftIds.length;

        for (uint256 i = 0; i < length; ++i) {
            uint256 nftId = _nftIds[i];

            // Check all nfts to assign arent already part of another set
            require(nftToSetId[nftId] == 0, "Nft already assigned to a set");
            // Assign to set
            nftToSetId[nftId] = _setId;
            maxNftStake[nftId] = _max[i];
        }

        if (!_isInArray(_setId, nftSetList)) {
            nftSetList.push(_setId);
        }

        nftSets[_setId] = NftSet({
            nftIds: _nftIds,
            bonusLanttiMultiplier: _bonusLanttiMultiplier,
            lanttiPerDayPerNft: _lanttiPerDayPerNft,
            poolBoosts: _poolBoosts,
            bonusFullSetBoost: _bonusFullSetBoost,
            isRemoved: false,
            isBooster: _isBooster
        });
    }

    /**
     * @dev Updates the lanttiPerDayPerNft for a nft set.
     */
    function setLanttiRateOfSets(uint256[] memory _setIds, uint256[] memory _lanttiPerDayPerNft)
        public
        onlyGovernance
    {
        require(
            _setIds.length == _lanttiPerDayPerNft.length,
            "_setId and _lanttiPerDayPerNft have different length"
        );

        for (uint256 i = 0; i < _setIds.length; ++i) {
            require(nftSets[_setIds[i]].nftIds.length > 0, "Set is empty");
            nftSets[_setIds[i]].lanttiPerDayPerNft = _lanttiPerDayPerNft[i];
        }
    }

    /**
     * @dev Set the bonusLanttiMultiplier value for a list of Nft sets
     */
    function setBonusLanttiMultiplierOfSets(
        uint256[] memory _setIds,
        uint256[] memory _bonusLanttiMultiplier
    ) public onlyGovernance {
        require(
            _setIds.length == _bonusLanttiMultiplier.length,
            "_setId and _lanttiPerDayPerNft have different length"
        );
        for (uint256 i = 0; i < _setIds.length; ++i) {
            require(nftSets[_setIds[i]].nftIds.length > 0, "Set is empty");
            nftSets[_setIds[i]].bonusLanttiMultiplier = _bonusLanttiMultiplier[i];
        }
    }

    /**
     * @dev Remove a nftSet that has been added.
     * !!!  Warning : if a booster set is removed, users with the booster staked will continue to benefit from the multiplier  !!!
     */
    function removeNftSet(uint256 _setId) public onlyGovernance {
        uint256 length = nftSets[_setId].nftIds.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 nftId = nftSets[_setId].nftIds[i];
            nftToSetId[nftId] = 0;
        }
        delete nftSets[_setId].nftIds;
        nftSets[_setId].isRemoved = true;
        nftSets[_setId].isBooster = false;
    }

    /**
     * @dev Harvests the accumulated LANTTI in the contract, for the caller.
     */
    function harvest() public {
        uint256 pendingLantti = totalPendingLanttiOfAddress(msg.sender, true);
        userLastUpdate[msg.sender] = block.timestamp;
        if (pendingLantti > 0) {
            lantti.mint(msg.sender, pendingLantti);
        }
        emit Harvest(msg.sender, pendingLantti);
    }

    /**
     * @dev Stakes the nfts on providing the nft IDs.
     */
    function stake(uint256[] memory _nftIds) public {
        stakeAction(_nftIds, true);
    }

    /**
     * @dev Unstakes the nfts on providing the nft IDs.
     */
    function unstake(uint256[] memory _nftIds) public {
        stakeAction(_nftIds, false);
    }

    function stakeAction(uint256[] memory _nftIds, bool stake) private {
        require(_nftIds.length > 0, "you need to stake something");

        // Check no nft will end up above max stake and if it is needed to update the user NFT pool
        uint256 length = _nftIds.length;
        bool hasLanttis = false;
        bool onlyNoBoosters = true;
        uint256 setId;
        uint256 nftType;
        NftSet storage nftSet;

        for (uint256 i = 0; i < length; ++i) {
            nftType = extractType(_nftIds[i]);
            setId = nftToSetId[nftType];

            require(setId != 0, "unknown set");

            if (stake) {
                require(userNfts[msg.sender][nftType] <= maxNftStake[nftType], "max staked");
                userNfts[msg.sender][nftType]++;
            } else {
                require(userNfts[msg.sender][nftType] != 0, "not staked");
                userNfts[msg.sender][nftType]--;
            }

            if (nftSets[setId].lanttiPerDayPerNft > 0) {
                hasLanttis = true;
            }

            if (nftSets[setId].isBooster) {
                onlyNoBoosters = false;
            }
        }

        // Harvest NFT pool if the LANTTI/day will be modified
        if (hasLanttis) {
            harvest();
        }

        // Harvest each pool where booster value will be modified
        if (!onlyNoBoosters) {
            for (uint256 i = 0; i < length; ++i) {
                nftType = extractType(_nftIds[i]);
                setId = nftToSetId[nftType];

                if (nftSets[setId].isBooster) {
                    nftSet = nftSets[setId];
                    uint256 boostLength = nftSet.poolBoosts.length;
                    for (uint256 j = 1; j <= boostLength; ++j) {
                        // pool ID starts from 1
                        if (
                            nftSet.poolBoosts[j - 1] > 0 &&
                            lanttiPools.pendingLantti(j, msg.sender) > 0
                        ) {
                            address staker = msg.sender;
                            lanttiPools.withdraw(j, 0, staker);
                        }
                    }
                }
            }
        }

        //Stake 1 unit of each nftId
        uint256[] memory amounts = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            amounts[i] = 1;
        }

        if (stake) {
            nft.safeBatchTransferFrom(msg.sender, address(this), _nftIds, amounts, "");
            emit Stake(msg.sender, _nftIds);
        } else {
            nft.safeBatchTransferFrom(address(this), msg.sender, _nftIds, amounts, "");
            emit Unstake(msg.sender, _nftIds);
        }
    }

    /**
     * @dev Emergency unstake the nfts on providing the nft IDs, forfeiting the LANTTI rewards in both Hub and LanttiPools.
     */
    function emergencyUnstake(uint256[] memory _nftIds) public {
        userLastUpdate[msg.sender] = block.timestamp;

        uint256[] memory amounts = new uint256[](_nftIds.length);
        uint256 length = _nftIds.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 nftType = extractType(_nftIds[i]);

            uint256 nftsStaked = userNfts[msg.sender][nftType];
            require(nftsStaked != 0, "Nft not staked");

            amounts[i] = 1;
            userNfts[msg.sender][nftType]--;
        }

        nft.safeBatchTransferFrom(address(this), msg.sender, _nftIds, amounts, "");
    }

    // update pot address if the pot logic changed.
    function updateLanttiPoolsAddress(LanttiPools _pools) public onlyGovernance {
        lanttiPools = _pools;
    }

    function extractType(uint256 nftId) private pure returns (uint256) {
        return nftId & TYPE_MASK;
    }

    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bytes4) {
        return 0xf23a6e61;
    }

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external returns (bytes4) {
        return 0xbc197c81;
    }

    /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return
            interfaceID == 0x01ffc9a7 || // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceID == 0x4e2312e0; // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }

    function scheduleUpgrade(address impl) public onlyGovernance {
        _setNextImplementation(impl);
        _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
    }

    function shouldUpgrade() external view override returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0 &&
                block.timestamp > nextImplementationTimestamp() &&
                nextImplementation() != address(0),
            nextImplementation()
        );
    }

    function finalizeUpgrade() external override onlyGovernance {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }
}

pragma solidity 0.6.12;

import "./Storage.sol";

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
     *
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity 0.6.12;

import "./BEP20.sol";
import "../Governable.sol";
import "../lib/MinterRole.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

contract Lantti is MinterRole, BEP20, Governable {
  using SafeMath for uint256;

  constructor(address _storage)
        public
        BEP20("LANTTI", "LANTTI")
        Governable(_storage)
    {
      renounceOwnership();

      address gov = governance();
      if (!isMinter(gov)) {
        _addMinter(gov);
      }
    }  

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) public onlyMinter {
      _burn(account, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
      revert("disabled");
    }
}

pragma solidity 0.6.12;

import "../token/ERC1155.sol";

contract VaultyNft is ERC1155Mintable {
    string private _contractURI;

    constructor(address _proxyRegistryAddress) public ERC1155Mintable("Vaulty NFT", "VaultyNFT", _proxyRegistryAddress) {
        _setBaseMetadataURI("https://api.vaulty.finance/nft/");
    }
    
    /**
         * @dev Ends minting of token
         * @param _id          Token ID for which minting will end
         */
    function endMinting(uint256 _id) external onlyWhitelistAdmin {
        tokenMaxSupply[_id] = tokenSupply[_id];
    }

    function burnFt(address _account, uint256 _id, uint256 _amount) public onlyMinter {
        _burnFungible(_account, _id, _amount);
    }

    function burnNft(address _account, uint256 _id) public onlyMinter {
        _burnNonFungible(_account, _id);
    }

    function airdropFt(uint256 _id, address[] memory _addresses) public onlyMinter {
        require(tokenMaxSupply[_id] - tokenSupply[_id] >= _addresses.length, "cannot mint above max supply");
        for (uint256 i = 0; i < _addresses.length; i++) {
            mintFt(_addresses[i], _id, 1, "");
        }
    }

    function airdropNft(uint256 _type, address[] memory _addresses) public onlyMinter {
        for (uint256 i = 0; i < _addresses.length; i++) {
            mintNft(_addresses[i], _type, "");
        }
    }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "../Governable.sol";
import "../token/Lantti.sol";
import "./INftHub.sol";
import "../interfaces/IUpgradeSource.sol";
import "../ControllableInit.sol";
import "../upgradability/BaseProxyStorage.sol";

contract LanttiPools is ControllableInit, BaseProxyStorage, IUpgradeSource {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256 public constant BONUS_PRECISION = 10**5;
    uint256 public constant REWARD_PRECISION = 10**12;

    // info of each user.
    struct UserInfo {
        uint256 amount; // how many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // we do some fancy math here. basically, any point in time, the amount of LANTTI
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accLanttiPerShare) - user.rewardDebt
        //
        // whenever a user deposits or withdraws tokens to a pool. Here's what happens:
        //   1. user's pending reward is minted to his/her address.
        //   2. user's `amount` gets updated.
        //   3. user's `lastUpdate` gets updated.
    }

    // info of each pool.
    struct PoolInfo {
        IBEP20 token; // address of token contract.
        uint256 lanttiPerDay; // the amount of LANTTI per day generated for each token staked
        uint256 maxStake; // the maximum amount of tokens which can be staked in this pool
        uint256 lastUpdateTime; // last timestamp that LANTTI distribution occurs.
        uint256 accLanttiPerShare; // accumulated LANTTI per share. See below.
    }

    // info of each pool.
    PoolInfo[] public poolInfo;
    // info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // record whether the pair has been added.
    mapping(address => uint256) public tokenPID;

    Lantti public lantti;
    INftHub public hub;
    uint256 public rewardsUnit;

    event PoolCreated(address indexed token, uint256 pid);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor() public {}

    function initialize(
        address _storage,
        Lantti _lantti,
        INftHub _hub
    ) public initializer {
        ControllableInit.initialize(_storage);

        lantti = _lantti;
        hub = _hub;

        uint256 d = _lantti.decimals();
        rewardsUnit = 10**d;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // add a new token to the pool. can only be called by the owner.
    // XXX DO NOT add the same token more than once. rewards will be messed up if you do.
    function add(
        address _token,
        uint256 _lanttiPerDay,
        uint256 _maxStake
    ) public onlyGovernance {
        uint256 pid = poolInfo.length.add(1);

        require(tokenPID[_token] == 0, "duplicated pool");
        require(_token != address(lantti), "can't stake lantti");
        poolInfo.push(
            PoolInfo({
                token: IBEP20(_token),
                maxStake: _maxStake,
                lanttiPerDay: _lanttiPerDay,
                lastUpdateTime: block.timestamp,
                accLanttiPerShare: 0
            })
        );

        tokenPID[_token] = pid;

        emit PoolCreated(_token, pid);
    }

    // set a new max stake. value must be greater than previous one,
    // to not give an unfair advantage to people who already staked > new max
    function setMaxStake(uint256 pid, uint256 amount) public onlyGovernance {
        poolInfo[pid.sub(1)].maxStake = amount;
    }

    // set the amount of LANTTI generated per day for each token staked
    function setLanttiPerDay(uint256 pid, uint256 amount) public onlyGovernance {
        PoolInfo storage pool = poolInfo[pid.sub(1)];
        uint256 blockTime = block.timestamp;
        uint256 lanttiReward = blockTime.sub(pool.lastUpdateTime).mul(pool.lanttiPerDay);

        pool.accLanttiPerShare = pool.accLanttiPerShare.add(
            lanttiReward.mul(REWARD_PRECISION).div(24 hours)
        );
        pool.lastUpdateTime = block.timestamp;
        pool.lanttiPerDay = amount;
    }

    function _userPoolState(uint256 _pid, address _user)
        internal
        view
        returns (uint256 pending, uint256 accLantti)
    {
        PoolInfo storage pool = poolInfo[_pid.sub(1)];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 blockTime = block.timestamp;
        accLantti = pool.accLanttiPerShare;

        uint256 lanttiReward = blockTime.sub(pool.lastUpdateTime).mul(pool.lanttiPerDay);
        accLantti = accLantti.add(lanttiReward.mul(REWARD_PRECISION).div(24 hours));

        pending = user.amount.mul(accLantti).div(REWARD_PRECISION).sub(user.rewardDebt).div(
            rewardsUnit
        );
    }

    // view function to see pending LANTTI on a frontend.
    function pendingLantti(uint256 _pid, address _user) public view returns (uint256) {
        (uint256 pending, ) = _userPoolState(_pid, _user);
        uint256 booster = hub.getBoosterForUser(_user, _pid);
        if (booster > 0) {
            pending = pending.mul(booster.add(BONUS_PRECISION));
            pending = pending.div(BONUS_PRECISION);
        }
        return pending;
    }

    // view function to calculate the total pending LANTTI of address across all pools
    function totalPendingLantti(address _user) public view returns (uint256) {
        uint256 total = 0;
        uint256 length = poolInfo.length;
        for (uint256 pid = 1; pid <= length; ++pid) {
            total = total.add(pendingLantti(pid, _user));
        }

        return total;
    }

    // harvest pending LANTTI of a list of pools.
    // might be worth it checking in the frontend for the pool IDs with pending lantti for this address and only harvest those
    function rugPull(uint256[] memory _pids) public {
        for (uint256 i = 0; i < _pids.length; i++) {
            withdraw(_pids[i], 0, msg.sender);
        }
    }

    // deposit LP tokens to pool for LANTTI allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid.sub(1)];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 userAmount = user.amount;
        require(_amount.add(userAmount) <= pool.maxStake, "cannot stake beyond max stake value");

        (uint256 pending, uint256 accLantti) = _userPoolState(_pid, msg.sender);
        userAmount = userAmount.add(_amount);
        user.rewardDebt = userAmount.mul(accLantti).div(REWARD_PRECISION);
        user.amount = userAmount;

        uint256 booster = hub.getBoosterForUser(msg.sender, _pid).add(BONUS_PRECISION);
        uint256 pendingWithBooster = pending.mul(booster).div(BONUS_PRECISION);
        if (pendingWithBooster > 0) {
            lantti.mint(msg.sender, pendingWithBooster);
        }

        pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // withdraw tokens from pool
    // withdrawing 0 amount will harvest rewards only
    function withdraw(
        uint256 _pid,
        uint256 _amount,
        address _staker
    ) public {
        address staker = _staker;
        PoolInfo storage pool = poolInfo[_pid.sub(1)];
        UserInfo storage user = userInfo[_pid][staker];

        uint256 userAmount = user.amount;

        if (userAmount == 0) {
            // early exit, nothing was staked to this pool
            return;
        }

        require(userAmount >= _amount, "not enough amount");
        require(msg.sender == staker || _amount == 0);

        (uint256 pending, uint256 accLantti) = _userPoolState(_pid, staker);

        // in case the maxstake has been lowered and address is above maxstake, we force it to withdraw what is above current maxstake
        // user can delay his/her withdraw/harvest to take advantage of a reducing of maxstake,
        // if he/she entered the pool at maxstake before the maxstake reducing occured
        uint256 leftAfterWithdraw = userAmount.sub(_amount);
        if (leftAfterWithdraw > pool.maxStake) {
            _amount = _amount.add(leftAfterWithdraw - pool.maxStake);
        }

        userAmount = userAmount.sub(_amount);
        user.rewardDebt = userAmount.mul(accLantti).div(REWARD_PRECISION);
        user.amount = userAmount;

        uint256 booster = hub.getBoosterForUser(staker, _pid).add(BONUS_PRECISION);
        uint256 pendingWithBooster = pending.mul(booster).div(BONUS_PRECISION);
        if (pendingWithBooster > 0) {
            lantti.mint(staker, pendingWithBooster);
        }

        pool.token.safeTransfer(address(staker), _amount);
        emit Withdraw(staker, _pid, _amount);
    }

    // withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid.sub(1)];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount > 0, "not enough amount");

        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(address(msg.sender), _amount);

        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // update hub address if the booster logic changed.
    function updateNftHubAddress(INftHub _hub) public onlyGovernance {
        hub = _hub;
    }

    function scheduleUpgrade(address impl) public onlyGovernance {
        _setNextImplementation(impl);
        _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
    }

    function shouldUpgrade() external view override returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0 &&
                block.timestamp > nextImplementationTimestamp() &&
                nextImplementation() != address(0),
            nextImplementation()
        );
    }

    function finalizeUpgrade() external override onlyGovernance {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }
}

pragma solidity 0.6.12;

interface INftHub {
  function getBoosterForUser(address _user, uint256 _pid) external view returns (uint256);
}

pragma solidity 0.6.12;

interface IUpgradeSource {
  function shouldUpgrade() external view returns (bool, address);
  function finalizeUpgrade() external;
}

pragma solidity 0.6.12;

import "./GovernableInit.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract ControllableInit is GovernableInit {

  constructor() public {
  }

  function initialize(address _storage) public override initializer {
    GovernableInit.initialize(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract BaseProxyStorage is Initializable {
  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0xd2e419928330bff46341e233ce76acced45e2a4d72eca0da439ceaad8a810424;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0xcc513a9d9a86885d0dcbd3c0ba0e09e91c988d066a2c3099cb0f0f4104ea0797;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0xc30f2f65a1117bd1d1a12244675384902c0891a5bfbe53e738e28acfb09c8cb0;


  constructor() public {
    assert(_NEXT_IMPLEMENTATION_SLOT == keccak256("eip1967.proxyStorage.nextImplementation"));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == keccak256("eip1967.proxyStorage.nextImplementationTimestamp"));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == keccak256("eip1967.proxyStorage.nextImplementationDelay"));
  }

  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function nextImplementation() public view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function nextImplementationTimestamp() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

  function _setNextImplementationDelay(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
  }

  function nextImplementationDelay() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
  }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  uint256[100] private ______gap;
}

pragma solidity 0.6.12;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol";

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    // function mint(uint256 amount) public virtual onlyOwner returns (bool) {
    //     _mint(_msgSender(), amount);
    //     return true;
    // }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "./Roles.sol";

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "not minter");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity 0.6.12;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "roles: account already has requested role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "roles: account does not have needed role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol";
import "./IERC165.sol";
import "./IERC1155TokenReceiver.sol";
import "../lib/MinterRole.sol";
import "../lib/WhitelistAdminRole.sol";
import "../lib/Strings.sol";
import "./ProxyRegistry.sol";

/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC165 {
    using SafeMath for uint256;
    using Address for address;

    // Use a split bit implementation.
    // Store the type in the upper 128 bits..
    uint256 internal constant TYPE_MASK = uint256(uint128(~0)) << 128;

    // ..and the non-fungible index in the lower 128
    uint256 internal constant NF_INDEX_MASK = uint128(~0);

    uint256 internal constant TYPE_NF_BIT = 1 << 255;

    /***********************************|
    |        Variables and Events       |
    |__________________________________*/

    // onReceive function signatures
    bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    // Objects balances
    mapping(address => mapping(uint256 => uint256)) internal balances;

    mapping(uint256 => address) public nfOwners;

    // Operator Functions
    mapping(address => mapping(address => bool)) internal operators;

    // Events
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _uri, uint256 indexed _id);

    function getNonFungibleIndex(uint256 _id) public pure returns (uint256) {
        return _id & NF_INDEX_MASK;
    }

    function getNonFungibleBaseType(uint256 _id) public pure returns (uint256) {
        return _id & TYPE_MASK;
    }

    function ownerOf(uint256 _id) public view returns (address) {
        return nfOwners[_id];
    }

    function isNonFungible(uint256 _id) public pure returns (bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    /***********************************|
    |     Public Transfer Functions     |
    |__________________________________*/

    /**
     * @notice Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     * @param _data    Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public {
        require(
            (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
            "erc1155#safetransferfrom: INVALID_OPERATOR"
        );
        require(_to != address(0), "erc1155#safetransferfrom: INVALID_RECIPIENT");
        // require(_amount >= balances[_from][_id]) is not necessary since checked with safemath operations

        _safeTransferFrom(_from, _to, _id, _amount);
        _callonERC1155Received(_from, _to, _id, _amount, _data);
    }

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     * @param _data     Additional data with no specified format, sent in call to `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public {
        // Requirements
        require(
            (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
            "erc1155#safebatchtransferfrom: INVALID_OPERATOR"
        );
        require(_to != address(0), "erc1155#safebatchtransferfrom: INVALID_RECIPIENT");

        _safeBatchTransferFrom(_from, _to, _ids, _amounts);
        _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
    }

    /***********************************|
    |    Internal Transfer Functions    |
    |__________________________________*/

    /**
     * @notice Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     */
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) internal {
        // Update balances
        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from, "erc1155#_safeTransferFrom: NOT OWNER");
            nfOwners[_id] = _to;
        } else {
            balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
            balances[_to][_id] = balances[_to][_id].add(_amount); // Add amount
        }

        // Emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
     */
    function _callonERC1155Received(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        // Check if recipient is contract
        if (_to.isContract()) {
            bytes4 retval =
                IERC1155TokenReceiver(_to).onERC1155Received(
                    msg.sender,
                    _from,
                    _id,
                    _amount,
                    _data
                );
            require(
                retval == ERC1155_RECEIVED_VALUE,
                "erc1155#_callonerc1155received: INVALID_ON_RECEIVE_MESSAGE"
            );
        }
    }

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     */
    function _safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) internal {
        require(
            _ids.length == _amounts.length,
            "erc1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH"
        );

        // Number of transfer to execute
        uint256 nTransfer = _ids.length;

        // Executing all transfers
        for (uint256 i = 0; i < nTransfer; i++) {
            uint256 id = _ids[i];

            if (isNonFungible(id)) {
                require(nfOwners[id] == _from, "erc1155#_safeBatchTransferFrom: NOT OWNER");
                nfOwners[id] = _to;
            } else {
                // Update storage balance of previous bin
                balances[_from][id] = balances[_from][id].sub(_amounts[i]);
                balances[_to][id] = balances[_to][id].add(_amounts[i]);
            }
        }

        // Emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
     */
    function _callonERC1155BatchReceived(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        // Pass data if recipient is contract
        if (_to.isContract()) {
            bytes4 retval =
                IERC1155TokenReceiver(_to).onERC1155BatchReceived(
                    msg.sender,
                    _from,
                    _ids,
                    _amounts,
                    _data
                );
            require(
                retval == ERC1155_BATCH_RECEIVED_VALUE,
                "erc1155#_callonerc1155batchreceived: INVALID_ON_RECEIVE_MESSAGE"
            );
        }
    }

    /***********************************|
    |         Operator Functions        |
    |__________________________________*/

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        // Update operator status
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _owner     The owner of the Tokens
     * @param _operator  Address of authorized operator
     * @return isOperator True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        returns (bool isOperator)
    {
        return operators[_owner][_operator];
    }

    /***********************************|
    |         Balance Functions         |
    |__________________________________*/

    /**
     * @notice Get the balance of an account's Tokens
     * @param _owner  The address of the token holder
     * @param _id     ID of the Token
     * @return The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) public view returns (uint256) {
        return balances[_owner][_id];
    }

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the Tokens
     * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
        public
        view
        returns (uint256[] memory)
    {
        require(_owners.length == _ids.length, "erc1155#balanceofbatch: INVALID_ARRAY_LENGTH");

        // Variables
        uint256[] memory batchBalances = new uint256[](_owners.length);

        // Iterate over each owner and token ID
        for (uint256 i = 0; i < _owners.length; i++) {
            batchBalances[i] = balances[_owners[i]][_ids[i]];
        }

        return batchBalances;
    }

    /***********************************|
    |          ERC165 Functions         |
    |__________________________________*/

    /**
     * INTERFACE_SIGNATURE_ERC165 = bytes4(keccak256("supportsInterface(bytes4)"));
     */
    bytes4 private constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /**
     * INTERFACE_SIGNATURE_ERC1155 =
     * bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
     * bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
     * bytes4(keccak256("balanceOf(address,uint256)")) ^
     * bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
     * bytes4(keccak256("setApprovalForAll(address,bool)")) ^
     * bytes4(keccak256("isApprovedForAll(address,address)"));
     */
    bytes4 private constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceID  The interface identifier, as specified in ERC-165
     * @return `true` if the contract implements `_interfaceID` and
     */
    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        if (
            _interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC1155
        ) {
            return true;
        }
        return false;
    }
}

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata {
    using Strings for uint256;

    // URI's default URI prefix
    string internal baseMetadataURI;
    event URI(string _uri, uint256 indexed _id);

    /***********************************|
    |     Metadata Public Function s    |
    |__________________________________*/

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     *      URIs are assumed to be deterministically generated based on token ID
     *      Token IDs are assumed to be represented in their hex format in URIs
     * @return URI string
     */
    function uri(uint256 _id) public view virtual returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, _id.uint2str()));
    }

    /***********************************|
    |    Metadata Internal Functions    |
    |__________________________________*/

    /**
     * @notice Will emit default URI log event for corresponding token _id
     * @param _tokenIDs Array of IDs of tokens to log default URI
     */
    function _logURIs(uint256[] memory _tokenIDs) internal {
        string memory baseURL = baseMetadataURI;
        string memory tokenURI;

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            tokenURI = string(abi.encodePacked(baseURL, _tokenIDs[i].uint2str()));
            emit URI(tokenURI, _tokenIDs[i]);
        }
    }

    /**
     * @notice Will emit a specific URI log event for corresponding token
     * @param _tokenIDs IDs of the token corresponding to the _uris logged
     * @param _URIs    The URIs of the specified _tokenIDs
     */
    function _logURIs(uint256[] memory _tokenIDs, string[] memory _URIs) internal {
        require(
            _tokenIDs.length == _URIs.length,
            "erc1155metadata#_loguris: INVALID_ARRAYS_LENGTH"
        );
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            emit URI(_URIs[i], _tokenIDs[i]);
        }
    }

    /**
     * @notice Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
        baseMetadataURI = _newBaseMetadataURI;
    }
}

/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {
    mapping(uint256 => uint256) maxIndex;

    /****************************************|
    |            Minting Functions           |
    |_______________________________________*/

    /**
     * @notice Mint _amount of tokens of a given id
     * @param _to      The address to mint tokens to
     * @param _id      Token id to mint
     * @param _amount  The amount to be minted
     * @param _data    Data to pass if receiver is contract
     */
    function _mintFungible(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        // Add _amount
        balances[_to][_id] = balances[_to][_id].add(_amount);

        // Emit event
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

        // Calling onReceive method if recipient is contract
        _callonERC1155Received(address(0x0), _to, _id, _amount, _data);
    }

    function _mintNonFungible(
        address _to,
        uint256 _type,
        bytes memory _data
    ) internal returns (uint256) {
        require(isNonFungible(_type), "not nft");

        uint256 index = maxIndex[_type] + 1;
        maxIndex[_type] = index;

        uint256 _id = _type | index;

        nfOwners[_id] = _to;

        // Emit event
        emit TransferSingle(msg.sender, address(0x0), _to, _id, 1);

        // Calling onReceive method if recipient is contract
        _callonERC1155Received(address(0x0), _to, _id, 1, _data);

        return _id;
    }

    /****************************************|
    |            Burning Functions           |
    |_______________________________________*/

    /**
     * @notice Burn _amount of tokens of a given token id
     * @param _from    The address to burn tokens from
     * @param _id      Token id to burn
     * @param _amount  The amount to be burned
     */
    function _burnFungible(
        address _from,
        uint256 _id,
        uint256 _amount
    ) internal {
        //Substract _amount
        balances[_from][_id] = balances[_from][_id].sub(_amount);

        // Emit event
        emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
    }

    function _burnNonFungible(address _from, uint256 _id) internal {
        require(nfOwners[_id] == _from);

        nfOwners[_id] = address(0x0);

        // Emit event
        emit TransferSingle(msg.sender, _from, address(0x0), _id, 1);
    }
}

/**
 * @title ERC1155Mintable
 * ERC1155Mintable - ERC1155 contract that whitelists an operator address,
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Mintable is
    ERC1155,
    ERC1155MintBurn,
    ERC1155Metadata,
    Ownable,
    MinterRole,
    WhitelistAdminRole
{
    using Strings for string;

    address proxyRegistryAddress;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) public {
        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Returns the max quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyWhitelistAdmin {
        _setBaseMetadataURI(_newBaseMetadataURI);
    }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * @param _maxSupply max supply allowed
     * @param _initialSupply Optional amount to supply the first owner
     * @param _uri Optional URI for this token type
     * @param _data Optional data to pass if receiver is contract
     * @return tokenId The newly created token ID
     */
    function create(
        uint256 _type,
        uint256 _maxSupply,
        uint256 _initialSupply,
        bool isNft,
        string calldata _uri,
        bytes calldata _data
    ) external onlyWhitelistAdmin returns (uint256 tokenId) {
        if (isNft) {
            _type <<= 128;
            _type |= TYPE_NF_BIT;
        }

        require(tokenMaxSupply[_type] == 0, "type exists");
        require(_initialSupply <= _maxSupply, "initial supply cannot be more than max supply");
        require(_maxSupply != 0, "incorrect max supply");

        if (bytes(_uri).length != 0) {
            emit URI(_uri, _type);
        }

        if (_initialSupply != 0) {
            if (isNft) {
                for (uint256 i = 0; i < _initialSupply; ++i) {
                    _mintNonFungible(msg.sender, _type, _data);
                }
            } else {
                _mintFungible(msg.sender, _type, _initialSupply, _data);
            }

            tokenSupply[_type] = _initialSupply;
        }

        tokenMaxSupply[_type] = _maxSupply;
        return _type;
    }

    /**
     * @dev Mints some amount of tokens to an address
     * @param _to          Address of the future owner of the token
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     * @param _data        Data to pass if receiver is contract
     */
    function mintFt(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public onlyMinter {
        uint256 tokenId = _id;

        uint256 newSupply = tokenSupply[tokenId].add(_quantity);
        require(newSupply <= tokenMaxSupply[tokenId], "max supply has reached");

        _mintFungible(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    function mintNft(
        address _to,
        uint256 _type,
        bytes memory _data
    ) public onlyMinter returns (uint256) {
        uint256 newSupply = tokenSupply[_type].add(1);
        require(newSupply <= tokenMaxSupply[_type], "max supply has reached");

        uint256 id = _mintNonFungible(_to, _type, _data);
        tokenSupply[_type]++;
        return id;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings - The Beano of NFTs
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return tokenMaxSupply[_id] != 0;
    }
}

pragma solidity 0.6.12;

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    virtual
    external
    view
    returns (bool);
}

pragma solidity 0.6.12;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) virtual external returns(bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) virtual external returns(bytes4);

    /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) virtual external view returns (bool);

}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "./Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "not admin");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

pragma solidity 0.6.12;

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity 0.6.12;

import "../Governable.sol";

contract ProxyRegistry is Governable {
  mapping(address => address) public proxies;

  constructor(address _storage) public Governable(_storage) {}

  function addOperator(address _owner, address _operator) public onlyGovernance {
    proxies[_owner] = _operator;
  }

  function removeOperator(address _owner) public onlyGovernance {
    delete proxies[_owner];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./Storage.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() public {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function initialize(address _store) public virtual initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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