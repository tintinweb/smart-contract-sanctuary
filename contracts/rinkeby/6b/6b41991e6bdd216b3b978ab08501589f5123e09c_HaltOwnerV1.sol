/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

contract Halt {
    mapping (address => uint256) internal _rOwned;
    mapping (address => uint256) internal _tOwned;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping(address => bool) public isTaxedAsSender;
	mapping(address => bool) public isTaxedAsRecipient;
    mapping (address => bool) public isExcluded;
    address[] internal _excluded;

    string public constant name = "Halt";
    string public constant symbol = "HALT";
    uint8 public constant decimals = 9;

    uint256 public constant totalSupply = 1_000_000_000 * (10 ** decimals);
    uint256 internal _rTotal = (type(uint256).max - (type(uint256).max % totalSupply));
    uint256 internal _tFeeTotal;
    uint256 constant internal _reflectBasisPoints = 7000;  // 0.01% = 1 basis point, 4.00% = 400 basis points
    uint256 internal reflectDisabledBlock;

    address public owner;
    address public pendingOwner;

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
    event Approval(address indexed account, address indexed spender, uint256 value);
    
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    function balanceOf(address account) external view returns (uint256) {
        return isExcluded[account] ? _tOwned[account] : tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowance[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] - subtractedValue);
        return true;
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }
    
    function reflect(uint256 tAmount) external {
        require(!isExcluded[msg.sender], "IS_EXCLUDED");
        
        (uint256 rAmount,,,,) = _getValues(address(0), address(0), tAmount);
        
        _rOwned[msg.sender] -= rAmount;
        _rTotal -= rAmount;
        _tFeeTotal += tAmount;
    }

    function reflectionFromToken(address sender, address recipient, uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
        require(tAmount <= totalSupply, "AMOUNT_>_SUPPLY");
        
        (uint256 rAmount,uint256 rTransferAmount,,,) = _getValues(sender, recipient, tAmount);
        
        return deductTransferFee ? rTransferAmount : rAmount;
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "AMOUNT_>_TOTAL_REFLECTIONS");
        return rAmount / _getRate();
    }

    function setSenderTaxed(address account, bool taxed) external isOwner {
        // by default, all senders are not taxed
        isTaxedAsSender[account] = taxed;
	}
	
	function setRecipientTaxed(address account, bool taxed) external isOwner {
	    // by default, all recipients are not taxed
        isTaxedAsRecipient[account] = taxed;
	}

    function excludeAccountFromRewards(address account) external isOwner {
        require(!isExcluded[account], "IS_EXCLUDED");
        
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        
        isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccountFromRewards(address account) external isOwner {
        require(isExcluded[account], "IS_INCLUDED");
        
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address account, address spender, uint256 amount) internal {
        allowance[account][spender] = amount;
        emit Approval(account, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(amount > 0, "INVALID_AMOUNT");
        
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(sender, recipient, amount);
        
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        
        if (isExcluded[sender] && !isExcluded[recipient]) {
            _tOwned[sender] -= amount;
        } else if (!isExcluded[sender] && isExcluded[recipient]) {
            _tOwned[recipient] += tTransferAmount;
        } else if (isExcluded[sender] && isExcluded[recipient]) {
            _tOwned[sender] -= amount;
            _tOwned[recipient] += tTransferAmount;
        }
        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) internal {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    function _getValues(address sender, address recipient, uint256 tAmount) internal view returns (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) {
        (tTransferAmount, tFee) = _getTValues(sender, recipient, tAmount);
        (rAmount, rTransferAmount, rFee) = _getRValues(tAmount, tFee, _getRate());
    }

    function _getTValues(address sender, address recipient, uint256 tAmount) internal view returns (uint256 tTransferAmount, uint256 tFee) {
        tFee = (block.number != reflectDisabledBlock) && (isTaxedAsSender[sender] || isTaxedAsRecipient[recipient])
            ? (tAmount * _reflectBasisPoints) / 10_000
            : 0;
        
        tTransferAmount = tAmount - tFee;
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) internal pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) {
        rAmount = tAmount * currentRate;
        rFee = tFee * currentRate;
        rTransferAmount = rAmount - rFee;
    }

    function _getRate() internal view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() internal view returns (uint256 rSupply, uint256 tSupply) {
        rSupply = _rTotal;
        tSupply = totalSupply; 
        
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, totalSupply);
            
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        
        if (rSupply < (_rTotal / totalSupply)) {
            (rSupply, tSupply) = (_rTotal, totalSupply);
        }
    }
    
    function changeOwner(address newOwner) external isOwner {
        pendingOwner = newOwner;
	}
	
	function acceptOwnership() external {
        require(msg.sender == pendingOwner, "NOT_PENDING_OWNER");
        
        emit OwnershipTransferred(owner, msg.sender);
        
        owner = msg.sender;
        pendingOwner = address(0);
	}
	
	function disableReflectionForCurrentBlock() external isOwner {
	    reflectDisabledBlock = block.number;
	}
	
	function resetReflectDisabledBlock() external isOwner {
	    reflectDisabledBlock = 0;
	}
}

interface UniswapRouterV202 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function factory() external pure returns (address);
}

interface UniswapPairV2 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
}

contract HaltOwnerV1 {
    Halt immutable public token;
    address public owner;
    address public pendingOwner;
    
    UniswapRouterV202 public router;
    UniswapPairV2 public pair;
    
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    
    constructor (address tokenAddress, address routerAddress, address pairAddress) {
        owner = msg.sender;
        token = Halt(tokenAddress);
        router = UniswapRouterV202(routerAddress);
        pair = UniswapPairV2(pairAddress);
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }
    
    function changeOwner(address newOwner) external isOwner {
        pendingOwner = newOwner;
	}
	
	function acceptOwner() external {
        require(msg.sender == pendingOwner, "NOT_PENDING_OWNER");
        
        emit OwnershipTransferred(owner, msg.sender);
        
        owner = msg.sender;
        pendingOwner = address(0);
	}
	
	function changeOwnerOfToken(address newOwner) external isOwner {
        token.changeOwner(newOwner);
	}
	
	function acceptOwnershipOfToken() external isOwner {
	    token.acceptOwnership();
	}
    
    function setSenderTaxed(address account, bool taxed) external isOwner {
        token.setSenderTaxed(account, taxed);
	}
	
	function setRecipientTaxed(address account, bool taxed) external isOwner {
	    token.setRecipientTaxed(account, taxed);
	}

    function setAccountGetsRewards(address account, bool getsRewards) external isOwner {
        getsRewards ? token.includeAccountFromRewards(account) : token.excludeAccountFromRewards(account);
    }
    
    function addLiquidityETH(
        address tokenAddress,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        require(tokenAddress == address(token), "NOT_TOKEN");
        
        // Turn off tax for this block
        token.disableReflectionForCurrentBlock();
        
        // Transfer token from caller to this
        token.transferFrom(msg.sender, address(this), amountTokenDesired);
        
        // Approve Router on the amount of token
        token.approve(address(router), amountTokenDesired);
        
        // Perform the liquidity add
        (amountToken, amountETH, liquidity) = router.addLiquidityETH{value: msg.value}(tokenAddress, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);
        
        uint256 leftOver = token.balanceOf(address(this));

        if (leftOver > 0) {
            // Transfer leftover ETH or tokens to the caller
            token.transfer(msg.sender, leftOver);
        }

        leftOver = address(this).balance;

        if (leftOver > 0) {
            payable(msg.sender).transfer(leftOver);
        }
        
        // Turn on tax for this block
        token.resetReflectDisabledBlock();
    }
    
    function setRouterAndPair(address routerAddress, address pairAddress) external isOwner {
        router = UniswapRouterV202(routerAddress);
        pair = UniswapPairV2(pairAddress);
    }
    
    receive() external payable {}
}