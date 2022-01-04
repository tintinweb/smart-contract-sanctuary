/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

/**
*
*  
*
*    
*   
*
*    
*/

pragma solidity ^0.7.6;
// SPDX-License-Identifier: Unlicensed

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

// Contracts and libraries

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

contract CoinslistPhoenix is Ownership, IBEP20 {
    using SafeMath for uint256;

    address DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;
    address ZERO_WALLET = 0x0000000000000000000000000000000000000000;
    address merchantWallet = 0x3E8dd97b2aF74181B2156F5Be1a125A6A5ddF702;

    address pancakeAddress =  0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // TESTNET - https://pancake.kiemtienonline360.com/
    // address pancakeAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //MAINNET

    string constant _name = "Coinslist.xyz";
    string constant _symbol = "CLXYZ";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1000000000000 * 1**18 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply;
    uint256 public _maxWalletAmount = ( _totalSupply * 1 ) / 100;
    uint256 private _maxTxAmountBuy = ( _maxWalletAmount * 1 ) / 2;
    uint256 private _maxTxAmountSell = ( _maxWalletAmount * 1 ) / 8;
    uint256 public _sellcoolDown = 1800;
    uint256 public _stackingSellcoolDown = 3600;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => uint256) _lastSell;
    mapping (address => uint256) _lastSellMultiplyer;

    uint256 liquidityFee    = 8;
    uint256 merchantFee     = 2;
    uint256 public totalFeeIfBuying = 10;
    uint256 public totalFeeIfSelling = 10;
    uint256 feeDenominator  = 100;

    uint256 nofee = 0;

    address public autoLiquidityReceiver;

    PancakeSwapRouter public router;
    address public pair;

    uint256 public launchedAt;
    bool public tradingOpen = true;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 10000;
    uint256 public buyBackThreshold = _totalSupply / 100000000000000;

    bool public inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownership(msg.sender) {
        router = PancakeSwapRouter(pancakeAddress);
        pair = PancakeSwapFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = _totalSupply;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD_WALLET] = true;

        autoLiquidityReceiver = DEAD_WALLET;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external view override returns (uint256) {return _totalSupply;}
    function getOwner() external view override returns (address) {return owner;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD_WALLET)).sub(balanceOf(ZERO_WALLET));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(- 1));
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferTo(msg.sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != uint256(- 1)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

        function _transferTo(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwap) {return _basicTransfer(sender, recipient, amount);}
 
        checkTxLimitTo(recipient, amount);
    
        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = takeFeeTo(sender, recipient, amount);

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }


    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwap) {return _basicTransfer(sender, recipient, amount);}
        
        checkTxLimitFrom(sender, recipient, amount);

        if(shouldSwapBack()){ swapBack(); }

        if(shouldBuyBack()){ buyBack(); }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = takeFeeFrom(sender, amount);

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function shouldBuyBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && address(this).balance >= buyBackThreshold;
    }

     function swapBack() internal swapping() {
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify.mul(liquidityFee).div(totalFeeIfSelling).div(2);
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

        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalFeeIfSelling);
        uint256 amountBNBmerchant = amountBNB.mul(merchantFee).div(totalFeeIfSelling).div(2);

        (bool tmpSuccess,) = payable(merchantWallet).call{value : amountBNBmerchant, gas : 30000}("");
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

    function buyBack() internal swapping() {

        uint256 amountBNBbuyback = address(this).balance;

        approve(address(this), amountBNBbuyback);

        address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(this);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBNBbuyback}(
                0,
                path,
                DEAD_WALLET,
                block.timestamp
            );
    }

   function checkTxLimitTo(address recipient, uint256 amount) internal view {
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

   function checkTxLimitFrom(address sender, address recipient, uint256 amount) internal view {
        if (isTxLimitExempt[sender]) {
            require(amount <= _maxTxAmount);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _totalSupply);
        } else if (!isTxLimitExempt[sender] && recipient == pair || recipient == DEAD_WALLET || recipient == ZERO_WALLET || recipient == address(this)) {
            require(amount <= _maxTxAmountSell);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _totalSupply);
        } else if (!isTxLimitExempt[sender]) {
            require(amount <= _maxTxAmountSell);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount);
        }
    }

    function takeFeeTo(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFeeIfBuying).div(feeDenominator);
        if (isFeeExempt[recipient]) {
            _balances[address(this)] = _balances[address(this)].add(nofee);
            emit Transfer(sender, address(this), nofee);
            return amount.sub(nofee);
        } else
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            return amount.sub(feeAmount);
    }

    function takeFeeFrom(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFeeIfSelling).div(feeDenominator);
        uint256 TwoX = amount.mul(totalFeeIfSelling).div(feeDenominator).mul(2);
        uint256 ThreeX = amount.mul(totalFeeIfSelling).div(feeDenominator).mul(3);
        if (isFeeExempt[sender]) {
            _balances[address(this)] = _balances[address(this)].add(nofee);
            emit Transfer(sender, address(this), nofee);
            return amount.sub(nofee);
        } else if (_lastSellMultiplyer[sender] >= block.timestamp) {
            _lastSellMultiplyer[sender] = block.timestamp + _sellcoolDown + _stackingSellcoolDown;
            _balances[address(this)] = _balances[address(this)].add(ThreeX);
            emit Transfer(sender, address(this), ThreeX);
            return amount.sub(ThreeX);
        } else if (_lastSell[sender] >= block.timestamp) {
            _lastSellMultiplyer[sender] = block.timestamp + _sellcoolDown;
            _balances[address(this)] = _balances[address(this)].add(TwoX);
            emit Transfer(sender, address(this), TwoX);
            return amount.sub(TwoX);
        } else
            _lastSell[sender] = block.timestamp + _sellcoolDown;
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            return amount.sub(feeAmount);
    }

    function modifyWalletLimit(uint256 newLimit) external authorized {
        _maxWalletAmount = newLimit;
    }

    function modifyIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function modifyIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function modifyFees(uint256 newLiqFee, uint256 newmerchantFee) external authorized {
        liquidityFee = newLiqFee;
        merchantFee = newmerchantFee;

        totalFeeIfBuying = liquidityFee.add(merchantFee);
        totalFeeIfSelling = liquidityFee.add(merchantFee);
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}