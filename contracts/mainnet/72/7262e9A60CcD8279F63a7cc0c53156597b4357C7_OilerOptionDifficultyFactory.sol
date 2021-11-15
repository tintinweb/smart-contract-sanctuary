// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import {OilerOptionDifficulty} from "./OilerOptionDifficulty.sol";
import {OilerOptionBaseFactory} from "./OilerOptionBaseFactory.sol";

contract OilerOptionDifficultyFactory is OilerOptionBaseFactory {
    constructor(
        address _factoryOwner,
        address _registryAddress,
        address _bRouter,
        address _optionLogicImplementation
    ) OilerOptionBaseFactory(_factoryOwner, _registryAddress, _bRouter, _optionLogicImplementation) {}

    function createOption(
        uint256 _strikePrice,
        uint256 _expiryTS,
        bool _put,
        address _collateral,
        uint256 _collateralToPushIntoAmount,
        uint256 _optionsToPushIntoPool
    ) external override onlyOwner returns (address optionAddress) {
        address option = _createOption();
        OilerOptionDifficulty(option).init(_strikePrice, _expiryTS, _put, _collateral);
        _pullInitialLiquidityCollateral(_collateral, _collateralToPushIntoAmount);
        _initializeOptionsPool(
            OptionInitialLiquidity(_collateral, _collateralToPushIntoAmount, option, _optionsToPushIntoPool)
        );
        registry.registerOption(option, "H");
        emit Created(option, "H");
        return option;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import {HeaderRLP} from "./lib/HeaderRLP.sol";
import {OilerOption} from "./OilerOptionBase.sol";

contract OilerOptionDifficulty is OilerOption {
    string private constant _optionType = "H";
    string private constant _name = "OilerOptionHashrate";

    constructor() OilerOption() {}

    function init(
        uint256 _strikePrice,
        uint256 _expiryTS,
        bool _put,
        address _collateralAddress
    ) external {
        super._init(_strikePrice, _expiryTS, _put, _collateralAddress);
    }

    function exercise(bytes calldata _rlp) external returns (bool) {
        require(isActive(), "OilerOptionDifficulty.exercise: not active, cannot exercise");

        uint256 blockNumber = HeaderRLP.checkBlockHash(_rlp);

        require(
            blockNumber >= startBlock,
            "OilerOptionDifficulty.exercise: can only be exercised with a block after option creation"
        );
        uint256 difficulty = HeaderRLP.getDifficulty(_rlp);

        _exercise(difficulty);
        return true;
    }

    function optionType() external pure override returns (string memory) {
        return _optionType;
    }

    function name() public pure override returns (string memory) {
        return _name;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import {IBRouter} from "./interfaces/IBRouter.sol";
import {IOilerOptionBase} from "./interfaces/IOilerOptionBase.sol";
import {IBPool} from "./interfaces/IBPool.sol";

import {OilerRegistry} from "./OilerRegistry.sol";

import {ProxyFactory} from "./proxies/ProxyFactory.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OilerOptionBaseFactory is Ownable, ProxyFactory {
    event Created(address _optionAddress, bytes32 _symbol);

    struct OptionInitialLiquidity {
        address collateral;
        uint256 collateralAmount;
        address option;
        uint256 optionsAmount;
    }
    /**
     * @dev Stores address of the registry.
     */
    OilerRegistry public immutable registry;

    /**
     * @dev Address on which proxy logic is deployed.
     */
    address public optionLogicImplementation;

    /**
     * @dev Balancer pools bRouter address.
     */
    IBRouter public immutable bRouter;

    /**
     * @param _factoryOwner - Factory owner.
     * @param _registryAddress - Oiler options registry address.
     * @param _optionLogicImplementation - Proxy implementation address.
     */
    constructor(
        address _factoryOwner,
        address _registryAddress,
        address _bRouter,
        address _optionLogicImplementation
    ) Ownable() {
        Ownable.transferOwnership(_factoryOwner);
        bRouter = IBRouter(_bRouter);
        registry = OilerRegistry(_registryAddress);
        optionLogicImplementation = _optionLogicImplementation;
    }

    function createOption(
        uint256 _strikePrice,
        uint256 _expiryTS,
        bool _put,
        address _collateral,
        uint256 _collateralToPushIntoAmount,
        uint256 _optionsToPushIntoPool
    ) external virtual returns (address optionAddress);

    /**
     * @dev Allows factory owner to remove liquidity from pool.
     * @param _option - option liquidity pool to be withdrawn..
     */
    function removeOptionsPoolLiquidity(address _option) external onlyOwner {
        _removeOptionsPoolLiquidity(_option);
    }

    function isClone(address _query) external view returns (bool) {
        return _isClone(optionLogicImplementation, _query);
    }

    function _createOption() internal returns (address) {
        return _createClone(optionLogicImplementation);
    }

    /**
     * @dev Transfers collateral from msg.sender to contract.
     * @param _collateral - option collateral.
     * @param _collateralAmount - collateral amount to be transfered.
     */
    function _pullInitialLiquidityCollateral(address _collateral, uint256 _collateralAmount) internal {
        require(
            IERC20(_collateral).transferFrom(msg.sender, address(this), _collateralAmount),
            "OilerOptionBaseFactory: ERC20 transfer failed"
        );
    }

    /**
     * @dev Initialized a new balancer liquidity pool by providing to it option token and collateral.
     * @notice creates a new liquidity pool.
     * @notice during initialization some options are written and provided to the liquidity pool.
     * @notice pulls collateral.
     * @param _initialLiquidity - See {OptionInitialLiquidity}.
     */
    function _initializeOptionsPool(OptionInitialLiquidity memory _initialLiquidity) internal {
        // Approve option to pull collateral while writing option.
        require(
            IERC20(_initialLiquidity.collateral).approve(_initialLiquidity.option, _initialLiquidity.optionsAmount),
            "OilerOptionBaseFactory: ERC20 approval failed, option"
        );

        // Approve bRouter to pull collateral.
        require(
            IERC20(_initialLiquidity.collateral).approve(address(bRouter), _initialLiquidity.collateralAmount),
            "OilerOptionBaseFactory: ERC20 approval failed, bRouter"
        );

        // Approve bRouter to pull written options.
        require(
            IERC20(_initialLiquidity.option).approve(address(bRouter), _initialLiquidity.optionsAmount),
            "OilerOptionBaseFactory: ERC20 approval failed, bRouter"
        );

        // Pull liquidity required to write an option.
        _pullInitialLiquidityCollateral(
            address(IOilerOptionBase(_initialLiquidity.option).collateralInstance()),
            _initialLiquidity.optionsAmount
        );

        // Write the option.
        IOilerOptionBase(_initialLiquidity.option).write(_initialLiquidity.optionsAmount);

        // Add liquidity.
        bRouter.addLiquidity(
            _initialLiquidity.option,
            _initialLiquidity.collateral,
            _initialLiquidity.optionsAmount,
            _initialLiquidity.collateralAmount
        );
    }

    /**
     * @dev Removes liquidity provided while option creation.
     * @notice withdraws remaining in pool options and collateral.
     * @notice if option is still active reverts.
     * @notice once liquidity is removed the pool becomes unusable.
     * @param _option - option liquidity pool to be withdrawn.
     */
    function _removeOptionsPoolLiquidity(address _option) internal {
        require(
            !IOilerOptionBase(_option).isActive(),
            "OilerOptionBaseFactory.removeOptionsPoolLiquidity: option still active"
        );
        address optionCollateral = address(IOilerOptionBase(_option).collateralInstance());

        IBPool pool = bRouter.getPoolByTokens(_option, optionCollateral);

        require(
            pool.approve(address(bRouter), pool.balanceOf(address(this))),
            "OilerOptionBaseFactory.removeOptionsPoolLiquidity: approval failed"
        );

        uint256[] memory amounts = bRouter.removeLiquidity(_option, optionCollateral, pool.balanceOf(address(this)));

        require(IERC20(_option).transfer(msg.sender, amounts[0]), "ERR_ERC20_FAILED");
        require(IERC20(optionCollateral).transfer(msg.sender, amounts[1]), "ERR_ERC20_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

// This library extracts data from Block header encoded in RLP format.
// It is not a complete implementation, but optimized for specific cases - thus many hardcoded values.
// Here's the current RLP structure and the values we're looking for:
//
// idx  Element                 element length with 1 byte storing its length
// ==========================================================================
// Static elements (always same size):
//
// 0    RLP length              1+2
// 1    parentHash              1+32
// 2    ommersHash              1+32
// 3    beneficiary             1+20
// 4    stateRoot               1+32
// 5    TransactionRoot         1+32
// 6    receiptsRoot            1+32
//      logsBloom length        1+2
// 7    logsBloom               256
//                              =========
//  Total static elements size: 448 bytes
//
// Dynamic elements (need to read length) start at position 448
// and each one is preceeded with 1 byte length (if element is >= 128)
// or if element is < 128 - then length byte is skipped and it is just the 1-byte element:
//
// 8	difficulty  - starts at pos 448
// 9	number      - blockNumber
// 10	gasLimit
// 11	gasUsed
// 12	timestamp
// 13	extraData
// 14	mixHash
// 15	nonce

// SAFEMATH DISCLAIMER:
// We and don't use SafeMath here intentionally, because input values are bytes in a byte-array, thus limited to 255
library HeaderRLP {
    function checkBlockHash(bytes calldata rlp) external view returns (uint256) {
        uint256 rlpBlockNumber = getBlockNumber(rlp);

        require(
            blockhash(rlpBlockNumber) == keccak256(rlp), // blockhash() costs 20 now but it may cost 5000 in the future
            "HeaderRLP.checkBlockHash: Block hashes don't match"
        );
        return rlpBlockNumber;
    }

    function nextElementJump(uint8 prefix) public pure returns (uint8) {
        // RLP has much more options for element lenghts
        // But we are safe between 56 bytes and 2MB
        if (prefix <= 128) {
            return 1;
        } else if (prefix <= 183) {
            return prefix - 128 + 1;
        }
        revert("HeaderRLP.nextElementJump: Given element length not implemented");
    }

    // no loop saves ~300 gas
    function getBlockNumberPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    // no loop saves ~300 gas
    function getGasLimitPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        //3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    // no loop saves ~300 gas
    function getTimestampPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        //3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));
        //4th element - gas used
        pos += nextElementJump(uint8(rlp[pos]));
        //timestamp - jackpot!
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    function getBaseFeePositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        //jumping straight to the 1st dynamic element at pos 448 - difficulty
        uint256 pos = 448;

        // 2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        // 3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));
        // 4th element - gas used
        pos += nextElementJump(uint8(rlp[pos]));
        // timestamp
        pos += nextElementJump(uint8(rlp[pos]));
        // extradata
        pos += nextElementJump(uint8(rlp[pos]));
        // mixhash
        pos += nextElementJump(uint8(rlp[pos]));
        // nonce
        pos += nextElementJump(uint8(rlp[pos]));
        // nonce
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    function extractFromRLP(bytes calldata rlp, uint256 elementPosition) public pure returns (uint256 element) {
        // RLP hint: If the byte is less than 128 - than this byte IS the value needed - just return it.
        if (uint8(rlp[elementPosition]) < 128) {
            return uint256(uint8(rlp[elementPosition]));
        }

        // RLP hint: Otherwise - this byte stores the length of the element needed (in bytes).
        uint8 elementSize = uint8(rlp[elementPosition]) - 128;

        // ABI Encoding hint for dynamic bytes element:
        //  0x00-0x04 (4 bytes): Function signature
        //  0x05-0x23 (32 bytes uint): Offset to raw data of RLP[]
        //  0x24-0x43 (32 bytes uint): Length of RLP's raw data (in bytes)
        //  0x44-.... The RLP raw data starts here
        //  0x44 + elementPosition: 1 byte stores a length of our element
        //  0x44 + elementPosition + 1: Raw data of the element

        // Copies the element from calldata to uint256 stored in memory
        assembly {
            calldatacopy(
                add(mload(0x40), sub(32, elementSize)), // Copy to: Memory 0x40 (free memory pointer) + 32bytes (uint256 size) - length of our element (in bytes)
                add(0x44, add(elementPosition, 1)), // Copy from: Calldata 0x44 (RLP raw data offset) + elementPosition + 1 byte for the size of element
                elementSize
            )
            element := mload(mload(0x40)) // Load the 32 bytes (uint256) stored at memory 0x40 pointer - into return value
        }
        return element;
    }

    function getBlockNumber(bytes calldata rlp) public pure returns (uint256 bn) {
        return extractFromRLP(rlp, getBlockNumberPositionNoLoop(rlp));
    }

    function getTimestamp(bytes calldata rlp) external pure returns (uint256 ts) {
        return extractFromRLP(rlp, getTimestampPositionNoLoop(rlp));
    }

    function getDifficulty(bytes calldata rlp) external pure returns (uint256 diff) {
        return extractFromRLP(rlp, 448);
    }

    function getGasLimit(bytes calldata rlp) external pure returns (uint256 gasLimit) {
        return extractFromRLP(rlp, getGasLimitPositionNoLoop(rlp));
    }

    function getBaseFee(bytes calldata rlp) external pure returns (uint256 baseFee) {
        return extractFromRLP(rlp, getBaseFeePositionNoLoop(rlp));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./lib/GenSymbol.sol";

import "./interfaces/IOilerCollateral.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/drafts/ERC20PermitUpgradeable.sol";

abstract contract OilerOption is ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PermitUpgradeable {
    using SafeMath for uint256;

    event Created(address indexed _optionAddress, string _symbol);
    event Exercised(uint256 _value);

    uint256 private constant MAX_UINT256 = type(uint256).max;

    // Added compatibility function below:
    function holderBalances(address holder_) public view returns (uint256) {
        return balanceOf(holder_);
    }

    mapping(address => uint256) public writerBalances;
    mapping(address => mapping(address => uint256)) public allowed;

    // OilerOption variables
    uint256 public startTS;
    uint256 public startBlock;
    uint256 public strikePrice;
    uint256 public expiryTS;
    bool public put; // put if true, call if false
    bool public exercised = false;

    IERC20 public collateralInstance;

    // Writes an option, locking the collateral
    function write(uint256 _amount) external {
        _write(_amount, msg.sender);
    }

    function write(uint256 _amount, address _onBehalfOf) external {
        _write(_amount, _onBehalfOf);
    }

    // Check if option's Expiration date has already passed
    function isAfterExpirationDate() public view returns (bool expired) {
        return (expiryTS <= block.timestamp);
    }

    function withdraw(uint256 _amount) external {
        if (isActive()) {
            // If the option is still Active - one can only release options that he wrote and still holds
            writerBalances[msg.sender] = writerBalances[msg.sender].sub(
                _amount,
                "Option.withdraw: Release amount exceeds options written"
            );
            _burn(msg.sender, _amount);
        } else {
            if (hasBeenExercised()) {
                // If the option was exercised - only holders can withdraw the collateral
                _burn(msg.sender, _amount);
            } else {
                // If the option wasn't exercised, but it's not active - this means it expired - and only writers can withdraw the collateral
                writerBalances[msg.sender] = writerBalances[msg.sender].sub(
                    _amount,
                    "Option.withdraw: Withdraw amount exceeds options written"
                );
            }
        }
        // If none of the above failed - then we succesfully withdrew the amount and we're good to burn tokens and release the collateral
        bool success = collateralInstance.transfer(msg.sender, _amount);
        require(success, "Option.withdraw: collateral transfer failed");
    }

    // Get withdrawable collateral
    function getWithdrawable(address _owner) external view returns (uint256 amount) {
        if (isActive()) {
            // If the option is still Active - one can only withdraw options that he wrote and still holds
            return min(holderBalances(_owner), writerBalances[_owner]);
        } else {
            if (hasBeenExercised()) {
                // If the option was exercised - only holders can withdraw the collateral
                return holderBalances(_owner);
            } else {
                // If the option wasn't exercised, but it's not active - this means it expired - and only writers can withdraw the collateral
                return writerBalances[_owner];
            }
        }
    }

    // Get amount of collateral locked in options
    function getLocked(address _address) external view returns (uint256 amount) {
        if (isActive()) {
            return writerBalances[_address];
        } else {
            return 0;
        }
    }

    function name() public view virtual override returns (string memory) {}

    // Option is Active (can still be written or exercised) - if it hasn't expired nor hasn't been exercised.
    // Option is not Active (and the collateral can be withdrawn) - if it has expired or has been exercised.
    function isActive() public view returns (bool active) {
        return (!isAfterExpirationDate() && !hasBeenExercised());
    }

    // Option is Expired if its Expiration Date has already passed and it wasn't exercised
    function hasExpired() public view returns (bool) {
        return isAfterExpirationDate() && !hasBeenExercised();
    }

    // Additional getter to make it more readable
    function hasBeenExercised() public view returns (bool) {
        return exercised;
    }

    function optionType() external view virtual returns (string memory) {}

    function _init(
        uint256 _strikePrice,
        uint256 _expiryTS,
        bool _put,
        address _collateralAddress
    ) internal initializer {
        startTS = block.timestamp;
        require(_expiryTS > startTS, "OilerOptionBase.init: expiry TS must be above start TS");
        expiryTS = _expiryTS;
        startBlock = block.number;
        strikePrice = _strikePrice;
        put = _put;
        string memory _symbol = GenSymbol.genOptionSymbol(_expiryTS, this.optionType(), _put, _strikePrice);

        __Context_init_unchained();
        __ERC20_init_unchained(this.name(), _symbol);
        __ERC20Burnable_init_unchained();
        __EIP712_init_unchained(this.name(), "1");
        __ERC20Permit_init_unchained(this.name());

        collateralInstance = IOilerCollateral(_collateralAddress);
        _setupDecimals(IOilerCollateral(_collateralAddress).decimals());
        emit Created(address(this), this.symbol());
    }

    function _write(uint256 _amount, address _onBehalfOf) internal {
        require(isActive(), "Option.write: not active, cannot mint");
        _mint(_onBehalfOf, _amount);
        writerBalances[_onBehalfOf] = writerBalances[_onBehalfOf].add(_amount);
        bool success = collateralInstance.transferFrom(msg.sender, address(this), _amount);
        require(success, "Option.write: collateral transfer failed");
    }

    function _exercise(uint256 price) internal {
        // (from vanilla option lingo) if it is a PUT then I can sell it at a higher (strike) price than the current price - I have a right to PUT it on the market
        // (from vanilla option lingo) if it is a CALL then I can buy it at a lower (strike) price than the current price - I have a right to CALL it from the market
        if ((put && strikePrice >= price) || (!put && strikePrice <= price)) {
            exercised = true;
            emit Exercised(price);
        } else {
            revert("Option.exercise: exercise conditions aren't met");
        }
    }

    /// @dev Returns the smallest of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {DateTime} from "./DateTime.sol";

// SAFEMATH DISCLAIMER:
// We and don't use SafeMath here intentionally, because input values are based on chars arithmetics
// and the results are used solely for display purposes (generating a token SYMBOL).
// Moreover - input data is provided only by contract owners, as creation of tokens is limited to owner only.
library GenSymbol {
    function monthToHex(uint8 m) public pure returns (bytes1) {
        if (m > 0 && m < 10) {
            return bytes1(uint8(bytes1("0")) + m);
        } else if (m >= 10 && m < 13) {
            return bytes1(uint8(bytes1("A")) + (m - 10));
        }
        revert("Invalid month");
    }

    function tsToDate(uint256 _ts) public pure returns (string memory) {
        bytes memory date = new bytes(4);

        uint256 year = DateTime.getYear(_ts);

        require(year >= 2020, "Year cannot be before 2020 as it is coded only by one digit");
        require(year < 2030, "Year cannot be after 2029 as it is coded only by one digit");

        date[0] = bytes1(
            uint8(bytes1("0")) + uint8(year - 2020) // 2020 is coded as "0"
        );

        date[1] = monthToHex(DateTime.getMonth(_ts)); // October = 10 is coded by "A"

        uint8 day = DateTime.getDay(_ts); // Day is just coded as a day of month starting from 1
        require(day > 0 && day <= 31, "Invalid day");

        date[2] = bytes1(uint8(bytes1("0")) + (day / 10));
        date[3] = bytes1(uint8(bytes1("0")) + (day % 10));

        return string(date);
    }

    function RKMconvert(uint256 _num) public pure returns (bytes memory) {
        bytes memory map = "0000KKKMMMGGGTTTPPPEEEZZZYYY";
        uint8 len;

        uint256 i = _num;
        while (i != 0) {
            // Calculate the length of the input number
            len++;
            i /= 10;
        }

        bytes1 prefix = map[len]; // Get the prefix code letter

        uint8 prefixPos = len > 3 ? ((len - 1) % 3) + 1 : 0; // Position of prefix (or 0 if the number is 3 digits or less)

        // Get the leftmost 4 digits from input number or just take the number as is if its already 4 digits or less
        uint256 firstFour = len > 4 ? _num / 10**(len - 4) : _num;

        bytes memory bStr = "00000";
        // We start from index 4 ^ of zero-string and go left
        uint8 index = 4;

        while (firstFour != 0) {
            // If index is on prefix position - insert a prefix and decrease index
            if (index == prefixPos) bStr[index--] = prefix;
            bStr[index--] = bytes1(uint8(48 + (firstFour % 10)));
            firstFour /= 10;
        }
        return bStr;
    }

    function uint2str(uint256 _num) public pure returns (bytes memory) {
        if (_num > 99999) return RKMconvert(_num);

        if (_num == 0) {
            return "00000";
        }
        uint256 j = _num;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bStr = "00000";
        uint256 k = 4;
        while (_num != 0) {
            bStr[k--] = bytes1(uint8(48 + (_num % 10)));
            _num /= 10;
        }
        return bStr;
    }

    function genOptionSymbol(
        uint256 _ts,
        string memory _type,
        bool put,
        uint256 _strikePrice
    ) external pure returns (string memory) {
        string memory putCall;
        putCall = put ? "P" : "C";
        return string(abi.encodePacked(_type, tsToDate(_ts), putCall, uint2str(_strikePrice)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";

interface IOilerCollateral is IERC20, IERC20Permit {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/ContextUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.5 <0.8.0;

import "../token/ERC20/ERC20Upgradeable.sol";
import "./IERC20PermitUpgradeable.sol";
import "../cryptography/ECDSAUpgradeable.sol";
import "../utils/CountersUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping (address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal initializer {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal initializer {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// Stripped version of the following:
// https://github.com/pipermerriam/ethereum-datetime
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

// SAFEMATH DISCLAIMER:
// We and don't use SafeMath here intentionally, because all of the operations are basic arithmetics
// (we have introduced a limit of year 2100 to definitely fit into uint16, hoping Year2100-problem will not be our problem)
// and the results are used solely for display purposes (generating a token SYMBOL).
// Moreover - input data is provided only by contract owners, as creation of tokens is limited to owner only.
library DateTime {
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
    }

    uint256 constant DAY_IN_SECONDS = 86400; // leap second?
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTimestamp(uint256 timestamp) public pure returns (_DateTime memory dt) {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }
    }

    function getYear(uint256 timestamp) public pure returns (uint16) {
        require(timestamp < 4102444800, "Years after 2100 aren't supported for sanity and safety reasons");
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) external pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) external pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
library SafeMathUpgradeable {
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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../math/SafeMathUpgradeable.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library CountersUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IBPool} from "./IBPool.sol";

interface IBRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256 poolTokens);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 poolAmountIn
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function getPoolByTokens(address tokenA, address tokenB) external view returns (IBPool pool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";
import {IOilerCollateral} from "./IOilerCollateral.sol";

interface IOilerOptionBase is IERC20, IERC20Permit {
    function optionType() external view returns (string memory);

    function collateralInstance() external view returns (IOilerCollateral);

    function isActive() external view returns (bool active);

    function hasExpired() external view returns (bool);

    function hasBeenExercised() external view returns (bool);

    function put() external view returns (bool);

    function write(uint256 _amount) external;

    function write(uint256 _amount, address _onBehalfOf) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IBPool {
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function balanceOf(address whom) external view returns (uint256);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function finalize() external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function setSwapFee(uint256 swapFee) external;

    function setPublicSwap(bool publicSwap) external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function isBound(address token) external view returns (bool);

    function getBalance(address token) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function isPublicSwap() external view returns (bool);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function EXIT_FEE() external view returns (uint256);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);

    function getCurrentTokens() external view returns (address[] memory tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOilerOptionBaseFactory} from "./interfaces/IOilerOptionBaseFactory.sol";
import {IOilerOptionBase} from "./interfaces/IOilerOptionBase.sol";
import {IOilerOptionsRouter} from "./interfaces/IOilerOptionsRouter.sol";

contract OilerRegistry is Ownable {
    uint256 public constant PUT = 1;
    uint256 public constant CALL = 0;

    /**
     * @dev Active options store, once the option expires the mapping keys are replaced.
     * option type => option contract.
     */
    mapping(bytes32 => address[2]) public activeOptions;

    /**
     * @dev Archived options store.
     * Once an option expires and is replaced it's pushed to an array under it's type key.
     * option type => option contracts.
     */
    mapping(bytes32 => address[]) public archivedOptions;

    /**
     * @dev Stores supported types of options.
     */
    bytes32[] public optionTypes; // Array of all option types ever registered

    /**
     * @dev Indicates who's the factory of specific option types.
     * option type => factory.
     */
    mapping(bytes32 => address) public factories;

    IOilerOptionsRouter public optionsRouter;

    constructor(address _owner) Ownable() {
        Ownable.transferOwnership(_owner);
    }

    function registerOption(address _optionAddress, string memory _optionType) external {
        require(address(optionsRouter) != address(0), "OilerRegistry.registerOption: router not set");
        bytes32 optionTypeHash = keccak256(abi.encodePacked(_optionType));
        // Check if caller is factory registered for current option.
        require(factories[optionTypeHash] == msg.sender, "OilerRegistry.registerOption: not a factory."); // Ensure that contract under address is an option.
        require(
            IOilerOptionBaseFactory(msg.sender).isClone(_optionAddress),
            "OilerRegistry.registerOption: invalid option contract."
        );
        uint256 optionDirection = IOilerOptionBase(_optionAddress).put() ? PUT : CALL;
        // Ensure option is not being registered again.
        require(
            _optionAddress != activeOptions[optionTypeHash][optionDirection],
            "OilerRegistry.registerOption: option already registered"
        );
        // Ensure currently set option is expired.
        if (activeOptions[optionTypeHash][optionDirection] != address(0)) {
            require(
                !IOilerOptionBase(activeOptions[optionTypeHash][optionDirection]).isActive(),
                "OilerRegistry.registerOption: option still active"
            );
        }
        archivedOptions[optionTypeHash].push(activeOptions[optionTypeHash][optionDirection]);
        activeOptions[optionTypeHash][optionDirection] = _optionAddress;
        optionsRouter.setUnlimitedApprovals(IOilerOptionBase(_optionAddress));
    }

    function setOptionsTypeFactory(string memory _optionType, address _factory) external onlyOwner {
        bytes32 optionTypeHash = keccak256(abi.encodePacked(_optionType));
        require(_factory != address(0), "Cannot set factory to 0x0");
        require(factories[optionTypeHash] != address(0), "OptionType wasn't yet registered");
        if (_factory != address(uint256(-1))) {
            // Send -1 if you want to remove the factory and disable this optionType
            require(
                optionTypeHash ==
                    keccak256(
                        abi.encodePacked(
                            IOilerOptionBase(IOilerOptionBaseFactory(_factory).optionLogicImplementation()).optionType()
                        )
                    ),
                "The factory is for different optionType"
            );
        }
        factories[optionTypeHash] = _factory;
    }

    function registerFactory(address factory) external onlyOwner {
        bytes32 optionTypeHash = keccak256(
            abi.encodePacked(
                IOilerOptionBase(IOilerOptionBaseFactory(factory).optionLogicImplementation()).optionType()
            )
        );
        require(factories[optionTypeHash] == address(0), "The factory for this OptionType was already registered");
        factories[optionTypeHash] = factory;
        optionTypes.push(optionTypeHash);
    }

    function setOptionsRouter(IOilerOptionsRouter _optionsRouter) external onlyOwner {
        optionsRouter = _optionsRouter;
    }

    function getOptionTypesLength() external view returns (uint256) {
        return optionTypes.length;
    }

    function getOptionTypeAt(uint256 _index) external view returns (bytes32) {
        return optionTypes[_index];
    }

    function getOptionTypeFactory(string memory _optionType) external view returns (address) {
        return factories[keccak256(abi.encodePacked(_optionType))];
    }

    function getAllArchivedOptionsOfType(bytes32 _optionType) external view returns (address[] memory) {
        return archivedOptions[_optionType];
    }

    function getAllArchivedOptionsOfType(string memory _optionType) external view returns (address[] memory) {
        return archivedOptions[keccak256(abi.encodePacked(_optionType))];
    }

    function checkActive(string memory _optionType) public view returns (bool, bool) {
        bytes32 id = keccak256(abi.encodePacked(_optionType));
        return checkActive(id);
    }

    function checkActive(bytes32 _optionType) public view returns (bool, bool) {
        return (
            activeOptions[_optionType][CALL] != address(0)
                ? IOilerOptionBase(activeOptions[_optionType][CALL]).isActive()
                : false,
            activeOptions[_optionType][PUT] != address(0)
                ? IOilerOptionBase(activeOptions[_optionType][PUT]).isActive()
                : false
        );
    }

    function getActiveOptions(bytes32 _optionType) public view returns (address[2] memory result) {
        (bool isCallActive, bool isPutActive) = checkActive(_optionType);

        if (isCallActive) {
            result[0] = activeOptions[_optionType][0];
        }

        if (isPutActive) {
            result[1] = activeOptions[_optionType][1];
        }
    }

    function getActiveOptions(string memory _optionType) public view returns (address[2] memory result) {
        return getActiveOptions(keccak256(abi.encodePacked(_optionType)));
    }

    function getArchivedOptions(bytes32 _optionType) public view returns (address[] memory result) {
        (bool isCallActive, bool isPutActive) = checkActive(_optionType);

        uint256 extraLength = 0;
        if (!isCallActive) {
            extraLength++;
        }
        if (!isPutActive) {
            extraLength++;
        }

        uint256 archivedLength = getArchivedOptionsLength(_optionType);

        result = new address[](archivedLength + extraLength);

        for (uint256 i = 0; i < archivedLength; i++) {
            result[i] = archivedOptions[_optionType][i];
        }

        uint256 cursor;
        if (!isCallActive) {
            result[archivedLength + cursor++] = activeOptions[_optionType][0];
        }

        if (!isPutActive) {
            result[archivedLength + cursor++] = activeOptions[_optionType][1];
        }

        return result;
    }

    function getArchivedOptions(string memory _optionType) public view returns (address[] memory result) {
        return getArchivedOptions(keccak256(abi.encodePacked(_optionType)));
    }

    function getArchivedOptionsLength(string memory _optionType) public view returns (uint256) {
        return archivedOptions[keccak256(abi.encodePacked(_optionType))].length;
    }

    function getArchivedOptionsLength(bytes32 _optionType) public view returns (uint256) {
        return archivedOptions[_optionType].length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

// TODO rename CloneFactory.
contract ProxyFactory {
    function _createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function _isClone(address target, address query) internal view returns (bool result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(eq(mload(clone), mload(other)), eq(mload(add(clone, 0xd)), mload(add(other, 0xd))))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IOilerOptionBaseFactory {
    function optionLogicImplementation() external view returns (address);

    function isClone(address _query) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IOilerOptionBase.sol";
import "./IOilerRegistry.sol";
import "./IBRouter.sol";

interface IOilerOptionsRouter {
    // TODO add expiration?
    struct Permit {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function registry() external view returns (IOilerRegistry);

    function bRouter() external view returns (IBRouter);

    function setUnlimitedApprovals(IOilerOptionBase _option) external;

    function write(IOilerOptionBase _option, uint256 _amount) external;

    function write(
        IOilerOptionBase _option,
        uint256 _amount,
        Permit calldata _permit
    ) external;

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount
    ) external;

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount,
        Permit calldata _writePermit,
        Permit calldata _liquidityAddPermit
    ) external;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./IOilerOptionsRouter.sol";

interface IOilerRegistry {
    function PUT() external view returns (uint256);

    function CALL() external view returns (uint256);

    function activeOptions(bytes32 _type) external view returns (address[2] memory);

    function archivedOptions(bytes32 _type, uint256 _index) external view returns (address);

    function optionTypes(uint256 _index) external view returns (bytes32);

    function factories(bytes32 _optionType) external view returns (address);

    function optionsRouter() external view returns (IOilerOptionsRouter);

    function getOptionTypesLength() external view returns (uint256);

    function getOptionTypeAt(uint256 _index) external view returns (bytes32);

    function getArchivedOptionsLength(string memory _optionType) external view returns (uint256);

    function getArchivedOptionsLength(bytes32 _optionType) external view returns (uint256);

    function getOptionTypeFactory(string memory _optionType) external view returns (address);

    function getAllArchivedOptionsOfType(string memory _optionType) external view returns (address[] memory);

    function getAllArchivedOptionsOfType(bytes32 _optionType) external view returns (address[] memory);

    function registerFactory(address factory) external;

    function setOptionsTypeFactory(string memory _optionType, address _factory) external;

    function registerOption(address _optionAddress, string memory _optionType) external;

    function setOptionsRouter(IOilerOptionsRouter _optionsRouter) external;
}

