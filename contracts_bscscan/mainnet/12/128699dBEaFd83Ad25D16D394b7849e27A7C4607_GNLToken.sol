// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";


/**
 * @dev GNL Token
 * 
 * Contract developed by DeFi Mark
 */
contract GNLToken is IERC20 {
    
    using SafeMath for uint256;
    using Address for address;
    
    // Token Data
    string private constant _name = "Green Life Energy";
    string private constant _symbol = "GNL";
    uint8  private constant _decimals = 9;
    
    // DEX Router
    IUniswapV2Router02 public _router;

    // Burn Wallet
    address public constant _burnWallet = 0x000000000000000000000000000000000000dEaD;
    
    // Bill Payment Receiver
    address public billPaymentRecipient;

    // BNB -> Token
    address[] path;

    // Balances
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Exclusions
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) public isLiquidityPool;
    address[] private _excluded;

    // Supply
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 5 * 10**8 * (10 ** _decimals);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    // Sell Fee Breakdown
    uint256 public _burnFee = 1;           // 25% Burned
    uint256 public _reflectFee = 3;        // 75% Reflected

    // Token Tax Settings
    uint256 public _sellFee = 4;           // 4% sell tax 
    uint256 public _buyFee = 1;            // 1% buy tax
    uint256 public _transferFee = 1;       // 1% transfer tax
    
    // Percentage Of Total Supply To Use GNL Application
    uint256 _walletDivisor = 10**6;
    
    // Ownership
    address public _owner;
    modifier onlyOwner() {
        require(msg.sender == _owner); _;
    }
    
    // initalize GNL Token
    constructor () {
        
        // ownership
        _owner = msg.sender;
        billPaymentRecipient = 0xad16b8964e6d251112cf6E4a6802597acAd072Af;
        
        // Initalize Router
        _router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        // Create Liquidity Pair
        address _pair = IUniswapV2Factory(_router.factory())
            .createPair(address(this), _router.WETH());

        // dividend exclusions
        _excludeFromReward(address(this));
        _excludeFromReward(_burnWallet);
        _excludeFromReward(_pair);
        
        // fee exclusions 
        _isExcludedFromFees[_burnWallet] = true;
        _isExcludedFromFees[_owner] = true;

        // liquidity pools
        isLiquidityPool[_pair] = true;
        
        // allocate total supply to owner
        _rOwned[_owner] = _rTotal;
        
        // BNB -> Token
        path = new address[](2);
        path[0] = _router.WETH();
        path[1] = address(this);

        // Transfer
        emit Transfer(address(0), _owner, _tTotal);
    }
    

    ////////////////////////////////////////////
    ////////      OWNER FUNCTIONS      /////////
    ////////////////////////////////////////////
    
    /**
     * @notice Transfers Ownership To New Account
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;  
        emit TransferOwnership(newOwner);
    }
    
    /**
     * @notice Withdraws BNB accidentally stuck inside contract
     */
    function withdrawBNB(uint256 amount) external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: amount}("");
        require(s, 'Failure on BNB Withdraw');
        emit OwnerWithdraw(_router.WETH(), amount);
    }
    
    /**
     * @notice Withdraws tokens sent to contract by mistake
     */
    function withdrawForeignToken(address token) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        if (bal > 0) {
            IERC20(token).transfer(msg.sender, bal);
        }
        emit OwnerWithdraw(token, bal);
    }

    /** 
     * Enables Liquidity Pool Behavor For Address 
     */
    function setIsLiquidityPool(address pool, bool isPool) external onlyOwner {
        isLiquidityPool[pool] = isPool;
        emit SetIsLiquidityPool(pool, isPool);
    }
    
     /**
     * @notice Excludes an address from receiving reflections
     */
    function excludeFromRewards(address account) external onlyOwner {
        _excludeFromReward(account);
        emit ExcludeFromRewards(account);
    }
    
    function setFeeExemption(address account, bool feeExempt) external onlyOwner {
        _isExcludedFromFees[account] = feeExempt;
        emit SetFeeExemption(account, feeExempt);
    }
    
    function setBillPaymentRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), 'Invalid Recipient');
        billPaymentRecipient = recipient;
        emit PaymentRecipientUpdated(recipient);
    }
    
    function setWalletDivisor(uint256 divisor) external onlyOwner {
        require(divisor >= 100, 'Divisor Too Low');
        _walletDivisor = divisor;
        emit SetWalletDivisor(divisor);
    }
    
    /** Sets Various Fees */
    function setFees(uint256 burnFee, uint256 reflectFee, uint256 buyFee, uint256 transferFee) external onlyOwner {
        _burnFee = burnFee;
        _reflectFee = reflectFee;
        _sellFee = burnFee.add(_reflectFee);
        _buyFee = buyFee;
        _transferFee = transferFee;
        require(_sellFee <= 30);
        require(buyFee < 30);
        require(transferFee < 30);
        emit SetFees(burnFee, reflectFee, buyFee, transferFee);
    }
    
    /**
     * @notice Includes an address back into the reflection system
     */
    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                // updating _rOwned to make sure the balances stay the same
                if (_tOwned[account] > 0)
                {
                    uint256 newrOwned = _tOwned[account].mul(_getRate());
                    _rTotal = _rTotal.sub(_rOwned[account]-newrOwned);
                    _rOwned[account] = newrOwned;
                }
                else
                {
                    _rOwned[account] = 0;
                }

                _tOwned[account] = 0;
                _excluded[i] = _excluded[_excluded.length - 1];
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
        emit IncludeInRewards(account);
    }
    
    
    ////////////////////////////////////////////
    ////////      PUBLIC FUNCTIONS     /////////
    ////////////////////////////////////////////
    
    
    function payBill(uint256 numberTokens) external {
        require(balanceOf(msg.sender) >= numberTokens, 'Insufficient Balance');
        require(numberTokens > 0, 'Zero Tokens');
        
        _tokenTransfer(msg.sender, billPaymentRecipient, numberTokens, false);
        emit BillPayed(msg.sender, numberTokens, block.number);
    }
    
    function reflectTokens(uint256 tAmount) external {
        require(balanceOf(msg.sender) >= tAmount, 'Insufficient Balance');
        require(!_isExcluded[msg.sender], "Excluded addresses cannot call this function");
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[msg.sender] = _rOwned[msg.sender].sub(rAmount, 'Insufficient Balance');
        _rTotal = _rTotal.sub(rAmount, 'Negative rTotal');
    }
    
    
    
    ////////////////////////////////////////////
    ////////      IERC20 FUNCTIONS     /////////
    ////////////////////////////////////////////
    

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        return _transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
    ////////////////////////////////////////////
    ////////       READ FUNCTIONS      /////////
    ////////////////////////////////////////////
    
    
    function getWalletDivisor() external view returns (uint256) {
        return _walletDivisor;
    }
    
    function canUseWallet(address user) external view returns (bool) {
        uint256 bal = balanceOf(user);
        if (bal == 0) return false;
        return bal >= _tTotal.div(_walletDivisor);
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function isExcludedFromRewards(address account) external view returns(bool) {
        return _isExcluded[account];
    }
    
    /**
     * @notice Converts a reflection value to a token value
     */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    /**
     * @notice Calculates transfer reflection values
     */
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    /**
     * @notice Calculates the rate of reflections to tokens
     */
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
    /**
     * @notice Gets the current supply values
     */
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function getIncludedTotalSupply() external view returns (uint256) {
        (, uint256 tSupply) = _getCurrentSupply();
        return tSupply;
    }
    
    ////////////////////////////////////////////
    ////////    INTERNAL FUNCTIONS     /////////
    ////////////////////////////////////////////


    /**
     * @notice Handles the before and after of a token transfer, such as taking fees and firing off a swap and liquify event
     */
    function _transfer(address from, address to, uint256 amount) private returns(bool){
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // Should fee be taken 
        bool takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);
        
        return _tokenTransfer(from, to, amount, takeFee);
    }
    
    function _tokenTransfer(address from, address to, uint256 amount, bool takeFee) private returns (bool) {
        
        // Calculate the values required to execute a transfer
        uint256 fee = getFee(from, to, takeFee);
        // take fee out of transfer amount
        uint256 tFee = amount.mul(fee).div(100);
        // new transfer amount
        uint256 tTransferAmount = amount.sub(tFee);
        // get R Values
        (uint256 rAmount, uint256 rTransferAmount,) = _getRValues(amount, tFee, _getRate());
        
        // Take Tokens From Sender
		if (_isExcluded[from]) {
		    _tOwned[from] = _tOwned[from].sub(amount);
		}
		_rOwned[from] = _rOwned[from].sub(rAmount);
		
		// Give Taxed Amount To Recipient
		if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to].add(tTransferAmount);
		}
		_rOwned[to] = _rOwned[to].add(rTransferAmount); 
		
		// apply fees if applicable
		if (takeFee) {
		    
		    // Burn Tokens
		    uint256 burnPortion = tFee.mul(_burnFee).div(_sellFee);
		    if (burnPortion > 0) {
		        _burnTokens(from, burnPortion);
		    }
		    
		    // Reflect tokens
	    	uint256 reflectPortion = tFee.sub(burnPortion);
	    	if (reflectPortion > 0) {
	    	    _reflectTokens(reflectPortion);
	    	}

            // Emit Fee Distribution
            emit FeesDistributed(burnPortion, reflectPortion);
		    
		}
		
        // Emit Transfer
        emit Transfer(from, to, tTransferAmount);
        return true;
        
    }

    function getFee(address sender, address recipient, bool takeFee) internal view returns (uint256) {
        if (!takeFee) return 0;
        return isLiquidityPool[recipient] ? _sellFee : isLiquidityPool[sender] ? _buyFee : _transferFee;
    }
    
    /**
     * @notice Burns CRIB tokens straight to the burn address
     */
    function _burnTokens(address sender, uint256 tAmount) private {
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[_burnWallet] = _rOwned[_burnWallet].add(rAmount);
        if(_isExcluded[_burnWallet]) {
            _tOwned[_burnWallet] = _tOwned[_burnWallet].add(tAmount);
        }
        emit Transfer(sender, _burnWallet, tAmount);
    }

    /**
     * @notice Increases the rate of how many reflections each token is worth
     */
    function _reflectTokens(uint256 tFee) private {
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
    }
    
    /**
     * @notice Excludes an address from receiving reflections
     */
    function _excludeFromReward(address account) private {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    
    receive() external payable {
        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            msg.sender,
            block.timestamp + 30
        );
    }
    
    
    ////////////////////////////////////////////
    ////////          EVENTS           /////////
    ////////////////////////////////////////////
    
    event FeesDistributed(uint256 burnPortion, uint256 reflectPortion);
    event TransferOwnership(address newOwner);
    event OwnerWithdraw(address token, uint256 amount);
    event SetIsLiquidityPool(address pool, bool isPool);
    event ExcludeFromRewards(address account);
    event SetFeeExemption(address account, bool feeExempt);
    event SetFees(uint256 burnFee, uint256 reflectFee, uint256 buyFee, uint256 transferFee);
    event IncludeInRewards(address account);
    event PaymentRecipientUpdated(address recipient);
    event SetWalletDivisor(uint256 divisor);
    event BillPayed(address user, uint256 amount, uint256 blockNumber);

}