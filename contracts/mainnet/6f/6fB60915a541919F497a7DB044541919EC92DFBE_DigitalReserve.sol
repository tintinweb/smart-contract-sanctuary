// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/Uniswap/IUniswapV2Factory.sol";
import "./interfaces/Uniswap/IUniswapV2Pair.sol";
import "./interfaces/Uniswap/IUniswapV2Router02.sol";
import "./interfaces/IDigitalReserve.sol";

/**
 * @dev Implementation of Digital Reserve contract.
 * Digital Reserve contract converts user's DRC into a set of SoV assets using the Uniswap router,
 * and hold these assets for it's users.
 * When users initiate a withdrawal action, the contract converts a share of the vault,
 * that the user is requesting, to DRC and sends it back to their wallet.
 */
contract DigitalReserve is IDigitalReserve, ERC20, Ownable {
    using SafeMath for uint256;

    struct StategyToken {
        address tokenAddress;
        uint8 tokenPercentage;
    }

    /**
     * @dev Set Uniswap router address, DRC token address, DR name.
     */
    constructor(
        address _router,
        address _drcAddress,
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) {
        drcAddress = _drcAddress;
        uniswapRouter = IUniswapV2Router02(_router);
    }

    StategyToken[] private _strategyTokens;
    uint8 private _feeFraction = 1;
    uint8 private _feeBase = 100;
    uint8 private constant _priceDecimals = 18;

    address private drcAddress;

    bool private depositEnabled = false;

    IUniswapV2Router02 private immutable uniswapRouter;

    /**
     * @dev See {IDigitalReserve-strategyTokenCount}.
     */
    function strategyTokenCount() public view override returns (uint256) {
        return _strategyTokens.length;
    }

    /**
     * @dev See {IDigitalReserve-strategyTokens}.
     */
    function strategyTokens(uint8 index) external view override returns (address, uint8) {
        return (_strategyTokens[index].tokenAddress, _strategyTokens[index].tokenPercentage);
    }

    /**
     * @dev See {IDigitalReserve-withdrawalFee}.
     */
    function withdrawalFee() external view override returns (uint8, uint8) {
        return (_feeFraction, _feeBase);
    }

    /**
     * @dev See {IDigitalReserve-priceDecimals}.
     */
    function priceDecimals() external view override returns (uint8) {
        return _priceDecimals;
    }

    /**
     * @dev See {IDigitalReserve-totalTokenStored}.
     */
    function totalTokenStored() public view override returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](strategyTokenCount());
        for (uint8 i = 0; i < strategyTokenCount(); i++) {
            amounts[i] = IERC20(_strategyTokens[i].tokenAddress).balanceOf(address(this));
        }
        return amounts;
    }

    /**
     * @dev See {IDigitalReserve-getUserVaultInDrc}.
     */
    function getUserVaultInDrc(
        address user, 
        uint8 percentage
    ) public view override returns (uint256, uint256, uint256) {
        uint256[] memory userStrategyTokens = _getStrategyTokensByPodAmount(balanceOf(user).mul(percentage).div(100));
        uint256 userVaultWorthInEth = _getEthAmountByStrategyTokensAmount(userStrategyTokens, true);
        uint256 userVaultWorthInEthAfterSwap = _getEthAmountByStrategyTokensAmount(userStrategyTokens, false);

        uint256 drcAmountBeforeFees = _getTokenAmountByEthAmount(userVaultWorthInEth, drcAddress, true);

        uint256 fees = userVaultWorthInEthAfterSwap.mul(_feeFraction).div(_feeBase + _feeFraction);
        uint256 drcAmountAfterFees = _getTokenAmountByEthAmount(userVaultWorthInEthAfterSwap.sub(fees), drcAddress, false);

        return (drcAmountBeforeFees, drcAmountAfterFees, fees);
    }

    /**
     * @dev See {IDigitalReserve-getProofOfDepositPrice}.
     */
    function getProofOfDepositPrice() public view override returns (uint256) {
        uint256 proofOfDepositPrice = 0;
        if (totalSupply() > 0) {
            proofOfDepositPrice = _getEthAmountByStrategyTokensAmount(totalTokenStored(), true).mul(1e18).div(totalSupply());
        }
        return proofOfDepositPrice;
    }

    /**
     * @dev See {IDigitalReserve-depositPriceImpact}.
     */
    function depositPriceImpact(uint256 drcAmount) public view override returns (uint256) {
        uint256 ethWorth = _getEthAmountByTokenAmount(drcAmount, drcAddress, false);
        return _getEthToStrategyTokensPriceImpact(ethWorth);
    }

    /**
     * @dev See {IDigitalReserve-depositDrc}.
     */
    function depositDrc(uint256 drcAmount, uint32 deadline) external override {
        require(strategyTokenCount() >= 1, "Strategy hasn't been set.");
        require(depositEnabled, "Deposit is disabled.");
        require(IERC20(drcAddress).allowance(msg.sender, address(this)) >= drcAmount, "Contract is not allowed to spend user's DRC.");
        require(IERC20(drcAddress).balanceOf(msg.sender) >= drcAmount, "Attempted to deposit more than balance.");

        uint256 swapPriceImpact = depositPriceImpact(drcAmount);
        uint256 feeImpact = (_feeFraction * 10000) / (_feeBase + _feeFraction);
        require(swapPriceImpact <= 100 + feeImpact, "Price impact on this swap is larger than 1% plus fee percentage.");

        SafeERC20.safeTransferFrom(IERC20(drcAddress), msg.sender, address(this), drcAmount);

        // Get current unit price before adding tokens to vault
        uint256 currentPodUnitPrice = getProofOfDepositPrice();

        uint256 ethConverted = _convertTokenToEth(drcAmount, drcAddress, deadline);
        _convertEthToStrategyTokens(ethConverted, deadline);

        uint256 podToMint = 0;
        if (totalSupply() == 0) {
            podToMint = drcAmount.mul(1e15);
        } else {
            uint256 vaultTotalInEth = _getEthAmountByStrategyTokensAmount(totalTokenStored(), true);
            uint256 newPodTotal = vaultTotalInEth.mul(1e18).div(currentPodUnitPrice);
            podToMint = newPodTotal.sub(totalSupply());
        }

        _mint(msg.sender, podToMint);

        emit Deposit(msg.sender, drcAmount, podToMint, totalSupply(), totalTokenStored());
    }

    /**
     * @dev See {IDigitalReserve-withdrawDrc}.
     */
    function withdrawDrc(uint256 drcAmount, uint32 deadline) external override {
        require(balanceOf(msg.sender) > 0, "Vault balance is 0");
        
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = drcAddress;

        uint256 ethNeeded = uniswapRouter.getAmountsIn(drcAmount, path)[0];
        uint256 ethNeededPlusFee = ethNeeded.mul(_feeBase + _feeFraction).div(_feeBase);

        uint256[] memory userStrategyTokens = _getStrategyTokensByPodAmount(balanceOf(msg.sender));
        uint256 userVaultWorth = _getEthAmountByStrategyTokensAmount(userStrategyTokens, false);

        require(userVaultWorth >= ethNeededPlusFee, "Attempt to withdraw more than user's holding.");

        uint256 amountFraction = ethNeededPlusFee.mul(1e10).div(userVaultWorth);
        uint256 podToBurn = balanceOf(msg.sender).mul(amountFraction).div(1e10);

        _withdrawProofOfDeposit(podToBurn, deadline);
    }

    /**
     * @dev See {IDigitalReserve-withdrawPercentage}.
     */
    function withdrawPercentage(uint8 percentage, uint32 deadline) external override {
        require(balanceOf(msg.sender) > 0, "Vault balance is 0");
        require(percentage <= 100, "Attempt to withdraw more than 100% of the asset");

        uint256 podToBurn = balanceOf(msg.sender).mul(percentage).div(100);
        _withdrawProofOfDeposit(podToBurn, deadline);
    }

    /**
     * @dev Enable or disable deposit.
     * @param status Deposit allowed or not
     * Disable deposit if it is to protect users' fund if there's any security issue or assist DR upgrade.
     */
    function changeDepositStatus(bool status) external onlyOwner {
        depositEnabled = status;
    }

    /**
     * @dev Change withdrawal fee percentage.
     * If 1%, then input (1,100)
     * If 0.5%, then input (5,1000)
     * @param withdrawalFeeFraction_ Fraction of withdrawal fee based on withdrawalFeeBase_
     * @param withdrawalFeeBase_ Fraction of withdrawal fee base
     */
    function changeFee(uint8 withdrawalFeeFraction_, uint8 withdrawalFeeBase_) external onlyOwner {
        require(withdrawalFeeFraction_ <= withdrawalFeeBase_, "Fee fraction exceeded base.");
        uint8 percentage = (withdrawalFeeFraction_ * 100) / withdrawalFeeBase_;
        require(percentage <= 2, "Attempt to set percentage higher than 2%."); // Requested by community

        _feeFraction = withdrawalFeeFraction_;
        _feeBase = withdrawalFeeBase_;
    }

    /**
     * @dev Set or change DR strategy tokens and allocations.
     * @param strategyTokens_ Array of strategy tokens.
     * @param tokenPercentage_ Array of strategy tokens' percentage allocations.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function changeStrategy(
        address[] calldata strategyTokens_,
        uint8[] calldata tokenPercentage_,
        uint32 deadline
    ) external onlyOwner {
        require(strategyTokens_.length >= 1, "Setting strategy to 0 tokens.");
        require(strategyTokens_.length <= 5, "Setting strategy to more than 5 tokens.");
        require(strategyTokens_.length == tokenPercentage_.length, "Strategy tokens length doesn't match token percentage length.");

        uint256 totalPercentage = 0;
        for (uint8 i = 0; i < tokenPercentage_.length; i++) {
            totalPercentage = totalPercentage.add(tokenPercentage_[i]);
        }
        require(totalPercentage == 100, "Total token percentage is not 100%.");

        address[] memory oldTokens = new address[](strategyTokenCount());
        uint8[] memory oldPercentage = new uint8[](strategyTokenCount());
        for (uint8 i = 0; i < strategyTokenCount(); i++) {
            oldTokens[i] = _strategyTokens[i].tokenAddress;
            oldPercentage[i] = _strategyTokens[i].tokenPercentage;
        }

        // Before mutate strategyTokens, convert current strategy tokens to ETH
        uint256 ethConverted = _convertStrategyTokensToEth(totalTokenStored(), deadline);

        delete _strategyTokens;
        
        for (uint8 i = 0; i < strategyTokens_.length; i++) {
            _strategyTokens.push(StategyToken(strategyTokens_[i], tokenPercentage_[i]));
        }

        _convertEthToStrategyTokens(ethConverted, deadline);

        emit StrategyChange(oldTokens, oldPercentage, strategyTokens_, tokenPercentage_, totalTokenStored());
    }

    /**
     * @dev Realigning the weighting of a portfolio of assets to the strategy allocation that is defined.
     * Only convert the amount that's necessory to convert to not be charged 0.3% uniswap fee for everything.
     * This in total saves 0.6% fee for majority of the assets.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function rebalance(uint32 deadline) external onlyOwner {
        require(strategyTokenCount() > 0, "Strategy hasn't been set");

        // Get each tokens worth and the total worth in ETH
        uint256 totalWorthInEth = 0;
        uint256[] memory tokensWorthInEth = new uint256[](strategyTokenCount());

        for (uint8 i = 0; i < strategyTokenCount(); i++) {
            address currentToken = _strategyTokens[i].tokenAddress;
            uint256 tokenWorth = _getEthAmountByTokenAmount(IERC20(currentToken).balanceOf(address(this)), currentToken, true);
            totalWorthInEth = totalWorthInEth.add(tokenWorth);
            tokensWorthInEth[i] = tokenWorth;
        }

        address[] memory strategyTokensArray = new address[](strategyTokenCount()); // Get percentages for event param
        uint8[] memory percentageArray = new uint8[](strategyTokenCount()); // Get percentages for event param
        uint256 totalInEthToConvert = 0; // Get total token worth in ETH needed to be converted
        uint256 totalEthConverted = 0; // Get total token worth in ETH needed to be converted
        uint256[] memory tokenInEthNeeded = new uint256[](strategyTokenCount()); // Get token worth need to be filled

        for (uint8 i = 0; i < strategyTokenCount(); i++) {
            strategyTokensArray[i] =  _strategyTokens[i].tokenAddress;
            percentageArray[i] = _strategyTokens[i].tokenPercentage;

            uint256 tokenShouldWorth = totalWorthInEth.mul(_strategyTokens[i].tokenPercentage).div(100);

            if (tokensWorthInEth[i] <= tokenShouldWorth) {
                // If token worth less than should be, calculate the diff and store as needed
                tokenInEthNeeded[i] = tokenShouldWorth.sub(tokensWorthInEth[i]);
                totalInEthToConvert = totalInEthToConvert.add(tokenInEthNeeded[i]);
            } else {
                tokenInEthNeeded[i] = 0;

                // If token worth more than should be, convert the overflowed amount to ETH
                uint256 tokenInEthOverflowed = tokensWorthInEth[i].sub(tokenShouldWorth);
                uint256 tokensToConvert = _getTokenAmountByEthAmount(tokenInEthOverflowed, _strategyTokens[i].tokenAddress, true);
                uint256 ethConverted = _convertTokenToEth(tokensToConvert, _strategyTokens[i].tokenAddress, deadline);
                totalEthConverted = totalEthConverted.add(ethConverted);
            }
            // Need the total value to help calculate how to distributed the converted ETH
        }

        // Distribute newly converted ETH by portion of each token to be converted to, and convert to that token needed.
        // Note: totalEthConverted would be a bit smaller than totalInEthToConvert due to Uniswap fee.
        // Converting everything is another way of rebalancing, but Uniswap would take 0.6% fee on everything.
        // In this method we reach the closest number with the lowest possible swapping fee.
        if(totalInEthToConvert > 0) {
            for (uint8 i = 0; i < strategyTokenCount(); i++) {
                uint256 ethToConvert = totalEthConverted.mul(tokenInEthNeeded[i]).div(totalInEthToConvert);
                _convertEthToToken(ethToConvert, _strategyTokens[i].tokenAddress, deadline);
            }
        }
        emit Rebalance(strategyTokensArray, percentageArray, totalTokenStored());
    }

    /**
     * @dev Withdraw DRC by DR-POD amount to burn.
     * @param podToBurn Amount of DR-POD to burn in exchange for DRC.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function _withdrawProofOfDeposit(uint256 podToBurn, uint32 deadline) private {
        uint256[] memory strategyTokensToWithdraw = _getStrategyTokensByPodAmount(podToBurn);

        _burn(msg.sender, podToBurn);

        uint256 ethConverted = _convertStrategyTokensToEth(strategyTokensToWithdraw, deadline);
        uint256 fees = ethConverted.mul(_feeFraction).div(_feeBase + _feeFraction);

        uint256 drcAmount = _convertEthToToken(ethConverted.sub(fees), drcAddress, deadline);

        SafeERC20.safeTransfer(IERC20(drcAddress), msg.sender, drcAmount);
        SafeERC20.safeTransfer(IERC20(uniswapRouter.WETH()), owner(), fees);

        emit Withdraw(msg.sender, drcAmount, fees, podToBurn, totalSupply(), totalTokenStored());
    }

    /**
     * @dev Get ETH worth of a certain amount of a token.
     * @param _amount Amount of token to convert.
     * @param _fromAddress Address of token to convert from.
     * @param _toAddress Address of token to convert to.
     * @param excludeFees If uniswap fees is considered.
     */
    function _getAAmountByBAmount(
        uint256 _amount,
        address _fromAddress,
        address _toAddress,
        bool excludeFees
    ) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _fromAddress;
        path[1] = _toAddress;

        if (path[0] == path[1] || _amount == 0) {
            return _amount;
        }

        uint256 amountOut = uniswapRouter.getAmountsOut(_amount, path)[1];

        if (excludeFees) {
            return amountOut.mul(1000).div(997);
        } else {
            return amountOut;
        }
    }

    /**
     * @dev Get the worth in a token of a certain amount of ETH.
     * @param _amount Amount of ETH to convert.
     * @param _tokenAddress Address of the token to convert to.
     * @param excludeFees If uniswap fees is considered.
     */
    function _getTokenAmountByEthAmount(
        uint256 _amount,
        address _tokenAddress,
        bool excludeFees
    ) private view returns (uint256) {
        return _getAAmountByBAmount(_amount, uniswapRouter.WETH(), _tokenAddress, excludeFees);
    }

    /**
     * @dev Get ETH worth of a certain amount of a token.
     * @param _amount Amount of token to convert.
     * @param _tokenAddress Address of token to convert from.
     * @param excludeFees If uniswap fees is considered.
     */
    function _getEthAmountByTokenAmount(
        uint256 _amount,
        address _tokenAddress,
        bool excludeFees
    ) private view returns (uint256) {
        return _getAAmountByBAmount(_amount, _tokenAddress, uniswapRouter.WETH(), excludeFees);
    }

    /**
     * @dev Get ETH worth of an array of strategy tokens.
     * @param strategyTokensBalance_ Array amounts of strategy tokens to convert.
     * @param excludeFees If uniswap fees is considered.
     */
    function _getEthAmountByStrategyTokensAmount(
        uint256[] memory strategyTokensBalance_, 
        bool excludeFees
    ) private view returns (uint256) {
        uint256 amountOut = 0;
        address[] memory path = new address[](2);
        path[1] = uniswapRouter.WETH();

        for (uint8 i = 0; i < strategyTokenCount(); i++) {
            address tokenAddress = _strategyTokens[i].tokenAddress;
            path[0] = tokenAddress;
            uint256 tokenAmount = strategyTokensBalance_[i];
            uint256 tokenAmountInEth = _getEthAmountByTokenAmount(tokenAmount, tokenAddress, excludeFees);

            amountOut = amountOut.add(tokenAmountInEth);
        }
        return amountOut;
    }

    /**
     * @dev Get DR-POD worth in an array of strategy tokens.
     * @param _amount Amount of DR-POD to convert.
     */
    function _getStrategyTokensByPodAmount(uint256 _amount) private view returns (uint256[] memory) {
        uint256[] memory strategyTokenAmount = new uint256[](strategyTokenCount());

        uint256 podFraction = 0;
        if(totalSupply() > 0){
            podFraction = _amount.mul(1e10).div(totalSupply());
        }
        for (uint8 i = 0; i < strategyTokenCount(); i++) {
            strategyTokenAmount[i] = IERC20(_strategyTokens[i].tokenAddress).balanceOf(address(this)).mul(podFraction).div(1e10);
        }
        return strategyTokenAmount;
    }

    /**
     * @dev Get price impact when swap ETH to a token via the Uniswap router.
     * @param _amount Amount of eth to swap.
     * @param _tokenAddress Address of token to swap to.
     */
    function _getEthToTokenPriceImpact(uint256 _amount, address _tokenAddress) private view returns (uint256) {
        if(_tokenAddress == uniswapRouter.WETH() || _amount == 0) {
            return 0;
        }
        address factory = uniswapRouter.factory();
        address pair = IUniswapV2Factory(factory).getPair(uniswapRouter.WETH(), _tokenAddress);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        uint256 reserveEth = 0;
        if(IUniswapV2Pair(pair).token0() == uniswapRouter.WETH()) {
            reserveEth = reserve0;
        } else {
            reserveEth = reserve1;
        }
        return 10000 - reserveEth.mul(10000).div(reserveEth.add(_amount));
    }

    /**
     * @dev Get price impact when swap ETH to strategy tokens via the Uniswap router.
     * @param _amount Amount of eth to swap.
     */
    function _getEthToStrategyTokensPriceImpact(uint256 _amount) private view returns (uint256) {
        uint256 priceImpact = 0;
        for (uint8 i = 0; i < strategyTokenCount(); i++) {
            uint8 tokenPercentage = _strategyTokens[i].tokenPercentage;
            uint256 amountToConvert = _amount.mul(tokenPercentage).div(100);
            uint256 tokenSwapPriceImpact = _getEthToTokenPriceImpact(amountToConvert, _strategyTokens[i].tokenAddress);
            priceImpact = priceImpact.add(tokenSwapPriceImpact.mul(tokenPercentage).div(100));
        }
        return priceImpact;
    }

    /**
     * @dev Convert a token to WETH via the Uniswap router.
     * @param _amount Amount of tokens to swap.
     * @param _tokenAddress Address of token to swap.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function _convertTokenToEth(
        uint256 _amount,
        address _tokenAddress,
        uint32 deadline
    ) private returns (uint256) {
        if (_tokenAddress == uniswapRouter.WETH() || _amount == 0) {
            return _amount;
        }
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = uniswapRouter.WETH();

        SafeERC20.safeApprove(IERC20(path[0]), address(uniswapRouter), _amount);
        
        uint256 amountOut = uniswapRouter.getAmountsOut(_amount, path)[1];
        uint256 amountOutWithFeeTolerance = amountOut.mul(999).div(1000);
        uint256 ethBeforeSwap = IERC20(path[1]).balanceOf(address(this));
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, amountOutWithFeeTolerance, path, address(this), deadline);
        uint256 ethAfterSwap = IERC20(path[1]).balanceOf(address(this));
        return ethAfterSwap - ethBeforeSwap;
    }

    /**
     * @dev Convert ETH to another token via the Uniswap router.
     * @param _amount Amount of WETH to swap.
     * @param _tokenAddress Address of token to swap to.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function _convertEthToToken(
        uint256 _amount,
        address _tokenAddress,
        uint32 deadline
    ) private returns (uint256) {
        if (_tokenAddress == uniswapRouter.WETH() || _amount == 0) {
            return _amount;
        }
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _tokenAddress;
        SafeERC20.safeApprove(IERC20(path[0]), address(uniswapRouter), _amount);
        uint256 amountOut = uniswapRouter.getAmountsOut(_amount, path)[1];
        uniswapRouter.swapExactTokensForTokens(_amount, amountOut, path, address(this), deadline);
        return amountOut;
    }

    /**
     * @dev Convert ETH to strategy tokens of DR in their allocation percentage.
     * @param amount Amount of WETH to swap.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function _convertEthToStrategyTokens(
        uint256 amount, 
        uint32 deadline
    ) private returns (uint256[] memory) {
        for (uint8 i = 0; i < strategyTokenCount(); i++) {
            uint256 amountToConvert = amount.mul(_strategyTokens[i].tokenPercentage).div(100);
            _convertEthToToken(amountToConvert, _strategyTokens[i].tokenAddress, deadline);
        }
    }

    /**
     * @dev Convert strategy tokens to WETH.
     * @param amountToConvert Array of the amounts of strategy tokens to swap.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function _convertStrategyTokensToEth(
        uint256[] memory amountToConvert, 
        uint32 deadline
    ) private returns (uint256) {
        uint256 ethConverted = 0;
        for (uint8 i = 0; i < strategyTokenCount(); i++) {
            uint256 amountConverted = _convertTokenToEth(amountToConvert[i], _strategyTokens[i].tokenAddress, deadline);
            ethConverted = ethConverted.add(amountConverted);
        }
        return ethConverted;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;

/**
* @dev Interface of Digital Reserve contract.
*/
interface IDigitalReserve {
    /**
     * @dev Returns length of the portfolio asset tokens. 
     * Can be used to get token addresses and percentage allocations.
     */
    function strategyTokenCount() external view returns (uint256);

    /**
     * @dev Returns a strategy token address. 
     * @param index The index of a strategy token
     */
    function strategyTokens(uint8 index) external view returns (address, uint8);

    /**
     * @dev Returns withdrawal withdrawal fee.
     * @return The first value is fraction, the second one is fraction base
     */
    function withdrawalFee() external view returns (uint8, uint8);

    /**
     * @dev Returns Proof of Deposit price decimal.
     * Price should be displayed as `price / (10 ** priceDecimals)`.
     */
    function priceDecimals() external view returns (uint8);

    /**
     * @dev Returns total strategy tokens stored in an array.
     * The output amount sequence is the strategyTokens() array sequence.
     */
    function totalTokenStored() external view returns (uint256[] memory);

    /**
     * @dev Returns how much user's vault share in DRC amount.
     * @param user Address of a DR user
     * @param percentage Percentage of user holding
     * @return The first output is total worth in DRC, 
     * second one is total DRC could withdraw (exclude fees), 
     * and last output is fees in wei.
     */
    function getUserVaultInDrc(address user, uint8 percentage) external view returns (uint256, uint256, uint256);

    /**
     * @dev Get deposit price impact
     * @param drcAmount DRC amount user want to deposit.
     * @return The price impact on the base of 10000, 
     */
    function depositPriceImpact(uint256 drcAmount) external view returns (uint256);

    /**
     * @dev Proof of Deposit net unit worth.
     */
    function getProofOfDepositPrice() external view returns (uint256);

    /**
     * @dev Deposit DRC to DR.
     * @param drcAmount DRC amount user want to deposit.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function depositDrc(uint256 drcAmount, uint32 deadline) external;

    /**
     * @dev Withdraw DRC from DR.
     * @param drcAmount DRC amount user want to withdraw.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function withdrawDrc(uint256 drcAmount, uint32 deadline) external;

    /**
     * @dev Withdraw a percentage of holding from DR.
     * @param percentage Percentage of holding user want to withdraw.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function withdrawPercentage(uint8 percentage, uint32 deadline) external;

    /**
     * @dev Emit when strategy set or change function is called by owner.
     * @param oldTokens Pervious strategy's token addresses.
     * @param oldPercentage Pervious strategy's token allocation percentages.
     * @param newTokens New strategy's token addresses.
     * @param newPercentage New strategy's token allocation percentages.
     * @param tokensStored How much each token is stored.
     */
    event StrategyChange(
        address[] oldTokens, 
        uint8[] oldPercentage, 
        address[] newTokens, 
        uint8[] newPercentage, 
        uint256[] tokensStored
    );
    
    /**
     * @dev Emit each time a rebalance function is called by owner.
     * @param strategyTokens Strategy token addresses.
     * @param tokenPercentage Strategy token allocation percentages.
     * @param tokensStored How much each token is stored.
     */
    event Rebalance(
        address[] strategyTokens, 
        uint8[] tokenPercentage, 
        uint256[] tokensStored
    );
    
    /**
     * @dev Emit each time a deposit action happened.
     * @param user Address made the deposit.
     * @param amount DRC amount deposited.
     * @param podMinted New DR-POD minted.
     * @param podTotalSupply New DR-POD total supply.
     * @param tokensStored How much each token is stored.
     */
    event Deposit(
        address indexed user, 
        uint256 amount, 
        uint256 podMinted, 
        uint256 podTotalSupply, 
        uint256[] tokensStored
    );
    
    /**
     * @dev Emit each time a withdraw action happened.
     * @param user Address made the withdrawal.
     * @param amount DRC amount withdrawn.
     * @param fees Withdrawal fees charged in wei.
     * @param podBurned DR-POD burned.
     * @param podTotalSupply New DR-POD total supply.
     * @param tokensStored How much each token is stored.
     */
    event Withdraw(
        address indexed user, 
        uint256 amount, 
        uint256 fees, 
        uint256 podBurned, 
        uint256 podTotalSupply, 
        uint256[] tokensStored
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;

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

