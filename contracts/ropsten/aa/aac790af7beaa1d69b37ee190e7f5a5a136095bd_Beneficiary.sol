/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

pragma solidity 0.7.5;


contract Beneficiary{
    
    address payable public owner;
    address payable public recipient;
    uint timetoWithdrawal;
    uint startTime;
    mapping(address => bool) approved;
        
    
    // Give address of beneficiary when deploying contract
    // start timer countdown to set release time
    
    constructor (address payable _recipient, uint withdrawalTimeinMinutes){
        owner = msg.sender;
        recipient = _recipient;
        startTime = block.timestamp;
        timetoWithdrawal = startTime + withdrawalTimeinMinutes * 60;
        
    }
    
    modifier onlyOwner{
        require(msg.sender == owner, "Only owner has access");
        _;
    }
    
    modifier onlyRecipient{
        require(msg.sender == recipient, "Only beneficiary has access");
        _;
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    
    function deposit() public payable returns(uint){
        return msg.value;
    }
    
    function getContractBalance()public view returns(uint){
        return address(this).balance;
    }
    
    function approve()public {
        approved[msg.sender] = true;
    }
    
    function withdraw(uint _amount)public onlyRecipient returns(bool){
        require(block.timestamp >= timetoWithdrawal, "withdrawal is not unlocked yet, check timeleft to see when you can withdraw in seconds");
        recipient.transfer(_amount);
        return true;
        
        }
        
    function destroyContract() public onlyOwner{
        //require(approvals[owners[0]][0] && approvals[owners[1]][0] && approvals[owners[2]][0]);
        selfdestruct(owner);
    }
    
    function timeLeft() public view returns(uint){
        return(sub(timetoWithdrawal, block.timestamp, "Cant substract negatives"));
    }
    
}