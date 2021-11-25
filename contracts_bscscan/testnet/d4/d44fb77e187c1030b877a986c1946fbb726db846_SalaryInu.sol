/**
 *Submitted for verification at BscScan.com on 2021-11-25
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

contract SalaryInu is IBEP20, Auth {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    address WBNB;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "STest";
    string constant _symbol = "ST";
    uint8 constant _decimals = 4;

    mapping (address => uint256) _gonBalances;
    mapping (address => mapping (address => uint256)) _allowances;

    uint256 public liquidityFee = 500;
    uint256 public marketingFee = 300;
    uint256 public totalFee = liquidityFee.add(marketingFee);
    uint256 public feeDenominator = 10000;

    address public marketingAddress;

    IDEXRouter public router;
    address public pair;
    InterfaceLP public pairContract; 

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    address public master;
    modifier onlyMaster() {
        require(msg.sender == master || isOwner(msg.sender));
        _;
    }

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    uint256 public rebase_count = 0;
    uint256 public _totalSupply;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**10 * 10**_decimals;
    uint256 private swapThreshold;
    uint256 private _gonsPerFragment;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private constant MAX_REBASE_LIMIT = 900;
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    function rebase(int256 supplyDelta)
        external
        onlyMaster
        returns (uint256)
    {
        require(!inSwap, "Try again");
        require(rebase_count < MAX_REBASE_LIMIT, "Out of the rebase max limit");

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

        swapThreshold = _gonsPerFragment.mul(1000 * 10**_decimals);

        emit LogRebase(rebase_count, _totalSupply);
        return _totalSupply;
    }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // mainnet : 0x10ED43C718714eb63d5aA57B78B54704E256024E, testnet : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        WBNB = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);        
        pairContract = InterfaceLP(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        swapThreshold = _gonsPerFragment.mul(1000 * 10**_decimals);

        marketingAddress = 0x5C3610F8e45542249534D26a0273258b2c95d1e8;

        _gonBalances[msg.sender] = TOTAL_GONS;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }
    
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function maxRebaseLimit() external pure returns (uint256) {return MAX_REBASE_LIMIT;}

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
        
        if(shouldSwapBack(sender)){ swapBack(); }

        //Exchange tokens
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, gonAmount) : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived.div(_gonsPerFragment));
        return true;
    }

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

    function shouldSwapBack(address sender) internal view returns (bool) {
        return sender != pair 
            && !inSwap 
            && _gonBalances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance_sender(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = _gonBalances[address(this)].div(_gonsPerFragment);

        // send to marketing address
        uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFee);
        _basicTransfer(address(this), marketingAddress, marketingTokens);
        
        // add liquidity
        uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFee);
        swapAndLiquify(swapTokens);

        _gonBalances[address(this)] = 0;
    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }


    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        approve(address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        approve(address(router), tokenAmount);

        // add the liquidity
        (,,uint256 liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
        require(liquidity > 0);
    }

    function setFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _feeDenominator) external authorized {
        marketingFee = _marketingFee;
        liquidityFee = _liquidityFee;
        totalFee = marketingFee.add(liquidityFee);
        feeDenominator = _feeDenominator;
    }

    function setMarketingAddress(address _marketingAddress) external authorized {
        marketingAddress = _marketingAddress;
    }

    function setSwapBackAmount(uint256 tokenAmount) external authorized {
        swapThreshold = tokenAmount.mul(_gonsPerFragment);
    }

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

    function isValidRebase() public view returns (bool) {
        return (rebase_count < MAX_REBASE_LIMIT);
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