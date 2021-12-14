// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../lib/RequiredDecimals.sol";
import "../interfaces/IAMM.sol";

/**
 * Represents a generalized contract for a single-sided AMM pair.
 *
 * That means is possible to add and remove liquidity in any proportion
 * at any time, even 0 in one of the sides.
 *
 * The AMM is constituted by 3 core functions: Add Liquidity, Remove liquidity and Trade.
 *
 * There are 4 possible trade types between the token pair (tokenA and tokenB):
 *
 * - ExactAInput:
 *     tokenA as an exact Input, meaning that the output tokenB is variable.
 *     it is important to have a slippage control of the minimum acceptable amount of tokenB in return
 * - ExactAOutput:
 *     tokenA as an exact Output, meaning that the input tokenB is variable.
 *     it is important to have a slippage control of the maximum acceptable amount of tokenB sent
 * - ExactBInput:
 *     tokenB as an exact Input, meaning that the output tokenA is variable.
 *     it is important to have a slippage control of the minimum acceptable amount of tokenA in return
 * - ExactBOutput:
 *     tokenB as an exact Output, meaning that the input tokenA is variable.
 *     it is important to have a slippage control of the maximum acceptable amount of tokenA sent
 *
 * Several functions are provided as virtual and must be overridden by the inheritor.
 *
 * - _getABPrice:
 *     function that will return the tokenA:tokenB price relation.
 *     How many units of tokenB in order to traded for 1 unit of tokenA.
 *     This price is represented in the same tokenB number of decimals.
 * - _onAddLiquidity:
 *     Executed after adding liquidity. Usually used for handling fees
 * - _onRemoveLiquidity:
 *     Executed after removing liquidity. Usually used for handling fees
 *
 *  Also, for which TradeType (E.g: ExactAInput) there are more two functions to override:

 * _getTradeDetails[$TradeType]:
 *   This function is responsible to return the TradeDetails struct, that contains basically the amount
 *   of the other token depending on the trade type. (E.g: ExactAInput => The TradeDetails will return the
 *   amount of B output).
 * _onTrade[$TradeType]:
 *    function that will be executed after UserDepositSnapshot updates and before
 *    token transfers. Usually used for handling fees and updating state at the inheritor.
 *
 */

abstract contract AMM is IAMM, RequiredDecimals {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
     * @dev The initial value for deposit factor (Fimp)
     */
    uint256 public constant INITIAL_FIMP = 10**27;

    /**
     * @notice The Fimp's precision (aka number of decimals)
     */
    uint256 public constant FIMP_DECIMALS = 27;

    /**
     * @notice The percent's precision
     */
    uint256 public constant PERCENT_PRECISION = 100;

    /**
     * @dev Address of the token A
     */
    address private _tokenA;

    /**
     * @dev Address of the token B
     */
    address private _tokenB;

    /**
     * @dev Token A number of decimals
     */
    uint8 private _tokenADecimals;

    /**
     * @dev Token B number of decimals
     */
    uint8 private _tokenBDecimals;

    /**
     * @notice The total balance of token A in the pool not counting the amortization
     */
    uint256 public deamortizedTokenABalance;

    /**
     * @notice The total balance of token B in the pool not counting the amortization
     */
    uint256 public deamortizedTokenBBalance;

    /**
     * @notice It contains the token A original balance, token B original balance,
     * and the Open Value Factor (Fimp) at the time of the deposit.
     */
    struct UserDepositSnapshot {
        uint256 tokenABalance;
        uint256 tokenBBalance;
        uint256 fImp;
    }

    struct Mult {
        uint256 AA; // How much A Im getting for rescuing one A that i've deposited
        uint256 AB; // How much B Im getting for rescuing one A that i've deposited
        uint256 BA; // How much A Im getting for rescuing one B that i've deposited
        uint256 BB; // How much B Im getting for rescuing one B that i've deposited
    }

    struct TradeDetails {
        uint256 amount;
        uint256 feesTokenA;
        uint256 feesTokenB;
        bytes params;
    }
    /**
     * @dev Tracks the UserDepositSnapshot struct of each user.
     * It contains the token A original balance, token B original balance,
     * and the Open Value Factor (Fimp) at the time of the deposit.
     */
    mapping(address => UserDepositSnapshot) private _userSnapshots;

    /** Events */
    event AddLiquidity(address indexed caller, address indexed owner, uint256 amountA, uint256 amountB);
    event RemoveLiquidity(address indexed caller, uint256 amountA, uint256 amountB);
    event TradeExactAInput(address indexed caller, address indexed owner, uint256 exactAmountAIn, uint256 amountBOut);
    event TradeExactBInput(address indexed caller, address indexed owner, uint256 exactAmountBIn, uint256 amountAOut);
    event TradeExactAOutput(address indexed caller, address indexed owner, uint256 amountBIn, uint256 exactAmountAOut);
    event TradeExactBOutput(address indexed caller, address indexed owner, uint256 amountAIn, uint256 exactAmountBOut);

    constructor(address tokenA, address tokenB) public {
        require(Address.isContract(tokenA), "AMM: token a is not a contract");
        require(Address.isContract(tokenB), "AMM: token b is not a contract");
        require(tokenA != tokenB, "AMM: tokens must differ");

        _tokenA = tokenA;
        _tokenB = tokenB;

        _tokenADecimals = tryDecimals(IERC20(tokenA));
        _tokenBDecimals = tryDecimals(IERC20(tokenB));
    }

    /**
     * @dev Returns the address for tokenA
     */
    function tokenA() public override view returns (address) {
        return _tokenA;
    }

    /**
     * @dev Returns the address for tokenB
     */
    function tokenB() public override view returns (address) {
        return _tokenB;
    }

    /**
     * @dev Returns the decimals for tokenA
     */
    function tokenADecimals() public override view returns (uint8) {
        return _tokenADecimals;
    }

    /**
     * @dev Returns the decimals for tokenB
     */
    function tokenBDecimals() public override view returns (uint8) {
        return _tokenBDecimals;
    }

    /**
     * @notice getPoolBalances external function that returns the current pool balance of token A and token B
     *
     * @return totalTokenA balanceOf this contract of token A
     * @return totalTokenB balanceOf this contract of token B
     */
    function getPoolBalances() external view returns (uint256 totalTokenA, uint256 totalTokenB) {
        return _getPoolBalances();
    }

    /**
     * @notice getUserDepositSnapshot external function that User original balance of token A,
     * token B and the Opening Value * * Factor (Fimp) at the moment of the liquidity added
     *
     * @param user address to check the balance info
     *
     * @return tokenAOriginalBalance balance of token A by the moment of deposit
     * @return tokenBOriginalBalance balance of token B by the moment of deposit
     * @return fImpUser value of the Opening Value Factor by the moment of the deposit
     */
    function getUserDepositSnapshot(address user)
        external
        view
        returns (
            uint256 tokenAOriginalBalance,
            uint256 tokenBOriginalBalance,
            uint256 fImpUser
        )
    {
        return _getUserDepositSnapshot(user);
    }

    /**
     * @notice _addLiquidity in any proportion of tokenA or tokenB
     *
     * @dev The inheritor contract should implement _getABPrice and _onAddLiquidity functions
     *
     * @param amountOfA amount of TokenA to add
     * @param amountOfB amount of TokenB to add
     * @param owner address of the account that will have ownership of the liquidity
     */
    function _addLiquidity(
        uint256 amountOfA,
        uint256 amountOfB,
        address owner
    ) internal {
        _isValidAddress(owner);
        // Get Pool Balances
        (uint256 totalTokenA, uint256 totalTokenB) = _getPoolBalances();

        bool hasNoLiquidity = deamortizedTokenABalance == 0 && deamortizedTokenBBalance == 0;
        uint256 fImpOpening;
        uint256 userAmountToStoreTokenA = amountOfA;
        uint256 userAmountToStoreTokenB = amountOfB;

        if (hasNoLiquidity) {
            // In the first liquidity, is necessary add both tokens
            bool bothTokensHigherThanZero = amountOfA > 0 && amountOfB > 0;
            require(bothTokensHigherThanZero, "AMM: invalid first liquidity");

            fImpOpening = INITIAL_FIMP;

            deamortizedTokenABalance = amountOfA;
            deamortizedTokenBBalance = amountOfB;
        } else {
            // Get ABPrice
            uint256 ABPrice = _getABPrice();
            require(ABPrice > 0, "AMM: option price zero");

            // Calculate the Pool's Value Factor (Fimp)
            fImpOpening = _getFImpOpening(
                totalTokenA,
                totalTokenB,
                ABPrice,
                deamortizedTokenABalance,
                deamortizedTokenBBalance
            );

            (userAmountToStoreTokenA, userAmountToStoreTokenB) = _getUserBalanceToStore(
                amountOfA,
                amountOfB,
                fImpOpening,
                _userSnapshots[owner]
            );

            // Update Deamortized Balance of the pool for each token;
            deamortizedTokenABalance = deamortizedTokenABalance.add(amountOfA.mul(10**FIMP_DECIMALS).div(fImpOpening));
            deamortizedTokenBBalance = deamortizedTokenBBalance.add(amountOfB.mul(10**FIMP_DECIMALS).div(fImpOpening));
        }

        // Update the User Balances for each token and with the Pool Factor previously calculated
        UserDepositSnapshot memory userDepositSnapshot = UserDepositSnapshot(
            userAmountToStoreTokenA,
            userAmountToStoreTokenB,
            fImpOpening
        );
        _userSnapshots[owner] = userDepositSnapshot;

        _onAddLiquidity(_userSnapshots[owner], owner);

        // Update Total Balance of the pool for each token
        if (amountOfA > 0) {
            IERC20(_tokenA).safeTransferFrom(msg.sender, address(this), amountOfA);
        }

        if (amountOfB > 0) {
            IERC20(_tokenB).safeTransferFrom(msg.sender, address(this), amountOfB);
        }

        emit AddLiquidity(msg.sender, owner, amountOfA, amountOfB);
    }

    /**
     * @notice _removeLiquidity in any proportion of tokenA or tokenB
     * @dev The inheritor contract should implement _getABPrice and _onRemoveLiquidity functions
     *
     * @param percentA proportion of the exposition of the original tokenA that want to be removed
     * @param percentB proportion of the exposition of the original tokenB that want to be removed
     */
    function _removeLiquidity(uint256 percentA, uint256 percentB) internal {
        (uint256 userTokenABalance, uint256 userTokenBBalance, uint256 userFImp) = _getUserDepositSnapshot(msg.sender);
        require(percentA <= 100 && percentB <= 100, "AMM: forbidden percent");

        uint256 originalBalanceAToReduce = percentA.mul(userTokenABalance).div(PERCENT_PRECISION);
        uint256 originalBalanceBToReduce = percentB.mul(userTokenBBalance).div(PERCENT_PRECISION);

        // Get Pool Balances
        (uint256 totalTokenA, uint256 totalTokenB) = _getPoolBalances();

        // Get ABPrice
        uint256 ABPrice = _getABPrice();

        // Calculate the Pool's Value Factor (Fimp)
        uint256 fImpOpening = _getFImpOpening(
            totalTokenA,
            totalTokenB,
            ABPrice,
            deamortizedTokenABalance,
            deamortizedTokenBBalance
        );

        // Calculate Multipliers
        Mult memory multipliers = _getMultipliers(totalTokenA, totalTokenB, fImpOpening);

        // Update User balance
        _userSnapshots[msg.sender].tokenABalance = userTokenABalance.sub(originalBalanceAToReduce);
        _userSnapshots[msg.sender].tokenBBalance = userTokenBBalance.sub(originalBalanceBToReduce);

        // Update deamortized balance
        deamortizedTokenABalance = deamortizedTokenABalance.sub(
            originalBalanceAToReduce.mul(10**FIMP_DECIMALS).div(userFImp)
        );
        deamortizedTokenBBalance = deamortizedTokenBBalance.sub(
            originalBalanceBToReduce.mul(10**FIMP_DECIMALS).div(userFImp)
        );

        // Calculate amount to send
        (uint256 withdrawAmountA, uint256 withdrawAmountB) = _getWithdrawAmounts(
            originalBalanceAToReduce,
            originalBalanceBToReduce,
            userFImp,
            multipliers
        );

        if (withdrawAmountA > totalTokenA) {
            withdrawAmountA = totalTokenA;
        }

        if (withdrawAmountB > totalTokenB) {
            withdrawAmountB = totalTokenB;
        }

        _onRemoveLiquidity(percentA, percentB, msg.sender);

        // Transfers / Update
        if (withdrawAmountA > 0) {
            IERC20(_tokenA).safeTransfer(msg.sender, withdrawAmountA);
        }

        if (withdrawAmountB > 0) {
            IERC20(_tokenB).safeTransfer(msg.sender, withdrawAmountB);
        }

        emit RemoveLiquidity(msg.sender, withdrawAmountA, withdrawAmountB);
    }

    /**
     * @notice _tradeExactAInput msg.sender is able to trade exact amount of token A in exchange for minimum
     * amount of token B sent by the contract to the owner
     * @dev The inheritor contract should implement _getTradeDetailsExactAInput and _onTradeExactAInput functions
     * _getTradeDetailsExactAInput should return tradeDetails struct format
     *
     * @param exactAmountAIn exact amount of A token that will be transfer from msg.sender
     * @param minAmountBOut minimum acceptable amount of token B to transfer to owner
     * @param owner the destination address that will receive the token B
     */
    function _tradeExactAInput(
        uint256 exactAmountAIn,
        uint256 minAmountBOut,
        address owner
    ) internal returns (uint256) {
        _isValidInput(exactAmountAIn);
        _isValidAddress(owner);
        TradeDetails memory tradeDetails = _getTradeDetailsExactAInput(exactAmountAIn);
        uint256 amountBOut = tradeDetails.amount;
        require(amountBOut > 0, "AMM: invalid amountBOut");
        require(amountBOut >= minAmountBOut, "AMM: slippage not acceptable");

        _onTrade(tradeDetails);

        IERC20(_tokenA).safeTransferFrom(msg.sender, address(this), exactAmountAIn);
        IERC20(_tokenB).safeTransfer(owner, amountBOut);

        emit TradeExactAInput(msg.sender, owner, exactAmountAIn, amountBOut);
        return amountBOut;
    }

    /**
     * @notice _tradeExactAOutput owner is able to receive exact amount of token A in exchange of a max
     * acceptable amount of token B sent by the msg.sender to the contract
     *
     * @dev The inheritor contract should implement _getTradeDetailsExactAOutput and _onTradeExactAOutput functions
     * _getTradeDetailsExactAOutput should return tradeDetails struct format
     *
     * @param exactAmountAOut exact amount of token A that will be transfer to owner
     * @param maxAmountBIn maximum acceptable amount of token B to transfer from msg.sender
     * @param owner the destination address that will receive the token A
     */
    function _tradeExactAOutput(
        uint256 exactAmountAOut,
        uint256 maxAmountBIn,
        address owner
    ) internal returns (uint256) {
        _isValidInput(maxAmountBIn);
        _isValidAddress(owner);
        TradeDetails memory tradeDetails = _getTradeDetailsExactAOutput(exactAmountAOut);
        uint256 amountBIn = tradeDetails.amount;
        require(amountBIn > 0, "AMM: invalid amountBIn");
        require(amountBIn <= maxAmountBIn, "AMM: slippage not acceptable");
        _onTrade(tradeDetails);

        IERC20(_tokenB).safeTransferFrom(msg.sender, address(this), amountBIn);
        IERC20(_tokenA).safeTransfer(owner, exactAmountAOut);

        emit TradeExactAOutput(msg.sender, owner, amountBIn, exactAmountAOut);
        return amountBIn;
    }

    /**
     * @notice _tradeExactBInput msg.sender is able to trade exact amount of token B in exchange for minimum
     * amount of token A sent by the contract to the owner
     *
     * @dev The inheritor contract should implement _getTradeDetailsExactBInput and _onTradeExactBInput functions
     * _getTradeDetailsExactBInput should return tradeDetails struct format
     *
     * @param exactAmountBIn exact amount of token B that will be transfer from msg.sender
     * @param minAmountAOut minimum acceptable amount of token A to transfer to owner
     * @param owner the destination address that will receive the token A
     */
    function _tradeExactBInput(
        uint256 exactAmountBIn,
        uint256 minAmountAOut,
        address owner
    ) internal returns (uint256) {
        _isValidInput(exactAmountBIn);
        _isValidAddress(owner);
        TradeDetails memory tradeDetails = _getTradeDetailsExactBInput(exactAmountBIn);
        uint256 amountAOut = tradeDetails.amount;
        require(amountAOut > 0, "AMM: invalid amountAOut");
        require(amountAOut >= minAmountAOut, "AMM: slippage not acceptable");

        _onTrade(tradeDetails);

        IERC20(_tokenB).safeTransferFrom(msg.sender, address(this), exactAmountBIn);
        IERC20(_tokenA).safeTransfer(owner, amountAOut);

        emit TradeExactBInput(msg.sender, owner, exactAmountBIn, amountAOut);
        return amountAOut;
    }

    /**
     * @notice _tradeExactBOutput owner is able to receive exact amount of token B from the contract in exchange of a
     * max acceptable amount of token A sent by the msg.sender to the contract.
     *
     * @dev The inheritor contract should implement _getTradeDetailsExactBOutput and _onTradeExactBOutput functions
     * _getTradeDetailsExactBOutput should return tradeDetails struct format
     *
     * @param exactAmountBOut exact amount of token B that will be transfer to owner
     * @param maxAmountAIn maximum acceptable amount of token A to transfer from msg.sender
     * @param owner the destination address that will receive the token B
     */
    function _tradeExactBOutput(
        uint256 exactAmountBOut,
        uint256 maxAmountAIn,
        address owner
    ) internal returns (uint256) {
        _isValidInput(maxAmountAIn);
        _isValidAddress(owner);
        TradeDetails memory tradeDetails = _getTradeDetailsExactBOutput(exactAmountBOut);
        uint256 amountAIn = tradeDetails.amount;
        require(amountAIn > 0, "AMM: invalid amountAIn");
        require(amountAIn <= maxAmountAIn, "AMM: slippage not acceptable");

        _onTrade(tradeDetails);

        IERC20(_tokenA).safeTransferFrom(msg.sender, address(this), amountAIn);
        IERC20(_tokenB).safeTransfer(owner, exactAmountBOut);

        emit TradeExactBOutput(msg.sender, owner, amountAIn, exactAmountBOut);
        return amountAIn;
    }

    /**
     * @notice _getFImpOpening Auxiliary function that calculate the Opening Value Factor Fimp
     *
     * @param _totalTokenA total contract balance of token A
     * @param _totalTokenB total contract balance of token B
     * @param _ABPrice Unit price AB, meaning, how many units of token B could buy 1 unit of token A
     * @param _deamortizedTokenABalance contract deamortized balance of token A
     * @param _deamortizedTokenBBalance contract deamortized balance of token B
     * @return fImpOpening Opening Value Factor Fimp
     */
    function _getFImpOpening(
        uint256 _totalTokenA,
        uint256 _totalTokenB,
        uint256 _ABPrice,
        uint256 _deamortizedTokenABalance,
        uint256 _deamortizedTokenBBalance
    ) internal view returns (uint256) {
        uint256 numerator;
        uint256 denominator;
        {
            numerator = _totalTokenA.mul(_ABPrice).div(10**uint256(_tokenADecimals)).add(_totalTokenB).mul(
                10**FIMP_DECIMALS
            );
        }
        {
            denominator = _deamortizedTokenABalance.mul(_ABPrice).div(10**uint256(_tokenADecimals)).add(
                _deamortizedTokenBBalance
            );
        }

        return numerator.div(denominator);
    }

    /**
     * @notice _getPoolBalances external function that returns the current pool balance of token A and token B
     *
     * @return totalTokenA balanceOf this contract of token A
     * @return totalTokenB balanceOf this contract of token B
     */
    function _getPoolBalances() internal view returns (uint256 totalTokenA, uint256 totalTokenB) {
        totalTokenA = IERC20(_tokenA).balanceOf(address(this));
        totalTokenB = IERC20(_tokenB).balanceOf(address(this));
    }

    /**
     * @notice _getUserDepositSnapshot internal function that User original balance of token A,
     * token B and the Opening Value * * Factor (Fimp) at the moment of the liquidity added
     *
     * @param user address of the user that want to check the balance
     *
     * @return tokenAOriginalBalance balance of token A by the moment of deposit
     * @return tokenBOriginalBalance balance of token B by the moment of deposit
     * @return fImpOriginal value of the Opening Value Factor by the moment of the deposit
     */
    function _getUserDepositSnapshot(address user)
        internal
        view
        returns (
            uint256 tokenAOriginalBalance,
            uint256 tokenBOriginalBalance,
            uint256 fImpOriginal
        )
    {
        tokenAOriginalBalance = _userSnapshots[user].tokenABalance;
        tokenBOriginalBalance = _userSnapshots[user].tokenBBalance;
        fImpOriginal = _userSnapshots[user].fImp;
    }

    /**
     * @notice _getMultipliers internal function that calculate new multipliers based on the current pool position
     *
     * mAA => How much A the users can rescue for each A they deposited
     * mBA => How much A the users can rescue for each B they deposited
     * mBB => How much B the users can rescue for each B they deposited
     * mAB => How much B the users can rescue for each A they deposited
     *
     * @param totalTokenA balanceOf this contract of token A
     * @param totalTokenB balanceOf this contract of token B
     * @param fImpOpening current Open Value Factor
     * @return multipliers multiplier struct containing the 4 multipliers: mAA, mBA, mBB, mAB
     */
    function _getMultipliers(
        uint256 totalTokenA,
        uint256 totalTokenB,
        uint256 fImpOpening
    ) internal view returns (Mult memory multipliers) {
        uint256 totalTokenAWithPrecision = totalTokenA.mul(10**FIMP_DECIMALS);
        uint256 totalTokenBWithPrecision = totalTokenB.mul(10**FIMP_DECIMALS);
        uint256 mAA = 0;
        uint256 mBB = 0;
        uint256 mAB = 0;
        uint256 mBA = 0;

        if (deamortizedTokenABalance > 0) {
            mAA = (_min(deamortizedTokenABalance.mul(fImpOpening), totalTokenAWithPrecision)).div(
                deamortizedTokenABalance
            );
        }

        if (deamortizedTokenBBalance > 0) {
            mBB = (_min(deamortizedTokenBBalance.mul(fImpOpening), totalTokenBWithPrecision)).div(
                deamortizedTokenBBalance
            );
        }
        if (mAA > 0) {
            mAB = totalTokenBWithPrecision.sub(mBB.mul(deamortizedTokenBBalance)).div(deamortizedTokenABalance);
        }

        if (mBB > 0) {
            mBA = totalTokenAWithPrecision.sub(mAA.mul(deamortizedTokenABalance)).div(deamortizedTokenBBalance);
        }

        multipliers = Mult(mAA, mAB, mBA, mBB);
    }

    /**
     * @notice _getRemoveLiquidityAmounts internal function of getRemoveLiquidityAmounts
     *
     * @param percentA percent of exposition A to be removed
     * @param percentB percent of exposition B to be removed
     * @param user address of the account that will be removed
     *
     * @return withdrawAmountA amount of token A that will be rescued
     * @return withdrawAmountB amount of token B that will be rescued
     */
    function _getRemoveLiquidityAmounts(
        uint256 percentA,
        uint256 percentB,
        address user
    ) internal view returns (uint256 withdrawAmountA, uint256 withdrawAmountB) {
        (uint256 totalTokenA, uint256 totalTokenB) = _getPoolBalances();
        (uint256 originalBalanceTokenA, uint256 originalBalanceTokenB, uint256 fImpOriginal) = _getUserDepositSnapshot(
            user
        );

        uint256 originalBalanceAToReduce = percentA.mul(originalBalanceTokenA).div(PERCENT_PRECISION);
        uint256 originalBalanceBToReduce = percentB.mul(originalBalanceTokenB).div(PERCENT_PRECISION);

        bool hasNoLiquidity = totalTokenA == 0 && totalTokenB == 0;
        if (hasNoLiquidity) {
            return (0, 0);
        }

        uint256 ABPrice = _getABPrice();
        uint256 fImpOpening = _getFImpOpening(
            totalTokenA,
            totalTokenB,
            ABPrice,
            deamortizedTokenABalance,
            deamortizedTokenBBalance
        );

        Mult memory multipliers = _getMultipliers(totalTokenA, totalTokenB, fImpOpening);

        (withdrawAmountA, withdrawAmountB) = _getWithdrawAmounts(
            originalBalanceAToReduce,
            originalBalanceBToReduce,
            fImpOriginal,
            multipliers
        );
    }

    /**
     * @notice _getWithdrawAmounts internal function of getRemoveLiquidityAmounts
     *
     * @param _originalBalanceAToReduce amount of original deposit of the token A
     * @param _originalBalanceBToReduce amount of original deposit of the token B
     * @param _userFImp Opening Value Factor by the moment of the deposit
     *
     * @return withdrawAmountA amount of token A that will be rescued
     * @return withdrawAmountB amount of token B that will be rescued
     */
    function _getWithdrawAmounts(
        uint256 _originalBalanceAToReduce,
        uint256 _originalBalanceBToReduce,
        uint256 _userFImp,
        Mult memory multipliers
    ) internal pure returns (uint256 withdrawAmountA, uint256 withdrawAmountB) {
        if (_userFImp > 0) {
            withdrawAmountA = _originalBalanceAToReduce
                .mul(multipliers.AA)
                .add(_originalBalanceBToReduce.mul(multipliers.BA))
                .div(_userFImp);
            withdrawAmountB = _originalBalanceBToReduce
                .mul(multipliers.BB)
                .add(_originalBalanceAToReduce.mul(multipliers.AB))
                .div(_userFImp);
        }
        return (withdrawAmountA, withdrawAmountB);
    }

    /**
     * @notice _getUserBalanceToStore internal auxiliary function to help calculation the
     * tokenA and tokenB value that should be stored in UserDepositSnapshot struct
     *
     * @param amountOfA current deposit of the token A
     * @param amountOfB current deposit of the token B
     * @param fImpOpening Opening Value Factor by the moment of the deposit
     *
     * @return userToStoreTokenA amount of token A that will be stored
     * @return userToStoreTokenB amount of token B that will be stored
     */
    function _getUserBalanceToStore(
        uint256 amountOfA,
        uint256 amountOfB,
        uint256 fImpOpening,
        UserDepositSnapshot memory userDepositSnapshot
    ) internal pure returns (uint256 userToStoreTokenA, uint256 userToStoreTokenB) {
        userToStoreTokenA = amountOfA;
        userToStoreTokenB = amountOfB;

        //Re-add Liquidity case
        if (userDepositSnapshot.fImp != 0) {
            userToStoreTokenA = userDepositSnapshot.tokenABalance.mul(fImpOpening).div(userDepositSnapshot.fImp).add(
                amountOfA
            );
            userToStoreTokenB = userDepositSnapshot.tokenBBalance.mul(fImpOpening).div(userDepositSnapshot.fImp).add(
                amountOfB
            );
        }
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _getABPrice() internal virtual view returns (uint256 ABPrice);

    function _getTradeDetailsExactAInput(uint256 amountAIn) internal virtual returns (TradeDetails memory);

    function _getTradeDetailsExactAOutput(uint256 amountAOut) internal virtual returns (TradeDetails memory);

    function _getTradeDetailsExactBInput(uint256 amountBIn) internal virtual returns (TradeDetails memory);

    function _getTradeDetailsExactBOutput(uint256 amountBOut) internal virtual returns (TradeDetails memory);

    function _onTrade(TradeDetails memory tradeDetails) internal virtual;

    function _onRemoveLiquidity(
        uint256 percentA,
        uint256 percentB,
        address owner
    ) internal virtual;

    function _onAddLiquidity(UserDepositSnapshot memory userDepositSnapshot, address owner) internal virtual;

    function _isValidAddress(address recipient) private pure {
        require(recipient != address(0), "AMM: transfer to zero address");
    }

    function _isValidInput(uint256 input) private pure {
        require(input > 0, "AMM: input should be greater than zero");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RequiredDecimals {
    uint256 private constant _MAX_TOKEN_DECIMALS = 38;

    /**
     * Tries to fetch the decimals of a token, if not existent, fails with a require statement
     *
     * @param token An instance of IERC20
     * @return The decimals of a token
     */
    function tryDecimals(IERC20 token) internal view returns (uint8) {
        // solhint-disable-line private-vars-leading-underscore
        bytes memory payload = abi.encodeWithSignature("decimals()");
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory returnData) = address(token).staticcall(payload);

        require(success, "RequiredDecimals: required decimals");
        uint8 decimals = abi.decode(returnData, (uint8));
        require(decimals < _MAX_TOKEN_DECIMALS, "RequiredDecimals: token decimals should be lower than 38");

        return decimals;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.12;

interface IAMM {
    function addLiquidity(
        uint256 amountOfA,
        uint256 amountOfB,
        address owner
    ) external;

    function removeLiquidity(uint256 amountOfA, uint256 amountOfB) external;

    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function tokenADecimals() external view returns (uint8);

    function tokenBDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0

// solhint-disable no-unused-vars
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../amm/AMM.sol";

contract MockAMM is AMM {
    using SafeMath for uint256;

    uint256 public price = 10**18;
    uint256 public priceDecimals = 18;

    constructor(address _tokenA, address _tokenB) public AMM(_tokenA, _tokenB) {}

    function addLiquidity(
        uint256 amountOfA,
        uint256 amountOfB,
        address owner
    ) external override {
        return _addLiquidity(amountOfA, amountOfB, owner);
    }

    function removeLiquidity(uint256 amountOfA, uint256 amountOfB) external override {
        return _removeLiquidity(amountOfA, amountOfB);
    }

    function tradeExactAInput(
        uint256 exactAmountAIn,
        uint256 minAmountBOut,
        address owner
    ) external returns (uint256) {
        return _tradeExactAInput(exactAmountAIn, minAmountBOut, owner);
    }

    function tradeExactAOutput(
        uint256 exactAmountAOut,
        uint256 maxAmountBIn,
        address owner
    ) external returns (uint256) {
        return _tradeExactAOutput(exactAmountAOut, maxAmountBIn, owner);
    }

    function tradeExactBInput(
        uint256 exactAmountBIn,
        uint256 minAmountAOut,
        address owner
    ) external returns (uint256) {
        return _tradeExactBInput(exactAmountBIn, minAmountAOut, owner);
    }

    function tradeExactBOutput(
        uint256 exactAmountBOut,
        uint256 maxAmountAIn,
        address owner
    ) external returns (uint256) {
        return _tradeExactBOutput(exactAmountBOut, maxAmountAIn, owner);
    }

    function _getABPrice() internal override view returns (uint256) {
        return price;
    }

    function _getTradeDetailsExactAInput(uint256 exactAmountAIn) internal override returns (TradeDetails memory) {
        uint256 amountTokensOut = exactAmountAIn.mul(price).div(10**uint256(tokenADecimals()));
        uint256 feesTokenA = 0;
        uint256 feesTokenB = 0;
        TradeDetails memory tradeDetails = TradeDetails(
            amountTokensOut,
            feesTokenA,
            feesTokenB,
            abi.encode(exactAmountAIn)
        );

        return tradeDetails;
    }

    function _getTradeDetailsExactAOutput(uint256 exactAmountAOut) internal override returns (TradeDetails memory) {
        uint256 amountTokensBIn = exactAmountAOut.mul(price).div(10**uint256(tokenADecimals()));
        uint256 feesTokenA = 0;
        uint256 feesTokenB = 0;
        TradeDetails memory tradeDetails = TradeDetails(
            amountTokensBIn,
            feesTokenA,
            feesTokenB,
            abi.encode(amountTokensBIn)
        );

        return tradeDetails;
    }

    function _getTradeDetailsExactBInput(uint256 exactAmountBIn) internal override returns (TradeDetails memory) {
        uint256 amountTokensAOut = exactAmountBIn.mul(10**uint256(tokenBDecimals()).div(price));
        uint256 feesTokenA = 0;
        uint256 feesTokenB = 0;
        TradeDetails memory tradeDetails = TradeDetails(
            amountTokensAOut,
            feesTokenA,
            feesTokenB,
            abi.encode(amountTokensAOut)
        );

        return tradeDetails;
    }

    function _getTradeDetailsExactBOutput(uint256 exactAmountBOut) internal override returns (TradeDetails memory) {
        uint256 amountTokensAIn = exactAmountBOut.mul(10**uint256(tokenBDecimals()).div(price));
        uint256 feesTokenA = 0;
        uint256 feesTokenB = 0;
        TradeDetails memory tradeDetails = TradeDetails(
            amountTokensAIn,
            feesTokenA,
            feesTokenB,
            abi.encode(amountTokensAIn)
        );

        return tradeDetails;
    }

    function setPrice(uint256 _price) public {
        price = _price;
    }

    function _onTrade(TradeDetails memory) internal override {
        return;
    }

    function _onRemoveLiquidity(
        uint256 percentA,
        uint256 percentB,
        address owner
    ) internal override {
        return;
    }

    function _onAddLiquidity(UserDepositSnapshot memory userDepositSnapshot, address owner) internal override {
        return;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IPodOption.sol";
import "../lib/CappedOption.sol";
import "../lib/RequiredDecimals.sol";
import "../interfaces/IConfigurationManager.sol";

/**
 * @title PodOption
 * @author Pods Finance
 *
 * @notice This contract represents the basic structure of the financial instrument
 * known as Option, sharing logic between both a PUT or a CALL types.
 *
 * @dev There are four main actions that can be called in an Option:
 *
 * A) mint => A minter can lock collateral and create new options before expiration.
 * B) unmint => The minter who previously minted can choose for leaving its position any given time
 * until expiration.
 * C) exercise => The option bearer the can exchange its option for the collateral at the strike price.
 * D) withdraw => The minter can retrieve collateral at the end of the series.
 *
 * Depending on the type (PUT / CALL) or the exercise (AMERICAN / EUROPEAN), those functions have
 * different behave and should be override accordingly.
 */
abstract contract PodOption is IPodOption, ERC20, RequiredDecimals, CappedOption {
    using SafeERC20 for IERC20;

    /**
     * @dev Minimum allowed exercise window: 24 hours
     */
    uint256 public constant MIN_EXERCISE_WINDOW_SIZE = 86400;

    OptionType private immutable _optionType;
    ExerciseType private immutable _exerciseType;
    IConfigurationManager public immutable configurationManager;

    address private immutable _underlyingAsset;
    uint8 private immutable _underlyingAssetDecimals;
    address private immutable _strikeAsset;
    uint8 private immutable _strikeAssetDecimals;
    uint256 private immutable _strikePrice;
    uint256 private immutable _expiration;
    uint256 private _startOfExerciseWindow;

    /**
     * @notice Reserve share balance
     * @dev Tracks the shares of the total asset reserve by address
     */
    mapping(address => uint256) public shares;

    /**
     * @notice Minted option balance
     * @dev Tracks amount of minted options by address
     */
    mapping(address => uint256) public mintedOptions;

    /**
     * @notice Total reserve shares
     */
    uint256 public totalShares = 0;

    constructor(
        string memory name,
        string memory symbol,
        OptionType optionType,
        ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager _configurationManager
    ) public ERC20(name, symbol) CappedOption(_configurationManager) {
        require(Address.isContract(underlyingAsset), "PodOption: underlying asset is not a contract");
        require(Address.isContract(strikeAsset), "PodOption: strike asset is not a contract");
        require(underlyingAsset != strikeAsset, "PodOption: underlying asset and strike asset must differ");
        require(expiration > block.timestamp, "PodOption: expiration should be in the future");
        require(strikePrice > 0, "PodOption: strike price must be greater than zero");

        if (exerciseType == ExerciseType.EUROPEAN) {
            require(
                exerciseWindowSize >= MIN_EXERCISE_WINDOW_SIZE,
                "PodOption: exercise window must be greater than or equal 86400"
            );
            _startOfExerciseWindow = expiration.sub(exerciseWindowSize);
        } else {
            require(exerciseWindowSize == 0, "PodOption: exercise window size must be equal to zero");
            _startOfExerciseWindow = block.timestamp;
        }

        configurationManager = _configurationManager;

        _optionType = optionType;
        _exerciseType = exerciseType;
        _expiration = expiration;

        _underlyingAsset = underlyingAsset;
        _strikeAsset = strikeAsset;

        uint8 underlyingDecimals = tryDecimals(IERC20(underlyingAsset));
        _underlyingAssetDecimals = underlyingDecimals;
        _strikeAssetDecimals = tryDecimals(IERC20(strikeAsset));

        _strikePrice = strikePrice;
        _setupDecimals(underlyingDecimals);
    }

    /**
     * @notice Checks if the options series has already expired.
     */
    function hasExpired() external override view returns (bool) {
        return _hasExpired();
    }

    /**
     * @notice External function to calculate the amount of strike asset
     * needed given the option amount
     */
    function strikeToTransfer(uint256 amountOfOptions) external override view returns (uint256) {
        return _strikeToTransfer(amountOfOptions);
    }

    /**
     * @notice Checks if the options trade window has opened.
     */
    function isTradeWindow() external override view returns (bool) {
        return _isTradeWindow();
    }

    /**
     * @notice Checks if the options exercise window has opened.
     */
    function isExerciseWindow() external override view returns (bool) {
        return _isExerciseWindow();
    }

    /**
     * @notice Checks if the options withdraw window has opened.
     */
    function isWithdrawWindow() external override view returns (bool) {
        return _isWithdrawWindow();
    }

    /**
     * @notice The option type. eg: CALL, PUT
     */
    function optionType() external override view returns (OptionType) {
        return _optionType;
    }

    /**
     * @notice Exercise type. eg: AMERICAN, EUROPEAN
     */
    function exerciseType() external override view returns (ExerciseType) {
        return _exerciseType;
    }

    /**
     * @notice The sell price of each unit of underlyingAsset; given in units
     * of strikeAsset, e.g. 0.99 USDC
     */
    function strikePrice() external override view returns (uint256) {
        return _strikePrice;
    }

    /**
     * @notice The number of decimals of strikePrice
     */
    function strikePriceDecimals() external override view returns (uint8) {
        return _strikeAssetDecimals;
    }

    /**
     * @notice The timestamp in seconds that represents the series expiration
     */
    function expiration() external override view returns (uint256) {
        return _expiration;
    }

    /**
     * @notice How many decimals does the strike token have? E.g.: 18
     */
    function strikeAssetDecimals() public override view returns (uint8) {
        return _strikeAssetDecimals;
    }

    /**
     * @notice The asset used as the strike asset, e.g. USDC, DAI
     */
    function strikeAsset() public override view returns (address) {
        return _strikeAsset;
    }

    /**
     * @notice How many decimals does the underlying token have? E.g.: 18
     */
    function underlyingAssetDecimals() public override view returns (uint8) {
        return _underlyingAssetDecimals;
    }

    /**
     * @notice The asset used as the underlying token, e.g. WETH, WBTC, UNI
     */
    function underlyingAsset() public override view returns (address) {
        return _underlyingAsset;
    }

    /**
     * @notice getSellerWithdrawAmounts returns the seller position based on his amount of shares
     * and the current option position
     *
     * @param owner address of the user to check the withdraw amounts
     *
     * @return strikeAmount current amount of strike the user will receive. It may change until maturity
     * @return underlyingAmount current amount of underlying the user will receive. It may change until maturity
     */
    function getSellerWithdrawAmounts(address owner)
        public
        override
        view
        returns (uint256 strikeAmount, uint256 underlyingAmount)
    {
        uint256 ownerShares = shares[owner];

        strikeAmount = ownerShares.mul(strikeReserves()).div(totalShares);
        underlyingAmount = ownerShares.mul(underlyingReserves()).div(totalShares);

        return (strikeAmount, underlyingAmount);
    }

    /**
     * @notice The timestamp in seconds that represents the start of exercise window
     */
    function startOfExerciseWindow() public override view returns (uint256) {
        return _startOfExerciseWindow;
    }

    /**
     * @notice Utility function to check the amount of the underlying tokens
     * locked inside this contract
     */
    function underlyingReserves() public override view returns (uint256) {
        return IERC20(_underlyingAsset).balanceOf(address(this));
    }

    /**
     * @notice Utility function to check the amount of the strike tokens locked
     * inside this contract
     */
    function strikeReserves() public override view returns (uint256) {
        return IERC20(_strikeAsset).balanceOf(address(this));
    }

    /**
     * @dev Modifier with the conditions to be able to mint
     * based on option exerciseType.
     */
    modifier tradeWindow() {
        require(_isTradeWindow(), "PodOption: trade window has closed");
        _;
    }

    /**
     * @dev Modifier with the conditions to be able to unmint
     * based on option exerciseType.
     */
    modifier unmintWindow() {
        require(_isTradeWindow() || _isExerciseWindow(), "PodOption: not in unmint window");
        _;
    }

    /**
     * @dev Modifier with the conditions to be able to exercise
     * based on option exerciseType.
     */
    modifier exerciseWindow() {
        require(_isExerciseWindow(), "PodOption: not in exercise window");
        _;
    }

    /**
     * @dev Modifier with the conditions to be able to withdraw
     * based on exerciseType.
     */
    modifier withdrawWindow() {
        require(_isWithdrawWindow(), "PodOption: option has not expired yet");
        _;
    }

    /**
     * @dev Internal function to check expiration
     */
    function _hasExpired() internal view returns (bool) {
        return block.timestamp >= _expiration;
    }

    /**
     * @dev Internal function to check trade window
     */
    function _isTradeWindow() internal view returns (bool) {
        if (_hasExpired()) {
            return false;
        } else if (_exerciseType == ExerciseType.EUROPEAN) {
            return !_isExerciseWindow();
        }
        return true;
    }

    /**
     * @dev Internal function to check window exercise started
     */
    function _isExerciseWindow() internal view returns (bool) {
        return !_hasExpired() && block.timestamp >= _startOfExerciseWindow;
    }

    /**
     * @dev Internal function to check withdraw started
     */
    function _isWithdrawWindow() internal view returns (bool) {
        return _hasExpired();
    }

    /**
     * @dev Internal function to calculate the amount of strike asset needed given the option amount
     * @param amountOfOptions Intended amount to options to mint
     */
    function _strikeToTransfer(uint256 amountOfOptions) internal view returns (uint256) {
        uint256 strikeAmount = amountOfOptions.mul(_strikePrice).div(10**uint256(underlyingAssetDecimals()));
        require(strikeAmount > 0, "PodOption: amount of options is too low");
        return strikeAmount;
    }

    /**
     * @dev Calculate number of reserve shares based on the amount of collateral locked by the minter
     */
    function _calculatedShares(uint256 amountOfCollateral) internal view returns (uint256 ownerShares) {
        uint256 currentStrikeReserves = strikeReserves();
        uint256 currentUnderlyingReserves = underlyingReserves();

        uint256 numerator = amountOfCollateral.mul(totalShares);
        uint256 denominator;

        if (_optionType == OptionType.PUT) {
            denominator = currentStrikeReserves.add(
                currentUnderlyingReserves.mul(_strikePrice).div(uint256(10)**underlyingAssetDecimals())
            );
        } else {
            denominator = currentUnderlyingReserves.add(
                currentStrikeReserves.mul(uint256(10)**underlyingAssetDecimals()).div(_strikePrice)
            );
        }
        ownerShares = numerator.div(denominator);
        return ownerShares;
    }

    /**
     * @dev Mint options, creating the shares accordingly to the amount of collateral provided
     * @param amountOfOptions The amount option tokens to be issued
     * @param amountOfCollateral The amount of collateral provided to mint options
     * @param owner Which address will be the owner of the options
     */
    function _mintOptions(
        uint256 amountOfOptions,
        uint256 amountOfCollateral,
        address owner
    ) internal capped(amountOfOptions) {
        require(owner != address(0), "PodOption: zero address cannot be the owner");

        if (totalShares > 0) {
            uint256 ownerShares = _calculatedShares(amountOfCollateral);

            shares[owner] = shares[owner].add(ownerShares);
            totalShares = totalShares.add(ownerShares);
        } else {
            shares[owner] = amountOfCollateral;
            totalShares = amountOfCollateral;
        }

        mintedOptions[owner] = mintedOptions[owner].add(amountOfOptions);

        _mint(msg.sender, amountOfOptions);
    }

    /**
     * @dev Unmints options, burning the option tokens removing shares accordingly and releasing a certain
     * amount of collateral.
     * @param amountOfOptions The amount option tokens to be burned
     * @param owner Which address options will be burned from
     */
    function _unmintOptions(uint256 amountOfOptions, address owner)
        internal
        returns (uint256 strikeToSend, uint256 underlyingToSend)
    {
        require(shares[owner] > 0, "PodOption: you do not have minted options");
        require(amountOfOptions <= mintedOptions[owner], "PodOption: not enough minted options");

        uint256 burnedShares = shares[owner].mul(amountOfOptions).div(mintedOptions[owner]);

        if (_optionType == IPodOption.OptionType.PUT) {
            uint256 strikeAssetDeposited = totalSupply().mul(_strikePrice).div(10**uint256(decimals()));
            uint256 totalInterest = 0;

            if (strikeReserves() > strikeAssetDeposited) {
                totalInterest = strikeReserves().sub(strikeAssetDeposited);
            }

            strikeToSend = amountOfOptions.mul(_strikePrice).div(10**uint256(decimals())).add(
                totalInterest.mul(burnedShares).div(totalShares)
            );

            // In the case we lost some funds due to precision, the last user to unmint will still be able to perform.
            if (strikeToSend > strikeReserves()) {
                strikeToSend = strikeReserves();
            }
        } else {
            uint256 underlyingAssetDeposited = totalSupply();
            uint256 currentUnderlyingAmount = underlyingReserves();
            uint256 totalInterest = 0;

            if (currentUnderlyingAmount > underlyingAssetDeposited) {
                totalInterest = currentUnderlyingAmount.sub(underlyingAssetDeposited);
            }

            underlyingToSend = amountOfOptions.add(totalInterest.mul(burnedShares).div(totalShares));
        }

        shares[owner] = shares[owner].sub(burnedShares);
        mintedOptions[owner] = mintedOptions[owner].sub(amountOfOptions);
        totalShares = totalShares.sub(burnedShares);

        _burn(owner, amountOfOptions);
    }

    /**
     * @dev Removes all shares, returning the amounts that would be withdrawable
     */
    function _withdraw() internal returns (uint256 strikeToSend, uint256 underlyingToSend) {
        uint256 ownerShares = shares[msg.sender];
        require(ownerShares > 0, "PodOption: you do not have balance to withdraw");

        (strikeToSend, underlyingToSend) = getSellerWithdrawAmounts(msg.sender);

        shares[msg.sender] = 0;
        mintedOptions[msg.sender] = 0;
        totalShares = totalShares.sub(ownerShares);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPodOption is IERC20 {
    /** Enums */
    // @dev 0 for Put, 1 for Call
    enum OptionType { PUT, CALL }
    // @dev 0 for European, 1 for American
    enum ExerciseType { EUROPEAN, AMERICAN }

    /** Events */
    event Mint(address indexed minter, uint256 amount);
    event Unmint(address indexed minter, uint256 optionAmount, uint256 strikeAmount, uint256 underlyingAmount);
    event Exercise(address indexed exerciser, uint256 amount);
    event Withdraw(address indexed minter, uint256 strikeAmount, uint256 underlyingAmount);

    /** Functions */

    /**
     * @notice Locks collateral and write option tokens.
     *
     * @dev The issued amount ratio is 1:1, i.e., 1 option token for 1 underlying token.
     *
     * The collateral could be the strike or the underlying asset depending on the option type: Put or Call,
     * respectively
     *
     * It presumes the caller has already called IERC20.approve() on the
     * strike/underlying token contract to move caller funds.
     *
     * Options can only be minted while the series is NOT expired.
     *
     * It is also important to notice that options will be sent back
     * to `msg.sender` and not the `owner`. This behavior is designed to allow
     * proxy contracts to mint on others behalf. The `owner` will be able to remove
     * the deposited collateral after series expiration or by calling unmint(), even
     * if a third-party minted options on its behalf.
     *
     * @param amountOfOptions The amount option tokens to be issued
     * @param owner Which address will be the owner of the options
     */
    function mint(uint256 amountOfOptions, address owner) external;

    /**
     * @notice Allow option token holders to use them to exercise the amount of units
     * of the locked tokens for the equivalent amount of the exercisable assets.
     *
     * @dev It presumes the caller has already called IERC20.approve() exercisable asset
     * to move caller funds.
     *
     * On American options, this function can only called anytime before expiration.
     * For European options, this function can only be called during the exerciseWindow.
     * Meaning, after expiration and before the end of exercise window.
     *
     * @param amountOfOptions The amount option tokens to be exercised
     */
    function exercise(uint256 amountOfOptions) external;

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their collateral to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and collateral.
     */
    function withdraw() external;

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external;

    function optionType() external view returns (OptionType);

    function exerciseType() external view returns (ExerciseType);

    function underlyingAsset() external view returns (address);

    function underlyingAssetDecimals() external view returns (uint8);

    function strikeAsset() external view returns (address);

    function strikeAssetDecimals() external view returns (uint8);

    function strikePrice() external view returns (uint256);

    function strikePriceDecimals() external view returns (uint8);

    function expiration() external view returns (uint256);

    function startOfExerciseWindow() external view returns (uint256);

    function hasExpired() external view returns (bool);

    function isTradeWindow() external view returns (bool);

    function isExerciseWindow() external view returns (bool);

    function isWithdrawWindow() external view returns (bool);

    function strikeToTransfer(uint256 amountOfOptions) external view returns (uint256);

    function getSellerWithdrawAmounts(address owner)
        external
        view
        returns (uint256 strikeAmount, uint256 underlyingAmount);

    function underlyingReserves() external view returns (uint256);

    function strikeReserves() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IConfigurationManager.sol";
import "../interfaces/ICapProvider.sol";

/**
 * @title CappedOption
 * @author Pods Finance
 *
 * @notice Controls a maximum cap for a guarded release
 */
abstract contract CappedOption is IERC20 {
    using SafeMath for uint256;

    IConfigurationManager private immutable _configurationManager;

    constructor(IConfigurationManager configurationManager) public {
        _configurationManager = configurationManager;
    }

    /**
     * @dev Modifier to stop transactions that exceed the cap
     */
    modifier capped(uint256 amountOfOptions) {
        uint256 cap = capSize();
        if (cap > 0) {
            require(this.totalSupply().add(amountOfOptions) <= cap, "CappedOption: amount exceed cap");
        }
        _;
    }

    /**
     * @dev Get the cap size
     */
    function capSize() public view returns (uint256) {
        ICapProvider capProvider = ICapProvider(_configurationManager.getCapProvider());
        return capProvider.getCap(address(this));
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.12;

interface IConfigurationManager {
    function setParameter(bytes32 name, uint256 value) external;

    function setEmergencyStop(address emergencyStop) external;

    function setPricingMethod(address pricingMethod) external;

    function setIVGuesser(address ivGuesser) external;

    function setIVProvider(address ivProvider) external;

    function setPriceProvider(address priceProvider) external;

    function setCapProvider(address capProvider) external;

    function setAMMFactory(address ammFactory) external;

    function setOptionFactory(address optionFactory) external;

    function setOptionHelper(address optionHelper) external;

    function setOptionPoolRegistry(address optionPoolRegistry) external;

    function getParameter(bytes32 name) external view returns (uint256);

    function owner() external view returns (address);

    function getEmergencyStop() external view returns (address);

    function getPricingMethod() external view returns (address);

    function getIVGuesser() external view returns (address);

    function getIVProvider() external view returns (address);

    function getPriceProvider() external view returns (address);

    function getCapProvider() external view returns (address);

    function getAMMFactory() external view returns (address);

    function getOptionFactory() external view returns (address);

    function getOptionHelper() external view returns (address);

    function getOptionPoolRegistry() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface ICapProvider {
    function setCap(address target, uint256 value) external;

    function getCap(address target) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./PodOption.sol";

/**
 * @title PodPut
 * @author Pods Finance
 *
 * @notice Represents a tokenized Put option series for some long/short token pair.
 *
 * @dev Put options represents the right, not the obligation to sell the underlying asset
 * for strike price units of the strike asset.
 *
 * There are four main actions that can be done with an option:
 *
 * Sellers can mint fungible Put option tokens by locking strikePrice * amountOfOptions
 * strike asset units until expiration. Buyers can exercise their Put, meaning
 * selling their underlying asset for strikePrice * amountOfOptions units of strike asset.
 * At the end, seller can retrieve back its collateral, that could be the underlying asset
 * AND/OR strike based on the contract's current ratio of underlying and strike assets.
 *
 * There are many option's style, but the most usual are: American and European.
 * The difference between them are the moments that the buyer is allowed to exercise and
 * the moment that seller can retrieve its locked collateral.
 *
 *  Exercise:
 *  American -> any moment until expiration
 *  European -> only after expiration and until the end of the exercise window
 *
 *  Withdraw:
 *  American -> after expiration
 *  European -> after end of exercise window
 *
 * Let's take an example: there is such an European Put option series where buyers
 * may sell 1 WETH for 300 USDC until Dec 31, 2021.
 *
 * In this case:
 *
 * - Expiration date: Dec 31, 2021
 * - Underlying asset: WETH
 * - Strike asset: USDC
 * - Strike price: 300 USDC
 *
 * USDC holders may call mint() until the expiration date, which in turn:
 *
 * - Will lock their USDC into this contract
 * - Will mint/issue option tokens corresponding to this USDC amount
 * - This contract is agnostic about where to sell/buy and how much should be the
 * the option premium.
 *
 * USDC holders who also hold the option tokens may call unmint() until the
 * expiration date, which in turn:
 *
 * - Will unlock their USDC from this contract
 * - Will burn the corresponding amount of options tokens
 *
 * Option token holders may call exercise() after the expiration date and
 * before the end of exercise window, to exercise their option, which in turn:
 *
 * - Will sell 1 ETH for 300 USDC (the strike price) each.
 * - Will burn the corresponding amount of option tokens.
 *
 * USDC holders that minted options initially can call withdraw() after the
 * end of exercise window, which in turn:
 *
 * - Will give back its amount of collateral locked. That could be o mix of
 * underlying asset and strike asset based if and how the pool was exercised.
 *
 * IMPORTANT: Note that after expiration, option tokens are worthless since they can not
 * be exercised and its price should worth 0 in a healthy market.
 *
 */
contract PodPut is PodOption {
    constructor(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    )
        public
        PodOption(
            name,
            symbol,
            IPodOption.OptionType.PUT,
            exerciseType,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        )
    {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Locks strike asset and write option tokens.
     *
     * @dev The issued amount ratio is 1:1, i.e., 1 option token for 1 underlying token.
     *
     * It presumes the caller has already called IERC20.approve() on the
     * strike token contract to move caller funds.
     *
     * This function is meant to be called by strike token holders wanting
     * to write option tokens. Calling it will lock `amountOfOptions` * `strikePrice`
     * units of `strikeToken` into this contract
     *
     * Options can only be minted while the series is NOT expired.
     *
     * It is also important to notice that options will be sent back
     * to `msg.sender` and not the `owner`. This behavior is designed to allow
     * proxy contracts to mint on others behalf. The `owner` will be able to remove
     * the deposited collateral after series expiration or by calling unmint(), even
     * if a third-party minted options on its behalf.
     *
     * @param amountOfOptions The amount option tokens to be issued
     * @param owner Which address will be the owner of the options
     */
    function mint(uint256 amountOfOptions, address owner) external override tradeWindow {
        require(amountOfOptions > 0, "PodPut: you can not mint zero options");

        uint256 amountToTransfer = _strikeToTransfer(amountOfOptions);
        _mintOptions(amountOfOptions, amountToTransfer, owner);

        IERC20(strikeAsset()).safeTransferFrom(msg.sender, address(this), amountToTransfer);

        emit Mint(owner, amountOfOptions);
    }

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external virtual override unmintWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _unmintOptions(amountOfOptions, msg.sender);
        require(strikeToSend > 0, "PodPut: amount of options is too low");

        // Sends strike asset
        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        emit Unmint(msg.sender, amountOfOptions, strikeToSend, underlyingToSend);
    }

    /**
     * @notice Allow Put token holders to use them to sell some amount of units
     * of the underlying token for the amount * strike price units of the
     * strike token.
     *
     * @dev It presumes the caller has already called IERC20.approve() on the
     * underlying token contract to move caller funds.
     *
     * During the process:
     *
     * - The amount * strikePrice of strike tokens are transferred to the caller
     * - The amount of option tokens are burned
     * - The amount of underlying tokens are transferred into
     * this contract as a payment for the strike tokens
     *
     * On American options, this function can only called anytime before expiration.
     * For European options, this function can only be called during the exerciseWindow.
     * Meaning, after expiration and before the end of exercise window.
     *
     * @param amountOfOptions The amount option tokens to be exercised
     */
    function exercise(uint256 amountOfOptions) external virtual override exerciseWindow {
        require(amountOfOptions > 0, "PodPut: you can not exercise zero options");
        // Calculate the strike amount equivalent to pay for the underlying requested
        uint256 amountOfStrikeToTransfer = _strikeToTransfer(amountOfOptions);

        // Burn the option tokens equivalent to the underlying requested
        _burn(msg.sender, amountOfOptions);

        // Retrieve the underlying asset from caller
        IERC20(underlyingAsset()).safeTransferFrom(msg.sender, address(this), amountOfOptions);

        // Releases the strike asset to caller, completing the exchange
        IERC20(strikeAsset()).safeTransfer(msg.sender, amountOfStrikeToTransfer);

        emit Exercise(msg.sender, amountOfOptions);
    }

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their strike asset tokens to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and strike asset tokens.
     */
    function withdraw() external virtual override withdrawWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _withdraw();

        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        if (underlyingToSend > 0) {
            IERC20(underlyingAsset()).safeTransfer(msg.sender, underlyingToSend);
        }

        emit Withdraw(msg.sender, strikeToSend, underlyingToSend);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./PodPut.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../lib/Conversion.sol";

/**
 * @title WPodPut
 * @author Pods Finance
 *
 * @notice Represents a tokenized Put option series for ETH. Internally it Wraps
 * ETH to treat it seamlessly.
 *
 * @dev Put options represents the right, not the obligation to sell the underlying asset
 * for strike price units of the strike asset.
 *
 * There are four main actions that can be done with an option:
 *
 * Sellers can mint fungible Put option tokens by locking strikePrice * amountOfOptions
 * strike asset units until expiration. Buyers can exercise their Put, meaning
 * selling their underlying asset for strikePrice * amountOfOptions units of strike asset.
 * At the end, seller can retrieve back its collateral, that could be the underlying asset
 * AND/OR strike based on the contract's current ratio of underlying and strike assets.
 *
 * There are many option's style, but the most usual are: American and European.
 * The difference between them are the moments that the buyer is allowed to exercise and
 * the moment that seller can retrieve its locked collateral.
 *
 *  Exercise:
 *  American -> any moment until expiration
 *  European -> only after expiration and until the end of the exercise window
 *
 *  Withdraw:
 *  American -> after expiration
 *  European -> after end of exercise window
 *
 * Let's take an example: there is such a put option series where buyers
 * may sell 1 ETH for 300 USDC until Dec 31, 2021.
 *
 * In this case:
 *
 * - Expiration date: Dec 31, 2021
 * - Underlying asset: ETH
 * - Strike asset: USDC
 * - Strike price: 300 USDC
 *
 * USDC holders may call mint() until the expiration date, which in turn:
 *
 * - Will lock their USDC into this contract
 * - Will issue put tokens corresponding to this USDC amount
 * - This contract is agnostic about where options could be bought or sold and how much the
 * the option premium should be.
 *
 * USDC holders who also hold the option tokens may call unmint() until the
 * expiration date, which in turn:
 *
 * - Will unlock their USDC from this contract
 * - Will burn the corresponding amount of put tokens
 *
 * Put token holders may call exerciseEth() until the expiration date, to
 * exercise their option, which in turn:
 *
 * - Will sell 1 ETH for 300 USDC (the strike price) each.
 * - Will burn the corresponding amount of put tokens.
 *
 * IMPORTANT: Note that after expiration, option tokens are worthless since they can not
 * be exercised and its price should be worth 0 in a healthy market.
 *
 */
contract WPodPut is PodPut, Conversion {
    event Received(address indexed sender, uint256 value);

    constructor(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    )
        public
        PodPut(
            name,
            symbol,
            exerciseType,
            _parseAddressFromUint(configurationManager.getParameter("WRAPPED_NETWORK_TOKEN")),
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        )
    {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external override unmintWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _unmintOptions(amountOfOptions, msg.sender);
        require(strikeToSend > 0, "WPodPut: amount of options is too low");

        // Sends strike asset
        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        emit Unmint(msg.sender, amountOfOptions, strikeToSend, underlyingToSend);
    }

    /**
     * @notice Allow Put token holders to use them to sell some amount of units
     * of ETH for the amount * strike price units of the strike token.
     *
     * @dev It uses the amount of ETH sent to exchange to the strike amount
     *
     * During the process:
     *
     * - The amount of ETH is transferred into this contract as a payment for the strike tokens
     * - The ETH is wrapped into WETH
     * - The amount of ETH * strikePrice of strike tokens are transferred to the caller
     * - The amount of option tokens are burned
     *
     * On American options, this function can only called anytime before expiration.
     * For European options, this function can only be called during the exerciseWindow.
     * Meaning, after expiration and before the end of exercise window.
     */
    function exerciseEth() external payable exerciseWindow {
        uint256 amountOfOptions = msg.value;
        require(amountOfOptions > 0, "WPodPut: you can not exercise zero options");
        // Calculate the strike amount equivalent to pay for the underlying requested
        uint256 strikeToSend = _strikeToTransfer(amountOfOptions);

        // Burn the option tokens equivalent to the underlying requested
        _burn(msg.sender, amountOfOptions);

        // Retrieve the underlying asset from caller
        IWETH(underlyingAsset()).deposit{ value: msg.value }();

        // Releases the strike asset to caller, completing the exchange
        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        emit Exercise(msg.sender, amountOfOptions);
    }

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their strike asset tokens to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and strike asset tokens.
     */
    function withdraw() external override withdrawWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _withdraw();

        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        if (underlyingToSend > 0) {
            IWETH(underlyingAsset()).withdraw(underlyingToSend);
            Address.sendValue(msg.sender, underlyingToSend);
        }

        emit Withdraw(msg.sender, strikeToSend, underlyingToSend);
    }

    receive() external payable {
        require(msg.sender == this.underlyingAsset(), "WPodPut: Only deposits from WETH are allowed");
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

contract Conversion {
    /**
     * @notice Parses the address represented by an uint
     */
    function _parseAddressFromUint(uint256 x) internal pure returns (address) {
        bytes memory data = new bytes(32);
        assembly {
            mstore(add(data, 32), x)
        }
        return abi.decode(data, (address));
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../interfaces/IOptionBuilder.sol";
import "../interfaces/IPodOption.sol";
import "../lib/Conversion.sol";
import "../interfaces/IOptionFactory.sol";

/**
 * @title OptionFactory
 * @author Pods Finance
 * @notice Creates and store new Options Series
 * @dev Uses IOptionBuilder to create the different types of Options
 */
contract OptionFactory is IOptionFactory, Conversion {
    IConfigurationManager public immutable configurationManager;
    IOptionBuilder public podPutBuilder;
    IOptionBuilder public wPodPutBuilder;
    IOptionBuilder public aavePodPutBuilder;
    IOptionBuilder public podCallBuilder;
    IOptionBuilder public wPodCallBuilder;
    IOptionBuilder public aavePodCallBuilder;

    event OptionCreated(
        address indexed deployer,
        address option,
        IPodOption.OptionType _optionType,
        IPodOption.ExerciseType _exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize
    );

    constructor(
        address PodPutBuilder,
        address WPodPutBuilder,
        address AavePodPutBuilder,
        address PodCallBuilder,
        address WPodCallBuilder,
        address AavePodCallBuilder,
        address ConfigurationManager
    ) public {
        configurationManager = IConfigurationManager(ConfigurationManager);
        podPutBuilder = IOptionBuilder(PodPutBuilder);
        wPodPutBuilder = IOptionBuilder(WPodPutBuilder);
        aavePodPutBuilder = IOptionBuilder(AavePodPutBuilder);
        podCallBuilder = IOptionBuilder(PodCallBuilder);
        wPodCallBuilder = IOptionBuilder(WPodCallBuilder);
        aavePodCallBuilder = IOptionBuilder(AavePodCallBuilder);
    }

    /**
     * @notice Creates a new Option Series
     * @param name The option token name. Eg. "Pods Put WBTC-USDC 5000 2020-02-23"
     * @param symbol The option token symbol. Eg. "podWBTC:20AA"
     * @param optionType The option type. Eg. "0 for Put / 1 for Calls"
     * @param exerciseType The option exercise type. Eg. "0 for European, 1 for American"
     * @param underlyingAsset The underlying asset. Eg. "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
     * @param strikeAsset The strike asset. Eg. "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
     * @param strikePrice The option strike price including decimals. e.g. 5000000000
     * @param expiration The Expiration Option date in seconds. e.g. 1600178324
     * @param exerciseWindowSize The Expiration Window Size duration in seconds. E.g 24*60*60 (24h)
     * @return option The address for the newly created option
     */
    function createOption(
        string memory name,
        string memory symbol,
        IPodOption.OptionType optionType,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        bool isAave
    ) external override returns (address) {
        IOptionBuilder builder;
        address wrappedNetworkToken = wrappedNetworkTokenAddress();

        if (optionType == IPodOption.OptionType.PUT) {
            if (underlyingAsset == wrappedNetworkToken) {
                builder = wPodPutBuilder;
            } else if (isAave) {
                builder = aavePodPutBuilder;
            } else {
                builder = podPutBuilder;
            }
        } else {
            if (underlyingAsset == wrappedNetworkToken) {
                builder = wPodCallBuilder;
            } else if (isAave) {
                builder = aavePodCallBuilder;
            } else {
                builder = podCallBuilder;
            }
        }

        address option = address(
            builder.buildOption(
                name,
                symbol,
                exerciseType,
                underlyingAsset,
                strikeAsset,
                strikePrice,
                expiration,
                exerciseWindowSize,
                configurationManager
            )
        );

        emit OptionCreated(
            msg.sender,
            option,
            optionType,
            exerciseType,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize
        );

        return option;
    }

    function wrappedNetworkTokenAddress() public override returns (address) {
        return _parseAddressFromUint(configurationManager.getParameter("WRAPPED_NETWORK_TOKEN"));
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./IPodOption.sol";
import "./IConfigurationManager.sol";

interface IOptionBuilder {
    function buildOption(
        string memory _name,
        string memory _symbol,
        IPodOption.ExerciseType _exerciseType,
        address _underlyingAsset,
        address _strikeAsset,
        uint256 _strikePrice,
        uint256 _expiration,
        uint256 _exerciseWindowSize,
        IConfigurationManager _configurationManager
    ) external returns (IPodOption);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./IPodOption.sol";

interface IOptionFactory {
    function createOption(
        string memory _name,
        string memory _symbol,
        IPodOption.OptionType _optionType,
        IPodOption.ExerciseType _exerciseType,
        address _underlyingAsset,
        address _strikeAsset,
        uint256 _strikePrice,
        uint256 _expiration,
        uint256 _exerciseWindowSize,
        bool _isAave
    ) external returns (address);

    function wrappedNetworkTokenAddress() external returns (address);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../WPodPut.sol";
import "../../interfaces/IPodOption.sol";
import "../../interfaces/IOptionBuilder.sol";

/**
 * @title WPodPutBuilder
 * @author Pods Finance
 * @notice Builds WPodPut options
 */
contract WPodPutBuilder is IOptionBuilder {
    /**
     * @notice creates a new WPodPut Contract
     * @param name The option token name. Eg. "Pods Put WETH-USDC 5000 2020-02-23"
     * @param symbol The option token symbol. Eg. "podWETH:20AA"
     * @param exerciseType The option exercise type. Eg. "0 for European, 1 for American"
     * @param underlyingAsset The underlying asset. For this type of option its not going to be used. Eg. "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
     * @param strikeAsset The strike asset. Eg. "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
     * @param strikePrice The option strike price including decimals. e.g. 5000000000
     * @param expiration The Expiration Option date in seconds. e.g. 1600178324
     * @param exerciseWindowSize The Expiration Window Size duration in seconds. E.g 24*60*60 (24h)
     */
    function buildOption(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset, // solhint-disable-line
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    ) external override returns (IPodOption) {
        WPodPut option = new WPodPut(
            name,
            symbol,
            exerciseType,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        );

        return option;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../WPodCall.sol";
import "../../interfaces/IPodOption.sol";
import "../../interfaces/IOptionBuilder.sol";

/**
 * @title WPodCallBuilder
 * @author Pods Finance
 * @notice Builds WPodCall options
 */
contract WPodCallBuilder is IOptionBuilder {
    /**
     * @notice creates a new WPodCall Contract
     * @param name The option token name. Eg. "Pods Call WETH-USDC 5000 2020-02-23"
     * @param symbol The option token symbol. Eg. "podWETH:20AA"
     * @param exerciseType The option exercise type. Eg. "0 for European, 1 for American"
     * @param underlyingAsset The underlying asset. For this type of option its not going to be used. Eg. "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
     * @param strikeAsset The strike asset. Eg. "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
     * @param strikePrice The option strike price including decimals. e.g. 5000000000
     * @param expiration The Expiration Option date in seconds. e.g. 1600178324
     * @param exerciseWindowSize The Expiration Window Size duration in seconds. E.g 24*60*60 (24h)
     */
    function buildOption(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset, // solhint-disable-line
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    ) external override returns (IPodOption) {
        WPodCall option = new WPodCall(
            name,
            symbol,
            exerciseType,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        );

        return option;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./PodCall.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../lib/Conversion.sol";

/**
 * @title WPodCall
 * @author Pods Finance
 *
 * @notice Represents a tokenized Call option series for some long/short token pair.
 *
 * @dev Call options represents the right, not the obligation to buy the underlying asset
 * for strike price units of the strike asset.
 *
 * There are four main actions that can be done with an option:
 *
 * Sellers can mint fungible call option tokens by locking 1:1 units
 * of underlying asset until expiration. Buyers can exercise their call, meaning
 * buying the locked underlying asset for strike price units of strike asset.
 * At the end, seller can retrieve back its collateral, that could be the underlying asset
 * AND/OR strike based on the contract's current ratio of underlying and strike assets.
 *
 * There are many option's style, but the most usual are: American and European.
 * The difference between them are the moments that the buyer is allowed to exercise and
 * the moment that seller can retrieve its locked collateral.
 *
 *  Exercise:
 *  American -> any moment until expiration
 *  European -> only after expiration and until the end of the exercise window
 *
 *  Withdraw:
 *  American -> after expiration
 *  European -> after end of exercise window
 *
 * Let's take an example: there is such an European call option series where buyers
 * may buy 1 ETH for 300 USDC until Dec 31, 2021.
 *
 * In this case:
 *
 * - Expiration date: Dec 31, 2021
 * - Underlying asset: ETH
 * - Strike asset: USDC
 * - Strike price: 300 USDC
 *
 * ETH holders may call mint() until the expiration date, which in turn:
 *
 * - Will lock their WETH into this contract
 * - Will issue option tokens corresponding to this WETH amount
 * - This contract is agnostic about where options could be bought or sold and how much the
 * the option premium should be.
 *
 * WETH holders who also hold the option tokens may call unmint() until the
 * expiration date, which in turn:
 *
 * - Will unlock their WETH from this contract
 * - Will burn the corresponding amount of options tokens
 *
 * Option token holders may call exercise() after the expiration date and
 * end of before exercise window, to exercise their option, which in turn:
 *
 * - Will buy 1 ETH for 300 USDC (the strike price) each.
 * - Will burn the corresponding amount of option tokens.
 *
 * WETH holders that minted options initially can call withdraw() after the
 * end of exercise window, which in turn:
 *
 * - Will give back its amount of collateral locked. That could be o mix of
 * underlying asset and strike asset based if and how the pool was exercised.
 *
 * IMPORTANT: Note that after expiration, option tokens are worthless since they can not
 * be exercised and its price should be worth 0 in a healthy market.
 *
 */
contract WPodCall is PodCall, Conversion {
    event Received(address indexed sender, uint256 value);

    constructor(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    )
        public
        PodCall(
            name,
            symbol,
            exerciseType,
            _parseAddressFromUint(configurationManager.getParameter("WRAPPED_NETWORK_TOKEN")),
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        )
    {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Locks underlying asset (ETH) and write option tokens.
     *
     * @dev The issued amount ratio is 1:1, i.e., 1 option token for 1 underlying token.
     *
     * This function is meant to be called by underlying token (ETH) holders wanting
     * to write option tokens. Calling it will lock `amountOfOptions` units of
     * `underlyingToken` into this contract
     *
     * Options can only be minted while the series is NOT expired.
     *
     * It is also important to notice that options will be sent back
     * to `msg.sender` and not the `owner`. This behavior is designed to allow
     * proxy contracts to mint on others behalf. The `owner` will be able to remove
     * the deposited collateral after series expiration or by calling unmint(), even
     * if a third-party minted options on its behalf.
     *
     * @param owner Which address will be the owner of the options
     */
    function mintEth(address owner) external payable tradeWindow {
        uint256 amountOfOptions = msg.value;
        require(amountOfOptions > 0, "WPodCall: you can not mint zero options");
        _mintOptions(amountOfOptions, amountOfOptions, owner);

        IWETH(underlyingAsset()).deposit{ value: amountOfOptions }();

        emit Mint(owner, amountOfOptions);
    }

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external virtual override unmintWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _unmintOptions(amountOfOptions, msg.sender);

        // Sends underlying asset
        IWETH(underlyingAsset()).withdraw(underlyingToSend);
        Address.sendValue(msg.sender, underlyingToSend);

        emit Unmint(msg.sender, amountOfOptions, strikeToSend, underlyingToSend);
    }

    /**
     * @notice Allow Call token holders to use them to buy some amount of ETH
     * for the amountOfOptions * strike price units of the strike token.
     *
     * @dev It presumes the caller has already called IERC20.approve() on the
     * strike token contract to move caller funds.
     *
     * During the process:
     *
     * - The amountOfOptions units of underlying tokens are transferred to the caller
     * - The amountOfOptions option tokens are burned.
     * - The amountOfOptions * strikePrice units of strike tokens are transferred into
     * this contract as a payment for the underlying tokens.
     *
     * On American options, this function can only called anytime before expiration.
     * For European options, this function can only be called during the exerciseWindow.
     * Meaning, after expiration and before the end of exercise window.
     *
     * @param amountOfOptions The amount option tokens to be exercised
     */
    function exercise(uint256 amountOfOptions) external override exerciseWindow {
        require(amountOfOptions > 0, "WPodCall: you can not exercise zero options");
        // Calculate the strike amount equivalent to pay for the underlying requested
        uint256 amountStrikeToReceive = _strikeToTransfer(amountOfOptions);

        // Burn the exercised options
        _burn(msg.sender, amountOfOptions);

        // Retrieve the strike asset from caller
        IERC20(strikeAsset()).safeTransferFrom(msg.sender, address(this), amountStrikeToReceive);

        // Sends underlying asset
        IWETH(underlyingAsset()).withdraw(amountOfOptions);
        Address.sendValue(msg.sender, amountOfOptions);

        emit Exercise(msg.sender, amountOfOptions);
    }

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their underlying asset tokens to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and underlying asset tokens.
     */
    function withdraw() external virtual override withdrawWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _withdraw();

        if (strikeToSend > 0) {
            IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);
        }

        // Sends underlying asset
        IWETH(underlyingAsset()).withdraw(underlyingToSend);
        Address.sendValue(msg.sender, underlyingToSend);

        emit Withdraw(msg.sender, strikeToSend, underlyingToSend);
    }

    receive() external payable {
        require(msg.sender == this.underlyingAsset(), "WPodCall: Only deposits from WETH are allowed");
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./PodOption.sol";

/**
 * @title PodCall
 * @author Pods Finance
 *
 * @notice Represents a tokenized Call option series for some long/short token pair.
 *
 * @dev Call options represents the right, not the obligation to buy the underlying asset
 * for strike price units of the strike asset.
 *
 * There are four main actions that can be done with an option:
 *
 *
 * Sellers can mint fungible call option tokens by locking 1:1 units
 * of underlying asset until expiration. Buyers can exercise their call, meaning
 * buying the locked underlying asset for strike price units of strike asset.
 * At the end, seller can retrieve back its collateral, that could be the underlying asset
 * AND/OR strike based on the contract's current ratio of underlying and strike assets.
 *
 * There are many option's style, but the most usual are: American and European.
 * The difference between them are the moments that the buyer is allowed to exercise and
 * the moment that seller can retrieve its locked collateral.
 *
 *  Exercise:
 *  American -> any moment until expiration
 *  European -> only after expiration and until the end of the exercise window
 *
 *  Withdraw:
 *  American -> after expiration
 *  European -> after end of exercise window
 *
 * Let's take an example: there is such an European call option series where buyers
 * may buy 1 WETH for 300 USDC until Dec 31, 2021.
 *
 * In this case:
 *
 * - Expiration date: Dec 31, 2021
 * - Underlying asset: WETH
 * - Strike asset: USDC
 * - Strike price: 300 USDC
 *
 * ETH holders may call mint() until the expiration date, which in turn:
 *
 * - Will lock their WETH into this contract
 * - Will issue option tokens corresponding to this WETH amount
 * - This contract is agnostic about where options could be bought or sold and how much the
 * the option premium should be.
 *
 * WETH holders who also hold the option tokens may call unmint() until the
 * expiration date, which in turn:
 *
 * - Will unlock their WETH from this contract
 * - Will burn the corresponding amount of options tokens
 *
 * Option token holders may call exercise() after the expiration date and
 * end of before exercise window, to exercise their option, which in turn:
 *
 * - Will buy 1 ETH for 300 USDC (the strike price) each.
 * - Will burn the corresponding amount of option tokens.
 *
 * WETH holders that minted options initially can call withdraw() after the
 * end of exercise window, which in turn:
 *
 * - Will give back its amount of collateral locked. That could be o mix of
 * underlying asset and strike asset based if and how the pool was exercised.
 *
 * IMPORTANT: Note that after expiration, option tokens are worthless since they can not
 * be exercised and it price should worth 0 in a healthy market.
 *
 */
contract PodCall is PodOption {
    constructor(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    )
        public
        PodOption(
            name,
            symbol,
            IPodOption.OptionType.CALL,
            exerciseType,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        )
    {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Locks underlying asset and write option tokens.
     *
     * @dev The issued amount ratio is 1:1, i.e., 1 option token for 1 underlying token.
     *
     * It presumes the caller has already called IERC20.approve() on the
     * underlying token contract to move caller funds.
     *
     * This function is meant to be called by underlying token holders wanting
     * to write option tokens. Calling it will lock `amountOfOptions` units of
     * `underlyingToken` into this contract
     *
     * Options can only be minted while the series is NOT expired.
     *
     * It is also important to notice that options will be sent back
     * to `msg.sender` and not the `owner`. This behavior is designed to allow
     * proxy contracts to mint on others behalf. The `owner` will be able to remove
     * the deposited collateral after series expiration or by calling unmint(), even
     * if a third-party minted options on its behalf.
     *
     * @param amountOfOptions The amount option tokens to be issued
     * @param owner Which address will be the owner of the options
     */
    function mint(uint256 amountOfOptions, address owner) external override tradeWindow {
        require(amountOfOptions > 0, "PodCall: you can not mint zero options");
        _mintOptions(amountOfOptions, amountOfOptions, owner);

        IERC20(underlyingAsset()).safeTransferFrom(msg.sender, address(this), amountOfOptions);

        emit Mint(owner, amountOfOptions);
    }

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external virtual override unmintWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _unmintOptions(amountOfOptions, msg.sender);

        // Sends underlying asset
        IERC20(underlyingAsset()).safeTransfer(msg.sender, underlyingToSend);

        emit Unmint(msg.sender, amountOfOptions, strikeToSend, underlyingToSend);
    }

    /**
     * @notice Allow Call token holders to use them to buy some amount of units
     * of underlying token for the amountOfOptions * strike price units of the
     * strike token.
     *
     * @dev It presumes the caller has already called IERC20.approve() on the
     * strike token contract to move caller funds.
     *
     * During the process:
     *
     * - The amountOfOptions units of underlying tokens are transferred to the caller
     * - The amountOfOptions option tokens are burned.
     * - The amountOfOptions * strikePrice units of strike tokens are transferred into
     * this contract as a payment for the underlying tokens.
     *
     * On American options, this function can only called anytime before expiration.
     * For European options, this function can only be called during the exerciseWindow.
     * Meaning, after expiration and before the end of exercise window.
     *
     * @param amountOfOptions The amount option tokens to be exercised
     */
    function exercise(uint256 amountOfOptions) external virtual override exerciseWindow {
        require(amountOfOptions > 0, "PodCall: you can not exercise zero options");
        // Calculate the strike amount equivalent to pay for the underlying requested
        uint256 amountStrikeToReceive = _strikeToTransfer(amountOfOptions);

        // Burn the exercised options
        _burn(msg.sender, amountOfOptions);

        // Retrieve the strike asset from caller
        IERC20(strikeAsset()).safeTransferFrom(msg.sender, address(this), amountStrikeToReceive);

        // Releases the underlying asset to caller, completing the exchange
        IERC20(underlyingAsset()).safeTransfer(msg.sender, amountOfOptions);

        emit Exercise(msg.sender, amountOfOptions);
    }

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their underlying asset tokens to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and underlying asset tokens.
     */
    function withdraw() external virtual override withdrawWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _withdraw();

        IERC20(underlyingAsset()).safeTransfer(msg.sender, underlyingToSend);

        if (strikeToSend > 0) {
            IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);
        }

        emit Withdraw(msg.sender, strikeToSend, underlyingToSend);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../interfaces/IWETH.sol";

contract WMATIC is IWETH, ERC20 {
    constructor() public ERC20("Wrapped Matic", "WMATIC") {}

    function deposit() public payable override {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public override {
        _burn(msg.sender, amount);
        Address.sendValue(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../interfaces/IWETH.sol";

contract WETH is IWETH, ERC20 {
    constructor() public ERC20("Wrapped Ether", "WETH") {}

    function deposit() public payable override {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public override {
        _burn(msg.sender, amount);
        Address.sendValue(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../interfaces/IOptionAMMPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AttackerOptionPool {
    function addLiquidityAndBuy(
        address poolAddress,
        uint256 amountToAddA,
        uint256 amountToAddB,
        uint256 amountToBuyA,
        uint256 sigmaInitialGuess,
        address owner
    ) public {
        IOptionAMMPool pool = IOptionAMMPool(poolAddress);
        address tokenAAddress = pool.tokenA();
        address tokenBAddress = pool.tokenB();

        IERC20 tokenA = IERC20(tokenAAddress);
        IERC20 tokenB = IERC20(tokenBAddress);

        tokenA.transferFrom(msg.sender, address(this), amountToAddA);
        tokenA.approve(poolAddress, 2**255);

        tokenB.transferFrom(msg.sender, address(this), amountToAddB);
        tokenB.approve(poolAddress, 2**255);

        pool.addLiquidity(amountToAddA, amountToAddB, address(this));
        pool.tradeExactAOutput(amountToBuyA, 2**255, owner, sigmaInitialGuess);
    }

    function addLiquidityAndRemove(
        address poolAddress,
        uint256 amountA,
        uint256 amountB,
        address owner
    ) public {
        IOptionAMMPool pool = IOptionAMMPool(poolAddress);
        address tokenAAddress = pool.tokenA();
        address tokenBAddress = pool.tokenB();

        IERC20 tokenA = IERC20(tokenAAddress);
        IERC20 tokenB = IERC20(tokenBAddress);

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenA.approve(poolAddress, 2**255);

        tokenB.transferFrom(msg.sender, address(this), amountB);
        tokenB.approve(poolAddress, 2**255);

        pool.addLiquidity(amountA, amountB, address(this));
        pool.removeLiquidity(amountA, amountB);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.12;

import "./IAMM.sol";

interface IOptionAMMPool is IAMM {
    // @dev 0 for when tokenA enter the pool and B leaving (A -> B)
    // and 1 for the opposite direction
    enum TradeDirection { AB, BA }

    function tradeExactAInput(
        uint256 exactAmountAIn,
        uint256 minAmountBOut,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function tradeExactAOutput(
        uint256 exactAmountAOut,
        uint256 maxAmountBIn,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function tradeExactBInput(
        uint256 exactAmountBIn,
        uint256 minAmountAOut,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function tradeExactBOutput(
        uint256 exactAmountBOut,
        uint256 maxAmountAIn,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function getOptionTradeDetailsExactAInput(uint256 exactAmountAIn)
        external
        view
        returns (
            uint256 amountBOutput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getOptionTradeDetailsExactAOutput(uint256 exactAmountAOut)
        external
        view
        returns (
            uint256 amountBInput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getOptionTradeDetailsExactBInput(uint256 exactAmountBIn)
        external
        view
        returns (
            uint256 amountAOutput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getOptionTradeDetailsExactBOutput(uint256 exactAmountBOut)
        external
        view
        returns (
            uint256 amountAInput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getRemoveLiquidityAmounts(
        uint256 percentA,
        uint256 percentB,
        address user
    ) external view returns (uint256 withdrawAmountA, uint256 withdrawAmountB);

    function getABPrice() external view returns (uint256);

    function getAdjustedIV() external view returns (uint256);

    function withdrawRewards() external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IConfigurationManager.sol";
import "../interfaces/IPodOption.sol";
import "../interfaces/IOptionAMMPool.sol";
import "../interfaces/IOptionPoolRegistry.sol";
import "../interfaces/IOptionHelper.sol";

/**
 * @title PodOption
 * @author Pods Finance
 * @notice Represents a Proxy that can perform a set of operations on the behalf of an user
 */
contract OptionHelper is IOptionHelper, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
     * @dev store globally accessed configurations
     */
    IConfigurationManager public immutable configurationManager;

    event OptionsBought(
        address indexed buyer,
        address indexed optionAddress,
        uint256 optionsBought,
        address inputToken,
        uint256 inputSold
    );

    event OptionsSold(
        address indexed seller,
        address indexed optionAddress,
        uint256 optionsSold,
        address outputToken,
        uint256 outputReceived
    );

    event OptionsMintedAndSold(
        address indexed seller,
        address indexed optionAddress,
        uint256 optionsMintedAndSold,
        address outputToken,
        uint256 outputBought
    );

    event LiquidityAdded(
        address indexed staker,
        address indexed optionAddress,
        uint256 amountOptions,
        address token,
        uint256 tokenAmount
    );

    constructor(IConfigurationManager _configurationManager) public {
        require(
            Address.isContract(address(_configurationManager)),
            "OptionHelper: Configuration Manager is not a contract"
        );
        configurationManager = _configurationManager;
    }

    modifier withinDeadline(uint256 deadline) {
        require(deadline > block.timestamp, "OptionHelper: deadline expired");
        _;
    }

    /**
     * @notice Mint options
     * @dev Mints an amount of options and return to caller
     *
     * @param option The option contract to mint
     * @param optionAmount Amount of options to mint
     */
    function mint(IPodOption option, uint256 optionAmount) external override {
        _mint(option, optionAmount);

        // Transfers back the minted options
        IERC20(address(option)).safeTransfer(msg.sender, optionAmount);
    }

    /**
     * @notice Mint and sell options
     * @dev Mints an amount of options and sell it in pool
     *
     * @param option The option contract to mint
     * @param optionAmount Amount of options to mint
     * @param minTokenAmount Minimum amount of output tokens accepted
     * @param deadline The deadline in unix-timestamp that limits the transaction from happening
     * @param initialIVGuess The initial implied volatility guess
     */
    function mintAndSellOptions(
        IPodOption option,
        uint256 optionAmount,
        uint256 minTokenAmount,
        uint256 deadline,
        uint256 initialIVGuess
    ) external override nonReentrant withinDeadline(deadline) {
        IOptionAMMPool pool = _getPool(option);

        _mint(option, optionAmount);

        // Approve pool transfer
        IERC20(address(option)).safeApprove(address(pool), optionAmount);

        // Sells options to pool
        uint256 tokensBought = pool.tradeExactAInput(optionAmount, minTokenAmount, msg.sender, initialIVGuess);

        emit OptionsMintedAndSold(msg.sender, address(option), optionAmount, pool.tokenB(), tokensBought);
    }

    /**
     * @notice Mint and add liquidity
     * @dev Mint options and provide them as liquidity to the pool
     *
     * @param option The option contract to mint
     * @param optionAmount Amount of options to mint
     * @param tokenAmount Amount of tokens to provide as liquidity
     */
    function mintAndAddLiquidity(
        IPodOption option,
        uint256 optionAmount,
        uint256 tokenAmount
    ) external override nonReentrant {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenB = IERC20(pool.tokenB());

        _mint(option, optionAmount);

        if (tokenAmount > 0) {
            // Take stable token from caller
            tokenB.safeTransferFrom(msg.sender, address(this), tokenAmount);
        }

        // Approve pool transfer
        IERC20(address(option)).safeApprove(address(pool), optionAmount);
        tokenB.safeApprove(address(pool), tokenAmount);

        // Adds options and tokens to pool as liquidity
        pool.addLiquidity(optionAmount, tokenAmount, msg.sender);

        emit LiquidityAdded(msg.sender, address(option), optionAmount, pool.tokenB(), tokenAmount);
    }

    /**
     * @notice Mint and add liquidity using only collateralAmount as input
     * @dev Mint options and provide them as liquidity to the pool
     *
     * @param option The option contract to mint
     * @param collateralAmount Amount of collateral tokens to be used to both mint and mint into the stable side
     */
    function mintAndAddLiquidityWithCollateral(IPodOption option, uint256 collateralAmount)
        external
        override
        nonReentrant
    {
        require(option.optionType() == IPodOption.OptionType.PUT, "OptionHelper: Invalid option type");
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenB = IERC20(pool.tokenB());

        (uint256 optionAmount, uint256 tokenBToAdd) = _calculateEvenAmounts(option, collateralAmount);

        _mint(option, optionAmount);

        tokenB.safeTransferFrom(msg.sender, address(this), tokenBToAdd);

        // Approve pool transfer
        IERC20(address(option)).safeApprove(address(pool), optionAmount);
        tokenB.safeApprove(address(pool), tokenBToAdd);

        // Adds options and tokens to pool as liquidity
        pool.addLiquidity(optionAmount, tokenBToAdd, msg.sender);

        emit LiquidityAdded(msg.sender, address(option), optionAmount, pool.tokenB(), tokenBToAdd);
    }

    /**
     * @notice Add liquidity
     * @dev Provide options as liquidity to the pool
     *
     * @param option The option contract to mint
     * @param optionAmount Amount of options to provide
     * @param tokenAmount Amount of tokens to provide as liquidity
     */
    function addLiquidity(
        IPodOption option,
        uint256 optionAmount,
        uint256 tokenAmount
    ) external override nonReentrant {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenB = IERC20(pool.tokenB());

        if (optionAmount > 0) {
            // Take options from caller
            IERC20(address(option)).safeTransferFrom(msg.sender, address(this), optionAmount);
        }

        if (tokenAmount > 0) {
            // Take stable token from caller
            tokenB.safeTransferFrom(msg.sender, address(this), tokenAmount);
        }

        // Approve pool transfer
        IERC20(address(option)).safeApprove(address(pool), optionAmount);
        tokenB.safeApprove(address(pool), tokenAmount);

        // Adds options and tokens to pool as liquidity
        pool.addLiquidity(optionAmount, tokenAmount, msg.sender);

        emit LiquidityAdded(msg.sender, address(option), optionAmount, pool.tokenB(), tokenAmount);
    }

    /**
     * @notice Sell exact amount of options
     * @dev Sell an amount of options from pool
     *
     * @param option The option contract to sell
     * @param optionAmount Amount of options to sell
     * @param minTokenReceived Min amount of input tokens to receive
     * @param deadline The deadline in unix-timestamp that limits the transaction from happening
     * @param initialIVGuess The initial implied volatility guess
     */
    function sellExactOptions(
        IPodOption option,
        uint256 optionAmount,
        uint256 minTokenReceived,
        uint256 deadline,
        uint256 initialIVGuess
    ) external override withinDeadline(deadline) nonReentrant {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenA = IERC20(pool.tokenA());

        // Take input amount from caller
        tokenA.safeTransferFrom(msg.sender, address(this), optionAmount);

        // Approve pool transfer
        tokenA.safeApprove(address(pool), optionAmount);

        // Buys options from pool
        uint256 tokenAmountReceived = pool.tradeExactAInput(optionAmount, minTokenReceived, msg.sender, initialIVGuess);

        emit OptionsSold(msg.sender, address(option), optionAmount, pool.tokenB(), tokenAmountReceived);
    }

    /**
     * @notice Sell estimated amount of options
     * @dev Sell an estimated amount of options to the pool
     *
     * @param option The option contract to sell
     * @param maxOptionAmount max Amount of options to sell
     * @param exactTokenReceived exact amount of input tokens to receive
     * @param deadline The deadline in unix-timestamp that limits the transaction from happening
     * @param initialIVGuess The initial implied volatility guess
     */
    function sellOptionsAndReceiveExactTokens(
        IPodOption option,
        uint256 maxOptionAmount,
        uint256 exactTokenReceived,
        uint256 deadline,
        uint256 initialIVGuess
    ) external override withinDeadline(deadline) nonReentrant {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenA = IERC20(pool.tokenA());

        // Take input amount from caller
        tokenA.safeTransferFrom(msg.sender, address(this), maxOptionAmount);

        // Approve pool transfer
        tokenA.safeApprove(address(pool), maxOptionAmount);

        // Buys options from pool
        uint256 optionsSold = pool.tradeExactBOutput(exactTokenReceived, maxOptionAmount, msg.sender, initialIVGuess);

        uint256 unusedFunds = maxOptionAmount.sub(optionsSold);

        // Reset allowance
        tokenA.safeApprove(address(pool), 0);

        // Transfer back unused funds
        if (unusedFunds > 0) {
            tokenA.safeTransfer(msg.sender, unusedFunds);
        }

        emit OptionsSold(msg.sender, address(option), optionsSold, pool.tokenB(), exactTokenReceived);
    }

    /**
     * @notice Buy exact amount of options
     * @dev Buys an amount of options from pool
     *
     * @param option The option contract to buy
     * @param optionAmount Amount of options to buy
     * @param maxTokenAmount Max amount of input tokens sold
     * @param deadline The deadline in unix-timestamp that limits the transaction from happening
     * @param initialIVGuess The initial implied volatility guess
     */
    function buyExactOptions(
        IPodOption option,
        uint256 optionAmount,
        uint256 maxTokenAmount,
        uint256 deadline,
        uint256 initialIVGuess
    ) external override withinDeadline(deadline) nonReentrant {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenB = IERC20(pool.tokenB());

        // Take input amount from caller
        tokenB.safeTransferFrom(msg.sender, address(this), maxTokenAmount);

        // Approve pool transfer
        tokenB.safeApprove(address(pool), maxTokenAmount);

        // Buys options from pool
        uint256 tokensSold = pool.tradeExactAOutput(optionAmount, maxTokenAmount, msg.sender, initialIVGuess);
        uint256 unusedFunds = maxTokenAmount.sub(tokensSold);

        // Reset allowance
        tokenB.safeApprove(address(pool), 0);

        // Transfer back unused funds
        if (unusedFunds > 0) {
            tokenB.safeTransfer(msg.sender, unusedFunds);
        }

        emit OptionsBought(msg.sender, address(option), optionAmount, pool.tokenB(), tokensSold);
    }

    /**
     * @notice Buy estimated amount of options
     * @dev Buys an estimated amount of options from pool
     *
     * @param option The option contract to buy
     * @param minOptionAmount Min amount of options bought
     * @param tokenAmount The exact amount of input tokens sold
     * @param deadline The deadline in unix-timestamp that limits the transaction from happening
     * @param initialIVGuess The initial implied volatility guess
     */
    function buyOptionsWithExactTokens(
        IPodOption option,
        uint256 minOptionAmount,
        uint256 tokenAmount,
        uint256 deadline,
        uint256 initialIVGuess
    ) external override withinDeadline(deadline) nonReentrant {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenB = IERC20(pool.tokenB());

        // Take input amount from caller
        tokenB.safeTransferFrom(msg.sender, address(this), tokenAmount);

        // Approve pool transfer
        tokenB.safeApprove(address(pool), tokenAmount);

        // Buys options from pool
        uint256 optionsBought = pool.tradeExactBInput(tokenAmount, minOptionAmount, msg.sender, initialIVGuess);

        emit OptionsBought(msg.sender, address(option), optionsBought, pool.tokenB(), tokenAmount);
    }

    /**
     * @dev Mints an amount of tokens collecting the strike tokens from the caller
     *
     * @param option The option contract to mint
     * @param amount The amount of options to mint
     */
    function _mint(IPodOption option, uint256 amount) internal {
        require(Address.isContract(address(option)), "OptionHelper: Option is not a contract");

        if (option.optionType() == IPodOption.OptionType.PUT) {
            IERC20 strikeAsset = IERC20(option.strikeAsset());
            uint256 strikeToTransfer = option.strikeToTransfer(amount);

            // Take strike asset from caller
            strikeAsset.safeTransferFrom(msg.sender, address(this), strikeToTransfer);

            // Approving strike asset transfer to Option
            strikeAsset.safeApprove(address(option), strikeToTransfer);

            option.mint(amount, msg.sender);
        } else if (option.optionType() == IPodOption.OptionType.CALL) {
            IERC20 underlyingAsset = IERC20(option.underlyingAsset());

            // Take underlying asset from caller
            underlyingAsset.safeTransferFrom(msg.sender, address(this), amount);

            // Approving underlying asset to Option
            underlyingAsset.safeApprove(address(option), amount);

            option.mint(amount, msg.sender);
        }
    }

    /**
     * @dev Returns the AMM Pool associated with the option
     *
     * @param option The option to search for
     * @return IOptionAMMPool
     */
    function _getPool(IPodOption option) internal view returns (IOptionAMMPool) {
        IOptionPoolRegistry registry = IOptionPoolRegistry(configurationManager.getOptionPoolRegistry());
        address exchangeOptionAddress = registry.getPool(address(option));
        require(exchangeOptionAddress != address(0), "OptionHelper: pool not found");
        return IOptionAMMPool(exchangeOptionAddress);
    }

    /**
     * @dev Returns the AMM Pool associated with the option
     *
     * @param option The option to search for
     * @param collateralAmount Total collateral amount that will be used to mint and add liquidity
     * @return amountOfOptions amount of options to mint
     * @return amountOfTokenB  amount of stable to add liquidity
     */
    function _calculateEvenAmounts(IPodOption option, uint256 collateralAmount)
        internal
        view
        returns (uint256 amountOfOptions, uint256 amountOfTokenB)
    {
        // 1) Get BS Unit Price
        IOptionAMMPool pool = _getPool(option);

        uint256 ABPrice = pool.getABPrice();
        uint256 strikePrice = option.strikePrice();
        uint256 optionDecimals = option.underlyingAssetDecimals();

        amountOfOptions = collateralAmount.mul(10**optionDecimals).div(strikePrice.add(ABPrice));
        amountOfTokenB = amountOfOptions.mul(ABPrice).div(10**optionDecimals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IOptionPoolRegistry {
    event PoolSet(address indexed factory, address indexed option, address pool);

    function getPool(address option) external view returns (address);

    function setPool(address option, address pool) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

import "./IPodOption.sol";

interface IOptionHelper {
    function mint(IPodOption option, uint256 optionAmount) external;

    function mintAndSellOptions(
        IPodOption option,
        uint256 optionAmount,
        uint256 minTokenAmount,
        uint256 deadline,
        uint256 initialIVGuess
    ) external;

    function mintAndAddLiquidity(
        IPodOption option,
        uint256 optionAmount,
        uint256 tokenAmount
    ) external;

    function mintAndAddLiquidityWithCollateral(IPodOption option, uint256 collateralAmount) external;

    function addLiquidity(
        IPodOption option,
        uint256 optionAmount,
        uint256 tokenAmount
    ) external;

    function sellExactOptions(
        IPodOption option,
        uint256 optionAmount,
        uint256 minTokenReceived,
        uint256 deadline,
        uint256 initialIVGuess
    ) external;

    function sellOptionsAndReceiveExactTokens(
        IPodOption option,
        uint256 maxOptionAmount,
        uint256 exactTokenReceived,
        uint256 deadline,
        uint256 initialIVGuess
    ) external;

    function buyExactOptions(
        IPodOption option,
        uint256 optionAmount,
        uint256 maxTokenAmount,
        uint256 deadline,
        uint256 initialIVGuess
    ) external;

    function buyOptionsWithExactTokens(
        IPodOption option,
        uint256 minOptionAmount,
        uint256 tokenAmount,
        uint256 deadline,
        uint256 initialIVGuess
    ) external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IPriceProvider.sol";
import "../interfaces/IConfigurationManager.sol";

/**
 * @title PriceProvider
 * @author Pods Finance
 * @notice Storage of prices feeds by asset
 */
contract PriceProvider is IPriceProvider, Ownable {
    /**
     * @dev store globally accessed configurations
     */
    IConfigurationManager public immutable configurationManager;

    /**
     * @dev Minimum price interval to accept a price feed
     */
    uint256 public minUpdateInterval;

    /**
     * @dev Stores PriceFeed by asset address
     */
    mapping(address => IPriceFeed) private _assetPriceFeeds;

    event AssetFeedUpdated(address indexed asset, address indexed feed);
    event AssetFeedRemoved(address indexed asset, address indexed feed);

    constructor(
        IConfigurationManager _configurationManager,
        address[] memory _assets,
        address[] memory _feeds
    ) public {
        configurationManager = _configurationManager;

        minUpdateInterval = _configurationManager.getParameter("MIN_UPDATE_INTERVAL");

        require(minUpdateInterval < block.timestamp, "PriceProvider: Invalid minUpdateInterval");

        _setAssetFeeds(_assets, _feeds);
    }

    /**
     * @notice Register price feeds
     * @param _assets Array of assets
     * @param _feeds Array of price feeds
     */
    function setAssetFeeds(address[] memory _assets, address[] memory _feeds) external override onlyOwner {
        _setAssetFeeds(_assets, _feeds);
    }

    /**
     * @notice Updates previously registered price feeds
     * @param _assets Array of assets
     * @param _feeds Array of price feeds
     */
    function updateAssetFeeds(address[] memory _assets, address[] memory _feeds) external override onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            require(address(_assetPriceFeeds[_assets[i]]) != address(0), "PriceProvider: PriceFeed not set");
        }
        _setAssetFeeds(_assets, _feeds);
    }

    /**
     * @notice Unregister price feeds
     * @dev Will not remove unregistered assets
     * @param _assets Array of assets
     */
    function removeAssetFeeds(address[] memory _assets) external override onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            address removedFeed = address(_assetPriceFeeds[_assets[i]]);

            if (removedFeed != address(0)) {
                delete _assetPriceFeeds[_assets[i]];
                emit AssetFeedRemoved(_assets[i], removedFeed);
            }
        }
    }

    /**
     * @notice Update minUpdateInterval fetching from configurationManager
     */
    function updateMinUpdateInterval() external override {
        minUpdateInterval = configurationManager.getParameter("MIN_UPDATE_INTERVAL");
        require(minUpdateInterval < block.timestamp, "PriceProvider: Invalid minUpdateInterval");
    }

    /**
     * @notice Gets the current price of an asset
     * @param _asset Address of an asset
     * @return Current price
     */
    function getAssetPrice(address _asset) external override view returns (uint256) {
        IPriceFeed feed = _assetPriceFeeds[_asset];
        require(address(feed) != address(0), "PriceProvider: Feed not registered");
        (int256 price, uint256 updatedAt) = feed.getLatestPrice();
        require(!_isObsolete(updatedAt), "PriceProvider: stale PriceFeed");
        require(price > 0, "PriceProvider: Negative price");

        return uint256(price);
    }

    /**
     * @notice Get the data from the latest round.
     * @param _asset Address of an asset
     * @return roundId is the round ID from the aggregator for which the data was
     * retrieved combined with an phase to ensure that round IDs get larger as
     * time moves forward.
     * @return answer is the answer for the given round
     * @return startedAt is the timestamp when the round was started.
     * (Only some AggregatorV3Interface implementations return meaningful values)
     * @return updatedAt is the timestamp when the round last was updated (i.e.
     * answer was last computed)
     * @return answeredInRound is the round ID of the round in which the answer
     * was computed.
     */
    function latestRoundData(address _asset)
        external
        override
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        IPriceFeed feed = _assetPriceFeeds[_asset];
        require(address(feed) != address(0), "PriceProvider: Feed not registered");

        return feed.latestRoundData();
    }

    /**
     * @notice Gets the number of decimals of a PriceFeed
     * @param _asset Address of an asset
     * @return Asset price decimals
     */
    function getAssetDecimals(address _asset) external override view returns (uint8) {
        IPriceFeed feed = _assetPriceFeeds[_asset];
        require(address(feed) != address(0), "PriceProvider: Feed not registered");

        return feed.decimals();
    }

    /**
     * @notice Get the address of a registered price feed
     * @param _asset Address of an asset
     * @return Price feed address
     */
    function getPriceFeed(address _asset) external override view returns (address) {
        return address(_assetPriceFeeds[_asset]);
    }

    /**
     * @dev Internal function to set price feeds for different assets
     * @param _assets Array of assets
     * @param _feeds Array of price feeds
     */
    function _setAssetFeeds(address[] memory _assets, address[] memory _feeds) internal {
        require(_assets.length == _feeds.length, "PriceProvider: inconsistent params length");
        for (uint256 i = 0; i < _assets.length; i++) {
            IPriceFeed feed = IPriceFeed(_feeds[i]);
            require(address(feed) != address(0), "PriceProvider: invalid PriceFeed");

            (, , uint256 startedAt, uint256 updatedAt, ) = feed.latestRoundData();

            require(startedAt > 0, "PriceProvider: PriceFeed not started");
            require(!_isObsolete(updatedAt), "PriceProvider: stale PriceFeed");

            _assetPriceFeeds[_assets[i]] = feed;
            emit AssetFeedUpdated(_assets[i], _feeds[i]);
        }
    }

    /**
     * @dev Internal function to check if a given timestamp is obsolete
     * @param _timestamp The timestamp to check
     */
    function _isObsolete(uint256 _timestamp) internal view returns (bool) {
        return _timestamp < (block.timestamp - minUpdateInterval);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IPriceFeed {
    function getLatestPrice() external view returns (int256, uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IPriceProvider {
    function setAssetFeeds(address[] memory _assets, address[] memory _feeds) external;

    function updateAssetFeeds(address[] memory _assets, address[] memory _feeds) external;

    function removeAssetFeeds(address[] memory _assets) external;

    function getAssetPrice(address _asset) external view returns (uint256);

    function getAssetDecimals(address _asset) external view returns (uint8);

    function latestRoundData(address _asset)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function getPriceFeed(address _asset) external view returns (address);

    function updateMinUpdateInterval() external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./AMM.sol";
import "../lib/CappedPool.sol";
import "../lib/CombinedActionsGuard.sol";
import "../interfaces/IPriceProvider.sol";
import "../interfaces/IIVProvider.sol";
import "../interfaces/IBlackScholes.sol";
import "../interfaces/IIVGuesser.sol";
import "../interfaces/IPodOption.sol";
import "../interfaces/IOptionAMMPool.sol";
import "../interfaces/IFeePool.sol";
import "../interfaces/IConfigurationManager.sol";
import "../interfaces/IEmergencyStop.sol";
import "../interfaces/IFeePoolBuilder.sol";
import "../options/rewards/AaveIncentives.sol";

/**
 * Represents an Option specific single-sided AMM.
 *
 * The tokenA MUST be an PodOption contract implementation.
 * The tokenB is preferable to be an stable asset such as DAI or USDC.
 *
 * There are 4 external contracts used by this contract:
 *
 * - priceProvider: responsible for the the spot price of the option's underlying asset.
 * - priceMethod: responsible for the current price of the option itself.
 * - impliedVolatility: responsible for one of the priceMethod inputs:
 *     implied Volatility
 * - feePoolA and feePoolB: responsible for handling Liquidity providers fees.
 */

contract OptionAMMPool is AMM, IOptionAMMPool, CappedPool, CombinedActionsGuard, ReentrancyGuard, AaveIncentives {
    using SafeMath for uint256;
    uint256 public constant PRICING_DECIMALS = 18;
    uint256 private constant _SECONDS_IN_A_YEAR = 31536000;
    uint256 private constant _ORACLE_IV_WEIGHT = 3;
    uint256 private constant _POOL_IV_WEIGHT = 1;

    // External Contracts
    /**
     * @notice store globally accessed configurations
     */
    IConfigurationManager public immutable configurationManager;

    /**
     * @notice responsible for handling Liquidity providers fees of the token A
     */
    IFeePool public immutable feePoolA;

    /**
     * @notice responsible for handling Liquidity providers fees of the token B
     */
    IFeePool public immutable feePoolB;

    // Option Info
    struct PriceProperties {
        uint256 expiration;
        uint256 startOfExerciseWindow;
        uint256 strikePrice;
        address underlyingAsset;
        IPodOption.OptionType optionType;
        uint256 currentIV;
        int256 riskFree;
        uint256 initialIVGuess;
    }

    /**
     * @notice priceProperties are all information needed to handle the price discovery method
     * most of the properties will be used by getABPrice
     */
    PriceProperties public priceProperties;

    event TradeInfo(uint256 spotPrice, uint256 newIV);

    constructor(
        address _optionAddress,
        address _stableAsset,
        uint256 _initialIV,
        IConfigurationManager _configurationManager,
        IFeePoolBuilder _feePoolBuilder
    ) public AMM(_optionAddress, _stableAsset) CappedPool(_configurationManager) AaveIncentives(_configurationManager) {
        require(
            IPodOption(_optionAddress).exerciseType() == IPodOption.ExerciseType.EUROPEAN,
            "Pool: invalid exercise type"
        );

        feePoolA = _feePoolBuilder.buildFeePool(_stableAsset, 10, 3, address(this));
        feePoolB = _feePoolBuilder.buildFeePool(_stableAsset, 10, 3, address(this));

        priceProperties.currentIV = _initialIV;
        priceProperties.initialIVGuess = _initialIV;
        priceProperties.underlyingAsset = IPodOption(_optionAddress).underlyingAsset();
        priceProperties.expiration = IPodOption(_optionAddress).expiration();
        priceProperties.startOfExerciseWindow = IPodOption(_optionAddress).startOfExerciseWindow();
        priceProperties.optionType = IPodOption(_optionAddress).optionType();

        uint256 strikePrice = IPodOption(_optionAddress).strikePrice();
        uint256 strikePriceDecimals = IPodOption(_optionAddress).strikePriceDecimals();

        require(strikePriceDecimals <= PRICING_DECIMALS, "Pool: invalid strikePrice unit");
        require(tokenBDecimals() <= PRICING_DECIMALS, "Pool: invalid tokenB unit");
        uint256 strikePriceWithRightDecimals = strikePrice.mul(10**(PRICING_DECIMALS - strikePriceDecimals));

        priceProperties.strikePrice = strikePriceWithRightDecimals;
        configurationManager = IConfigurationManager(_configurationManager);
    }

    /**
     * @notice addLiquidity in any proportion of tokenA or tokenB
     *
     * @dev This function can only be called before option expiration
     *
     * @param amountOfA amount of TokenA to add
     * @param amountOfB amount of TokenB to add
     * @param owner address of the account that will have ownership of the liquidity
     */
    function addLiquidity(
        uint256 amountOfA,
        uint256 amountOfB,
        address owner
    ) external override capped(tokenB(), amountOfB) {
        require(msg.sender == configurationManager.getOptionHelper() || msg.sender == owner, "AMM: invalid sender");
        _nonCombinedActions();
        _beforeStartOfExerciseWindow();
        _emergencyStopCheck();
        _addLiquidity(amountOfA, amountOfB, owner);
        _emitTradeInfo();
    }

    /**
     * @notice removeLiquidity in any proportion of tokenA or tokenB
     *
     * @param amountOfA amount of TokenA to add
     * @param amountOfB amount of TokenB to add
     */
    function removeLiquidity(uint256 amountOfA, uint256 amountOfB) external override nonReentrant {
        _nonCombinedActions();
        _emergencyStopCheck();
        _removeLiquidity(amountOfA, amountOfB);
        _emitTradeInfo();
    }

    /**
     * @notice withdrawRewards claims reward from Aave and send to admin
     * @dev should only be called by the admin power
     *
     */
    function withdrawRewards() external override {
        require(msg.sender == configurationManager.owner(), "not owner");
        address[] memory assets = new address[](1);
        assets[0] = this.tokenB();

        _claimRewards(assets);

        address rewardAsset = _parseAddressFromUint(configurationManager.getParameter("REWARD_ASSET"));
        uint256 rewardsToSend = _rewardBalance();

        IERC20(rewardAsset).safeTransfer(msg.sender, rewardsToSend);
    }

    /**
     * @notice tradeExactAInput msg.sender is able to trade exact amount of token A in exchange for minimum
     * amount of token B and send the tokens B to the owner. After that, this function also updates the
     * priceProperties.* currentIV
     *
     * @dev initialIVGuess is a parameter for gas saving costs purpose. Instead of calculating the new implied volatility
     * out of thin ar, caller can help the Numeric Method achieve the result in less iterations with this parameter.
     * In order to know which guess the caller should use, call the getOptionTradeDetailsExactAInput first.
     *
     * @param exactAmountAIn exact amount of A token that will be transfer from msg.sender
     * @param minAmountBOut minimum acceptable amount of token B to transfer to owner
     * @param owner the destination address that will receive the token B
     * @param initialIVGuess The first guess that the Numeric Method (getPutIV / getCallIV) should use
     */
    function tradeExactAInput(
        uint256 exactAmountAIn,
        uint256 minAmountBOut,
        address owner,
        uint256 initialIVGuess
    ) external override nonReentrant returns (uint256) {
        _nonCombinedActions();
        _beforeStartOfExerciseWindow();
        _emergencyStopCheck();
        priceProperties.initialIVGuess = initialIVGuess;

        uint256 amountBOut = _tradeExactAInput(exactAmountAIn, minAmountBOut, owner);

        _emitTradeInfo();
        return amountBOut;
    }

    /**
     * @notice _tradeExactAOutput owner is able to receive exact amount of token A in exchange of a max
     * acceptable amount of token B transfer from the msg.sender. After that, this function also updates
     * the priceProperties.currentIV
     *
     * @dev initialIVGuess is a parameter for gas saving costs purpose. Instead of calculating the new implied volatility
     * out of thin ar, caller can help the Numeric Method achieve the result in less iterations with this parameter.
     * In order to know which guess the caller should use, call the getOptionTradeDetailsExactAOutput first.
     *
     * @param exactAmountAOut exact amount of token A that will be transfer to owner
     * @param maxAmountBIn maximum acceptable amount of token B to transfer from msg.sender
     * @param owner the destination address that will receive the token A
     * @param initialIVGuess The first guess that the Numeric Method (getPutIV / getCallIV) should use
     */
    function tradeExactAOutput(
        uint256 exactAmountAOut,
        uint256 maxAmountBIn,
        address owner,
        uint256 initialIVGuess
    ) external override nonReentrant returns (uint256) {
        _nonCombinedActions();
        _beforeStartOfExerciseWindow();
        _emergencyStopCheck();
        priceProperties.initialIVGuess = initialIVGuess;

        uint256 amountBIn = _tradeExactAOutput(exactAmountAOut, maxAmountBIn, owner);

        _emitTradeInfo();
        return amountBIn;
    }

    /**
     * @notice _tradeExactBInput msg.sender is able to trade exact amount of token B in exchange for minimum
     * amount of token A sent to the owner. After that, this function also updates the priceProperties.currentIV
     *
     * @dev initialIVGuess is a parameter for gas saving costs purpose. Instead of calculating the new implied volatility
     * out of thin ar, caller can help the Numeric Method achieve the result ini less iterations with this parameter.
     * In order to know which guess the caller should use, call the getOptionTradeDetailsExactBInput first.
     *
     * @param exactAmountBIn exact amount of token B that will be transfer from msg.sender
     * @param minAmountAOut minimum acceptable amount of token A to transfer to owner
     * @param owner the destination address that will receive the token A
     * @param initialIVGuess The first guess that the Numeric Method (getPutIV / getCallIV) should use
     */
    function tradeExactBInput(
        uint256 exactAmountBIn,
        uint256 minAmountAOut,
        address owner,
        uint256 initialIVGuess
    ) external override nonReentrant returns (uint256) {
        _nonCombinedActions();
        _beforeStartOfExerciseWindow();
        _emergencyStopCheck();
        priceProperties.initialIVGuess = initialIVGuess;

        uint256 amountAOut = _tradeExactBInput(exactAmountBIn, minAmountAOut, owner);

        _emitTradeInfo();
        return amountAOut;
    }

    /**
     * @notice _tradeExactBOutput owner is able to receive exact amount of token B in exchange of a max
     * acceptable amount of token A transfer from msg.sender. After that, this function also updates the
     * priceProperties.currentIV
     *
     * @dev initialIVGuess is a parameter for gas saving costs purpose. Instead of calculating the new implied volatility
     * out of thin ar, caller can help the Numeric Method achieve the result ini less iterations with this parameter.
     * In order to know which guess the caller should use, call the getOptionTradeDetailsExactBOutput first.
     *
     * @param exactAmountBOut exact amount of token B that will be transfer to owner
     * @param maxAmountAIn maximum acceptable amount of token A to transfer from msg.sender
     * @param owner the destination address that will receive the token B
     * @param initialIVGuess The first guess that the Numeric Method (getPutIV / getCallIV) should use
     */
    function tradeExactBOutput(
        uint256 exactAmountBOut,
        uint256 maxAmountAIn,
        address owner,
        uint256 initialIVGuess
    ) external override nonReentrant returns (uint256) {
        _nonCombinedActions();
        _beforeStartOfExerciseWindow();
        _emergencyStopCheck();
        priceProperties.initialIVGuess = initialIVGuess;

        uint256 amountAIn = _tradeExactBOutput(exactAmountBOut, maxAmountAIn, owner);

        _emitTradeInfo();
        return amountAIn;
    }

    /**
     * @notice getRemoveLiquidityAmounts external function that returns the available for rescue
     * amounts of token A, and token B based on the original position
     *
     * @param percentA percent of exposition of Token A to be removed
     * @param percentB percent of exposition of Token B to be removed
     * @param user Opening Value Factor by the moment of the deposit
     *
     * @return withdrawAmountA the total amount of token A that will be rescued
     * @return withdrawAmountB the total amount of token B that will be rescued plus fees
     */
    function getRemoveLiquidityAmounts(
        uint256 percentA,
        uint256 percentB,
        address user
    ) external override view returns (uint256 withdrawAmountA, uint256 withdrawAmountB) {
        (uint256 poolWithdrawAmountA, uint256 poolWithdrawAmountB) = _getRemoveLiquidityAmounts(
            percentA,
            percentB,
            user
        );
        (uint256 feeSharesA, uint256 feeSharesB) = _getAmountOfFeeShares(percentA, percentB, user);
        uint256 feesWithdrawAmountA = 0;
        uint256 feesWithdrawAmountB = 0;

        if (feeSharesA > 0) {
            (, feesWithdrawAmountA) = feePoolA.getWithdrawAmount(user, feeSharesA);
        }

        if (feeSharesB > 0) {
            (, feesWithdrawAmountB) = feePoolB.getWithdrawAmount(user, feeSharesB);
        }

        withdrawAmountA = poolWithdrawAmountA;
        withdrawAmountB = poolWithdrawAmountB.add(feesWithdrawAmountA).add(feesWithdrawAmountB);
        return (withdrawAmountA, withdrawAmountB);
    }

    /**
     * @notice getABPrice This function wll call internal function _getABPrice that will calculate the
     * calculate the ABPrice based on current market conditions. It calculates only the unit price AB, not taking in
     * consideration the slippage.
     *
     * @return ABPrice ABPrice is the unit price AB. Meaning how many units of B, buys 1 unit of A
     */
    function getABPrice() external override view returns (uint256 ABPrice) {
        return _getABPrice();
    }

    /**
     * @notice getAdjustedIV This function will return the adjustedIV, which is an average
     * between the pool IV and an external oracle IV
     *
     * @return adjustedIV The average between pool's IV and external oracle IV
     */
    function getAdjustedIV() external override view returns (uint256 adjustedIV) {
        return _getAdjustedIV(tokenA(), priceProperties.currentIV);
    }

    /**
     * @notice getOptionTradeDetailsExactAInput view function that simulates a trade, in order the preview
     * the amountBOut, the new implied volatility, that will be used as the initialIVGuess if caller wants to perform
     * a trade in sequence. Also returns the amount of Fees that will be payed to liquidity pools A and B.
     *
     * @param exactAmountAIn amount of token A that will by transfer from msg.sender to the pool
     *
     * @return amountBOut amount of B in exchange of the exactAmountAIn
     * @return newIV the new implied volatility that this trade will result
     * @return feesTokenA amount of fees of collected by token A
     * @return feesTokenB amount of fees of collected by token B
     */
    function getOptionTradeDetailsExactAInput(uint256 exactAmountAIn)
        external
        override
        view
        returns (
            uint256 amountBOut,
            uint256 newIV,
            uint256 feesTokenA,
            uint256 feesTokenB
        )
    {
        return _getOptionTradeDetailsExactAInput(exactAmountAIn);
    }

    /**
     * @notice getOptionTradeDetailsExactAOutput view function that simulates a trade, in order the preview
     * the amountBIn, the new implied volatility, that will be used as the initialIVGuess if caller wants to perform
     * a trade in sequence. Also returns the amount of Fees that will be payed to liquidity pools A and B.
     *
     * @param exactAmountAOut amount of token A that will by transfer from pool to the msg.sender/owner
     *
     * @return amountBIn amount of B that will be transfer from msg.sender to the pool
     * @return newIV the new implied volatility that this trade will result
     * @return feesTokenA amount of fees of collected by token A
     * @return feesTokenB amount of fees of collected by token B
     */
    function getOptionTradeDetailsExactAOutput(uint256 exactAmountAOut)
        external
        override
        view
        returns (
            uint256 amountBIn,
            uint256 newIV,
            uint256 feesTokenA,
            uint256 feesTokenB
        )
    {
        return _getOptionTradeDetailsExactAOutput(exactAmountAOut);
    }

    /**
     * @notice getOptionTradeDetailsExactBInput view function that simulates a trade, in order the preview
     * the amountAOut, the new implied volatility, that will be used as the initialIVGuess if caller wants to perform
     * a trade in sequence. Also returns the amount of Fees that will be payed to liquidity pools A and B.
     *
     * @param exactAmountBIn amount of token B that will by transfer from msg.sender to the pool
     *
     * @return amountAOut amount of A that will be transfer from contract to owner
     * @return newIV the new implied volatility that this trade will result
     * @return feesTokenA amount of fees of collected by token A
     * @return feesTokenB amount of fees of collected by token B
     */
    function getOptionTradeDetailsExactBInput(uint256 exactAmountBIn)
        external
        override
        view
        returns (
            uint256 amountAOut,
            uint256 newIV,
            uint256 feesTokenA,
            uint256 feesTokenB
        )
    {
        return _getOptionTradeDetailsExactBInput(exactAmountBIn);
    }

    /**
     * @notice getOptionTradeDetailsExactBOutput view function that simulates a trade, in order the preview
     * the amountAIn, the new implied volatility, that will be used as the initialIVGuess if caller wants to perform
     * a trade in sequence. Also returns the amount of Fees that will be payed to liquidity pools A and B.
     *
     * @param exactAmountBOut amount of token B that will by transfer from pool to the msg.sender/owner
     *
     * @return amountAIn amount of A that will be transfer from msg.sender to the pool
     * @return newIV the new implied volatility that this trade will result
     * @return feesTokenA amount of fees of collected by token A
     * @return feesTokenB amount of fees of collected by token B
     */
    function getOptionTradeDetailsExactBOutput(uint256 exactAmountBOut)
        external
        override
        view
        returns (
            uint256 amountAIn,
            uint256 newIV,
            uint256 feesTokenA,
            uint256 feesTokenB
        )
    {
        return _getOptionTradeDetailsExactBOutput(exactAmountBOut);
    }

    function _getOptionTradeDetailsExactAInput(uint256 exactAmountAIn)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 newABPrice, uint256 spotPrice, uint256 timeToMaturity) = _getPriceDetails();
        if (newABPrice == 0) {
            return (0, 0, 0, 0);
        }

        (uint256 poolAmountA, uint256 poolAmountB) = _getPoolAmounts(newABPrice);

        uint256 amountBOutPool = _getAmountBOutPool(exactAmountAIn, poolAmountA, poolAmountB);
        uint256 newTargetABPrice = _getNewTargetPrice(newABPrice, exactAmountAIn, amountBOutPool, TradeDirection.AB);

        // Prevents the pool to sell an option under the minimum target price,
        // because it causes an infinite loop when trying to calculate newIV
        if (!_isValidTargetPrice(newTargetABPrice, spotPrice)) {
            return (0, 0, 0, 0);
        }

        uint256 newIV = _getNewIV(newTargetABPrice, spotPrice, timeToMaturity);

        uint256 feesTokenA = feePoolA.getCollectable(amountBOutPool, poolAmountB);
        uint256 feesTokenB = feePoolB.getCollectable(amountBOutPool, poolAmountB);

        uint256 amountBOutUser = amountBOutPool.sub(feesTokenA).sub(feesTokenB);

        return (amountBOutUser, newIV, feesTokenA, feesTokenB);
    }

    function _getOptionTradeDetailsExactAOutput(uint256 exactAmountAOut)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 newABPrice, uint256 spotPrice, uint256 timeToMaturity) = _getPriceDetails();
        if (newABPrice == 0) {
            return (0, 0, 0, 0);
        }
        (uint256 poolAmountA, uint256 poolAmountB) = _getPoolAmounts(newABPrice);

        uint256 amountBInPool = _getAmountBInPool(exactAmountAOut, poolAmountA, poolAmountB);
        uint256 newTargetABPrice = _getNewTargetPrice(newABPrice, exactAmountAOut, amountBInPool, TradeDirection.BA);

        uint256 feesTokenA = feePoolA.getCollectable(amountBInPool, poolAmountB);
        uint256 feesTokenB = feePoolB.getCollectable(amountBInPool, poolAmountB);

        uint256 amountBInUser = amountBInPool.add(feesTokenA).add(feesTokenB);

        uint256 newIV = _getNewIV(newTargetABPrice, spotPrice, timeToMaturity);

        return (amountBInUser, newIV, feesTokenA, feesTokenB);
    }

    function _getOptionTradeDetailsExactBInput(uint256 exactAmountBIn)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 newABPrice, uint256 spotPrice, uint256 timeToMaturity) = _getPriceDetails();
        if (newABPrice == 0) {
            return (0, 0, 0, 0);
        }
        (uint256 poolAmountA, uint256 poolAmountB) = _getPoolAmounts(newABPrice);

        uint256 feesTokenA = feePoolA.getCollectable(exactAmountBIn, poolAmountB);
        uint256 feesTokenB = feePoolB.getCollectable(exactAmountBIn, poolAmountB);
        uint256 totalFees = feesTokenA.add(feesTokenB);

        uint256 poolBIn = exactAmountBIn.sub(totalFees);

        uint256 amountAOutPool = _getAmountAOutPool(poolBIn, poolAmountA, poolAmountB);
        uint256 newTargetABPrice = _getNewTargetPrice(newABPrice, amountAOutPool, poolBIn, TradeDirection.BA);

        uint256 newIV = _getNewIV(newTargetABPrice, spotPrice, timeToMaturity);

        return (amountAOutPool, newIV, feesTokenA, feesTokenB);
    }

    function _getOptionTradeDetailsExactBOutput(uint256 exactAmountBOut)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 newABPrice, uint256 spotPrice, uint256 timeToMaturity) = _getPriceDetails();
        if (newABPrice == 0) {
            return (0, 0, 0, 0);
        }
        (uint256 poolAmountA, uint256 poolAmountB) = _getPoolAmounts(newABPrice);

        uint256 feesTokenA = feePoolA.getCollectable(exactAmountBOut, poolAmountB);
        uint256 feesTokenB = feePoolB.getCollectable(exactAmountBOut, poolAmountB);
        uint256 totalFees = feesTokenA.add(feesTokenB);

        uint256 poolBOut = exactAmountBOut.add(totalFees);

        uint256 amountAInPool = _getAmountAInPool(poolBOut, poolAmountA, poolAmountB);
        uint256 newTargetABPrice = _getNewTargetPrice(newABPrice, amountAInPool, poolBOut, TradeDirection.AB);

        // Prevents the pool to sell an option under the minimum target price,
        // because it causes an infinite loop when trying to calculate newIV
        if (!_isValidTargetPrice(newTargetABPrice, spotPrice)) {
            return (0, 0, 0, 0);
        }

        uint256 newIV = _getNewIV(newTargetABPrice, spotPrice, timeToMaturity);

        return (amountAInPool, newIV, feesTokenA, feesTokenB);
    }

    function _getPriceDetails()
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 timeToMaturity = _getTimeToMaturityInYears();

        if (timeToMaturity == 0) {
            return (0, 0, 0);
        }

        uint256 spotPrice = _getSpotPrice(priceProperties.underlyingAsset, PRICING_DECIMALS);
        uint256 adjustedIV = _getAdjustedIV(tokenA(), priceProperties.currentIV);

        IBlackScholes pricingMethod = IBlackScholes(configurationManager.getPricingMethod());
        uint256 newABPrice;

        if (priceProperties.optionType == IPodOption.OptionType.PUT) {
            newABPrice = pricingMethod.getPutPrice(
                spotPrice,
                priceProperties.strikePrice,
                adjustedIV,
                timeToMaturity,
                priceProperties.riskFree
            );
        } else {
            newABPrice = pricingMethod.getCallPrice(
                spotPrice,
                priceProperties.strikePrice,
                adjustedIV,
                timeToMaturity,
                priceProperties.riskFree
            );
        }
        if (newABPrice == 0) {
            return (0, spotPrice, timeToMaturity);
        }
        uint256 newABPriceWithDecimals = newABPrice.div(10**(PRICING_DECIMALS.sub(tokenBDecimals())));
        return (newABPriceWithDecimals, spotPrice, timeToMaturity);
    }

    /**
     * @dev returns maturity in years with 18 decimals
     */
    function _getTimeToMaturityInYears() internal view returns (uint256) {
        if (block.timestamp >= priceProperties.expiration) {
            return 0;
        }
        return priceProperties.expiration.sub(block.timestamp).mul(10**PRICING_DECIMALS).div(_SECONDS_IN_A_YEAR);
    }

    function _getPoolAmounts(uint256 newABPrice) internal view returns (uint256 poolAmountA, uint256 poolAmountB) {
        (uint256 totalAmountA, uint256 totalAmountB) = _getPoolBalances();
        if (newABPrice != 0) {
            poolAmountA = _min(totalAmountA, totalAmountB.mul(10**uint256(tokenADecimals())).div(newABPrice));
            poolAmountB = _min(totalAmountB, totalAmountA.mul(newABPrice).div(10**uint256(tokenADecimals())));
        }
        return (poolAmountA, poolAmountB);
    }

    function _getABPrice() internal override view returns (uint256) {
        (uint256 newABPrice, , ) = _getPriceDetails();
        return newABPrice;
    }

    function _getSpotPrice(address asset, uint256 decimalsOutput) internal view returns (uint256) {
        IPriceProvider priceProvider = IPriceProvider(configurationManager.getPriceProvider());
        uint256 spotPrice = priceProvider.getAssetPrice(asset);
        uint256 spotPriceDecimals = priceProvider.getAssetDecimals(asset);
        uint256 diffDecimals;
        uint256 spotPriceWithRightPrecision;

        if (decimalsOutput <= spotPriceDecimals) {
            diffDecimals = spotPriceDecimals.sub(decimalsOutput);
            spotPriceWithRightPrecision = spotPrice.div(10**diffDecimals);
        } else {
            diffDecimals = decimalsOutput.sub(spotPriceDecimals);
            spotPriceWithRightPrecision = spotPrice.mul(10**diffDecimals);
        }
        return spotPriceWithRightPrecision;
    }

    function _getOracleIV(address optionAddress) internal view returns (uint256 normalizedOracleIV) {
        IIVProvider ivProvider = IIVProvider(configurationManager.getIVProvider());
        (, , uint256 oracleIV, uint256 ivDecimals) = ivProvider.getIV(optionAddress);
        uint256 diffDecimals;

        if (ivDecimals <= PRICING_DECIMALS) {
            diffDecimals = PRICING_DECIMALS.sub(ivDecimals);
        } else {
            diffDecimals = ivDecimals.sub(PRICING_DECIMALS);
        }
        return oracleIV.div(10**diffDecimals);
    }

    function _getAdjustedIV(address optionAddress, uint256 currentIV) internal view returns (uint256 adjustedIV) {
        uint256 oracleIV = _getOracleIV(optionAddress);

        adjustedIV = _ORACLE_IV_WEIGHT.mul(oracleIV).add(_POOL_IV_WEIGHT.mul(currentIV)).div(
            _POOL_IV_WEIGHT + _ORACLE_IV_WEIGHT
        );
    }

    function _getNewIV(
        uint256 newTargetABPrice,
        uint256 spotPrice,
        uint256 timeToMaturity
    ) internal view returns (uint256) {
        uint256 newTargetABPriceWithDecimals = newTargetABPrice.mul(10**(PRICING_DECIMALS.sub(tokenBDecimals())));
        uint256 newIV;
        IIVGuesser ivGuesser = IIVGuesser(configurationManager.getIVGuesser());
        if (priceProperties.optionType == IPodOption.OptionType.PUT) {
            (newIV, ) = ivGuesser.getPutIV(
                newTargetABPriceWithDecimals,
                priceProperties.initialIVGuess,
                spotPrice,
                priceProperties.strikePrice,
                timeToMaturity,
                priceProperties.riskFree
            );
        } else {
            (newIV, ) = ivGuesser.getCallIV(
                newTargetABPriceWithDecimals,
                priceProperties.initialIVGuess,
                spotPrice,
                priceProperties.strikePrice,
                timeToMaturity,
                priceProperties.riskFree
            );
        }
        return newIV;
    }

    /**
     * @dev After it gets the unit BlackScholes price, it applies slippage based on the minimum available in the pool
     * (returned by the _getPoolAmounts()) and the product constant curve.
     * @param amountBOutPool The exact amount of tokenB will leave the pool
     * @param poolAmountA The amount of A available for trade
     * @param poolAmountB The amount of B available for trade
     * @return amountAInPool The amount of tokenA(options) will enter the pool
     */
    function _getAmountAInPool(
        uint256 amountBOutPool,
        uint256 poolAmountA,
        uint256 poolAmountB
    ) internal pure returns (uint256 amountAInPool) {
        uint256 productConstant = poolAmountA.mul(poolAmountB);
        require(amountBOutPool < poolAmountB, "AMM: insufficient liquidity");
        amountAInPool = productConstant.div(poolAmountB.sub(amountBOutPool)).sub(poolAmountA);
    }

    /**
     * @dev After it gets the unit BlackScholes price, it applies slippage based on the minimum available in the pool
     * (returned by the _getPoolAmounts()) and the product constant curve.
     * @param amountBInPool The exact amount of tokenB will enter the pool
     * @param poolAmountA The amount of A available for trade
     * @param poolAmountB The amount of B available for trade
     * @return amountAOutPool The amount of tokenA(options) will leave the pool
     */
    function _getAmountAOutPool(
        uint256 amountBInPool,
        uint256 poolAmountA,
        uint256 poolAmountB
    ) internal pure returns (uint256 amountAOutPool) {
        uint256 productConstant = poolAmountA.mul(poolAmountB);
        amountAOutPool = poolAmountA.sub(productConstant.div(poolAmountB.add(amountBInPool)));
    }

    /**
     * @dev After it gets the unit BlackScholes price, it applies slippage based on the minimum available in the pool
     * (returned by the _getPoolAmounts()) and the product constant curve.
     * @param amountAOutPool The amount of tokenA(options) will leave the pool
     * @param poolAmountA The amount of A available for trade
     * @param poolAmountB The amount of B available for trade
     * @return amountBInPool The amount of tokenB will enter the pool
     */
    function _getAmountBInPool(
        uint256 amountAOutPool,
        uint256 poolAmountA,
        uint256 poolAmountB
    ) internal pure returns (uint256 amountBInPool) {
        uint256 productConstant = poolAmountA.mul(poolAmountB);
        require(amountAOutPool < poolAmountA, "AMM: insufficient liquidity");
        amountBInPool = productConstant.div(poolAmountA.sub(amountAOutPool)).sub(poolAmountB);
    }

    /**
     * @dev After it gets the unit BlackScholes price, it applies slippage based on the minimum available in the pool
     * (returned by the _getPoolAmounts()) and the product constant curve.
     * @param amountAInPool The exact amount of tokenA(options) will enter the pool
     * @param poolAmountA The amount of A available for trade
     * @param poolAmountB The amount of B available for trade
     * @return amountBOutPool The amount of tokenB will leave the pool
     */
    function _getAmountBOutPool(
        uint256 amountAInPool,
        uint256 poolAmountA,
        uint256 poolAmountB
    ) internal pure returns (uint256 amountBOutPool) {
        uint256 productConstant = poolAmountA.mul(poolAmountB);
        amountBOutPool = poolAmountB.sub(productConstant.div(poolAmountA.add(amountAInPool)));
    }

    /**
     * @dev Based on the tokensA and tokensB leaving or entering the pool, it is possible to calculate the new option
     * target price. That price will be used later to update the currentIV.
     * @param newABPrice calculated Black Scholes unit price (how many units of tokenB, to buy 1 tokenA(option))
     * @param amountA The amount of tokenA that will leave or enter the pool
     * @param amountB TThe amount of tokenB that will leave or enter the pool
     * @param tradeDirection The trade direction, if it is AB, means that tokenA will enter, and tokenB will leave.
     * @return newTargetPrice The new unit target price (how many units of tokenB, to buy 1 tokenA(option))
     */
    function _getNewTargetPrice(
        uint256 newABPrice,
        uint256 amountA,
        uint256 amountB,
        TradeDirection tradeDirection
    ) internal view returns (uint256 newTargetPrice) {
        (uint256 poolAmountA, uint256 poolAmountB) = _getPoolAmounts(newABPrice);
        if (tradeDirection == TradeDirection.AB) {
            newTargetPrice = poolAmountB.sub(amountB).mul(10**uint256(tokenADecimals())).div(poolAmountA.add(amountA));
        } else {
            newTargetPrice = poolAmountB.add(amountB).mul(10**uint256(tokenADecimals())).div(poolAmountA.sub(amountA));
        }
    }

    function _getTradeDetailsExactAInput(uint256 exactAmountAIn) internal override returns (TradeDetails memory) {
        (uint256 amountBOut, uint256 newIV, uint256 feesTokenA, uint256 feesTokenB) = _getOptionTradeDetailsExactAInput(
            exactAmountAIn
        );

        TradeDetails memory tradeDetails = TradeDetails(amountBOut, feesTokenA, feesTokenB, abi.encodePacked(newIV));
        return tradeDetails;
    }

    function _getTradeDetailsExactAOutput(uint256 exactAmountAOut) internal override returns (TradeDetails memory) {
        (uint256 amountBIn, uint256 newIV, uint256 feesTokenA, uint256 feesTokenB) = _getOptionTradeDetailsExactAOutput(
            exactAmountAOut
        );

        TradeDetails memory tradeDetails = TradeDetails(amountBIn, feesTokenA, feesTokenB, abi.encodePacked(newIV));
        return tradeDetails;
    }

    function _getTradeDetailsExactBInput(uint256 exactAmountBIn) internal override returns (TradeDetails memory) {
        (uint256 amountAOut, uint256 newIV, uint256 feesTokenA, uint256 feesTokenB) = _getOptionTradeDetailsExactBInput(
            exactAmountBIn
        );

        TradeDetails memory tradeDetails = TradeDetails(amountAOut, feesTokenA, feesTokenB, abi.encodePacked(newIV));
        return tradeDetails;
    }

    function _getTradeDetailsExactBOutput(uint256 exactAmountBOut) internal override returns (TradeDetails memory) {
        (uint256 amountAIn, uint256 newIV, uint256 feesTokenA, uint256 feesTokenB) = _getOptionTradeDetailsExactBOutput(
            exactAmountBOut
        );

        TradeDetails memory tradeDetails = TradeDetails(amountAIn, feesTokenA, feesTokenB, abi.encodePacked(newIV));
        return tradeDetails;
    }

    /**
     * @dev If a option is ITM, either PUTs or CALLs, the minimum price that it would cost is the difference between
     * the spot price and strike price. If the target price after applying slippage is above this minimum, the function
     * returns true.
     * @param newTargetPrice the new ABPrice after slippage (how many units of tokenB, to buy 1 option)
     * @param spotPrice current underlying asset spot price during this transaction
     * @return true if is a valid target price (above the minimum)
     */
    function _isValidTargetPrice(uint256 newTargetPrice, uint256 spotPrice) internal view returns (bool) {
        if (priceProperties.optionType == IPodOption.OptionType.PUT) {
            if (spotPrice < priceProperties.strikePrice) {
                return
                    newTargetPrice >
                    priceProperties.strikePrice.sub(spotPrice).div(10**PRICING_DECIMALS.sub(tokenBDecimals()));
            }
        } else {
            if (spotPrice > priceProperties.strikePrice) {
                return
                    newTargetPrice >
                    spotPrice.sub(priceProperties.strikePrice).div(10**PRICING_DECIMALS.sub(tokenBDecimals()));
            }
        }
        return true;
    }

    function _onAddLiquidity(UserDepositSnapshot memory _userDepositSnapshot, address owner) internal override {
        uint256 currentQuotesA = feePoolA.sharesOf(owner);
        uint256 currentQuotesB = feePoolB.sharesOf(owner);
        uint256 amountOfQuotesAToAdd = 0;
        uint256 amountOfQuotesBToAdd = 0;

        uint256 totalQuotesA = _userDepositSnapshot.tokenABalance.mul(10**FIMP_DECIMALS).div(_userDepositSnapshot.fImp);

        if (totalQuotesA > currentQuotesA) {
            amountOfQuotesAToAdd = totalQuotesA.sub(currentQuotesA);
        }

        uint256 totalQuotesB = _userDepositSnapshot.tokenBBalance.mul(10**FIMP_DECIMALS).div(_userDepositSnapshot.fImp);

        if (totalQuotesB > currentQuotesB) {
            amountOfQuotesBToAdd = totalQuotesB.sub(currentQuotesB);
        }

        feePoolA.mint(owner, amountOfQuotesAToAdd);
        feePoolB.mint(owner, amountOfQuotesBToAdd);
    }

    function _onRemoveLiquidity(
        uint256 percentA,
        uint256 percentB,
        address owner
    ) internal override {
        (uint256 amountOfSharesAToRemove, uint256 amountOfSharesBToRemove) = _getAmountOfFeeShares(
            percentA,
            percentB,
            owner
        );

        if (amountOfSharesAToRemove > 0) {
            feePoolA.withdraw(owner, amountOfSharesAToRemove);
        }
        if (amountOfSharesBToRemove > 0) {
            feePoolB.withdraw(owner, amountOfSharesBToRemove);
        }
    }

    function _getAmountOfFeeShares(
        uint256 percentA,
        uint256 percentB,
        address owner
    ) internal view returns (uint256, uint256) {
        uint256 currentSharesA = feePoolA.sharesOf(owner);
        uint256 currentSharesB = feePoolB.sharesOf(owner);

        uint256 amountOfSharesAToRemove = currentSharesA.mul(percentA).div(PERCENT_PRECISION);
        uint256 amountOfSharesBToRemove = currentSharesB.mul(percentB).div(PERCENT_PRECISION);

        return (amountOfSharesAToRemove, amountOfSharesBToRemove);
    }

    function _onTrade(TradeDetails memory tradeDetails) internal override {
        uint256 newIV = abi.decode(tradeDetails.params, (uint256));
        require(tradeDetails.feesTokenA > 0 && tradeDetails.feesTokenB > 0, "Pool: zero fees");
        priceProperties.currentIV = newIV;

        IERC20(tokenB()).safeTransfer(address(feePoolA), tradeDetails.feesTokenA);
        IERC20(tokenB()).safeTransfer(address(feePoolB), tradeDetails.feesTokenB);
    }

    /**
     * @dev Check for functions which are only allowed to be executed
     * BEFORE start of exercise window.
     */
    function _beforeStartOfExerciseWindow() internal view {
        require(block.timestamp < priceProperties.startOfExerciseWindow, "Pool: exercise window has started");
    }

    function _emergencyStopCheck() private view {
        IEmergencyStop emergencyStop = IEmergencyStop(configurationManager.getEmergencyStop());
        require(
            !emergencyStop.isStopped(address(this)) &&
                !emergencyStop.isStopped(configurationManager.getPriceProvider()) &&
                !emergencyStop.isStopped(configurationManager.getPricingMethod()),
            "Pool: Pool is stopped"
        );
    }

    function _emitTradeInfo() private {
        uint256 spotPrice = _getSpotPrice(priceProperties.underlyingAsset, PRICING_DECIMALS);
        emit TradeInfo(spotPrice, priceProperties.currentIV);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IConfigurationManager.sol";
import "../interfaces/ICapProvider.sol";

/**
 * @title CappedPool
 * @author Pods Finance
 *
 * @notice Controls a maximum cap for a guarded release
 */
abstract contract CappedPool {
    using SafeMath for uint256;

    IConfigurationManager private immutable _configurationManager;

    constructor(IConfigurationManager configurationManager) public {
        _configurationManager = configurationManager;
    }

    /**
     * @dev Modifier to stop transactions that exceed the cap
     */
    modifier capped(address token, uint256 amountOfLiquidity) {
        uint256 cap = capSize();

        if (cap > 0) {
            uint256 poolBalance = IERC20(token).balanceOf(address(this));
            require(poolBalance.add(amountOfLiquidity) <= cap, "CappedPool: amount exceed cap");
        }
        _;
    }

    /**
     * @dev Get the cap size
     */
    function capSize() public view returns (uint256) {
        ICapProvider capProvider = ICapProvider(_configurationManager.getCapProvider());
        return capProvider.getCap(address(this));
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

contract CombinedActionsGuard {
    mapping(address => uint256) sessions;

    /**
     * @dev Prevents an address from calling more than one function that contains this
     * function in the same block
     */
    function _nonCombinedActions() internal {
        require(sessions[tx.origin] != block.number, "CombinedActionsGuard: reentrant call");
        sessions[tx.origin] = block.number;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IIVProvider {
    struct IVData {
        uint256 roundId;
        uint256 updatedAt;
        uint256 answer;
        uint8 decimals;
    }

    event UpdatedIV(address indexed option, uint256 roundId, uint256 updatedAt, uint256 answer, uint8 decimals);
    event UpdaterSet(address indexed admin, address indexed updater);

    function getIV(address option)
        external
        view
        returns (
            uint256 roundId,
            uint256 updatedAt,
            uint256 answer,
            uint8 decimals
        );

    function updateIV(
        address option,
        uint256 answer,
        uint8 decimals
    ) external;

    function setUpdater(address updater) external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.12;

interface IBlackScholes {
    function getCallPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) external view returns (uint256);

    function getPutPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IIVGuesser {
    function blackScholes() external view returns (address);

    function getPutIV(
        uint256 _targetPrice,
        uint256 _initialIVGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree
    ) external view returns (uint256, uint256);

    function getCallIV(
        uint256 _targetPrice,
        uint256 _initialIVGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree
    ) external view returns (uint256, uint256);

    function updateAcceptableRange() external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IFeePool {
    struct Balance {
        uint256 shares;
        uint256 liability;
    }

    function setFee(uint256 feeBaseValue, uint8 decimals) external;

    function withdraw(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function feeToken() external view returns (address);

    function feeValue() external view returns (uint256);

    function feeDecimals() external view returns (uint8);

    function getCollectable(uint256 amount, uint256 poolAmount) external view returns (uint256);

    function sharesOf(address owner) external view returns (uint256);

    function getWithdrawAmount(address owner, uint256 amountOfShares) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IEmergencyStop {
    function stop(address target) external;

    function resume(address target) external;

    function isStopped(address target) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./IFeePool.sol";

interface IFeePoolBuilder {
    function buildFeePool(
        address asset,
        uint256 feeBaseValue,
        uint8 feeDecimals,
        address owner
    ) external returns (IFeePool);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IAaveIncentivesController.sol";
import "../../interfaces/IConfigurationManager.sol";
import "../../lib/Conversion.sol";

abstract contract AaveIncentives is Conversion {
    address public immutable rewardAsset;
    address public immutable rewardContract;

    event RewardsClaimed(address indexed claimer, uint256 rewardAmount);

    constructor(IConfigurationManager configurationManager) public {
        rewardAsset = _parseAddressFromUint(configurationManager.getParameter("REWARD_ASSET"));
        rewardContract = _parseAddressFromUint(configurationManager.getParameter("REWARD_CONTRACT"));
    }

    /**
     * @notice Gets the current reward claimed
     */
    function _rewardBalance() internal view returns (uint256) {
        return IERC20(rewardAsset).balanceOf(address(this));
    }

    /**
     * @notice Claim pending rewards
     */
    function _claimRewards(address[] memory assets) internal {
        IAaveIncentivesController distributor = IAaveIncentivesController(rewardContract);
        uint256 amountToClaim = distributor.getRewardsBalance(assets, address(this));
        distributor.claimRewards(assets, amountToClaim, address(this));
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IAaveIncentivesController {
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../PodPut.sol";
import "./AaveIncentives.sol";

/**
 * @title AavePodPut
 * @author Pods Finance
 *
 * @notice Represents a tokenized Put option series that handles and distributes liquidity
 * mining rewards to minters (sellers) proportionally to their amount of shares
 */
contract AavePodPut is PodPut, AaveIncentives {
    constructor(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    )
        public
        PodPut(
            name,
            symbol,
            exerciseType,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        )
        AaveIncentives(configurationManager)
    {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external override unmintWindow {
        _claimRewards(_getClaimableAssets());
        uint256 rewardsToSend = (shares[msg.sender].mul(amountOfOptions).div(mintedOptions[msg.sender])).mul(_rewardBalance()).div(totalShares);

        (uint256 strikeToSend, uint256 underlyingToSend) = _unmintOptions(amountOfOptions, msg.sender);
        require(strikeToSend > 0, "AavePodPut: amount of options is too low");

        // Sends strike asset
        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        emit Unmint(msg.sender, amountOfOptions, strikeToSend, underlyingToSend);

        if (rewardsToSend > 0) {
            IERC20(rewardAsset).safeTransfer(msg.sender, rewardsToSend);
            emit RewardsClaimed(msg.sender, rewardsToSend);
        }
    }

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their strike asset tokens to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and strike asset tokens.
     */
    function withdraw() external override withdrawWindow {
        _claimRewards(_getClaimableAssets());
        uint256 rewardsToSend = shares[msg.sender].mul(_rewardBalance()).div(totalShares);

        (uint256 strikeToSend, uint256 underlyingToSend) = _withdraw();

        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        if (underlyingToSend > 0) {
            IERC20(underlyingAsset()).safeTransfer(msg.sender, underlyingToSend);
        }

        emit Withdraw(msg.sender, strikeToSend, underlyingToSend);

        if (rewardsToSend > 0) {
            IERC20(rewardAsset).safeTransfer(msg.sender, rewardsToSend);
            emit RewardsClaimed(msg.sender, rewardsToSend);
        }
    }

    /**
     * @dev Returns an array of staked assets which may be eligible for claiming rewards
     */
    function _getClaimableAssets() internal view returns (address[] memory) {
        address[] memory assets = new address[](1);
        assets[0] = strikeAsset();

        return assets;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../rewards/AavePodPut.sol";
import "../../interfaces/IPodOption.sol";
import "../../interfaces/IOptionBuilder.sol";

/**
 * @title AavePodPutBuilder
 * @author Pods Finance
 * @notice Builds AavePodPut options
 */
contract AavePodPutBuilder is IOptionBuilder {
    /**
     * @notice creates a new AavePodPut Contract
     * @param name The option token name. Eg. "Pods Put WBTC-USDC 5000 2020-02-23"
     * @param symbol The option token symbol. Eg. "podWBTC:20AA"
     * @param exerciseType The option exercise type. Eg. "0 for European, 1 for American"
     * @param underlyingAsset The underlying asset. Eg. "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
     * @param strikeAsset The strike asset. Eg. "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
     * @param strikePrice The option strike price including decimals. e.g. 5000000000
     * @param expiration The Expiration Option date in seconds. e.g. 1600178324
     * @param exerciseWindowSize The Expiration Window Size duration in seconds. E.g 24*60*60 (24h)
     */
    function buildOption(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    ) external override returns (IPodOption) {
        AavePodPut option = new AavePodPut(
            name,
            symbol,
            exerciseType,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        );

        return option;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../PodCall.sol";
import "./AaveIncentives.sol";

/**
 * @title AavePodCall
 * @author Pods Finance
 *
 * @notice Represents a tokenized Call option series that handles and distributes liquidity
 * mining rewards to minters (sellers) proportionally to their amount of shares
 */
contract AavePodCall is PodCall, AaveIncentives {
    constructor(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    )
        public
        PodCall(
            name,
            symbol,
            exerciseType,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        )
        AaveIncentives(configurationManager)
    {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external override unmintWindow {
        _claimRewards(_getClaimableAssets());
        uint256 rewardsToSend = (shares[msg.sender].mul(amountOfOptions).div(mintedOptions[msg.sender])).mul(_rewardBalance()).div(totalShares);

        (uint256 strikeToSend, uint256 underlyingToSend) = _unmintOptions(amountOfOptions, msg.sender);

        IERC20(underlyingAsset()).safeTransfer(msg.sender, underlyingToSend);

        emit Unmint(msg.sender, amountOfOptions, strikeToSend, underlyingToSend);

        if (rewardsToSend > 0) {
            IERC20(rewardAsset).safeTransfer(msg.sender, rewardsToSend);
            emit RewardsClaimed(msg.sender, rewardsToSend);
        }
    }

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their strike asset tokens to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and strike asset tokens.
     */
    function withdraw() external override withdrawWindow {
        _claimRewards(_getClaimableAssets());
        uint256 rewardsToSend = shares[msg.sender].mul(_rewardBalance()).div(totalShares);

        (uint256 strikeToSend, uint256 underlyingToSend) = _withdraw();

        IERC20(underlyingAsset()).safeTransfer(msg.sender, underlyingToSend);

        if (strikeToSend > 0) {
            IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);
        }

        emit Withdraw(msg.sender, strikeToSend, underlyingToSend);

        if (rewardsToSend > 0) {
            IERC20(rewardAsset).safeTransfer(msg.sender, rewardsToSend);
            emit RewardsClaimed(msg.sender, rewardsToSend);
        }
    }

    /**
     * @dev Returns an array of staked assets which may be eligible for claiming rewards
     */
    function _getClaimableAssets() internal view returns (address[] memory) {
        address[] memory assets = new address[](1);
        assets[0] = underlyingAsset();

        return assets;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../PodCall.sol";
import "../../interfaces/IPodOption.sol";
import "../../interfaces/IOptionBuilder.sol";

/**
 * @title PodCallBuilder
 * @author Pods Finance
 * @notice Builds PodCall options
 */
contract PodCallBuilder is IOptionBuilder {
    /**
     * @notice creates a new PodCall Contract
     * @param name The option token name. Eg. "Pods Call WBTC-USDC 5000 2020-02-23"
     * @param symbol The option token symbol. Eg. "podWBTC:20AA"
     * @param exerciseType The option exercise type. Eg. "0 for European, 1 for American"
     * @param underlyingAsset The underlying asset. Eg. "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
     * @param strikeAsset The strike asset. Eg. "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
     * @param strikePrice The option strike price including decimals. e.g. 5000000000
     * @param expiration The Expiration Option date in seconds. e.g. 1600178324
     * @param exerciseWindowSize The Expiration Window Size duration in seconds. E.g 24*60*60 (24h)
     */
    function buildOption(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    ) external override returns (IPodOption) {
        PodCall option = new PodCall(
            name,
            symbol,
            exerciseType,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        );

        return option;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../rewards/AavePodCall.sol";
import "../../interfaces/IPodOption.sol";
import "../../interfaces/IOptionBuilder.sol";

/**
 * @title AavePodCallBuilder
 * @author Pods Finance
 * @notice Builds AavePodCall options
 */
contract AavePodCallBuilder is IOptionBuilder {
    /**
     * @notice creates a new AavePodCall Contract
     * @param name The option token name. Eg. "Pods Call WBTC-USDC 5000 2020-02-23"
     * @param symbol The option token symbol. Eg. "podWBTC:20AA"
     * @param exerciseType The option exercise type. Eg. "0 for European, 1 for American"
     * @param underlyingAsset The underlying asset. Eg. "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
     * @param strikeAsset The strike asset. Eg. "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
     * @param strikePrice The option strike price including decimals. e.g. 5000000000
     * @param expiration The Expiration Option date in seconds. e.g. 1600178324
     * @param exerciseWindowSize The Expiration Window Size duration in seconds. E.g 24*60*60 (24h)
     */
    function buildOption(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    ) external override returns (IPodOption) {
        AavePodCall option = new AavePodCall(
            name,
            symbol,
            exerciseType,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        );

        return option;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IConfigurationManager.sol";
import "../interfaces/IOptionAMMFactory.sol";
import "../interfaces/IFeePoolBuilder.sol";
import "./OptionAMMPool.sol";
import "../interfaces/IOptionPoolRegistry.sol";

/**
 * @title OptionAMMFactory
 * @author Pods Finance
 * @notice Creates and store new OptionAMMPool
 */
contract OptionAMMFactory is IOptionAMMFactory {
    /**
     * @dev store globally accessed configurations
     */
    IConfigurationManager public immutable configurationManager;

    /**
     * @dev store globally accessed configurations
     */
    IFeePoolBuilder public immutable feePoolBuilder;

    event PoolCreated(address indexed deployer, address pool, address option);

    constructor(IConfigurationManager _configurationManager, address _feePoolBuilder) public {
        require(
            Address.isContract(address(_configurationManager)),
            "OptionAMMFactory: Configuration Manager is not a contract"
        );
        require(Address.isContract(_feePoolBuilder), "OptionAMMFactory: FeePoolBuilder is not a contract");

        configurationManager = _configurationManager;

        feePoolBuilder = IFeePoolBuilder(_feePoolBuilder);
    }

    /**
     * @notice Creates an option pool
     *
     * @param _optionAddress The address of option token
     * @param _stableAsset A stablecoin asset address
     * @param _initialIV Initial number of implied volatility
     * @return The address of the newly created pool
     */
    function createPool(
        address _optionAddress,
        address _stableAsset,
        uint256 _initialIV
    ) external override returns (address) {
        IOptionPoolRegistry registry = IOptionPoolRegistry(configurationManager.getOptionPoolRegistry());
        require(registry.getPool(_optionAddress) == address(0), "OptionAMMFactory: Pool already exists");

        OptionAMMPool pool = new OptionAMMPool(
            _optionAddress,
            _stableAsset,
            _initialIV,
            configurationManager,
            feePoolBuilder
        );

        address poolAddress = address(pool);
        emit PoolCreated(msg.sender, poolAddress, _optionAddress);
        registry.setPool(_optionAddress, poolAddress);

        return poolAddress;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IOptionAMMFactory {
    function createPool(
        address _optionAddress,
        address _stableAsset,
        uint256 _initialSigma
    ) external returns (address);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./FeePool.sol";
import "../interfaces/IFeePool.sol";
import "../interfaces/IFeePoolBuilder.sol";

/**
 * @title FeePoolBuilder
 * @author Pods Finance
 * @notice Builds FeePool
 */
contract FeePoolBuilder is IFeePoolBuilder {
    /**
     * @notice creates a new FeePool Contract
     * @param asset The token in which the fees are collected
     * @param feeBaseValue The base value of fees
     * @param feeDecimals Amount of decimals of feeValue
     * @param owner Owner of the FeePool
     * @return feePool
     */
    function buildFeePool(
        address asset,
        uint256 feeBaseValue,
        uint8 feeDecimals,
        address owner
    ) external override returns (IFeePool) {
        FeePool feePool = new FeePool(asset, feeBaseValue, feeDecimals);
        feePool.transferOwnership(owner);
        return feePool;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IFeePool.sol";

/**
 * @title FeePool
 * @author Pods Finance
 * @notice Represents a pool that manages fee collection.
 * Shares can be created to redeem the collected fees between participants proportionally.
 */
contract FeePool is IFeePool, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => Balance) private _balances;
    uint256 private _shares;
    uint256 private _totalLiability;

    uint256 private _feeBaseValue;
    uint8 private _feeDecimals;
    address private immutable _token;
    uint256 private constant _DYNAMIC_FEE_ALPHA = 2000;
    uint256 private constant _MAX_FEE_DECIMALS = 38;

    event FeeUpdated(address token, uint256 newBaseFee, uint8 newFeeDecimals);
    event FeeWithdrawn(address token, address to, uint256 amountWithdrawn, uint256 sharesBurned);
    event ShareMinted(address token, address to, uint256 amountMinted);

    constructor(
        address token,
        uint256 feeBaseValue,
        uint8 feeDecimals
    ) public {
        require(token != address(0), "FeePool: Invalid token");
        require(
            feeDecimals <= _MAX_FEE_DECIMALS && feeBaseValue <= uint256(10)**feeDecimals,
            "FeePool: Invalid Fee data"
        );

        _token = token;
        _feeBaseValue = feeBaseValue;
        _feeDecimals = feeDecimals;
    }

    /**
     * @notice Sets fee and the decimals
     *
     * @param feeBaseValue Fee value
     * @param feeDecimals Fee decimals
     */
    function setFee(uint256 feeBaseValue, uint8 feeDecimals) external override onlyOwner {
        require(
            feeDecimals <= _MAX_FEE_DECIMALS && feeBaseValue <= uint256(10)**feeDecimals,
            "FeePool: Invalid Fee data"
        );
        _feeBaseValue = feeBaseValue;
        _feeDecimals = feeDecimals;
        emit FeeUpdated(_token, _feeBaseValue, _feeDecimals);
    }

    /**
     * @notice get the withdraw token amount based on the amount of shares that will be burned
     *
     * @param to address of the share holder
     * @param amountOfShares amount of shares to withdraw
     */
    function getWithdrawAmount(address to, uint256 amountOfShares)
        external
        override
        view
        returns (uint256 amortizedLiability, uint256 withdrawAmount)
    {
        return _getWithdrawAmount(to, amountOfShares);
    }

    /**
     * @notice Withdraws collected fees to an address
     *
     * @param to To whom the fees should be transferred
     * @param amountOfShares Amount of Shares to burn
     */
    function withdraw(address to, uint256 amountOfShares) external override onlyOwner {
        require(_balances[to].shares >= amountOfShares, "Burn exceeds balance");

        (uint256 amortizedLiability, uint256 withdrawAmount) = _getWithdrawAmount(to, amountOfShares);

        _balances[to].shares = _balances[to].shares.sub(amountOfShares);
        _balances[to].liability = _balances[to].liability.sub(amortizedLiability);
        _shares = _shares.sub(amountOfShares);
        _totalLiability = _totalLiability.sub(amortizedLiability);

        if (withdrawAmount > 0) {
            IERC20(_token).safeTransfer(to, withdrawAmount);
            emit FeeWithdrawn(_token, to, withdrawAmount, amountOfShares);
        }
    }

    /**
     * @notice Creates new shares that represent a fraction when withdrawing fees
     *
     * @param to To whom the tokens should be minted
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external override onlyOwner {
        // If no share was minted, share value should worth nothing
        uint256 newLiability = 0;

        // Otherwise it should divide the total collected by total shares minted
        if (_shares > 0) {
            uint256 feesCollected = IERC20(_token).balanceOf(address(this));
            newLiability = feesCollected.add(_totalLiability).mul(amount).div(_shares);
        }

        _balances[to].shares = _balances[to].shares.add(amount);
        _balances[to].liability = _balances[to].liability.add(newLiability);
        _shares = _shares.add(amount);
        _totalLiability = _totalLiability.add(newLiability);

        emit ShareMinted(_token, to, amount);
    }

    /**
     * @notice Return the current fee token
     */
    function feeToken() external override view returns (address) {
        return _token;
    }

    /**
     * @notice Return the current fee value
     */
    function feeValue() external override view returns (uint256 feeBaseValue) {
        return _feeBaseValue;
    }

    /**
     * @notice Returns the number of decimals used to represent fees
     */
    function feeDecimals() external override view returns (uint8) {
        return _feeDecimals;
    }

    /**
     * @notice Utility function to calculate fee charges to a given amount
     *
     * @param amount Total transaction amount
     * @param poolAmount Total pool amount
     */
    function getCollectable(uint256 amount, uint256 poolAmount) external override view returns (uint256 totalFee) {
        uint256 baseFee = amount.mul(_feeBaseValue).div(10**uint256(_feeDecimals));
        uint256 dynamicFee = _getDynamicFees(amount, poolAmount);
        return baseFee.add(dynamicFee);
    }

    /**
     * @dev Returns the `Balance` owned by `account`.
     */
    function balanceOf(address account) external view returns (Balance memory) {
        return _balances[account];
    }

    /**
     * @dev Returns the `shares` owned by `account`.
     */
    function sharesOf(address account) external override view returns (uint256) {
        return _balances[account].shares;
    }

    /**
     * @notice Total count of shares created
     */
    function totalShares() external view returns (uint256) {
        return _shares;
    }

    /**
     * @notice Calculates a dynamic fee to counterbalance big trades and incentivize liquidity
     */
    function _getDynamicFees(uint256 tradeAmount, uint256 poolAmount) internal pure returns (uint256) {
        uint256 numerator = _DYNAMIC_FEE_ALPHA * tradeAmount.mul(tradeAmount).mul(tradeAmount);
        uint256 denominator = poolAmount.mul(poolAmount).mul(poolAmount);
        uint256 ratio = numerator.div(denominator);

        return ratio.mul(tradeAmount) / 100;
    }

    function _getWithdrawAmount(address to, uint256 amountOfShares)
        internal
        view
        returns (uint256 amortizedLiability, uint256 withdrawAmount)
    {
        uint256 feesCollected = IERC20(_token).balanceOf(address(this));

        withdrawAmount = 0;
        amortizedLiability = amountOfShares.mul(_balances[to].liability).div(_balances[to].shares);
        uint256 collectedGross = feesCollected.add(_totalLiability).mul(amountOfShares).div(_shares);
        // Prevents negative payouts
        if (collectedGross > amortizedLiability) {
            withdrawAmount = collectedGross.sub(amortizedLiability);
        }
        return (amortizedLiability, withdrawAmount);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IIVProvider.sol";

/**
 * @title IVProvider
 * @author Pods Finance
 * @notice Storage of implied volatility oracles
 */
contract IVProvider is IIVProvider, Ownable {
    mapping(address => IVData) private _answers;

    mapping(address => uint256) private _lastIds;

    address public updater;

    modifier isUpdater() {
        require(msg.sender == updater, "IVProvider: sender must be an updater");
        _;
    }

    function getIV(address option)
        external
        override
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint8
        )
    {
        IVData memory data = _answers[option];
        return (data.roundId, data.updatedAt, data.answer, data.decimals);
    }

    function updateIV(
        address option,
        uint256 answer,
        uint8 decimals
    ) external override isUpdater {
        uint256 lastRoundId = _lastIds[option];
        uint256 roundId = ++lastRoundId;

        _lastIds[option] = roundId;
        _answers[option] = IVData(roundId, block.timestamp, answer, decimals);

        emit UpdatedIV(option, roundId, block.timestamp, answer, decimals);
    }

    function setUpdater(address _updater) external override onlyOwner {
        updater = _updater;
        emit UpdaterSet(msg.sender, updater);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../configuration/ModuleStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ModuleStorageUser is ModuleStorage, Ownable {
    bytes32 private constant TOKEN_BURNER = "TOKEN_BURNER";

    function setTokenBurner(address newTokenBurner) external onlyOwner {
        _setModule(TOKEN_BURNER, newTokenBurner);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

/**
 * @title ModuleStorage
 * @author Pods Finance
 * @notice Stores addresses from configuration modules
 */
contract ModuleStorage {
    mapping(bytes32 => address) private _addresses;

    event ModuleSet(bytes32 indexed name, address indexed newAddress);

    /**
     * @dev Get a configuration module address
     * @param name The name of a module
     */
    function getModule(bytes32 name) public view returns (address) {
        return _addresses[name];
    }

    /**
     * @dev Set a configuration module address
     * @param name The name of a module
     * @param module The module address
     */
    function _setModule(bytes32 name, address module) internal {
        require(module != address(0), "ModuleStorage: Invalid module");
        _addresses[name] = module;
        emit ModuleSet(name, module);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ModuleStorage.sol";
import "../interfaces/IConfigurationManager.sol";

/**
 * @title ConfigurationManager
 * @author Pods Finance
 * @notice Allows contracts to read protocol-wide configuration modules
 */
contract ConfigurationManager is IConfigurationManager, ModuleStorage, Ownable {
    mapping(bytes32 => uint256) private _parameters;

    /* solhint-disable private-vars-leading-underscore */
    bytes32 private constant EMERGENCY_STOP = "EMERGENCY_STOP";
    bytes32 private constant PRICING_METHOD = "PRICING_METHOD";
    bytes32 private constant IV_GUESSER = "IV_GUESSER";
    bytes32 private constant IV_PROVIDER = "IV_PROVIDER";
    bytes32 private constant PRICE_PROVIDER = "PRICE_PROVIDER";
    bytes32 private constant CAP_PROVIDER = "CAP_PROVIDER";
    bytes32 private constant AMM_FACTORY = "AMM_FACTORY";
    bytes32 private constant OPTION_FACTORY = "OPTION_FACTORY";
    bytes32 private constant OPTION_HELPER = "OPTION_HELPER";
    bytes32 private constant OPTION_POOL_REGISTRY = "OPTION_POOL_REGISTRY";

    /* solhint-enable private-vars-leading-underscore */

    event ParameterSet(bytes32 name, uint256 value);

    constructor() public {
        /**
         * Minimum price interval to accept a price feed
         * Defaulted to 3 hours and 10 minutes
         */
        _parameters["MIN_UPDATE_INTERVAL"] = 11100;

        /**
         * Acceptable range interval on sigma numerical method
         */
        _parameters["GUESSER_ACCEPTABLE_RANGE"] = 10;
    }

    function setParameter(bytes32 name, uint256 value) external override onlyOwner {
        _parameters[name] = value;
        emit ParameterSet(name, value);
    }

    function setEmergencyStop(address emergencyStop) external override onlyOwner {
        _setModule(EMERGENCY_STOP, emergencyStop);
    }

    function setPricingMethod(address pricingMethod) external override onlyOwner {
        _setModule(PRICING_METHOD, pricingMethod);
    }

    function setIVGuesser(address ivGuesser) external override onlyOwner {
        _setModule(IV_GUESSER, ivGuesser);
    }

    function setIVProvider(address ivProvider) external override onlyOwner {
        _setModule(IV_PROVIDER, ivProvider);
    }

    function setPriceProvider(address priceProvider) external override onlyOwner {
        _setModule(PRICE_PROVIDER, priceProvider);
    }

    function setCapProvider(address capProvider) external override onlyOwner {
        _setModule(CAP_PROVIDER, capProvider);
    }

    function setAMMFactory(address ammFactory) external override onlyOwner {
        _setModule(AMM_FACTORY, ammFactory);
    }

    function setOptionFactory(address optionFactory) external override onlyOwner {
        _setModule(OPTION_FACTORY, optionFactory);
    }

    function setOptionHelper(address optionHelper) external override onlyOwner {
        _setModule(OPTION_HELPER, optionHelper);
    }

    function setOptionPoolRegistry(address optionPoolRegistry) external override onlyOwner {
        _setModule(OPTION_POOL_REGISTRY, optionPoolRegistry);
    }

    function getParameter(bytes32 name) external override view returns (uint256) {
        return _parameters[name];
    }

    function getEmergencyStop() external override view returns (address) {
        return getModule(EMERGENCY_STOP);
    }

    function getPricingMethod() external override view returns (address) {
        return getModule(PRICING_METHOD);
    }

    function getIVGuesser() external override view returns (address) {
        return getModule(IV_GUESSER);
    }

    function getIVProvider() external override view returns (address) {
        return getModule(IV_PROVIDER);
    }

    function getPriceProvider() external override view returns (address) {
        return getModule(PRICE_PROVIDER);
    }

    function getCapProvider() external override view returns (address) {
        return getModule(CAP_PROVIDER);
    }

    function getAMMFactory() external override view returns (address) {
        return getModule(AMM_FACTORY);
    }

    function getOptionFactory() external override view returns (address) {
        return getModule(OPTION_FACTORY);
    }

    function getOptionHelper() external override view returns (address) {
        return getModule(OPTION_HELPER);
    }

    function getOptionPoolRegistry() external override view returns (address) {
        return getModule(OPTION_POOL_REGISTRY);
    }

    function owner() public override(Ownable, IConfigurationManager) view returns (address) {
        return super.owner();
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IEmergencyStop.sol";

/**
 * @title EmergencyStop
 * @author Pods Finance
 * @notice Keeps the addresses of stopped contracts, so contracts can be aware
 * of which functions to interrupt temporarily
 */
contract EmergencyStop is IEmergencyStop, Ownable {
    mapping(address => bool) private _addresses;

    event Stopped(address indexed target);
    event Resumed(address indexed target);

    /**
     * @dev Signals that the target should now be considered as stopped
     * @param target The contract address
     */
    function stop(address target) external override onlyOwner {
        _addresses[target] = true;
        emit Stopped(target);
    }

    /**
     * @dev Signals that the target should now be considered as fully functional
     * @param target The contract address
     */
    function resume(address target) external override onlyOwner {
        require(_addresses[target], "EmergencyStop: target is not stopped");
        _addresses[target] = false;
        emit Resumed(target);
    }

    /**
     * @dev Checks if a contract should be considered as stopped
     * @param target The contract address
     */
    function isStopped(address target) external override view returns (bool) {
        return _addresses[target];
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICapProvider.sol";

/**
 * @title CapProvider
 * @author Pods Finance
 * @notice Keeps the addresses of capped contracts, so contracts can be aware
 * of the max amount allowed of some asset inside the contract
 */
contract CapProvider is ICapProvider, Ownable {
    mapping(address => uint256) private _addresses;

    event SetCap(address indexed target, uint256 value);

    /**
     * @dev Defines a cap value to a contract
     * @param target The contract address
     * @param value Cap amount
     */
    function setCap(address target, uint256 value) external override onlyOwner {
        require(target != address(0), "CapProvider: Invalid target");
        _addresses[target] = value;
        emit SetCap(target, value);
    }

    /**
     * @dev Get the value of a defined cap
     * Note that 0 cap means that the contract is not capped
     * @param target The contract address
     */
    function getCap(address target) external override view returns (uint256) {
        return _addresses[target];
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../interfaces/INormalDistribution.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title NormalDistribution
 * @author Pods Finance
 * @notice Calculates the Cumulative Distribution Function of
 * the standard normal distribution
 */
contract NormalDistribution is INormalDistribution, Ownable {
    using SafeMath for uint256;
    mapping(uint256 => uint256) private _cachedDataPoints;

    event DataPointSet(uint256 key, uint256 value);

    constructor() public {
        _cachedDataPoints[0] = 50000;
        _cachedDataPoints[100] = 50399;
        _cachedDataPoints[200] = 50798;
        _cachedDataPoints[300] = 51197;
        _cachedDataPoints[400] = 51595;
        _cachedDataPoints[500] = 51994;
        _cachedDataPoints[600] = 52392;
        _cachedDataPoints[700] = 52790;
        _cachedDataPoints[800] = 53188;
        _cachedDataPoints[900] = 53586;
        _cachedDataPoints[1000] = 53983;
        _cachedDataPoints[1100] = 54380;
        _cachedDataPoints[1200] = 54776;
        _cachedDataPoints[1300] = 55172;
        _cachedDataPoints[1400] = 55567;
        _cachedDataPoints[1500] = 55962;
        _cachedDataPoints[1600] = 56356;
        _cachedDataPoints[1700] = 56749;
        _cachedDataPoints[1800] = 57142;
        _cachedDataPoints[1900] = 57535;
        _cachedDataPoints[2000] = 57926;
        _cachedDataPoints[2100] = 58317;
        _cachedDataPoints[2200] = 58706;
        _cachedDataPoints[2300] = 59095;
        _cachedDataPoints[2400] = 59483;
        _cachedDataPoints[2500] = 59871;
        _cachedDataPoints[2600] = 60257;
        _cachedDataPoints[2700] = 60642;
        _cachedDataPoints[2800] = 61026;
        _cachedDataPoints[2900] = 61409;
        _cachedDataPoints[3000] = 61791;
        _cachedDataPoints[3100] = 62172;
        _cachedDataPoints[3200] = 62552;
        _cachedDataPoints[3300] = 62930;
        _cachedDataPoints[3400] = 63307;
        _cachedDataPoints[3500] = 63683;
        _cachedDataPoints[3600] = 64058;
        _cachedDataPoints[3700] = 64431;
        _cachedDataPoints[3800] = 64803;
        _cachedDataPoints[3900] = 65173;
        _cachedDataPoints[4000] = 65542;
        _cachedDataPoints[4100] = 65910;
        _cachedDataPoints[4200] = 66276;
        _cachedDataPoints[4300] = 66640;
        _cachedDataPoints[4400] = 67003;
        _cachedDataPoints[4500] = 67364;
        _cachedDataPoints[4600] = 67724;
        _cachedDataPoints[4700] = 68082;
        _cachedDataPoints[4800] = 68439;
        _cachedDataPoints[4900] = 68793;
        _cachedDataPoints[5000] = 69146;
        _cachedDataPoints[5100] = 69497;
        _cachedDataPoints[5200] = 69847;
        _cachedDataPoints[5300] = 70194;
        _cachedDataPoints[5400] = 70540;
        _cachedDataPoints[5500] = 70884;
        _cachedDataPoints[5600] = 71226;
        _cachedDataPoints[5700] = 71566;
        _cachedDataPoints[5800] = 71904;
        _cachedDataPoints[5900] = 72240;
        _cachedDataPoints[6000] = 72575;
        _cachedDataPoints[6100] = 72907;
        _cachedDataPoints[6200] = 73237;
        _cachedDataPoints[6300] = 73565;
        _cachedDataPoints[6400] = 73891;
        _cachedDataPoints[6500] = 74215;
        _cachedDataPoints[6600] = 74537;
        _cachedDataPoints[6700] = 74857;
        _cachedDataPoints[6800] = 75175;
        _cachedDataPoints[6900] = 75490;
        _cachedDataPoints[7000] = 75804;
        _cachedDataPoints[7100] = 76115;
        _cachedDataPoints[7200] = 76424;
        _cachedDataPoints[7300] = 76730;
        _cachedDataPoints[7400] = 77035;
        _cachedDataPoints[7500] = 77337;
        _cachedDataPoints[7600] = 77637;
        _cachedDataPoints[7700] = 77935;
        _cachedDataPoints[7800] = 78230;
        _cachedDataPoints[7900] = 78524;
        _cachedDataPoints[8000] = 78814;
        _cachedDataPoints[8100] = 79103;
        _cachedDataPoints[8200] = 79389;
        _cachedDataPoints[8300] = 79673;
        _cachedDataPoints[8400] = 79955;
        _cachedDataPoints[8500] = 80234;
        _cachedDataPoints[8600] = 80511;
        _cachedDataPoints[8700] = 80785;
        _cachedDataPoints[8800] = 81057;
        _cachedDataPoints[8900] = 81327;
        _cachedDataPoints[9000] = 81594;
        _cachedDataPoints[9100] = 81859;
        _cachedDataPoints[9200] = 82121;
        _cachedDataPoints[9300] = 82381;
        _cachedDataPoints[9400] = 82639;
        _cachedDataPoints[9500] = 82894;
        _cachedDataPoints[9600] = 83147;
        _cachedDataPoints[9700] = 83398;
        _cachedDataPoints[9800] = 83646;
        _cachedDataPoints[9900] = 83891;
        _cachedDataPoints[10000] = 84134;
        _cachedDataPoints[10100] = 84375;
        _cachedDataPoints[10200] = 84614;
        _cachedDataPoints[10300] = 84849;
        _cachedDataPoints[10400] = 85083;
        _cachedDataPoints[10500] = 85314;
        _cachedDataPoints[10600] = 85543;
        _cachedDataPoints[10700] = 85769;
        _cachedDataPoints[10800] = 85993;
        _cachedDataPoints[10900] = 86214;
        _cachedDataPoints[11000] = 86433;
        _cachedDataPoints[11100] = 86650;
        _cachedDataPoints[11200] = 86864;
        _cachedDataPoints[11300] = 87076;
        _cachedDataPoints[11400] = 87286;
        _cachedDataPoints[11500] = 87493;
        _cachedDataPoints[11600] = 87698;
        _cachedDataPoints[11700] = 87900;
        _cachedDataPoints[11800] = 88100;
        _cachedDataPoints[11900] = 88298;
        _cachedDataPoints[12000] = 88493;
        _cachedDataPoints[12100] = 88686;
        _cachedDataPoints[12200] = 88877;
        _cachedDataPoints[12300] = 89065;
        _cachedDataPoints[12400] = 89251;
        _cachedDataPoints[12500] = 89435;
        _cachedDataPoints[12600] = 89617;
        _cachedDataPoints[12700] = 89796;
        _cachedDataPoints[12800] = 89973;
        _cachedDataPoints[12900] = 90147;
        _cachedDataPoints[13000] = 90320;
        _cachedDataPoints[13100] = 90490;
        _cachedDataPoints[13200] = 90658;
        _cachedDataPoints[13300] = 90824;
        _cachedDataPoints[13400] = 90988;
        _cachedDataPoints[13500] = 91149;
        _cachedDataPoints[13600] = 91309;
        _cachedDataPoints[13700] = 91466;
        _cachedDataPoints[13800] = 91621;
        _cachedDataPoints[13900] = 91774;
        _cachedDataPoints[14000] = 91924;
        _cachedDataPoints[14100] = 92073;
        _cachedDataPoints[14200] = 92220;
        _cachedDataPoints[14300] = 92364;
        _cachedDataPoints[14400] = 92507;
        _cachedDataPoints[14500] = 92647;
        _cachedDataPoints[14600] = 92785;
        _cachedDataPoints[14700] = 92922;
        _cachedDataPoints[14800] = 93056;
        _cachedDataPoints[14900] = 93189;
        _cachedDataPoints[15000] = 93319;
        _cachedDataPoints[15100] = 93448;
        _cachedDataPoints[15200] = 93574;
        _cachedDataPoints[15300] = 93699;
        _cachedDataPoints[15400] = 93822;
        _cachedDataPoints[15500] = 93943;
        _cachedDataPoints[15600] = 94062;
        _cachedDataPoints[15700] = 94179;
        _cachedDataPoints[15800] = 94295;
        _cachedDataPoints[15900] = 94408;
        _cachedDataPoints[16000] = 94520;
        _cachedDataPoints[16100] = 94630;
        _cachedDataPoints[16200] = 94738;
        _cachedDataPoints[16300] = 94845;
        _cachedDataPoints[16400] = 94950;
        _cachedDataPoints[16500] = 95053;
        _cachedDataPoints[16600] = 95154;
        _cachedDataPoints[16700] = 95254;
        _cachedDataPoints[16800] = 95352;
        _cachedDataPoints[16900] = 95449;
        _cachedDataPoints[17000] = 95543;
        _cachedDataPoints[17100] = 95637;
        _cachedDataPoints[17200] = 95728;
        _cachedDataPoints[17300] = 95818;
        _cachedDataPoints[17400] = 95907;
        _cachedDataPoints[17500] = 95994;
        _cachedDataPoints[17600] = 96080;
        _cachedDataPoints[17700] = 96164;
        _cachedDataPoints[17800] = 96246;
        _cachedDataPoints[17900] = 96327;
        _cachedDataPoints[18000] = 96407;
        _cachedDataPoints[18100] = 96485;
        _cachedDataPoints[18200] = 96562;
        _cachedDataPoints[18300] = 96638;
        _cachedDataPoints[18400] = 96712;
        _cachedDataPoints[18500] = 96784;
        _cachedDataPoints[18600] = 96856;
        _cachedDataPoints[18700] = 96926;
        _cachedDataPoints[18800] = 96995;
        _cachedDataPoints[18900] = 97062;
        _cachedDataPoints[19000] = 97128;
        _cachedDataPoints[19100] = 97193;
        _cachedDataPoints[19200] = 97257;
        _cachedDataPoints[19300] = 97320;
        _cachedDataPoints[19400] = 97381;
        _cachedDataPoints[19500] = 97441;
        _cachedDataPoints[19600] = 97500;
        _cachedDataPoints[19700] = 97558;
        _cachedDataPoints[19800] = 97615;
        _cachedDataPoints[19900] = 97670;
        _cachedDataPoints[20000] = 97725;
        _cachedDataPoints[20100] = 97778;
        _cachedDataPoints[20200] = 97831;
        _cachedDataPoints[20300] = 97882;
        _cachedDataPoints[20400] = 97932;
        _cachedDataPoints[20500] = 97982;
        _cachedDataPoints[20600] = 98030;
        _cachedDataPoints[20700] = 98077;
        _cachedDataPoints[20800] = 98124;
        _cachedDataPoints[20900] = 98169;
        _cachedDataPoints[21000] = 98214;
        _cachedDataPoints[21100] = 98257;
        _cachedDataPoints[21200] = 98300;
        _cachedDataPoints[21300] = 98341;
        _cachedDataPoints[21400] = 98382;
        _cachedDataPoints[21500] = 98422;
        _cachedDataPoints[21600] = 98461;
        _cachedDataPoints[21700] = 98500;
        _cachedDataPoints[21800] = 98537;
        _cachedDataPoints[21900] = 98574;
        _cachedDataPoints[22000] = 98610;
        _cachedDataPoints[22100] = 98645;
        _cachedDataPoints[22200] = 98679;
        _cachedDataPoints[22300] = 98713;
        _cachedDataPoints[22400] = 98745;
        _cachedDataPoints[22500] = 98778;
        _cachedDataPoints[22600] = 98809;
        _cachedDataPoints[22700] = 98840;
        _cachedDataPoints[22800] = 98870;
        _cachedDataPoints[22900] = 98899;
        _cachedDataPoints[23000] = 98928;
        _cachedDataPoints[23100] = 98956;
        _cachedDataPoints[23200] = 98983;
        _cachedDataPoints[23300] = 99010;
        _cachedDataPoints[23400] = 99036;
        _cachedDataPoints[23500] = 99061;
        _cachedDataPoints[23600] = 99086;
        _cachedDataPoints[23700] = 99111;
        _cachedDataPoints[23800] = 99134;
        _cachedDataPoints[23900] = 99158;
        _cachedDataPoints[24000] = 99180;
        _cachedDataPoints[24100] = 99202;
        _cachedDataPoints[24200] = 99224;
        _cachedDataPoints[24300] = 99245;
        _cachedDataPoints[24400] = 99266;
        _cachedDataPoints[24500] = 99286;
        _cachedDataPoints[24600] = 99305;
        _cachedDataPoints[24700] = 99324;
        _cachedDataPoints[24800] = 99343;
        _cachedDataPoints[24900] = 99361;
        _cachedDataPoints[25000] = 99379;
        _cachedDataPoints[25100] = 99396;
        _cachedDataPoints[25200] = 99413;
        _cachedDataPoints[25300] = 99430;
        _cachedDataPoints[25400] = 99446;
        _cachedDataPoints[25500] = 99461;
        _cachedDataPoints[25600] = 99477;
        _cachedDataPoints[25700] = 99492;
        _cachedDataPoints[25800] = 99506;
        _cachedDataPoints[25900] = 99520;
        _cachedDataPoints[26000] = 99534;
        _cachedDataPoints[26100] = 99547;
        _cachedDataPoints[26200] = 99560;
        _cachedDataPoints[26300] = 99573;
        _cachedDataPoints[26400] = 99585;
        _cachedDataPoints[26500] = 99598;
        _cachedDataPoints[26600] = 99609;
        _cachedDataPoints[26700] = 99621;
        _cachedDataPoints[26800] = 99632;
        _cachedDataPoints[26900] = 99643;
        _cachedDataPoints[27000] = 99653;
        _cachedDataPoints[27100] = 99664;
        _cachedDataPoints[27200] = 99674;
        _cachedDataPoints[27300] = 99683;
        _cachedDataPoints[27400] = 99693;
        _cachedDataPoints[27500] = 99702;
        _cachedDataPoints[27600] = 99711;
        _cachedDataPoints[27700] = 99720;
        _cachedDataPoints[27800] = 99728;
        _cachedDataPoints[27900] = 99736;
        _cachedDataPoints[28000] = 99744;
        _cachedDataPoints[28100] = 99752;
        _cachedDataPoints[28200] = 99760;
        _cachedDataPoints[28300] = 99767;
        _cachedDataPoints[28400] = 99774;
        _cachedDataPoints[28500] = 99781;
        _cachedDataPoints[28600] = 99788;
        _cachedDataPoints[28700] = 99795;
        _cachedDataPoints[28800] = 99801;
        _cachedDataPoints[28900] = 99807;
        _cachedDataPoints[29000] = 99813;
        _cachedDataPoints[29100] = 99819;
        _cachedDataPoints[29200] = 99825;
        _cachedDataPoints[29300] = 99831;
        _cachedDataPoints[29400] = 99836;
        _cachedDataPoints[29500] = 99841;
        _cachedDataPoints[29600] = 99846;
        _cachedDataPoints[29700] = 99851;
        _cachedDataPoints[29800] = 99856;
        _cachedDataPoints[29900] = 99861;
        _cachedDataPoints[30000] = 99865;
        _cachedDataPoints[30100] = 99869;
        _cachedDataPoints[30200] = 99874;
        _cachedDataPoints[30300] = 99878;
        _cachedDataPoints[30400] = 99882;
        _cachedDataPoints[30500] = 99886;
        _cachedDataPoints[30600] = 99889;
        _cachedDataPoints[30700] = 99893;
        _cachedDataPoints[30800] = 99896;
        _cachedDataPoints[30900] = 99900;
        _cachedDataPoints[31000] = 99903;
        _cachedDataPoints[31100] = 99906;
        _cachedDataPoints[31200] = 99910;
        _cachedDataPoints[31300] = 99913;
        _cachedDataPoints[31400] = 99916;
        _cachedDataPoints[31500] = 99918;
        _cachedDataPoints[31600] = 99921;
        _cachedDataPoints[31700] = 99924;
        _cachedDataPoints[31800] = 99926;
        _cachedDataPoints[31900] = 99929;
        _cachedDataPoints[32000] = 99931;
        _cachedDataPoints[32100] = 99934;
        _cachedDataPoints[32200] = 99936;
        _cachedDataPoints[32300] = 99938;
        _cachedDataPoints[32400] = 99940;
        _cachedDataPoints[32500] = 99942;
        _cachedDataPoints[32600] = 99944;
        _cachedDataPoints[32700] = 99946;
        _cachedDataPoints[32800] = 99948;
        _cachedDataPoints[32900] = 99950;
        _cachedDataPoints[33000] = 99952;
        _cachedDataPoints[33100] = 99953;
        _cachedDataPoints[33200] = 99955;
        _cachedDataPoints[33300] = 99957;
        _cachedDataPoints[33400] = 99958;
        _cachedDataPoints[33500] = 99960;
        _cachedDataPoints[33600] = 99961;
        _cachedDataPoints[33700] = 99962;
        _cachedDataPoints[33800] = 99964;
        _cachedDataPoints[33900] = 99965;
        _cachedDataPoints[34000] = 99966;
        _cachedDataPoints[34100] = 99968;
        _cachedDataPoints[34200] = 99969;
        _cachedDataPoints[34300] = 99970;
        _cachedDataPoints[34400] = 99971;
        _cachedDataPoints[34500] = 99972;
        _cachedDataPoints[34600] = 99973;
        _cachedDataPoints[34700] = 99974;
        _cachedDataPoints[34800] = 99975;
        _cachedDataPoints[34900] = 99976;
        _cachedDataPoints[35000] = 99977;
        _cachedDataPoints[35100] = 99978;
        _cachedDataPoints[35200] = 99978;
        _cachedDataPoints[35300] = 99979;
        _cachedDataPoints[35400] = 99980;
        _cachedDataPoints[35500] = 99981;
        _cachedDataPoints[35600] = 99981;
        _cachedDataPoints[35700] = 99982;
        _cachedDataPoints[35800] = 99983;
        _cachedDataPoints[35900] = 99983;
        _cachedDataPoints[36000] = 99984;
        _cachedDataPoints[36100] = 99985;
        _cachedDataPoints[36200] = 99985;
        _cachedDataPoints[36300] = 99986;
        _cachedDataPoints[36400] = 99986;
        _cachedDataPoints[36500] = 99987;
        _cachedDataPoints[36600] = 99987;
        _cachedDataPoints[36700] = 99988;
        _cachedDataPoints[36800] = 99988;
        _cachedDataPoints[36900] = 99989;
        _cachedDataPoints[37000] = 99989;
        _cachedDataPoints[37100] = 99990;
        _cachedDataPoints[37200] = 99990;
        _cachedDataPoints[37300] = 99990;
        _cachedDataPoints[37400] = 99991;
        _cachedDataPoints[37500] = 99991;
        _cachedDataPoints[37600] = 99992;
        _cachedDataPoints[37700] = 99992;
        _cachedDataPoints[37800] = 99992;
        _cachedDataPoints[37900] = 99992;
        _cachedDataPoints[38000] = 99993;
        _cachedDataPoints[38100] = 99993;
        _cachedDataPoints[38200] = 99993;
        _cachedDataPoints[38300] = 99994;
        _cachedDataPoints[38400] = 99994;
        _cachedDataPoints[38500] = 99994;
        _cachedDataPoints[38600] = 99994;
        _cachedDataPoints[38700] = 99995;
        _cachedDataPoints[38800] = 99995;
        _cachedDataPoints[38900] = 99995;
        _cachedDataPoints[39000] = 99995;
        _cachedDataPoints[39100] = 99995;
        _cachedDataPoints[39200] = 99996;
        _cachedDataPoints[39300] = 99996;
        _cachedDataPoints[39400] = 99996;
        _cachedDataPoints[39500] = 99996;
        _cachedDataPoints[39600] = 99996;
        _cachedDataPoints[39700] = 99996;
    }

    /**
     * @notice Returns probability approximations of Z in a normal distribution curve
     * @dev For performance, numbers are truncated to 2 decimals. Ex: 1134500000000000000(1.13) gets truncated to 113
     * @dev For Z > ±0.307 the curve response gets more concentrated, hence some predefined answers can be
     * given for a few sets of z. Otherwise it will calculate a median answer between the saved data points
     * @param z A point in the normal distribution
     * @param decimals Amount of decimals of z
     * @return The probability of a z variable in a normal distribution
     */
    function getProbability(int256 z, uint256 decimals) external override view returns (uint256) {
        require(decimals >= 5 && decimals < 77, "NormalDistribution: invalid decimals");
        uint256 absZ = _abs(z);
        uint256 truncatedZ = absZ.div(10**(decimals.sub(2))).mul(100);
        uint256 fourthDigit = absZ.div(10**(decimals.sub(3))) - absZ.div(10**(decimals.sub(2))).mul(10);
        uint256 responseDecimals = 10**(decimals.sub(5));
        uint256 responseValue;

        if (truncatedZ >= 41900) {
            // Over 4.18 the answer is rounded to 0.99999
            responseValue = 99999;
        } else if (truncatedZ >= 40600) {
            // Between 4.06 and 4.17 the answer is rounded to 0.99998
            responseValue = 99998;
        } else if (truncatedZ >= 39800) {
            // Between 3.98 and 4.05 the answer is rounded to 0.99997
            responseValue = 99997;
        } else if (fourthDigit >= 7) {
            // If the fourthDigit is 7, 8 or 9, rounds up to the next data point
            responseValue = _cachedDataPoints[truncatedZ + 100];
        } else if (fourthDigit >= 4) {
            // If the fourthDigit is 4, 5 or 6, get the average between the current and the next
            responseValue = _cachedDataPoints[truncatedZ].add(_cachedDataPoints[truncatedZ + 100]).div(2);
        } else {
            // If the fourthDigit is 0, 1, 2 or 3, rounds down to the current data point
            responseValue = _cachedDataPoints[truncatedZ];
        }

        // Handle negative z
        if (z < 0) {
            responseValue = uint256(100000).sub(responseValue);
        }

        return responseValue.mul(responseDecimals);
    }

    /**
     * @dev Defines a new probability point
     * @param key A point in the normal distribution
     * @param value The value
     */
    function setDataPoint(uint256 key, uint256 value) external override onlyOwner {
        _cachedDataPoints[key] = value;
        emit DataPointSet(key, value);
    }

    /**
     * @dev Returns the absolute value of a number.
     */
    function _abs(int256 a) internal pure returns (uint256) {
        return a < 0 ? uint256(-a) : uint256(a);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.12;

interface INormalDistribution {
    function getProbability(int256 z, uint256 decimals) external view returns (uint256);

    function setDataPoint(uint256 key, uint256 value) external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IBlackScholes.sol";
import "../interfaces/IPodOption.sol";
import "../interfaces/IIVGuesser.sol";
import "../interfaces/IConfigurationManager.sol";

contract IVGuesser is IIVGuesser {
    using SafeMath for uint256;
    IBlackScholes private immutable _blackScholes;

    /**
     * @dev store globally accessed configurations
     */
    IConfigurationManager public immutable configurationManager;

    /**
     * @dev numerical method's acceptable range
     */
    uint256 public acceptableRange;

    /**
     * @dev Min numerical method's acceptable range
     */
    uint256 public constant MIN_ACCEPTABLE_RANGE = 10; //10%

    struct Boundaries {
        uint256 ivLower;
        uint256 priceLower;
        uint256 ivHigher;
        uint256 priceHigher;
    }

    constructor(IConfigurationManager _configurationManager, address blackScholes) public {
        require(blackScholes != address(0), "IV: Invalid blackScholes");

        configurationManager = _configurationManager;

        acceptableRange = _configurationManager.getParameter("GUESSER_ACCEPTABLE_RANGE");

        require(acceptableRange >= MIN_ACCEPTABLE_RANGE, "IV: Invalid acceptableRange");

        _blackScholes = IBlackScholes(blackScholes);
    }

    function blackScholes() external override view returns (address) {
        return address(_blackScholes);
    }

    function getPutIV(
        uint256 _targetPrice,
        uint256 _initialIVGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree
    ) external override view returns (uint256 calculatedIV, uint256 calculatedPrice) {
        (calculatedIV, calculatedPrice) = getApproximatedIV(
            _targetPrice,
            _initialIVGuess,
            _spotPrice,
            _strikePrice,
            _timeToMaturity,
            _riskFree,
            IPodOption.OptionType.PUT
        );
        return (calculatedIV, calculatedPrice);
    }

    function getCallIV(
        uint256 _targetPrice,
        uint256 _initialIVGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree
    ) external override view returns (uint256 calculatedIV, uint256 calculatedPrice) {
        (calculatedIV, calculatedPrice) = getApproximatedIV(
            _targetPrice,
            _initialIVGuess,
            _spotPrice,
            _strikePrice,
            _timeToMaturity,
            _riskFree,
            IPodOption.OptionType.CALL
        );
        return (calculatedIV, calculatedPrice);
    }

    function getCloserIV(Boundaries memory boundaries, uint256 targetPrice) external pure returns (uint256) {
        return _getCloserIV(boundaries, targetPrice);
    }

    /**
     * Get an approximation of implied volatility given a target price inside an error range
     *
     * @param _targetPrice The target price that we need to find the implied volatility for
     * @param _initialIVGuess Implied Volatility guess in order to reduce gas costs
     * @param _spotPrice Current spot price of the underlying
     * @param _strikePrice Option strike price
     * @param _timeToMaturity Annualized time to maturity
     * @param _riskFree The risk-free rate
     * @param _optionType the option type (0 for PUt, 1 for Call)
     * @return calculatedIV The new implied volatility found given _targetPrice and inside ACCEPTABLE_ERROR
     * @return calculatedPrice That is the real price found, in the best scenario, calculated price should
     * be equal to _targetPrice
     */
    function getApproximatedIV(
        uint256 _targetPrice,
        uint256 _initialIVGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree,
        IPodOption.OptionType _optionType
    ) public view returns (uint256 calculatedIV, uint256 calculatedPrice) {
        require(_initialIVGuess > 0, "IV: initial guess should be greater than zero");
        uint256 calculatedInitialPrice = _getPrice(
            _spotPrice,
            _strikePrice,
            _initialIVGuess,
            _timeToMaturity,
            _riskFree,
            _optionType
        );
        if (_equalEnough(_targetPrice, calculatedInitialPrice, acceptableRange)) {
            return (_initialIVGuess, calculatedInitialPrice);
        } else {
            Boundaries memory boundaries = _getInitialBoundaries(
                _targetPrice,
                calculatedInitialPrice,
                _initialIVGuess,
                _spotPrice,
                _strikePrice,
                _timeToMaturity,
                _riskFree,
                _optionType
            );
            calculatedIV = _getCloserIV(boundaries, _targetPrice);
            calculatedPrice = _getPrice(
                _spotPrice,
                _strikePrice,
                calculatedIV,
                _timeToMaturity,
                _riskFree,
                _optionType
            );

            while (_equalEnough(_targetPrice, calculatedPrice, acceptableRange) == false) {
                if (calculatedPrice < _targetPrice) {
                    boundaries.priceLower = calculatedPrice;
                    boundaries.ivLower = calculatedIV;
                } else {
                    boundaries.priceHigher = calculatedPrice;
                    boundaries.ivHigher = calculatedIV;
                }
                calculatedIV = _getCloserIV(boundaries, _targetPrice);

                calculatedPrice = _getPrice(
                    _spotPrice,
                    _strikePrice,
                    calculatedIV,
                    _timeToMaturity,
                    _riskFree,
                    _optionType
                );
            }
            return (calculatedIV, calculatedPrice);
        }
    }

    /**********************************************************************************************
    // Each time you run this function, returns you a closer implied volatility value to          //
    // the target price p0 getCloserIV                                                            //
    // sL = IVLower                                                                               //
    // sH = IVHigher                                    ( sH - sL )                               //
    // pL = priceLower          sN = sL + ( p0 - pL ) * -----------                               //
    // pH = priceHigher                                 ( pH - pL )                               //
    // p0 = targetPrice                                                                           //
    // sN = IVNext                                                                                //
    **********************************************************************************************/
    function _getCloserIV(Boundaries memory boundaries, uint256 targetPrice) internal pure returns (uint256) {
        uint256 numerator = targetPrice.sub(boundaries.priceLower).mul(boundaries.ivHigher.sub(boundaries.ivLower));
        uint256 denominator = boundaries.priceHigher.sub(boundaries.priceLower);

        uint256 result = numerator.div(denominator);
        uint256 nextIV = boundaries.ivLower.add(result);
        return nextIV;
    }

    function _getPrice(
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 calculatedIV,
        uint256 _timeToMaturity,
        int256 _riskFree,
        IPodOption.OptionType _optionType
    ) internal view returns (uint256 price) {
        if (_optionType == IPodOption.OptionType.PUT) {
            price = _blackScholes.getPutPrice(_spotPrice, _strikePrice, calculatedIV, _timeToMaturity, _riskFree);
        } else {
            price = _blackScholes.getCallPrice(_spotPrice, _strikePrice, calculatedIV, _timeToMaturity, _riskFree);
        }
        return price;
    }

    function _equalEnough(
        uint256 target,
        uint256 value,
        uint256 range
    ) internal pure returns (bool) {
        uint256 proportion = target / range;
        if (target > value) {
            uint256 diff = target - value;
            return diff <= proportion;
        } else {
            uint256 diff = value - target;
            return diff <= proportion;
        }
    }

    function _getInitialBoundaries(
        uint256 _targetPrice,
        uint256 initialPrice,
        uint256 initialIV,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree,
        IPodOption.OptionType _optionType
    ) internal view returns (Boundaries memory b) {
        b.ivLower = 0;
        b.priceLower = 0;
        uint256 newGuessPrice = initialPrice;
        uint256 newGuessIV = initialIV;

        // nextGuessIV = nextTryPrice
        while (newGuessPrice < _targetPrice) {
            b.ivLower = newGuessIV;
            b.priceLower = newGuessPrice;

            // it keep increasing the currentIV in 150% until it finds a new higher boundary
            newGuessIV = newGuessIV.add(newGuessIV.div(2));
            newGuessPrice = _getPrice(_spotPrice, _strikePrice, newGuessIV, _timeToMaturity, _riskFree, _optionType);
        }
        b.ivHigher = newGuessIV;
        b.priceHigher = newGuessPrice;
    }

    /**
     * @notice Update acceptableRange calling configuratorManager
     */
    function updateAcceptableRange() external override {
        acceptableRange = configurationManager.getParameter("GUESSER_ACCEPTABLE_RANGE");
        require(acceptableRange >= MIN_ACCEPTABLE_RANGE, "IV: Invalid acceptableRange");
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../lib/CombinedActionsGuard.sol";

contract FlashloanSample is CombinedActionsGuard {
    uint256 public interactions = 0;

    function one() public {
        _nonCombinedActions();
        interactions += 1;
    }

    function two() public {
        _nonCombinedActions();
        interactions += 1;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../interfaces/IPriceFeed.sol";
import "../interfaces/IChainlinkPriceFeed.sol";

/**
 * @title ChainlinkPriceFeed
 * @author Pods Finance
 * @notice Facade to Chainlink Aggregators
 */
contract ChainlinkPriceFeed is IPriceFeed {
    address public chainlinkFeedAddress;

    constructor(address _source) public {
        require(_source != address(0), "ChainlinkPriceFeed: Invalid source");
        chainlinkFeedAddress = _source;
    }

    /**
     * @dev Get the latest price
     */
    function getLatestPrice() external override view returns (int256, uint256) {
        (, int256 price, , uint256 lastUpdate, ) = IChainlinkPriceFeed(chainlinkFeedAddress).latestRoundData();
        return (price, lastUpdate);
    }

    /**
     * @dev Get the latest round data
     */
    function latestRoundData()
        external
        override
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return IChainlinkPriceFeed(chainlinkFeedAddress).latestRoundData();
    }

    /**
     * @dev Get asset decimals
     */
    function decimals() external override view returns (uint8) {
        return IChainlinkPriceFeed(chainlinkFeedAddress).decimals();
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IChainlinkPriceFeed {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../interfaces/IPriceFeed.sol";

contract MockChainlinkFeed is IPriceFeed {
    uint8 private _decimals;
    int256 private _currentPrice;
    uint256 private _updatedAt;
    address public assetFeed;

    constructor(
        address _assetFeed,
        uint8 _answerDecimals,
        int256 _initialPrice
    ) public {
        _decimals = _answerDecimals;
        _currentPrice = _initialPrice;
        assetFeed = _assetFeed;
        _updatedAt = block.timestamp;
    }

    function setPrice(int256 newPrice) external returns (int256) {
        _currentPrice = newPrice;
        _updatedAt = block.timestamp;
        return _currentPrice;
    }

    function getLatestPrice() external override view returns (int256, uint256) {
        return (_currentPrice, _updatedAt);
    }

    function latestRoundData()
        external
        override
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, _currentPrice, 1, _updatedAt, uint80(_currentPrice));
    }

    function decimals() external override view returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../PodPut.sol";
import "../../interfaces/IPodOption.sol";
import "../../interfaces/IOptionBuilder.sol";

/**
 * @title PodPutBuilder
 * @author Pods Finance
 * @notice Builds PodPut options
 */
contract PodPutBuilder is IOptionBuilder {
    /**
     * @notice creates a new PodPut Contract
     * @param name The option token name. Eg. "Pods Put WBTC-USDC 5000 2020-02-23"
     * @param symbol The option token symbol. Eg. "podWBTC:20AA"
     * @param exerciseType The option exercise type. Eg. "0 for European, 1 for American"
     * @param underlyingAsset The underlying asset. Eg. "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
     * @param strikeAsset The strike asset. Eg. "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
     * @param strikePrice The option strike price including decimals. e.g. 5000000000
     * @param expiration The Expiration Option date in seconds. e.g. 1600178324
     * @param exerciseWindowSize The Expiration Window Size duration in seconds. E.g 24*60*60 (24h)
     */
    function buildOption(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    ) external override returns (IPodOption) {
        PodPut option = new PodPut(
            name,
            symbol,
            exerciseType,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        );

        return option;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MintableERC20.sol";

/**
 * @title ERC20Mintable
 * @dev ERC20 with mint function
 */
contract MintableInterestBearing is MintableERC20 {
    uint256 lastUpdate;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public MintableERC20(name, symbol, decimals) {
        lastUpdate = block.number;
    }

    function earnInterest(address owner) public {
        uint256 currentBalance = this.balanceOf(owner);
        uint256 earnedInterest = currentBalance.div(uint256(100));
        _mint(owner, earnedInterest);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20Mintable
 * @dev ERC20 with mint function
 */
contract MintableERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public ERC20(name, symbol) {
        _setupDecimals(decimals);
    }

    function mint(uint256 amount) public returns (bool) {
        _mint(msg.sender, amount);
        return true;
    }

    function burn(uint256 amount) public returns(bool) {
        _burn(msg.sender, amount);
        return true;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../interfaces/IERC20Mintable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface LendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

contract FaucetMumbai {
    using SafeMath for uint256;
    LendingPool private _lendingPool = LendingPool(0x9198F13B08E299d85E096929fA9781A1E3d5d827);
    IERC20Mintable private _usdc = IERC20Mintable(0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e);
    IERC20Mintable private _dai = IERC20Mintable(0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F);
    IERC20Mintable private _weth = IERC20Mintable(0x2f9374157Ef337620b19a720019A6FDB0593d20B);

    function getFaucet() external {
        uint256 askedAmount = 5000;

        // Mint USDC and aUSDC
        uint8 usdcDecimals = _usdc.decimals();
        uint256 mintedUsdcAmount = askedAmount.mul(10**uint256(usdcDecimals));
        _usdc.mint(mintedUsdcAmount);
        _usdc.transfer(msg.sender, mintedUsdcAmount.div(2));
        _usdc.approve(address(_lendingPool), mintedUsdcAmount.div(2));
        _lendingPool.deposit(address(_usdc), mintedUsdcAmount.div(2), msg.sender, 0);

        // Mint DAI and aDAI
        uint8 daiDecimals = _dai.decimals();
        uint256 mintedDaiAmount = askedAmount.mul(10**uint256(daiDecimals));
        _dai.mint(mintedDaiAmount);
        _dai.transfer(msg.sender, mintedDaiAmount.div(2));
        _dai.approve(address(_lendingPool), mintedDaiAmount.div(2));
        _lendingPool.deposit(address(_dai), mintedDaiAmount.div(2), msg.sender, 0);

        // Mint WETH
        uint256 askedWethAmount = 10 ether;
        _weth.mint(askedWethAmount);
        _weth.transfer(msg.sender, askedWethAmount);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IERC20Mintable {
    function mint(uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../interfaces/IERC20Mintable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface LendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

contract FaucetKovan {
    using SafeMath for uint256;
    LendingPool private _lendingPool = LendingPool(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
    IERC20Mintable private _usdc = IERC20Mintable(0xe22da380ee6B445bb8273C81944ADEB6E8450422);
    IERC20Mintable private _dai = IERC20Mintable(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD);
    IERC20Mintable private _wbtc = IERC20Mintable(0x351a448d49C8011D293e81fD53ce5ED09F433E4c);
    IERC20Mintable private _link = IERC20Mintable(0xbA74882beEe5482EbBA7475A0C5A51589d4ed5De);

    function getFaucet() external {
        uint256 askedAmount = 5000;

        // Mint USDC and aUSDC
        uint8 usdcDecimals = _usdc.decimals();
        uint256 mintedUsdcAmount = askedAmount.mul(10**uint256(usdcDecimals));
        _usdc.mint(mintedUsdcAmount);
        _usdc.transfer(msg.sender, mintedUsdcAmount.div(2));
        _usdc.approve(address(_lendingPool), mintedUsdcAmount.div(2));
        _lendingPool.deposit(address(_usdc), mintedUsdcAmount.div(2), msg.sender, 0);

        // Mint DAI and aDAI
        uint8 daiDecimals = _dai.decimals();
        uint256 mintedDaiAmount = askedAmount.mul(10**uint256(daiDecimals));
        _dai.mint(mintedDaiAmount);
        _dai.transfer(msg.sender, mintedDaiAmount.div(2));
        _dai.approve(address(_lendingPool), mintedDaiAmount.div(2));
        _lendingPool.deposit(address(_dai), mintedDaiAmount.div(2), msg.sender, 0);

        // Mint WBTC
        uint256 askedWbtcAmount = 5;
        uint8 wbtcDecimals = _wbtc.decimals();
        uint256 mintedWbtcAmount = askedWbtcAmount.mul(10**uint256(wbtcDecimals));

        _wbtc.mint(mintedWbtcAmount);
        _wbtc.transfer(msg.sender, mintedWbtcAmount);

        // Mint LINK
        uint256 askedLinkAmount = 100;
        uint8 linkDecimals = _link.decimals();
        uint256 mintedLinkAmount = askedLinkAmount.mul(10**uint256(linkDecimals));

        _link.mint(mintedLinkAmount);
        _link.transfer(msg.sender, mintedLinkAmount);
    }
}