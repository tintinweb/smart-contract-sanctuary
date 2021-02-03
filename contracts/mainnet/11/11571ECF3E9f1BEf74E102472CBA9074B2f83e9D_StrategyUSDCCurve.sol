/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

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


interface UniswapRouter {
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}

interface ICurveFi {
    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external payable;
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        bool use_underlying
    ) external;
    function get_virtual_price() external view returns (uint256);
}

interface Gauge {
    function deposit(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
    function integrate_fraction(address) external view returns(uint256);
}

interface Mintr {
    function mint(address) external;
    function minted(address,address) external view returns(uint256);
}

contract StrategyUSDCCurve {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public dmsrouter = address(0x446D34aBF8Ac435f9191A7C1b14FfB88BB77F3ec);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	address constant public dms = address(0x34D3d2b46881588387Dbe17e3B478DcB8b1A2450);

    address constant public want = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);  //USDC

    address constant public a3CRVPool = address(0xDeBF20617708857ebe4F679508E7b7863a8A8EeE);
    address constant public a3CRVToken = address(0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900);

    address constant public a3CRVGauge = address(0xd662908ADA2Ea1916B3318327A97eB18aD588b5d);

    address constant public CRVMinter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address constant public CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    address public governance;
    address public controller;
    uint256 public redeliverynum = 100 * 1e18;

    address[] public swap2TokenRouting;
    address[] public swap2WETHRouting;
    address[] public swap2DMSRouting;

    modifier onlyController {
        require(msg.sender == controller, "!controller");
        _;
    }

    constructor() public {
        governance = tx.origin;
        controller = 0xEE79a912B31e85a3245fb1A431D68b577993B7dC;
        swap2WETHRouting = [CRV,weth];
		swap2DMSRouting = [weth, dms];
        swap2TokenRouting = [CRV,weth,want];

        IERC20(CRV).approve(unirouter, uint(-1));
        IERC20(weth).approve(dmsrouter, uint(-1));
    }


    function deposit() public {
		uint _usdc = IERC20(want).balanceOf(address(this));
        if (_usdc > 0) {
            IERC20(want).safeApprove(a3CRVPool, 0);
            IERC20(want).safeApprove(a3CRVPool, _usdc);
            ICurveFi(a3CRVPool).add_liquidity([0,_usdc,0],0,true);
        }

        uint256 _a3CRV = IERC20(a3CRVToken).balanceOf(address(this));
        if(_a3CRV >0){
            IERC20(a3CRVToken).safeApprove(a3CRVGauge, 0);
            IERC20(a3CRVToken).safeApprove(a3CRVGauge, _a3CRV);
            Gauge(a3CRVGauge).deposit(_a3CRV);
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
		}
        if (amount < _amount){
            return amount;
        }
		return _amount;
    }

    function _withdrawSome(uint _amount) internal
    {
        uint256 _a3CRV = _amount.mul(1e18).mul(1e12).div(ICurveFi(a3CRVPool).get_virtual_price());
        uint256 _a3CRVBefore = IERC20(a3CRVToken).balanceOf(address(this));
        if(_a3CRV > _a3CRVBefore){
            uint256 _eCRVGauge = _a3CRV.sub(_a3CRVBefore);
            if(_eCRVGauge>IERC20(a3CRVGauge).balanceOf(address(this))){
                _eCRVGauge = IERC20(a3CRVGauge).balanceOf(address(this));
            }
            Gauge(a3CRVGauge).withdraw(_eCRVGauge);
            _a3CRV = IERC20(a3CRVToken).balanceOf(address(this));
        }
        ICurveFi(a3CRVPool).remove_liquidity_one_coin(_a3CRV,1,0,true);
    }

	function withdrawAll() external onlyController returns (uint balance) {
		balance = _withdraw(balanceOf());

		address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault");
        IERC20(want).safeTransfer(_vault, balance);
	}


	function balanceOfwant() public view returns (uint256) {
		return IERC20(want).balanceOf(address(this));
	}

	function balanceOfeCRV() public view returns (uint256) {
        return IERC20(a3CRVGauge).balanceOf(address(this)).add(IERC20(a3CRVToken).balanceOf(address(this)));
	}

    function balanceOfeCRV2ETH() public view returns(uint256) {
        return balanceOfeCRV().mul(ICurveFi(a3CRVPool).get_virtual_price()).div(1e18).div(1e12);
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfwant().add(balanceOfeCRV2ETH());
    }

    function getPending() public view returns (uint256) {
        return Gauge(a3CRVGauge).integrate_fraction(address(this)).sub(Mintr(CRVMinter).minted(address(this), a3CRVGauge));
    }

	function getCRV() public view returns(uint256)
	{
		return IERC20(CRV).balanceOf(address(this));
	}

    function harvest() public
    {
        Mintr(CRVMinter).mint(a3CRVGauge);
        redelivery();
    }

    function redelivery() internal {
        uint256 reward = IERC20(CRV).balanceOf(address(this));
        if (reward > redeliverynum)
        {
            uint256 _2want = reward.mul(80).div(100); //80%
		    UniswapRouter(unirouter).swapExactTokensForTokens(_2want, 0, swap2TokenRouting, address(this), now.add(1800));
		    uint256 _2weth = reward.sub(_2want);  //20%
            UniswapRouter(unirouter).swapExactTokensForTokens(_2weth, 0, swap2WETHRouting, address(this), now.add(1800));
            uint256 _weth = IERC20(weth).balanceOf(address(this));
		    UniswapRouter(dmsrouter).swapExactTokensForTokens(_weth, 0, swap2DMSRouting, Controller(controller).rewards(), now.add(1800));
		}
        deposit();
    }


    function setredeliverynum(uint256 value) public
    {
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