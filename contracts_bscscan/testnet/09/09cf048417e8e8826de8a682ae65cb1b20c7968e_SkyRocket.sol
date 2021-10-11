/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: unlicensed

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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface InterfaceLP {
    function sync() external;
}

interface IDEXRouter {
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

contract SkyRocket is IBEP20, Auth {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "STest";
    string constant _symbol = "DTEST";
    uint8 constant _decimals = 9;

    //mapping (address => uint256) _balances;
    mapping (address => uint256) _gonBalances;
    mapping (address => mapping (address => uint256)) _allowances;

    uint256 public taxFee1 = 470;
    uint256 public taxFee2 = 340;
    uint256 public taxFee3 = 180;
    uint256 public totalFee = taxFee1.add(taxFee2).add(taxFee3);
    uint256 public feeDenominator = 10000;

    address public taxFeeReceiver1;
    address public taxFeeReceiver2;
    address public taxFeeReceiver3;

    // uint256 targetLiquidity = 20;
    // uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;
    InterfaceLP public pairContract; 

    bool public tradingOpen = false;

    uint8 public cooldownTimerInterval = 5;
    mapping (address => uint) private cooldownTimer;

    bool public swapEnabled = false;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    address public master;
    modifier onlyMaster() {
        require(msg.sender == master || isOwner(msg.sender));
        _;
    }

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event CaliforniaCheckin(address guest, uint256 rentPaid);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**16 * 10**_decimals;
    uint256 public swapThreshold = TOTAL_GONS * 10 / 100000000000;
    uint256 public rebase_count = 0;
    uint256 public _gonsPerFragment;
    uint256 public _totalSupply;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private constant MAX_REBASE_LIMIT = 288;
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // Sauce
    function rebase(uint256 epoch, int256 supplyDelta) public onlyMaster returns (uint256) {
        require(!inSwap, "Try again");
        require(epoch < MAX_REBASE_LIMIT, "Out of the rebase max limit");
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        _totalSupply = _totalSupply.sub(uint256(supplyDelta));

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        
        pairContract = InterfaceLP(pair);
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        taxFeeReceiver1 = 0xcFE445EEC95d66874759A90afFAfA73978BfbF98;
        taxFeeReceiver2 = 0x10bbf08610359bE4c6A3498938d7889dD354c771;
        taxFeeReceiver3 = 0x3fF0251166506691fAe0AEDCa46a7b2118321cd4;

        _gonBalances[msg.sender] = TOTAL_GONS;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    
    
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function getContractGonAmount() external view returns (uint256) {return _gonBalances[address(this)]; }

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
        
        // if(shouldSwapBack()){ swapBack(); }
        if(shouldFeeBack()){ feeBack(); }

        //Exchange tokens
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount, "Insufficient Balance");

        // uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, gonAmount) : gonAmount;
        uint256 amountReceived = takeFee(sender, gonAmount);
        _gonBalances[recipient] = _gonBalances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived.div(_gonsPerFragment));
        return true;
    }
    
    // Changed
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount, "Insufficient Balance");
        _gonBalances[recipient] = _gonBalances[recipient].add(gonAmount);
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
  
    // function shouldSwapBack() internal view returns (bool) {
    //     return msg.sender != pair
    //     && !inSwap
    //     && swapEnabled
    //     && _gonBalances[address(this)] >= swapThreshold;
    // }

    function shouldFeeBack() internal view returns (bool) {
        return !inSwap && _gonBalances[address(this)] >= swapThreshold;
    }

    // function clearStuckBalance(uint256 amountPercentage) external authorized {
    //     uint256 amountBNB = address(this).balance;
    //     payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    // }
    
    function clearStuckBalance_sender(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
    }

    // OK, check 3
    // function swapBack() internal swapping {
    //     uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
    //     uint256 tokensToSell = swapThreshold.div(_gonsPerFragment);

    //     uint256 amountToLiquify = tokensToSell.div(totalFee).mul(dynamicLiquidityFee).div(2);
    //     uint256 amountToSwap = tokensToSell.sub(amountToLiquify);

    //     address[] memory path = new address[](2);
    //     path[0] = address(this);
    //     path[1] = WBNB;

    //     uint256 balanceBefore = address(this).balance;

    //     router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //         amountToSwap,
    //         0,
    //         path,
    //         address(this),
    //         block.timestamp
    //     );

    //     uint256 amountBNB = address(this).balance.sub(balanceBefore);

    //     uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
    //     uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
    //     uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
    //     uint256 amountBNBDev = amountBNB.mul(devFee).div(totalBNBFee);

    //     (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
    //     (tmpSuccess,) = payable(devFeeReceiver).call{value: amountBNBDev, gas: 30000}("");
        
    //     // only to supress warning msg
    //     tmpSuccess = false;

    //     if(amountToLiquify > 0){
    //         router.addLiquidityETH{value: amountBNBLiquidity}(
    //             address(this),
    //             amountToLiquify,
    //             0,
    //             0,
    //             autoLiquidityReceiver,
    //             block.timestamp
    //         );
    //         emit AutoLiquify(amountBNBLiquidity, amountToLiquify.div(_gonsPerFragment));
    //     }
    // }

    function feeBack() internal swapping {
        uint256 gonAmount = _gonBalances[address(this)];

        uint256 amountToReceiver1 = gonAmount.mul(taxFee1).div(totalFee);
        _gonBalances[address(this)] = _gonBalances[address(this)].sub( amountToReceiver1 );
        _gonBalances[taxFeeReceiver1] = _gonBalances[taxFeeReceiver1].add( amountToReceiver1);
        emit Transfer(address(this), taxFeeReceiver1, amountToReceiver1.div(_gonsPerFragment));

        uint256 amountToReceiver2 = gonAmount.mul(taxFee2).div(totalFee);
        _gonBalances[address(this)] = _gonBalances[address(this)].sub( amountToReceiver2 );
        _gonBalances[taxFeeReceiver2] = _gonBalances[taxFeeReceiver2].add( amountToReceiver2);
        emit Transfer(address(this), taxFeeReceiver2, amountToReceiver2.div(_gonsPerFragment));

        uint256 amountToReceiver3 = gonAmount.mul(taxFee3).div(totalFee);
        _gonBalances[address(this)] = _gonBalances[address(this)].sub( amountToReceiver3 );
        _gonBalances[taxFeeReceiver3] = _gonBalances[taxFeeReceiver3].add( amountToReceiver3);
        emit Transfer(address(this), taxFeeReceiver3, amountToReceiver3.div(_gonsPerFragment));
    }
    
    function setFees(
        uint256 _taxFee1,
        uint256 _taxFee2,
        uint256 _taxFee3,
        uint256 _feeDenominator
    ) external authorized {
        taxFee1 = _taxFee1;
        taxFee2 = _taxFee2;
        taxFee3 = _taxFee3;
        totalFee = taxFee1.add(taxFee2).add(taxFee3);
        feeDenominator = _feeDenominator;
    }

    function setFeeReceivers(
        address _taxFeeReceiver1,
        address _taxFeeReceiver2,
        address _taxFeeReceiver3
    ) external authorized {
        taxFeeReceiver1 = _taxFeeReceiver1;
        taxFeeReceiver2 = _taxFeeReceiver2;
        taxFeeReceiver3 = _taxFeeReceiver3;
    }

    function setSwapBackSettings(bool _enabled, uint256 _percentage_base1000) external authorized {
        swapEnabled = _enabled;
        swapThreshold = TOTAL_GONS.div(1000).mul(_percentage_base1000);
    }

    // function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
    //     targetLiquidity = _target;
    //     targetLiquidityDenominator = _denominator;
    // }

    function manualSync() external {
        InterfaceLP(pair).sync();
    }
    
    function setLP(address _address) external onlyOwner {
        pairContract = InterfaceLP(_address);
    }
    
    function setMaster(address _master) external onlyOwner {
        master = _master;
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function checkSwapThreshold() external view returns (uint256) {
        return swapThreshold.div(_gonsPerFragment);
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

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}