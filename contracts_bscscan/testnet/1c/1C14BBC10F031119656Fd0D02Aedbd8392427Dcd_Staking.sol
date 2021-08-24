/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-10
*/

pragma solidity <=0.8.1;

interface ERC {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Math {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Staking is Math {
    ERC public smartContract;
    ERC public vSmartContract;
    address public veraswap;
    address public admin;

    modifier isAdmin(){
        require(msg.sender == admin,"Access Error");
        _;
    }

    constructor() public{
        admin = msg.sender;
    }
    
    struct User {
        uint256 currentStake;
        uint256 rewardsClaimed;
        uint256 time;
        uint256 rFactor;
    }

    mapping(address => mapping(address => User)) public users;
    mapping(address => uint256) public rFactor; // 18 decimal (reward % per second)
    mapping(address => uint256) public decimals;
    mapping(address => uint256) public lockTime;
    
    function stake(uint256 _stakeAmount,address _contractAddress) public returns(bool){
        smartContract = ERC(_contractAddress);
        require(smartContract.allowance(msg.sender,address(this))>=_stakeAmount,"Allowance Exceeded");
        User storage u = users[msg.sender][_contractAddress];
        require(u.currentStake == 0,"Already Staked");
        u.currentStake = _stakeAmount;
        u.time = block.timestamp;
        u.rFactor = rFactor[_contractAddress];
        smartContract.transferFrom(msg.sender,address(this),_stakeAmount);
        return true;
    }
    
    function claim(address _contractAddress) public returns(bool){
        smartContract = ERC(_contractAddress);
        vSmartContract = ERC(veraswap);
        User storage u = users[msg.sender][_contractAddress];
        require(Math.add(u.time,lockTime[_contractAddress]) < block.timestamp,"Not Matured Yet");
        uint256 mFactor = 10 ** Math.sub(18,decimals[_contractAddress]);
        uint256 interest = Math.sub(block.timestamp,u.time);
                interest = Math.mul(interest,mFactor);
                interest = Math.mul(u.currentStake,interest);
                interest = Math.mul(interest,u.rFactor);
                interest = Math.div(interest,10 ** 18);
        u.rewardsClaimed = Math.add(u.rewardsClaimed,interest);
        smartContract.transfer(msg.sender,u.currentStake);
        vSmartContract.transfer(msg.sender,interest);
        u.currentStake = 0;
        u.time = 0;
    }
    
    function fetchUnclaimed(address _user,address _contractAddress) public view returns(uint256 claimableAmount){
        User storage u = users[_user][_contractAddress];
        require(u.currentStake > 0,"No Stake");
        uint256 mFactor = 10 ** Math.sub(18,decimals[_contractAddress]);
        uint256 interest = Math.sub(block.timestamp,u.time);
                interest = Math.mul(interest,mFactor);
                interest = Math.mul(u.currentStake,interest);
                interest = Math.mul(interest,u.rFactor);
                interest = Math.div(interest,10 ** 18);
        return interest;
    }
    
    function updateReward(address _contractAddress,uint256 _rFactor) public isAdmin returns(bool){
        uint256 rewardFactor = Math.mul(_rFactor,10 ** 9);
                rewardFactor = Math.div(rewardFactor,3154);
        rFactor[_contractAddress] = rewardFactor;
        return true;
    }
    
    function updateDecimals(address _contractAddress, uint256 _decimal) public isAdmin returns(bool){
        decimals[_contractAddress] = _decimal;
        return true;
    }
    
    function updateLockTime(address _contractAddress,uint256 _newTime) public isAdmin returns(bool){
        lockTime[_contractAddress] = _newTime;
        return true;
    }
    
    function revokeOwnership(address _newAdmin) public isAdmin returns(bool){
        admin = _newAdmin;
        return true;
    }
    
    function updateVeraSwapContract(address _contractAddress) public isAdmin returns(bool){
        veraswap = _contractAddress;
        return true;
    }
    
    function fetchCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
    
}