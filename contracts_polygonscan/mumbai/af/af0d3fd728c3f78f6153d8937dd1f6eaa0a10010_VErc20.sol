/**
 *Submitted for verification at polygonscan.com on 2021-08-19
*/

// SPDX-License-Identifier:MIT
// produced by the Solididy File Flattener (c) David Appleton 2018 - 2020 and beyond
// contact : [email protected]
// source  : https://github.com/DaveAppleton/SolidityFlattery
// released under Apache 2.0 licence
// input  /Users/chris/Git/vestollc/vesto-contracts/src/erc20/VErc20.sol
// flattened :  Wednesday, 18-Aug-21 16:22:12 UTC
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

interface IStorage {

    enum Role { USER, ADMIN, SUPER_ADMIN }

    struct User {
        string id;
        string institutionId;
        address userAddress;
        address recoveryAddress;
        Role role;
        uint256 dailyLimit;
        uint256 unused;
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
        string transactionId;
        address who;
        uint256 tokens;
        uint256 underlyingTokensOrAmount;
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

interface IRecovery {

    function swapUserAddress(
        string memory userId,
        address userAddress,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;
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
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    /**
     * upper
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
    * Convert an alphabetic character to upper case and return the original
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
abstract contract AStorage is IStorage {

    mapping(bytes32 => uint256) internal uint256Storage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => address[]) internal addressArrayStorage;
    mapping(bytes32 => bytes32) internal bytes32Storage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
    mapping(bytes32 => Exchange) internal exchangeStorage;
    mapping(bytes32 => Exchange[]) internal exchangeArrayStorage;
    mapping(bytes32 => Element) internal elementStorage;
    mapping(bytes32 => Element[]) internal elementArrayStorage;
    mapping(bytes32 => Withdrawal[]) internal withdrawalArrayStorage;
    mapping(bytes32 => mapping(bytes32 => Withdrawal[])) internal bytes32ToWithdrawalArrayStorage;
    mapping(bytes32 => mapping(bytes32 => User)) internal bytes32ToUserStorage;
    mapping(bytes32 => mapping(bytes32 => uint256)) internal bytes32ToUnitStorage;
    mapping(bytes32 => mapping(address => uint256)) internal addressToUnitStorage;
    mapping(bytes32 => mapping(address => bool)) internal addressToBoolStorage;
    mapping(bytes32 => mapping(address => address)) internal addressToAddressStorage;
    mapping(bytes32 => mapping(bytes32 => bool)) internal bytes32ToBoolStorage;
    mapping(bytes32 => mapping(bytes32 => address)) internal bytes32ToAddressStorage;
    mapping(bytes32 => mapping(bytes32 => address[])) internal bytes32ToAddressArrayStorage;
    mapping(bytes32 => mapping(address => address[])) internal addressToAddressArrayStorage;
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
    bytes32 constant ADDITIONAL_USER_ADDRESSES = keccak256(abi.encodePacked("ADDITIONAL_USER_ADDRESSES"));
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
    bytes32 constant INSTITUTION_ID = keccak256(abi.encodePacked("INSTITUTION_ID"));
    bytes32 constant ALLOWANCES = keccak256(abi.encodePacked("ALLOWANCES"));
    bytes32 constant NONCES = keccak256(abi.encodePacked(abi.encodePacked("NONCES")));
    bytes32 constant CHAIN_ID = keccak256(abi.encodePacked("CHAIN_ID"));
    bytes32 constant ERC20_PREDICATE_PROXY_ADDRESS = keccak256(abi.encodePacked("ERC20_PREDICATE_PROXY_ADDRESS"));
    bytes32 constant ROOT_CHAIN_MANAGER_PROXY_ADDRESS = keccak256(abi.encodePacked("ROOT_CHAIN_MANAGER_PROXY_ADDRESS"));
    bytes32 constant CHILD_CHAIN_MANAGER_PROXY_ADDRESS = keccak256(abi.encodePacked("CHILD_CHAIN_MANAGER_PROXY_ADDRESS"));
    bytes32 constant BALANCER_VAULT_ADDRESS = keccak256(abi.encodePacked("BALANCER_VAULT_ADDRESS"));
    bytes32 constant VPAYOUT_ADDRESS = keccak256(abi.encodePacked("VPAYOUT_ADDRESS"));
    bytes32 constant PAYOUT_ADDRESSES = keccak256(abi.encodePacked("PAYOUT_ADDRESSES"));

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

    function element(
        string memory symbol
    ) external view returns (IStorage.Element memory);

    function deployElement(
        string memory symbol,
        address trancheAddress,
        address poolAddress,
        bytes32 poolId,
        address underlyingAddress,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    //    function drain(
    //        IErc20 iErc20,
    //        string memory nonce,
    //        uint8[] memory V,
    //        bytes32[] memory R,
    //        bytes32[] memory S
    //    ) external;
}
interface IVLighthouse is IRecovery, IBase {

    function chainId(
    ) external view returns (uint256);

    function userById(
        string memory id
    ) external view returns (IStorage.User memory);

    function userByAddress(
        address _address
    ) external view returns (IStorage.User memory);

    function addressByKey(
        bytes32 _key
    ) external view returns (address);

    function redeemAddress(
        string memory symbol
    ) external view returns (address);

    function payoutAddress(
        string memory institutionId
    ) external view returns (address);

    function isVErc20(
        address _address
    ) external view returns (bool);

    function isVWallet(
        address _address
    ) external view returns (bool);

    function exchange(
        string memory symbol
    ) external view returns (IStorage.Exchange memory);

    function synchronize(
        string[] memory keys,
        address[] memory addresses,
        string[] memory nestedKeys1,
        string[] memory nestedKeys2,
        address[] memory nestedAddresses,
        address[] memory vErc20Addresses,
        uint256[] memory vErc20Apys,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function addUser(
        string memory id,
        string memory institutionId,
        address userAddress,
        address recoveryAddress,
        uint256 dailyLimit,
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

    function swapVAddress(
        address _address,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function addVWalletProxyAddress(
        address _address,
        string memory userId,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function incrementExchanges(
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function isWithinDailyLimit(
        string memory userId,
        uint256 tokens,
        uint256 underlyingTokensOrAmount
    ) external;

    function setDailyLimit(
        string memory userId,
        uint256 dailyLimit,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    event ExchangesIncremented(
        string[] symbols,
        uint256[] rates
    );
}
interface IVErc20 is IErc20, IBase {

    function underlying(
    ) external view returns (IErc20);

    function balancesOf(
       address who
    ) external view returns (uint256, uint256);

    function totalSupplies(
    ) external view returns (uint256, uint256);

    function apy(
    ) external view returns (uint256);

    function exchangeRate(
    ) external view returns (uint256);

    function hasWithdrawals(
    ) external view returns (bool);

    function mintAndDepositFor(
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function deposit(
        address who,
        bytes calldata depositData
    ) external;

    function distributeUnderlyingEquivalent(
        address[] memory who,
        uint256[] memory underlyingTokens,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function withdraw(
        uint256 tokens
    ) external;

    function withdrawUnderlyingEquivalent(
        string memory transactionId,
        uint256 underlyingTokens
    ) external;

    function withdrawAll(
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function exitAndRedeem(
        bytes memory exitPayload,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    event Minted(
        uint256 tokens,
        uint256 underlyingTokens
    );

    event DistributedUnderlyingEquivalent(
        uint256[] tokens,
        uint256[] underlyingTokens
    );

    event WithdrawnUnderlyingEquivalent(
        uint256 tokens,
        uint256 underlyingTokens
    );

    event WithdrawnAll(
        string[] transactionIds,
        address[] addresses,
        uint256[] tokens,
        uint256[] underlyingTokens
    );

    event ExitedAndRedeemed(
        uint256 tokens,
        uint256 underlyingTokens
    );
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

    function vLighthouse(
    ) internal view returns (IVLighthouse) {
        return IVLighthouse(addressStorage[VLIGHTHOUSE_PROXY_ADDRESS]);
    }

    modifier onlyOwner(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsOwnerAddress(addresses) && containsVAddress(addresses), "VBase::onlyOwner - must include owner and Vesto signatures");
        _;
    }

    modifier onlyRecovery(
        string memory userId,
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsRecoveryAddress(userId, addresses) && containsVAddress(addresses), "VBase::onlyRecovery - must include recovery and Vesto signatures");
        _;
    }

    modifier onlyVesto(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsVAddress(addresses), "VBase::onlyVesto - must include Vesto signature");
        _;
    }

    modifier onlyAdmin(
        Signatures memory signatures,
        string memory _userId
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsAdminAddresses(addresses, _userId) && containsVAddress(addresses), "VBase::onlyAdmin - must include admin and Vesto signatures");
        _;
    }

    modifier onlySuperAdmin(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsSuperAdminAddresses(addresses) && containsVAddress(addresses), "VBase::onlySuperAdmin - must include super admin and Vesto signatures");
        _;
    }

    modifier onlyVErc20(
        address _address
    ) {
        require(vLighthouse().isVErc20(_address), "VBase::onlyVErc20 - only vErc20 addresses supported");
        _;
    }

    modifier onlyVWallet(
        address _address
    ) {
        require(vLighthouse().isVWallet(_address), "VBase::onlyVWallet - only vWallet addresses supported");
        _;
    }

    modifier onlyEthereum(
    ) {
        require(vLighthouse().chainId() == ETHEREUM_MAINNET || vLighthouse().chainId() == ETHEREUM_GOERLI, "VBase::onlyEthereum - function only supported on Ethereum Goerli or Mainnet");
        _;
    }

    modifier onlyPolygon(
    ) {
        require(vLighthouse().chainId() == POLYGON_MUMBAI || vLighthouse().chainId() == POLYGON_MAINNET, "VBase::onlyPolygon - function only supported on Polygon");
        _;
    }

    function vAddress(
    ) virtual internal view returns (address) {
        return vLighthouse().addressByKey(VADDRESS);
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

    function containsOwnerAddress(
        address[] memory addresses
    ) internal view returns (bool) {
        address ownerAddress = vLighthouse().userById(stringStorage[USER_ID]).userAddress;
        address[] memory additionalUserAddresses = addressArrayStorage[ADDITIONAL_USER_ADDRESSES];
        for (uint i = 0; i < addresses.length; i++) {
            if (ownerAddress == addresses[i]) {
                return true;
            }
            for (uint j = 0; j < additionalUserAddresses.length; j++) {
                if (additionalUserAddresses[j] == addresses[i]) {
                    return true;
                }
            }
        }
        return false;
    }

    function containsRecoveryAddress(
        string memory userId,
        address[] memory addresses
    ) internal view returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            User memory user = vLighthouse().userByAddress(addresses[i]);
            if (LString.compare(userId, user.id) && user.recoveryAddress == addresses[i]) {
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
        for (uint i = 0; i < addresses.length; i++) {
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
abstract contract AErc20 is IErc20, ABase {

    using SafeMath for uint256;

    function symbol(
    ) override public view returns (string memory) {
        return stringStorage[SYMBOL];
    }

    function decimals(
    ) override public pure returns (uint8) {
        return 18;
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
        return approve(msg.sender, spender, tokens);
    }

    function transfer(
        address to,
        uint256 tokens
    ) override public returns (bool) {
        transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) override public returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance(from, spender);
        require(spender != from, "AErc20::transferFrom - spender and from address cannot be the same");
        require(spenderAllowance >= tokens, "AErc20::transferFrom - transfer tokens exceeds spender allowance");
        setAllowance(from, spender, spenderAllowance.sub(tokens));
        transfer(from, to, tokens);
        return true;
    }

    function setSupply(
        uint256 supply
    ) internal {
        uint256Storage[SUPPLY] = supply;
    }

    function setBalance(
        address account,
        uint256 balance
    ) internal {
        addressToUnitStorage[BALANCES][account] = balance;
    }

    function setAllowance(
        address account,
        address spender,
        uint256 tokens
    ) internal {
        addressToAddressToUnitStorage[ALLOWANCES][account][spender] = tokens;
    }

    function approve(
        address account,
        address spender,
        uint256 tokens
    ) internal returns (bool) {
        setAllowance(account, spender, tokens);
        emit Approval(account, spender, tokens);
        return true;
    }

    function transfer(
        address from,
        address to,
        uint256 tokens
    ) internal {
        uint256 fromBalance = balanceOf(from);
        uint256 toBalance = balanceOf(to);
        require(from != to, "AErc20::transfer - from and to address cannot be the same");
        require(from != address(0x0), "AErc20::transfer - from address cannot be zero");
        require(to != address(0x0), "AErc20::transfer - to address cannot be zero");
        require(fromBalance >= tokens, "AErc20::transfer - insufficient tokens");

        setBalance(from, fromBalance.sub(tokens));
        setBalance(to, toBalance.add(tokens));
        emit Transfer(from, to, tokens);
    }
}
contract VErc20 is IVErc20, AErc20 {

    using SafeMath for uint256;

    function name(
    ) override public pure returns (string memory) {
        return "Vesto vErc20";
    }

    function underlying(
    ) override public view returns (IErc20) {
        return IErc20(addressStorage[UNDERLYING_ADDRESS]);
    }

    function balancesOf(
        address who
    ) override public view returns (uint256, uint256) {
        uint256 tokens = balanceOf(who);
        uint256 underlyingTokens = convert(this, underlying(), exchangeRate(), tokens);
        return (tokens, underlyingTokens);
    }

    function totalSupplies(
    ) override public view returns (uint256, uint256) {
        uint256 tokens = totalSupply();
        uint256 underlyingTokens = convert(this, underlying(), exchangeRate(), tokens);
        return (tokens, underlyingTokens);
    }

    function vFinance(
    ) internal view returns (IVFinance) {
        return IVFinance(vLighthouse().addressByKey(VFINANCE_PROXY_ADDRESS));
    }

    function rootChainManager(
    ) internal view returns (IRootChainManager) {
        return IRootChainManager(vLighthouse().addressByKey(ROOT_CHAIN_MANAGER_PROXY_ADDRESS));
    }

    function apy(
    ) override public view returns (uint256) {
        return vLighthouse().exchange(symbol()).apy;
    }

    function exchangeRate(
    ) override public view returns (uint256) {
        return vLighthouse().exchange(symbol()).rate;
    }

    function hasWithdrawals(
    ) override public view returns (bool) {
        return withdrawals().length > 0 ? true : false;
    }

    function withdrawals(
    ) internal view returns (Withdrawal[] storage) {
        return withdrawalArrayStorage[WITHDRAWALS];
    }

    function mintAndDepositFor(
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) onlyEthereum (
    ) onlyVesto(
        Signatures(nonce, keccak256(abi.encodePacked(address(this), "mintAndDepositFor", nonce)), V, R, S)
    ) override public {
        uint256 underlyingTokens = underlying().balanceOf(address(this));
        require(underlyingTokens > 0, "VErc20:mintAndDepositFor - there are no underlying tokens to mint");

        require(underlying().transfer(address(vFinance()), underlyingTokens), "VErc20:mintAndDepositFor - failed to transfer tokens to vFinance");
        vFinance().mint(underlyingTokens);

        uint256 tokens = convert(underlying(), this, exchangeRate(), underlyingTokens);
        mint(address(this), tokens, underlyingTokens);

        require(approve(address(this), vLighthouse().addressByKey(ERC20_PREDICATE_PROXY_ADDRESS), balanceOf(address(this))), "VErc20:mintAndDepositFor - failed to approve ERC20_PREDICATE_PROXY_ADDRESS");
        rootChainManager().depositFor(address(this), address(this), abi.encodePacked(balanceOf(address(this))));
    }

    function deposit(
        address who,
        bytes calldata depositData
    ) onlyPolygon(
    ) override public {
        require(msg.sender == vLighthouse().addressByKey(CHILD_CHAIN_MANAGER_PROXY_ADDRESS), "VErc20::deposit - sender is not child chain manager proxy");
        uint256 tokens = abi.decode(depositData, (uint256));
        uint256 underlyingTokens = convert(this, underlying(), exchangeRate(), tokens);
        mint(who, tokens, underlyingTokens);
    }

    function distributeUnderlyingEquivalent(
        address[] memory who,
        uint256[] memory underlyingTokens,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) onlySuperAdmin(  // TODO: Should this be onlyAdmin???
        Signatures(nonce, keccak256(abi.encodePacked(address(this), "distributeUnderlyingEquivalent", encodePackedAddressArray(who), encodePackedUint32Array(underlyingTokens), nonce)), V, R, S)
    ) override public {
        uint256[] memory tokens = new uint256[](who.length);
        uint256 totalTokens = 0;
        for (uint i = 0; i < who.length; i++) {
            tokens[i] = convert(underlying(), this, exchangeRate(), underlyingTokens[i]);
            totalTokens += tokens[i];
        }
        require(totalTokens <= balanceOf(address(this)), "VErc20::distributeUnderlyingEquivalent - insufficient tokens");

        for (uint i = 0; i < who.length; i++) {
            transfer(address(this), who[i], tokens[i]);
        }

        emit DistributedUnderlyingEquivalent(tokens, underlyingTokens);
    }

    function withdraw(
        uint256 tokens
    ) onlyPolygon(
    ) override public {
        require(tokens <= balanceOf(msg.sender), "VErc20::withdraw - insufficient tokens");
        burn(msg.sender, tokens);
    }

    function withdrawUnderlyingEquivalent(
        string memory transactionId,
        uint256 underlyingTokens
    ) onlyPolygon(
    ) onlyVWallet(
        msg.sender
    ) override public {
        uint256 tokens = convert(underlying(), this, exchangeRate(), underlyingTokens);
        require(tokens <= balanceOf(msg.sender), "VErc20::withdrawUnderlyingEquivalent - insufficient tokens to withdraw");
        require(IVErc20(address(this)).transferFrom(msg.sender, address(this), tokens), "VErc20::withdrawUnderlyingEquivalent - failed to transfer tokens from vWallet");

        Withdrawal memory _withdrawal;
        _withdrawal.transactionId = transactionId;
        _withdrawal.who = msg.sender;
        _withdrawal.tokens = tokens;
        _withdrawal.underlyingTokensOrAmount = underlyingTokens;
        _withdrawal.stamp = block.timestamp;
        withdrawals().push(_withdrawal);

        emit WithdrawnUnderlyingEquivalent(tokens, underlyingTokens);
    }

    function withdrawAll(
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) onlyPolygon(
    ) onlyVesto(
        Signatures(nonce, keccak256(abi.encodePacked(address(this), "withdrawAll", nonce)), V, R, S)
    ) override public {
        Withdrawal[] storage _withdrawals =  withdrawals();
        require(_withdrawals.length > 0, "VErc20::withdrawAll - there are currently no withdrawals");

        uint256 totalTokens;
        string[] memory transactionIds = new string[](_withdrawals.length);
        address[] memory addresses = new address[](_withdrawals.length);
        uint256[] memory tokens = new uint256[](_withdrawals.length);
        uint256[] memory underlyingTokens = new uint256[](_withdrawals.length);
        while (_withdrawals.length > 0) {
            uint i = _withdrawals.length-1;
            transactionIds[i] = _withdrawals[i].transactionId;
            addresses[i] = _withdrawals[i].who;
            tokens[i] = _withdrawals[i].tokens;
            underlyingTokens[i] = _withdrawals[i].underlyingTokensOrAmount;
            totalTokens = totalTokens.add(_withdrawals[i].tokens);
            _withdrawals.pop();
        }

        IVErc20(address(this)).withdraw(totalTokens);

        emit WithdrawnAll(transactionIds, addresses, tokens, underlyingTokens);
    }

    function exitAndRedeem(
        bytes memory exitPayload,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) onlyEthereum(
    ) onlyVesto(
        Signatures(nonce, keccak256(abi.encodePacked(address(this), "exitAndRedeem", exitPayload, nonce)), V, R, S)
    ) override public {
        rootChainManager().exit(exitPayload);

        uint256 tokens = balanceOf(address(this));
        require(tokens > 0, "VErc20::exitAndRedeem - no tokens to redeem");

        uint256 underlyingTokens = 0;
        (, underlyingTokens) = vFinance().redeem(tokens);
        burn(address(this), tokens);

        emit ExitedAndRedeemed(tokens, underlyingTokens);
    }

    function mint(
        address who,
        uint256 tokens,
        uint256 underlyingTokens
    ) internal {
        setBalance(who, balanceOf(who).add(tokens));
        setSupply(totalSupply().add(tokens));

        emit Minted(tokens, underlyingTokens);
        emit Transfer(address(0), who, tokens);
    }

    function burn(
        address who,
        uint256 tokens
    ) internal {
        setBalance(who, balanceOf(who).sub(tokens));
        setSupply(totalSupply().sub(tokens));

        emit Transfer(who, address(0), tokens);
    }
}