/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier:MIT
// produced by the Solididy File Flattener (c) David Appleton 2018 - 2020 and beyond
// contact : [email protected]
// source  : https://github.com/DaveAppleton/SolidityFlattery
// released under Apache 2.0 licence
// input  /Users/chris/Git/vestollc/vesto-contracts/src/erc20/VErc20.sol
// flattened :  Monday, 24-May-21 15:53:32 UTC
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
abstract contract AStorage {

    struct Exchange {
        uint256 institutionApy;
        uint256 institutionRate;
        uint256 apy;
        uint256 rate;
        uint256 stamp;
    }

    struct Withdrawal {
        uint256 amount;
        uint256 stamp;
    }

    mapping(bytes32 => uint256) internal uint256Storage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => address[]) internal addressArrayStorage;
    mapping(bytes32 => bytes32) internal bytes32Storage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
    mapping(bytes32 => Exchange) internal exchangeStorage;
    mapping(bytes32 => Withdrawal[]) internal withdrawalArrayStorage;
    mapping(bytes32 => mapping(address => uint256)) internal addressToUnitStorage;
    mapping(bytes32 => mapping(address => bool)) internal addressToBoolStorage;
    mapping(bytes32 => mapping(address => address)) internal addressToAddressStorage;
    mapping(bytes32 => mapping(bytes32 => bool)) internal bytes32ToBoolStorage;
    mapping(bytes32 => mapping(bytes32 => address)) internal bytes32ToAddressStorage;
    mapping(bytes32 => mapping(address => mapping(address => uint256))) internal addressToAddressToUnitStorage;
    mapping(bytes32 => mapping(address => mapping(address => bool))) internal addressToAddressToBoolStorage;
    mapping(bytes32 => mapping(bytes32 => mapping(address => bool))) internal bytes32ToAddressToBoolStorage;
    mapping(bytes32 => mapping(address => mapping(bytes32 => bool))) internal addressToBytes32ToBoolStorage;

    // Storage keys.
    bytes32 constant VSTORE_ADDRESS = keccak256(abi.encodePacked("VSTORE_ADDRESS"));
    bytes32 constant VSTORE_PROXY_ADDRESS = keccak256(abi.encodePacked("VSTORE_PROXY_ADDRESS"));
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
    bytes32 constant USER_ADDRESSES = keccak256(abi.encodePacked("USER_ADDRESSES"));
    bytes32 constant RECOVERY_ADDRESS = keccak256(abi.encodePacked("RECOVERY_ADDRESS"));
    bytes32 constant WITHDRAWALS = keccak256(abi.encodePacked("WITHDRAWALS"));
    bytes32 constant NAME = keccak256(abi.encodePacked("NAME"));
    bytes32 constant SYMBOL = keccak256(abi.encodePacked("SYMBOL"));
    bytes32 constant SUPPLY = keccak256(abi.encodePacked("SUPPLY"));
    bytes32 constant BALANCES = keccak256(abi.encodePacked("BALANCES"));
    bytes32 constant UNDERLYING = keccak256(abi.encodePacked("UNDERLYING"));
    bytes32 constant ALLOWANCES = keccak256(abi.encodePacked("ALLOWANCES"));
    bytes32 constant NONCES = keccak256(abi.encodePacked(abi.encodePacked("NONCES")));
    bytes32 constant UNDERLYING_ADDRESS_KEY = keccak256(abi.encodePacked("UNDERLYING_ADDRESS_KEY"));
    bytes32 constant REDEEM_ADDRESS_KEY = keccak256(abi.encodePacked("REDEEM_ADDRESS_KEY"));
    bytes32 constant RAYUSDC_ADDRESS = keccak256(abi.encodePacked("RAYUSDC_ADDRESS"));
    bytes32 constant RAYDAI_ADDRESS = keccak256(abi.encodePacked("RAYDAI_ADDRESS"));
    bytes32 constant RAYETH_ADDRESS = keccak256(abi.encodePacked("RAYETH_ADDRESS"));
    bytes32 constant USDC_ADDRESS = keccak256(abi.encodePacked("USDC_ADDRESS"));
    bytes32 constant DAI_ADDRESS = keccak256(abi.encodePacked("DAI_ADDRESS"));
    bytes32 constant CHAIN_ID = keccak256(abi.encodePacked("CHAIN_ID"));
    bytes32 constant DAILY_LIMIT = keccak256(abi.encodePacked("DAILY_LIMIT"));
    bytes32 constant ERC20_PREDICATE_PROXY_ADDRESS = keccak256(abi.encodePacked("ERC20_PREDICATE_PROXY_ADDRESS"));
    bytes32 constant ROOT_CHAIN_MANAGER_PROXY_ADDRESS = keccak256(abi.encodePacked("ROOT_CHAIN_MANAGER_PROXY_ADDRESS"));
    bytes32 constant CHILD_CHAIN_MANAGER_PROXY_ADDRESS = keccak256(abi.encodePacked("CHILD_CHAIN_MANAGER_PROXY_ADDRESS"));

    function key(
        string memory _key
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_key));
    }
}
interface IOwnable {

    function setUserAddresses(
        address[] memory addresses,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    function setRecoveryAddress(
        address _address,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;
}
interface IBase is IOwnable {

    function name(
    ) external view returns (string memory);

    function version(
    ) external pure returns (string memory);
}
interface IVStore is IBase {

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

    function exchange(
        bytes32 symbol
    ) external view returns(uint256, uint256, uint256, uint256);

    function setExchanges(
        bytes32[] memory symbols,
        uint256[] memory institutionApys,
        uint256[] memory apys,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) external;

    event SetExchanges(
        uint256[] institutionRates,
        uint256[] rates
    );
}
interface IVErc20 is IBase, IErc20 {

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

    function deposit(
        address user,
        bytes calldata depositData
    ) external;

    function withdraw(
        uint256 amount
    ) external;

    function exchangeRate(
    ) external view returns (uint256);

    event Mint(
        uint256 tokens,
        uint256 underlyingTokens
    );

    event Redeem(
        uint256 tokens,
        uint256 underlyingTokens
    );
}
interface IVFinance is IBase {

    function balanceOf(
        IErc20 iErc20
    ) external view returns (uint256);

    function balanceOfUnderlying(
    ) external;

    function mint(
        uint256 underlyingTokens
    ) external returns (uint256, uint256);

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

    event BalanceOfUnderlying(
        uint256 underlyingTokens
    );
}
abstract contract ABase is IBase, AStorage {

    using SafeMath for uint256;

    uint256 constant ETHEREUM_MAINNET = 1;
    uint256 constant ETHEREUM_GOERLI = 5;
    uint256 constant ETHEREUM_KOVAN = 42;
    uint256 constant POLYGON_MAINNET = 137;
    uint256 constant POLYGON_MUMBAI = 8001;

    struct Signatures {
        string nonce;
        bytes32 hash;
        uint8[] V;
        bytes32[] R;
        bytes32[] S;
    }

    modifier onlyEthereum(
    ) {
        require(isEthereum(), "VBase::onlyEthereum - function only supported on Ethereum");
        _;
    }

    modifier onlyPolygon(
    ) {
        require(isPolygon(), "VBase::onlyPolygon - function only supported on Polygon");
        _;
    }

    modifier onlyUserAndVesto(
        Signatures memory signatures
    ) {
        address[] memory signedBy = validateSignatures(signatures);
        require((isUserAddress(signedBy[0]) && signedBy[1] == vAddress()) || (signedBy[0] == vAddress() && isUserAddress(signedBy[1])), "VBase::onlyUserAndVesto - must include user's and Vesto's signatures");
        _;
    }

    modifier onlyRecoveryAndVesto(
        Signatures memory signatures
    ) {
        address[] memory signedBy = validateSignatures(signatures);
        require((signedBy[0] == recoveryAddress() && signedBy[1] == vAddress()) || (signedBy[0] == vAddress() && signedBy[1] == recoveryAddress()), "VBase::onlyRecoveryAndVesto - must include recovery's and Vesto's signatures");
        _;
    }

    modifier onlyUserAndRecovery(
        Signatures memory signatures
    ) {
        address[] memory signedBy = validateSignatures(signatures);
        require((isUserAddress(signedBy[0]) && signedBy[1] == recoveryAddress()) || (signedBy[0] == recoveryAddress() && isUserAddress(signedBy[1])), "VBase::onlyUserAndRecovery - must include user's and recovery's signatures");
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

    function isPolygon(
    ) internal view returns (bool) {
        return (vStore().chainId() == POLYGON_MUMBAI || vStore().chainId() == POLYGON_MAINNET);
    }

    function version(
    ) override public pure returns (string memory) {
        return "1.0";
    }

    function vStore(
    ) internal view returns (IVStore){
        return IVStore(addressStorage[VSTORE_PROXY_ADDRESS]);
    }

    function vAddress(
    ) virtual internal view returns (address) {
        return vStore().getAddress(VADDRESS);
    }

    function userAddresses(
    ) internal view returns (address[] memory) {
        return addressArrayStorage[USER_ADDRESSES];
    }

    function recoveryAddress(
    ) internal view returns (address) {
        return addressStorage[RECOVERY_ADDRESS];
    }

    function setUserAddresses(
        address[] memory addresses,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) onlyRecoveryAndVesto(
        Signatures(nonce, keccak256(abi.encodePacked(address(this), "setUserAddresses", addresses, nonce)), V, R, S)
    ) override public {
        addressArrayStorage[USER_ADDRESSES] = addresses;
    }

    function setRecoveryAddress(
        address _address,
        string memory nonce,
        uint8[] memory V,
        bytes32[] memory R,
        bytes32[] memory S
    ) onlyUserAndVesto(
        Signatures(nonce, keccak256(abi.encodePacked(address(this), "setRecoveryAddress", _address, nonce)), V, R, S)
    ) override public {
        addressStorage[RECOVERY_ADDRESS] = _address;
    }

    function isOwnerAddress(
        address _address
    ) internal view returns (bool) {
        return _address == vAddress() || isUserAddress(_address) || _address == recoveryAddress();
    }

    function isUserAddress(
        address _address
    ) internal view returns (bool) {
        for (uint i = 0; i < userAddresses().length; i++) {
            if (userAddresses()[i] == _address) {
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
        uint256 multiplier = 10 ** (18 + 18 - erc20.decimals());
        // USDC 1e6 x 1e30 ➗ 1e18 -> 1e18
        uint256 convertedTokens = tokens
        .mul(multiplier)
        .mul(rate)
        .div(1e18)
        .div(1e18);

        if (pairedErc20.decimals() != 18) {
            multiplier = 10 ** (18 + 18 - pairedErc20.decimals());
            // USDC 1e18 x 1e18 ➗ 1e30 -> 1e6
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
        return IErc20(vStore().getAddress(bytes32Storage[UNDERLYING_ADDRESS_KEY]));
    }

    function vFinance(
    ) internal view returns (IVFinance) {
        return IVFinance(vStore().getAddress(VFINANCE_PROXY_ADDRESS));
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
        address account
    ) override public view returns (uint256) {
        return addressToUnitStorage[BALANCES][account];
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
        return approveInternal(msg.sender, spender, tokens);
    }

    function approveInternal(
        address account,
        address spender,
        uint256 tokens
    ) internal returns (bool) {
        setAllowance(account, spender, tokens);
        emit Approval(account, spender, tokens);
        return true;
    }

    function transfer(
        address to,
        uint256 tokens
    ) override public returns (bool) {
        transferInternal(msg.sender, to, tokens);
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
        transferInternal(from, to, tokens);
        return true;
    }

    function transferInternal(
        address from,
        address to,
        uint256 tokens
    ) internal {
        uint256 fromBalance = balanceOf(from);
        uint256 toBalance = balanceOf(to);
        require(from != to, "VErc20::transferInternal - from and to address cannot be the same");
        require(from != address(0), "VErc20::transferInternal - from address cannot be zero");
        require(to != address(0), "VErc20::transferInternal - to address cannot be zero");
        require(fromBalance >= tokens, "VErc20::transferInternal - insufficient tokens");
        setBalance(from, fromBalance.sub(tokens));
        setBalance(to, toBalance.add(tokens));
        emit Transfer(from, to, tokens);
    }

    function balanceOfUnderlying(
        address account
    ) override public view returns (uint256) {
        return convert(IErc20(address(this)), underlying(), exchangeRate(), balanceOf(account));
    }

    function totalBalanceOfUnderlying(
    ) override public view returns (uint256) {
        return convert(IErc20(address(this)), underlying(), exchangeRate(), totalSupply());
    }

    function redeemAddress(
    ) internal view returns (address) {
        return vStore().getAddress(bytes32Storage[REDEEM_ADDRESS_KEY]);
    }

    function vDistributionProxyAddress(
    ) internal view returns (address) {
        return vStore().getAddress(VDISTRIBUTION_PROXY_ADDRESS);
    }

    function mint(
    ) onlyEthereum(
    ) override public {
        uint256 underlyingTokens = underlying().balanceOf(address(this));
        require(underlyingTokens > 0, "VErc20:mint - there are no underlying tokens to mint");

        uint256 tokens;
        if (vStore().chainId() == ETHEREUM_KOVAN || vStore().chainId() == ETHEREUM_MAINNET) {
            require(underlying().transfer(address(vFinance()), underlyingTokens), "VErc20:mint - failed to transfer tokens to vFinance");
            (tokens,) = vFinance().mint(underlyingTokens);
        } else {
            tokens = convert(underlying(), IErc20(address(this)), exchangeRate(), underlyingTokens);
        }
        setBalance(address(this), balanceOf(address(this)).add(tokens));
        setSupply(totalSupply().add(tokens));
        emit Mint(tokens, underlyingTokens);
        emit Transfer(address(0), address(this), tokens);

        if (vStore().chainId() == ETHEREUM_GOERLI || vStore().chainId() == ETHEREUM_MAINNET) {
            require(approveInternal(address(this), vStore().getAddress(ERC20_PREDICATE_PROXY_ADDRESS), tokens), "VErc20:mint - failed to approve ERC20_PREDICATE_PROXY_ADDRESS");
            IRootChainManager(vStore().getAddress(ROOT_CHAIN_MANAGER_PROXY_ADDRESS)).depositFor(vDistributionProxyAddress(), address(this), abi.encodePacked(tokens));
        } else {
            transferInternal(address(this), vDistributionProxyAddress(), tokens);
        }
    }

    function redeem(
    ) onlyEthereum(
    ) override public {
        uint256 tokens = balanceOf(address(this));
        require(tokens > 0, "VErc20:mint - there are no tokens to redeem");

        uint256 underlyingTokens;
        if (vStore().chainId() == ETHEREUM_KOVAN || vStore().chainId() == ETHEREUM_MAINNET) {
            (, underlyingTokens) = vFinance().redeem(tokens);
            setBalance(address(this), balanceOf(address(this)).sub(tokens));
            setSupply(totalSupply().sub(tokens));
            emit Redeem(tokens, underlyingTokens);
            emit Transfer(address(0), address(this), tokens);
        } else {
            underlyingTokens = convert(IErc20(address(this)), underlying(), exchangeRate(), underlyingTokens);
        }
        underlying().transfer(redeemAddress(), underlyingTokens);
    }

    function deposit(
        address user, bytes calldata depositData
    ) onlyPolygon(
    ) override public {
        require(msg.sender == vStore().getAddress(CHILD_CHAIN_MANAGER_PROXY_ADDRESS), "VErc20::deposit - sender is not child chain proxy");
        uint256 tokens = abi.decode(depositData, (uint256));

        setBalance(user, balanceOf(user).add(tokens));
        setSupply(totalSupply().add(tokens));

        emit Transfer(address(0), user, tokens);
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
        uint256 rate;
        (,,, rate) = vStore().exchange(key(symbol()));
        return rate;
    }
}