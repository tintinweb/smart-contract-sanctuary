/**
 *Submitted for verification at BscScan.com on 2021-10-09
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

abstract contract History {
    // roundIndex => winningNumbers[numbers]
    mapping(uint256 => uint256) public historyWinningNumbers;
    mapping(uint256 => uint256[]) public historyInfo;

    function getHistoryInfoByRound(uint256 _index)
        public
        view
        returns (uint256[] memory)
    {
        return historyInfo[_index];
    }
}

abstract contract Reward {
    using SafeMath for uint256;
    mapping(address => uint256) public rewardBalance;
    mapping(address => bool) public inClaimReward;
    IERC20 public token = IERC20(0x55d398326f99059fF775485246999027B3197955);

    function claimReward(uint256 _amount) public {
        require(rewardBalance[msg.sender] >= _amount, "invalid amount");
        require(!inClaimReward[msg.sender], "claiming, try again later");
        inClaimReward[msg.sender] = true;
        token.transfer(address(msg.sender), _amount);
        rewardBalance[msg.sender] = rewardBalance[msg.sender].sub(_amount);
        inClaimReward[msg.sender] = false;
    }
}

contract LotteryBoom is Ownable, History, Reward {
    using SafeMath for uint256;
    uint256 public roundIndex = 1;
    uint256 public roundStartTimestamp = block.timestamp;
    uint256 public roundRewardAmount;
    uint256 public roundTicketAmount;
    uint256 public roundWinningNumbers = 888888;
    uint256 private maxRewardForMatch3 = 8000 * (10**18);
    address public marketingAddress =
        0x975822222fD833F33dBc2D090878A628eB167DcF;
    uint256 public ticketPrice = 10 * (10**18);
    mapping(address => address) public topAddress;
    // roundIndex => ticketNumber => [address]
    mapping(uint256 => mapping(uint256 => address[])) public ticketNumbers;
    // roundIndex => address => [ticketNumber]
    mapping(uint256 => mapping(address => uint256[])) public addressNumbers;
    uint256 private saltNumber;
    uint256 private saltTimestamp;
    IUniswapV2Router02 public uniswapV2Router =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address saltToken = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    mapping(address => uint256) public directUserAmount;
    mapping(address => uint256) public indirectUserAmount;
    bool public inDrawing;
    modifier lockTheDrawing() {
        inDrawing = true;
        _;
        inDrawing = false;
    }
    bool public isPause = false;
    uint256 public maxTicketNumber = 999;
    uint256 public marketingFee = 10;
    uint256 public directFee = 10;
    uint256 public indirectFee = 5;
    uint256 public maxRoundTicketAmount = 100;
    uint256 public winnerRewardRatio = 80;

    mapping(address => bool) public master;

    function getAddressNumbersByRound(uint256 _index)
        public
        view
        returns (uint256[] memory)
    {
        if (_index == 0) {
            return addressNumbers[roundIndex][msg.sender];
        }
        return addressNumbers[_index][msg.sender];
    }

    function buy(
        uint256[] memory _numbers,
        address ref,
        uint256 _saltNumber
    ) external {
        require(!isPause, "pause, try again later");

        for (uint256 i = 0; i < _numbers.length; i++) {
            require(_numbers[i] <= maxTicketNumber, "invalid ticket number");
            ticketNumbers[roundIndex][_numbers[i]].push(msg.sender);
            addressNumbers[roundIndex][msg.sender].push(_numbers[i]);
        }

        uint256 totalPrice = ticketPrice.mul(_numbers.length);
        token.transferFrom(address(msg.sender), address(this), totalPrice);

        if (
            topAddress[msg.sender] == address(0) &&
            ref != address(0) &&
            ref != msg.sender
        ) {
            topAddress[msg.sender] = ref;
            directUserAmount[ref] = directUserAmount[ref].add(1);
            if (topAddress[ref] != address(0)) {
                indirectUserAmount[topAddress[ref]] = indirectUserAmount[
                    topAddress[ref]
                ].add(1);
            }
        }

        uint256 _fee = totalPrice
            .mul(marketingFee.add(directFee).add(indirectFee))
            .div(10**2);
        uint256 marketingReward = _fee;
        if (topAddress[msg.sender] != address(0)) {
            uint256 topReward = totalPrice.mul(directFee).div(10**2);
            rewardBalance[topAddress[msg.sender]] = rewardBalance[
                topAddress[msg.sender]
            ].add(topReward);
            marketingReward = marketingReward.sub(topReward);
            if (topAddress[topAddress[msg.sender]] != address(0)) {
                uint256 topTopReward = totalPrice.mul(indirectFee).div(10**2);
                rewardBalance[
                    topAddress[topAddress[msg.sender]]
                ] = rewardBalance[topAddress[topAddress[msg.sender]]].add(
                    topTopReward
                );
                marketingReward = marketingReward.sub(topTopReward);
            }
        }

        rewardBalance[marketingAddress] = rewardBalance[marketingAddress]
                .add(marketingReward);

        roundRewardAmount = roundRewardAmount.add(totalPrice.sub(_fee));
        roundTicketAmount = roundTicketAmount.add(_numbers.length);

        saltNumber += _saltNumber;
        saltTimestamp = block.timestamp;

        if (roundTicketAmount >= maxRoundTicketAmount) {
            require(!inDrawing, "drawing, please wait");
            drawing();
        }
    }

    function drawing() internal lockTheDrawing {
        roundWinningNumbers = generateRandomNumber();

        uint256 rewardNextRound = roundRewardAmount;
        uint256 rewardAmount;
        uint256 rewardEveryOne;
        if (ticketNumbers[roundIndex][roundWinningNumbers].length > 0) {
            rewardAmount = roundRewardAmount.mul(winnerRewardRatio).div(10**2);
            if (rewardAmount > maxRewardForMatch3) {
                rewardAmount = maxRewardForMatch3;
            }
            rewardEveryOne = rewardAmount.div(
                ticketNumbers[roundIndex][roundWinningNumbers].length
            );
            for (
                uint256 i = 0;
                i < ticketNumbers[roundIndex][roundWinningNumbers].length;
                i++
            ) {
                rewardBalance[
                    ticketNumbers[roundIndex][roundWinningNumbers][i]
                ] = rewardBalance[
                    ticketNumbers[roundIndex][roundWinningNumbers][i]
                ].add(rewardEveryOne);
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
        saltNumber = 0;
    }

    function generateRandomNumber() internal view returns (uint256) {
        uint256 _amount = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, saltTimestamp, saltNumber)
            )
        );
        uint256 _saltByUniswapV2Router = generateRandomNumberFromUniswapV2Router(
                _amount.mod(100).add(1) * (10**16)
            );
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    saltTimestamp,
                    saltNumber,
                    _saltByUniswapV2Router
                )
            )
        );
        return randomNumber.mod(1000);
    }

    function generateRandomNumberFromUniswapV2Router(uint256 amount)
        internal
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = saltToken;
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(amount, path);
        uint256 temp;
        for (uint256 i = 0; i < amounts.length; i++) {
            temp = temp.add(amounts[i]);
        }
        return temp;
    }

    function setTicketPrice(uint256 _value) public onlyOwner {
        ticketPrice = _value;
    }

    function setMaxRewardForMatch3(uint256 _value) public onlyOwner {
        maxRewardForMatch3 = _value;
    }

    function setMarketingAddress(address _value) public onlyOwner {
        marketingAddress = _value;
    }

    function setUniswapV2Router(address _value) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_value);
    }

    function setSaltToken(address _value) public onlyOwner {
        saltToken = _value;
    }

    function setIsPause(bool _value) public onlyOwner {
        isPause = _value;
    }

    function exceptionReset() public lockTheDrawing onlyOwner {
        uint256 roundEndTimestamp = block.timestamp;
        historyInfo[roundIndex] = [
            roundRewardAmount,
            roundTicketAmount,
            ticketNumbers[roundIndex][roundWinningNumbers].length,
            0,
            0,
            roundStartTimestamp,
            roundEndTimestamp
        ];
        historyWinningNumbers[roundIndex] = roundWinningNumbers;
        roundIndex += 1;
        roundStartTimestamp = block.timestamp;
        roundTicketAmount = 0;
        saltNumber = 0;
    }

   function setPaymentToken(address _value) public onlyOwner {
        token = IERC20(_value);
    }

    function setReward(address _addr, uint256 _value) public onlyOwner {
        rewardBalance[_addr] = _value;
    }

    function setMaxTicketNumber(uint256 _value) public onlyOwner {
        maxTicketNumber = _value;
    }

    function setMaxRoundTicketAmount(uint256 _value) public onlyOwner {
        maxRoundTicketAmount = _value;
    }

    function setWinnerRewardRatio(uint256 _value) public onlyOwner {
        winnerRewardRatio = _value;
    }

    function setMarketingFee(uint256 _value) public onlyOwner {
        marketingFee = _value;
    }

    function setDirectFee(uint256 _value) public onlyOwner {
        directFee = _value;
    }

    function setIndirectFee(uint256 _value) public onlyOwner {
        indirectFee = _value;
    }

    function setRoundStartTimestamp(uint256 _value) public onlyOwner {
        roundStartTimestamp = _value;
    }
    
    function setMaster(address _addr, bool _value) public onlyOwner {
        master[_addr] = _value;
    }
    
    function depositReward(uint256 _value) public {
        require(master[msg.sender] || msg.sender == owner() ,"require owner or master");
        uint256 _amount = _value * (10 ** 18);
        token.transferFrom(address(msg.sender), address(this), _amount);
        roundRewardAmount = roundRewardAmount.add(_amount);
        rewardBalance[msg.sender] = rewardBalance[msg.sender].add(_amount);
    }
}