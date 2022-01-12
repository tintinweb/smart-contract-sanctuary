// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "./GovLiquidatorBase.sol";
import "../library/TokenLoanData.sol";
import "../../admin/interfaces/IGovWorldAdminRegistry.sol";
import "../interfaces/ITokenMarket.sol";
import "../../oracle/IGovPriceConsumer.sol";
import "../../interfaces/IUniswapSwapInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../admin/interfaces/IGovWorldProtocolRegistry.sol";
import "../../claimtoken/IGovClaimToken.sol";

interface IGToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract GovWorldLiquidator is GovLiquidatorBase {
    using TokenLoanData for *;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address private _tokenMarket;

    IGovWorldAdminRegistry govAdminRegistry;
    ITokenMarket govTokenMarket;
    IGovPriceConsumer govPriceConsumer;
    IGovWorldProtocolRegistry govProtocolRegistry;
    IGovClaimToken govClaimToken;

    constructor(
        address _liquidator1,
        address _liquidator2,
        address _liquidator3,
        address _govWorldAdminRegistry,
        address _govPriceConsumer,
        address _govProtocolRegistry,
        address _claimToken
    ) {
        //owner becomes the default admin.
        _makeDefaultApproved(_liquidator1, true);
        _makeDefaultApproved(_liquidator2, true);
        _makeDefaultApproved(_liquidator3, true);

        govAdminRegistry = IGovWorldAdminRegistry(_govWorldAdminRegistry);
        govPriceConsumer = IGovPriceConsumer(_govPriceConsumer);
        govProtocolRegistry = IGovWorldProtocolRegistry(_govProtocolRegistry);
        govClaimToken = IGovClaimToken(_claimToken);
    }

    /**
     * @dev This function is used to Set Token Market Address
     *
     * @param _tokenMarketAddress Address of the Media Contract to set
     */
    function configureTokenMarket(address _tokenMarketAddress) external {
        require(
            govAdminRegistry.isSuperAdminAccess(msg.sender),
            "GL: only super admin"
        );
        require(
            _tokenMarketAddress != address(0),
            "GL: Invalid Media Contract Address!"
        );
        // require(_tokenMarket == address(0), 'GL: Media Contract Alredy Configured!'); //TODO uncomment before live on mainnet
        _tokenMarket = _tokenMarketAddress;
        govTokenMarket = ITokenMarket(_tokenMarket);
    }

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddLiquidatorRole(address admin) {
        require(
            govAdminRegistry.isAddGovAdminRole(admin),
            "GL: msg.sender not a Gov Admin."
        );
        _;
    }

    //modifier: only liquidators can liquidate pending liquidation calls
    modifier onlyLiquidatorRole(address liquidator) {
        require(
            this.isLiquidateAccess(liquidator),
            "GL: Not a Gov Liquidator."
        );
        _;
    }

    modifier onlyTokenMarket() {
        require(msg.sender == _tokenMarket, "GL: Unauthorized Access!");
        _;
    }

    //modifier: only super admin can withdraw contract balance
    modifier onlySuperAdmin(address superAdmin) {
        require(
            govAdminRegistry.isSuperAdminAccess(superAdmin),
            "GTM: Not a Gov Super Admin."
        );
        _;
    }

    //mapping of wallet address to track the approved claim token balances when loan is liquidated
    // wallet address lender => sunTokenAddress => balanceofSUNToken
    mapping(address => mapping(address => uint256))
        private liquidatedSUNTokenbalances;

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawToken(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );

    /**
     * @dev makes _newLiquidator as a whitelisted liquidator
     * @param _newLiquidators Address of the new liquidators
     * @param _liquidatorRole access variables for _newLiquidator
     */
    function setLiquidator(
        address[] memory _newLiquidators,
        bool[] memory _liquidatorRole
    ) external onlyAddLiquidatorRole(msg.sender) {
        for (uint256 i = 0; i < _newLiquidators.length; i++) {
            require(
                !_liquidatorExists(_newLiquidators[i], whitelistedLiquidators),
                "GL: Already Liquidator"
            );
            _makeDefaultApproved(_newLiquidators[i], _liquidatorRole[i]);
        }
    }

    function _liquidateCollateralAutoSellOn(uint256 _loanId) internal {
        
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        (, uint256 earnedAPYFee, ) = this.getTotalPaybackAmount(_loanId);

        for (
                uint256 i = 0;
                i < loanDetails.stakedCollateralTokens.length;
                i++
            ) {

                Market memory market = IGovWorldProtocolRegistry(govProtocolRegistry).getSingleApproveToken(loanDetails.stakedCollateralTokens[i]);
                if (loanDetails.isMintSp[i]) {
                    IGToken(market.gToken).burnFrom(
                    loanDetails.borrower,
                    loanDetails.stakedCollateralAmounts[i]);
                }

                address[] memory path = new address[](2);
                path[0] = loanDetails.stakedCollateralTokens[i];
                path[1] = loanDetails.borrowStableCoin;
                (uint256 amountIn, uint256 amountOut) = govPriceConsumer
                    .getSwapData(
                        path[0],
                        loanDetails.stakedCollateralAmounts[i],
                        path[1]
                    );

                //transfer the swap stable coins to the liquidator contract address.
                IUniswapSwapInterface swapInterface = IUniswapSwapInterface(
                    IGovPriceConsumer(govPriceConsumer).getSwapInterface(
                        loanDetails.stakedCollateralTokens[i]
                    )
                );
                IERC20(loanDetails.stakedCollateralTokens[i]).approve(
                    address(swapInterface),
                    amountIn
                );
                swapInterface
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        amountIn,
                        amountOut,
                        path,
                        address(this),
                        block.timestamp + 5 minutes
                    );
            }

            uint256 autosellFeeinStable = govTokenMarket.getautosellAPYFee(
                loanDetails.loanAmountInBorrowed,
                govProtocolRegistry.getAutosellPercentage(),
                loanDetails.termsLengthInDays
            );
            uint256 finalAmountToLender = (loanDetails.loanAmountInBorrowed +
                earnedAPYFee) - (autosellFeeinStable);

            IERC20(loanDetails.borrowStableCoin).safeTransfer(
                lenderDetails.lender,
                finalAmountToLender
            );
            loanDetails.loanStatus = TokenLoanData.LoanStatus.LIQUIDATED;
            emit AutoLiquidated(_loanId, TokenLoanData.LoanStatus.LIQUIDATED);
    }

    function _liquidateCollateralAutSellOff(uint256 _loanId) internal {

        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);


        (, uint256 earnedAPYFee, ) = this.getTotalPaybackAmount(_loanId);
            // uint256 thresholdFee = govProtocolRegistry.getThresholdPercentage();
            uint256 thresholdFeeinStable = (
                (
                    loanDetails.loanAmountInBorrowed.mul(
                        govProtocolRegistry.getThresholdPercentage()
                    )
                ).div(10000)
            );
            uint256 lenderAmountinStable = earnedAPYFee + thresholdFeeinStable;
            //send collateral tokens to the lender
            uint256 collateralAmountinStable;

            for (
                uint256 i = 0;
                i < loanDetails.stakedCollateralTokens.length;
                i++
            ) {
                uint256 priceofCollateral;
                address claimToken = IGovClaimToken(govClaimToken)
                    .getClaimTokenofSUNToken(
                        loanDetails.stakedCollateralTokens[i]
                    );

                if (govClaimToken.isClaimToken(claimToken)) {
                    IERC20(loanDetails.stakedCollateralTokens[i]).safeTransfer(
                        lenderDetails.lender,
                        loanDetails.stakedCollateralAmounts[i]
                    );
                    liquidatedSUNTokenbalances[lenderDetails.lender][
                        loanDetails.stakedCollateralTokens[i]
                    ] += loanDetails.stakedCollateralAmounts[i];
                } else {

                    Market memory market = IGovWorldProtocolRegistry(govProtocolRegistry).getSingleApproveToken(loanDetails.stakedCollateralTokens[i]);
                    if (loanDetails.isMintSp[i]) {
                    IGToken(market.gToken).burnFrom(
                    loanDetails.borrower,
                    loanDetails.stakedCollateralAmounts[i]);
                    }
                    priceofCollateral = govPriceConsumer
                        .getAltCoinPriceinStable(
                            loanDetails.borrowStableCoin,
                            loanDetails.stakedCollateralTokens[i],
                            loanDetails.stakedCollateralAmounts[i]
                        );
                    collateralAmountinStable = collateralAmountinStable.add(
                        priceofCollateral
                    );

                    if (
                        collateralAmountinStable <=
                        loanDetails.loanAmountInBorrowed
                    ) {
                        IERC20(loanDetails.stakedCollateralTokens[i])
                            .safeTransfer(
                                lenderDetails.lender,
                                loanDetails.stakedCollateralAmounts[i]
                            );
                    } else if (
                        collateralAmountinStable >
                        loanDetails.loanAmountInBorrowed
                    ) {
                        uint256 exceedAltcoinValue = govPriceConsumer
                            .getAltCoinPriceinStable(
                                loanDetails.stakedCollateralTokens[i],
                                loanDetails.borrowStableCoin,
                                collateralAmountinStable.sub(
                                    loanDetails.loanAmountInBorrowed
                                )
                            );
                        uint256 collateralToLender = loanDetails
                            .stakedCollateralAmounts[i]
                            .sub(exceedAltcoinValue);
                        IERC20(loanDetails.stakedCollateralTokens[i])
                            .safeTransfer(
                                lenderDetails.lender,
                                collateralToLender
                            );
                        break;
                    }
                }
            }
            //loan status is now liquidated
            loanDetails.loanStatus = TokenLoanData.LoanStatus.LIQUIDATED;
            //lender recieves the stable coins
            IERC20(loanDetails.borrowStableCoin).safeTransfer(
                lenderDetails.lender,
                lenderAmountinStable
            );
            emit LiquidatedCollaterals(
                _loanId,
                TokenLoanData.LoanStatus.LIQUIDATED
            );
    }

    /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
     */
    function liquidateLoan(uint256 _loanId) external override {
        require(
            this.isLiquidateAccess(msg.sender),
            "GL: Not a Gov Liquidator."
        );

        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        require(
            loanDetails.loanStatus == TokenLoanData.LoanStatus.ACTIVE,
            "GLM, not active"
        );

        uint256 loanTermLengthPassedInDays = (
            block.timestamp.sub(lenderDetails.activationLoanTimeStamp)
        ).div(86400);

        // require(this.isLiquidationPending(_loanId) || (loanTermLengthPassedInDays > loanDetails.termsLengthInDays), "GTM: Liquidation Error");  // TODO uncomment this line before  deployment

        if (lenderDetails.autoSell == true) {
            _liquidateCollateralAutoSellOn(_loanId);
        } else {
            _liquidateCollateralAutSellOff(_loanId);
        }
    }

    function getAllLiquidators() public view returns (address[] memory) {
        return whitelistedLiquidators;
    }

    function getLiquidatorAccess(address _liquidator)
        public
        view
        returns (bool)
    {
        return whitelistLiquidators[_liquidator];
    }

    //only super admin can withdraw coins
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public onlySuperAdmin(msg.sender) {
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
    ) public onlySuperAdmin(msg.sender) {
        require(
            _withdrawAmount <= IERC20(_tokenAddress).balanceOf(address(this)),
            "GTM: Amount Invalid"
        );
        IERC20(_tokenAddress).safeTransfer(_walletAddress, _withdrawAmount);
        emit WithdrawToken(_tokenAddress, _walletAddress, _withdrawAmount);
    }

    /**
    @dev functino to get the LTV of the loan amount in borrowed of the staked colletral token
    @param _loanId loan ID for which ltv is getting
     */
    function getLtv(uint256 _loanId) external view override returns (uint256) {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        //get individual collateral tokens for the loan id
        uint256[] memory stakedCollateralAmounts = loanDetails
            .stakedCollateralAmounts;
        address[] memory stakedCollateralTokens = loanDetails
            .stakedCollateralTokens;
        address borrowedToken = loanDetails.borrowStableCoin;
        return
            govPriceConsumer.calculateLTV(
                stakedCollateralAmounts,
                stakedCollateralTokens,
                borrowedToken,
                loanDetails.loanAmountInBorrowed.sub(loanDetails.paybackAmount)
            );
    }

    /**
    @dev function to check the loan is pending for liqudation or not
    @param _loanId for which loan liquidation checking
     */
    function isLiquidationPending(uint256 _loanId)
        external
        view
        override
        returns (bool)
    {
        //get LTV
        uint256 ltv = this.getLtv(_loanId);
        //the collateral is less than liquidation threshold percentage/ ok for liquidation
        if (ltv <= govTokenMarket.getLTVPercentage()) return true;
        else return false;
    }

    function getTotalPaybackAmount(uint256 _loanId)
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        uint256 loanTermLengthPassedInDays = (
            block.timestamp.sub(
                govTokenMarket
                    .getActivatedLoanDetails(_loanId)
                    .activationLoanTimeStamp
            )
        ).div(86400);

        // require(loanTermLengthPassedInDays <= loanDetails.termsLengthInDays, "GLM: paid back or liquidated."); //TODO uncomment before mainnet deployment

        uint256 apyFeeOriginal = govTokenMarket.getAPYFee(loanDetails);
        uint256 earnedAPYFee = (
            (
                loanDetails.loanAmountInBorrowed.mul(loanDetails.apyOffer).div(
                    10000
                )
            ).div(365)
        ).mul(loanTermLengthPassedInDays);
        uint256 unEarnedAPYFee = apyFeeOriginal.sub(earnedAPYFee);
        //lender also getting the some percentage of the unearned APY FEE //TODO (to add unEarnedPercentage or not??)
        return (
            loanDetails.loanAmountInBorrowed.add(earnedAPYFee),
            earnedAPYFee,
            unEarnedAPYFee
        );
    }

    /**
    @dev payback loan full by the borrower to the lender
     */
    function fullLoanPaybackEarly(uint256 _loanId) internal {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        (uint256 finalPaybackAmounttoLender, uint256 earnedAPYFee, ) = this
            .getTotalPaybackAmount(_loanId);
        uint256 stableCoinFee = govTokenMarket.getStableCoinAPYFeeinContract(
            loanDetails.borrowStableCoin
        );
        stableCoinFee = govTokenMarket
            .getStableCoinAPYFeeinContract(loanDetails.borrowStableCoin)
            .sub(earnedAPYFee);

        //first transferring the payback amount from borrower to the Gov Token Market
        IERC20(loanDetails.borrowStableCoin).safeTransferFrom(
            loanDetails.borrower,
            address(this),
            (loanDetails.loanAmountInBorrowed.sub(loanDetails.paybackAmount))
        );
        IERC20(loanDetails.borrowStableCoin).safeTransfer(
            lenderDetails.lender,
            finalPaybackAmounttoLender
        );

        //loop through all staked collateral tokens.
        for (
            uint256 i = 0;
            i < loanDetails.stakedCollateralTokens.length;
            i++
        ) {
            //contract will the repay staked collateral tokens to the borrower
            IERC20(loanDetails.stakedCollateralTokens[i]).safeTransfer(
                msg.sender,
                loanDetails.stakedCollateralAmounts[i]
            );
            Market memory market = IGovWorldProtocolRegistry(
                govProtocolRegistry
            ).getSingleApproveToken(loanDetails.stakedCollateralTokens[i]);
            IGToken gtoken = IGToken(market.gToken);
            if (market.isSP && loanDetails.isMintSp[i]) {
                gtoken.burnFrom(
                    loanDetails.borrower,
                    loanDetails.stakedCollateralAmounts[i]
                );
            }
        }

        loanDetails.paybackAmount = finalPaybackAmounttoLender;
        loanDetails.loanStatus = TokenLoanData.LoanStatus.CLOSED;
        emit FullTokensLoanPaybacked(
            _loanId,
            msg.sender,
            lenderDetails.lender,
            loanDetails.loanAmountInBorrowed.sub(loanDetails.paybackAmount),
            earnedAPYFee
        );
    }

    /**
    @dev token loan payback partial
    if _paybackAmount is equal to the total loan amount in stable coins the loan concludes as full payback
     */
    function payback(uint256 _loanId, uint256 _paybackAmount) public override {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        require(
            loanDetails.loanType == TokenLoanData.LoanType.SINGLE_TOKEN ||
                loanDetails.loanType == TokenLoanData.LoanType.MULTI_TOKEN,
            "GLM: Invalid Loan Type"
        );
        require(loanDetails.borrower == msg.sender, "GLM, not borrower");
        require(
            loanDetails.loanStatus == TokenLoanData.LoanStatus.ACTIVE,
            "GLM, not active"
        );
        require(
            _paybackAmount > 0 &&
                _paybackAmount <= loanDetails.loanAmountInBorrowed,
            "GLM: Invalid Loan Amount"
        );
        uint256 totalPayback = _paybackAmount.add(loanDetails.paybackAmount);
        if (totalPayback >= loanDetails.loanAmountInBorrowed) {
            fullLoanPaybackEarly(_loanId);
        }
        //partial loan paypack
        else {
            uint256 remainingLoanAmount = loanDetails.loanAmountInBorrowed.sub(
                totalPayback
            );
            uint256 newLtv = IGovPriceConsumer(govPriceConsumer).calculateLTV(
                loanDetails.stakedCollateralAmounts,
                loanDetails.stakedCollateralTokens,
                loanDetails.borrowStableCoin,
                remainingLoanAmount
            );
            require(newLtv > govTokenMarket.getLTVPercentage(), "GLM: new LTV exceeds threshold.");
            IERC20(loanDetails.borrowStableCoin).safeTransferFrom(
                loanDetails.borrower,
                address(this),
                _paybackAmount
            );
            loanDetails.paybackAmount = loanDetails.paybackAmount.add(
                _paybackAmount
            );
            loanDetails.loanStatus = TokenLoanData.LoanStatus.ACTIVE;
            emit PartialTokensLoanPaybacked(
                _loanId,
                msg.sender,
                lenderDetails.lender,
                _paybackAmount
            );
        }
    }

    function getLenderSUNTokenBalances(address _lender, address _sunToken)
        public
        view
        returns (uint256)
    {
        return liquidatedSUNTokenbalances[_lender][_sunToken];
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../market/liquidator/IGovLiquidator.sol";

abstract contract GovLiquidatorBase is Ownable, IGovLiquidator {
    //list of already approved liquidators.
    mapping(address => bool) public whitelistLiquidators;

    //list of all approved liquidator addresses. Stores the key for mapping approvedLiquidators
    address[] whitelistedLiquidators;

    event NewLiquidatorApproved(
        address indexed _newLiquidator,
        bool _liquidatorAccess
    );
    event AutoLiquidated(uint256 _loanId, TokenLoanData.LoanStatus loanStatus);
    event LiquidatedCollaterals(
        uint256 _loanId,
        TokenLoanData.LoanStatus loanStatus
    );
    event FullTokensLoanPaybacked(uint256, address, address, uint256, uint256);
    event PartialTokensLoanPaybacked(uint256, address, address, uint256);

    /**
    @dev function to check if address have liquidate role option
     */
    function isLiquidateAccess(address liquidator)
        external
        view
        override
        returns (bool)
    {
        return whitelistLiquidators[liquidator];
    }

    /**
     * @dev makes _newLiquidator an approved liquidator and emits the event
     * @param _newLiquidator Address of the new liquidator
     * @param _liquidatorAccess access variables for _newLiquidator
     */
    function _makeDefaultApproved(
        address _newLiquidator,
        bool _liquidatorAccess
    ) internal {
        whitelistLiquidators[_newLiquidator] = _liquidatorAccess;
        whitelistedLiquidators.push(_newLiquidator);
        emit NewLiquidatorApproved(_newLiquidator, _liquidatorAccess);
    }

    function _liquidatorExists(address _liquidator, address[] memory from)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] == _liquidator) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library TokenLoanData {
    using SafeMath for uint256;
    enum LoanStatus {
        ACTIVE,
        INACTIVE,
        CLOSED,
        CANCELLED,
        LIQUIDATED,
        TERMINATED
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
        //user choose terms length in days TODO define validations
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IGovWorldAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    function isAddGovAdminRole(address admin) external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "../library/TokenLoanData.sol";

interface ITokenMarket {
    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(TokenLoanData.LoanDetails memory _loanDetails)
        external
        returns (uint256);

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external returns (uint256);

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

    function getStableCoinAPYFeeinContract(address _stableCoin)
        external
        view
        returns (uint256);

    function getLTVPercentage() external view returns(uint256);

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

// SPDX-License-Identifier: agpl-3.0

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

// SPDX-License-Identifier: agpl-3.0
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

// Token Market Data
struct Market {
    address dexRouter;
    bool isSP;
    bool isReversedLoan;
    uint256 tokenLimitPerReverseLoan;
    address gToken;
    bool isMint;
    bool isClaimToken;
}

interface IGovWorldProtocolRegistry {
    /** external functions of the Gov Protocol Contract */
    /**
    @dev function to add token to approvedTokens mapping
    *@param _tokenAddress of the new token Address
    *@param  _market of the _tokenAddress
    */
    function addTokens(address[] memory _tokenAddress, Market[] memory _market)
        external;

    /**
     *@dev function to update the token market data
     *@param _tokenAddress to check if it exit in the array and mapping
     *@param _marketData struct to update the token market
     */
    function updateTokens(
        address[] memory _tokenAddress,
        Market[] memory _marketData
    ) external;

    /**
     *@dev function which remove tokenaddress from array and data from the mapping
     *@param _removeTokenAddress the key to remove
     */
    function removetokens(address[] memory _removeTokenAddress) external;

    /**
    @dev add sp wallet to the mapping approvedSps
    @param _tokenAddress token contract address
    @param _walletAddress sp wallet address to add  
    */

    function addSp(address _tokenAddress, address _walletAddress) external;

    /**
    @dev remove sp wallet from mapping
    @param _tokenAddress token address as a key to remove sp
    @param _removeWalletAddress sp wallet address to be removed 
    */

    function removeSp(address _tokenAddress, address _removeWalletAddress)
        external;

    /**
    @dev adding bulk sp wallet address to the approvedSps
    @param _tokenAddress token contract address as a key for sp wallets
    @param _walletAddress sp wallet addresses adding to the approvedSps mapping
     */
    function addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        external;

    /**
     *@dev function to update the sp wallet
     *@param _tokenAddress to check if it exit in the array and mapping
     *@param _oldWalletAddress old wallet address to be updated
     *@param _newWalletAddress new wallet address
     */
    function updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) external;

    /**
    @dev external function update bulk SP wallets to the approvedSps
    @param _tokenAddress token contract address being updated
    @param _oldWalletAddress  array of old sp wallets 
    @param _newWalletAddress  array of the new sp wallets
     */
    function updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) external;

    /**
    *@dev function which remove bulk wallet address and key
    @param _tokenAddress check across this token address
    @param _removeWalletAddress array of wallet addresses to be removed
     */

    function removeBulkSps(
        address _tokenAddress,
        address[] memory _removeWalletAddress
    ) external;

    /** 
    @dev check function if Token Contract address is already added 
    @param _tokenAddress token address */
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool);

    function getUnearnedAPYPercentageForLender()
        external
        view
        returns (uint256);

    function getGovPlatformFee() external view returns (uint256);

    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getAdminWalletPercentage() external view returns (uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (Market memory);

    function getTokenMarket() external view returns (address[] memory);

    function getAdminFeeWallet() external view returns (address);

    function getSingleTokenSps(address _tokenAddress)
        external
        view
        returns (address[] memory);

    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: agpl-3.0

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

// SPDX-License-Identifier: agpl-3.0

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