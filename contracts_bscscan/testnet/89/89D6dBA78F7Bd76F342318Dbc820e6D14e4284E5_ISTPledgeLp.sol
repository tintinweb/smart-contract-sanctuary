/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

pragma solidity 0.5.16;

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

library UniswapV2Library {
    using SafeMath for uint;

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'bb600ba95884f2c2837114fd2f157d00137e0b65b0fe5226523d720e4a4ce539' // init code hash
            ))));
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

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
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

contract Ownable is Context {
    address private _owner;
    address private _profitor;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        _profitor = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function profitor() public view returns (address) {
        return _profitor;
    }

    function setProfitor(address profitorVal) public onlyOwner returns (bool) {
        _profitor = profitorVal;
        return true;
    }

    modifier onlyProfitor(){
        require(_profitor == _msgSender(), "Ownable: caller is not the profitor");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ISTPledgeLp is Context, Ownable {

    using SafeMath for uint256;

    IBEP20 _IstToken;
    IUniswapV2Pair _LpToken;
    KeyFlag[] public keys;
    MintParams[] public mintArr;

    uint256 public perPledgeMinAmount;
    uint256 public pledegTotalAmount;
    uint256 public mintTotalAmount;
    uint256 public pledgingCount;

    uint256 public mintLimit;
    uint256 public mintLimitAdd;
    uint256 public mintBaseVal;
    uint256 public decreaseFlag;

    uint256 public fee_receive_rate1;
    address public fee_receive_addr1;
    uint256 public fee_receive_rate2;
    address public fee_receive_addr2;

    uint256 public divBaseVal;
    uint256 public giveProfitLastTime;
    uint256 public returnPrincipalRate;

    address public istTokenAddr;
    address public lpTokenAddr;
    address public factory;
    address public lpTokenA;
    address public lpTokenB;

    mapping(address => PledgerInfo) public pledgeData;

    struct PledgerInfo {
        bool isHas;
        uint256 pledgeToken;
        uint256 profitToken;
        uint256 allProfitToken;
        uint256 index;
    }

    struct KeyFlag {
        address key;
        bool isExist;
    }

    struct MintParams {
        uint256 mintTriggerLp;
        uint256 mintIstAmount;
        uint256 triggerLpAmount;
        uint256 triggerTime;
    }

    event PledgeTokenEvent(address indexed sender, uint256 amount);
    event TakePrincipalEvent(address indexed sender, uint256 amount);
    event TakeProfitEvent(address indexed sender, uint256 amount);

    constructor(
        address _istTokenAddr,
        address _factory,
        address _lpTokenA,
        address _lpTokenB,
        uint256 _ledgeMinAmount,
        address _fee_receive_addr1,
        address _fee_receive_addr2
    ) public {
        istTokenAddr = _istTokenAddr;
        _IstToken = IBEP20(istTokenAddr);

        factory = _factory;
        lpTokenA = _lpTokenA;
        lpTokenB = _lpTokenB;
        lpTokenAddr = UniswapV2Library.pairFor(factory, lpTokenA, lpTokenB);
        _LpToken = IUniswapV2Pair(lpTokenAddr);

        perPledgeMinAmount = _ledgeMinAmount;
        mintLimit = 10000 * 10 ** uint256(_LpToken.decimals());
        mintLimitAdd = 50000 * 10 ** uint256(_LpToken.decimals());
        mintBaseVal = 500 * 10 ** uint256(_IstToken.decimals());
        decreaseFlag = 2000000 * 10 ** uint256(_IstToken.decimals());
        fee_receive_rate1 = 10;
        fee_receive_rate2 = 20;
        fee_receive_addr1 = _fee_receive_addr1;
        fee_receive_addr2 = _fee_receive_addr2;
        returnPrincipalRate = 500;
        divBaseVal = 1000;
        giveProfitLastTime = block.timestamp;
    }

    function getContractTokens() public view returns (uint256 _istAmount, uint256 _lpAmount){
        uint256 istAmount = _IstToken.balanceOf(address(this));
        uint256 lpAmount =_LpToken.balanceOf(address(this));
        return (istAmount, lpAmount);
    }

    function getLpTokensData() public view returns (uint256 _liquidity, uint256 _reservesA, uint256 _reservesB){
        uint256 liquidity = _LpToken.totalSupply();
        (uint256 reservesA, uint256 reservesB) = UniswapV2Library.getReserves(factory, lpTokenA, lpTokenB);
        return (liquidity, reservesA, reservesB);
    }

    function getUserLpData() public view returns (uint256 _liquidity, uint256 _tokenAAmount, uint256 tokenBAmount){
        uint256 userLiquidity = _LpToken.balanceOf(_msgSender());
        (uint256 utokenAAmount, uint256 utokenBAmount) = getLiquidityValue(factory, lpTokenA, lpTokenB, userLiquidity);
        return (userLiquidity, utokenAAmount, utokenBAmount);
    }

    function getUserLedgeInfo() public view returns (uint256 _pledgeTokens, uint256 _profitTokens, uint256 _allProfitTokens) {
        PledgerInfo memory pledge  = pledgeData[_msgSender()];
        return (pledge.pledgeToken, pledge.profitToken, pledge.allProfitToken);
    }

    function getPledgeJoinCount() public view returns (uint256){
        return keys.length;
    }

    function getPledgingCount() public view returns (uint256){
        return pledgingCount;
    }

    function pledgeToken(uint256 _amount) public returns (bool){
        require(_amount >= perPledgeMinAmount, "pledge amount must be greater than the minimum pledge amount");
        require(_LpToken.allowance(_msgSender(), address(this)) >= _amount,"pledge amount should be less than the lp approve amount");
        require(_msgSender() == address(tx.origin), "submission address cannot be a contract address");

        _LpToken.transferFrom(_msgSender(), address(this), _amount);

        if(pledgeData[_msgSender()].isHas == false){
            keys.push(KeyFlag(_msgSender(), true));
            pledgingCount ++;
            _createPledgerInfo(_amount, keys.length.sub(1));
        }else{
            PledgerInfo storage pledger = pledgeData[_msgSender()];
            pledger.pledgeToken = pledger.pledgeToken.add(_amount);
            if(keys[pledger.index].isExist == false){
                pledgingCount ++;
            }
            keys[pledger.index].isExist = true;
        }

        pledegTotalAmount = pledegTotalAmount.add(_amount);

        emit PledgeTokenEvent(_msgSender(), _amount);

        return true;
    }

    function giveProfits() public onlyProfitor returns (bool) {
        require(pledegTotalAmount > 0, "fund of pledge pool should be greater than 0");
        require(pledegTotalAmount >= mintLimit, "fund of pledge pool should be greater than mint limit value");
        require(pledgingCount > 0, "number of users in the pledge pool must be greater than 0");

        uint256 mintAmount = _mintIst(pledegTotalAmount);

        for(uint256 i = 0; i < keys.length; i++) {
            if(keys[i].isExist == true){
                PledgerInfo storage pledger = pledgeData[keys[i].key];
                uint256 profit = pledger.pledgeToken.div(pledegTotalAmount).mul(mintAmount);
                pledger.profitToken = pledger.profitToken.add(profit);
                pledger.allProfitToken = pledger.allProfitToken.add(profit);
            }
        }

        giveProfitLastTime = block.timestamp;

        return true;
    }

    function takePrincipal(uint256 _amount) public returns (bool) {
        require(_amount > 0, "withdrawal amount must be greater than 0");
        require(_msgSender() == address(tx.origin), "submission address cannot be a contract address");

        PledgerInfo storage pledge = pledgeData[_msgSender()];
        require(pledge.pledgeToken > 0 , "pledge amount must be greater than 0");
        require(_amount <= pledge.pledgeToken, "withdrawal amount should be less than the pledge amount");

        uint256 halfHistoryProfit = pledge.allProfitToken.mul(returnPrincipalRate).div(divBaseVal);
        require(pledge.profitToken >= halfHistoryProfit, "current profit amount should be more than half of total profit amount");
        pledge.profitToken = pledge.profitToken.sub(halfHistoryProfit);

        pledegTotalAmount = pledegTotalAmount.sub(_amount);
        if(pledge.pledgeToken == _amount){
            pledge.pledgeToken = 0;
            pledgingCount --;
            keys[pledge.index].isExist = false;
        }else{
            pledge.pledgeToken = pledge.pledgeToken.sub(_amount);
        }

        _LpToken.transfer(_msgSender(), _amount);

        emit TakePrincipalEvent(_msgSender(), _amount);

        return true;
    }

    function takeProfit(uint256 _amount) public returns (bool) {
        require(_amount > 0, "withdrawal amount must be greater than 0");
        require(_msgSender() == address(tx.origin), "submission address cannot be a contract address");

        PledgerInfo storage pledge = pledgeData[_msgSender()];
        require(pledge.profitToken > 0 , "profit amount must be greater than 0");
        require(_amount <= pledge.profitToken, "withdrawal amount should be less than profit amount");

        pledge.profitToken = pledge.profitToken.sub(_amount);

        uint256 fee1 = _amount.mul(fee_receive_rate1).div(divBaseVal);
        uint256 fee2 = _amount.mul(fee_receive_rate2).div(divBaseVal);
        _IstToken.transfer(fee_receive_addr1, fee1);
        _IstToken.transfer(fee_receive_addr2, fee2);

        uint256 withdraw = _amount.sub(fee1).sub(fee2);
        _IstToken.transfer(_msgSender(), withdraw);

        emit TakeProfitEvent(_msgSender(), _amount);

        return true;
    }

    function _createPledgerInfo(uint256 _amount,uint256 _index) private {
        pledgeData[_msgSender()] = PledgerInfo(true, _amount, 0, 0, _index);
    }

    function _mintIst(uint256 _lpAmount) private returns (uint256){
        require(_lpAmount >= mintLimit, "mint faile: pledge amount is not enough to mint");
        uint256 istAmount;

        if(mintArr.length == 0){
            istAmount = mintBaseVal;
            mintArr.push(MintParams(mintLimit, mintBaseVal, _lpAmount, block.timestamp));
            mintLimit = mintLimit.add(mintLimitAdd);
            mintTotalAmount = mintBaseVal;
        }else{
            MintParams memory mp = mintArr[mintArr.length.sub(1)];
            istAmount = mp.mintIstAmount.add(mintBaseVal);
            if(mintTotalAmount >= decreaseFlag){
                uint256 d = mintTotalAmount.div(decreaseFlag);
                istAmount = istAmount.div(2 ** d);
            }

            mintArr.push(MintParams(mintLimit, istAmount, _lpAmount, block.timestamp));
            mintLimit = mintLimit.add(mintLimitAdd);
            mintTotalAmount = mintTotalAmount.add(istAmount);
        }
        return istAmount;
    }

    function getLiquidityValue(
        address mfactory,
        address tokenA,
        address tokenB,
        uint256 liquidityAmount
    ) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        (uint256 reservesA, uint256 reservesB) = UniswapV2Library.getReserves(mfactory, tokenA, tokenB);
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        bool feeOn = IUniswapV2Factory(factory).feeTo() != address(0);
        uint kLast = feeOn ? pair.kLast() : 0;
        uint totalSupply = pair.totalSupply();
        return computeLiquidityValue(reservesA, reservesB, totalSupply, liquidityAmount, feeOn, kLast);
    }

    function computeLiquidityValue(
        uint256 reservesA,
        uint256 reservesB,
        uint256 totalSupply,
        uint256 liquidityAmount,
        bool feeOn,
        uint kLast
    ) internal pure returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        if (feeOn && kLast > 0) {
            uint rootK = Babylonian.sqrt(reservesA.mul(reservesB));
            uint rootKLast = Babylonian.sqrt(kLast);
            if (rootK > rootKLast) {
                uint numerator1 = totalSupply;
                uint numerator2 = rootK.sub(rootKLast);
                uint denominator = rootK.mul(5).add(rootKLast);
                uint feeLiquidity = FullMath.mulDiv(numerator1, numerator2, denominator);
                totalSupply = totalSupply.add(feeLiquidity);
            }
        }
        return (reservesA.mul(liquidityAmount) / totalSupply, reservesB.mul(liquidityAmount) / totalSupply);
    }

    //******************************************
    function testProfitParams(uint256 i) public onlyOwner returns (uint256 _mintAmount, uint256 _profit) {
        uint256 mintAmount = _mintIst(pledegTotalAmount);
        PledgerInfo memory pledger = pledgeData[keys[i].key];
        uint256 profit = pledger.pledgeToken.div(pledegTotalAmount).mul(mintAmount);
        return (mintAmount, profit);
    }

    function testSetPledegAmount(uint256 _pledgeAmount) public onlyOwner returns (bool) {
        pledegTotalAmount = _pledgeAmount;
        return true;
    }

    function testSetMintAmount(uint256 _mintAmount) public onlyOwner returns (bool) {
        mintTotalAmount = _mintAmount;
        return true;
    }

    function testSetPledgeData(uint256 _pledgeToken) public onlyOwner returns (bool) {
        PledgerInfo storage p = pledgeData[_msgSender()];
        p.pledgeToken = _pledgeToken;
        return true;
    }

    function setMintLimit(uint256 _mintLimit, uint256 _mintLimitAdd, uint256 _mintBaseVal, uint256 _decreaseFlag) public onlyOwner returns (bool) {
        mintLimit = _mintLimit;
        mintLimitAdd = _mintLimitAdd;
        mintBaseVal = _mintBaseVal;
        decreaseFlag = _decreaseFlag;
        return true;
    }

    function setReturnRate(uint256 _returnPrincipalRate) public onlyOwner returns (bool) {
        returnPrincipalRate = _returnPrincipalRate;
        return true;
    }

    function setFeeRateParams(uint256 _rate1, uint256 _rate2) public onlyOwner returns (bool) {
        fee_receive_rate1 = _rate1;
        fee_receive_rate2 = _rate2;
        return true;
    }

    function setFeeAddrParams(address _addr1, address _addr2) public onlyOwner returns (bool) {
        fee_receive_addr1 = _addr1;
        fee_receive_addr2 = _addr2;
        return true;
    }

    function setDivBaseParams(uint256 _value) public onlyOwner returns (bool) {
        divBaseVal = _value;
        return true;
    }

    function setPledgeMinAmount(uint256 _pledgeAmount) public onlyOwner returns (bool) {
        perPledgeMinAmount = _pledgeAmount;
        return true;
    }
    //******************************************

}