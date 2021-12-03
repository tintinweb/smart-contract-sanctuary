/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
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

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface InterfaceLP {
    function sync() external;
}

// IUniswapV2Factory interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract ShivaFestival is IBEP20, Auth {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    address WBNB;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address public constant BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // mainnet : 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 , testnet : 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7

    string constant _name = "Shiba Festival";
    string constant _symbol = "SFEST";
    uint8 constant _decimals = 4;

    address [] public holderList;
    mapping (address => bool) isHolder;
    mapping (address => bool) isExcludeFromReward;
    mapping (address => uint256) _gonBalances;
    mapping (address => mapping (address => uint256)) _allowances;

    uint256 public liquidityFee = 400;
    uint256 public marketingFee = 300;
    uint256 public rewardFee = 500;
    uint256 public totalFee = liquidityFee.add(marketingFee).add(rewardFee);
    uint256 public feeDenominator = 10000;

    address public marketingAddress;
    address public liquidityAddress;

    IUniswapV2Router02 public router;
    address public pair;
    address public bnb_busdPair = address(0xe0e92035077c39594793e61802a350347c320cf2); // mainnet : 0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16, testnet : 0xe0e92035077c39594793e61802a350347c320cf2
    InterfaceLP public pairContract; 

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    uint256 public rebase_count = 0;
    uint256 public _totalSupply;
    uint256 public  swapThreshold;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**11 * 10**_decimals;
    uint256 private _gonsPerFragment;
    uint256 private LIMIT_TOKEN_PRICE = 1;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    function rebase(int256 supplyDelta)
        external
        onlyOwner
        returns (uint256)
    {
        require(!inSwap, "Try again");
        require(isValidRebase(), "Token price is over 1 dollar");

        if (supplyDelta == 0) {
            emit LogRebase(rebase_count, _totalSupply);
            return _totalSupply;
        }

        rebase_count ++;

        _totalSupply = _totalSupply.sub(uint256(supplyDelta));

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        pairContract.sync();

        emit LogRebase(rebase_count, _totalSupply);
        return _totalSupply;
    }

    function makeReward() external onlyOwner returns (bool) {
        uint256 tokenAmount = 0;
        for (uint i = 0; i < holderList.length; i++) {
            if ( !isExcludeFromReward[holderList[i]] && (_gonBalances[holderList[i]] > 0)) 
            {
                tokenAmount = _gonBalances[holderList[i]].div(_gonsPerFragment);
                _basicTransfer(owner, holderList[i], tokenAmount);
            }
        }

        return true;
    }

    constructor () Auth(msg.sender) {
        router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // mainnet : 0x10ED43C718714eb63d5aA57B78B54704E256024E, testnet : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        WBNB = router.WETH();
        pair = IUniswapV2Factory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);        
        pairContract = InterfaceLP(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        swapThreshold = 1000 * 10**_decimals;

        marketingAddress = 0xD85c23E09ecB7aAF696F162Bf37835Bf9e242d4f;
        liquidityAddress = 0x77508984FF5A95ABc1c1EeC733f229736B33032c;

        isExcludeFromReward[address(this)] = true;
        isExcludeFromReward[owner] = true;
        isExcludeFromReward[pair] = true;
        isExcludeFromReward[marketingAddress] = true;
        isExcludeFromReward[liquidityAddress] = true;
        isExcludeFromReward[DEAD] = true;

        _gonBalances[msg.sender] = TOTAL_GONS;
        emit Transfer(ZERO, msg.sender, _totalSupply);
    }

    receive() external payable { }
    
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }

    function balanceOf(address account) public view override returns (uint256) {
        return _gonBalances[account].div(_gonsPerFragment);
    }
    
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        uint256 gonAmount = amount.mul(_gonsPerFragment);
        
        if(shouldSwapBack(sender, recipient)){ swapBack(); }

        //Exchange tokens
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, gonAmount) : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(amountReceived);

        // add recipient address to holder list
        if (!isHolder[recipient]) {
            isHolder[recipient] = true;
            holderList.push(recipient);
        }

        emit Transfer(sender, recipient, amountReceived.div(_gonsPerFragment));
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount, "Insufficient Balance");
        _gonBalances[recipient] = _gonBalances[recipient].add(gonAmount);

        // add recipient address to holder list
        if (!isHolder[recipient]) {
            isHolder[recipient] = true;
            holderList.push(recipient);
        }

        emit Transfer(sender, recipient, gonAmount.div(_gonsPerFragment));
        return true;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return (pair == sender || pair == recipient);
    }

    function takeFee(address sender, uint256 gonAmount) internal returns (uint256) {
        uint256 feeAmount = gonAmount.mul(totalFee).div(feeDenominator);
        _gonBalances[address(this)] = _gonBalances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    function shouldSwapBack(address sender, address recipient) internal view returns (bool) {
        return sender != pair
            &&  recipient != pair 
            && !inSwap 
            && _gonBalances[address(this)] >= swapThreshold.mul(_gonsPerFragment);
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = _gonBalances[address(this)].div(_gonsPerFragment);

        // send to owner
        uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFee);
        _basicTransfer(address(this), liquidityAddress, swapTokens);

        // send to marketing address
        uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFee);
        _basicTransfer(address(this), marketingAddress, marketingTokens);
        
        // send to dev address
        uint256 rewardTokens = contractTokenBalance.mul(rewardFee).div(totalFee);
        _basicTransfer(address(this), owner, rewardTokens);

        _gonBalances[address(this)] = 0;
    }

    function setFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _rewardFee, uint256 _feeDenominator) external onlyOwner {
        marketingFee = _marketingFee;
        liquidityFee = _liquidityFee;
        rewardFee = _rewardFee;
        totalFee = marketingFee.add(liquidityFee).add(rewardFee);
        feeDenominator = _feeDenominator;
    }

    function setMarketingAddress(address _marketingAddress) external authorized {
        marketingAddress = _marketingAddress;
    }

    function setLiquidityAddress(address _liquidityAddress) external {
        require(msg.sender == liquidityAddress, "Only previous dev can change dev address");
        liquidityAddress = _liquidityAddress;
    }

    function setSwapBackAmount(uint256 tokenAmount) external authorized {
        swapThreshold = tokenAmount;
    }

    function manualSync() external {
        InterfaceLP(pair).sync();
    }
    
    function setLP(address _address) external onlyOwner {
        pairContract = InterfaceLP(_address);
    }
    
    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }
    
    function rescueToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return IBEP20(tokenAddress).transfer(msg.sender, tokens);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(_gonsPerFragment);
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, address _pair)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair)
            .getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    function isValidRebase() public view returns (bool) {
        // get BNB price
        (uint256 _reserveA1, uint256 _reserveB1) = getReserves(
            WBNB,
            BUSD,
            bnb_busdPair
        );

        uint256 _bnb_price = _reserveB1.div(_reserveA1);

        (uint256 _reserveA, uint256 _reserveB) = getReserves(
            address(this),
            WBNB,
            pair
        );

        uint256 _market_price = _reserveB.mul(_bnb_price).div(10**14).div(_reserveA);
        return (_market_price < LIMIT_TOKEN_PRICE);
    }

    function sendToBurn(uint256 amount) 
        external 
        onlyOwner 
    {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _totalSupply = _totalSupply.sub(gonAmount.div(_gonsPerFragment));
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonAmount);
        _gonBalances[DEAD] = _gonBalances[DEAD].add(gonAmount);

        emit Transfer(
            msg.sender,
            DEAD,
            gonAmount.div(_gonsPerFragment)
        );
    }
}