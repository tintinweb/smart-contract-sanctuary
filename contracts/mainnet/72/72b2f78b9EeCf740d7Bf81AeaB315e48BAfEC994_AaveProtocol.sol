// File: contracts/Lend/ProtocolInterface.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0;

abstract contract ProtocolInterface {
    function deposit(
        address _user,
        uint256 _amount,
        address _token,
        address _cToken
    ) public virtual;

    function withdraw(
        address _user,
        uint256 _amount,
        address _token,
        address _cToken
    ) public virtual;
}

// File: contracts/interfaces/LendingPoolAddressesProviderInterface.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0;

abstract contract LendingPoolAddressesProviderInterface {
    function getLendingPool() external virtual returns (address);

    function getLendingPoolCore() external virtual returns (address);
}

// File: contracts/interfaces/LendingPool.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0;

abstract contract LendingPool {
    function deposit(
        address,
        uint256,
        uint16
    ) external virtual;

    function redeemUnderlying(
        address _reserve,
        address payable _user,
        uint256 _amount,
        uint256 _aTokenBalanceAfterRedeem
    ) external virtual;

    function borrow(
        address _reserve,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode
    ) external virtual;

    function repay(
        address _reserve,
        uint256 _amount,
        address payable _onBehalfOf
    ) external virtual payable;

    function swapBorrowRateMode(address _reserve) external virtual;

    function rebalanceStableBorrowRate(address _reserve, address _user) external virtual;

    function setUserUseReserveAsCollateral(address, bool) external virtual;

    function liquidationCall(
        address _collateral,
        address _reserve,
        address _user,
        uint256 _purchaseAmount,
        bool _receiveAToken
    ) external virtual payable;

    function flashLoan(
        address _receiver,
        address _reserve,
        uint256 _amount,
        bytes memory _params
    ) public virtual;

    function getReserveConfigurationData(address _reserve)
        external
        virtual
        view
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            address interestRateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive
        );

    function getReserveData(address _reserve)
        external
        virtual
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            address aTokenAddress,
            uint40 lastUpdateTimestamp
        );

    function getUserAccountData(address _user)
        external
        virtual
        view
        returns (
            uint256 totalLiquidityETH,
            uint256 totalCollateralETH,
            uint256 totalBorrowsETH,
            uint256 totalFeesETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserReserveData(address _reserve, address _user)
        external
        virtual
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentBorrowBalance,
            uint256 principalBorrowBalance,
            uint256 borrowRateMode,
            uint256 borrowRate,
            uint256 liquidityRate,
            uint256 originationFee,
            uint256 variableBorrowIndex,
            uint256 lastUpdateTimestamp,
            bool usageAsCollateralEnabled
        );

    function getReserves() external virtual view returns (address[] memory);
}

// File: contracts/interfaces/ERC20.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0;

interface ERC20 {
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _src, address indexed _dst, uint256 _amount);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    // function decimals() external view returns (uint256 digits);

   
}

// File: contracts/interfaces/ATokenInterface.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0;


abstract contract ATokenInterface is ERC20 {
    function principalBalanceOf(address _user) external virtual view returns (uint256 balance);

    function UINT_MAX_VALUE() external virtual returns (uint256);

    function underlyingAssetAddress() external virtual view returns (address);

    function getUserIndex(address _user) external virtual view returns (uint256);

    function getInterestRedirectionAddress(address _user) external virtual view returns (address);

    function getRedirectedBalance(address _user) external virtual view returns (uint256);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool);

    function redirectInterestStream(address _to) external virtual;

    function redirectInterestStreamOf(address _from, address _to) external virtual;

    function allowInterestRedirectionTo(address _to) external virtual;

    function redeem(uint256 _amount) external virtual;

    function mintOnDeposit(address _account, uint256 _amount) external virtual;

    function burnOnLiquidation(address _account, uint256 _value) external virtual;

    function transferOnLiquidation(
        address _from,
        address _to,
        uint256 _value
    ) external virtual;

    function isTransferAllowed(address _user, uint256 _amount) external virtual view returns (bool);
}

// File: contracts/Lend/aave/AaveProtocol.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;






/**
 * @notice AaveProtocol
 * @author Solidefi
 */
contract AaveProtocol is ProtocolInterface {
    address public constant LENDING_PROTO_ADDRESS_PROV = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

    ATokenInterface public aDaiContract;
    LendingPoolAddressesProviderInterface public provider;
    LendingPool public lendingPool;

    /**
     * @dev Deposit DAI to aave protocol return cDAI to user proxy wallet.
     * @param _user User proxy wallet address.
     * @param _amount Amount of DAI.
     */
    function deposit(
        address _user,
        uint256 _amount,
        address _token,
        address _aToken
    ) public override {
        aDaiContract = ATokenInterface(_aToken);
        provider = LendingPoolAddressesProviderInterface(LENDING_PROTO_ADDRESS_PROV);

        lendingPool = LendingPool(provider.getLendingPool());
        require(ERC20(_token).transferFrom(_user, address(this), _amount), "Nothing to deposit");
        ERC20(_token).approve(provider.getLendingPoolCore(), uint256(-1));
        lendingPool.deposit(_token, _amount, 0);

        aDaiContract.transfer(_user, aDaiContract.balanceOf(address(this)));
    }

    /**
     *@dev Withdraw DAI from aave protocol return it to users EOA
     *@param _user User proxy wallet address.
     *@param _amount Amount of Token.
     *@param _token Token address.
     *@param _aToken Interest-Bearing Token address.
     */
    function withdraw(
        address _user,
        uint256 _amount,
        address _token,
        address _aToken
    ) public override {
        aDaiContract = ATokenInterface(_aToken);
        require(aDaiContract.transferFrom(_user, address(this), _amount), "Nothing to withdraw");

        aDaiContract.redeem(_amount);

        ERC20(_token).transfer(_user, _amount);
    }
}