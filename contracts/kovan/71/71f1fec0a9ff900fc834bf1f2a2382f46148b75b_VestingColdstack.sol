// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;
    
    import "./SafeMath.sol";
    import "./IERC20.sol";
    import "./KeeperCompatibleInterface.sol";
    
    contract VestingColdstack is KeeperCompatibleInterface {
        IERC20 public token;
        address public owner;
        uint public immutable interval;
        uint public lastTimeStamp;
        
        struct Vesting {
            uint paymentCount;
            address paymentAddress;
            uint256 paymentSummDay;
            uint lastPayment;
        }
        
        address[] public VestingAddresses;
        mapping(address => Vesting) public  vestings;
        
        event TokensClaimed(address paymentAddress, uint256 amountClaimed);
        
        modifier nonZeroAddress(address x) {
            require(x != address(0), "token-zero-address");
            _;
        }
        
        modifier onlyOwner {
            require(msg.sender == owner, "unauthorized");
            _;
        }
      
        constructor(address _token) nonZeroAddress(_token) {
            owner = msg.sender;
            token = IERC20(_token);
            interval = 86400;
            lastTimeStamp = block.timestamp;
        }
        
        
        function addVesting(address _paymentAddress, uint256 _paymentSummDay) public onlyOwner nonZeroAddress(_paymentAddress) {
            
            
            Vesting memory newVesting;
            
            newVesting.paymentAddress = _paymentAddress;
            newVesting.paymentCount = 270;
            newVesting.paymentSummDay = _paymentSummDay;
            newVesting.lastPayment = block.timestamp;
            
            
             vestings[_paymentAddress] = newVesting;
             VestingAddresses.push(_paymentAddress);
        
        }
        
        function removeVesting(address _paymentAddress) public onlyOwner nonZeroAddress(_paymentAddress) {
            delete vestings[_paymentAddress];
        }
        
        function calculateClaim(address sender) public  returns(uint256) {
            uint count = SafeMath.sub(block.timestamp,vestings[sender].lastPayment) / 86400;
            
            if(count == 0) return 0;
            
            if(vestings[msg.sender].paymentCount < count) count = vestings[sender].paymentCount;
            
            return SafeMath.mul(count, vestings[sender].paymentSummDay);
        }
        
        function ClaimedToken(address sender) public returns(bool){
            // require(calculateClaim() != 0, 'Claimed zero tokens');
            // require(token.transferFrom(owner,msg.sender, calculateClaim()), 'token transfer error');
            
            uint  count = (SafeMath.sub(block.timestamp,vestings[sender].lastPayment) / 86400);
            
            if(count == 0) return false;
            
            if(vestings[sender].paymentCount < count) count = vestings[sender].paymentCount;
            
            vestings[sender].paymentCount = SafeMath.sub(vestings[sender].paymentCount, count);
            vestings[sender].lastPayment = SafeMath.add(vestings[sender].lastPayment,SafeMath.mul(86400,count));
            
            emit TokensClaimed(sender, SafeMath.mul(count, vestings[sender].paymentSummDay));
            
            if(vestings[sender].paymentCount == 0) delete vestings[sender];
            
            return true;
            
        }
        
        function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded,  bytes memory /* performData */) {
            upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        }

        function performUpkeep(bytes calldata /* performData */) external override {
        lastTimeStamp = block.timestamp;
        
        for(uint index = 0; index<VestingAddresses.length; index++){
            ClaimedToken(VestingAddresses[index]);
        }
        
        }   
    }