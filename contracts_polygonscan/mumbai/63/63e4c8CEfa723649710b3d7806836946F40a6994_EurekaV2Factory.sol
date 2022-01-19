/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

// File: contracts/uniswapv2/interfaces/IEurekaV2Factory.sol

// SPDX-License-Identifier: GPL-3.0


pragma solidity 0.6.12;

interface IEurekaV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    // function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function PERCENT100() external view returns (uint256);

    // function fee() external view returns (address);
    function swapFee() external view returns (uint256);
    function swapAdminFee() external view returns (uint256);

    function adminFee() external view returns (uint256);
    function farm1Fee() external view returns (uint256);
    function farm2Fee() external view returns (uint256);
    function farm3Fee() external view returns (uint256);


    function admin() external view returns (address);
    function farm1() external view returns (address);
    function farm2() external view returns (address);
    function farm3() external view returns (address);



}

// File: contracts/uniswapv2/libraries/SafeMath.sol



pragma solidity 0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathEureka {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

// File: contracts/uniswapv2/EurekaV2ERC20.sol



pragma solidity 0.6.12;


contract EurekaV2ERC20 {
    using SafeMathEureka for uint;

    string public constant name = 'EurekaV LP Token';
    string public constant symbol = 'ELP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
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

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'EurekaV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'EurekaV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// File: contracts/uniswapv2/libraries/Math.sol



pragma solidity 0.6.12;

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

// File: contracts/uniswapv2/libraries/UQ112x112.sol



pragma solidity 0.6.12;

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

// File: contracts/uniswapv2/interfaces/IERC20.sol



pragma solidity 0.6.12;

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

// File: contracts/uniswapv2/interfaces/IEurekaV2Callee.sol



pragma solidity 0.6.12;

interface IEurekaV2Callee {
    function eurekaV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// File: contracts/uniswapv2/interfaces/IFarm.sol

pragma solidity 0.6.12;


interface IFarm{
    
     function addLPInfo(
        IERC20 _lpToken,
        IERC20 _rewardToken0,
        IERC20 _rewardToken1
    ) external;

    function addReward(address _lp,address token0, address token1, uint256 amount0, uint256 amount1) external;

}

interface IMelt{
    function addReward(address token0, address token1, uint256 amount0, uint256 amount1) external;
}


interface IBank{
    function addReward(address token0, address token1, uint256 amount0, uint256 amount1) external;
}

// File: contracts/uniswapv2/EurekaV2Pair.sol



pragma solidity 0.6.12;










contract EurekaV2Pair is EurekaV2ERC20 {
    using SafeMathEureka  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'EurekaV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'EurekaV2: TRANSFER_FAILED');
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

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'EurekaV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'EurekaV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IEurekaV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
                liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'EurekaV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'EurekaV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        (amount0, amount1) = takeremoveLiquidityFee(_token0, _token1, amount0, amount1);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'EurekaV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'EurekaV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'EurekaV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IEurekaV2Callee(to).eurekaV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'EurekaV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'EurekaV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
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

    function takeremoveLiquidityFee(address _token0, address _token1, uint256 amount0, uint256 amount1) internal returns(uint256, uint256){
        uint256 PERCENT = IEurekaV2Factory(factory).PERCENT100(); 
        address[3] memory farm = [IEurekaV2Factory(factory).farm1(),IEurekaV2Factory(factory).farm2(), IEurekaV2Factory(factory).farm3()];
        
        uint256[4] memory farmFee0;
        farmFee0[0] = amount0.mul(IEurekaV2Factory(factory).farm1Fee()).div(PERCENT);
        farmFee0[1] = amount0.mul(IEurekaV2Factory(factory).farm2Fee()).div(PERCENT);
        farmFee0[2] = amount0.mul(IEurekaV2Factory(factory).farm2Fee()).div(PERCENT);
        farmFee0[3] = amount0.mul(IEurekaV2Factory(factory).adminFee()).div(PERCENT);

        uint256[4] memory farmFee1;
        farmFee1[0] = amount0.mul(IEurekaV2Factory(factory).farm1Fee()).div(PERCENT);
        farmFee1[1] = amount1.mul(IEurekaV2Factory(factory).farm2Fee()).div(PERCENT);
        farmFee1[2] = amount1.mul(IEurekaV2Factory(factory).farm3Fee()).div(PERCENT);
        farmFee1[3] = amount1.mul(IEurekaV2Factory(factory).adminFee()).div(PERCENT);

        _safeTransfer(_token0, IEurekaV2Factory(factory).admin(), farmFee0[3]);
        _safeTransfer(_token1, IEurekaV2Factory(factory).admin(), farmFee1[3]);

        _approvetoken(token0, farm[0], amount0);
        _approvetoken(token0, farm[1], amount0);
        _approvetoken(token0, farm[2], amount0);

        _approvetoken(token1, farm[0], amount1);
        _approvetoken(token1, farm[1], amount1);
        _approvetoken(token1, farm[2], amount1);

        IFarm(farm[0]).addReward(address(this), token0, token1, farmFee0[0], farmFee1[0]);
        IMelt(farm[1]).addReward(token0, token1, farmFee0[1], farmFee1[1]);
        IBank(farm[2]).addReward(token0, token1, farmFee0[2], farmFee1[2]);

        amount0 = amount0.sub(farmFee0[0] + farmFee0[1] + farmFee0[2] + farmFee0[3]);
        amount1 = amount1.sub(farmFee1[0] + farmFee1[1] + farmFee1[2] + farmFee1[3]);
        return(amount0, amount1);
    }

    function _approvetoken(address token, address _receiver, uint256 amount) private {
        if(IERC20(token).allowance(address(this), _receiver) < amount){
            IERC20(token).approve(_receiver, amount);
        }
    }
}

// File: contracts/uniswapv2/EurekaV2Factory.sol



pragma solidity 0.6.12;






contract EurekaV2Factory is IEurekaV2Factory {
    uint256 public override constant PERCENT100 = 10000; 

    address public override feeTo; // address(0x00)
    address public override feeToSetter;

    uint256 public override swapAdminFee =10 ; //0.25 
    uint256 public override swapFee = 15; //0.25 

    address public override admin; // admin recevier address
    address public override farm1; // lp stakers
    address public override farm2; // tokenE staking
    address public override farm3; // tokenL staking
    // In and out tax. up to 2 decimal
    uint256 public override farm1Fee = 300;
    uint256 public override farm2Fee = 100;
    uint256 public override farm3Fee = 100; 
    uint256 public override adminFee = 100; 

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter, address _admin) public {
        feeToSetter = _feeToSetter;
        admin = _admin;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(EurekaV2Pair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'EurekaV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'EurekaV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'EurekaV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(EurekaV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        EurekaV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        IFarm(farm1).addLPInfo(IERC20(pair),IERC20(tokenA),IERC20(tokenB));
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'EurekaV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setAdmin(address _admin) external  {
        require(msg.sender == feeToSetter, 'EurekaV2: FORBIDDEN');
        admin = _admin;
    }
    
    function setInOutTax(uint256 _farm1Fee, uint256 _farm2Fee, uint256 _farm3Fee, uint256 _adminFee) external  {
       require(msg.sender == feeToSetter, 'EurekaV2: FORBIDDEN');
        farm1Fee = _farm1Fee;
        farm2Fee = _farm2Fee;
        farm3Fee = _farm3Fee; 
        adminFee = _adminFee; 
    }

    function setFarmInfo(address[3] memory _farm) external {
        require(msg.sender == feeToSetter, 'EurekaV2: FORBIDDEN');
        farm1 = _farm[0]; // lp staking
        farm2 = _farm[1]; // tokenE staking
        farm3 = _farm[2]; // tokenL staking
    }

    function setSwapFee(uint256 _swapFee, uint256 _swapAdminFee) external  {
        require(msg.sender == feeToSetter, 'EurekaV2: FORBIDDEN');
        swapFee = _swapFee;
        swapAdminFee = _swapAdminFee;
    }

}