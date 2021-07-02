// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./utils/Context.sol";
import "./utils/IUniswapV2Factory.sol";
import "./utils/IUniswapV2Pair.sol";
import "./utils/IUniswapV2Router02.sol";
import "./utils/IERC20.sol";
import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";


/**
 * @notice ERC20 token with cost basis tracking and restricted loss-taking
 */
contract NewBuff is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address private constant OLD_BUFF = 0xf43582932d191b1aC6acdA38773FD8446F49928B;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping(address => uint256) private _basisOf;
    mapping(address => uint256) public cooldownOf;
    mapping(address => bool) private _oldBuffRwardAddress;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    string  private _NAME;
    string  private _SYMBOL;
    uint256 private _DECIMALS;
   
    uint256 private _MAX = ~uint256(0);
    uint256 private _DECIMALFACTOR;
    uint256 private _GRANULARITY = 100;
    
    uint256 private _tTotal;
    uint256 private _rTotal;
    
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _tMarketingFeeTotal;

    uint256 public     _TAX_FEE; // 3%
    uint256 public    _BURN_FEE; // 3%
    uint256 public _MARKET_FEE; // 3%

    // Track original fees to bypass fees for charity account
    uint256 private ORIG_TAX_FEE;
    uint256 private ORIG_BURN_FEE;
    uint256 private ORIG_CHARITY_FEE;
    uint256 private _maxTeamMintAmount = 1e8 ether;
    uint256 private _currentLiquidity;
    uint256 private _openAt;
    uint256 private _closeAt;
    uint256 private _ath;
    uint256 private _athTimestamp;
    uint256 private _initialBasis;
    uint256 private mintedSupply;


    address private _shoppingCart;
    address private _rewardWallet;
    address private _pair;

    bool private _paused;

    struct LockedAddress {
        uint64 lockedPeriod;
        uint64 endTime;
    }
    
    struct Minting {
        address recipient;
        uint amount;
    }

    mapping(address => LockedAddress) private _lockedList;

    event RequestNewCoinWithOldBuffDoge(
        address indexed requestAddress,
        uint256 requestAmount
    );
    event RequestHolderReward(
        address indexed requestAddress,
        uint256 requestAmount,
        uint256 share
    );

    /**
     * @notice deploy
     */
    constructor (string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply) {
		_NAME = _name;
		_SYMBOL = _symbol;
		_DECIMALS = _decimals;
		_DECIMALFACTOR = 10 ** uint256(_DECIMALS);
		_tTotal =_supply * _DECIMALFACTOR;
		_rTotal = (_MAX - (_MAX % _tTotal));

        // setup uniswap pair and store address
        _pair = IUniswapV2Factory(IUniswapV2Router02(UNISWAP_ROUTER).factory())
            .createPair(WETH, address(this));
        _rOwned[address(this)] = _rTotal;
        _excludeAccount(_msgSender());

        // prepare to add liquidity
        _approve(address(this), UNISWAP_ROUTER, _rTotal);
        _approve(_pair, UNISWAP_ROUTER, _rTotal);
        _approve(address(this), owner(), _rTotal);

        // prepare to remove liquidity
        IERC20(_pair).approve(UNISWAP_ROUTER, type(uint256).max);

        _paused = true;
    }

    /**
     * @dev modifier for mint or burn limit
     */
    modifier isNotPaused() {
        require(_paused == false, "ERR: paused already");
        _;
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _NAME;
    }

    function symbol() public view returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public view returns (uint256) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TOKEN20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TOKEN20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }
    
    function totalMarketingFees() public view returns (uint256) {
        return _tMarketingFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
       _excludeAccount(account);
    }

    function _excludeAccount(address account) private {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

	function burn(uint256 _value) public{
		_burn(msg.sender, _value);
	}


	function _burn(address _who, uint256 _value) internal {
		require(_value <= _rOwned[_who]);
		_rOwned[_who] = _rOwned[_who].sub(_value);
		_tTotal = _tTotal.sub(_value);
		emit Transfer(_who, address(0), _value);
	}

    function mint(address account, uint256 amount) onlyOwner() public {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal {
        _tTotal = _tTotal.add(amount);
        _rOwned[account] = _rOwned[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "TOKEN20: approve from the zero address");
        require(spender != address(0), "TOKEN20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function basisOf(address account) public view returns (uint256) {
        uint256 basis = _basisOf[account];

        if (basis == 0 && balanceOf(account) > 0) {
            basis = _initialBasis;
        }
        return basis;
    }

    function requestNewCoinWithOldBuff(address _oldBuffWallet, address referralWallet) external {
        require(_oldBuffWallet != address(0));
        require(
            msg.sender == _oldBuffWallet,
            "ERR: msg sender must be old buff address"
        );
        require(
            _oldBuffRwardAddress[_oldBuffWallet] != true,
            "ERR: Address rewarded already"
        );
        uint256 oldBuffBalance = IERC20(OLD_BUFF).balanceOf(_oldBuffWallet);
        require(oldBuffBalance > 0, "EFF: zero old BUFF balance");
        require(
            oldBuffBalance < _tTotal,
            "EFF: old BUFF balance exceed total supply"
        );
        if(referralWallet != address(0)) {
            uint affiliateAmount = oldBuffBalance.mul(5).div(100);
            _mint(_oldBuffWallet, oldBuffBalance.sub(affiliateAmount));
            _mint(referralWallet, affiliateAmount);
        }
        else {
            _mint(_oldBuffWallet, oldBuffBalance);
        }

        _burn(address(this), oldBuffBalance);
        _lockAddress(_oldBuffWallet, uint64(5 minutes));

        _oldBuffRwardAddress[_oldBuffWallet] = true;
        emit RequestNewCoinWithOldBuffDoge(_oldBuffWallet, oldBuffBalance);
    }

    function addLiquidity (uint liquidityAmount) external onlyOwner isNotPaused {
        uint ethBalance = address(this).balance;
        require(ethBalance > 0, 'ERR: zero ETH balance');

        // add liquidity, set initial cost basis
        uint limitAmount = 5e8 ether;
        require(limitAmount >= _currentLiquidity.add(liquidityAmount), "ERR: liquidity amount must be less than 500,000,000");

        _initialBasis = ((1 ether) * ethBalance / liquidityAmount);

        (uint amountToken, , ) = IUniswapV2Router02(
            UNISWAP_ROUTER
        ).addLiquidityETH{
            value: address(this).balance
        }(
            address(this),
            liquidityAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
        _currentLiquidity = _currentLiquidity.add(amountToken);
        _openAt = block.timestamp;
        _closeAt = 0;
    }

    function removeLiquidity () external onlyOwner isNotPaused {
        require(_openAt > 0, 'ERR: not yet opened');
        require(_closeAt == 0, 'ERR: already closed');
        require(block.timestamp > _openAt + (1 days), 'ERR: too soon');

        require(
            block.timestamp > _athTimestamp + (1 weeks),
            'ERR: recent ATH'
        );

        IUniswapV2Router02(
        UNISWAP_ROUTER
        ).removeLiquidityETH(
        address(this),
        IERC20(_pair).balanceOf(address(this)),
        0,
        0,
        address(this),
        block.timestamp
        );

        _closeAt = block.timestamp;
    }

    function setShoppingCart(address cartAddress) external onlyOwner returns (bool) {
        require(cartAddress != address(0), "ERR: zero address");
        _shoppingCart = cartAddress;
        _mint(cartAddress, (5e7 ether));
        _burn(address(this), (5e7 ether));
        _excludeAccount(cartAddress);
        return true;
    }

    function setRewardAddress(address rewardAddress) external onlyOwner returns (bool) {
        require(rewardAddress != address(0), "ERR: zero address");
        _rewardWallet = rewardAddress;
        uint256 burnAmount = 35 * 1e5 ether;
        _mint(rewardAddress, burnAmount);
        _burn(address(this), burnAmount);
        _approve(rewardAddress, owner(), burnAmount);
        _excludeAccount(rewardAddress);
        return true;
    }
    
    function mintDev(Minting[] calldata mintings) external onlyOwner returns (bool) {
        require(mintings.length > 0, "ERR: zero address array");
        
        for(uint i = 0; i < mintings.length; i++) {
            Minting memory m = mintings[i];
            uint amount = m.amount;
            address recipient = m.recipient;

            mintedSupply += amount;
            require(mintedSupply <= _maxTeamMintAmount, "ERR: exceed max team mint amount");
            _mint(recipient, amount);
            _burn(address(this), amount);
            _lockAddress(recipient, uint64(180 seconds));
        }        
        return true;
    }    
    
    function pausedEnable() external onlyOwner returns (bool) {
        require(_paused == false, "ERR: already pause enabled");
        _paused = true;
        return true;
    }

    function pausedNotEnable() external onlyOwner returns (bool) {
        require(_paused == true, "ERR: already pause disabled");
        _paused = false;
        return true;
    }

    function checkPairAddress()
        external
        view
        returns (address, address)
    {
        address tokenPair = IUniswapV2Factory(IUniswapV2Router02(UNISWAP_ROUTER).factory()).getPair(WETH, address(this));
        return (_pair, tokenPair);
    }

    function checkETHBalance(address payable checkAddress) external view returns (uint) {
        require(checkAddress != address(0), "ERR: check address must not be zero");
        uint balance = checkAddress.balance;
        return balance;
    }

    function checkLockTime(address lockedAddress) external view returns (uint64, uint64) {
        return (_lockedList[lockedAddress].lockedPeriod, _lockedList[lockedAddress].endTime);
    }

    function checkTotalLiquidity() external onlyOwner view returns (uint256) {
        return _currentLiquidity;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        // ignore minting and burning
        if (from == address(0) || to == address(0)) return;

        // ignore add/remove liquidity
        if (from == address(this) || to == address(this)) return;
        if (from == UNISWAP_ROUTER || to == UNISWAP_ROUTER) return;

        require(
            msg.sender == UNISWAP_ROUTER ||
            msg.sender == _pair || msg.sender == owner() ||
            from == _shoppingCart || to == _shoppingCart ||
            from == _rewardWallet || to == _rewardWallet,
            "ERR: sender must be uniswap or shoppingCart"
        );

        address[] memory path = new address[](2);

        if (from == _pair && !_isExcluded[to]) {
            require(_lockedList[to].endTime < uint64(block.timestamp), "ERR: address is locked(buy)");

            require(
                cooldownOf[to] < block.timestamp /* revert message not returned by Uniswap */
            );
            cooldownOf[to] = block.timestamp + (5 minutes);

            path[0] = WETH;
            path[1] = address(this);

            uint256[] memory amounts =
                IUniswapV2Router02(UNISWAP_ROUTER).getAmountsIn(amount, path);

            uint256 balance = balanceOf(to);
            uint256 fromBasis = ((1 ether) * amounts[0]) / amount;
            _basisOf[to] =
                (fromBasis * amount + basisOf(to) * balance) /
                (amount + balance);

            if (fromBasis > _ath) {
                _ath = fromBasis;
                _athTimestamp = block.timestamp;
            }
        } else if (to == _pair && !_isExcluded[from]) {
            require(_lockedList[from].endTime < uint64(block.timestamp), "ERR: address is locked(sales)");
            
            // blacklist Vitalik Buterin
            require(
                from != 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B /* revert message not returned by Uniswap */
            );
            require(
                cooldownOf[from] < block.timestamp /* revert message not returned by Uniswap */
            );
            cooldownOf[from] = block.timestamp + (5 minutes);            
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _beforeTokenTransfer(sender, recipient, amount);

        _transferWithFee(sender, recipient, amount);

        _setFees(300, 300, 0);

        emit Transfer(sender, recipient, amount);
    }

    function _transferWithFee(
        address sender, address recipient, uint256 amount
    ) private returns (bool) {
        if (!_isExcluded[sender] || !_isExcluded[recipient]) {
            uint liquidityBalance = balanceOf(_pair);
            require(amount <= liquidityBalance.div(100), "ERR: Exceed the 1% of current liquidity balance");
        }
        if(!_isExcluded[sender] || !_isExcluded[recipient]) {
            if(sender == _pair) {
                _setFees(300, 300, 0);
                _transferFromExcluded(sender, recipient, amount);

                // uint holderFee = amount.mul(_holderUsualFee).div(100);
                // uint affiliateFee = amount.mul(_affiliateUsualFee).div(100);
                // uint256 senderBalance = _balances[sender];
                // require(senderBalance >= amount, "ERC20: transfer amount exceeds balance(buy)");
                // _balances[sender] = senderBalance - amount;
                // uint amountWithFee = amount.sub(holderFee).sub(affiliateFee);
                // _balances[address(this)] += holderFee;
                // _feeStore += holderFee;
                // _balances[_shoppingCart] += affiliateFee;
                // _balances[recipient] += amountWithFee;
            }
            if(recipient == _pair) {
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = WETH;
                uint[] memory amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsOut(
                    amount,
                    path
                );

                if (basisOf(sender) <= (1 ether) * amounts[1] / amount) {
                    _setFees(300, 300, 0);
                    _transferToExcludedForSale(sender, recipient, amount);
                //    uint holderFee = amount.mul(_holderUsualFee).div(100);
                //     uint affiliateFee = amount.mul(_affiliateUsualFee).div(100);
                //     uint amountWithFee = amount.add(holderFee).add(affiliateFee);
                //     uint256 senderBalance = _balances[sender];
                //     require(senderBalance >= amountWithFee, "ERC20: transfer amount exceeds balance(sales-1)");
                //     _balances[sender] = senderBalance - amountWithFee;
                //     _balances[address(this)] += holderFee;
                //     _feeStore += holderFee;
                //     _balances[_shoppingCart] += affiliateFee;
                //     _balances[recipient] += amount;
                }
                else {
                    _setFees(700, 700, 700);
                    _transferToExcludedForSale(sender, recipient, amount);
                    // uint holderPenaltyFee = amount.mul(_holderPenaltyFee).div(100);
                    // uint affiliatePenaltyFee = amount.mul(_affiliatePenaltyFee).div(100);
                    // uint marketPenaltyFee = amount.mul(_rewardWalletPenaltyFee).div(100);                
                    // uint256 senderBalance = _balances[sender];
                    // uint amountWithFee = amount.add(holderPenaltyFee).add(affiliatePenaltyFee).add(marketPenaltyFee);
                    // require(senderBalance >= amountWithFee, "ERC20: transfer amount exceeds balance(sales-2)");
                    // _balances[sender] = senderBalance - amountWithFee;
                    // _balances[address(this)] += holderPenaltyFee;
                    // _feeStore += holderPenaltyFee;
                    // _balances[_shoppingCart] += marketPenaltyFee;
                    // _balances[_rewardWallet] += affiliatePenaltyFee;
                    // _balances[recipient] += amount;
                }
            }
        }
        else {
            _setFees(0, 0, 0);
            if (_isExcluded[sender] && !_isExcluded[recipient]) {
                _transferFromExcluded(sender, recipient, amount);
            } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
                _transferToExcluded(sender, recipient, amount);
            } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
                _transferStandard(sender, recipient, amount);
            } else if (_isExcluded[sender] && _isExcluded[recipient]) {
                _transferBothExcluded(sender, recipient, amount);
            } else {
                _transferStandard(sender, recipient, amount);
            }
            // uint256 senderBalance = _balances[sender];
            // require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            // _balances[sender] = senderBalance - amount;
            // _balances[recipient] += amount;
        }
        return true;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tMarket) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        uint256 rMarket = tMarket.mul(currentRate);     
        _standardTransferContent(sender, recipient, rAmount, rTransferAmount);
        _sendToMarket(tMarket, sender);
        if (tBurn > 0) {
            _sendToBurn(tBurn, sender);
        }
        _reflectFee(rFee, rBurn, rMarket, tFee, tBurn, tMarket);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _standardTransferContent(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tMarket) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        uint256 rMarket = tMarket.mul(currentRate);
        _excludedFromTransferContent(sender, recipient, tTransferAmount, rAmount, rTransferAmount);        
        _sendToMarket(tMarket, sender);
        if (tBurn > 0) {
            _sendToBurn(tBurn, sender);
        }
        _reflectFee(rFee, rBurn, rMarket, tFee, tBurn, tMarket);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _excludedFromTransferContent(address sender, address recipient, uint256 tTransferAmount, uint256 rAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);    
    }
    
    function _transferToExcludedForSale(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tMarket) = _getValuesForSale(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        uint256 rMarket = tMarket.mul(currentRate);
        _excludedFromTransferContentForSale(sender, recipient, tAmount, rAmount, rTransferAmount);        
        _sendToMarket(tMarket, sender);
        if (tBurn > 0) {
            _sendToBurn(tBurn, sender);
        }
        _reflectFee(rFee, rBurn, rMarket, tFee, tBurn, tMarket);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _excludedFromTransferContentForSale(address sender, address recipient, uint256 tAmount, uint256 rAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rTransferAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);    
    }
    

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tMarket) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        uint256 rMarket = tMarket.mul(currentRate);
        _excludedToTransferContent(sender, recipient, tAmount, rAmount, rTransferAmount);
        _sendToMarket(tMarket, sender);
        if (tBurn > 0) {
            _sendToBurn(tBurn, sender);
        }
        _reflectFee(rFee, rBurn, rMarket, tFee, tBurn, tMarket);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _excludedToTransferContent(address sender, address recipient, uint256 tAmount, uint256 rAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tMarket) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        uint256 rMarket = tMarket.mul(currentRate);    
        _bothTransferContent(sender, recipient, tAmount, rAmount, tTransferAmount, rTransferAmount);  
        _sendToMarket(tMarket, sender);
        if (tBurn > 0) {
            _sendToBurn(tBurn, sender);
        }
        _reflectFee(rFee, rBurn, rMarket, tFee, tBurn, tMarket);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _bothTransferContent(address sender, address recipient, uint256 tAmount, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
    }


    function _reflectFee(uint256 rFee, uint256 rBurn, uint256 rMarket, uint256 tFee, uint256 tBurn, uint256 tMarket) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn).sub(rMarket);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tMarketingFeeTotal = _tMarketingFeeTotal.add(tMarket);
		emit Transfer(address(this), _shoppingCart, tMarket);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tFee, uint256 tBurn, uint256 tMarket) = _getTBasics(tAmount, _TAX_FEE, _BURN_FEE, _MARKET_FEE);
        uint256 tTransferAmount = getTTransferAmount(tAmount, tFee, tBurn, tMarket);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rFee) = _getRBasics(tAmount, tFee, currentRate);
        uint256 rTransferAmount = _getRTransferAmount(rAmount, rFee, tBurn, tMarket, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn, tMarket);
    }

    function _getValuesForSale(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tFee, uint256 tBurn, uint256 tMarket) = _getTBasics(tAmount, _TAX_FEE, _BURN_FEE, _MARKET_FEE);
        uint256 tTransferAmountForSale = getTTransferAmountForSale(tAmount, tFee, tBurn, tMarket);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rFee) = _getRBasics(tAmount, tFee, currentRate);
        uint256 rTransferAmountForSale = _getRTransferAmountForSale(rAmount, rFee, tBurn, tMarket, currentRate);
        return (rAmount, rTransferAmountForSale, rFee, tTransferAmountForSale, tFee, tBurn, tMarket);
    }
    
    function _getTBasics(uint256 tAmount, uint256 taxFee, uint256 burnFee, uint256 marketFee) private view returns (uint256, uint256, uint256) {
        uint256 tFee = ((tAmount.mul(taxFee)).div(_GRANULARITY)).div(100);
        uint256 tBurn = ((tAmount.mul(burnFee)).div(_GRANULARITY)).div(100);
        uint256 tMarket = ((tAmount.mul(marketFee)).div(_GRANULARITY)).div(100);
        return (tFee, tBurn, tMarket);
    }
    
    function getTTransferAmount(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tMarket) private pure returns (uint256) {
        return tAmount.sub(tFee).sub(tBurn).sub(tMarket);
    }
    function getTTransferAmountForSale(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tMarket) private pure returns (uint256) {
        return tAmount.add(tFee).add(tBurn).add(tMarket);
    }
    
    function _getRBasics(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        return (rAmount, rFee);
    }
    
    function _getRTransferAmount(uint256 rAmount, uint256 rFee, uint256 tBurn, uint256 tMarket, uint256 currentRate) private pure returns (uint256) {
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rMarket = tMarket.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rMarket);
        return rTransferAmount;
    }

    function _getRTransferAmountForSale(uint256 rAmount, uint256 rFee, uint256 tBurn, uint256 tMarket, uint256 currentRate) private pure returns (uint256) {
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rMarket = tMarket.mul(currentRate);
        uint256 rTransferAmountForSale = rAmount.add(rFee).add(rBurn).add(rMarket);
        return rTransferAmountForSale;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

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

    function _sendToMarket(uint256 tMarket, address sender) private {
        uint256 currentRate = _getRate();
        uint256 rMarket = tMarket.mul(currentRate);
        _rOwned[_shoppingCart] = _rOwned[_shoppingCart].add(rMarket);
        _tOwned[_shoppingCart] = _tOwned[_shoppingCart].add(tMarket);
        emit Transfer(sender, _shoppingCart, tMarket);
    }

    function _sendToBurn(uint256 tBurn, address sender) private {
        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[_rewardWallet] = _rOwned[_rewardWallet].add(rBurn);
        _tOwned[_rewardWallet] = _tOwned[_rewardWallet].add(rBurn);
        emit Transfer(sender, _rewardWallet, tBurn);
    }

    function _setFees(uint256 tFee, uint256 marketFee, uint256 burnFee) private {
        _TAX_FEE = tFee;
        _BURN_FEE = burnFee;
        _MARKET_FEE = marketFee;
    }

    function _lockAddress(address lockAddress, uint64 lockTime) internal {
        require(lockAddress != address(0), "ERR: zero lock address");
        require(lockTime > 0, "ERR: zero lock period");
        require(_lockedList[lockAddress].endTime == 0, "ERR: already locked");
        if (lockAddress != _pair && lockAddress != UNISWAP_ROUTER &&
            lockAddress != _shoppingCart && lockAddress != address(this) &&
            lockAddress != owner()) {
            _lockedList[lockAddress].lockedPeriod = lockTime;
            _lockedList[lockAddress].endTime = uint64(block.timestamp) + lockTime;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}