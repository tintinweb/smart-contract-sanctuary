/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface ILegacyVault {
    function earn() external;
}

interface ISweetVault {
    function earn(uint, uint, uint, uint) external;

    function getExpectedOutputs() external view returns (uint, uint, uint, uint);

    function totalStake() external view returns (uint);
}

interface KeeperCompatibleInterface {
    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (
        bool upkeepNeeded,
        bytes memory performData
    );

    function performUpkeep(
        bytes calldata performData
    ) external;
}

contract SweetKeeper is Ownable, KeeperCompatibleInterface {
    using SafeMath for uint;

    struct VaultInfo {
        uint lastCompound;
        bool enabled;
    }

    struct CompoundInfo {
        address[] legacyVaults;
        address[] sweetVaults;
        uint[] minPlatformOutputs;
        uint[] minKeeperOutputs;
        uint[] minBurnOutputs;
        uint[] minPacocaOutputs;
    }

    address[] public legacyVaults;
    address[] public sweetVaults;

    mapping(address => VaultInfo) public vaultInfos;

    address public keeper;
    address public moderator;

    uint public maxDelay = 1 days;
    uint public minKeeperFee = 5500000000000000;
    uint public slippageFactor = 9600; // 4%
    uint16 public maxVaults = 3;

    constructor(
        address _keeper,
        address _moderator,
        address _owner
    ) public {
        keeper = _keeper;
        moderator = _moderator;

        transferOwnership(_owner);
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper, "SweetKeeper::onlyKeeper: Not keeper");
        _;
    }

    modifier onlyModerator() {
        require(msg.sender == moderator, "SweetKeeper::onlyModerator: Not moderator");
        _;
    }

    function checkUpkeep(
        bytes calldata
    ) external override view returns (
        bool upkeepNeeded,
        bytes memory performData
    ) {
        CompoundInfo memory tempCompoundInfo = CompoundInfo(
            new address[](legacyVaults.length),
            new address[](sweetVaults.length),
            new uint[](sweetVaults.length),
            new uint[](sweetVaults.length),
            new uint[](sweetVaults.length),
            new uint[](sweetVaults.length)
        );

        uint16 legacyVaultsLength = 0;
        uint16 sweetVaultsLength = 0;

        for (uint16 index = 0; index < sweetVaults.length; ++index) {
            if (maxVaults == sweetVaultsLength) {
                continue;
            }

            address vault = sweetVaults[index];
            VaultInfo memory vaultInfo = vaultInfos[vault];

            if (!vaultInfo.enabled || ISweetVault(vault).totalStake() == 0) {
                continue;
            }

            (uint platformOutput, uint keeperOutput, uint burnOutput, uint pacocaOutput) = _getExpectedOutputs(vault);

            if (
                block.timestamp >= vaultInfo.lastCompound + maxDelay
                || keeperOutput >= minKeeperFee
            ) {
                tempCompoundInfo.sweetVaults[sweetVaultsLength] = vault;

                tempCompoundInfo.minPlatformOutputs[sweetVaultsLength] = platformOutput.mul(slippageFactor).div(10000);
                tempCompoundInfo.minKeeperOutputs[sweetVaultsLength] = keeperOutput.mul(slippageFactor).div(10000);
                tempCompoundInfo.minBurnOutputs[sweetVaultsLength] = burnOutput.mul(slippageFactor).div(10000);
                tempCompoundInfo.minPacocaOutputs[sweetVaultsLength] = pacocaOutput.mul(slippageFactor).div(10000);

                sweetVaultsLength = sweetVaultsLength + 1;
            }
        }

        for (uint16 index = 0; index < legacyVaults.length; ++index) {
            if (maxVaults == (sweetVaultsLength + legacyVaultsLength)) {
                continue;
            }

            address vault = legacyVaults[index];
            VaultInfo memory vaultInfo = vaultInfos[vault];

            if (!vaultInfo.enabled) {
                continue;
            }

            if (block.timestamp >= vaultInfo.lastCompound + maxDelay) {
                tempCompoundInfo.legacyVaults[legacyVaultsLength] = vault;

                legacyVaultsLength = legacyVaultsLength + 1;
            }
        }

        if (legacyVaultsLength > 0 || sweetVaultsLength > 0) {
            CompoundInfo memory compoundInfo = CompoundInfo(
                new address[](legacyVaultsLength),
                new address[](sweetVaultsLength),
                new uint[](sweetVaultsLength),
                new uint[](sweetVaultsLength),
                new uint[](sweetVaultsLength),
                new uint[](sweetVaultsLength)
            );

            for (uint16 index = 0; index < legacyVaultsLength; ++index) {
                compoundInfo.legacyVaults[index] = tempCompoundInfo.legacyVaults[index];
            }

            for (uint16 index = 0; index < sweetVaultsLength; ++index) {
                compoundInfo.sweetVaults[index] = tempCompoundInfo.sweetVaults[index];
                compoundInfo.minPlatformOutputs[index] = tempCompoundInfo.minPlatformOutputs[index];
                compoundInfo.minKeeperOutputs[index] = tempCompoundInfo.minKeeperOutputs[index];
                compoundInfo.minBurnOutputs[index] = tempCompoundInfo.minBurnOutputs[index];
                compoundInfo.minPacocaOutputs[index] = tempCompoundInfo.minPacocaOutputs[index];
            }

            return (true, abi.encode(
                compoundInfo.legacyVaults,
                compoundInfo.sweetVaults,
                compoundInfo.minPlatformOutputs,
                compoundInfo.minKeeperOutputs,
                compoundInfo.minBurnOutputs,
                compoundInfo.minPacocaOutputs
            ));
        }

        return (false, "");
    }

    function performUpkeep(
        bytes calldata performData
    ) external override onlyKeeper {
        (
        address[] memory _legacyVaults,
        address[] memory _sweetVaults,
        uint[] memory _minPlatformOutputs,
        uint[] memory _minKeeperOutputs,
        uint[] memory _minBurnOutputs,
        uint[] memory _minPacocaOutputs
        ) = abi.decode(
            performData,
            (address[], address[], uint[], uint[], uint[], uint[])
        );

        _earn(
            _legacyVaults,
            _sweetVaults,
            _minPlatformOutputs,
            _minKeeperOutputs,
            _minBurnOutputs,
            _minPacocaOutputs
        );
    }

    function _earn(
        address[] memory _legacyVaults,
        address[] memory _sweetVaults,
        uint[] memory _minPlatformOutputs,
        uint[] memory _minKeeperOutputs,
        uint[] memory _minBurnOutputs,
        uint[] memory _minPacocaOutputs
    ) private {
        uint legacyLength = _legacyVaults.length;

        for (uint index = 0; index < legacyLength; ++index) {
            address vault = _legacyVaults[index];

            ILegacyVault(vault).earn();

            vaultInfos[vault].lastCompound = block.timestamp;
        }

        uint sweetLength = _sweetVaults.length;

        for (uint index = 0; index < sweetLength; ++index) {
            address vault = _sweetVaults[index];

            ISweetVault(vault).earn(
                _minPlatformOutputs[index],
                _minKeeperOutputs[index],
                _minBurnOutputs[index],
                _minPacocaOutputs[index]
            );

            vaultInfos[vault].lastCompound = block.timestamp;
        }
    }

    function _getExpectedOutputs(
        address _vault
    ) private view returns (
        uint, uint, uint, uint
    ) {
        try ISweetVault(_vault).getExpectedOutputs() returns (
            uint platformOutput,
            uint keeperOutput,
            uint burnOutput,
            uint pacocaOutput
        ) {
            return (platformOutput, keeperOutput, burnOutput, pacocaOutput);
        }
        catch (bytes memory) {
        }

        return (0, 0, 0, 0);
    }

    function legacyVaultsLength() external view returns (uint) {
        return legacyVaults.length;
    }

    function sweetVaultsLength() external view returns (uint) {
        return sweetVaults.length;
    }

    function addVault(address _vault, bool _legacy) public onlyModerator {
        require(
            vaultInfos[_vault].lastCompound == 0,
            "SweetKeeper::addVault: Vault already exists"
        );

        vaultInfos[_vault] = VaultInfo(
            block.timestamp - 6 hours,
            true
        );

        if (_legacy) {
            legacyVaults.push(_vault);
        }
        else {
            sweetVaults.push(_vault);
        }
    }

    function enableVault(address _vault) external onlyModerator {
        vaultInfos[_vault].enabled = true;
    }

    function disableVault(address _vault) external onlyModerator {
        vaultInfos[_vault].enabled = false;
    }

    function setKeeper(address _keeper) public onlyOwner {
        keeper = _keeper;
    }

    function setModerator(address _moderator) public onlyOwner {
        moderator = _moderator;
    }

    function setMaxDelay(uint _maxDelay) public onlyOwner {
        maxDelay = _maxDelay;
    }

    function setMinKeeperFee(uint _minKeeperFee) public onlyOwner {
        minKeeperFee = _minKeeperFee;
    }

    function setSlippageFactor(uint _slippageFactor) public onlyOwner {
        slippageFactor = _slippageFactor;
    }

    function setMaxVaults(uint16 _maxVaults) public onlyOwner {
        maxVaults = _maxVaults;
    }
}