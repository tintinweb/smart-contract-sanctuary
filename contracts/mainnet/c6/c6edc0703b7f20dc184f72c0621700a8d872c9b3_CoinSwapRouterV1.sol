/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

//SPDX-License-Identifier: TBD
pragma solidity =0.7.4;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

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

interface ICoinSwapERC20 is IERC20 {
    event Swap(address indexed,uint192,uint192,address indexed); 
    event Sync(uint);
    event Mint(address indexed sender, uint192);
    event Burn(address indexed sender, uint192, address indexed to);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


interface ICoinSwapCallee {
    function coinswapCall(address sender, uint amount0,uint amount1, bytes calldata data) external;
}

contract CoinSwapERC20 is ICoinSwapERC20 {
    using SafeMath for uint;

    string public constant override name = 'CoinSwap V1';
    string public constant override symbol = 'CSWPLT';//CoinSwap Liquidity Token
    uint8 public constant override decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

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

    function approve(address spender, uint value) external override returns (bool) {
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

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'CSWP:01');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'CSWP:02');
        _approve(owner, spender, value);
    }
}


contract CoinSwapPair is CoinSwapERC20  {
    using SafeMath for uint;
    
    address public  patron;
    address public  factory;
    address public  token0; // token0 < token1
    address public  token1;
    uint224 private reserve; //reserve0(96) | reserve1(96) | blockTimestampLast(32)
    uint private unlocked = 1;
    uint public  priceCumulative; //=Delta_y/Delta_x: 96-fractional bits; allows overflow
    uint224 private circleData;
  
    modifier lock() {
        require(unlocked == 1, 'CSWP:1');
    	unlocked = 0;
        _;
        unlocked = 1;
    }
    
    constructor() {factory = msg.sender; patron=tx.origin;}
    function initialize(address _token0, address _token1, uint224 circle) external  {
        //circle needs to in order of token0<token1
        require(circleData == 0, 'CSWP:2');
        token0 = _token0;
        token1 = _token1;
        circleData = circle;  // validity of circle should be checked by CoinSwapFactory
    }

    function ICO(uint224 _circleData)  external  {
        require( (tx.origin==patron) && (circleData >> 216) >0, 'CSWP:3');//to close ICO, set (circleData >> 216) = 0x00
        circleData = _circleData;
    }

    function setPatron(address _patron)  external  {
        require( (tx.origin==patron), 'CSWP:11');
        patron = _patron;
    }
    
    function getReserves() public  view returns (uint224 _reserve, uint224 _circleData) {
        _reserve = reserve;
        _circleData = circleData;
    }
    
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CSWP:6');
    }

    function revisemu(uint192 balance) private returns (uint56 _mu) {
        require(balance>0, 'CSWP:4');
    	uint224 _circleData = circleData;
        uint X = uint(balance>>96) *      uint16(_circleData >> 72)* uint56(_circleData >> 160);
        uint Y = uint(uint96(balance)) *  uint16(_circleData >> 56)* uint56(_circleData >> 104);
        uint XpY =  X + Y;
        uint X2pY2 = (X*X) + (Y*Y);
       	X = XpY*100;
       	Y = (X*X)  + X2pY2 * (10000+ uint16(_circleData>>88));
        uint Z= X2pY2 * 20000;
    	require(Y>Z, 'CSWP:5');
        Y = SQRT.sqrt(Y-Z); 
        Z = Y > X ? X + Y : X-Y;
        _mu =  uint56(1)+uint56(((10**32)*Z) / X2pY2);
        circleData = (_circleData & 0xFF_FFFFFFFFFFFFFF_FFFFFFFFFFFFFF_FFFF_FFFF_FFFF_00000000000000) | uint224(_mu);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance) private {
	    uint32 lastTime = uint32(balance);	
        uint32 deltaTime = uint32(block.timestamp) -lastTime ;
        if (deltaTime>0 && lastTime>0) {
    	    uint circle = circleData;
            uint lambda0 = uint16(circle >> 72);
            uint lambda1 = uint16(circle >> 56);
	        uint CmulambdaX = 10**34 - (balance>>128)     *lambda0*uint56(circle)*uint56(circle >> 160);
            uint CmulambdaY = 10**34 - uint96(balance>>32)*lambda1*uint56(circle)*uint56(circle >> 104); 
	        priceCumulative += (((lambda0*CmulambdaX)<< 96)/(lambda1*CmulambdaY)) * deltaTime;  
        }
        reserve = uint224(balance +deltaTime);
        emit Sync(balance>>32);
    }

    function _mintFee(uint56 mu0) private returns (uint56 mu) {
        address feeTo = CoinSwapFactory(factory).feeTo();
        mu=revisemu(uint192(reserve>>32));
        if (mu0>mu) _mint(feeTo, totalSupply.mul(uint(mu0-mu)) / (5*mu0+mu));
    }

    function mint(address to) external  lock returns (uint liquidity) {
        uint224 circle = circleData;
        uint _totalSupply = totalSupply; 
        uint224 _reserve = reserve;
        uint96 reserve0 = uint96(_reserve >>128);
        uint96 reserve1 = uint96(_reserve >>32);
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint scaledBalance0 = balance0* uint56(circle >> 160);
        uint scaledBalance1 = balance1* uint56(circle >> 104);
        require((scaledBalance0< 2**96) && (scaledBalance1< 2**96) 
            && ( scaledBalance0 >=10**16 || scaledBalance1 >=10**16), 'CSWP:7');
        if (_totalSupply == 0) { 
            uint lambda0 = uint16(circle >> 72);
            uint lambda1 = uint16(circle >> 56);
            liquidity = (scaledBalance0 * lambda0 + scaledBalance1 * lambda1) >> 1;
    	    revisemu(uint192((balance0<<96)|balance1));
        } else { 
            uint56 mu0=_mintFee(uint56(circle));
            _totalSupply = totalSupply;
    	    (uint mu, uint _totalS)=(0,0);
	        if (reserve0==0) {
	            mu=(uint(mu0) * reserve1) / balance1;
	            _totalS =  _totalSupply.mul(balance1)/reserve1;
	        } else if (reserve1==0) {
	            mu=(uint(mu0) * reserve0) / balance0;
	            _totalS = _totalSupply.mul(balance0)/reserve0;
	        } else {
	            (mu, _totalS) = (balance0 * reserve1) < (balance1 * reserve0)?
		        ((uint(mu0) * reserve0) / balance0, _totalSupply.mul(balance0)/reserve0) :
		        ((uint(mu0) * reserve1) / balance1, _totalSupply.mul(balance1)/reserve1) ;
	        }
            liquidity = _totalS - _totalSupply;
            circleData = (circle & 0xFF_FFFFFFFFFFFFFF_FFFFFFFFFFFFFF_FFFF_FFFF_FFFF_00000000000000) | uint224(mu);
        }
        _mint(to, liquidity);
        _update(balance0<<128 | balance1<<32 | uint32(_reserve));
        emit Mint(msg.sender, uint192((balance0-reserve0)<<96 | (balance1-reserve1)));
    }

    function burn(address to) external  lock returns (uint192 amount) {
        uint224 _reserve = reserve;
        address _token0 = token0;                                
        address _token1 = token1;    
        _mintFee(uint56(circleData));
        uint _totalSupply = totalSupply; 
        uint liquidity = balanceOf[address(this)];
        uint amount0 = liquidity.mul(uint96(_reserve>>128)) / _totalSupply; 
        uint amount1 = liquidity.mul(uint96(_reserve>>32)) / _totalSupply; 
        amount = uint192((amount0<<96)|amount1);
        require(amount > 0, 'CSWP:8');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        uint192 combinedBalance = uint192(IERC20(_token0).balanceOf(address(this))<<96 | IERC20(_token1).balanceOf(address(this)));
        _update(uint(combinedBalance)<<32 | uint32(_reserve));
        if (combinedBalance>0) revisemu(combinedBalance);
        emit Burn(msg.sender, amount, to); 
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amountOut, address to, bytes calldata data) external  lock {       
        uint amount0Out = (amountOut >> 96); 
        uint amount1Out = uint(uint96(amountOut));
        uint balance0;
        uint balance1;
        uint _circleData = circleData;

        { // avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require((to != _token0) && (to != _token1), 'CSWP:9');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            if (data.length > 0) ICoinSwapCallee(to).coinswapCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
            require(balance0*uint56(_circleData >> 160) < 2**96 
                 && balance1*uint56(_circleData >> 104) < 2**96, 'CSWP:10');
        }
        uint amountIn0;
        uint amountIn1;
        uint224 _reserve = reserve;
        {// if _reserve0 < amountOut, then should have been reverted above already, so no need to check here 
            uint96 reserve0 = uint96(_reserve >>128);
            uint96 reserve1 = uint96(_reserve >>32);
            amountIn0 = balance0 + amount0Out - reserve0;
            amountIn1 = balance1 + amount1Out - reserve1;
            uint mulambda0 = uint(uint16(_circleData >> 72))*uint56(_circleData)*uint56(_circleData >> 160);
            uint mulambda1 = uint(uint16(_circleData >> 56))*uint56(_circleData)*uint56(_circleData >> 104);        
            uint X=mulambda0*(balance0*1000 - amountIn0*3); 
            uint Y=mulambda1*(balance1*1000 - amountIn1*3);
    	    require(10**37 > X && 10**37 >Y, 'CSWP:11');
            X = 10**37-X;
            Y = 10**37-Y;
            uint newrSquare = X*X+Y*Y;
            X=10**37-(mulambda0 * reserve0*1000);
            Y=10**37-(mulambda1 * reserve1*1000);
            require(newrSquare<= (X*X+Y*Y), 'CSWP:12');
        }
        _update(balance0<<128 | balance1<<32 | uint32(_reserve));
        emit Swap(msg.sender, uint192(amountIn0<<96 | amountIn1), uint192(amountOut), to);
    }
}

contract CoinSwapFactory {
    address payable public feeTo;
    address payable public feeToSetter;
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address payable _feeToSetter) {
        feeToSetter = _feeToSetter;
        feeTo = _feeToSetter;
    }
    
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB, uint224 circle) external returns (address pair) {  
        require(tx.origin==feeToSetter, 'CSWP:22');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(getPair[token0][token1] == address(0), 'CSWP:20'); 
        require(uint16(circle>>56)>0 && uint16(circle>>72)>0 && 
                uint16(circle>>88)>0 && uint16(circle>>88)<=9999
                && uint56(circle>>104)>=1 && uint56(circle>>104)<=10**16
                && uint56(circle>>160)>=1 && uint56(circle>>160)<=10**16, 'CSWP:23');
        bytes memory bytecode = type(CoinSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        CoinSwapPair(pair).initialize(token0, token1, circle);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; 
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
    
    function setFeeTo(address payable _feeTo) external {
	    require(msg.sender == feeToSetter, 'CSWP:21');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address payable _feeToSetter) external {
        require(msg.sender == feeToSetter, 'CSWP:22');
        feeToSetter = _feeToSetter;
    }
}

contract CoinSwapRouterV1 { 
    using SafeMath for uint;
    address public immutable factory;
    address public immutable WETH;
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'CSWP:30');
        _;
    }
    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
        
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin, 
        uint amountBMin,
        uint224 circle //lambda0/lambda1 in circle needs in order of token0<token1 
    ) internal virtual returns (uint amountA, uint amountB, address pairForAB) {
        pairForAB =CoinSwapFactory(factory).getPair(tokenA, tokenB);
        if (pairForAB == address(0)) {
            pairForAB= CoinSwapFactory(factory).createPair(tokenA,tokenB,circle);
        }
        (uint reserveA, uint reserveB,) = CoinSwapLibrary.getReservesAndmu(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
          (amountA, amountB) = (amountADesired, amountBDesired);
        } else if (reserveA == 0) {
	        (amountA, amountB) = (0, amountBDesired);
	    } else if (reserveB == 0) {
	        (amountA, amountB) = (amountADesired,0);
	    } else {
	        uint amountBOptimal = (amountADesired *reserveB) / reserveA;
	        if (amountBOptimal <= amountBDesired) {
	            require(amountBOptimal >= amountBMin, 'CSWP:31');
	            (amountA, amountB) = (amountADesired, amountBOptimal);
	        } else {
	            uint amountAOptimal = (amountBDesired *reserveA) / reserveB;
	            assert(amountAOptimal <= amountADesired);
	            require(amountAOptimal >= amountAMin, 'CSWP:32');
	            (amountA, amountB) = (amountAOptimal, amountBDesired);
	        }
	    }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amtADesired,
        uint amtBDesired,
        uint amtAMin,
        uint amtBMin,
        address to,
        uint deadline,
        uint224 circle
    ) external virtual ensure(deadline) returns (uint amtA, uint amtB, uint liquidity) {
        address pair;
        (amtA, amtB, pair) = _addLiquidity(tokenA, tokenB, amtADesired, amtBDesired, amtAMin, amtBMin, circle);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amtA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amtB);
        liquidity = CoinSwapPair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amtTokenDesired,
        uint amtTokenMin,
        uint amtETHMin,
        address to,
        uint deadline,
        uint224 circle
    ) external virtual payable ensure(deadline) returns (uint amtToken, uint amtETH, uint liquidity) {
        address pair;
        (amtToken, amtETH, pair) = _addLiquidity(token,WETH,amtTokenDesired,msg.value,amtTokenMin,amtETHMin,circle);
                TransferHelper.safeTransferFrom(token, msg.sender, pair, amtToken);
        IWETH(WETH).deposit{value: amtETH}();
        assert(IWETH(WETH).transfer(pair, amtETH));
        liquidity = CoinSwapPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amtETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amtETH);
    }

    // **** REMOVE LIQUIDITY **** 
    // For OCI market, we do not have specific remove liquidity function
    // but one can remove a pair by providing OCI-ed addresses
       function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amtAMin,
        uint amtBMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = CoinSwapLibrary.pairFor(factory, tokenA, tokenB);
        CoinSwapPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        uint192 amount = CoinSwapPair(pair).burn(to);
        (amountA, amountB) = tokenA < tokenB ? (uint(amount>>96), uint(uint96(amount))) : (uint(uint96(amount)), uint(amount>>96));
        require((amountA >= amtAMin) && (amountB >= amtBMin), 'CSWP:33');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual returns (uint amountA, uint amountB) {
        address pair = CoinSwapLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        CoinSwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual returns (uint amountToken, uint amountETH) {
        address pair = CoinSwapLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        CoinSwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }
    
    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual returns (uint amountETH) {
        address pair = CoinSwapLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        CoinSwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }
    

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input < output ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? CoinSwapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            CoinSwapPair(CoinSwapLibrary.pairFor(factory, input, output)).swap(
                uint192((amount0Out<<96) | amount1Out), to, new bytes(0));
        }
    }
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        amounts = CoinSwapLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'CSWP:34');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, CoinSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        amounts = CoinSwapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'CSWP:35');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, CoinSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'CSWP:36');
        amounts = CoinSwapLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'CSWP:37');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(CoinSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'CSWP:38');
        amounts = CoinSwapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'CSWP:39');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, CoinSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'CSWP:40');
        amounts = CoinSwapLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'CSWP:41');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, CoinSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'CSWP:42');
        amounts = CoinSwapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'CSWP:43');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(CoinSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            CoinSwapPair pair = CoinSwapPair(CoinSwapLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
	    
	    (uint reserveInput, uint reserveOutput, uint mulambda) = CoinSwapLibrary.getReservesAndmu(factory, input, output);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = CoinSwapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput, mulambda);
            }
            (uint amount0Out, uint amount1Out) = input < output ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? CoinSwapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(uint192(amount0Out<<96 | amount1Out), to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, CoinSwapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'CSWP:44'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'CSWP:45');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(CoinSwapLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'CSWP:46'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'CSWP:47');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, CoinSwapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'CSWP:48');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint mulambda) public pure returns (uint amountOut) {
        return CoinSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut, mulambda);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint mulambda) public pure returns (uint amountIn) {
        return CoinSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut, mulambda);
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        return CoinSwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path) public view returns (uint[] memory amounts) {
        return CoinSwapLibrary.getAmountsIn(factory, amountOut, path);
    }
}



// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CSWP70');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CSWP71');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CSWP72');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'CSWP73');
    }
}

library CoinSwapLibrary {
    using SafeMath for uint;

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'08d6ace72c919d3777e7a6a0ae82941b79932ea4e7b37e16d8c04f7fd2783574'
            ))));
    }

    function getReservesAndmu(address factory, address tokenA, address tokenB) internal view returns 
                                        (uint reserveA, uint reserveB, uint mulambda) {
        (uint224 reserve, uint224 circleData) = CoinSwapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        uint reserve0 = uint(reserve>>128);
        uint reserve1 = uint(uint96(reserve>>32));
        uint mulambda0 = uint(uint16(circleData >> 72))* uint56(circleData >> 160) * uint56(circleData);
        uint mulambda1 = uint(uint16(circleData >> 56))* uint56(circleData >> 104) * uint56(circleData);
        (reserveA, reserveB, mulambda) = tokenA < tokenB ?
	      (reserve0,reserve1, (mulambda0<<128) | mulambda1 ):(reserve1,reserve0, (mulambda1<<128) | mulambda0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint mulambda) internal pure returns (uint amountOut) {
        require((amountIn > 0) && (reserveOut > 0), 'CSWP:63');
	    uint mulambda0 = (mulambda>>128);
	    uint mulambda1 = uint(uint128(mulambda));
        uint Z = 10**37-(mulambda0 * reserveIn * 1000);
        uint R0=Z*Z;
        Z= 10**37-(mulambda1 * reserveOut * 1000);
        R0 += Z*Z;
        uint ZZ = uint(10**37).sub(mulambda0 * (1000*reserveIn + amountIn * 997));  
        R0 = R0.sub(ZZ*ZZ);  
        R0 = SQRT.sqrt(R0);
        amountOut = R0.sub(Z) / (mulambda1 * 1000);
	    if (amountOut > reserveOut) amountOut = reserveOut;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint mulambda) internal pure returns (uint amountIn) {
        uint mulambda0 = (mulambda>>128);
	    uint mulambda1 = uint(uint128(mulambda));
        uint Z= 10**37-(mulambda1 * reserveOut * 1000);
        uint R1 = Z*Z;
	    Z = 10**37-(mulambda0 * reserveIn * 1000);
        R1 += Z*Z;
        uint ZZ = 10**37-(mulambda1 * 1000* (reserveOut.sub(amountOut)));  
	    R1 =R1.sub(ZZ*ZZ); 
        amountIn = 1+ (Z.sub(SQRT.sqrt(R1))) / (mulambda0 * 997) ; 
    }

    function getAmountsOut(address factory, uint amountIn, address[] memory path) 
            internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'CSWP:65');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut, uint mulambda) 
                = getReservesAndmu(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, mulambda);
        }
    }

    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'CSWP:66');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut, uint mulambda) 
                = getReservesAndmu(factory, path[i-1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, mulambda);
        }
    }
}



library SQRT {
    function sqrt(uint256 a) internal pure returns (uint256 x) { 
        if (a > 3) {
            uint msbpos =0;
            uint b=a;
            if (b > 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
                msbpos += 128;
                b = b >> 128;
            } 
            if (b > 0xFFFFFFFFFFFFFFFF) {
                msbpos += 64;
                b = b>>64;
            }
            if (b > 0xFFFFFFFF ) {
                msbpos += 32;
                b = b>>32;
            }
            if (b > 0xFFFF ) {
                msbpos += 16;
                b = b>>16;
            }
            if (b > 0xFF ) {
                msbpos += 8;
                b = b>>8;
            }
            if (b > 0xF ) {
                msbpos += 4;
            }
            msbpos += 4;
            
            uint256 x0=a;
            uint X=((a >> 1) + 1);
            uint Y=2**(msbpos/2);
            x = X< Y ? X : Y;
            while (x < x0 ) {
                x0 = x;
                x = (a / x0 + x0) >> 1;
            }
        } else if (a != 0) {
            x = 1;
        }
    }
}


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