// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../admin/interfaces/IGovWorldTierLevel.sol";
import "../liquidator/IGovLiquidator.sol";
import "../base/TokenMarketBase.sol";
import "../library/TokenLoanData.sol";
import "../../oracle/IGovPriceConsumer.sol";
import "../../interfaces/IUniswapSwapInterface.sol";
import "../../interfaces/IERC20Extras.sol";
import "../interfaces/ITokenMarketRegistry.sol";
import "../../claimtoken/IGovClaimToken.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IGToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract TokenMarket is
    TokenMarketBase,
    PausableUpgradeable,
    OwnableUpgradeable
{
    //Load library structs into contract
    using TokenLoanData for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address govWorldLiquidator;
    address govWorldTierLevel;
    address govPriceConsumer;
    address govClaimToken;
    address marketRegistry;
    uint256 public loanId;

    mapping(address => uint256) public loanLendLimit;

    function initialize(
        address _govWorldLiquidator,
        address _govWorldTierLevel,
        address _govPriceConsumer,
        address _govClaimToken,
        address _marketRegistry
    ) external initializer {
        __Ownable_init();
        govWorldLiquidator = _govWorldLiquidator;
        govWorldTierLevel = _govWorldTierLevel;
        govPriceConsumer = _govPriceConsumer;
        govClaimToken = _govClaimToken;
        marketRegistry = _marketRegistry;
        loanId = 0;
    }

    modifier onlyLiquidator() {
        require(
            msg.sender == govWorldLiquidator,
            "GTM: Caller not liquidattor"
        );
        _;
    }

    receive() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    @dev function to create Single || Multi Token(ERC20) Loan Offer by the BORROWER
    */
    function createLoan(TokenLoanData.LoanDetails memory loanDetails)
        public
        whenNotPaused
    {
        uint256 newLoanId = loanId + 1;
        require(
            loanDetails.stakedCollateralTokens.length ==
                loanDetails.stakedCollateralAmounts.length &&
                loanDetails.stakedCollateralTokens.length ==
                loanDetails.isMintSp.length,
            "GLM: Tokens and amounts length must be same"
        );
        require(
            TokenLoanData.LoanType.SINGLE_TOKEN == loanDetails.loanType ||
                TokenLoanData.LoanType.MULTI_TOKEN == loanDetails.loanType,
            "GLM: Invalid Loan Type"
        );
        require(
            loanDetails.paybackAmount == 0,
            "GLM: payback amount should be zero"
        );

        require(
            ITokenMarketRegistry(marketRegistry).isStableApproved(
                loanDetails.borrowStableCoin
            ),
            "GTM: not approved stable coin"
        );

        if (TokenLoanData.LoanType.SINGLE_TOKEN == loanDetails.loanType) {
            //for single tokens collateral length must be one.
            require(
                loanDetails.stakedCollateralTokens.length == 1,
                "GLM: Multi-tokens not allowed in SINGLE TOKEN loan type."
            );
        }

        //call internal function to get calculateLTV, getMaxLoanAmount

        (
            uint256 collateralLTVPercentage,
            ,
            uint256 collatetralInBorrowed
        ) = this._getltvCalculations(
                loanDetails.stakedCollateralTokens,
                loanDetails.stakedCollateralAmounts,
                loanDetails.borrowStableCoin,
                loanDetails.loanAmountInBorrowed,
                loanDetails.borrower
            );
        require(
            collateralLTVPercentage >
                ITokenMarketRegistry(marketRegistry).getLTVPercentage(),
            "GLM: Can not create loan at liquidation level."
        );

        uint256 response = IGovWorldTierLevel(govWorldTierLevel)
            .isCreateLoanTokenUnderTier(
                msg.sender,
                loanDetails.loanAmountInBorrowed,
                collatetralInBorrowed,
                loanDetails.stakedCollateralTokens
            );
        require(response == 200, "GLM: Invalid Tier Loan");

        borrowerloanOfferIds[msg.sender].push(newLoanId);
        loanOfferIds.push(newLoanId);
        //loop through all staked collateral tokens.
        for (
            uint256 i = 0;
            i < loanDetails.stakedCollateralTokens.length;
            i++
        ) {
            address claimToken = IGovClaimToken(govClaimToken)
                .getClaimTokenofSUNToken(loanDetails.stakedCollateralTokens[i]);
            require(
                ITokenMarketRegistry(marketRegistry).isTokenApproved(
                    loanDetails.stakedCollateralTokens[i]
                ) || IGovClaimToken(govClaimToken).isClaimToken(claimToken),
                "GLM: One or more tokens not approved."
            );
            require(
                ITokenMarketRegistry(marketRegistry)
                    .isTokenEnabledForCreateLoan(
                        loanDetails.stakedCollateralTokens[i]
                    ),
                "GTM: token not enabled"
            );
            require(loanDetails.isMintSp[i] == false, "GLM: mint error");
            uint256 allowance = IERC20(loanDetails.stakedCollateralTokens[i])
                .allowance(msg.sender, address(this));
            require(
                allowance >= loanDetails.stakedCollateralAmounts[i],
                "GLM: Transfer amount exceeds allowance."
            );
        }

        loanOffersToken[newLoanId] = TokenLoanData.LoanDetails(
            loanDetails.loanAmountInBorrowed,
            loanDetails.termsLengthInDays,
            loanDetails.apyOffer,
            loanDetails.loanType,
            loanDetails.isPrivate,
            loanDetails.isInsured,
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            TokenLoanData.LoanStatus.INACTIVE,
            msg.sender,
            loanDetails.paybackAmount,
            loanDetails.isMintSp
        );

        emit LoanOfferCreatedToken(loanOffersToken[newLoanId]);
        loanId++;
    }

    /**
    @dev function to adjust already created loan offer, while in inactive state
    @param  _loanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    @param _newTermsLengthInDays, borrower changing the loan term in days
    @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    @param _isPrivate, boolena value of true if private otherwise false
    @param _isInsured, isinsured true or false
     */
    function loanAdjusted(
        uint256 _loanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint56 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isPrivate,
        bool _isInsured
    ) public whenNotPaused {
        TokenLoanData.LoanDetails memory loanDetails = loanOffersToken[
            _loanIdAdjusted
        ];

        require(
            loanDetails.loanType == TokenLoanData.LoanType.SINGLE_TOKEN ||
                loanDetails.loanType == TokenLoanData.LoanType.MULTI_TOKEN,
            "GLM: Invalid Loan Type"
        );
        require(
            loanDetails.loanStatus == TokenLoanData.LoanStatus.INACTIVE,
            "GLM, Loan cannot adjusted"
        );
        require(
            loanDetails.borrower == msg.sender,
            "GLM, Only Borrow Adjust Loan"
        );

        (
            uint256 collateralLTVPercentage,
            uint256 maxLoanAmount,
            uint256 collatetralInBorrowed
        ) = this._getltvCalculations(
                loanDetails.stakedCollateralTokens,
                loanDetails.stakedCollateralAmounts,
                loanDetails.borrowStableCoin,
                loanDetails.loanAmountInBorrowed,
                loanDetails.borrower
            );
        uint256 response = IGovWorldTierLevel(govWorldTierLevel)
            .isCreateLoanTokenUnderTier(
                msg.sender,
                _newLoanAmountBorrowed,
                collatetralInBorrowed,
                loanDetails.stakedCollateralTokens
            );
        require(response == 200, "GLM: Invalid Tier Loan");
        require(
            collateralLTVPercentage >
                ITokenMarketRegistry(marketRegistry).getLTVPercentage(),
            "GLM: can not adjust loan to liquidation level."
        );

        require(
            _newLoanAmountBorrowed <= maxLoanAmount,
            "GLM: loan amount not allowed."
        );

        loanDetails = TokenLoanData.LoanDetails(
            _newLoanAmountBorrowed,
            _newTermsLengthInDays,
            _newAPYOffer,
            loanDetails.loanType,
            _isPrivate,
            _isInsured,
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            TokenLoanData.LoanStatus.INACTIVE,
            msg.sender,
            loanDetails.paybackAmount,
            loanDetails.isMintSp
        );

        emit LoanOfferAdjustedToken(loanDetails);
    }

    /**
    @dev function to cancel the created laon offer for token type Single || Multi Token Colletrals
    @param _loanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping
     */
    function loanOfferCancel(uint256 _loanId) public whenNotPaused {
        require(
            loanOffersToken[_loanId].loanType ==
                TokenLoanData.LoanType.SINGLE_TOKEN ||
                loanOffersToken[_loanId].loanType ==
                TokenLoanData.LoanType.MULTI_TOKEN,
            "GLM: Invalid Loan Type"
        );
        require(
            loanOffersToken[_loanId].loanStatus ==
                TokenLoanData.LoanStatus.INACTIVE,
            "GLM, Loan cannot be cancel"
        );
        require(
            loanOffersToken[_loanId].borrower == msg.sender,
            "GLM, Only Borrow can cancel"
        );

        // delete loanOffersToken[_loanId];
        loanOffersToken[_loanId].loanStatus = TokenLoanData
            .LoanStatus
            .CANCELLED;
        emit LoanOfferCancelToken(
            _loanId,
            msg.sender,
            loanOffersToken[_loanId].loanStatus
        );
    }

    /**
    @dev function for lender to activate loan offer by the borrower
    @param loanIds array of loan ids which are going to be activated
    @param stableCoinAmounts amounts of stable coin requested by the borrower for the specific loan Id
    @param _autoSell if autosell, then loan will be autosell at the time of liquidation through the DEX
     */
    function activateLoan(
        uint256[] memory loanIds,
        uint256[] memory stableCoinAmounts,
        bool[] memory _autoSell
    ) public whenNotPaused {
        for (uint256 i = 0; i < loanIds.length; i++) {
            // address claimToken = IGovClaimToken(govClaimToken).getClaimTokenofSUNToken(loanOffersToken[loanIds[i]].stakedCollateralTokens[i]);
            TokenLoanData.LoanDetails memory loanDetails = loanOffersToken[
                loanIds[i]
            ];
            if (
                !ITokenMarketRegistry(marketRegistry)
                    .isWhitelistedForActivation(msg.sender)
            ) {
                require(
                    loanLendLimit[msg.sender] + 1 <=
                        ITokenMarketRegistry(marketRegistry)
                            .getLoanActivateLimitt(),
                    "GTM: you cannot lend more loans"
                );
                loanLendLimit[msg.sender]++;
            }

            if (
                IGovClaimToken(govClaimToken).isClaimToken(
                    IGovClaimToken(govClaimToken).getClaimTokenofSUNToken(
                        loanDetails.stakedCollateralTokens[i]
                    )
                )
            ) {
                require(
                    _autoSell[i] == false,
                    "GTM: autosell should be false for SUN Collateral Token"
                );
            }

            (uint256 collateralLTVPercentage, uint256 maxLoanAmount, ) = this
                ._getltvCalculations(
                    loanDetails.stakedCollateralTokens,
                    loanDetails.stakedCollateralAmounts,
                    loanDetails.borrowStableCoin,
                    loanDetails.loanAmountInBorrowed,
                    loanDetails.borrower
                );

            require(
                collateralLTVPercentage >
                    ITokenMarketRegistry(marketRegistry).getLTVPercentage(),
                "GLM: Can not create loan at liquidation level."
            );

            // if maxLoanAmount is greater then we will keep setting the borrower loan offer amount in the loan Details
            require(maxLoanAmount != 0, "GTM: not eligible for");

            if (maxLoanAmount >= loanDetails.loanAmountInBorrowed) {
                require(
                    loanDetails.loanAmountInBorrowed == stableCoinAmounts[i],
                    "GLM, insufficient amount"
                );
                loanOffersToken[loanIds[i]].loanAmountInBorrowed = stableCoinAmounts[i];
            } else if (maxLoanAmount < loanDetails.loanAmountInBorrowed) {
                // maxLoanAmount is now assigning in the loan Details struct
                loanDetails.loanAmountInBorrowed == maxLoanAmount;
                loanOffersToken[loanIds[i]].loanAmountInBorrowed = maxLoanAmount;
            }

            require(
                loanDetails.loanType == TokenLoanData.LoanType.SINGLE_TOKEN ||
                    loanDetails.loanType == TokenLoanData.LoanType.MULTI_TOKEN,
                "GLM: invalid loan type"
            );
            require(
                loanDetails.loanStatus == TokenLoanData.LoanStatus.INACTIVE,
                "GLM, not inactive"
            );
            require(
                loanDetails.borrower != msg.sender,
                "GLM, self activation forbidden"
            );
            require(
                loanIds.length == stableCoinAmounts.length &&
                    loanIds.length == _autoSell.length,
                "GLM: length not match"
            );

            uint256 apyFee = ITokenMarketRegistry(marketRegistry).getAPYFee(
                loanOffersToken[loanIds[i]].loanAmountInBorrowed,
                loanOffersToken[loanIds[i]].apyOffer,
                loanOffersToken[loanIds[i]].termsLengthInDays
            );
            uint256 platformFee = (loanOffersToken[loanIds[i]]
                .loanAmountInBorrowed *
                (ITokenMarketRegistry(marketRegistry).getGovPlatformFee())) /
                (10000);
            uint256 loanAmountAfterCut = loanOffersToken[loanIds[i]]
                .loanAmountInBorrowed - (apyFee + platformFee);
            stableCoinAPYFeeFromToken[
                loanOffersToken[loanIds[i]].borrowStableCoin
            ] =
                stableCoinAPYFeeFromToken[
                    loanOffersToken[loanIds[i]].borrowStableCoin
                ] +
                (apyFee + platformFee);

            require(
                (apyFee + loanAmountAfterCut + platformFee) ==
                    loanDetails.loanAmountInBorrowed,
                "GLM, invalid amount"
            );
            {
                //checking again the collateral tokens approval from the borrower
                //contract will now hold the staked collateral tokens
                for (
                    uint256 k = 0;
                    k < loanDetails.stakedCollateralTokens.length;
                    k++
                ) {
                    require(
                        IERC20(loanDetails.stakedCollateralTokens[k]).allowance(
                            loanDetails.borrower,
                            address(this)
                        ) >= loanDetails.stakedCollateralAmounts[k],
                        "GLM: Transfer amount exceeds allowance."
                    );

                    IERC20Upgradeable(loanDetails.stakedCollateralTokens[k])
                        .safeTransferFrom(
                            loanDetails.borrower,
                            govWorldLiquidator,
                            loanDetails.stakedCollateralAmounts[k]
                        );
                    {
                        (address gToken, , ) = ITokenMarketRegistry(
                            marketRegistry
                        ).getSingleApproveTokenData(
                                loanOffersToken[loanIds[i]]
                                    .stakedCollateralTokens[k]
                            );
                        if (
                            ITokenMarketRegistry(marketRegistry)
                                .isSynthetticMintOn(
                                    loanOffersToken[loanIds[i]]
                                        .stakedCollateralTokens[k]
                                )
                        ) {
                            IGToken(gToken).mint(
                                loanDetails.borrower,
                                loanDetails.stakedCollateralAmounts[k]
                            );
                            loanDetails.isMintSp[i] = true;
                        }
                    }
                }

                //approving token from the front end
                //keep the APYFEE  to govworld  before  transfering the stable coins to borrower.
                IERC20Upgradeable(loanDetails.borrowStableCoin)
                    .safeTransferFrom(
                        msg.sender,
                        address(this),
                        loanDetails.loanAmountInBorrowed
                    );

                // APY Fee transfer to the liquidator contract
                IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
                    govWorldLiquidator,
                    apyFee
                );

                //loan amount send to borrower
                IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
                    loanDetails.borrower,
                    loanAmountAfterCut
                );

                loanOffersToken[loanIds[i]].loanStatus = TokenLoanData
                    .LoanStatus
                    .ACTIVE;

                //push active loan ids to the lendersactivatedloanIds mapping
                lenderActivatedLoanIds[msg.sender].push(loanIds[i]);

                //activated loan id to the lender details
                activatedLoanOffersFull[loanIds[i]] = TokenLoanData
                    .LenderDetails({
                        lender: msg.sender,
                        activationLoanTimeStamp: block.timestamp,
                        autoSell: _autoSell[i]
                    });
            }

            emit TokenLoanOfferActivated(
                loanIds[i],
                msg.sender,
                stableCoinAmounts[i],
                _autoSell[i]
            );
        }
    }

    function _getltvCalculations(
        address[] memory _stakedCollateralTokens,
        uint256[] memory _stakedCollateralAmount,
        address _borrowStableCoin,
        uint256 _loanAmountinStable,
        address _borrower
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 collatetralInBorrowed = 0;
        IGovPriceConsumer _priceConsumer = IGovPriceConsumer(govPriceConsumer);

        for (
            uint256 index = 0;
            index < _stakedCollateralAmount.length;
            index++
        ) {
            address claimToken = IGovClaimToken(govClaimToken)
                .getClaimTokenofSUNToken(_stakedCollateralTokens[index]);
            if (IGovClaimToken(govClaimToken).isClaimToken(claimToken)) {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        _priceConsumer.getSUNTokenPrice(
                            claimToken,
                            _borrowStableCoin,
                            _stakedCollateralTokens[index],
                            _stakedCollateralAmount[index]
                        )
                    );
            } else {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        _priceConsumer.getAltCoinPriceinStable(
                            _borrowStableCoin,
                            _stakedCollateralTokens[index],
                            _stakedCollateralAmount[index]
                        )
                    );
            }
        }
        uint256 calulatedLTV = _priceConsumer.calculateLTV(
            _stakedCollateralAmount,
            _stakedCollateralTokens,
            _borrowStableCoin,
            _loanAmountinStable
        );
        uint256 maxLoanAmountValue = IGovWorldTierLevel(govWorldTierLevel)
            .getMaxLoanAmountToValue(collatetralInBorrowed, _borrower);

        return (calulatedLTV, maxLoanAmountValue, collatetralInBorrowed);
    }

    function updateLoanStatusonLiquidation(uint256 _loanId)
        external
        override
        onlyLiquidator
    {
        loanOffersToken[_loanId].loanStatus = TokenLoanData
            .LoanStatus
            .LIQUIDATED;
    }

    function updateLoanStatusonPayback(uint256 _loanId)
        external
        override
        onlyLiquidator
    {
        loanOffersToken[_loanId].loanStatus = TokenLoanData.LoanStatus.CLOSED;
    }

    //only super admin can withdraw coins
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public {
        require(
            ITokenMarketRegistry(marketRegistry).isSuperAdminAccess(msg.sender),
            "GTM: Not a Gov Super Admin."
        );
        require(
            _withdrawAmount <= address(this).balance,
            "GTM: Amount Invalid"
        );
        payable(_walletAddress).transfer(_withdrawAmount);
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }

    //only super admin can withdraw tokens
    function withdrawToken(
        address _tokenAddress,
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public {
        require(
            ITokenMarketRegistry(marketRegistry).isSuperAdminAccess(msg.sender),
            "GTM: Not a Gov Super Admin."
        );
        require(
            _withdrawAmount <=
                IERC20Upgradeable(_tokenAddress).balanceOf(address(this)),
            "GTM: Amount Invalid"
        );
        IERC20Upgradeable(_tokenAddress).safeTransfer(
            _walletAddress,
            _withdrawAmount
        );
        emit WithdrawToken(_tokenAddress, _walletAddress, _withdrawAmount);
    }

    /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetails(uint256 _loanId)
        public
        view
        override
        returns (TokenLoanData.LenderDetails memory)
    {
        return activatedLoanOffersFull[_loanId];
    }

    /**
    @dev get loan details of the single or multi-token
    */
    function getLoanOffersToken(uint256 _loanId)
        public
        view
        override
        returns (TokenLoanData.LoanDetails memory)
    {
        return loanOffersToken[_loanId];
    }

    function getStableCoinAPYFeeinContract(address _stableCoin)
        external
        view
        override
        returns (uint256)
    {
        return stableCoinAPYFeeFromToken[_stableCoin];
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
interface IERC20Upgradeable {
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
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

struct TierData {
    // Gov  Holdings to check if it lies in that tier
    uint256 govHoldings;
    // LTV percentage of the Gov Holdings
    uint8 loantoValue;
    //checks that if tier level have access
    bool govIntel;
    bool singleToken;
    bool multiToken;
    bool singleNFT;
    bool multiNFT;
    bool reverseLoan;
}
struct SingleSPTierData {
    uint256 ltv;
    bool singleToken;
    bool singleNft;
    bool multiNFT;
}

struct NFTTierData {
    address nftContract;
    bool isTraditional;
    address spToken;
    bytes32 traditionalTier;
    uint256 nftTier;
    address[] allowedNfts;
    address[] allowedSUNTokens;
}

interface IGovWorldTierLevel {
    function getTierDatabyGovBalance(address userWalletAddress)
        external
        view
        returns (TierData memory _tierData);

    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower
    ) external view returns (uint256);

    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);

    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../library/TokenLoanData.sol";

interface IGovLiquidator {
    //using this function externally in the Token and NFT Loan Market Smart Contract
    function isLiquidateAccess(address liquidator) external view returns (bool);

    function liquidateLoan(uint256 _loanId) external;

    function getLtv(uint256 _loanId) external view returns (uint256);

    function isLiquidationPending(uint256 _loanId) external view returns (bool);

    function payback(uint256 _loanId, uint256 _paybackAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../library/TokenLoanData.sol";
import "../interfaces/ITokenMarket.sol";

abstract contract TokenMarketBase is ITokenMarket {
    //Load library structs into contract
    using TokenLoanData for *;
    using TokenLoanData for bytes32;

    //saves the transaction hash of the create loan offer transaction as loanId
    mapping(uint256 => TokenLoanData.LoanDetails) public loanOffersToken;

    //mapping saves the information of the lender across the active loanId
    mapping(uint256 => TokenLoanData.LenderDetails)
        public activatedLoanOffersFull;

    //array of all loan offer ids of the ERC20 tokens.
    uint256[] public loanOfferIds;

    //erc20 tokens loan offer mapping
    mapping(address => uint256[]) borrowerloanOfferIds;

    //mapping address of lender => loan Ids
    mapping(address => uint256[]) lenderActivatedLoanIds;

    //mapping address stable => APY Fee in stable
    mapping(address => uint256) public stableCoinAPYFeeFromToken;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library TokenLoanData {
    enum LoanStatus {
        ACTIVE,
        INACTIVE,
        CLOSED,
        CANCELLED,
        LIQUIDATED
    }

    enum LoanType {
        SINGLE_TOKEN,
        MULTI_TOKEN
    }

    struct LenderDetails {
        address lender;
        uint256 activationLoanTimeStamp;
        bool autoSell;
    }

    struct LoanDetails {
        //total Loan Amount in Borrowed stable coin
        uint256 loanAmountInBorrowed;
        //user choose terms length in days
        uint256 termsLengthInDays;
        //borrower given apy percentage
        uint32 apyOffer;
        //Single-ERC20, Multiple staked ERC20,
        LoanType loanType;
        //private loans will not appear on loan market
        bool isPrivate;
        //will allow lender to fund in 25%, 50%, 75% or 100% or original loan amount
        // bool isPartialFunding; //REMOVED this variable was for lender.
        //Future use flag to insure funds as they go to protocol.
        bool isInsured;
        //single - or multi token collateral tokens wrt tokenAddress
        address[] stakedCollateralTokens;
        uint256[] stakedCollateralAmounts;
        address borrowStableCoin;
        //current status of the loan
        LoanStatus loanStatus;
        //borrower's address
        address borrower;
        uint256 paybackAmount;
        bool[] isMintSp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

struct ChainlinkDataFeed {
    AggregatorV3Interface usdPriceAggrigator;
    bool enabled;
    uint256 decimals;
}

interface IGovPriceConsumer {
    event PriceFeedAdded(
        address indexed token,
        address usdPriceAggrigator,
        bool enabled,
        uint256 decimals
    );
    event PriceFeedAddedBulk(
        address[] indexed tokens,
        address[] chainlinkFeedAddress,
        bool[] enabled,
        uint256[] decimals
    );
    event PriceFeedRemoved(address indexed token);

    /**
     * Use chainlink PriceAggrigator to fetch prices of the already added feeds.
     */
    function getLatestUsdPriceFromChainlink(address priceFeedToken)
        external
        view
        returns (int256, uint8);

    /**
    @dev multiple token prices fetch
    @param priceFeedToken multi token price fetch
    */
    function getLatestUsdPricesFromChainlink(address[] memory priceFeedToken)
        external
        view
        returns (
            address[] memory tokens,
            int256[] memory prices,
            uint8[] memory decimals
        );

    function getNetworkPriceFromChainlinkinUSD() external view returns (int256);

    function getSwapData(
        address _collateralToken,
        uint256 _collateralAmount,
        address _borrowStableCoin
    ) external view returns (uint256, uint256);

    function getNetworkCoinSwapData(
        address _collateralToken,
        uint256 _collateralAmount,
        address _borrowStableCoin
    ) external view returns (uint256, uint256);

    function getSwapInterface(address _collateralTokenAddress)
        external
        view
        returns (address);

    function getSwapInterfaceForETH() external view returns (address);

    /**
     * @dev How  much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
     * @param _stable address of stable coin
     * @param _alt address of alt coin
     * @param _amount address of alt
     */
    function getDexTokenPrice(
        address _stable,
        address _alt,
        uint256 _amount
    ) external view returns (uint256);

    //check wether token feed for this token is enabled or not
    function isChainlinFeedEnabled(address _tokenAddress)
        external
        view
        returns (bool);

    function getusdPriceAggrigators(address _tokenAddress)
        external
        view
        returns (ChainlinkDataFeed memory);

    function getAllChainlinkAggiratorsContract()
        external
        view
        returns (address[] memory);

    function getAllGovAggiratorsTokens()
        external
        view
        returns (address[] memory);

    function WETHAddress() external view returns (address);

    function getAltCoinPriceinStable(
        address _stableCoin,
        address _altCoin,
        uint256 _collateralAmount
    ) external view returns (uint256);

    function getClaimTokenPrice(
        address _stable,
        address _alt,
        uint256 _amount
    ) external view returns (uint256);

    function calculateLTV(
        uint256[] memory _stakedCollateralAmounts,
        address[] memory _stakedCollateralTokens,
        address _borrowedToken,
        uint256 _loanAmount
    ) external view returns (uint256);

    function getSUNTokenPrice(
        address _claimToken,
        address _stable,
        address _sunToken,
        uint256 _amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapSwapInterface {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Extras {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenMarketRegistry {
    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(
        uint256 _loanAmountInBorrowed,
        uint256 _apyOffer,
        uint256 _termsLengthInDays
    ) external returns (uint256);

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external returns (uint256);

    function getLoanActivateLimitt() external view returns (uint256);

    function getLTVPercentage() external view returns (uint256);

    function isWhitelistedForActivation(address) external returns (bool);

    function isSuperAdminAccess(address) external returns (bool);

    function isTokenApproved(address) external returns (bool);

    function isTokenEnabledForCreateLoan(address) external returns (bool);

    function getGovPlatformFee() external view returns (uint256);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSynthetticMintOn(address _token) external view returns (bool);

    function isStableApproved(address _stable) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct ClaimTokenData {
    address[] sunTokens;
    uint256[] sunTokenPricePercentage;
    address dexRouter; //this address will get the price from the AMM DEX (uniswap, sushiswap etc...)
}

interface IGovClaimToken {
    function isClaimToken(address _claimTokenAddress)
        external
        view
        returns (bool);

    function getClaimTokensData(address _claimTokenAddress)
        external
        view
        returns (ClaimTokenData memory);

    function getClaimTokenofSUNToken(address _sunToken)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../library/TokenLoanData.sol";

interface ITokenMarket {
    function getStableCoinAPYFeeinContract(address _stableCoin)
        external
        view
        returns (uint256);

    /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetails(uint256 _loanId)
        external
        view
        returns (TokenLoanData.LenderDetails memory);

    /**
    @dev get loan details of the single or multi-token
    */
    function getLoanOffersToken(uint256 _loanId)
        external
        view
        returns (TokenLoanData.LoanDetails memory);

    function updateLoanStatusonLiquidation(uint256 _loanId) external;

    function updateLoanStatusonPayback(uint256 _loanId) external;

    event LoanOfferCreatedToken(TokenLoanData.LoanDetails _loanDetailsToken);

    event LoanOfferAdjustedToken(TokenLoanData.LoanDetails _loanDetails);

    event TokenLoanOfferActivated(
        uint256 loanId,
        address _lender,
        uint256 _stableCoinAmount,
        bool _autoSell
    );

    event LoanOfferCancelToken(
        uint256 loanId,
        address _borrower,
        TokenLoanData.LoanStatus loanStatus
    );

    event FullTokensLoanPaybacked(
        uint256 loanId,
        address _borrower,
        address _lender,
        uint256 _paybackAmount,
        TokenLoanData.LoanStatus loanStatus,
        uint256 _earnedAPY
    );

    event PartialTokensLoanPaybacked(
        uint256 loanId,
        address _borrower,
        address _lender,
        uint256 paybackAmount
    );

    event AutoLiquidated(uint256 _loanId, TokenLoanData.LoanStatus loanStatus);

    event LiquidatedCollaterals(
        uint256 _loanId,
        TokenLoanData.LoanStatus loanStatus
    );

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawToken(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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

}