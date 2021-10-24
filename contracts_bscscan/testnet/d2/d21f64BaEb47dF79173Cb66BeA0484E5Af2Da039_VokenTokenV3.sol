/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;



// Part: Address

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

// Part: Context

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

// Part: Counters

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// Part: ECDSA

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(
                vs,
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(s.length),
                    s
                )
            );
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// Part: IERC20

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Part: IERC20Permit

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// Part: IPancakeV2Factory

interface IPancakeV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Part: IPancakeV2Router

interface IPancakeV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// Part: Math

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// Part: SafeCast

library SafeCast {  
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// Part: SafeMath

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
}

// Part: Strings

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// Part: EIP712

abstract contract EIP712 {
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion
        );
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (
            address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID
        ) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return
                _buildDomainSeparator(
                    _TYPE_HASH,
                    _HASHED_NAME,
                    _HASHED_VERSION
                );
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// Part: IERC20Metadata

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// Part: Manageable

abstract contract Manageable is Context {
    address private _manager;
    event ManagementTransferred(
        address indexed previousManager,
        address indexed newManager
    );

    constructor() {
        address msgSender = _msgSender();
        _manager = msgSender;
        emit ManagementTransferred(address(0), msgSender);
    }

    function manager() public view returns (address) {
        return _manager;
    }

    modifier onlyManager() {
        require(
            _manager == _msgSender(),
            "Manageable: caller is not the manager"
        );
        _;
    }

    // A function that allows an inheriting contract to override its behavior will be marked at virtual
    function transferManagement(address newManager)
        external
        virtual
        onlyManager
    {
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }
}

// Part: Ownable

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner, bool safety_param)
        public
        virtual
        onlyOwner
    {
        require(safety_param);
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time, bool safety_param) public virtual onlyOwner {
        require(safety_param);
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock(bool safety_param) public virtual {
        require(safety_param);
        require(
            _previousOwner == msg.sender,
            "Only the previous owner can unlock onwership"
        );
        require(block.timestamp > _lockTime, "The contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// Part: Tokenomics

abstract contract Tokenomics {
    using SafeMath for uint256;

    string internal constant NAME = "VokenDeploy20";
    string internal constant SYMBOL = "VKND20";

    uint16 internal constant FEES_DIVISOR = 10**3;
    uint8 internal constant DECIMALS = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant TOTAL_SUPPLY = 10_000_000 * 10**DECIMALS;
    uint256 internal _reflectedSupply = (MAX - (MAX % TOTAL_SUPPLY));

    /**
     * @dev Set the maximum transaction amount allowed in a transfer: 1% of the total supply
     */
    uint256 internal constant maxTransactionAmount = TOTAL_SUPPLY / 100;

    /**
     * @dev Set the maximum allowed balance in a wallet: 4% of total supply
     */
    uint256 internal constant maxWalletBalance = TOTAL_SUPPLY / 25;

    /**
     * @dev Set the number of tokens to (activate) swap and add to liquidity: 0.05% of the total supply
     *
     * Whenever the contract's balance reaches this number of tokens (=threshold), a swap & liquify will be
     * executed in the very next transfer (via the `_beforeTokenTransfer`)
     *
     * See: `Liquifier`
     */
    uint256 internal constant thresholdSwapToLiquidity = TOTAL_SUPPLY / 5_000; 

    // TODO: change this
    address internal rndAddress = 0x71422DfAc007920d47D3A32724C1431671b73F1D;
    address internal fundAddress = 0x3Df416497347A20BDb3B124B081A18c029E0675C;
    address internal controlledBurnAddress = 0x6daE480fA27A1314D8c1E5a291Ec18ec0e489735;
    address internal definitiveBurnAddress = 0x000000000000000000000000000000000000dEaD;

    enum FeeType {Liquidity, Rfi, External}

    struct Fee {
        FeeType name;
        uint256 value;
        address recipient;
        uint256 total;
    }

    Fee[] internal fees;
    uint256 internal sumOfFees;

    constructor() {
        _addFees();
    }

    function _addFee(FeeType name, uint256 value, address recipient) private {
        fees.push(Fee(name, value, recipient, 0));
        sumOfFees += value;
    }
     
    // The value of fees is given in part per 1000 (based on the value of FEES_DIVISOR)   
    function _addFees() private {
        _addFee(FeeType.Rfi, 20, address(this));
        _addFee(FeeType.External, 50, fundAddress);
        _addFee(FeeType.Liquidity, 40, address(this));
        _addFee(FeeType.External, 40, rndAddress);
    }

    function _getFeesCount() internal view returns (uint256) {
        return fees.length;
    }

    function _getFeeStruct(uint256 index) private view returns (Fee storage) {
        require(
            index >= 0 && index < fees.length,
            "FeesSettings._getFeeStruct: Fee index out of bounds"
        );
        return fees[index];
    }

    function getFee(uint256 index) public view returns (FeeType, uint256, address, uint256) {
        Fee memory fee = _getFeeStruct(index);
        return (fee.name, fee.value, fee.recipient, fee.total);
    }

    function _addFeeCollectedAmount(uint256 index, uint256 amount) internal {
        Fee storage fee = _getFeeStruct(index);
        fee.total = fee.total.add(amount);
    }

    function getCollectedFeeTotal(uint256 index) external view returns (uint256) {
        Fee memory fee = _getFeeStruct(index);
        return fee.total;
    }
}

// Part: Antiwhale

abstract contract Antiwhale is Tokenomics {
    /**
     * @dev Returns the total sum of fees in per-mille (FEES_DIVISOR value)
     */
    function _getAntiwhaleFees(uint256, uint256) internal view returns (uint256) {
        return sumOfFees;
    }
}

// Part: Liquifier

abstract contract Liquifier is Ownable, Manageable {
    using SafeMath for uint256;

    uint256 private withdrawableBalance;

    enum Env {Testnet, MainnetV1, MainnetV2} //TODO: remove Testnet and all it's corresponing calls
    Env private _env;

    // MultiSigWallet for safety of the lp tokens
    address private multiSigWallet = 0x42489c73E040fF7a3dA77294A54fA0a617550072; //TODO: change this after the deployment of the multisig wallet

    // PancakeSwap V1
    address private _mainnetRouterV1Address = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    // PancakeSwap V2
    address private _mainnetRouterV2Address = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // Testnet
    address private _testnetRouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //TODO: remove this

    IPancakeV2Router internal _router;
    // PanCakeSwap pair
    address internal _pair;

    bool private inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;

    uint256 private maxTransactionAmount;
    uint256 private thresholdSwapToLiquidity;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event RouterSet(address indexed router);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);

    receive() external payable {}

    function initializeLiquiditySwapper(Env env, uint256 maxTx, uint256 liquifyAmount) internal {
        _env = env;
        if (_env == Env.MainnetV1) {
            _setRouterAddress(_mainnetRouterV1Address);
        } else if (_env == Env.MainnetV2) {
            _setRouterAddress(_mainnetRouterV2Address);
        }
        /*(_env == Env.Testnet)*/
        else {
            _setRouterAddress(_testnetRouterAddress);
        }

        maxTransactionAmount = maxTx;
        thresholdSwapToLiquidity = liquifyAmount;
    }

    function liquify(uint256 contractTokenBalance, address sender) internal {
        if (contractTokenBalance >= maxTransactionAmount)
            contractTokenBalance = maxTransactionAmount;

        bool isOverRequiredTokenBalance = (contractTokenBalance >=
            thresholdSwapToLiquidity);

        /**
         * 1) check if the contract has collected enough tokens
         * 2) check if swap and liquify is enabled
         * 3) make sure not to get caught in a circular liquidity event
         * 4) don't swap & liquify if the sender = PanCakeSwap pair
         */
        if (
            isOverRequiredTokenBalance &&
            swapAndLiquifyEnabled &&
            !inSwapAndLiquify &&
            (sender != _pair)
        ) {
            _swapAndLiquify(contractTokenBalance);
        }
    }

    /**
     * @dev sets the router address and created the router + factory pair to enable
     * swapping and liquifying the contract Vokens
     */
    function _setRouterAddress(address router) private {
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(router);
        _pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(
            address(this),
            _newPancakeRouter.WETH()
        );
        _router = _newPancakeRouter;
        emit RouterSet(router);
    }

    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        uint256 initialBalance = address(this).balance;

        // swap Vokens for BNB
        _swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the PanCakeSwap pair path of Vokens -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approveDelegate(address(this), address(_router), tokenAmount);

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approveDelegate(address(this), address(_router), tokenAmount);

        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = _router.addLiquidityETH{value: ethAmount}(
            address(this), tokenAmount, 0, 0, 
            multiSigWallet,
            block.timestamp);

        withdrawableBalance = address(this).balance;
        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);
    }

    /**
     * @dev Sets the PanCakeSwapV2 pair (router & factory) for swapping and liquifying tokens.
     * This is a precaution taken to upgrade the router address if PancakeSwap decided to move on to v3
     */
    function setRouterAddress(address router) external onlyManager {
        _setRouterAddress(router);
    }

    /**
     * @dev Sends the swap and liquify flag to the provided value.
     * If set to `false` tokens collected in the contract will not be converted into liquidity.
     */
    function setSwapAndLiquifyEnabled(bool enabled) external onlyManager {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }

    /**
     * @dev The owner can withdraw BNB collected in the contract from `swapAndLiquify`
     * or if someone (accidentally) sends BNB directly to the contract.
     */
    function withdrawLockedEth(address payable recipient) external onlyManager {
        require(recipient != address(0), "Cannot withdraw the BNB balance to the zero address");
        require(withdrawableBalance > 0, "The BNB balance must be greater than 0");

        // prevent re-entrancy attacks
        uint256 amount = withdrawableBalance;
        withdrawableBalance = 0;
        recipient.transfer(amount);
    }

    /**
     * @dev Use this delegate instead of having (unnecessarily) extend `BaseRfiToken` to gained access to the `_approve` function.
     */
    function _approveDelegate(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual;
}

// Part: Presaleable

// The fee tokenomics start after the token auction. To achive this, a "isInPresale" flag is used.
abstract contract Presaleable is Manageable {
    bool internal isInPresale;

    function setPreseableEnabled(bool value) external onlyManager {
        isInPresale = value;
    }
}

// Part: BaseRfiToken

abstract contract BaseRfiToken is IERC20, IERC20Metadata, Ownable, Presaleable, Tokenomics {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) internal _reflectedBalances;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    mapping(address => bool) internal _isExcludedFromFee;
    mapping(address => bool) internal _isExcludedFromRewards;
    address[] private _excluded;

    constructor() {
        _reflectedBalances[owner()] = _reflectedSupply;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[rndAddress] = true;
        _isExcludedFromFee[address(this)] = true;

        /**
        * @dev the controlledBurnAddress is excluded from rewards (no rfi).
        *
        * 'controlledBurnAddress' is a temporary 'deposit' address for the Vokens that will be burnt.
        * The community will vote the amount of Vokens that should be send to the 
        * 'definitiveBurnAddress':  0x000000000000000000000000000000000000dEaD.
        * This 'definitiveBurnAddress' is included in rewards (in rfi).
        * By doing so, the amount of rewards distributed among the Voken holders will be impacted by
        * the amount of Vokens in the 'definitiveBurnAddress'. 
        * The more Vokens the 'definitiveBurnAddress' contains, the less rewards all other Voken holders
        * will recieve.
        */
        _exclude(address(this));
        _exclude(controlledBurnAddress);

        emit Transfer(address(0), owner(), TOTAL_SUPPLY);
    }

    /** Functions required by IERC20Metadata **/
    function name() external pure override returns (string memory) {
        return NAME;
    }

    function symbol() external pure override returns (string memory) {
        return SYMBOL;
    }

    function decimals() external pure override returns (uint8) {
        return DECIMALS;
    }
    /** Functions required by IERC20Metadat - END **/

    /** Functions required by IERC20 **/
    function totalSupply() external pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromRewards[account]) return _balances[account];
        return tokenFromReflection(_reflectedBalances[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(), 
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromRewards[account];
    }

    /**
     * @dev Calc and returns the reflected amount for a given amount. (with or without the transfer fees)
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
        require(tAmount <= TOTAL_SUPPLY, "Amount must be less than the total supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount, 0);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(
                tAmount,
                _getSumOfFees(_msgSender(), tAmount)
            );
            return rTransferAmount;
        }
    }

    /**
     * @dev Calc and returns the amount of Vokens corresponding to the given reflected amount.
     */
    function tokenFromReflection(uint256 rAmount) internal view returns (uint256) {
        require(rAmount <= _reflectedSupply, "Amount must be less than total reflections");
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcludedFromRewards[account], "Account is not included");
        _exclude(account);
    }

    function _exclude(address account) internal {
        if (_reflectedBalances[account] > 0) {
            _balances[account] = tokenFromReflection(
                _reflectedBalances[account]
            );
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balances[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function setExcludedFromFee(address account, bool value) external onlyOwner {
        _isExcludedFromFee[account] = value;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BaseRfiToken: approve from the zero address");
        require(spender != address(0), "BaseRfiToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // used to send tokens to LP, ICO, DEX, ...
    function _isUnlimitedSender(address account) internal view returns (bool) {
        return (account == owner());
    }

    function _isUnlimitedRecipient(address account) internal view returns (bool) {
        return (account == owner() || 
        account == controlledBurnAddress || account == rndAddress ||
        account == definitiveBurnAddress);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BaseRfiToken: transfer from the zero address");
        require(recipient != address(0), "BaseRfiToken: transfer to the zero address");
        require(sender != address(fundAddress), "BaseRfiToken: transfer from the fund address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;

        if (isInPresale) {
            takeFee = false;
        } else {
            if (
                amount > maxTransactionAmount &&
                !_isUnlimitedSender(sender) &&
                !_isUnlimitedRecipient(recipient)
            ) {
                revert("Transfer amount exceeds the maxTxAmount.");
            }

            // The pair (lp) needs to be excluded from the max wallet balance check;
            if (
                maxWalletBalance > 0 &&
                !_isUnlimitedSender(sender) &&
                !_isUnlimitedRecipient(recipient) &&
                !_isV2Pair(recipient)
            ) {
                uint256 recipientBalance = balanceOf(recipient);
                require(
                    recipientBalance + amount <= maxWalletBalance,
                    "New balance would exceed the maxWalletBalance"
                );
            }
        }

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        _beforeTokenTransfer(sender, recipient, amount, takeFee);
        _transferTokens(sender, recipient, amount, takeFee);
    }

    function _transferTokens(address sender, address recipient, uint256 amount, bool takeFee) private {
        uint256 sumOfFees = _getSumOfFees(sender, amount);
        if (!takeFee) {
            sumOfFees = 0;
        }

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tAmount,
            uint256 tTransferAmount,
            uint256 currentRate
        ) = _getValues(amount, sumOfFees);

        /**
         * Sender's and Recipient's reflected balances must always be updated regardless of
         * whether they're excluded from rewards or not.
         */
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(rAmount);
        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(
            rTransferAmount
        );

        /**
         * Update the true/nominal balances for the excluded accounts
         */
        if (_isExcludedFromRewards[sender]) {
            _balances[sender] = _balances[sender].sub(tAmount);
        }
        if (_isExcludedFromRewards[recipient]) {
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
        }

        _takeFees(amount, currentRate, sumOfFees);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeFees(uint256 amount, uint256 currentRate, uint256 sumOfFees) private {
        if (sumOfFees > 0 && !isInPresale) {
            _takeTransactionFees(amount, currentRate);
        }
    }

    function _getValues(uint256 tAmount, uint256 feesSum) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 currentRate = _getCurrentRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);

        return (rAmount, rTransferAmount, tAmount, tTransferAmount, currentRate);
    }

    function _getCurrentRate() internal view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() internal view returns (uint256, uint256) {
        uint256 rSupply = _reflectedSupply;
        uint256 tSupply = TOTAL_SUPPLY;

        /**
         * Remove balances of addresses excluded from rewards from rSupply and tSupply, which 
         * effectively increases the % of transaction fees delivered to non-excluded holders
         */
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectedBalances[_excluded[i]] > rSupply ||
                _balances[_excluded[i]] > tSupply
            ) return (_reflectedSupply, TOTAL_SUPPLY);
            rSupply = rSupply.sub(_reflectedBalances[_excluded[i]]);
            tSupply = tSupply.sub(_balances[_excluded[i]]);
        }
        if (tSupply == 0 || rSupply < _reflectedSupply.div(TOTAL_SUPPLY))
            return (_reflectedSupply, TOTAL_SUPPLY);
        return (rSupply, tSupply);
    }

    /**
     * @dev Hook, called before any transfer.
     */
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal virtual;

    /**
     * @dev Returns the total sum of fees to be processed in each transaction.
     */
    function _getSumOfFees(address sender, uint256 amount) internal view virtual returns (uint256);

    /**
     * @dev A delegate, return true if the given address is the V2 Pair and false otherwise
     */
    function _isV2Pair(address account) internal view virtual returns (bool);

    /**
     * @dev Redistributes the amount among the current holders via the reflect.finance algorithm.
     */
    function _redistribute(uint256 amount, uint256 currentRate, uint256 fee, uint256 index) internal {
        uint256 tFee = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rFee = tFee.mul(currentRate);

        _reflectedSupply = _reflectedSupply.sub(rFee);
        _addFeeCollectedAmount(index, tFee);
    }

    /**
     * @dev Hook, called before the `Transfer` event is emitted. (if the fees are enabled for the transfer)
     */
    function _takeTransactionFees(uint256 amount, uint256 currentRate) internal virtual;


    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


}

// Part: ERC20Permit

abstract contract ERC20Permit is BaseRfiToken, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor() EIP712(NAME, "1") {}

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// Part: VokenToken

abstract contract VokenToken is BaseRfiToken, Liquifier, Antiwhale {
    using SafeMath for uint256;

    // constructor(string memory _name, string memory _symbol, uint8 _decimals){ TODO: check tf is this
    constructor(Env _env) {
        initializeLiquiditySwapper(_env, maxTransactionAmount, thresholdSwapToLiquidity);
        _exclude(_pair);
    }

    function _isV2Pair(address account) internal view override returns (bool) {
        return (account == _pair);
    }

    function _getSumOfFees(address sender, uint256 amount)
        internal
        view
        override
        returns (uint256)
    {
        return _getAntiwhaleFees(balanceOf(sender), amount);
    }

    // function _beforeTokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal override {
    function _beforeTokenTransfer(address sender, address, uint256, bool) internal override {
        if (!isInPresale) {
            uint256 contractTokenBalance = balanceOf(address(this));
            liquify(contractTokenBalance, sender);
        }
    }

    function _takeTransactionFees(uint256 amount, uint256 currentRate) internal override {
        if (isInPresale) {
            return;
        }

        uint256 feesCount = _getFeesCount();
        for (uint256 index = 0; index < feesCount; index++) {
            (FeeType name, uint256 value, address recipient, ) = getFee(index);
            // no need to check value < 0 as the value is uint
            if (value == 0) continue;
            if (name == FeeType.Rfi) {
                _redistribute(amount, currentRate, value, index);
            } else {
                _takeFee(amount, currentRate, value, recipient, index);
            }
        }
    }

    function _takeFee(uint256 amount, uint256 currentRate, uint256 fee, address recipient, uint256 index) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAmount);

        if (_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);

        _addFeeCollectedAmount(index, tAmount);
    }

    function _approveDelegate(address owner, address spender, uint256 amount) internal override {
        _approve(owner, spender, amount);
    }
}

// Part: ERC20Votes

abstract contract ERC20Votes is ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    function delegate(address delegatee) public virtual {
        _delegate(_msgSender(), delegatee);
    }

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}

// File: VokenTokenV3.sol

contract VokenTokenV3 is VokenToken, ERC20Permit, ERC20Votes {
    constructor() VokenToken(Env.Testnet) ERC20Permit() { //TODO: change this to mainnetv2
        _approve(owner(), address(_router), ~uint256(0));
    }
}