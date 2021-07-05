/**
 *Submitted for verification at Etherscan.io on 2021-07-05
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

interface ICurveFi {
    function add_liquidity(
        address _pool,
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        address _receiver
    ) external;
}

interface UniswapRouter {
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);
}

interface WETH {
    function withdraw(uint wad) external;
}

contract StrategyalUSD3CRV {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 poolId = 36;

    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public sushirouter = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	address constant public bt = address(0x76c5449F4950f6338A393F53CdA8b53B0cd3Ca3a);
    address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    address constant public want = address(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);  //alUSD3CRV

    address constant public booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);     //StakingPools
    address constant public baserewardpool = address(0x02E2151D4F351881017ABdF2DD2b51150841d5B3);   //crvRewards

    address constant public ALCX = address(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);        //ALCX
    address constant public CVX = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);        //CVX
    address constant public CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);        //CRV

    address constant public alUSD3CRV = address(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
    address constant public alUSDPool = address(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);

    address public governance;
    address public controller;

    uint256 public redeliverynum = 100 * 1e18;

	address[] public swapALCX2ETHRouting;
	address[] public swapCVX2ETHRouting;
	address[] public swapCRV2ETHRouting;
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
        doApprove();
		swapALCX2ETHRouting = [ALCX,weth];
		swapCVX2ETHRouting = [CVX,weth];
		swapCRV2ETHRouting = [CRV,weth];
		swap2BTRouting = [weth,bt];
        swap2TokenRouting = [weth, usdt];
    }

	function doApprove () internal{
        IERC20(ALCX).approve(sushirouter, uint(-1));
        IERC20(CVX).approve(sushirouter, uint(-1));
        IERC20(CRV).approve(sushirouter, uint(-1));
        IERC20(weth).approve(sushirouter, uint(-1));
        IERC20(weth).approve(unirouter, uint(-1));
    }

    function deposit() public isAuthorized{
		uint256 _wantAmount = IERC20(want).balanceOf(address(this));
		if (_wantAmount > 0) {
            IERC20(want).safeApprove(booster, 0);
            IERC20(want).safeApprove(booster, _wantAmount);

            Booster(booster).depositAll(poolId,true);
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
            amount = _amount.sub(amount);
            uint256 allAmount = BaseRewardPool(baserewardpool).balanceOf(address(this));
            if(amount > allAmount){
                amount = allAmount;
            }
            BaseRewardPool(baserewardpool).withdrawAndUnwrap(amount,false);
			amount = IERC20(want).balanceOf(address(this));
            if (amount < _amount){
                return amount;
            }
        }
		return _amount;
    }

	function withdrawAll() external onlyController returns (uint balance){
		_withdraw(balanceOf());

        balance = IERC20(want).balanceOf(address(this));

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

	function balanceOfStakingPool() public view returns (uint256) {
		return BaseRewardPool(baserewardpool).balanceOf(address(this));
	}

    function balanceOf() public view returns (uint256) {
        return balanceOfwant().add(balanceOfStakingPool());
    }

    function getALCXToken()public view returns(uint256) {
        return IERC20(ALCX).balanceOf(address(this));
    }

    function getPending()public view returns(uint256){
        return BaseRewardPool(baserewardpool).earned(address(this));
    }

    function harvest() public
    {
        BaseRewardPool(baserewardpool).getReward(address(this),true);
        redelivery();
    }

    function redelivery() internal {
        uint256 reward = IERC20(ALCX).balanceOf(address(this));
        if(reward > redeliverynum){
            uint256 _alcxAmount = IERC20(ALCX).balanceOf(address(this));
            if(_alcxAmount > 0){
                UniswapRouter(sushirouter).swapExactTokensForTokens(_alcxAmount,0,swapALCX2ETHRouting,address(this),now.add(1800));
            }
            uint256 _crvAmount = IERC20(CRV).balanceOf(address(this));
            if(_crvAmount > 0){
                UniswapRouter(sushirouter).swapExactTokensForTokens(_crvAmount,0,swapCRV2ETHRouting,address(this),now.add(1800));
            }
            uint256 _cvxAmount = IERC20(CVX).balanceOf(address(this));
            if(_cvxAmount > 0){
                UniswapRouter(sushirouter).swapExactTokensForTokens(_cvxAmount,0,swapCVX2ETHRouting,address(this),now.add(1800));
            }

            uint256 wethAmount = IERC20(weth).balanceOf(address(this));
            uint256 _2token = wethAmount.mul(80).div(100); //80%
		    uint256 _2bt = wethAmount.sub(_2token);  //20%
		    UniswapRouter(sushirouter).swapExactTokensForTokens(_2token, 0, swap2TokenRouting, address(this), now.add(1800));
		    UniswapRouter(unirouter).swapExactTokensForTokens(_2bt, 0, swap2BTRouting, Controller(controller).rewards(), now.add(1800));

            uint _usdtAmount = IERC20(usdt).balanceOf(address(this));
            if (_usdtAmount > 0) {
                IERC20(usdt).safeApprove(alUSD3CRV, 0);
                IERC20(usdt).safeApprove(alUSD3CRV, _usdtAmount);
                ICurveFi(alUSD3CRV).add_liquidity(alUSDPool,[0,0,0, _usdtAmount],0,address(this));
            }

            deposit();
        }
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