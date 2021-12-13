// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
    function withdraw(uint256) external;
    function balanceOf(address account) external view returns (uint256);
}

interface ICollateralReserveV2{
    function rebalance(
            address token0,
            address token1,
            uint256 _amount,
            uint256 _min_output_amount,
            bool nocheckcollateral,
            address routerAddress
    ) external;
    function createLiquidity(
        address token0,
        address token1,
        uint256 amtToken0,
        uint256 amtToken1,
        uint256 minToken0,
        uint256 minToken1,
        address routerAddrsss
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(
        address token0,
        address token1,
        uint liquidity,
        uint256 minToken0,
        uint256 minToken1,
        address routerAddrsss
    )
        external

        returns (
            uint256,
            uint256,
            uint256
        );
    function yvDeposit(address _token0, address _token1, uint _amount) external;
    function yvWithdraw(address _token, uint _amount) external;
    function stakeCoffin(uint _amount) external;
    function stakeBOO(uint _amount) external;
    function unstakeXBOO(uint _amount) external;

    function getCollateralBalance(address _token) external view returns (uint256);
    function getCollateralPrice(address _token) external view  returns (uint256);
    function valueOf( address _token, uint _amount ) external view returns ( uint value_ );
    function getValue(address _token, uint256 _amt) external view  returns (uint256);
    function getCollateralValue(address _token) external view  returns (uint256);
    function getActualCollateralValue() external view  returns (uint256);
    function getTotalCollateralValue() external view  returns (uint256) ;
}




contract CollateralReserveV2Manager is Ownable{

    address public collateralReserveV2;
    address public manager;


    //wftm
    address private wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    //
    address private usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address private dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    address private mim = 0x82f0B8B456c1A451378467398982d4834b6829c1;
    address private weth = 0x74b23882a30290451A17c44f4F05243b6b58C76d;
    address private yvdai = 0x637eC617c86D24E421328e6CAEa1d92114892439;
    address private yvmim = 0x0A0b23D9786963DE69CB2447dC125c49929419d8;
    address private xboo = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;
    address private boo  = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    address private yvusdc = 0xEF0210eB96c7EB36AF8ed1c20306462764935607;
    address private nice   = 0x7f620d7d0b3479b1655cEFB1B0Bc67fB0EF4E443;
    address private wmemo   = 0xDDc0385169797937066bBd8EF409b5B3c0dFEB52;
    address private sspell   = 0xbB29D2A58d880Af8AA5859e30470134dEAf84F2B;

    receive() external payable {
        IWETH(wftm).deposit{value: msg.value}();
        IERC20(wftm).transfer(collateralReserveV2, msg.value);
    }

    // router address. it's spooky router by default.
    address private spookyRouterAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address private morpheusswapRouterAddress = 0x8aC868293D97761A1fED6d4A01E9FF17C5594Aa3;

    constructor(address _collateralReserveV2) {
        collateralReserveV2 = _collateralReserveV2;

    }

    /* ========== MODIFIER ========== */



    modifier onlyOwnerOrManager() {
        require(owner() == msg.sender || manager == msg.sender, "Only owner or manager can trigger this function");
        _;
    }



    /* ========== VIEWS ================ */

    function balanceToken(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(collateralReserveV2));
    }



    function setManager(address _manager) public onlyOwner {
        require(_manager != address(0), "Invalid address");
        manager = _manager;
    }

    // function setBuybackManager(address _buyback_manager) public onlyOwner {
    //     require(_buyback_manager != address(0), "Invalid address");
    //     buyback_manager = _buyback_manager;
    // }

    function rebalanceFTM2BOO(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(wftm, boo, _amount, _min,  spookyRouterAddress);
    }
    function rebalanceBOO2FTM(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(boo, wftm, _amount, _min,  spookyRouterAddress);
    }
    function rebalanceFTM2MIM(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(wftm, mim, _amount, _min,  spookyRouterAddress);
    }

    function rebalanceMIM2FTM(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(mim, wftm, _amount, _min,  spookyRouterAddress);
    }

    function rebalanceFTM2DAI(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(wftm, dai, _amount, _min,  spookyRouterAddress);
    }

    function rebalanceDAI2FTM(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(dai, wftm, _amount, _min, spookyRouterAddress);
    }

    function rebalanceUSDC2FTM(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(usdc, wftm, _amount, _min,  spookyRouterAddress);
    }

    function rebalanceFTM2USDC(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(wftm, usdc, _amount, _min,  spookyRouterAddress);
    }

    function rebalanceFTM2WETH(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(wftm, weth, _amount, _min,  spookyRouterAddress);
    }

    function rebalanceWETH2FTM(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(weth, wftm, _amount, _min,  spookyRouterAddress);
    }

    function rebalanceMIM2WMEMO(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(mim, wmemo, _amount, _min,  morpheusswapRouterAddress);
    }
    function rebalanceMIM2SSPELL(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(mim, sspell, _amount, _min, morpheusswapRouterAddress);
    }
    function rebalanceMIM2NICE(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(mim, nice, _amount, _min,  morpheusswapRouterAddress);
    }

    function rebalanceWMEMO2MIM(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(wmemo, mim, _amount, _min,  morpheusswapRouterAddress);
    }
    function rebalanceSSPELL2MIM(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(sspell, mim, _amount, _min, morpheusswapRouterAddress);
    }
    function rebalanceNICE2MIM(uint _amount, uint _min) public onlyOwnerOrManager {
        rebalance(nice, mim, _amount, _min, morpheusswapRouterAddress);
    }



    function stakeBOO(uint _amount) public onlyOwnerOrManager {
        ICollateralReserveV2(collateralReserveV2).stakeBOO( _amount);
    }

    function unstakeXBOO(uint _amount) public onlyOwnerOrManager {
        ICollateralReserveV2(collateralReserveV2).unstakeXBOO( _amount);
    }


    function rebalanceDAI2YVDAI(uint _amount) public onlyOwnerOrManager {
        ICollateralReserveV2(collateralReserveV2).yvDeposit(dai, yvdai, _amount);
    }

    function rebalanceYVDAI2DAI(uint _amount) public onlyOwnerOrManager {
        ICollateralReserveV2(collateralReserveV2).yvWithdraw(yvdai, _amount);
    }

    function rebalanceMIM2YVMIM(uint _amount) public onlyOwnerOrManager {
        ICollateralReserveV2(collateralReserveV2).yvDeposit(mim, yvmim, _amount);

    }

    function rebalanceYVMIM2MIM(uint _amount) public onlyOwnerOrManager {
        ICollateralReserveV2(collateralReserveV2).yvWithdraw(yvmim, _amount);

    }

    function rebalanceUSDC2YVUSDC(uint _amount) public onlyOwnerOrManager {
        ICollateralReserveV2(collateralReserveV2).yvDeposit(usdc, yvusdc, _amount);

    }

    function rebalanceYVUSDC2USDC(uint _amount) public onlyOwnerOrManager {
        ICollateralReserveV2(collateralReserveV2).yvWithdraw(yvusdc, _amount);
    }

    function rebalance(
            address token0,
            address token1,
            uint256 _amount,
            uint256 _min_output_amount,
            // bool nocheckcollateral,
            address routerAddress
    ) public onlyOwnerOrManager {
        return ICollateralReserveV2(collateralReserveV2)
            .rebalance(
                token0, token1, _amount
                , _min_output_amount, false, routerAddress);
    }



    function createLiquiditySpookySwap(
        address token0,
        address token1,
        uint256 amtToken0,
        uint256 amtToken1,
        uint256 minToken0,
        uint256 minToken1
    )
        external
        onlyOwnerOrManager
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return createLiquidity(
            token0,
            token1,
            amtToken0,
            amtToken1,
            minToken0,
            minToken1,
            spookyRouterAddress
        );
    }
    function createLiquidityMorpheusSwap(
        address token0,
        address token1,
        uint256 amtToken0,
        uint256 amtToken1,
        uint256 minToken0,
        uint256 minToken1
    )
        external
        onlyOwnerOrManager
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return createLiquidity(
            token0,
            token1,
            amtToken0,
            amtToken1,
            minToken0,
            minToken1,
            morpheusswapRouterAddress
        );
    }

    function createLiquidity(
        address token0,
        address token1,
        uint256 amtToken0,
        uint256 amtToken1,
        uint256 minToken0,
        uint256 minToken1,
        address routerAddrsss
    )
        public
        onlyOwnerOrManager
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return ICollateralReserveV2(collateralReserveV2).createLiquidity(
        token0,
        token1,
        amtToken0,
        amtToken1,
        minToken0,
        minToken1,
        routerAddrsss
        );

    }


    function removeLiquidity(
        address token0,
        address token1,
        uint liquidity,
        uint256 minToken0,
        uint256 minToken1,
        address routerAddrsss
    )
        public
        onlyOwnerOrManager
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return ICollateralReserveV2(collateralReserveV2).removeLiquidity(
        token0,
        token1,
        liquidity,
        minToken0,
        minToken1,
        routerAddrsss
        );

    }


    function removeLiquidityMorpheusSwap(
        address token0,
        address token1,
        uint liquidity,
        uint256 minToken0,
        uint256 minToken1
    )
        external
        onlyOwnerOrManager
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return removeLiquidity(token0, token1, liquidity, minToken0, minToken1, morpheusswapRouterAddress);
    }
    function removeLiquiditySpookySwap(
        address token0,
        address token1,
        uint liquidity,
        uint256 minToken0,
        uint256 minToken1
    )
        external
        onlyOwnerOrManager
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return removeLiquidity(token0, token1, liquidity, minToken0, minToken1, spookyRouterAddress);
    }

    function getCollateralBalance(address _token) external view returns (uint256)
    {
        return ICollateralReserveV2(collateralReserveV2).getCollateralBalance(_token);
    }

    function getCollateralPrice(address _token) external view  returns (uint256)
    {
        return ICollateralReserveV2(collateralReserveV2).getCollateralPrice(_token);
    }

    function valueOf( address _token, uint _amount ) external view returns ( uint value_ )
    {
        return ICollateralReserveV2(collateralReserveV2).valueOf(_token, _amount);
    }

    function getValue(address _token, uint256 _amt) external view  returns (uint256)
    {
        return ICollateralReserveV2(collateralReserveV2).getValue(_token, _amt);
    }

    function getCollateralValue(address _token) external view  returns (uint256)
    {
        return ICollateralReserveV2(collateralReserveV2).getCollateralValue(_token);
    }

    function getActualCollateralValue() external view  returns (uint256)
    {
        return ICollateralReserveV2(collateralReserveV2).getActualCollateralValue();
    }

    function getTotalCollateralValue() external view  returns (uint256)
    {
        return ICollateralReserveV2(collateralReserveV2).getTotalCollateralValue();
    }



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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