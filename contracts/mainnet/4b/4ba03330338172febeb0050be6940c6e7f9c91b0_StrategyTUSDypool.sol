/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

// SPDX-License-Identifier: AGPL-3.0

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
    function strategies(address) external view returns (address);
    function rewards() external view returns (address);
    function approvedStrategies(address, address) external view returns (bool);
    // v no need
    function approveStrategy(address, address) external;
    function setStrategy(address, address) external;
    function withdrawAll(address) external;
}

interface yvERC20 {
    function deposit(uint) external;
    function withdraw(uint) external;
    function getPricePerFullShare() external view returns (uint);
}

interface ICurveFi {
    function get_virtual_price() external view returns (uint);
    function balances(int128) external view returns (uint);
    function add_liquidity(
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;
    function remove_liquidity(
        uint256 _amount,
        uint256[4] calldata min_amounts
    ) external;
    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount
    ) external;
    function exchange(
        int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
    ) external;
    function get_dy(
        int128 from, int128 to, uint256 _from_amount
    ) external view returns (uint);
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


contract StrategyTUSDypool {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address constant public want = address(0x0000000000085d4780B73119b644AE5ecd22b376);
    address constant public ypool = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    address constant public ycrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    address constant public yycrv = address(0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c);

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
    address public strategist;
    address public keeper;

    uint constant public DENOMINATOR = 10000;
    uint public treasuryFee = 1000;
    uint public withdrawalFee = 50;
    uint public strategistReward = 1000;
    uint public threshold = 8000;
    uint public slip = 10;
    uint public tank = 0;
    uint public p = 0;
    uint public maxAmount = 1e24;

    modifier isAuthorized() {
        require(msg.sender == strategist || 
                msg.sender == governance || 
                msg.sender == controller ||
                msg.sender == address(this), "!authorized");
        _;
    }

    constructor(address _controller) public {
        governance = msg.sender;
        strategist = msg.sender;
        keeper = msg.sender;
        controller = _controller;
        approveAll();
    }

    function approveAll() public isAuthorized {
        IERC20(want).approve(ytusd, uint(-1));
        IERC20(ytusd).approve(ypool, uint(-1));
        IERC20(ycrv).approve(yycrv, uint(-1));
        IERC20(ycrv).approve(ypool, uint(-1));
        IERC20(ydai).approve(ypool, uint(-1));
        IERC20(yusdc).approve(ypool, uint(-1));
        IERC20(yusdt).approve(ypool, uint(-1));
    }
    
    function getName() external pure returns (string memory) {
        return "StrategyTUSDypool";
    }
    
    function harvest() external {
        require(msg.sender == keeper || msg.sender == strategist || msg.sender == governance, "!ksg");
        rebalance();
        uint _want = (IERC20(want).balanceOf(address(this))).sub(tank);
        if (_want > 0) {
            if (_want > maxAmount) _want = maxAmount;
            yvERC20(ytusd).deposit(_want);
        }
        uint _y = IERC20(ytusd).balanceOf(address(this));
        if (_y > 0) {
            uint v = _want.mul(1e18).div(ICurveFi(ypool).get_virtual_price());
            ICurveFi(ypool).add_liquidity([0, 0, 0, _y], v.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
        }
        uint _bal = IERC20(ycrv).balanceOf(address(this));
        if (_bal > 0) {
            yvERC20(yycrv).deposit(_bal);
        }
    }

    function deposit() public {}
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(ycrv != address(_asset), "ycrv");
        require(yycrv != address(_asset), "yycrv");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }
    
    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");

        rebalance();
        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
            tank = 0;
        }
        else {
            if (tank >= _amount) tank = tank.sub(_amount);
            else tank = 0;
        }

        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        uint _fee = _amount.mul(withdrawalFee).div(DENOMINATOR);
        IERC20(want).safeTransfer(Controller(controller).rewards(), _fee);
        IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
    }

    function _withdrawSome(uint _amount) internal returns (uint) {
        uint _amnt = _amount.mul(1e18).div(ICurveFi(ypool).get_virtual_price());
        uint _amt = _amnt.mul(1e18).div(yvERC20(yycrv).getPricePerFullShare());
        uint _bal = IERC20(yycrv).balanceOf(address(this));
        if (_amt > _bal) _amt = _bal;
        uint _before = IERC20(ycrv).balanceOf(address(this));
        yvERC20(yycrv).withdraw(_amt);
        uint _after = IERC20(ycrv).balanceOf(address(this));
        return _withdrawOne(_after.sub(_before));
    }

    function _withdrawOne(uint _amnt) internal returns (uint) {
        uint _aux = _amnt.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR);
        uint _t = IERC20(ycrv).totalSupply();
        ICurveFi(ypool).remove_liquidity(_amnt, [
            ICurveFi(ypool).balances(0).mul(_aux).div(_t), 
            ICurveFi(ypool).balances(1).mul(_aux).div(_t), 
            ICurveFi(ypool).balances(2).mul(_aux).div(_t), 
            ICurveFi(ypool).balances(3).mul(_aux).div(_t)]);

        uint _ydai = IERC20(ydai).balanceOf(address(this));
        uint _yusdc = IERC20(yusdc).balanceOf(address(this));
        uint _yusdt = IERC20(yusdt).balanceOf(address(this));
    
        uint tmp;
        if (_ydai > 0) {
            tmp = ICurveFi(ypool).get_dy(0, 3, _ydai);
            ICurveFi(ypool).exchange(0, 3, _ydai, tmp.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
        }
        if (_yusdc > 0) {
            tmp = ICurveFi(ypool).get_dy(1, 3, _yusdc);
            ICurveFi(ypool).exchange(1, 3, _yusdc, tmp.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
        }
        if (_yusdt > 0) {
            tmp = ICurveFi(ypool).get_dy(2, 3, _yusdt);
            ICurveFi(ypool).exchange(2, 3, _yusdt, tmp.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
        }

        uint _before = IERC20(want).balanceOf(address(this));
        yvERC20(ytusd).withdraw(IERC20(ytusd).balanceOf(address(this)));
        uint _after = IERC20(want).balanceOf(address(this));
        
        return _after.sub(_before);
    }
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();
        
        balance = IERC20(want).balanceOf(address(this));
        
        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }
    
    function _withdrawAll() internal {
        uint _yycrv = IERC20(yycrv).balanceOf(address(this));
        if (_yycrv > 0) {
            yvERC20(yycrv).withdraw(_yycrv);
            _withdrawOne(IERC20(ycrv).balanceOf(address(this)));
        }
    }
    
    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }
    
    function balanceOfYCRV() public view returns (uint) {
        return IERC20(ycrv).balanceOf(address(this));
    }
    
    function balanceOfYCRVinWant() public view returns (uint) {
        return balanceOfYCRV().mul(ICurveFi(ypool).get_virtual_price()).div(1e18);
    }

    function balanceOfYYCRV() public view returns (uint) {
        return IERC20(yycrv).balanceOf(address(this));
    }

    function balanceOfYYCRVinYCRV() public view returns (uint) {
        return balanceOfYYCRV().mul(yvERC20(yycrv).getPricePerFullShare()).div(1e18);
    }

    function balanceOfYYCRVinWant() public view returns (uint) {
        return balanceOfYYCRVinYCRV().mul(ICurveFi(ypool).get_virtual_price()).div(1e18);
    }

    function lick() public view returns (uint l) {
        uint _p = yvERC20(yycrv).getPricePerFullShare();
        _p = _p.mul(ICurveFi(ypool).get_virtual_price()).div(1e18);
        if (_p >= p) {
            l = (_p.sub(p)).mul(balanceOfYYCRV()).div(1e18);
            l = l.mul(treasuryFee.add(strategistReward)).div(DENOMINATOR);
        }
    }
    
    function balanceOf() public view returns (uint) {
        return balanceOfWant().add(balanceOfYYCRVinWant()).sub(lick());
    }

    function migrate(address _strategy) external {
        require(msg.sender == governance, "!governance");
        require(Controller(controller).approvedStrategies(want, _strategy), "!stategyAllowed");
        IERC20(yycrv).safeTransfer(_strategy, IERC20(yycrv).balanceOf(address(this)));
        IERC20(ycrv).safeTransfer(_strategy, IERC20(ycrv).balanceOf(address(this)));
        IERC20(want).safeTransfer(_strategy, IERC20(want).balanceOf(address(this)));
    }

    function forceD(uint _amount) external isAuthorized {
        drip();
        yvERC20(ytusd).deposit(_amount);

        uint _y = IERC20(ytusd).balanceOf(address(this));
        uint v = _amount.mul(1e18).div(ICurveFi(ypool).get_virtual_price());
        ICurveFi(ypool).add_liquidity([0, 0, 0, _y], v.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));

        uint _bal = IERC20(ycrv).balanceOf(address(this));
        yvERC20(yycrv).deposit(_bal);

        if (_amount < tank) tank = tank.sub(_amount);
        else tank = 0;
    }

    function forceW(uint _amt) external isAuthorized {
        drip();
        uint _before = IERC20(ycrv).balanceOf(address(this));
        yvERC20(yycrv).withdraw(_amt);
        uint _after = IERC20(ycrv).balanceOf(address(this));
        _amt = _after.sub(_before);
        
        _before = IERC20(want).balanceOf(address(this));
        _withdrawOne(_amt);
        _after = IERC20(want).balanceOf(address(this));
        tank = tank.add(_after.sub(_before));
    }

    function drip() public isAuthorized {
        uint _p = yvERC20(yycrv).getPricePerFullShare();
        _p = _p.mul(ICurveFi(ypool).get_virtual_price()).div(1e18);
        require(_p >= p, 'backward');
        uint _r = (_p.sub(p)).mul(balanceOfYYCRV()).div(1e18);
        uint _s = _r.mul(strategistReward).div(DENOMINATOR);
        IERC20(yycrv).safeTransfer(strategist, _s.mul(1e18).div(_p));
        uint _t = _r.mul(treasuryFee).div(DENOMINATOR);
        IERC20(yycrv).safeTransfer(Controller(controller).rewards(), _t.mul(1e18).div(_p));
        p = _p;
    }

    function tick() public view returns (uint _t, uint _c) {
        _t = ICurveFi(ypool).balances(3)
                .mul(yvERC20(ytusd).getPricePerFullShare()).div(1e18)
                .mul(threshold).div(DENOMINATOR);
        _c = balanceOfYYCRVinWant();
    }

    function rebalance() public isAuthorized {
        drip();
        (uint _t, uint _c) = tick();
        if (_c > _t) {
            _withdrawSome(_c.sub(_t));
            tank = IERC20(want).balanceOf(address(this));
        }
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance || msg.sender == strategist, "!gs");
        strategist = _strategist;
    }

    function setKeeper(address _keeper) external {
        require(msg.sender == strategist || msg.sender == governance, "!sg");
        keeper = _keeper;
    }

    function setWithdrawalFee(uint _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setTreasuryFee(uint _treasuryFee) external {
        require(msg.sender == governance, "!governance");
        treasuryFee = _treasuryFee;
    }

    function setStrategistReward(uint _strategistReward) external {
        require(msg.sender == governance, "!governance");
        strategistReward = _strategistReward;
    }

    function setThreshold(uint _threshold) external {
        require(msg.sender == strategist || msg.sender == governance, "!sg");
        threshold = _threshold;
    }

    function setSlip(uint _slip) external {
        require(msg.sender == strategist || msg.sender == governance, "!sg");
        slip = _slip;
    }

    function setMaxAmount(uint _maxAmount) external {
        require(msg.sender == strategist || msg.sender == governance, "!sg");
        maxAmount = _maxAmount;
    }
}