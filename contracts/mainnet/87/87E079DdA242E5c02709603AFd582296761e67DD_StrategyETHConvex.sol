/**
 *Submitted for verification at Etherscan.io on 2021-06-29
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

interface Booster {
    function depositAll(uint256 _pid, bool _stake) external returns(bool);
    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);
}

interface BaseRewardPool {
    function getReward(address _account, bool _claimExtras) external returns(bool);
    function earned(address account) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
}

contract StrategyETHConvex {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public pid = 23;

    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public sushirouter = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	address constant public bt = address(0x76c5449F4950f6338A393F53CdA8b53B0cd3Ca3a);

    address constant public want = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);  //weth

    address constant public eCRVPool = address(0xc5424B857f758E906013F3555Dad202e4bdB4567);
    address constant public eCRVToken = address(0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c);

    address constant public booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    address constant public baserewardpool = address(0x192469CadE297D6B21F418cFA8c366b63FFC9f9b);

    address constant public CVX = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address constant public CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    address public governance;
    address public controller;
    uint256 public redeliverynum = 100 * 1e18;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public slip = 60;
	uint256 public depositLastPrice;
	bool public withdrawSlipCheck = true;

	address[] public swapCVX2ETHRouting;
	address[] public swapCRV2ETHRouting;
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

        swapCVX2ETHRouting = [CVX,weth];
		swapCRV2ETHRouting = [CRV,weth];
		swap2BTRouting = [weth,bt];

        IERC20(CRV).approve(sushirouter, uint(-1));
        IERC20(CVX).approve(sushirouter, uint(-1));
        IERC20(weth).approve(sushirouter, uint(-1));
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
            IERC20(eCRVToken).safeApprove(booster, 0);
            IERC20(eCRVToken).safeApprove(booster, _eCRV);

            Booster(booster).depositAll(pid,true);
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
            _eCRV = _eCRV.sub(_eCRVBefore);
            uint256 alleCRV = BaseRewardPool(baserewardpool).balanceOf(address(this));
            if(_eCRV>alleCRV){
                _eCRV = alleCRV;
            }
            BaseRewardPool(baserewardpool).withdrawAndUnwrap(_eCRV,false);
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

    // Governance only function for creating additional rewards from dust
    function withdrawAsset(address _asset,address _to) external returns(uint256 balance){
        require(msg.sender == governance, "!governance");
        require(_to != address(0x0) && _asset != address(0x0) ,"Invalid address");
        require(want != _asset , "want");
        balance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransfer(_to, balance);
    }


	function balanceOfwant() public view returns (uint256) {
		return IERC20(want).balanceOf(address(this));
	}

	function balanceOfeCRV() public view returns (uint256) {
        return BaseRewardPool(baserewardpool).balanceOf(address(this)).add(IERC20(eCRVToken).balanceOf(address(this)));
	}

    function balanceOfeCRV2ETH() public view returns(uint256) {
        return balanceOfeCRV().mul(ICurveFi(eCRVPool).get_virtual_price()).div(1e18);
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfwant().add(balanceOfeCRV2ETH());
    }

    function getPending() public view returns (uint256) {
        return BaseRewardPool(baserewardpool).earned(address(this));
    }

	function getCRV() public view returns(uint256)
	{
		return IERC20(CRV).balanceOf(address(this));
	}

    function harvest() public
    {
        BaseRewardPool(baserewardpool).getReward(address(this),true);
        redelivery();
    }

    function redelivery() internal {
        uint256 reward = IERC20(CRV).balanceOf(address(this));
        if (reward > redeliverynum)
        {
            uint256 _crvAmount = IERC20(CRV).balanceOf(address(this));
            if(_crvAmount > 0){
                UniswapRouter(sushirouter).swapExactTokensForTokens(_crvAmount,0,swapCRV2ETHRouting,address(this),now.add(1800));
            }
            uint256 _cvxAmount = IERC20(CVX).balanceOf(address(this));
            if(_cvxAmount > 0){
                UniswapRouter(sushirouter).swapExactTokensForTokens(_cvxAmount,0,swapCVX2ETHRouting,address(this),now.add(1800));
            }

            uint256 wethAmount = IERC20(weth).balanceOf(address(this));
		    uint256 _2bt = wethAmount.mul(20).div(100); //20%
		    UniswapRouter(unirouter).swapExactTokensForTokens(_2bt, 0, swap2BTRouting, Controller(controller).rewards(), now.add(1800));

            deposit();
		}
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