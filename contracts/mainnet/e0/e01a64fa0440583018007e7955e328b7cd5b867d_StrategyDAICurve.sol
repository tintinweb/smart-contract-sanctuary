// SPDX-License-Identifier: MIT

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
    function rewards() external view returns (address);
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

interface yERC20 {
  function deposit(uint) external;
  function withdraw(uint) external;
  function getPricePerFullShare() external view returns (uint);
}

interface ICurveFi {

  function get_virtual_price() external view returns (uint);
  function add_liquidity(
    uint256[4] calldata amounts,
    uint256 min_mint_amount
  ) external;
  function remove_liquidity_imbalance(
    uint256[4] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    uint256 _amount,
    uint256[4] calldata amounts
  ) external;
  function exchange(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external;
}

contract StrategyDAICurve {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address constant public want = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address constant public y = address(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);
    address constant public ycrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    address constant public yycrv = address(0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c);
    address constant public curve = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    
    address constant public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address constant public ydai = address(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);

    address constant public usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address constant public yusdc = address(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e);

    address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address constant public yusdt = address(0x83f798e925BcD4017Eb265844FDDAbb448f1707D);

    address constant public tusd = address(0x0000000000085d4780B73119b644AE5ecd22b376);
    address constant public ytusd = address(0x73a052500105205d34Daf004eAb301916DA8190f);

    
    address public governance;
    address public controller;
    
    constructor(address _controller) public {
        governance = msg.sender;
        controller = _controller;
    }
    
    function getName() external pure returns (string memory) {
        return "StrategyDAICurve";
    }
    
    function deposit() public {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(y, 0);
            IERC20(want).safeApprove(y, _want);
            yERC20(y).deposit(_want);
        }
        uint _y = IERC20(y).balanceOf(address(this));
        if (_y > 0) {
            IERC20(y).safeApprove(curve, 0);
            IERC20(y).safeApprove(curve, _y);
            ICurveFi(curve).add_liquidity([_y,0,0,0],0);
        }
        uint _ycrv = IERC20(ycrv).balanceOf(address(this));
        if (_ycrv > 0) {
            IERC20(ycrv).safeApprove(yycrv, 0);
            IERC20(ycrv).safeApprove(yycrv, _ycrv);
            yERC20(yycrv).deposit(_ycrv);
        }
    }
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(y != address(_asset), "y");
        require(ycrv != address(_asset), "ycrv");
        require(yycrv != address(_asset), "yycrv");
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
        
        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount);
        
    }
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();
        
        
        balance = IERC20(want).balanceOf(address(this));
        
        /*
        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
        */
        IERC20(want).safeTransfer(controller, balance);
    }
    
    function withdrawUnderlying(uint256 _amount) internal returns (uint) {
        IERC20(ycrv).safeApprove(curve, 0);
        IERC20(ycrv).safeApprove(curve, _amount);
        ICurveFi(curve).remove_liquidity(_amount, [uint256(0),0,0,0]);
    
        uint256 _yusdc = IERC20(yusdc).balanceOf(address(this));
        uint256 _yusdt = IERC20(yusdt).balanceOf(address(this));
        uint256 _ytusd = IERC20(ytusd).balanceOf(address(this));
        
        if (_yusdc > 0) {
            IERC20(yusdc).safeApprove(curve, 0);
            IERC20(yusdc).safeApprove(curve, _yusdc);
            ICurveFi(curve).exchange(1, 0, _yusdc, 0);
        }
        if (_yusdt > 0) {
            IERC20(yusdt).safeApprove(curve, 0);
            IERC20(yusdt).safeApprove(curve, _yusdt);
            ICurveFi(curve).exchange(2, 0, _yusdt, 0);
        }
        if (_ytusd > 0) {
            IERC20(ytusd).safeApprove(curve, 0);
            IERC20(ytusd).safeApprove(curve, _ytusd);
            ICurveFi(curve).exchange(3, 0, _ytusd, 0);
        }
        
        uint _before = IERC20(want).balanceOf(address(this));
        yERC20(ydai).withdraw(IERC20(ydai).balanceOf(address(this)));
        uint _after = IERC20(want).balanceOf(address(this));
        
        return _after.sub(_before);
    }
    
    function _withdrawAll() internal {
        uint _yycrv = IERC20(yycrv).balanceOf(address(this));
        if (_yycrv > 0) {
            yERC20(yycrv).withdraw(_yycrv);
            withdrawUnderlying(IERC20(ycrv).balanceOf(address(this)));
        }
    }
    
    function _withdrawSome(uint256 _amount) internal returns (uint) {
        // calculate amount of ycrv to withdraw for amount of _want_
        uint _ycrv = _amount.mul(1e18).div(ICurveFi(curve).get_virtual_price());
        // calculate amount of yycrv to withdraw for amount of _ycrv_
        uint _yycrv = _ycrv.mul(1e18).div(yERC20(yycrv).getPricePerFullShare());
        uint _before = IERC20(ycrv).balanceOf(address(this));
        yERC20(yycrv).withdraw(_yycrv);
        uint _after = IERC20(ycrv).balanceOf(address(this));
        return withdrawUnderlying(_after.sub(_before));
    }
    
    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }
    
    function balanceOfYYCRV() public view returns (uint) {
        return IERC20(yycrv).balanceOf(address(this));
    }
    
    function balanceOfYYCRVinYCRV() public view returns (uint) {
        return balanceOfYYCRV().mul(yERC20(yycrv).getPricePerFullShare()).div(1e18);
    }
    
    function balanceOfYYCRVinyTUSD() public view returns (uint) {
        return balanceOfYYCRVinYCRV().mul(ICurveFi(curve).get_virtual_price()).div(1e18);
    }
    
    function balanceOfYCRV() public view returns (uint) {
        return IERC20(ycrv).balanceOf(address(this));
    }
    
    function balanceOfYCRVyTUSD() public view returns (uint) {
        return balanceOfYCRV().mul(ICurveFi(curve).get_virtual_price()).div(1e18);
    }
    
    function balanceOf() public view returns (uint) {
        return balanceOfWant()
               .add(balanceOfYYCRVinyTUSD());
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