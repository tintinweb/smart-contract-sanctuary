/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

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

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PRBReaserveStaking is Ownable{
    using SafeMath for uint256;
    
    uint256 stakeID;
    
    IBEP20 public PRBToken;
    uint256 public APYdays;
    uint256 public APYPercent;
    uint256 public reserve;
    uint256 public depositFee;
    uint256 public withdrawFee;
    address public walletAddress;
    
    struct details{
        uint256 amount;
        uint256 stakingTime;
        uint256 withdrawTime;
        uint256 stakingID;
        uint256 APYpercentage;
        uint256 rewardReserve;
        uint256 rewardingTime;
        bool claim;
    }
    
    struct _StakeingId{
        uint256[] stakingId;
    }
    
    mapping(address => _StakeingId) stakings;
    mapping(address => mapping(uint256 => details)) public userDetails;
    
    event Stake(address staker, uint256 stakeTime, uint256 stakeID, uint256 stakeAmount);
    event UnStake(address staker, uint256 withdrawTime, uint256 stakeID, uint256 withdrawAmount);
    event AdminDeposit(address Owner, uint256 amount, uint256 depositTime);
    event SetAPYpercent(address Owner, uint256 percentage);
    event FailSafe(address receiver, address token, uint256 amount);
    event SetDepositFee(address owner, uint256 depositFee);
    event SetWithdrawFee(address Owner, uint256 withdrawFee);
    event SetWalletAddress(address owner, address newWallet);
    event ClaimReward(address staker,uint256 rewardAmount );

    
    constructor(address _PRBToken, uint256 _APYdays, uint256 _APYPercent,address _Wallet,uint256 _depositFee, uint256 _withdrawFee) {
        require(_PRBToken != address(0),"Staking :: Zero address");
        PRBToken = IBEP20(_PRBToken);
        APYdays = _APYdays;
        APYPercent = _APYPercent;
        walletAddress = _Wallet;
        depositFee = _depositFee;
        withdrawFee = _withdrawFee;
    }
    
    function setDepositFee(uint256 _depositFee)external onlyOwner {
        depositFee = _depositFee;
        emit SetDepositFee(msg.sender, _depositFee);
    }
    
    function setWithdrawFee(uint256 _withdrawFee)external onlyOwner {
        withdrawFee = _withdrawFee;
        emit SetWithdrawFee(msg.sender, _withdrawFee);
    }
    
    function updateWallet(address _newWallet)external onlyOwner{
        require(_newWallet != address(0),"wallet address not a zero address");
        walletAddress = _newWallet;
        emit SetWalletAddress(msg.sender, _newWallet);
    }
    
    function stake(uint256 amount)external payable returns(uint256){
        require(amount > 0,"Staking :: amount must greater than zero");
        require(msg.value >= depositFee,"Staking :: less deposit Fee");
        stakeID++;
        uint256 reward = amount.mul(APYPercent).div(100);
        
        reserve = reserve.sub(reward,"stake :: staking account reached");
        details storage user = userDetails[msg.sender][stakeID];
        user.amount = amount;
        user.stakingTime = block.timestamp;
        user.stakingID = stakeID;
        user.rewardReserve = reward;
        user.APYpercentage = APYPercent;
        user.rewardingTime = block.timestamp;
        stakings[msg.sender].stakingId.push(stakeID);
        
        PRBToken.transferFrom(msg.sender, address(this),amount);
        
        require(payable(walletAddress).send(msg.value),"Amount not sendt in wallet");
        
        emit Stake(msg.sender, block.timestamp, stakeID, amount);
        
        return stakeID;
    }
    
    function unStake(uint256 _stakeID)external payable returns(bool) {
        details storage user = userDetails[msg.sender][stakeID];
        require(user.stakingTime > 0,"Unstake :: Account not found");
        require(!user.claim,"Unstake :: already claimed");
        require(msg.value >= withdrawFee,"Staking :: less Withdraw Fee");
        claimReward(_stakeID, msg.sender);
        user.withdrawTime = block.timestamp;
        user.rewardingTime = block.timestamp;
        user.claim = true;
        
        uint256 reward = calculateReward(_stakeID, msg.sender);
        if(reward > user.rewardReserve) reward = user.rewardReserve;
        reserve = reserve.add((user.rewardReserve.sub(reward)));
        
        PRBToken.transfer(msg.sender, user.amount.add(reward));
        
        require(payable(walletAddress).send(msg.value),"Amount not sendt in wallet");
        
        emit UnStake(msg.sender, block.timestamp, _stakeID, user.amount.add(reward));
        user.amount = 0;
        
        return true;
    }
    
    function setAPYpercent(uint256 _APYPercent)external onlyOwner {
        APYPercent = _APYPercent;
        emit SetAPYpercent(msg.sender, _APYPercent);
    }
    
    function calculateReward(uint256 _stakeID, address _account)public view returns(uint256 reward){
        details storage user = userDetails[_account][_stakeID];
        if(user.stakingTime == user.rewardingTime && user.stakingTime.add(31536000) <= block.timestamp ){
            reward = user.rewardReserve;
        } else {
            uint256[3] memory localVar;
            localVar[0] = (block.timestamp).sub(user.rewardingTime);
            localVar[1] = (user.APYpercentage).mul(1e12).div(APYdays);
            reward = user.amount.mul(localVar[0]).mul(localVar[1]).div(100).div(1e12).div(86400);
        }
    }
    
    function claimReward(uint256 _stakeID, address _account)public {
        details storage user = userDetails[_account][_stakeID];
        require(user.amount > 0,"Unstake :: Account not found");
        uint256 reward = calculateReward(_stakeID, _account);
        user.rewardingTime = block.timestamp;
        user.rewardReserve = user.rewardReserve.sub(reward,"Claiming Amount reached");
        PRBToken.transfer(msg.sender, reward);
        
        emit ClaimReward(msg.sender, reward );
    }
    
    function stakingDay(uint256 _stakeID, address _account)public view returns(uint256 stakingDays){
        stakingDays = (block.timestamp).sub(userDetails[_account][_stakeID].stakingTime).div(86400);
    }
    
    function stakingId(address _staker) public view returns(uint256[] memory){
        return stakings[_staker].stakingId;
    }
    
    function adminDeposit(uint256 amount) external onlyOwner{
        reserve = reserve.add(amount);
        PRBToken.transferFrom(msg.sender, address(this),amount);
        
        emit AdminDeposit(msg.sender, amount, block.timestamp);
    }
    
    function failSafe(address token, address to, uint256 amount)external onlyOwner{
        if(token == address(0x0)){
            payable(to).transfer(amount);
        } else  {
            require(PRBToken == IBEP20(token),"FailSafe :: PRBtoken only");
            PRBToken.transfer(to, amount);
        }
        emit FailSafe(to, token, amount);
    }
}