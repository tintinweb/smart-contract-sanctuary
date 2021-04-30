/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier:MIT
// produced by the Solididy File Flattener (c) David Appleton 2018 - 2020 and beyond
// contact : [email protected]
// source  : https://github.com/DaveAppleton/SolidityFlattery
// released under Apache 2.0 licence
// input  /Users/chris/Git/vestollc/vesto-contracts/src/proxy/VErc20Proxy.sol
// flattened :  Thursday, 29-Apr-21 22:45:25 UTC
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

interface IVBase {

    function name(
    ) external view returns (string memory);

    function version(
    ) external pure returns (string memory);

    function institutionId(
    ) external view returns (string memory);

    function setVAddress(
        address _address,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) external;

    function setUserAddress(
        address _address,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) external;

    function setRecoveryAddress(
        address _address,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) external;
}
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

interface IVStore is IVBase {

    function chainId(
    ) external view returns (uint256);

    function setAddress(
        string memory _key,
        address _address,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) external;

    function getAddress(
        string memory _key
    ) external view returns (address);

    function setVErc20Address(
        address _address,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) external;

    function isVErc20(
        address _address
    ) external view returns(bool);

    function setVWalletAddress(
        string memory institutionId,
        address _address,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) external;

    function isVWallet(
        string memory institutionId,
        address _address
    ) external view returns(bool);

    function setRedeemAddress(
        address underlyingAddress,
        address _address,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) external;

    function redeemAddress(
        address underlyingAddress
    ) external view returns (address);

    function vDistributionAddress(
        string memory institutionId
    ) external view returns (address);

    function setVDistributionAddress(
        string memory institutionId,
        address _address,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) external;
}
interface IVErc20 is IVBase, IErc20 {

    function underlying(
    ) external view returns (IErc20);

    function balanceOfUnderlying(
        address account
    ) external view returns (uint256);

    function totalBalanceOfUnderlying(
    ) external view returns (uint256);

    function mint(
    ) external;

    function redeem(
    ) external;

    function setExchangeRates(
        uint256 institutionApy,
        uint256 apy,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) external;

    function institutionApy(
    ) external view returns (uint256);

    function apy(
    ) external view returns (uint256);

    function institutionExchangeRate(
    ) external view returns (uint256);

    function exchangeRate(
    ) external view returns (uint256);

    event SetExchangeRates(
        uint256 institutionRate,
        uint256 rate
    );

    event Mint(
        uint256 tokens,
        uint256 underlyingTokens
    );

    event Redeem(
        uint256 tokens,
        uint256 underlyingTokens
    );
}
interface IVProxy is IVBase {

    function implementationAddress(
    ) external view returns (address);
}
abstract contract AVBase is IVBase {

    using SafeMath for uint256;

    uint256 constant ETHEREUM_MAINNET = 1;
    uint256 constant ETHEREUM_GOERLI = 5;
    uint256 constant ETHEREUM_KOVAN = 42;
    uint256 constant MATIC_MAINNET = 137;
    uint256 constant MATIC_MUMBAI = 8001;

    struct Exchange {
        uint256 rate;
        uint256 decimals;
        uint256 pairedDecimals;
        uint256 updated;
    }

    struct Withdrawal {
        uint256 amount;
        uint256 stamp;
    }

    struct Signatures {
        string nonce;
        bytes32 hash;
        uint8[2] V;
        bytes32[2] R;
        bytes32[2] S;
    }

    mapping(bytes32 => uint256) internal uint256Storage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytes32Storage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
    mapping(bytes32 => Withdrawal[]) internal withdrawalArrayStorage;
    mapping(bytes32 => mapping(address => uint256)) internal addressToUnitStorage;
    mapping(bytes32 => mapping(bytes32 => Exchange)) internal bytes32ToExchangeStorage;
    mapping(bytes32 => mapping(address => bool)) internal addressToBoolStorage;
    mapping(bytes32 => mapping(address => address)) internal addressToAddressStorage;
    mapping(bytes32 => mapping(bytes32 => bool)) internal bytes32ToBoolStorage;
    mapping(bytes32 => mapping(bytes32 => address)) internal bytes32ToAddressStorage;
    mapping(bytes32 => mapping(address => mapping(address => uint256))) internal addressToAddressToUnitStorage;
    mapping(bytes32 => mapping(address => mapping(address => bool))) internal addressToAddressToBoolStorage;
    mapping(bytes32 => mapping(bytes32 => mapping(address => bool))) internal bytes32ToAddressToBoolStorage;
    mapping(bytes32 => mapping(address => mapping(bytes32 => bool))) internal addressToBytes32ToBoolStorage;

    modifier onlyEthereum(
    ) {
        require(isEthereum(), "VBase::onlyEthereum - function only supported on Ethereum");
        _;
    }

    modifier onlyMatic(
    ) {
        require(isMatic(), "VBase::onlyMatic - function only supported on Matic");
        _;
    }

    modifier onlyUserAndVesto(
        Signatures memory signatures
    ) {
        address[2] memory signedBy = validateSignatures(signatures);
        require((signedBy[0] == userAddress() && signedBy[1] == vAddress()) || (signedBy[0] == vAddress() && signedBy[1] == userAddress()), "VBase::onlyUserAndVesto - must include user's and Vesto's signatures");
        _;
    }

    modifier onlyRecoveryAndVesto(
        Signatures memory signatures
    ) {
        address[2] memory signedBy = validateSignatures(signatures);
        require((signedBy[0] == recoveryAddress() && signedBy[1] == vAddress()) || (signedBy[0] == vAddress() && signedBy[1] == recoveryAddress()), "VBase::onlyRecoveryAndVesto - must include recovery's and Vesto's signatures");
        _;
    }

    modifier onlyUserAndRecovery(
        Signatures memory signatures
    ) {
        address[2] memory signedBy = validateSignatures(signatures);
        require((signedBy[0] == userAddress() && signedBy[1] == recoveryAddress()) || (signedBy[0] == recoveryAddress() && signedBy[1] == userAddress()), "VBase::onlyUserAndRecovery - must include user's and recovery's signatures");
        _;
    }

    modifier onlyVErc20(
        address _address
    ) {
        require(vStore().isVErc20(_address), "VBase::onlyVErc20 - only vErc20 addresses supported");
        _;
    }

    function isEthereum(
    ) internal view returns (bool) {
        return (vStore().chainId() == ETHEREUM_MAINNET || vStore().chainId() == ETHEREUM_KOVAN || vStore().chainId() == ETHEREUM_GOERLI);
    }

    function isMatic(
    ) internal view returns (bool) {
        return (vStore().chainId() == MATIC_MUMBAI ||  vStore().chainId() == MATIC_MAINNET);
    }

    function key(
        string memory _key
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_key));
    }

    function version(
    ) override public pure returns (string memory) {
        return "1.0";
    }

    function institutionId(
    ) override public view returns (string memory) {
        return stringStorage[key("institutionId")];
    }

    function vStore(
    ) internal view returns (IVStore){
        return IVStore(addressStorage[key("vStoreProxyAddress")]);
    }

    function vAddress(
    ) internal view returns (address) {
        return addressStorage[key("vAddress")];
    }

    function userAddress(
    ) internal view returns (address) {
        return addressStorage[key("userAddress")];
    }

    function recoveryAddress(
    ) internal view returns (address) {
        return addressStorage[key("recoveryAddress")];
    }

    function setVAddress(
        address _address,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) onlyUserAndRecovery(
        Signatures(nonce, keccak256(abi.encodePacked(address(this), "setVAddress", _address, nonce)), V, R, S)
    ) override public {
        addressStorage[key("vAddress")] = _address;
    }

    function setUserAddress(
        address _address,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) onlyRecoveryAndVesto(
        Signatures(nonce, keccak256(abi.encodePacked(address(this), "setUserAddress", _address, nonce)), V, R, S)
    ) override public {
        addressStorage[key("userAddress")] = _address;
    }

    function setRecoveryAddress(
        address _address,
        string memory nonce,
        uint8[2] calldata V,
        bytes32[2] calldata R,
        bytes32[2] calldata S
    ) onlyUserAndVesto(
        Signatures(nonce, keccak256(abi.encodePacked(address(this), "setRecoveryAddress", _address, nonce)), V, R, S)
    ) override public {
        addressStorage[key("recoveryAddress")] = _address;
    }

    function isOwnerAddress(
        address _address
    ) internal view returns (bool) {
        return _address == vAddress() || _address == userAddress() || _address == recoveryAddress();
    }

    function validateSignatures(
        Signatures memory signatures
    ) internal returns (address[2] memory signedBy) {
        uint256 begin;
        uint256 end;
        (begin,end) = spliceTimestamps(signatures.nonce);
        require((end >= block.timestamp) && (begin < block.timestamp), "VBase::validateSignatures - invalid timestamps");
        require(!isThisNonceUsed(signatures.nonce), "VBase::validateSignatures - possible replay attack");

        address[2] memory addresses;
        for (uint i = 0; i < 2; i++) {
            uint8 csv = signatures.V[i];
            // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
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
        bytes32ToBoolStorage[key("nonces")][key(nonce)] = true;
    }

    function isThisNonceUsed(
        string memory nonce
    ) private view returns (bool) {
        return bytes32ToBoolStorage[key("nonces")][key(nonce)];
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

    function setOwnerAddresses(
        address _vAddress,
        address _userAddress,
        address _recoveryAddress
    ) internal {
        addressStorage[key("vAddress")] = _vAddress;
        addressStorage[key("userAddress")] = _userAddress;
        addressStorage[key("recoveryAddress")] = _recoveryAddress;
    }
}
abstract contract AVProxy is IVProxy, AVBase {

    event Received(uint256 amount, address sender);

    constructor (
        address vAddress,
        address userAddress,
        address recoveryAddress,
        string memory _implementationAddressKey,
        address vStoreProxyAddress
    ) {
        setOwnerAddresses(vAddress, userAddress, recoveryAddress);
        stringStorage[key("implementationAddressKey")] = _implementationAddressKey;
        addressStorage[key("vStoreProxyAddress")] = vStoreProxyAddress;
    }

    function implementationAddressKey(
    ) internal view returns (string memory) {
        return stringStorage[key("implementationAddressKey")];
    }

    function implementationAddress(
    ) override virtual public view returns (address) {
        return vStore().getAddress(implementationAddressKey());
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
        require(_implementationAddress != address(0), "VProxy::fallback - invalid implementation address");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _implementationAddress, ptr, calldatasize(), 0, 0)
            mstore(0x40, add(ptr, returndatasize()))
            returndatacopy(ptr, 0, returndatasize())
            switch result
            case 0 {revert(ptr, returndatasize())}
            default {return (ptr, returndatasize())}
        }
    }
}


contract VErc20Proxy is AVProxy {
    constructor (
        address vAddress,
        address userAddress,
        address recoveryAddress,
        address vStoreProxyAddress,
        address vFinanceProxyAddress,
        string memory name,
        string memory symbol,
        address underlying,
        string memory institutionId
    ) AVProxy(vAddress, userAddress, recoveryAddress, "vErc20Address", vStoreProxyAddress) {
        addressStorage[key("vFinanceProxyAddress")] = vFinanceProxyAddress;
        stringStorage[key("name")] = name;
        stringStorage[key("symbol")] = symbol;
        addressStorage[key("underlying")] = underlying;
        stringStorage[key("institutionId")] = institutionId;
    }

    function name(
    ) override public view returns (string memory) {
        return stringStorage[key("name")];
    }
}