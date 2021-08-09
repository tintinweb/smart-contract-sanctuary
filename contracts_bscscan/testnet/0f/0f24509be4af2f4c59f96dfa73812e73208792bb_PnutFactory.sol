/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

/**
 *Submitted for verification at BscScan.com on 2020-11-07
*/

// Dependency file: contracts/interfaces/IPnutFactory.sol

// pragma solidity =0.6.12;

interface IPnutFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// Dependency file: contracts/libraries/SafeMath.sol

// pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathPnut {
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }    
}


// Dependency file: contracts/PnutERC20.sol

// pragma solidity =0.6.12;

// import 'contracts/libraries/SafeMath.sol';

contract PnutERC20 {
    using SafeMathPnut for uint;

    string public constant name = 'Pnut LP';
    string public constant symbol = 'PNUT-LP';
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
        require(deadline >= block.timestamp, 'Pnut: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Pnut: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}


// Dependency file: contracts/libraries/Math.sol

// pragma solidity =0.6.12;

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


// Dependency file: contracts/libraries/UQ112x112.sol

// pragma solidity =0.6.12;

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


// Dependency file: contracts/interfaces/IERC20.sol

// pragma solidity =0.6.12;

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


// Dependency file: contracts/interfaces/IyToken.sol

// pragma solidity =0.6.12;

interface IyToken {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function deposit(uint) external;
    function withdraw(uint) external;    
    function balance() external view returns (uint);
}


// Dependency file: contracts/interfaces/IPnutCallee.sol

// pragma solidity =0.6.12;

interface IPnutCallee {
    function PnutCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}


// Dependency file: contracts/PnutPair.sol

// pragma solidity =0.6.12;

// import 'contracts/PnutERC20.sol';
// import 'contracts/libraries/Math.sol';
// import 'contracts/libraries/UQ112x112.sol';
// import 'contracts/interfaces/IERC20.sol';
// import 'contracts/interfaces/IyToken.sol';
// import 'contracts/interfaces/IPnutFactory.sol';
// import 'contracts/interfaces/IPnutCallee.sol';

contract PnutPair is PnutERC20 {
    using SafeMathPnut for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;
    address public yToken0;
    address public yToken1;
    uint16 redepositRatio0;
    uint16 redepositRatio1;
    uint public deposited0;
    uint public deposited1;
    uint112 public dummy0;
    uint112 public dummy1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint8 public fee = 3;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Pnut: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return IPnutFactory(factory).feeTo();
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function getDeposited() public view returns (uint _deposited0, uint _deposited1) {
        _deposited0 = deposited0;
        _deposited1 = deposited1;
    }

    function getDummy() public view returns (uint _dummy0, uint _dummy1) {
        _dummy0 = dummy0;
        _dummy1 = dummy1;
    }

    function _safeTransfer(address token, address to, uint value) private {
        IERC20 u = IERC20(token);
        uint b = u.balanceOf(address(this));
        if (b < value) {
            if (token == token0) {
                _withdrawAll0();
                (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));                
                if (redepositRatio0 > 0) {
                    redeposit0();
                }
                require(success && (data.length == 0 || abi.decode(data, (bool))), 'Pnut: TRANSFER_FAILED');
            } else {
                _withdrawAll1();
                (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
                if (redepositRatio1 > 0) {
                    redeposit1();
                }
                require(success && (data.length == 0 || abi.decode(data, (bool))), 'Pnut: TRANSFER_FAILED');
            }
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'Pnut: TRANSFER_FAILED');
        }
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event DummyMint(uint amount0, uint amount1);
    event DummyBurn(uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    event FeeUpdated(uint8 fee);

    event Y0Updated(address indexed token);
    event Y1Updated(address indexed token);

    event Deposited0Updated(uint deposited);
    event Deposited1Updated(uint deposited);

    event RedepositRatio0Updated(uint16 ratio);
    event RedepositRatio1Updated(uint16 ratio);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'Pnut: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Pnut: OVERFLOW');
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

    // this low-level function should be called from a contract which performs // important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = b0();
        uint balance1 = b1();
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        _reserve0 -= dummy0;
        _reserve1 -= dummy1;
        uint _totalSupply = totalSupply; // gas savings
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'Pnut: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);
        _reserve0 += dummy0;
        _reserve1 += dummy1;
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs // important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = b0().sub(dummy0);
        uint balance1 = b1().sub(dummy1);
        uint liquidity = balanceOf[address(this)];

        uint _totalSupply = totalSupply; // gas savings
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Pnut: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = b0();
        balance1 = b1();

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs // important safety checks
    function dummy_mint(uint amount0, uint amount1) external onlyOwner() lock {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        dummy0 += uint112(amount0);
        dummy1 += uint112(amount1);
        _update(b0(), b1(), _reserve0, _reserve1);
        emit DummyMint(amount0, amount1);
    }

    // this low-level function should be called from a contract which performs // important safety checks
    function dummy_burn(uint amount0, uint amount1) external onlyOwner() lock {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        dummy0 -= uint112(amount0);
        dummy1 -= uint112(amount1);
        _update(b0(), b1(), _reserve0, _reserve1);
        emit DummyBurn(amount0, amount1);
    }

    // this low-level function should be called from a contract which performs // important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'Pnut: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Pnut: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'Pnut: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IPnutCallee(to).PnutCall(msg.sender, amount0Out, amount1Out, data);
        balance0 = b0();
        balance1 = b1();
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Pnut: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(fee));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(fee));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Pnut: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, b0().sub(reserve0));
        _safeTransfer(_token1, to, b1().sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(b0(), b1(), reserve0, reserve1);
    }

    function setFee(uint8 _fee) external onlyOwner() {
        fee = _fee;

        emit FeeUpdated(_fee);
    }

    // vault
    function b0() public view returns (uint b) {
        IERC20 u = IERC20(token0);
        b = u.balanceOf(address(this)).add(deposited0).add(dummy0);
    }
    function b1() public view returns (uint b) {
        IERC20 u = IERC20(token1);
        b = u.balanceOf(address(this)).add(deposited1).add(dummy1);
    }
    function approve0() public onlyOwner() {
        IERC20(token0).approve(yToken0, uint(-1));
    }
    function approve1() public onlyOwner() {
        IERC20(token1).approve(yToken1, uint(-1));
    }
    function unapprove0() public onlyOwner() {
        IERC20(token0).approve(yToken0, 0);
    }
    function unapprove1() public onlyOwner() {
        IERC20(token1).approve(yToken1, 0);
    }
    function setY0(address y) public onlyOwner() {
        yToken0 = y;
        approve0();
        emit Y0Updated(y);
    }
    function setY1(address y) public onlyOwner() {
        yToken1 = y;
        approve1();
        emit Y1Updated(y);
    }

    function deposit0(uint a) internal {
        require(a > 0, "deposit amount must be greater than 0");
        IyToken y = IyToken(yToken0);
        deposited0 += a;
        y.deposit(a);    
        emit Deposited0Updated(deposited0);
    }
    function deposit1(uint a) internal {
        require(a > 0, "deposit amount must be greater than 0");
        IyToken y = IyToken(yToken1);
        deposited1 += a;
        y.deposit(a);
        emit Deposited1Updated(deposited1);
    }
    function depositSome0(uint a) onlyOwner() external {
        deposit0(a);
    }
    function depositSome1(uint a) onlyOwner() external {
        deposit1(a);
    }
    function depositAll0() onlyOwner() external {
        IERC20 u = IERC20(token0);
        deposit0(u.balanceOf(address(this)));
    }
    function depositAll1() onlyOwner() external {
        IERC20 u = IERC20(token1);
        deposit1(u.balanceOf(address(this)));
    }
    function redeposit0() internal {
        IERC20 u = IERC20(token0);
        deposit0(u.balanceOf(address(this)).mul(redepositRatio0).div(1000));
    }
    function redeposit1() internal {
        IERC20 u = IERC20(token1);
        deposit1(u.balanceOf(address(this)).mul(redepositRatio1).div(1000));
    }
    function set_redepositRatio0(uint16 _redpositRatio0) onlyOwner() external {
        require(_redpositRatio0 <= 1000, "ratio too large");
        redepositRatio0 = _redpositRatio0;

        emit RedepositRatio0Updated(_redpositRatio0);
    }
    function set_redepositRatio1(uint16 _redpositRatio1) onlyOwner() external {
        require(_redpositRatio1 <= 1000, "ratio too large");
        redepositRatio1 = _redpositRatio1;

        emit RedepositRatio1Updated(_redpositRatio1);
    }
    function _withdraw0(uint s) internal {
        require(s > 0, "withdraw amount must be greater than 0");
        IERC20 u = IERC20(token0);
        uint delta = u.balanceOf(address(this));
        IyToken y = IyToken(yToken0);
        y.withdraw(s);
        delta = u.balanceOf(address(this)).sub(delta);
        if (delta <= deposited0) {
            deposited0 -= delta;
        } else {
            delta -= deposited0; deposited0 = 0;
            _safeTransfer(token0, owner(), delta);
        }

        emit Deposited0Updated(deposited0);
    }
    function _withdraw1(uint s) internal {
        require(s > 0, "withdraw amount must be greater than 0");
        IERC20 u = IERC20(token1);
        uint delta = u.balanceOf(address(this));
        IyToken y = IyToken(yToken1);
        y.withdraw(s);
        delta = u.balanceOf(address(this)).sub(delta);
        if (delta <= deposited1) {
            deposited1 -= delta;
        } else {
            delta -= deposited1; deposited1 = 0;
            _safeTransfer(token1, owner(), delta);
        }

        emit Deposited1Updated(deposited1);
    }
    function _withdrawAll0() internal {
        IERC20 y = IERC20(yToken0);
        _withdraw0(y.balanceOf(address(this)));
    }
    function _withdrawAll1() internal {
        IERC20 y = IERC20(yToken1);
        _withdraw1(y.balanceOf(address(this)));
    }
    function withdraw0(uint s) external onlyOwner() {
        _withdraw0(s);
    }
    function withdraw1(uint s) external onlyOwner() {
        _withdraw1(s);
    }
    function withdrawAll0() external onlyOwner() {
        _withdrawAll0();
    }
    function withdrawAll1() external onlyOwner() {
        _withdrawAll1();
    }
}


// Root file: contracts/PnutFactory.sol

pragma solidity =0.6.12;

// import 'contracts/interfaces/IPnutFactory.sol';
// import 'contracts/PnutPair.sol';

contract PnutFactory is IPnutFactory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor() public {
        feeToSetter = msg.sender;
        feeTo = msg.sender;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(PnutPair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'Pnut: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Pnut: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Pnut: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(PnutPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        PnutPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'Pnut: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'Pnut: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}