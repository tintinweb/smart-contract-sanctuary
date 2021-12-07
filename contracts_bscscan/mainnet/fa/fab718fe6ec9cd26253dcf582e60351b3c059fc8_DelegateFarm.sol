pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./BEP20.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./IPancakeChef.sol";
import "./IRobiniaChef.sol";
import "./ReentrancyGuard.sol";

contract DelegateFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct UserInfo {
        uint256 amount;
        uint256 depositBlock;
        uint256 rewardDebt;
    }

    struct WithdrawFee {
        uint256 blockUntil;
        uint256 feeBP;
    }

    address public rewardAddr;
    address public feeAddr;
    address private operator;

    IPancakeChef private pancakeChef;
    IRobiniaChef private robiniaChef;
    uint256 public poolId;
    uint256 public pancakePoolId;

    IBEP20 private userStakingToken;
    BEP20 private stakingToken;
    IBEP20 private robiniaToken;
    IBEP20 private earningToken;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public totalStakedAmount;
    uint256 public totalTokenHarvested;
    uint256 public tokenPerShare;
    uint256 public lastUpdateBlock;
    uint256 public depositFeeBP;
    uint256 public maxDepositFeeBP = 1000;
    uint256 public maxWithdrawFeeBP = 1000;
    uint256[] public withdrawFeeLevels = [300,100,50];
    mapping(address => UserInfo) public userInfo;

    constructor(address _rewards, address _fee, IPancakeChef _pancake, IRobiniaChef _robinia,
    IBEP20 _userStaking, BEP20 _staking, IBEP20 _robiniaToken, uint256 _rbsPool, address _op ,IBEP20 _earning) {
        rewardAddr = _rewards;
        feeAddr = _fee;
        pancakeChef = _pancake;
        userStakingToken = _userStaking;
        robiniaChef = _robinia;
        stakingToken = _staking;
        robiniaToken = _robiniaToken;
        poolId = _rbsPool;
        operator = _op;
        earningToken = _earning;
        initialApprovals();
    }

    // user function
    function deposit(uint256 _pid,uint256 _amount) public nonReentrant {

        require(msg.sender != address(0),"Sender is zero.");

        UserInfo storage user = userInfo[msg.sender];
        updateShares(false, 0);
        if(user.amount > 0) {


            uint256 pending = user.amount.mul(tokenPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeTransferFunds(msg.sender, pending);
            }

        }

        if(_amount > 0) {
            // get cakes from user
            uint256 beforeCake = userStakingToken.balanceOf(address(this));
            userStakingToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 afterCake = userStakingToken.balanceOf(address(this));
            uint256 netTokenTransferred = afterCake.sub(beforeCake);
            uint256 fee = netTokenTransferred.mul(depositFeeBP).div(10000);
            uint256 netTokenStaked = netTokenTransferred.sub(fee);

            require((netTokenStaked.add(fee)) == netTokenTransferred, "Error at fee calculation.");
            userStakingToken.safeTransfer(feeAddr, fee);

            pancakeDeposit(_pid,netTokenStaked);


            stakingToken.mint(netTokenStaked);
            robiniaChef.deposit(poolId, netTokenStaked, address(0));
            user.amount = user.amount.add(netTokenStaked);
            user.depositBlock = block.number;
            totalStakedAmount = totalStakedAmount.add(netTokenStaked);
        }

        user.rewardDebt = user.amount.mul(tokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid,_amount);
    }

    // user function
    function withdraw(uint256 _pid,uint256 _amount) public nonReentrant {

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updateShares(false, 0);
        uint256 pendingRobinia = user.amount.mul(tokenPerShare).div(1e12).sub(user.rewardDebt);
        if(pendingRobinia > 0) {
            safeTransferFunds(msg.sender, pendingRobinia);
        }

        if(_amount > 0) {


            updateShares(true, _amount);
            totalStakedAmount = totalStakedAmount.sub(_amount);
            user.amount = user.amount.sub(_amount);



            uint256 beforeCakeBalance = userStakingToken.balanceOf(address(this));
            pancakeWithdraw(_pid,_amount);
            uint256 afterCakeBalance = userStakingToken.balanceOf(address(this));
            uint256 netWithdrawAmount = afterCakeBalance.sub(beforeCakeBalance);

            uint256 withdrawFeeBP = getWithdrawFee(user.depositBlock);
            if(withdrawFeeBP > 0) {
                uint256 withdrawFee = netWithdrawAmount.mul(withdrawFeeBP).div(10000);
                uint256 netUserWithdraw = netWithdrawAmount.sub(withdrawFee);
                userStakingToken.safeTransfer(feeAddr, withdrawFee);
                userStakingToken.safeTransfer(msg.sender, netUserWithdraw);
            } else {

                userStakingToken.safeTransfer(msg.sender, netWithdrawAmount);
            }
        }

        user.depositBlock = block.number;
        user.rewardDebt = user.amount.mul(tokenPerShare).div(1e12);

        emit Withdraw(msg.sender,_pid, _amount);
    }

    //// internal functions

    function pendingReward(address _user) public view returns(uint256){
        UserInfo storage u = userInfo[_user];
        if(tokenPerShare == 0) {
            return 0;
        }
        uint256 pendingBalance = robiniaChef.pendingRobinia(poolId, address(this));
        uint256 newShare = tokenPerShare;
        if(pendingBalance > 0) {
            newShare = tokenPerShare.add(pendingBalance.mul(1e12).div(totalStakedAmount));
        }
        return u.amount.mul(newShare).div(1e12).sub(u.rewardDebt);
    }


    function updateShares(bool isWithdraw, uint256 _amount) internal {
        uint256 rbsBalanceBefore = robiniaToken.balanceOf(address(this));

        if(totalStakedAmount == 0) {
            lastUpdateBlock = block.number;
            return;
        }
        if(isWithdraw) {
            uint256 beforeWithdraw = stakingToken.balanceOf(address(this));
            robiniaChef.withdraw(poolId, _amount);
            uint256 afterWithdraw = stakingToken.balanceOf(address(this));
            uint256 netToBurn = afterWithdraw.sub(beforeWithdraw);
            stakingToken.transfer(BURN_ADDRESS, netToBurn);
        } else {
            robiniaChef.deposit(poolId, 0, address(0));
        }
        uint256 rbsBalanceAfter = robiniaToken.balanceOf(address(this));
        uint256 harvestedNet = rbsBalanceAfter.sub(rbsBalanceBefore);
        totalTokenHarvested = totalTokenHarvested.add(harvestedNet);
        tokenPerShare = tokenPerShare.add(harvestedNet.mul(1e12).div(totalStakedAmount));
        lastUpdateBlock = block.number;
    }

    function pancakeDeposit(uint256 _pid , uint256 _amount) internal {
        pancakeChef.deposit(_pid ,_amount);
        uint256 currCake = earningToken.balanceOf(address(this));
        earningToken.safeTransfer(rewardAddr,currCake);
    }

    function pancakeWithdraw(uint256 _pid,uint256 _amount) internal {
        pancakeChef.withdraw(_pid,_amount);
        uint256 currCake = earningToken.balanceOf(address(this));
        earningToken.safeTransfer(rewardAddr,currCake);
    }


    function initialApprovals() internal {
        //approve cakes for pancakeswap masterchef
        userStakingToken.approve(address(pancakeChef), ~uint256(0));

        //approve staking token for robinia masterchef
        stakingToken.approve(address(robiniaChef), ~uint256(0));
    }


    function safeTransferFunds(address user, uint256 amount) internal returns(uint256){
        uint256 robiniaSwapBal = robiniaToken.balanceOf(address(this));
        if (amount > robiniaSwapBal) {
            robiniaToken.transfer(user, robiniaSwapBal);
            emit TokenTransfered(user,amount,robiniaSwapBal);
            return robiniaSwapBal;
        } else {
            robiniaToken.transfer(user, amount);
            emit TokenTransfered(user,amount,amount);
            return amount;
        }
    }

    //// view functions


    function getWithdrawFee(uint256 depositBlock) public view returns(uint256) {
        uint256 currentBlock = block.number;
        uint256 netBlocks = currentBlock.sub(depositBlock);
        if(netBlocks < 28800) {
            return withdrawFeeLevels[0];
        } else if(netBlocks < 57600) {
            return withdrawFeeLevels[1];
        } else if(netBlocks < 86400) {
            return withdrawFeeLevels[2];
        } else {
            return 0;
        }
    }

    function getWithdrawalFeeLevels() public view returns(uint256,uint256,uint256) {
        return (withdrawFeeLevels[0], withdrawFeeLevels[1], withdrawFeeLevels[2]);
    }

    function getUserStakingToken() public view returns(IBEP20) {
        return userStakingToken;
    }

    function getPancakeChef() public view returns(IPancakeChef) {
        return pancakeChef;
    }

    function getRobiniaChef() public view returns(IRobiniaChef) {
        return robiniaChef;
    }

    function getStakingToken() public view returns(IBEP20) {
        return stakingToken;
    }

    function getRobiniaToken() public view returns(IBEP20) {
        return robiniaToken;
    }

    /// OWNER FUNCTIONS

    function setWithdrawFeeLevels(uint256 level1, uint256 level2, uint256 level3) public onlyOwner {
        require(level1 <= maxWithdrawFeeBP, "level1 too high");
        require(level2 <= maxWithdrawFeeBP, "level1 too high");
        require(level3 <= maxWithdrawFeeBP, "level1 too high");

        withdrawFeeLevels[0] = level1;
        withdrawFeeLevels[1] = level2;
        withdrawFeeLevels[2] = level3;
    }

    //in case of changing the pool on robinia masterchef we can change the pool id from here.
    function setRobiniaPoolId(uint256 _id) public onlyOwner {
        poolId = _id;
    }

    function setDepositFee(uint256 _fee) public onlyOwner {
        require(_fee <= maxDepositFeeBP, "Deposit fee too high");
        depositFeeBP = _fee;
    }

    /// OPERATOR EMERGENCY FUNCTIONS

    function withdrawCakes(uint256 _pid,uint256 _amount) public onlyOperator {
        pancakeChef.withdraw(_pid,_amount);
        uint256 cakeBalance = userStakingToken.balanceOf(address(this));
        require(_amount <= cakeBalance, "Cake balance is lower");
        userStakingToken.safeTransfer(operator, _amount);
    }

    function withdrawRBSStaking(uint256 _amount, uint256 _pid) public onlyOperator {
        robiniaChef.withdraw(_pid, _amount);
        uint256 stakingBalance = stakingToken.balanceOf(address(this));
        require(_amount <= stakingBalance, "Staking balance is low");
        stakingToken.transfer(operator, _amount);
    }

    function transferStakingOwnership(address newOwner) public onlyOperator {
        require(newOwner != address(0), "New owner cant be zero.");
        stakingToken.transferOwnership(newOwner);
    }

    // This is a delegate farm contract. So there shouldnt be any tokens inside of this contract.
    // If there is any errors or smth stucked inside, owner can withdraw these tokens.
    // User funds are safe because these funds should be inside the pancake masterchef.
    function releaseStuckedBalances(IBEP20 tokenContract, uint256 amount) public onlyOperator {
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance >= amount, "Amount is higher.");
        tokenContract.transfer(msg.sender, amount);
    }
    // events

    modifier onlyOperator {
        require(msg.sender == operator, "Only operator");
        _;
    }

    event TokenTransfered(address indexed user, uint256 amount, uint256 netAmount);
    event Deposit(address indexed user, uint256 _pid, uint256 totalCake);
    event Withdraw(address indexed user,uint256 _pid, uint256 amount);
}