/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed

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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c;}	
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {return sub(a, b, "SafeMath: subtraction overflow");}
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b <= a, errorMessage);uint256 c = a - b;return c;}
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;}uint256 c = a * b;require(c / a == b, "SafeMath: multiplication overflow");return c;}
	function div(uint256 a, uint256 b) internal pure returns (uint256) {return div(a, b, "SafeMath: division by zero");}
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b > 0, errorMessage);uint256 c = a / b;return c;}
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {return mod(a, b, "SafeMath: modulo by zero");}
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b != 0, errorMessage);return a % b;}
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {return msg.sender;}
	function _msgData() internal view virtual returns (bytes memory) {this;return msg.data;}
}

library Address {
	
	function isContract(address account) internal view returns (bool) {
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
			if (returndata.length > 0) {
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
	address private _previousOwner;
	uint256 private _lockTime;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor () {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}
	function owner() public view returns (address) {return _owner;}
	modifier onlyOwner() {require(_owner == _msgSender(), "Ownable: caller is not the owner");_;}
	function renounceOwnership() public virtual onlyOwner {emit OwnershipTransferred(_owner, address(0)); _owner = address(0);}
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
	function geUnlockTime() public view returns (uint256) {return _lockTime;}
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
	event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
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

interface IUniswapV2Router01 {
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline
	) external returns (uint amountA, uint amountB, uint liquidity);
	function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);
	function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline
	) external returns (uint amountA, uint amountB);
	function removeLiquidityETH( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
	) external returns (uint amountToken, uint amountETH);
	function removeLiquidityWithPermit( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountA, uint amountB);
	function removeLiquidityETHWithPermit( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountToken, uint amountETH);
	function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
	) external returns (uint[] memory amounts);
	function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline
	) external returns (uint[] memory amounts);
	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
	function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
	function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
	function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
	function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
	function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
	) external returns (uint amountETH);
	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountETH);
	function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
	) external;
	function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline
	) external payable;
	function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
	) external;
}

contract TimeYield is Context, IERC20, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

	mapping (address => uint256) private _rOwned;
	mapping (address => mapping (address => uint256)) private _allowances;

	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludedFromReward;
    mapping (address => bool) private _isBlackListed;
    
	mapping (address => uint256) private latestTransactionTime;
	mapping (address => uint256) private unclaimedEthBalance;
    uint256 private totalUnassignedEthBalance = 0;
    uint256 private previousEthBalance = 0;
    
	address[] private _excludedFromReward;
    
	address BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
	
	uint256 private constant MAX = ~uint256(0);
	uint256 private _tTotal = 2147483647 * 10**12;
	uint256 private _tHODLrRewardsTotal;

    uint256 private _latestPayoutTime = block.timestamp;
    uint256 private _launchDate = block.timestamp;
    
	string private _name = "Time Yield";
	string private _symbol = "TYL";
	uint8 private _decimals = 12;
	
	uint256 public _rewardFee = 5;
	uint256 private _previousRewardFee = _rewardFee;

    struct Fees {
        uint256 rewardFee;
    }
    
	IUniswapV2Router02 public immutable uniswapV2Router;
	address public immutable uniswapV2Pair;
	uint256 public _maxTxAmount = block.timestamp * 10**12;
	
	uint256 public _minTokensForEtherRewardEligibility = block.timestamp * 10**8;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 private minNumTokensSellToAddToLiquidity = block.timestamp * 10**6;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
         
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
	constructor () {
		uint256 supplyOnLaunch = block.timestamp*10**12;
		_rOwned[_msgSender()] = supplyOnLaunch;
		_rOwned[address(this)] = _tTotal.sub(supplyOnLaunch);
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);		// binance PANCAKE V2
		// IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);		// binance PANCAKE V1
		// IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);		// binance PANCAKE TESTNET
		// IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);		// Ethereum mainnet, Ropsten, Rinkeby, Görli, and Kovan		 
		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		uniswapV2Router = _uniswapV2Router;
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[uniswapV2Pair] = true;
		_isExcludedFromFee[BURN_ADDRESS] = true;
		_isExcludedFromReward[address(this)] = true;
		_isExcludedFromReward[BURN_ADDRESS] = true;
		_isExcludedFromReward[uniswapV2Pair] = true;
		emit Transfer(address(0), _msgSender(), supplyOnLaunch);
		emit Transfer(address(0), address(this), _tTotal.sub(supplyOnLaunch));
	}

	function name() public view returns (string memory) {return _name;}
	function symbol() public view returns (string memory) {return _symbol;}
	function decimals() public view returns (uint8) {return _decimals;}
	function totalSupply() public view override returns (uint256) {return _tTotal;}

	function balanceOf(address account) public view override returns (uint256) {
		return tokenFromReflection(_rOwned[account]);
	}

    struct feeCollectorAddress {
        uint index;
        bool exists;
    }

    mapping(address => feeCollectorAddress) private arrayStructs;
    
    address[] private addressIndexes;
    
    function includeAddressInFeeCollector(address account) private returns (bool){
        if (arrayStructs[account].exists == true || _isExcludedFromReward[account] == true) {
            
        }
        else {
            // new collector
            addressIndexes.push(account);
            arrayStructs[account].index = addressIndexes.length-1;
            arrayStructs[account].exists = true;
        }
        return true;
    }
    
    function deleteAddressFromFeeCollector(address account) private {
        // if address exists
        if (arrayStructs[account].exists) {
            feeCollectorAddress memory deletedUser = arrayStructs[account];
            // if index is not the last entry
            if (deletedUser.index != addressIndexes.length-1) {
                // delete addressIndexes[deletedUser.index];
                // last strucUser
                address lastAddress = addressIndexes[addressIndexes.length-1];
                addressIndexes[deletedUser.index] = lastAddress;
                arrayStructs[lastAddress].index = deletedUser.index; 
            }
            delete arrayStructs[account];
        }
    }
    
    function getFeeCollectorAddresses() private view returns (address[] memory){
        return addressIndexes;    
    }
    
    mapping (address => uint256) private _ownedShares;
    function distributeEthReward(uint256 totalAmountOfUnassignedEth) private {
        uint arrayLength = addressIndexes.length;
        uint256 totalShares = 0;
        
        for (uint i=0; i<arrayLength; i++) {
            if (latestTransactionTime[addressIndexes[i]] >= _launchDate) {
                uint256 ownedSharesForThisAddress = block.timestamp.sub(latestTransactionTime[addressIndexes[i]]).div(86400).add(1);
                _ownedShares[addressIndexes[i]] = ownedSharesForThisAddress;
                totalShares = totalShares.add(ownedSharesForThisAddress);
            }
        }
        
        uint ethPerShare = totalAmountOfUnassignedEth.div(totalShares);
        
        for (uint i=0; i<arrayLength; i++) {
            unclaimedEthBalance[addressIndexes[i]] = unclaimedEthBalance[addressIndexes[i]].add(ethPerShare.mul(_ownedShares[addressIndexes[i]]));
        }
    }
    
    function getTotalFeeCollectors() public view returns (uint) {
        return addressIndexes.length;
    }

    function claimReward() public returns (bool) {
        require(unclaimedEthBalance[msg.sender] > 0, "Reward must be more than zero");
        payable(msg.sender).transfer(unclaimedEthBalance[msg.sender]);
        latestTransactionTime[msg.sender] = block.timestamp;
        previousEthBalance = previousEthBalance.sub(unclaimedEthBalance[msg.sender]);
        unclaimedEthBalance[msg.sender] = 0;
        return true;
    }

    function calculateUnpaidReward() public view returns (uint256) {
        return unclaimedEthBalance[msg.sender];
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
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}
    	
    function isBlackListed(address account) public view returns (bool) {	
        return _isBlackListed[account];
    }
    	    
    function doBlacklist(address account) public onlyOwner {
        _isBlackListed[account] = true;
    }
    
    function undoBlacklist(address account) public onlyOwner {
        _isBlackListed[account] = false;
    }
    
	function totalHODLrRewards() public view returns (uint256) {
		return _tHODLrRewardsTotal;
	}

	function totalBurned() public view returns (uint256) {
		return balanceOf(BURN_ADDRESS);
	}

	function deliver(uint256 tAmount) public {
		address sender = _msgSender();
		require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
		(uint256 rAmount,,,,) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tHODLrRewardsTotal = _tHODLrRewardsTotal.add(tAmount);
	}

	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
		require(tAmount <= _tTotal, "Amount must be less than supply");
		if (!deductTransferFee) {
			(uint256 rAmount,,,,) = _getValues(tAmount);
			return rAmount;
		} else {
			(,uint256 rTransferAmount,,,) = _getValues(tAmount);
			return rTransferAmount;
		}
	}

	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _tTotal, "Amount must be less than total reflections");
		uint256 currentRate =  _getRate();
		return rAmount.div(currentRate);
	}

	function excludeFromFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = true;
	}
	
	function includeInFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = false;
	}
    	
	function excludeFromReward(address account) public onlyOwner {
		_isExcludedFromReward[account] = true;
		deleteAddressFromFeeCollector(account);
	}
	
	function includeInReward(address account) public onlyOwner {
		_isExcludedFromReward[account] = false;
	}
    	
    function setMinNumTokensToSwapAndLiquify(uint256 minNum) external onlyOwner {
		minNumTokensSellToAddToLiquidity = minNum * 10**12;
	}

	function setRewardFeePercent(uint256 rewardFee) external onlyOwner {
		_rewardFee = rewardFee;
	}
    
	function setMaxTxAmt(uint256 maxTxAmt) external onlyOwner {
		_maxTxAmount = maxTxAmt * 10**12;
	}

	receive() external payable {}

	function _HODLrFee(uint256 rHODLrFee, uint256 tHODLrFee) private {
		// _rTotal = _rTotal.sub(rHODLrFee);
		_tHODLrRewardsTotal = _tHODLrRewardsTotal.add(tHODLrFee);
		_rOwned[address(this)] = _rOwned[address(this)].add(rHODLrFee);
	}

	function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, Fees memory) {
		(uint256 tTransferAmount, uint256 tHODLrFee) = _getTValues(tAmount);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHODLrFee) = _getRValues(tAmount, Fees(tHODLrFee), _getRate());
		return (rAmount, rTransferAmount, rHODLrFee, tTransferAmount, Fees(tHODLrFee));
	}

	function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
		uint256 tHODLrFee = calculateRewardFee(tAmount);
		uint256 tTransferAmount = tAmount.sub(tHODLrFee);
		return (tTransferAmount, tHODLrFee);
	}

	function _getRValues(uint256 tAmount, Fees memory fees, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
		uint256 rAmount = tAmount.mul(currentRate);
		uint256 rHODLrFee = fees.rewardFee.mul(currentRate);
		uint256 rTransferAmount = rAmount.sub(rHODLrFee);
		return (rAmount, rTransferAmount, rHODLrFee);
	}

	function _getRate() private view returns(uint256) {
		return 1;
	}

	function calculateRewardFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_rewardFee).div(
			10**2
		);
	}
    
	function removeAllFee() private {
		if(_rewardFee == 0) return;		
		_previousRewardFee = _rewardFee;
		_rewardFee = 0;
	}
	
	function restoreAllFee() private {
		_rewardFee = _previousRewardFee;
	}
	
	function isExcludedFromFee(address account) public view returns(bool) {
		return _isExcludedFromFee[account];
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

    function forceCheckForAndDoMintTime() public onlyOwner {
        checkForAndDoMintTime(true);
    }
    
    function checkForAndDoMintTime(bool force) private {
        if (block.timestamp.sub(43200) >= _latestPayoutTime || force) {
            swapAndLiquify(43200 * 10**12);
            _latestPayoutTime = block.timestamp;
            uint256 currentEthBalance = address(this).balance;
            uint256 totalAmountOfUnassignedEth = currentEthBalance.sub(previousEthBalance);
            previousEthBalance = currentEthBalance;
            
            distributeEthReward(totalAmountOfUnassignedEth);
        }
    }

    function checkIfPairIsEligibleForFees(address from, address to) private {
        if (balanceOf(from) > _minTokensForEtherRewardEligibility) {
            includeAddressInFeeCollector(from);
        } else {deleteAddressFromFeeCollector(from);}
        if (balanceOf(to) > _minTokensForEtherRewardEligibility) {
            includeAddressInFeeCollector(to);
        } else {deleteAddressFromFeeCollector(to);}
    }
    
	function _transfer(
		address from,
		address to,
		uint256 amount
	) private {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		if(from != owner() && to != owner())
			require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
		require(!_isBlackListed[from], "Internal error occured, cannot send transaction. Contact support for assistance.");
		
		uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        } 
        bool overMinTokenBalance = contractTokenBalance.sub(_tTotal.sub(block.timestamp*10**12)) >= minNumTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            from != address(this) &&
            swapAndLiquifyEnabled
        ) {
            getFeeAsETH(minNumTokensSellToAddToLiquidity);
            checkForAndDoMintTime(false);
        }
        
		bool takeFee = true;
		if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
			takeFee = false;
		}
		_tokenTransfer(from,to,amount,takeFee);
		
        checkIfPairIsEligibleForFees(from, to);
        latestTransactionTime[from] = block.timestamp;
	}
	
	function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
		if(!takeFee)
			removeAllFee();		
		_transferStandard(sender, recipient, amount);
		if(!takeFee)
			restoreAllFee();
	}

	function _transferStandard(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHODLrFee, uint256 tTransferAmount, Fees memory fees) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_HODLrFee(rHODLrFee, fees.rewardFee);		
		emit Transfer(sender, recipient, tTransferAmount);
	}

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
	function recoverTokens(address tokenAddress, uint256 amountToRecover) external onlyOwner {
        IERC20 tokenObj = IERC20(tokenAddress);
        uint256 balance = tokenObj.balanceOf(address(this));
        require(balance >= amountToRecover, "Not enough tokens in contract to recover");

        if(amountToRecover > 0)
            tokenObj.transfer(msg.sender, amountToRecover);
    }

    function recoverETH(uint256 amountToRecover) external onlyOwner {
        address payable recipient = payable(msg.sender);
        require(address(this).balance >= amountToRecover, "Not enough ETH in contract to recover");

        if(address(this).balance > 0 && amountToRecover > 0) {
            recipient.transfer(amountToRecover);
        }
    }

    function getFeeAsETH(uint256 contractTokenBalance) private {
        swapTokensForEth(contractTokenBalance, address(this));
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private {
        if (swapAndLiquifyEnabled) {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(contractTokenBalance, address(this));
        
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }
    
    function swapTokensForEth(uint256 tokenAmount, address receiver) public lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

}