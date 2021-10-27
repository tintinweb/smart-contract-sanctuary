/**
 *Submitted for verification at BscScan.com on 2021-10-27
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

    function balanceOf(address) external view returns (uint256);

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


   struct UserInfo {                                                                
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CAKEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCakePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCakePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }


interface dRewards {
    function userInfo(uint256,address) external view returns(UserInfo calldata);
    // function stake(address _pair, uint256 _amount) external;
    // function unstake(address _pair, uint256 _amount) external;
    // function pendingToken(address _pair, address _user) external returns (uint256);
    
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
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

interface FarmWBNB{
    function set_initReward(uint256 initamount, uint finishPeriod) external;
}

interface FarmNEWB{
    function set_initReward(uint256 initamount, uint finishPeriod) external;
}

contract xmsStrategy{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant xms = 0x7859B01BbF675d67Da8cD128a50D155cd881B576;
    address public constant marsRouter = 0xb68825C810E67D4e444ad5B9DeB55BA56A66e72D;
    address public constant liquidityminingmasterBNB = 0x48C42579D98Aa768cde893F8214371ed607CABE3; //pool
    address public constant newb = 0x545f90dC35CA1e6129f1fEd354b3e2DF12034261;
    address public constant busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;  
    address public constant usdt = 0x55d398326f99059fF775485246999027B3197955;  
    address public constant uniRouter = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;
    address public newbfarm;
    address public wbnbfarm;

    uint256 public strategistReward = 20;
    uint256 public restake = 40;
    uint256 public newbReward = 20;
    uint256 public wbnbReward = 20;
    uint256 public withdrawalFee = 50;
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint public lastHarvestTime;

    address public out;
    
    address public pool;
    uint256 public pid;
    address public want;

    address public governance;
    address public controller;
    address public strategist;
    
    //uint public TotalBNBReward;
    //uint public TotalNewBReward;

    mapping(address => bool) public farmers;

    constructor(
        address _controller
    ) {
        governance = msg.sender;
        strategist = 0x2E692d0E4b79938bacd08E66F053de060a3A64e2;
        controller = _controller;
        pool = liquidityminingmasterBNB;
        pid = 0;
        want = xms;
        out = wbnb;
        
        doApprove();
    }
    
    function doApprove () internal{
        IERC20(out).safeApprove(uniRouter, 0);
        IERC20(out).safeApprove(uniRouter, uint(-1));
        IERC20(out).safeApprove(marsRouter, 0);
        IERC20(out).safeApprove(marsRouter, uint(-1));
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
    
    
    function setReward(uint256 _restake, uint _strategistReward, uint _newBReward, uint _wbnbReward) external {
        require(msg.sender == governance, "!governance");
        restake = _restake;
        strategistReward = _strategistReward;
        newbReward = _newBReward;
        wbnbReward = _wbnbReward;
    }
    
    

    function setStrategistReward(uint256 _strategistReward) external {
        require(msg.sender == governance, "!governance");
        strategistReward = _strategistReward;
    }
    
    function setNEWBFarm(address _newbFarm) external {
        require(msg.sender == governance, "!governance");
        newbfarm = _newbFarm;
    }
    
    function setWBNBFarm(address _wbnbFarm) external {
        require(msg.sender == governance, "!governance");
        wbnbfarm = _wbnbFarm;
    }
    
    //
    function setRestake(uint256 _restake) external {
        require(msg.sender == governance, "!governance");
        restake = _restake;
    }

    function balanceOfPool() public view returns (uint256) {
        UserInfo memory user = dRewards(pool).userInfo(pid,address(this));
        return user.amount;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    modifier onlyBenevolent {
        require(
            farmers[msg.sender] ||
                msg.sender == governance ||
                msg.sender == strategist
        );
        _;
    }
    
    function getNumOfRewards() public view returns (uint256 pending) {
        pending = dRewards(pool).pendingCake(pid,address(this));
    }
    
    function harvest() public {
        require(!Address.isContract(msg.sender),"!contract");
        require(block.timestamp >= lastHarvestTime, "Wait for next harvest time");
        dRewards(pool).deposit(uint256(0), 0);
        wrapBNB();
        uint totalReward = IERC20(out).balanceOf(address(this));
        //Strategist Reward
        IERC20(out).safeTransfer(strategist, (totalReward.mul(strategistReward)).div(100));
        
        //NewB Reward 
        address[] memory path = new address[](2); 
        IERC20(out).safeApprove(uniRouter, 0);
        IERC20(out).safeApprove(uniRouter, uint256(-1));
        path[0] = out;
        path[1] = newb;
        Uni(uniRouter).swapExactTokensForTokens(
            (totalReward.mul(newbReward)).div(100),
            uint256(0),
            path,
            address(this),
            block.timestamp.add(1800)
        );
        
        uint currentTime = block.timestamp;
        //uint currentTime = block.timestamp + 8 hours;
        //lastHarvestTime = currentTime;
        lastHarvestTime = currentTime + 5 minutes;
        //FarmWBNB(wbnbfarm).set_initReward(TotalBNBReward, currentTime);
        //FarmNEWB(newbfarm).set_initReward(TotalNewBReward, currentTime);
        FarmWBNB(wbnbfarm).set_initReward((totalReward.mul(wbnbReward)).div(100), currentTime);
        FarmNEWB(newbfarm).set_initReward(IERC20(newb).balanceOf(address(this)), currentTime);
        
        //TotalNewBReward = TotalNewBReward.add(IERC20(newb).balanceOf(address(this)));
        IERC20(newb).safeTransfer(newbfarm, IERC20(newb).balanceOf(address(this)));
        
        
        //WBNB Reward
        //TotalBNBReward = TotalBNBReward.add((totalReward.mul(wbnbReward)).div(100));
        IERC20(out).transfer(wbnbfarm, (totalReward.mul(wbnbReward)).div(100));
        
        
        //Restake
        convertWBNBtoXms();
        IERC20(want).approve(pool, uint256(0));
        IERC20(want).approve(pool, IERC20(want).balanceOf(address(this)));
        dRewards(pool).deposit(uint256(0), IERC20(want).balanceOf(address(this)));
        
        
        
    }
    
    function convertWBNBtoXms() public {
        require(!Address.isContract(msg.sender),"!contract");
        address[] memory path = new address[](2);
                    path[0] = out; //wbnb
                    path[1] = xms;
                    Uni(marsRouter).swapExactTokensForTokens(
                            IERC20(wbnb).balanceOf(address(this)),
                            uint256(0),
                            path,
                            address(this),
                            block.timestamp.add(1800)
                    );
    }
    
    function _wrapBNB() internal {
        // BNB -> WBNB
        uint256 bnbBal = address(this).balance;
        if (bnbBal > 0) {
            WBNBContract(wbnb).deposit{value: bnbBal}(); // BNB -> WBNB
        }
    }

    function wrapBNB() public {
        _wrapBNB();
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
            IERC20(want).safeApprove(pool, uint256(0));
            IERC20(want).safeApprove(pool, _want);
            dRewards(pool).deposit(uint256(0), _want);
        }
        return _want;
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        uint _before = IERC20(want).balanceOf(address(this));
        dRewards(pool).withdraw(pid,_amount);
        uint _after = IERC20(want).balanceOf(address(this));
        uint _withdrew = _after.sub(_before);
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
        uint256 wamount = balanceOfPool();
        dRewards(pool).withdraw(pid,wamount);
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
    
    // function setTotalReward(uint amount1, uint amount2)public {
    //     require(
    //         msg.sender == governance || msg.sender == strategist,
    //         "!authorized"
    //     );
    //     TotalBNBReward = amount1;
    //     TotalNewBReward = amount2;
    // }
}