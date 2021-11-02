/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

/**
 * SPDX-License-Identifier: MIT
 */ 
 
pragma solidity ^0.8.7;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

library Address {
    function isContract(address account) internal view returns (bool) { 
        uint256 size; assembly { size := extcodesize(account) } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
        
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IPancakeV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeV2Router {
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

contract FalconZilla is IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    address public marketingWallet = 0xCDA523e9fF879aCe6788DC2cEF060FA5F2309A54; // Marketing Address
    address internal deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public presaleAddress = address(0);
    
    string constant _name = "FalconZilla";
    string constant _symbol = "FalconZilla";
    uint8 constant _decimals = 9;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant _totalSupply = 1000000000000000000000 * 10**9;
    uint256 internal _reflectedSupply = (MAX - (MAX % _totalSupply));
    
    uint256 public collectedFeeTotal;
  
    uint256 public maxTxAmount = _totalSupply / 1000; // 0.5% of the total supply
    uint256 public maxWalletBalance = _totalSupply / 50; // 2% of the total supply
    
    bool public takeFeeEnabled = true;
    bool public tradingIsEnabled = true;
    bool public isInPresale = false;
    
    bool private swapping;
    bool public swapEnabled = true;
    uint256 public swapTokensAtAmount = 10000000000 * (10**9);
    
    uint256 public marketingPortionOfSwap = 40;
    
    uint256 internal FEES_DIVISOR = 10**2;
    
    uint256 public sellingMarketingFee = 3;
    uint256 public buyingMarketingFee = 3;
    
    uint256 public sellingRfiFee = 2;
    uint256 public buyingRfiFee = 2;
    
    uint256 public sellingLpFee = 4;
    uint256 public buyingLpFee = 4;
    
    uint256 public buyersTotalFees = buyingMarketingFee.add(buyingRfiFee).add(buyingLpFee);
    uint256 public sellersTotalFees = sellingMarketingFee.add(sellingRfiFee).add(sellingLpFee);
    
    IPancakeV2Router public router;
    address public pair;
    
    mapping (address => uint256) internal _reflectedBalances;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    
    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _isExcludedFromRewards;
    address[] private _excluded;
    
    event UpdatePancakeswapRouter(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event LiquidityAdded(uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    constructor () {
        _reflectedBalances[owner()] = _reflectedSupply;
        
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        router = _newPancakeRouter;
        
        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        // exclude the owner and this contract from rewards
        _exclude(owner());
        _exclude(address(this));
        
        // exclude the pair address from rewards - we don't want to redistribute
        _exclude(pair);
        _exclude(deadAddress);
        
        _approve(owner(), address(router), ~uint256(0));
        
        emit Transfer(address(0), owner(), _totalSupply);
    }
    
    receive() external payable { }
    
    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256){
        if (_isExcludedFromRewards[account]) return _balances[account];
        return tokenFromReflection(_reflectedBalances[account]);
        }
        
    function transfer(address recipient, uint256 amount) external override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
        }
        
    function allowance(address owner, address spender) external view override returns (uint256){
        return _allowances[owner][spender];
        }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
        }
        
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool){
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
        }
        
    function burn(uint256 amount) external {

        address sender = _msgSender();
        require(sender != address(0), "ERC20: burn from the zero address");
        require(sender != address(deadAddress), "ERC20: burn from the burn address");

        uint256 balance = balanceOf(sender);
        require(balance >= amount, "ERC20: burn amount exceeds balance");

        uint256 reflectedAmount = amount.mul(_getCurrentRate());

        // remove the amount from the sender's balance first
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(reflectedAmount);
        if (_isExcludedFromRewards[sender])
            _balances[sender] = _balances[sender].sub(amount);

        _burnTokens( sender, amount, reflectedAmount );
    }
    
    /**
     * @dev "Soft" burns the specified amount of tokens by sending them 
     * to the burn address
     */
    function _burnTokens(address sender, uint256 tBurn, uint256 rBurn) internal {

        /**
         * @dev Do not reduce _totalSupply and/or _reflectedSupply. (soft) burning by sending
         * tokens to the burn address (which should be excluded from rewards) is sufficient
         * in RFI
         */ 
        _reflectedBalances[deadAddress] = _reflectedBalances[deadAddress].add(rBurn);
        if (_isExcludedFromRewards[deadAddress])
            _balances[deadAddress] = _balances[deadAddress].add(tBurn);

        /**
         * @dev Emit the event so that the burn address balance is updated (on bscscan)
         */
        emit Transfer(sender, deadAddress, tBurn);
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BaseRfiToken: approve from the zero address");
        require(spender != address(0), "BaseRfiToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
     /**
     * @dev Calculates and returns the reflected amount for the given amount with or without 
     * the transfer fees (deductTransferFee true/false)
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee, bool isBuying) external view returns(uint256) {
        require(tAmount <= _totalSupply, "Amount must be less than supply");
        uint256 feesSum;
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount,0);
            return rAmount;
        } else {
            feesSum = isBuying ? buyersTotalFees : sellersTotalFees;
            (,uint256 rTransferAmount,,,) = _getValues(tAmount, feesSum);
            return rTransferAmount;
        }
    }

    /**
     * @dev Calculates and returns the amount of tokens corresponding to the given reflected amount.
     */
    function tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _reflectedSupply, "Amount must be less than total reflections");
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
    }
    
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcludedFromRewards[account], "Account is not included");
        _exclude(account);
    }
    
    function _exclude(address account) internal {
        if(_reflectedBalances[account] > 0) {
            _balances[account] = tokenFromReflection(_reflectedBalances[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balances[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function setExcludedFromFee(address account, bool value) external onlyOwner { 
        _isExcludedFromFee[account] = value; 
    }

    function _getValues(uint256 tAmount, uint256 feesSum) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 currentRate = _getCurrentRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);
        
        return (rAmount, rTransferAmount, tAmount, tTransferAmount, currentRate);
    }
    
    function _getCurrentRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
    function _getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _reflectedSupply;
        uint256 tSupply = _totalSupply;

        /**
         * The code below removes balances of addresses excluded from rewards from
         * rSupply and tSupply, which effectively increases the % of transaction fees
         * delivered to non-excluded holders
         */    
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectedBalances[_excluded[i]] > rSupply || _balances[_excluded[i]] > tSupply)
            return (_reflectedSupply, _totalSupply);
            rSupply = rSupply.sub(_reflectedBalances[_excluded[i]]);
            tSupply = tSupply.sub(_balances[_excluded[i]]);
        }
        if (tSupply == 0 || rSupply < _reflectedSupply.div(_totalSupply)) return (_reflectedSupply, _totalSupply);
        return (rSupply, tSupply);
    }
    
    
    /**
     * @dev Redistributes the specified amount among the current holders via the reflect.finance
     * algorithm, i.e. by updating the _reflectedSupply (_rSupply) which ultimately adjusts the
     * current rate used by `tokenFromReflection` and, in turn, the value returns from `balanceOf`. 
     * 
     */
    function _redistribute(uint256 amount, uint256 currentRate, uint256 fee) internal {
        uint256 tFee = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rFee = tFee.mul(currentRate);

        _reflectedSupply = _reflectedSupply.sub(rFee);
        
        collectedFeeTotal = collectedFeeTotal.add(tFee);
    }
    // views
    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return swapTokensAtAmount;
    }
    
    function totalCollectedFees() external view returns (uint256) {
        return collectedFeeTotal;
    }
    
     function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromRewards[account];
    }
    
    function isExcludedFromFee(address account) public view returns(bool) { 
        return _isExcludedFromFee[account]; 
    }
    
    function whitelistDxSale(address _presaleAddress, address _routerAddress) external onlyOwner {
  	    presaleAddress = _presaleAddress;
  	    
        _exclude(_presaleAddress);
        _isExcludedFromFee[_presaleAddress] = true;

        _exclude(_routerAddress);
        _isExcludedFromFee[_routerAddress] = true;
  	}
  	
    
    function prepareForPreSale() external onlyOwner {
        takeFeeEnabled = false;
        swapEnabled = false;
        isInPresale = true;
        maxTxAmount = _totalSupply;
        maxWalletBalance = _totalSupply;
    }
    
    function afterPreSale() external onlyOwner {
        takeFeeEnabled = true;
        swapEnabled = true;
        isInPresale = false;
        maxTxAmount = _totalSupply / 1000;
        maxWalletBalance = _totalSupply / 50;
    }
    
    
    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled  = _enabled;
    }
    
    function updateSwapTokensAt(uint256 _swaptokens) external onlyOwner {
        swapTokensAtAmount = _swaptokens * (10**9);
    }
    
    function updateWalletMax(uint256 _walletMax) external onlyOwner {
        maxWalletBalance = _walletMax * (10**9);
    }
    
    function updateTransactionMax(uint256 _txMax) external onlyOwner {
        maxTxAmount = _txMax * (10**9);
    }
    
    function calcBuyersTotalFees() private {
        buyersTotalFees = buyingMarketingFee.add(buyingRfiFee).add(buyingLpFee);
    }
    
    function calcSellersTotalFees() private {
        sellersTotalFees = sellingMarketingFee.add(sellingRfiFee).add(sellingLpFee);
    }
    
    function updateSellingRfiFee (uint256 newFee) external onlyOwner {
        sellingRfiFee = newFee;
        calcSellersTotalFees();
    }
    
    function updateSellingMarketingFee (uint256 newFee) external onlyOwner {
        sellingMarketingFee = newFee;
        calcSellersTotalFees();
    }
    
    function updateSellingLpFee (uint256 newFee) external onlyOwner {
        sellingLpFee = newFee;
        calcSellersTotalFees();
    }
    
    function updateBuyingRfiFee (uint256 newFee) external onlyOwner {
        buyingRfiFee = newFee;
        calcBuyersTotalFees();
    }
    
    function updateBuyingMarketingFee (uint256 newFee) external onlyOwner {
        buyingMarketingFee = newFee;
        calcBuyersTotalFees();
    }
    
    function updateBuyingLpFee (uint256 newFee) external onlyOwner {
        buyingLpFee = newFee;
        calcBuyersTotalFees();
    }
    
    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != marketingWallet, "The Marketing wallet is already this address");
        marketingWallet = newMarketingWallet;
        
        emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);
    }
    
    function setFeesDivisor(uint256 divisor) external onlyOwner() {
        FEES_DIVISOR = divisor;
    }
    
    function updateTradingIsEnabled(bool tradingStatus) external onlyOwner() {
        tradingIsEnabled = tradingStatus;
    }
    
    function updateRouterAddress(address newAddress) external onlyOwner {
        require(newAddress != address(router), "The router already has that address");
        router = IPancakeV2Router(newAddress);
        
        emit UpdatePancakeswapRouter(newAddress, address(router));
    }
    
    function updateMarketingPortionOfSwap(uint256 newAmount) external onlyOwner {
        marketingPortionOfSwap = newAmount;
    }
    
    function _swapAndLiquify(uint256 amount) private {
        
        // split the amount into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);
        
        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        
        // swap tokens for BNB
        swapTokensForBNB(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to Pancakeswap
        _addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );

        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);
    }
    

    function _takeFee(uint256 amount, uint256 currentRate, uint256 fee, address recipient) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAmount);
        if(_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);

        collectedFeeTotal = collectedFeeTotal.add(tAmount);
    }
    
    function _transferTokens(address sender, address recipient, uint256 amount, bool takeFee) private {
        
         uint256 sumOfFees = isInPresale ? 0 : buyersTotalFees;
         
         bool isBuying = true;
         
        if(recipient == pair) {
            sumOfFees = isInPresale ? 0 : sellersTotalFees;
            isBuying  = false;
        }
        
        if ( !takeFee ){ sumOfFees = 0; }
        
        processReflectedBal(sender, recipient, amount, sumOfFees, isBuying);
       
    }
    
    function processReflectedBal (address sender, address recipient, uint256 amount, uint256 sumOfFees, bool isBuying) private {
        
        (uint256 rAmount, uint256 rTransferAmount, uint256 tAmount, 
        uint256 tTransferAmount, uint256 currentRate ) = _getValues(amount, sumOfFees);
         
        theReflection(sender, recipient, rAmount, rTransferAmount, tAmount, tTransferAmount); 
        
        _takeFees(amount, currentRate, sumOfFees, isBuying);
        
        emit Transfer(sender, recipient, tTransferAmount);    
    }
    
    function theReflection(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount, uint256 tAmount, 
        uint256 tTransferAmount) private {
            
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(rAmount);
        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rTransferAmount);
        
        /**
         * Update the true/nominal balances for excluded accounts
         */        
        if (_isExcludedFromRewards[sender]) { _balances[sender] = _balances[sender].sub(tAmount); }
        if (_isExcludedFromRewards[recipient] ) { _balances[recipient] = _balances[recipient].add(tTransferAmount); }
    }
    
    
    function _takeFees(uint256 amount, uint256 currentRate, uint256 sumOfFees, bool isBuying) private {
        if ( sumOfFees > 0 && !isInPresale ){
            if(isBuying) {
                _redistribute( amount, currentRate, buyingRfiFee);
                _takeFee( amount, currentRate, buyingLpFee, address(this));
                _takeFee( amount, currentRate, buyingMarketingFee, marketingWallet);  
            }
            else{
                _redistribute( amount, currentRate, sellingRfiFee);
                _takeFee( amount, currentRate, sellingLpFee, address(this));
                _takeFee( amount, currentRate, sellingMarketingFee, marketingWallet);     
            }
        }
    }
    
    function _beforeTokenTransfer(address recipient) private {
            
        if ( !isInPresale ){
            uint256 contractTokenBalance = balanceOf(address(this));
            // swap
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap && swapEnabled && recipient == pair) {
                swapping = true;
                
                // split the contract balance
                uint256 marketingPercent = contractTokenBalance.mul(marketingPortionOfSwap).div(FEES_DIVISOR);
                uint256 liquidityPercent = contractTokenBalance.sub(marketingPercent);
                
                //swap and send to marketing wallet
                sendToMarketingAddress(marketingPercent); 
                
                // add liquidity
                _swapAndLiquify(liquidityPercent);
                
                swapping = false;
            }
            
        }
    }
   
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Token: transfer from the zero address");
        require(recipient != address(0), "Token: transfer to the zero address");
        require(sender != address(deadAddress), "Token: transfer from the burn address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        require(tradingIsEnabled, "This account cannot send tokens until trading is enabled");

        if (
            sender != address(router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFee[recipient] && //no max for those excluded from fees
            !_isExcludedFromFee[sender] 
        ) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the Max Transaction Amount.");
            
        }
        
        if ( maxWalletBalance > 0 && !_isExcludedFromFee[recipient] && !_isExcludedFromFee[sender] && recipient != address(pair) ) {
                uint256 recipientBalance = balanceOf(recipient);
                require(recipientBalance + amount <= maxWalletBalance, "New balance would exceed the maxWalletBalance");
            }
            
         // indicates whether or not fee should be deducted from the transfer
        bool _isTakeFee = takeFeeEnabled;
        if ( isInPresale ){ _isTakeFee = false; }
        
         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) { 
            _isTakeFee = false; 
        }
        
        _beforeTokenTransfer(recipient);
        _transferTokens(sender, recipient, amount, _isTakeFee);
        
    }
    
    function sendToMarketingAddress(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(tokenAmount);
        
        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        
         //Send to Marketing address
       transferToAddressBNB(payable(marketingWallet), transferredBalance);
    }
    
    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }
    
    function swapBNBForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

      // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp
        );
        
        emit SwapETHForTokens(amount, path);
    }
    
    function transferToAddressBNB(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
     // function to allow admin to transfer ETH from this contract
    function TransferETH(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Cannot withdraw the ETH balance to the zero address");
        recipient.transfer(amount);
    }
    
}