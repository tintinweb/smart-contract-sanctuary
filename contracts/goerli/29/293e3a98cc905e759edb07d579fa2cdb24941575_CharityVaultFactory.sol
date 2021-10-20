/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/CharityVaultFactory.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.6 >=0.7.0 >=0.8.0 >=0.8.6 <0.9.0;

////// lib/solmate/src/auth/Auth.sol
/* pragma solidity >=0.7.0; */

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event AuthorityUpdated(Authority indexed authority);

    event OwnerUpdated(address indexed owner);

    /*///////////////////////////////////////////////////////////////
                       OWNER AND AUTHORITY STORAGE
    //////////////////////////////////////////////////////////////*/

    Authority public authority;

    address public owner;

    constructor(address newOwner) {
        owner = newOwner;

        emit OwnerUpdated(newOwner);
    }

    /*///////////////////////////////////////////////////////////////
                  OWNER AND AUTHORITY SETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) external requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(owner);
    }

    function setAuthority(Authority newAuthority) external requiresAuth {
        authority = newAuthority;

        emit AuthorityUpdated(authority);
    }

    /*///////////////////////////////////////////////////////////////
                        AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        }

        if (src == owner) {
            return true;
        }

        Authority _authority = authority;

        if (_authority == Authority(address(0))) {
            return false;
        }

        return _authority.canCall(src, address(this), sig);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
interface Authority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) external view returns (bool);
}

////// lib/solmate/src/erc20/ERC20.sol
/* pragma solidity >=0.8.0; */

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                         PERMIT/EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 public immutable DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 value) public virtual returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        balanceOf[msg.sender] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                          PERMIT/EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

        allowance[recoveredAddress][spender] = value;

        emit Approval(owner, spender, value);
    }

    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }
}

////// lib/solmate/src/erc20/SafeERC20.sol
/* pragma solidity >=0.8.0; */

/* import {ERC20} from "./ERC20.sol"; */

/// @notice Safe ERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
library SafeERC20 {
    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, value)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transfer.selector, to, value)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.approve.selector, to, value)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

////// lib/solmate/src/utils/Bytes32AddressLib.sol
/* pragma solidity 0.8.6; */

/// @notice Library for converting between addresses and bytes32 values.
/// @author Original work by Transmissions11 (https://github.com/transmissions11)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

////// lib/solmate/src/utils/FixedPointMathLib.sol
/* pragma solidity >=0.8.0; */

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Modified from Dappsys V2 (https://github.com/dapp-org/dappsys-v2/blob/main/src/math.sol)
/// and ABDK (https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        z = (x * y) / baseUnit;
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        z = (x * baseUnit) / y;
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        unchecked {
            assembly {
                switch x
                case 0 {
                    switch n
                    case 0 {
                        z := baseUnit
                    }
                    default {
                        z := 0
                    }
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := baseUnit
                    }
                    default {
                        z := x
                    }
                    let half := div(baseUnit, 2)
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, baseUnit)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, baseUnit)
                        }
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                          GENERAL NUMBER UTILS
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;

                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }

                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }

                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }

                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }

                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }

                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }

                if (xx >= 0x8) {
                    r <<= 1;
                }

                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;

                uint256 r1 = x / r;
                return (r < r1 ? r : r1);
            }
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }
}

////// lib/vaults/src/VaultFactory.sol
/* pragma solidity 0.8.6; */

/* import {Auth} from "solmate/auth/Auth.sol"; */
/* import {ERC20} from "solmate/erc20/ERC20.sol"; */
/* import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol"; */

/* import {Vault} from "./Vault.sol"; */

/// @title Rari Vault Factory
/// @author Transmissions11 + JetJadeja
/// @notice Factory which enables deploying a Vault contract for any ERC20 token.
contract VaultFactory is Auth(msg.sender) {
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when `deployVault` is called.
    /// @param underlying The underlying token used in the vault.
    /// @param vault The new vault deployed that accepts the underlying token.
    event VaultDeployed(ERC20 underlying, Vault vault);

    /*///////////////////////////////////////////////////////////////
                          VAULT DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy a new Vault contract that supports a specific underlying asset.
    /// @dev This will revert if a vault with the token has already been created.
    /// @param underlying Address of the ERC20 token that the Vault will earn yield on.
    /// @return vault The newly deployed Vault contract.
    function deployVault(ERC20 underlying) external returns (Vault vault) {
        // Use the create2 opcode to deploy a Vault contract.
        // This will revert if a vault with this underlying has already been
        // deployed, as the salt would be the same and we can't deploy with it twice.
        vault = new Vault{salt: address(underlying).fillLast12Bytes()}(underlying);

        emit VaultDeployed(underlying, vault);
    }

    /*///////////////////////////////////////////////////////////////
                            VAULT LOOKUP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Computes a Vault's address from its underlying token.
    /// @dev The Vault returned may not have been deployed yet.
    /// @param underlying The underlying ERC20 token the Vault earns yield on.
    /// @return The Vault that supports this underlying token.
    function getVaultFromUnderlying(ERC20 underlying) external view returns (Vault) {
        // Compute the create2 hash.
        bytes32 create2Hash = keccak256(
            abi.encodePacked(
                // Prefix:
                bytes1(0xFF),
                // Creator:
                address(this),
                // Salt:
                address(underlying).fillLast12Bytes(),
                // Bytecode hash:
                keccak256(
                    abi.encodePacked(
                        // Deployment bytecode:
                        type(Vault).creationCode,
                        // Constructor arguments:
                        abi.encode(underlying)
                    )
                )
            )
        );

        // Convert the create2 hash into a Vault address.
        return Vault(create2Hash.fromLast20Bytes());
    }

    /// @notice Returns if a vault at an address has been deployed yet.
    /// @dev This function is useful to check the return value of
    /// getVaultFromUnderlying, as it may return vaults that have not been deployed yet.
    /// @param vault The address of the vault that may not have been deployed.
    /// @return A bool indicated whether the vault has been deployed already.
    function isVaultDeployed(Vault vault) external view returns (bool) {
        return address(vault).code.length > 0;
    }
}

////// lib/vaults/src/external/Strategy.sol
/* pragma solidity 0.8.6; */

interface Strategy {
    function balanceOfUnderlying(address owner) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    // TODO: Maybe add underlying so we can check when entering a cToken that it accepts the right asset?
    // function underlying() external view returns (address);

    // TODO: Ether support
    // function mint() external payable returns (uint256);
    // function isCEther() external view returns (bool);
}

////// lib/vaults/src/Vault.sol
/* pragma solidity 0.8.6; */

/* import {Auth} from "solmate/auth/Auth.sol"; */
/* import {ERC20} from "solmate/erc20/ERC20.sol"; */
/* import {SafeERC20} from "solmate/erc20/SafeERC20.sol"; */
/* import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol"; */

/* import {Strategy} from "./external/Strategy.sol"; */
/* import {VaultFactory} from "./VaultFactory.sol"; */

/// @title Rari Vault (rvToken)
/// @author Transmissions11 + JetJadeja
/// @notice Minimalist yield aggregator designed to support any ERC20 token.
contract Vault is ERC20, Auth {
    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The underlying token for the Vault.
    ERC20 public immutable UNDERLYING;

    /// @notice One base unit of the underlying, and hence rvToken.
    /// @dev Will be equal to 10 ** UNDERLYING.decimals() which means
    /// if the token has 18 decimals ONE_WHOLE_UNIT will equal 10**18.
    uint256 public immutable BASE_UNIT;

    /// @notice Creates a new Vault that accepts a specific underlying token.
    /// @param _UNDERLYING An underlying ERC20-compliant token.
    constructor(ERC20 _UNDERLYING)
        ERC20(
            // ex: Rari DAI Vault
            string(abi.encodePacked("Rari ", _UNDERLYING.name(), " Vault")),
            // ex: rvDAI
            string(abi.encodePacked("rv", _UNDERLYING.symbol())),
            // ex: 18
            _UNDERLYING.decimals()
        )
        Auth(
            // Set the Vault's owner to
            // the VaultFactory's owner:
            VaultFactory(msg.sender).owner()
        )
    {
        UNDERLYING = _UNDERLYING;

        // TODO: Once we upgrade to 0.8.9 we can use 10**decimals
        // instead which will save us an external call and SLOAD.
        BASE_UNIT = 10**_UNDERLYING.decimals();
    }

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after a successful deposit.
    /// @param user The address that deposited into the Vault.
    /// @param underlyingAmount The amount of underlying tokens that were deposited.
    event Deposit(address indexed user, uint256 underlyingAmount);

    /// @notice Emitted after a successful withdrawal.
    /// @param user The address that withdrew from the Vault.
    /// @param underlyingAmount The amount of underlying tokens that were withdrawn.
    event Withdraw(address indexed user, uint256 underlyingAmount);

    /// @notice Emitted after a successful harvest.
    /// @param strategy The strategy that was harvested.
    /// @param lockedProfit The amount of locked profit after the harvest.
    event Harvest(Strategy indexed strategy, uint256 lockedProfit);

    /// @notice Emitted after the Vault deposits into a strategy contract.
    /// @param strategy The strategy that was deposited into.
    /// @param underlyingAmount The amount of underlying tokens that were deposited.
    event StrategyDeposit(Strategy indexed strategy, uint256 underlyingAmount);

    /// @notice Emitted after the Vault withdraws funds from a strategy contract.
    /// @param strategy The strategy that was withdrawn from.
    /// @param underlyingAmount The amount of underlying tokens that were withdrawn.
    event StrategyWithdrawal(Strategy indexed strategy, uint256 underlyingAmount);

    /// @notice Emitted when a strategy is set to trusted.
    /// @param strategy The strategy that became trusted.
    event StrategyTrusted(Strategy indexed strategy);

    /// @notice Emitted when a strategy is set to untrusted.
    /// @param strategy The strategy that became untrusted.
    event StrategyDistrusted(Strategy indexed strategy);

    /// @notice Emitted when the withdrawal queue is updated.
    /// @param updatedWithdrawalQueue The updated withdrawal queue.
    event WithdrawalQueueUpdated(Strategy[] updatedWithdrawalQueue);

    /*///////////////////////////////////////////////////////////////
                          STRATEGY STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The total amount of underlying tokens held in strategies at the time of the last harvest.
    /// @dev Includes maxLockedProfit, must be correctly subtracted to compute available/free holdings.
    uint256 public totalStrategyHoldings;

    /// @notice Maps strategies to the amount of underlying tokens they held last harvest.
    mapping(Strategy => uint256) public balanceOfStrategy;

    /// @notice Maps strategies to a boolean representing if the strategy is trusted.
    /// @dev A strategy must be trusted for harvest to be called with it.
    mapping(Strategy => bool) public isStrategyTrusted;

    /// @notice Store a strategy as trusted, enabling it to be harvested.
    /// @param strategy The strategy to make trusted.
    function trustStrategy(Strategy strategy) external requiresAuth {
        // We don't allow trusting again to prevent emitting a useless event.
        require(!isStrategyTrusted[strategy], "ALREADY_TRUSTED");

        // Store the strategy as trusted.
        isStrategyTrusted[strategy] = true;

        emit StrategyTrusted(strategy);
    }

    /// @notice Store a strategy as untrusted, disabling it from being harvested.
    /// @param strategy The strategy to make untrusted.
    function distrustStrategy(Strategy strategy) external requiresAuth {
        // We don't allow untrusting again to prevent emitting a useless event.
        require(isStrategyTrusted[strategy], "ALREADY_UNTRUSTED");

        // Store the strategy as untrusted.
        isStrategyTrusted[strategy] = false;

        emit StrategyDistrusted(strategy);
    }

    /*///////////////////////////////////////////////////////////////
                             HARVEST STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice A timestamp representing when the last harvest occurred.
    uint256 public lastHarvest;

    /// @notice The amount of locked profit at the end of the last harvest.
    uint256 public maxLockedProfit;

    /// @notice The approximate period in seconds over which locked profits are unlocked.
    /// @dev Defaults to 6 hours. Cannot be 0 as it opens harvests to sandwich attacks.
    uint256 public profitUnlockDelay = 6 hours;

    /// @notice Set a new profit unlock delay delay.
    /// @param newProfitUnlockDelay The new profit unlock delay.
    function setProfitUnlockDelay(uint256 newProfitUnlockDelay) external requiresAuth {
        // An unlock delay of 0 makes harvests vulnerable to sandwich attacks.
        require(profitUnlockDelay != 0, "DELAY_CANNOT_BE_ZERO");

        // Update the profit unlock delay.
        profitUnlockDelay = newProfitUnlockDelay;
    }

    /*///////////////////////////////////////////////////////////////
                      WITHDRAWAL QUEUE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice An ordered array of strategies representing the withdrawal queue.
    /// @dev The queue is processed in an ascending order, meaning the last index will be withdrawn from first.
    Strategy[] public withdrawalQueue;

    /// @notice Gets the full withdrawal queue.
    /// @return An ordered array of strategies representing the withdrawal queue.
    /// @dev This is provided because Solidity converts public arrays into index getters,
    /// but we need a way to allow external contracts and users to access the whole array.
    function getWithdrawalQueue() external view returns (Strategy[] memory) {
        return withdrawalQueue;
    }

    /// @notice Set a new withdrawal queue.
    /// @param newQueue The updated withdrawal queue.
    function setWithdrawalQueue(Strategy[] calldata newQueue) external requiresAuth {
        withdrawalQueue = newQueue;

        emit WithdrawalQueueUpdated(newQueue);
    }

    /// @notice Push a single strategy to front of the withdrawal queue.
    /// @param strategy The strategy to be inserted at the front of the withdrawal queue.
    function pushToWithdrawalQueue(Strategy strategy) external requiresAuth {
        // TODO: Optimize SLOADs?

        withdrawalQueue.push(strategy);

        emit WithdrawalQueueUpdated(withdrawalQueue);
    }

    /// @notice Remove the strategy at the tip of the withdrawal queue.
    /// @dev Be careful, another user could push a different strategy than
    /// expected to the queue while a popFromWithdrawalQueue transaction is pending.
    function popFromWithdrawalQueue() external requiresAuth {
        // TODO: Optimize SLOADs?

        withdrawalQueue.pop();

        emit WithdrawalQueueUpdated(withdrawalQueue);
    }

    /// @notice Move the strategy at the tip of the queue to the specified index and pop the tip off the queue.
    /// @dev The index specified must be less than current length of the withdrawal queue array.
    function replaceWithdrawalQueueIndexWithTip(uint256 index) external requiresAuth {
        // Ensure the index is actually in the withdrawal queue array.
        require(index < withdrawalQueue.length, "OUT_OF_BOUNDS");

        // Replace the index specified with the tip of the queue.
        withdrawalQueue[index] = withdrawalQueue[withdrawalQueue.length - 1];

        // Remove the now duplicated tip from the array.
        withdrawalQueue.pop();
    }

    /*///////////////////////////////////////////////////////////////
                       TARGET FLOAT CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice A percent value representing part of the total underlying to keep in the Vault.
    /// @dev A mantissa where 1e18 represents 100% and 0 represents 0%.
    uint256 public targetFloatPercent = 0.01e18;

    /// @notice Allows governance to set a new float size.
    /// @dev The new float size is a percentage mantissa scaled by 1e18.
    /// @param newTargetFloatPercent The new target float size.percent
    function setTargetFloatPercent(uint256 newTargetFloatPercent) external requiresAuth {
        // A target float percentage over 100% doesn't make sense.
        require(targetFloatPercent <= 1e18, "TARGET_TOO_HIGH");

        // Update the target float percentage.
        targetFloatPercent = newTargetFloatPercent;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit a specific amount of underlying tokens.
    /// @param underlyingAmount The amount of the underlying token to deposit.
    function deposit(uint256 underlyingAmount) external {
        // We don't allow depositing 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // Determine the equivalent amount of rvTokens and mint them.
        _mint(msg.sender, underlyingAmount.fdiv(exchangeRate(), BASE_UNIT));

        emit Deposit(msg.sender, underlyingAmount);

        // Transfer in underlying tokens from the user.
        UNDERLYING.safeTransferFrom(msg.sender, address(this), underlyingAmount);
    }

    /// @notice Withdraw a specific amount of underlying tokens.
    /// @param underlyingAmount The amount of underlying tokens to withdraw.
    function withdraw(uint256 underlyingAmount) external {
        // We don't allow withdrawing 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // Determine the equivalent amount of rvTokens and burn them.
        // This will revert if the user does not have enough rvTokens.
        _burn(msg.sender, underlyingAmount.fdiv(exchangeRate(), BASE_UNIT));

        emit Withdraw(msg.sender, underlyingAmount);

        // If the amount is greater than the float, withdraw from strategies.
        // TODO: Optimize double calls to totalFloat()? One is also done in totalHoldings.
        if (underlyingAmount > totalFloat()) {
            pullFromWithdrawalQueue(
                // The bare minimum we need for this withdrawal.
                (underlyingAmount - totalFloat()) +
                    // The amount needed to reach our target float percentage.
                    (totalHoldings() - underlyingAmount).fmul(targetFloatPercent, 1e18)
            );
        }

        // Transfer underlying tokens to the user.
        UNDERLYING.safeTransfer(msg.sender, underlyingAmount);
    }

    /// @notice Redeem a specific amount of rvTokens for underlying tokens.
    /// @param rvTokenAmount The amount of rvTokens to redeem for underlying tokens.
    function redeem(uint256 rvTokenAmount) external {
        // We don't allow redeeming 0 to prevent emitting a useless event.
        require(rvTokenAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // Determine the equivalent amount of underlying tokens.
        uint256 underlyingAmount = rvTokenAmount.fmul(exchangeRate(), BASE_UNIT);

        // Burn the provided rvTokens.
        // This will revert if the user does not have enough rvTokens.
        _burn(msg.sender, rvTokenAmount);

        emit Withdraw(msg.sender, underlyingAmount);

        // If the amount is greater than the float, withdraw from strategies.
        // TODO: Optimize double calls to totalFloat()? One is also done in totalHoldings.
        if (underlyingAmount > totalFloat()) {
            pullFromWithdrawalQueue(
                // The bare minimum we need for this withdrawal.
                (underlyingAmount - totalFloat()) +
                    // The amount needed to reach our target float percentage.
                    (totalHoldings() - underlyingAmount).fmul(targetFloatPercent, 1e18)
            );
        }

        // Transfer underlying tokens to the user.
        UNDERLYING.safeTransfer(msg.sender, underlyingAmount);
    }

    /*///////////////////////////////////////////////////////////////
                        VAULT ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns a user's Vault balance in underlying tokens.
    /// @return The user's Vault balance in underlying tokens.
    function balanceOfUnderlying(address account) external view returns (uint256) {
        return balanceOf[account].fmul(exchangeRate(), BASE_UNIT);
    }

    /// @notice Returns the amount of underlying tokens an rvToken can be redeemed for.
    /// @return The amount of underlying tokens an rvToken can be redeemed for.
    function exchangeRate() public view returns (uint256) {
        // If there are no rvTokens in circulation, return an exchange rate of 1:1.
        if (totalSupply == 0) return BASE_UNIT;

        // TODO: Optimize double SLOAD of totalSupply here?
        // Calculate the exchange rate by diving the total holdings by the rvToken supply.
        return totalHoldings().fdiv(totalSupply, BASE_UNIT);
    }

    /// @notice Calculate the total amount of tokens the Vault currently holds for depositors.
    /// @return The total amount of tokens the Vault currently holds for depositors.
    function totalHoldings() public view returns (uint256) {
        // Subtract locked profit from the amount of total deposited tokens and add the float value.
        // We subtract locked profit from totalStrategyHoldings because maxLockedProfit is baked into it.
        return totalFloat() + (totalStrategyHoldings - lockedProfit());
    }

    /// @notice Calculate the current amount of locked profit.
    /// @return The current amount of locked profit.
    function lockedProfit() public view returns (uint256) {
        // TODO: Cache SLOADs?
        return
            block.timestamp >= lastHarvest + profitUnlockDelay
                ? 0 // If profit unlock delay has passed, there is no locked profit.
                : maxLockedProfit - (maxLockedProfit * (block.timestamp - lastHarvest)) / profitUnlockDelay;
    }

    /// @notice Returns the amount of underlying tokens that idly sit in the Vault.
    /// @return The amount of underlying tokens that sit idly in the Vault.
    function totalFloat() public view returns (uint256) {
        return UNDERLYING.balanceOf(address(this));
    }

    /*///////////////////////////////////////////////////////////////
                             HARVEST LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Harvest a trusted strategy.
    /// @param strategy The trusted strategy to harvest.
    function harvest(Strategy strategy) external {
        // If an untrusted strategy could be harvested a malicious user could
        // construct a fake strategy that over-reports holdings to manipulate share price.
        require(isStrategyTrusted[strategy], "UNTRUSTED_STRATEGY");

        uint256 balanceLastHarvest = balanceOfStrategy[strategy];
        uint256 balanceThisHarvest = strategy.balanceOfUnderlying(address(this));

        // Update our stored balance for the strategy.
        balanceOfStrategy[strategy] = balanceThisHarvest;

        // Increase/decrease totalStrategyHoldings based on the profit/loss registered.
        // We cannot wrap the subtraction in parenthesis as it would underflow if the strategy had a loss.
        totalStrategyHoldings = totalStrategyHoldings + balanceThisHarvest - balanceLastHarvest;

        // Update maxLockedProfit to include any new profit.
        maxLockedProfit =
            lockedProfit() +
            (
                balanceThisHarvest > balanceLastHarvest
                    ? balanceThisHarvest - balanceLastHarvest // Profits since last harvest.
                    : 0 // If the strategy registered a net loss we don't have any new profit to lock.
            );

        // Set lastHarvest to the current timestamp.
        lastHarvest = block.timestamp;

        // TODO: Cache SLOAD here?
        emit Harvest(strategy, maxLockedProfit);
    }

    /*///////////////////////////////////////////////////////////////
                            REBALANCE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit a specific amount of float into a trusted strategy.
    /// @param strategy The trusted strategy to deposit into.
    /// @param underlyingAmount The amount of underlying tokens in float to deposit.
    function depositIntoStrategy(Strategy strategy, uint256 underlyingAmount) external requiresAuth {
        // A strategy must be trusted before it can be deposited into.
        require(isStrategyTrusted[strategy], "UNTRUSTED_STRATEGY");

        // We don't allow exiting 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // Without this the next harvest would count the deposit as profit.
        balanceOfStrategy[strategy] += underlyingAmount;

        // Increase totalStrategyHoldings to account for the deposit.
        totalStrategyHoldings += underlyingAmount;

        emit StrategyDeposit(strategy, underlyingAmount);

        // Approve underlyingAmount to the strategy so we can deposit.
        UNDERLYING.safeApprove(address(strategy), underlyingAmount);

        // Deposit into the strategy and revert if returns an error code.
        require(strategy.mint(underlyingAmount) == 0, "MINT_FAILED");
    }

    /// @notice Withdraw a specific amount of underlying tokens from a strategy.
    /// @param strategy The strategy to withdraw from.
    /// @param underlyingAmount  The amount of underlying tokens to withdraw.
    /// @dev Withdrawing from a strategy will not remove it from the withdrawal queue.
    function withdrawFromStrategy(Strategy strategy, uint256 underlyingAmount) external requiresAuth {
        // We don't allow exiting 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // Without this the next harvest would count the withdrawal as a loss.
        balanceOfStrategy[strategy] -= underlyingAmount;

        // Decrease totalStrategyHoldings to account for the withdrawal.
        totalStrategyHoldings -= underlyingAmount;

        emit StrategyWithdrawal(strategy, underlyingAmount);

        // Withdraw from the strategy and revert if returns an error code.
        require(strategy.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                       STRATEGY WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Withdraw a specific amount of underlying tokens from strategies in the withdrawal queue.
    /// @param underlyingAmount The amount of underlying tokens to pull into float.
    /// @dev Automatically removes depleted strategies from the withdrawal queue.
    function pullFromWithdrawalQueue(uint256 underlyingAmount) internal {
        // TODO: Cache variables to optimize SLOADs.

        // We will update this variable as we pull from strategies.
        uint256 amountLeftToPull = underlyingAmount;

        // Store the starting index which is at the tip of the queue.
        uint256 startingIndex = withdrawalQueue.length - 1;

        // We will use this after the loop to check how many strategies we withdrew from.
        uint256 currentIndex = startingIndex;

        // Iterate in reverse as the withdrawalQueue is sorted in ascending order.
        for (; currentIndex >= 0; currentIndex--) {
            // Get the strategy at the current queue index.
            Strategy strategy = withdrawalQueue[currentIndex];

            // We want to pull as much as we can from the strategy, but no more than we need.
            uint256 amountToPull = FixedPointMathLib.min(amountLeftToPull, balanceOfStrategy[strategy]);

            // Without this the next harvest would count the withdrawal as a loss.
            balanceOfStrategy[strategy] -= amountToPull;

            // Adjust our goal based on how much we're able to pull from the strategy.
            amountLeftToPull -= amountToPull;

            // Withdraw from the strategy and revert if returns an error code.
            require(strategy.redeemUnderlying(amountToPull) == 0, "REDEEM_FAILED");

            emit StrategyWithdrawal(strategy, amountToPull);

            // If we depleted the strategy, remove it from the queue.
            if (balanceOfStrategy[strategy] == 0) withdrawalQueue.pop();

            // If we've pulled all we need, exit the loop.
            if (amountLeftToPull == 0) break;
        }

        // Revert if we weren't able to pull the desired amount.
        require(amountLeftToPull == 0, "NOT_ENOUGH_IN_QUEUE");

        // Decrease totalStrategyHoldings to account for the withdrawals.
        totalStrategyHoldings -= underlyingAmount;

        // If we went beyond the starting index, at least one item on the queue was popped.
        if (currentIndex != startingIndex) emit WithdrawalQueueUpdated(withdrawalQueue);
    }
}

////// src/CharityVaultFactory.sol
/* pragma solidity ^0.8.6; */

/* import {Auth} from "solmate/auth/Auth.sol"; */
/* import {ERC20} from "solmate/erc20/ERC20.sol"; */
/* import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol"; */
/* import {VaultFactory} from "vaults/VaultFactory.sol"; */

/* import {CharityVault} from "./CharityVault.sol"; */

/// @title Fuse Charity Vault Factory
/// @author Transmissions11, JetJadeja, Andreas Bigger
/// @notice Charity wrapper for vaults/VaultFactory.
contract CharityVaultFactory is Auth(msg.sender) {
    using Bytes32AddressLib for *;

    /// @dev we need to store a vaultFactory to fetch existing Vaults
    /// @dev immutable instead of constant so we can set VAULT_FACTORY in the constructor
    // solhint-disable-next-line var-name-mixedcase
    VaultFactory private immutable VAULT_FACTORY;

    /// @notice Creates a new CharityVaultFactory
    /// @param _address the address of the VaultFactory
    constructor(address _address) {
        VAULT_FACTORY = VaultFactory(_address);
    }

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when `deployCharityVault` is called.
    /// @param underlying The underlying token used in the vault.
    /// @param vault The new charity vault deployed that accepts the underlying token.
    event CharityVaultDeployed(ERC20 underlying, CharityVault vault);

    /*///////////////////////////////////////////////////////////////
                           STATEFUL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy a new CharityVault contract that supports a specific underlying asset.
    /// @dev This will revert if a vault with the token has already been created.
    /// @param underlying Address of the ERC20 token that the Vault will earn yield on.
    /// @param charity donation address
    /// @param feePercent percent of earned interest sent to the charity as a donation
    /// @return cvault The newly deployed CharityVault contract.
    function deployCharityVault(
        ERC20 underlying,
        address payable charity,
        uint256 feePercent
    ) external returns (CharityVault cvault) {
        // Use the create2 opcode to deploy a CharityVault contract.
        // This will revert if a vault with this underlying has already been
        // deployed, as the salt would be the same and we can't deploy with it twice.
        cvault = new CharityVault{ // Compute Inline CharityVault Salt, h/t @t11s
            salt: keccak256(
                abi.encode(
                    address(underlying).fillLast12Bytes(),
                    charity,
                    feePercent
                    // address(VAULT_FACTORY.getVaultFromUnderlying(underlying))
                )
            )
        }(
            underlying,
            charity,
            feePercent,
            VAULT_FACTORY.getVaultFromUnderlying(underlying)
        );

        emit CharityVaultDeployed(underlying, cvault);
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Computes a CharityVault's address from its underlying token, donation address, and fee percent.
    /// @dev The CharityVault returned may not have been deployed yet.
    /// @param underlying The underlying ERC20 token the CharityVault earns yield on.
    /// @param charity donation address
    /// @param feePercent percent of earned interest sent to the charity as a donation
    /// @return The CharityVault that supports this underlying token.
    function getCharityVaultFromUnderlying(
        ERC20 underlying,
        address payable charity,
        uint256 feePercent
    ) external view returns (CharityVault) {
        // Convert the create2 hash into a CharityVault.
        return
            CharityVault(
                payable(
                    keccak256(
                        abi.encodePacked(
                            // Prefix:
                            bytes1(0xFF),
                            // Creator:
                            address(this),
                            // Compute Inline CharityVault Salt, h/t @t11s
                            keccak256(
                                abi.encode(
                                    address(underlying).fillLast12Bytes(),
                                    charity,
                                    feePercent
                                )
                            ),
                            // Bytecode hash:
                            keccak256(
                                abi.encodePacked(
                                    // Deployment bytecode:
                                    type(CharityVault).creationCode,
                                    // Constructor arguments:
                                    abi.encode(
                                        underlying,
                                        charity,
                                        feePercent,
                                        VAULT_FACTORY.getVaultFromUnderlying(
                                            underlying
                                        )
                                    )
                                )
                            )
                        )
                    ).fromLast20Bytes()
                )
            );
    }

    /// @notice Returns if a charity vault at an address has been deployed yet.
    /// @dev This function is useful to check the return value of
    /// getCharityVaultFromUnderlying, as it may return vaults that have not been deployed yet.
    /// @param cvault The address of the charity vault that may not have been deployed.
    /// @return A bool indicated whether the charity vault has been deployed already.
    function isCharityVaultDeployed(CharityVault cvault)
        external
        view
        returns (bool)
    {
        return address(cvault).code.length > 0;
    }
}

////// src/CharityVault.sol
/* pragma solidity 0.8.6; */

/* import {ERC20} from "solmate/erc20/ERC20.sol"; */
/* import {Auth} from "solmate/auth/Auth.sol"; */
/* import {SafeERC20} from "solmate/erc20/SafeERC20.sol"; */
/* import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol"; */
/* import {Vault} from "vaults/Vault.sol"; */

/* import {CharityVaultFactory} from "./CharityVaultFactory.sol"; */

/// @title Fuse Charity Vault (fcvToken)
/// @author Transmissions11, JetJadeja, Andreas Bigger, Nicolas Neven, Adam Egyed
/// @notice Yield bearing token that enables users to swap
/// their underlying asset to instantly begin earning yield
/// where a percent of the earned interest is sent to charity.
contract CharityVault is ERC20, Auth {
    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev we need to compose a Vault here because the Vault functions are external
    /// @dev which are not able to be overridden since that requires public virtual specifiers
    /// @dev immutable instead of constant so we can set VAULT in the constructor
    // solhint-disable-next-line var-name-mixedcase
    Vault private immutable VAULT;

    /// @notice The underlying token for the vault.
    /// @dev immutable instead of constant so we can set UNDERLYING in the constructor
    // solhint-disable-next-line var-name-mixedcase
    ERC20 public immutable UNDERLYING;

    /// @notice the charity's payable donation address
    /// @dev immutable instead of constant so we can set CHARITY in the constructor
    // solhint-disable-next-line var-name-mixedcase
    address payable public immutable CHARITY;

    /// @notice the percent of the earned interest that should be redirected to the charity
    /// @dev immutable instead of constant so we can set BASE_FEE in the constructor
    // solhint-disable-next-line var-name-mixedcase
    uint256 public immutable BASE_FEE;

    /// @notice One base unit of the underlying, and hence rvToken.
    /// @dev Will be equal to 10 ** UNDERLYING.decimals() which means
    /// if the token has 18 decimals ONE_WHOLE_UNIT will equal 10**18.
    // solhint-disable-next-line var-name-mixedcase
    uint256 public immutable BASE_UNIT;

    /// @notice Price per share of rvTokens earned at the last extraction
    uint256 private pricePerShareAtLastExtraction;

    /// @notice accumulated rvTokens earned by the Charity
    uint256 private rvTokensEarnedByCharity;

    /// @notice rvTokens claimed by the Charity
    uint256 private rvTokensClaimedByCharity;

    /// @notice Creates a new charity vault based on an underlying token.
    /// @param _UNDERLYING An underlying ERC20 compliant token.
    /// @param _CHARITY The address of the charity
    /// @param _BASE_FEE The percent of earned interest to be routed to the Charity
    /// @param _VAULT The existing/deployed Vault for the respective underlying token
    constructor(
        // solhint-disable-next-line var-name-mixedcase
        ERC20 _UNDERLYING,
        // solhint-disable-next-line var-name-mixedcase
        address payable _CHARITY,
        // solhint-disable-next-line var-name-mixedcase
        uint256 _BASE_FEE,
        // solhint-disable-next-line var-name-mixedcase
        Vault _VAULT
    )
        ERC20(
            // ex: Rari DAI Charity Vault
            string(
                abi.encodePacked("Rari ", _UNDERLYING.name(), " Charity Vault")
            ),
            // ex: rcvDAI
            string(abi.encodePacked("rcv", _UNDERLYING.symbol())),
            // ex: 18
            _UNDERLYING.decimals()
        )
        Auth(
            // Set the CharityVault's owner to the CharityVaultFactory's owner:
            CharityVaultFactory(msg.sender).owner()
        )
    {
        // Enforce BASE_FEE
        require(
            _BASE_FEE >= 0 && _BASE_FEE <= 100,
            "Fee Percent fails to meet [0, 100] bounds constraint."
        );

        // Define our immutables
        UNDERLYING = _UNDERLYING;
        CHARITY = _CHARITY;
        BASE_FEE = _BASE_FEE;
        VAULT = _VAULT;

        // TODO: Once we upgrade to 0.8.9 we can use 10**decimals
        // instead which will save us an external call and SLOAD.
        BASE_UNIT = 10**_UNDERLYING.decimals();
    }

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after a successful deposit.
    /// @param user The address of the account that deposited into the vault.
    /// @param underlyingAmount The amount of underlying tokens that were deposited.
    event DepositCV(address indexed user, uint256 underlyingAmount);

    /// @notice Emitted after a successful user withdrawal.
    /// @param user The address of the account that withdrew from the vault.
    /// @param underlyingAmount The amount of underlying tokens that were withdrawn.
    event WithdrawCV(address indexed user, uint256 underlyingAmount);

    /// @notice Emitted when a Charity successfully withdraws their fee percent of earned interest.
    /// @param charity the address of the charity that withdrew - used primarily for indexing
    /// @param underlyingAmount The amount of underlying tokens that were withdrawn.
    event CharityWithdrawCV(address indexed charity, uint256 underlyingAmount);

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit the vault's underlying token to mint rcvTokens.
    /// @param underlyingAmount The amount of the underlying token to deposit.
    function deposit(uint256 underlyingAmount) external {
        // We don't allow depositing 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // Extract interest to charity
        extractInterestToCharity();

        // Determine the equivalent amount of rvTokens that will be minted to this charity vault.
        uint256 rvTokensToMint = underlyingAmount.fdiv(
            VAULT.exchangeRate(),
            BASE_UNIT
        );
        _mint(
            msg.sender,
            rvTokensToMint.fdiv(rcvRvExchangeRateAtLastExtraction(), BASE_UNIT)
        );
        emit DepositCV(msg.sender, underlyingAmount);

        // Transfer in UNDERLYING tokens from the sender to the vault
        UNDERLYING.safeTransferFrom(
            msg.sender,
            address(this),
            underlyingAmount
        );

        // Deposit to the VAULT
        VAULT.deposit(underlyingAmount);
    }

    // Returns the total holdings of rvTokens at the time of the last extraction.
    function rvTokensOwnedByUsersAtLastExtraction()
        internal
        view
        returns (uint256)
    {
        return (VAULT.balanceOf(address(this)) -
            (rvTokensEarnedByCharity - rvTokensClaimedByCharity));
    }

    /// @dev Extracts and withdraws unclaimed interest earned by charity.
    function withdrawInterestToCharity() external {
        extractInterestToCharity();
        uint256 rvTokensToClaim = rvTokensEarnedByCharity -
            rvTokensClaimedByCharity;
        rvTokensClaimedByCharity = rvTokensEarnedByCharity;
        VAULT.transfer(CHARITY, rvTokensToClaim);
    }

    /// @notice returns the rvTokens owned by a user
    function rvTokensOwnedByUser(address user) public view returns (uint256) {
        uint256 pricePerShareNow = VAULT.exchangeRate();

        uint256 underlyingEarnedByUsersSinceLastExtraction = (VAULT.balanceOf(
            address(this)
        ) - (rvTokensEarnedByCharity - rvTokensClaimedByCharity)) *
            (pricePerShareNow - pricePerShareAtLastExtraction);
        uint256 underlyingToUser = ((underlyingEarnedByUsersSinceLastExtraction *
                this.balanceOf(user)) / totalSupply) / 100;
        uint256 rcvTokensToUser = underlyingToUser.fdiv(
            pricePerShareNow,
            VAULT.BASE_UNIT()
        );

        return rcvTokensToUser;
    }

    /// @notice Withdraws a user's interest earned from the vault.
    /// @param withdrawalAmount The amount of the underlying token to withdraw.
    function withdraw(uint256 withdrawalAmount) external {
        // We don't allow withdrawing 0 to prevent emitting a useless event.
        require(withdrawalAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // First extract interest to charity
        extractInterestToCharity();

        // Determine the equivalent amount of rcvTokens and burn them.
        // This will revert if the user does not have enough rcvTokens.
        _burn(
            msg.sender,
            withdrawalAmount.fdiv(VAULT.exchangeRate(), BASE_UNIT)
        );

        uint256 rvTokensToUser = rvTokensOwnedByUser(msg.sender);

        require(rvTokensToUser >= withdrawalAmount, "INSUFFICIENT_FUNDS");

        // Try to transfer balance to msg.sender
        VAULT.transfer(msg.sender, withdrawalAmount);
    }

    /*///////////////////////////////////////////////////////////////
                        VAULT ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Do this before user deposits, user withdrawals, and charity withdrawals.
    function extractInterestToCharity() internal {
        uint256 pricePerShareNow = VAULT.exchangeRate();

        if (pricePerShareAtLastExtraction == 0) {
            pricePerShareAtLastExtraction = pricePerShareNow;
            return;
        }

        uint256 underlyingEarnedByUsersSinceLastExtraction = (VAULT.balanceOf(
            address(this)
        ) - (rvTokensEarnedByCharity - rvTokensClaimedByCharity)) *
            (pricePerShareNow - pricePerShareAtLastExtraction);
        uint256 underlyingToCharity = (underlyingEarnedByUsersSinceLastExtraction *
                BASE_FEE) / 100;
        uint256 rvTokensToCharity = underlyingToCharity.fdiv(
            pricePerShareNow,
            VAULT.BASE_UNIT()
        );
        pricePerShareAtLastExtraction = pricePerShareNow;
        rvTokensEarnedByCharity += rvTokensToCharity;
    }

    // Returns the exchange rate of rcvTokens in terms of rvTokens since the last extraction.
    function rcvRvExchangeRateAtLastExtraction()
        internal
        view
        returns (uint256)
    {
        // If there are no rvTokens in circulation, return an exchange rate of 1:1.
        if (totalSupply == 0) return BASE_UNIT;

        // TODO: Optimize double SLOAD of totalSupply here?
        // Calculate the exchange rate by diving the total holdings by the rvToken supply.
        return
            rvTokensOwnedByUsersAtLastExtraction().fdiv(totalSupply, BASE_UNIT);
    }
}