// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./interfaces/IInterestRateModel.sol";
import "./interfaces/IBSWrapperToken.sol";
import "./interfaces/IDebtToken.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title DataTypes
/// @author @samparsky
////////////////////////////////////////////////////////////////////////////////////////////

library DataTypes {
    struct BorrowAssetConfig {
        uint256 initialExchangeRateMantissa;
        uint256 reserveFactorMantissa;
        uint256 collateralFactor;
        IBSWrapperToken wrappedBorrowAsset;
        uint256 liquidationFee;
        IDebtToken debtToken;
    }

    function validBorrowAssetConfig(BorrowAssetConfig memory self, address _owner) internal view {
        require(self.initialExchangeRateMantissa > 0, "E");
        require(self.reserveFactorMantissa > 0, "F");
        require(self.collateralFactor > 0, "C");
        require(self.liquidationFee > 0, "L");
        require(address(self.wrappedBorrowAsset) != address(0), "B");
        require(address(self.debtToken) != address(0), "IB");
        require(self.wrappedBorrowAsset.owner() == _owner, "IW");
        require(self.debtToken.owner() == _owner, "IVW");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IPriceOracleAggregator.sol";
import "./interfaces/IInterestRateModel.sol";
import "./interfaces/IBSLendingPair.sol";
import "./interfaces/IBSWrapperToken.sol";
import "./interfaces/IDebtToken.sol";
import "./interfaces/IRewardDistributorManager.sol";
import "./interest/JumpRateModelV2.sol";
import "./token/IERC20Details.sol";
import "./DataTypes.sol";

contract LendingPairFactory is Pausable {
    using Clones for address;

    address public immutable owner;

    address public lendingPairImplementation;
    address public collateralWrapperImplementation;
    address public debtTokenImplementation;
    address public borrowAssetWrapperImplementation;
    address public rewardDistributionManager;

    address[] public allPairs;

    mapping (address => bool) public validInterestRateModels;

    event NewLendingPair(address pair, uint256 created);
    event LogicContractUpdated(address pairLogic);
    event NewInterestRateModel(address ir, uint256 timestamp);

    /// @notice modifier to allow only the owner to call a function
    modifier onlyOwner {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    constructor(
        address _owner,
        address _pairLogic,
        address _collateralWrapperLogic,
        address _debtTokenLogic,
        address _borrowAssetWrapperLogic,
        address _rewardDistributionManager
    ) {
        require(_owner != address(0), "inv_o");
        require(_pairLogic != address(0), "inv_l");
        require(_collateralWrapperLogic != address(0), "inv_c");
        require(_debtTokenLogic != address(0), "inv_d");
        require(_borrowAssetWrapperLogic != address(0), "inv_b");
        require(_rewardDistributionManager != address(0), "inv_r");

        owner = _owner;
        lendingPairImplementation = _pairLogic;
        collateralWrapperImplementation = _collateralWrapperLogic;
        debtTokenImplementation = _debtTokenLogic;
        borrowAssetWrapperImplementation = _borrowAssetWrapperLogic;
        rewardDistributionManager = _rewardDistributionManager;
    }

    /// @notice pause
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause
    function unpause() external onlyOwner {
        _unpause();
    }

    function updatePairImpl(address _newLogicContract) external onlyOwner {
        require(_newLogicContract != address(0), "INV_C");
        lendingPairImplementation = _newLogicContract;
        emit LogicContractUpdated(_newLogicContract);
    }

    function updateCollateralWrapperImpl(address _newLogicContract) external onlyOwner {
        require(_newLogicContract != address(0), "INV_C");
        collateralWrapperImplementation = _newLogicContract;
        emit LogicContractUpdated(_newLogicContract);
    }

    function updateDebtTokenImpl(address _newLogicContract) external onlyOwner {
        require(_newLogicContract != address(0), "INV_C");
        debtTokenImplementation = _newLogicContract;
        emit LogicContractUpdated(_newLogicContract);
    }

    function updateBorrowAssetWrapperImpl(address _newLogicContract) external onlyOwner {
        require(_newLogicContract != address(0), "INV_C");
        borrowAssetWrapperImplementation = _newLogicContract;
        emit LogicContractUpdated(_newLogicContract);
    }
    
    function updateRewardManager(address _newManager) external onlyOwner {
        require(_newManager != address(0), "INV_C");
        rewardDistributionManager = _newManager;
        emit LogicContractUpdated(_newManager);
    }

    struct NewLendingVaultIRLocalVars {
        uint256 baseRatePerYear;
        uint256 multiplierPerYear;
        uint256 jumpMultiplierPerYear;
        uint256 optimal;
        uint256 borrowRateMaxMantissa;
        uint256 blocksPerYear;
    }

    /// @dev create interest rate model
    function createIR(NewLendingVaultIRLocalVars calldata _interestRateVars, address _team)
        external
        onlyOwner
        returns (address ir)
    {
        require(address(_team) != address(0), "inv_t");

        ir = address(
            new JumpRateModelV2(
                _interestRateVars.baseRatePerYear,
                _interestRateVars.multiplierPerYear,
                _interestRateVars.jumpMultiplierPerYear,
                _interestRateVars.optimal,
                _team,
                _interestRateVars.borrowRateMaxMantissa,
                _interestRateVars.blocksPerYear
            )
        );

        validInterestRateModels[ir] = true;

        emit NewInterestRateModel(ir, block.timestamp);
    }
    
    /// @dev disable interest rate model
    function disableIR(address ir) external onlyOwner {
        require(validInterestRateModels[ir] == true, "IR_NOT_EXIST");
        validInterestRateModels[ir] = false;
    }
    
    struct BorrowLocalVars {
        IERC20 borrowAsset;
        uint256 initialExchangeRateMantissa;
        uint256 reserveFactorMantissa;
        uint256 collateralFactor;
        uint256 liquidationFee;
        IInterestRateModel interestRateModel;
    }

    struct WrappedAssetLocalVars {
        IBSWrapperToken wrappedBorrowAsset;
        IBSWrapperToken wrappedCollateralAsset;
        IDebtToken debtToken;
    }

    /// @dev create lending pair with clones
    function createLendingPairWithProxy(
        string memory _lendingPairName,
        string memory _lendingPairSymbol,
        address _pauseGuardian,
        IERC20 _collateralAsset,
        BorrowLocalVars calldata _borrowVars
    ) external whenNotPaused returns (address newLendingPair) {
        require(_pauseGuardian != address(0), "INV_G");
        require(address(_collateralAsset) != address(0), "INV_C");
        require(address(_borrowVars.borrowAsset) != address(0), "INV_B");
        require(
            validInterestRateModels[address(_borrowVars.interestRateModel)] == true,
            "INV_I"
        );


        WrappedAssetLocalVars memory wrappedAssetLocalVars;
        
        bytes32 salt = keccak256(abi.encode(_lendingPairName, _lendingPairSymbol, allPairs.length));
        newLendingPair = lendingPairImplementation.cloneDeterministic(salt);

        // initialize wrapper borrow asset
        wrappedAssetLocalVars.wrappedBorrowAsset =
            IBSWrapperToken(
                initWrapperTokensWithProxy(
                    borrowAssetWrapperImplementation,
                    newLendingPair,
                    address(_borrowVars.borrowAsset),
                    _lendingPairName,
                    "BOR",
                    salt
                )
            );

        // initialize wrapper collateral asset
        wrappedAssetLocalVars.wrappedCollateralAsset =
            IBSWrapperToken(
                initWrapperTokensWithProxy(
                    collateralWrapperImplementation,
                    newLendingPair,
                    address(_collateralAsset),
                    _lendingPairName,
                    "COL",
                    salt
                )
            );

        // initialize debt token
        wrappedAssetLocalVars.debtToken =
            IDebtToken(
                initWrapperTokensWithProxy(
                    debtTokenImplementation,
                    newLendingPair,
                    address(_borrowVars.borrowAsset),
                    _lendingPairName,
                    "DEBT",
                    salt
                )
            );

        DataTypes.BorrowAssetConfig memory borrowConfig =
            DataTypes.BorrowAssetConfig(
                _borrowVars.initialExchangeRateMantissa,
                _borrowVars.reserveFactorMantissa,
                _borrowVars.collateralFactor,
                wrappedAssetLocalVars.wrappedBorrowAsset,
                _borrowVars.liquidationFee,
                wrappedAssetLocalVars.debtToken
            );

        // initialize lending pair
        IBSLendingPair(newLendingPair).initialize(
            _lendingPairName,
            _lendingPairSymbol,
            _borrowVars.borrowAsset,
            _collateralAsset,
            borrowConfig,
            wrappedAssetLocalVars.wrappedCollateralAsset,
            _borrowVars.interestRateModel,
            _pauseGuardian
        );
        
        allPairs.push(newLendingPair);
        emit NewLendingPair(newLendingPair, block.timestamp);
    }

    function initWrapperTokensWithProxy(
        address _implementation,
        address _pair,
        address _underlying,
        string memory _lendingPairName,
        string memory _tokenType,
        bytes32 _salt
    ) internal returns (address wrapper) {
        wrapper = _implementation.cloneDeterministic(_salt);

        initializeWrapperTokens(
            _pair,
            IBSWrapperToken(wrapper),
            IERC20Details(_underlying),
            _lendingPairName,
            _tokenType
        );
    }

    function initializeWrapperTokens(
        address _pair,
        IBSWrapperToken _wrapperToken,
        IERC20Details _underlying,
        string memory _lendingPairName,
        string memory _tokenType
    ) internal {
        bytes memory name = abi.encodePacked(_lendingPairName);
        name = abi.encodePacked(name, "-PAIR-", _tokenType);
        bytes memory symbol = abi.encodePacked(_lendingPairName);
        symbol = abi.encodePacked(name, _tokenType);
        // initialize wrapperToken
        IBSWrapperToken(_wrapperToken).initialize(
            _pair,
            address(_underlying),
            string(name),
            string(symbol),
            IRewardDistributorManager(rewardDistributionManager)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

////////////////////////////////////////////////////////////////////////////////////////////
/// @title JumpRateModelV2
/// @author
////////////////////////////////////////////////////////////////////////////////////////////

contract JumpRateModelV2 {
    event NewInterestParams(
        uint256 baseRatePerBlock,
        uint256 multiplierPerBlock,
        uint256 jumpMultiplierPerBlock,
        uint256 kink
    );

    /// @notice The address of the owner, i.e. the Timelock contract, which can update parameters directly
    address public owner;

    /// @notice The approximate number of blocks per year that is assumed by the interest rate model
    uint256 public immutable blocksPerYear;

    /// @notice The multiplier of utilization rate that gives the slope of the interest rate
    uint256 public multiplierPerBlock;

    /// @notice The base interest rate which is the y-intercept when utilization rate is 0
    uint256 public baseRatePerBlock;

    /// @notice The multiplierPerBlock after hitting a specified utilization point
    uint256 public jumpMultiplierPerBlock;

    /// @notice The utilization point at which the jump multiplier is applied
    uint256 public kink;

    /// @dev Maximum borrow rate that can ever be applied per second
    uint256 internal immutable borrowRateMaxMantissa;

    /// @notice Construct an interest rate model
    /// @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
    /// @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
    /// @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
    /// @param kink_ The utilization point at which the jump multiplier is applied
    /// @param owner_ The address of the owner, i.e. which has the ability to update parameters directly
    /// @param borrowRateMaxMantissa_ maximum borrow rate per second
    /// @param blocksPerYear_ the number of blocks on the chain per year
    constructor(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_,
        address owner_,
        uint256 borrowRateMaxMantissa_,
        uint256 blocksPerYear_
    ) {
        require(baseRatePerYear > 0, "invalid base rate");
        require(multiplierPerYear > 0, "invalid multiplier per year");
        require(jumpMultiplierPerYear > 0, "invalid jump multiplier per year");
        require(kink_ > 0, "invalid kink");
        require(owner_ != address(0), "invalid owner");
        require(borrowRateMaxMantissa_ > 0, "invalid borrow rate max");
        require(blocksPerYear_ > 0, "invalid blocks per year");

        owner = owner_;
        borrowRateMaxMantissa = borrowRateMaxMantissa_;
        blocksPerYear = blocksPerYear_;
        updateJumpRateModelInternal(
            baseRatePerYear,
            multiplierPerYear,
            jumpMultiplierPerYear,
            kink_,
            blocksPerYear_
        );
    }

    /// @notice Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
    /// @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
    /// @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
    /// @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
    /// @param kink_ The utilization point at which the jump multiplier is applied
    function updateJumpRateModel(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_
    ) external {
        require(msg.sender == owner, "only the owner may call this function.");
        require(baseRatePerYear > 0, "invalid base rate");
        require(multiplierPerYear > 0, "invalid multiplier per year");
        require(jumpMultiplierPerYear > 0, "invalid jump multiplier per year");
        require(kink_ > 0, "invalid kink");

        updateJumpRateModelInternal(
            baseRatePerYear,
            multiplierPerYear,
            jumpMultiplierPerYear,
            kink_,
            blocksPerYear
        );
    }

    /// @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
    /// @param cash The amount of cash in the market
    /// @param borrows The amount of borrows in the market
    /// @param reserves The amount of reserves in the market (currently unused)
    /// @return The utilization rate as a mantissa between [0, 1e18]
    function utilizationRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public pure returns (uint256) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        return (borrows * (1e18)) / (cash + borrows - reserves);
    }

    /// @notice Calculates the current borrow rate per block, with the error code expected by the market
    /// @param cash The amount of cash in the market
    /// @param borrows The amount of borrows in the market
    /// @param reserves The amount of reserves in the market
    /// @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
    function getBorrowRateInternal(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) internal view returns (uint256) {
        uint256 util = utilizationRate(cash, borrows, reserves);

        if (util <= kink) {
            return (util * multiplierPerBlock) / 1e18 + baseRatePerBlock;
        } else {
            uint256 normalRate = (kink * multiplierPerBlock) / 1e18 + baseRatePerBlock;
            uint256 excessUtil = util - kink;
            return (excessUtil * jumpMultiplierPerBlock) / 1e18 + normalRate;
        }
    }

    /**
    /// @notice Calculates the current supply rate per block
    /// @param cash The amount of cash in the market
    /// @param borrows The amount of borrows in the market
    /// @param reserves The amount of reserves in the market
    /// @param reserveFactorMantissa The current reserve factor for the market
    /// @return The supply rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) public view returns (uint256) {
        uint256 oneMinusReserveFactor = uint256(1e18) - reserveFactorMantissa;
        uint256 borrowRate = getBorrowRateInternal(cash, borrows, reserves);
        uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / 1e18;
        return (utilizationRate(cash, borrows, reserves) * rateToPool) / 1e18;
    }

    /// @notice Internal function to update the parameters of the interest rate model
    /// @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
    /// @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
    /// @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
    /// @param kink_ The utilization point at which the jump multiplier is applied
    function updateJumpRateModelInternal(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_,
        uint256 blocksPerYear_
    ) internal {
        baseRatePerBlock = baseRatePerYear / blocksPerYear_;
        multiplierPerBlock = (multiplierPerYear * 1e18) / (blocksPerYear_ * kink_);
        jumpMultiplierPerBlock = jumpMultiplierPerYear / blocksPerYear_;
        kink = kink_;

        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
    }

    /// @notice Calculates the current borrow rate per block
    /// @param cash The amount of cash in the market
    /// @param borrows The amount of borrows in the market
    /// @param reserves The amount of reserves in the market
    /// @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256) {
        uint256 borrowRateMantissa = getBorrowRateInternal(cash, borrows, reserves);
        if (borrowRateMantissa > borrowRateMaxMantissa) {
            return borrowRateMaxMantissa;
        } else {
            return borrowRateMantissa;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPriceOracleAggregator.sol";
import "./IBSWrapperToken.sol";
import "./IDebtToken.sol";
import "./IBSVault.sol";
import "../DataTypes.sol";

interface IBSLendingPair {
    event Initialized(
        address indexed pair,
        address indexed asset,
        address indexed collateralAsset,
        address pauseGuardian
    );

    /**
     * Emitted on deposit
     *
     * @param pair The pair being interacted with
     * @param asset The asset deposited in the pair
     * @param tokenReceipeint The user the receives the bsTokens
     * @param user The user that made the deposit
     * @param amount The amount deposited
     **/
    event Deposit(
        address indexed pair,
        address indexed asset,
        address indexed tokenReceipeint,
        address user,
        uint256 amount
    );

    event Borrow(address indexed borrower, uint256 amount);

    /**
     * Emitted on Redeem
     *
     * @param pair The pair being interacted with
     * @param asset The asset withdraw in the pair
     * @param user The user that's making the withdrawal
     * @param to The user the receives the withdrawn tokens
     * @param amount The amount being withdrawn
     **/
    event Redeem(
        address indexed pair,
        address indexed asset,
        address indexed user,
        address to,
        uint256 amount,
        uint256 amountofWrappedBurned
    );

    event WithdrawCollateral(address account, uint256 amount);

    event ReserveWithdraw(address user, uint256 shares);

    /**
     * Emitted on repay
     *
     * @param pair The pair being interacted with
     * @param asset The asset repaid in the pair
     * @param beneficiary The user that's getting their debt reduced
     * @param repayer The user that's providing the funds
     * @param amount The amount being repaid
     **/
    event Repay(
        address indexed pair,
        address indexed asset,
        address indexed beneficiary,
        address repayer,
        uint256 amount
    );

    /**
     * Emitted on liquidation
     *
     * @param pair The pair being interacted with
     * @param asset The asset that getting liquidated
     * @param user The user that's getting liquidated
     * @param liquidatedCollateralAmount The of collateral transferred to the liquidator
     * @param liquidator The liquidator
     **/
    event Liquidate(
        address indexed pair,
        address indexed asset,
        address indexed user,
        uint256 liquidatedCollateralAmount,
        address liquidator
    );

    /**
     * @dev Emitted on flashLoan
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );

    /**
     * @dev Emitted on interest accrued
     * @param accrualBlockNumber block number
     * @param borrowIndex borrow index
     * @param totalBorrows total borrows
     * @param totalReserves total reserves
     **/
    event InterestAccrued(
        address indexed pair,
        uint256 accrualBlockNumber,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalReserves
    );

    event InterestShortCircuit(uint256 blockNumber);

    event ActionPaused(uint8 action, uint256 timestamp);
    event ActionUnPaused(uint8 action, uint256 timestamp);

    function initialize(
        string memory _name,
        string memory _symbol,
        IERC20 _asset,
        IERC20 _collateralAsset,
        DataTypes.BorrowAssetConfig calldata borrowConfig,
        IBSWrapperToken _wrappedCollateralAsset,
        IInterestRateModel _interestRate,
        address _pauseGuardian
    ) external;

    function asset() external view returns (IERC20);

    function depositBorrowAsset(address _tokenReceipeint, uint256 _amount) external;

    function depositCollateral(address _tokenReceipeint, uint256 _vaultShareAmount) external;

    function redeem(address _to, uint256 _amount) external;

    function collateralOfAccount(address _account) external view returns (uint256);

    function getMaxWithdrawAllowed(address account) external returns (uint256);

    function oracle() external view returns (IPriceOracleAggregator);

    function collateralAsset() external view returns (IERC20);

    function calcBorrowLimit(uint256 amount) external view returns (uint256);

    function accountInterestIndex(address) external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function debtToken() external view returns (IDebtToken);

    function borrowBalancePrior(address _account) external view returns (uint256);

    function wrapperBorrowedAsset() external view returns (IBSWrapperToken);

    function wrappedCollateralAsset() external view returns (IBSWrapperToken);

    function totalReserves() external view returns (uint256);

    function withdrawFees(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC3156FlashLender.sol";

interface IBSVault is IERC3156FlashLender {
    // ************** //
    // *** EVENTS *** //
    // ************** //

    /// @notice Emitted on deposit
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being deposited
    /// @param amount being deposited
    /// @param shares the represent the amount deposited in the vault
    event Deposit(
        IERC20 indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 shares
    );

    /// @notice Emitted on withdraw
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being withdrawn
    /// @param amount Amount of underlying being withdrawn
    /// @param shares the represent the amount withdraw from the vault
    event Withdraw(
        IERC20 indexed token,
        address indexed from,
        address indexed to,
        uint256 shares,
        uint256 amount
    );

    event Transfer(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);

    event FlashLoan(
        address indexed borrower,
        IERC20 indexed token,
        uint256 amount,
        uint256 feeAmount,
        address indexed receiver
    );

    event TransferControl(address _newTeam, uint256 timestamp);

    event UpdateFlashLoanRate(uint256 newRate);

    event Approval(address indexed user, address indexed allowed, bool status);

    event OwnershipAccepted(address newOwner, uint256 timestamp);

    // ************** //
    // *** FUNCTIONS *** //
    // ************** //

    function initialize(uint256 _flashLoanRate, address _owner) external;

    function approveContract(
        address _user,
        address _contract,
        bool _status,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function balanceOf(IERC20, address) external view returns (uint256);

    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares
    ) external;

    function toShare(
        IERC20 token,
        uint256 amount,
        bool ceil
    ) external view returns (uint256);

    function toUnderlying(IERC20 token, uint256 share) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRewardDistributorManager.sol";

interface IBSWrapperTokenBase is IERC20 {
    function initialize(
        address _owner,
        address _underlying,
        string memory _tokenName,
        string memory _tokenSymbol,
        IRewardDistributorManager _manager
    ) external;

    function burn(address _from, uint256 _amount) external;

    function owner() external view returns (address);
}

interface IBSWrapperToken is IBSWrapperTokenBase {
    function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import {IBSWrapperTokenBase} from "./IBSWrapperToken.sol";

interface IDebtToken is IBSWrapperTokenBase {
    event DelegateBorrow(address from, address to, uint256 amount, uint256 timestamp);

    function increaseTotalDebt(uint256 _amount) external;

    function principal(address _account) external view returns (uint256);

    function mint(
        address _to,
        address _owner,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IInterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IOracle {
    /// @notice Price update event
    /// @param asset the asset
    /// @param newPrice price of the asset
    event PriceUpdated(address asset, uint256 newPrice);

    function getPriceInUSD() external returns (uint256);

    function viewPriceInUSD() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOracle.sol";

interface IPriceOracleAggregator {
    event UpdateOracle(IERC20 token, IOracle oracle);

    function getPriceInUSD(IERC20 _token) external returns (uint256);

    function updateOracleForAsset(IERC20 _asset, IOracle _oracle) external;

    function viewPriceInUSD(IERC20 _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardDistributor {
    event Initialized(
        IERC20 indexed _rewardToken,
        uint256 _amountDistributePerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _guardian,
        uint256 timestamp
    );

    function accumulateReward(address _tokenAddr, address _user) external;

    function endTimestamp() external returns (uint256);

    function initialize(
        string calldata _name,
        IERC20 _rewardToken,
        uint256 _amountDistributePerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _guardian
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./IRewardDistributor.sol";

interface IRewardDistributorManager {
    /// @dev Emitted on Initialization
    event Initialized(address owner, uint256 timestamp);

    event ApprovedDistributor(IRewardDistributor distributor, uint256 timestamp);
    event AddReward(address tokenAddr, IRewardDistributor distributor, uint256 timestamp);
    event RemoveReward(address tokenAddr, IRewardDistributor distributor, uint256 timestamp);
    event TransferControl(address _newTeam, uint256 timestamp);
    event OwnershipAccepted(address newOwner, uint256 timestamp);

    function activateReward(address _tokenAddr) external;

    function removeReward(address _tokenAddr, IRewardDistributor _distributor) external;

    function accumulateRewards(address _from, address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IERC20Details {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

