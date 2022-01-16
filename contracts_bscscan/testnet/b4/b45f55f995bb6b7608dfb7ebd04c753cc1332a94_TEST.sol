/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

/*
*/
pragma solidity ^0.8.11;
// SPDX-License-Identifier: MIT
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
abstract contract Ownable {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface PancakeSwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface PancakeSwapRouter {
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
        if (a == 0) {return 0;}
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
abstract contract tokenInterface {
    function balanceOf(address whom) view public virtual returns (uint);
}
contract TEST is IBEP20, Ownable {
    using SafeMath for uint256;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address devWallet = 0x09355546108A319E04E020b39cb8F3Ccf33f25D1;
    address tokenAddress = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // TESTNET - BUSD - https://testnet.bscscan.com/address/0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7#code
    //address tokenAddress = 0x2859e4544C4bB03966803b044A93563Bd2D0DD4D; // MAINNET - SHIB - https://bscscan.com/address/0x2859e4544c4bb03966803b044a93563bd2d0dd4d#code
    address pancakeAddress =  0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // TESTNET - https://pancake.kiemtienonline360.com/
    //address pancakeAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // MAINNET - https://pancakeswap.finance/
    string constant _name = "testnet";
    string constant _symbol = "test";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 1000000 * 1**18 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply;
    uint256 public _maxWalletAmount = _totalSupply * 3 / 100;
    uint256 public _maxTxAmountBuy = _maxWalletAmount / 2; 
    uint256 public _maxTxAmountSell = _maxWalletAmount / 2;
    uint256 public _lotteryTicketThreshold = _totalSupply / 100;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    uint256 public liquidityFee = 8;
    uint256 public devBurnReflectionFee = 2;
    uint256 private zeroFee = 0;
    address public autoLiquidityReceiver;
    address public devFeeReceiver;
    address[] public players;
    PancakeSwapRouter public router;
    address public pair;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000;
    uint256 public lotteryThreshold = _totalSupply / 100000000;
    bool public inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    modifier restricted() {
    require(msg.sender == owner());
    _;
    }
    constructor() {
        router = PancakeSwapRouter(pancakeAddress);
        pair = PancakeSwapFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[pair] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[ZERO] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;
        autoLiquidityReceiver = address(this);
        devFeeReceiver = devWallet;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    receive() external payable {}
    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external view override returns (uint256) {return _totalSupply;}
    function getOwner() external view override returns (address) {return owner();}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}
    function tokenBalance(address _addressToQuery) view public returns (uint256) {
        return tokenInterface(tokenAddress).balanceOf(_addressToQuery);
    }
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferTo(msg.sender, recipient, amount);
    }
    function _basicTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }
    function _transferTo(address sender, address recipient, uint256 amount) private returns (bool) {
        if (inSwap) {return _basicTransfer(sender, recipient, amount);}
        checkTxLimitTo(recipient, amount);
        if(shouldSwapBack()){ swapBack(); }
        //if(doLottery()){ pickWinner(); }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = takeFeeTo(sender, recipient, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!isFeeExempt[recipient]){ enterLotteryTicket(recipient, amountReceived); }
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        if (inSwap) {return _basicTransfer(sender, recipient, amount);}
        checkTxLimitFrom(sender, recipient, amount);
        if(shouldSwapBack()){ swapBack(); }
        //if(doLottery()){ pickWinner(); }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = takeFeeFrom(sender, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);
        //if(!isFeeExempt[sender]){ removeLotteryTicket(sender); }
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    function shouldSwapBack() private view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    function doLottery() private view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && address(this).balance >= lotteryThreshold;
    }
    function swapBack() private swapping() {
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify.mul(8).div(10);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);
        approve(address(this), amountToSwap);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance;
        uint256 amountBNBLiquidity = amountBNB.mul(8).div(10); // 80%
        // 20% REMAINING
        uint256 amountBNBdev = amountBNB.mul(5).div(10000); // 12.5%
        (bool tmpSuccess,) = payable(devFeeReceiver).call{value : amountBNBdev, gas : 30000}("");
        tmpSuccess = false;
        if (amountToLiquify > 0) {
            router.addLiquidityETH{value : amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }
    function checkTxLimitTo(address recipient, uint256 amount) private view {
        if (isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmount);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _totalSupply);
        } else if (!isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmountBuy);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount);
        }
    }
    function checkTxLimitFrom(address sender, address recipient, uint256 amount) private view {
        if (isTxLimitExempt[sender]) {
            require(amount <= _maxTxAmount);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _totalSupply);
        } else if (!isTxLimitExempt[sender] && isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmountSell);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _totalSupply);
        } else if (!isTxLimitExempt[sender]) {
            require(amount <= _maxTxAmountSell);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount);
        }
    }
    function takeFeeTo(address sender, address recipient, uint256 amount) private returns (uint256) {
        uint256 fivePercent = amount.mul(10).div(100).div(2);
        uint256 tenPercent = amount.mul(10).div(100);
        if (isFeeExempt[recipient]) {
            _balances[address(this)] = _balances[address(this)].add(zeroFee);
            emit Transfer(sender, address(this), zeroFee);
            return amount.sub(zeroFee);
        } else if (tokenBalance(recipient) > 0) {
            _balances[address(this)] = _balances[address(this)].add(fivePercent);
            emit Transfer(sender, address(this), fivePercent);
            return amount.sub(fivePercent);
        } else
            _balances[address(this)] = _balances[address(this)].add(tenPercent);
            emit Transfer(sender, address(this), tenPercent);
            return amount.sub(tenPercent);
    }
    function takeFeeFrom(address sender, uint256 amount) private returns (uint256) {
        uint256 twoPointFivePercent = amount.mul(10).div(100).div(4);
        uint256 tenPercent = amount.mul(10).div(100);
        if (isFeeExempt[sender]) {
            _balances[address(this)] = _balances[address(this)].add(zeroFee);
            emit Transfer(sender, address(this), zeroFee);
            return amount.sub(zeroFee);
        } else if (tokenBalance(sender) > 0) {
            _balances[address(this)] = _balances[address(this)].add(twoPointFivePercent);
            emit Transfer(sender, address(this), twoPointFivePercent);
            return amount.sub(twoPointFivePercent);
        } else
            _balances[address(this)] = _balances[address(this)].add(tenPercent);
            emit Transfer(sender, address(this), tenPercent);
            return amount.sub(tenPercent);
    }
    function enterLotteryTicket(address recipient, uint256 amount) private {
        if (amount >= _lotteryTicketThreshold) {
            players.push(recipient);
        }
    }
    function removeLotteryTicket(address sender) private {
        uint256 i = uint256(uint160(sender));
        players[i] = players[players.length - 1];
        players.pop();
    }
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    // function pickWinner() private swapping() {
    function pickWinner() public restricted() {
        uint index = random() % players.length;
        approve(address(this), address(this).balance);
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);       
    }
    function getPlayers() public view returns (address[] memory) {
        return players;
    }
    function withdrawTokens(address _tokenContract) external onlyOwner {
        IBEP20 tokenContract = IBEP20(_tokenContract);
        uint256 withdrawBalance = tokenContract.balanceOf(address(this));
        approve(address(this), withdrawBalance);
        tokenContract.transfer(owner(), withdrawBalance);
    }
    function clearStuckBalance() external onlyOwner {
        uint256 amountBNB = address(this).balance;
        approve(address(this), amountBNB);
        payable(owner()).transfer(amountBNB);
    }
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}