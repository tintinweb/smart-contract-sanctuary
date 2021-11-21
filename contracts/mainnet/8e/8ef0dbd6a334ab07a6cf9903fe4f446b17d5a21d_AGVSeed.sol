/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract AGVSeed {

    address public owner;
    address private AGV_address;
    uint256 private tokenGenerateTime;
    uint256 private vestingDuration;      // In months
    uint256 private vestingTimeStartFrom;  //  Claim cannot start before vestingTimeStart from 
    uint256 public totalInvestment;
    uint256 public totalRelease;
    uint256 public tgePercentage;
    uint256 public claimPercentage;
    
    struct Investor {
        uint256 lockedAgv;        //  Locked balance
        uint256 releasedAgv;       // relesed balance
        uint256 previousClaimTime;
        uint256 claimCounter;
        bool isTokenGenerated;
        uint256 balance;     // remaining balance
    }

    mapping(address => Investor) public investors;
    
    event AddInvestor(address indexed investor, uint256 indexed amount);
    event Claim(address indexed sender, address indexed investor, uint256 indexed amount);
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    constructor() {
        tokenGenerateTime = 1640217600; //23 dec 2021
        vestingTimeStartFrom = 1643587200; //31 jan 2022
        vestingDuration = 24;
        tgePercentage = 5;
        claimPercentage = 396;
        owner = _msgSender();
        AGV_address = 0xf4F618Eff5eF36Cde2FCa4FBD86554c62Fb1382B;
    }
    
    modifier isValidAddress(address _address ){
        require(_address != address(0),"Address cannot be empty");
        _;
    }
    
    modifier isInvestorExist(){
        require(investors[_msgSender()].lockedAgv != 0," Invalid investor. ");
        _;
    }
    
    modifier isValidAmount(uint256 _amount){
        require(_amount != 0," Amount not found. ");
        _;
    }
    
    modifier isValidDate(uint256 _date){
        require(_date != 0," Date is not valid. ");
        _;
    }
    
    modifier onlyOwner() {
        require(owner == _msgSender() , "Only owner access");
        _;
    }
    
    function isTokenGenerateEventStarted() public view returns(bool){
        if(block.timestamp > tokenGenerateTime)
            return true;       // if date is after TGE time
        else
            return false;      // if date is before TGE time
    }
    
    function isVestingTimeStarted() public view returns(bool){
        if(block.timestamp > vestingTimeStartFrom)
            return true;       // vesting Time started
        else
            return false;      // or not
    }
    
    function modifyVestingDuration(uint256 _month) public onlyOwner {
        bool isVestingTimeStart = isVestingTimeStarted();
        require(isVestingTimeStart == false," Vesting duration cannot be changed when vesting period started.");
        vestingDuration = _month;
    }
    
    function modifyVestingTimeStartFrom(uint256 _date) public onlyOwner isValidDate(_date) {
        bool isVestingTimeStart = isVestingTimeStarted();
        require(isVestingTimeStart == false," Vesting time cannot be changed when vesting period started.");
        require(_date >= tokenGenerateTime, "Vesting time cannot start before token generate event.");
        vestingTimeStartFrom = _date;
    }
    
    function modifyTokenGenerateTime(uint256 _date) public onlyOwner isValidDate(_date) {
        bool isTokenGenerateStarted = isTokenGenerateEventStarted();
        require(isTokenGenerateStarted == false,"Token generate time cannot be changed when token generate event started.");
        require(_date <= vestingTimeStartFrom, "Token generate event time must be less than vesting time.");
        tokenGenerateTime = _date;
    }

    function withdrawAgv(address _address, uint256 _amount) public onlyOwner isValidAmount(_amount) {
        uint256 contractBalance = IERC20(AGV_address).balanceOf(address(this));
        require(contractBalance >= _amount," Insufficient AGV token balance.");
        transferAGV(_address,_amount);
    }

    function decreaseInvestorAllowance(address _address, uint256 _amount) public onlyOwner isValidAddress(_address) isValidAmount(_amount) {
        require(_amount < investors[_address].balance,"Not enough token");
        investors[_address].lockedAgv -= _amount;
        investors[_address].balance -= _amount;
        totalInvestment -= _amount;
    }
    
    function changeAgvAddress(address _address) external onlyOwner isValidAddress(_address) {
        AGV_address = _address;
    }
    
    function transferOwnership(address _address) external onlyOwner isValidAddress(_address){
        owner = _address;
    }
    
    function getTokenGenerateTime() public view returns (uint256){
        return tokenGenerateTime;
    }
    function getVestingTime() public view returns (uint256){
        return vestingTimeStartFrom;
    }
    
    function getInvestor(address _address) public view returns (uint256 lockedAgv, uint256 releasedAgv, uint256 balance, uint256 totalClaim, uint256 previousClaimTime, bool tokenGenerated){
        if(investors[_address].lockedAgv != 0){
            return (
                investors[_address].lockedAgv,
                investors[_address].releasedAgv,
                investors[_address].balance,
                investors[_address].claimCounter,
                investors[_address].previousClaimTime,
                investors[_address].isTokenGenerated
            );
        } else {
            return (0,0,0,0,0,false);
        }
    }
    
    function isEligibleForClaim() public view isInvestorExist returns(bool _res){
        bool isTokenGenerateStarted = isTokenGenerateEventStarted();
        bool isVestingTime = isVestingTimeStarted();
        if(isTokenGenerateStarted == true){
            if(isVestingTime == true){
                if(investors[_msgSender()].releasedAgv < investors[_msgSender()].lockedAgv){
                    if(investors[_msgSender()].claimCounter < vestingDuration){
                        if(investors[_msgSender()].previousClaimTime != 0){
                            if(block.timestamp > investors[_msgSender()].previousClaimTime + 30*24*60*60) return true;
                            else return false;
                        } else {
                            return true;
                        }
                    }
                }      
            } 
        }
        return false;
    }
    
    function addInvestor(address _address, uint256 _amount) external onlyOwner isValidAddress(_address) isValidAmount(_amount) {
        bool isTGETime = isTokenGenerateEventStarted();
        require(isTGETime == false," Cannot add investor after Token generation started.");
        totalInvestment += _amount;
        if(investors[_address].lockedAgv != 0){
            investors[_address].lockedAgv += _amount;
            investors[_address].balance += _amount;
        } else {
            investors[_address] = Investor ({
                lockedAgv:_amount,
                releasedAgv:0,
                previousClaimTime:0,
                claimCounter:0,
                isTokenGenerated:false,
                balance:_amount
            });
            emit AddInvestor(_address,_amount);
        }
    }
    
    function transferAGV(address _receiver, uint256 _amount) internal returns(bool _res){
        bool responce = IERC20(AGV_address).transfer(_receiver,_amount);
        return responce;
    }
    
    function generateToken() external isInvestorExist {
        bool isTokenGenerateStarted = isTokenGenerateEventStarted();
        address _address = _msgSender();
        
        require(isTokenGenerateStarted == true,"Token generate event not started.");
        
        require(investors[_address].isTokenGenerated == false,"Token already generated.");
        
        uint256 _amount = (investors[_address].lockedAgv * tgePercentage)/100;
        
        uint256 contractBalance = IERC20(AGV_address).balanceOf(address(this));
        require(contractBalance >= _amount," Insufficient AGV token balance.");
        
        transferAGV(_address,_amount);
        totalRelease += _amount;
        
        investors[_address].releasedAgv += _amount;
        investors[_address].balance = investors[_address].lockedAgv - investors[_address].releasedAgv;
        investors[_address].isTokenGenerated = true;
    }
    
    function claimAgv() external isInvestorExist {
        
        bool isVestingTimeStart = isVestingTimeStarted();
        require(isVestingTimeStart == true,"Claim cannot be started before the vesting time started.");
        
        bool isEligible = isEligibleForClaim();
        require(isEligible == true,"Not eligible for claim.");
        
        uint256 contractBalance = IERC20(AGV_address).balanceOf(address(this));
        
        address _address = _msgSender();
        
        uint256 _transferAmount  = ( investors[_address].lockedAgv*claimPercentage)/10000;
        
        require(contractBalance >= _transferAmount," Insufficient AGV token balance.");
        require(investors[_address].isTokenGenerated == true,"Token not generated.");
        
        if(investors[_address].claimCounter == vestingDuration-1){
            _transferAmount = investors[_address].balance;
        }
       
        transferAGV(_address,_transferAmount);
        investors[_address].previousClaimTime = block.timestamp;
        investors[_address].releasedAgv += _transferAmount;
        investors[_address].claimCounter++;
        investors[_address].balance = investors[_address].lockedAgv - investors[_address].releasedAgv; 
        totalRelease += _transferAmount;
       
        emit Claim(address(this),_address,_transferAmount);
       
    }
    
}