/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

 /*
                                         __       ____     ______  ___      __   _______
                                        |◘◘|     /◘◘◘◘    |◘◘◘◘◘◘| \◘◘\    /◘◘/ |◘◘ ◘◘◘◘  |◘◘◘◘◘\  (◘◘◘◘◘
/*Devlopped By Med BOUHOUCH             |◘◘|    |◘|  \◘|  |◘◘| |◘   \◘◘\  /◘◘/  |◘◘|___   |◘◘  ◘◘  ◘◘
*https://www.fiverr.com/medbouhouch     |◘◘|    |◘|◘◘◘◘|  |◘◘◘◘◘/    \◘◘◘◘◘/    |◘◘◘◘◘◘|  |◘◘◘◘◘◘  ◘◘◘◘◘◘
*watsapp : +212772975925                |◘◘|__  |◘|  |◘|  |◘◘|         \◘◘/     |◘◘|____  |◘◘  ◘◘      ◘◘
                                        |◘◘◘◘◘| |◘|  |◘|  |◘◘|          \/      |◘◘◘◘◘◘◘  |◘◘  ◘◘  ◘◘◘◘◘)
                                         
                        
                        
      LAPVERSE                  
                                       

*/


//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
        uint DEADline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint DEADline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint DEADline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint DEADline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint DEADline
    ) external;
}

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
    function claimDividend(address shareholder) external;
}

contract BNBDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;
    address marketingReceiver = 0xbB420DD611299b848398f13F393E122B5ec37c16; // Merketing Wallet
    address devReceiver = 0x84e010A4F6bff174B3a152f0114465d0C5C4956F;       //DEV WALLET
    address liquidityReceiver=0xB651E691335543F7B237F1F366e128de9471caA1;   //Main Wallet

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address WBNB;
    IDEXRouter router;

    mapping(address => uint256) _shareAmount;
    mapping(address => uint256) _shareEntry;
    mapping(address => uint256) _accured;
    uint256 _totalShared;
    uint256 _totalAIRDROP;
    uint256 _totalAccured;
    uint256 _stakingMagnitude;

    uint256 public minAmount = 0;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _wbnb, address _router, address _marketingReceiver, address _devReceiver, address _liquidityReceiver) {
        WBNB = _wbnb;
        router = IDEXRouter(_router);
        _token = msg.sender;
        marketingReceiver = _marketingReceiver;
        devReceiver = _devReceiver;
        liquidityReceiver = _liquidityReceiver;

        _stakingMagnitude = 10 * 10 ** (9 + 9); // 10 Billion
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        // Shareholder has given up their AIRDROP Share
        if (amount < 1000000000) {
            uint256 current_AIRDROPs = currentAIRDROPs(shareholder);
            if (current_AIRDROPs > 0) {
                distributeDividend(shareholder, marketingReceiver);
            }

            _accured[shareholder] = _accured[shareholder] - _accured[shareholder];
            _totalShared = _totalShared - _shareAmount[shareholder];

            _shareAmount[shareholder] = _shareAmount[shareholder] - _shareAmount[shareholder];
            _shareEntry[shareholder] = _totalAccured;
        } else {
            if (_shareAmount[shareholder] > 0) {
                _accured[shareholder] = currentAIRDROPs(shareholder);
            }

            _totalShared = _totalShared.sub(_shareAmount[shareholder]).add(amount);
            _shareAmount[shareholder] = amount;

            _shareEntry[shareholder] = _totalAccured;
        }
    }

    function getWalletShare(address shareholder) public view returns (uint256) {
        return _shareAmount[shareholder];
    }

    function deposit(uint256 amount) external override onlyToken {
        _totalAIRDROP = _totalAIRDROP + amount;
        _totalAccured = _totalAccured + amount * _stakingMagnitude / _totalShared;
    }

    function distributeDividend(address shareholder, address receiver) internal {
        if(_shareAmount[shareholder] == 0){ return; }

        _accured[shareholder] = currentAIRDROPs(shareholder);
        require(_accured[shareholder] > minAmount, "AIRDROP amount has to be more than minimum amount");

        payable(receiver).transfer(_accured[shareholder]);
        _totalAIRDROP = _totalAIRDROP - _accured[shareholder];
        _accured[shareholder] = _accured[shareholder] - _accured[shareholder];

        _shareEntry[shareholder] = _totalAccured;
    }

    function claimDividend(address shareholder) external override onlyToken {
        uint256 amount = currentAIRDROPs(shareholder);
        if (amount == 0) {
            return;
        }

        distributeDividend(shareholder, shareholder);
    }

    

    function setMarketingFeeReceiver(address _receiver) external onlyToken {
        marketingReceiver = _receiver;
    }
    function setDevFeeReceiver(address _receiver) external onlyToken {
        devReceiver = _receiver;
    }

    function settaxPoolReceiver(address _receiver) external onlyToken {
        liquidityReceiver = _receiver;
    }

    

    function buyToken(address shareholder) external onlyToken {
        if(_shareAmount[shareholder] == 0){ return; }

        uint256 amount = currentAIRDROPs(shareholder);

        if (amount == 0) { return; }

        _accured[shareholder] = amount;

        uint256 amountToburn = amount.mul(1).div(100);
        uint256 amountToLiquify = amount.mul(3).div(100).div(2);
        uint256 walletAmount = amount.mul(96).div(100);

        uint256 amountToSwap = amountToLiquify.add(walletAmount);

        // Pay charity fee
        payable(0x000000000000000000000000000000000000dEaD).transfer(amountToburn); // burn

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = _token;

        uint256 balanceBefore = IBEP20(_token).balanceOf(address(this));

        IBEP20(_token).approve(address(router), amountToSwap);
        // Buy more tokens with the BNB of the shareholder and send to them
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountToSwap}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 swapBalance = IBEP20(_token).balanceOf(address(this)).sub(balanceBefore);
        uint256 amountTokensToLiquify = swapBalance.mul(3).div(98);
        uint256 amountTokensToShareholder = swapBalance.sub(amountTokensToLiquify);

        if (amountTokensToShareholder > 0) {
            IBEP20(_token).transfer(shareholder, amountTokensToShareholder);
        }

        if (amountTokensToLiquify > 0 && amountToLiquify > 0){
            IBEP20(_token).approve(address(router), amountTokensToLiquify);
            router.addLiquidityETH{ value: amountToLiquify }(
                _token,
                amountTokensToLiquify,
                0,
                0,
                liquidityReceiver,
                block.timestamp
            );
        }

        _totalAIRDROP = _totalAIRDROP - _accured[shareholder];
        _accured[shareholder] = _accured[shareholder] - _accured[shareholder];

        _shareEntry[shareholder] = _totalAccured;
    }

    function depositExternalBNB(uint256 amount) external onlyToken {
        _totalAIRDROP = _totalAIRDROP + amount;
        _totalAccured = _totalAccured + amount * _stakingMagnitude / _totalShared;
    }

    function _calculateAIRDROP(address addy) private view returns (uint256) {
        return _shareAmount[addy] * (_totalAccured - _shareEntry[addy]) / _stakingMagnitude;
    }

    function currentAIRDROPs(address addy) public view returns (uint256) {
        uint256 totalAIRDROPs = address(this).balance;

        uint256 calcAIRDROP = _accured[addy] + _calculateAIRDROP(addy);

        // Fail safe to ensure AIRDROPs are never more than the contract holding.
        if (calcAIRDROP > totalAIRDROPs) {
            return totalAIRDROPs;
        }

        return calcAIRDROP;
    }

    receive() external payable { }
}

contract Lapverse is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    address WBNB = 0xB651E691335543F7B237F1F366e128de9471caA1;//Main Wallet ◘◘ bnb ◘◘
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "LapVerse";
    string constant _symbol = "LVERSE";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 200 * 10 ** (6 + _decimals); // 200 million

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isRestricted;


    uint256 taxPool = 5 * 100;
    uint256 burnFee = 20 * 100;
    uint256 marketingFee = 3 * 100;
    uint256 devFee = 10 * 100;
    
    
    
    uint256 AIRDROP = 2.5 * 100;
    uint256 LIQUIDITY = 25 * 100;
     uint256 TEAM = 5 * 100;
    uint256 STAKING = 5.5 * 100;
    
    uint256 INFLUENCER = 2 * 100;
    uint256 TREASURY = 12 * 100;
    uint256 BOUNTIES = 5 * 100;
    uint256 TAXBUYBACK = 5 * 100;

    uint256 feeDenominator = 10000;
    address public marketingFeeReceiver;
    address public devFeeReceiver;
    address public autoLiquidityReceiver;

    IDEXRouter public router;
    address pancakeV2BNBPair;
    address[] public pairs;

    bool public swapEnabled = true;
    bool public feesOnNormalTransfers = true;

    BNBDistributor public bnbDistributor;

    bool inSwap;
    modifier swapping { inSwap = true; _; inSwap = false; }
    uint256 public swapThreshold = 100 * 10 ** _decimals;

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
    event BoughtBack(uint256 amount, address to);
    event Launched(uint256 blockNumber, uint256 timestamp);
    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);

    constructor() {
        address _owner = msg.sender;
        

        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakeV2BNBPair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        pairs.push(pancakeV2BNBPair);
        bnbDistributor = new BNBDistributor(WBNB, address(router), _owner, _owner , _owner);

        isFeeExempt[_owner] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(bnbDistributor)] = true;
        isDividendExempt[pancakeV2BNBPair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        isDividendExempt[address(bnbDistributor)] = true;
        isDividendExempt[_owner] = true;

        address upgradeContract = 0x5Ba41eAE2AE8a103B19ffE23384310B065bAF7f3;
        isFeeExempt[upgradeContract] = true;
        isDividendExempt[upgradeContract] = true;

        
        
        autoLiquidityReceiver = 0xB651E691335543F7B237F1F366e128de9471caA1;// Main Wallet

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "MetaBull: approve from the zero address");
        require(spender != address(0), "MetaBull: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    ///////////////////////////////////////////////
    function multiSend(address sender, address[] memory recipient, uint256[] memory amount) public {
        
        address from = msg.sender;
        
        require(recipient.length > 0);
        require(amount.length > 0);
        uint256 allAmount =0 ;
        for (uint256 i = 0; i < recipient.length; i++) {
            allAmount = allAmount + amount[i];
        }
        if(_allowances[sender][msg.sender] != ~uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(allAmount, "Insufficient Allowance");
        }
        
        for (uint256 i = 0; i < recipient.length; i++) {_transferFrom(from, recipient[i], amount[i]);
        
        }
        
    }  
    

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != ~uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!isRestricted[recipient], "Address is restricted");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(shouldSwapBack()) { swapBack(); }

        require(_balances[sender].sub(amount) >= 0, "Insufficient Balance");
        _balances[sender] = _balances[sender].sub(amount);

        if (shouldTakeFee(sender, recipient)) {
            uint256 _marketingFee = amount.mul(marketingFee).div(feeDenominator);
            uint256 _devFee = amount.mul(devFee).div(feeDenominator);
            uint256 _burnFee = amount.mul(burnFee).div(feeDenominator);
            uint256 _bnbFee = amount.mul(AIRDROP).div(feeDenominator);
            uint256 _taxPool = amount.mul(taxPool).div(feeDenominator);

            uint256 _totalFee = _marketingFee + _devFee + _burnFee + _bnbFee + _taxPool; // Total token fee

            _balances[address(this)] = _balances[address(this)] + _totalFee; // New Balance

            uint256 amountReceived = amount - _totalFee;
            _balances[recipient] = _balances[recipient].add(amountReceived);
            emit Transfer(sender, recipient, amountReceived);

        } else {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }

        if (!isDividendExempt[sender]) {
            try bnbDistributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try bnbDistributor.setShare(recipient, _balances[recipient]) {} catch {}
        }

        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(balanceOf(sender).sub(amount) >= 0, "Insufficient Balance");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient]) return false;

        address[] memory liqPairs = pairs;

        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }

        return feesOnNormalTransfers;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pancakeV2BNBPair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapAndLiquidify() external onlyOwner {
        swapBack();
    }

    function swapBack() internal swapping {
        uint256 balanceBefore = address(this).balance;

        uint256 totalAmount = _balances[address(this)];
        uint256 denom = taxPool + burnFee + marketingFee + devFee + AIRDROP;

        uint256 marketingSwap = totalAmount.mul(marketingFee).div(denom);
        uint256 devSwap = totalAmount.mul(devFee).div(denom);
        uint256 bnbSwap = totalAmount.mul(AIRDROP).div(denom);
        uint256 liquiditySwap = totalAmount.mul(taxPool).div(denom);

        uint256 amountToLiquify = liquiditySwap.div(2);

        uint256 amountToSwap = marketingSwap + devSwap  + bnbSwap + amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToSwap);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 swapedBNBAmount = address(this).balance.sub(balanceBefore);

        if (swapedBNBAmount > 0) {
            uint256 bnbDenom = taxPool.div(2) + burnFee + marketingFee + devFee + AIRDROP;
            uint256 bnbSwapMarketingAmount = swapedBNBAmount.mul(marketingFee).div(bnbDenom); // BNB for Marketing
            uint256 bnbSwapDevAmount = swapedBNBAmount.mul(devFee).div(bnbDenom); // BNB for Marketing
            uint256 bnbSwapCharityAmount = swapedBNBAmount.mul(burnFee).div(bnbDenom); // BNB for Charity
            uint256 bnbSwapBnbAmount = swapedBNBAmount.mul(AIRDROP).div(bnbDenom); // BNB for BNB AIRDROPs
            uint256 bnbLiquidify = swapedBNBAmount.mul(taxPool.div(2)).div(bnbDenom); // BNB for Liqudity

            if (bnbSwapMarketingAmount > 0) {
                // Send BNB for Marketing
                payable(marketingFeeReceiver).transfer(bnbSwapMarketingAmount);
            }
            if (bnbSwapDevAmount > 0) {
                // Send BNB for Marketing
                payable(devFeeReceiver).transfer(bnbSwapDevAmount);
            }


            if (bnbSwapCharityAmount > 0) {
                // Send BNB for Charity
                payable(DEAD).transfer(bnbSwapCharityAmount);
            }

            if (bnbSwapBnbAmount > 0) {
                // Send BNB for AIRDROPs
                payable(bnbDistributor).transfer(bnbSwapBnbAmount);
                bnbDistributor.depositExternalBNB(bnbSwapBnbAmount);
            }

            if (bnbLiquidify > 0){
                _approve(address(this), address(router), amountToLiquify);
                router.addLiquidityETH{ value: bnbLiquidify }(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                );
            }
        }
    }

    function BNBbalance() external view returns (uint256) {
        return address(this).balance;
    }

    function BNBAIRDROPbalance() external view returns (uint256) {
        return address(bnbDistributor).balance;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pancakeV2BNBPair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            bnbDistributor.setShare(holder, 0);
        } else{
            bnbDistributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
    /*

    
    
    
    

    */
    function setOther(
        uint256 _AIRDROP,
        uint256 _LIQUIDITY,
        uint256 _TEAM,
        uint256 _STAKING,
        uint256 _INFLUENCER,
        uint256 _TREASURY,
        uint256 _BOUNTIES,
        uint256 _TAXBUYBACK
    ) external onlyOwner {
        AIRDROP = _AIRDROP;
        LIQUIDITY = _LIQUIDITY;
        TEAM = _TEAM;
        STAKING = _STAKING;
        INFLUENCER = _INFLUENCER;
        TREASURY = _TREASURY;
        BOUNTIES = _BOUNTIES;
        TAXBUYBACK = _TAXBUYBACK;
    }

    function setFees(
        uint256 _taxPool,
        uint256 _burnFee,
        uint256 _marketingFee,
        uint256 _devFee
    ) external onlyOwner {
        taxPool = _taxPool;
        burnFee = _burnFee;
        marketingFee = _marketingFee;
        devFee = _devFee;
    }

    function setSwapThreshold(uint256 threshold) external onlyOwner {
        swapThreshold = threshold;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    

    function setMarketingFeeReceiver(address _receiver) external onlyOwner {
        marketingFeeReceiver = _receiver;
        bnbDistributor.setMarketingFeeReceiver(_receiver);

        isDividendExempt[_receiver] = true;
        isFeeExempt[_receiver] = true;
    }
    function setDevFeeReceiver(address _receiver) external onlyOwner {
        devFeeReceiver = _receiver;
        bnbDistributor.setDevFeeReceiver(_receiver);

        isDividendExempt[_receiver] = true;
        isFeeExempt[_receiver] = true;
    }

    function settaxPoolReceiver(address _receiver) external onlyOwner {
        autoLiquidityReceiver = _receiver;
        bnbDistributor.settaxPoolReceiver(_receiver);

        isDividendExempt[_receiver] = true;
        isFeeExempt[_receiver] = true;
    }


    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getClaimableBNB() external view returns (uint256) {
        return bnbDistributor.currentAIRDROPs(msg.sender);
    }

    function getWalletClaimableBNB(address _addr) external view returns (uint256) {
        return bnbDistributor.currentAIRDROPs(_addr);
    }

    function getWalletShareAmount(address _addr) external view returns (uint256) {
        return bnbDistributor.getWalletShare(_addr);
    }

    function claim() external {
        bnbDistributor.claimDividend(msg.sender);
    }

    

    function depositExternalBNB() external payable {
        payable(bnbDistributor).transfer(msg.value);
        bnbDistributor.depositExternalBNB(msg.value);
    }

    function buyLapverseWithAIRDROP() external {
        bnbDistributor.buyToken(msg.sender);
    }

    function addPair(address pair) external onlyOwner {
        pairs.push(pair);
    }

    function removeLastPair() external onlyOwner {
        pairs.pop();
    }

    function setFeesOnNormalTransfers(bool _enabled) external onlyOwner {
        feesOnNormalTransfers = _enabled;
    }

    function setisRestricted(address adr, bool restricted) external onlyOwner {
        isRestricted[adr] = restricted;
    }

    function walletIsDividendExempt(address adr) external view returns (bool) {
        return isDividendExempt[adr];
    }

    function walletIsTaxExempt(address adr) external view returns (bool) {
        return isFeeExempt[adr];
    }

    function walletisRestricted(address adr) external view returns (bool) {
        return isRestricted[adr];
    }

    // only for recovering excess BNB in the contract, in times of miscalculation. Can only be sent to marketing wallet - ALWAYS CONFIRM BEFORE USE
    function recoverExcessMarketing(uint256 amount) external onlyOwner {
        require(amount < address(this).balance, "MetaBull: Can not send more than contract balance");
        payable(marketingFeeReceiver).transfer(amount);
    }
    function recoverExcessDev(uint256 amount) external onlyOwner {
        require(amount < address(this).balance, "MetaBull: Can not send more than contract balance");
        payable(devFeeReceiver).transfer(amount);
    }

    // only for recovering tokens that are NOT Lapverse tokens sent in error by wallets
    function withdrawTokens(address tokenaddr) external onlyOwner {
        require(tokenaddr != address(this), 'This is for tokens sent to the contract by mistake');
        uint256 tokenBal = IBEP20(tokenaddr).balanceOf(address(this));
        if (tokenBal > 0) {
            IBEP20(tokenaddr).transfer(marketingFeeReceiver, tokenBal);
        }
    }

    receive() external payable { }
}