// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./IBPool.sol";


/**
 * @title Arbitrage bot contract
 */
contract ArbitrageBot is AccessControl {
    using SafeMath for uint256;

    IBPool public bPool;
    address public safeAccount;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant WITHDRAWAL_ROLE = keccak256("WITHDRAWAL_ROLE");

    mapping(address => ERC20) private tokens;

    string private constant UNAUTHORIZED_USER = "The Caller is Unauthorized";
    string private constant UNSET_SAFE_ACCOUNT = "First set the safe account";
    string private constant TRANSFER_ERROR = "Token transfer failed";

    event Swapped(address tokenIn, address tokenOut, uint256 tokenAmountIn, uint256 minTokenAmountOut);
    event SafeAccountSet(address safeAccount);
    event ReclaimedToken(address token, uint256 amount, address safeAccount);

    /**
     * @dev sets values for
     * @param _bPool address of the balancer pool
     * @param _deus address of DEUS token
     * @param _dea address of DEA token
     * @param _sdea address of SDEA token
     * @param _suni_dd address of SUNI_DD token
     * @param _suni_de address of SUNI_DE token
     * @param _suni_du address of SUNI_DU token
     * @param _sdeus address of SDEUS token
     */
    constructor(
        address _bPool,
        address _deus,
        address _dea,
        address _sdea,
        address _suni_dd,
        address _suni_de,
        address _suni_du,
        address _sdeus
    ) public {
        bPool = IBPool(_bPool);
        tokens[_deus] = ERC20(_deus);
        tokens[_dea] = ERC20(_dea);
        tokens[_sdea] = ERC20(_sdea);
        tokens[_suni_dd] = ERC20(_suni_dd);
        tokens[_suni_de] = ERC20(_suni_de);
        tokens[_suni_du] = ERC20(_suni_du);
        tokens[_sdeus] = ERC20(_sdeus);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     *@notice swap base token to quote token
     * @param tokenIn address of the base token
     * @param tokenOut address of the quote token
     * @param tokenAmountIn amount of the base token
     * @param incrementalPercentage The incremental percentage
     */
    function _trade(address tokenIn, address tokenOut, uint256 tokenAmountIn, uint256 incrementalPercentage)
        internal
    {
        uint maxPrice = bPool.getSpotPrice(tokenIn, tokenOut).mul(incrementalPercentage).div(100);
        uint minTokenAmountOut = tokenAmountIn.div(maxPrice);
        tokens[tokenIn].approve(address(bPool), tokenAmountIn);
        emit Swapped(tokenIn, tokenOut, tokenAmountIn, minTokenAmountOut);
        bPool.swapExactAmountIn(tokenIn, tokenAmountIn, tokenOut, minTokenAmountOut, maxPrice);
    }

    /**
     *@notice create a batch transaction to swap multiple pairs on the Balancer pool to balance the pool
     * @param tokensIn The list of the base tokens
     * @param tokensOut The list of the quote tokens
     * @param tokensAmountIn The amount of list of the base tokens
     * @param incrementalPercentages list of the incremental percentage
     */
    function makeBalance(
        address[] memory tokensIn,
        address[] memory tokensOut,
        uint256[] memory tokensAmountIn,
        uint256[] memory incrementalPercentages
    )
    	external
    {
        require(hasRole(OPERATOR_ROLE, _msgSender()), UNAUTHORIZED_USER);

        for (uint8 i = 0; i < tokensIn.length; i++) {
        	_trade(tokensIn[i], tokensOut[i], tokensAmountIn[i], incrementalPercentages[i]);
        }
    }

    /**
     * @notice get the the pair's current price
     * @param tokenIn address of the base token
     * @param tokenOut address of the quote token
     */
    function getSpotPrice(address tokenIn, address tokenOut)
        external
        view
        returns(uint)
    {
        return bPool.getSpotPrice(tokenIn, tokenOut);
    }

    /**
     * @notice Set a safe address where reclaimed tokens will go
     * @param _safeAccount a safe address where reclaimed tokens will go
     */
    function setSafeAccount(address _safeAccount)
        external
    {
        require(hasRole(WITHDRAWAL_ROLE, _msgSender()), UNAUTHORIZED_USER);

        safeAccount = _safeAccount;
        emit SafeAccountSet(_safeAccount);
    }

    /**
    * @notice Reclaim tokens of the specified type sent to the safe account
     * @param token The token address
     * @param amount Withdrawal amount
     */
    function reclaimTokens(address token, uint256 amount)
        external
    {
        require(hasRole(WITHDRAWAL_ROLE, _msgSender()), UNAUTHORIZED_USER);

        require(safeAccount != address(0), UNSET_SAFE_ACCOUNT);

        require(tokens[token].transfer(safeAccount, amount), TRANSFER_ERROR);
        emit ReclaimedToken(token, amount, safeAccount);
    }
}