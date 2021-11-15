// contracts/LowbVoucher.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "./IPancakePair.sol";
import "./IPancakeRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BorrowLowb {
    
    /* Inverse basis point. */
    uint public constant INVERSE_BASIS_POINT = 100000000000;
    uint public constant MAXIMUM_FEE = 100000;
    uint public commission = 2e18;
    uint public feePerBlock;
    uint totalDeposit;
    
    struct Record {
        address prevUser;
        address nextUser;
        uint lowbAmount;
        uint usdtAmount;
        uint startBlock;
        uint feePerBlock;
    }
    
    address public owner;
    address public routerAddress;
    address public lpAddress;
    address public usdtAddress;
    address public lowbAddress;
    address[] public usdtToLowbPath;
    
    mapping (address => uint) public balanceOf;
    mapping (address => Record) public recordOf;

    // Emitted events
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event LowbBorrowed(address indexed user, uint lowbAmount, uint usdtAmount);
    event ReturnAllLowb(address indexed user, uint lowbAmount, uint usdtAmount, uint interestAmount);
    event AddUsdt(address indexed user, uint amount);
    event MoreLowbBorrowed(address indexed user, uint amount);

    constructor(address lpAddress_, address routerAddress_) {
        lpAddress = lpAddress_;
        routerAddress = routerAddress_;
        owner = msg.sender;
        IPancakePair pair = IPancakePair(lpAddress_);
        usdtAddress = pair.token0();
        lowbAddress = pair.token1();
        usdtToLowbPath.push(usdtAddress);
        usdtToLowbPath.push(lowbAddress);
    }

    function getInterestOf(address user) public view returns (uint) {
        return recordOf[user].lowbAmount * recordOf[user].feePerBlock * (block.number - recordOf[user].startBlock) / INVERSE_BASIS_POINT;
    }

    function getRiskNumberOf(address user) public view returns (uint) {
        uint lowbAmount = recordOf[user].lowbAmount;
        uint usdtAmount = recordOf[user].usdtAmount;
        IPancakePair pair = IPancakePair(lpAddress);
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, ) = pair.getReserves();
        return reserve0 * lowbAmount / reserve1 * INVERSE_BASIS_POINT / usdtAmount;
    }

    function setFee(uint fee_) public {
        require(msg.sender == owner, "You are not admin");
        require(fee_ < MAXIMUM_FEE, "Fee to high");
        feePerBlock = fee_;
    }
    
    function deposit(uint amount) public {
        require(amount > 0, "You deposit nothing!");
        IERC20 token = IERC20(lowbAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Lowb transfer failed");
        balanceOf[msg.sender] +=  amount;
        totalDeposit += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint amount) public {
        require(amount <= balanceOf[msg.sender], "amount larger than the balance");  
        balanceOf[msg.sender] -= amount;
        IERC20 token = IERC20(lowbAddress);
        require(token.transfer(msg.sender, amount), "Lowb transfer failed");
        totalDeposit -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function borrowLowb(uint lowbAmount, uint usdtAmount) public {
        require(lowbAmount > 0, "You borrow nothing!");
        require(usdtAmount >= 50e18, "Not enough usdt!");
        recordOf[msg.sender] = Record(address(0), address(0), lowbAmount, usdtAmount, block.number, feePerBlock);
        require(getRiskNumberOf(msg.sender) < INVERSE_BASIS_POINT * 90/100, "borrow to much lowb!");
        IERC20 lowb = IERC20(lowbAddress);
        IERC20 usdt = IERC20(usdtAddress);
        require(usdt.transferFrom(msg.sender, address(this), usdtAmount), "usdt transfer failed");
        require(lowb.transfer(msg.sender, lowbAmount), "lowb transfer failed");
        _addRecords(msg.sender);
        emit LowbBorrowed(msg.sender, lowbAmount, usdtAmount);
    }

    function addMoreUsdt(uint amount) public {
        require(amount > 0, "You add nothing!");
        IERC20 token = IERC20(usdtAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "usdt transfer failed");
        recordOf[msg.sender].usdtAmount += amount;
        emit AddUsdt(msg.sender, amount);
    }

    function borrowMoreLowb(uint amount) public {
        require(amount > 0, "You borrow nothing!");
        uint interest = getInterestOf(msg.sender);
        _removeRecords(msg.sender);
        recordOf[msg.sender].lowbAmount += (amount + interest);
        require(getRiskNumberOf(msg.sender) < INVERSE_BASIS_POINT * 90/100, "borrow to much lowb!");
        _addRecords(msg.sender);
        IERC20 token = IERC20(lowbAddress);
        require(token.transfer(msg.sender, amount), "lowb transfer failed");
        recordOf[msg.sender].startBlock = block.number;
        emit MoreLowbBorrowed(msg.sender, amount);
    }

    function _addRecords(address newUser) private {
        uint price = recordOf[newUser].lowbAmount / recordOf[newUser].usdtAmount;
        address user = recordOf[address(0)].nextUser;
        while (user != address(0)) {
            if (price >= recordOf[user].lowbAmount / recordOf[user].usdtAmount) {
                address prevUser = recordOf[user].prevUser;
                recordOf[user].prevUser = user;
                recordOf[newUser].nextUser = user;
                recordOf[newUser].prevUser = prevUser;
                recordOf[prevUser].nextUser = newUser;
                return;
            }
            user = recordOf[user].nextUser;
        }
        recordOf[user].nextUser = newUser;
        recordOf[newUser].prevUser = user;
    }

    function _removeRecords(address user) private {
        address prevUser = recordOf[user].prevUser;
        address nextUser = recordOf[user].nextUser;
        recordOf[prevUser].nextUser = nextUser;
        recordOf[nextUser].prevUser = prevUser;
    }

    function _returnAllLowb(address user) private {
        IERC20 lowb = IERC20(lowbAddress);
        IERC20 usdt = IERC20(usdtAddress);
        uint interest = getInterestOf(user);
        emit ReturnAllLowb(user, recordOf[user].lowbAmount, recordOf[user].usdtAmount, interest);
        require(lowb.transferFrom(msg.sender, address(this), recordOf[user].lowbAmount + interest), "lowb transfer failed");
        require(usdt.transfer(msg.sender, recordOf[user].usdtAmount), "usdt transfer failed");
        _removeRecords(user);
        recordOf[user] = Record(address(0), address(0), 0, 0, 0, 0);
    }

    function returnAllLowb() public {
        require(recordOf[msg.sender].lowbAmount > 0, "You return nothing!");
        _returnAllLowb(msg.sender);
    }

    function forceReturnAllLowb(address user) public {
        require(getRiskNumberOf(user) > INVERSE_BASIS_POINT * 95/100, "cannot force return for now!");
        _returnAllLowb(user);
    }

    function lockUsdt(address user) public {
        require(user != address(0), "invaild user address");
        require(getRiskNumberOf(user) > INVERSE_BASIS_POINT * 95/100, "cannot lock usdt for now!");
        recordOf[address(0)].lowbAmount += (recordOf[user].lowbAmount + getInterestOf(user));
        recordOf[address(0)].usdtAmount += (recordOf[user].usdtAmount - commission);
        _removeRecords(user);
        recordOf[user] = Record(address(0), address(0), 0, 0, 0, 0);
        IERC20 usdt = IERC20(usdtAddress);
        require(usdt.transfer(msg.sender, commission), "usdt transfer failed");
    }

    function buyBackLowb(uint amount) public {
        require(amount > 0 && amount <= recordOf[address(0)].usdtAmount, "invaild user address");
        uint minLowbAmount = amount * recordOf[address(0)].lowbAmount / recordOf[address(0)].usdtAmount;
        uint lowbCommission = minLowbAmount / 100;
        IPancakeRouter01 router = IPancakeRouter01(routerAddress);
        router.swapExactTokensForTokens(amount, minLowbAmount+lowbCommission, usdtToLowbPath, address(this), block.number+100);
        recordOf[address(0)].usdtAmount -= amount;
        recordOf[address(0)].lowbAmount -= minLowbAmount;
        IERC20 lowb = IERC20(lowbAddress);
        require(lowb.transfer(msg.sender, lowbCommission), "lowb transfer failed");
    }

    function getRecords(address user, uint n) public view returns (Record[] memory) {
        require(n > 0, "Invalid record number");
        Record[] memory records = new Record[](n);
        Record memory record = recordOf[user];
        for (uint i=0; i<n; i++) {
            records[i] = record;
            if (record.nextUser == address(0)) {
                break;
            }
            else {
                record = recordOf[record.nextUser];
            }
        }
        return records;
    }

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

// contracts/IPancakeRouter.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeRouter01 {
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

// contracts/IPancakePair.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakePair {
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

