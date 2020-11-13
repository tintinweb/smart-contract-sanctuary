pragma solidity ^0.6.0; interface ERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
} abstract contract GasTokenInterface is ERC20 {
    function free(uint256 value) public virtual returns (bool success);

    function freeUpTo(uint256 value) public virtual returns (uint256 freed);

    function freeFrom(address from, uint256 value) public virtual returns (bool success);

    function freeFromUpTo(address from, uint256 value) public virtual returns (uint256 freed);
} contract GasBurner {
    // solhint-disable-next-line const-name-snakecase
    GasTokenInterface public constant gasToken = GasTokenInterface(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    modifier burnGas(uint _amount) {
        if (gasToken.balanceOf(address(this)) >= _amount) {
            gasToken.free(_amount);
        }

        _;
    }
} abstract contract IAToken {
    function redeem(uint256 _amount) external virtual;
} abstract contract ILendingPool {
    function flashLoan( address payable _receiver, address _reserve, uint _amount, bytes calldata _params) external virtual;
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external virtual payable;
	function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external virtual;
	function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external virtual;
	function repay( address _reserve, uint256 _amount, address payable _onBehalfOf) external virtual payable;
	function swapBorrowRateMode(address _reserve) external virtual;
    function getReserves() external virtual view returns(address[] memory);

    /// @param _reserve underlying token address
    function getReserveData(address _reserve)
        external virtual
        view
        returns (
            uint256 totalLiquidity,               // reserve total liquidity
            uint256 availableLiquidity,           // reserve available liquidity for borrowing
            uint256 totalBorrowsStable,           // total amount of outstanding borrows at Stable rate
            uint256 totalBorrowsVariable,         // total amount of outstanding borrows at Variable rate
            uint256 liquidityRate,                // current deposit APY of the reserve for depositors, in Ray units.
            uint256 variableBorrowRate,           // current variable rate APY of the reserve pool, in Ray units.
            uint256 stableBorrowRate,             // current stable rate APY of the reserve pool, in Ray units.
            uint256 averageStableBorrowRate,      // current average stable borrow rate
            uint256 utilizationRate,              // expressed as total borrows/total liquidity.
            uint256 liquidityIndex,               // cumulative liquidity index
            uint256 variableBorrowIndex,          // cumulative variable borrow index
            address aTokenAddress,                // aTokens contract address for the specific _reserve
            uint40 lastUpdateTimestamp            // timestamp of the last update of reserve data
        );

    /// @param _user users address
    function getUserAccountData(address _user)
        external virtual
        view
        returns (
            uint256 totalLiquidityETH,            // user aggregated deposits across all the reserves. In Wei
            uint256 totalCollateralETH,           // user aggregated collateral across all the reserves. In Wei
            uint256 totalBorrowsETH,              // user aggregated outstanding borrows across all the reserves. In Wei
            uint256 totalFeesETH,                 // user aggregated current outstanding fees in ETH. In Wei
            uint256 availableBorrowsETH,          // user available amount to borrow in ETH
            uint256 currentLiquidationThreshold,  // user current average liquidation threshold across all the collaterals deposited
            uint256 ltv,                          // user average Loan-to-Value between all the collaterals
            uint256 healthFactor                  // user current Health Factor
    );    

    /// @param _reserve underlying token address
    /// @param _user users address
    function getUserReserveData(address _reserve, address _user)
        external virtual
        view
        returns (
            uint256 currentATokenBalance,         // user current reserve aToken balance
            uint256 currentBorrowBalance,         // user current reserve outstanding borrow balance
            uint256 principalBorrowBalance,       // user balance of borrowed asset
            uint256 borrowRateMode,               // user borrow rate mode either Stable or Variable
            uint256 borrowRate,                   // user current borrow rate APY
            uint256 liquidityRate,                // user current earn rate on _reserve
            uint256 originationFee,               // user outstanding loan origination fee
            uint256 variableBorrowIndex,          // user variable cumulative index
            uint256 lastUpdateTimestamp,          // Timestamp of the last data update
            bool usageAsCollateralEnabled         // Whether the user's current reserve is enabled as a collateral
    );

    function getReserveConfigurationData(address _reserve)
        external virtual
        view
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            address rateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive
    );

    // ------------------ LendingPoolCoreData ------------------------
    function getReserveATokenAddress(address _reserve) public virtual view returns (address);
    function getReserveConfiguration(address _reserve)
        external virtual
        view
        returns (uint256, uint256, uint256, bool);
    function getUserUnderlyingAssetBalance(address _reserve, address _user)
        public virtual
        view
        returns (uint256);

    function getReserveCurrentLiquidityRate(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveCurrentVariableBorrowRate(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveTotalLiquidity(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveAvailableLiquidity(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveTotalBorrowsVariable(address _reserve)
        public virtual
        view
        returns (uint256);

    // ---------------- LendingPoolDataProvider ---------------------
    function calculateUserGlobalData(address _user)
        public virtual
        view
        returns (
            uint256 totalLiquidityBalanceETH,
            uint256 totalCollateralBalanceETH,
            uint256 totalBorrowBalanceETH,
            uint256 totalFeesETH,
            uint256 currentLtv,
            uint256 currentLiquidationThreshold,
            uint256 healthFactor,
            bool healthFactorBelowThreshold
        );
} /**
@title ILendingPoolAddressesProvider interface
@notice provides the interface to fetch the LendingPoolCore address
 */
abstract contract ILendingPoolAddressesProvider {

    function getLendingPool() public virtual view returns (address);
    function getLendingPoolCore() public virtual view returns (address payable);
    function getLendingPoolConfigurator() public virtual view returns (address);
    function getLendingPoolDataProvider() public virtual view returns (address);
    function getLendingPoolParametersProvider() public virtual view returns (address);
    function getTokenDistributor() public virtual view returns (address);
    function getFeeProvider() public virtual view returns (address);
    function getLendingPoolLiquidationManager() public virtual view returns (address);
    function getLendingPoolManager() public virtual view returns (address);
    function getPriceOracle() public virtual view returns (address);
    function getLendingRateOracle() public virtual view returns (address);
} library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}







library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     */
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(ERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
} /// @title Basic compound interactions through the DSProxy
contract AaveBasicProxy is GasBurner {

    using SafeERC20 for ERC20;

    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant AAVE_LENDING_POOL_ADDRESSES = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

    uint16 public constant AAVE_REFERRAL_CODE = 64;

    /// @notice User deposits tokens to the Aave protocol
    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @param _tokenAddr The address of the token to be deposited
    /// @param _amount Amount of tokens to be deposited
    function deposit(address _tokenAddr, uint256 _amount) public burnGas(5) payable {
        address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        uint ethValue = _amount;

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);
            approveToken(_tokenAddr, lendingPoolCore);
            ethValue = 0;
        }

        ILendingPool(lendingPool).deposit{value: ethValue}(_tokenAddr, _amount, AAVE_REFERRAL_CODE);

        setUserUseReserveAsCollateralIfNeeded(_tokenAddr);
    }

    /// @notice User withdraws tokens from the Aave protocol
    /// @param _tokenAddr The address of the token to be withdrawn
    /// @param _aTokenAddr ATokens to be withdrawn
    /// @param _amount Amount of tokens to be withdrawn
    /// @param _wholeAmount If true we will take the whole amount on chain
    function withdraw(address _tokenAddr, address _aTokenAddr, uint256 _amount, bool _wholeAmount) public burnGas(8) {
        uint256 amount = _wholeAmount ? ERC20(_aTokenAddr).balanceOf(address(this)) : _amount;

        IAToken(_aTokenAddr).redeem(amount);

        withdrawTokens(_tokenAddr);
    }

    /// @notice User borrows tokens to the Aave protocol
    /// @param _tokenAddr The address of the token to be borrowed
    /// @param _amount Amount of tokens to be borrowed
    /// @param _type Send 1 for variable rate and 2 for fixed rate
    function borrow(address _tokenAddr, uint256 _amount, uint256 _type) public burnGas(8) {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        ILendingPool(lendingPool).borrow(_tokenAddr, _amount, _type, AAVE_REFERRAL_CODE);

        withdrawTokens(_tokenAddr);
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Aave protocol
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _aTokenAddr ATokens to be paybacked
    /// @param _amount Amount of tokens to be payed back
    /// @param _wholeDebt If true the _amount will be set to the whole amount of the debt
    function payback(address _tokenAddr, address _aTokenAddr, uint256 _amount, bool _wholeDebt) public burnGas(3) payable {
        address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        uint256 amount = _amount;

        if (_wholeDebt) {
            (,amount,,,,,,,,) = ILendingPool(lendingPool).getUserReserveData(_tokenAddr, address(this));
        }

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), amount);
            approveToken(_tokenAddr, lendingPoolCore);
        }

        ILendingPool(lendingPool).repay{value: msg.value}(_tokenAddr, amount, payable(address(this)));

        withdrawTokens(_tokenAddr);
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Aave protocol
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _aTokenAddr ATokens to be paybacked
    /// @param _amount Amount of tokens to be payed back
    /// @param _wholeDebt If true the _amount will be set to the whole amount of the debt
    function paybackOnBehalf(address _tokenAddr, address _aTokenAddr, uint256 _amount, bool _wholeDebt, address payable _onBehalf) public burnGas(3) payable {
        address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        uint256 amount = _amount;

        if (_wholeDebt) {
            (,amount,,,,,,,,) = ILendingPool(lendingPool).getUserReserveData(_tokenAddr, _onBehalf);
        }

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), amount);
            approveToken(_tokenAddr, lendingPoolCore);
        }

        ILendingPool(lendingPool).repay{value: msg.value}(_tokenAddr, amount, _onBehalf);

        withdrawTokens(_tokenAddr);
    }

    /// @notice Helper method to withdraw tokens from the DSProxy
    /// @param _tokenAddr Address of the token to be withdrawn
    function withdrawTokens(address _tokenAddr) public {
        uint256 amount = _tokenAddr == ETH_ADDR ? address(this).balance : ERC20(_tokenAddr).balanceOf(address(this));

        if (amount > 0) {
            if (_tokenAddr != ETH_ADDR) {
                ERC20(_tokenAddr).safeTransfer(msg.sender, amount);
            } else {
                msg.sender.transfer(amount);
            }
        }
    }

    /// @notice Approves token contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _caller Address which will gain the approval
    function approveToken(address _tokenAddr, address _caller) internal {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeApprove(_caller, 0);
            ERC20(_tokenAddr).safeApprove(_caller, uint256(-1));
        }
    }

    function setUserUseReserveAsCollateralIfNeeded(address _tokenAddr) public {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        (,,,,,,,,,bool collateralEnabled) = ILendingPool(lendingPool).getUserReserveData(_tokenAddr, address(this));

        if (!collateralEnabled) {
            ILendingPool(lendingPool).setUserUseReserveAsCollateral(_tokenAddr, true);
        }
    }

    function setUserUseReserveAsCollateral(address _tokenAddr, bool _true) public {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        ILendingPool(lendingPool).setUserUseReserveAsCollateral(_tokenAddr, _true);
    }

    function swapBorrowRateMode(address _reserve) public {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        ILendingPool(lendingPool).swapBorrowRateMode(_reserve);
    }
}