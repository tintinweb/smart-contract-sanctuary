// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IERC20Modified.sol";
import "./tokens/VolmexPositionToken.sol";
import "./VolmexProtocol.sol";

/**
 * @title Factory Contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexIndexFactory is OwnableUpgradeable {
    event IndexRegistered(
        uint256 indexed indexCount,
        VolmexProtocol indexed index
    );

    event VolatilityTokenCreated(
        IERC20Modified indexed volatilityToken,
        IERC20Modified indexed inverseVolatilityToken,
        string tokenName,
        string tokenSymbol
    );

    // Volatility token implementation contract for factory
    address public positionTokenImplementation;

    // To store the address of volatility.
    mapping(uint256 => address) public getIndex;

    // To store the name of volatility
    mapping(uint256 => string) public getIndexSymbol;

    // Used to store the address and name of volatility at a particular _index (incremental state of 1)
    uint256 public indexCount;

    // These are position token roles
    // Calculated as keccak256("VOLMEX_PROTOCOL_ROLE").
    bytes32 private constant VOLMEX_PROTOCOL_ROLE =
        0x33ba6006595f7ad5c59211bde33456cab351f47602fc04f644c8690bc73c4e16;

    // Referenced from Openzepplin AccessControl.sol
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @notice Get the address of implementation contracts instance.
     */
    function initialize(address _implementation) external initializer {
        __Ownable_init();

        positionTokenImplementation = _implementation;
    }

    /**
     * @notice Get the counterfactual address of position token implementation
     */
    function determineVolatilityTokenAddress(
        uint256 _indexCount,
        string memory _name,
        string memory _symbol
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_indexCount, _name, _symbol));
        return
            Clones.predictDeterministicAddress(
                positionTokenImplementation,
                salt,
                address(this)
            );
    }

    /**
     * @notice Clones new volatility tokens - { returns volatility tokens address typecasted to IERC20Modified }
     *
     * @dev Increment the indexCount by 1
     * @dev Check if state is at NotInitialized
     * @dev Clones the volatility and inverse volatility tokens
     * @dev Stores the volatility name, referenced by indexCount
     * @dev Emits event of volatility token name & symbol, indexCount(position), position tokens address
     *
     * @param _tokenName is the name for volatility
     * @param _tokenSymbol is the symbol for volatility
     */
    function createVolatilityTokens(
        string memory _tokenName,
        string memory _tokenSymbol
    )
        external
        onlyOwner
        returns (
            IERC20Modified volatilityToken,
            IERC20Modified inverseVolatilityToken
        )
    {
        volatilityToken = IERC20Modified(
            _clonePositonToken(_tokenName, _tokenSymbol)
        );
        inverseVolatilityToken = IERC20Modified(
            _clonePositonToken(
                string(abi.encodePacked("Inverse ", _tokenName)),
                string(abi.encodePacked("i", _tokenSymbol))
            )
        );

        emit VolatilityTokenCreated(
            volatilityToken,
            inverseVolatilityToken,
            _tokenName,
            _tokenSymbol
        );
    }

    /**
     * @notice Registers the Volmex Protocol
     *
     * @dev Check if state is at VolatilitysCreated
     * @dev Stores index address, referenced by indexCount
     * @dev Grants the VOLMEX_PROTOCOL_ROLE and DEFAULT_ADMIN_ROLE to protocol
     * @dev Update index state to Completed
     * @dev Emit event of index registered with indexCount and index address
     *
     * @param _volmexProtocolContract Address of VolmexProtocol typecasted to VolmexProtocol
     * @param _collateralSymbol Symbol of collateral used
     */
    function registerIndex(
        VolmexProtocol _volmexProtocolContract,
        string memory _collateralSymbol
    ) external onlyOwner {
        indexCount++;

        getIndex[indexCount] = address(_volmexProtocolContract);

        IERC20Modified volatilityToken =
            _volmexProtocolContract.volatilityToken();
        IERC20Modified inverseVolatilityToken =
            _volmexProtocolContract.inverseVolatilityToken();

        getIndexSymbol[indexCount] = string(
            abi.encodePacked(volatilityToken.symbol(), _collateralSymbol)
        );

        volatilityToken.grantRole(
            VOLMEX_PROTOCOL_ROLE,
            address(_volmexProtocolContract)
        );

        inverseVolatilityToken.grantRole(
            VOLMEX_PROTOCOL_ROLE,
            address(_volmexProtocolContract)
        );

        volatilityToken.grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        inverseVolatilityToken.grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        emit IndexRegistered(indexCount, _volmexProtocolContract);
    }

    /**
     * @notice Clones the position token - { returns position token address }
     *
     * @dev Generates a salt using indexCount, token name and token symbol
     * @dev Clone the position token implementation with a salt make it deterministic
     * @dev Initializes the position token
     *
     * @param _name is the name of volatility token
     * @param _symbol is the symbol of volatility token
     */
    function _clonePositonToken(string memory _name, string memory _symbol)
        private
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(indexCount, _name, _symbol));

        VolmexPositionToken newVolatilityToken =
            VolmexPositionToken(
                Clones.cloneDeterministic(positionTokenImplementation, salt)
            );
        newVolatilityToken.initialize(_name, _symbol);

        return address(newVolatilityToken);
    }
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
    uint256[49] private __gap;
}

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Modified Interface of the OpenZeppelin's IERC20 extra functions to add features in position token.
 */
interface IERC20Modified is IERC20 {
    function symbol() external view returns (string memory);

    function mint(address _toWhom, uint256 amount) external;

    function burn(address _whose, uint256 amount) external;

    function grantRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";

/**
 * @title Token Contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexPositionToken is
    Initializable,
    AccessControlUpgradeable,
    ERC20PausableUpgradeable
{
    // Position token role, calculated as keccak256("VOLMEX_PROTOCOL_ROLE")
    bytes32 public constant VOLMEX_PROTOCOL_ROLE =
        0x33ba6006595f7ad5c59211bde33456cab351f47602fc04f644c8690bc73c4e16;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `VOLMEX_PROTOCOL_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    function initialize(string memory name, string memory symbol)
        external
        initializer
    {
        __ERC20_init_unchained(name, symbol);
        __AccessControl_init_unchained();

        __ERC20Pausable_init();
        __ERC165_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VOLMEX_PROTOCOL_ROLE, msg.sender);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `VOLMEX_PROTOCOL_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(VOLMEX_PROTOCOL_ROLE, msg.sender),
            "VolmexPositionToken: must have volmex protocol role to mint"
        );
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(address from, uint256 amount) public virtual {
        require(
            hasRole(VOLMEX_PROTOCOL_ROLE, msg.sender),
            "VolmexPositionToken: must have volmex protocol role to burn"
        );
        _burn(from, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `VOLMEX_PROTOCOL_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(VOLMEX_PROTOCOL_ROLE, msg.sender),
            "VolmexPositionToken: must have volmex protocol role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `VOLMEX_PROTOCOL_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(VOLMEX_PROTOCOL_ROLE, msg.sender),
            "VolmexPositionToken: must have volmex protocol role to unpause"
        );
        _unpause();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IERC20Modified.sol";
import "./library/VolmexSafeERC20.sol";

/**
 * @title Protocol Contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexProtocol is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using VolmexSafeERC20 for IERC20Modified;

    event ToggleActivated(bool isActive);
    event UpdatedVolatilityToken(
        address indexed positionToken,
        bool isVolatilityIndexToken
    );
    event UpdatedFees(uint256 issuanceFees, uint256 redeemFees);
    event UpdatedMinimumCollateral(uint256 newMinimumCollateralQty);
    event ClaimedFees(uint256 fees);
    event ToggledVolatilityTokenPause(bool isPause);
    event Settled(uint256 settlementPrice);
    event Collateralized(
        address indexed sender,
        uint256 collateralLock,
        uint256 positionTokensMinted,
        uint256 fees
    );
    event Redeemed(
        address indexed sender,
        uint256 collateralReleased,
        uint256 volatilityIndexTokenBurned,
        uint256 inverseVolatilityIndexTokenBurned,
        uint256 fees
    );

    // Has the value of minimum collateral qty required
    uint256 public minimumCollateralQty;

    // Has the boolean state of protocol
    bool public active;

    // Has the boolean state of protocol settlement
    bool public isSettled;

    // Volatility tokens
    IERC20Modified public volatilityToken;
    IERC20Modified public inverseVolatilityToken;

    // Only ERC20 standard functions are used by the collateral defined here.
    // Address of the acceptable collateral token.
    IERC20Modified public collateral;

    // Used to calculate collateralize fee
    uint256 public issuanceFees;

    // Used to calculate redeem fee
    uint256 public redeemFees;

    // Total fee amount for call of collateralize and redeem
    uint256 public accumulatedFees;

    // Percentage value is upto two decimal places, so we're dividing it by 10000
    // Set the max fee as 5%, i.e. 500/10000.
    uint256 constant MAX_FEE = 500;

    // No need to add 18 decimals, because they are already considered in respective token qty arguments.
    uint256 public volatilityCapRatio;

    // This is the price of volatility index, ranges from 0 to volatilityCapRatio,
    // and the inverse can be calculated by subtracting volatilityCapRatio by settlementPrice.
    uint256 public settlementPrice;

    /**
     * @notice Used to check contract is active
     */
    modifier onlyActive() {
        require(active, "Volmex: Protocol not active");
        _;
    }

    /**
     * @notice Used to check contract is not settled
     */
    modifier onlyNotSettled() {
        require(!isSettled, "Volmex: Protocol settled");
        _;
    }

    /**
     * @notice Used to check contract is settled
     */
    modifier onlySettled() {
        require(isSettled, "Volmex: Protocol not settled");
        _;
    }

    /**
     * @dev Makes the protocol `active` at deployment
     * @dev Sets the `minimumCollateralQty`
     * @dev Makes the collateral token as `collateral`
     * @dev Assign position tokens
     * @dev Sets the `volatilityCapRatio`
     *
     * @param _collateralTokenAddress is address of collateral token typecasted to IERC20Modified
     * @param _volatilityToken is address of volatility index token typecasted to IERC20Modified
     * @param _inverseVolatilityToken is address of inverse volatility index token typecasted to IERC20Modified
     * @param _minimumCollateralQty is the minimum qty of tokens need to mint 0.1 volatility and inverse volatility tokens
     * @param _volatilityCapRatio is the cap for volatility
     */
    function initialize(
        IERC20Modified _collateralTokenAddress,
        IERC20Modified _volatilityToken,
        IERC20Modified _inverseVolatilityToken,
        uint256 _minimumCollateralQty,
        uint256 _volatilityCapRatio
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        require(
            _minimumCollateralQty > 0,
            "Volmex: Minimum collateral quantity should be greater than 0"
        );

        active = true;
        minimumCollateralQty = _minimumCollateralQty;
        collateral = _collateralTokenAddress;
        volatilityToken = _volatilityToken;
        inverseVolatilityToken = _inverseVolatilityToken;
        volatilityCapRatio = _volatilityCapRatio;
    }

    /**
     * @notice Toggles the active variable. Restricted to only the owner of the contract.
     */
    function toggleActive() external onlyOwner {
        active = !active;
        emit ToggleActivated(active);
    }

    /**
     * @notice Update the `minimumCollateralQty`
     * @param _newMinimumCollQty Provides the new minimum collateral quantity
     */
    function updateMinimumCollQty(uint256 _newMinimumCollQty)
        external
        onlyOwner
    {
        require(
            _newMinimumCollQty > 0,
            "Volmex: Minimum collateral quantity should be greater than 0"
        );
        minimumCollateralQty = _newMinimumCollQty;
        emit UpdatedMinimumCollateral(_newMinimumCollQty);
    }

    /**
     * @notice Update the {Volatility Token}
     * @param _positionToken Address of the new position token
     * @param _isVolatilityIndexToken Type of the position token, { VolatilityIndexToken: true, InverseVolatilityIndexToken: false }
     */
    function updateVolatilityToken(
        address _positionToken,
        bool _isVolatilityIndexToken
    ) external onlyOwner {
        _isVolatilityIndexToken
            ? volatilityToken = IERC20Modified(_positionToken)
            : inverseVolatilityToken = IERC20Modified(_positionToken);
        emit UpdatedVolatilityToken(_positionToken, _isVolatilityIndexToken);
    }

    /**
     * @notice Add collateral to the protocol and mint the position tokens
     * @param _collateralQty Quantity of the collateral being deposited
     *
     * NOTE: Collateral quantity should be at least required minimum collateral quantity
     *
     * Calculation: Get the quantity for position token
     * Mint the position token for `msg.sender`
     *
     */
    function collateralize(uint256 _collateralQty)
        external
        onlyActive
        onlyNotSettled
    {
        require(
            _collateralQty >= minimumCollateralQty,
            "Volmex: CollateralQty > minimum qty required"
        );

        // Mechanism to calculate the collateral qty using the increase in balance
        // of protocol contract to counter USDT's fee mechanism, which can be enabled in future
        uint256 initialProtocolBalance = collateral.balanceOf(address(this));
        collateral.safeTransferFrom(msg.sender, address(this), _collateralQty);
        uint256 finalProtocolBalance = collateral.balanceOf(address(this));

        _collateralQty = finalProtocolBalance - initialProtocolBalance;

        uint256 fee;
        if (issuanceFees > 0) {
            fee = (_collateralQty * issuanceFees) / 10000;
            _collateralQty = _collateralQty - fee;
            accumulatedFees = accumulatedFees + fee;
        }

        uint256 qtyToBeMinted = _collateralQty / volatilityCapRatio;

        volatilityToken.mint(msg.sender, qtyToBeMinted);
        inverseVolatilityToken.mint(msg.sender, qtyToBeMinted);

        emit Collateralized(msg.sender, _collateralQty, qtyToBeMinted, fee);
    }

    /**
     * @notice Redeem the collateral from the protocol by providing the position token
     *
     * @param _positionTokenQty Quantity of the position token that the user is surrendering
     *
     * Amount of collateral is `_positionTokenQty` by the volatilityCapRatio.
     * Burn the position token
     *
     * Safely transfer the collateral to `msg.sender`
     */
    function redeem(uint256 _positionTokenQty)
        external
        onlyActive
        onlyNotSettled
    {
        uint256 collQtyToBeRedeemed = _positionTokenQty * volatilityCapRatio;

        _redeem(collQtyToBeRedeemed, _positionTokenQty, _positionTokenQty);
    }

    /**
     * @notice Redeem the collateral from the protocol after settlement
     *
     * @param _volatilityIndexTokenQty Quantity of the volatility index token that the user is surrendering
     * @param _inverseVolatilityIndexTokenQty Quantity of the inverse volatility index token that the user is surrendering
     *
     * Amount of collateral is `_volatilityIndexTokenQty` by the settlementPrice and `_inverseVolatilityIndexTokenQty`
     * by volatilityCapRatio - settlementPrice
     * Burn the position token
     *
     * Safely transfer the collateral to `msg.sender`
     */
    function redeemSettled(
        uint256 _volatilityIndexTokenQty,
        uint256 _inverseVolatilityIndexTokenQty
    ) external onlyActive onlySettled {
        uint256 collQtyToBeRedeemed =
            (_volatilityIndexTokenQty * settlementPrice) +
                (_inverseVolatilityIndexTokenQty *
                    (volatilityCapRatio - settlementPrice));

        _redeem(
            collQtyToBeRedeemed,
            _volatilityIndexTokenQty,
            _inverseVolatilityIndexTokenQty
        );
    }

    /**
     * @notice Settle the contract, preventing new minting and providing individual token redemption
     *
     * @param _settlementPrice The price of the volatility index after settlement
     *
     * The inverse volatility index token at settlement is worth volatilityCapRatio - volatility index settlement price
     */
    function settle(uint256 _settlementPrice)
        external
        onlyOwner
        onlyNotSettled
    {
        require(
            _settlementPrice <= volatilityCapRatio,
            "Volmex: _settlementPrice should be less than equal to volatilityCapRatio"
        );
        settlementPrice = _settlementPrice;
        isSettled = true;
        emit Settled(settlementPrice);
    }

    /**
     * @notice Recover tokens accidentally sent to this contract
     */
    function recoverTokens(
        address _token,
        address _toWhom,
        uint256 _howMuch
    ) external nonReentrant onlyOwner {
        require(
            _token != address(collateral),
            "Volmex: Collateral token not allowed"
        );
        IERC20Modified(_token).safeTransfer(_toWhom, _howMuch);
    }

    /**
     * @notice Update the percentage of `issuanceFees` and `redeemFees`
     *
     * @param _issuanceFees Percentage of fees required to collateralize the collateral
     * @param _redeemFees Percentage of fees required to redeem the collateral
     */
    function updateFees(uint256 _issuanceFees, uint256 _redeemFees)
        external
        onlyOwner
    {
        require(
            _issuanceFees <= MAX_FEE && _redeemFees <= MAX_FEE,
            "Volmex: issue/redeem fees should be less than MAX_FEE"
        );

        issuanceFees = _issuanceFees;
        redeemFees = _redeemFees;

        emit UpdatedFees(_issuanceFees, _redeemFees);
    }

    /**
     * @notice Safely transfer the accumulated fees to owner
     */
    function claimAccumulatedFees() external onlyOwner {
        uint256 claimedAccumulatedFees = accumulatedFees;
        delete accumulatedFees;

        collateral.safeTransfer(owner(), claimedAccumulatedFees);

        emit ClaimedFees(claimedAccumulatedFees);
    }

    /**
     * @notice Pause/unpause volmex position token.
     *
     * @param _isPause Boolean value to pause or unpause the position token { true = pause, false = unpause }
     */
    function togglePause(bool _isPause) external onlyOwner {
        if (_isPause) {
            volatilityToken.pause();
            inverseVolatilityToken.pause();
        } else {
            volatilityToken.unpause();
            inverseVolatilityToken.unpause();
        }

        emit ToggledVolatilityTokenPause(_isPause);
    }

    function _redeem(
        uint256 _collateralQtyRedeemed,
        uint256 _volatilityIndexTokenQty,
        uint256 _inverseVolatilityIndexTokenQty
    ) internal {
        uint256 fee;
        if (redeemFees > 0) {
            fee = (_collateralQtyRedeemed * redeemFees) / 10000;
            _collateralQtyRedeemed = _collateralQtyRedeemed - fee;
            accumulatedFees = accumulatedFees + fee;
        }

        volatilityToken.burn(msg.sender, _volatilityIndexTokenQty);
        inverseVolatilityToken.burn(
            msg.sender,
            _inverseVolatilityIndexTokenQty
        );

        collateral.safeTransfer(msg.sender, _collateralQtyRedeemed);

        emit Redeemed(
            msg.sender,
            _collateralQtyRedeemed,
            _volatilityIndexTokenQty,
            _inverseVolatilityIndexTokenQty,
            fee
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VolmexSafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using VolmexSafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 *
 * NOTE: Inspired from Openzeppelin's SafeERC20 library.
 */
library VolmexSafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "VolmexSafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        // we're implementing it ourselves. We use {functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = functionCall(address(token), data, "VolmexSafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "VolmexSafeERC20: ERC20 operation did not succeed");
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "VolmexSafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: 0 }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}