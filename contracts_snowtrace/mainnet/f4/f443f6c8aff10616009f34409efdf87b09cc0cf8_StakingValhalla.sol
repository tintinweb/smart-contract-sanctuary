/**
 *Submitted for verification at snowtrace.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

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

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}


library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    function mul(int256 a, int256 b) internal pure returns (int256) {
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c; 
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
  }
}


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor () public {
        _name = "Valhalla Staking Shares";
        _symbol = "VSS";
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract StakingValhalla is ERC20 {
    
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    address public owner;
    IERC20 public wsVal;
    IERC20 public mim;
    
    uint256 constant internal multiplier = 2**64;
    uint256 public calculatorMIM;

    uint256 public lastwsVALbalance;
    uint256 public lastMIMbalance;
    
	mapping(address => int256) public correctionMim;
	mapping(address => uint256) public withdrawnMIM;
    

    event Staked(address indexed user, uint256 amount, uint256 total);
    event Unstaked(address indexed user, uint256 amount, uint256 total);
    event MimWithdrawn(address indexed user, uint256 amount);
    event BalanceSnapshot(uint256 wsVAL, uint256 MIM);
    
    constructor (address wsVAL, address MIM) public {
        wsVal = IERC20(wsVAL);
        mim = IERC20(MIM);
        owner = msg.sender;
    }

    function stake(uint256 amount) public {
        stakeFor(msg.sender, amount);
    }

    function stakeFor(address user, uint256 amount) internal {
        require(wsVal.balanceOf(user) >= amount, "Amount exceeds your wsVAL balance");
        uint totalSupply = totalSupply();
        uint256 shares = totalSupply == 0 ? amount : amount.mul(totalSupply).div(getBalancewsVAL());
        
        require(wsVal.transferFrom(user, address(this), amount), "Stake required");
		
        withdrawDividendsMIM();

        _mint(user, shares);
        lastwsVALbalance = getBalancewsVAL();
		lastMIMbalance = getBalanceMIM();

        emit Staked(user, amount, totalSupply);
        emit BalanceSnapshot(lastwsVALbalance, lastMIMbalance);
    }

    
    function updateRewardPerShare() internal {
        uint256 MIMdiff = getBalanceMIM().sub(lastMIMbalance);
        
        if( MIMdiff > 0) {
            uint256 updateAmountMIM = MIMdiff.mul(multiplier).div(totalSupply());
            calculatorMIM = calculatorMIM.add(updateAmountMIM);
		}
    }
    
    function unstake(uint256 amount) public {
        unstakeFor(msg.sender, amount);
    }
   
    function unstakeFor(address user, uint256 amount) internal {
        require(balanceOf(user) >= amount, "Amount exceeds your share balance");

        uint256 unstakeAmount = amount.mul(getBalancewsVAL()).div(totalSupply());

        require(wsVal.transfer(user, unstakeAmount), "Unstake required");
        withdrawDividendsMIM();
        _burn(user, amount);

        lastwsVALbalance = getBalancewsVAL();
		lastMIMbalance = getBalanceMIM();

        emit Unstaked(msg.sender, amount, totalSupply());
        emit BalanceSnapshot(lastwsVALbalance, lastMIMbalance);

    }
    
    function getBalancewsVAL() public view returns (uint256) {
		return wsVal.balanceOf(address(this));
	}
	
	function getBalanceMIM() public view returns (uint256) {
		return mim.balanceOf(address(this));
	}
	
	function withdrawDividendsMIM() public {
	    updateRewardPerShare();
	    uint256 mimAm = withdrawableMIMOf(msg.sender);
	    withdrawnMIM[msg.sender] = withdrawnMIM[msg.sender].add(mimAm);
	    require(mim.transfer(msg.sender, mimAm));
	    lastMIMbalance = getBalanceMIM();
	    emit MimWithdrawn(msg.sender, mimAm);
	}

	function withdrawableMIMOf(address user) public view returns(uint256) {
		return accumulativeMIMOf(user).sub(withdrawnMIM[user]);
	}
	
	function accumulativeMIMOf(address _owner) internal view returns(uint256) {
		return (calculatorMIM.mul(balanceOf(_owner)).toInt256Safe()
			.add(correctionMim[_owner]).toUint256Safe()).div(multiplier);
	}
	
	function _transfer(address from, address to, uint256 value) internal override {
		updateRewardPerShare();
		super._transfer(from, to, value);
		correctionMim[from] = correctionMim[from]
			.add( (calculatorMIM.mul(value)).toInt256Safe() );
		correctionMim[to] = correctionMim[to]
			.sub( (calculatorMIM.mul(value)).toInt256Safe() );
	}
	
	function _mint(address account, uint256 value) internal override {
		super._mint(account, value);

		correctionMim[account] = correctionMim[account]
			.sub( (calculatorMIM.mul(value)).toInt256Safe() );
	}
	
	function _burn(address account, uint256 value) internal override {
		super._burn(account, value);

		correctionMim[account] = correctionMim[account]
			.add( (calculatorMIM.mul(value)).toInt256Safe() );
	}
}