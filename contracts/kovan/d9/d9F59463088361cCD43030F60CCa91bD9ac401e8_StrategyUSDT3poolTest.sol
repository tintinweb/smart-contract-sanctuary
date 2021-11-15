pragma solidity 0.5.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint256);

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
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
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

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IController {
    function notifyFee(address _underlying, uint256 fee) external;
}

interface yvERC20 {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);
}

interface ICurveFi {
    function get_virtual_price() external view returns (uint256);

    function balances(uint256) external view returns (uint256);

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

contract IStorage {
    function controller() external view returns (address);

    function governance() external view returns (address);

    function setGovernance(address _governance) external;

    function setController(address _controller) external;

    function isGovernance(address account) external view returns (bool);

    function isController(address account) external view returns (bool);
}

contract StrategyUSDT3poolTest {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public want = address(0x87c74f9a8af61e2Ef33049E299dF919a17792115);
    address public _3pool = address(0xf7e68e9A17eF6E43f456eda1281765C10498208f);
    address public _3crv = address(0x8CD2678d7ba67752ca7585925582882E6EFd4b66);
    address public y3crv = address(0xAb299848AeA8f6641Fe1FfB809AD0c0208DbBB40);

    address public _storage;
    address public vault;

    uint256 constant public DENOMINATOR = 10000;
    uint256 public adminFee = 50;
    uint256 public threshold = 8000;
    uint256 public slip = 100;
    uint256 public tank;
    uint256 public p;

    event Threshold(address indexed strategy);

    modifier isAuthorized() {
        require(msg.sender == IStorage(_storage).governance() || msg.sender == vault ||
        msg.sender == IStorage(_storage).controller() || msg.sender == address(this), "!authorized");
        _;
    }

    constructor(address __storage, address _vault) public {
        vault = _vault;
        _storage = __storage;
    }

    function deposit() public isAuthorized {
        rebalance();
        uint256 _want = (IERC20(want).balanceOf(address(this))).sub(tank);
        if (_want > 0) {
            IERC20(want).safeApprove(_3pool, 0);
            IERC20(want).safeApprove(_3pool, _want);
            uint256 v = _want.mul(1e30).div(ICurveFi(_3pool).get_virtual_price());
            ICurveFi(_3pool).add_liquidity([0, 0, _want], v.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
        }
        uint256 _bal = IERC20(_3crv).balanceOf(address(this));
        if (_bal > 0) {
            IERC20(_3crv).safeApprove(y3crv, 0);
            IERC20(_3crv).safeApprove(y3crv, _bal);
            yvERC20(y3crv).deposit(_bal);
        }
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset, address to, uint256 amount) external returns (uint256) {
        require(msg.sender == IStorage(_storage).governance(), "!governance");
        _asset.safeTransfer(to, amount);
        return amount;
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external isAuthorized {
        rebalance();
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
            tank = 0;
        }
        else {
            if (tank >= _amount) tank = tank.sub(_amount);
            else tank = 0;
        }
        IERC20(want).safeTransfer(vault, _amount);
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        uint256 _amnt = _amount.mul(1e30).div(ICurveFi(_3pool).get_virtual_price());
        uint256 _amt = _amnt.mul(1e18).div(yvERC20(y3crv).getPricePerFullShare());
        uint256 _before = IERC20(_3crv).balanceOf(address(this));
        yvERC20(y3crv).withdraw(_amt);
        uint256 _after = IERC20(_3crv).balanceOf(address(this));
        return _withdrawOne(_after.sub(_before));
    }

    function _withdrawOne(uint256 _amnt) internal returns (uint256) {
        uint256 _before = IERC20(want).balanceOf(address(this));
        IERC20(_3crv).safeApprove(_3pool, 0);
        IERC20(_3crv).safeApprove(_3pool, _amnt);
        ICurveFi(_3pool).remove_liquidity_one_coin(_amnt, 2, _amnt.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR).div(1e12));
        uint256 _after = IERC20(want).balanceOf(address(this));

        return _after.sub(_before);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external isAuthorized returns (uint256 balance) {
        drip();
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(vault, balance);
    }

    function _withdrawAll() internal {
        uint256 _y3crv = IERC20(y3crv).balanceOf(address(this));
        if (_y3crv > 0) {
            yvERC20(y3crv).withdraw(_y3crv);
            _withdrawOne(IERC20(_3crv).balanceOf(address(this)));
        }
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOf3CRV() public view returns (uint256) {
        return IERC20(_3crv).balanceOf(address(this));
    }

    function balanceOf3CRVinWant() public view returns (uint256) {
        return balanceOf3CRV().mul(ICurveFi(_3pool).get_virtual_price()).div(1e30);
    }

    function balanceOfy3CRV() public view returns (uint256) {
        return IERC20(y3crv).balanceOf(address(this));
    }

    function balanceOfy3CRVin3CRV() public view returns (uint256) {
        return balanceOfy3CRV().mul(yvERC20(y3crv).getPricePerFullShare()).div(1e18);
    }

    function balanceOfy3CRVinWant() public view returns (uint256) {
        return balanceOfy3CRVin3CRV().mul(ICurveFi(_3pool).get_virtual_price()).div(1e30);
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfy3CRVinWant());
    }

    function migrate(address _strategy) external {
        require(msg.sender == IStorage(_storage).governance(), "!governance");
        IERC20(y3crv).safeTransfer(_strategy, IERC20(y3crv).balanceOf(address(this)));
        IERC20(_3crv).safeTransfer(_strategy, IERC20(_3crv).balanceOf(address(this)));
        IERC20(want).safeTransfer(_strategy, IERC20(want).balanceOf(address(this)));
    }

    function forceD(uint256 _amount) external isAuthorized {
        IERC20(want).safeApprove(_3pool, 0);
        IERC20(want).safeApprove(_3pool, _amount);
        uint256 v = _amount.mul(1e30).div(ICurveFi(_3pool).get_virtual_price());
        ICurveFi(_3pool).add_liquidity([0, 0, _amount], v.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR));
        if (_amount < tank) tank = tank.sub(_amount);
        else tank = 0;

        uint256 _bal = IERC20(_3crv).balanceOf(address(this));
        IERC20(_3crv).safeApprove(y3crv, 0);
        IERC20(_3crv).safeApprove(y3crv, _bal);
        yvERC20(y3crv).deposit(_bal);
    }

    function forceW(uint256 _amt) external isAuthorized {
        uint256 _before = IERC20(_3crv).balanceOf(address(this));
        yvERC20(y3crv).withdraw(_amt);
        uint256 _after = IERC20(_3crv).balanceOf(address(this));
        _amt = _after.sub(_before);

        IERC20(_3crv).safeApprove(_3pool, 0);
        IERC20(_3crv).safeApprove(_3pool, _amt);
        _before = IERC20(want).balanceOf(address(this));
        ICurveFi(_3pool).remove_liquidity_one_coin(_amt, 2, _amt.mul(DENOMINATOR.sub(slip)).div(DENOMINATOR).div(1e12));
        _after = IERC20(want).balanceOf(address(this));
        tank = tank.add(_after.sub(_before));
    }

    event NotifyProfitInRewardToken(uint256 _p, uint p, uint _s, uint amount);

    function notifyProfitInRewardToken(uint256 _rewardBalance) internal {
        IERC20(y3crv).safeApprove(IStorage(_storage).controller(), 0);
        IERC20(y3crv).safeApprove(IStorage(_storage).controller(), _rewardBalance);
        IController(IStorage(_storage).controller()).notifyFee(
            y3crv,
            _rewardBalance
        );
    }

    function drip() public isAuthorized {
        uint256 _p = yvERC20(y3crv).getPricePerFullShare();
        _p = _p.mul(ICurveFi(_3pool).get_virtual_price()).div(1e18);
        require(_p >= p, 'backward');
        uint256 _r = (_p.sub(p)).mul(balanceOfy3CRV()).div(1e18);
        uint256 _s = _r.mul(adminFee).div(DENOMINATOR);
        emit NotifyProfitInRewardToken(_p, p, _s, _s.mul(1e18).div(_p));
        notifyProfitInRewardToken(_s.mul(1e18).div(_p));
        p = _p;
    }

    function tick() public view returns (uint256 _t, uint256 _c) {
        _t = balanceOfy3CRVinWant() + 100;
        _c = balanceOfy3CRVinWant();
    }

    // Send portion interest to team and withdraw some if (invested amount - thread*(total usdt amount in pool)>0 )
    function rebalance() public isAuthorized {
        drip();
        (uint256 _t, uint256 _c) = tick();
        if (_c > _t) {
            _withdrawSome(_c.sub(_t));
            tank = IERC20(want).balanceOf(address(this));
            emit Threshold(address(this));
        }
    }

    function setAdminFee(uint256 _adminFee) external isAuthorized {
        adminFee = _adminFee;
    }

    function setThreshold(uint256 _threshold) external isAuthorized {
        threshold = _threshold;
    }

    function setSlip(uint256 _slip) external isAuthorized {
        slip = _slip;
    }
}

