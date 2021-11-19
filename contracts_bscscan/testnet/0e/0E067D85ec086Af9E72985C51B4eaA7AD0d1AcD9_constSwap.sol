// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* TODO: Actually methods are public instead of external */
interface ISTAL {
    function burnFrom(address _address, uint256 _amount) external;

    function mint(address _address, uint256 _amount) external;
}

interface IBTOKEN {
    function deposit(uint256 _amount) external;

    function withdraw() external returns (uint256);
}

contract constSwap is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e18;

    uint256 public constant SWAP_FEE_MAX = 1e16; // 1%
    uint256 public constant MINTING_FEE_MAX = 1e16; // 1%
    uint256 public constant REDEMPTION_FEE_MAX = 1e16; // 1%
    uint256 public constant ADMIN_FEE_MAX = 50; // 50%
    uint256 public constant RESERVE_RATIO_MAX = 100; // 100%
    uint256 public constant REBALANCE_PERIOD_MAX = 86400; // 24 hours

    ISTAL public _stalStablecoin;

    /// @dev Fee collector of the contract
    address public _feeCollector;
    address public _theVault;

    // Maps token address to an index in the pool. Used to prevent duplicate tokens in the pool.
    // getTokenIndex function also relies on this mapping to retrieve token index.
    mapping(address => uint256) private _tokenIndexes;
    mapping(uint256 => address) public _pooledTokens;
    mapping(uint256 => address) public _ibTokens;
    mapping(uint256 => bool) public _enableIbToken;
    mapping(uint256 => uint256) public _tokenDecimals;
    mapping(uint256 => uint256) public _pooledBalances;
    mapping(uint256 => uint256) public _ibTokenBalances;
    mapping(uint256 => uint256) public _minWeight;
    mapping(uint256 => uint256) public _maxWeight;

    mapping(uint256 => uint256) public _lastRebalance;
    mapping(address => uint256) private _tokenExist;
    

    // Fee calculation
    uint256 public _swapFee = 2e14; //0.02%
    uint256 public _adminFee = 50; // 50%
    uint256 public _adminInterestFee = 20; // 20%
    uint256 public _mintingFee = 2e14; //0.02%
    uint256 public _redemptionFee = 4e14; //0.04%

    uint256 public _reserveRatio = 20; // 20% of total pooled token amounts
    uint256 public _maxRatio = 30; // 30% of total pooled token amounts
    uint256 public _rebalancePeriod = 21600; // 6 hours

    uint256 public _nTokens;
    uint256 public _tradeVolume;

    event Swap(
        address indexed buyer,
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 inAmounts,
        uint256 outAmounts
    );

    event MintFee(
        address theVault,
        uint256 feeToTheVault,
        address feeCollector,
        uint256 adminFee
    );

    event Mint(
        address indexed provider,
        address token,
        uint256 inAmounts,
        uint256 stalMinted
    );

    event Redeem(
        address indexed provider,
        address token,
        uint256 stalBurned,
        uint256 outAmounts
    );

    event AddToken(
        address token,
        address ibToken
    );

    constructor(
        address stal,
        address feeCollector,
        address theVault,
        address[] memory tokenAddr,
        address[] memory ibTokenAddr,
        uint256[] memory minWeight,
        uint256[] memory maxWeight
    ) {
        require(stal != address(0), "stal = address(0)");
        require(feeCollector != address(0), "feeCollector = address(0)");
        require(theVault != address(0), "theVault = address(0)");

        require(tokenAddr.length == ibTokenAddr.length, "tokens and ibTokens must have the same length");
        require(tokenAddr.length == minWeight.length, "incorrect minWeight length");
        require(tokenAddr.length == maxWeight.length, "incorrect maxWeight length");

        _stalStablecoin = ISTAL(stal);
        _feeCollector = feeCollector;
        _theVault = theVault;

        uint256 nTokens = tokenAddr.length;

        for (uint256 i = 0; i < nTokens; i++) {
            require(tokenAddr[i] != address(0), "The 0 address isn't an ERC-20");
            require(minWeight[i] <= maxWeight[i], "Min weight must <= Max weight");
            require(maxWeight[i] <= PRICE_PRECISION, "Max weight must <= 1e18");

            bool enableIbToken = false;
            if (ibTokenAddr[i] != address(0)) {
                enableIbToken = true;
            }

            _tokenIndexes[tokenAddr[i]] = i;

            _pooledTokens[i] = tokenAddr[i];
            _ibTokens[i] = ibTokenAddr[i];
            _enableIbToken[i] = enableIbToken;
            _tokenDecimals[i] = IERC20Metadata(tokenAddr[i]).decimals();
            _pooledBalances[i] = 0;
            _ibTokenBalances[i] = 0;
            _minWeight[i] = minWeight[i];
            _maxWeight[i] = maxWeight[i];

            _tokenExist[tokenAddr[i]] = 1;
        }

        _nTokens = nTokens;
    }

    /****************************************
     * Owner methods
     ****************************************/
    function addToken(
        address tokenAddr,
        address ibTokenAddr,
        uint256 minWeight,
        uint256 maxWeight
    )
        external
        onlyOwner
    {
        require(tokenAddr != address(0), "The 0 address isn't an ERC-20");

        // Check if index is already used.
        require(_tokenExist[tokenAddr] != 1, "Token already added");

        require(minWeight <= maxWeight, "Min weight must <= Max weight");
        require(maxWeight <= PRICE_PRECISION, "Max weight must <= 1e18");

        bool enableIbToken = false;
        if (ibTokenAddr != address(0)) {
            enableIbToken = true;
        }

        uint256 newIndex = _nTokens;

        _tokenIndexes[tokenAddr] = newIndex;

        _pooledTokens[newIndex] = tokenAddr;
        _ibTokens[newIndex] = ibTokenAddr;
        _enableIbToken[newIndex] = enableIbToken;
        _tokenDecimals[newIndex] = IERC20Metadata(tokenAddr).decimals();
        _pooledBalances[newIndex] = 0;
        _ibTokenBalances[newIndex] = 0;
        _minWeight[newIndex] = minWeight;
        _maxWeight[newIndex] = maxWeight;

        _tokenExist[tokenAddr] = 1;
        _nTokens = _nTokens + 1;
        
        emit AddToken(tokenAddr, ibTokenAddr);
    }

    function adjustReserveRatio(
        uint256 newReserveRatio,
        uint256 newMaxRatio
    )
        external
        onlyOwner
    {
        require(newReserveRatio <= newMaxRatio, "ReserveRatio must <= MaxRatio");
        require(newMaxRatio <= RESERVE_RATIO_MAX, "MaxRatio must <= RESERVE_RATIO_MAX");

        _reserveRatio = newReserveRatio;
        _maxRatio = newMaxRatio;
    }

    function adjustWeights(
        uint256 tokenIndex,
        uint256 newMinWeight,
        uint256 newMaxWeight
    )
        external
        onlyOwner
    {
        require(newMinWeight <= newMaxWeight, "Min weight must <= Max weight");
        require(newMaxWeight <= PRICE_PRECISION, "Max weight must <= 1");
        require(tokenIndex < _nTokens, "Token not exists");

        _minWeight[tokenIndex] = newMinWeight;
        _maxWeight[tokenIndex] = newMaxWeight;
    }

    function setSwapFee(uint256 swapFee) external onlyOwner {
        require(swapFee <= SWAP_FEE_MAX, "Swap fee must <= SWAP_FEE_MAX");
        _swapFee = swapFee;
    }

    function setMintingFee(uint256 mintingFee) external onlyOwner {
        require(mintingFee <= MINTING_FEE_MAX, "Mint fee must <= MINTING_FEE_MAX");
        _mintingFee = mintingFee;
    }

    function setRedemptionFee(uint256 redemptionFee) external onlyOwner {
        require(redemptionFee <= REDEMPTION_FEE_MAX, "Redeem fee must <= REDEMPTION_FEE_MAX");
        _redemptionFee = redemptionFee;
    }

    function setAdminFee(uint256 adminFee) external onlyOwner {
        require (adminFee <= ADMIN_FEE_MAX, "Admin fee must <= ADMIN_FEE_MAX");
        _adminFee = adminFee;
    }

    function setAdminInterestFee(uint256 adminInterestFee) external onlyOwner {
        require (adminInterestFee <= ADMIN_FEE_MAX, "Admin interest fee must <= ADMIN_FEE_MAX");
        _adminInterestFee = adminInterestFee;
    }

    function setRebalancePeriod(uint256 rebalancePeriod) external onlyOwner {
        require (rebalancePeriod <= REBALANCE_PERIOD_MAX, "Rebalance Period must <= REBALANCE_PERIOD_MAX");
        _rebalancePeriod = rebalancePeriod;
    }

    function setEnableIbToken(uint256 tokenIndex, address newIbToken) external onlyOwner {
        require(tokenIndex < _nTokens, "Token not exists");
        address oldIbToken = _ibTokens[tokenIndex];
        require(newIbToken != oldIbToken, "newIbToken = oldIbToken");

        if (newIbToken != address(0)) {
            uint256 oldIbTokenBalance = _ibTokenBalances[tokenIndex];
            if (oldIbTokenBalance > 0) {
                // Withdraw from oldIbToken
                _withdrawIbtoken(tokenIndex);
            }

            _ibTokens[tokenIndex] = newIbToken;
            _enableIbToken[tokenIndex] = true;

            IERC20 pooledToken = IERC20(_pooledTokens[tokenIndex]);
            uint256 pooledAmount = pooledToken.balanceOf(address(this));
            uint256 targetReserve = pooledAmount.mul(_reserveRatio).div(100);
            uint256 depositAmount = pooledAmount.sub(targetReserve);
            // Deposit to ibToken
            _depositIbtoken(tokenIndex, depositAmount);
        } else {
            uint256 oldIbTokenBalance = _ibTokenBalances[tokenIndex];
            if (oldIbTokenBalance > 0) {
                // Withdraw from oldIbToken
                _withdrawIbtoken(tokenIndex);
            }

            _ibTokens[tokenIndex] = address(0);
            _enableIbToken[tokenIndex] = false;
        }
    }

    function _totalBalance() public view returns (uint256) {
        uint256 totalBalance;
        for (uint256 i = 0; i < _nTokens; i++) {
            uint256 amountNormalized =
                _pooledBalances[i]
                .mul(_normalizeBalance(i));
            totalBalance = totalBalance.add(amountNormalized);
        }
        return totalBalance;
    }

    function _getTokenIndex(address tokenAddr) public view returns (uint256) {
        require(tokenAddr != address(0), "The 0 address isn't an ERC-20");
        // Check if index is already used.
        require(_tokenExist[tokenAddr] == 1, "Token not exists");

        uint256 tokenIndex = _tokenIndexes[tokenAddr];
        return tokenIndex;
    }

    function _getTokenInfo(uint256 tokenIndex) external view returns (
        address pooledToken,
        address ibToken,
        bool enableIbToken,
        uint256 tokenDecimals,
        uint256 pooledBalance,
        uint256 ibTokenBalance,
        uint256 minWeight,
        uint256 maxWeight
    ) {
        require(tokenIndex < _nTokens, "Token is not found!");

        pooledToken = _pooledTokens[tokenIndex];
        ibToken = _ibTokens[tokenIndex];
        enableIbToken = _enableIbToken[tokenIndex];
        tokenDecimals = _tokenDecimals[tokenIndex];
        pooledBalance = _pooledBalances[tokenIndex];
        ibTokenBalance = _ibTokenBalances[tokenIndex];
        minWeight = _minWeight[tokenIndex];
        maxWeight = _maxWeight[tokenIndex];
    }

    function _normalizeBalance(uint256 tokenIndex) internal view returns (uint256) {
        uint256 decm = 18 - _tokenDecimals[tokenIndex];
        return 10 ** decm;
    }

    /**************************************************************************************
     * Methods for rebalance reserve
     * After rebalancing, we will have reserve equaling to 20% of total balance
     *************************************************************************************/

    function _rebalanceReserve(
        uint256 tokenIndex
    ) internal {
        IERC20 pooledToken = IERC20(_pooledTokens[tokenIndex]);
        uint256 pooledBalance = _pooledBalances[tokenIndex];
        uint256 reserveAmount = pooledToken.balanceOf(address(this));
        uint256 targetReserve = pooledBalance.mul(_reserveRatio).div(100);

        if (reserveAmount > targetReserve) {
            uint256 depositAmount = reserveAmount.sub(targetReserve);

            // Deposit to ibToken
            _depositIbtoken(tokenIndex, depositAmount);
        } else {
            uint256 expectedWithdraw = targetReserve.sub(reserveAmount);
            if (expectedWithdraw == 0) {
                return;
            }

            // Withdraw from ibToken
            _withdrawIbtoken(tokenIndex);
            uint256 pooledAmount = pooledToken.balanceOf(address(this));
            uint256 depositAmount = pooledAmount.sub(targetReserve);

            // Deposit back to ibToken
            _depositIbtoken(tokenIndex, depositAmount);
        }

        _lastRebalance[tokenIndex] = block.timestamp;
    }

    function _rebalanceReserveSubstract(
        uint256 tokenIndex,
        uint256 amountUnnormalized
    ) internal {
        IERC20 pooledToken = IERC20(_pooledTokens[tokenIndex]);
        uint256 pooledBalance = _pooledBalances[tokenIndex];
        uint256 targetReserve = pooledBalance.mul(_reserveRatio).div(100);

        // Withdraw from ibToken
        _withdrawIbtoken(tokenIndex);
        uint256 pooledAmount = pooledToken.balanceOf(address(this));
        uint256 reserveAmount = targetReserve.add(amountUnnormalized);
        uint256 depositAmount = pooledAmount.sub(reserveAmount);

        // Deposit back to ibToken
        _depositIbtoken(tokenIndex, depositAmount);

        _lastRebalance[tokenIndex] = block.timestamp;
    }

    function _depositIbtoken(
        uint256 tokenIndex,
        uint256 toIbTokenAmount
    ) internal {
        uint256 ibTokenBalances = _ibTokenBalances[tokenIndex];
        IERC20 pooledToken = IERC20(_pooledTokens[tokenIndex]);
        IBTOKEN ibToken = IBTOKEN(_ibTokens[tokenIndex]);

        pooledToken.safeApprove(address(ibToken), 0);
        pooledToken.safeApprove(address(ibToken), toIbTokenAmount);
        ibToken.deposit(toIbTokenAmount);

        _ibTokenBalances[tokenIndex] = ibTokenBalances.add(toIbTokenAmount);
    }

    function _withdrawIbtoken(
        uint256 tokenIndex
    ) internal {
        uint256 ibTokenBalances = _ibTokenBalances[tokenIndex];
        IBTOKEN ibToken = IBTOKEN(_ibTokens[tokenIndex]);
        uint256 withdrawAmounts = ibToken.withdraw();

        if (withdrawAmounts > ibTokenBalances) {
            uint256 interest = withdrawAmounts.sub(ibTokenBalances);
            uint256 interestNormalized = interest.mul(_normalizeBalance(tokenIndex));
            uint256 adminInterestFee = interestNormalized.mul(_adminInterestFee).div(100);
            uint256 interestToTheVault = interestNormalized.sub(adminInterestFee);

            if (adminInterestFee > 0) _stalStablecoin.mint(_feeCollector, adminInterestFee);
            _stalStablecoin.mint(_theVault, interestToTheVault);

            _pooledBalances[tokenIndex] = _pooledBalances[tokenIndex].add(interest);
        }
        _ibTokenBalances[tokenIndex] = 0;
        
    }

    function _checkRebalancePeriod(
        uint256 tokenIndex
    )   public
        view
        returns (bool) 
    {
        uint256 blockTimestamp = block.timestamp;
        uint256 timeElapsed = blockTimestamp - _lastRebalance[tokenIndex];

        return (timeElapsed >= _rebalancePeriod);
    }

    /// @dev Forcibly rebalance so that reserve is about 20% of total.
    function rebalanceReserve(
        uint256 tokenIndex
    )
        external
        nonReentrant
        whenNotPaused
    {
        require(tokenIndex < _nTokens, "Token is not found!");
        
        if (_checkRebalancePeriod(tokenIndex)) {
            _rebalanceReserve(tokenIndex);
        }
    }

    /// @dev Mint with out fee for sent to the Vault.
    function _mintFee(
        uint256 tokenIndex,
        uint256 fee
    ) internal {
        uint256 stalAmount = fee.mul(_normalizeBalance(tokenIndex));

        // Fee calculation
        if (stalAmount > 0) {
            uint256 adminFee = stalAmount.mul(_adminFee).div(100);
            uint256 feeToTheVault = stalAmount.sub(adminFee);

            if (adminFee > 0) _stalStablecoin.mint(_feeCollector, adminFee);
            _stalStablecoin.mint(_theVault, feeToTheVault);

            emit MintFee(_theVault, feeToTheVault, _feeCollector, adminFee);
        }  
    }

    /// @dev Transfer the amount of token out. Rebalance the reserve if needed
    function _transferOut(
        uint256 tokenIndex,
        uint256 amountUnnormalized,
        uint256 feeUnnormalized
    )
        internal
    {
        IERC20 pooledToken = IERC20(_pooledTokens[tokenIndex]);
        uint256 reserveAmount = pooledToken.balanceOf(address(this));

        if (_enableIbToken[tokenIndex]) {
            // Check rebalance if needed
            if (amountUnnormalized > reserveAmount) {
                _rebalanceReserveSubstract(tokenIndex, amountUnnormalized);
            }
        }

        _mintFee(tokenIndex, feeUnnormalized);

        pooledToken.safeTransfer(
            msg.sender,
            amountUnnormalized
        );

        _pooledBalances[tokenIndex] =
            _pooledBalances[tokenIndex]
            .sub(amountUnnormalized);
    }

    /// @dev Transfer the amount of token in. Rebalance the reserve if needed
    function _transferIn(
        uint256 tokenIndex,
        uint256 amountUnnormalized
    )
        internal
    {
        IERC20 pooledToken = IERC20(_pooledTokens[tokenIndex]);

        pooledToken.safeTransferFrom(
            msg.sender,
            address(this),
            amountUnnormalized
        );

        _pooledBalances[tokenIndex] =
            _pooledBalances[tokenIndex]
            .add(amountUnnormalized);

        if (_enableIbToken[tokenIndex]) {
            // Check rebalance if needed
            uint256 reserveAmount = pooledToken.balanceOf(address(this));
            uint256 maxReserveAmount = _pooledBalances[tokenIndex].mul(_maxRatio).div(100);
            if (reserveAmount > maxReserveAmount) {
                _rebalanceReserve(tokenIndex);
            }
        }
    }

    /**************************************************************************************
     * Methods for minting
     *************************************************************************************/

    /// @dev Given the token index and the amount to be deposited, return the amount of Stal Stablecoin
    function getMintAmount(
        uint256 tokenIndex,
        uint256 tokenAmountIn
    )
        public
        view
        returns (uint256 stalAmountOut, uint256 fee)
    {
        require(tokenIndex < _nTokens, "Token is not found!");

        // Obtain normalized balances
        uint256 tokenAmountInNormalized = tokenAmountIn.mul(_normalizeBalance(tokenIndex));

        // Gas saving: Use cached totalBalance from _totalBalance().
        uint256 totalBalance = _totalBalance();
        uint256 pooledBalanceNormalized = _pooledBalances[tokenIndex].mul(_normalizeBalance(tokenIndex));
        uint256 currentWeight = getRatioOf(pooledBalanceNormalized, totalBalance);
        uint256 minWeight = _minWeight[tokenIndex];
        uint256 maxWeight = _maxWeight[tokenIndex];

        // Fee calculation
        uint256 mintingfee = _mintingFee;
        if (currentWeight < minWeight) {
            mintingfee = mintingfee.div(2);
        } else if (currentWeight > maxWeight) {
            mintingfee = mintingfee.mul(2);
        }
        fee = getProductOf(tokenAmountInNormalized, mintingfee);

        stalAmountOut = tokenAmountInNormalized.sub(fee);
    }

    /// @dev Given the token index and the amount to be deposited, mint Stal Stablecoin
    function mint(
        uint256 tokenIndex,
        uint256 tokenAmountIn,
        uint256 stalMintedMin
    )
        external
        nonReentrant
        whenNotPaused
    {
        require(tokenAmountIn > 0, "Amount must be greater than 0");
        (uint256 stalAmountOut, uint256 fee) = getMintAmount(tokenIndex, tokenAmountIn);

        require(stalAmountOut >= stalMintedMin, "STAL minted should >= minimum STAL asked");
        
        _transferIn(tokenIndex, tokenAmountIn);

        // Fee calculation
        if (fee > 0) {
            uint256 adminFee = fee.mul(_adminFee).div(100);
            uint256 feeToTheVault = fee.sub(adminFee);

            if (adminFee > 0) _stalStablecoin.mint(_feeCollector, adminFee);
            _stalStablecoin.mint(_theVault, feeToTheVault);

            emit MintFee(_theVault, feeToTheVault, _feeCollector, adminFee);
        }

        _stalStablecoin.mint(msg.sender, stalAmountOut);

        emit Mint(msg.sender, _pooledTokens[tokenIndex], tokenAmountIn, stalAmountOut);
    }

    /**************************************************************************************
     * Methods for redeeming
     *************************************************************************************/

    /// @dev Given token index and STAL amount, return the max amount of token can be withdrawn
    function getRedeemAmount(
        uint256 tokenIndex,
        uint256 stalAmountIn
    )
        public
        view
        returns (uint256 tokenAmountOut, uint256 fee)
    {
        require(tokenIndex < _nTokens, "Token is not found!");

        // Obtain normalized balances
        uint256 stalAmountInNormalized = stalAmountIn;

        // Gas saving: Use cached totalBalance from _totalBalance().
        uint256 totalBalance = _totalBalance();
        uint256 pooledBalanceNormalized = _pooledBalances[tokenIndex].mul(_normalizeBalance(tokenIndex));
        uint256 currentWeight = getRatioOf(pooledBalanceNormalized, totalBalance);
        uint256 minWeight = _minWeight[tokenIndex];
        uint256 maxWeight = _maxWeight[tokenIndex];

        // Fee calculation
        uint256 redemptionfee = _redemptionFee;
        if (currentWeight < minWeight) {
            redemptionfee = redemptionfee.mul(2);
        } else if (currentWeight > maxWeight) {
            redemptionfee = redemptionfee.div(2);
        }
        uint256 feeNormalized = getProductOf(stalAmountInNormalized, redemptionfee);
        uint256 tokenAmountOutNormalized = stalAmountInNormalized.sub(feeNormalized);

        fee = feeNormalized.div(_normalizeBalance(tokenIndex));
        tokenAmountOut = tokenAmountOutNormalized.div(_normalizeBalance(tokenIndex));
    }

    /// @dev Given the token index and Stal amount to be redeemed, burn Stal Stablecoin
    function redeem(
        uint256 tokenIndex,
        uint256 stalAmountIn,
        uint256 tokenAmountOutMin
    )
        external
        nonReentrant
        whenNotPaused
    {
        require(stalAmountIn > 0, "Amount must be greater than 0");
        (uint256 tokenAmountOut, uint256 fee) = getRedeemAmount(tokenIndex, stalAmountIn);

        uint256 pooledBalances = _pooledBalances[tokenIndex];
        require(tokenAmountOut <= pooledBalances, "Token amount should <= pool balances");
        require(tokenAmountOut >= tokenAmountOutMin, "Token amount should >= minimum token asked");

        _stalStablecoin.burnFrom(msg.sender, stalAmountIn);

        _transferOut(tokenIndex, tokenAmountOut, fee);

        emit Redeem(msg.sender, _pooledTokens[tokenIndex], stalAmountIn, tokenAmountOut);
    }

    /**************************************************************************************
     * Methods for swapping tokens
     *************************************************************************************/

    /// @dev Return the maximum amount of token can be withdrawn after depositing another token.
    function getSwapAmount(
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountIn
    )
        public
        view
        returns (uint256 tokenAmountOut, uint256 fee)
    {
        require(tokenIndexIn < _nTokens, "TokenIn is not found!");
        require(tokenIndexOut < _nTokens, "TokenOut token is not found!");
        require(tokenIndexIn != tokenIndexOut, "Tokens for swap must be different!");

        uint256 tokenAmountInNormalized = tokenAmountIn.mul(_normalizeBalance(tokenIndexIn));
        uint256 tokenAmountOutNormalized = tokenAmountInNormalized;

        uint256 feeNormalized = getProductOf(tokenAmountOutNormalized, _swapFee);
        uint256 amountOutPostFeeNormalized = tokenAmountOutNormalized.sub(feeNormalized);

        fee = feeNormalized.div(_normalizeBalance(tokenIndexOut));
        tokenAmountOut = amountOutPostFeeNormalized.div(_normalizeBalance(tokenIndexOut));
    }

    /**
     * @dev Swap a token to another.
     * @param tokenIndexIn - the id of the token to be deposited
     * @param tokenIndexOut - the id of the token to be withdrawn
     * @param tokenAmountIn - the amount (unnormalized) of the token to be deposited
     * @param tokenAmountOutMin - the mininum amount (unnormalized) token that is expected to be withdrawn
     */
    function swap(
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOutMin
    )
        external
        nonReentrant
        whenNotPaused
    {
        (uint256 tokenAmountOut, uint256 fee) = getSwapAmount(tokenIndexIn, tokenIndexOut, tokenAmountIn);
        require(tokenAmountOut >= tokenAmountOutMin, "Returned tokenAmountOut < asked");

        _transferIn(tokenIndexIn, tokenAmountIn);

        _transferOut(tokenIndexOut, tokenAmountOut, fee);

        uint256 tokenAmountInNormalized = tokenAmountIn.mul(_normalizeBalance(tokenIndexIn));
        _tradeVolume = _tradeVolume.add(tokenAmountInNormalized);

        emit Swap(
            msg.sender,
            tokenIndexIn,
            tokenIndexOut,
            tokenAmountIn,
            tokenAmountOut
        );
    }

    function getProductOf(uint256 _amount, uint256 _multiplier)
        public
        pure
        returns (uint256)
    {
        return (_amount.mul(_multiplier)).div(PRICE_PRECISION);
    }

    function getRatioOf(uint256 _amount, uint256 _divider)
        public
        pure
        returns (uint256)
    {
        if (_divider == 0) _divider = PRICE_PRECISION;
        return
            (
                ((_amount.mul(PRICE_PRECISION)).div(_divider)).mul(
                    PRICE_PRECISION
                )
            )
                .div(PRICE_PRECISION);
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

// SPDX-License-Identifier: MIT

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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

    constructor() {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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