/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint);
    function name() external view returns (string memory);
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

interface CurveDeposit{
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function claimable_tokens(address) external view returns (uint256);
}
interface CurveMinter{
    function mint(address) external;
}

interface yERC20 {
  function deposit(uint256 _amount) external;
  function withdraw(uint256 _amount) external;
  function getRatio() external view returns (uint);
}

interface pERC20 {
  function deposit(uint256 ,uint256 ) external;
  function withdraw(uint256 ,uint256 ) external;
  function getRatio() external view returns (uint);
  function pendingPickle(uint256,address) external view returns(uint);
}

interface ZAPPER {
    function ZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _allowanceTarget,
        address _swapTarget,
        bytes calldata swapData
    ) external payable returns (uint256);
}

interface UniswapRouter {
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}
contract StrategyUSDTSLPPickle  {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 pickleindex = 19;

    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	address constant public bt = address(0x76c5449F4950f6338A393F53CdA8b53B0cd3Ca3a);

    address constant public want = address(0x06da0fd433C1A5d7a4faa01111c044910A184553); //ETH_USDT SLP
    address constant public pickleJar = address(0xa7a37aE5Cb163a3147DE83F15e15D8E5f94D6bCE);
	address constant public PICKLE = address(0xbD17B1ce622d73bD438b9E658acA5996dc394b0d);

    address constant public pickletoken = address(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5);

    address constant public zapper = address(0xfF350eDc2242Ca4d7252A64746aec4A5487a852B);
    address constant public swap = address(0xDef1C0ded9bec7F1a1670819833240f027b25EfF);

    address public governance;
    address public controller;

    uint256 public pledgePickles = 0;
    uint256 public redeliverynum = 100 * 1e18;

	address[] public swap2BTRouting;
    address[] public swap2TokenRouting;

    modifier onlyController {
        require(msg.sender == controller, "!controller");
        _;
    }

    constructor() public {
        governance = tx.origin;
        controller = 0xD6FA3746A04B27716bd89F090A0c5Cb3e763faAf;
        doApprove();
		swap2BTRouting = [pickletoken,weth,bt];
        swap2TokenRouting = [pickletoken,weth];
    }

	function doApprove () internal{
        IERC20(pickletoken).approve(unirouter, uint(-1));
    }

    function deposit() public {
		uint256 _want = IERC20(want).balanceOf(address(this));
		if (_want > 0)
		{
		    IERC20(want).safeApprove(pickleJar, 0);
            IERC20(want).safeApprove(pickleJar, _want);
		    yERC20(pickleJar).deposit(_want);
		}

		uint _pslp = IERC20(pickleJar).balanceOf(address(this));
		if (_pslp > 0)
		{
	        IERC20(pickleJar).safeApprove(PICKLE, 0);
            IERC20(pickleJar).safeApprove(PICKLE, _pslp);
	    	pERC20(PICKLE).deposit(pickleindex, _pslp);
    		pledgePickles = pledgePickles.add(_pslp);
		}
    }


    // Withdraw partial funds, normally used with a vault withdrawal
	function withdraw(uint _amount) external onlyController
	{
		uint amount = _withdraw(_amount);
		address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault");
        IERC20(want).safeTransfer(_vault, amount);
	}


    function _withdraw(uint _amount) internal returns(uint) {
		uint amount = IERC20(want).balanceOf(address(this));
		if (amount < _amount) {
			_withdrawSome(_amount.sub(amount));
			amount = IERC20(want).balanceOf(address(this));
            if (amount < _amount){
                return amount;
            }
        }
		return _amount;
    }

	function withdrawAll() external onlyController returns (uint balance){
		balance = _withdraw(balanceOf());

		address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault");
        IERC20(want).safeTransfer(_vault, balance);
	}

    function _withdrawSome(uint256 _amount) internal {
        uint256 _pslp = _amount.mul(1e18).div(yERC20(pickleJar).getRatio());
        uint _before = IERC20(pickleJar).balanceOf(address(this));
        if (_before < _pslp) {
            _pslp = _pslp.sub(_before);
            if (_pslp > pledgePickles)
            {
                _pslp = pledgePickles;
            }
            pERC20(PICKLE).withdraw(pickleindex, _pslp);
            pledgePickles = pledgePickles.sub(_pslp);
            _pslp = IERC20(pickleJar).balanceOf(address(this));
        }
        yERC20(pickleJar).withdraw(_pslp);
    }

	function balanceOfwant() public view returns (uint256) {
		return IERC20(want).balanceOf(address(this));
	}

	function balanceOfpSLP() public view returns (uint256) {
		return pledgePickles.add(IERC20(pickleJar).balanceOf(address(this)));
	}

    //pSLP => SLP
	function balanceOfSLP() public view returns (uint256){
		return balanceOfpSLP().mul(yERC20(pickleJar).getRatio()).div(1e18);
	}


    function balanceOf() public view returns (uint256) {
        return balanceOfwant().add(balanceOfSLP());
    }

    function getPending() public view returns (uint256) {
        return pERC20(PICKLE).pendingPickle(pickleindex,address(this));
    }

	function getPickle() public view returns(uint256)
	{
		return IERC20(pickletoken).balanceOf(address(this));
	}

    function harvest() public
    {
        pERC20(PICKLE).withdraw(pickleindex,pledgePickles);
        pledgePickles = 0;
        redelivery();
    }

    function redelivery() internal {
        uint256 reward = IERC20(pickletoken).balanceOf(address(this));
        if (reward > redeliverynum)
        {
            uint256 _2weth = reward.mul(80).div(100); //80%
		    uint256 _2bt = reward.sub(_2weth);  //20%
		    UniswapRouter(unirouter).swapExactTokensForTokens(_2weth, 0, swap2TokenRouting, address(this), now.add(1800));
		    UniswapRouter(unirouter).swapExactTokensForTokens(_2bt, 0, swap2BTRouting, Controller(controller).rewards(), now.add(1800));

            uint256 _weth = IERC20(weth).balanceOf(address(this));
            address pair = want;
            if (_weth > 0) {
                IERC20(weth).safeApprove(zapper,0);
                IERC20(weth).safeApprove(zapper, _weth);
                ZAPPER(zapper).ZapIn(
                    weth,
                    pair,
                    _weth,
                    0,
                    swap,
                    swap,
                    new bytes(0));
            }
		}
        deposit();
    }

    function setredeliverynum(uint256 value) public {
        require(msg.sender == governance, "!governance");
        redeliverynum = value;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
}