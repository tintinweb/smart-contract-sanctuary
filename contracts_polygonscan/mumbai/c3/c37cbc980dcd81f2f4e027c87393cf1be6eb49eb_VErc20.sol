/**
 *Submitted for verification at polygonscan.com on 2021-07-01
*/

// SPDX-License-Identifier:MIT
// produced by the Solididy File Flattener (c) David Appleton 2018 - 2020 and beyond
// contact : [email protected]
// source  : https://github.com/DaveAppleton/SolidityFlattery
// released under Apache 2.0 licence
// input  /Users/chris/Git/vestollc/vesto-contracts/src/erc20/VErc20.sol
// flattened :  Thursday, 01-Jul-21 21:10:10 UTC
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IErc20 {
    function totalSupply(
    ) external view returns (uint256);

    function balanceOf(
        address who
    ) external view returns (uint256);

    function decimals(
    ) external pure returns (uint8);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address to,
        uint256 value
    ) external returns (bool);

    function approve(
        address spender,
        uint256 value
    ) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function symbol(
    ) external view returns (string memory);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library LString {

    function isEmpty(
        string memory value
    ) internal pure returns (bool) {
        return bytes(value).length == 0 ? true : false;
    }

    function compare(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    /**
     * Upper
     *
     * Converts all the values of a string to their corresponding upper case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string
     */
    function upper(
        string memory _base
    ) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
    * Upper
    *
    *  Convert an alphabetic character to upper case and return the original
    * value when not alphabetic
    *
    * @param _b1 The byte to be converted to upper case
    * @return bytes1 The converted value if the passed value was alphabetic
    *                and in a lower case otherwise returns the original value
    */
    function _upper(
        bytes1 _b1
    ) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }
        return _b1;
    }
}
interface IStorage {

    enum Role { USER, ADMIN, SUPER_ADMIN }

    struct User {
        string id;
        string institutionId;
        address userAddress;
        address recoveryAddress;
        Role role;
        uint256 dailyLimit;
        bytes data;
    }

    struct Exchange {
        uint256 apy;
        uint256 rate;
        uint256 stamp;
    }

    struct Element {
        bytes32 poolId;
        address trancheAddress;
        address poolAddress;
        address underlyingAddress;
        uint256 apy;
    }

    struct Withdrawal {
        uint256 amount;
        uint256 stamp;
    }
}
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IRootChainManager {
    event TokenMapped(
        address indexed rootToken,
        address indexed childToken,
        bytes32 indexed tokenType
    );

    event PredicateRegistered(
        bytes32 indexed tokenType,
        address indexed predicateAddress
    );

    function registerPredicate(bytes32 tokenType, address predicateAddress)
    external;

    function mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function cleanMapToken(
        address rootToken,
        address childToken
    ) external;

    function remapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function exit(bytes calldata inputData) external;
}
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}
interface IRecovery {

    function swapUserAddress(
        string memory _userId,
        address _userAddress,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;
}
interface IVault {

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }


    /**
    * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
    * `recipient` account.
    *
    * If the caller is not `sender`, it must be an authorized relayer for them.
    *
    * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
    * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
    * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
    * `joinPool`.
    *
    * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
    * transferred. This matches the behavior of `exitPool`.
    *
    * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
    * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    /**
    * @dev Performs a swap with a single Pool.
    *
    * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
    * taken from the Pool, which must be greater than or equal to `limit`.
    *
    * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
    * sent to the Pool, which must be less than or equal to `limit`.
    *
    * Internal Balance usage and the recipient are determined by the `funds` struct.
    *
    * Emits a `Swap` event.
    */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
    * @dev Emitted when a Pool is registered by calling `registerPool`.
    */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }
}
abstract contract AStorage is IStorage {

    mapping(bytes32 => uint256) internal uint256Storage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => address[]) internal addressArrayStorage;
    mapping(bytes32 => bytes32) internal bytes32Storage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
    mapping(bytes32 => Exchange) internal exchangeStorage;
    mapping(bytes32 => Element) internal elementStorage;
    mapping(bytes32 => Element[]) internal elementArrayStorage;
    mapping(bytes32 => mapping(bytes32 => Withdrawal[])) internal bytes32ToWithdrawalArrayStorage;
    mapping(bytes32 => mapping(bytes32 => User)) internal bytes32ToUserStorage;
    mapping(bytes32 => mapping(bytes32 => uint256)) internal bytes32ToUnitStorage;
    mapping(bytes32 => mapping(address => uint256)) internal addressToUnitStorage;
    mapping(bytes32 => mapping(address => bool)) internal addressToBoolStorage;
    mapping(bytes32 => mapping(address => address)) internal addressToAddressStorage;
    mapping(bytes32 => mapping(bytes32 => bool)) internal bytes32ToBoolStorage;
    mapping(bytes32 => mapping(bytes32 => address)) internal bytes32ToAddressStorage;
    mapping(bytes32 => mapping(address => bytes32)) internal addressToBytes32Storage;
    mapping(bytes32 => mapping(address => string)) internal addressToStringStorage;
    mapping(bytes32 => mapping(address => mapping(address => uint256))) internal addressToAddressToUnitStorage;
    mapping(bytes32 => mapping(address => mapping(address => bool))) internal addressToAddressToBoolStorage;
    mapping(bytes32 => mapping(bytes32 => mapping(address => bool))) internal bytes32ToAddressToBoolStorage;
    mapping(bytes32 => mapping(address => mapping(bytes32 => bool))) internal addressToBytes32ToBoolStorage;

    // Storage keys.
    bytes32 constant USER_ID = keccak256(abi.encodePacked("USER_ID"));
    bytes32 constant USER = keccak256(abi.encodePacked("USER"));
    bytes32 constant ADDRESS_TO_USER_ID = keccak256(abi.encodePacked("ADDRESS_TO_USER_ID"));
    bytes32 constant VLIGHTHOUSE_ADDRESS = keccak256(abi.encodePacked("VLIGHTHOUSE_ADDRESS"));
    bytes32 constant VLIGHTHOUSE_PROXY_ADDRESS = keccak256(abi.encodePacked("VLIGHTHOUSE_PROXY_ADDRESS"));
    bytes32 constant VFINANCE_ADDRESS = keccak256(abi.encodePacked("VFINANCE_ADDRESS"));
    bytes32 constant VFINANCE_PROXY_ADDRESS = keccak256(abi.encodePacked("VFINANCE_PROXY_ADDRESS"));
    bytes32 constant VERC20_ADDRESS = keccak256(abi.encodePacked("VERC20_ADDRESS"));
    bytes32 constant VERC20_PROXY_ADDRESSES = keccak256(abi.encodePacked("VERC20_PROXY_ADDRESSES"));
    bytes32 constant VWALLET_ADDRESS = keccak256(abi.encodePacked("VWALLET_ADDRESS"));
    bytes32 constant VWALLET_PROXY_ADDRESSES = keccak256(abi.encodePacked("VWALLET_PROXY_ADDRESSES"));
    bytes32 constant IMPLEMENTATION_ADDRESS_KEY = keccak256(abi.encodePacked("IMPLEMENTATION_ADDRESS_KEY"));
    bytes32 constant VADDRESS = keccak256(abi.encodePacked("VADDRESS"));
    bytes32 constant WITHDRAWALS = keccak256(abi.encodePacked("WITHDRAWALS"));
    bytes32 constant NAME = keccak256(abi.encodePacked("NAME"));
    bytes32 constant SYMBOL = keccak256(abi.encodePacked("SYMBOL"));
    bytes32 constant UNDERLYING_ADDRESS = keccak256(abi.encodePacked("UNDERLYING_ADDRESS"));
    bytes32 constant REDEEM_ADDRESSES = keccak256(abi.encodePacked("REDEEM_ADDRESSES"));
    bytes32 constant SUPPLY = keccak256(abi.encodePacked("SUPPLY"));
    bytes32 constant BALANCES = keccak256(abi.encodePacked("BALANCES"));
    bytes32 constant INSTITUTION_BALANCES = keccak256(abi.encodePacked("INSTITUTION_BALANCES"));
    bytes32 constant ALLOWANCES = keccak256(abi.encodePacked("ALLOWANCES"));
    bytes32 constant NONCES = keccak256(abi.encodePacked(abi.encodePacked("NONCES")));
    bytes32 constant USDC_ADDRESS = keccak256(abi.encodePacked("USDC_ADDRESS"));
    bytes32 constant DAI_ADDRESS = keccak256(abi.encodePacked("DAI_ADDRESS"));
    bytes32 constant CHAIN_ID = keccak256(abi.encodePacked("CHAIN_ID"));
    bytes32 constant ERC20_PREDICATE_PROXY_ADDRESS = keccak256(abi.encodePacked("ERC20_PREDICATE_PROXY_ADDRESS"));
    bytes32 constant ROOT_CHAIN_MANAGER_PROXY_ADDRESS = keccak256(abi.encodePacked("ROOT_CHAIN_MANAGER_PROXY_ADDRESS"));
    bytes32 constant CHILD_CHAIN_MANAGER_PROXY_ADDRESS = keccak256(abi.encodePacked("CHILD_CHAIN_MANAGER_PROXY_ADDRESS"));
    bytes32 constant BALANCER_VAULT_ADDRESS = keccak256(abi.encodePacked("BALANCER_VAULT_ADDRESS"));
    bytes32 constant DISTRIBUTION_ADDRESS = keccak256(abi.encodePacked("DISTRIBUTION_ADDRESS"));
    bytes32 constant VFEE_PAYOUT_ADDRESS = keccak256(abi.encodePacked("VFEE_PAYOUT_ADDRESS"));
    bytes32 constant FEE_PAYOUT_ADDRESSES = keccak256(abi.encodePacked("FEE_PAYOUT_ADDRESSES"));

    function key(
        string memory _key
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_key));
    }
}
interface IBase is IStorage {

    function name(
    ) external view returns (string memory);

    function version(
    ) external pure returns (string memory);

    function user(
    ) external view returns (IStorage.User memory);

    function vAddress(
    ) external view returns (address);
}
interface IVErc20 is IBase, IErc20 {

    function underlying(
    ) external view returns (IErc20);

    function balancesOf(
       address who
    ) external view returns (uint256, uint256);

    function totalBalances(
    ) external view returns (uint256, uint256);

    function faucet(
    ) external;

    function mint(
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function redeem(
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function deposit(
        address who,
        bytes calldata depositData
    ) external;

    function withdraw(
        uint256 amount
    ) external;

    function exchangeRate(
    ) external view returns (uint256);

    event Minted(
        uint256 tokens,
        uint256 underlyingTokens
    );

    event Redeemed(
        uint256 tokens,
        uint256 underlyingTokens
    );
}
interface IVLighthouse is IBase, IRecovery {

    function chainId(
    ) external view returns (uint256);

    function userById(
        string memory id
    ) external view returns (IStorage.User memory);

    function userByAddress(
        address _address
    ) external view returns (IStorage.User memory);

    function addUser(
        string memory id,
        string memory _institutionId,
        address _userAddress,
        address _recoveryAddress,
        uint256 _dailyLimit,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

//    function setRecoveryAddress(
//        string memory userId,
//        address _recoveryAddress,
//        string memory nonce,
//        uint8[] memory V,
//        bytes32[] memory R,
//        bytes32[] memory S
//    ) external;

    function addressByKey(
        bytes32 _key
    ) external view returns (address);

    function redeemAddress(
        string memory symbol
    ) external view returns (address);

    function feePayoutAddress(
        string memory institutionId
    ) external view returns (address);

    function synchronize(
        bytes32[] memory keys,
        address[] memory addresses,
        string[] memory payoutInstitutionIds,
        address[] memory payoutAddresses,
        string[] memory redeemSymbols,
        address[] memory redeemAddresses,
        address[] memory vErc20Addresses,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function setVAddress(
        address _address,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function isVErc20(
        address _address
    ) external view returns (bool);

    function addVWalletProxyAddress(
        address _address,
        string memory userId,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function isVWallet(
        address _address
    ) external view returns (bool);

    function exchange(
        string memory symbol
    ) external view returns (IStorage.Exchange memory);

    function incrementExchanges(
        string[] memory symbols,
        uint256[] memory apys,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function isWithinDailyLimit(
        string memory userId,
        uint256 amount
    ) external;

    function setDailyLimit(
        string memory userId,
        uint256 _dailyLimit,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    event ExchangesIncremented(
        uint256[] rates
    );
}
interface IVFinance is IBase {

    function balanceOf(
        IErc20 iErc20
    ) external view returns (uint256);

    function mint(
        uint256 underlyingTokens
    ) external;

    function redeem(
        uint256 tokens
    ) external returns (uint256, uint256);

    function drain(
        IErc20 iErc20,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function element(
        bytes32 _key
    ) external view returns (IStorage.Element memory);

    function deployElement(
        bytes32 _key,
        address trancheAddress,
        bytes32 poolId,
        address underlyingAddress,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;
}
abstract contract ABase is IBase, AStorage {

    using SafeMath for uint256;

    uint256 constant ETHEREUM_MAINNET = 1;
    uint256 constant ETHEREUM_GOERLI = 5;
    uint256 constant ETHEREUM_KOVAN = 42;
    uint256 constant POLYGON_MAINNET = 137;
    uint256 constant POLYGON_MUMBAI = 80001;
    uint256 constant SUPER_ADMIN_SIGNATURES_REQUIRED = 1;

    struct Signatures {
        string nonce;
        bytes32 hash;
        uint8[] V;
        bytes32[] R;
        bytes32[] S;
    }

    function version(
    ) override public pure returns (string memory) {
        return "Lime Kiln";
    }

    function user(
    ) override public view returns (User memory) {
        return vLighthouse().userById(stringStorage[USER_ID]);
    }

    function vLighthouse(
    ) internal view returns (IVLighthouse) {
        return IVLighthouse(addressStorage[VLIGHTHOUSE_PROXY_ADDRESS]);
    }

    modifier onlyUser(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsUserAddress(addresses) && containsVAddress(addresses), "VBase::onlyUser - must include user's and Vesto's signatures");
        _;
    }

    modifier onlyRecovery(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsRecoveryAddress(addresses) && containsUserAddress(addresses), "VBase::onlyRecovery - must include recovery's and Vesto's signatures");
        _;
    }

    modifier onlyAdmin(
        Signatures memory signatures,
        string memory _userId
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsAdminAddresses(addresses, _userId) && containsVAddress(addresses), "VBase::onlyAdmin - must include admin's and Vesto's signatures");
        _;
    }

    modifier onlySuperAdmin(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsSuperAdminAddresses(addresses) && containsVAddress(addresses), "VBase::onlySuperAdmin - must include super admin's and Vesto's signatures");
        _;
    }

    modifier onlyVErc20(
        address _address
    ) {
        require(vLighthouse().isVErc20(_address), "VBase::onlyVErc20 - only vErc20 addresses supported");
        _;
    }

    modifier onlyEthereum(
    ) {
        require(vLighthouse().chainId() == ETHEREUM_MAINNET || vLighthouse().chainId() == ETHEREUM_GOERLI, "VBase::onlyEthereum - function only supported on Ethereum Goerli or Mainnet");
        _;
    }

    modifier onlyGoerli(
    ) {
        require(vLighthouse().chainId() == ETHEREUM_GOERLI, "VBase::onlyGoerli - function only supported on Ethereum Goerli");
        _;
    }

    modifier onlyPolygon(
    ) {
        require(vLighthouse().chainId() == POLYGON_MUMBAI || vLighthouse().chainId() == POLYGON_MAINNET, "VBase::onlyPolygon - function only supported on Polygon");
        _;
    }

    function vAddress(
    ) override virtual public view returns (address) {
        return vLighthouse().addressByKey(VADDRESS);
    }

    function userAddress(
    ) internal view returns (address) {
        return vLighthouse().userById(stringStorage[USER_ID]).userAddress;
    }

    function recoveryAddress(
    ) internal view returns (address) {
        return vLighthouse().userById(stringStorage[USER_ID]).recoveryAddress;
    }

    function containsVAddress(
        address[] memory addresses
    ) internal view returns (bool) {
        address _vAddress = vAddress();
        for (uint i = 0; i < addresses.length; i++) {
            if (_vAddress == addresses[i]) {
                return true;
            }
        }
        return false;
    }

    function containsUserAddress(
        address[] memory addresses
    ) internal view returns (bool) {
        address _userAddress = userAddress();
        for (uint i = 0; i < addresses.length; i++) {
            //if (_userAddress == addresses[i] || isAdditionalUserAddress(addresses[i])) {
            if (_userAddress == addresses[i]) {
                return true;
            }
        }
        return false;
    }

//    function isAdditionalUserAddress(
//        address _address
//    ) internal view returns (bool) {
//        User memory _user = user();
//        for (uint i = 0; i < _user.additionalUserAddresses.length; i++) {
//            if (_address == _user.additionalUserAddresses[i]) {
//                return true;
//            }
//        }
//        return false;
//    }

    function containsRecoveryAddress(
        address[] memory addresses
    ) internal view returns (bool) {
        address _recoveryAddress = recoveryAddress();
        for (uint i = 0; i < addresses.length; i++) {
            if (_recoveryAddress == addresses[i]) {
                return true;
            }
        }
        return false;
    }

    function containsAdminAddresses(
        address[] memory addresses,
        string memory _userId
    ) internal view returns (bool) {
        User memory _user = vLighthouse().userById(_userId);
        for (uint i = 0; i < addresses.length; i++) {
            User memory adminUser = vLighthouse().userByAddress(addresses[i]);
            if ((adminUser.role == Role.ADMIN || adminUser.role == Role.SUPER_ADMIN) && LString.compare(adminUser.institutionId, _user.institutionId)) {
                 return true;
            }
        }
        return false;
    }

    function containsSuperAdminAddresses(
        address[] memory addresses
    ) internal view returns (bool) {
        uint256 signatures = 0;
        for (uint i = 0; i < addresses.length; i++) {
            if (vLighthouse().userByAddress(addresses[i]).role == Role.SUPER_ADMIN) {
                if (++signatures == SUPER_ADMIN_SIGNATURES_REQUIRED) {
                    return true;
                }
            }
        }
        return false;
    }

    function validateSignatures(
        Signatures memory signatures
    ) internal returns (address[] memory signedBy) {
        uint256 begin;
        uint256 end;
        (begin, end) = spliceTimestamps(signatures.nonce);
        require((end >= block.timestamp) && (begin < block.timestamp), "VBase::validateSignatures - invalid timestamps");
        require(!isThisNonceUsed(signatures.nonce), "VBase::validateSignatures - possible replay attack");

        address[] memory addresses = new address[](signatures.V.length);
        for (uint i = 0; i < 2; i++) {
            // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
            uint8 csv = signatures.V[i];
            if (csv < 27) {
                csv += 27;
            }
            require(csv == 27 || csv == 28, "VBase::validateSignatures - invalid signature version");
            addresses[i] = ecrecover(signatures.hash, csv, signatures.R[i], signatures.S[i]);
        }
        flagThisNonce(signatures.nonce);
        return addresses;
    }

    function spliceTimestamps(
        string memory nonce
    ) private pure returns (uint256 begin, uint256 end) {
        bytes memory _bytes = bytes(nonce);
        require(_bytes.length == 56, "VBase::spliceTimestamps - invalid nonce length");

        uint256 result = 0;
        for (uint256 i = 36; i < _bytes.length; i++) {
            uint256 b = uint(uint8(_bytes[i]));
            if (b >= 48 && b <= 57) {
                result = result * 10 + (b - 48);
            }
        }
        begin = result / 1e10;
        end = result % 1e10;
    }

    function flagThisNonce(
        string memory nonce
    ) private {
        bytes32ToBoolStorage[NONCES][key(nonce)] = true;
    }

    function isThisNonceUsed(
        string memory nonce
    ) private view returns (bool) {
        return bytes32ToBoolStorage[NONCES][key(nonce)];
    }

    function encodePackedAddressArray(
        address[] memory array
    ) internal pure returns (bytes memory) {
        bytes memory data;
        for (uint i = 0; i < array.length; i++) {
            data = abi.encodePacked(data, array[i]);
        }
        return data;
    }

    function encodePackedStringArray(
        string[] memory array
    ) internal pure returns (bytes memory) {
        bytes memory data;
        for (uint i = 0; i < array.length; i++) {
            data = abi.encodePacked(data, array[i]);
        }
        return data;
    }

    function encodePackedBytes32Array(
        bytes32[] memory array
    ) internal pure returns (bytes memory) {
        bytes memory data;
        for (uint i = 0; i < array.length; i++) {
            data = abi.encodePacked(data, array[i]);
        }
        return data;
    }

    function encodePackedUint32Array(
        uint256[] memory array
    ) internal pure returns (bytes memory) {
        bytes memory data;
        for (uint i = 0; i < array.length; i++) {
            data = abi.encodePacked(data, array[i]);
        }
        return data;
    }

    function encodeSymbolPair(
        string memory symbol,
        string memory pairedSymbol
    ) internal pure returns (bytes32){
        return key(string(abi.encodePacked(symbol, "/", pairedSymbol)));
    }

    function convert(
        IErc20 erc20,
        IErc20 pairedErc20,
        uint256 rate,
        uint256 tokens
    ) internal pure returns (uint256) {
        uint256 multiplier = 10 ** (18 + 18 - erc20.decimals()); // USDC 1e6 x 1e30 ➗ 1e18 -> 1e18
        uint256 convertedTokens = tokens
        .mul(multiplier)
        .mul(rate)
        .div(1e18)
        .div(1e18);

        if (pairedErc20.decimals() != 18) {
            multiplier = 10 ** (18 + 18 - pairedErc20.decimals()); // USDC 1e18 x 1e18 ➗ 1e30 -> 1e6
            convertedTokens = convertedTokens
            .mul(1e18)
            .div(multiplier);
        }
        return convertedTokens;
    }
}
contract VErc20 is IVErc20, ABase {

    using SafeMath for uint256;

    function name(
    ) override public pure returns (string memory) {
        return "Vesto vErc20";
    }

    function symbol(
    ) override public view returns (string memory) {
        return stringStorage[SYMBOL];
    }

    function decimals(
    ) override public pure returns (uint8) {
        return 18;
    }

    function underlying(
    ) override public view returns (IErc20) {
        return IErc20(addressStorage[UNDERLYING_ADDRESS]);
    }

    function setSupply(
        uint256 supply
    ) internal {
        uint256Storage[SUPPLY] = supply;
    }

    function totalSupply(
    ) override public view returns (uint256) {
        return uint256Storage[SUPPLY];
    }

    function balanceOf(
        address who
    ) override public view returns (uint256) {
        return addressToUnitStorage[BALANCES][who];
    }

    function balancesOf(
        address who
    ) override public view returns (uint256, uint256) {
        uint256 tokens = balanceOf(who);
        uint256 underlyingTokens = convert(this, underlying(), exchangeRate(), tokens);
        return (tokens, underlyingTokens);
    }

    function totalBalances(
    ) override public view returns (uint256, uint256) {
        uint256 tokens = totalSupply();
        uint256 underlyingTokens = convert(this, underlying(), exchangeRate(), tokens);
        return (tokens, underlyingTokens);
    }

    function setBalance(
        address account,
        uint256 balance
    ) private {
        addressToUnitStorage[BALANCES][account] = balance;
    }

    function setAllowance(
        address account,
        address spender,
        uint256 tokens
    ) internal {
        addressToAddressToUnitStorage[ALLOWANCES][account][spender] = tokens;
    }

    function allowance(
        address account,
        address spender
    ) override public view returns (uint256) {
        return addressToAddressToUnitStorage[ALLOWANCES][account][spender];
    }

    function approve(
        address spender,
        uint256 tokens
    ) override public returns (bool) {
        return _approve(msg.sender, spender, tokens);
    }

    function transfer(
        address to,
        uint256 tokens
    ) override public returns (bool) {
        _transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) override public returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance(from, spender);
        require(spender != from, "VErc20::transferFrom - spender and from address cannot be the same");
        require(spenderAllowance >= tokens, "VErc20::transferFrom - transfer tokens exceeds spender allowance");
        setAllowance(from, spender, spenderAllowance.sub(tokens));
        _transfer(from, to, tokens);
        return true;
    }

    function redeemAddress(
    ) internal view returns (address) {
        return vLighthouse().redeemAddress(symbol());
    }

    function vFinance(
    ) internal view returns (IVFinance) {
        return IVFinance(vLighthouse().addressByKey(VFINANCE_PROXY_ADDRESS));
    }

    function distributionAddress(
    ) internal view returns (address) {
        return vLighthouse().addressByKey(DISTRIBUTION_ADDRESS);
    }

    function faucet(
    ) onlyGoerli (
    ) override public {
        uint256 tokens = 500000e18;
        uint256 underlyingTokens = convert(this, underlying(), exchangeRate(), tokens);
        _mint(address(this), tokens, underlyingTokens);

        require(_approve(address(this), vLighthouse().addressByKey(ERC20_PREDICATE_PROXY_ADDRESS), tokens), "VErc20:faucet - failed to approve ERC20_PREDICATE_PROXY_ADDRESS");
        IRootChainManager(vLighthouse().addressByKey(ROOT_CHAIN_MANAGER_PROXY_ADDRESS)).depositFor(distributionAddress(), address(this), abi.encodePacked(tokens));
    }

    function mint(
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) onlyEthereum (
    ) onlySuperAdmin(
        Signatures(nonce, keccak256(abi.encodePacked(address(this), "mint", nonce)), V, R, S)
    ) override public {
        uint256 underlyingTokens = underlying().balanceOf(address(this));
        require(underlyingTokens > 0, "VErc20:mint - there are no underlying tokens to mint");

        require(underlying().transfer(address(vFinance()), underlyingTokens), "VErc20:mint - failed to transfer tokens to vFinance");
        vFinance().mint(underlyingTokens);

        uint256 tokens = convert(underlying(), this, exchangeRate(), underlyingTokens);
        _mint(address(this), tokens, underlyingTokens);

       require(_approve(address(this), vLighthouse().addressByKey(ERC20_PREDICATE_PROXY_ADDRESS), balanceOf(address(this))), "VErc20:mint - failed to approve ERC20_PREDICATE_PROXY_ADDRESS");
       IRootChainManager(vLighthouse().addressByKey(ROOT_CHAIN_MANAGER_PROXY_ADDRESS)).depositFor(distributionAddress(), address(this), abi.encodePacked(balanceOf(address(this))));
    }

    function redeem(
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) onlyEthereum(
    ) onlySuperAdmin(
        Signatures(nonce, keccak256(abi.encodePacked(address(this), "redeem", nonce)), V, R, S)
    ) override public {
//        uint256 tokens = convert(underlying(), this, exchangeRate(), underlyingTokens);
//        require(tokens > balanceOf(address(this)), "VErc20:redeemByInstitutionId - insufficient tokens to redeem");
//
//        uint256 underlyingTokens;
//        if (vLighthouse().chainId() == ETHEREUM_GOERLI || vLighthouse().chainId() == ETHEREUM_MAINNET) {
//            (, underlyingTokens) = vFinance().redeem(tokens);
//
//            // TODO: Create _burn() function!!!!
//            setBalance(address(this), balanceOf(address(this)).sub(tokens));
//            setSupply(totalSupply().sub(tokens));
//            emit Redeemed(tokens, underlyingTokens);
//            emit Transfer(address(0), address(this), tokens);
//        } else {
//            underlyingTokens = convert(IErc20(address(this)), underlying(), exchangeRate(), underlyingTokens);
//        }
//        underlying().transfer(redeemAddress(), underlyingTokens);
    }

    function deposit(
        address who,
        bytes calldata depositData
    ) onlyPolygon(
    ) override public {
        require(msg.sender == vLighthouse().addressByKey(CHILD_CHAIN_MANAGER_PROXY_ADDRESS), "VErc20::deposit - sender is not child chain manager proxy");
        uint256 tokens = abi.decode(depositData, (uint256));
        uint256 underlyingTokens = convert(this, underlying(), exchangeRate(), tokens);
        _mint(who, tokens, underlyingTokens);
    }

    function withdraw(
        uint256 amount
    ) onlyPolygon(
    ) override public {
        setBalance(msg.sender, balanceOf(msg.sender).sub(amount, "VErc20::withdraw - withdraw amount exceeds balance"));
        setSupply(totalSupply().sub(amount));
        emit Transfer(msg.sender, address(0), amount);
    }

    function exchangeRate(
    ) override public view returns (uint256) {
        return vLighthouse().exchange(symbol()).rate;
    }

    function _approve(
        address account,
        address spender,
        uint256 tokens
    ) internal returns (bool) {
        setAllowance(account, spender, tokens);
        emit Approval(account, spender, tokens);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokens
    ) internal {
        uint256 fromBalance = balanceOf(from);
        uint256 toBalance = balanceOf(to);
        require(from != to, "VErc20::_transfer - from and to address cannot be the same");
        require(from != address(0), "VErc20::_transfer - from address cannot be zero");
        require(to != address(0), "VErc20::_transfer - to address cannot be zero");
        require(fromBalance >= tokens, "VErc20::_transfer - insufficient tokens");
        setBalance(from, fromBalance.sub(tokens));
        setBalance(to, toBalance.add(tokens));
        emit Transfer(from, to, tokens);
    }

    function _mint(
        address who,
        uint256 tokens,
        uint256 underlyingTokens
    ) internal {
        setBalance(who, balanceOf(who).add(tokens));
        setSupply(totalSupply().add(tokens));
        emit Minted(tokens, underlyingTokens);
        emit Transfer(address(0), who, tokens);
    }
}