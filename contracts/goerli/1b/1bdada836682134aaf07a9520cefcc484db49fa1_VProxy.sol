/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/lib/SafeMath.sol

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;


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


pragma solidity ^0.8.7;


interface IStorage {

    enum Role { USER, ADMIN, SUPER_ADMIN }
    enum DistributionKind { MINT, REDEEM, PAYOUT }

    struct User {
        string id;
        string institutionId;
        address userAddress;
        address recoveryAddress;
        Role role;
        uint256 dailyLimit;
        uint256 unused1;
        uint256 unused2;
        bytes data;
    }

    struct Exchange {
        uint256 apy;
        uint256 rate;
        uint256 stamp;
    }

    struct Element {
        address trancheAddress;
        address poolAddress;
        uint256 apy;
    }

    struct Distribution {
        DistributionKind kind;
        string id;
        address who;
        uint256 tokens;
        uint256 underlyingTokens;
    }

    struct Withdrawal {
        address who;
        uint256 tokens;
        uint256 underlyingTokensOrAmount;
        uint256 stamp;
    }
}

pragma solidity ^0.8.7;

interface IBase is IStorage {

    function name(
    ) external view returns (string memory);

    function version(
    ) external pure returns (string memory);
}


pragma solidity ^0.8.7;

interface IRecovery {

    function swapUserAddress(
        string memory userId,
        address userAddress,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;
}


pragma solidity ^0.8.7;


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
        uint256[] memory vErc20Apys,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function addUser(
        string memory id,
        string memory institutionId,
        address userAddress,
        address recoveryAddress,
        uint256 dailyLimit,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    //    function setRecoveryAddress(
    //        string memory userId,
    //        address _recoveryAddress,
    //        string memory nonce,
    //        uint8[] memory v,
    //        bytes32[] memory r,
    //        bytes32[] memory s
    //    ) external;

    function swapVAddress(
        address _address,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function addVErc20ProxyAddress(
        address who
    ) external;

    function addVWalletProxyAddress(
        address who,
        string memory userId
    ) external;

    function readyToIncrementExchanges(
    ) external view returns (bool);

    function incrementExchanges(
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
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
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    event ExchangesIncremented(
        uint256 timestamp,
        string[] symbols,
        uint256[] apys,
        uint256[] rates
    );
}


// File contracts/erc20/IErc20.sol

/// This contract is subject to the MIT License (MIT)
///
/// Copyright (c) 2016-2019 zOS Global Limited
///
/// Permission is hereby granted, free of charge, to any person obtaining
/// a copy of this software and associated documentation files (the
/// "Software"), to deal in the Software without restriction, including
/// without limitation the rights to use, copy, modify, merge, publish,
/// distribute, sublicense, and/or sell copies of the Software, and to
/// permit persons to whom the Software is furnished to do so, subject to
/// the following conditions:
///
/// The above copyright notice and this permission notice shall be included
/// in all copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
/// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
/// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
/// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
/// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
/// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
/// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.7;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
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


pragma solidity ^0.8.7;


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

    function hasDistributions(
    ) external view returns (bool);

    function mintToPolygon(
        string[] memory ids,
        address[] memory who,
        uint256[] memory underlyingTokens,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function deposit(
        address who,
        bytes calldata depositData
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
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function exitAndRedeem(
        bytes memory exitPayload,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
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
        address[] who,
        uint256[] tokens,
        uint256[] underlyingTokens
    );

    event ExitedAndRedeemed(
        uint256 tokens,
        uint256 underlyingTokens
    );
}


pragma solidity ^0.8.7;

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
    mapping(bytes32 => Distribution[]) internal distributionArrayStorage;
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
    bytes32 constant ACCOUNT_ID = keccak256(abi.encodePacked("ACCOUNT_ID"));
    bytes32 constant USER = keccak256(abi.encodePacked("USER"));
    bytes32 constant ADDRESS_TO_USER_ID = keccak256(abi.encodePacked("ADDRESS_TO_USER_ID"));
    bytes32 constant ADDITIONAL_USER_ADDRESSES = keccak256(abi.encodePacked("ADDITIONAL_USER_ADDRESSES"));
    bytes32 constant VFACTORY_ADDRESS = keccak256(abi.encodePacked("VFACTORY_ADDRESS"));
    bytes32 constant VFACTORY_PROXY_ADDRESS = keccak256(abi.encodePacked("VFACTORY_PROXY_ADDRESS"));
    bytes32 constant VLIGHTHOUSE_ADDRESS = keccak256(abi.encodePacked("VLIGHTHOUSE_ADDRESS"));
    bytes32 constant VLIGHTHOUSE_PROXY_ADDRESS = keccak256(abi.encodePacked("VLIGHTHOUSE_PROXY_ADDRESS"));
    bytes32 constant VBRIDGE_ADDRESS = keccak256(abi.encodePacked("VBRIDGE_ADDRESS"));
    bytes32 constant VBRIDGE_PROXY_ADDRESS = keccak256(abi.encodePacked("VBRIDGE_PROXY_ADDRESS"));
    bytes32 constant VDEFI_ADDRESS = keccak256(abi.encodePacked("VDEFI_ADDRESS"));
    bytes32 constant VDEFI_PROXY_ADDRESS = keccak256(abi.encodePacked("VDEFI_PROXY_ADDRESS"));
    bytes32 constant VERC20_ADDRESS = keccak256(abi.encodePacked("VERC20_ADDRESS"));
    bytes32 constant VERC20_PROXY_ADDRESSES = keccak256(abi.encodePacked("VERC20_PROXY_ADDRESSES"));
    bytes32 constant VWALLET_ADDRESS = keccak256(abi.encodePacked("VWALLET_ADDRESS"));
    bytes32 constant VWALLET_PROXY_ADDRESSES = keccak256(abi.encodePacked("VWALLET_PROXY_ADDRESSES"));
    bytes32 constant IMPLEMENTATION_ADDRESS_KEY = keccak256(abi.encodePacked("IMPLEMENTATION_ADDRESS_KEY"));
    bytes32 constant VADDRESS = keccak256(abi.encodePacked("VADDRESS"));
    bytes32 constant WITHDRAWALS = keccak256(abi.encodePacked("WITHDRAWALS"));
    bytes32 constant DISTRIBUTIONS = keccak256(abi.encodePacked("DISTRIBUTIONS"));
    bytes32 constant NAME = keccak256(abi.encodePacked("NAME"));
    bytes32 constant SYMBOL = keccak256(abi.encodePacked("SYMBOL"));
    bytes32 constant UNDERLYING_ADDRESS = keccak256(abi.encodePacked("UNDERLYING_ADDRESS"));
    bytes32 constant REDEEM_ADDRESSES = keccak256(abi.encodePacked("REDEEM_ADDRESSES"));
    bytes32 constant SUPPLY = keccak256(abi.encodePacked("SUPPLY"));
    bytes32 constant BALANCES = keccak256(abi.encodePacked("BALANCES"));
    bytes32 constant INSTITUTION_ID = keccak256(abi.encodePacked("INSTITUTION_ID"));
    bytes32 constant INCREMENT_EXCHANGES_TIMESTAMP = keccak256(abi.encodePacked("INCREMENT_EXCHANGES_TIMESTAMP"));
    bytes32 constant ALLOWANCES = keccak256(abi.encodePacked("ALLOWANCES"));
    bytes32 constant NONCES = keccak256(abi.encodePacked(abi.encodePacked("NONCES")));
    bytes32 constant CHAIN_ID = keccak256(abi.encodePacked("CHAIN_ID"));
    bytes32 constant BALANCER_VAULT_ADDRESS = keccak256(abi.encodePacked("BALANCER_VAULT_ADDRESS"));
    bytes32 constant VPAYOUT_ADDRESS = keccak256(abi.encodePacked("VPAYOUT_ADDRESS"));
    bytes32 constant PAYOUT_ADDRESSES = keccak256(abi.encodePacked("PAYOUT_ADDRESSES"));
    bytes32 constant CHECKPOINT_MANAGER_ADDRESS = keccak256(abi.encodePacked("CHECKPOINT_MANAGER_ADDRESS"));
    bytes32 constant FX_ROOT_ADDRESS = keccak256(abi.encodePacked("FX_ROOT_ADDRESS"));
    bytes32 constant FX_CHILD_ADDRESS = keccak256(abi.encodePacked("FX_ROOT_ADDRESS"));

    function key(
        string memory _key
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_key));
    }
}

pragma solidity ^0.8.7;





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
        uint8[] v;
        bytes32[] r;
        bytes32[] s;
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
        require(containsOwnerAddress(addresses) && containsVAddress(addresses), "ABase: INVALID_SIGNATURES");
        _;
    }

    modifier onlyRecovery(
        string memory userId,
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsRecoveryAddress(userId, addresses) && containsVAddress(addresses), "ABase: INVALID_SIGNATURES");
        _;
    }

    modifier onlyVesto(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsVAddress(addresses), "ABase: INVALID_SIGNATURE");
        _;
    }

    modifier onlyAdmin(
        Signatures memory signatures,
        string memory _userId
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsAdminAddresses(addresses, _userId) && containsVAddress(addresses), "ABase: INVALID_SIGNATURES");
        _;
    }

    modifier onlySuperAdmin(
        Signatures memory signatures
    ) {
        address[] memory addresses = validateSignatures(signatures);
        require(containsSuperAdminAddresses(addresses) && containsVAddress(addresses), "ABase: INVALID_SIGNATURES");
        _;
    }

    modifier onlyVErc20(
        address _address
    ) {
        require(vLighthouse().isVErc20(_address), "ABase: ONLY_ERC20");
        _;
    }

    modifier onlyVWallet(
        address _address
    ) {
        require(vLighthouse().isVWallet(_address), "ABase: ONLY_VWALLET");
        _;
    }

    modifier onlyEthereum(
    ) {
        require(vLighthouse().chainId() == ETHEREUM_MAINNET || vLighthouse().chainId() == ETHEREUM_GOERLI, "ABase: ONLY_ETHEREUM");
        _;
    }

    modifier onlyPolygon(
    ) {
        require(vLighthouse().chainId() == POLYGON_MUMBAI || vLighthouse().chainId() == POLYGON_MAINNET, "ABase: ONLY_POLYGON");
        _;
    }

    modifier onlyVFactory(
        address sender
    ) {
        require(sender == addressStorage[VFACTORY_PROXY_ADDRESS], "ABase: ONLY_VFACTORY");
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
            if (compare(userId, user.id) && user.recoveryAddress == addresses[i]) {
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
            if ((adminUser.role == Role.ADMIN || adminUser.role == Role.SUPER_ADMIN) && compare(adminUser.institutionId, _user.institutionId)) {
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
        (uint256 begin, uint256 end) = spliceTimestamps(signatures.nonce);
        require((end >= block.timestamp) && (begin < block.timestamp), "ABase: INVALID_TIMESTAMPS");
        require(!isThisNonceUsed(signatures.nonce), "ABase: POSSIBLE_REPLAY_ATTACK");

        address[] memory addresses = new address[](signatures.v.length);
        for (uint i = 0; i < addresses.length; i++) {
            // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
            uint8 csv = signatures.v[i];
            if (csv < 27) {
                csv += 27;
            }
            require(csv == 27 || csv == 28, "ABase: INVALID_SIGNATURE_VERSION");
            addresses[i] = ecrecover(signatures.hash, csv, signatures.r[i], signatures.s[i]);
        }
        flagThisNonce(signatures.nonce);
        return addresses;
    }

    function spliceTimestamps(
        string memory nonce
    ) private pure returns (uint256 begin, uint256 end) {
        bytes memory _bytes = bytes(nonce);
        require(_bytes.length == 56, "ABase: INVALID_NONCE_LENGTH");

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

    function encodePacked(
        address[] memory array
    ) internal pure returns (bytes memory) {
        bytes memory data;
        for (uint i = 0; i < array.length; i++) {
            data = abi.encodePacked(data, array[i]);
        }
        return data;
    }

    function encodePacked(
        string[] memory array
    ) internal pure returns (bytes memory) {
        bytes memory data;
        for (uint i = 0; i < array.length; i++) {
            data = abi.encodePacked(data, array[i]);
        }
        return data;
    }

    function encodePacked(
        bytes32[] memory array
    ) internal pure returns (bytes memory) {
        bytes memory data;
        for (uint i = 0; i < array.length; i++) {
            data = abi.encodePacked(data, array[i]);
        }
        return data;
    }

    function encodePacked(
        uint256[] memory array
    ) internal pure returns (bytes memory) {
        bytes memory data;
        for (uint i = 0; i < array.length; i++) {
            data = abi.encodePacked(data, array[i]);
        }
        return data;
    }

    function compare(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function encodeSymbolPair(
        string memory symbol,
        string memory pairedSymbol
    ) internal pure returns (bytes32){
        return key(string(abi.encodePacked(symbol, "/", pairedSymbol)));
    }

    function toTokens(
        IVErc20 vErc20,
        uint256 underlyingTokens
    ) internal view returns (uint256) {
        return underlyingTokens // USDC 1e6 x 1e30 ➗ 1e18 -> 1e18
        .mul(10 ** (18 + 18 - vErc20.underlying().decimals()))
        .div(1e18)
        .mul(1e18)
        .div(vErc20.exchangeRate());
    }

    function toUnderlyingTokens(
        IVErc20 vErc20,
        uint256 tokens
    ) internal view returns (uint256) {
        return tokens
        .mul(vErc20.exchangeRate())
        .div(1e18)
        .mul(1e18) // USDC 1e18 x 1e18 ➗ 1e30 -> 1e6
        .div(10 ** (18 + 18 - vErc20.underlying().decimals()));
    }
}

pragma solidity ^0.8.7;

interface IProxy is IBase {

    function implementationAddress(
    ) external view returns (address);
}


pragma solidity ^0.8.7;


abstract contract AProxy is IProxy, ABase {

    event Received(uint256 amount, address sender);

    constructor (
        string memory _name,
        bytes32 _implementationAddressKey,
        address _vLighthouseProxyAddress
    ) {
        stringStorage[NAME] = _name;
        bytes32Storage[IMPLEMENTATION_ADDRESS_KEY] = _implementationAddressKey;
        addressStorage[VLIGHTHOUSE_PROXY_ADDRESS] = _vLighthouseProxyAddress;
    }

    function name(
    ) override public view returns (string memory){
        return stringStorage[NAME];
    }

    /**
    * Every proxy contract looks at VLighthouse for their implementation, except the VLighthouse looks at it's self.
    */
    function implementationAddress(
    ) override public view returns (address) {
        return implementationAddressKey() == VLIGHTHOUSE_ADDRESS ? addressStorage[VLIGHTHOUSE_ADDRESS] : vLighthouse().addressByKey(implementationAddressKey());
    }

    function implementationAddressKey(
    ) internal view returns (bytes32) {
        return bytes32Storage[IMPLEMENTATION_ADDRESS_KEY];
    }

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    receive(
    ) external payable {
        emit Received(msg.value, msg.sender);
    }

    fallback(
    ) payable external {
        address _implementationAddress = implementationAddress();
        require(_implementationAddress != address(0x0), "VProxy::fallback - invalid implementation address");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _implementationAddress, ptr, calldatasize(), 0, 0)
            mstore(0x40, add(ptr, returndatasize()))
            returndatacopy(ptr, 0, returndatasize())
            switch result
            case 0 {
                revert(ptr, returndatasize())
            }
            default {
                return (ptr, returndatasize())
            }
        }
    }
}

pragma solidity ^0.8.7;

contract VProxy is AProxy {

    constructor(
        address _vFactoryProxy,
        string memory _name,
        bytes32 _implementationAddressKey,
        address _vLighthouseProxyAddress
    ) AProxy(_name, _implementationAddressKey, _vLighthouseProxyAddress) {
        addressStorage[VFACTORY_PROXY_ADDRESS] = _vFactoryProxy;
    }

    function initialize (
        User[] memory users,
        address vAddress,
        uint256 chainId,
        address vFactoryAddress,
        address vLighthouseAddress
    ) onlyVFactory(
        msg.sender
    ) public {
        addressStorage[VLIGHTHOUSE_PROXY_ADDRESS] = address(this);
        addressStorage[VADDRESS] = vAddress;
        uint256Storage[CHAIN_ID] = chainId;
        addressStorage[VFACTORY_ADDRESS] = vFactoryAddress;
        addressStorage[VLIGHTHOUSE_ADDRESS] = vLighthouseAddress;
        for (uint i=0; i<users.length; i++) {
            users[i].role = Role.SUPER_ADMIN;
            bytes32ToUserStorage[USER][key(users[i].id)] = users[i];
            addressToBytes32Storage[ADDRESS_TO_USER_ID][users[i].userAddress] = key(users[i].id);
            addressToBytes32Storage[ADDRESS_TO_USER_ID][users[i].recoveryAddress] = key(users[i].id);
        }
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _underlyingAddress,
        string memory _institutionId
    ) onlyVFactory(
        msg.sender
    ) public {
        stringStorage[NAME] = _name;
        stringStorage[SYMBOL] = _symbol;
        addressStorage[UNDERLYING_ADDRESS] = _underlyingAddress;
        stringStorage[INSTITUTION_ID] = _institutionId;
    }

    function initialize (
        string memory userId,
        string memory accountId
    ) onlyVFactory(
        msg.sender
    ) public {
        stringStorage[USER_ID] = userId;
        stringStorage[ACCOUNT_ID] = accountId;
    }

    function stubbedForWeb3jGenerationBug(
    ) public pure returns (User memory) {
        User memory user;
        return user;
    }
}