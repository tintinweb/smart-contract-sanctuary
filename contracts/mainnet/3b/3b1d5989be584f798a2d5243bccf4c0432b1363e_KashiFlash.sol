/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the Aave fee IFlashLoanReceiver.
 * @author Aave
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    // function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

    // function LENDING_POOL() external view returns (ILendingPool);
}

interface ILendingPoolAddressesProvider {}

interface ILendingPool {

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

}

interface IUniswapV2Router02 {

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata data,
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

    function factory() external pure returns (address);

}

interface IERC20 {

    function balanceOf(address) external view returns (uint);

    function approve(address, uint256) external returns (bool);

    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint) external returns (bool);
}

interface ISwapper {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);

    /// @notice Calculates the amount of token 'from' needed to complete the swap (amountFrom),
    /// this should be less than or equal to amountFromMax.
    /// Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for exactly 'exactAmountTo' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Transfers allocated, but unused 'from' tokens within the BentoBox to 'refundTo' (amountFromMax - amountFrom).
    /// Returns the amount of 'from' tokens withdrawn from BentoBox (amountFrom).
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) external returns (uint256 shareUsed, uint256 shareReturned);
}

struct Rebase {
    uint128 elastic;
    uint128 base;
}

interface Kashi {

    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        ISwapper swapper,
        bool open
    ) external;

    function masterContract() external view returns (address);

    function asset() external view returns (address);

    function collateral() external view returns (address);

    function userCollateralShare(address) external view returns (uint256);

    function userBorrowPart(address) external view returns (uint256);

    function totalBorrow() external view returns (Rebase memory);

}

interface BentoBox {

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function balanceOf(address token_, address user_) external view returns (uint256);

}

contract KashiFlash is IFlashLoanReceiver {

    address owner;

    ILendingPool public LENDING_POOL = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    ILendingPoolAddressesProvider public ADDRESSES_PROVIDER = ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    BentoBox private immutable bentobox = BentoBox(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);

    struct Swap {
        address user;
        address desiredAsset;
        uint256 amountInExact;
        uint256 amountOutMin;
    }
    Swap private _swap;

    struct Liquidation {
        address target;
        address kashiAddr;
        address collateral;
        address asset;
        uint ratio;
        address router;
    }
    Liquidation private liq;

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    /**
       Use an Aave flashloan to liquidate a Kashi position.
       Take a flashloan in the Kashi borrowed asset.
       Kashi liquidate(), which sends borrowed asset to BentoBox and receives collateral asset.
       Swap collateral asset for borrowed asset.
       Repay borrowed asset to Aave flashloan, keep the extra from the swap.
    **/
    function liquidateWithFlashloan(
        address target,
        address kashiAddr,
        address router
    ) public {
        // require(false, "beginning of liquidateWithFlashloan");
        // uint collateralAmount = Kashi(kashiAddr).userCollateralShare(target);
        uint borrowAmount = Kashi(kashiAddr).userBorrowPart(target);
        Rebase memory totalBorrow = Kashi(kashiAddr).totalBorrow();
        uint ratio = (totalBorrow.elastic + 1) / totalBorrow.base;
        // Get USDC flashloan
        liq = Liquidation({
            target: target,
            kashiAddr: kashiAddr, // has collateral and borrowed asset addresses
            collateral: Kashi(kashiAddr).collateral(),
            asset: Kashi(kashiAddr).asset(),
            ratio: ratio,
            router: router
        });
        // require(false, "after setting liquidation");

        // Take out flashloan
        address[] memory assets = new address[](1);
        assets[0] = Kashi(kashiAddr).asset();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount * liq.ratio;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        // require(false, "before flashloan");
        LENDING_POOL.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(0x0), // onBehalfOf, not used here
            bytes("0x0"), // params, not used here
            0 // referralCode
        );

    }

    /**
       Receive a flashloan in the Kashi borrowed asset.
       Approve and deposit that borrowed asset into BentoBox.
       Kashi liquidate(), which moves the borrowed asset to a diff user in BentoBox and receives collateral asset.
       Withdraw the collateral asset from BentoBox.
       Swap collateral asset for borrowed asset.
       Repay borrowed asset to Aave flashloan, keep the extra from the swap.
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) public override returns (bool) {

        // {
        // Simulate flashloan
        // address target = 0x22A6D12B6D500d173a1c74f61ADE047D05d8faC6;
        // address kashiAddr = 0xB7b45754167d65347C93F3B28797887b4b6cd2F3;

        // liq = Liquidation({
        //     target: 0x22A6D12B6D500d173a1c74f61ADE047D05d8faC6,
        //     kashiAddr: 0xB7b45754167d65347C93F3B28797887b4b6cd2F3, // has collateral and borrowed asset addresses
        //     collateral: Kashi(0xB7b45754167d65347C93F3B28797887b4b6cd2F3).collateral(),
        //     asset: Kashi(0xB7b45754167d65347C93F3B28797887b4b6cd2F3).asset()
        // });

        require(IERC20(assets[0]).balanceOf(address(this)) >= amounts[0], "Insufficient borrow amount");
        IERC20(assets[0]).approve(address(bentobox), amounts[0]);
        bentobox.deposit(
            IERC20(assets[0]),
            address(this),
            address(this),
            amounts[0],
            0
        );


        // uint collateralAmount = Kashi(liq.kashiAddr).userCollateralShare(liq.target);
        // require(collateralAmount > 0, "User collateral should not be 0");
        // uint collateralAmount = bentobox.balanceOf(liq.target, collateral);

        uint collateralRetrieved;
        {
            address[] memory users = new address[](1);
            users[0] = liq.target;

            uint[] memory amountsMinusFees = new uint[](1);
            amountsMinusFees[0] = amounts[0] * 95 / 100; // TODO: Add in our contract call

            // We make it here
            liquidate(
                liq.kashiAddr,
                users,
                amountsMinusFees, // maxBorrowParts; matches the flashloan since that's what we're providing
                address(this)
            );

            // require(false, "Before withdraw");
            collateralRetrieved = bentobox.balanceOf(liq.collateral, address(this));
            bentobox.withdraw(
                IERC20(liq.collateral),
                address(this),
                address(this),
                // collateralAmount,
                collateralRetrieved,
                0
            );
        }


        // Swap collateral
        {
            uint loanPlusPremium = amounts[0] + premiums[0];

            address[] memory data = new address[](2);
            data[0] = liq.collateral;
            data[1] = assets[0];
            uint deadline = type(uint).max;

            uint bal = IERC20(liq.collateral).balanceOf(address(this));
            require(bal >= collateralRetrieved, "Insufficient input amount to swap");
            IERC20(liq.collateral).approve(address(liq.router), collateralRetrieved);
            IUniswapV2Router02(liq.router).swapExactTokensForTokens(
                collateralRetrieved,
                loanPlusPremium,
                data,
                address(this),
                deadline
            );

            // Approve the LendingPool contract allowance to *pull* the owed amount
            IERC20(assets[0]).approve(address(LENDING_POOL), loanPlusPremium);
            uint borrowBalance = IERC20(assets[0]).balanceOf(address(this));
            require(
                borrowBalance >= loanPlusPremium,
                "Not enough tokens to repay flashloan"
            );
            // uint surplus = borrowBalance - loanPlusPremium;
            IERC20(assets[0]).transfer(owner, borrowBalance - loanPlusPremium);
            // For manual testing before adding the flashloan back
            // IERC20(assets[0]).transfer(address(LENDING_POOL), loanPlusPremium);
        }

        // Remove the swap information from storage
        delete liq;

        return true;
    }

    // Precondition: the borrowed asset is in BentoBox owned by this contract
    function liquidate(
        address kashiAddr,
        address[] memory users,
        uint256[] memory maxBorrowParts,
        address to
    ) public {
        address collateral = Kashi(kashiAddr).collateral();
        address borrow = Kashi(kashiAddr).asset();
        // uint collateralBalanceBefore = Kashi(kashiAddr).userCollateralShare(address(this));
        uint collateralBalanceBefore = bentobox.balanceOf(collateral, address(this));
        uint borrowBalanceBefore = bentobox.balanceOf(borrow, address(this));


        bentobox.setMasterContractApproval(
            address(this),
            Kashi(kashiAddr).masterContract(),
            true,
            0,
            0x0,
            0x0
        );

        Rebase memory totalBorrow = Kashi(kashiAddr).totalBorrow();
        require(borrowBalanceBefore >= maxBorrowParts[0], "Don't have enough to repay the borrow");
        // IERC20(borrow).approve(bentoboxAddr, maxBorrowParts[0]); // doesn't do anything, the asset is already in bento
        Kashi(kashiAddr).liquidate(
            users,
            maxBorrowParts,
            address(this),
            ISwapper(address(0x0)),
            true
        );

        uint collateralBalanceAfter = bentobox.balanceOf(collateral, address(this));
        uint borrowBalanceAfter = bentobox.balanceOf(borrow, address(this));
        require(collateralBalanceAfter > collateralBalanceBefore, "BentoBox balance did not increase after liquidation");
    }

}