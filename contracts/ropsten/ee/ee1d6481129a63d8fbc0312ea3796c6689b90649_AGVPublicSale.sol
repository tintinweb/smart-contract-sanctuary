/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract AGVPublicSale {

    address public owner;
    address private AGV_address;
    address private usdt_address;
    uint256 private tokenGenerateTime;
    uint256 private vestingDuration;       // In months
    uint256 private vestingTimeStartFrom;  //  Claim cannot start before vestingTimeStart from 
    uint256 public totalInvestment;
    uint256 public totalRelease;
    uint256 public tgePercentage;
    uint256 public claimPercentage;
    uint256 public agv_in_usd;
    
    struct PublicInvestors {
        uint256 lockedAgv;         //  Locked balance
        uint256 releasedAgv;       // relesed balance
        uint256 previousClaimTime;
        uint256 claimCounter;
        bool isTokenGenerated;
        uint256 balance;     // remaining balance
    }
    
    using SafeMath for uint;
    mapping(address => PublicInvestors) public investors;
    
    event AddInvestor(address indexed investor, uint indexed amount);
    event Claim(address indexed sender, address indexed investor, uint indexed amount);
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    constructor() {
        tokenGenerateTime = 1639902919; // 23 Dec 2021
        vestingTimeStartFrom = 1639906519; // 31 Jan 2022
        vestingDuration = 6;
        tgePercentage = 20;
        claimPercentage = 1333;
        agv_in_usd = 20;
        owner = _msgSender();
        AGV_address = 0x9d876FEe82C8d9b6b484757f9092bCF0ba096AfC;
        usdt_address = 0x8096f70ad471212761599B5ABF73960B269597fC;
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

    function modifyAGVValue(uint256 _value) public onlyOwner {
        agv_in_usd = _value;
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
    function modifyUsdtContractAddress(address _address) public onlyOwner {
        usdt_address = _address;
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
                            // if(block.timestamp > investors[_msgSender()].previousClaimTime + 3*60) return true;
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
    function buyAgv(address _address, uint _amount,string memory _currency)  external  {
        if(keccak256(abi.encodePacked((_currency))) == keccak256(abi.encodePacked(("USDT")))){
            uint _usd = (_amount.mul(agv_in_usd)).div(100);
            _usd = (_usd.div(10**12));
            IERC20(usdt_address).transferFrom(_address,address(this),_usd);
            addInvestor(_address,_amount);
        }
        else
        {
            revert("Invalid Currency");
        }
    }
    function addInvestors(address[] calldata _addresses,uint256[] calldata _amounts) onlyOwner external {
        for(uint i = 0 ; i < _addresses.length ; i ++ ){
           addInvestor(_addresses[i],_amounts[i]);
        }
    } 
    function addInvestor(address _address, uint256 _amount) internal isValidAddress(_address) isValidAmount(_amount) {
        totalInvestment += _amount;

        if(investors[_address].lockedAgv != 0){
            investors[_address].lockedAgv += _amount;
            investors[_address].balance += _amount;
        } else {
            investors[_address] = PublicInvestors ({
                lockedAgv:_amount,
                releasedAgv:0,
                previousClaimTime:0,
                claimCounter:0,
                isTokenGenerated:false,
                balance:_amount
            });
        }
    }
    
    function transferAGV(address _receiver, uint256 _amount) internal returns(bool _res){
        bool responce = IERC20(AGV_address).transfer(_receiver,_amount);
        return responce;
    }

    function generateToken() external isInvestorExist {
        bool isTokenGenerateStarted = isTokenGenerateEventStarted();
        address _address = _msgSender();
        
        require(isTokenGenerateStarted == true,"TGE not started !");
        
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
    
    function withdrawToken(address _tokenAddress, uint256 _amount) public onlyOwner {
        IERC20(_tokenAddress).transfer(owner,_amount);
    }

    function withdrawEth(uint256 _amount) public onlyOwner {
        address payable payableOwner = payable(owner);
        payableOwner.transfer(_amount);
    }
}