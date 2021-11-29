/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-04
*/

pragma solidity =0.5.16;

// UNI-V2工厂合约接口
interface IUniswapV2Factory {
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

//UNI-V2建立流动池接口
interface IUniswapV2Pair {
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
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

//UNI-V2 ERC20代币接口
interface IUniswapV2ERC20 {
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);  //域分隔符
    function PERMIT_TYPEHASH() external pure returns (bytes32);   //允许类型的哈希散列
    function nonces(address owner) external view returns (uint);  //记录转出次数
    //许可判断,再授权
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

//IERC20 接口
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

//IUniswapV2Callee 接口
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

//本V2的代币LP Token 合约
contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public constant name = 'Uniswap V2';
    string public constant symbol = 'UNI-V2';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR; //域分隔符
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	//允许类型的哈希散列: 将允许使用的数据类型进行哈希得到。注意就是对上句中的引号内的内容进行keccak256哈希
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;   //地址的nonces,每转出一次会+1

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;  //网络ID，每个主链都有一个唯一网络ID
        assembly {
            chainId := chainid
        }
		//域分隔符 获得方式
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
    //铸造代币 （内部调用、具体实现）
    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }
    //燃烧销毁代币（内部调用、具体实现）
    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }
    //授权代币数量（内部调用、具体实现）
    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    //转币（内部调用、具体实现）
    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }
    //授权代币数量（外部调用）
    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    //转币（外部调用）
    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    //授权的转币（外部调用）
    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
    //许可判断,再授权。它允许用户在链下签署授权（approve）的交易，生成任何人都可以使用并提交给区块链的签名。
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
	    //判定当前区块（创建）时间不能超过最晚交易时间
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s); //签名加密的恢复地址
		//如果签名地址为0 或 不为管理者，则签名错误
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

//UNI-V2流动池协议，此合约继承了IUniswapV2Pair和UniswapV2ERC20，因此也是ERC20代币。
contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath  for uint;      //在uint上使用SafeMath，防止上下溢出。
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;  //定义最小流动池
	
	//获取transfer方法的bytecode前四个字节
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

	//使用单个存储插槽，可通过getReserves访问
    uint112 private reserve0;           // uses single storage slot, accessible via getReserves 
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; //用来记录更新的区块时间

    uint public price0CumulativeLast;   //0 token 的累加价格
    uint public price1CumulativeLast;   //1 token 的累加价格
	
	//reserve0*reserve1，自最近一次流动性事件发生后立即生效
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
	
	//一个锁，使用该modifier的函数在unlocked==1时才可以进入，
    //第一个调用者进入后，会将unlocked置为0，此使第二个调用者无法再进入
    //执行完_部分的代码后，才会再将unlocked置1，重新将锁打开
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

	//用于获取两个代币在池子中的数量和最后更新的时间
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
		//调用transfer方法，把地址token中的value个代币转账给to
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
		//检查返回值，必须成功否则报错
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,uint amount1In,
        uint amount0Out,uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
	
	//部署此合约时将msg.sender设置为factory，后续初始化时会用到这个值
    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment 
	//初始化函数 require 调用者需是工厂合约，而且工厂合约中只会初始化一次。
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

	//TWAP = Time-Weighted Average Price，即时间加权平均价格，可用来创建有效防止价格操纵的链上价格预言机。
	//这个函数是用来更新价格oracle的，计算累计价格。每次 mint、burn、swap、sync 时都会触发更新
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        //防止溢出
		require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
		//读取当前的区块时间 blockTimestamp
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
		//计算出与上一次更新的区块时间之间的时间差 timeElapsed
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
		
        //计算时间加权的累计价格，256位中，前112位用来存整数，后112位用来存小数，多的32位用来存溢出的值
		//如果 timeElapsed > 0 且两个 token 的 reserve 都不为 0，则更新两个累加价格
		if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
		//更新reserve值(更新两个 reserve 和区块时间 blockTimestampLast)
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
	//如果收取费用，薄荷流动性相当于sqrt（k）增长的1/6
	//在工厂合约中有一个 feeTo 的地址，如果设置了该地址不为零地址，就表示添加和移除流动性时会收取协议费用，但 Uniswap 一直到现在都没有设置该地址。
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
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
	// 应从执行重要安全检查的合同中调用此底层函数
	//通过同时注入两种代币资产来获取流动性代币。
	//lock 这是一个防止重入的修饰器，保证了每次添加流动性时不会有多个用户同时往配对合约里转账，不然就没法计算的 amount0 和 amount1 了。
    function mint(address to) external lock returns (uint liquidity) {
		//两个代币原有的数量
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings 节省汽油
		//获取两个币的当前余额 balance0 和 balance1
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
		//两个代币的投入数
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1); //计算协议费用的
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee 
		
        if (_totalSupply == 0) {
			//两个代币投入的数量相乘后求平方根，结果再减去最小流动性。最小流动性为 1000，该最小流动性会永久锁在零地址。
			//第一次铸币，也就是第一次注入流动性，值为根号k减去 MINIMUM_LIQUIDITY
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
			//把 MINIMUM_LIQUIDITY 赋给地址0，永久锁住
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
			//如果不是提供最初流动性的话，那流动性则是取以下两个值中较小的那个，作为新铸币的数量
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
		
		//铸币，修改to的token数量及totalsupply
        _mint(to, liquidity);		
		//更新时间加权平均价格
        _update(balance0, balance1, _reserve0, _reserve1);
		
		//判断如果协议费用开启的话，更新 kLast 值，即 reserve0 和 reserve1 的乘积值，该值其实只在计算协议费用时用到。
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);    //触发一个 Mint() 事件
    }


    // this low-level function should be called from a contract which performs important safety checks
	// 应从执行重要安全检查的合同中调用此底层函数
	//销毁掉流动性代币并提取相应的两种代币资产给到用户
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
		//分别获取本合约地址中token0、token1和本合约代币的数量
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
		//此时用户的LP token已经被转移至合约地址，因此这里取合约地址中的LP Token余额就是等下要burn掉的量
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        //根据liquidity占比获取两个代币的实际数量
		amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        //销毁LP Token
		_burn(address(this), liquidity);
        //将token0和token1转给地址to
		_safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
		
		//更新时间加权平均价格
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
	// 应从执行重要安全检查的合同中调用此底层函数
	//兑换交易
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
		//先校验兑换结果的数量是否有一个大于 0
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
		//读取出两个代币的 reserve
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
		//再校验兑换数量是否小于 reserve
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
		//一对大括号，这主要是为了限制 _token{0,1} 这两个临时变量的作用域，防止堆栈太深导致错误。
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
		
		//FlashSwap，翻译过来就是闪电兑换，和闪电贷（FlashLoan） 有点类似
		//如果 data 参数长度大于 0，则将 to 地址转为 IUniswapV2Callee 并调用其 uniswapV2Call() 函数，这其实就是一个回调函数，to 地址需要实现该接口
        //1、to 地址是一个合约地址；2、to 地址的合约实现了 IUniswapV2Callee 接口；3、可以在 uniswapV2Call 函数里执行 to 合约自己的逻辑
		if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
		//获取两个代币当前的余额 balance{0,1} ，而这个余额是扣减了转出代币后的余额。
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
		
		//是计算出实际转入的代币数量了。实际转入的数量其实也通常是一个为 0，一个不为 0 的。
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
		
		//进行扣减交易手续费后的恒定乘积校验
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
	// 强制平衡以匹配储备金
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
	// 迫使储备与余额相匹配
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}


// UNI-V2工厂合约
contract UniswapV2Factory is IUniswapV2Factory {

	//此句是额外添加的，目的是方便显示硬编码的 INIT_CODE_PAIR_HASH
	bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(UniswapV2Pair).creationCode));
	
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
		
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
    //用来创建交易对
    function createPair(address tokenA, address tokenB) external returns (address pair) {
		//必须是两个不一样的ERC20合约地址，也就交易对必须是两种不同的ERC20代币。
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
		//让tokenA和tokenB的地址从小到大排列,因为地址类型底层其实是uint160，所以也是有大小可以排序的。
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		//token地址不能是0
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
		//用来验证交易对并未创建（不能重复创建相同的交易对）
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
		
        //获取交易对模板合约UniswapV2Pair的创建字节码creationCode。
		//注意，它返回的结果是包含了创建字节码的字节数组，类型为bytes。
		bytes memory bytecode = type(UniswapV2Pair).creationCode;
		//用来计算一个salt。注意，它使用了两个代币地址作为计算源，这就意味着，对于任意交易对，该salt是固定值
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
		//assembly代表这是一段内嵌汇编代码，Solidity中内嵌汇编语言为Yul语言。
        assembly {
			//在Yul代码中使用了create2函数（该函数名表明使用了create2操作码）来创建新合约
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
		//初始化刚刚创建的合约
        IUniswapV2Pair(pair).initialize(token0, token1);
		//记录刚刚创建的合约对应的pair
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);  //添加到pair池里
        emit PairCreated(token0, token1, pair, allPairs.length); //触发交易对创建事件
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}

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