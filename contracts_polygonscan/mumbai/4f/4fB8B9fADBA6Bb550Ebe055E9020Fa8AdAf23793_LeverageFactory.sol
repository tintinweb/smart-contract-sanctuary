//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IAAVE.sol";
import "./interfaces/ICamDAI.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IQuickswapV2Router02.sol";
import "./interfaces/IUniswapV2Callee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LeverageFactory {

    mapping(address => address[]) public index;

    function createNew() external returns (address) {
        camDaiLeverage _camDaiLeverage = new camDaiLeverage(msg.sender);
        address contractAddress = address(_camDaiLeverage);
        index[msg.sender].push(contractAddress);
        return contractAddress;
    }

    function getContractAddresses(address account) external view returns (address[] memory) {
        return index[account];
    }

}

contract camDaiLeverage is Ownable, IUniswapV2Callee {

    IERC20 private DAI = IERC20(0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F);
    IERC20 private amDAI = IERC20(0x639cB7b21ee2161DF9c882483C9D55c90c20Ca3e);
    IERC20 private MAI = IERC20(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1);
    IERC20 private USDC = IERC20(0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e);
    ICamDAI private camDAI = ICamDAI(0xE6C23289Ba5A9F0Ef31b8EB36241D5c800889b7b);

    IAAVE private AAVE = IAAVE(0x341d1f30e77D3FBfbD43D17183E2acb9dF25574E);
    IVault private vault = IVault(0xD2FE44055b5C874feE029119f70336447c8e8827);
    IQuickswapV2Router02 private QuickswapV2Router02 = IQuickswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    IUniswapV2Factory private  QuickswapFactory = IUniswapV2Factory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);

    uint public vaultID;
    uint constant private max = type(uint256).max;

    constructor (address _newOwner) {
        //Create vault
        vaultID = vault.createVault();
        //Approves
        DAI.approve(address(AAVE), max);
        amDAI.approve(address(camDAI), max);
        camDAI.approve(address(vault), max);
        MAI.approve(address(vault), max);
        MAI.approve(address(QuickswapV2Router02), max);
        DAI.approve(address(QuickswapV2Router02), max);
        //Transfer ownership
        transferOwnership(_newOwner);
    }

    function _triggerFlash(IERC20 tokenA, IERC20 tokenB, uint amountA, uint amountB, uint _type) internal {
        address pair = QuickswapFactory.getPair(address(tokenA), address(tokenB));
        require(pair != address(0), "zeroAddress");
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint amount0Out = address(tokenA) == token0 ? amountA : amountB;
        uint amount1Out = address(tokenA) == token1 ? amountA : amountB;

        // need to pass some data to trigger uniswapV2Call
        bytes memory data = abi.encode(token0, token1, _type);

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function _calculateFlashLoanFee(uint flashAmount) internal pure returns (uint, uint) {
        if (flashAmount == 0) {
            return (0, 0);
        }
        // about 0.3%
        uint fee = ((flashAmount * 3) / 997) + 1;
        uint amountToRepay = flashAmount + fee;
        return (amountToRepay, fee); // (flashAmount + fee, fee)
    }

    function _calculateOnePercent(uint amount) internal pure returns (uint) {
        //Return 1% of amount
        uint _100 = 100e18;
        uint _1 = 1e18;
        return ((amount * _1) / _100);
    }

    function _getAmountsIn(uint amountOut, IERC20 _in, IERC20 _out) internal view returns (uint) {
        //Calculate how much `_in` do you need for receiving an specified amount of `_out`
        address[] memory path = new address[](2);
        path[0] = address(_in);
        path[1] = address(_out);

        uint256[] memory amountsIn = QuickswapV2Router02.getAmountsIn(
            amountOut,
            path
        );

        return amountsIn[0];
    }

    function _swap(IERC20 _in, IERC20 _out) internal {
        //swap in -> out
        uint256 _inBalance = _in.balanceOf(address(this));

        if (_inBalance != 0) {
            address[] memory path = new address[](2);
            path[0] = address(_in);
            path[1] = address(_out);

            uint256[] memory amountsOut = QuickswapV2Router02.getAmountsOut(
                _inBalance,
                path
            );

            uint256 minAmount = amountsOut[1] - _calculateOnePercent(amountsOut[1]); // 1% slippage
            address receiver = address(this);

            QuickswapV2Router02.swapExactTokensForTokens(
                _inBalance,
                minAmount,
                path,
                receiver,
                block.timestamp
            );
        }

    }

    function _doRuloInternal(uint feeA) internal {
        address thisContract = address(this);
        uint totalCollateral = DAI.balanceOf(thisContract);
        AAVE.deposit(address(DAI), totalCollateral, thisContract, 0);
        camDAI.enter(amDAI.balanceOf(thisContract));
        uint toDeposit = camDAI.balanceOf(thisContract);
        vault.depositCollateral(vaultID, toDeposit);
        uint toBorrow = (totalCollateral / (vault._minimumCollateralPercentage() + 10)) * 100; //10% secure
        uint enoughAmount = _getAmountsIn(toBorrow + feeA, MAI, DAI); //Borrow enough MAI to not be short
        vault.borrowToken(vaultID, enoughAmount + _calculateOnePercent(enoughAmount)); //Borrow 1% cause slippage o the next line
        _swap(MAI, DAI);
    }

    function _undoRuloInternal() internal {
        address thisContract = address(this);

        uint debt = getVaultDebt();
        if (debt != 0) {
            vault.payBackToken(vaultID, debt);
            vault.withdrawCollateral(vaultID, getVaultCollateral());
            camDAI.leave(camDAI.balanceOf(thisContract));
            AAVE.withdraw(address(DAI), max, thisContract);
            _swap(DAI, MAI);
        }
    }

    function doRulo(uint amount) external onlyOwner {
        DAI.transferFrom(msg.sender, address(this), amount);
        uint optimalAmount = (amount * 100) / ((vault._minimumCollateralPercentage() + 10) - 100); //Optimal amount formula: see calc.py
        require(optimalAmount <= vault.getDebtCeiling(), "!debtCeiling");
        _triggerFlash(DAI, USDC, optimalAmount, 0, 0);
    }

    function undoRulo() external onlyOwner {
        require(getVaultDebt() > 0, "there is no rulo to undo");
        _triggerFlash(MAI, USDC, getVaultDebt(), 0, 1);
        //Close position, send DAI to owner
        _swap(MAI, DAI); // !! can be optimized
        DAI.transfer(owner(), DAI.balanceOf(address(this)));
        MAI.transfer(owner(), MAI.balanceOf(address(this)));
    }

    function transferTokens(address _tokenAddress) external onlyOwner {
        //Used for "rescue" tokens
        IERC20(_tokenAddress).transfer(owner(), IERC20(_tokenAddress).balanceOf(address(this)));
    }

    function getVaultCollateral() public view returns (uint256) {
        return vault.vaultCollateral(vaultID);
    }

    function getVaultDebt() public view returns (uint256) {
        return vault.vaultDebt(vaultID);
    }

    function getCollateralPercentage() public view returns (uint256) {
        return vault.checkCollateralPercentage(vaultID);
    }

    //Uniswap callback
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = QuickswapFactory.getPair(token0, token1);
        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");

        (address tokenA, address tokenB, uint _type) = abi.decode(_data, (address, address, uint));

        (uint amountToRepayA, uint feeA) = _calculateFlashLoanFee(_amount0);
        (uint amountToRepayB, uint feeB) = _calculateFlashLoanFee(_amount1);

        uint fee = feeB == 0 ? feeA : feeB;

        //0 -> _doRuloInternal
        //1 -> _undoRuloInternal
        if (_type == 0) {
            _doRuloInternal(fee);
        }else{
            _undoRuloInternal();
        }

        IERC20(tokenA).transfer(pair, amountToRepayA);
        IERC20(tokenB).transfer(pair, amountToRepayB);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAAVE {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICamDAI {
    function approve(address spender, uint256 amount) external returns (bool);
    function enter(uint256 _amount) external;
    function leave(uint256 _share) external;
    function balanceOf(address account) external returns (uint256);
    function decimals() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IVault {
    function createVault() external returns (uint256);
    function depositCollateral(uint256 vaultID, uint256 amount) external;
    function withdrawCollateral(uint256 vaultID, uint256 amount) external;
    function borrowToken(uint256 vaultID, uint256 amount) external;
    function payBackToken(uint256 vaultID, uint256 amount) external;
    function checkCollateralPercentage(uint256 vaultID) external view returns (uint256);
    function _minimumCollateralPercentage() external view returns(uint256);
    function getDebtCeiling() external view returns (uint256);
    function vaultCollateral(uint256 vaultID) external view returns (uint256);
    function vaultDebt(uint256 vaultID) external view returns (uint256);
    function getEthPriceSource() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IQuickswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1)
        external
        view
        returns (address);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
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