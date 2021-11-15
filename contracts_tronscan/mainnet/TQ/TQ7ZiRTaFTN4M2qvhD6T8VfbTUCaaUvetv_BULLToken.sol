//SourceUnit: TestBull.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
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

interface ITRC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
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
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }

}

contract BULLToken is Context, ITRC20, Ownable {
    using SafeMath for uint256;
	using Address for address;
	
    mapping (address => uint256) private _balances;
	
	mapping (address => mapping (address => uint256)) private _allowances;
	
	struct Liquidity {
        bool flag; 
        uint256 lpAmout; 
        uint256 lastTime; 
    }
    mapping(address => Liquidity) public LiquidityOrder;
	
	ITRC20 public _exchangePool;
	
	
	address public lpPoolAddress;
	
	uint256 private lpFeeAmount=0;
	
	uint256 private lpTotalAmount=0;
	
    string private _name = 'BULL';
    string private _symbol = 'BULL';
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 10000000 * 10**uint256(_decimals);

    uint256 public _liquidityFee = 15;
    uint256 private _previousLiquidityFee = _liquidityFee;

    mapping(address => bool) private _isExcludedFee;

    constructor () public {
        _isExcludedFee[owner()] = true;
        _isExcludedFee[address(this)] = true;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    receive () external payable {}
    
    function name() public view virtual returns (string memory) {
        return _name;
    }


    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

 
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

  
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

  
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance.sub(amount));

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function excludeFee(address account) public onlyOwner {
        _isExcludedFee[account] = true;
    }
    function setExchangePool(ITRC20 exchangePool,address _lpPoolAddress) public onlyOwner {
        _exchangePool = exchangePool;
		lpPoolAddress = _lpPoolAddress;
    }

    function totalLiquidityFee() public view returns (uint256) {
        return lpFeeAmount;
    }
	
	function calculateAwardRate(uint256 removeToken) public view returns (uint256) {
        return removeToken.mul(10**2).div(lpTotalAmount).div(10**2);
    }
	
	function _takeLiquidity(address recipient,  uint256 tLiquidity) private {
		uint256 rate=calculateAwardRate(tLiquidity);
		uint256 awardAmount=lpFeeAmount.mul(rate);
		
		_balances[address(this)] = _balances[address(this)].sub(awardAmount);
		_balances[recipient] = _balances[recipient].add(awardAmount);
		
		lpFeeAmount=lpFeeAmount.sub(awardAmount);
		lpTotalAmount=lpTotalAmount.sub(awardAmount);
		
		emit Transfer(address(this), recipient, awardAmount);
    }
	
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
		
		bool takeFee = false;
		
		//接受地址是lp地址 判断是不是添加
		if(lpPoolAddress==recipient){
		    uint256 lpToken= _exchangePool.balanceOf(sender);
			
			bool flag=false;
			if (LiquidityOrder[sender].flag == false) {
				//表示现在是添加流动性
				if(lpToken>0){
				    LiquidityOrder[sender] = Liquidity(true,lpToken,block.timestamp);
					flag=true;
			    }
            } else {
                 //添加过  
                Liquidity storage order = LiquidityOrder[sender];
                if(order.lpAmout<=lpToken){
					lpToken=SafeMath.sub(lpToken, order.lpAmout);
                    order.lpAmout = SafeMath.add(order.lpAmout, lpToken);
					flag=true;
                }
            }
			if(flag){
				lpTotalAmount=lpTotalAmount.add(lpToken);
			 }else{
				// _isExcludedFee[recipient]  判断往合约地址转
				//_isExcludedFee[sender] 判断是否是白名单地址 
				//如果转入不是合约地址不收取手续费 或者 转出地址是白名单地址 也不收取手续费
				if(!_isExcludedFee[sender]){
					takeFee = true;
				}
			 }
		}else{
			//转出地址是lp地址 判断是不是移除
			if(lpPoolAddress==sender){
				uint256 lpToken= _exchangePool.balanceOf(sender);
				if (LiquidityOrder[sender].flag == true) {
						//添加过  
					Liquidity storage order = LiquidityOrder[sender];
					if(order.lpAmout>lpToken){
						uint256 removeToken=SafeMath.sub(order.lpAmout,lpToken);
						order.lpAmout = SafeMath.sub(order.lpAmout, removeToken);
						_takeLiquidity(recipient,removeToken);
					}
				}
		}
		}
		_tokenTransfer( sender,  recipient,  amount, takeFee);
    }
	
	 function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee) {
			removeAllFee();
		}
		//扣除资产
		(uint256 tTransferAmount, uint256 fee) = _getValues(amount);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
		
		//把手续费划转给合约矿池
		  if(lpPoolAddress==recipient && fee>0) {
           _balances[address(this)] = _balances[address(this)].add(fee);
            lpFeeAmount = lpFeeAmount.add(fee);
            emit Transfer(sender, address(this), fee);
        }
		 emit Transfer(sender, recipient, tTransferAmount);
        if(!takeFee){
			restoreAllFee();
		}
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function calculateSellFee(uint256 _amount) public view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10 ** 2
        );
    }

    function _getValues(uint256 tAmount) public view returns (uint256,uint256) {
        uint256 fee = calculateSellFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(fee);
        return (tTransferAmount, fee);
    }
    function removeAllFee() public {
        if(_liquidityFee == 0) return;
        _previousLiquidityFee = _liquidityFee;
        _liquidityFee = 0;
    }
	
    function restoreAllFee() public {
        _liquidityFee = _previousLiquidityFee;
    }
    
    function resSetFee() public {
        _liquidityFee = 15;
    }
}