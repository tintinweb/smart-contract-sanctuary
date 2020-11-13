pragma solidity ^0.5.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

interface Controller {
    function vaults(address) external view returns (address);
}

interface Vault {
    function deposit(uint) external;
    function withdraw(uint) external;
    function getPricePerFullShare() external view returns (uint);
}

interface Aave {
    function borrow(address _reserve, uint _amount, uint _interestRateModel, uint16 _referralCode) external;
    function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external;
    function repay(address _reserve, uint _amount, address payable _onBehalfOf) external payable;
    function getUserAccountData(address _user)
        external
        view
        returns (
            uint totalLiquidityETH,
            uint totalCollateralETH,
            uint totalBorrowsETH,
            uint totalFeesETH,
            uint availableBorrowsETH,
            uint currentLiquidationThreshold,
            uint ltv,
            uint healthFactor
        );
    function getUserReserveData(address _reserve, address _user)
        external
        view
        returns (
            uint currentATokenBalance,
            uint currentBorrowBalance,
            uint principalBorrowBalance,
            uint borrowRateMode,
            uint borrowRate,
            uint liquidityRate,
            uint originationFee,
            uint variableBorrowIndex,
            uint lastUpdateTimestamp,
            bool usageAsCollateralEnabled
        );
}

interface LendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
    function getPriceOracle() external view returns (address);
}

/*

 A strategy must implement the following calls;
 
 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()
 
 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
 
*/

contract StrategyVaultUSDT {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address constant public want = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address constant public vault = address(0x2927071efbC6BdC21B87c27F2923689Cec562FD7);
    
    address public constant aave = address(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public governance;
    address public controller;
    
    constructor(address _controller) public {
        governance = msg.sender;
        controller = _controller;
    }
    
    function deposit() external {
        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance > 0) {
            IERC20(want).safeApprove(address(vault), 0);
            IERC20(want).safeApprove(address(vault), _balance);
            Vault(vault).deposit(_balance);
        }
    }
    
    function getAave() public view returns (address) {
        return LendingPoolAddressesProvider(aave).getLendingPool();
    }
    
    function getName() external pure returns (string memory) {
        return "StrategyVaultUSDT";
    }
    
    function debt() external view returns (uint) {
        (,uint currentBorrowBalance,,,,,,,,) = Aave(getAave()).getUserReserveData(want, Controller(controller).vaults(address(this)));
        return currentBorrowBalance;
    }
    
    function have() public view returns (uint) {
        uint _have = balanceOf();
        return _have;
    }
    
    function skimmable() public view returns (uint) {
        (,uint currentBorrowBalance,,,,,,,,) = Aave(getAave()).getUserReserveData(want, Controller(controller).vaults(address(this)));
        uint _have = have();
        if (_have > currentBorrowBalance) {
            return _have.sub(currentBorrowBalance);
        } else {
            return 0;
        }
    }
    
    function skim() external {
        uint _balance = IERC20(want).balanceOf(address(this));
        uint _amount = skimmable();
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        } 
        IERC20(want).safeTransfer(controller, _amount);
    }
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(address(_asset) != address(want), "!want");
        require(address(_asset) != address(vault), "!vault");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }
    
    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");
        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        address _vault = Controller(controller).vaults(address(this));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount);
    }
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();
        balance = IERC20(want).balanceOf(address(this));
        address _vault = Controller(controller).vaults(address(this));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }
    
    function _withdrawAll() internal {
        Vault(vault).withdraw(IERC20(vault).balanceOf(address(this)));
    }
    
    function _withdrawSome(uint256 _amount) internal returns (uint) {
        uint _redeem = IERC20(vault).balanceOf(address(this)).mul(_amount).div(balanceSavingsInToken());
        uint _before = IERC20(want).balanceOf(address(this));
        Vault(vault).withdraw(_redeem);
        uint _after = IERC20(want).balanceOf(address(this));
        return _after.sub(_before);
    }
    
    function balanceOf() public view returns (uint) {
        return IERC20(want).balanceOf(address(this))
                .add(balanceSavingsInToken());
    }
    
    function balanceSavingsInToken() public view returns (uint256) {
        return IERC20(vault).balanceOf(address(this)).mul(Vault(vault).getPricePerFullShare()).div(1e18);
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
}