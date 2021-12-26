// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 val) internal {
        (bool success,) = to.call{value : val}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IOwnable {
    function policy() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyPolicy() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

interface IDepositor {
    function deposit(uint _amount, uint _maxPrTIME, address _depositor) external returns (uint);

    function payoutFor(uint _value) external view returns (uint);
}

interface ISwapV2Pair {

    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint256);
}

interface ISwapV2Router {

    function factory() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
    external
    returns (
        uint amountA,
        uint amountB,
        uint liquidity
    );

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

}

interface ISwapV2Factory {
    function factory() external pure returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ITreasury {
    function valueOfToken(address _token, uint _amount) external view returns (uint value_);
}

contract DepositHelper is Ownable {
    using SafeToken for address;
    using SafeMath for uint256;

    address public immutable deposit;
    address public immutable MIN;
    address public TIME; //
    ISwapV2Factory public immutable factory;
    ISwapV2Router public immutable router;
    address public immutable principle;
    ITreasury public immutable treasury;
    address public immutable _tokenA;
    address public immutable _tokenB;


    constructor (address _deposit, ISwapV2Router _router, address _principle, address _TIME, address _MIN, ITreasury _treasury) {
        require(_deposit != address(0));
        deposit = _deposit;
        require(_TIME != address(0));
        TIME = _TIME;
        _tokenA = _TIME;
        require(_MIN != address(0));
        MIN = _MIN;
        _tokenB = _MIN;
        factory = ISwapV2Factory(_router.factory());
        router = _router;
        principle = _principle;
        treasury = _treasury;
    }


    function depositHelper(
        uint _amount,
        uint _maxPrTIME,
        address _tokenAddress
    ) external payable returns (uint) {
        uint256 payout = 0;
        if (_tokenAddress == principle) {
            principle.safeTransferFrom(msg.sender, address(this), _amount);
            principle.safeApprove(address(deposit), _amount);
            payout = IDepositor(deposit).deposit(_amount, _maxPrTIME, msg.sender);
            return payout;
        } else {
            require(_tokenAddress == _tokenA || _tokenAddress == _tokenB ,"_tokenAddress err");
            if(_tokenAddress == _tokenA){
                _tokenA.safeTransferFrom(msg.sender, address(this), _amount);
                _tokenA.safeApprove(address(router), uint256(- 1));
            }else{
                _tokenB.safeTransferFrom(msg.sender, address(this), _amount);
                _tokenB.safeApprove(address(router), uint256(- 1));
            }            
            TIME.safeApprove(address(router), uint256(- 1));

            ISwapV2Pair lpToken = ISwapV2Pair(factory.getPair(_tokenA, _tokenB));   
            require(address(lpToken) != address(0),"not Pair");
            calAndSwap(lpToken,_tokenA,_tokenB);

            (,, uint256 moreLPAmount) = router.addLiquidity(MIN, TIME, MIN.myBalance(), TIME.myBalance(), 0, 0, address(this), block.timestamp);
            principle.safeApprove(address(deposit), moreLPAmount);
            if (MIN.myBalance() > 0) {
                MIN.safeTransfer(msg.sender, MIN.myBalance());
            }
            if (TIME.myBalance() > 0) {
                TIME.safeTransfer(msg.sender, TIME.myBalance());
            }
            payout = IDepositor(deposit).deposit(moreLPAmount, _maxPrTIME, msg.sender);
            return payout;
        }
    }

    function depositValue(uint256 _amount) public view returns (uint256 value_) {
        ISwapV2Pair lpToken = ISwapV2Pair(factory.getPair(MIN, TIME));
        (uint256 token0Reserve, uint256 token1Reserve,) = lpToken.getReserves();
        (uint256 debtReserve, uint256 relativeReserve) = MIN ==
        lpToken.token0() ? (token0Reserve, token1Reserve) : (token1Reserve, token0Reserve);
        (uint256 swapAmt, bool isReversed) = optimalDeposit(_amount, 0,
            debtReserve, relativeReserve);
        if (swapAmt > 0) {
            address[] memory path = new address[](2);
            (path[0], path[1]) = isReversed ? (TIME, MIN) : (MIN, TIME);
            uint[] memory amounts = router.getAmountsOut(swapAmt, path);
            (uint256 amount0, uint256 amount1) = MIN == lpToken.token0() ? (_amount.sub(swapAmt), amounts[1]) : (amounts[1], _amount.sub(swapAmt));
            uint256 _totalSupply = lpToken.totalSupply();
            uint256 lpAmount = Math.min(amount0.mul(_totalSupply) / token0Reserve, amount1.mul(_totalSupply) / token1Reserve);
            uint256 value = treasury.valueOfToken(address(lpToken), lpAmount);
            value_ = IDepositor(deposit).payoutFor(value);
            return value_;
        }
        return 0;
    }

    /// Compute amount and swap between borrowToken and tokenRelative.
    function calAndSwap(ISwapV2Pair lpToken,address tokenA,address tokenB) internal {
        (uint256 token0Reserve, uint256 token1Reserve,) = lpToken.getReserves();
        (uint256 debtReserve, uint256 relativeReserve) = _tokenA ==
        lpToken.token0() ? (token0Reserve, token1Reserve) : (token1Reserve, token0Reserve);
        (uint256 swapAmt, bool isReversed) = optimalDeposit(_tokenA.myBalance(), _tokenB.myBalance(),
            debtReserve, relativeReserve);

        if (swapAmt > 0) {
            address[] memory path = new address[](2);
            (path[0], path[1]) = isReversed ? (tokenB, tokenA) : (tokenA, tokenB);
            router.swapExactTokensForTokens(swapAmt, 0, path, address(this), block.timestamp);
        }
    }

    function optimalDeposit(
        uint256 amtA,
        uint256 amtB,
        uint256 resA,
        uint256 resB
    ) internal pure returns (uint256 swapAmt, bool isReversed) {
        if (amtA.mul(resB) >= amtB.mul(resA)) {
            swapAmt = _optimalDepositA(amtA, amtB, resA, resB);
            isReversed = false;
        } else {
            swapAmt = _optimalDepositA(amtB, amtA, resB, resA);
            isReversed = true;
        }
    }

    function _optimalDepositA(
        uint256 amtA,
        uint256 amtB,
        uint256 resA,
        uint256 resB
    ) internal pure returns (uint256) {
        require(amtA.mul(resB) >= amtB.mul(resA), "Reversed");

        uint256 a = 997;
        uint256 b = uint256(1997).mul(resA);
        uint256 _c = (amtA.mul(resB)).sub(amtB.mul(resA));
        uint256 c = _c.mul(1000).div(amtB.add(resB)).mul(resA);

        uint256 d = a.mul(c).mul(4);
        uint256 e = Math.sqrt(b.mul(b).add(d));

        uint256 numerator = e.sub(b);
        uint256 denominator = a.mul(2);

        return numerator.div(denominator);
    }
}