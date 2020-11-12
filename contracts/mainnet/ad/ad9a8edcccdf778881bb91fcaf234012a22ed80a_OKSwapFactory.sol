//author: 谛听

// File: localhost/contracts/interfaces/IOKra.sol

pragma solidity >=0.5.0;

interface IOKra {
    function  mint(address _to, uint256 _amount) external returns (uint);
    function balanceOf(address owner) external view returns (uint);
}
// File: localhost/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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
    event Harvest(address indexed sender, uint amount);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to,address user,bool emerg) external returns (uint amount0, uint amount1);
    function swap(uint[3] memory amount, address to, bytes calldata data) external;
    function skim(address to) external;
    function pending(address user) external view returns (uint);
    function harvestNow(address to) external;
    function sync() external;

    function initialize(address, address,address) external;
}
// File: localhost/contracts/interfaces/IUniswapV2Callee.sol

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// File: localhost/contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC20Uniswap {
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

// File: localhost/contracts/libraries/UQ112x112.sol

pragma solidity =0.6.12;

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

// File: localhost/contracts/libraries/Math.sol

 pragma solidity =0.6.12;

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

// File: localhost/contracts/interfaces/IUniswapV2ERC20.sol

    pragma solidity >=0.5.0;

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

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}
// File: localhost/contracts/libraries/SafeMath.sol

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
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
        require(b > 0, 'ds-math-div-overflow');
        uint256 c = a / b;
        return c;
    }

}


// File: localhost/contracts/OKSwapERC20.sol

pragma solidity =0.6.12;



contract OKSwapERC20 is IUniswapV2ERC20 {
    using SafeMathUniswap for uint;

    string public override constant name = 'OKSwap LPT';
    string public override constant symbol = 'OKLP';
    uint8 public override constant decimals = 18;
    uint  public  override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public override constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

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

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override  returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'OKSwapERC20: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'OKSwapERC20: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// File: localhost/contracts/OKSwapPair.sol

pragma solidity =0.6.12;











contract OKSwapPair is OKSwapERC20 {

    address public okra;

    using SafeMathUniswap  for uint;
    using UQ112x112 for uint224;

    uint public   constant MINIMUM_LIQUIDITY = 10 ** 3;
    uint public constant BONUS_BLOCKNUM = 36000;
    uint public constant BASECAP = 5120 * (10 ** 18);
    uint public constant TEAM_BLOCKNUM = 13200000;
    uint private constant TEAM_CAP = 15000000 * (10 ** 18);
    uint private constant VC_CAP = 5000000 * (10 ** 18);
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public   factory;
    address public   token0;
    address public  token1;
    

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public  price0CumulativeLast;
    uint public  price1CumulativeLast;
    uint public  kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    mapping(address => uint) public userPools;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'OKSwap: LOCKED');
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
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'OKSwap: TRANSFER_FAILED');
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
    event Harvest(address indexed sender, uint amount);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, address _okra) external {
        require(msg.sender == factory, 'OKSwap: FORBIDDEN');
        // sufficient check
        token0 = _token0;
        token1 = _token1;
        okra = _okra;
    }


    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(- 1) && balance1 <= uint112(- 1), 'OKSwap: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        // overflow is desired
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
//        address feeTo = IOkswapFactory(factory).feeTo();
        (,,,address feeHolder,address burnHolder,) = IOkswapFactory(factory).getBonusConfig(address(this));
        feeOn = true;
        uint _kLast = kLast;
        // gas savings
        if (_kLast != 0) {
            uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
            uint rootKLast = Math.sqrt(_kLast);
            if (rootK > rootKLast) {
                uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                uint denominator = rootK.mul(5).add(rootKLast);
                uint liquidity = numerator.mul(2) / denominator;
                if (liquidity > 0) {
                    if (feeHolder != address(0)) _mint(feeHolder, liquidity);
                    if (burnHolder != address(0)) _mint(burnHolder, liquidity);
                }
            }
        }

    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint balance0 = IERC20Uniswap(token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply;
        // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'OKSwap: INSUFFICIENT_LIQUIDITY_MINTED');
        if (IOkswapFactory(factory).isBonusPair(address(this))) {
            uint startAtBlock = userPools[to];
            if (startAtBlock > 0) {
                uint liquid = balanceOf[to];
                userPools[to] = startAtBlock.mul(liquid).add(block.number.mul(liquidity)) / liquid.add(liquidity);
            }else{
                userPools[to] = block.number;
            }
           
        }
        _mint(to, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1);
        // reserve0 and reserve1 are up-to-date
        
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to,address user,bool emerg) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // gas savings
        address _token0 = token0;
        // gas savings
        address _token1 = token1;
        // gas savings
        uint balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply;
        // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply;
        amount1 = liquidity.mul(balance1) / _totalSupply;
        // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'OKSwap: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        balance1 = IERC20Uniswap(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1);
        // reserve0 and reserve1 are up-to-date

        if (!emerg) _getHarvest(user);

        emit Burn(msg.sender, amount0, amount1, to);
    }
    
    function _getHarvest(address _to) private {

            (uint based,,,,,) = IOkswapFactory(factory).getBonusConfig(address(this));
            if (based > 0 ) {
                uint harvestLiquid = balanceOf[_to];
                uint pendingAmount = _getHarvestAmount(harvestLiquid, based, userPools[_to]);
                uint max = BASECAP + IOKra(okra).balanceOf(_to);
                uint mintAmount = pendingAmount <= max ? pendingAmount : max;
                userPools[_to] = block.number;
                IOkswapFactory(factory).realize(_to, mintAmount);

                emit Harvest(msg.sender, mintAmount);
            }

    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint[3] memory amount, address to, bytes calldata data) external lock {
        uint amount0Out = amount[0];
        uint amount1Out = amount[1];
        uint amountIn = amount[2];

        require(amount0Out > 0 || amount1Out > 0, 'OKSwap: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'OKSwap: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        {// scope for _token{0,1}, avoids stack too deep errors
            require(to != token0 && to != token1, 'OKSwap: INVALID_TO');
            if (amount0Out > 0) {_safeTransfer(token0, to, amount0Out);assign(amount0Out,token1,token0,amountIn,to);}
            if (amount1Out > 0) {_safeTransfer(token1, to, amount1Out);assign(amount1Out,token0,token1,amountIn,to);}
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20Uniswap(token0).balanceOf(address(this));
            balance1 = IERC20Uniswap(token1).balanceOf(address(this));

        }

        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'OKSwap: INSUFFICIENT_INPUT_AMOUNT');
        {// scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000 ** 2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
    

    function assign(uint amountOut,address tokenIn, address tokenOut, uint amountIn, address to) private {
        (,,address tokenAddress,,,) = IOkswapFactory(factory).getBonusConfig(address(this));
        if (tokenAddress == tokenIn) {
            _tradeBonus(tokenIn, amountIn, to);
        }else if (tokenAddress == tokenOut) {
            _tradeBonus(tokenIn, amountOut, to);
        } 
    }
    
    
    function _tradeBonus(address _token, uint _amountOut, address _to) private {
        IOkswapFactory _factory = IOkswapFactory(factory);
        if (_token != address(okra) && _factory.isBonusPair(address(this))) {
            uint sysCf = _factory.getSysCf();
            (uint elac0,uint elac1) = IOkswapFactory(factory).getElac();
            (,uint share, ,address teamHolder,,address vcHolder) = _factory.getBonusConfig(address(this));
            uint tradeMint = _amountOut.div(100).mul(share).div(sysCf);
            tradeMint = tradeMint.mul(elac0).div(elac1);
            _realize(tradeMint,_to,teamHolder,vcHolder);
        }
    }


    function _realize(uint tradeMint,address _to,address teamHolder,address vcHolder) private {
        if (tradeMint > 0) {
            IOkswapFactory(factory).realize(_to, tradeMint);
            uint syncMint = tradeMint.div(100).mul(2);
            uint vcNum = IOkswapFactory(factory).vcAmount();
            uint vcMint = vcNum.add(syncMint) >= VC_CAP ? VC_CAP.sub(vcNum) : syncMint;
            if (vcMint > 0 && vcHolder != address(0)) {
                IOkswapFactory(factory).updateVcAmount(vcMint);
                IOkswapFactory(factory).realize(vcHolder, vcMint);
            }
            if (block.number >= TEAM_BLOCKNUM) {
                uint teamNum = IOkswapFactory(factory).teamAmount();
                syncMint = syncMint.mul(3);
                uint teamMint = teamNum.add(syncMint) >= TEAM_CAP ? TEAM_CAP.sub(teamNum) : syncMint;
                if (teamMint > 0 && teamHolder != address(0)){
                    IOkswapFactory(factory).updateTeamAmount(teamMint);
                    IOkswapFactory(factory).realize(teamHolder, teamMint);
                }
            }

            emit Harvest(msg.sender, tradeMint);
        }
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(_token0, to, IERC20Uniswap(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20Uniswap(_token1).balanceOf(address(this)).sub(reserve1));
    }


    function _getHarvestAmount(uint _amount, uint _based, uint _startBlock) private view returns (uint){
        uint sysCf = IOkswapFactory(factory).getSysCf();
        (uint elac0,uint elac1) = IOkswapFactory(factory).getElac();

        uint point = (block.number.sub(_startBlock)) / BONUS_BLOCKNUM;

        uint mintAmount;
        if (point == 0) {
            mintAmount = _amount.mul(block.number.sub(_startBlock));
        } else if (point == 1) {
            uint amount0 = _amount.mul(BONUS_BLOCKNUM);
            uint amount1 = _amount.mul(block.number.sub(_startBlock).sub(BONUS_BLOCKNUM));
            mintAmount = amount0.add(amount1.mul(2));
        } else {
            uint amount0 = _amount.mul(BONUS_BLOCKNUM);
            uint amount1 = _amount.mul(block.number.sub(_startBlock).sub(BONUS_BLOCKNUM).sub(BONUS_BLOCKNUM));
            mintAmount = amount0.add(amount0.mul(2)).add(amount1.mul(3));
        }

        return mintAmount.mul(elac0).div(elac1).div(sysCf).mul(100).div(_based);
    }


    function getblock(address _user) external view returns (uint256){
        return userPools[_user];
    }

    function pending(address _user) external view returns (uint256) {
        (uint _based,,,,,) = IOkswapFactory(factory).getBonusConfig(address(this));
        uint sysCf = IOkswapFactory(factory).getSysCf();
        (uint elac0,uint elac1) = IOkswapFactory(factory).getElac();
        uint _startBlock = userPools[_user];
        uint _amount = balanceOf[_user];
        require(block.number >= _startBlock, "OKSwap:FAIL");

        uint point = (block.number.sub(_startBlock)) / BONUS_BLOCKNUM;
        uint mintAmount;
        if (point == 0) {
            mintAmount = _amount.mul(block.number.sub(_startBlock));
        } else if (point == 1) {
            uint amount0 = _amount.mul(BONUS_BLOCKNUM);
            uint amount1 = _amount.mul(block.number.sub(_startBlock).sub(BONUS_BLOCKNUM));
            mintAmount = amount0.add(amount1.mul(2));
        } else {
            uint amount0 = _amount.mul(BONUS_BLOCKNUM);
            uint amount1 = _amount.mul(block.number.sub(_startBlock).sub(BONUS_BLOCKNUM).sub(BONUS_BLOCKNUM));
            mintAmount = amount0.add(amount0.mul(2)).add(amount1.mul(3));
        }
        return mintAmount.mul(elac0).div(elac1).div(sysCf).mul(100).div(_based);
    }


    function harvestNow() external {
        address _to = msg.sender;
        (uint based,,,,, ) = IOkswapFactory(factory).getBonusConfig(address(this));
        require(based > 0, 'OKSwap: FAIL_BASED');
        uint _amount = balanceOf[_to];
        uint pendingAmount = _getHarvestAmount(_amount, based, userPools[_to]);
        uint max = BASECAP + IOKra(okra).balanceOf(_to);
        uint mintAmount = pendingAmount <= max ? pendingAmount : max;
        userPools[_to] = block.number;
        IOkswapFactory(factory).realize(_to, mintAmount);
        emit Harvest(msg.sender, mintAmount);
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20Uniswap(token0).balanceOf(address(this)), IERC20Uniswap(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

// File: localhost/contracts/interfaces/IOkswapFactory.sol

pragma solidity >=0.5.0;

interface IOkswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function teamAmount() external view returns (uint);
    function vcAmount() external view returns (uint);
    function isBonusPair(address) external view returns (bool);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function changeSetter(address) external;
    function setFeeHolder(address) external;
    function setBurnHolder(address) external;
    function setVcHolder(address) external;

    function pairCodeHash() external pure returns (bytes32);
    function addBonusPair(uint, uint, address, address, bool) external ;
    function getBonusConfig(address) external view returns (uint, uint,address,address,address,address);
    function getElac() external view returns (uint, uint);
    function setElac(uint,uint) external;
    function updateTeamAmount(uint) external;
    function updateVcAmount(uint) external;
    function realize(address,uint) external;

    function getSysCf() external view returns (uint);
}

// File: localhost/contracts/OKSwapFactory.sol

pragma solidity =0.6.12;




contract OKSwapFactory is IOkswapFactory {
    address private  setter;
    uint    public  startBlock;
    address public  okra;
    address public  feeHolder;
    address public  burnHolder;
    address public  vcHolder;
    address public  elacSetter;
    uint public override teamAmount;
    uint public override vcAmount;
    uint private  elac0;
    uint private  elac1;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    mapping(address => bool) public override isBonusPair;
    
    struct mintPair {
        uint32 based;
        uint8 share;
        address token;
    }

    mapping(address => mintPair) public mintPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _setter,address _okra) public {
        setter = _setter;
        startBlock = block.number;
        okra = _okra;
        elacSetter = _setter;
        elac0 = 1;
        elac1 = 1;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external override pure returns (bytes32) {
        return keccak256(type(OKSwapPair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'OKSwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'OKSwap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'OKSwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(OKSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        OKSwapPair(pair).initialize(token0, token1,okra);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }


    function changeSetter(address _setter) external override {
        require(msg.sender == setter, 'OKSwap: FORBIDDEN');
        setter = _setter;
    }
    
    function setFeeHolder(address _holder) external override {
        require(msg.sender == setter, 'OKSwap: FORBIDDEN');
        feeHolder = _holder;
    }
    
    function setBurnHolder(address _holder) external override {
        require(msg.sender == setter, 'OKSwap: FORBIDDEN');
        burnHolder = _holder;
    }

    function setVcHolder(address _holder) external override {
        require(msg.sender == setter, 'OKSwap: FORBIDDEN');
        vcHolder = _holder;
    }

    function setElacContract(address _setter) external {
        require(msg.sender == elacSetter, 'OKSwap: FORBIDDEN');
        elacSetter = _setter;
    }
    

    function getSysCf() external override view returns (uint){
        uint cf = (block.number - startBlock) / 512000 ;
        return cf <= 0 ? 1 : (2 ** cf);
    }

    function addBonusPair(uint _based, uint _share, address _pair, address _token, bool _update) external override {
        require(msg.sender == setter, "OKSwap: FORBIDDEN");
        if (_update) {
            require(mintPairs[_pair].token != address(0),"OKSwap: TOKEN");
            mintPairs[_pair].based = uint32(_based);
            mintPairs[_pair].share = uint8(_share);
            mintPairs[_pair].token = _token;
            isBonusPair[_pair] = !isBonusPair[_pair];
        }

        mintPairs[_pair].based = uint32(_based);
        mintPairs[_pair].share = uint8(_share);
        mintPairs[_pair].token = _token;
        
        isBonusPair[_pair] = true;
    }
    
    function getBonusConfig(address _pair) external override view returns (uint _based, uint _share,address _token,address _feeHolder,address _burnHolder,address _vcHolder) {
        _based = mintPairs[_pair].based;
        _share = mintPairs[_pair].share;
        _token = mintPairs[_pair].token;
        _feeHolder = feeHolder;
        _burnHolder = burnHolder;
        _vcHolder = vcHolder;
    }

    function getElac() external override view returns (uint _elac0, uint _elac1) {
        _elac0 = elac0;
        _elac1 = elac1;
    }


    function setElac(uint _elac0,uint _elac1) external override {
        require(msg.sender == elacSetter, 'OKSwap: FORBIDDEN');
        elac0 = _elac0;
        elac1 = _elac1;
    }

    function updateVcAmount(uint amount) external override {
        require(isBonusPair[msg.sender], "OKSwap: FORBIDDEN");
        require(amount > 0, "OKSwap: Ops");
        vcAmount += amount;
    }

    function updateTeamAmount(uint amount) external override {
        require(isBonusPair[msg.sender], "OKSwap: FORBIDDEN");
        require(amount > 0, "OKSwap: Ops");
        teamAmount += amount;
    }

    function realize(address _to,uint amount) external override {
        require(isBonusPair[msg.sender], "OKSwap: FORBIDDEN");
        IOKra(okra).mint(_to, amount);
    }

}