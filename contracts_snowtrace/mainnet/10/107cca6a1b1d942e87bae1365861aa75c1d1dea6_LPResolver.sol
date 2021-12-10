/**
 *Submitted for verification at snowtrace.io on 2021-12-09
*/

pragma solidity 0.8.6;

interface IResolver {
    function checker(ICauldron cauldron, ILPStrategy strategy, bool swap)
        external
        view
        returns (bool canExec, bytes memory execPayload);
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
interface ILPStrategy {
    function safeHarvest(
        uint256 maxBalance,
        bool rebalance,
        uint256 maxChangeAmount,
        bool harvestRewards
    ) external;
    function swapToLP(uint256 amountOutMin) external;
    function strategyToken() external view returns (IERC20 token);
    function bentoBox() external view returns (IBentoBox);
}

interface ICauldron {
    function oracle() external view returns (IOracle oracle);
    function oracleData() external view returns (bytes memory data);
}

interface IOracle {
    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);
}

interface IBentoBox {
    function strategyData(IERC20 token) external view returns (uint64 strategyStartDate, uint64 targentPercentage, uint128 balance);
    function totals(IERC20 token) external view returns (uint128 elastic, uint128 base);
}

contract LPResolver is IResolver {

    IERC20 public constant JOE = IERC20(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd);

    function checker(ICauldron cauldron, ILPStrategy strategy, bool swap)
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {   
        IOracle oracle = cauldron.oracle();
        bytes memory oracleData = cauldron.oracleData();

        if(swap) {
            if(JOE.balanceOf(address(strategy)) >= 500 * 1e18) {
                (, uint256 peekPrice) = oracle.peek(oracleData);
                uint256 spotPrice = oracle.peekSpot(oracleData);
                canExec = spotPrice > peekPrice || peekPrice * 20 / 100 > (peekPrice - spotPrice);
            } else {
                canExec = false;
            }
            execPayload = abi.encodeWithSelector(
                ILPStrategy.swapToLP.selector,
                uint256(0)
            );
        } else {
            IERC20 strategyToken = strategy.strategyToken();

            (, uint64 targentPercentage, uint128 balance) = strategy.bentoBox().strategyData(strategyToken);
            (uint128 elastic, ) = strategy.bentoBox().totals(strategyToken);
            canExec = balance < elastic * targentPercentage * 98 / 100 / 100 || balance > elastic * targentPercentage * 102 / 100 / 100;
            execPayload = abi.encodeWithSelector(
                ILPStrategy.safeHarvest.selector,
                0,
                true,
                type(uint256).max,
                false
            );
        }
        
    }
}