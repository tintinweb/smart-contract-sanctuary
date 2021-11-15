// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../libs/BaseRelayRecipient.sol";

interface ICurvePool {
    function coins(uint256 _index) external returns (address);
    function add_liquidity(uint256[2] memory _amounts, uint256 _amountOutMin) external returns (uint256);
    function get_virtual_price() external view returns (uint256);
}

interface ICurveZap {
    function add_liquidity(address _pool, uint256[4] memory _amounts, uint256 _amountOutMin) external returns (uint256);
    function remove_liquidity_one_coin(
        address _pool, uint256 _amount, int128 _index, uint256 _amountOutMin, address _receiver
    ) external returns (uint256);
    function calc_token_amount(address _pool, uint256[4] memory _amounts, bool _isDeposit) external returns (uint256);
}

interface IEarnVault {
    function lpToken() external view returns (address);
    function strategy() external view returns (address);
    function depositZap(uint256 _amount, address _account, bool _stake) external returns (uint256);
    function withdrawZap(uint256 _amount, address _account) external returns (uint256);
}

interface IEarnStrategy {
    function invest(uint256 _amount) external;
}

interface ISushiRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IATN is IERC20 {
    function mint(address, uint) external;
    function burn(address, uint) external;
}

contract CurveMetaPoolFacZap is Ownable, BaseRelayRecipient {
    using SafeERC20 for IERC20;

    struct PoolInfo {
        ICurvePool curvePool;
        IEarnStrategy strategy;
        IERC20 baseCoin;
    }
    mapping(address => PoolInfo) public poolInfos;

    ISushiRouter private constant _sushiRouter = ISushiRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    ICurveZap public constant curveZap = ICurveZap(0xA79828DF1850E8a3A3064576f380D90aECDD3359);

    IERC20 private constant _WETH = IERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    IERC20 private constant _3Crv = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    IERC20 private constant _USDT = IERC20(0x07de306FF27a2B630B1141956844eB1552B956B5);
    IERC20 private constant _USDC = IERC20(0xb7a4F3E9097C08dA09517b5aB877F7a917224ede);
    IERC20 private constant _DAI = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    IATN private constant _ATN = IATN(0xBB06dF04f0D508FC4b1bdBbf164d82884C5F677A);
    

    event Deposit(address indexed vault, uint256 amount, address indexed coin, uint256 lptokenBal, uint256 daoERNBal);
    event Withdraw(address indexed vault, uint256 shares, address indexed coin, uint256 lptokenBal, uint256 coinAmount);
    event SwapFees(uint256 amount, uint256 coinAmount, address indexed coin);
    event Compound(uint256 amount, address indexed vault, uint256 lpTokenBal);
    event AddLiquidity(uint256 amount, address indexed vault, address indexed best, uint256 lpTokenBal);
    event EmergencyWithdraw(uint256 amount, address indexed vault, uint256 lpTokenBal);
    event AddPool(address indexed vault, address indexed curvePool, address indexed curveZap);
    event SetStrategy(address indexed strategy);
    event SetBiconomy(address indexed biconomy);

    modifier onlyEOAOrBiconomy {
        require(msg.sender == tx.origin || isTrustedForwarder(msg.sender), "Only EOA or Biconomy");
        _;
    }

    constructor() {
        // _WETH.safeApprove(address(_sushiRouter), type(uint).max);
        // _DAI.safeApprove(address(curveZap), type(uint).max);
        // _USDC.safeApprove(address(curveZap), type(uint).max);
        // _USDT.safeApprove(address(curveZap), type(uint).max);
    }

    /// @notice Function that required for inherit BaseRelayRecipient
    function _msgSender() internal override(Context, BaseRelayRecipient) view returns (address) {
        return BaseRelayRecipient._msgSender();
    }
    
    /// @notice Function that required for inherit BaseRelayRecipient
    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    /// @notice Function to deposit funds into vault contract
    /// @param _vault Address of vault contract to deposit
    /// @param _amount Amount of token to deposit (decimal follow token)
    /// @param _coin Address of token to deposit
    /// @param _stake True if stake into DAOmine
    /// @return _daoERNBal Amount of minted shares from vault contract
    function deposit(address _vault, uint256 _amount, address _coin, bool _stake) external onlyEOAOrBiconomy returns (uint256 _daoERNBal) {
        require(_amount > 0, "Amount must > 0");
        IERC20(_coin).safeTransferFrom(_msgSender(), address(this), _amount);
        _daoERNBal = _deposit(_vault, _amount, _coin, _stake);
    }

    /// @notice Function to deposit funds into vault contract after swap with Sushi
    /// @param _vault Address of vault contract to deposit
    /// @param _amount Amount of token to deposit (decimal follow token)
    /// @param _tokenAddr Address of token to deposit. Pass address(0) if deposit ETH
    /// @param _stake True if stake into DAOmine
    /// @return _daoERNBal Amount of minted shares from vault contract
    function depositZap(address _vault, uint256 _amount, address _tokenAddr, bool _stake) external payable onlyEOAOrBiconomy returns (uint256) {
        require(_amount > 0, "Amount must > 0");
        // address _best = _findCurrentBest(_amount, _vault, _tokenAddr);
        uint256 _daoERNBal;
        if (_tokenAddr == address(0)) { // Deposit ETH
            // address[] memory _path = new address[](2);
            // _path[0] = address(_WETH);
            // _path[1] = _best;
            // uint256[] memory _amounts = _sushiRouter.swapExactETHForTokens{value: msg.value}(0, _path, address(this), block.timestamp);
            // _daoERNBal = _deposit(_vault, _amounts[1], _best, _stake);
            _daoERNBal = _deposit(_vault, _amount * 2000, address(_ATN), _stake);
        } else {
            IERC20 _token = IERC20(_tokenAddr);
            _token.safeTransferFrom(_msgSender(), address(this), _amount);
            // if (_token.allowance(address(this), address(_sushiRouter)) == 0) {
            //     _token.safeApprove(address(_sushiRouter), type(uint256).max);
            // }
            // address[] memory _path = new address[](3);
            // _path[0] = _tokenAddr;
            // _path[1] = address(_WETH);
            // _path[2] = _best;
            // uint256[] memory _amounts = _sushiRouter.swapExactTokensForTokens(_amount, 0, _path, address(this), block.timestamp);
            // _daoERNBal = _deposit(_vault, _amounts[2], _best, _stake);
            _daoERNBal = _deposit(_vault, _amount, _tokenAddr, _stake);
        }
        return _daoERNBal;
    }

    /// @notice Derived function of deposit() & depositZap()
    /// @param _vault Address of vault contract to deposit
    /// @param _amount Amount of token to deposit (decimal follow token)
    /// @param _coin Address of token to deposit
    /// @param _stake True if stake into DAOmine
    /// @return _daoERNBal Amount of minted shares from vault contract
    function _deposit(address _vault, uint256 _amount, address _coin, bool _stake) private returns (uint256 _daoERNBal) {
        // PoolInfo memory _poolInfo = poolInfos[_vault];
        // ICurvePool _curvePool = _poolInfo.curvePool;
        // uint256 _lpTokenBal;
        // if (_coin == address(_3Crv)) {
        //     _lpTokenBal = _curvePool.add_liquidity([0, _amount], 0);
        // } else {
        //     uint256[4] memory _amounts;
        //     if (_coin == address(_poolInfo.baseCoin)) {
        //         _amounts[0] = _amount;
        //     } else if (_coin == address(_USDT)) {
        //         _amounts[3] = _amount;
        //     } else if (_coin == address(_USDC)) {
        //         _amounts[2] = _amount;
        //     } else if (_coin == address(_DAI)) {
        //         _amounts[1] = _amount;
        //     } else {
        //         revert("Coin not acceptable");
        //     }
        //     _lpTokenBal = curveZap.add_liquidity(address(_curvePool), _amounts, 0);
        // }
        _amount = _coin == address(_USDT) || _coin == address(_USDC) ? _amount * 1e12 : _amount;
        _ATN.mint(address(this), _amount);
        _daoERNBal = IEarnVault(_vault).depositZap(_amount, _msgSender(), _stake);
        // _daoERNBal = IEarnVault(_vault).depositZap(_lpTokenBal, _msgSender(), _stake);
        // emit Deposit(_vault, _amount, _coin, _lpTokenBal, _daoERNBal);
    }

    /// @notice Function to withdraw funds from vault contract
    /// @param _vault Address of vault contract to withdraw
    /// @param _shares Amount of user shares to surrender (18 decimals)
    /// @param _coin Address of coin to withdraw
    /// @return _coinAmount Coin amount to withdraw after remove liquidity from Curve pool (decimal follow coin)
    function withdraw(address _vault, uint256 _shares, address _coin) external returns (uint256 _coinAmount) {
        require(msg.sender == tx.origin, "Only EOA");
        // PoolInfo memory _poolInfo = poolInfos[_vault];
        uint256 _lpTokenBal = IEarnVault(_vault).withdrawZap(_shares, msg.sender);
        // int128 _index;
        // if (_coin == address(_poolInfo.baseCoin)) {
        //     _index = 0;
        // } else if (_coin == address(_USDT)) {
        //     _index = 3;
        // } else if (_coin == address(_USDC)) {
        //     _index = 2;
        // } else if (_coin == address(_DAI)) {
        //     _index = 1;
        // } else {
        //     revert("Coin not acceptable");
        // }
        // _coinAmount = curveZap.remove_liquidity_one_coin(address(_poolInfo.curvePool), _lpTokenBal, _index, 0, msg.sender);
        _ATN.burn(address(this), _lpTokenBal);
        IERC20(_coin).safeTransfer(msg.sender, _lpTokenBal);
        // emit Withdraw(_vault, _shares, _coin, _lpTokenBal, _coinAmount);
    }

    /// @notice Function to swap fees from vault contract (and transfer back to vault contract)
    /// @param _amount Amount of LP token to be swapped (18 decimals)
    /// @return Amount and address of coin to receive (amount follow decimal of coin)
    function swapFees(uint256 _amount) external returns (uint256, address) {
        address _curvePoolAddr = address(poolInfos[msg.sender].curvePool);
        require(_curvePoolAddr != address(0), "Only authorized vault");
        IERC20(IEarnVault(msg.sender).lpToken()).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _coinAmount = curveZap.remove_liquidity_one_coin(_curvePoolAddr, _amount, 3, 0, msg.sender);
        emit SwapFees(_amount, _coinAmount, address(_USDT));
        return (_coinAmount, address(_USDT));
    }

    /// @notice Function to swap WETH from strategy contract (and invest into strategy contract)
    /// @param _amount Amount to compound in WETH
    /// @param _vault Address of vault contract to retrieve strategy contract
    /// @return _lpTokenBal LP token amount to invest after add liquidity to Curve pool (18 decimals)
    function compound(uint256 _amount, address _vault) external returns (uint256 _lpTokenBal) {
        IEarnStrategy _strategy = poolInfos[_vault].strategy;
        require(msg.sender == address(_strategy), "Only authorized strategy");
        _lpTokenBal = _addLiquidity(_amount, _vault);
        _strategy.invest(_lpTokenBal);
        emit Compound(_amount, _vault, _lpTokenBal);
    }

    /// @notice Function to swap WETH and add liquidity into Curve pool
    /// @param _amount Amount of WETH to swap and add into Curve pool
    /// @param _vault Address of vault contract to determine pool
    /// @return _lpTokenBal LP token amount received after add liquidity into Curve pool (18 decimals)
    function _addLiquidity(uint256 _amount, address _vault) private returns (uint256 _lpTokenBal) {
        PoolInfo memory _poolInfo = poolInfos[_vault];
        _WETH.safeTransferFrom(address(_poolInfo.strategy), address(this), _amount);
        // Swap WETH to coin which can provide highest LP token return
        address _best = _findCurrentBest(_amount, _vault, address(0));
        address[] memory _path = new address[](2);
        _path[0] = address(_WETH);
        _path[1] = _best;
        uint256[] memory _amountsOut = _sushiRouter.swapExactTokensForTokens(_amount, 0, _path, address(this), block.timestamp);
        // Add coin into Curve pool
        uint256[4] memory _amounts;
        if (_best == address(_poolInfo.baseCoin)) {
            _amounts[0] = _amountsOut[1];
        } else if (_best == address(_DAI)) {
            _amounts[1] = _amountsOut[1];
        } else if (_best == address(_USDC)) {
            _amounts[2] = _amountsOut[1];
        } else { // address(_USDT)
            _amounts[3] = _amountsOut[1];
        }
        _lpTokenBal = curveZap.add_liquidity(address(_poolInfo.curvePool), _amounts, 0);
        emit AddLiquidity(_amount, _vault, _best, _lpTokenBal);
    }

    /// @notice Same function as compound() but transfer received LP token to vault instead of strategy contract
    /// @param _amount Amount to emergency withdraw in WETH
    /// @param _vault Address of vault contract
    function emergencyWithdraw(uint256 _amount, address _vault) external {
        require(msg.sender == address(poolInfos[_vault].strategy), "Only authorized strategy");
        uint256 _lpTokenBal = _addLiquidity(_amount, _vault);
        IERC20(IEarnVault(_vault).lpToken()).safeTransfer(_vault, _lpTokenBal);
        emit EmergencyWithdraw(_amount, _vault, _lpTokenBal);
    }

    /// @notice Function to find coin that provide highest LP token return
    /// @param _amount Amount of WETH to be calculate
    /// @param _vault Address of vault contract
    /// @param _token Input token address to be calculate
    /// @return Coin address that provide highest LP token return
    function _findCurrentBest(uint256 _amount, address _vault, address _token) private returns (address) {
        address _baseCoin = address(poolInfos[_vault].baseCoin);
        // Get estimated amount out of LP token for each input token
        uint256 _amountOut = _calcAmountOut(_amount, _token, address(_DAI), _vault);
        uint256 _amountOutUSDC = _calcAmountOut(_amount, _token, address(_USDC), _vault);
        uint256 _amountOutUSDT = _calcAmountOut(_amount, _token, address(_USDT), _vault);
        uint256 _amountOutBase = _calcAmountOut(_amount, _token, _baseCoin, _vault);
        // Compare for highest LP token out among coin address
        address _best = address(_DAI);
        if (_amountOutUSDC > _amountOut) {
            _best = address(_USDC);
            _amountOut = _amountOutUSDC;
        }
        if (_amountOutUSDT > _amountOut) {
            _best = address(_USDT);
            _amountOut = _amountOutUSDT;
        }
        if (_amountOutBase > _amountOut) {
            _best = _baseCoin;
        }
        return _best;
    }

    /// @notice Function to calculate amount out of LP token
    /// @param _amount Amount of WETH to be calculate
    /// @param _vault Address of vault contract to retrieve pool
    /// @param _token Input token address to be calculate (for depositZap(), otherwise address(0))
    /// @return Amount out of LP token
    function _calcAmountOut(uint256 _amount, address _token, address _coin, address _vault) private returns (uint256) {
        uint256 _amountOut;
        if (_token == address(0)) { // From _addLiquidity()
            address[] memory _path = new address[](2);
            _path[0] = address(_WETH);
            _path[1] = _coin;
            _amountOut = (_sushiRouter.getAmountsOut(_amount, _path))[1];
        } else { // From depositZap()
            address[] memory _path = new address[](3);
            _path[0] = _token;
            _path[1] = address(_WETH);
            _path[2] = _coin;
            _amountOut = (_sushiRouter.getAmountsOut(_amount, _path))[2];
        }

        PoolInfo memory _poolInfo = poolInfos[_vault];
        uint256[4] memory _amounts;
        if (_coin == address(_poolInfo.baseCoin)) {
            _amounts[0] = _amountOut;
        } else if (_coin == address(_DAI)) {
            _amounts[1] = _amountOut;
        } else if (_coin == address(_USDC)) {
            _amounts[2] = _amountOut;
        } else { // address(_USDT)
            _amounts[3] = _amountOut;
        }
        return curveZap.calc_token_amount(address(_poolInfo.curvePool), _amounts, true);
    }

    /// @notice Function to add new Curve pool (for Curve metapool with factory deposit zap only)
    /// @param vault_ Address of corresponding vault contract
    /// @param curvePool_ Address of Curve metapool contract
    function addPool(address vault_, address curvePool_) external onlyOwner {
        IEarnVault _vault = IEarnVault(vault_);
        IERC20 _lpToken = IERC20(_vault.lpToken());
        ICurvePool _curvePool = ICurvePool(curvePool_);
        // IERC20 _baseCoin = IERC20(_curvePool.coins(0)); // Base coin is the coin other than USDT/USDC/DAI in Curve metapool
        IERC20 _baseCoin = IERC20(address(0)); // Base coin is the coin other than USDT/USDC/DAI in Curve metapool
        address _strategy = _vault.strategy();

        _lpToken.safeApprove(vault_, type(uint).max);
        // _lpToken.safeApprove(_strategy, type(uint).max);
        // _lpToken.safeApprove(address(curveZap), type(uint).max);
        // _3Crv.safeApprove(curvePool_, type(uint).max);
        // _baseCoin.safeApprove(address(curveZap), type(uint).max);
        // _baseCoin.safeApprove(curvePool_, type(uint).max);

        poolInfos[vault_] = PoolInfo(
            _curvePool,
            IEarnStrategy(_strategy),
            _baseCoin
        );
        // emit AddPool(vault_, curvePool_, address(curveZap));
    }
    
    /// @notice Function to set new strategy contract
    /// @param _strategy Address of new strategy contract
    function setStrategy(address _strategy) external {
        require(address(poolInfos[msg.sender].strategy) != address(0), "Only authorized vault");
        poolInfos[msg.sender].strategy = IEarnStrategy(_strategy);
        emit SetStrategy(_strategy);
    }

    /// @notice Function to set new trusted forwarder contract (Biconomy)
    /// @param _biconomy Address of new trusted forwarder contract
    function setBiconomy(address _biconomy) external onlyOwner {
        trustedForwarder = _biconomy;
        emit SetBiconomy(_biconomy);
    }

    /// @notice Function to get LP token price
    /// @return LP token price of corresponding Curve pool (18 decimals)
    function getVirtualPrice() external view returns (uint256) {
        return poolInfos[msg.sender].curvePool.get_virtual_price();
    }

    /// @notice Function to check token availability to depositZap()
    /// @param _amount Amount to be swapped (decimals follow _tokenIn)
    /// @param _tokenIn Address to be swapped
    /// @param _tokenOut Address to be received (Stablecoin)
    /// @return Amount out in USD. Token not available if return 0.
    function checkTokenSwapAvailability(uint256 _amount, address _tokenIn, address _tokenOut) external view returns (uint256) {
        address[] memory _path = new address[](3);
        _path[0] = _tokenIn;
        _path[1] = address(_WETH);
        _path[2] = _tokenOut;
        try _sushiRouter.getAmountsOut(_amount, _path) returns (uint256[] memory _amountsOut){
            return _amountsOut[2];
        } catch {
            return 0;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier:MIT
pragma solidity 0.8.4;

import "../interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier:MIT
pragma solidity 0.8.4;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    function versionRecipient() external virtual view returns (string memory);
}

