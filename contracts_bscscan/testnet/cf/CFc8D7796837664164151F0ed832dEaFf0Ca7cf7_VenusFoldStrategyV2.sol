pragma solidity 0.6.12;


interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IVBNB {
    function mint() external payable;

    function borrow(uint borrowAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function repayBorrow() external payable;
}

interface IPancakeRouter02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

abstract contract VTokenInterface {
    function balanceOfUnderlying(address owner) external virtual returns (uint);

    function borrowBalanceCurrent(address account) external virtual returns (uint);

    function getCash() external virtual view returns (uint);
}

abstract contract VBep20Interface {
    function mint(uint mintAmount) external virtual returns (uint);

    function redeem(uint redeemTokens) external virtual returns (uint);

    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);

    function borrow(uint borrowAmount) external virtual returns (uint);

    function repayBorrow(uint repayAmount) external virtual returns (uint);
}

abstract contract CompleteVToken is VBep20Interface, VTokenInterface {}

abstract contract ComptrollerInterface {
    function claimVenus(address holder, address[] memory vTokens) external virtual;

    function enterMarkets(address[] calldata vTokens) external virtual returns (uint[] memory);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }



    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

abstract contract ReentrancyGuardUpgradeable {
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

    function __ReentrancyGuard_init() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    uint256[50] private __gap;
}

contract BaseUpgradeableStrategyStorage {
    address public underlying;
    address public rewardToken;
    address public rewardPool;
    uint256 public  sellFloor;
    bool public sell;
    uint256 public allowedFeeNumerator;
    address public vToken;
    address public comptroller;
    address public pancakeswapRouterV2;
    uint256 public suppliedInUnderlying;
    address[] public liquidationPath;
    bool public _initialized;
    address public governance;
    mapping(address => bool) public restrictedPermissions;
}

contract VenusInteractorInitializableV2 is ReentrancyGuardUpgradeable, BaseUpgradeableStrategyStorage {

    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    function initialize(
    ) internal {
        __ReentrancyGuard_init();
        // Enter the market
        address[] memory vTokens = new address[](1);
        vTokens[0] = vToken;
        ComptrollerInterface(comptroller).enterMarkets(vTokens);

    }

    /**
    * Supplies to Venus
    */
    function _supply(uint256 amount) internal returns (uint256) {
        uint256 balance = IBEP20(underlying).balanceOf(address(this));
        if (amount < balance) {
            balance = amount;
        }
        IBEP20(underlying).safeApprove(vToken, 0);
        IBEP20(underlying).safeApprove(vToken, balance);
        uint256 mintResult = CompleteVToken(vToken).mint(balance);
        require(mintResult == 0, "Supplying failed");
        return balance;
    }

    /**
    * Redeem liquidity in underlying
    */
    function _redeemUnderlying(uint256 amountUnderlying) internal {
        if (amountUnderlying > 0) {
            CompleteVToken(vToken).redeemUnderlying(amountUnderlying);
        }
    }
    /**
    * Get XVS
    */
    function claimVenus() public {
        address[] memory markets = new address[](1);
        markets[0] = address(vToken);
        ComptrollerInterface(comptroller).claimVenus(address(this), markets);
    }


    function redeemMaximumNoFold() internal {
        // amount of liquidity in Venus
        uint256 available = CompleteVToken(vToken).getCash();
        // amount we supplied
        uint256 supplied = CompleteVToken(vToken).balanceOfUnderlying(address(this));

        _redeemUnderlying(SafeMath.min(supplied, available));
    }
}

contract VenusFoldStrategyV2 is VenusInteractorInitializableV2 {

    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    event ProfitNotClaimed();
    event TooLowBalance();
    event Liquidated(uint256 amount);
    modifier restricted() {
        require(restrictedPermissions[msg.sender] == true, "restrictedPermissions");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Not governance");
        _;
    }

    modifier initializer(){
        require(_initialized == false);
        _;
        _initialized = true;
    }

    function initializeStrategy(
        address _underlying,
        address _vtoken,
        address _comptroller,
        address _xvs,
        address _governance,
        address _pancakeSwap,
        uint256 _sellFloor,
        uint256 _allowedFeeNumerator,
        address[] calldata _liquidationPath
    )
    external initializer {
        underlying = _underlying;
        //0x16227D60f7a0e586C66B005219dfc887D13C9531
        comptroller = _comptroller;
        //0x94d1820b2D1c7c7452A163983Dc888CEC546b77D
        rewardToken = _xvs;
        //0xb9e0e753630434d7863528cc73cb7ac638a7c8ff
        sell = true;
        sellFloor = _sellFloor;
        governance = _governance;
        restrictedPermissions[governance] = true;
        vToken = _vtoken;
        //0xD5C4C2e2facBEB59D0216D0595d63FcDc6F9A1a7
        allowedFeeNumerator = _allowedFeeNumerator;
        liquidationPath = _liquidationPath;
        //[0xb9e0e753630434d7863528cc73cb7ac638a7c8ff,0x16227D60f7a0e586C66B005219dfc887D13C9531]
        pancakeswapRouterV2 = _pancakeSwap;
        // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    }

    modifier updateSupplyInTheEnd() {
        _;
        suppliedInUnderlying = CompleteVToken(vToken).balanceOfUnderlying(address(this));
    }

    function depositArbCheck() public pure returns (bool) {
        // there's no arb here.
        return true;
    }

    /**
    * The strategy invests by supplying the underlying as a collateral.
    */
    function investAllUnderlying() public restricted updateSupplyInTheEnd {
        uint256 balance = IBEP20(underlying).balanceOf(address(this));
        if (balance > 0) {
            _supply(balance);
        }
    }

    /**
    * Exits Venus and transfers everything to the vault.
    */
    function withdrawAll(address to) external restricted updateSupplyInTheEnd {
        withdrawMaximum();
        if (IBEP20(underlying).balanceOf(address(this)) > 0) {
            IBEP20(underlying).safeTransfer(to, IBEP20(underlying).balanceOf(address(this)));
        }
    }

    function emergencyExit() external onlyGovernance updateSupplyInTheEnd {
        withdrawMaximum();
    }

    function withdrawMaximum() internal updateSupplyInTheEnd {
        if (sell) {
            liquidateVenus();
        } else {
            emit ProfitNotClaimed();
        }
        redeemMaximumNoFold();
    }


    function withdraw(uint256 amountUnderlying, address to) external restricted updateSupplyInTheEnd {
        uint256 redeemedAmount = mustRedeemPartial(amountUnderlying);
        IBEP20(underlying).safeTransfer(to, redeemedAmount);
        uint256 balance = IBEP20(underlying).balanceOf(address(this));
        if (balance > 0) {
            // invest back to Venus
            investAllUnderlying();
        }
    }

    /**
    * Withdraws all assets, liquidates XVS, and invests again in the required ratio.
    */
    function doHardWork() public restricted {
        if (sell) {
            liquidateVenus();
        } else {
            emit ProfitNotClaimed();
        }
        investAllUnderlying();
    }

    /**
    * Redeems `amountUnderlying` or fails.
    */
    function mustRedeemPartial(uint256 amountUnderlyingToRedeem) internal returns (uint256){
        uint256 initialBalance = IBEP20(underlying).balanceOf(address(this));
        require(
            CompleteVToken(vToken).getCash() >= amountUnderlyingToRedeem,
            "market cash cannot cover liquidity"
        );
        _redeemUnderlying(amountUnderlyingToRedeem);
        uint256 finalBalance = IBEP20(underlying).balanceOf(address(this));
        require(
            finalBalance.sub(initialBalance) >= amountUnderlyingToRedeem.mul(allowedFeeNumerator).div(10000),
            "Unable to withdraw the entire amountUnderlyingToRedeem");
        return finalBalance.sub(initialBalance);
    }

    /**
    * Salvages a token.
    */
    function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
        // To make sure that governance cannot come in and take away the coins
        IBEP20(token).safeTransfer(recipient, amount);
    }

    function liquidateVenus() internal {
        // Calculating rewardBalance is needed for the case underlying = reward token
        uint256 balance = IBEP20(rewardToken).balanceOf(address(this));
        claimVenus();
        uint256 balanceAfter = IBEP20(rewardToken).balanceOf(address(this));
        uint256 rewardBalance = balanceAfter.sub(balance);

        if (rewardBalance < sellFloor || rewardBalance == 0) {
            emit TooLowBalance();
            return;
        }
        balance = IBEP20(rewardToken).balanceOf(address(this));

        emit Liquidated(balance);


        // we can accept 1 as minimum as this will be called by trusted roles only
        uint256 amountOutMin = 0;
        IBEP20(rewardToken).safeApprove(address(pancakeswapRouterV2), 0);
        IBEP20(rewardToken).safeApprove(address(pancakeswapRouterV2), balance);

        IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
            balance,
            amountOutMin,
            liquidationPath,
            address(this),
            block.timestamp
        );
    }

    /**
    * Returns the current balance. Ignores XVS that was not liquidated and invested.
    */
    function investedUnderlyingBalance() public view returns (uint256) {
        // underlying in this strategy + underlying redeemable from Venus + loan
        return IBEP20(underlying).balanceOf(address(this))
        .add(suppliedInUnderlying);
    }

    function currentInvestedUnderlyingBalance() public returns (uint256) {
        // underlying in this strategy + underlying redeemable from Venus + loan
        return CompleteVToken(vToken).balanceOfUnderlying(address(this));
    }

    function setSellFloor(uint256 floor) public onlyGovernance {
        sellFloor = floor;
    }

    function setAllowedFeeNumerator(uint256 _numerator) public onlyGovernance {
        allowedFeeNumerator = _numerator;
    }

    function setSell(bool s) public onlyGovernance {
        sell = s;
    }

    function setRestrictedPermissions(address _account) public onlyGovernance {
        restrictedPermissions[_account] = true;
    }

}