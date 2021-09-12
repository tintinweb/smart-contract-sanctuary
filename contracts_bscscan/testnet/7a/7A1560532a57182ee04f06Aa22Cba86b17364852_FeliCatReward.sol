pragma solidity 0.6.12;


import "./IBEP20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

//SPDX-License-Identifier: UNLICENSED

interface IFeliCatRouter{
    function getUserVolumePower(address user) external view returns (uint256 power);
    function getTotalVolumePower() external view returns (uint256 totalPower);
}

contract FeliCatReward is Ownable {
    
    using SafeMath for uint256;
    using Address for address;
    
    // user's last withdraw time
    mapping(address => uint256) private _withdrawTime;
    
    uint256 public _startBlock;
    
    // 7 days
    // uint256 private _maxWithdrawLimitBlock = 201600;
    uint256 private _maxWithdrawLimitBlock = 200;
    
    IBEP20 public _feliCatToken;
    
    IFeliCatRouter public immutable _feliCatRouter;
    
    event Withdraw(address indexed user, uint256 amount);
    
    constructor(IBEP20 feliCatToken,uint256 startBlock) public {
        _feliCatToken = feliCatToken;
        _startBlock = startBlock;
        //FeliCatSwap Testnet Router 0x4175c9984C902444c829B0Ba6f28035aA07943f6s
        IFeliCatRouter feliCatRouter = IFeliCatRouter(0x4175c9984C902444c829B0Ba6f28035aA07943f6);
        _feliCatRouter = feliCatRouter;
    }
    
    function pendingReward(address _user) public view returns (uint256) {
        
        if(_user == address(0)){
            return 0;
        }
        if(block.number < _startBlock){
            return 0;
        }
        uint256 userVolumePower = userCurrentVolumePower(_user);
        uint256 totalVolumePower = currentTotalVolumePower();
        uint256 totalReward = getTotalFelCatReward();
        if(totalVolumePower == 0){
            return 0;
        }
        uint256 rate = totalReward.mul(1000).div(totalVolumePower);
        uint256 reward = rate.mul(userVolumePower).div(1000);
        return reward;
    }
    function currentTotalVolumePower() public view returns (uint256) {
        
        return _feliCatRouter.getTotalVolumePower();
    }
    
    function userCurrentVolumePower(address _user) public view returns (uint256) {
        return _feliCatRouter.getUserVolumePower(_user);
    }
    
    function withdrawReward(address _user) external {
        
        require(_user != address(0),"no zero address");
        require(block.number > _startBlock,"not start");
        require(block.number.sub(_startBlock) >= _maxWithdrawLimitBlock, "Start time is less than 7 days");
        require(block.number.sub(_withdrawTime[_user]) >= _maxWithdrawLimitBlock, "Can only be claimed once every seven days");
        
        uint256 userVolumePower = userCurrentVolumePower(_user);
        uint256 totalVolumePower = currentTotalVolumePower();
        uint256 totalReward = getTotalFelCatReward();
        require(userVolumePower > 0, "user power is 0");
        require(totalVolumePower > 0, "total power is 0");
        require(totalReward > 0, "total reward Felicat token is 0");
        
        uint256 rate = totalReward.mul(1000).div(totalVolumePower);
        uint256 withdrawAmount = rate.mul(userVolumePower).div(1000);
        require(withdrawAmount > 0 && withdrawAmount < totalReward,"safe math overflow");
        
        _feliCatToken.transferFrom(address(this),_user,withdrawAmount);
        _withdrawTime[_user] = block.number;
        emit Withdraw(_user,withdrawAmount);
    }
    
    function getTotalFelCatReward() public view returns (uint256){
        return _feliCatToken.balanceOf(address(this));
    }
    
    function getUserlastWithdrawBlock(address _user) external view returns (uint256){
        return _withdrawTime[_user];
    }
    
    function maxWithdrawLimitBlock() external view returns (uint256){
        return _maxWithdrawLimitBlock;
    }
    function setMaxWithdrawLimitBlock(uint256 maxBlock) external onlyOwner {
        _maxWithdrawLimitBlock = maxBlock;
    }
    
    
}