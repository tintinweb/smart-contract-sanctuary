// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


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

contract SimpleDEX is Context, Ownable, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    
    struct Invest {
        uint256 depositTime;
        uint256 tokenAmount;
        uint256 etherAmount;
        uint256 liquidity;
        bool justEther;
	    uint256 withdrawTime;
    }
    
    struct User {
	    bool isRegistered;
	    address[] inviters;
	    Invest[] invests;
    }

    uint256 public registrationReward = 5 * 1e18; // new user gains welcome tip
    uint256 public minimumInvestmentEther = 1000 * 1e18; // minimum amount of tether for justEther
    uint256 public minimumInvestmentBoth = 2000 * 1e18; // minimum amount of tether for both
    uint256 public investmentsLimit = 10; // Total investment slots per user
    uint256 public investmentPeriod = 91; // 91 days = 13 weeks
    uint256 public profitPeriod = 7; // 7 days = a week
    uint256 public ppJustEther = 4; // Profit Percent
    uint256 public ppBothSides = 9; // Profit Percent
    
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => User) private _users;

    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Pair public immutable uniswapV2Pair;
    address public tether = 0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60; // Goerli USDC
    
    event Invested(address indexed investor, uint256 tokenAmount, uint256 etherAmount, bool justEther, uint256 liquidity);
    event ProfitGained(address indexed investor, uint256 profit);
    event InvestCompleted(address indexed investor, uint256 tokenAmount, uint256 etherAmount, bool justEther, uint256 liquidity);
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 1000000 * 1e18;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        uniswapV2Pair = IUniswapV2Pair(IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH()));
        
        uniswapV2Router = _uniswapV2Router;
        
    	User storage user = _users[_msgSender()];
    	user.isRegistered = true;
        
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function register(address inviter) external returns (bool) {
    	User storage user = _users[_msgSender()];
    	User storage inviter_ = _users[inviter];
    
    	require(user.isRegistered == false, "user is registered before");
    	require(inviter_.isRegistered == true, "inviter is not registered");
    
        user.isRegistered = true;
    	user.inviters.push(inviter);
    	
    	for (uint8 i = 0; i < inviter_.inviters.length && i < 2; i++) {
    	    user.inviters.push(inviter_.inviters[i]);
    	}
    
    	_transfer(owner(), _msgSender(), registrationReward);
	    return true;
    }
    
    function isRegistered(address holder) external view returns (bool) {
        return _users[holder].isRegistered;
    } 

    function estimate(uint256 tetherAmount) public view returns (uint256 etherAmount, uint256 tokenAmount) {
        address[] memory path = new address[](2);
        path[0] = tether;
        path[1] = uniswapV2Router.WETH();
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(tetherAmount, path);
        
        uint256 resToken;
        uint256 resEther;
        if (uniswapV2Pair.token0() == address(this))
            (resToken, resEther, ) = uniswapV2Pair.getReserves();
        else
            (resEther, resToken, ) = uniswapV2Pair.getReserves();
        
        etherAmount = amounts[1];
	    tokenAmount = uniswapV2Router.quote(etherAmount, resEther, resToken);
    }
    
    function depositETH(uint256 tetherAmount) public payable returns (bool) {
    	User storage user = _users[_msgSender()];
    	require(user.isRegistered == true, "user is not registered");
    	require(tetherAmount >= minimumInvestmentEther, "below minimum investment");
    	require(user.invests.length < investmentsLimit, "user does not have empty investment slot");
    	
    	(uint256 etherAmount, uint256 tokenAmount) = estimate(tetherAmount);
    	
    	Invest memory invest;
    	invest.depositTime = block.timestamp;
    	invest.withdrawTime = block.timestamp;
    	
    	_transfer(owner(), address(this), tokenAmount);
    	(invest.tokenAmount, invest.etherAmount, invest.liquidity) = addLiquidity(tokenAmount, etherAmount);
    	
    	payable(_msgSender()).transfer(msg.value.sub(invest.etherAmount));
    	_transfer(address(this), owner(), tokenAmount.sub(invest.tokenAmount));
    	
    	invest.justEther = true;
    	user.invests.push(invest);
	    
    	emit Invested(_msgSender(), invest.tokenAmount, invest.etherAmount, invest.justEther, invest.liquidity);
    	return true;
    }

    function depositBoth(uint256 tetherAmount) public payable returns (bool) {
        User storage user = _users[_msgSender()];
    	require(user.isRegistered == true, "user is not registered");
    	require(tetherAmount >= minimumInvestmentBoth, "below minimum investment");
    	require(user.invests.length < investmentsLimit, "user does not have empty investment slot");
    	
    	(uint256 etherAmount, uint256 tokenAmount) = estimate(tetherAmount);
    	
    	Invest memory invest;
    	invest.depositTime = block.timestamp;
    	invest.withdrawTime = block.timestamp;
    	
    	_transfer(_msgSender(), address(this), tokenAmount);
    	(invest.tokenAmount, invest.etherAmount, invest.liquidity) = addLiquidity(tokenAmount, etherAmount);
    	
    	payable(_msgSender()).transfer(msg.value.sub(invest.etherAmount));
    	_transfer(address(this), _msgSender(), tokenAmount.sub(invest.tokenAmount));
    	
    	invest.justEther = false;
    	user.invests.push(invest);
	    
    	emit Invested(_msgSender(), invest.tokenAmount, invest.etherAmount, invest.justEther, invest.liquidity);
    	return true;
    }
    
    function withdrawProfit(uint8 slot) public returns (bool) {
        User storage user = _users[_msgSender()];
    	Invest storage invest = user.invests[slot];
    	require(daysOf(invest.withdrawTime) >= profitPeriod, "profit period is not completed");
    	
    	uint256 tWeeks = weeksOf(invest.withdrawTime);
    	uint256 profitPerWeek;
    	if (invest.justEther == true) {
    	    profitPerWeek = invest.tokenAmount.div(100).mul(ppJustEther);
    	} else {
    	    profitPerWeek = invest.tokenAmount.div(100).mul(ppBothSides);
    	}
    	uint256 profit = tWeeks.mul(profitPerWeek);
    	
    	for (uint8 i = 0; i < user.inviters.length && i < 3; i++) {
    	    if (i == 0) 
    	        _transfer(owner(), user.inviters[i], profit.div(100).mul(10));
    	    else if (i == 1) 
    	        _transfer(owner(), user.inviters[i], profit.div(100).mul(5));
    	    else
    	        _transfer(owner(), user.inviters[i], profit.div(100).mul(3));
    	}
    	_transfer(owner(), _msgSender(), profit);
    	
    	invest.withdrawTime += tWeeks * profitPeriod * 60 seconds; //(24 hours * 60 minutes * 60 seconds);
    	
    	emit ProfitGained(_msgSender(), profit);
        return true;
    }
    
    function profitOf(uint8 slot) external view returns (uint256) {
        User memory user = _users[_msgSender()];
    	Invest memory invest = user.invests[slot];
    	
    	uint256 tWeeks = weeksOf(invest.withdrawTime);
    	uint256 profitPerWeek;
    	if (invest.justEther == true) {
    	    profitPerWeek = invest.tokenAmount.div(100).mul(ppJustEther);
    	} else {
    	    profitPerWeek = invest.tokenAmount.div(100).mul(ppBothSides);
    	}
    	return tWeeks.mul(profitPerWeek);
    }
    
    function poolReserves() public view returns (uint256 tokenReserve, uint256 etherReserve) {
        if (uniswapV2Pair.token0() == address(this))
            (tokenReserve, etherReserve, ) = uniswapV2Pair.getReserves();
        else
            (etherReserve, tokenReserve, ) = uniswapV2Pair.getReserves();    
    }
    
    function poolShare(uint256 liquidity) public view returns (uint256 rate, uint256 tokens, uint256 ethers) {
        uint256 resToken;
        uint256 resEther;
        if (uniswapV2Pair.token0() == address(this))
            (resToken, resEther, ) = uniswapV2Pair.getReserves();
        else
            (resEther, resToken, ) = uniswapV2Pair.getReserves();
        
        rate = liquidity.mul(1e18).div(uniswapV2Pair.totalSupply());
        tokens = resToken.mul(rate).div(1e18);
        ethers = resEther.mul(rate).div(1e18);
    }
    
    function withdraw(uint8 slot) public returns (bool) {
        User storage user = _users[_msgSender()];
    	require(slot < user.invests.length, "empty slot");
    	
    	Invest memory invest = user.invests[slot];
    	//require(daysOf(invest.depositTime) >= investmentPeriod, "investment period is not completed");
    	
    	if (daysOf(invest.withdrawTime) >= profitPeriod) {
    	    withdrawProfit(slot);
    	}
    	
        uniswapV2Pair.approve(address(uniswapV2Router), invest.liquidity);
        
        (/*uint256 rate*/, /*uint256 tokens*/, uint256 ethers) = poolShare(invest.liquidity);
    	(uint amountToken, uint amountEther) = uniswapV2Router.removeLiquidityETH(
            address(this),
            invest.liquidity,
            0,
            ethers,
            address(this),
            block.timestamp + 180
        );
        
        payable(_msgSender()).transfer(amountEther);
        if (invest.justEther == true) {
            _transfer(address(this), owner(), amountToken);
        } else {
            _transfer(address(this), _msgSender(), amountToken);
        }
        
        for (uint8 i = slot + 1; i < user.invests.length; i++) {
            user.invests[i - 1] = user.invests[i];
        }
        user.invests.pop();
        
        emit InvestCompleted(_msgSender(), amountToken, amountEther, invest.justEther, invest.liquidity);
        return true;
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 etherAmount) private 
        returns (uint amountToken, uint amountEther, uint liquidity) {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        return uniswapV2Router.addLiquidityETH{value: etherAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 180
        );
    }
    
    function powerUp(uint256 tokenAmount) public onlyOwner payable returns (bool) {
        _transfer(owner(), address(this), tokenAmount);
        (uint256 amountToken, uint256 amountEther, uint256 liquidity) = addLiquidity(tokenAmount, msg.value);
        
    	emit Invested(_msgSender(), amountToken, amountEther, false, liquidity);
        return true;
    }
    
    function poolLiquidity() external view returns (uint256) {
        return uniswapV2Pair.totalSupply();
    }
    
    function investsList(address investor) public view returns (Invest[] memory) {
        User storage user = _users[investor];
    	return user.invests;
    }
    
    function daysOf(uint256 timestamp) public view returns (uint256) {
        return (block.timestamp - timestamp) / 60 seconds; //(24 hours * 60 minutes * 60 seconds);
    }
    
    function weeksOf(uint256 timestamp) public view returns (uint256) {
        return daysOf(timestamp) / 7;
    }
    
    function monthsOf(uint256 timestamp) public view returns (uint256) {
        return daysOf(timestamp) / 30;
    }
    
    function setTetherAddress(address tetherAddress) public returns (bool) {
        tether = tetherAddress;
        return true;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function withdrawToken(uint256 amount) public onlyOwner returns (bool) {
        _transfer(address(this), owner(), amount);
        return true;
    }
    
    function withdrawEther(uint256 amount) public onlyOwner returns (bool) {
        payable(owner()).transfer(amount);
        return true;
    }
    
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
    
    receive() external payable {}
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

