pragma solidity >=0.6.2;

import './interfaces/IFlashLoanV1Factory.sol';
import './interfaces/IFlashLoanV1Pool.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import "erc3156/contracts/interfaces/IERC3156FlashBorrower.sol";
import "erc3156/contracts/interfaces/IERC3156FlashLender.sol";
import './interfaces/IFlashLoanReceiver.sol';
import './interfaces/IFlashLoanV1Router.sol';
import './libraries/FlashLoanV1Library.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';

contract FlashLoanV1Router02 is IFlashLoanV1Router, IERC3156FlashLender, IFlashLoanReceiver {
    using SafeMath for uint;

    // CONSTANTS
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'FlashLoanV1Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function addLiquidity(
        address token,
        uint amount,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint liquidity) {
        if (IFlashLoanV1Factory(factory).getPool(token) == address(0)) {
            IFlashLoanV1Factory(factory).createPool(token);
        }
        address pool = FlashLoanV1Library.poolFor(factory, token);
        TransferHelper.safeTransferFrom(token, msg.sender, pool, amount);
        liquidity = IFlashLoanV1Pool(pool).mint(to);
    }
    function addLiquidityETH(
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint liquidity) {
        if (IFlashLoanV1Factory(factory).getPool(WETH) == address(0)) {
            IFlashLoanV1Factory(factory).createPool(WETH);
        }
        address pool = FlashLoanV1Library.poolFor(factory, WETH);
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pool, msg.value));
        liquidity = IFlashLoanV1Pool(pool).mint(to);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address token,
        uint liquidity,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amount) {
        address pool = FlashLoanV1Library.poolFor(factory, token);
        IFlashLoanV1Pool(pool).transferFrom(msg.sender, pool, liquidity);
        amount = IFlashLoanV1Pool(pool).burn(to);
    }
    function removeLiquidityETH(
        uint liquidity,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        amountETH = removeLiquidity(WETH, liquidity, address(this), deadline);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address token,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amount) {
        address pool = FlashLoanV1Library.poolFor(factory, token);
        uint value = approveMax ? uint(-1) : liquidity;
        IFlashLoanV1Pool(pool).permit(msg.sender, address(this), value, deadline, v, r, s);
        amount = removeLiquidity(token, liquidity, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pool = FlashLoanV1Library.poolFor(factory, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IFlashLoanV1Pool(pool).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETH(liquidity, to, deadline);
    }

    /**
     * @dev From ERC-3156. The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view override returns (uint256) {
        address poolAddress = FlashLoanV1Library.poolFor(factory, token);
        if (poolAddress != address(0)) {
            uint256 balance = IERC20(token).balanceOf(poolAddress);
            if (balance > 0) return balance - 1;
        }
        return 0;
    }

    /**
     * @dev From ERC-3156. The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        require(FlashLoanV1Library.poolFor(factory, token) != address(0), "Unsupported currency");
        uint feeInBips = IFlashLoanV1Factory(factory).feeInBips();
        return amount.mul(feeInBips) / 10000;
    }

    /**
     * @dev From ERC-3156. Loan `amount` tokens to `receiver`, which needs to return them plus fee to this contract within the same transaction.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param userData A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token, uint256 amount,
        bytes calldata userData
    ) external override virtual returns(bool) {
        address poolAddress = FlashLoanV1Library.poolFor(factory, token);
        require(poolAddress != address(0), "Unsupported currency");

        bytes memory data = abi.encode(
          msg.sender,
          receiver,
          userData
        );
        IFlashLoanV1Pool(poolAddress).flashLoan(address(this), amount, data);
        return true;
    }

    /// @dev deerfi flash loan callback. It sends the amount borrowed to `receiver`, and takes it back plus a `flashFee` after the ERC3156 callback.
    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address sender,
        bytes calldata data
    ) external override returns (bool) {
        require(msg.sender == FlashLoanV1Library.poolFor(factory, token), "only DeerfiV1 pool can call");
        require(sender == address(this), "Callbacks only initiated from this contract");

        (address origin, IERC3156FlashBorrower receiver, bytes memory userData) = 
            abi.decode(data, (address, IERC3156FlashBorrower, bytes));

        // Send the tokens to the original receiver using the ERC-3156 interface
        IERC20(token).transfer(address(receiver), amount);
        // do whatever the user wants
        require(
            receiver.onFlashLoan(origin, token, amount, fee, userData) == CALLBACK_SUCCESS,
            "Callback failed"
        );
        // retrieve the borrowed amount plus fee from the receiver and send it to the deerfi pool
        IERC20(token).transferFrom(address(receiver), msg.sender, amount.add(fee));

        return true;
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity =0.6.6;

interface IFlashLoanReceiver {
    function executeOperation(
        address asset,
        uint amount,
        uint premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

pragma solidity >=0.5.0;

interface IFlashLoanV1Factory {
    event PoolCreated(address indexed token, address pool, uint);

    function feeInBips() external view returns (uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPool(address token) external view returns (address pool);
    function allPools(uint) external view returns (address pool);
    function allPoolsLength() external view returns (uint);

    function createPool(address token) external returns (address pool);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IFlashLoanV1Pool {
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

    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount, address indexed to);
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint amount,
        uint premium
    );
    event Sync(uint reserve);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token() external view returns (address);
    function reserve() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount);
    function flashLoan(address target, uint amount, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address) external;
}

pragma solidity >=0.6.2;

interface IFlashLoanV1Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address token,
        uint amount,
        address to,
        uint deadline
    ) external returns (uint liquidity);
    function addLiquidityETH(
        address to,
        uint deadline
    ) external payable returns (uint liquidity);
    function removeLiquidity(
        address token,
        uint liquidity,
        address to,
        uint deadline
    ) external returns (uint amount);
    function removeLiquidityETH(
        uint liquidity,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityWithPermit(
        address token,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amount);
    function removeLiquidityETHWithPermit(
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.5.0;

import "./SafeMath.sol";

library FlashLoanV1Library {
    using SafeMath for uint;

    // calculates the CREATE2 address for a pool without making any external calls
    function poolFor(address factory, address token) internal pure returns (address pool) {
        pool = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token)),
                hex'6c57ed802dc5d4d6ce04dc39f66e6d2a6cebf8b7efbc068ce7b0419f5ee4ade1' // init code hash
            ))));
    }
}

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;


interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;
import "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}