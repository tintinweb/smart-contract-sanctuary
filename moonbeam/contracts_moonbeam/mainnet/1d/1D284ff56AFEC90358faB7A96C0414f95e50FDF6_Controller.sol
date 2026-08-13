// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Initializable.sol";

import "IRelayEncoder.sol";
import "IxTokens.sol";
import "IXcmTransactor.sol";
import "ILedger.sol";
import "IAuthManager.sol";
import "ILido.sol";
import "Encoding.sol";


contract Controller is Initializable {
    using Encoding for uint256;

    // Event emitted when weight updated
    event WeightUpdated (
        uint8 index,
        uint64 newValue
    );

    // Event emitted when bond called on relay chain
    event Bond (
        address caller,
        bytes32 stash,
        bytes32 controller,
        uint256 amount
    );

    // Event emitted when bond extra called on relay chain
    event BondExtra (
        address caller,
        bytes32 stash,
        uint256 amount
    );

    // Event emitted when unbond on relay chain
    event Unbond (
        address caller,
        bytes32 stash,
        uint256 amount
    );

    // Event emitted when rebond called on relay chain
    event Rebond (
        address caller,
        bytes32 stash,
        uint256 amount
    );

    // Event emitted when withdraw called on relay chain
    event Withdraw (
        address caller,
        bytes32 stash
    );

    // Event emitted when nominate called on relay chain
    event Nominate (
        address caller,
        bytes32 stash,
        bytes32[] validators
    );

    // Event emitted when chill called on relay chain
    event Chill (
        address caller,
        bytes32 stash
    );

    // Event emitted when transfer vKSM from parachain to relay chain called
    event TransferToRelaychain (
        address from,
        bytes32 to,
        uint256 amount
    );

    // Event emitted when transfer KSM from relay chain to parachain called
    event TransferToParachain (
        bytes32 from,
        address to,
        uint256 amount
    );

    // ledger controller account
    uint16 public rootDerivativeIndex;

    // vKSM precompile
    IERC20 internal VKSM;

    // relay call builder precompile
    IRelayEncoder internal RELAY_ENCODER;

    // xcm transactor precompile
    IXcmTransactor internal XCM_TRANSACTOR;

    // xTokens precompile
    IxTokens internal X_TOKENS;

    // LIDO address
    address public LIDO;

    // first hex for encodeTransfer (defines parachain ID, 2023 for Kusama)
    bytes public hex1;

    // second hex for encodeTransfer (defines asset for transfer, fungible)
    bytes public hex2;

    // hex for determination pallet (0x1801 for Kusama)
    bytes public asDerevativeHex;

    // Second layer derivative-proxy account to index
    mapping(address => uint16) public senderToIndex;

    // Index to second layer derivative-proxy account
    mapping(uint16 => bytes32) public indexToAccount;

    // Enumerator for weights
    enum WEIGHT {
        AS_DERIVATIVE,              // 410_000_000
        BOND_BASE,                  // 600_000_000
        BOND_EXTRA_BASE,            // 1_100_000_000
        UNBOND_BASE,                // 1_250_000_000
        WITHDRAW_UNBONDED_BASE,     // 500_000_000
        WITHDRAW_UNBONDED_PER_UNIT, // 60_000
        REBOND_BASE,                // 1_200_000_000
        REBOND_PER_UNIT,            // 40_000
        CHILL_BASE,                 // 900_000_000
        NOMINATE_BASE,              // 1_000_000_000
        NOMINATE_PER_UNIT,          // 31_000_000
        TRANSFER_TO_PARA_BASE,      // 700_000_000
        TRANSFER_TO_RELAY_BASE      // 4_000_000_000
    }

    // Constant for max weight
    uint64 public MAX_WEIGHT;// = 1_835_300_000;

    // Array with current weights
    uint64[] public weights;

    // Parachain side fee on reverse transfer
    uint256 public REVERSE_TRANSFER_FEE;// = 4_000_000

    // Relay side fee on transfer
    uint256 public TRANSFER_FEE;// = 18_900_000_000

    // Controller manager role
    bytes32 internal constant ROLE_CONTROLLER_MANAGER = keccak256("ROLE_CONTROLLER_MANAGER");

    // Beacon manager role
    bytes32 internal constant ROLE_BEACON_MANAGER = keccak256("ROLE_BEACON_MANAGER");

    // Allows function calls only for registered ledgers
    modifier onlyRegistred() {
        require(senderToIndex[msg.sender] != 0, "CONTROLLER: UNREGISTERED_SENDER");
        _;
    }

    // Allows function calls only for members with role
    modifier auth(bytes32 role) {
        require(IAuthManager(ILido(LIDO).AUTH_MANAGER()).has(role, msg.sender), "CONTROLLER: UNAUTHOROZED");
        _;
    }

    // Allows function calls only for LIDO contract
    modifier onlyLido() {
        require(msg.sender == LIDO, "CONTROLLER: CALLER_NOT_LIDO");
        _;
    }

    /**
    * @notice Initialize ledger contract.
    * @param _rootDerivativeIndex - stash account id
    * @param _vKSM - vKSM contract address
    * @param _relayEncoder - relayEncoder(relaychain calls builder) contract address
    * @param _xcmTransactor - xcmTransactor(relaychain calls relayer) contract address
    * @param _xTokens - minimal allowed nominator balance
    * @param _hex1 - first hex for encodeTransfer
    * @param _hex2 - second hex for encodeTransfer
    * @param _asDerevativeHex - hex for as derevative call
    */
    function initialize(
        uint16 _rootDerivativeIndex,
        address _vKSM,
        address _relayEncoder,
        address _xcmTransactor,
        address _xTokens,
        bytes calldata _hex1,
        bytes calldata _hex2,
        bytes calldata _asDerevativeHex
    ) external initializer {
        require(address(VKSM) == address(0), "CONTROLLER: ALREADY_INITIALIZED");

        rootDerivativeIndex = _rootDerivativeIndex;

        VKSM = IERC20(_vKSM);
        RELAY_ENCODER = IRelayEncoder(_relayEncoder);
        XCM_TRANSACTOR = IXcmTransactor(_xcmTransactor);
        X_TOKENS = IxTokens(_xTokens);

        hex1 = _hex1;
        hex2 = _hex2;
        asDerevativeHex = _asDerevativeHex;
    }

    /**
    * @notice Get current weight by enum
    * @param weightType - enum index of weight
    */
    function getWeight(WEIGHT weightType) public view returns(uint64) {
        return weights[uint256(weightType)];
    }

    /**
    * @notice Set new max weight. Can be called only by ROLE_CONTROLLER_MANAGER
    * @param _maxWeight - max weight
    */
    function setMaxWeight(uint64 _maxWeight) external auth(ROLE_CONTROLLER_MANAGER) {
        MAX_WEIGHT = _maxWeight;
    }

    /**
    * @notice Set new REVERSE_TRANSFER_FEE
    * @param _reverseTransferFee - new fee
    */
    function setReverseTransferFee(uint256 _reverseTransferFee) external auth(ROLE_CONTROLLER_MANAGER) {
        REVERSE_TRANSFER_FEE = _reverseTransferFee;
    }

    /**
    * @notice Set new TRANSFER_FEE
    * @param _transferFee - new fee
    */
    function setTransferFee(uint256 _transferFee) external auth(ROLE_CONTROLLER_MANAGER) {
        TRANSFER_FEE = _transferFee;
    }

    /**
    * @notice Set new relay encoder
    * @param _relayEncoder - new relay encoder
    */
    function setRelayEncoder(address _relayEncoder) external auth(ROLE_BEACON_MANAGER) {
        require(_relayEncoder != address(0), "CONTROLLER: ENCODER_ZERO_ADDRESS");
        RELAY_ENCODER = IRelayEncoder(_relayEncoder);
    }

    /**
    * @notice Set new hexes parametes for encodeTransfer
    * @param _hex1 - first hex for encodeTransfer
    * @param _hex2 - second hex for encodeTransfer
    * @param _asDerevativeHex - hex for as derevative call
    */
    function updateHexParameters(bytes calldata _hex1, bytes calldata _hex2, bytes calldata _asDerevativeHex) external auth(ROLE_CONTROLLER_MANAGER) {
        hex1 = _hex1;
        hex2 = _hex2;
        asDerevativeHex = _asDerevativeHex;
    }

    /**
    * @notice Set LIDO address. Function can be called only once
    * @param _lido - LIDO address
    */
    function setLido(address _lido) external {
        require(LIDO == address(0) && _lido != address(0), "CONTROLLER: LIDO_ALREADY_INITIALIZED");
        LIDO = _lido;
    }

    /**
    * @notice Update weights array. Weight updated only if weight = _weight | 1 << 65
    * @param _weights - weights array
    */
    function setWeights(
        uint128[] calldata _weights
    ) external auth(ROLE_CONTROLLER_MANAGER) {
        require(_weights.length == uint256(type(WEIGHT).max) + 1, "CONTROLLER: WRONG_WEIGHTS_SIZE");
        for (uint256 i = 0; i < _weights.length; ++i) {
            if ((_weights[i] >> 64) > 0) { // if _weights[i] = _weights[i] | 1 << 65 we must update i-th weight
                if (weights.length == i) {
                    weights.push(0);
                }

                weights[i] = uint64(_weights[i]);
                emit WeightUpdated(uint8(i), weights[i]);
            }
        }
    }

    /**
    * @notice Register new ledger contract
    * @param index - index of ledger contract
    * @param accountId - relay chain address of ledger
    * @param paraAddress - parachain address of ledger
    */
    function newSubAccount(uint16 index, bytes32 accountId, address paraAddress) external onlyLido {
        require(indexToAccount[index + 1] == bytes32(0), "CONTROLLER: ALREADY_REGISTERED");

        senderToIndex[paraAddress] = index + 1;
        indexToAccount[index + 1] = accountId;
    }

    /**
    * @notice Unregister ledger contract
    * @param paraAddress - parachain address of ledger
    */
    function deleteSubAccount(address paraAddress) external onlyLido {
        require(senderToIndex[paraAddress] > 0, "CONTROLLER: UNREGISTERED_LEDGER");

        delete indexToAccount[senderToIndex[paraAddress]];
        delete senderToIndex[paraAddress];
    }

    /**
    * @notice Nominate validators from ledger on relay chain
    * @param validators - validators addresses to nominate
    */
    function nominate(bytes32[] calldata validators) external onlyRegistred {
        uint256[] memory convertedValidators = new uint256[](validators.length);
        for (uint256 i = 0; i < validators.length; ++i) {
            convertedValidators[i] = uint256(validators[i]);
        }
        callThroughDerivative(
            getSenderIndex(),
            getWeight(WEIGHT.NOMINATE_BASE) + getWeight(WEIGHT.NOMINATE_PER_UNIT) * uint64(validators.length),
            RELAY_ENCODER.encode_nominate(convertedValidators)
        );

        emit Nominate(msg.sender, getSenderAccount(), validators);
    }

    /**
    * @notice Bond KSM of ledger on relay chain
    * @param controller - controller which used to bond
    * @param amount - amount of KSM to bond
    */
    function bond(bytes32 controller, uint256 amount) external onlyRegistred {
        callThroughDerivative(
            getSenderIndex(),
            getWeight(WEIGHT.BOND_BASE),
            RELAY_ENCODER.encode_bond(uint256(controller), amount, bytes(hex"00"))
        );

        emit Bond(msg.sender, getSenderAccount(), controller, amount);
    }

    /**
    * @notice Bond extra KSM of ledger on relay chain
    * @param amount - extra amount of KSM to bond
    */
    function bondExtra(uint256 amount) external onlyRegistred {
        callThroughDerivative(
            getSenderIndex(),
            getWeight(WEIGHT.BOND_EXTRA_BASE),
            RELAY_ENCODER.encode_bond_extra(amount)
        );

        emit BondExtra(msg.sender, getSenderAccount(), amount);
    }

    /**
    * @notice Unbond KSM of ledger on relay chain
    * @param amount - amount of KSM to unbond
    */
    function unbond(uint256 amount) external onlyRegistred {
        callThroughDerivative(
            getSenderIndex(),
            getWeight(WEIGHT.UNBOND_BASE),
            RELAY_ENCODER.encode_unbond(amount)
        );

        emit Unbond(msg.sender, getSenderAccount(), amount);
    }

    /**
    * @notice Withdraw unbonded tokens (move unbonded tokens to free)
    * @param slashingSpans - number of slashes received by ledger in case if we trying set ledger bonded balance < min, 
    in other cases = 0
    */
    function withdrawUnbonded(uint32 slashingSpans) external onlyRegistred {
        callThroughDerivative(
            getSenderIndex(),
            getWeight(WEIGHT.WITHDRAW_UNBONDED_BASE) + getWeight(WEIGHT.WITHDRAW_UNBONDED_PER_UNIT) * slashingSpans,
            RELAY_ENCODER.encode_withdraw_unbonded(slashingSpans)
        );

        emit Withdraw(msg.sender, getSenderAccount());
    }

    /**
    * @notice Rebond KSM of ledger from unbonded chunks on relay chain
    * @param amount - amount of KSM to rebond
    * @param unbondingChunks - amount of unbonding chunks to rebond
    */
    function rebond(uint256 amount, uint256 unbondingChunks) external onlyRegistred {
        callThroughDerivative(
            getSenderIndex(),
            getWeight(WEIGHT.REBOND_BASE) + getWeight(WEIGHT.REBOND_PER_UNIT) * uint64(unbondingChunks),
            RELAY_ENCODER.encode_rebond(amount)
        );

        emit Rebond(msg.sender, getSenderAccount(), amount);
    }

    /**
    * @notice Put ledger to chill mode
    */
    function chill() external onlyRegistred {
        callThroughDerivative(
            getSenderIndex(),
            getWeight(WEIGHT.CHILL_BASE),
            RELAY_ENCODER.encode_chill()
        );

        emit Chill(msg.sender, getSenderAccount());
    }

    /**
    * @notice Transfer KSM from relay chain to parachain
    * @param amount - amount of KSM to transfer
    */
    function transferToParachain(uint256 amount) external onlyRegistred {
        // to - msg.sender, from - getSenderIndex()
        uint256 parachain_fee = REVERSE_TRANSFER_FEE;

        callThroughDerivative(
            getSenderIndex(),
            getWeight(WEIGHT.TRANSFER_TO_PARA_BASE),
            //encodeReverseTransfer(msg.sender, amount)
            encodeLimitReserveTransfer(msg.sender, amount, getWeight(WEIGHT.TRANSFER_TO_PARA_BASE))
        );

        // compensate parachain side fee on reverse transfer
        if (amount <= parachain_fee) {
            // if amount less than fee just transfer amount
            VKSM.transfer(msg.sender, amount);
        }
        else {
            // else just compensate fee
            VKSM.transfer(msg.sender, parachain_fee);
        }

        emit TransferToParachain(getSenderAccount(), msg.sender, amount);
    }

    /**
    * @notice Transfer vKSM from parachain to relay chain
    * @param amount - amount of vKSM to transfer
    */
    function transferToRelaychain(uint256 amount) external onlyRegistred {
        // to - getSenderIndex(), from - msg.sender
        VKSM.transferFrom(msg.sender, address(this), amount);
        IxTokens.Multilocation memory destination;
        destination.parents = 1;
        destination.interior = new bytes[](1);
        destination.interior[0] = bytes.concat(bytes1(hex"01"), getSenderAccount(), bytes1(hex"00")); // X2, NetworkId: Any
        X_TOKENS.transfer_with_fee(address(VKSM), amount, TRANSFER_FEE, destination, getWeight(WEIGHT.TRANSFER_TO_RELAY_BASE));

        emit TransferToRelaychain(msg.sender, getSenderAccount(), amount);
    }

    /**
    * @notice Get index of registered ledger
    */
    function getSenderIndex() internal returns(uint16) {
        return senderToIndex[msg.sender] - 1;
    }

    /**
    * @notice Get relay chain address of msg.sender
    */
    function getSenderAccount() internal returns(bytes32) {
        return indexToAccount[senderToIndex[msg.sender]];
    }

    /**
    * @notice Send call to relay cahin through xcm transactor
    * @param index - index of ledger on relay chain
    * @param weight - fees on tx execution
    * @param call - bytes for tx execution
    */
    function callThroughDerivative(uint16 index, uint64 weight, bytes memory call) internal {
        bytes memory le_index = new bytes(2);
        le_index[0] = bytes1(uint8(index));
        le_index[1] = bytes1(uint8(index >> 8));

        uint64 total_weight = weight + getWeight(WEIGHT.AS_DERIVATIVE);
        require(total_weight <= MAX_WEIGHT, "CONTROLLER: TOO_MUCH_WEIGHT");

        XCM_TRANSACTOR.transact_through_derivative(
            0, // The transactor to be used
            rootDerivativeIndex, // The index to be used
            address(VKSM), // Address of the currencyId of the asset to be used for fees
            total_weight, // The weight we want to buy in the destination chain
            bytes.concat(asDerevativeHex, le_index, call) // The inner call to be executed in the destination chain
        );
    }

    /**
    * @notice Encoding bytes to call transfer on relay chain
    * @param to - address of KSM receiver
    * @param amount - amount of KSM to send
    */
    function encodeReverseTransfer(address to, uint256 amount) internal returns(bytes memory) {
        return bytes.concat(
            hex1,
            abi.encodePacked(to),
            hex2,
            amount.scaleCompactUint(),
            hex"00000000"
        );
    }

    /**
    * @notice Encoding bytes to call limit reserve transfer on relay chain
    * @param to - address of KSM receiver
    * @param amount - amount of KSM to send
    * @param weight - weight for xcm call
    */
    function encodeLimitReserveTransfer(address to, uint256 amount, uint64 weight) internal returns(bytes memory) {
        return bytes.concat(
            hex1,
            abi.encodePacked(to),
            hex2,
            amount.scaleCompactUint(),
            hex"0000000001",
            uint256(weight).scaleCompactUint()
        );
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

/// @author The Moonbeam Team
/// @title The interface through which solidity contracts will interact with Relay Encoder
/// We follow this same interface including four-byte function selectors, in the precompile that
/// wraps the pallet
interface IRelayEncoder {
    // dev Encode 'bond' relay call
    // Selector: 31627376
    // @param controller_address: Address of the controller
    // @param amount: The amount to bond
    // @param reward_destination: the account that should receive the reward
    // @returns The bytes associated with the encoded call
    function encode_bond(uint256 controller_address, uint256 amount, bytes memory reward_destination) external view returns (bytes memory result);

    // dev Encode 'bond_extra' relay call
    // Selector: 49def326
    // @param amount: The extra amount to bond
    // @returns The bytes associated with the encoded call
    function encode_bond_extra(uint256 amount) external view returns (bytes memory result);

    // dev Encode 'unbond' relay call
    // Selector: bc4b2187
    // @param amount: The amount to unbond
    // @returns The bytes associated with the encoded call
    function encode_unbond(uint256 amount) external view returns (bytes memory result);

    // dev Encode 'withdraw_unbonded' relay call
    // Selector: 2d220331
    // @param slashes: Weight hint, number of slashing spans
    // @returns The bytes associated with the encoded call
    function encode_withdraw_unbonded(uint32 slashes) external view returns (bytes memory result);

    // dev Encode 'validate' relay call
    // Selector: 3a0d803a
    // @param comission: Comission of the validator as parts_per_billion
    // @param blocked: Whether or not the validator is accepting more nominations
    // @returns The bytes associated with the encoded call
    // selector: 3a0d803a
    // function encode_validate(uint256 comission, bool blocked) external pure returns (bytes memory result);

    // dev Encode 'nominate' relay call
    // Selector: a7cb124b
    // @param nominees: An array of AccountIds corresponding to the accounts we will nominate
    // @param blocked: Whether or not the validator is accepting more nominations
    // @returns The bytes associated with the encoded call
    function encode_nominate(uint256 [] memory nominees) external view returns (bytes memory result);

    // dev Encode 'chill' relay call
    // Selector: bc4b2187
    // @returns The bytes associated with the encoded call
    function encode_chill() external view returns (bytes memory result);

    // dev Encode 'set_payee' relay call
    // Selector: 9801b147
    // @param reward_destination: the account that should receive the reward
    // @returns The bytes associated with the encoded call
    // function encode_set_payee(bytes memory reward_destination) external pure returns (bytes memory result);

    // dev Encode 'set_controller' relay call
    // Selector: 7a8f48c2
    // @param controller: The controller address
    // @returns The bytes associated with the encoded call
    // function encode_set_controller(uint256 controller) external pure returns (bytes memory result);

    // dev Encode 'rebond' relay call
    // Selector: add6b3bf
    // @param amount: The amount to rebond
    // @returns The bytes associated with the encoded call
    function encode_rebond(uint256 amount) external view returns (bytes memory result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Xtokens Interface
 *
 * The interface through which solidity contracts will interact with xtokens pallet
 *
 */
interface IxTokens {
    // A multilocation is defined by its number of parents and the encoded junctions (interior)
    struct Multilocation {
        uint8 parents;
        bytes [] interior;
    }

    /** Transfer a token through XCM based on its currencyId
     *
     * @dev The token transfer burns/transfers the corresponding amount before sending
     * @param currency_address The ERC20 address of the currency we want to transfer
     * @param amount The amount of tokens we want to transfer
     * @param destination The Multilocation to which we want to send the tokens
     * @param weight The weight we want to buy in the destination chain
     */
    function transfer(address currency_address, uint256 amount, Multilocation memory destination, uint64 weight) external;

    /** Transfer a token through XCM based on its currencyId
     *
     * @dev The token transfer burns/transfers the corresponding amount before sending
     * @param currency_address The ERC20 address of the currency we want to transfer
     * @param amount The amount of tokens we want to transfer
     * @param fee The amount of fees
     * @param destination The Multilocation to which we want to send the tokens
     * @param weight The weight we want to buy in the destination chain
     */
    function transfer_with_fee(address currency_address, uint256 amount, uint256 fee, Multilocation memory destination, uint64 weight) external;

    /** Transfer a token through XCM based on its currencyId
     *
     * @dev The token transfer burns/transfers the corresponding amount before sending
     * @param asset The asset we want to transfer, defined by its multilocation. Currently only Concrete Fungible assets
     * @param amount The amount of tokens we want to transfer
     * @param destination The Multilocation to which we want to send the tokens
     * @param weight The weight we want to buy in the destination chain
     */
    function transfer_multiasset(Multilocation memory asset, uint256 amount, Multilocation memory destination, uint64 weight) external;
}

// Function selector reference
// {
// "b9f813ff": "transfer(address,uint256,(uint8,bytes[]),uint64)",
// "b38c60fa": "transfer_multiasset((uint8,bytes[]),uint256,(uint8,bytes[]),uint64)"
//}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Xcm Transactor Interface
 *
 * The interface through which solidity contracts will interact with xcm transactor pallet
 *
 */
interface IXcmTransactor {
    // A multilocation is defined by its number of parents and the encoded junctions (interior)
    struct Multilocation {
        uint8 parents;
        bytes [] interior;
    }

    /** Get index of an account in xcm transactor
     *
     * @param index The index of which we want to retrieve the account
     */
    function index_to_account(uint16 index) external view returns(address);

    /** Get transact info of a multilocation
     * Selector 71b0edfa
     * @param multilocation The location for which we want to retrieve transact info
     */
    function transact_info(Multilocation memory multilocation)
        external view  returns(uint64, uint256, uint64, uint64, uint256);

    /** Transact through XCM using fee based on its multilocation
     *
     * @dev The token transfer burns/transfers the corresponding amount before sending
     * @param transactor The transactor to be used
     * @param index The index to be used
     * @param fee_asset The asset in which we want to pay fees.
     * It has to be a reserve of the destination chain
     * @param weight The weight we want to buy in the destination chain
     * @param inner_call The inner call to be executed in the destination chain
     */
    function transact_through_derivative_multilocation(
        uint8 transactor,
        uint16 index,
        Multilocation memory fee_asset,
        uint64 weight,
        bytes memory inner_call
    ) external;

    /** Transact through XCM using fee based on its currency_id
     *
     * @dev The token transfer burns/transfers the corresponding amount before sending
     * @param transactor The transactor to be used
     * @param index The index to be used
     * @param currency_id Address of the currencyId of the asset to be used for fees
     * It has to be a reserve of the destination chain
     * @param weight The weight we want to buy in the destination chain
     * @param inner_call The inner call to be executed in the destination chain
     */
    function transact_through_derivative(
        uint8 transactor,
        uint16 index,
        address currency_id,
        uint64 weight,
        bytes memory inner_call
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Types.sol";

interface ILedger {
    function initialize(
        bytes32 _stashAccount,
        bytes32 controllerAccount,
        address vKSM,
        address controller,
        uint128 minNominatorBalance,
        address lido,
        uint128 _minimumBalance,
        uint256 _maxUnlockingChunks
    ) external;

    function pushData(uint64 eraId, Types.OracleData calldata staking) external;

    function nominate(bytes32[] calldata validators) external;

    function status() external view returns (Types.LedgerStatus);

    function isEmpty() external view returns (bool);

    function stashAccount() external view returns (bytes32);

    function totalBalance() external view returns (uint128);

    function setRelaySpecs(uint128 minNominatorBalance, uint128 minimumBalance, uint256 _maxUnlockingChunks) external;

    function cachedTotalBalance() external view returns (uint128);

    function transferDownwardBalance() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Types {
    struct Fee{
        uint16 total;
        uint16 operators;
        uint16 developers;
        uint16 treasury;
    }

    struct Stash {
        bytes32 stashAccount;
        uint64  eraId;
    }

    enum LedgerStatus {
        // bonded but not participate in staking
        Idle,
        // participate as nominator
        Nominator,
        // participate as validator
        Validator,
        // not bonded not participate in staking
        None
    }

    struct UnlockingChunk {
        uint128 balance;
        uint64 era;
    }

    struct OracleData {
        bytes32 stashAccount;
        bytes32 controllerAccount;
        LedgerStatus stakeStatus;
        // active part of stash balance
        uint128 activeBalance;
        // locked for stake stash balance.
        uint128 totalBalance;
        // totalBalance = activeBalance + sum(unlocked.balance)
        UnlockingChunk[] unlocking;
        uint32[] claimedRewards;
        // stash account balance. It includes locked (totalBalance) balance assigned
        // to a controller.
        uint128 stashBalance;
        // slashing spans for ledger
        uint32 slashingSpans;
    }

    struct RelaySpec {
        uint16 maxValidatorsPerLedger;
        uint128 minNominatorBalance;
        uint128 ledgerMinimumActiveBalance;
        uint256 maxUnlockingChunks;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthManager {
    function has(bytes32 role, address member) external view returns (bool);

    function add(bytes32 role, address member) external;

    function remove(bytes32 role, address member) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Types.sol";

interface ILido {
    function MAX_ALLOWABLE_DIFFERENCE() external view returns(uint128);

    function deposit(uint256 amount) external returns (uint256);

    function distributeRewards(uint256 totalRewards, uint256 ledgerBalance) external;

    function distributeLosses(uint256 totalLosses, uint256 ledgerBalance) external;

    function getStashAccounts() external view returns (bytes32[] memory);

    function getLedgerAddresses() external view returns (address[] memory);

    function ledgerStake(address ledger) external view returns (uint256);

    function transferFromLedger(uint256 amount, uint256 excess) external;

    function transferFromLedger(uint256 amount) external;

    function transferToLedger(uint256 amount) external;

    function flushStakes() external;

    function findLedger(bytes32 stash) external view returns (address);

    function AUTH_MANAGER() external returns(address);

    function ORACLE_MASTER() external view returns (address);

    function decimals() external view returns (uint8);

    function getPooledKSMByShares(uint256 sharesAmount) external view returns (uint256);

    function getSharesByPooledKSM(uint256 amount) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Encoding {
    /**
    * @notice Converting uint256 value to le bytes
    * @param value - uint256 value
    * @param len - length of output bytes array
    */
    function toLeBytes(uint256 value, uint256 len) internal pure returns(bytes memory) {
        bytes memory out = new bytes(len);
        for (uint256 idx = 0; idx < len; ++idx) {
            out[idx] = bytes1(uint8(value));
            value = value >> 8;
        }
        return out;
    }

    /**
    * @notice Converting uint256 value to bytes
    * @param value - uint256 value
    */
    function scaleCompactUint(uint256 value) internal pure returns(bytes memory) {
        if (value < 1<<6) {
            return toLeBytes(value << 2, 1);
        }
        else if(value < 1 << 14) {
            return toLeBytes((value << 2) + 1, 2);
        }
        else if(value < 1 << 30) {
            return toLeBytes((value << 2) + 2, 4);
        }
        else {
            uint256 numBytes = 0;
            {
                uint256 m = value;
                for (; numBytes < 256 && m != 0; ++numBytes) {
                    m = m >> 8;
                }
            }

            bytes memory out = new bytes(numBytes + 1);
            out[0] = bytes1(uint8(((numBytes - 4) << 2) + 3));
            for (uint256 i = 0; i < numBytes; ++i) {
                out[i + 1] = bytes1(uint8(value & 0xFF));
                value = value >> 8;
            }
            return out;
        }
    }
}