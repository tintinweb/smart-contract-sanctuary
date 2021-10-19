/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library SafeMath {

    function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            uint c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }


    function tryMul(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (a == 0) return (true, 0);
            uint c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint a, uint b) internal pure returns (uint) {
        return a + b;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        return a * b;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return a / b;
    }

    function mod(uint a, uint b) internal pure returns (uint) {
        return a % b;
    }

    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint amount) internal {
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

    function functionCallWithValue(address target, bytes memory data, uint value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint weiValue, string memory errorMessage) private returns (bytes memory) {
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

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20 is IERC20 {
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _totalSupply;
    string internal _name;
    string internal _symbol;

    uint internal endTimestamp;   // 结束区块

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        uint currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        // 如果不是为了转币，挖矿没有结束，就不允许转账
        
        if (sender != address(this) || block.timestamp < endTimestamp) {
            return;
        }

        _beforeTokenTransfer(sender, recipient, amount);

        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual {}
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

contract BPunkPool is ERC20 {

    using SafeMath for uint;
    using Address for address;

    IUniswapV2Router02 public UniswapV2Router;
    IUniswapV2Pair public Pair;
    address public pair;
    address public Admin;

    // Mint Parameter Start

    IERC20 public depositCoin;// 存款抵押的LP币地址
    IERC20 public RewardCoin;  // 奖励的币地址

    struct Users {
        uint amount; // 用户存的实币数
        uint rewardDebt; // 用户存的币+奖励
    }

    mapping(address => Users) public users; // 用户信息结构体

    uint public lastRewardTimestamp; // 上次最后计算的区块，这个可以改成时间戳 lastBlockTimestamp
    uint public accTokenPerShare; // 每股累计奖励数，开场是0，在使用的时候乘以1e12/depositTotalsupply就是股份，先乘以e12是为了不出现小数。
    uint public startTimestamp; // 开始区块
    // uint public endTimestamp;   // 结束区块 在上面定义了
    uint public mintPerSecond; // 每秒产出多少币，如果上面是时间戳，那就是每秒多少个币

    bool public initialized;
    
    event Deposit(address indexed user,  uint amount);
    event Withdraw(address indexed user, uint amount);

    function initialize( address _ALPAddress ) external  {
        require(!initialized, "Initialization is completed");
        //require(block.timestamp < 1635468378, "For Test");

        _name        = "APunk";
        _symbol      = "APunk";
        Admin = msg.sender; // 上线改
        UniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        depositCoin = IERC20(_ALPAddress);
        RewardCoin = IERC20(address(this));
        // 最后分配区块是项目方设定的时间，或者是当前立即开始
        startTimestamp = block.timestamp + 30;
        endTimestamp = startTimestamp + 1200; // 开始时间戳+ 挖多少秒
        lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        mintPerSecond = (150 * 10000 * 1e18) / (endTimestamp - startTimestamp);
        _name = "B Punk Coin";
        _symbol = "BPunk";
        initialized = true;

        _mint(_msgSender(), 11999*1e18); // 开场给自己挖1万，方便测试
        //_mint(address(this), 1*1e18); // 开场给合约挖1个，方便增加流动性,但这个跟deposit冲突必须先初始化上币后，再搞deposit
        _approve(msg.sender, address(UniswapV2Router), type(uint).max); 

        /* gamache test NO here 测试版本，不执行下面逻辑
        IUniswapV2Factory(UniswapV2Router.factory()).createPair(address(this), UniswapV2Router.WETH());
        _approve(address(this), address(UniswapV2Router), type(uint).max); 

        pair = IUniswapV2Factory(UniswapV2Router.factory()).getPair(address(this), UniswapV2Router.WETH());
        Pair = IUniswapV2Pair(pair);

        UniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this), // this is token address
            1e18, // this is token amount
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
        */
        initialized = true;
    }

    function updateMintPerSecond() internal {
        if (block.timestamp > startTimestamp + 300) {
            if (block.timestamp > endTimestamp ) {
                mintPerSecond = 0;
            }
            mintPerSecond += 210 * 10000 * 1e18; // 每月+10%
        } 
    }

    // JVM方便测试用，显示当前区块号
    function getTimestamp() view external returns(uint) {
        return block.timestamp;
    }

    function userAmount() external view returns(uint) {
        return users[_msgSender()].amount;
    }

    // 计算时间差，不再这里判断开盘逻辑
    function getTimestampDiff(uint _lowerTimestamp, uint _upperTimestamp) internal view returns (uint) {
        // 这里不用管存款时间小于开始时间，只判断上标大于下标即可
        require(_upperTimestamp > _lowerTimestamp, "The end time must exceed the start time");

        uint _normalTimestamp = _upperTimestamp>endTimestamp? endTimestamp : _upperTimestamp;
        return _normalTimestamp - _lowerTimestamp;
    }

    // 纯view，查看玩家目前可以获得多少奖励，这个不带存款，是单纯奖励数量
    function pendingToken(address _userAddress) public view returns (uint) {
        Users storage user = users[_userAddress];
        uint _accTokenPerShare = accTokenPerShare;
        uint totalDeposit = depositCoin.balanceOf(address(this));
        if (block.timestamp > lastRewardTimestamp && totalDeposit != 0) {
            uint secondDiff = getTimestampDiff(lastRewardTimestamp, block.timestamp);
            uint userReward = secondDiff.mul(mintPerSecond);
            _accTokenPerShare = _accTokenPerShare.add(userReward.mul(1e12).div(totalDeposit));
        }
        return user.amount.mul(_accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

        // 刷新矿池accTOkenPerShare信息，这个是结合存款提款使用的。
    function updatePool() internal {
        
        if (block.timestamp <= lastRewardTimestamp) {
            return;
        }

        // 判断是否是第一次存款
        uint totalDeposit = depositCoin.balanceOf(address(this));
        if (totalDeposit == 0) {
            lastRewardTimestamp = block.timestamp;
            return;
        }
        // 不是第一个存款。就开始计算利息
        uint secondDiff = getTimestampDiff(lastRewardTimestamp, block.timestamp);
        uint userReward = secondDiff.mul(mintPerSecond);
        _mint(address(this), userReward);
        accTokenPerShare = accTokenPerShare.add(
            userReward.mul(1e12).div(totalDeposit)
        );
        lastRewardTimestamp = block.timestamp;
    }

    function deposit(uint _amount) public {
        updateMintPerSecond();
        Users storage user = users[_msgSender()]; // 先读取现存的客户信息
        updatePool();
        if (user.amount > 0) {
            uint pending = pendingToken(_msgSender());
            RewardCoin.transfer(msg.sender, pending);
        }
        depositCoin.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint _amount) public {
        updateMintPerSecond();

        Users storage user = users[_msgSender()];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint pending = pendingToken(_msgSender());
        RewardCoin.transfer(_msgSender(), pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(1e12);
        depositCoin.transfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _amount);
    }

    // mint END

    modifier onlyAdmin() {
        require(Admin == msg.sender, "Error: You are not the Admin");
        _;
    }







    receive() external payable {}

}