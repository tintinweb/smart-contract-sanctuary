/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

/*
lets go
*
* https://t.me/comfytokenandraffle
*
*/
pragma solidity 0.8.11;
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

abstract contract Ownership {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "You're not an owner!");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "You're not authorized");
        _;
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

contract Testfor1 is Ownership, IBEP20 {

    uint256 _totalSupply = 1000 * 1**18 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 20;
    uint256 public _walletMax = _maxTxAmount;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address lotteryContract = 0x0000000000000000000000000000000000000000;

    //address pancakeAddress =  0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // TESTNET - https://pancake.kiemtienonline360.com/
    address pancakeAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // MAINNET - https://pancakeswap.finance/

    string constant _name = "Testfor1";
    string constant _symbol = "Testfor1";
    uint8 constant _decimals = 18;

    bool public restrictWhales = true;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    uint256 public liquidityFee = 99;
    uint256 public lotteryFee = 99;

    uint256 public totalFee = 99;
    uint256 private totalFeeIfSelling = 0;

    address public autoLiquidityReceiver;
    address public lotteryFeeReceiver;

    PancakeSwapRouter public router;
    address public pair;

    uint256 public launchedAt;
    bool public tradingOpen = true;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;

    uint256 public swapThreshold = (_totalSupply * 1) / 1000;

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() Ownership(msg.sender) {
        router = PancakeSwapRouter(pancakeAddress);
        pair = PancakeSwapFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = uint256(_totalSupply);

        isFeeExempt[owner] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[ZERO] = true;

        isTxLimitExempt[owner] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        autoLiquidityReceiver = address(this);
        lotteryFeeReceiver = lotteryContract;

        totalFee = liquidityFee + lotteryFee;
        totalFeeIfSelling = totalFee;  }

    receive() external payable {}

    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external view override returns (uint256) {return _totalSupply;}
    function getOwner() external view override returns (address) {return owner;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(_totalSupply));
    }
    function launched() private view returns (bool) {
        return launchedAt != 0;
    }
    function launch() private {
        launchedAt = block.number;
    }
    function checkTxLimit(address sender, address recipient, uint256 amount) private view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || recipient == DEAD || recipient == ZERO, "TX Limit Exceeded");
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    function _basicTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != uint256(_totalSupply)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }
    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        if (inSwapAndLiquify) {return _basicTransfer(sender, recipient, amount);}
        checkTxLimit(sender, recipient, amount);
        if (msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold) {lotteryAndLiquidity();}
        if (!launched() && recipient == pair) {
            require(_balances[sender] > 0, "Zero balance violated!");
            launch();
        }
        _balances[sender] = _balances[sender] - amount;
        if (!isTxLimitExempt[recipient] && restrictWhales) {
            require((_balances[recipient] + amount) <= _walletMax, "Max wallet violated!");
        }
        uint256 finalAmount = extractFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient] + finalAmount;
        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function extractFee(address sender, address recipient, uint256 amount) private returns (uint256) {
        uint256 feeAmount = (amount * totalFee) / 100;
        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            uint256 zeroFee = 0;
            _balances[address(this)] = _balances[address(this)] + zeroFee;
            emit Transfer(sender, address(this), zeroFee);
            return amount - zeroFee;
        } else
            _balances[address(this)] = _balances[address(this)] + feeAmount;
            emit Transfer(sender, address(this), feeAmount);
            return amount - feeAmount;
    }

    function lotteryAndLiquidity() private lockTheSwap() {
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = (tokensToLiquify * liquidityFee) / totalFee;
        uint256 amountToSwap = tokensToLiquify - amountToLiquify;
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
        uint256 amountBNBLiquidity = (amountBNB * liquidityFee) / totalFee;
        uint256 amountBNBLottery = amountBNB - amountBNBLiquidity;
        (bool tmpSuccess,) = payable(lotteryFeeReceiver).call{value : amountBNBLottery, gas : 30000}("");
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
    function modifyIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
    function modifyIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
    function modifyFees(uint256 newLiqFee, uint256 newlotteryFee) external onlyOwner {
        liquidityFee = newLiqFee;
        lotteryFee = newlotteryFee;
        totalFee = liquidityFee + lotteryFee;
        totalFeeIfSelling = totalFee;
    }
    function modifyFeeReceivers(address newLiquidityReceiver, address newlotteryContract) external onlyOwner {
        autoLiquidityReceiver = newLiquidityReceiver;
        lotteryFeeReceiver = newlotteryContract;
    }
    function modifySwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit, bool swapByLimitOnly) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
        swapAndLiquifyByLimitOnly = swapByLimitOnly;
    }
    function withdrawTokens(address _tokenContract) external onlyOwner {
        IBEP20 tokenContract = IBEP20(_tokenContract);
        uint256 withdrawBalance = tokenContract.balanceOf(address(this));
        approve(address(this), withdrawBalance);
        tokenContract.transfer(owner, withdrawBalance);
    }
    function clearStuckBalance() external onlyOwner {
        uint256 amountBNB = address(this).balance;
        approve(address(this), amountBNB);
        payable(owner).transfer(amountBNB);
    }
}