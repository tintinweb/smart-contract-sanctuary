// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./interfaces/IEvryFactory.sol";
import "./EvryPair.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EvryFactory is IEvryFactory, Ownable {
    address public override feeToPlatform;
    address public override admin;
    uint256 public override feePlatformBasis;
    uint256 public override feeLiquidityBasis;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    event feeToPlatformAddressUpdated(
        address sender,
        address newFeeToPlatform
    );

    event adminUpdated(
        address sender,
        address newAdmin
    );

    event platformFeeUpdated(
        address sender,
        uint256 newPlatformFee
    );

    event liquidityFeeUpdated(
        address sender,
        uint256 newliquidityFee
    );

    modifier onlyAdmin() {
        require(admin == msg.sender, "Evry: FORBIDDEN");
        _;
    }

    constructor(
        address _admin,
        uint256 _feePlatformBasis,
        uint256 _feeLiquidityBasis
    ) {
        admin = _admin;
        feePlatformBasis = _feePlatformBasis;
        feeLiquidityBasis = _feeLiquidityBasis;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        onlyAdmin
        override
        returns (address pair)
    {
        require(feeToPlatform != address(0), "Evry: INVALID_TREASURY_ADDRESS");
        require(tokenA != tokenB, "Evry: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Evry: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Evry: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(EvryPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IEvryPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
    
    function setFeeToPlatform(address _feeToPlatform) external onlyOwner override {
        require(_feeToPlatform != address(0), "Evry: INVALID_TREASURY_ADDRESS");
        feeToPlatform = _feeToPlatform;
        emit feeToPlatformAddressUpdated(msg.sender, _feeToPlatform);
    }

    function setPlatformFee(uint256 feeBasis) external onlyOwner override {
        require(feeBasis <= 10000, "Evry: INVALID_RANGE_OF_FEE");
        feePlatformBasis = feeBasis;
        emit platformFeeUpdated(msg.sender, feeBasis);
    }

    function setLiquidityFee(uint256 feeBasis) external onlyOwner override {
        require(feeBasis <= 10000, "Evry: INVALID_RANGE_OF_FEE");
        feeLiquidityBasis = feeBasis;
        emit liquidityFeeUpdated(msg.sender, feeBasis);
    }

    function transferAdmin(address newAdmin) external onlyAdmin override {
        admin = newAdmin;
        emit adminUpdated(msg.sender, newAdmin);
    }

    function getFeeConfiguration() external override view returns (address _feeToPlatform, uint256 _feePlatformBasis, uint256 _feeLiquidityBasis)
    {
        _feeToPlatform = feeToPlatform;
        _feePlatformBasis = feePlatformBasis;
        _feeLiquidityBasis = feeLiquidityBasis;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IEvryFactory {
    function feeToPlatform() external view returns (address);

    function feePlatformBasis() external view returns (uint256);

    function feeLiquidityBasis() external view returns (uint256);

    function getFeeConfiguration() external view returns (address _feeToPlatform, uint256 _feePlatformBasis, uint256 _feeLiquidityBasis);

    function admin() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeToPlatform(address) external;

    function transferAdmin(address newAdmin) external;

    function setPlatformFee(uint256) external;

    function setLiquidityFee(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './interfaces/IEvryPair.sol';
import './EvryERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import "./libraries/EvryLibrary.sol";
import './interfaces/IERC20.sol';
import './interfaces/IEvryFactory.sol';
import './interfaces/IEvryCallee.sol';

contract EvryPair is IEvryPair, EvryERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public override constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private  constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public override factory;
    address public override token0;
    address public override token1;
    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Evry: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    struct FeeConfiguration {
        address feeToPlatform;
        uint256 feePlatformBasis;
        uint256 feeLiquidityBasis;
        uint256 amount0Out;
        uint256 amount1Out;
    }


    function getReserves() public view override returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Evry: TRANSFER_FAILED');
    }

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
    event SendFeeToPlatFrom(address indexed sender, uint amount0, uint feeAmount);

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, 'Evry: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Evry: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
       
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock override returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this)); 
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'Evry: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock override returns (uint amount0, uint amount1) {
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Evry: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
            uint[2] memory amountOut, 
            address to, 
            bytes calldata data
        ) 
            external 
            lock 
            override 
        {

        FeeConfiguration memory feeConfiguration;
        {   // scope to avoid stack too deep errors
            (address _feeToPlatform, uint256 _feePlatformBasis, uint256 _feeLiquidityBasis) = IEvryFactory(factory).getFeeConfiguration();
            feeConfiguration = FeeConfiguration({
                feeToPlatform: _feeToPlatform,
                feePlatformBasis: _feePlatformBasis,
                feeLiquidityBasis: _feeLiquidityBasis,
                amount0Out: amountOut[0],
                amount1Out: amountOut[1]
            });
        }
        require(feeConfiguration.amount0Out > 0 || feeConfiguration.amount1Out > 0, 'Evry: INSUFFICIENT_OUTPUT_AMOUNT');
        
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(feeConfiguration.amount0Out < _reserve0 && feeConfiguration.amount1Out < _reserve1, 'Evry: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'Evry: INVALID_TO');
            if (feeConfiguration.amount0Out > 0) _safeTransfer(_token0, to, feeConfiguration.amount0Out); // optimistically transfer tokens
            if (feeConfiguration.amount1Out > 0) _safeTransfer(_token1, to, feeConfiguration.amount1Out); // optimistically transfer tokens
            if (data.length > 0) IEvryCallee(to).evryCall(msg.sender, feeConfiguration.amount0Out, feeConfiguration.amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - feeConfiguration.amount0Out ? balance0 - (_reserve0 - feeConfiguration.amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - feeConfiguration.amount1Out ? balance1 - (_reserve1 - feeConfiguration.amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Evry: INSUFFICIENT_INPUT_AMOUNT');
        
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint totalFee = feeConfiguration.feePlatformBasis.add(feeConfiguration.feeLiquidityBasis);
            uint balance0Adjusted = balance0.mul(10000).sub(amount0In.mul(totalFee));
            uint balance1Adjusted = balance1.mul(10000).sub(amount1In.mul(totalFee));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(10000**2), 'Evry: K');
        }

        _update(balance0, balance1);
        {
        // emit Swap(msg.sender, amount0In, amount1In, amountOut, to);
}   
        if (amount0In > 0) {
            sendFeeToPlatform(token0, amount0In, feeConfiguration.feePlatformBasis, feeConfiguration.feeToPlatform);
        } else {
            sendFeeToPlatform(token1, amount1In, feeConfiguration.feePlatformBasis, feeConfiguration.feeToPlatform);
        }
        _sync();
        
    }

    function sendFeeToPlatform(address token, uint256 amount, uint feePlatformBasis, address feeToPlatform) private {
        
        uint denominator = amount.mul(feePlatformBasis);
        uint platformFeeAmount = denominator / 10000;

        _safeTransfer(token, feeToPlatform, platformFeeAmount);

        SendFeeToPlatFrom(msg.sender, amount, platformFeeAmount);
    }

     function getBasisTotalFee()
        internal
        view
        returns (uint256 totalFee)
    {
        (, uint256 _feePlatformBasis, uint256 _feeLiquidityBasis) = IEvryFactory(factory).getFeeConfiguration();
        totalFee = _feePlatformBasis.add(_feeLiquidityBasis);
    }
    
    function _sync() private {
        uint balance0;
        uint balance1;
        address _token0 = token0;
        address _token1 = token1;
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
    }

    // force balances to match reserves
    function skim(address to) external lock override{
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock override{
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './IEvryERC20.sol';

interface IEvryPair is IEvryERC20{
    
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(
        uint[2] memory amountOut,
        address to, 
        bytes calldata data ) 
    external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './interfaces/IEvryERC20.sol';
import './libraries/SafeMath.sol';

contract EvryERC20 is IEvryERC20 {
    using SafeMath for uint;

    string public override constant name = 'Evry.finance AMM LP';
    string public override constant symbol = 'EF-AMM-LP';
    uint8 public override constant decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public  override constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
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

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external  override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external  override {
        require(deadline >= block.timestamp, 'Evry: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Evry: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/IEvryPair.sol";
import "../interfaces/IEvryFactory.sol";

import "./SafeMath.sol";

library EvryLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "EvryLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "EvryLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        pair = IEvryFactory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IEvryPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    function calculatePlatformFee(address factory, uint256 amountIn)
        internal
        view
        returns (uint256 platformFeeAmount)
    {
        uint256 feePlatformBasis = IEvryFactory(factory).feePlatformBasis();
        uint256 denominator = amountIn.mul(feePlatformBasis);
        platformFeeAmount = denominator / 10000;
    }

    function getBasisTotalFee(address factory)
        internal
        view
        returns (uint256 totalFee)
    {
        uint256 platformFee = IEvryFactory(factory).feePlatformBasis();
        uint256 protocalFee = IEvryFactory(factory).feeLiquidityBasis();
        totalFee = platformFee.add(protocalFee);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "EvryLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "EvryLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

     // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint feeAmount) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'EvryLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'EvryLibrary: INSUFFICIENT_LIQUIDITY');
        uint256 feeMuiltiplier = 10000 - feeAmount;
        uint amountInWithFee = amountIn.mul(feeMuiltiplier);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint feeAmount) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'EvryLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'EvryLibrary: INSUFFICIENT_LIQUIDITY');
        uint256 feeMuiltiplier = 10000 - feeAmount;
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(feeMuiltiplier);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'EvryLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        uint feeAmount = getBasisTotalFee(factory);
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, feeAmount);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'EvryLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            uint feeAmount = getBasisTotalFee(factory);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, feeAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IEvryCallee {
    function evryCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IEvryERC20 {

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

