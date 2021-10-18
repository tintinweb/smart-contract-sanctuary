/**
 *Submitted for verification at BscScan.com on 2021-10-18
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

interface WBNBContract{
    function deposit() external;
}

//path
// bb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c WBNB
// e9e7cea3dedca5984780bafc599bd69add087d56 BUSD
// 7859b01bbf675d67da8cd128a50d155cd881b576 XMS

interface MarsInterface {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )   external returns (uint256[] memory amounts);
}

interface LiquidityMiningMaster{
    function deposit(
        uint256 _pid,
        uint256 _amount
        ) external;
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

contract Strategy{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

   
    address public newb;
    address public constant usdt = 0x55d398326f99059fF775485246999027B3197955;  
    address public constant wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;  
    address public constant busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;  
    address public constant xms = 0x7859B01BbF675d67Da8cD128a50D155cd881B576; 
    
    address public uniRouter;
    address public marsRouter;
    address public lmmBNB;

    uint256 public strategistReward = 20;
    uint256 public restake = 40;
    uint256 public convertNewB = 20;
    uint256 public convertVault = 20;
    uint256 public withdrawalFee = 500;
    uint256 public constant FEE_DENOMINATOR = 10000;

    address public out;
    
    address public pool;
    uint256 public pid;
    address public want;
    
    address public token0Address;
    address public token1Address;

    address public governance;
    address public controller;
    address public strategist;
    address public vault;

    mapping(address => bool) public farmers;
    
    
    event FarmerAdded(address indexed farmer);
    event FarmerRemoved(address indexed farmer);
    event WithdrawalFeeUpdated(uint256 indexed withdrawalFee);
    event StrategistRewardUpdated(uint256 indexed strategistReward);
    event RestakeUpdated(uint256 indexed restake);
    event PoolUpdated(address indexed pool);
    event PIDUpdated(uint256 indexed pid);
    event WantUpdated(address indexed want);
    event OutUpdated(address indexed out);
    event HarvestComplete();
    event DepoitComplete();
    event StrategistUpdate(address indexed previousStrategist, address indexed newStrategist);
    event GovernanceUpdate(address indexed previousGovernance, address indexed newGovernance);
    event UniRouterUpdate(address indexed previousUniRouter, address indexed newUniRouter);
    event ControllerUpdate(address indexed previousController, address indexed newController);
    
    constructor(
        address _controller,
        address _pool,
        uint _pid,
        address _want,
        address _out,
        address _token0Address,
        address _token1Address,
        address _newbAddress,
        address _strategistAddress,
        address _uniRouter,
        address _marsRouter,
        address _lmmBNB
        
    ) {
        governance = msg.sender;
        strategist = _strategistAddress;
        controller = _controller;
        pool = _pool;
        pid = _pid;
        want = _want;
        out = _out;
        token0Address = _token0Address;
        token1Address = _token1Address;
        newb = _newbAddress;
        uniRouter = _uniRouter;
        marsRouter = _marsRouter;
        lmmBNB = _lmmBNB;
        doApprove();
    }
    
    function doApprove () internal{
        IERC20(out).safeApprove(uniRouter, 0);
        IERC20(out).safeApprove(uniRouter, uint(-1));
    }

    function addFarmer(address f) external {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!authorized"
        );
        require(f != address(0), "address error");
        farmers[f] = true;
        
        emit FarmerAdded(f);
    }

    function removeFarmer(address f) external {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!authorized"
        );
        farmers[f] = false;
        
        emit FarmerRemoved(f);
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        require(_governance != address(0), "address error");
        
        address previousGovernance = governance;
        governance = _governance;
        
        emit GovernanceUpdate(previousGovernance, _governance);
    }
    
    function setStrategist(address _strategist) external {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!authorized"
        );
        require(_strategist != address(0), "address error");
        address previousStrategist = _strategist;
        strategist = _strategist;
        
        
         emit StrategistUpdate(previousStrategist, _strategist);
    }
    
    function setController(address _controller) external {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!authorized"
        );
        require(_controller != address(0), "address error");
        address previousController = controller;
        controller = _controller;
        
        
         emit StrategistUpdate(previousController, _controller);
    }
    
    function setUniRouter(address _uniRouter) external {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!authorized"
        );
        require(uniRouter != address(0), "address error");
        address previousUniRouter = uniRouter;
        uniRouter = _uniRouter;
        
        
         emit UniRouterUpdate(previousUniRouter, _uniRouter);
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setStrategistReward(uint256 _strategistReward) external {
        require(msg.sender == governance, "!governance");
        strategistReward = _strategistReward;
        
        emit StrategistRewardUpdated(_strategistReward);
    }
    
    //
    function setRestake(uint256 _restake) external {
        require(msg.sender == governance, "!governance");
        restake = _restake;
        
        emit RestakeUpdated(_restake);
    }
    
    function setPID(uint256 _pid) external {
        require(msg.sender == governance, "!governance");
        pid = _pid;
        
        emit PIDUpdated(_pid);
    }
    
    function setPool(address _pool) external {
        require(msg.sender == governance, "!governance");
        pool = _pool;
        
        emit PoolUpdated(_pool);
    }
    
    function setWant(address _want) external {
        require(msg.sender == governance, "!governance");
        want = _want;
        
        emit WantUpdated(_want);
    }
    
    function setOut(address _out) external {
        require(msg.sender == governance, "!governance");
        out = _out;
        
        emit OutUpdated(_out);
    }
    
    function balanceOfPool() public view returns (uint256) {
        UserInfo memory user = dRewards(pool).userInfo(pid,address(this));
        return user.amount;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOf() external view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }
    
    function getNumOfRewards() external view returns (uint256 pending) {
        pending = dRewards(pool).pendingCake(pid,address(this));
    }
    
    function swapXms(uint _amount)external{
        address[] memory path = new address[](2); 
        path[0] = wbnb;
        path[1] = busd;
        path[2] = xms;
        MarsInterface(marsRouter).swapExactTokensForTokens(_amount, uint256(0), path, msg.sender, block.timestamp.add(1800));
    }
    
    function depositWithBnb(uint _amount)public{
        address[] memory path = new address[](2); 
        path[0] = wbnb;
        path[1] = busd;
        path[2] = xms;
        MarsInterface(marsRouter).swapExactTokensForTokens(_amount, uint256(0), path, address(this), block.timestamp.add(1800));
        
        LiquidityMiningMaster(lmmBNB).deposit(0, IERC20(xms).balanceOf(address(this)));
    }
    
    function depositWithXms(uint _amount)external{
        LiquidityMiningMaster(lmmBNB).deposit(0, _amount);
    }
    
    function harvest() external{
         require(!Address.isContract(msg.sender),"!contract");
         LiquidityMiningMaster(lmmBNB).deposit(0, 0);
        uint TotalReward = address(this).balance;
        // (bool sentBNBStrategist, bytes memory data1) = address(this).call{value: TotalReward.mul(strategistReward).div(100)}("");
        // require(sentBNBStrategist, "Failed to send BNB to strategist");
        // (bool sentBNBVault, bytes memory data2) = address(this).call{value: TotalReward.mul(convertVault).div(100)}("");
        // require(sentBNBVault, "Failed to send BNB to Vault");
        WBNBContract(wbnb).deposit();
        IERC20(wbnb).safeTransfer(strategist, TotalReward.mul(strategistReward).div(100));
        IERC20(wbnb).safeTransfer(vault, TotalReward.mul(convertVault).div(100));
        
        depositWithBnb(TotalReward.mul(restake).div(100));
        
        address[] memory path = new address[](2); 
                path[0] = out;
                path[1] = busd;
                Uni(uniRouter).swapExactTokensForTokens(
                    TotalReward.mul(convertNewB).div(100),
                    uint256(0),
                    path,
                    address(this),
                    block.timestamp.add(1800)
                );
                IERC20(busd).safeApprove(uniRouter, 0);
                IERC20(busd).safeApprove(uniRouter, uint256(-1));
                path[0] = busd;
                path[1] = newb;
                Uni(uniRouter).swapExactTokensForTokens(
                    IERC20(busd).balanceOf(address(this)),
                    uint256(0),
                    path,
                    address(this),
                    block.timestamp.add(1800)
                );
        IERC20(newb).safeTransfer(vault, IERC20(newb).balanceOf(address(this)));
    }
    
    function harvest2() payable external{
        LiquidityMiningMaster(lmmBNB).deposit(0, 0);
        uint TotalReward = address(this).balance;
        (bool sentBNBStrategist, bytes memory data1) = address(this).call{value: TotalReward.mul(strategistReward).div(100)}("");
        require(sentBNBStrategist, "Failed to send BNB to strategist");
        (bool sentBNBVault, bytes memory data2) = address(this).call{value: TotalReward.mul(convertVault).div(100)}("");
        require(sentBNBVault, "Failed to send BNB to Vault");
        
        depositWithBnb(TotalReward.mul(restake).div(100));
        
        address[] memory path = new address[](2); 
                path[0] = out;
                path[1] = busd;
                Uni(uniRouter).swapExactTokensForTokens(
                    TotalReward.mul(convertNewB).div(100),
                    uint256(0),
                    path,
                    address(this),
                    block.timestamp.add(1800)
                );
                IERC20(busd).safeApprove(uniRouter, 0);
                IERC20(busd).safeApprove(uniRouter, uint256(-1));
                path[0] = busd;
                path[1] = newb;
                Uni(uniRouter).swapExactTokensForTokens(
                    IERC20(busd).balanceOf(address(this)),
                    uint256(0),
                    path,
                    address(this),
                    block.timestamp.add(1800)
                );
            IERC20(newb).safeTransfer(vault, IERC20(newb).balanceOf(address(this)));
    }
    
    // function harvest() external {
        
    //     require(!Address.isContract(msg.sender),"!contract");
    //     dRewards(pool).withdraw(pid,0);
        
    //     uint256 _2reward = IERC20(out).balanceOf(address(this)).mul(strategistReward).div(100);
    //     uint256 _2want = IERC20(out).balanceOf(address(this)).mul(restake).div(100);
    //     if(_2reward > 0)
    //     {
    //         address[] memory path = new address[](2); 
    //             path[0] = out;
    //             path[1] = busd;
    //             Uni(uniRouter).swapExactTokensForTokens(
    //                 _2reward,
    //                 uint256(0),
    //                 path,
    //                 address(this),
    //                 block.timestamp.add(1800)
    //             );
    //             IERC20(busd).safeApprove(uniRouter, 0);
    //             IERC20(busd).safeApprove(uniRouter, uint256(-1));
    //             path[0] = busd;
    //             path[1] = newb;
    //             Uni(uniRouter).swapExactTokensForTokens(
    //                 IERC20(busd).balanceOf(address(this)),
    //                 uint256(0),
    //                 path,
    //                 address(this),
    //                 block.timestamp.add(1800)
    //             );
    //         uint256 _2strategistReward = IERC20(newb).balanceOf(address(this));
            
    //         IERC20(newb).safeTransfer(strategist, _2strategistReward);
            
    //     }
    //     if(_2want > 0)
    //     {
    //         if (out != token0Address) {
    //             // Swap half earned to token0
    //             if(token0Address == busd)
    //             {
    //                 address[] memory path = new address[](2);
    //                 path[0] = out;
    //                 path[1] = busd;
    //                 Uni(uniRouter).swapExactTokensForTokens(
    //                         _2want.div(2),
    //                         uint256(0),
    //                         path,
    //                         address(this),
    //                         block.timestamp.add(1800)
    //                 );
    //             }else if(token0Address == usdt)
    //             {
    //                 address[] memory path = new address[](3);
    //                 path[0] = out;
    //                 path[1] = busd;
    //                 path[2] = usdt;
    //                 Uni(uniRouter).swapExactTokensForTokens(
    //                         _2want.div(2),
    //                         uint256(0),
    //                         path,
    //                         address(this),
    //                         block.timestamp.add(1800)
    //                 );
    //             }else{
    //                 address[] memory path = new address[](4);
    //                 path[0] = out;
    //                 path[1] = busd;
    //                 path[2] = usdt;
    //                 path[3] = token0Address;
    //                 Uni(uniRouter).swapExactTokensForTokens(
    //                         _2want.div(2),
    //                         uint256(0),
    //                         path,
    //                         address(this),
    //                         block.timestamp.add(1800)
    //                 );
    //             }
    //         }

    //     if (out != token1Address) {
    //         // Swap half earned to token1
    //           if(token1Address == busd)
    //             {
    //                 address[] memory path = new address[](2);
    //                 path[0] = out;
    //                 path[1] = busd;
    //                 Uni(uniRouter).swapExactTokensForTokens(
    //                         _2want.div(2),
    //                         uint256(0),
    //                         path,
    //                         address(this),
    //                         block.timestamp.add(1800)
    //                 );
    //             }else if(token1Address == usdt)
    //             {
    //                 address[] memory path = new address[](3);
    //                 path[0] = out;
    //                 path[1] = busd;
    //                 path[2] = usdt;
    //                 Uni(uniRouter).swapExactTokensForTokens(
    //                         _2want.div(2),
    //                         uint256(0),
    //                         path,
    //                         address(this),
    //                         block.timestamp.add(1800)
    //                 );
    //             }else{
    //                 address[] memory path = new address[](4);
    //                 path[0] = out;
    //                 path[1] = busd;
    //                 path[2] = usdt;
    //                 path[3] = token1Address;
    //                 Uni(uniRouter).swapExactTokensForTokens(
    //                         _2want.div(2),
    //                         uint256(0),
    //                         path,
    //                         address(this),
    //                         block.timestamp.add(1800)
    //                 );
    //             }
    //     }

    //     uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
    //     uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
    //     if (token0Amt > 0 && token1Amt > 0) {
    //             IERC20(token0Address).safeApprove(uniRouter, 0);
    //             IERC20(token0Address).safeApprove(uniRouter, uint256(-1));
    //             IERC20(token1Address).safeApprove(uniRouter, 0);
    //             IERC20(token1Address).safeApprove(uniRouter, uint256(-1));
    //             Uni(uniRouter).addLiquidity(
    //                 token0Address,
    //                 token1Address,
    //                 token0Amt,
    //                 token1Amt,
    //                 0,
    //                 0,
    //                 address(this),
    //                 block.timestamp.add(1800)
    //             );
    //         }
    //     }
        
    //     _deposit();
        
    //     emit HarvestComplete();
    // }

    function deposit() external {
        
        _deposit();
        emit DepoitComplete();
    }

    function _deposit() internal returns (uint) {
        uint256 xmsAmount = IERC20(want).balanceOf(address(this));
        if (xmsAmount > 0) {
            IERC20(want).safeApprove(pool, 0);
            IERC20(want).safeApprove(pool, xmsAmount);
            LiquidityMiningMaster(lmmBNB).deposit(0, xmsAmount);
        }
        return xmsAmount;
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

}