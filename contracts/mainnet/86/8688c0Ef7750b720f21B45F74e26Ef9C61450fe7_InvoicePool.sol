pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./VersionedInitializable.sol";

import "./MintableERC20.sol";
import "./MockUSDC.sol";
import "./LendingPoolAddressesProvider.sol";
// import "../configuration/LendingPoolParametersProvider.sol";
import "./PToken.sol";
// import "../libraries/WadRayMath.sol";
import "./IFeeProvider.sol";
import "./IPriceOracleGetter.sol";

import "./LendingPool.sol";
import "./LendingPoolDataProvider.sol";


contract InvoicePool is Ownable {
    using SafeMath for uint256;
    using Address for address;

    /// FIELD/GLOBAL VARIABLES
    uint256 public constant UINT_MAX_VALUE = uint256(-1);
    LendingPool public lendingPool;
    address public lendingPoolCore;
    LendingPoolDataProvider public lendingPoolDataProvider;
    LendingPoolAddressesProvider public lendingPoolAddressesProvider;

    address public PAX;
    MockUSDC public USDp;


    /// EVENTS
    event CollateralDeposited(address indexed token, uint256 amount);
    event CollateralWithdrawn(address indexed token, uint256 amount);
    event Borrowed(address indexed token, uint256 amount);
    event Repaid(address indexed token, uint256 amount);

    modifier onlyWalletOrOwner() {
        require(msg.sender == address(this) || msg.sender == owner(), "caller should be contract itself or owner");
        _;
    }

    constructor(
        address _USDpToken, address _PAXToken,
        address _lendingPool, address _lendingPoolCore
    ) public
    {
        require(
            (_USDpToken != address(0) && _lendingPool != address(0) && 
            _PAXToken != address(0) && _lendingPoolCore != address(0)),
            "Invalid zero address passed as constructor argument"
        );
        USDp = MockUSDC(_USDpToken);
        PAX = _PAXToken;
        lendingPool = LendingPool(_lendingPool);
        lendingPoolCore = _lendingPoolCore;
        lendingPoolAddressesProvider = LendingPoolAddressesProvider(address(lendingPool.addressesProvider));
        lendingPoolDataProvider = LendingPoolDataProvider(address(lendingPool.dataProvider));
    }

    function deposit(uint256 amount) public onlyWalletOrOwner {
        // if balance of contract is less than amount, mint tokens to reach balance
        if (USDp.balanceOf(address(this)) < amount) {
            USDp.mint(amount.sub(USDp.balanceOf(address(this))));
        }
        // approve lending pool core before deposit
        USDp.approve(lendingPoolCore, amount);
        // deposit amount of tokens into lending pool
        // initial deposit is automatically set as collateral
        lendingPool.deposit(address(USDp), amount, 0);
        // emit deposit event
        emit CollateralDeposited(address(USDp), amount);
    }

    function withdraw() public onlyWalletOrOwner {
        address PTokenAddress;
        ( , , , , , , , , , , , PTokenAddress, ) = lendingPool.getReserveData(address(USDp));
        uint256 previousBalance = USDp.balanceOf(address(this));
        // will only redeem tokens not used/locked as collateral from lending pool
        PToken(PTokenAddress).redeem(UINT_MAX_VALUE);
        uint256 currentBalance = USDp.balanceOf(address(this));
        uint256 withdrawnAmount = currentBalance.sub(previousBalance);
        USDp.burn(withdrawnAmount);
        emit CollateralWithdrawn(address(USDp), withdrawnAmount);
    }

    function borrow(uint256 amount) external onlyOwner {
        uint256 borrowFee = IFeeProvider(lendingPoolAddressesProvider.getFeeProvider()).calculateLoanOriginationFee(address(this), amount);
        (
            , 
            uint256 totalCollateralBalanceETH,
            uint256 totalBorrowBalanceETH,
            uint256 totalFeesETH,
            uint256 currentLtv,
            ,
            ,
            
        ) = lendingPoolDataProvider.calculateUserGlobalData(address(this));

        uint256 amountOfCollateralNeededETH = lendingPoolDataProvider.calculateCollateralNeededInETH( 
            PAX,
            amount,
            borrowFee,
            totalBorrowBalanceETH,
            totalFeesETH,
            currentLtv
        );

        if (amountOfCollateralNeededETH > totalCollateralBalanceETH) {
            IPriceOracleGetter oracle = IPriceOracleGetter(
                lendingPoolAddressesProvider.getPriceOracle()
            );

            uint256 tokenUnit = 10**USDp.decimals();
            uint256 reserveUnitPrice = oracle.getAssetPrice(address(USDp));
            uint256 collateralToDeposit = amountOfCollateralNeededETH.mul(reserveUnitPrice).div(
                        tokenUnit);

            USDp.approve(lendingPoolCore, collateralToDeposit);

            if (USDp.balanceOf(address(this)) < collateralToDeposit) {
                USDp.mint(collateralToDeposit.sub(USDp.balanceOf(address(this))));
            }

            deposit(collateralToDeposit);
        }

        lendingPool.borrow(PAX, amount, 1, 0);
        emit Borrowed(PAX, amount);
    }

    function repay(uint256 amount) external onlyOwner {
        address payable invoicePool = address(uint160(address(this)));
        IERC20(PAX).approve(lendingPoolCore, amount);
        lendingPool.repay(PAX, amount, invoicePool);
        // after repay, compute how much USDp collateral can be withdrawn in PToken contract and 
        // burn when received
        withdraw();
        emit Repaid(PAX, amount);
    }
}