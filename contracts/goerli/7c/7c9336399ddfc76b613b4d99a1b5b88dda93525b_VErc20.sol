/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier:MIT
// produced by the Solididy File Flattener (c) David Appleton 2018 - 2020 and beyond
// contact : [email protected]
// source  : https://github.com/DaveAppleton/SolidityFlattery
// released under Apache 2.0 licence
// input  /Users/chris/Git/vestollc/vesto-contracts/src/erc20/VErc20.sol
// flattened :  Wednesday, 09-Jun-21 20:30:14 UTC
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
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
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
interface IRecovery {

    function setUserAddress(
        string memory userId,
        address userAddress,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;
}
interface IStorage {

    enum Role { USER, ADMIN, SUPER_ADMIN }

    struct User {
        string id;
        string institutionId;
        address userAddress;
        address recoveryAddress;
        Role role;
        uint256 dailyLimit; // zero means no daily limit.
    }

    struct Exchange {
        uint256 apy;
        uint256 rate;
        uint256 stamp;
    }

    struct ElementPool {
        bytes32 id;
        address _address;
        uint256 stamp;
    }

    struct Withdrawal {
        uint256 amount;
        uint256 stamp;
    }

    struct Fee {
        uint256 percentage;
        address feeAddress;
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

    function userAddress(
    ) external view returns (address);

    function recoveryAddress(
    ) external view returns (address);
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
    mapping(bytes32 => Fee) internal feeStorage;
    mapping(bytes32 => ElementPool) internal elementPoolStorage;
    mapping(bytes32 => mapping(bytes32 => Withdrawal[])) internal bytes32ToWithdrawalArrayStorage;
    mapping(bytes32 => mapping(bytes32 => User)) internal bytes32ToUserStorage;
    mapping(bytes32 => mapping(address => uint256)) internal addressToUnitStorage;
    mapping(bytes32 => mapping(address => bool)) internal addressToBoolStorage;
    mapping(bytes32 => mapping(address => address)) internal addressToAddressStorage;
    mapping(bytes32 => mapping(bytes32 => bool)) internal bytes32ToBoolStorage;
    mapping(bytes32 => mapping(bytes32 => address)) internal bytes32ToAddressStorage;
    mapping(bytes32 => mapping(address => bytes32)) internal addressToBytes32Storage;
    mapping(bytes32 => mapping(address => mapping(address => uint256))) internal addressToAddressToUnitStorage;
    mapping(bytes32 => mapping(address => mapping(address => bool))) internal addressToAddressToBoolStorage;
    mapping(bytes32 => mapping(bytes32 => mapping(address => bool))) internal bytes32ToAddressToBoolStorage;
    mapping(bytes32 => mapping(address => mapping(bytes32 => bool))) internal addressToBytes32ToBoolStorage;

    // Storage keys.
    bytes32 constant USER = keccak256(abi.encodePacked("USER"));
    bytes32 constant USER_ADDRESS = keccak256(abi.encodePacked("USER_ADDRESS"));
    bytes32 constant USER_ID = keccak256(abi.encodePacked("USER_ID"));
    bytes32 constant VLIGHT_ADDRESS = keccak256(abi.encodePacked("VLIGHT_ADDRESS"));
    bytes32 constant VLIGHTHOUSE_PROXY_ADDRESS = keccak256(abi.encodePacked("VLIGHTHOUSE_PROXY_ADDRESS"));
    bytes32 constant VFINANCE_ADDRESS = keccak256(abi.encodePacked("VFINANCE_ADDRESS"));
    bytes32 constant VFINANCE_PROXY_ADDRESS = keccak256(abi.encodePacked("VFINANCE_PROXY_ADDRESS"));
    bytes32 constant VERC20_ADDRESS = keccak256(abi.encodePacked("VERC20_ADDRESS"));
    bytes32 constant VERC20_PROXY_ADDRESSES = keccak256(abi.encodePacked("VERC20_PROXY_ADDRESSES"));
    bytes32 constant VDISTRIBUTION_ADDRESS = keccak256(abi.encodePacked("VDISTRIBUTION_ADDRESS"));
    bytes32 constant VDISTRIBUTION_PROXY_ADDRESS = keccak256(abi.encodePacked("VDISTRIBUTION_PROXY_ADDRESS"));
    bytes32 constant VWALLET_ADDRESS = keccak256(abi.encodePacked("VWALLET_ADDRESS"));
    bytes32 constant VWALLET_PROXY_ADDRESSES = keccak256(abi.encodePacked("VWALLET_PROXY_ADDRESSES"));
    bytes32 constant IMPLEMENTATION_ADDRESS_KEY = keccak256(abi.encodePacked("IMPLEMENTATION_ADDRESS_KEY"));
    bytes32 constant VADDRESS = keccak256(abi.encodePacked("VADDRESS"));
    bytes32 constant WITHDRAWALS = keccak256(abi.encodePacked("WITHDRAWALS"));
    bytes32 constant NAME = keccak256(abi.encodePacked("NAME"));
    bytes32 constant SYMBOL = keccak256(abi.encodePacked("SYMBOL"));
    bytes32 constant UNDERLYING_ADDRESS = keccak256(abi.encodePacked("UNDERLYING_ADDRESS"));
    bytes32 constant REDEEM_ADDRESS = keccak256(abi.encodePacked("REDEEM_ADDRESS"));
    bytes32 constant SUPPLY = keccak256(abi.encodePacked("SUPPLY"));
    bytes32 constant BALANCES = keccak256(abi.encodePacked("BALANCES"));
    bytes32 constant ALLOWANCES = keccak256(abi.encodePacked("ALLOWANCES"));
    bytes32 constant NONCES = keccak256(abi.encodePacked(abi.encodePacked("NONCES")));
    bytes32 constant USDC_ADDRESS = keccak256(abi.encodePacked("USDC_ADDRESS"));
    bytes32 constant DAI_ADDRESS = keccak256(abi.encodePacked("DAI_ADDRESS"));
    bytes32 constant CHAIN_ID = keccak256(abi.encodePacked("CHAIN_ID"));
    bytes32 constant ERC20_PREDICATE_PROXY_ADDRESS = keccak256(abi.encodePacked("ERC20_PREDICATE_PROXY_ADDRESS"));
    bytes32 constant ROOT_CHAIN_MANAGER_PROXY_ADDRESS = keccak256(abi.encodePacked("ROOT_CHAIN_MANAGER_PROXY_ADDRESS"));
    bytes32 constant CHILD_CHAIN_MANAGER_PROXY_ADDRESS = keccak256(abi.encodePacked("CHILD_CHAIN_MANAGER_PROXY_ADDRESS"));
    bytes32 constant USDC_ELEMENT_POOL = keccak256(abi.encodePacked("USDC_ELEMENT_POOL"));
    bytes32 constant DAI_ELEMENT_POOL = keccak256(abi.encodePacked("USDC_ELEMENT_POOL"));
    bytes32 constant BALANCER_VAULT_ADDRESS = keccak256(abi.encodePacked("BALANCER_VAULT_ADDRESS"));

    function key(
        string memory _key
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_key));
    }
}
interface IVLighthouse is IBase, IRecovery {

    function chainId(
    ) external view returns (uint256);

    function getAddress(
        bytes32 key
    ) external view returns (address);

    function setAddresses(
        bytes32[] memory keys,
        address[] memory addresses,
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

    function setVErc20ProxyAddress(
        address _address,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function userById(
        string memory id
    ) external view returns (IStorage.User memory);

    function userByUserAddress(
        address userAddress
    ) external view returns (IStorage.User memory);

    function setUser(
        string memory id,
        string memory institutionId,
        address userAddress,
        address recoveryAddress,
        Role role,
        uint256 _dailyLimit,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function isVErc20(
        address _address
    ) external view returns(bool);

    function setVWalletProxyAddress(
        address _address,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function isVWallet(
        address _address
    ) external view returns(bool);

    function fee(
        string memory _institutionId
    ) external view returns (IStorage.Fee memory);

    function setFees(
        string[] memory _institutionIds,
        uint256[] memory percentages,
        address[] memory feeAddresses,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function exchange(
        string memory symbol
    ) external view returns (IStorage.Exchange memory);

    function setExchanges(
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

    event ExchangesUpdated(
        uint256[] rates
    );
}
interface IVErc20 is IBase, IErc20 {

    function underlying(
    ) external view returns (IErc20);

    function balancesOf(
       address who
    ) external view returns (uint256, uint256);

    function mint(
    ) external;

    function faucet(
    ) external;

    function redeem(
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
interface IVFinance is IBase {

    function balanceOf(
        IErc20 iErc20
    ) external view returns (uint256);

    function swap(
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

    function elementPool(
        bytes32 _key
    ) external view returns (IStorage.ElementPool memory);

    function deployElementPool(
        bytes32 _key,
        bytes32 _id,
        address _address,
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

    struct Signatures {
        string nonce;
        bytes32 hash;
        uint8[] V;
        bytes32[] R;
        bytes32[] S;
    }

    function version(
    ) override public pure returns (string memory) {
        return "1.0";
    }

    function vLighthouse(
    ) internal view returns (IVLighthouse){
        return IVLighthouse(addressStorage[VLIGHTHOUSE_PROXY_ADDRESS]);
    }

    function user(
    ) override public virtual view returns (IStorage.User memory) {
        return vLighthouse().userById(stringStorage[USER_ID]);
    }

    modifier onlySuperAdminUserAndVesto(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsUserAddress(addresses) && containsVAddress(addresses), "VBase::onlySuperAdminUserAndVesto - must include user's and Vesto's signatures");
        require(user().role == Role.SUPER_ADMIN, "VBase::onlySuperAdminUserAndVesto - user is not a super admin");
        _;
    }

    modifier onlyUserAndVesto(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsUserAddress(addresses) && containsVAddress(addresses), "VBase::onlyUserAndVesto - must include user's and Vesto's signatures");
        _;
    }

    modifier onlyRecoveryAndVesto(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsRecoveryAddress(addresses) && containsUserAddress(addresses), "VBase::onlyRecoveryAndVesto - must include recovery's and Vesto's signatures");
        _;
    }

    modifier onlyUserAndRecovery(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsUserAddress(addresses) && containsRecoveryAddress(addresses), "VBase::onlyUserAndRecovery - must include user's and recovery's signatures");
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
        require(isEthereum(), "VBase::onlyEthereum - function only supported on Ethereum");
        _;
    }

    modifier onlyGoerli(
    ) {
        require(isGoerli(), "VBase::onlyEthereum - function only supported on Ethereum Goerli");
        _;
    }

    modifier onlyPolygon(
    ) {
        require(isPolygon(), "VBase::onlyPolygon - function only supported on Polygon");
        _;
    }

    function isEthereum(
    ) internal view returns (bool) {
        return (vLighthouse().chainId() == ETHEREUM_MAINNET || vLighthouse().chainId() == ETHEREUM_GOERLI);
    }

    function isGoerli(
    ) internal view returns (bool) {
        return (vLighthouse().chainId() == ETHEREUM_GOERLI);
    }

    function isPolygon(
    ) internal view returns (bool) {
        return (vLighthouse().chainId() == POLYGON_MUMBAI || vLighthouse().chainId() == POLYGON_MAINNET);
    }

    function vAddress(
    ) override virtual public view returns (address) {
        return vLighthouse().getAddress(VADDRESS);
    }

    function userAddress(
    ) override public view returns (address) {
        return user().userAddress;
    }

    function recoveryAddress(
    ) override public view returns (address) {
        return user().recoveryAddress;
    }

    function isOwnerAddress(
        address _address
    ) internal view returns (bool) {
        return _address == vAddress() || _address == userAddress() || _address == recoveryAddress();
    }

    function containsUserAddress(
        address[] memory addresses
    ) internal view returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            if (userAddress() == addresses[i]) {
                return true;
            }
        }
        return false;
    }

    function containsRecoveryAddress(
        address[] memory addresses
    ) internal view returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            if (recoveryAddress() == addresses[i]) {
                return true;
            }
        }
        return false;
    }

    function containsVAddress(
        address[] memory addresses
    ) internal view returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            if (vAddress() == addresses[i]) {
                return true;
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
            require(isOwnerAddress(addresses[i]), "VBase::validateSignatures - invalid signature");
        }
        require(addresses[0] != addresses[1], "VBase::validateSignatures - signatures must be from different accounts");
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

    function setBalance(
        address account,
        uint256 balance
    ) private {
        addressToUnitStorage[BALANCES][account] = balance;
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
        return addressStorage[REDEEM_ADDRESS];
    }

    function vFinance(
    ) internal view returns (IVFinance) {
        return IVFinance(vLighthouse().getAddress(VFINANCE_PROXY_ADDRESS));
    }

    function vDistributionProxyAddress(
    ) internal view returns (address) {
        return vLighthouse().getAddress(VDISTRIBUTION_PROXY_ADDRESS);
    }

    function faucet(
    ) onlyGoerli (
    ) override public {
        uint256 tokens = 500000e18;
        uint256 underlyingTokens = convert(this, underlying(), exchangeRate(), tokens);
        _mint(address(this), tokens, underlyingTokens);

        require(_approve(address(this), vLighthouse().getAddress(ERC20_PREDICATE_PROXY_ADDRESS), tokens), "VErc20:faucet - failed to approve ERC20_PREDICATE_PROXY_ADDRESS");
        IRootChainManager(vLighthouse().getAddress(ROOT_CHAIN_MANAGER_PROXY_ADDRESS)).depositFor(vDistributionProxyAddress(), address(this), abi.encodePacked(tokens));
    }

    function mint(
    ) onlyEthereum (
    ) override public {
        uint256 underlyingTokens = underlying().balanceOf(address(this));
        require(underlyingTokens > 0, "VErc20:mint - there are no underlying tokens to mint");

        require(underlying().approve(vLighthouse().getAddress(BALANCER_VAULT_ADDRESS), underlyingTokens), "VErc20::mint - failed to approve transfer of USDC/DAI tokens to Element pool");
        //require(underlying().transfer(address(vFinance()), underlyingTokens), "VErc20:mint - failed to transfer tokens to vFinance");
        vFinance().swap(underlyingTokens);

        uint256 tokens = convert(underlying(), this, exchangeRate(), underlyingTokens);
        _mint(address(this), tokens, underlyingTokens);

        require(_approve(address(this), vLighthouse().getAddress(ERC20_PREDICATE_PROXY_ADDRESS), balanceOf(address(this))), "VErc20:mint - failed to approve ERC20_PREDICATE_PROXY_ADDRESS");
        IRootChainManager(vLighthouse().getAddress(ROOT_CHAIN_MANAGER_PROXY_ADDRESS)).depositFor(vDistributionProxyAddress(), address(this), abi.encodePacked(balanceOf(address(this))));
    }

    function redeem(
    ) onlyEthereum(
    ) override public {
        uint256 tokens = balanceOf(address(this));
        require(tokens > 0, "VErc20:mint - there are no tokens to redeem");

        uint256 underlyingTokens;
        if (vLighthouse().chainId() == ETHEREUM_KOVAN || vLighthouse().chainId() == ETHEREUM_MAINNET) {
            (, underlyingTokens) = vFinance().redeem(tokens);

            // TODO: Create _burn() function!!!!
            setBalance(address(this), balanceOf(address(this)).sub(tokens));
            setSupply(totalSupply().sub(tokens));
            emit Redeemed(tokens, underlyingTokens);
            emit Transfer(address(0), address(this), tokens);
        } else {
            underlyingTokens = convert(IErc20(address(this)), underlying(), exchangeRate(), underlyingTokens);
        }
        underlying().transfer(redeemAddress(), underlyingTokens);
    }

    function deposit(
        address who, bytes calldata depositData
    ) onlyPolygon(
    ) override public {
        require(msg.sender == vLighthouse().getAddress(CHILD_CHAIN_MANAGER_PROXY_ADDRESS), "VErc20::deposit - sender is not child chain manager proxy");
        uint256 tokens = abi.decode(depositData, (uint256));
        uint256 underlyingTokens = convert(this, underlying(), exchangeRate(), tokens);
        _mint(who, tokens, underlyingTokens);
    }

    function withdraw(
        uint256 amount
    ) onlyPolygon(
    ) override public {
        setBalance(msg.sender, balanceOf(msg.sender).sub(amount, "VErc20::withdraw - burn amount exceeds balance"));
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