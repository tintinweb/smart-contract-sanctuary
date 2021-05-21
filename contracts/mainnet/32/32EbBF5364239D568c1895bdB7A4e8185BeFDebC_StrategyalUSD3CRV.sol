/**
 *Submitted for verification at Etherscan.io on 2021-05-21
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

interface StakingPools {
    function deposit(uint256 _poolId, uint256 _depositAmount) external;
    function withdraw(uint256 _poolId, uint256 _withdrawAmount) external;
    function getStakeTotalDeposited(address _account, uint256 _poolId) external view returns(uint256);
    function getStakeTotalUnclaimed(address _account, uint256 _poolId) external view returns(uint256);
    function claim(uint256 _poolId) external;
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

    uint256 poolId = 4;

    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	address constant public bt = address(0x76c5449F4950f6338A393F53CdA8b53B0cd3Ca3a);
    address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    address constant public want = address(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);  //alUSD3CRV

    address constant public stakingPools = address(0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa);     //StakingPools

    address constant public ALCX = address(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);        //ALCX

    address constant public alUSD3CRV = address(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
    address constant public alUSDPool = address(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);

    address public governance;
    address public controller;

    uint256 public redeliverynum = 100 * 1e18;

	address[] public swap2BTRouting;
    address[] public swap2TokenRouting;

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
		swap2BTRouting = [ALCX,weth,bt];
        swap2TokenRouting = [ALCX,weth, usdt];
    }

	function doApprove () internal{
        IERC20(ALCX).approve(unirouter, uint(-1));
    }

    function deposit() public isAuthorized{
		uint256 _wantAmount = IERC20(want).balanceOf(address(this));
		if (_wantAmount > 0) {
            IERC20(want).safeApprove(stakingPools, 0);
            IERC20(want).safeApprove(stakingPools, _wantAmount);

            StakingPools(stakingPools).deposit(poolId,_wantAmount);
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
            uint256 allAmount = StakingPools(stakingPools).getStakeTotalDeposited(address(this),poolId);
            if(amount > allAmount){
                amount = allAmount;
            }
            StakingPools(stakingPools).withdraw(poolId,amount);
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
		return StakingPools(stakingPools).getStakeTotalDeposited(address(this),poolId);
	}

    function balanceOf() public view returns (uint256) {
        return balanceOfwant().add(balanceOfStakingPool());
    }

    function getALCXToken()public view returns(uint256) {
        return IERC20(ALCX).balanceOf(address(this));
    }

    function getPending()public view returns(uint256){
        return StakingPools(stakingPools).getStakeTotalUnclaimed(address(this),poolId);
    }

    function harvest() public
    {
        StakingPools(stakingPools).claim(poolId);
        redelivery();
    }

    function redelivery() internal {
        uint256 reward = IERC20(ALCX).balanceOf(address(this));
        if(reward > redeliverynum){
            uint256 _2token = reward.mul(80).div(100); //80%
		    uint256 _2bt = reward.sub(_2token);  //20%
		    UniswapRouter(unirouter).swapExactTokensForTokens(_2token, 0, swap2TokenRouting, address(this), now.add(1800));
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