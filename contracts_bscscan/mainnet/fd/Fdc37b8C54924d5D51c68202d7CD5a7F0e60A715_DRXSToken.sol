/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IBIP20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract DRXSToken is Context, IBIP20, Ownable {
    
	using SafeMath for uint256;
	using Address for address;
	mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludedFromReward;
	
	address[] private _excludedFromReward;
	address BURN_ADDRESS = 0x0000000000000000000000000000000000000001;
	address public _projectAddress;
	address public _charityAddress;
	address public _marketingAddress;
	uint256 private constant MAX = ~uint256(0);
	uint256 private _tTotal = 100000000000 * 10**18;
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tHODLrRewardsTotal;
	string private _name = "DRIVE XS";
	string private _symbol = "DRXS";
	uint8 private _decimals = 18;
	
	uint256 public _rewardFee = 1;
	uint256 private _previousRewardFee = _rewardFee;
	
	uint256 public _charityFee = 1;
	uint256 private _previousCharityFee = _charityFee;
	
	uint256 public _burnFee = 1;
	uint256 private _previousBurnFee = _burnFee;
	
	uint256 public _marketingFee = 1;
	uint256 private _previousMarketingFee = _marketingFee;
	
	uint256 public _projectFee = 4; 
	uint256 private _previousProjectFee = _projectFee;
	
	IUniswapV2Router02 public immutable uniswapV2Router;
	address public immutable uniswapV2Pair;
	uint256 public _maxTxAmount = 10000000 * 10**18;
	constructor ( address initialProjectAddress, address initialCharityAddress, address initialMarketingAddress ) {
	    require(
            initialProjectAddress != address(0),
            "Address should not be 0x00"
        );
        require(
            initialMarketingAddress != address(0),
            "Address should not be 0x00"
        );
        require(
            initialCharityAddress != address(0),
            "Address should not be 0x00"
        );
        
		_rOwned[_msgSender()] = _rTotal;
		
		_projectAddress = initialProjectAddress;
		_charityAddress = initialCharityAddress;
		_marketingAddress = initialMarketingAddress;		
	
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);		// BSC PANCAKE Router V2
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;
            
		_isExcludedFromReward[address(this)] = true;
		_isExcludedFromReward[BURN_ADDRESS] = true;
		
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[BURN_ADDRESS] = true;
		_isExcludedFromFee[_charityAddress] = true;
		_isExcludedFromFee[_marketingAddress] = true;
		_isExcludedFromFee[_projectAddress] = true;
		emit Transfer(address(0), _msgSender(), _tTotal);
	}
	function name() public view returns (string memory) {return _name;}
	function symbol() public view returns (string memory) {return _symbol;}
	function decimals() public view returns (uint8) {return _decimals;}
	function totalSupply() public view override returns (uint256) {return _tTotal;}
	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcludedFromReward[account]) return _tOwned[account];
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
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BIP20: transfer amount exceeds allowance"));
		return true;
	}
	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}
	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BIP20: decreased allowance below zero"));
		return true;
	}
	function totalHODLrRewards() public view returns (uint256) {
		return _tHODLrRewardsTotal;
	}
	function totalBurned() public view returns (uint256) {
		return balanceOf(BURN_ADDRESS);
	}
	
	function totalProject() public view returns (uint256) {
		return balanceOf(_projectAddress);
	}
	
	function totalCharity() public view returns (uint256) {
		return balanceOf(_charityAddress);
	}
	
	function totalMarketing() public view returns (uint256) {
	    return balanceOf(_marketingAddress);
	}
	function deliver(uint256 tAmount) public {
		address sender = _msgSender();
		require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
		(uint256 rAmount,,,,,,,,) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rTotal = _rTotal.sub(rAmount);
		_tHODLrRewardsTotal = _tHODLrRewardsTotal.add(tAmount);
	}
	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
		require(tAmount <= _tTotal, "Amount must be less than supply");
		if (!deductTransferFee) {
			(uint256 rAmount,,,,,,,,) = _getValues(tAmount);
			return rAmount;
		} else {
			(,uint256 rTransferAmount,,,,,,,) = _getValues(tAmount);
			return rTransferAmount;
		}
	}
	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _rTotal, "Amount must be less than total reflections");
		uint256 currentRate =  _getRate();
		return rAmount.div(currentRate);
	}
	function isExcludedFromReward(address account) public view returns (bool) {
		return _isExcludedFromReward[account];
	}
	function excludeFromReward(address account) public onlyOwner {
		require(!_isExcludedFromReward[account], "Account is already excluded");
		if(_rOwned[account] > 0) {
			_tOwned[account] = tokenFromReflection(_rOwned[account]);
		}
		_isExcludedFromReward[account] = true;
		_excludedFromReward.push(account);
	}
	function includeInReward(address account) external onlyOwner {
		require(_isExcludedFromReward[account], "Account is already excluded");
		for (uint256 i = 0; i < _excludedFromReward.length; i++) {
			if (_excludedFromReward[i] == account) {
				_excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
				_tOwned[account] = 0;
				_isExcludedFromReward[account] = false;
				_excludedFromReward.pop();
				break;
			}
		}
	}
	function excludeFromFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = true;
	}
	
	function includeInFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = false;
	}
	
	function setRewardFeePercent(uint256 rewardFee) external onlyOwner {
		_rewardFee = rewardFee;
	}
	
	function setBurnFeePercent(uint256 burnFee) external onlyOwner {
		_burnFee = burnFee;
	}
	
	function setProjectFeePercent(uint256 projectFee) external onlyOwner {
		_projectFee = projectFee;
	}
	
	function setMarketingFeePercent(uint256 marketingFee) external onlyOwner {
		_marketingFee = marketingFee;
	}
	
	function setCharityFeePercent(uint256 charitytFee) external onlyOwner {
		_charityFee = charitytFee;
	}
	function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
		_maxTxAmount = _tTotal.mul(maxTxPercent).div(
			10**2
		);
	}
	
	function setMaxTx(uint256 _maxTx) external onlyOwner {
		_maxTxAmount = _maxTx * 10**18;
	}
	receive() external payable {}
	function _HODLrFee(uint256 rHODLrFee, uint256 tHODLrFee) private {
		_rTotal = _rTotal.sub(rHODLrFee);
		_tHODLrRewardsTotal = _tHODLrRewardsTotal.add(tHODLrFee);
	}
	function _getValues(uint256 tAmount) 
	private view returns (
	
	    uint256 rAmount, 
	    uint256 rTransferAmount, 
	    uint256 rReward, 
	    uint256 tTransferAmount, 
	    uint256 tReward, 
	    uint256 tProject, 
	    uint256 tBurn, 
	    uint256 tCharity,
	    uint256 tMarketing
	    
	    ) 
	{
		( tTransferAmount, tReward, tProject, tCharity, tBurn, tMarketing
		) = _getTValues(tAmount, tTransferAmount, tReward, tProject, tCharity, tBurn, tMarketing);
		
		( rAmount, rTransferAmount, rReward, tReward
		) =  _getRValues(tAmount, tReward, tProject, tBurn, tCharity, tMarketing,  _getRate());
		
		return (
		rAmount, 
		rTransferAmount, 
		rReward, 
		tTransferAmount, 
		tReward, 
		tProject,
		tBurn,
		tCharity,
		tMarketing);
	}
	function _getTValues(
	uint256 tAmount, 
	uint256 tTransferAmount,
	uint256 tReward, 
	uint256 tProject, 
	uint256 tBurn, 
	uint256 tCharity,
	uint256 tMarketing
	) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
	    
		tReward = calculateRewardFee(tAmount); 
		tProject = calculateProjectFee(tAmount);
		tBurn = calculateBurnFee(tAmount);
		tCharity = calculateCharityFee(tAmount);
		tMarketing = calculateMarketingFee(tAmount);
		tTransferAmount = tAmount.sub(tReward);
		tTransferAmount = tTransferAmount.sub(tBurn);
		tTransferAmount = tTransferAmount.sub(tCharity);
		tTransferAmount = tTransferAmount.sub(tProject);
		tTransferAmount = tTransferAmount.sub(tMarketing);
		
		return (tTransferAmount, tReward, tProject, tCharity, tBurn, tMarketing);
	}
	
	function _getRValues(
	uint256 tAmount, 
	uint256 tReward, 
	uint256 tProject, 
	uint256 tBurn, 
	uint256 tCharity,
	uint256 tMarketing,
	uint256 currentRate
	) private pure returns (
	    uint256 rAmount, 
	    uint256 rTransferAmount, 
	    uint256 rReward, uint256) {
	    
		rAmount = tAmount.mul(currentRate);
        rReward = tReward.mul(currentRate);
        rTransferAmount = rAmount.sub(rReward);
		rTransferAmount = rTransferAmount.sub(tBurn.mul(currentRate));
		rTransferAmount = rTransferAmount.sub(tCharity.mul(currentRate));
		rTransferAmount = rTransferAmount.sub(tProject.mul(currentRate));
		rTransferAmount = rTransferAmount.sub(tMarketing.mul(currentRate));
		
		return (rAmount, rTransferAmount, rReward, tReward);
	}
	function _getRate() private view returns(uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}
	function _getCurrentSupply() private view returns(uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;
		for (uint256 i = 0; i < _excludedFromReward.length; i++) {
			if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) 
			return (_rTotal, _tTotal);
			rSupply = rSupply.sub(_rOwned[_excludedFromReward[i]]);
			tSupply = tSupply.sub(_tOwned[_excludedFromReward[i]]);
		}
		if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}
	function calculateRewardFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_rewardFee).div(
			10**2
		);
	}
	
	function calculateBurnFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_burnFee).div(
			10**2
		);
	}
	
	function calculateCharityFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_charityFee).div(
			10**2
		);
	}
	
	function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_marketingFee).div(
			10**2
		);
	}
	
	function calculateProjectFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_projectFee).div(
			10**2
		);
	}
	
	function removeAllFee() private {
		if(_rewardFee == 0 && _burnFee == 0 && _projectFee == 0 && _charityFee == 0 && _marketingFee == 0) return;		
		_previousRewardFee = _rewardFee;
		_previousBurnFee = _burnFee;
		_previousProjectFee = _projectFee;
		_previousCharityFee = _charityFee;
		_previousMarketingFee = _marketingFee;
		_rewardFee = 0;
		_burnFee = 0;
		_projectFee = 0;
		_charityFee = 0;
		_marketingFee = 0;
	}
	
	function restoreAllFee() private {
		_rewardFee = _previousRewardFee;
		_burnFee = _previousBurnFee;
		_projectFee = _previousProjectFee;
		_charityFee = _previousCharityFee;
		_marketingFee = _previousMarketingFee;
	}
	
	function isExcludedFromFee(address account) public view returns(bool) {
		return _isExcludedFromFee[account];
	}
	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "BIP20: approve from the zero address");
		require(spender != address(0), "BIP20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
	function _transfer(
		address from,
		address to,
		uint256 amount
	) private {
		require(from != address(0), "BIP20: transfer from the zero address");
		require(to != address(0), "BIP20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		if(from != owner() && to != owner())
			require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
		bool takeFee = true;
		if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
			takeFee = false;
		}
		_tokenTransfer(from,to,amount,takeFee);
	}
	
	function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
		if(!takeFee)
			removeAllFee();		
		if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
			_transferFromExcluded(sender, recipient, amount);
		} else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
			_transferToExcluded(sender, recipient, amount);
		} else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
			_transferStandard(sender, recipient, amount);
		} else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
			_transferBothExcluded(sender, recipient, amount);
		} else {
			_transferStandard(sender, recipient, amount);
		}		
		if(!takeFee)
			restoreAllFee();
	}
	function _transferBurn(address sender, uint256 tBurn) private {
		uint256 currentRate = _getRate();
		uint256 rBurn = tBurn.mul(currentRate);		
		_rOwned[BURN_ADDRESS] = _rOwned[BURN_ADDRESS].add(rBurn);
		if(_isExcludedFromReward[BURN_ADDRESS])
			_tOwned[BURN_ADDRESS] = _tOwned[BURN_ADDRESS].add(tBurn);
		emit Transfer(sender, BURN_ADDRESS, tBurn);
			
			
	}
	
	function _transferProject(address sender, uint256 tProject) private {
		uint256 currentRate = _getRate();
		uint256 rProject = tProject.mul(currentRate);		
		_rOwned[_projectAddress] = _rOwned[_projectAddress].add(rProject);
		if(_isExcludedFromReward[_projectAddress])
			_tOwned[_projectAddress] = _tOwned[_projectAddress].add(tProject);
		
		emit Transfer(sender, _projectAddress, tProject);
	}
	
	function _transferMarketing(address sender, uint256 tMarketing) private {
		uint256 currentRate = _getRate();
		uint256 rMarketing = tMarketing.mul(currentRate);		
		_rOwned[_marketingAddress] = _rOwned[_marketingAddress].add(rMarketing);
		if(_isExcludedFromReward[_marketingAddress])
			_tOwned[_marketingAddress] = _tOwned[_marketingAddress].add(tMarketing);
		
		emit Transfer(sender, _marketingAddress, tMarketing);
	}
	
	function _transferCharity(address sender, uint256 tCharity) private {
		uint256 currentRate = _getRate();
		uint256 rCharity = tCharity.mul(currentRate);		
		_rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
		if(_isExcludedFromReward[_charityAddress])
			_tOwned[_charityAddress] = _tOwned[_charityAddress].add(tCharity);
		
		emit Transfer(sender, _charityAddress, tCharity);
	}
	function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
		(
			uint256 rAmount,
			uint256 rTransferAmount,
			uint256 rReward,
			uint256 tTransferAmount,
			uint256 tReward,
			uint256 tProject,
			uint256 tBurn,
			uint256 tCharity,
			uint256 tMarketing) = _getValues(tAmount);
			
	    _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
    
		_transferBurn(sender, tBurn);
        _transferProject(sender, tProject);
        _transferCharity(sender, tCharity);
        _transferMarketing(sender, tMarketing);
		_HODLrFee(rReward, tReward);
		emit Transfer(sender, recipient, tTransferAmount);
	}
	
	function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
		(
	 	    uint256 rAmount,
			uint256 rTransferAmount,
			uint256 rReward,
			uint256 tTransferAmount,
			uint256 tReward,
			uint256 tProject,
			uint256 tBurn,
			uint256 tCharity,
			uint256 tMarketing) = _getValues(tAmount);
			
	    _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
    
		_transferBurn(sender, tBurn);
        _transferProject(sender, tProject);
        _transferCharity(sender, tCharity);
        _transferMarketing(sender, tMarketing);
		_HODLrFee(rReward, tReward);
		emit Transfer(sender, recipient, tTransferAmount);
	}
	
	function _transferStandard(address sender, address recipient, uint256 tAmount) 	private {
		(
	        uint256 rAmount,
			uint256 rTransferAmount,
			uint256 rReward,
			uint256 tTransferAmount,
			uint256 tReward,
			uint256 tProject,
			uint256 tBurn,
			uint256 tCharity,
			uint256 tMarketing) = _getValues(tAmount);
			
	    _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
		_transferBurn(sender, tBurn);
        _transferProject(sender, tProject);
        _transferCharity(sender, tCharity);
        _transferMarketing(sender, tMarketing);
		_HODLrFee(rReward, tReward);
		emit Transfer(sender, recipient, tTransferAmount);
	}
	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
		(
		   	uint256 rAmount,
			uint256 rTransferAmount,
			uint256 rReward,
			uint256 tTransferAmount,
			uint256 tReward,
			uint256 tProject,
			uint256 tBurn,
			uint256 tCharity,
			uint256 tMarketing) = _getValues(tAmount);
			
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);     
        
		_transferBurn(sender, tBurn);
        _transferProject(sender, tProject);
        _transferCharity(sender, tCharity);
        _transferMarketing(sender, tMarketing);
		_HODLrFee(rReward, tReward);
		emit Transfer(sender, recipient, tTransferAmount);
	}
}