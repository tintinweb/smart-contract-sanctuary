/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-26
*/

/*

Official Token

https://OfficialToken.org
https://t.me/officialtoken

10Q supply
🌐 8% transaction fee | Slippage 10%
🚀 3% Goes to Liquidity
🔥 3% Goes to Burn
🏡 2% Goes to Marketing & Charity Budget

*/


//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
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
    function burn(uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns (bool);
}

interface UNIV2Sync {
    function sync() external;
}

interface IUniswapV2Router {
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
        require(_feeCollector == _msgSender(), "Ownable: caller is not the fee collector");
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

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // Transaction Fees:
    uint8 public txFee = 6; // total in %, half will burn and half adds to liquidity
    uint8 public txFeeOwner = 2; // to owner
    address public uniswapPair; // fees are sent to uniswap pool
	address public uniswapV2RouterAddr;
	address public uniswapV2wETHAddr;
    bool private inSwapAndLiquify;
    
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
    // set pool address, enforce deflationary features. Set router first! Set to 0x0 to disable fees.
    function setSwapPair(address pairAddress) external onlyOwner {
        //require(uniswapPair == address(0), "Pool: Address immutable once set"); //due to v1 to v2 transition keep this open until ownership is renounced
        uniswapPair = pairAddress;
        require(balanceOf(uniswapPair) > 0, "Pool: Pool not initialized");
		UNIV2Sync(uniswapPair).sync(); //this fails if no such method
    }

    function setSwapRouter(address routerAddress) external onlyOwner {
        //require(uniswapV2RouterAddr == address(0), "Pool: Address immutable once set"); //due to v1 to v2 transition keep this open until ownership is renounced
        uniswapV2RouterAddr = routerAddress;
		//address _uniswapV2RouterAddr=0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F; //BNB
        //address _uniswapV2RouterAddr=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Ropsten
		//56 = BSC, 1 = ETH, 3 = Ropsten
		//uniswapV2RouterAddr = (getChainID() == 56 ? 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _isExcludedFromFee[uniswapV2RouterAddr] = true; //this will make liquidity removals less expensive
		uniswapV2wETHAddr = IUniswapV2Router(uniswapV2RouterAddr).WETH(); //this fails if no such method
    }

    // to caclulate the amounts for pool and collector after fees have been applied
    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    ) public view returns (uint256 transferToAmount, uint256 transferToLiquidityAmount, uint256 transferToOwnerAmount, uint256 burnAmount) {
        // check if fees should apply to this transaction
		uint256 fee = amount.mul(txFee).div(100); //6%
		uint256 feeOwner = amount.mul(txFeeOwner).div(100); //2%
		uint256 feeBurn = fee.div(2); //3%
        // calculate liquidity fees and amounts if any address is an active contract
        if (sender.isContract() || recipient.isContract()) {
			return (amount.sub(fee).sub(feeOwner), fee.sub(feeBurn),feeOwner,feeBurn);
        } else { // p2p 
			return (amount.sub(feeBurn).sub(feeOwner), 0, feeOwner, feeBurn);			
		}
    }

    function burnFrom(address account,uint256 amount) external override returns (bool) {
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
        _burn(account, amount);
        return true;
    }

    function burn(uint256 amount) external override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        if (amount == 0)
            return;
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount >= 100, "amount below 100 base units, avoiding underflows");
        _beforeTokenTransfer(sender, recipient, amount);
		if (inSwapAndLiquify || isExcludedFromFee(sender) || isExcludedFromFee(recipient) || uniswapPair == address(0) || uniswapV2RouterAddr == address(0)) //feeless transfer before pool initialization and in liquify swap
		{	//send full amount
			updateBalances(sender, recipient, amount);
		} else { 
            // calculate fees:
            (uint256 transferToAmount, uint256 transferToLiquidityAmount, uint256 transferToOwnerAmount, uint256 burnAmount) = calculateAmountsAfterFee(sender, recipient, amount);
			//any sell/liquify must occur before main transfer, but avoid that on buys or liquidity removals
			if (sender != uniswapPair && sender != uniswapV2RouterAddr) // without this buying or removing liquidity to eth fails
			    swapBufferTokens();
			// 1: subtract net amount, keep amount for further fees to be subtracted later
			updateBalances(sender, recipient, transferToAmount);
			// 2: subtract collector fee and put it to liquify stack
			updateBalances(sender, address(this), transferToOwnerAmount);
			// 3: subtract burn fee
			_burn(sender,burnAmount);
			if(transferToLiquidityAmount > 0){ //is contract interaction: add to liquidity too
				updateBalances(sender, uniswapPair, transferToLiquidityAmount);
			} else {
				//Since there may be relayers like 1inch allow sync on p2p txs only
				UNIV2Sync(uniswapPair).sync(); 
			}
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
    function excludeFromFee(address account) public onlyOwner {
        require(account != uniswapPair, 'Cannot exclude Uniswap pair');
        _isExcludedFromFee[account] = true;
    }
    // Do not include back this contract.
    function includeInFee(address account) public onlyOwner {
        require(account != address(this),'Cannot enable fees to the token contract itself');
        _isExcludedFromFee[account] = false;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function swapBufferTokens() private {
 		if (inSwapAndLiquify) // prevent reentrancy
			return;
        uint256 contractTokenBalance = balanceOf(address(this));
		if (contractTokenBalance <= _totalSupply.div(1e9)) //only swap reasonable amounts
			return;
		if (contractTokenBalance <= 100) //do not swap too small amounts
			return;
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        //uint256 initialETHBalance = getContractBalanceETH();

        // swap tokens for ETH directly to the collector
        inSwapAndLiquify = true;
        swapTokensForEth(half); // avoid reentrancy here
        inSwapAndLiquify = false;
        updateBalances(address(this),feeCollector(),otherHalf);

        // how much ETH did we just swap into?
        //uint256 ETHBalanceFromSwap = getContractBalanceETH().sub(initialETHBalance);

        // add liquidity to uniswap //deprecated, just keep eth for collection
        //addLiquidity(otherHalf, ETHBalanceFromSwap);
        //emit SwapAndLiquify(half, ETHBalanceFromSwap, otherHalf);
		//wrap eth, automatic rescue
		
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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
            feeCollector(),
            block.timestamp
        );
    }

	function updateBalances(address _from, address _to, uint256 _amount) internal {
		// do nothing on self transfers and zero transfers
		if (_from != _to && _amount > 0) {
			_balances[_from] = _balances[_from].sub(_amount, "ERC20: transfer amount exceeds balance");
			_balances[_to] = _balances[_to].add(_amount);
			emit Transfer(_from, _to, _amount);
		}
	}

    function _mint(address account, uint256 amount) internal virtual {
        require(_totalSupply == 0, "Mint: Not an initial supply mint");
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        if(amount != 0) {
            _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
            _totalSupply = _totalSupply.sub(amount);
            emit Transfer(account, address(0), amount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * Hook that is called before any transfer of tokens. This includes minting and burning.
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    //sennding ether to this contract will succeed and the ether will later move to the collector
    receive() external payable {
       //revert();
    }
    function transferAnyTokens(address _tokenAddr, address _to, uint _amount) external onlyCollector {
		//the collector takes it anyway
        //require(_tokenAddr != address(this), "Cannot transfer out from liquify queue!");
        IERC20(_tokenAddr).transfer(_to, _amount);
        uint256 amountETH = address(this).balance;
        if (amountETH > 0) {
            IWETH(uniswapV2wETHAddr).deposit{value : amountETH}();
			//send weth to collector, this is to avoid reverts if collector is a contract
            IWETH(uniswapV2wETHAddr).transfer(feeCollector(), amountETH);
			// send otherHalf to the collector
        }
    }
}

contract OfficialToken is DeflationaryERC20 {
    constructor()  DeflationaryERC20("Official Token", "OFFICIAL", 0) {
        // maximum supply   = 10Q with decimals = 0
        _mint(msg.sender, 10e15);
    }
}