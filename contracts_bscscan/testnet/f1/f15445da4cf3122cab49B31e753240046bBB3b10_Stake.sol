/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.4;

interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}
interface Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function WETH() external pure returns (address);
}

contract Stake {
    
    struct user {
        uint depositAmount;
        uint earnings;
        bool status;
        uint stakeDuration;
        uint rewards;
        uint types;
    }
    
    IBEP20 public token;
    address public owner;
    uint public rewardPercent = 15;
    bool public lockStatus;
    Router public router;
    
    event Staking(address indexed from,uint _type,uint amount,uint time);
    event Withdraw(address indexed from,uint _type,uint amount,uint reward,uint time);
    
    constructor(address _token,address _owner,address _router) {
        token = IBEP20(_token);
        owner = _owner;
        router = Router(_router);
    }
    
      /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
    /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, " Contract Locked");
        _;
    }
    
    mapping(uint => uint)public stakeDays;
    mapping(address => user)public users;
    
    function addToken(uint amount)public onlyOwner {
        token.transferFrom(msg.sender,address(this),amount);
    }
    
    function updateStakeDays(uint _stake1,uint _stake2)public onlyOwner{
        stakeDays[1] = _stake1;
        stakeDays[2] = _stake2;
    }
    
    function updatePercent(uint _percent)public onlyOwner {
        rewardPercent = _percent;
    }
    
    function stake(uint _type,uint amount) public isLock {
        require(_type == 1 || _type == 2,"Incorrect type");
        require(stakeDays[_type] > 0,"Not yet set");
        require(amount > 0,"Amount not be zero");
        user storage userInfo = users[msg.sender];
        require(userInfo.status == false,"Already staked");
        token.transferFrom(msg.sender,address(this),amount);
        userInfo.types = _type;
        userInfo.depositAmount = amount;
        userInfo.stakeDuration = block.timestamp+stakeDays[_type];
        userInfo.status = true;
        userInfo.earnings = 0;
        userInfo.rewards = amount*rewardPercent/100;
        emit Staking(msg.sender,_type, amount,block.timestamp);
    }
    
    function unStake(uint _type) public isLock {
        user storage userInfo = users[msg.sender];
        require(userInfo.types == _type,"Incorrect type");
        require(userInfo.status == true,"Not yet deposit");
        require(block.timestamp >= userInfo.stakeDuration,"Duration not complete");
        uint amount = (userInfo.rewards*1e18/31536000*stakeDays[_type])/1e18;
        token.transfer(msg.sender,userInfo.depositAmount);
        _swap(msg.sender,amount);
        userInfo.earnings = amount;
        userInfo.status = false;
        userInfo.depositAmount = 0;
        userInfo.types = 0;
        emit Withdraw(msg.sender,_type,userInfo.depositAmount,amount,block.timestamp);
    }
    
    function _swap(address _user,uint _amount)internal {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(router.WETH());
       token.approve(address(router),_amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0, 
            path,
            _user,
            block.timestamp
        );
    }
    
    function failSafe(address to,uint amount) public onlyOwner {
        require(to != address(0),"Invalid address");
        require(amount <= token.balanceOf(address(this)),"Invalid amount");
        token.transfer(msg.sender,amount);
    }
    
    
}