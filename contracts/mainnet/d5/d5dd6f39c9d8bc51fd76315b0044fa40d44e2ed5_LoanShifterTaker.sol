pragma solidity ^0.6.0; 
  pragma experimental ABIEncoderV2;

abstract contract ILendingPool {
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
}  interface ERC20 {
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
}  abstract contract CTokenInterface is ERC20 {
    function mint(uint256 mintAmount) external virtual returns (uint256);

    // function mint() external virtual payable;

    function accrueInterest() public virtual returns (uint);

    function redeem(uint256 redeemTokens) external virtual returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external virtual returns (uint256);

    function borrow(uint256 borrowAmount) external virtual returns (uint256);

    function repayBorrow(uint256 repayAmount) external virtual returns (uint256);

    function repayBorrow() external virtual payable;

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external virtual returns (uint256);

    function repayBorrowBehalf(address borrower) external virtual payable;

    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral)
        external virtual
        returns (uint256);

    function liquidateBorrow(address borrower, address cTokenCollateral) external virtual payable;

    function exchangeRateCurrent() external virtual returns (uint256);

    function supplyRatePerBlock() external virtual returns (uint256);

    function borrowRatePerBlock() external virtual returns (uint256);

    function totalReserves() external virtual returns (uint256);

    function reserveFactorMantissa() external virtual returns (uint256);

    function borrowBalanceCurrent(address account) external virtual returns (uint256);

    function totalBorrowsCurrent() external virtual returns (uint256);

    function getCash() external virtual returns (uint256);

    function balanceOfUnderlying(address owner) external virtual returns (uint256);

    function underlying() external virtual returns (address);

    function getAccountSnapshot(address account) external virtual view returns (uint, uint, uint, uint);
}  abstract contract ILoanShifter {
    function getLoanAmount(uint, address) public view virtual returns(uint);
    function getUnderlyingAsset(address _addr) public virtual returns (address);
}  abstract contract DSProxyInterface {

    /// Truffle wont compile if this isn't commented
    // function execute(bytes memory _code, bytes memory _data)
    //     public virtual
    //     payable
    //     returns (address, bytes32);

    function execute(address _target, bytes memory _data) public virtual payable returns (bytes32);

    function setCache(address _cacheAddr) public virtual payable returns (bool);

    function owner() public virtual returns (address);
}  abstract contract Vat {

    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
    }

    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
        uint256 dust;  // Urn Debt Floor            [rad]
    }

    mapping (bytes32 => mapping (address => Urn )) public urns;
    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]

    function can(address, address) virtual public view returns (uint);
    function dai(address) virtual public view returns (uint);
    function frob(bytes32, address, address, address, int, int) virtual public;
    function hope(address) virtual public;
    function move(address, address, uint) virtual public;
    function fork(bytes32, address, address, int, int) virtual public;
}  abstract contract Manager {
    function last(address) virtual public returns (uint);
    function cdpCan(address, uint, address) virtual public view returns (uint);
    function ilks(uint) virtual public view returns (bytes32);
    function owns(uint) virtual public view returns (address);
    function urns(uint) virtual public view returns (address);
    function vat() virtual public view returns (address);
    function open(bytes32, address) virtual public returns (uint);
    function give(uint, address) virtual public;
    function cdpAllow(uint, address, uint) virtual public;
    function urnAllow(address, uint) virtual public;
    function frob(uint, int, int) virtual public;
    function flux(uint, address, uint) virtual public;
    function move(uint, address, uint) virtual public;
    function exit(address, uint, address, uint) virtual public;
    function quit(uint, address) virtual public;
    function enter(address, uint) virtual public;
    function shift(uint, uint) virtual public;
}  library Address {
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
}  library SafeMath {
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
}  library SafeERC20 {
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
}  contract AdminAuth {

    using SafeERC20 for ERC20;

    address public owner;
    address public admin;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /// @notice Admin is set by owner first time, after that admin is super role and has permission to change owner
    /// @param _admin Address of multisig that becomes admin
    function setAdminByOwner(address _admin) public {
        require(msg.sender == owner);
        require(admin == address(0));

        admin = _admin;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function setAdminByAdmin(address _admin) public {
        require(msg.sender == admin);

        admin = _admin;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function setOwnerByAdmin(address _owner) public {
        require(msg.sender == admin);

        owner = _owner;
    }

    /// @notice Destroy the contract
    function kill() public onlyOwner {
        selfdestruct(payable(owner));
    }

    /// @notice  withdraw stuck funds
    function withdrawStuckFunds(address _token, uint _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(owner).transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(owner, _amount);
        }
    }
}  abstract contract DSGuard {
    function canCall(address src_, address dst_, bytes4 sig) public view virtual returns (bool);

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public virtual;

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public virtual;

    function permit(address src, address dst, bytes32 sig) public virtual;

    function forbid(address src, address dst, bytes32 sig) public virtual;
}


abstract contract DSGuardFactory {
    function newGuard() public virtual returns (DSGuard guard);
}  abstract contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public virtual view returns (bool);
}  contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}


contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}  contract ProxyPermission {
    address public constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    /// @notice Called in the context of DSProxy to authorize an address
    /// @param _contractAddr Address which will be authorized
    function givePermission(address _contractAddr) public {
        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        guard.permit(_contractAddr, address(this), bytes4(keccak256("execute(address,bytes)")));
    }

    /// @notice Called in the context of DSProxy to remove authority of an address
    /// @param _contractAddr Auth address which will be removed from authority list
    function removePermission(address _contractAddr) public {
        address currAuthority = address(DSAuth(address(this)).authority());
        
        // if there is no authority, that means that contract doesn't have permission
        if (currAuthority == address(0)) {
            return;
        }

        DSGuard guard = DSGuard(currAuthority);
        guard.forbid(_contractAddr, address(this), bytes4(keccak256("execute(address,bytes)")));
    }
}  contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

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
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}  abstract contract TokenInterface {
    function allowance(address, address) public virtual returns (uint256);

    function balanceOf(address) public virtual returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(address, address, uint256) public virtual returns (bool);

    function deposit() public virtual payable;

    function withdraw(uint256) public virtual;
}  interface ExchangeInterfaceV2 {
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external payable returns (uint);

    function buy(address _srcAddr, address _destAddr, uint _destAmount) external payable returns(uint);

    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) external view returns (uint);

    function getBuyRate(address _srcAddr, address _destAddr, uint _srcAmount) external view returns (uint);
}  contract ZrxAllowlist is AdminAuth {

    mapping (address => bool) public zrxAllowlist;
    mapping(address => bool) private nonPayableAddrs;

    constructor() public {
        zrxAllowlist[0x6958F5e95332D93D21af0D7B9Ca85B8212fEE0A5] = true;
        zrxAllowlist[0x61935CbDd02287B511119DDb11Aeb42F1593b7Ef] = true;
        zrxAllowlist[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        zrxAllowlist[0x080bf510FCbF18b91105470639e9561022937712] = true;

        nonPayableAddrs[0x080bf510FCbF18b91105470639e9561022937712] = true;
    }

    function setAllowlistAddr(address _zrxAddr, bool _state) public onlyOwner {
        zrxAllowlist[_zrxAddr] = _state;
    }

    function isZrxAddr(address _zrxAddr) public view returns (bool) {
        return zrxAllowlist[_zrxAddr];
    }

    function addNonPayableAddr(address _nonPayableAddr) public onlyOwner {
		nonPayableAddrs[_nonPayableAddr] = true;
	}

	function removeNonPayableAddr(address _nonPayableAddr) public onlyOwner {
		nonPayableAddrs[_nonPayableAddr] = false;
	}

	function isNonPayableAddr(address _addr) public view returns(bool) {
		return nonPayableAddrs[_addr];
	}
}  contract Discount {
    address public owner;
    mapping(address => CustomServiceFee) public serviceFees;

    uint256 constant MAX_SERVICE_FEE = 400;

    struct CustomServiceFee {
        bool active;
        uint256 amount;
    }

    constructor() public {
        owner = msg.sender;
    }

    function isCustomFeeSet(address _user) public view returns (bool) {
        return serviceFees[_user].active;
    }

    function getCustomServiceFee(address _user) public view returns (uint256) {
        return serviceFees[_user].amount;
    }

    function setServiceFee(address _user, uint256 _fee) public {
        require(msg.sender == owner, "Only owner");
        require(_fee >= MAX_SERVICE_FEE || _fee == 0);

        serviceFees[_user] = CustomServiceFee({active: true, amount: _fee});
    }

    function disableServiceFee(address _user) public {
        require(msg.sender == owner, "Only owner");

        serviceFees[_user] = CustomServiceFee({active: false, amount: 0});
    }
}  contract SaverExchangeHelper {

    using SafeERC20 for ERC20;

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address payable public constant WALLET_ID = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant DISCOUNT_ADDRESS = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;
    address public constant SAVER_EXCHANGE_REGISTRY = 0x25dd3F51e0C3c3Ff164DDC02A8E4D65Bb9cBB12D;

    address public constant ERC20_PROXY_0X = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;
    address public constant ZRX_ALLOWLIST_ADDR = 0x4BA1f38427b33B8ab7Bb0490200dAE1F1C36823F;


    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    function getBalance(address _tokenAddr) internal view returns (uint balance) {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            balance = address(this).balance;
        } else {
            balance = ERC20(_tokenAddr).balanceOf(address(this));
        }
    }

    function approve0xProxy(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr != KYBER_ETH_ADDRESS) {
            ERC20(_tokenAddr).safeApprove(address(ERC20_PROXY_0X), _amount);
        }
    }

    function sendLeftover(address _srcAddr, address _destAddr, address payable _to) internal {
        // send back any leftover ether or tokens
        if (address(this).balance > 0) {
            _to.transfer(address(this).balance);
        }

        if (getBalance(_srcAddr) > 0) {
            ERC20(_srcAddr).safeTransfer(_to, getBalance(_srcAddr));
        }

        if (getBalance(_destAddr) > 0) {
            ERC20(_destAddr).safeTransfer(_to, getBalance(_destAddr));
        }
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }
}  contract SaverExchangeRegistry is AdminAuth {

	mapping(address => bool) private wrappers;

	constructor() public {
		wrappers[0x880A845A85F843a5c67DB2061623c6Fc3bB4c511] = true;
		wrappers[0x4c9B55f2083629A1F7aDa257ae984E03096eCD25] = true;
		wrappers[0x42A9237b872368E1bec4Ca8D26A928D7d39d338C] = true;
	}

	function addWrapper(address _wrapper) public onlyOwner {
		wrappers[_wrapper] = true;
	}

	function removeWrapper(address _wrapper) public onlyOwner {
		wrappers[_wrapper] = false;
	}

	function isWrapper(address _wrapper) public view returns(bool) {
		return wrappers[_wrapper];
	}
} 








contract SaverExchangeCore is SaverExchangeHelper, DSMath {

    // first is empty to keep the legacy order in place
    enum ExchangeType { _, OASIS, KYBER, UNISWAP, ZEROX }

    enum ActionType { SELL, BUY }

    struct ExchangeData {
        address srcAddr;
        address destAddr;
        uint srcAmount;
        uint destAmount;
        uint minPrice;
        address wrapper;
        address exchangeAddr;
        bytes callData;
        uint256 price0x;
    }

    /// @notice Internal method that preforms a sell on 0x/on-chain
    /// @dev Usefull for other DFS contract to integrate for exchanging
    /// @param exData Exchange data struct
    /// @return (address, uint) Address of the wrapper used and destAmount
    function _sell(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;
        uint tokensLeft = exData.srcAmount;

        // if selling eth, convert to weth
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(WETH_ADDRESS).deposit.value(exData.srcAmount)();
        }

        // Try 0x first and then fallback on specific wrapper
        if (exData.price0x > 0) {
            approve0xProxy(exData.srcAddr, exData.srcAmount);

            uint ethAmount = getProtocolFee(exData.srcAddr, msg.value, exData.srcAmount);
            (success, swapedTokens, tokensLeft) = takeOrder(exData, ethAmount, ActionType.SELL);

            if (success) {
                wrapper = exData.exchangeAddr;
            }
        }

        // fallback to desired wrapper if 0x failed
        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.SELL);
            wrapper = exData.wrapper;
        }

        require(getBalance(exData.destAddr) >= wmul(exData.minPrice, exData.srcAmount), "Final amount isn't correct");

        // if anything is left in weth, pull it to user as eth
        if (getBalance(WETH_ADDRESS) > 0) {
            TokenInterface(WETH_ADDRESS).withdraw(
                TokenInterface(WETH_ADDRESS).balanceOf(address(this))
            );
        }

        return (wrapper, swapedTokens);
    }

    /// @notice Internal method that preforms a buy on 0x/on-chain
    /// @dev Usefull for other DFS contract to integrate for exchanging
    /// @param exData Exchange data struct
    /// @return (address, uint) Address of the wrapper used and srcAmount
    function _buy(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;

        require(exData.destAmount != 0, "Dest amount must be specified");

        // if selling eth, convert to weth
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(WETH_ADDRESS).deposit.value(exData.srcAmount)();
        }

        if (exData.price0x > 0) {
            approve0xProxy(exData.srcAddr, exData.srcAmount);

            uint ethAmount = getProtocolFee(exData.srcAddr, msg.value, exData.srcAmount);
            (success, swapedTokens,) = takeOrder(exData, ethAmount, ActionType.BUY);

            if (success) {
                wrapper = exData.exchangeAddr;
            }
        }

        // fallback to desired wrapper if 0x failed
        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.BUY);
            wrapper = exData.wrapper;
        }

        require(swapedTokens >= exData.destAmount, "Final amount isn't correct");

        // if anything is left in weth, pull it to user as eth
        if (getBalance(WETH_ADDRESS) > 0) {
            TokenInterface(WETH_ADDRESS).withdraw(
                TokenInterface(WETH_ADDRESS).balanceOf(address(this))
            );
        }

        return (wrapper, getBalance(exData.destAddr));
    }

    /// @notice Takes order from 0x and returns bool indicating if it is successful
    /// @param _exData Exchange data
    /// @param _ethAmount Ether fee needed for 0x order
    function takeOrder(
        ExchangeData memory _exData,
        uint256 _ethAmount,
        ActionType _type
    ) private returns (bool success, uint256, uint256) {

        // write in the exact amount we are selling/buing in an order
        if (_type == ActionType.SELL) {
            writeUint256(_exData.callData, 36, _exData.srcAmount);
        } else {
            writeUint256(_exData.callData, 36, _exData.destAmount);
        }

        if (ZrxAllowlist(ZRX_ALLOWLIST_ADDR).isNonPayableAddr(_exData.exchangeAddr)) {
            _ethAmount = 0;
        }

        uint256 tokensBefore = getBalance(_exData.destAddr);

        if (ZrxAllowlist(ZRX_ALLOWLIST_ADDR).isZrxAddr(_exData.exchangeAddr)) {
            (success, ) = _exData.exchangeAddr.call{value: _ethAmount}(_exData.callData);
        } else {
            success = false;
        }

        uint256 tokensSwaped = 0;
        uint256 tokensLeft = _exData.srcAmount;

        if (success) {
            // check to see if any _src tokens are left over after exchange
            tokensLeft = getBalance(_exData.srcAddr);

            // convert weth -> eth if needed
            if (_exData.destAddr == KYBER_ETH_ADDRESS) {
                TokenInterface(WETH_ADDRESS).withdraw(
                    TokenInterface(WETH_ADDRESS).balanceOf(address(this))
                );
            }

            // get the current balance of the swaped tokens
            tokensSwaped = getBalance(_exData.destAddr) - tokensBefore;
        }

        return (success, tokensSwaped, tokensLeft);
    }

    /// @notice Calls wraper contract for exchage to preform an on-chain swap
    /// @param _exData Exchange data struct
    /// @param _type Type of action SELL|BUY
    /// @return swapedTokens For Sell that the destAmount, for Buy thats the srcAmount
    function saverSwap(ExchangeData memory _exData, ActionType _type) internal returns (uint swapedTokens) {
        require(SaverExchangeRegistry(SAVER_EXCHANGE_REGISTRY).isWrapper(_exData.wrapper), "Wrapper is not valid");

        uint ethValue = 0;

        ERC20(_exData.srcAddr).safeTransfer(_exData.wrapper, _exData.srcAmount);

        if (_type == ActionType.SELL) {
            swapedTokens = ExchangeInterfaceV2(_exData.wrapper).
                    sell{value: ethValue}(_exData.srcAddr, _exData.destAddr, _exData.srcAmount);
        } else {
            swapedTokens = ExchangeInterfaceV2(_exData.wrapper).
                    buy{value: ethValue}(_exData.srcAddr, _exData.destAddr, _exData.destAmount);
        }
    }

    function writeUint256(bytes memory _b, uint256 _index, uint _input) internal pure {
        if (_b.length < _index + 32) {
            revert("Incorrent lengt while writting bytes32");
        }

        bytes32 input = bytes32(_input);

        _index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(_b, _index), input)
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }

    /// @notice Calculates protocol fee 
    /// @param _srcAddr selling token address (if eth should be WETH)
    /// @param _msgValue msg.value in transaction
    /// @param _srcAmount amount we are selling
    function getProtocolFee(address _srcAddr, uint256 _msgValue, uint256 _srcAmount) internal returns(uint256) {
        // if we are not selling ETH msg value is always the protocol fee
        if (_srcAddr != WETH_ADDRESS) return _msgValue;

        // if msg value is larger than srcAmount, that means that msg value is protocol fee + srcAmount, so we subsctract srcAmount from msg value
        // we have an edge case here when protocol fee is higher than selling amount
        if (_msgValue > _srcAmount) return _msgValue - _srcAmount;

        // if msg value is lower than src amount, that means that srcAmount isn't included in msg value, so we return msg value
        return _msgValue;
    }

    function packExchangeData(ExchangeData memory _exData) public pure returns(bytes memory) {
        // splitting in two different bytes and encoding all because of stack too deep in decoding part

        bytes memory part1 = abi.encode(
            _exData.srcAddr,
            _exData.destAddr,
            _exData.srcAmount,
            _exData.destAmount
        );

        bytes memory part2 = abi.encode(
            _exData.minPrice,
            _exData.wrapper,
            _exData.exchangeAddr,
            _exData.callData,
            _exData.price0x
        );


        return abi.encode(part1, part2);
    }

    function unpackExchangeData(bytes memory _data) public pure returns(ExchangeData memory _exData) {
        (
            bytes memory part1,
            bytes memory part2
        ) = abi.decode(_data, (bytes,bytes));

        (
            _exData.srcAddr,
            _exData.destAddr,
            _exData.srcAmount,
            _exData.destAmount
        ) = abi.decode(part1, (address,address,uint256,uint256));

        (
            _exData.minPrice,
            _exData.wrapper,
            _exData.exchangeAddr,
            _exData.callData,
            _exData.price0x
        )
        = abi.decode(part2, (uint256,address,address,bytes,uint256));
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}  contract ShifterRegistry is AdminAuth {
    mapping (string => address) public contractAddresses;
    bool public finalized;

    function changeContractAddr(string memory _contractName, address _protoAddr) public onlyOwner {
        require(!finalized);
        contractAddresses[_contractName] = _protoAddr;
    }

    function lock() public onlyOwner {
        finalized = true;
    }

    function getAddr(string memory _contractName) public view returns (address contractAddr) {
        contractAddr = contractAddresses[_contractName];

        require(contractAddr != address(0), "No contract address registred");
    }

}












/// @title LoanShifterTaker Entry point for using the shifting operation
contract LoanShifterTaker is AdminAuth, ProxyPermission {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;

    Manager public constant manager = Manager(MANAGER_ADDRESS);
    ShifterRegistry public constant shifterRegistry = ShifterRegistry(0x597C52281b31B9d949a9D8fEbA08F7A2530a965e);

    enum Protocols { MCD, COMPOUND }
    enum SwapType { NO_SWAP, COLL_SWAP, DEBT_SWAP }

    struct LoanShiftData {
        Protocols fromProtocol;
        Protocols toProtocol;
        SwapType swapType;
        bool wholeDebt;
        uint collAmount;
        uint debtAmount;
        address debtAddr1;
        address debtAddr2;
        address addrLoan1;
        address addrLoan2;
        uint id1;
        uint id2;
    }

    /// @notice Main entry point, it will move or transform a loan
    /// @dev Called through DSProxy
    function moveLoan(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        LoanShiftData memory _loanShift
    ) public payable {
        if (_isSameTypeVaults(_loanShift)) {
            _forkVault(_loanShift);
            return;
        }

        _callCloseAndOpen(_exchangeData, _loanShift);
    }

    //////////////////////// INTERNAL FUNCTIONS //////////////////////////

    function _callCloseAndOpen(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        LoanShiftData memory _loanShift
    ) internal {
        address protoAddr = shifterRegistry.getAddr(getNameByProtocol(uint8(_loanShift.fromProtocol)));

        uint loanAmount = _loanShift.debtAmount;

        if (_loanShift.wholeDebt) {
            loanAmount = ILoanShifter(protoAddr).getLoanAmount(_loanShift.id1, _loanShift.addrLoan1);
        }

        (
            uint[8] memory numData,
            address[8] memory addrData,
            uint8[3] memory enumData,
            bytes memory callData
        )
        = _packData(_loanShift, _exchangeData);

        // encode data
        bytes memory paramsData = abi.encode(numData, addrData, enumData, callData, address(this));

        address payable loanShifterReceiverAddr = payable(shifterRegistry.getAddr("LOAN_SHIFTER_RECEIVER"));

        loanShifterReceiverAddr.transfer(address(this).balance);

        // call FL
        givePermission(loanShifterReceiverAddr);

        lendingPool.flashLoan(loanShifterReceiverAddr,
           getLoanAddr(_loanShift.debtAddr1, _loanShift.fromProtocol), loanAmount, paramsData);

        removePermission(loanShifterReceiverAddr);
    }

    function _forkVault(LoanShiftData memory _loanShift) internal {
        // Create new Vault to move to
        if (_loanShift.id2 == 0) {
            _loanShift.id2 = manager.open(manager.ilks(_loanShift.id1), address(this));
        }

        if (_loanShift.wholeDebt) {
            manager.shift(_loanShift.id1, _loanShift.id2);
        }
    }

    function _isSameTypeVaults(LoanShiftData memory _loanShift) internal pure returns (bool) {
        return _loanShift.fromProtocol == Protocols.MCD && _loanShift.toProtocol == Protocols.MCD
                && _loanShift.addrLoan1 == _loanShift.addrLoan2;
    }

    function getNameByProtocol(uint8 _proto) internal pure returns (string memory) {
        if (_proto == 0) {
            return "MCD_SHIFTER";
        } else if (_proto == 1) {
            return "COMP_SHIFTER";
        }
    }

    function getLoanAddr(address _address, Protocols _fromProtocol) internal returns (address) {
        if (_fromProtocol == Protocols.COMPOUND) {
            return CTokenInterface(_address).underlying();
        } else if (_fromProtocol == Protocols.MCD) {
            return DAI_ADDRESS;
        } else {
            return address(0);
        }
    }

    function _packData(
        LoanShiftData memory _loanShift,
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (uint[8] memory numData, address[8] memory addrData, uint8[3] memory enumData, bytes memory callData) {

        numData = [
            _loanShift.collAmount,
            _loanShift.debtAmount,
            _loanShift.id1,
            _loanShift.id2,
            exchangeData.srcAmount,
            exchangeData.destAmount,
            exchangeData.minPrice,
            exchangeData.price0x
        ];

        addrData = [
            _loanShift.addrLoan1,
            _loanShift.addrLoan2,
            _loanShift.debtAddr1,
            _loanShift.debtAddr2,
            exchangeData.srcAddr,
            exchangeData.destAddr,
            exchangeData.exchangeAddr,
            exchangeData.wrapper
        ];

        enumData = [
            uint8(_loanShift.fromProtocol),
            uint8(_loanShift.toProtocol),
            uint8(_loanShift.swapType)
        ];

        callData = exchangeData.callData;
    }

}