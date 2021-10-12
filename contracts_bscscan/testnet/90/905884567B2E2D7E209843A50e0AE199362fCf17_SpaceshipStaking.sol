// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./common/Globals.sol";
import "./token/BEP20/IBEP20.sol";
import "./token/ERC721/IAlienWorldsNFT.sol";
import "./ISpaceshipStaking.sol";

/// @title SpaceshipStaking contract.
contract SpaceshipStaking is ISpaceshipStaking, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint64;

    IBEP20 public TLMToken;

    /// @dev Contain needed information that user input when join to mission.
    struct UserInvest {
        uint256 ships;
        uint256 BNBAmount;
    }

    /// @notice Contain all missions
    mapping(uint256 => Mission) public missions;
    /// @notice Total missions count.
    uint256 public missionsCount = 0;

    /// @notice Contain relation between `missionNum` and all `UserInvest` (join user info) that connect to mission
    mapping(uint256 => mapping(address => UserInvest)) public missionToUsersInvest;

    /// @param _TLMToken TLM BEP20 address.
    constructor(address _TLMToken) {
        TLMToken = IBEP20(_TLMToken);
    }

    /// @notice Create new mission.
    /// @dev See test for Mission structure example. Only for owner.
    /// @param _newMission New mission structure.
    /// @return True if creation success.
    function createMission(Mission memory _newMission) external override onlyOwner returns(bool) {
        require(_newMission.launchTime > _newMission.boardingTime, "[E-38] - Boarding time less then launch time.");
        require(_newMission.launchTime > block.timestamp, "[E-39] - Launch time less current timestamp.");
        require(_newMission.duration > 0, "[E-40] - Duration can't be a zero.");
        require(_newMission.reward > 0, "[E-42] - Reward can't be a zero.");
        require(_newMission.spaceshipCost > 0, "[E-43] - Spaceship cost can't be a zero.");
        require(_newMission.nftInfo.contractAddress != address(0), "[E-44] - NFT contract can't be zero address.");
        require(bytes(_newMission.nftInfo.tokenURI).length != 0, "[E-45] - NFT token uri can't be empty.");

        _checkBoostOrder(_newMission);

        TLMToken.transferFrom(msg.sender, address(this), _newMission.reward);

        uint256 _missionNumber = missionsCount;
        missions[_missionNumber] = _newMission;
        missionsCount++;

        emit MissionCreated(_missionNumber, _newMission.name);

        return true;
    }

    /// @notice Allow user join to created mission.
    /// @param _missionNum Existed mission number.
    /// @param _spaceshipCount Spaceship count that user send on mission.
    /// @return True if join success.
    function joinToMission(uint256 _missionNum, uint256 _spaceshipCount) external payable override returns(bool) {
        require(_spaceshipCount > 0, "[E-63] - Spaceship count can't be a zero.");

        Mission memory _mission = _getMission(_missionNum);
        require(_mission.launchTime > block.timestamp, "[E-64] - Registration closed because mission already launched.");
        require(_mission.boardingTime < block.timestamp, "[E-65] - Registration on mission still not launched.");

        uint256 _BNBAmount = msg.value;
        uint256 _newSpaceshipCount = _spaceshipCount;

        UserInvest memory _oldUserInvest = missionToUsersInvest[_missionNum][msg.sender];
        if (_oldUserInvest.ships != 0) {
            // Remove old user power from mission
            uint256 _oldUserPower = _calculateUserPower(_mission, _oldUserInvest);
            _mission.missionPower = (_mission.missionPower).sub(_oldUserPower);

            // Form new input parameters based on old userInvest
            _newSpaceshipCount = _newSpaceshipCount.add(_oldUserInvest.ships);
            _BNBAmount = _BNBAmount.add(_oldUserInvest.BNBAmount);
        }

        // Add user to mission
        UserInvest memory _newUserInvests = UserInvest(_newSpaceshipCount, _BNBAmount);
        missionToUsersInvest[_missionNum][msg.sender] = _newUserInvests;

        // Calculate new user power and add it to mission
        uint256 _newUserPower = _calculateUserPower(_mission, _newUserInvests);
        missions[_missionNum].missionPower = (_mission.missionPower).add(_newUserPower);

        // Calculate mission price for user and transfer token to contract
        uint256 _TLMMissionPrice = _getJoinMissionPrice(_mission, _spaceshipCount);
        TLMToken.transferFrom(msg.sender, address(this), _TLMMissionPrice);

        emit MissionJoined(_missionNum, msg.sender, _spaceshipCount);

        return true;
    }

    /// @notice See `_calculateReward()`.
    /// @param _missionNum Existed mission number.
    /// @return All info about reward for mission.
    function calculateReward(uint256 _missionNum) external view override returns(RewardInfo memory) {
        Mission memory _mission = _getMission(_missionNum);
        return _calculateReward(_missionNum, _mission);
    }

    /// @notice Calculate reward for mission and return all tokens count that will transfer for user account
    /// @param _missionNum Existed mission number.
    /// @param _mission Mission which user join.
    /// @return Transferred on mission TLM and BNB tokens, reward in TLM and NFT that will be created.
    function _calculateReward(uint256 _missionNum, Mission memory _mission) private view returns(RewardInfo memory) {
        require(_mission.launchTime <= block.timestamp, "[E-89] - Can't calculate reward before mission launch.");

        UserInvest memory _userInvest = missionToUsersInvest[_missionNum][msg.sender];

        uint256 _userPower = _calculateUserPower(_mission, _userInvest);
        require(_userPower > 0, "[E-90] - You haven't rewards for this mission.");

        uint256 _rewardTLM = (_mission.reward).mul(getDecimal()).mul(_userPower).div(_mission.missionPower)
            .div(getDecimal());

        RewardInfo memory _rewardInfo = RewardInfo({
            investedTLM: _getJoinMissionPrice(_mission, _userInvest.ships),
            investedBNB: _userInvest.BNBAmount,
            rewardTLM: _rewardTLM,
            rewardNFTCount: _userInvest.ships > 5 ? 5 : _userInvest.ships
        });

        return _rewardInfo;
    }

    /// @notice Transfer all tokens from `_calculateReward()` to user account.
    /// @param _missionNum Existed mission number.
    /// @return True if transfer was success.
    function withdraw(uint256 _missionNum) external override returns(bool) {
        Mission memory _mission = _getMission(_missionNum);
        require((_mission.launchTime).add(_mission.duration) < block.timestamp, "[E-140] - Can't withdraw before mission end.");

        RewardInfo memory _rewardInfo = _calculateReward(_missionNum, _mission);

        missionToUsersInvest[_missionNum][msg.sender].ships = 0;
        missionToUsersInvest[_missionNum][msg.sender].BNBAmount = 0;

        // Claim reward
        TLMToken.transfer(msg.sender, (_rewardInfo.investedTLM).add(_rewardInfo.rewardTLM));
        msg.sender.transfer(_rewardInfo.investedBNB);

        // Mint NFT tokens
        IAlienWorldsNFT _NFTContract = IAlienWorldsNFT(_mission.nftInfo.contractAddress);
        for (uint256 i = 0; i < _rewardInfo.rewardNFTCount; i++) {
            _NFTContract.mint(msg.sender, _mission.nftInfo.tokenURI);
        }

        emit RewardWithdrawn(_missionNum, msg.sender, _rewardInfo.investedTLM, _rewardInfo.rewardTLM, _rewardInfo.investedBNB);

        return true;
    }

    /// @notice Return mission, include require.
    /// @param _missionNum Existed mission number.
    /// @return Mission structure.
    function _getMission(uint256 _missionNum) private view returns(Mission memory) {
        require(missionsCount > _missionNum, "[E-88] - Mission not exist.");
        return missions[_missionNum];
    }

    /// @notice Calculate mission price in TLM.
    /// @param _mission Mission structure.
    /// @param _spaceshipCount Count of spaceships.
    /// @return Price in TLM.
    function _getJoinMissionPrice(Mission memory _mission, uint256 _spaceshipCount) private pure returns(uint256) {
        return _spaceshipCount.mul(_mission.spaceshipCost);
    }

    /// @notice Calculate user power ny mission and invest.
    /// @param _mission Mission structure.
    /// @param _userInvest User invested info
    /// @return User power for mission.
    function _calculateUserPower(Mission memory _mission, UserInvest memory _userInvest) private pure returns(uint256) {
        uint256 _boostCounter = getDecimal();

        if (_mission.boostCounters.length > 0) {
            for (uint256 k = _mission.boostCounters.length - 1; k >= 0 && k < _mission.boostCounters.length; k--) {
                if (_userInvest.BNBAmount >= _mission.boostPrices[k]) {
                    _boostCounter = _mission.boostCounters[k];
                    break;
                }
            }
        }

        return (_userInvest.ships).mul(_boostCounter);
    }

    /// @notice Check boost order on mission create
    /// @param _mission Mission structure.
    function _checkBoostOrder(Mission memory _mission) private pure {
        require(_mission.boostCounters.length == _mission.boostPrices.length, "[E-194] - Boost length is not equal.");

        if (_mission.boostCounters.length <= 1) return;

        for (uint256 k = 0; k < _mission.boostCounters.length - 1; k++) {
            require(_mission.boostCounters[k] < _mission.boostCounters[k + 1], "[E-199] - Wrong boost counter order.");
            require(_mission.boostPrices[k] < _mission.boostPrices[k + 1], "[E-200] - Wrong boost prices order.");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

function getDecimal() pure returns (uint256) {
  return 10 ** 27;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IAlienWorldsNFT {
    /// @notice Mints new token for `owner` and set `tokenURI`.
    function mint(address owner, string memory tokenURI) external returns(uint256);

    function setBaseURI(string memory baseURI_) external;

    /// @notice Mints a batch of new token(s) for `recipient` and set `tokenURI`.
    function mintBatch(address recipient, string memory tokenURI, uint8 tokensToMint) external;

    /// @notice set or update the batchMint limit for NFTs
    function setMintBatchLimit(uint8 _newMintBatchLimit) external;

    /// @notice get current batchMint limit for NFTs
    function getMintBatchLimit() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/// @title SpaceshipStaking interface.
interface ISpaceshipStaking {
    /// Emitted when new mission created with `id` and `name`.
    event MissionCreated(uint256 indexed id, string name);

    /// Emitted when `player` joined to mission by `missionId`.
    event MissionJoined(uint256 indexed missionId, address indexed player, uint256 spaceshipCount);

    /// Emitted when `player` withdraw reward from mission by `missionId`.
    event RewardWithdrawn(uint256 indexed missionId, address indexed player, uint256 investedTLM, uint256 rewardTLM, uint256 investedBNB);

    /// @dev Contain information about ERC721 contract for each mission.
    struct NFTInfo {
        address contractAddress;
        string tokenURI;
    }

    /// @dev Contain information about mission.
    struct Mission {
        uint64 boardingTime;
        uint64 launchTime;
        uint64 duration;
        uint64 missionType;
        uint256 reward;
        uint256 spaceshipCost;
        uint256 missionPower;
        string description;
        string name;
        uint256[] boostCounters;
        uint256[] boostPrices;
        NFTInfo nftInfo;
    }

    /// @dev Contain information about user reward for mission.
    struct RewardInfo {
        uint256 investedTLM;
        uint256 investedBNB;
        uint256 rewardTLM;
        uint256 rewardNFTCount;
    }

    /// @notice Create new mission.
    /// @dev See test for Mission structure example. Only for owner.
    /// @param _newMission New mission structure.
    /// @return True if creation success.
    function createMission(Mission memory _newMission) external returns(bool);

    /// @notice Allow user join to created mission.
    /// @param _missionNum Existed mission number.
    /// @param _spaceshipCount Spaceship count that user send on mission.
    /// @return True if join success.
    function joinToMission(uint256 _missionNum, uint256 _spaceshipCount) external payable returns(bool);

    /// @notice See `_calculateReward()`.
    /// @param _missionNum Existed mission number.
    /// @return All info about reward for mission.
    function calculateReward(uint256 _missionNum) external view returns(RewardInfo memory);

    /// @notice Transfer all tokens from `_calculateReward()` to user account.
    /// @param _missionNum Existed mission number.
    /// @return True if transfer was success.
    function withdraw(uint256 _missionNum) external returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}