/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

contract MLBountyEscrow {
    
    
    address owner;

    // taskId -> address -> amount
    mapping(string => mapping(address => uint256)) public bounties;
    mapping(string => uint256) public totalBounties;
    mapping(address => uint256) public balances;
    
    event DepositedBounty ( 
        string taskId,
        address sender,
        uint256 amount
    );
    
    event WithdrawnBounty (
        string taskId,
        address sender,
        uint256 amount
    );
    
    event CompletedBounty (
        string taskId,
        address recipient,
        uint256 amount
    );
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function completeBounty(string calldata taskId, address payable recipient) external onlyOwner {
        uint256 totalAmount = totalBounties[taskId];
        uint256 commission = totalAmount * 5 / 100;
        uint256 paidOut = totalAmount - commission;
        recipient.transfer(paidOut);
        payable(owner).transfer(commission);
        emit CompletedBounty(taskId, recipient, paidOut);
    }
    
    function createBounty(string calldata taskId) external payable { 
        bounties[taskId][msg.sender] += msg.value;
        totalBounties[taskId] += msg.value; 
        balances[msg.sender] += msg.value;
        emit DepositedBounty(taskId, msg.sender, msg.value);
    }
    
    function withdrawBounty(string calldata taskId, uint256 amount) external {
        require(bounties[taskId][msg.sender] >= amount);
        bounties[taskId][msg.sender] -= amount;
        totalBounties[taskId] -= amount;
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit WithdrawnBounty(taskId, msg.sender, amount);
    }
    
    
    function bountyOfTask(string calldata taskId) public view returns(uint) {
        return totalBounties[taskId];
    }
    
    function bountyOfUser() public view returns(uint) {
        return balances[msg.sender];
    }
}