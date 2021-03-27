pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../access/FundsManager.sol";
import "../access/Adminable.sol";

import "../constants/ConstantAddressesMainnet.sol";

import "../utils/DSMath.sol";
import "../utils/SafeMath.sol";

import "../flashloan/base/FlashLoanReceiverBase.sol";
import "../dydxFlashloan/FlashloanDyDx.sol";

// **INTERFACES**
import "../compound/interfaces/ICToken.sol";
import "../flashloan/interfaces/ILendingPool.sol";
import "../interfaces/IDfWalletFactory.sol";
import "../interfaces/IDfWallet.sol";
import "../interfaces/IToken.sol";
import "../interfaces/IComptrollerLensInterface.sol";
import "../interfaces/IComptroller.sol";
import "../interfaces/IWeth.sol";
import "../interfaces/IDfProxy.sol";


contract DfFinanceDeposits is
    Initializable,
    DSMath,
    ConstantAddresses,
    FundsManager,
    Adminable,
    FlashLoanReceiverBase,
    FlashloanDyDx
{
    using UniversalERC20 for IToken;
    using SafeMath for uint256;


    // ** STRUCTS **

    struct FeeScheme {
        address[] partners;
        uint32[] percents;
        uint32 fee;
        bool isEnabled;
    }

    struct UserData {
        address owner;
        uint256 deposit; // in dai
        uint64 compClaimed;
        uint64 compClaimedinUSD; // 6 decimals
        uint64 activeFeeScheme; // 0 - fee scheme is disabled
        uint64 depositUSDC;
        // next pack
        uint96 depositETH;
        uint64 depositWBTC;
        uint96 gap;
    }

    struct FlashloanData {
        address dfWallet;
        address token;
        address cToken;
        uint256 deposit;
        uint256 amountFlashLoan;
    }

    struct FlashloanDataDyDxEth {
        address dfWallet;
        address token;
        address cToken;
        uint256 deposit;
        uint256 debt;
        uint256 ethAmountFlashLoan;
    }

    // ** ENUMS **

    enum OP {
        UNKNOWN,
        DEPOSIT,
        WITHDRAW,
        DEPOSIT_USING_DYDX_ETH,
        WITHDRAW_USING_DYDX_ETH
    }

    enum FlashloanProvider {
        DYDX,
        AAVE,
        ADDRESS
    }


    // ** PUBLIC STATES **

    IDfWalletFactory public dfWalletFactory;

    uint256 private DELETED_fee; // DELETED state

    mapping(address => UserData) public wallets;


    // ** PRIVATE STATES **

    // partner => token => balance
    mapping(address => mapping(address => uint256)) private DELETED_partnerBalances;    // DELETED state

    FeeScheme[] private DELETED_feeSchemes; // DELETED state

    OP private state;


    // ** ADDED STATES **

    // withdraw min ratio from cToken to Token conversion
    uint256 public withdrawMinRatio;


    // ** EVENTS **

    event DfOpenDeposit(address indexed dfWallet, uint256 amount);
    event DfAddDeposit(address indexed dfWallet, uint256 amount);
    event DfCloseDeposit(address indexed dfWallet, uint256 amount, address token);
    event DfPartiallyCloseDeposit(
        address indexed dfWallet, address indexed tokenReceiver, uint256 amountDAI, uint256 tokensSent,  uint256 deposit
    );


    // ** INITIALIZER – Constructor for Upgradable contracts **

    function initialize() public initializer {
        Adminable.initialize();  // Initialize Parent Contract
        // FundsManager.initialize();  // Init in Adminable

        withdrawMinRatio = 0.995 * 1e18;

        // dfWalletFactory = IDfWalletFactory(0);
    }


    // ** ONLY_OWNER functions **

    function setDfWalletFactory(address _dfWalletFactory) public onlyOwner {
        require(_dfWalletFactory != address(0));
        dfWalletFactory = IDfWalletFactory(_dfWalletFactory);
    }

    function setWithdrawMinRatio(uint256 _withdrawMinRatio) public onlyOwner {
        require(_withdrawMinRatio >= 0.9 * 1e18 && _withdrawMinRatio <= 1e18);
        withdrawMinRatio = _withdrawMinRatio;
    }


    // ** PUBLIC functions **

    function getCompBalanceMetadataExt(address account) external returns (uint256 balance, uint256 allocated) {
        IComptrollerLensInterface comptroller = IComptrollerLensInterface(COMPTROLLER);
        balance = IToken(COMP_ADDRESS).balanceOf(account);
        comptroller.claimComp(account);
        uint256 newBalance = IToken(COMP_ADDRESS).balanceOf(account);
        uint256 accrued = comptroller.compAccrued(account);
        uint256 total = add(accrued, newBalance);
        allocated = sub(total, balance);
    }


    // DEPOSIT function

    function deposit(
        address dfWallet,
        uint256 amountDAI,
        uint256 amountUSDC,
        uint256 amountWBTC,
        uint256 flashloanDAI,
        uint256 flashloanUSDC,
        FlashloanProvider flashloanType,
        address flashloanFromAddress
    ) public payable onlyOwnerOrAdmin returns (address) {
        if (dfWallet == address(0)) {
            dfWallet = dfWalletFactory.createDfWallet();
            wallets[dfWallet] = UserData(msg.sender, 0, 0, 0, 0, 0, 0, 0, 0);
        }

        require(wallets[dfWallet].owner == msg.sender);

        uint amountETH = msg.value;

        // Update states
        wallets[dfWallet].deposit = add(wallets[dfWallet].deposit, amountDAI);
        wallets[dfWallet].depositUSDC = uint64(add(wallets[dfWallet].depositUSDC, amountUSDC));
        wallets[dfWallet].depositETH = uint96(add(wallets[dfWallet].depositETH, amountETH));
        wallets[dfWallet].depositWBTC = uint64(add(wallets[dfWallet].depositWBTC, amountWBTC));

        // Deposit ETH without boosting
        if (amountETH > 0) {
            IDfWallet(dfWallet).deposit.value(amountETH)(ETH_ADDRESS, CETH_ADDRESS, amountETH, address(0), address(0), 0);
        }

        // Deposit WBTC without boosting
        if (amountWBTC > 0) {
            IDfWallet(dfWallet).deposit(WBTC_ADDRESS, CWBTC_ADDRESS, amountWBTC, address(0), address(0), 0);
        }

        // Boost USDC deposit
        if (amountUSDC > 0 || flashloanUSDC > 0) {
            if (flashloanType == FlashloanProvider.DYDX
                && flashloanUSDC > IToken(USDC_ADDRESS).balanceOf(SOLO_MARGIN_ADDRESS)
            ) {
                // if dYdX lacks liquidity in USDC use ETH
                _depositBoostUsingDyDxEth(
                    dfWallet, USDC_ADDRESS, CUSDC_ADDRESS, amountUSDC, flashloanUSDC
                );
            } else {
                _depositBoost(
                    dfWallet, USDC_ADDRESS, CUSDC_ADDRESS, amountUSDC, flashloanUSDC, flashloanType, flashloanFromAddress
                );
            }
        }

        // Boost DAI deposit
        if (amountDAI > 0 || flashloanDAI > 0) {
            if (flashloanType == FlashloanProvider.DYDX
                && flashloanDAI > IToken(DAI_ADDRESS).balanceOf(SOLO_MARGIN_ADDRESS)
            ) {
                // if dYdX lacks liquidity in DAI use ETH
                _depositBoostUsingDyDxEth(
                    dfWallet, DAI_ADDRESS, CDAI_ADDRESS, amountDAI, flashloanDAI
                );
            } else {
                _depositBoost(
                    dfWallet, DAI_ADDRESS, CDAI_ADDRESS, amountDAI, flashloanDAI, flashloanType, flashloanFromAddress
                );
            }
        }

        return dfWallet;
    }


    // CLAIM function

    function claimComps(address dfWallet, address[] memory cTokens) public returns(uint256) {
        require(wallets[dfWallet].owner == msg.sender);

        IDfWallet(dfWallet).claimComp(cTokens);

        uint compTokenBalance = IToken(COMP_ADDRESS).balanceOf(address(this));
        IToken(COMP_ADDRESS).transfer(msg.sender, compTokenBalance);

        wallets[dfWallet].compClaimed += uint64(compTokenBalance / 1e12); // 6 decemals
        return compTokenBalance;
    }


    // WITHDRAW function

    function withdraw(
        address dfWallet,
        uint256 amountDAI,
        uint256 amountUSDC,
        uint256 amountETH,
        uint256 amountWBTC,
        address receiver,
        uint256 flashloanDAI,
        uint256 flashloanUSDC,
        FlashloanProvider flashloanType,
        address flashloanFromAddress
    ) public onlyOwnerOrAdmin {
        require(wallets[dfWallet].owner == msg.sender);
        require(receiver != address(0));

        // Update states
        wallets[dfWallet].deposit     = (amountDAI < wallets[dfWallet].deposit) ? sub(wallets[dfWallet].deposit, amountDAI) : 0;
        wallets[dfWallet].depositUSDC = (amountUSDC < wallets[dfWallet].depositUSDC) ? uint64(sub(wallets[dfWallet].depositUSDC, amountUSDC)) : 0;
        wallets[dfWallet].depositETH  = (amountETH < wallets[dfWallet].depositETH) ? uint96(sub(wallets[dfWallet].depositETH, amountETH)) : 0;
        wallets[dfWallet].depositWBTC = (amountWBTC < wallets[dfWallet].depositWBTC) ? uint64(sub(wallets[dfWallet].depositWBTC, amountWBTC)) : 0;

        // Withdraw assets
        _withdrawBoostedAsset(
            dfWallet, USDC_ADDRESS, CUSDC_ADDRESS, amountUSDC, receiver, flashloanUSDC, flashloanType, flashloanFromAddress
        );

        _withdrawBoostedAsset(
            dfWallet, DAI_ADDRESS, CDAI_ADDRESS, amountDAI, receiver, flashloanDAI, flashloanType, flashloanFromAddress
        );

        _withdrawAsset(
            dfWallet, ETH_ADDRESS, CETH_ADDRESS, amountETH, receiver
        );

        _withdrawAsset(
            dfWallet, WBTC_ADDRESS, CWBTC_ADDRESS, amountWBTC, receiver
        );
    }


    // ** FLASHLOAN CALLBACK functions **

    // Aave flashloan callback
    function executeOperation(
        address _reserve,
        uint256 _amountFlashLoan,
        uint256 _fee,
        bytes memory _data
    ) public {
        _flashloanHandler(_data, _fee);

        // Time to transfer the funds back
        transferFundsBackToPoolInternal(_reserve, add(_amountFlashLoan, _fee));
    }

    // dYdX flashloan callback
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        _flashloanHandler(data, 0);
    }


    // ** PRIVATE & INTERNAL functions **

    function _bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    function _depositBoost(
        address dfWallet,
        address token,
        address cToken,
        uint256 deposit,
        uint256 flashloanAmount,
        FlashloanProvider flashloanType,
        address flashloanFromAddress
    ) internal {
        // FLASHLOAN LOGIC
        state = OP.DEPOSIT;

        if (flashloanType == FlashloanProvider.DYDX) {
            _initFlashloanDyDx(
                token,
                flashloanAmount,
                // Encode FlashloanData for callFunction
                abi.encode(FlashloanData({dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, amountFlashLoan: flashloanAmount}))
            );
        } else if (flashloanType == FlashloanProvider.AAVE) {
            ILendingPool lendingPool = ILendingPool(ILendingPoolAddressesProvider(AAVE_ADDRESSES_PROVIDER).getLendingPool());
            lendingPool.flashLoan(
                address(this),
                token,
                flashloanAmount,
                // Encode FlashloanData for executeOperation
                abi.encode(FlashloanData({dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, amountFlashLoan: flashloanAmount}))
            );
        } else if (flashloanType == FlashloanProvider.ADDRESS) {
            IToken(token).universalTransferFrom(flashloanFromAddress, dfWallet, flashloanAmount);

            IDfWallet(dfWallet).deposit(token, cToken, add(deposit, flashloanAmount), token, cToken, flashloanAmount);
            IDfWallet(dfWallet).withdrawToken(token, flashloanFromAddress, flashloanAmount);
        }

        state = OP.UNKNOWN;
        // END FLASHLOAN LOGIC
    }

    function _depositBoostUsingDyDxEth(
        address dfWallet,
        address token,
        address cToken,
        uint256 deposit,
        uint256 flashloanInTokens
    ) internal {
        // FLASHLOAN LOGIC
        state = OP.DEPOSIT_USING_DYDX_ETH;

        IPriceOracle compOracle = IComptroller(COMPTROLLER).oracle();
        uint256 ethPrice = compOracle.price("ETH").mul(1e12); // with 1e18 (1e6 * 1e12)

        uint256 ethDecimals = 18;
        uint256 decimalsMultiplier = 10 ** ethDecimals.sub(IToken(token).decimals());

        // IMPORTANT: token price is equal to 1 USD
        uint256 flashloanEthAmount = wdiv(flashloanInTokens * decimalsMultiplier, ethPrice).mul(2); // use x2 coef for eth as collateral

        _initFlashloanDyDx(
            WETH_ADDRESS,
            flashloanEthAmount,
            // Encode FlashloanDataDyDxEth for callFunction
            abi.encode(FlashloanDataDyDxEth({
                dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, debt: flashloanInTokens, ethAmountFlashLoan: flashloanEthAmount
            }))
        );

        state = OP.UNKNOWN;
        // END FLASHLOAN LOGIC
    }

    function _withdrawBoostedAsset(
        address dfWallet,
        address token,
        address cToken,
        uint256 amountToken,
        address receiver,
        uint256 flashloanAmount,
        FlashloanProvider flashloanType,
        address flashloanFromAddress
    ) internal {
        if (amountToken == 0 && flashloanAmount == 0) {
            return;
        }

        if (IToken(token).allowance(address(this), dfWallet) != uint(-1)) {
            IToken(token).approve(dfWallet, uint(-1));
        }

        uint startBalance = IToken(token).universalBalanceOf(address(this));

        if (flashloanType == FlashloanProvider.DYDX
            && flashloanAmount > IToken(token).balanceOf(SOLO_MARGIN_ADDRESS)
        ) {
            // if dYdX lacks liquidity in token (DAI or USDC) use ETH
            _withdrawBoostUsingDyDxEth(
                dfWallet, token, cToken, amountToken, flashloanAmount
            );
        } else {
            _withdrawBoost(
                dfWallet, token, cToken, amountToken, flashloanAmount, flashloanType, flashloanFromAddress
            );
        }

        uint curBalance = IToken(token).universalBalanceOf(address(this));

        // rounding in token to cToken conversion
        if (curBalance <= startBalance) {
            require(wdiv(curBalance, startBalance) >= withdrawMinRatio);
            return;
        }

        uint tokensToUser = sub(curBalance, startBalance);
        if (token == ETH_ADDRESS) {
            _transferEth(receiver, tokensToUser);
        } else {
            IToken(token).universalTransfer(receiver, tokensToUser);
        }
    }

    function _withdrawAsset(
        address dfWallet,
        address token,
        address cToken,
        uint256 amountToken,
        address receiver
    ) internal {
        if (amountToken == 0) {
            return;
        }

        uint startBalance = IToken(token).universalBalanceOf(address(this));

        // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
        uint cTokenToExtract =  (amountToken != uint(-1)) ? amountToken.mul(1e36).div(ICToken(cToken).exchangeRateCurrent()).div(1e18) : uint(-1);
        IDfWallet(dfWallet).withdraw(token, cToken, cTokenToExtract, ETH_ADDRESS, CETH_ADDRESS, 0);

        uint tokensToUser = sub(IToken(token).universalBalanceOf(address(this)), startBalance);
        if (token == ETH_ADDRESS) {
            _transferEth(receiver, tokensToUser);
        } else {
            IToken(token).universalTransfer(receiver, tokensToUser);
        }
    }

    function _withdrawBoost(
        address dfWallet,
        address token,
        address cToken,
        uint256 deposit,
        uint256 flashloanAmount,
        FlashloanProvider flashloanType,
        address flashloanFromAddress
    ) internal {
        // FLASHLOAN LOGIC
        state = OP.WITHDRAW;

        if (flashloanType == FlashloanProvider.DYDX) {
            _initFlashloanDyDx(
                token,
                flashloanAmount,
                // Encode FlashloanData for callFunction
                abi.encode(FlashloanData({dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, amountFlashLoan: flashloanAmount}))
            );
        } else if (flashloanType == FlashloanProvider.AAVE) {
            ILendingPool lendingPool = ILendingPool(ILendingPoolAddressesProvider(AAVE_ADDRESSES_PROVIDER).getLendingPool());
            lendingPool.flashLoan(
                address(this),
                token,
                flashloanAmount,
                // Encode FlashloanData for executeOperation
                abi.encode(FlashloanData({dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, amountFlashLoan: flashloanAmount}))
            );
        } else if (flashloanType == FlashloanProvider.ADDRESS) {
            IToken(token).universalTransferFrom(flashloanFromAddress, dfWallet, flashloanAmount);

            // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
            uint cTokenToExtract = (deposit != uint(-1)) ? deposit.add(flashloanAmount).mul(1e36).div(ICToken(cToken).exchangeRateCurrent()).div(1e18) : uint(-1);
            IDfWallet(dfWallet).withdraw(token, cToken, cTokenToExtract, token, cToken, flashloanAmount);

            IToken(token).universalTransfer(flashloanFromAddress, flashloanAmount);
        }

        state = OP.UNKNOWN;
        // END FLASHLOAN LOGIC
    }

    function _withdrawBoostUsingDyDxEth(
        address dfWallet,
        address token,
        address cToken,
        uint256 deposit,
        uint256 flashloanInTokens
    ) internal {
        // FLASHLOAN LOGIC
        state = OP.WITHDRAW_USING_DYDX_ETH;

        IPriceOracle compOracle = IComptroller(COMPTROLLER).oracle();
        uint256 ethPrice = compOracle.price("ETH").mul(1e12); // with 1e18 (1e6 * 1e12)

        uint256 ethDecimals = 18;
        uint256 decimalsMultiplier = 10 ** ethDecimals.sub(IToken(token).decimals());

        // IMPORTANT: token price is equal to 1 USD
        uint256 flashloanEthAmount = wdiv(flashloanInTokens * decimalsMultiplier, ethPrice).mul(2); // use x2 coef for eth as collateral

        _initFlashloanDyDx(
            WETH_ADDRESS,
            flashloanEthAmount,
            // Encode FlashloanDataDyDxEth for callFunction
            abi.encode(FlashloanDataDyDxEth({
                dfWallet: dfWallet, token: token, cToken: cToken, deposit: deposit, debt: flashloanInTokens, ethAmountFlashLoan: flashloanEthAmount
            }))
        );

        state = OP.UNKNOWN;
        // END FLASHLOAN LOGIC
    }

    function _flashloanHandler(
        bytes memory data,
        uint fee
    ) internal {
        require(state != OP.UNKNOWN);

        if (state == OP.DEPOSIT) {
            FlashloanData memory flashloanData = abi.decode(data, (FlashloanData));

            // Calculate repay amount
            uint totalDebt = add(flashloanData.amountFlashLoan, fee);

            IToken(flashloanData.token).transfer(flashloanData.dfWallet, flashloanData.amountFlashLoan);

            IDfWallet(flashloanData.dfWallet).deposit(
                flashloanData.token, flashloanData.cToken, add(flashloanData.deposit, flashloanData.amountFlashLoan), flashloanData.token, flashloanData.cToken, totalDebt
            );

            IDfWallet(flashloanData.dfWallet).withdrawToken(flashloanData.token, address(this), totalDebt);
        } else if (state == OP.WITHDRAW) {
            FlashloanData memory flashloanData = abi.decode(data, (FlashloanData));

            // _withdrawBoost() subtracts flashloan fee
            // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
            uint cTokenToExtract = (flashloanData.deposit != uint(-1)) ? flashloanData.deposit.add(flashloanData.amountFlashLoan).mul(1e36).div(ICToken(flashloanData.cToken).exchangeRateCurrent()).div(1e18) : uint(-1);

            IDfWallet(flashloanData.dfWallet).withdraw(flashloanData.token, flashloanData.cToken, cTokenToExtract, flashloanData.token, flashloanData.cToken, flashloanData.amountFlashLoan);
            // require(flashloanData.amountFlashLoan.div(3) >= sub(receivedAmount, _fee), "Fee greater then user amount"); // user pay fee for flash loan
        } else if (state == OP.DEPOSIT_USING_DYDX_ETH) {
            // use dYdX flashloans without fee
            FlashloanDataDyDxEth memory flashloanData = abi.decode(data, (FlashloanDataDyDxEth));
            uint256 loanEth = flashloanData.ethAmountFlashLoan;

            // WETH to ETH for loan using proxy (eth transfer gas limit)
            IDfProxy dfProxy = IDfProxy(DF_PROXY_ADDRESS);
            IERC20(WETH_ADDRESS).transfer(address(dfProxy), loanEth);
            dfProxy.cast(address(uint160(WETH_ADDRESS)), abi.encodeWithSelector(IWeth(WETH_ADDRESS).withdraw.selector, loanEth));
            dfProxy.withdrawEth(address(this));

            // deposit eth loan and borrow debt tokens
            IDfWallet(flashloanData.dfWallet).deposit.value(loanEth)(
                ETH_ADDRESS, CETH_ADDRESS, loanEth, flashloanData.token, flashloanData.cToken, flashloanData.debt
            );

            // deposit user deposit + debt tokens (are already on the dfWallet)
            IDfWallet(flashloanData.dfWallet).deposit(
                flashloanData.token, flashloanData.cToken, add(flashloanData.deposit, flashloanData.debt), address(0), address(0), 0
            );

            // redeem eth loan (using withdraw function)
            // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
            uint cEthToExtract = loanEth.mul(1e36).div(ICToken(CETH_ADDRESS).exchangeRateCurrent()).div(1e18);
            IDfWallet(flashloanData.dfWallet).withdraw(
                ETH_ADDRESS, CETH_ADDRESS, cEthToExtract, ETH_ADDRESS, CETH_ADDRESS, 0
            );

            // ETH to WETH for loan
            IWeth(WETH_ADDRESS).deposit.value(loanEth)();
        } else if (state == OP.WITHDRAW_USING_DYDX_ETH) {
            // use dYdX flashloans without fee
            FlashloanDataDyDxEth memory flashloanData = abi.decode(data, (FlashloanDataDyDxEth));
            uint256 loanEth = flashloanData.ethAmountFlashLoan;

            // WETH to ETH for loan using proxy (eth transfer gas limit)
            IDfProxy dfProxy = IDfProxy(DF_PROXY_ADDRESS);
            IERC20(WETH_ADDRESS).transfer(address(dfProxy), loanEth);
            dfProxy.cast(address(uint160(WETH_ADDRESS)), abi.encodeWithSelector(IWeth(WETH_ADDRESS).withdraw.selector, loanEth));
            dfProxy.withdrawEth(address(this));

            // deposit eth loan and borrow debt tokens
            IDfWallet(flashloanData.dfWallet).deposit.value(loanEth)(
                ETH_ADDRESS, CETH_ADDRESS, loanEth, flashloanData.token, flashloanData.cToken, flashloanData.debt
            );
            IDfWallet(flashloanData.dfWallet).withdrawToken(flashloanData.token, address(this), flashloanData.debt);

            // repay debt tokens and redeem deposit + debt tokens
            // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
            uint cTokenToExtract = (flashloanData.deposit != uint(-1)) ? flashloanData.deposit.add(flashloanData.debt).mul(1e36).div(ICToken(flashloanData.cToken).exchangeRateCurrent()).div(1e18) : uint(-1);
            IDfWallet(flashloanData.dfWallet).withdraw(
                flashloanData.token, flashloanData.cToken, cTokenToExtract, flashloanData.token, flashloanData.cToken, flashloanData.debt
            );

            // repay debt tokens and redeem eth loan
            // Compound Quick Maths – redeemAmountIn * 1e18 * 1e18 / exchangeRateCurrent / 1e18
            uint cEthToExtract = loanEth.mul(1e36).div(ICToken(CETH_ADDRESS).exchangeRateCurrent()).div(1e18);
            IDfWallet(flashloanData.dfWallet).withdraw(
                ETH_ADDRESS, CETH_ADDRESS, cEthToExtract, flashloanData.token, flashloanData.cToken, flashloanData.debt
            );

            // ETH to WETH for loan
            IWeth(WETH_ADDRESS).deposit.value(loanEth)();
        }
    }

    function _transferEth(address _receiver, uint _amount) internal {
        address payable receiverPayable = address(uint160(_receiver));
        (bool result, ) = receiverPayable.call.value(_amount)("");
        require(result, "Transfer of ETH failed");
    }


    // **FALLBACK functions**
    function() external payable {}

}

pragma solidity ^0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
// import "../openzeppelin/upgrades/contracts/Initializable.sol";
import "./Ownable.sol";
import "../utils/UniversalERC20.sol";


contract FundsManager is Initializable, Ownable {
    using UniversalERC20 for IToken;

    // Initializer – Constructor for Upgradable contracts
    function initialize() public initializer {
        Ownable.initialize();  // Initialize Parent Contract
    }

    function initialize(address payable newOwner) public initializer {
        Ownable.initialize(newOwner);  // Initialize Parent Contract
    }


    function withdraw(address token, uint256 amount) public onlyOwner {
        if (token == address(0x0)) {
            owner.transfer(amount);
        } else {
            IToken(token).universalTransfer(owner, amount);
        }
    }

    function withdrawAll(address[] memory tokens) public onlyOwner {
        for(uint256 i = 0; i < tokens.length;i++) {
            withdraw(tokens[i], IToken(tokens[i]).universalBalanceOf(address(this)));
        }
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
// import "../openzeppelin/upgrades/contracts/Initializable.sol";


contract Ownable is Initializable {
    address payable public owner;
    address payable internal newOwnerCandidate;


    modifier onlyOwner {
        require(msg.sender == owner, "Permission denied");
        _;
    }


    // ** INITIALIZERS – Constructors for Upgradable contracts **

    function initialize() public initializer {
        owner = msg.sender;
    }

    function initialize(address payable newOwner) public initializer {
        owner = newOwner;
    }


    function changeOwner(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate, "Permission denied");
        owner = newOwnerCandidate;
    }


    uint256[50] private ______gap;
}

pragma solidity ^0.5.16;

// import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
// import "./SafeMath.sol";
import "./SafeERC20.sol";

import "../interfaces/IToken.sol";

library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IToken;

    IToken private constant ZERO_ADDRESS = IToken(0x0000000000000000000000000000000000000000);
    IToken private constant ETH_ADDRESS = IToken(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IToken token, address to, uint256 amount) internal {
        universalTransfer(token, to, amount, false);
    }

    function universalTransfer(IToken token, address to, uint256 amount, bool mayFail) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            if (mayFail) {
                return address(uint160(to)).send(amount);
            } else {
                address(uint160(to)).transfer(amount);
                return true;
            }
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalApprove(IToken token, address to, uint256 amount) internal {
        if (token != ZERO_ADDRESS && token != ETH_ADDRESS) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(IToken token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            require(from == msg.sender && msg.value >= amount, "msg.value is zero");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(uint256(msg.value).sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IToken token, address who) internal view returns (uint256) {
        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}

pragma solidity ^0.5.16;

// import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./SafeMath.sol";
// import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "./Address.sol";

import "../interfaces/IToken.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IToken token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IToken token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IToken token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IToken token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IToken token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IToken token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.16;

interface IToken {
    function decimals() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function deposit() external payable;
    function mint(address, uint256) external;
    function withdraw(uint amount) external;
    function totalSupply() view external returns (uint256);
    function burnFrom(address account, uint256 amount) external;
}

pragma solidity ^0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
// import "../openzeppelin/upgrades/contracts/Initializable.sol";

import "./Ownable.sol";


contract Adminable is Initializable, Ownable {
    mapping(address => bool) public admins;


    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner ||
                admins[msg.sender], "Permission denied");
        _;
    }


    // Initializer – Constructor for Upgradable contracts
    function initialize() public initializer {
        Ownable.initialize();  // Initialize Parent Contract
    }

    function initialize(address payable newOwner) public initializer {
        Ownable.initialize(newOwner);  // Initialize Parent Contract
    }


    function setAdminPermission(address _admin, bool _status) public onlyOwner {
        admins[_admin] = _status;
    }

//    function setAdminPermission(address[] memory _admins, bool _status) public onlyOwner {
//        for (uint i = 0; i < _admins.length; i++) {
//            admins[_admins[i]] = _status;
//        }
//    }


    uint256[50] private ______gap;
}

pragma solidity ^0.5.16;


contract ConstantAddresses {
    address public constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
//    address public constant COMPOUND_ORACLE = 0x1D8aEdc9E924730DD3f9641CDb4D1B92B848b4bd;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant CUSDC_ADDRESS = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;

    address public constant WBTC_ADDRESS = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant CWBTC_ADDRESS = 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4;

    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant CDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    address public constant COMP_ADDRESS = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // proxy for eth transfer (gas limit)
    address public constant DF_PROXY_ADDRESS = 0x7a925f91a4583E87b355f6CE15B2C3BF26E3449F;
}

pragma solidity ^0.5.0;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
//    function imin(int x, int y) internal pure returns (int z) {
//        return x <= y ? x : y;
//    }
//    function imax(int x, int y) internal pure returns (int z) {
//        return x >= y ? x : y;
//    }

    uint constant WAD = 10 ** 18;
//    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y, uint base) internal pure returns (uint z) {
        z = add(mul(x, y), base / 2) / base;
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
//    function rmul(uint x, uint y) internal pure returns (uint z) {
//        z = add(mul(x, y), RAY / 2) / RAY;
//    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
//    function rdiv(uint x, uint y) internal pure returns (uint z) {
//        z = add(mul(x, RAY), y / 2) / y;
//    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    /*function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }*/
}

pragma solidity ^0.5.0;

// import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IToken.sol";

import "../interfaces/IFlashLoanReceiver.sol";
import "../interfaces/ILendingPoolAddressesProvider.sol";

import "../../utils/SafeERC20.sol";
import "../../utils/EthAddressLib.sol";


contract FlashLoanReceiverBase is IFlashLoanReceiver {

    using SafeERC20 for IToken;


    // Mainnet Aave LendingPoolAddressesProvider address
     address public constant AAVE_ADDRESSES_PROVIDER = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

    // Kovan Aave LendingPoolAddressesProvider addres
    // address public constant AAVE_ADDRESSES_PROVIDER = 0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5;


    function transferFundsBackToPoolInternal(address _reserve, uint256 _amount) internal {
        address payable core = ILendingPoolAddressesProvider(AAVE_ADDRESSES_PROVIDER).getLendingPoolCore();
        transferInternal(core, _reserve, _amount);
    }

    function transferInternal(address _destination, address _reserve, uint256  _amount) internal {

        if(_reserve == EthAddressLib.ethAddress()) {
            address payable receiverPayable = address(uint160(_destination));

            //solium-disable-next-line
            (bool result, ) = receiverPayable.call.value(_amount)("");

            require(result, "Transfer of ETH failed");
            return;
        }

        IToken(_reserve).safeTransfer(_destination, _amount);
    }

    function getBalanceInternal(address _target, address _reserve) internal view returns(uint256) {
        if(_reserve == EthAddressLib.ethAddress()) {
            return _target.balance;
        }

        return IToken(_reserve).balanceOf(_target);
    }

}

pragma solidity ^0.5.16;

/**
* @title IFlashLoanReceiver interface
* @notice Interface for the Aave fee IFlashLoanReceiver.
* @author Aave
* @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
**/
interface IFlashLoanReceiver {

    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

pragma solidity ^0.5.0;


/**
@title ILendingPoolAddressesProvider interface
@notice provides the interface to fetch the LendingPoolCore address
 */
interface ILendingPoolAddressesProvider {

    function getLendingPool() external view returns (address);
    function setLendingPoolImpl(address _pool) external;

    function getLendingPoolCore() external view returns (address payable);
    function setLendingPoolCoreImpl(address _lendingPoolCore) external;

    function getLendingPoolConfigurator() external view returns (address);
    function setLendingPoolConfiguratorImpl(address _configurator) external;

    function getLendingPoolDataProvider() external view returns (address);
    function setLendingPoolDataProviderImpl(address _provider) external;

    function getLendingPoolParametersProvider() external view returns (address);
    function setLendingPoolParametersProviderImpl(address _parametersProvider) external;

    function getTokenDistributor() external view returns (address);
    function setTokenDistributor(address _tokenDistributor) external;


    function getFeeProvider() external view returns (address);
    function setFeeProviderImpl(address _feeProvider) external;

    function getLendingPoolLiquidationManager() external view returns (address);
    function setLendingPoolLiquidationManager(address _manager) external;

    function getLendingPoolManager() external view returns (address);
    function setLendingPoolManager(address _lendingPoolManager) external;

    function getPriceOracle() external view returns (address);
    function setPriceOracle(address _priceOracle) external;

    function getLendingRateOracle() external view returns (address);
    function setLendingRateOracle(address _lendingRateOracle) external;

}

pragma solidity ^0.5.0;


library EthAddressLib {

    /**
    * @dev returns the address used within the protocol to identify ETH
    * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./helpers/DydxFlashloanBase.sol";
import "./helpers/ICallee.sol";


contract FlashloanDyDx is
    ICallee,
    DydxFlashloanBase
{

    address public constant SOLO_MARGIN_ADDRESS = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    function _initFlashloanDyDx(
        address _token,
        uint256 _amount,
        bytes memory _data  // data to callFunction()
    ) internal {
        ISoloMargin solo = ISoloMargin(SOLO_MARGIN_ADDRESS);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(address(solo), _token);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_amount);
        IERC20(_token).approve(address(solo), repayAmount);

        // 1. Withdraw tokens
        // 2. Call callFunction()
        // 3. Deposit back tokens
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(_data);
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);
    }
}

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "../../utils/SafeMath.sol";
import "../../interfaces/IERC20.sol";

import "./ISoloMargin.sol";


contract DydxFlashloanBase {
    using SafeMath for uint256;

    // -- Internal Helper functions -- //

    function _getMarketIdFromTokenAddress(address _solo, address token)
        internal
        view
        returns (uint256)
    {
        ISoloMargin solo = ISoloMargin(_solo);

        uint256 numMarkets = solo.getNumMarkets();

        address curToken;
        for (uint256 i = 0; i < numMarkets; i++) {
            curToken = solo.getMarketTokenAddress(i);

            if (curToken == token) {
                return i;
            }
        }

        revert("No marketId found for provided token");
    }

    function _getRepaymentAmountInternal(uint256 amount)
        internal
        view
        returns (uint256)
    {
        // Needs to be overcollateralize
        // Needs to provide +2 wei to be safe
        return amount.add(2);
    }

    function _getAccountInfo() internal view returns (Account.Info memory) {
        return Account.Info({owner: address(this), number: 1});
    }

    function _getWithdrawAction(uint marketId, uint256 amount)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Withdraw,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }

    function _getCallAction(bytes memory data)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Call,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: 0
                }),
                primaryMarketId: 0,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: data
            });
    }

    function _getDepositAction(uint marketId, uint256 amount)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Deposit,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: true,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


library Account {
    enum Status {Normal, Liquid, Vapor}
    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
    struct Storage {
        mapping(uint256 => Types.Par) balances; // Mapping from marketId to principal
        Status status;
    }
}


library Actions {
    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (publicly)
        Sell, // sell an amount of some token (publicly)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }

    enum AccountLayout {OnePrimary, TwoPrimary, PrimaryAndSecondary}

    enum MarketLayout {ZeroMarkets, OneMarket, TwoMarkets}

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    struct TransferArgs {
        Types.AssetAmount amount;
        Account.Info accountOne;
        Account.Info accountTwo;
        uint256 market;
    }

    struct BuyArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 makerMarket;
        uint256 takerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct SellArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 takerMarket;
        uint256 makerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct TradeArgs {
        Types.AssetAmount amount;
        Account.Info takerAccount;
        Account.Info makerAccount;
        uint256 inputMarket;
        uint256 outputMarket;
        address autoTrader;
        bytes tradeData;
    }

    struct LiquidateArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info liquidAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct VaporizeArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info vaporAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct CallArgs {
        Account.Info account;
        address callee;
        bytes data;
    }
}


library Decimal {
    struct D256 {
        uint256 value;
    }
}


library Interest {
    struct Rate {
        uint256 value;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }
}


library Monetary {
    struct Price {
        uint256 value;
    }
    struct Value {
        uint256 value;
    }
}


library Storage {
    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;
        // Total aggregated supply and borrow amount of the entire market
        Types.TotalPar totalPar;
        // Interest index of the market
        Interest.Index index;
        // Contract address of the price oracle for this market
        address priceOracle;
        // Contract address of the interest setter for this market
        address interestSetter;
        // Multiplier on the marginRatio for this market
        Decimal.D256 marginPremium;
        // Multiplier on the liquidationSpread for this market
        Decimal.D256 spreadPremium;
        // Whether additional borrows are allowed for this market
        bool isClosing;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal.D256 marginRatio;
        // Percentage penalty incurred by liquidated accounts
        Decimal.D256 liquidationSpread;
        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal.D256 earningsRate;
        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Monetary.Value minBorrowedValue;
    }

    // The maximum RiskParam values that can be set
    struct RiskLimits {
        uint64 marginRatioMax;
        uint64 liquidationSpreadMax;
        uint64 earningsRateMax;
        uint64 marginPremiumMax;
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    // The entire storage state of Solo
    struct State {
        // number of markets
        uint256 numMarkets;
        // marketId => Market
        mapping(uint256 => Market) markets;
        // owner => account number => Account
        mapping(address => mapping(uint256 => Account.Storage)) accounts;
        // Addresses that can control other users accounts
        mapping(address => mapping(address => bool)) operators;
        // Addresses that can control all users accounts
        mapping(address => bool) globalOperators;
        // mutable risk parameters of the system
        RiskParams riskParams;
        // immutable risk limits of the system
        RiskLimits riskLimits;
    }
}


library Types {
    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct Par {
        bool sign; // true if positive
        uint128 value;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}


contract ISoloMargin {
    struct OperatorArg {
        address operator;
        bool trusted;
    }

    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal.D256 memory spreadPremium
    ) public;

    function getIsGlobalOperator(address operator) public view returns (bool);

    function getMarketTokenAddress(uint256 marketId)
        public
        view
        returns (address);

    function ownerSetInterestSetter(uint256 marketId, address interestSetter)
        public;

    function getAccountValues(Account.Info memory account)
        public
        view
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketPriceOracle(uint256 marketId)
        public
        view
        returns (address);

    function getMarketInterestSetter(uint256 marketId)
        public
        view
        returns (address);

    function getMarketSpreadPremium(uint256 marketId)
        public
        view
        returns (Decimal.D256 memory);

    function getNumMarkets() public view returns (uint256);

    function ownerWithdrawUnsupportedTokens(address token, address recipient)
        public
        returns (uint256);

    function ownerSetMinBorrowedValue(Monetary.Value memory minBorrowedValue)
        public;

    function ownerSetLiquidationSpread(Decimal.D256 memory spread) public;

    function ownerSetEarningsRate(Decimal.D256 memory earningsRate) public;

    function getIsLocalOperator(address owner, address operator)
        public
        view
        returns (bool);

    function getAccountPar(Account.Info memory account, uint256 marketId)
        public
        view
        returns (Types.Par memory);

    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal.D256 memory marginPremium
    ) public;

    function getMarginRatio() public view returns (Decimal.D256 memory);

    function getMarketCurrentIndex(uint256 marketId)
        public
        view
        returns (Interest.Index memory);

    function getMarketIsClosing(uint256 marketId) public view returns (bool);

    function getRiskParams() public view returns (Storage.RiskParams memory);

    function getAccountBalances(Account.Info memory account)
        public
        view
        returns (address[] memory, Types.Par[] memory, Types.Wei[] memory);

    function renounceOwnership() public;

    function getMinBorrowedValue() public view returns (Monetary.Value memory);

    function setOperators(OperatorArg[] memory args) public;

    function getMarketPrice(uint256 marketId) public view returns (address);

    function owner() public view returns (address);

    function isOwner() public view returns (bool);

    function ownerWithdrawExcessTokens(uint256 marketId, address recipient)
        public
        returns (uint256);

    function ownerAddMarket(
        address token,
        address priceOracle,
        address interestSetter,
        Decimal.D256 memory marginPremium,
        Decimal.D256 memory spreadPremium
    ) public;

    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) public;

    function getMarketWithInfo(uint256 marketId)
        public
        view
        returns (
            Storage.Market memory,
            Interest.Index memory,
            Monetary.Price memory,
            Interest.Rate memory
        );

    function ownerSetMarginRatio(Decimal.D256 memory ratio) public;

    function getLiquidationSpread() public view returns (Decimal.D256 memory);

    function getAccountWei(Account.Info memory account, uint256 marketId)
        public
        view
        returns (Types.Wei memory);

    function getMarketTotalPar(uint256 marketId)
        public
        view
        returns (Types.TotalPar memory);

    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) public view returns (Decimal.D256 memory);

    function getNumExcessTokens(uint256 marketId)
        public
        view
        returns (Types.Wei memory);

    function getMarketCachedIndex(uint256 marketId)
        public
        view
        returns (Interest.Index memory);

    function getAccountStatus(Account.Info memory account)
        public
        view
        returns (uint8);

    function getEarningsRate() public view returns (Decimal.D256 memory);

    function ownerSetPriceOracle(uint256 marketId, address priceOracle) public;

    function getRiskLimits() public view returns (Storage.RiskLimits memory);

    function getMarket(uint256 marketId)
        public
        view
        returns (Storage.Market memory);

    function ownerSetIsClosing(uint256 marketId, bool isClosing) public;

    function ownerSetGlobalOperator(address operator, bool approved) public;

    function transferOwnership(address newOwner) public;

    function getAdjustedAccountValues(Account.Info memory account)
        public
        view
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketMarginPremium(uint256 marketId)
        public
        view
        returns (Decimal.D256 memory);

    function getMarketInterestRate(uint256 marketId)
        public
        view
        returns (Interest.Rate memory);
}

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "./ISoloMargin.sol";


/**
 * @title ICallee
 * @author dYdX
 *
 * Interface that Callees for Solo must implement in order to ingest data.
 */
contract ICallee {

    // ============ Public Functions ============

    /**
     * Allows users to send this contract arbitrary data.
     *
     * @param  sender       The msg.sender to Solo
     * @param  accountInfo  The account from which the data is being sent
     * @param  data         Arbitrary data given by the sender
     */
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    )
        public;
}

pragma solidity ^0.5.16;

interface ICToken {
    function borrowIndex() view external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrow() external payable;

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower) external payable;

    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral)
        external
        returns (uint256);

    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function borrowRatePerBlock() external returns (uint256);

    function totalReserves() external returns (uint256);

    function reserveFactorMantissa() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function getCash() external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function balanceOf(address owner) view external returns (uint256);

    function underlying() external returns (address);
}

pragma solidity ^0.5.16;

interface ILendingPool {
    function addressesProvider () external view returns ( address );
    function deposit ( address _reserve, uint256 _amount, uint16 _referralCode ) external payable;
    function redeemUnderlying ( address _reserve, address _user, uint256 _amount ) external;
    function borrow ( address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode ) external;
    function repay ( address _reserve, uint256 _amount, address _onBehalfOf ) external payable;
    function swapBorrowRateMode ( address _reserve ) external;
    function rebalanceFixedBorrowRate ( address _reserve, address _user ) external;
    function setUserUseReserveAsCollateral ( address _reserve, bool _useAsCollateral ) external;
    function liquidationCall ( address _collateral, address _reserve, address _user, uint256 _purchaseAmount, bool _receiveAToken ) external payable;
    function flashLoan ( address _receiver, address _reserve, uint256 _amount, bytes calldata _params ) external;
    function getReserveConfigurationData ( address _reserve ) external view returns ( uint256 ltv, uint256 liquidationThreshold, uint256 liquidationDiscount, address interestRateStrategyAddress, bool usageAsCollateralEnabled, bool borrowingEnabled, bool fixedBorrowRateEnabled, bool isActive );
    function getReserveData ( address _reserve ) external view returns ( uint256 totalLiquidity, uint256 availableLiquidity, uint256 totalBorrowsFixed, uint256 totalBorrowsVariable, uint256 liquidityRate, uint256 variableBorrowRate, uint256 fixedBorrowRate, uint256 averageFixedBorrowRate, uint256 utilizationRate, uint256 liquidityIndex, uint256 variableBorrowIndex, address aTokenAddress, uint40 lastUpdateTimestamp );
    function getUserAccountData ( address _user ) external view returns ( uint256 totalLiquidityETH, uint256 totalCollateralETH, uint256 totalBorrowsETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor );
    function getUserReserveData ( address _reserve, address _user ) external view returns ( uint256 currentATokenBalance, uint256 currentUnderlyingBalance, uint256 currentBorrowBalance, uint256 principalBorrowBalance, uint256 borrowRateMode, uint256 borrowRate, uint256 liquidityRate, uint256 originationFee, uint256 variableBorrowIndex, uint256 lastUpdateTimestamp, bool usageAsCollateralEnabled );
    function getReserves () external view;
}

pragma solidity ^0.5.16;

interface IDfWalletFactory {
    function createDfWallet() external returns (address dfWallet);
}

pragma solidity ^0.5.16;

interface IDfWallet {

    function claimComp(address[] calldata cTokens) external;

    function borrow(address _cTokenAddr, uint _amount) external;

    function setDfFinanceClose(address _dfFinanceClose) external;

    function deposit(
        address _tokenIn, address _cTokenIn, uint _amountIn, address _tokenOut, address _cTokenOut, uint _amountOut
    ) external payable;

    function withdraw(
        address _tokenIn, address _cTokenIn, address _tokenOut, address _cTokenOut
    ) external payable;

    function withdraw(
        address _tokenIn, address _cTokenIn, uint256 amountRedeem, address _tokenOut, address _cTokenOut, uint256 amountPayback
    ) external payable returns(uint256);

    function withdrawToken(address _tokenAddr, address to, uint256 amount) external;

    function redeem(address _tokenAddr, address _cTokenAddr, uint256 amount) external; 

}

pragma solidity ^0.5.16;

interface IComptrollerLensInterface {
    function markets(address) external view returns (bool, uint);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
    function claimComp(address) external;
    function compAccrued(address) external view returns (uint);
}

pragma solidity ^0.5.16;

import "./IPriceOracle.sol";

interface IComptroller {
    function oracle() external view returns (IPriceOracle);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

pragma solidity ^0.5.16;

interface IPriceOracle {
    function price(string calldata symbol) external view returns (uint);
}

pragma solidity ^0.5.16;

interface IWeth {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

pragma solidity ^0.5.16;

interface IDfProxy {
    function cast(address payable _to, bytes calldata _data) external payable;
    function withdrawEth(address payable _to) external;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}