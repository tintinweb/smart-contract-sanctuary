/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

abstract contract History {
    // roundIndex => winningNumbers[numbers]
    mapping(uint256 => uint256) public historyWinningNumbers;
    mapping(uint256 => uint256[]) public historyInfo;
    function getHistoryInfoByRound(uint256 _index) public view returns ( uint256[] memory)  {
        return historyInfo[_index];
    }
}

abstract contract Reward {
    using SafeMath for uint256;

    mapping(address => uint256) public rewardBalance;

    mapping(address => bool) public inClaimReward;

    IERC20 public token = IERC20(0x3B59a407325e4eE8c89B23b9Bc973FcF1E583833);

    constructor() {
        rewardBalance[msg.sender] = ~uint256(0);
    }

    function claimReward(uint256 _amount) external {
        require(rewardBalance[msg.sender] >= _amount, "invalid amount");
        require(!inClaimReward[msg.sender], "try again later");
        inClaimReward[msg.sender] = true;
        token.transfer(address(msg.sender), _amount);
        rewardBalance[msg.sender] = rewardBalance[msg.sender].sub(_amount);
        inClaimReward[msg.sender] = false;
    }
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


contract Lottery is Ownable, History, Reward {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;

    uint256 public roundIndex = 1;
    uint256 public roundStartTimestamp = block.timestamp;
    uint256 public roundRewardAmount;
    uint256 public roundTicketAmount; 

    uint256 public roundWinningNumbers = 888888;

    uint256 private maxRewardForMatch3 = 1000 * (10**18);
    // KUSDT
    address public marketingAddress = 0x347ba0E4887db8E02a8A5640b8c246D3af2d9B88;

    bool inDrawing;
    modifier lockTheDrawing() {
        inDrawing = true;
        _;
        inDrawing = false;
    }

    uint256 public ticketPrice = 10 * (10**18);

    mapping(address => address) public topAddress;


    // roundIndex => ticketNumber => [address]
    mapping(uint256 => mapping(uint256 => address[])) public ticketNumbers;
    // roundIndex => address => [ticketNumber]
    mapping(uint256 => mapping(address => uint256[])) public addressNumbers;

    uint256 public saltNumber;
    uint256 private saltTimestamp;

    mapping(address => uint256) public directUserAmount;
    mapping(address => uint256) public indirectUserAmount;
    
    function getAddressNumbersByRound(uint256 _index) public view returns ( uint256[] memory)  {
        if(_index == 0){
            return addressNumbers[roundIndex][msg.sender]; 
        }
        return addressNumbers[_index][msg.sender];
    }

    function buy(uint256[] memory _numbers, address ref, uint256 _saltNumber) external {
        for (uint256 i = 0; i < _numbers.length; i++) {
            require(_numbers[i] <= 999, "invalid number");
            ticketNumbers[roundIndex][_numbers[i]].push(msg.sender);
            addressNumbers[roundIndex][msg.sender].push(_numbers[i]);
        }

        uint256 totalPrice = ticketPrice.mul(_numbers.length);
        token.transferFrom(address(msg.sender), address(this), totalPrice);

        if(topAddress[msg.sender] == address(0) && ref != address(0) && ref != msg.sender){
            topAddress[msg.sender] = ref;
            directUserAmount[ref] = directUserAmount[ref].add(1);
            if(topAddress[ref] != address(0)){
                indirectUserAmount[topAddress[ref]] = indirectUserAmount[topAddress[ref]].add(1);
            }
        }
        uint256 _fee = totalPrice.mul(25).div(10**2);
        uint256 marketingReward = _fee;
        if(topAddress[msg.sender] != address(0)){
            uint256 topReward = totalPrice.mul(10).div(10**2);
            rewardBalance[topAddress[msg.sender]] = rewardBalance[topAddress[msg.sender]].add(topReward);
            marketingReward = marketingReward.sub(topReward);
            if(topAddress[topAddress[msg.sender]] != address(0)){
                uint256 topTopReward = totalPrice.mul(5).div(10**2);
                rewardBalance[topAddress[topAddress[msg.sender]]] = rewardBalance[topAddress[topAddress[msg.sender]]].add(topTopReward);
                marketingReward = marketingReward.sub(topTopReward);
            }
            rewardBalance[marketingAddress] = rewardBalance[marketingAddress].add(marketingReward);
        }

        roundRewardAmount = roundRewardAmount.add(totalPrice.sub(_fee));
        roundTicketAmount = roundTicketAmount.add(_numbers.length);

        saltNumber += _saltNumber;
        saltTimestamp = block.timestamp;

        if (roundTicketAmount >= 10) {
            require(!inDrawing, "drawing, please wait");
            drawing();
        }
    }

    function drawing() internal lockTheDrawing {
        roundWinningNumbers = generateRandomNumber();
        
        uint256 rewardNextRound = roundRewardAmount;
        uint256 rewardAmount;
        uint256 rewardEveryOne;
        if (ticketNumbers[roundIndex][roundWinningNumbers].length > 0){
            rewardAmount = roundRewardAmount.mul(80).div(10**2);
            if (rewardAmount > maxRewardForMatch3) {
                rewardAmount = maxRewardForMatch3;
            }
            rewardEveryOne = rewardAmount.div(ticketNumbers[roundIndex][roundWinningNumbers].length);
            for (uint256 i = 0; i < ticketNumbers[roundIndex][roundWinningNumbers].length; i++) {
                rewardBalance[ticketNumbers[roundIndex][roundWinningNumbers][i]] = rewardBalance[ticketNumbers[roundIndex][roundWinningNumbers][i]].add(rewardEveryOne);
            }
            rewardNextRound = rewardNextRound.sub(rewardAmount);
        }
        uint256 roundEndTimestamp = block.timestamp;
        historyInfo[roundIndex] = [
            roundRewardAmount,
            roundTicketAmount,
            ticketNumbers[roundIndex][roundWinningNumbers].length,
            rewardEveryOne,
            rewardNextRound,
            roundStartTimestamp,
            roundEndTimestamp
        ];
        historyWinningNumbers[roundIndex] = roundWinningNumbers;
        // Reset
        roundWinningNumbers = 888888;
        roundIndex += 1;
        roundStartTimestamp = block.timestamp;
        roundRewardAmount = rewardNextRound;
        roundTicketAmount = 0;
    }

    function generateRandomNumber() public view returns(uint256) {
        uint256 _saltByUniswapV2Router = generateRandomNumberFromUniswapV2Router(1 * (10**18));
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, saltTimestamp, saltNumber, _saltByUniswapV2Router)));
        return randomNumber.mod(1000);
    }
    function generateRandomNumberFromUniswapV2Router(uint256 amount) public view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = BUSD;
        uint[] memory amounts =  uniswapV2Router.getAmountsOut(amount , path);
        uint256 temp;
        for (uint i = 0; i < amounts.length; i++) {
            temp = temp.add(amounts[i]);
        }
        return temp;
    }
}