//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;
import "ERC20.sol";

    contract Lead is ERC20 {
    
    ERC20 public philosophersToken;
    address public  contractAddress = address(this);
    address payable treasuryAddress = 0xF2b189939DB027B2f54d96d17006A2A5772b5623;
    address gameMaster;
    address gameMaster2;
    uint256 public dayEnd;
    uint256 public dailyAmount = 1000e18;
    uint256 public reward = 100e18;
    uint256 public divisible = 1e16;
    uint256 public minimum = 1e16;
    uint256 shiftLength = 1 days;
    address public topMiner;
    mapping (address => Claim) public _ethClaim;
    uint256[] public dayClaims;
    bool public mineStatus = false;
    
    event Stake(address indexed _from, uint256 indexed _amount);
    event DayOver(address indexed _topMiner);
    event Claimed(address indexed _from, uint256 indexed _share);
    event TopMiner(address indexed _from, uint256 indexed _amount);

    struct Claim {
        uint256 ethAmount;
        uint256 day;
    }
    
    modifier gamemaster {
        require( msg.sender == gameMaster || msg.sender == gameMaster2 );
        _;
    }
    
    modifier mineOpen {
        require( mineStatus == true);
        _;
    }
    
constructor() public ERC20("tokenalchem.ist Lead Mine", "LEAD")  {
        gameMaster = msg.sender;
}
    
    // Address Changes
    
     function setTreasuryAddress(address payable _address) external gamemaster {
       treasuryAddress = _address;
    }
    
    function setContractAddress(address _address) external gamemaster {
        philosophersToken = ERC20(_address);
    }
    
    function changeMaster(address payable _address) gamemaster external {
        gameMaster = _address;
    }
    
    function changeMaster2(address payable _address) gamemaster external {
        gameMaster2 = _address;
    }
    
    function changeShiftLength(uint256 _length) gamemaster external {
        shiftLength = _length;
    }
    // Mine Status
    
    function openMine() external gamemaster{
     mineStatus = true;
    }
    
    function closeMine() external gamemaster {
        if(contractAddress.balance > 0){
            dailyUpdateNo();
        }
        mineStatus = false;
    }
    
    
    
    function topAmount() public view returns(uint256){
    return _ethClaim[topMiner].ethAmount;
    }

    function changeReward(uint256 _reward) external gamemaster {
        reward = _reward;
    }

    function today() public view returns(uint256){
        return dayClaims.length + 1;
    }
    
      function dailyUpdateNo() private {
        dayEnd = 0;
        philosophersToken.transfer(topMiner, 1e18);
        emit DayOver(topMiner);
        topMiner = address(0);
        _mint(treasuryAddress, 100e18);
        dayClaims.push(contractAddress.balance);
        treasuryAddress.transfer(contractAddress.balance);
    }
    
    function stakeUpdate() private {
        if (block.timestamp >= dayEnd){
            newDay();
        if(contractAddress.balance - msg.value > 0){
            _mint(treasuryAddress, 100e18);
            philosophersToken.transfer(topMiner, 1e18);
            emit DayOver(topMiner);
            topMiner = address(0);
            dayClaims.push(contractAddress.balance - msg.value);
            treasuryAddress.transfer(contractAddress.balance - msg.value);
        }
        _mint(msg.sender, reward);
        }
    }
    
    function newDay() private {
        dayEnd = now + shiftLength;
    }
    
    // Stakes
    
    function stakeClaim() public mineOpen payable {
    require(msg.value >= minimum && msg.value % divisible == 0 );
    stakeUpdate();
    claimCheck();
    _ethClaim[msg.sender].ethAmount += msg.value;
    _ethClaim[msg.sender].day = today();
    emit Stake(msg.sender, _ethClaim[msg.sender].ethAmount);
    if(_ethClaim[msg.sender].ethAmount > _ethClaim[topMiner].ethAmount){
            topMiner = msg.sender;
            emit TopMiner(msg.sender, _ethClaim[msg.sender].ethAmount);
        }
    }
    
    
    // Claims
    function claimCheck() public {
        if((today() > _ethClaim[msg.sender].day && _ethClaim[msg.sender].ethAmount > 0) || (_ethClaim[msg.sender].ethAmount > 0 && block.timestamp > dayEnd)){
            claim();
        }
    }
    
    function claimAvailable() public view returns(bool){
     if((today() > _ethClaim[msg.sender].day && _ethClaim[msg.sender].ethAmount > 0) || (_ethClaim[msg.sender].ethAmount > 0 && block.timestamp > dayEnd)){
            return true;
        }
    else{
        return false;
    }
    }
    
    function claim() private {
    if(today() == _ethClaim[msg.sender].day){
    dailyUpdateNo();
    }
    uint256 share = dailyAmount * (_ethClaim[msg.sender].ethAmount / (dayClaims[_ethClaim[msg.sender].day-1] / 1e10))/1e10;
    _ethClaim[msg.sender].ethAmount = 0;
    _ethClaim[msg.sender].day = 0;
    _mint(msg.sender, share);
    emit Claimed(msg.sender, share);
    }
    
    function claimAmount() external view returns (uint256){
        if(claimAvailable()){
        if(_ethClaim[msg.sender].day == today() && contractAddress.balance > 0){
            uint256 share = dailyAmount * (_ethClaim[msg.sender].ethAmount / (contractAddress.balance / 1e10))/1e10;
        return share;

        }
        else{
            uint256 share = dailyAmount * (_ethClaim[msg.sender].ethAmount / (dayClaims[_ethClaim[msg.sender].day-1] / 1e10))/1e10;
        return share;
        }
    }
    else{
        return 0;
    }
    }
    
    
    // Financials
    function getBalance() public view returns (uint256){
        return address(this).balance;
    }
    
    function updateReward(uint256 _reward) external gamemaster {
        dailyAmount = _reward * 1e18;
    }
    
    function updateCartReward (uint256 _reward) external gamemaster {
        reward = _reward * 1e18;
    }
    
    function minimumStake (uint256 _minimum) external gamemaster {
        minimum = _minimum;
    }
    
    function updateDecimal (uint256 _divisor) external gamemaster {
        divisible = _divisor;
    }

}