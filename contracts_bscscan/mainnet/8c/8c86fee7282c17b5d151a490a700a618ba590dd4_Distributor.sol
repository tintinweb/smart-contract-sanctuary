/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-26
*/

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Distributor {
    address public owner;
    
    // list of the accounts that will receive a share
    address payable[] public recipients;
    // Shares eich recipient owns (we do 1 share/recipient with 2 shares for the treasury)
    mapping(address => uint256) public weights;
    
    // Just a quick way to get the index in the list for deletion
    mapping(address => uint256) public recipientIds;
    
    // Total weight (number of shares)
    uint256 public totalWeight;
    
    constructor() {
        owner = msg.sender;
    }
    
    // ADMINISTRATIVE FUNCTIONS
    
    // Add the address as a distribution recipient with the given weight (shares)
    
    event RecipientAdded(address indexed addr, uint256 weight, uint256 totalWeightAfter);
    event RecipientUpdated(address indexed addr, uint256 weightBefore, uint256 weightAfter, uint256 totalWeightAfter);
    event RecipientRemoved(address indexed addr, uint256 totalWeightAfter);
    function addRecipient(address payable addr, uint256 weight) public {
        require(msg.sender == owner, "!owner");
        require(weight > 0, "zero weight");
        require(weights[addr] == 0, "already added");
        
        recipients.push(addr);
        weights[addr] = weight;
        totalWeight += weight;
        recipientIds[addr] = recipients.length - 1;
        
        emit RecipientAdded(addr, weight, totalWeight);
    }
    
    
    // Remove a recipient from receiving distributions
    function removeRecipient(address payable addr) public {
        require(msg.sender == owner, "!owner");
        require(weights[addr] > 0, "not added");
        totalWeight -= weights[addr];
        weights[addr] = 0;
        _removeAddr(recipientIds[addr]);
        recipientIds[addr] = 0;
        
        emit RecipientRemoved(addr, totalWeight);
    }
    
    // Update the weight of an existing recipient
    function updateRecipient(address payable addr, uint256 weight) public {
        require(msg.sender == owner, "!owner");
        require(weight > 0, "remove recipient instead");
        require(weights[addr] > 0, "add recipient instead");
        
        uint256 weightBefore = weights[addr];
        totalWeight -= weightBefore;
        totalWeight += weight;
        weights[addr] = weight;
        
        emit RecipientUpdated(addr, weightBefore, weight, totalWeight);
    }
    
    // DISTRIBUTION FUNCTIONS
    
    // Distributes the tokens over the recipients pro-rata their weight
    function distributeToken(IERC20 token) public {
        require(msg.sender == owner, "!owner");
        uint256 balance = token.balanceOf(address(this));
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 weight = weights[recipient];
            uint256 amount = balance*weight/totalWeight;
            safeTokenTransfer(token, recipient, amount);
        }
    }
    
     function test() public view returns (uint256){
        require(msg.sender == owner, "!owner");
        uint256 j = 0 ;
        for (uint256 i = 0; i < recipients.length; i++) {
            j++;
        }
        return j;
    }
    
    
    // Distributes the contract BNB over the recipients pro-rata their weight
    function distributeBNB() public {
        require(msg.sender == owner, "!owner");
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < recipients.length; i++) {
            address payable recipient = recipients[i];
            uint256 weight = weights[recipient];
            uint256 amount = balance*weight/totalWeight;
            safeBnbTransfer(recipient, amount);
        }
    }
    
    // SAFE TRANSFER FUNCTIONS (for rounding)
    
    // Helper function for rounding errors (shouldn't happen due to solidity rounding down)
    function safeTokenTransfer(IERC20 token, address to, uint256 amount) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance < amount) {
            token.transfer(to, balance);
        } else {
            token.transfer(to, amount);
        }
    }
    
    // Helper function for rounding errors (shouldn't happen due to solidity rounding down)
    function safeBnbTransfer(address payable to, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount) {
            to.transfer(balance);
        } else {
            to.transfer(amount);
        }
    }
    
    // UTILITY FUNCTIONS
    
    // Move the last element to the deleted spot.
    // Delete the last element, then correct the length.
    function _removeAddr(uint index) internal {
        require(index < recipients.length);
        recipients[index] = recipients[recipients.length-1];
        recipientIds[recipients[index]] = index; // also update the index
        recipients.pop(); // todo: Check if pop works
    }
    
    function recipientsLength() public view returns (uint256) {
        return recipients.length;
    }
        
    // Helper function to withdraw BNB
    function inCaseTokensBNBGetStuck(address payable to) public {
        require(msg.sender == owner, "!owner");
        to.transfer(address(this).balance);
    }
    
    // Helper function to withdraw tokens
    function inCaseTokensGetStuck(IERC20 token, address to) public {
        require(msg.sender == owner, "!owner");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(to, balance);
    }
    
    
    function changeOwner(address _owner) public {
        require(msg.sender == owner, "!owner");
        owner = _owner;
        
    }
    
    receive () external payable {}
    
}