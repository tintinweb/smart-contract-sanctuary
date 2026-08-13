// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./FractCompoundStrategy.sol";
import "./interfaces/compound/CErc20Interface.sol";
import "./interfaces/compound/ComptrollerInterface.sol";
import "./interfaces/compound/CTokenStorage.sol";
import "./interfaces/compound/IPriceFeed.sol";
import "./lib/openzeppelin/SafeERC20.sol";



contract FractCompoundStrategyMOVR is FractCompoundStrategy {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        CONTRACT VARIABLES
    //////////////////////////////////////////////////////////////*/

    //moonwell comptroller address   
    address public constant MOONWELL_COMPTROLLER = 0x0b7a0EAA884849c6Af7a129e899536dDDcA4905E;
    //moonwell token address
    address public constant MOONWELL_TOKEN = 0xBb8d88bcD9749636BC4D2bE22aaC4Bb3B01A58F1;
    //moonwell moonriver token
    address public constant MOONWELL_MOVR_TOKEN = 0x6a1A771C7826596652daDC9145fEAaE62b1cd07f;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals,
        address _depositToken,
        address _priceFeed,
        address _swapRouter,
        address _chainToken
    ) FractCompoundStrategy(
        _name,
        _symbol,
        decimals,
        _depositToken,
        _priceFeed,
        _swapRouter,
        _chainToken
    ) {
        name = _name;
        symbol = _symbol;
        depositToken = IERC20(_depositToken);
        priceFeed = IPriceFeed(_priceFeed);
        swapRouter = IUniswapV2Router02(_swapRouter);
        chainToken = _chainToken;
    }
    
    /*///////////////////////////////////////////////////////////////
                        HARVEST FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Claim and swap simultaneously.
     * @param mintAddress The cToken market to claim on.
     * @param borrowAddress The cToken market to claim on and swap into.
     * @param rewardToken The reward token to swap from.
    */ 
    function harvestByMarket(
        address mintAddress, 
        address borrowAddress, 
        address rewardToken) external onlyOwner {
        uint256 rewardBalance;
        address underlyingAddress;
        claimRewardsByMarket(mintAddress, borrowAddress);
        rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        underlyingAddress = CErc20Interface(borrowAddress).underlying();
        swap(rewardToken, underlyingAddress, rewardBalance);        
    }

    function harvestAll(address rewardToken, address borrowAddress) external onlyOwner {
        uint256 rewardBalance;
        address underlyingAddress;
        claimAllRewards();
        rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        underlyingAddress = CErc20Interface(borrowAddress).underlying();
        swap(rewardToken, underlyingAddress, rewardBalance);        
    }

    /**
     * @notice Claim rewards from moonwell comptroller by market.
     * @param mintAddress The cToken market to claim on.
     * @param borrowAddress The cToken market to claim on.
     */ 
    function claimRewardsByMarket(address mintAddress, address borrowAddress) public onlyOwner {
        ComptrollerInterface comptroller = ComptrollerInterface(MOONWELL_COMPTROLLER);
        address[] memory claimAddresses = new address[](2);
        claimAddresses[0] = mintAddress;
        claimAddresses[1] = borrowAddress;
        //claim MFAM tokens
        comptroller.claimReward(0, address(this), claimAddresses);
        //claim MOVR tokens
        comptroller.claimReward(1, address(this), claimAddresses);
    }

    /**
     * @notice Claim all rewards from moonwell comptroller.
     */ 
    function claimAllRewards() public onlyOwner {
        ComptrollerInterface comptroller = ComptrollerInterface(MOONWELL_COMPTROLLER);
        //claim MFAM tokens
        comptroller.claimReward(0, address(this));
        //claim MOVR tokens
        comptroller.claimReward(1, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./FractStrategyV1.sol";
import "./interfaces/compound/CErc20Interface.sol";
import "./interfaces/compound/ComptrollerInterface.sol";
import "./interfaces/compound/CTokenStorage.sol";
import "./interfaces/compound/IPriceFeed.sol";
import "./interfaces/uniswap/IUniswapV2Router02.sol";
import "./lib/openzeppelin/SafeERC20.sol";




abstract contract FractCompoundStrategy is FractStrategyV1 {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        CONTRACT VARIABLES
    //////////////////////////////////////////////////////////////*/

    //UNIV2 Styler Router for swapping tokens.
    IUniswapV2Router02 public swapRouter;

    //Price feed for fetching underlying price.
    IPriceFeed public priceFeed;

    //Total collateral accumulated by strategy.
    uint256 public totalCollateral;

    //Total debt accumulated by strategy.
    uint256 public totalDebt;

    //The chain's native token (wrapped).
    address public chainToken;

    /**
     * @notice Constructor
     * @param _name The name of the receipt token that will be minted by this strategy.
     * @param _symbol The symbol of the receipt token that will be minted by this strategy.
     * @param decimals The decimal level for the receipt token. 
     * @param _depositToken The address of the deposit token.
     * @param _priceFeed The address of the price feed for primary oracle.
     * @param _swapRouter The address of the uni v2 style router for swapping.
     * @param _chainToken The address of the chain's native token (wrapped). 
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals,
        address _depositToken,
        address _priceFeed,
        address _swapRouter,
        address _chainToken
    ) ERC20 (
        _name,
        _symbol,
        decimals
    ) {
        name = _name;
        symbol = _symbol;
        depositToken = IERC20(_depositToken);
        priceFeed = IPriceFeed(_priceFeed);
        swapRouter = IUniswapV2Router02(_swapRouter);
        chainToken = _chainToken;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit into the strategy. Can only be called by the fractVault.
     * @dev Must mint receipt tokens to `msg.sender`
     * @param amount deposit tokens
     */
    function deposit(uint256 amount) public override onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        uint256 depositAmount = getSharesForDepositTokens(amount);
        require(depositAmount > 0, "Deposit Amount must be greater than 0");
        totalDeposits = totalDeposits + amount;

        _mint(msg.sender, depositAmount);

        emit Deposit(msg.sender, amount);

        depositToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Withdraw from the strategy. Can only be called by the fractVault.
     * @dev Must burn receipt tokens from `msg.sender`
     * @param amount receipt tokens.
     */
    function withdraw(uint256 amount) public override onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        uint256 withdrawalAmount = getDepositTokensForShares(amount);
        require(withdrawalAmount > 0, "Withdrawal Amount must be greater than 0");
        totalDeposits = totalDeposits - withdrawalAmount;

        _burn(msg.sender, amount);

        emit Withdraw(msg.sender, withdrawalAmount);

        depositToken.safeTransfer(msg.sender, withdrawalAmount);

    }

    /*///////////////////////////////////////////////////////////////
                        MINT/BORROW/REPAY/REDEEM
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint and borrow simultaneously.
     * @param mintAddress The cToken market to mint on.
     * @param borrowAddress The cToken market to borrow against.
     * @param mintAmount The amount of underlying token we want to mint.
     * @param collateralFactorBips The amount we want to borrow, based on account liquidity.  
     */
    function mintAndBorrow(
        address mintAddress, 
        address borrowAddress, 
        uint256 mintAmount, 
        uint256 collateralFactorBips) external virtual onlyOwner {
        mint(mintAddress, mintAmount);
        borrow(borrowAddress, collateralFactorBips);
    }

    /**
     * @notice Repay borrow and redeem underlying simultaneously.
     * @param mintAddress The cToken market to redeem on.
     * @param borrowAddress The cToken market to repay borrow on.
     * @param underlyingRedeemAmount The amount of underlying token we want to redeem.
     */
    function repayAndRedeem(
        address mintAddress, 
        address borrowAddress,
        uint256 underlyingRedeemAmount) external virtual onlyOwner {
        repayBorrow(borrowAddress);
        redeem(mintAddress, underlyingRedeemAmount);
    }
    
    /*///////////////////////////////////////////////////////////////
                        INTERNAL STRATEGY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Swap through the specified swapRouter.
     * @param tokenIn The token to swap.
     * @param tokenOut The token to receive.
     * @param amount The amount of underlying token we want to redeem.
     */

	 function swap(address tokenIn, address tokenOut, uint amount) internal {	
		IERC20(tokenIn).approve(address(swapRouter), amount); 
		address[] memory path; 
		if (tokenIn == chainToken || tokenOut == chainToken) {
			path = new address[](2); 
			path[0] = tokenIn; 
			path[1] = tokenOut; 
		} else {
			path = new address[](3); 
			path[0] = tokenIn; 
			path[1] = chainToken; 
			path[2] = tokenOut; 	
		}
	  	swapRouter.swapExactTokensForTokens(
   			amount, 
	  		0, //min amount out 
	  		path, 
	  		address(this),
	  		block.timestamp + 30
	 	); 
	}

    /**
     * @notice Redeem underlying tokens by burning minted tokens.
     * @param mintAddress The cToken we want to burn to redeem underlying.
     * @param underlyingRedeemAmount The underlying amount to redeem. 
     */
    function redeem(address mintAddress, uint256 underlyingRedeemAmount) internal onlyOwner {
        CErc20Interface cErcToken = CErc20Interface(mintAddress);
        uint256 redeemError = cErcToken.redeemUnderlying(underlyingRedeemAmount);
        uint256 normalizedCollateral = normalizeValue(underlyingRedeemAmount, mintAddress);
        require(redeemError == 0, "Redeem Failed");

        totalCollateral = totalCollateral - normalizedCollateral;
    }

    /**
     * @notice Repay borrowed tokens.
     * @param borrowAddress The cToken to repay. 
     */
    function repayBorrow(address borrowAddress) internal onlyOwner {
        CErc20Interface cErcToken = CErc20Interface(borrowAddress);
        address underlyingAddress = cErcToken.underlying();
        uint256 borrowBalance = IERC20(underlyingAddress).balanceOf(address(this));
        uint256 normalizedDebt = normalizeValue(borrowBalance, borrowAddress);
        IERC20(underlyingAddress).approve(borrowAddress, borrowBalance);
        uint256 repayError = cErcToken.repayBorrow(borrowBalance);
        require(repayError == 0, "Repay Failed");

        totalDebt = totalDebt - normalizedDebt;
    }

    /**
     * @notice mint cToken.
     * @param mintAddress The cToken to mint.
     * @param mintAmount The amount of cToken to mint. 
     */
    function mint(address mintAddress, uint256 mintAmount) internal onlyOwner {
        require(mintAddress != address(0), "Address is 0");
        require(mintAmount > 0, "Mint is 0");
        CErc20Interface cErcToken = CErc20Interface(mintAddress);
        address underlyingAddress = cErcToken.underlying();
        IERC20(underlyingAddress).approve(mintAddress, mintAmount);
        uint256 mintError = cErcToken.mint(mintAmount);
        require(mintError == 0, 'Mint failed');
        uint256 normalizedCollateral = normalizeValue(mintAmount, mintAddress);
        //increment totalCollateral
        totalCollateral = totalCollateral + normalizedCollateral;
        //after minting, enter market for borrowing.
        address[] memory markets = new address[](1);
        markets[0] = address(mintAddress);
        ComptrollerInterface comptroller = CTokenStorage(mintAddress).comptroller();
        uint256[] memory errors = comptroller.enterMarkets(markets);
        if (errors[0] != 0) {
            revert('comptroller.enterMarkets() failed');
        }
    }

    /**
     * @notice Borrow underlying token.
     * @param borrowAddress The cToken to borrow against.
     * @param collateralFactorBips The ratio to use when borrowing. 
     */
    function borrow(address borrowAddress, uint256 collateralFactorBips) internal onlyOwner returns(uint256) {
        require(borrowAddress != address(0), "Address is 0");
        require(collateralFactorBips <= BIPS_DIVISOR, "Max leverage exceeded");
        //set comptroller
        ComptrollerInterface comptroller = CTokenStorage(borrowAddress).comptroller();
        CErc20Interface cErcToken = CErc20Interface(borrowAddress);
        //find out how much of your borrow token you can get for your collateral amount
        (uint256 error2, uint256 liquidity, uint256 shortfall) = comptroller.getAccountLiquidity(address(this));
        if (error2 != 0) {
            revert('comptroller.getAccountLiquidity() failed.');
        }
        require(shortfall == 0, "Account underwater");
        require(liquidity >0, "Account does not have excess collateral");
        uint256 collateralPrice = getUnderlyingPrice(address(comptroller), borrowAddress);
        uint256 maxBorrow = (liquidity*ONE_ETHER) / collateralPrice;
        uint256 borrowAmount = (maxBorrow * collateralFactorBips) / BIPS_DIVISOR;

        // when borrowing, the amount must be inferior to the collateral minus the collateral factor; must be caluculated first!!!
        cErcToken.borrow(borrowAmount);

        // get actual borrow balance
        uint256 currentBorrow = cErcToken.borrowBalanceCurrent(address(this));

        uint256 normalizedDebt = normalizeValue(currentBorrow, borrowAddress);
        //increment totalDebt
        totalDebt = totalDebt + normalizedDebt;
        return currentBorrow;

    }

    /*///////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Normalized value to 18 decimals.
     * @param amount The amount(or price) to normalize.
     * @param cTokenAddress The cToken address to use. 
     */
    function normalizeValue(uint256 amount, address cTokenAddress) internal view returns (uint) {
        address underlyingAddress = CErc20Interface(cTokenAddress).underlying();
        uint256 underlyingDecimals = CTokenStorage(underlyingAddress).decimals();
        return amount * (10**(18 - underlyingDecimals));
    }

    /**
     * @notice Get the underlying balance based on cTokenAddress.
     * @param cTokenAddress The cToken address to use. 
     */
    function getUnderlyingBalance(address cTokenAddress) public view virtual returns(uint256) {
		address underlyingAddress = CErc20Interface(cTokenAddress).underlying();
        uint256 underlyingBalance = CErc20Interface(underlyingAddress).balanceOf(address(this)); 
		return underlyingBalance; 
	}

    /**
     * @notice Get the underlying price of cToken via oracle.
     * @param cTokenAddress The cToken address to use. 
     */
    function getUnderlyingPrice(address comptrollerAddress, address cTokenAddress) public virtual onlyOwner returns(uint256){
        uint256 price = priceFeed.getUnderlyingPrice(cTokenAddress);
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface CErc20Interface {

    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function underlying() external view returns (address);
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ComptrollerInterface {
   function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function markets(address) external view returns (bool, uint256);

    function getAssetsIn(address) external view returns (address[] memory);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    // function claimComp(
    //     address[] memory holders,
    //     address[] memory cTokens,
    //     bool borrowers,
    //     bool suppliers
    // ) external;

    function claimComp(address holder) external;

    function claimComp(address holder, address[] memory cToken) external;

    function claimReward(uint8 rewardType, address holder, address[] memory mToken) external;

    function claimReward(uint8 rewardType, address holder) external;

    function getCompAddress() external view returns (address);

    function compAccrued(address) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ComptrollerInterface.sol";

contract CTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPriceFeed {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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
pragma solidity 0.8.10;

import "./lib/openzeppelin/Ownable.sol";
import "./lib/openzeppelin/IERC20.sol";
import "./lib/solmate/ERC20.sol";

/**
 * @notice FractStrategyV1 should be inherited by new strategies.
 */

abstract contract FractStrategyV1 is ERC20, Ownable {

    // Deposit token that the strategy accepts.
    IERC20 public depositToken;

    // Reward token that the strategy receives from protocol it interacts with.
    IERC20 public rewardToken;

    // Fractal Vault address;
    address public fractVault;
    
    // Developer Address
    address public devAddr;

    // Minimum amount of token rewards to harvest into the strategy.
    uint256 public minTokensToHarvest;

    // Minimum amount of tokens to deposit into strategy without harvesting.
    uint256 public maxTokensToDepositWithoutHarvest;

    // Total deposits in the strategy.
    uint256 public totalDeposits;

    // Bool value to enable or disable deposits.
    bool public depositsEnabled;

    // Fee that is given to EOA that calls harvest() function.
    uint256 public harvestRewardBips;

    // Fee that is sent to owner address.
    uint256 public adminFeeBips;

    // Constant used as a bips divisor. 
    uint256 constant internal BIPS_DIVISOR = 10000;

    // Constant for scaling values.
    uint256 public constant ONE_ETHER = 10**18;

    /**
     * @notice This event is fired when the strategy receives a deposit.
     * @param account Specifies the depositor address.
     * @param amount Specifies the deposit amount.
     */
    event Deposit(address indexed account, uint amount);

    /**
     * @notice This event is fired when the strategy receives a withdrawal.
     * @param account Specifies the withdrawer address.
     * @param amount Specifies the withdrawal amount,
     */
    event Withdraw(address indexed account, uint amount);

    /**
     * @notice This event is fired when the strategy harvest its earned rewards.
     * @param newTotalDeposits Specifies the total amount of deposits in the strategy.
     * @param newTotalSupply Specifies the total supply of receipt tokens the strategy has minted.
     */
    event Harvest(uint newTotalDeposits, uint newTotalSupply);

    /**
     * @notice This event is fired when tokens are recovered from the strategy contract.
     * @param token Specifies the token that was recovered.
     * @param amount Specifies the amount that was recovered.
     */
    event Recovered(address token, uint amount);

    /**
     * @notice This event is fired when the admin fee is updated.
     * @param oldValue Old admin fee.
     * @param newValue New admin fee.
     */
    event UpdateAdminFee(uint oldValue, uint newValue);

    /**
     * @notice This event is fired when the harvest fee is updated.
     * @param oldValue Old harvest fee.
     * @param newValue New harvest fee.
     */
    event UpdateHarvestReward(uint oldValue, uint newValue);

    /**
     * @notice This event is fired when the min tokens to harvest is updated.
     * @param oldValue Old min tokens to harvest amount.
     * @param newValue New min tokens to harvest amount.
     */
    event UpdateMinTokensToHarvest(uint oldValue, uint newValue);

    /**
     * @notice This event is fired when the max tokens to deposit without harvest is updated.
     * @param oldValue Old max tokens to harvest without deposit.
     * @param newValue New max tokens to harvest without deposit.
     */
    event UpdateMaxTokensToDepositWithoutHarvest(uint oldValue, uint newValue);

     /**
     * @notice This event is fired when the developer address is updated.
     * @param oldValue Old developer address.
     * @param newValue New developer address.
     */
    event UpdateDevAddr(address oldValue, address newValue);

    /**
     * @notice This event is fired when deposits are enabled or disabled.
     * @param newValue Bool for enabling or disabling deposits.
     */
    event DepositsEnabled(bool newValue);

    /**
     * @notice This event is fired when the vault contract address is set. 
     * @param vaultAddress Specifies the address of the fractVault. 
     */
    event SetVault(address indexed vaultAddress);


    /**
     * @notice This event is fired when funds (interest) are withdrawn from a strategy.
     * @param amount The amount (interest) withdrawn from the strategy.
     */
    event WithdrawInterest(uint256 amount);

    /**
     * @notice This event is fired when the deposit token is altered. 
     * @param newTokenAddress The address of the new deposit token.  
     */
    event ChangeDepositToken(address indexed newTokenAddress);
    
    /**
     * @notice Only called by dev
     */
    modifier onlyDev() {
        require(msg.sender == devAddr, "Only Developer can call this function");
        _;
    }

    /**
     * @notice Only called by vault
     */
    modifier onlyVault() {
        require(msg.sender == fractVault, "Only the fractVault can call this function.");
        _;
    }

    /**
     * @notice Initialized the different strategy settings after the contract has been deployed.
     * @param minHarvestTokens The minimum amount of pending reward tokens needed to call the harvest function.
     * @param adminFee The admin fee, charged when calling harvest function.
     * @param harvestReward The harvest fee, charged when calling the harvest function, given to EOA.
     */
    function initializeStrategySettings(uint256 minHarvestTokens, uint256 adminFee, uint256 harvestReward) 
    external onlyOwner {
        minTokensToHarvest = minHarvestTokens;
        adminFeeBips = adminFee;
        harvestRewardBips = harvestReward;

        updateMinTokensToHarvest(minTokensToHarvest);
        updateAdminFee(adminFeeBips);
        updateHarvestReward(harvestRewardBips);
    }

    /**
     * @notice Sets the vault address the strategy will receive deposits from. 
     * @param vaultAddress Specifies the address of the poolContract. 
     */
    function setVaultAddress(address vaultAddress) external onlyOwner {
        require(vaultAddress != address(0), "Address cannot be a 0 address");
        fractVault = vaultAddress;

        emit SetVault(fractVault);

    }
    
    /**
     * @notice Revoke token allowance
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address token, address spender) external onlyOwner {
        require(IERC20(token).approve(spender, 0), "Revoke Failed");
    }

    // /**
    //  * @notice Set a new deposit token, and swap current deposit tokens to new deposit tokens via lp pool.
    //  * @param oldDeposit The address of the old depositToken for the strategy.
    //  * @param newDeposit The address of the new depositToken for the strategy.
    //  * @param swapContract The address of the lp pool to swap old deposit token to new deposit token.
    //  */
    // function changeDepositToken(address oldDeposit, address newDeposit, address swapContract) external onlyOwner {
    //     require(oldDeposit != address(0), "Address cannot be a 0 address");
    //     require(newDeposit != address(0), "Address cannot be a 0 address");
    //     require(swapContract != address(0), "Address cannot be a 0 address");

    //     uint256 depositTokenBalance = depositToken.balanceOf(address(this));
    //     uint256 newDepositTokenBalance = 0;
        
    //     depositToken = IERC20(newDeposit);
        
    //     emit ChangeDepositToken(newDeposit);

    //     newDepositTokenBalance = DexLibrary.swap(
    //         depositTokenBalance,
    //         oldDeposit,
    //         newDeposit,
    //         IPair(swapContract)
    //     );
    // }


    /**
     * @notice Deposit and deploy deposits tokens to the strategy
     * @dev Must mint receipt tokens to `msg.sender`
     * @param amount deposit tokens
     */
    function deposit(uint256 amount) external virtual;

    /**
     * @notice Redeem receipt tokens for deposit tokens
     * @param amount receipt tokens
     */
    function withdraw(uint256 amount) external virtual;
    
    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint256 amount) public view returns (uint) {
        if (totalSupply * totalDeposits > 0) {
            return (amount * totalSupply) / totalDeposits;
        }
        return amount;
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint256 amount) public view returns (uint) {
        if (totalSupply * totalDeposits > 0) {
            return (amount * totalDeposits) / totalSupply;
        }
        return 0;
    }

    /**
     * @notice Update harvest min threshold
     * @param newValue threshold
     */
    function updateMinTokensToHarvest(uint256 newValue) public onlyOwner {
        emit UpdateMinTokensToHarvest(minTokensToHarvest, newValue);
        minTokensToHarvest = newValue;
    }

    /**
     * @notice Update harvest max threshold before a deposit
     * @param newValue threshold
     */
    function updateMaxTokensToDepositWithoutHarvest(uint256 newValue) external onlyOwner {
        emit UpdateMaxTokensToDepositWithoutHarvest(maxTokensToDepositWithoutHarvest,newValue);
        maxTokensToDepositWithoutHarvest = newValue;
    }

    /**
     * @notice Update admin fee
     * @param newValue fee in BIPS
     */
    function updateAdminFee(uint256 newValue) public onlyOwner {
        require(newValue + harvestRewardBips <= BIPS_DIVISOR, "Updated Failed");
        emit UpdateAdminFee(adminFeeBips, newValue);
        adminFeeBips = newValue;
    }

    /**
     * @notice Update harvest reward
     * @param newValue fee in BIPS
     */
    function updateHarvestReward(uint256 newValue) public onlyOwner {
        require(newValue + adminFeeBips <= BIPS_DIVISOR, "Update Failed");
        emit UpdateHarvestReward(harvestRewardBips, newValue);
        harvestRewardBips = newValue;
    }

    /**
     * @notice Enable/disable deposits
     * @param newValue bool
     */
    function updateDepositsEnabled(bool newValue) external onlyOwner {
        require(depositsEnabled != newValue, "Update Failed");
        depositsEnabled = newValue;
        emit DepositsEnabled(newValue);
    }

    /**
     * @notice Update devAddr
     * @param newValue address
     */
    function updateDevAddr(address newValue) external onlyDev {
        require(newValue != address(0), "Address is a 0 address");
        emit UpdateDevAddr(devAddr, newValue);
        devAddr = newValue;
    }

    /**
     * @notice Recover ERC20 from contract
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Recovery amount must be greater than 0");
        emit Recovered(tokenAddress, tokenAmount);
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount), "Recovery Failed");
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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