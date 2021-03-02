/**
 *Submitted for verification at Etherscan.io on 2021-03-02
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

interface WETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
}

interface ICurveFi {
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
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

contract StrategyETHCurve {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	address constant public bt = address(0x76c5449F4950f6338A393F53CdA8b53B0cd3Ca3a);

    address constant public want = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);  //weth

    address constant public eCRVPool = address(0xc5424B857f758E906013F3555Dad202e4bdB4567);
    address constant public eCRVToken = address(0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c);

    address constant public eCRVGauge = address(0x3C0FFFF15EA30C35d7A85B85c0782D6c94e1d238);

    address constant public CRVMinter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address constant public CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    address public governance;
    address public controller;
    uint256 public redeliverynum = 100 * 1e18;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public slip = 60;
	uint256 public depositLastPrice;
	bool public withdrawSlipCheck = true;

    address[] public swap2TokenRouting;
    address[] public swap2BTRouting;

    modifier onlyController {
        require(msg.sender == controller, "!controller");
        _;
    }

    modifier isAuthorized() {
        require(msg.sender == governance || msg.sender == controller || msg.sender == address(this), "!authorized");
        _;
    }

    constructor() public {
        governance = tx.origin;
        controller = 0x5C6d3Cb5612b551452B3E9b48c920559634510D4;
		swap2BTRouting = [CRV,weth,bt];
        swap2TokenRouting = [CRV,weth];

        IERC20(CRV).approve(unirouter, uint(-1));
    }

    function () external payable {
    }

    function deposit() public isAuthorized{
		uint _want = IERC20(want).balanceOf(address(this));
        require(_want > 0,"WETH is 0");
        WETH(address(weth)).withdraw(_want); //weth->eth
        uint256[2] memory amounts = [_want,0];
        uint256 v = _want.mul(1e18).div(ICurveFi(eCRVPool).get_virtual_price());
        uint256 beforeCRV = IERC20(eCRVToken).balanceOf(address(this));
        ICurveFi(eCRVPool).add_liquidity.value(_want)(amounts,v.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
        uint256 _eCRV = IERC20(eCRVToken).balanceOf(address(this));
        depositLastPrice = _want.mul(1e18).div(_eCRV.sub(beforeCRV));

        if(_eCRV>0){
            IERC20(eCRVToken).safeApprove(eCRVGauge, 0);
            IERC20(eCRVToken).safeApprove(eCRVGauge, _eCRV);
            Gauge(eCRVGauge).deposit(_eCRV);
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
            uint256 _eCRV = _withdrawSome(_amount.sub(amount));
			uint256 afterAmount = IERC20(want).balanceOf(address(this));
			if(withdrawSlipCheck){
				uint256 withdrawPrice = afterAmount.sub(amount).mul(1e18).div(_eCRV);
				if(withdrawPrice < depositLastPrice){
					require(depositLastPrice.sub(withdrawPrice).mul(DENOMINATOR) < slip.mul(depositLastPrice),"slippage");
				}
			}
			amount = afterAmount;
		}
        if (amount < _amount){
            return amount;
        }
		return _amount;
    }

    function _withdrawSome(uint _amount) internal returns(uint256 _eCRV)
    {
        _eCRV = _amount.mul(1e18).div(ICurveFi(eCRVPool).get_virtual_price());
        uint256 _eCRVBefore = IERC20(eCRVToken).balanceOf(address(this));
        if(_eCRV>_eCRVBefore){
            uint256 _eCRVGauge = _eCRV.sub(_eCRVBefore);
            if(_eCRVGauge>IERC20(eCRVGauge).balanceOf(address(this))){
                _eCRVGauge = IERC20(eCRVGauge).balanceOf(address(this));
            }
            Gauge(eCRVGauge).withdraw(_eCRVGauge);
            _eCRV = IERC20(eCRVToken).balanceOf(address(this));
        }
        ICurveFi(eCRVPool).remove_liquidity_one_coin(_eCRV,0,_amount.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
        WETH(weth).deposit.value(address(this).balance)();
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
        return IERC20(eCRVGauge).balanceOf(address(this)).add(IERC20(eCRVToken).balanceOf(address(this)));
	}

    function balanceOfeCRV2ETH() public view returns(uint256) {
        return balanceOfeCRV().mul(ICurveFi(eCRVPool).get_virtual_price()).div(1e18);
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfwant().add(balanceOfeCRV2ETH());
    }

    function getPending() public view returns (uint256) {
        return Gauge(eCRVGauge).integrate_fraction(address(this)).sub(Mintr(CRVMinter).minted(address(this),eCRVGauge));
    }

	function getCRV() public view returns(uint256)
	{
		return IERC20(CRV).balanceOf(address(this));
	}

    function harvest() public
    {
        Mintr(CRVMinter).mint(eCRVGauge);
        redelivery();
    }

    function redelivery() internal {
        uint256 reward = IERC20(CRV).balanceOf(address(this));
        if (reward > redeliverynum)
        {
            uint256 _2weth = reward.mul(80).div(100); //80%
		    uint256 _2bt = reward.sub(_2weth);  //20%
		    UniswapRouter(unirouter).swapExactTokensForTokens(_2weth, 0, swap2TokenRouting, address(this), now.add(1800));
		    UniswapRouter(unirouter).swapExactTokensForTokens(_2bt, 0, swap2BTRouting, Controller(controller).rewards(), now.add(1800));
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

    function setSlip(uint256 _slip) external {
        require(msg.sender == governance, "!governance");
        require(_slip <= DENOMINATOR,"slip error");
        slip = _slip;
    }
	function setWithdrawSlipCheck(bool _check) external {
        require(msg.sender == governance, "!governance");
        withdrawSlipCheck = _check;
    }
}