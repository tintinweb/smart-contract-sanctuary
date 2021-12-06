pragma solidity 0.6.12;

import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts/math/Math.sol';

import '../../interfaces/IPancakeRouter02.sol';
import '../VaultController.sol';
import '../../interfaces/IGoenDistributor.sol';
import '../../interfaces/IMasterChef.sol';
import '../../library/SafeToken.sol';
import '../../interfaces/IStrategy.sol';

import '../../goen/GoenToken.sol';


contract VaultCake is 
VaultController,
IStrategy,
ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using SafeToken for address;

    // Harvester
    address public harvester;

    // Pancake router
    IPancakeRouter02 private constant
    PANCAKE_ROUTER = IPancakeRouter02(0x89e310DB3feB95cf8eFD1EB47d9e0f2261E0f6bb); //Hardcoded

    // CAKE Manual Pool
    IMasterChef private constant 
    PancakePool = IMasterChef(0xcAc8e86Af492635F1a3Bd83D07658B8888D48CA8);

    // GOEN Token
    GoenToken private GOEN;

    // GOEN Distributor
    IGoenDistributor private goenDistributor;

    // WBNB address to use for swap from pancake
    address private constant WBNB = 0x97c012Ef10eDc79510A17272CEE3ecBE1443177F; //Hardcoded

    // To amplify reward
    uint256 private constant AMPLIFIED_COEF = 1e18;  

    // Value for balance of user deposit in real
    mapping(address => uint256) private principal;

    // Total BNB earned in pool
    uint256 public totalBNB;

    // Total GOEN earned in pool
    uint256 public totalGOEN;

    // Total share distributed (only calculate for share rewards BNB)
    uint256 public totalShares;

    // Last-time BNB earned
    uint256 public lastTimeBNB;

    // Last-time GOEN earned
    uint256 public lastTimeGOEN;

    // Last-time harvest
    uint256 public lastTimeHarvest;

    // Store balances of user (update from withdrawal, deposit, claim = getReward)
    mapping(address => uint256) public balances;

    // Reward per share stored of the last time update reward
    uint256 public rewardPerShareStored;

    // Reward per share stored of the last time update reward
    uint256 public goenRewardPerShareStored;

    uint256 public profitInterval;

    // Store the reward per share paid of user (update from updateReward modifier)
    mapping(address => uint256) public userRewardPerSharePaid;

    // Store the reward per share paid of user (update from updateReward modifier)
    mapping(address => uint256) public goenUserRewardPerSharePaid;

    // Current reward that can claim of user
    mapping(address => uint256) public rewards;

     // Current GOEN reward that can claim of user
    mapping(address => uint256) public goenRewards;

    // Total amount deposit in pool
    uint256 public totalDeposit;

    // Array of deposited addresses
    address[] public depositedUsers;

    // Current deposit 24h
    mapping(address => uint256) public userTotalDeposit24h;

    struct User {
        uint256 userId;
        address userAddress;
    }

    // Mapping user
    mapping(address => User) public mappingUser;
    
    // Total deposit balance of the day
    uint256 public totalDeposit24h;

    User newUser;

    function userExist(address _newUser) public view returns (bool) {
        if (depositedUsers.length == 0)
            return false;

        return (depositedUsers[mappingUser[_newUser].userId] == _newUser);
    }

    function addUser(address userAddress) public returns (uint256) {
        require(userAddress!= address(0));

        if (!userExist(userAddress)) {
            newUser = User(depositedUsers.length, userAddress);

            mappingUser[userAddress] = newUser;
            depositedUsers.push(userAddress);

            return newUser.userId;
        }
    }

    modifier onlyHarvester() {
        require(msg.sender == harvester, "Only Harvester can do this");
        _;
    }

    // Update the rewards and rewardPerSharePaid of an address
    modifier updateReward(address _account) {
        rewardPerShareStored = rewardPerShare();
        lastTimeBNB = totalBNB;
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerSharePaid[_account] = rewardPerShareStored;
        }
        _;
    }

    // Update the rewards and rewardPerSharePaid of an address
    modifier updateGOENReward(address _account) {
        goenRewardPerShareStored = goenRewardPerShare();
        lastTimeGOEN = totalGOEN;
        if (_account != address(0)) {
            goenRewards[_account] = goenEarned(_account);
            goenUserRewardPerSharePaid[_account] = goenRewardPerShareStored;
        }
        _;
    }

    /**
     * @notice TODO: Make contract can transfer ETH(BNB)???
     */
    receive() external payable {}

    /**
     * @notice TODO: Explaining???
     */
    function initialize(address _token) 
    external 
    initializer {
        require(
            _token != address(0), 
            'VaultCake: invalid token');

        __VaultController_init(IBEP20(_token));
        __ReentrancyGuard_init();
        vaultStakingToken.approve(address(PancakePool), uint256(-1));
        vaultStakingToken.approve(address(PANCAKE_ROUTER), uint256(-1));
    }

    
    /**
     * @notice Return amount balance being deposit in pool
     */
    function principalOf(address _account)
    public
    view
    override
    returns (uint256) {
        return principal[_account];
    }

    /**
     * @notice TODO: Get last time reward applicable benefit
     * @return The benefit from Venus that apply in the last time get rewardPerShare
     */
    function lastTimeRewardApplicable() 
    public
    view
    returns (uint256) {
        return Math.min(totalBNB, lastTimeBNB);
    }

    /**
     * @notice Calculate the reward per share of the system
     */
    function rewardPerShare()
    public
    view
    returns (uint256) {
        if (totalShares == 0) {
            return rewardPerShareStored;
        }
        return rewardPerShareStored.add(totalBNB.sub(lastTimeBNB).mul(AMPLIFIED_COEF).div(totalShares));
    }

    /**
     * @notice Calculate the reward per share of the system
     */
    function goenRewardPerShare()
    public
    view
    returns (uint256) {
        if (totalShares == 0) {
            return goenRewardPerShareStored;
        }
        return goenRewardPerShareStored.add(totalGOEN.sub(lastTimeGOEN).mul(AMPLIFIED_COEF).div(totalShares));
    }
    
    /**
     * @notice Calculate the current earned of an account
     */
    function earned(address _account) 
    public
    view
    override
    returns (uint256) {
        return balances[_account].
        mul(rewardPerShare().sub(userRewardPerSharePaid[_account]))
        .div(AMPLIFIED_COEF)
        .add(rewards[_account]);
    }

    /**
     * @notice Calculate the current earned of an account
     */
    function goenEarned(address _account) 
    public
    view
    returns (uint256) {
        return balances[_account].
        mul(goenRewardPerShare().sub(goenUserRewardPerSharePaid[_account]))
        .div(AMPLIFIED_COEF)
        .add(goenRewards[_account]);
    }

    /**
     * @notice return avaiable token asset of market on venus.
     */
    function balance() 
    public
    view
    override 
    returns (uint256) {
        return totalDeposit;
    }

    /**
     * @notice balance of user was deposited for pool
     * @param _account : address of user account
     */
    function balanceOf(address _account) 
    public
    view
    override 
    returns (uint256) {
        return principal[_account];
    }

    /**
     * @notice Return amount user can withdraw
     * @param _account : address of user account
     */
    function withdrawableBalanceOf(address _account)
    public
    view
    override
    returns (uint256) {
        return userTotalDeposit24h[_account] + balanceOf(_account);
    }

    function setup(address goenAddress, address harvesterAddress, address payable _goenDistributor)
    public
    onlyOwner {
        GOEN = GoenToken(goenAddress);
        harvester = harvesterAddress;
        goenDistributor = IGoenDistributor(_goenDistributor);
    }

    function setGoenToken(address goenAddress)
    public
    onlyOwner {
        GOEN = GoenToken(goenAddress);
    }

    /**
     * @notice Set harvester address
     * @param harvesterAddress  harvester address
     */
    function setHarvester(address harvesterAddress) 
    public
    onlyOwner {
        harvester = harvesterAddress;
    }

    /**
    * @notice Set goen distributor
    * @param _goenDistributor GoenDistributor address
    */
    function setGoenDistributor(address payable _goenDistributor) 
    public 
    onlyOwner {
        goenDistributor = IGoenDistributor(_goenDistributor);
    } 

    /**
     * @notice Deposit partial balances tokens asset of user
     * @param _amount : amount users deposit
     */
    function deposit(uint256 _amount)
    public
    override
    notPaused
    nonReentrant
    updateReward(msg.sender)
    updateGOENReward(msg.sender) {
        vaultStakingToken.transferFrom(msg.sender, address(this), _amount);
        totalDeposit = totalDeposit.add(_amount);

        addUser(msg.sender);
        userTotalDeposit24h[msg.sender] = userTotalDeposit24h[msg.sender].add(_amount);
        principal[msg.sender] = principal[msg.sender].add(_amount);
        totalDeposit24h = totalDeposit24h.add(_amount);

        emit Deposited(msg.sender, _amount);
    }

    /**
     * @notice deposit all balances tokens asset of user
     */
    function depositAll()
    external
    override {
        deposit(vaultStakingToken.balanceOf(msg.sender));
    }

    /**
     * @notice Withdraw all ballance from amount of deposit, rewards BNB &   * GOEN
     */
    function withdrawAll()
    external
    override
    updateReward(msg.sender)
    updateGOENReward(msg.sender) {
        uint256 amount = principal[msg.sender];
        //Update userTotalDeposit24h
        uint256 amount24h = userTotalDeposit24h[msg.sender];
        if (amount24h >= amount) {
            userTotalDeposit24h[msg.sender] = amount24h.sub(amount);
        } else {
            uint256 before = 0;
            PancakePool.leaveStaking(amount.sub(amount24h));
            uint256 afterBalance = 0;
            uint256 withdrawProfit = afterBalance.sub(before).sub(amount.sub(amount24h));

            totalShares = totalShares.sub(amount.sub(amount24h));
            userTotalDeposit24h[msg.sender] = 0;
            profitInterval = profitInterval.add(withdrawProfit);
        }
        totalDeposit = totalDeposit.sub(amount);
        totalDeposit24h = totalDeposit24h.sub(amount24h);

        vaultStakingToken.transfer(msg.sender, amount);

        delete principal[msg.sender];
        uint256 profit = rewards[msg.sender];
        SafeToken.safeTransferETH(msg.sender, profit);
        SafeToken.safeTransfer(address(GOEN), msg.sender, goenRewards[msg.sender]);
        delete rewards[msg.sender];
        delete userRewardPerSharePaid[msg.sender];
        delete goenRewards[msg.sender];
        delete goenUserRewardPerSharePaid[msg.sender];
        delete balances[msg.sender];
        emit Withdrawn(msg.sender, amount, 0);
    }

    /**
     * @notice The amount of underlying currently owned by the account
     */
    function getUnderlyingBalance()
    public
    returns (uint256) {
        return totalDeposit;
    }

    function withdraw(uint256) 
    external 
    override {
        revert('N/A');
    }

    /**
     * @notice Withdraw underlying ballance of user
     * @param _amount : amount tokens asset user want withdraw
     */
    function withdrawUnderlying(uint256 _amount)
    external
    updateReward(msg.sender)
    updateGOENReward(msg.sender) {

        uint256 amount = Math.min(_amount, principal[msg.sender]);
        //Update userTotalDeposit24h
        uint256 amount24h = userTotalDeposit24h[msg.sender];
        if (amount24h >= amount) {
            userTotalDeposit24h[msg.sender] = amount24h.sub(amount);
            totalDeposit24h = totalDeposit24h.sub(amount);
        } else {
            uint256 leftover = amount.sub(amount24h);
            uint256 before = vaultStakingToken.balanceOf(address(this));
            PancakePool.leaveStaking(leftover);
            uint256 afterBalance = vaultStakingToken.balanceOf(address(this));
            uint256 withdrawProfit = afterBalance.sub(before).sub(amount.sub(amount24h));
            profitInterval = profitInterval.add(withdrawProfit);

            totalShares = totalShares.sub(leftover);
            balances[msg.sender] = balances[msg.sender].sub(leftover);
            userTotalDeposit24h[msg.sender] = 0;
            totalDeposit24h = totalDeposit24h.sub(amount24h);
        }

        vaultStakingToken.transfer(msg.sender, amount);
        
        principal[msg.sender] = principal[msg.sender].sub(amount);
        totalDeposit = totalDeposit.sub(amount);
    }

    /**
     * @notice rewards token earned (BNB from swap and GOEN tokens)
     */
    function getReward()
    public
    override
    nonReentrant
    updateReward(msg.sender)
    updateGOENReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        uint256 goenReward = goenRewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            
        }

        if (goenReward > 0) {
            goenRewards[msg.sender] = 0;
        }

        SafeToken.safeTransferETH(msg.sender, reward);
        GOEN.transfer(msg.sender, goenReward);

        emit ProfitPaid(msg.sender, reward, 0);
    }

    function swapCakeToBNB(uint256 amount) 
    internal
    returns (uint256) {
        address[] memory path = new address[](2);
        uint256 swapBefore = address(this).balance;
        
        path[0] = address(vaultStakingToken);
        path[1] = WBNB;
        PANCAKE_ROUTER.swapExactTokensForETH(amount, 0, path, address(this), block.timestamp);
        uint256 swapAmount = address(this).balance.sub(swapBefore);
        return swapAmount;
    }

    event VaultHarvested(
        uint256 poolReceivedAmount,
        uint256 goenReceivedAmount);

    /**
     * @notice Harvest interest token and BNB
     */
    function harvest()
    public
    override
    notPaused 
    onlyHarvester
    updateReward(address(0))
    updateGOENReward(address(0)) 
    returns (uint256 poolReceivedAmount, uint256 goenReceivedAmount) {
        // GET REWARDS
        uint256 totalDuration = 86400;
        if (lastTimeHarvest != 0) {
            totalDuration = block.timestamp - lastTimeHarvest;
        }
        lastTimeHarvest = block.timestamp;
        
        uint256 before = vaultStakingToken.balanceOf(address(this));
        PancakePool.enterStaking(totalDeposit24h);
        uint256 afterBalance = vaultStakingToken.balanceOf(address(this));
        uint256 withdrawProfit = afterBalance.add(totalDeposit24h).sub(before);

        goenReceivedAmount = goenDistributor.harvest(totalDeposit.sub(totalDeposit24h), totalDuration);
        
        if (profitInterval.add(withdrawProfit) > 0) {
            poolReceivedAmount = swapCakeToBNB(profitInterval.add(withdrawProfit));
            totalBNB += poolReceivedAmount;
        }
        totalGOEN += goenReceivedAmount;

        // // BATCH DEPOSIT
        rewardPerShareStored = rewardPerShare();
        goenRewardPerShareStored = goenRewardPerShare();
        lastTimeBNB = totalBNB;
        lastTimeGOEN = totalGOEN;
        for (uint i = 0; i < depositedUsers.length; i++) {
            address userAddress = depositedUsers[i];
            rewards[userAddress] = earned(userAddress);
            userRewardPerSharePaid[userAddress] = rewardPerShareStored;
            goenRewards[userAddress] = goenEarned(userAddress);
            goenUserRewardPerSharePaid[userAddress] = goenRewardPerShareStored;
            
            uint256 userDeposited = userTotalDeposit24h[userAddress];
            balances[userAddress] = balances[userAddress].add(userDeposited);
            delete userTotalDeposit24h[userAddress];
            delete mappingUser[userAddress];
        }
        totalShares = totalShares.add(totalDeposit24h);
        
        // // CLEAR DEPOSIT
        delete depositedUsers;
        totalDeposit24h = 0;
        profitInterval = 0;

        emit VaultHarvested(poolReceivedAmount, goenReceivedAmount);
    }

    // function emergencyWithdraw()
    // nonReentrant
    // external
    // onlyOwner {
    //     updateVenusFactors();
    //     uint256 underlyingBalance = getUnderlyingBalance();
    //     venusBridge.redeemAll();
    //     venusBridge.withdraw(msg.sender, underlyingBalance);
    //     SafeToken.safeTransfer(address(GOEN), msg.sender, GOEN.balanceOf(address(this)));
    //     SafeToken.safeTransferETH(msg.sender, address(this).balance);
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol';

import '../interfaces/IPancakeRouter02.sol';
import '../interfaces/IPancakePair.sol';
import '../interfaces/IStrategy.sol';
import '../interfaces/IMasterChef.sol';
import '../library/PausableUpgradeable.sol';
import '../library/WhitelistUpgradeable.sol';

abstract contract VaultController is
IVaultController,
PausableUpgradeable,
WhitelistUpgradeable 
{
    using SafeBEP20 for IBEP20;

    // Address of GOEN token
    BEP20 private constant GOEN = BEP20(0xa093D11E9B4aB850B77f64307F55640A75c580d2);

    // Address of Keeper    
    address public keeper;

    // Address of Staking token
    IBEP20 internal vaultStakingToken;

    // TODO: Grap: not used this one yet???
    uint256[49] private __gap;

    // Events    
    event Recovered(address token, uint256 amount);

    /**
     * @notice Validate sender is keeper
     */
    modifier onlyKeeper() {
        require(
            msg.sender == keeper || msg.sender == owner(),
            'VaultController: caller is not the owner or keeper');
        _;
    }

    /**
     * @notice Initialize vault controller from BEP20 token
     * @param _token the staking token
     */
    function __VaultController_init(IBEP20 _token) 
    internal 
    initializer {
        __PausableUpgradeable_init();
        __WhitelistUpgradeable_init();

        // TODO: what is address???
        keeper = 0xce2Be8b93E2d832b51C7a5dd296FAC6c39a67872;
        vaultStakingToken = _token;
    }

    /**
     * @notice Return address of staking token
     */
    function stakingToken()
    external
    view
    override
    returns (address) {
        return address(vaultStakingToken);
    }

    /**
     * @notice Transfer amount tokens to owner
     * @param _token the token which be needed transfering
     * @param _amount the amount of tokens
     */
    function recoverToken(address _token, uint256 _amount)
    external
    virtual
    onlyOwner {
        require(
            _token != address(vaultStakingToken),
            'VaultController: cannot recover underlying token');

        IBEP20(_token).safeTransfer(owner(), _amount);
        emit Recovered(_token, _amount);
    }
}

// SPDX-License-Identifier: MIT


pragma solidity 0.6.12;


interface IGoenDistributor {
    function harvest(uint256 totalValue, uint256 period) external returns (uint256);
    function sendTo(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IMasterChef {
    function cakePerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCakePerShare
        );

    function userInfo(uint256 _pid, address _account) external view returns (uint256 amount, uint256 rewardDebt);

    function poolLength() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeApprove');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeTransfer');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeTransferFrom');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, '!safeTransferETH');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import './IStrategyCompact.sol';

interface IStrategy is IStrategyCompact {
    // rewardsToken
    // function sharesOf(address account) external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    /* ========== Interface ========== */

    function depositAll() external;

    function withdrawAll() external;

    function getReward() external;

    function harvest() external returns (uint256, uint256);

    // function pid() external view returns (uint256);

    // function totalSupply() external view returns (uint256);

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 withdrawalFee);
    event ProfitPaid(address indexed user, uint256 profit, uint256 performanceFee);
    event BunnyPaid(address indexed user, uint256 profit, uint256 performanceFee);
    event Harvested(uint256 profit);
}

// SPDX-License-Identifier: MIT
// Refers:
// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol    
// https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol';

contract GoenToken is
BEP20('Goen Token', 'GOEN') 
{
    // A record of each accounts delegate
    mapping(address => address) internal delegates;

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    // The EIP-712 typehash for the contract's domain
    bytes32 public constant 
    DOMAIN_TYPEHASH = keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    // The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant
    DELEGATION_TYPEHASH = keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

    // A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    // An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate);

    // An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance);

    /**
     * @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
     * @param _to TODO: The address of beneficiary
     * @param _amount TODO: The amount of token going to be minted
     */
    function mint(address _to, uint256 _amount) 
    public 
    onlyOwner {
        uint256 totalSupply = totalSupply();

        require(
            totalSupply + _amount < 555555555 ether,
            'GOEN::mint: exceeding the permitted limits');

        _mint(_to, _amount);
        _moveDelegates(address(0), delegates[_to], _amount);
    }

    /**
     * @notice burn `_amount` token.
     * @param _amount amount of token that system going to burn
     */
    function burn(uint256 _amount) public onlyOwner {
        _burn(_msgSender(), _amount);
        _moveDelegates(delegates[_msgSender()], address(0), _amount);
    }

    /**
     * @notice Burn from `_account` for `account' token.
     * @param _account address of the account that system will burn
     * @param _amount amount of token that system going to burn
     */
    function burnFrom(address _account, uint256 _amount)
    public 
    onlyOwner {
        _burnFrom(_account, _amount);
        _moveDelegates(delegates[_account], address(0), _amount);
    }
    
    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param _delegator The address to get delegatee for
     */
    function goenDelegates(address _delegator)
    external
    view
    returns (address) {
        return delegates[_delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `_delegatee`
     * @param _delegatee The address to delegate votes to
     */
    function goenDelegate(address _delegatee)
    external {
        return _delegate(msg.sender, _delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param _delegatee The address to delegate votes to
     * @param _nonce The contract state required to match the signature
     * @param _expiry The time at which to expire the signature
     * @param _v The recovery byte of the signature
     * @param _r Half of the ECDSA signature pair
     * @param _s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address _delegatee,
        uint256 _nonce,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this))
        );

        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, _delegatee, _nonce, _expiry));

        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));

        address signatory = ecrecover(digest, _v, _r, _s);

        require(signatory != address(0), 'GOEN::delegateBySig: invalid signature');
        require(_nonce == nonces[signatory]++, 'GOEN::delegateBySig: invalid nonce');
        require(now <= _expiry, 'GOEN::delegateBySig: signature expired');

        return _delegate(signatory, _delegatee);
    }

    /**
     * @notice Gets the current votes balance for `_account`
     * @param _account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address _account)
    external
    view 
    returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[_account];
        return nCheckpoints > 0 ? checkpoints[_account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @notice Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _account The address of the account to check
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address _account, uint256 _blockNumber)
    external 
    view 
    returns (uint256) {
        require(
            _blockNumber < block.number,
            'GOEN::getPriorVotes: not yet determined');

        uint32 nCheckpoints = numCheckpoints[_account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[_account][nCheckpoints - 1].fromBlock <= _blockNumber) {
            return checkpoints[_account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[_account][0].fromBlock > _blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            // ceil, avoiding overflow
            uint32 center = upper - (upper - lower) / 2; 

            Checkpoint memory cp = checkpoints[_account][center];
            if (cp.fromBlock == _blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[_account][lower].votes;
    }

    /**
     * @notice Delegate votes to a delegatee, all the balance of delegator will become
     delegatee votes
     * @param _delegator Address of delegator
     * @param _delegatee Address of delegatee
     */
    function _delegate(address _delegator, address _delegatee)
    internal {
        address currentDelegate = delegates[_delegator];
        uint256 delegatorBalance = balanceOf(_delegator);

        delegates[_delegator] = _delegatee;
        emit DelegateChanged(_delegator, currentDelegate, _delegatee);

        _moveDelegates(currentDelegate, _delegatee, delegatorBalance);
    }

    /**
     * @notice Move delegate votes from an address to another
     * @param _srcRep Source representative
     * @param _dstRep Destination representative
     * @param _amount Amount of votes that going to move delegate
     */
    function _moveDelegates(
        address _srcRep,
        address _dstRep,
        uint256 _amount
    ) internal {
        if (_srcRep != _dstRep && _amount > 0) {
            if (_srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[_srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[_srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(_amount);
                _writeCheckpoint(_srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (_dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[_dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[_dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(_amount);
                _writeCheckpoint(_dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /**
     * @notice Write the checkpoint for delegate vote changed event
     * @param _delegatee The delegatee of votes
     * @param _nCheckpoints Delegatee's Number of checkpoint
     * @param _oldVotes Old amount of votes
     * @param _newVotes New amount of votes
     */
    function _writeCheckpoint(
        address _delegatee,
        uint32 _nCheckpoints,
        uint256 _oldVotes,
        uint256 _newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number, 
            'GOEN::_writeCheckpoint: block number exceeds 32 bits');

        if (_nCheckpoints > 0 &&checkpoints[_delegatee][_nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[_delegatee][_nCheckpoints - 1].votes = _newVotes;
        } else {
            checkpoints[_delegatee][_nCheckpoints] = Checkpoint(blockNumber, _newVotes);
            numCheckpoints[_delegatee] = _nCheckpoints + 1;
        }

        emit DelegateVotesChanged(_delegatee, _oldVotes, _newVotes);
    }

    /**
     * @notice Cast uint256 to uint32
     * @param _n Number that we need to convert
     * @param _errorMessage Error message in case casting fail   
     * @return uint32 value of the input _n
     */
    function safe32(uint256 _n, string memory _errorMessage) 
    internal
    pure
    returns (uint32) {
        require(_n < 2**32, _errorMessage);
        return uint32(_n);
    }

    /**
     * @notice Get the chainID of the chainnet for delegateBySig
     * @return chainId of chain net
     */
    function getChainId()
    internal
    pure
    returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import '../../access/Ownable.sol';
import '../../GSN/Context.sol';
import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

abstract contract PausableUpgradeable is OwnableUpgradeable {
    uint256 public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused() {
        require(!paused, 'PausableUpgradeable: cannot be performed while the contract is paused');
        _;
    }

    function __PausableUpgradeable_init() internal initializer {
        __Ownable_init();
        require(owner() != address(0), 'PausableUpgradeable: owner must be set');
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) {
            return;
        }

        paused = _paused;
        if (paused) {
            lastPauseTime = now;
        }

        emit PauseChanged(paused);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract WhitelistUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _whitelist;
    bool private _disable; // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted() {
        require(_disable || _whitelist[msg.sender], 'Whitelist: caller is not on the whitelist');
        _;
    }

    function __WhitelistUpgradeable_init() internal initializer {
        __Ownable_init();
    }

    function isWhitelist(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        _whitelist[_address] = _on;

        emit Whitelisted(_address, _on);
    }

    function disableWhitelist(bool disable) external onlyOwner {
        _disable = disable;
        if (disable) {
            emit DisableWhitelist();
        } else {
            emit EnableWhitelist();
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import './IVaultController.sol';

interface IStrategyCompact is IVaultController {
    /* ========== Dashboard ========== */

    function balance() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function principalOf(address account) external view returns (uint256);

    function withdrawableBalanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    // function priceShare() external view returns (uint256);

    // function depositedAtOf(address account) external view returns (uint256);

    // function rewardsToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IVaultController {
    function stakingToken() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}