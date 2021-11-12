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

contract ERC20 is IERC20 {
    mapping(address => uint) internal _balances;
    mapping(address => mapping(address => uint)) internal _allowances;
    uint internal _totalSupply;
    string internal _name;
    string internal _symbol;

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

contract DAKPoolV1 is ERC20 {
    using SafeMath for uint;
    using Address for address;

    uint internal StartTimestamp;     // 开始挖矿时间
    uint internal EndTimestamp;       // 结束挖矿时间

    uint public MintPerSecond; // 每秒产出多少币，0号和4号都是 0空的不给挖 EndmintPerSecond
    // uint public StartMintPerSecond; // hushi wakuangsudu
    // uint public EndmintPerSecond; // hushi wakuangsudu

    // 每股分红，开场是0 在使用的时候乘以1e12/depositTotalsupply就是股份，先乘以e12是为了不出现小数。
    uint public accTokenPerShare; // 0号和5号不允许更新
    uint public lastRewardTimestamp; // 每个阶段的最后结算区块

    uint public inviterAccTokenPerShare; // 0号和5号不允许更新
    uint public inviterLastRewardTimestamp; // 每个阶段的最后结算区块
    uint public inviteTotalAmount; // 邀请的总量，因为有些人不邀请，所以这个数值比balanceOf要低

    IUniswapV2Router02 public UniswapV2Router;
    IUniswapV2Factory  public UniswapV2Factory;
    IUniswapV2Pair public BOSPair;
    IUniswapV2Pair public DAKPair;
    address public pair;
    address public TEAM;
    address public DEAD;

    IERC20 public BOS;// A币
    IERC20 public LP;// For test LP 
    IERC20 public RewardCoin;  // B币，奖励的币地址

    // 普通玩家信息
    struct Users {
        uint DepositAmount; // 第0个月用户预存的实币数，乘以每个月的每股分红accTokenPerShare就是当月的奖励
        uint RewardAmount; // 用户的奖励 第0阶段
        address inviter;
    }

    // 团长的邀请表
    struct InviterList {
        address Customer;
        uint DepositAmount; // 第0个月用户预存的实币数，乘以每个月的每股分红accTokenPerShare就是当月的奖励
    }


    mapping(address => Users) public users; // 用户信息结构体 需要public
    mapping(address => InviterList[] ) internal invitations; // 团长邀请记录，不要public

    bool public initialized;
    
    event Stake(address indexed user,  uint amount);
    event Withdraw(address indexed user, uint amount);

    function initialize(address _lp) external payable {
        
        require(!initialized, "Initialization is completed");
        // 部署BOSCoin合约（A币），记得手动开源BOS
        LP = IERC20(_lp);
        TEAM = 0xABCD756f71564a1c24e4C8f429580c4A6DCfbccc;
        DEAD = 0x000000000000000000000000000000000000dEaD;

        // 部署本合约的DAK币 （B币）
        _name        = "DAK";
        _symbol      = "DAK";
        _totalSupply = 1500 * 10000 * 1e18;

        StartTimestamp = block.timestamp + 5;
        lastRewardTimestamp = StartTimestamp;
        EndTimestamp = StartTimestamp + 120 days;
        
        // mintPerSecond 处于其他时间段就赋值给这里
        MintPerSecond = _totalSupply.div(120).div(24).div(3600);

        // Router和Factory全套 上线要加上
        //UniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        //UniswapV2Factory = IUniswapV2Factory(UniswapV2Router.factory());
        //UniswapV2Factory.createPair(address(BOS), UniswapV2Router.WETH());
        //UniswapV2Factory.createPair(address(this), UniswapV2Router.WETH());

        _mint(address(this), _totalSupply + 1e18); // 开场给合约挖1个，方便增加流动性,但这个跟deposit冲突必须先初始化上币后，再搞deposit
        //_approve(address(this), address(UniswapV2Router), type(uint).max); 
        //BOS.approve(address(UniswapV2Router), type(uint).max); 


        // LP地址 地址使用 address(Pair), address(UniswapV2Router)
        //BOSPair = IUniswapV2Pair(UniswapV2Factory.getPair(address(BOS), UniswapV2Router.WETH()));
        //DAKPair = IUniswapV2Pair(UniswapV2Factory.getPair(address(this), UniswapV2Router.WETH()));

        RewardCoin = IERC20(address(this));
        
        //UniswapV2Router.addLiquidityETH{value: address(this).balance / 2 }(address(BOS),  1e18, 0, 0, address(TEAM), block.timestamp);
        //UniswapV2Router.addLiquidityETH{value: address(this).balance / 2 }(address(this), 1e18, 0, 0, address(TEAM), block.timestamp);
        // 每月的存款总额，如果到了下一个月，上一个月总额就不变了
        initialized = true;
    }

    function balanceOf(address _account) public view virtual override returns (uint) {
        if (_account == address(DEAD)) {
            return 0;
        }

        return _balances[_account] + pendingToken(_account);

    }

  
    // 改变每股分红,算分红只用mintPerSecond即可，存款提款都执行,上线改internal
    function updatePool() public {

        // 没开盘就不更新
        if (block.timestamp < StartTimestamp) {
            return;
        }

        if (LP.balanceOf(address(this)) == 0) {
            lastRewardTimestamp = block.timestamp;
            return;
        }

        uint timestampDiff = getTimestampDiff(lastRewardTimestamp, block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp);
        // 这个是这个时间段应该铸造出来的总奖励userReward
        uint _userReward = timestampDiff.mul(MintPerSecond*6/10);
        accTokenPerShare += (_userReward.mul(1e12).div(LP.balanceOf(address(this))));
        lastRewardTimestamp = block.timestamp;
    }

    function updateInviter() public {

        // 没开盘就不更新
        if (block.timestamp < StartTimestamp) {
            return;
        }

        if (inviteTotalAmount == 0) {
            inviterLastRewardTimestamp = block.timestamp;
            return;
        }

        uint timestampDiff = getTimestampDiff(inviterLastRewardTimestamp, block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp);
        // 这个是这个时间段应该铸造出来的总奖励userReward
        uint _userReward = timestampDiff.mul(MintPerSecond*4/10);
        inviterAccTokenPerShare += (_userReward.mul(1e12).div(inviteTotalAmount));
        inviterLastRewardTimestamp = block.timestamp;
    }

    // 纯view，查看玩家目前可以获得多少奖励，只返回数量而已
    function pendingToken(address _account) public view returns (uint) {

        // 没开盘就不更新
        if (block.timestamp <= StartTimestamp) {
            return 0;
        }

        // 先计算user
        Users storage user = users[_account];
        uint _accTokenPerShare = accTokenPerShare;
        uint _inviterAccTokenPerShare = inviterAccTokenPerShare;
        uint LPbalance = LP.balanceOf(address(this));
        if (LP.balanceOf(address(this)) !=0) {
            uint timestampDiff = getTimestampDiff(lastRewardTimestamp, block.timestamp>EndTimestamp?EndTimestamp:block.timestamp);
            uint _thisReward = timestampDiff.mul(MintPerSecond);//这里是100%
            _accTokenPerShare = _accTokenPerShare + (_thisReward*6/10*1e12/LPbalance);
            _inviterAccTokenPerShare = _inviterAccTokenPerShare + (_thisReward*4/10*1e12/inviteTotalAmount);
        }

        // 计算邀请列表
        uint _leaderTotalDepositAmount;
        InviterList[] storage invitation = invitations[_account]; // 读取客户自己团队的邀请列表
        if (invitation.length > 0) {
            for (uint i = 0; i<=invitation.length; i++) {
                _leaderTotalDepositAmount +=  invitation[i].DepositAmount;
            }
        }
        // 客户自己的存款 + 自己团员的存款
        uint userReward = (user.DepositAmount * _accTokenPerShare + _leaderTotalDepositAmount * _inviterAccTokenPerShare).div(1e12).sub(user.RewardAmount);

        return userReward;
    }


    function stake(uint _amount, address _inviter) external {
        // 上线要加上这些验证
        require(_inviter != address(this), "Inviter can't be LP Contract");
        require(_inviter != address(0), "Inviter can't be LP Contract");
        require(_inviter != _msgSender(), "Inviter can't be Yourself");
        Users storage user = users[_msgSender()];    
        InviterList[] storage invitation = invitations[_inviter]; // 读取客户团长的邀请列表
        
        // list 默认是不存在，而不是0所以需要初始化
        if (user.inviter == address(0)) {
            invitation.push(InviterList({
                Customer : _msgSender(),
                DepositAmount : 0
            }));
            user.inviter = _inviter;// DEAD一样要写入进去
        }
        
        uint _accTokenPerShare = accTokenPerShare; // 在更新矿池之前，拿到acc发奖励用
            
       
        // 不能放在最后，没挖币不能发币
        updatePool(); // 上面先取值后，再更新获得新的 accpershare 和lastRewardTimestamp

        if (_amount > 0 && user.inviter != address(DEAD) && user.inviter != address(0)) {
            updateInviter();
        }

        // Users storage leader = users[user.inviter]; // 客户更新邀请人之后再读取leader

        // 给客户结算之前的奖励，团长一起结算发送
        if (user.DepositAmount > 0 && _accTokenPerShare > 0 ) {
            uint userPending = pendingToken(_msgSender());
            RewardCoin.transfer(_msgSender(), userPending);// 这里包含自己团队的奖励也发给了自己
            // 发奖才会更新已发奖的数量
            user.RewardAmount = userPending; // 客户已经领走的奖励数量
            
            // 自己团队自己结算，下层客户不会带着上层结算了
            // if (invitation.length > 0 && user.inviter != address(DEAD) && user.inviter != address(0) ) {
                
            //     uint _totalDepositAmount;// 团长队员的总存款
            //     for (uint i = 0; i<invitation.length; i++) {
            //         _totalDepositAmount +=  invitation[i].DepositAmount;
            //     }
            //     uint leaderPending = _totalDepositAmount.mul(_accTokenPerShare).div(1e12).sub(leader.RewardAmount);
            //     RewardCoin.transfer(_inviter, leaderPending);
            //     // 邀请总额和LP存款总额的差值：_accTokenPerShare * LP.balanceOf(address(this)) / totalInviteAmount
            //     leader.RewardAmount = _totalDepositAmount.mul(_accTokenPerShare * LP.balanceOf(address(this)) / totalInviteAmount ).div(1e12);
            //     // 团长已经领走的记录在团长自己的user表里leader.RewardAmount

            // }

        }

        //本次存款大于0，拿走LP,写入团长邀请表
        if ( _amount > 0) {
            LP.transferFrom(_msgSender(), address(this), _amount);            
            // 重新读取信息，然后找到团长的邀请表，更新进去
            Users storage _user = users[_msgSender()];
            InviterList[] storage _invitation = invitations[_user.inviter]; // 读取客户团长的邀请列表
            _user.DepositAmount += _amount;
            if (_user.inviter != address(DEAD) && _user.inviter != address(0)) {
                inviteTotalAmount += _amount; // 记录邀请奖励总额,排除未邀请的数量
                for (uint j = 0; j < _invitation.length; j++) {
                    if (_invitation[j].Customer == _msgSender()){
                        _invitation[j].DepositAmount += _amount;
                    }
                }
            }
        }
        
        emit Stake(msg.sender, _amount);

    }


    function withdraw(uint _amount) public {

        Users storage user = users[_msgSender()];
        Users storage leader = users[user.inviter];
        InviterList[] storage invitation = invitations[user.inviter]; // 读取客户团长的邀请列表

        require(user.DepositAmount > _amount, "ERROR: Withdraw Too Many");
        updatePool();

        // 给客户结算之前的奖励，团长一起结算发送
        if (user.DepositAmount > 0 ) {
            uint userPending = user.DepositAmount.mul(accTokenPerShare).div(1e12).sub(user.RewardAmount);
            RewardCoin.transfer(_msgSender(), userPending);
            // 发奖才会更新已发奖的数量
            user.RewardAmount = user.DepositAmount.mul(accTokenPerShare).div(1e12);

            uint _totalDepositAmount;
            if (invitation.length > 0 && user.inviter != address(DEAD)) {
                for (uint i = 0; i<=invitation.length; i++) {
                    _totalDepositAmount +=  invitation[i].DepositAmount;
                }
                uint leaderPending = _totalDepositAmount.mul(accTokenPerShare).div(1e12).sub(leader.RewardAmount);
                RewardCoin.transfer(user.inviter, leaderPending);
                leader.RewardAmount = _totalDepositAmount.mul(accTokenPerShare).div(1e12);
                // 团长已经领走的记录在团长自己的user表里leader.RewardAmount
            }

        }

        // 更新客户和团长的表
        if ( _amount > 0) {
            LP.transfer(_msgSender(), _amount); //  LP返还给客户
            user.DepositAmount -= _amount;
            // 找到团长的邀请表，更新进去

            for (uint i = 0; i<=invitation.length; i++) {
                if (invitation[i].Customer == _msgSender()){
                    invitation[i].DepositAmount -= _amount;
                }
            }
        }

        emit Withdraw(_msgSender(), _amount);
    }

    function getInviterList(address _account) public view returns( address[] memory, uint[] memory) {
        address[] memory Customers = new address[](invitations[_account].length);
        uint[] memory DepositAmounts = new uint[](invitations[_account].length);
        for (uint i = 0; i< invitations[_account].length; i++) {
            InviterList storage _userlist = invitations[_account][i];
            Customers[i] = _userlist.Customer;
            DepositAmounts[i] = _userlist.DepositAmount;
        }

        return (Customers, DepositAmounts);
    }

    function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal virtual override {
        require(sender == address(this) || block.timestamp > EndTimestamp, "Transfer Lock Until Mint Over");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Pool ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }


    // JVM方便测试用，显示当前区块号
    function showTimestamp() view external returns(uint) {
        return block.timestamp;
    }

    // 计算时间差，不再这里判断开盘逻辑
    function getTimestampDiff(uint _lowerTimestamp, uint _upperTimestamp) public view returns (uint) {
        // 这里不用管存款时间小于开始时间，只判断上标大于下标即可
        if (_upperTimestamp <= _lowerTimestamp || _upperTimestamp > EndTimestamp ) {
            return 0;
        }

        return _upperTimestamp - _lowerTimestamp;
    }


    receive() external payable {}

}