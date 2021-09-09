// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ERC2222 {
    uint256 internal constant pointsMultiplier = 2**128;
    uint256 internal pointsPerShare;

    uint256 public totalPricipalDepositedInVault;
    mapping(address => int256) internal pointsCorrection;
    mapping(address => uint256) internal withdrawnFunds;

    /**
     * @dev This event emits when new funds are distributed
     * @param by the address of the sender who distributed funds
     * @param fundsDistributed the amount of funds received for distribution
     */
    event FundsDistributed(address indexed by, uint256 fundsDistributed);

    /**
     * @dev This event emits when distributed funds are withdrawn by a token holder.
     * @param by the address of the receiver of funds
     * @param fundsWithdrawn the amount of funds that were withdrawn
     */
    event FundsWithdrawn(address indexed by, uint256 fundsWithdrawn);

    // --- External View Functions ---

    // total wantTokenVault tokens withdrawn by user
    function withdrawnFundsOf(address _owner) public view returns (uint256) {
        return withdrawnFunds[_owner];
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow
/// of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and
/// division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision.
    /// Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result
    ///  overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

/**
 * @title SafeMathInt
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathInt {
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice DCA (Dollar-Cost Averaging) Vault. Uses interest earned on a
///principal token to accumulate another desired token (the wantToken).
// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.4;

import "../../oz/0.8.0-contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../oz/0.8.0-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../../oz/0.8.0/token/ERC20/utils/SafeERC20.sol";
import "../../oz/0.8.0/token/ERC20/extensions/IERC20Metadata.sol";
import "../ERC2222.sol";
import "../MathLib.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// Beefy
interface IBeefyVault {
    function approvalDelay() external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function available() external view returns (uint256);

    function balance() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function deposit(uint256 _amount) external;

    function depositAll() external;

    function earn() external;

    function getPricePerFullShare() external view returns (uint256);

    function inCaseTokensGetStuck(address _token) external;

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function proposeStrat(address _implementation) external;

    function renounceOwnership() external;

    function stratCandidate()
        external
        view
        returns (address implementation, uint256 proposedTime);

    function strategy() external view returns (address);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function upgradeStrat() external;

    function want() external view returns (address);

    function withdraw(uint256 _shares) external;

    function withdrawAll() external;
}

interface IDCAFactory {
    function registry() external view returns (address);

    function owner() external view returns (address);

    function collector() external view returns (address);

    function approvedTargets(address) external view returns (bool);

    function approvedKeepers(address) external view returns (address);

    function performanceFee() external view returns (uint256);

    function keeperFee() external view returns (uint256);

    function toDepositBuffer() external view returns (uint256);
}

contract DCA_Vault_V1_Beefy is Initializable, ERC20Upgradeable, ERC2222 {
    using SafeERC20 for IERC20;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // Used to pause the contract
    bool public stopped;

    //Token being deposited
    address public principalToken;
    // Token to acquire with interest accrued from principalToken
    address public wantToken;
    // vault for the principalToken
    IBeefyVault public principalTokenVault;
    // vault for the wantTokenVault (O address if none)
    IBeefyVault public wantTokenVault;

    // 100% in bps
    uint256 constant BPS_BASE = 10000;

    // Caps total deposits of the principal token that can be held by the vault
    uint256 public depositCap;

    // Used to restrict withdrawals to at least n+1 block after a deposit
    mapping(address => uint256) internal lastDepositAtBlock;

    // current total want shares that have been distributed, but not claimed
    uint256 internal pendingDistributedWantShares;

    // Address of the WMATIC token on polygon
    address private constant wmaticTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // zDCA Factory that deploys minimal proxies
    IDCAFactory public factory;

    /**
     * @dev Called by the factory `deployVault` function
     * @param _principalToken The address of the token which will accrue interest
     * @param _wantToken The address of the token to acquire with accured interest
     * from the _principalToken
     * @param _principalTokenVault The vault in which to deposit the _principalToken
     * @param _wantTokenVault The vault in which to deposit the _wantTokenVault
     * (0 address if no vault exists)
     */
    function initialize(
        address _principalToken,
        address _wantToken,
        address _principalTokenVault,
        address _wantTokenVault // address(0) if doesn't exist
    ) external initializer {
        require(
            _principalToken != _wantToken,
            "DCA: Can't initialize Same token"
        );
        string memory principalTokenSymbol = IERC20Metadata(_principalToken)
            .symbol();
        string memory wantTokenSymbol = IERC20Metadata(_wantToken).symbol();

        string memory tokenName = string(
            abi.encodePacked(
                "Zapper DCA Vault ",
                principalTokenSymbol,
                "-",
                wantTokenSymbol
            )
        );
        string memory tokenSymbol = string(
            abi.encodePacked(
                "zDCA-",
                principalTokenSymbol,
                "-",
                wantTokenSymbol
            )
        );

        __ERC20_init(tokenName, tokenSymbol);

        principalToken = _principalToken;
        wantToken = _wantToken;
        principalTokenVault = IBeefyVault(_principalTokenVault);
        wantTokenVault = IBeefyVault(_wantTokenVault);
        depositCap = 0;

        factory = IDCAFactory(msg.sender);
    }

    modifier stopInEmergency() {
        require(!stopped, "DCA: Paused");
        _;
    }

    modifier onlyFactoryOwner() {
        require(msg.sender == factory.owner(), "DCA: caller is not the owner");
        _;
    }

    // --- External Mutative Functions ---

    /**
     * @notice Used to add liquidity into the vault with any token
     * @dev vault tokens are minted 1:1 with the principal token
     * @param _fromToken The token used for entry (address(0) if ether)
     * @param _amountIn Quantity of _fromToken being added
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     * @param _minToTokens The minimum acceptable quantity of principal
     * tokens to receive. Reverts otherwise
     */
    function deposit(
        address _fromToken,
        uint256 _amountIn,
        address _swapTarget,
        bytes calldata _swapData,
        uint256 _minToTokens
    ) external payable stopInEmergency {
        lastDepositAtBlock[msg.sender] = block.number;

        // get tokens from user
        _amountIn = _pullTokens(_fromToken, _amountIn);

        // swap them to principalTokens
        uint256 netPrincipalReceived = _fillQuote(
            _fromToken,
            principalToken,
            _amountIn,
            _swapTarget,
            _swapData,
            _minToTokens
        );
        require(
            netPrincipalReceived +
                totalPricipalDepositedInVault +
                _getBalance(principalToken) <=
                depositCap,
            "DCA: Capacity reached"
        );

        // deposit amount after accounting for buffer
        uint256 principalToDeposit = (netPrincipalReceived *
            factory.toDepositBuffer()) / BPS_BASE;

        // deposit into principal strategy vault
        _deposit(principalToDeposit);
        totalPricipalDepositedInVault += principalToDeposit;

        // mint shares for user
        _mint(msg.sender, netPrincipalReceived);
    }

    /**
     * @notice Used to withdraw principal tokens from the vault,
     * optionally swapping into any token
     * @param _principalAmount The quantity of principal tokens being removed
     * @param _toToken The adress of the token to receive
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     * @param _minToTokens The minimum acceptable quantity of principal
     * tokens to receive. Reverts otherwise
     */
    function withdraw(
        uint256 _principalAmount,
        address _toToken,
        address _swapTarget,
        bytes memory _swapData,
        uint256 _minToTokens
    ) public {
        require(
            block.number > lastDepositAtBlock[msg.sender],
            "DCA: Same block withdraw"
        );

        // burn user shares
        _burn(msg.sender, _principalAmount);

        uint256 principalBalance = IERC20(principalToken).balanceOf(
            address(this)
        );
        if (principalBalance < _principalAmount) {
            uint256 principalToWithdraw = _principalAmount - principalBalance;
            // withdraw principalTokens from strategy vault
            uint256 _totalAssets = principalTokenVault.balance();
            uint256 _totalSupply = principalTokenVault.totalSupply();
            uint256 sharesToBurn = FullMath.mulDivRoundingUp(
                principalToWithdraw,
                _totalSupply,
                _totalAssets
            );

            principalTokenVault.withdraw(sharesToBurn);
            // take care of any vault withdrawal fees
            _principalAmount = principalTokenVault.balanceOf(address(this));
            totalPricipalDepositedInVault -= principalToWithdraw;
        }

        // swap to _toToken
        uint256 toTokenAmt = _fillQuote(
            principalToken,
            _toToken,
            _principalAmount,
            _swapTarget,
            _swapData,
            _minToTokens
        );

        // send _toToken to user
        if (_toToken == address(0)) {
            payable(msg.sender).transfer(toTokenAmt);
        } else {
            IERC20(_toToken).safeTransfer(msg.sender, toTokenAmt);
        }
    }

    /**
     * @notice Used to claim dividends (denominated in wantToken),
     * optionally swapping into any token
     * @param _toToken The adress of the token to receive
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     * @param _minToTokens The minimum acceptable quantity of _toToken
     * to receive. Reverts otherwise
     */
    function claim(
        address _toToken,
        address _swapTarget,
        bytes calldata _swapData,
        uint256 _minToTokens
    ) public {
        uint256 userWantShares = _prepareWithdraw();

        uint256 wantTokenToSend = userWantShares;
        // unwrap wantTokens from strategy (if exists)
        if (address(wantTokenVault) != address(0)) {
            (
                uint256 wantTokenBalance,
                uint256 wantVaultTokenEquivalent,
                uint256 pricePerShare
            ) = _totalWantBalance();
            uint256 totalWantBal = wantTokenBalance + wantVaultTokenEquivalent;

            wantTokenToSend =
                (userWantShares * totalWantBal) /
                pendingDistributedWantShares;

            // if buffer is insufficient, withdraw more from vault
            if (wantTokenBalance < wantTokenToSend) {
                uint256 wantToWithdraw = wantTokenToSend - wantTokenBalance;

                uint256 sharesToBurn = (wantToWithdraw * 1e18) / pricePerShare;
                wantTokenVault.withdraw(sharesToBurn);
                // takes care of any withdrawal fee with vault
                wantTokenToSend = wantTokenVault.balanceOf(address(this));
            }

            pendingDistributedWantShares -= userWantShares;
        }

        // swap to _toToken
        uint256 toTokenAmt = _fillQuote(
            wantToken,
            _toToken,
            wantTokenToSend,
            _swapTarget,
            _swapData,
            _minToTokens
        );

        // send _toToken to user
        if (_toToken == address(0)) {
            payable(msg.sender).transfer(toTokenAmt);
        } else {
            IERC20(_toToken).safeTransfer(msg.sender, toTokenAmt);
        }
    }

    /**
     * @notice Exits the vault, liquidating all of the senders
     principalTokens and wantTokens, optionally swapping them
     to a desired token
     * @dev _swapData[0] and _mintTotokens[0] must be for the
     * principalToken swap. Index 1 must be used for the 
     * wantToken swap
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     * @param _minToTokens The minimum acceptable quantity of _toToken
     * to receive. Reverts otherwise
     */
    function exit(
        address _toToken,
        address[] calldata _swapTarget,
        bytes[] calldata _swapData,
        uint256[] calldata _minToTokens
    ) external {
        // withdraw principal tokens
        uint256 userShares = balanceOf(msg.sender);
        withdraw(
            userShares,
            _toToken,
            _swapTarget[0],
            _swapData[0],
            _minToTokens[0]
        );

        // claim wantToken dividends
        claim(_toToken, _swapTarget[1], _swapData[1], _minToTokens[1]);
    }

    /**
     * @notice Harvests interest accrued from the principal token
     * vault and acquires more wantToken, locking it in its own vault
     * if applicable
     * @dev only approved keepers may harvest this vault
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     * @param _minToTokens The minimum acceptable quantity of _toToken
     * to receive. Reverts otherwise
     */
    function harvest(
        address _swapTarget,
        bytes calldata _swapData,
        uint256 _minToTokens
    ) external stopInEmergency {
        require(
            factory.approvedKeepers(msg.sender) != address(0),
            "DCA: Keeper not Authorized"
        );

        // get interest accumulated
        (
            uint256 interest,
            uint256 _totalAssets,
            uint256 _totalSupply
        ) = _pendingInterestAccumulated();

        // withdraw interest from principal strategy vault
        uint256 sharesToBurn = FullMath.mulDivRoundingUp(
            interest,
            _totalSupply,
            _totalAssets
        );
        uint256 initialPrincipalBalance = IERC20(principalToken).balanceOf(
            address(this)
        );
        principalTokenVault.withdraw(sharesToBurn);
        uint256 principalReceived = IERC20(principalToken).balanceOf(
            address(this)
        ) - initialPrincipalBalance;

        // convert principalReceived to want token
        uint256 wantReceived = _fillQuote(
            principalToken,
            wantToken,
            principalReceived,
            _swapTarget,
            _swapData,
            _minToTokens
        );

        uint256 keeperShare = (wantReceived * factory.keeperFee()) / BPS_BASE;
        uint256 collectorShare = (wantReceived * factory.performanceFee()) /
            BPS_BASE;
        IERC20(wantToken).safeTransfer(msg.sender, keeperShare);
        IERC20(wantToken).safeTransfer(factory.collector(), collectorShare);

        wantReceived -= keeperShare;

        // deposit into wantToken strategy vault (if exists)
        uint256 _wantSharesToDistribute = wantReceived;
        if (address(wantTokenVault) != address(0)) {
            _approveToken(wantToken, address(wantTokenVault));

            uint256 _preTotalWantBalance = totalWantBalance();

            if (pendingDistributedWantShares == 0) {
                _wantSharesToDistribute = wantReceived;
            } else {
                _wantSharesToDistribute =
                    (wantReceived * pendingDistributedWantShares) /
                    _preTotalWantBalance;
            }
            pendingDistributedWantShares += wantReceived;

            uint256 wantToDeposit = (wantReceived * factory.toDepositBuffer()) /
                BPS_BASE;
            wantTokenVault.deposit(wantToDeposit);
        }

        // update wantToken dividends
        _distributeFunds(_wantSharesToDistribute);
    }

    /**
     * @notice Toggles the vault's active state
     */
    function toggleVaultActive() external onlyFactoryOwner {
        stopped = !stopped;
    }

    /**
     * @notice Updates the deposit capacity
     * @dev should be in the base units of the principalToken
     * (i.e 18 decimals for ETH, 6 for USDC)
     */
    function updateDepositCap(uint256 _depositCap) external onlyFactoryOwner {
        depositCap = _depositCap;
    }

    // --- Internal Mutative Functions ---

    function _deposit(uint256 amount) internal {
        _approveToken(principalToken, address(principalTokenVault));
        principalTokenVault.deposit(amount);
    }

    /**
     * @notice Distributes funds to token holders.
     */
    function _distributeFunds(uint256 value) internal {
        require(totalSupply() > 0, "DCA._distributeFunds: SUPPLY_IS_ZERO");

        if (value > 0) {
            pointsPerShare =
                pointsPerShare +
                ((value * pointsMultiplier) / totalSupply());
            emit FundsDistributed(msg.sender, value);
        }
    }

    /**
     * @notice Prepares funds withdrawal
     */
    function _prepareWithdraw() internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableFundsOf(msg.sender);

        withdrawnFunds[msg.sender] =
            withdrawnFunds[msg.sender] +
            _withdrawableDividend;

        emit FundsWithdrawn(msg.sender, _withdrawableDividend);

        return _withdrawableDividend;
    }

    /**
     * @dev Internal function that mints tokens to an account.
     * Update pointsCorrection to keep funds unchanged.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        pointsCorrection[account] =
            pointsCorrection[account] -
            (pointsPerShare * value).toInt256Safe();
    }

    /**
     * @dev Internal function that burns an amount of the token of a given account.
     * Update pointsCorrection to keep funds unchanged.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        pointsCorrection[account] =
            pointsCorrection[account] +
            (pointsPerShare * value).toInt256Safe();
    }

    /**
     * @dev Internal function that transfer tokens from one address to another.
     * Update pointsCorrection to keep funds unchanged.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        super._transfer(from, to, value);

        int256 _magCorrection = (pointsPerShare * value).toInt256Safe();
        pointsCorrection[from] = pointsCorrection[from] + _magCorrection;
        pointsCorrection[to] = pointsCorrection[to] - _magCorrection;

        if (lastDepositAtBlock[from] == block.number) {
            lastDepositAtBlock[to] = block.number;
        }
    }

    function _pullTokens(address token, uint256 amount)
        internal
        returns (uint256)
    {
        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");
            return msg.value;
        }

        require(amount > 0, "Invalid token amount");
        require(msg.value == 0, "Eth sent with token");

        // transfer token
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return amount;
    }

    /**
     * @dev Internal function to execute a swap or Zap
     * @param _fromToken The address of the sell token
     * @param _toToken The address tof the buy token
     * @param _amount The quantity of _fromToken to sell
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     */
    function _fillQuote(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory _swapData,
        uint256 _minToTokens
    ) internal returns (uint256 amtBought) {
        if (_fromToken == _toToken) {
            return _amount;
        }

        if (_fromToken == address(0) && _toToken == wmaticTokenAddress) {
            IWETH(wmaticTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        if (_fromToken == wmaticTokenAddress && _toToken == address(0)) {
            IWETH(wmaticTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (_fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromToken, _swapTarget);
        }

        uint256 iniBal = _getBalance(_toToken);
        require(
            factory.approvedTargets(_swapTarget),
            "DCA: Target not Authorized"
        );
        (bool success, ) = _swapTarget.call{ value: valueToSend }(_swapData);
        require(success, "DCA: Error Swapping Tokens");
        uint256 finalBal = _getBalance(_toToken);

        amtBought = finalBal - iniBal;
        require(amtBought >= _minToTokens, "DCA: High Slippage");
    }

    /**
     * @dev Internal function for token approvals
     * @param token The address of the token being approved
     * @param spender The address of the spender of the token
     */
    function _approveToken(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) > 0) return;
        else {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    // --- External View Functions ---

    /**
     * @notice View the current total quantity of principal tokens
     * earned as interest by this vault
     * @return interest accrued
     */
    function pendingInterestAccumulated()
        public
        view
        returns (uint256 interest)
    {
        (interest, , ) = _pendingInterestAccumulated();
    }

    /**
     * @notice View dividends earned by an account
     * @param _owner The address of the token holder
     * @return Quantity of wantTokens that can be withdrawn by _owner
     */
    function claimableWantOf(address _owner) external view returns (uint256) {
        uint256 pricePerShare = 1e18;
        if (address(wantTokenVault) != address(0)) {
            pricePerShare = wantTokenVault.getPricePerFullShare();
        }
        return (withdrawableFundsOf(_owner) * pricePerShare) / 1e18;
    }

    /**
     * @notice View interest bearing dividends earned by an account
     * (i.e. vault tokens)
     * @param _owner The address of the token holder
     * @return Quantity of vault wantTokens that can be withdrawn by _owner
     */
    function withdrawableFundsOf(address _owner) public view returns (uint256) {
        return accumulativeFundsOf(_owner) - withdrawnFunds[_owner];
    }

    /**
     * @notice View the amount of wantTokenVault tokens that an address has earned in total.
     * @dev accumulativeFundsOf(_owner) = withdrawableFundsOf(_owner) + withdrawnFundsOf(_owner)
     * = (pointsPerShare * balanceOf(_owner) + pointsCorrection[_owner]) / pointsMultiplier
     * @param _owner The address of a token holder.
     * @return The wantTokenVault tokens that `_owner` has earned in total.
     */
    function accumulativeFundsOf(address _owner) public view returns (uint256) {
        return
            ((pointsPerShare * balanceOf(_owner)).toInt256Safe() +
                pointsCorrection[_owner]).toUint256Safe() / pointsMultiplier;
    }

    /**
     * @notice View the total wantTokens owned by vault
     * @dev totalWantBalance = (wantToken balance) + (wantTokenVault balance) * pricePerShare
     */
    function totalWantBalance() public view returns (uint256) {
        (
            uint256 wantTokenBalance,
            uint256 wantVaultTokenEquivalent,

        ) = _totalWantBalance();
        return wantTokenBalance + wantVaultTokenEquivalent;
    }

    // --- Internal View Functions ---

    /**
     * @notice View the interest of principalToken that has accumulated
     * @return interest of principalToken that has accumulated
     * pricePerShare of vault token
     */
    function _pendingInterestAccumulated()
        internal
        view
        returns (
            uint256 interest,
            uint256 _totalAssets,
            uint256 _totalSupply
        )
    {
        _totalAssets = principalTokenVault.balance();
        _totalSupply = principalTokenVault.totalSupply();

        uint256 principalTokenVaultShares = principalTokenVault.balanceOf(
            address(this)
        );

        // principal tokens received if all vault shares burned
        uint256 netPrincipalOnWithdraw;
        if (_totalSupply == 0) {
            netPrincipalOnWithdraw = 0;
        } else {
            netPrincipalOnWithdraw = FullMath.mulDivRoundingUp(
                principalTokenVaultShares,
                _totalAssets,
                _totalSupply
            );
        }

        interest = netPrincipalOnWithdraw - totalPricipalDepositedInVault;
    }

    function _totalWantBalance()
        internal
        view
        returns (
            uint256 wantTokenBalance,
            uint256 wantVaultTokenEquivalent,
            uint256 wantPricePerShare
        )
    {
        wantTokenBalance = IERC20(wantToken).balanceOf(address(this));

        if (address(wantTokenVault) != address(0)) {
            uint256 wantVaultBalance = wantTokenVault.balanceOf(address(this));
            wantPricePerShare = wantTokenVault.getPricePerFullShare();
            wantVaultTokenEquivalent =
                (wantVaultBalance * wantPricePerShare) /
                1e18;
        }
    }

    /**
     * @notice Balance utility function
     * @param token The address of the token used in the balance call
     * (0 address if ETH)
     * @return balance Quantity of token that is held by this contract
     */
    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    // --- Receive ---

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
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
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

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

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable
{
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_)
        internal
        initializer
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_)
        internal
        initializer
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    uint256[45] private __gap;
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

    function __Context_init_unchained() internal initializer {}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
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

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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