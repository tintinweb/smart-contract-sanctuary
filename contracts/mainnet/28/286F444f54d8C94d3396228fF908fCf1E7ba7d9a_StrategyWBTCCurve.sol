/**
 *Submitted for verification at Etherscan.io on 2021-03-03
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
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external ;
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
    function calc_token_amount(uint256[4] calldata amounts,bool is_deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount,int128 index)external view returns (uint256);
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

contract StrategyWBTCCurve {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	address constant public bt = address(0x76c5449F4950f6338A393F53CdA8b53B0cd3Ca3a);

    address constant public want = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);  //WBTC

    address constant public cruvefi = address(0xC45b2EEe6e09cA176Ca3bB5f7eEe7C47bF93c756);
    address constant public bBtc = address(0x410e3E86ef427e30B9235497143881f717d93c2A);

    address constant public bBtcGauge = address(0xdFc7AdFa664b08767b735dE28f9E84cd30492aeE);

    address constant public CRVMinter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address constant public CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    address public governance;
    address public controller;
    uint256 public redeliverynum = 100 * 1e18;

    address[] public swap2TokenRouting;
    address[] public swap2BTRouting;

    modifier onlyController {
        require(msg.sender == controller, "!controller");
        _;
    }

    constructor() public {
        governance = tx.origin;
        controller = 0x5C6d3Cb5612b551452B3E9b48c920559634510D4;
		swap2BTRouting = [CRV,weth,bt];
        swap2TokenRouting = [CRV,weth,want];

        IERC20(CRV).approve(unirouter, uint(-1));
        IERC20(bBtc).approve(cruvefi,uint(-1));
    }


    function deposit() public {
		uint _wbtc = IERC20(want).balanceOf(address(this));

        require(_wbtc > 0,"WBTC is 0");
        IERC20(want).safeApprove(cruvefi, 0);
        IERC20(want).safeApprove(cruvefi, _wbtc);
        ICurveFi(cruvefi).add_liquidity([0, 0, _wbtc,0],0);

        uint256 _bBtc = IERC20(bBtc).balanceOf(address(this));
        require(_wbtc > 0,"bBtc is 0");
        IERC20(bBtc).safeApprove(bBtcGauge, 0);
        IERC20(bBtc).safeApprove(bBtcGauge, _bBtc);
        Gauge(bBtcGauge).deposit(_bBtc);
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
        uint256 _bBtc =  ICurveFi(cruvefi).calc_token_amount([0,0,_amount,0],false);
        uint256 _bBtcBefore = IERC20(bBtc).balanceOf(address(this));
        if(_bBtc > _bBtcBefore){
            uint256 _bBtcGauge = _bBtc.sub(_bBtcBefore);
            if(_bBtcGauge >IERC20(bBtcGauge).balanceOf(address(this))){
                _bBtcGauge = IERC20(bBtcGauge).balanceOf(address(this));
            }
            Gauge(bBtcGauge).withdraw(_bBtcGauge);
            _bBtc = IERC20(bBtc).balanceOf(address(this));
        }
        ICurveFi(cruvefi).remove_liquidity_one_coin(_bBtc,2,0);
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

	function balanceOfbBtc() public view returns (uint256) {
        return IERC20(bBtcGauge).balanceOf(address(this)).add(IERC20(bBtc).balanceOf(address(this)));
	}

    function balanceOfbBtc2WBTC() public view returns(uint256) {
        uint256 _bBtc = balanceOfbBtc();
        if (_bBtc == 0)
        {
            return 0;
        }
        return ICurveFi(cruvefi).calc_withdraw_one_coin(_bBtc,2);
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfwant().add(balanceOfbBtc2WBTC());
    }

    function getPending() public view returns (uint256) {
        return Gauge(bBtcGauge).integrate_fraction(address(this)).sub(Mintr(CRVMinter).minted(address(this), bBtcGauge));
    }

	function getCRV() public view returns(uint256)
	{
		return IERC20(CRV).balanceOf(address(this));
	}

    function harvest() public
    {
        Mintr(CRVMinter).mint(bBtcGauge);
        redelivery();
    }

    function redelivery() internal {
        uint256 reward = IERC20(CRV).balanceOf(address(this));
        if (reward > redeliverynum)
        {
            uint256 _2wbtc = reward.mul(80).div(100); //80%
		    uint256 _2bt = reward.sub(_2wbtc);  //20%
		    UniswapRouter(unirouter).swapExactTokensForTokens(_2wbtc, 0, swap2TokenRouting, address(this), now.add(1800));
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
}