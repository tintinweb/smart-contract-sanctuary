/**
 *Submitted for verification at Etherscan.io on 2021-02-18
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
    function balances(uint) external view returns (uint);
    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;
    function remove_liquidity(
        uint256 _amount,
        uint256[3] calldata min_amounts
    ) external;
    function remove_liquidity_one_coin(
        uint256 _token_amount, 
        int128 i, 
        uint256 min_amount
    ) external;
    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount
    ) external;
    function exchange(
        int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
    ) external;
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


contract StrategyDAI3pool {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address constant public want = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address constant public _3pool = address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    address constant public _3crv = address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    address constant public y3crv = address(0x9cA85572E6A3EbF24dEDd195623F188735A5179f);

    address public governance;
    address public controller;
    address public strategist;
    address public keeper;

    uint constant public DENOMINATOR = 10000;
    uint public treasuryFee = 1000;
    uint public withdrawalFee = 50;
    uint public strategistReward = 1000;
    uint public threshold = 8000;
    uint public slip = 5;
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
    }
    
    function getName() external pure returns (string memory) {
        return "StrategyDAI3pool";
    }
    
    function harvest() external {
        require(msg.sender == keeper || msg.sender == strategist || msg.sender == governance, "!ksg");
        rebalance();
        uint _want = (IERC20(want).balanceOf(address(this))).sub(tank);
        if (_want > 0) {
            if (_want > maxAmount) _want = maxAmount;
            IERC20(want).safeApprove(_3pool, 0);
            IERC20(want).safeApprove(_3pool, _want);
            uint v = _want.mul(1e18).div(ICurveFi(_3pool).get_virtual_price());
            ICurveFi(_3pool).add_liquidity([_want, 0, 0], v.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
        }
        uint _bal = IERC20(_3crv).balanceOf(address(this));
        if (_bal > 0) {
            IERC20(_3crv).safeApprove(y3crv, 0);
            IERC20(_3crv).safeApprove(y3crv, _bal);
            yvERC20(y3crv).deposit(_bal);
        }
    }

    function deposit() public {}
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(_3crv != address(_asset), "3crv");
        require(y3crv != address(_asset), "y3crv");
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
        uint _amnt = _amount.mul(1e18).div(ICurveFi(_3pool).get_virtual_price());
        uint _amt = _amnt.mul(1e18).div(yvERC20(y3crv).getPricePerFullShare());
        uint _bal = IERC20(y3crv).balanceOf(address(this));
        if (_amt > _bal) _amt = _bal;
        uint _before = IERC20(_3crv).balanceOf(address(this));
        yvERC20(y3crv).withdraw(_amt);
        uint _after = IERC20(_3crv).balanceOf(address(this));
        return _withdrawOne(_after.sub(_before));
    }

    function _withdrawOne(uint _amnt) internal returns (uint) {
        uint _before = IERC20(want).balanceOf(address(this));
        IERC20(_3crv).safeApprove(_3pool, 0);
        IERC20(_3crv).safeApprove(_3pool, _amnt);
        ICurveFi(_3pool).remove_liquidity_one_coin(_amnt, 0, _amnt.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
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
        uint _y3crv = IERC20(y3crv).balanceOf(address(this));
        if (_y3crv > 0) {
            yvERC20(y3crv).withdraw(_y3crv);
            _withdrawOne(IERC20(_3crv).balanceOf(address(this)));
        }
    }
    
    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }
    
    function balanceOf3CRV() public view returns (uint) {
        return IERC20(_3crv).balanceOf(address(this));
    }
    
    function balanceOf3CRVinWant() public view returns (uint) {
        return balanceOf3CRV().mul(ICurveFi(_3pool).get_virtual_price()).div(1e18);
    }

    function balanceOfy3CRV() public view returns (uint) {
        return IERC20(y3crv).balanceOf(address(this));
    }

    function balanceOfy3CRVin3CRV() public view returns (uint) {
        return balanceOfy3CRV().mul(yvERC20(y3crv).getPricePerFullShare()).div(1e18);
    }

    function balanceOfy3CRVinWant() public view returns (uint) {
        return balanceOfy3CRVin3CRV().mul(ICurveFi(_3pool).get_virtual_price()).div(1e18);
    }

    function lick() public view returns (uint l) {
        uint _p = yvERC20(y3crv).getPricePerFullShare();
        _p = _p.mul(ICurveFi(_3pool).get_virtual_price()).div(1e18);
        if (_p >= p) {
            l = (_p.sub(p)).mul(balanceOfy3CRV()).div(1e18);
            l = l.mul(treasuryFee.add(strategistReward)).div(DENOMINATOR);
        }
    }
    
    function balanceOf() public view returns (uint) {
        return balanceOfWant().add(balanceOfy3CRVinWant()).sub(lick());
    }

    function migrate(address _strategy) external {
        require(msg.sender == governance, "!governance");
        require(Controller(controller).approvedStrategies(want, _strategy), "!stategyAllowed");
        IERC20(y3crv).safeTransfer(_strategy, IERC20(y3crv).balanceOf(address(this)));
        IERC20(_3crv).safeTransfer(_strategy, IERC20(_3crv).balanceOf(address(this)));
        IERC20(want).safeTransfer(_strategy, IERC20(want).balanceOf(address(this)));
    }

    function forceD(uint _amount) external isAuthorized {
        drip();
        IERC20(want).safeApprove(_3pool, 0);
        IERC20(want).safeApprove(_3pool, _amount);
        uint v = _amount.mul(1e18).div(ICurveFi(_3pool).get_virtual_price());
        ICurveFi(_3pool).add_liquidity([_amount, 0, 0], v.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
        if (_amount < tank) tank = tank.sub(_amount);
        else tank = 0;

        uint _bal = IERC20(_3crv).balanceOf(address(this));
        IERC20(_3crv).safeApprove(y3crv, 0);
        IERC20(_3crv).safeApprove(y3crv, _bal);
        yvERC20(y3crv).deposit(_bal);
    }

    function forceW(uint _amt) external isAuthorized {
        drip();
        uint _before = IERC20(_3crv).balanceOf(address(this));
        yvERC20(y3crv).withdraw(_amt);
        uint _after = IERC20(_3crv).balanceOf(address(this));
        _amt = _after.sub(_before);
        
        IERC20(_3crv).safeApprove(_3pool, 0);
        IERC20(_3crv).safeApprove(_3pool, _amt);
        _before = IERC20(want).balanceOf(address(this));
        ICurveFi(_3pool).remove_liquidity_one_coin(_amt, 0, _amt.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
        _after = IERC20(want).balanceOf(address(this));
        tank = tank.add(_after.sub(_before));
    }

    function drip() public isAuthorized {
        uint _p = yvERC20(y3crv).getPricePerFullShare();
        _p = _p.mul(ICurveFi(_3pool).get_virtual_price()).div(1e18);
        require(_p >= p, 'backward');
        uint _r = (_p.sub(p)).mul(balanceOfy3CRV()).div(1e18);
        uint _s = _r.mul(strategistReward).div(DENOMINATOR);
        IERC20(y3crv).safeTransfer(strategist, _s.mul(1e18).div(_p));
        uint _t = _r.mul(treasuryFee).div(DENOMINATOR);
        IERC20(y3crv).safeTransfer(Controller(controller).rewards(), _t.mul(1e18).div(_p));
        p = _p;
    }

    function tick() public view returns (uint _t, uint _c) {
        _t = ICurveFi(_3pool).balances(0).mul(threshold).div(DENOMINATOR);
        _c = balanceOfy3CRVinWant();
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