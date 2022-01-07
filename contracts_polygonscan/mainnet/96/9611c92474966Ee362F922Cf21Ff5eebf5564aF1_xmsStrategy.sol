/**
 *Submitted for verification at polygonscan.com on 2022-01-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

//
interface IController {
    function withdraw(address, uint256) external;

    function balanceOf(address, address) external view returns (uint256);

    function earn(address, uint256) external;

    function want(address) external view returns (address);

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);

    function strategies(address) external view returns (address);
}

//
interface Uni {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}


interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256 amt) external;
}

interface WBNBContract{
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

interface FarmKlima{
    function set_initReward(uint256 initamount) external returns (uint);
}

// //Look into this
// interface FarmGEG{
//     function set_initReward(uint256 initamount) external returns (uint);
// }

interface IKlimaStaking{
    function unstake( uint _amount, bool _trigger ) external;
}

interface IKlimaHelper{
    function stake( uint _amount ) external;
}

contract xmsStrategy{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant klimahelper = 0x4D70a031Fc76DA6a9bC0C922101A05FA95c3A227;
    address public constant kilimastaking = 0x25d28a24Ceb6F81015bB0b2007D795ACAc411b4d;
    address public constant klima = 0x4e78011Ce80ee02d2c3e649Fb657E45898257815;
    address public constant sklima = 0xb0C22d8D350C67420f06F48936654f567C73E8C8;

    // uint256 public strategistReward = 20;
    uint256 public restake = 50;
    uint256 public gegReward = 25;
    uint256 public wbnbReward = 25;
    uint256 public withdrawalFee = 50;
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint public lastHarvestTime;

    address public out;
    
    address public pool;
    // uint256 public pid;
    address public want;

    address public governance;
    address public controller;
    address public strategist;
    uint256 public totalStake;
    address klimafarm = address(0);
    
    mapping(address => bool) public farmers;

    constructor(
        address _controller
    ) {
        governance = msg.sender;
        strategist = 0x254e34FD8DC5ca1752944DF0D89261809C225F9D;
        controller = _controller;
        want = klima;
        out = klima;
    }

    function addFarmer(address f) public {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!authorized"
        );
        require(f != address(0), "address error");
        farmers[f] = true;
    }

    function removeFarmer(address f) public {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!authorized"
        );
        farmers[f] = false;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        require(_governance != address(0), "address error");
        governance = _governance;
    }
    
    function setStrategist(address _strategist) external {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!authorized"
        );
        require(_strategist != address(0), "address error");
        strategist = _strategist;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }
    
    function setKlimaFarm(address _klimaFarm) external {
        require(msg.sender == governance, "!governance");
        klimafarm = _klimaFarm;
    }
    
    function setReward(uint256 _restake, uint _gegReward, uint _wbnbReward) external {
        require(msg.sender == governance, "!governance");
        restake = _restake;
        gegReward = _gegReward;
        wbnbReward = _wbnbReward;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return IERC20(sklima).balanceOf(address(this));
    }

    modifier onlyBenevolent {
        require(
            farmers[msg.sender] ||
                msg.sender == governance ||
                msg.sender == strategist
        );
        _;
    }
    

    function harvest() external{
        require(!Address.isContract(msg.sender),"!contract");
        require(block.timestamp >= lastHarvestTime, "Wait for next harvest time");

        //Balace - TotalStake
        uint rewards = IERC20(sklima).balanceOf(address(this)) - totalStake;
        IKlimaStaking(kilimastaking).unstake(rewards, false); 

        //rewards to farm
        lastHarvestTime = FarmKlima(klimafarm).set_initReward(IERC20(klima).balanceOf(address(this)));
        IERC20(klima).safeTransfer(klimafarm, IERC20(klima).balanceOf(address(this)));
    }

    function deposit() public {
        _deposit();
    }
    
    receive() external payable {
        // emit Received(msg.sender, msg.value);
    }

    function _deposit() internal returns (uint) {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            //xms
            IERC20(want).safeApprove(klimahelper, uint256(0));
            IERC20(want).safeApprove(klimahelper, _want);
            IKlimaHelper(klimahelper).stake(_want);
            totalStake = totalStake.add(_want);
        }
        return _want;
    }

    function _withdrawSome(uint256 _amount) public returns (uint256) {
        uint _before = IERC20(want).balanceOf(address(this));
        IERC20(sklima).safeApprove(kilimastaking, uint(0));
        IERC20(sklima).safeApprove(kilimastaking, uint(-1));
        IKlimaStaking(kilimastaking).unstake(_amount, false);
        uint _after = IERC20(want).balanceOf(address(this));
        uint _withdrew = _after.sub(_before);
        totalStake = totalStake.sub(_withdrew);
        return _withdrew;
    }

    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }

    function _withdrawAll() internal {
        uint256 wamount = balanceOf();
        IKlimaStaking(kilimastaking).unstake(wamount, false);
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _fee = _amount.mul(withdrawalFee).div(FEE_DENOMINATOR);

        if (_fee > 0) {
            IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
        }
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
    }

    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }
    
}