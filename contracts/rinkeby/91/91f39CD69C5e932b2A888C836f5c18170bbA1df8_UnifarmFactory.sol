pragma solidity =0.5.16;

import './interfaces/IUnifarmFactory.sol';
import './UnifarmPair.sol';
import './Ownable.sol';
import './BaseRelayRecipient.sol';

contract UnifarmFactory is IUnifarmFactory, Ownable, BaseRelayRecipient {
    address payable public feeTo;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    struct Pair {
        bool lpFeesInToken;
        bool swapFeesInToken;
        uint256 lpFee;
        uint256 swapFee;
    }
    mapping(address => Pair) public pairConfigs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor(
        address payable _feeTo,
        address _trustedForwarder,
        uint256 _lpFee,
        uint256 _swapFee,
        bool _lpFeesInToken,
        bool _swapFeesInToken
    ) public {
        require(_feeTo != address(0), 'Unifarm: WALLET_ZERO_ADDRESS');
        feeTo = _feeTo;

        Pair memory pair;
        pair.lpFeesInToken = _lpFeesInToken;
        pair.swapFeesInToken = _swapFeesInToken;
        pair.lpFee = _lpFee;
        pair.swapFee = _swapFee;

        trustedForwarder = _trustedForwarder;

        pairConfigs[address(0)] = pair;
    }

    /*
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract.
     */
    function versionRecipient() external view returns (string memory) {
        return '1';
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Unifarm: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Unifarm: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Unifarm: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UnifarmPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUnifarmPair(pair).initialize(token0, token1, trustedForwarder);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction

        Pair memory globalConfig = pairConfigs[address(0)];
        pairConfigs[pair] = globalConfig;

        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address payable _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function updateLPFeeConfig(
        address _pairAddress,
        bool _feeInToken,
        uint256 _fee
    ) external onlyOwner {
        //To set max and min limit for both fee types
        Pair storage pair = pairConfigs[_pairAddress];
        pair.lpFeesInToken = _feeInToken;
        pair.lpFee = _fee;
    }

    function updateSwapFeeConfig(
        address _pairAddress,
        bool _feeInToken,
        uint256 _fee
    ) external onlyOwner {
        //To set max and min limit for both fee types
        Pair storage pair = pairConfigs[_pairAddress];
        pair.lpFeesInToken = _feeInToken;
        pair.lpFee = _fee;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IUnifarmFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address payable);
    function pairConfigs(address)
        external
        view
        returns (
            bool lpFeesInToken,
            bool swapFeesInToken,
            uint256 lpFee,
            uint256 swapFee
        );

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address payable) external;
}

pragma solidity =0.5.16;

import './interfaces/IUnifarmPair.sol';
import './UnifarmERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUnifarmFactory.sol';
import './interfaces/IUnifarmCallee.sol';

contract UnifarmPair is IUnifarmPair, UnifarmERC20 {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Unifarm: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Unifarm: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        address _trustedForwarder
    ) external {
        require(msg.sender == factory, 'Unifarm: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        trustedForwarder = _trustedForwarder;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Unifarm: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function _deductTokenFee(
        address _feeTo,
        uint256 _feeInReserve0,
        uint256 _feeInReserve1
    ) internal {
        _safeTransfer(token0, _feeTo, _feeInReserve0);
        _safeTransfer(token1, _feeTo, _feeInReserve1);
    }

    function _deductETHFee(address payable _feeTo, uint256 _fee) internal {
        require(msg.value >= _fee, 'Unifarm: REQUIRE_FEE');
        _feeTo.transfer(_fee);
    }

    function _mintFee(uint256 _reserve0, uint256 _reserve1)
        private
        returns (uint256 feeInReserve0, uint256 feeInReserve1)
    {
        (bool lpFeesInToken, , uint256 lpFee, ) = IUnifarmFactory(factory).pairConfigs(address(this));
        address payable feeTo = IUnifarmFactory(factory).feeTo();
        bool feeOn = feeTo != address(0);

        if (feeOn) {
            if (lpFeesInToken) {
                feeInReserve0 = (_reserve0.mul(lpFee)) / (1000);
                feeInReserve1 = (_reserve1.mul(lpFee)) / (1000);
                _deductTokenFee(feeTo, feeInReserve0, feeInReserve1);
            } else {
                _deductETHFee(feeTo, lpFee);
            }
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external payable lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        (uint256 feeInReserve0, uint256 feeInReserve1) = _mintFee(amount0, amount1);
        amount0 = amount0.sub(feeInReserve0);
        amount1 = amount1.sub(feeInReserve1);

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'Unifarm: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);

        emit Mint(_msgSender(), amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external payable lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Unifarm: INSUFFICIENT_LIQUIDITY_BURNED');

        (uint256 feeInReserve0, uint256 feeInReserve1) = _mintFee(amount0, amount1);
        amount0 = amount0.sub(feeInReserve0);
        amount1 = amount1.sub(feeInReserve1);

        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(_msgSender(), amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external payable lock {
        require(amount0Out > 0 || amount1Out > 0, 'Unifarm: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Unifarm: INSUFFICIENT_LIQUIDITY');

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'Unifarm: INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IUnifarmCallee(to).unifarmCall(_msgSender(), amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

        require(amount0In > 0 || amount1In > 0, 'Unifarm: INSUFFICIENT_INPUT_AMOUNT');
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 fee0;
            uint256 fee1;
            if (amount0In > 0) fee0 = _swapFee(token0, amount0In);
            if (amount1In > 0) fee1 = _swapFee(token1, amount1In);
            uint256 balance0Adjusted = balance0.mul(1000).sub(fee0);
            uint256 balance1Adjusted = balance1.mul(1000).sub(fee1);
            require(
                balance0Adjusted.mul(balance1Adjusted) >= uint256(_reserve0).mul(_reserve1).mul(1000**2),
                'Unifarm: K'
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(_msgSender(), amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function _swapFee(address _token, uint256 _amount) internal returns (uint256 fee) {
        (, bool swapFeesInToken, , uint256 swapFee) = IUnifarmFactory(factory).pairConfigs(address(this));
        address payable feeTo = IUnifarmFactory(factory).feeTo();
        bool feeOn = feeTo != address(0);

        if (feeOn) {
            if (swapFeesInToken) {
                fee = (_amount.mul(swapFee)) / (1000);
                _safeTransfer(_token, feeTo, fee);
            } else _deductETHFee(feeTo, swapFee);
        }
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier:MIT
pragma solidity 0.5.16;

import './interfaces/IRelayRecipient.sol';

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
contract BaseRelayRecipient is IRelayRecipient {
    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), 'Function can only be called through the trusted Forwarder');
        _;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IUnifarmPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);

    function mint(address to) external payable returns (uint liquidity);
    function burn(address to) external payable returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external payable;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, address) external;
}

pragma solidity =0.5.16;

import './interfaces/IUnifarmERC20.sol';
import './libraries/SafeMath.sol';
import './BaseRelayRecipient.sol';

contract UnifarmERC20 is IUnifarmERC20, BaseRelayRecipient {
    using SafeMath for uint256;

    string public constant name = 'Unifarm Liquidity Token';
    string public constant symbol = 'UFARM-LP';
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    /*
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract.
     */
    function versionRecipient() external view returns (string memory) {
        return '1';
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][_msgSender()] != uint256(-1)) {
            allowance[from][_msgSender()] = allowance[from][_msgSender()].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, 'Unifarm: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Unifarm: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

pragma solidity =0.5.16;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity =0.5.16;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IUnifarmCallee {
    function unifarmCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IUnifarmERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier:MIT
pragma solidity 0.5.16;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
contract IRelayRecipient {
    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public view returns (bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view returns (address payable);

    function versionRecipient() external view returns (string memory);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}