pragma solidity ^0.4.12;

contract Leaderboard {
    // Contract owner
    address owner;
    // Bid must be multiples of minBid
    uint256 public minBid;
    // Max num of leaders on the board
    uint public maxLeaders;
    
    // Linked list of leaders on the board
    uint public numLeaders;
    address public head;
    address public tail;
    mapping (address => Leader) public leaders;
    
    struct Leader {
        // Data
        uint256 amount;
        string url;
        string img_url;
        
        // Pointer to next and prev element in linked list
        address next;
        address previous;
    }
    
    
    // Set initial parameters
    function Leaderboard() {
        owner = msg.sender;
        minBid = 0.001 ether;
        numLeaders = 0;
        maxLeaders = 10;
    }
    
    
    /*
        Default function, make a new bid or add to bid by sending Eth to contract
    */
    function () payable {
        // Bid must be larger than minBid
        require(msg.value >= minBid);
        
        // Bid must be multiple of minBid. Remainder is sent back.
        uint256 remainder  = msg.value % minBid;
        uint256 bid_amount = msg.value - remainder;
        
        // If leaderboard is full, bid needs to be larger than the lowest placed leader
        require(!((numLeaders == maxLeaders) && (bid_amount <= leaders[tail].amount)));
        
        // Get leader
        Leader memory leader = popLeader(msg.sender);
        
        // Add to leader&#39;s bid
        leader.amount += bid_amount;
        
        // Insert leader in appropriate position
        insertLeader(leader);
        
        // If leaderboard is full, drop last leader
        if (numLeaders > maxLeaders) {
            dropLast();
        }
        
        // Return remainder to sender
        if (remainder > 0) msg.sender.transfer(remainder);
    }
    
    
    /*
        Set the urls for the link and image
    */
    function setUrls(string url, string img_url) {
        var leader = leaders[msg.sender];
        
        require(leader.amount > 0);
        
        // Set leader&#39;s url if it is not an empty string
        bytes memory tmp_url = bytes(url);
        if (tmp_url.length != 0) {
            // Set url
            leader.url = url;
        }
        
        // Set leader&#39;s img_url if it is not an empty string
        bytes memory tmp_img_url = bytes(img_url);
        if (tmp_img_url.length != 0) {
            // Set image url
            leader.img_url = img_url;
        }
    }
    
    
    /*
        Allow user to reset urls if he wants nothing to show on the board
    */
    function resetUrls(bool url, bool img_url) {
        var leader = leaders[msg.sender];
        
        require(leader.amount > 0);
        
        // Reset urls
        if (url) leader.url = "";
        if (img_url) leader.img_url = "";
    }
    
    
    /*
        Get a leader at position
    */
    function getLeader(address key) constant returns (uint amount, string url, string img_url, address next) {
        amount  = leaders[key].amount;
        url     = leaders[key].url;
        img_url = leaders[key].img_url;
        next    = leaders[key].next;
    }
    
    
    /*
        Remove from leaderboard LL
    */
    function popLeader(address key) internal returns (Leader leader) {
        leader = leaders[key];
        
        // If no leader - return
        if (leader.amount == 0) {
            return leader;
        }
        
        if (numLeaders == 1) {
            tail = 0x0;
            head = 0x0;
        } else if (key == head) {
            head = leader.next;
            leaders[head].previous = 0x0;
        } else if (key == tail) {
            tail = leader.previous;
            leaders[tail].next = 0x0;
        } else {
            leaders[leader.previous].next = leader.next;
            leaders[leader.next].previous = leader.previous;
        }
        
        numLeaders--;
        return leader;
    }
    
    
    /*
        Insert in leaderboard LinkedList
    */
    function insertLeader(Leader leader) internal {
        if (numLeaders == 0) {
            head = msg.sender;
            tail = msg.sender;
        } else if (leader.amount <= leaders[tail].amount) {
            leaders[tail].next = msg.sender;
            tail = msg.sender;
        } else if (leader.amount > leaders[head].amount) {
            leader.next = head;
            leaders[head].previous = msg.sender;
            head = msg.sender;
        } else {
            var current_addr = head;
            var current = leaders[current_addr];
            
            while (current.amount > 0) {
                if (leader.amount > current.amount) {
                    leader.next = current_addr;
                    leader.previous = current.previous;
                    current.previous = msg.sender;
                    leaders[current.previous].next = msg.sender;
                    break;
                }
                
                current_addr = current.next;
                current = leaders[current_addr];
            }
        }
        
        leaders[msg.sender] = leader;
        numLeaders++;
    }
    
    
    /*
        Drop last leader from board and return his/her funds
    */
    function dropLast() internal {
        // Get last leader
        address leader_addr = tail;
        var leader = popLeader(leader_addr);
        
        uint256 refund_amount = leader.amount;
        
        // Delete leader from board
        delete leader;
        
        // Return funds to leader
        leader_addr.transfer(refund_amount);
    }

    
    /*
        Modifier that only allows the owner to call certain functions
    */
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }


    /*
        Lets owner withdraw Eth from the contract. Owner can withdraw all funds,
        because leaders who fall of the board can always be refunded with the new
        bid: (newBid > refund).
    */
    function withdraw() onlyOwner {
        owner.transfer(this.balance);
    }
    
    
    /*
        Set new maximum for amount of leaders
    */
    function setMaxLeaders(uint newMax) onlyOwner {
        maxLeaders = newMax;
    }
}