/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface UNIV2Sync {
    function sync() external;
}

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


interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IWETH {
    function deposit() external payable;
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function withdraw(uint256 _amount) external;
}

// Since 0.8.0 not needed. Keeping for backwards compatibility and error messages.
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

contract Ownable is Context {
    address private _owner;
    address private _feeCollector;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CollectorTransferred(address indexed previousCollector, address indexed newCollector);

    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        _feeCollector = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
        emit CollectorTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function feeCollector() public view returns (address) {
        return _feeCollector;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    modifier onlyCollector() {
        require(_feeCollector == _msgSender() || _owner == _msgSender(), "Ownable: caller is not owner or fee collector");
        _;
    }
    //Keep opportunity to preserve fee collector
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        _feeCollector = newOwner;
    }

    function transferCollector(address newCollector) public virtual onlyCollector {
		//don't allow burning except 0xdead
        require(newCollector != address(0), "Ownable: new collector is the zero address");
        emit CollectorTransferred(_feeCollector, newCollector);
        _feeCollector = newCollector;
    }

}


/*
 * An {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract DeflationaryERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isIncludedInReward;
    mapping (address => uint256) private _lastWeiCheckpoint; //global weiRaised of last rewards calculation
    mapping (address => uint256) private _addrWeiWithdrawn; //sum of rewards withdrawn per address
    mapping (address => uint256) private _addrWeiRaised; //sum of already calculated rewards

    uint256 private _totalSupply;
    uint256 private _weiRaised; 
    uint256 private _weiWithdrawn;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint8 public txFee = 10; // total in %
    uint8 public txFeeOwner = 3; // to owner in liquidity payouts
    uint8 public maxWalletBalancePercent = 1; //Anti whale: Any wallet should not have more than 1% supply on receive
    address public uniswapPair;
	address public uniswapV2RouterAddr;
	address public uniswapV2wETHAddr;
    bool private inSwap;
    bool private inPay;

    event RewardAdded(address indexed to, uint256 value);

    
    constructor (string memory __name, string memory __symbol, uint8 __decimals)  {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        _isExcludedFromFee[address(this)] = true;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function weiRaised() external view  returns (uint256) {
        return _weiRaised;
    }
    function weiWithdrawn() external view  returns (uint256) {
        return _weiWithdrawn;
    }
    function weiPayoutsPending() public view  returns (uint256) {
		if(_weiRaised > _weiWithdrawn)
            return _weiRaised.sub(_weiWithdrawn);
		else
			return 0;
    }
    function weiRescuePending() public view  returns (uint256) {
		if(_weiRaised > _weiWithdrawn && address(this).balance > weiPayoutsPending())
            return address(this).balance.sub(_weiRaised.sub(_weiWithdrawn));
		else
			return 0;
    }
    function addrWeiRaised(address a) external view  returns (uint256) {
        return _addrWeiRaised[a];
    }
    function addrWeiWithdrawn(address a) external view  returns (uint256) {
        return _addrWeiWithdrawn[a];
    }
    function addrWeiPayoutPending(address a) public view  returns (uint256) {
		if (_addrWeiRaised[a] >= _addrWeiWithdrawn[a])
            return _addrWeiRaised[a].sub(_addrWeiWithdrawn[a]).add(_weiRaised.sub(_lastWeiCheckpoint[a]).mul(_balances[a]).div(_totalSupply));
	    else
			return 0;
    }
    function poolWeiPayoutsPending() external view  returns (uint256) {
        return addrWeiPayoutPending(uniswapPair);
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

	function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

	function getRouterForChain(uint256 chainId) public view returns (address) {
	    address ethDeterministicUniswapV2RouterAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
		if (chainId == 1) return ethDeterministicUniswapV2RouterAddr; //ETH mainnet v2
		if (chainId == 3) return ethDeterministicUniswapV2RouterAddr; //Ropsten testnet, v2
		if (chainId == 4) return ethDeterministicUniswapV2RouterAddr; //Rinkeby testnet, v2
		if (chainId == 69) return ethDeterministicUniswapV2RouterAddr; //Kovan testnet, v2
		if (chainId == 420) return ethDeterministicUniswapV2RouterAddr; //Goerli testnet, v2
		if (chainId == 56) return 0x10ED43C718714eb63d5aA57B78B54704E256024E; //BSC mainnet, v2
        return address(0);
		//address _uniswapV2RouterAddr=0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F; //BNB v1
		//address _uniswapV2RouterAddr=0x10ED43C718714eb63d5aA57B78B54704E256024E; //BNB v2
        //address _uniswapV2RouterAddr=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Ropsten
		//56 = BSC, 1 = ETH, 3 = Ropsten
    }

    // initialize yield features, get/create pool address
    function setSwapRouter() external  {
        require(uniswapV2RouterAddr == address(0), "Pool: Address immutable once set"); 
		uniswapV2RouterAddr = getRouterForChain(getChainID());
		require(uniswapV2RouterAddr!=address(0),'Swapping for this chain id is not implemeted');
        _isExcludedFromFee[uniswapV2RouterAddr] = true; //this will make liquidity removals less expensive
		uniswapV2wETHAddr = IUniswapV2Router(uniswapV2RouterAddr).WETH(); //this fails if no such method
        // Create a uniswap pair for this new token
        uniswapPair = IUniswapV2Factory(IUniswapV2Router(uniswapV2RouterAddr).factory())
            .getPair(address(this), uniswapV2wETHAddr);
        // do not create pair, the pair must exist and have at least 10% supply in liquidity so that swaps won't fail.
        require(uniswapPair != address(0),'Set a new pool and fund it with at least 2% supply');    
        require(balanceOf(uniswapPair) >= _totalSupply.div(50), "Pool: Pool not funded enough");
        //uniswapPair = IUniswapV2Factory(IUniswapV2Router(uniswapV2RouterAddr).factory())
        //    .createPair(address(this), uniswapV2wETHAddr);
    }

    // to caclulate the amounts for pool and collector after fees have been applied
    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    ) public view returns (uint256 transferToAmount, uint256 swapToWeiAmount) {
        // check if fees should apply to this transaction
		uint256 fee = amount.mul(txFee).div(100); //10%
        // calculate liquidity fees and amounts if any address is an active contract
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) 
			return (amount, 0);
        if (sender.isContract() || recipient.isContract()) {
			return (amount.sub(fee), fee);
        } else { // p2p 
			return (amount, 0);			
		}
    }


    function _transfer(address sender, address recipient, uint256 amount) internal  {
        if (amount == 0) {
		    swapBufferTokens();
			updateBalances(sender, recipient, amount);
		} else {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            //require(amount > 100, "amount below 100 base units, avoiding underflows");
            _beforeTokenTransfer(sender, recipient, amount);
    		if (inSwap || uniswapPair == address(0) || uniswapV2RouterAddr == address(0)) //feeless transfer before pool initialization and in liquify swap
    		{	//send full amount
    			updateBalances(sender, recipient, amount);
    		} else { 
                // calculate fees:
                (uint256 transferToAmount, uint256 swapToWeiAmount) = calculateAmountsAfterFee(sender, recipient, amount);
    			// 1: subtract collector fee and put it to swap queue
    			updateBalances(sender, address(this), swapToWeiAmount);
    			//any sell/liquify must occur before main transfer, but avoid that on buys or liquidity removals
    			if (sender != uniswapPair && sender != uniswapV2RouterAddr) // without this buying or removing liquidity to eth fails
    			    swapBufferTokens();
    			// 2: subtract net amount
    			updateBalances(sender, recipient, transferToAmount);
            }
		}
		if(!inPay) {
			inPay = true;
			_payRewards(sender);
			_payRewards(recipient);
			inPay = false;
		}
    }

    function bulkTransfer(address payable[] calldata addrs, uint256[] calldata amounts) external returns(bool) {
        for (uint256 i = 0; i < addrs.length; i++) {
            _transfer(_msgSender(), addrs[i], amounts[i]);
        }
        return true;
    }

    function bulkTransferFrom(address payable[] calldata addrsFrom, address payable[] calldata addrsTo, uint256[] calldata amounts) external returns(bool) {
        address _currentOwner = _msgSender();
        for (uint256 i = 0; i < addrsFrom.length; i++) {
           _currentOwner = addrsFrom[i];
           if (_currentOwner != _msgSender()) {
               _approve(_currentOwner, _msgSender(), _allowances[_currentOwner][_msgSender()].sub(amounts[i], "ERC20: some transfer amount in bulkTransferFrom exceeds allowance"));
           }
           _transfer(_currentOwner, addrsTo[i], amounts[i]);
        }
        return true;
    }

    //Allow excluding from fee certain contracts, usually lock or payment contracts, but not the router or the pool.
    function excludeFromFee(address account) external onlyOwner {
        require(account != uniswapPair, 'Cannot exclude Uniswap pair');
        _isExcludedFromFee[account] = true;
    }
    // Do not include back this contract.
    function includeInFee(address account) external onlyOwner {
        require(account != address(this),'Cannot enable fees to the token contract itself');
        _isExcludedFromFee[account] = false;
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _setRewardIncluded(address a,bool e) internal {
        updateRewards(a);
		_isIncludedInReward[a] = e;
	}

    //Allow excluding contracts from reward but they can include themselves if able to handle rewards.
    function excludeFromReward() external  {
        require (Address.isContract(_msgSender()),'Available for contracts only');
        _setRewardIncluded(_msgSender(),false);
    }

    function includeInReward() external  {
        _setRewardIncluded(_msgSender(),true);
    }
    
    function isIncludedInReward(address account) public view returns (bool) {
        if (Address.isContract(_msgSender()))
            return _isIncludedInReward[account];
        else
            return true;
    }

    function swapBufferTokens() public {
 		if (inSwap) // prevent reentrancy
			return;
        uint256 contractTokenBalance = balanceOf(address(this));
		if (contractTokenBalance <= _totalSupply.div(1e7)) //only swap reasonable amounts
			return;
		if (contractTokenBalance <= 100) //do not swap too small amounts
			return;
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // existed in the contract
        uint256 initialWeiBalance = address(this).balance;

        // swap tokens for ETH directly to the collector
        inSwap = true;
        swapTokensForWei(contractTokenBalance); // avoid reentrancy here
        inSwap = false;

        // how much ETH did we just swap into?
        uint256 weiBalanceFromSwap = address(this).balance.sub(initialWeiBalance);
        _weiRaised += weiBalanceFromSwap;
		
    }

    function swapTokensForWei(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2wETHAddr;

        _approve(address(this), uniswapV2RouterAddr, tokenAmount);

        // make the swap
        IUniswapV2Router(uniswapV2RouterAddr).swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

	function updateBalances(address _from, address _to, uint256 _amount) internal {
		// do nothing on self transfers and zero transfers, but update rewards at all times
		updateRewards(_from);
		updateRewards(_to);
		if (_from != _to && _amount > 0) {
			_balances[_from] = _balances[_from].sub(_amount, "ERC20: transfer amount exceeds balance");
			_balances[_to] = _balances[_to].add(_amount);
    		if (!_to.isContract() && _balances[_to] > _totalSupply.mul(maxWalletBalancePercent).div(100)) //anti whale
    		    revert("Recipient wallet would have more than max percentage of total supply");
			emit Transfer(_from, _to, _amount);
		}
	}

    function updateRewards(address a) public {
        //computes proportional rewards since _lastWeiCheckpoint
        //updates _lastWeiCheckpoint to _weiRaised
        //adds rewards to _addrWeiRaised
		uint256 r = _weiRaised.sub(_lastWeiCheckpoint[a]).mul(balanceOf(a)).div(_totalSupply);
        _lastWeiCheckpoint[a] = _weiRaised; 
		if (r > 0)
		{
		    _addrWeiRaised[a] += r;
		    emit RewardAdded(a,r);
		}
	}
    // make sure updateRewards has been called before
    function _payRewards(address a) internal {
		uint256 payout = _addrWeiRaised[a].sub(_addrWeiWithdrawn[a]);
		if (payout == 0 || payout > address(this).balance) { //the latter should never happen but if yes, prevent failure
            _addrWeiWithdrawn[a] = _addrWeiRaised[a];		
			_weiWithdrawn += payout;
			return;
		}			
	    if (!_isIncludedInReward[a] && a.isContract()) { // pays out virtually only and add to liquidity pool rewards
		    _addrWeiRaised[a] = _addrWeiWithdrawn[a]; //reverts the reward
			_addrWeiRaised[uniswapPair] += payout; //adds it to the pool
		} else { //pays out really
		    _addrWeiWithdrawn[a] = _addrWeiRaised[a];
			_weiWithdrawn += payout;
			payable(a).transfer(payout);
		}
	}

    function payRewardsToPool() public {
		uint256 payout = _addrWeiRaised[uniswapPair].sub(_addrWeiWithdrawn[uniswapPair]);
		uint256 payoutToTeam = payout.mul(txFeeOwner).div(10);
	    _addrWeiWithdrawn[uniswapPair] = _addrWeiRaised[uniswapPair];
		_weiWithdrawn += payout;
		if (payout == 0 || payout > address(this).balance) //the latter should never happen but if yes, prevent failure
			return;
        IWETH(uniswapV2wETHAddr).deposit{value : payout}();
        uint256 amountWETH =  IWETH(uniswapV2wETHAddr).balanceOf(address(this));
        //Sends weth it finds to liquidity pool
        IWETH(uniswapV2wETHAddr).transfer(uniswapPair, amountWETH.sub(payoutToTeam));
        IWETH(uniswapV2wETHAddr).transfer(feeCollector(), payoutToTeam);
		UNIV2Sync(uniswapPair).sync(); 
	}
	
	function payRewards() external {
		if (inPay)
			return;
		inPay = true;
		address a = _msgSender();
		swapBufferTokens();
		updateRewards(a);
		updateRewards(uniswapPair);
		_payRewards(a);
		payRewardsToPool();
		inPay = false;
	}

    function _mint(address account, uint256 amount) internal  {
        require(_totalSupply == 0, "Mint: Not an initial supply mint");
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        if(amount > 0) {
            _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
            _totalSupply = _totalSupply.sub(amount);
            emit Transfer(account, address(0), amount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal  {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * Hook that is called before any transfer of tokens. This includes minting and burning.
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal  { }
    
    //sennding ether to this contract must succeed in order to collect BNB
    receive() external payable {
       //revert();
    }

	
    // This will allow to rescue BNB sent by mistake directly to the contract
    function rescueWeiFromContract() external onlyCollector {
        address payable s = _msgSender();
        //s.transfer(address(this).balance);
		//BNB rescue is allowed only on top of weiRaised-weiWithdrawn
        uint256 balanceWei = address(this).balance;
		uint256 lockedWei = _weiRaised.sub(_weiWithdrawn);
		uint256 freeWei = balanceWei.sub(lockedWei);
        s.transfer(freeWei);
    }

    // Function to allow admin to claim *other* tokens sent to this contract (by mistake)
    // Owner cannot transfer out BNB Yield tokens from this smart contract
    function transferAnyTokens(address _tokenAddr, address _to, uint _amount) external onlyCollector {
        require(_tokenAddr != address(this), "Cannot transfer out from swap queue!");
        IERC20(_tokenAddr).transfer(_to, _amount);
    }
}

contract TestToken02 is DeflationaryERC20 {
    constructor()  DeflationaryERC20("TestToken02", "TTO02", 0) {
        // maximum supply   = 100B with decimals = 0
        _mint(msg.sender, 100e9);
    }
}