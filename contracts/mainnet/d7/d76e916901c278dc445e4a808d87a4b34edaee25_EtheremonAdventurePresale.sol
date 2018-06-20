pragma solidity ^0.4.19;

library AddressUtils {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract BasicAccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    function BasicAccessControl() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


contract EtheremonAdventurePresale is BasicAccessControl {
    uint8 constant NO_ETH_SITE = 52;
    uint8 constant MAX_BID_PER_SITE = 10;
    using AddressUtils for address;
    
    struct BiddingInfo {
        address bidder;
        uint32 bidId;
        uint amount;
        uint time;
        uint8 siteId;
    }
    
    // address
    address public tokenContract;
    
    uint32 public totalBid = 0;
    uint public startTime;
    uint public endTime;
    uint public bidETHMin;
    uint public bidETHIncrement;
    uint public bidEMONTMin;
    uint public bidEMONTIncrement;
    
    mapping(uint32 => BiddingInfo) bids;
    mapping(uint8 => uint32[]) sites;

    // event
    event EventPlaceBid(address indexed bidder, uint8 siteId, uint32 bidId, uint amount);
    
    // modifier
    modifier requireTokenContract {
        require(tokenContract != address(0));
        _;
    }
    
    modifier validETHSiteId(uint8 _siteId) {
        require(_siteId > 0 && _siteId <= NO_ETH_SITE);
        _;
    }
    modifier validEMONTSiteId(uint8 _siteId) {
        require(_siteId == 53 || _siteId == 54);
        _;
    }
    modifier onlyRunning {
        require(!isMaintaining);
        require(block.timestamp >= startTime && block.timestamp < endTime);
        _;
    }
    
    function withdrawEther(address _sendTo, uint _amount) onlyModerators public {
        // only allow withdraw after the presale 
        if (block.timestamp < endTime)
            revert();
        if (_amount > this.balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }
    
    function withdrawToken(address _sendTo, uint _amount) onlyModerators requireTokenContract external {
        // only allow withdraw after the presale 
        if (block.timestamp < endTime)
            revert();
        ERC20Interface token = ERC20Interface(tokenContract);
        if (_amount > token.balanceOf(address(this))) {
            revert();
        }
        token.transfer(_sendTo, _amount);
    }

    
    // public functions
    
    function EtheremonAdventurePresale(uint _bidETHMin, uint _bidETHIncrement, uint _bidEMONTMin, uint _bidEMONTIncrement, uint _startTime, uint _endTime, address _tokenContract) public {
        if (_startTime >= _endTime) revert();
        
        startTime = _startTime;
        endTime = _endTime;
        bidETHMin = _bidETHMin;
        bidETHIncrement = _bidETHIncrement;
        bidEMONTMin = _bidEMONTMin;
        bidEMONTIncrement = _bidEMONTIncrement;
        
        tokenContract = _tokenContract;
    }
    
    function placeETHBid(uint8 _siteId) onlyRunning payable external validETHSiteId(_siteId) {
        // check valid bid 
        if (msg.sender.isContract()) revert();
        if (msg.value < bidETHMin) revert();
        
        uint index = 0;
        totalBid += 1;
        BiddingInfo storage bid = bids[totalBid];
        bid.bidder = msg.sender;
        bid.bidId = totalBid;
        bid.amount = msg.value;
        bid.time = block.timestamp;
        bid.siteId = _siteId;
        
        uint32[] storage siteBids = sites[_siteId];
        if (siteBids.length >= MAX_BID_PER_SITE) {
            // find lowest bid
            uint lowestIndex = 0;
            BiddingInfo storage currentBid = bids[siteBids[0]];
            BiddingInfo storage lowestBid = currentBid;
            for (index = 0; index < siteBids.length; index++) {
                currentBid = bids[siteBids[index]];
                // check no same ether address 
                if (currentBid.bidder == msg.sender) {
                    revert();
                }
                if (lowestBid.amount == 0 || currentBid.amount < lowestBid.amount || (currentBid.amount == lowestBid.amount && currentBid.bidId > lowestBid.bidId)) {
                    lowestIndex = index;
                    lowestBid = currentBid;
                }
            }
            
            // verify bidIncrement
            if (msg.value < lowestBid.amount + bidETHIncrement)
                revert();
            
            // update latest bidder
            siteBids[lowestIndex] = totalBid;
            
            // refund for the lowest 
            lowestBid.bidder.transfer(lowestBid.amount);
        } else {
            for (index = 0; index < siteBids.length; index++) {
                if (bids[siteBids[index]].bidder == msg.sender)
                    revert();
            }
            siteBids.push(totalBid);
        }
        
        EventPlaceBid(msg.sender, _siteId, totalBid, msg.value);
    }
    
    // call from our payment contract
    function placeEMONTBid(address _bidder, uint8 _siteId, uint _bidAmount) requireTokenContract onlyRunning onlyModerators external validEMONTSiteId(_siteId) {
        // check valid bid 
        if (_bidder.isContract()) revert();
        if (_bidAmount < bidEMONTMin) revert();
        
        
        uint index = 0;
        totalBid += 1;
        BiddingInfo storage bid = bids[totalBid];
        uint32[] storage siteBids = sites[_siteId];
        if (siteBids.length >= MAX_BID_PER_SITE) {
            // find lowest bid
            uint lowestIndex = 0;
            BiddingInfo storage currentBid = bids[siteBids[0]];
            BiddingInfo storage lowestBid = currentBid;
            for (index = 0; index < siteBids.length; index++) {
                currentBid = bids[siteBids[index]];
                // check no same ether address 
                if (currentBid.bidder == _bidder) {
                    revert();
                }
                if (lowestBid.amount == 0 || currentBid.amount < lowestBid.amount || (currentBid.amount == lowestBid.amount && currentBid.bidId > lowestBid.bidId)) {
                    lowestIndex = index;
                    lowestBid = currentBid;
                }
            }
            
            // verify bidIncrement
            if (_bidAmount < lowestBid.amount + bidEMONTIncrement)
                revert();
            
            // update latest bidder
            bid.bidder = _bidder;
            bid.bidId = totalBid;
            bid.amount = _bidAmount;
            bid.time = block.timestamp;
            siteBids[lowestIndex] = totalBid;
            
            // refund for the lowest 
            ERC20Interface token = ERC20Interface(tokenContract);
            token.transfer(lowestBid.bidder, lowestBid.amount);
        } else {
            for (index = 0; index < siteBids.length; index++) {
                if (bids[siteBids[index]].bidder == _bidder)
                    revert();
            }
            bid.bidder = _bidder;
            bid.bidId = totalBid;
            bid.amount = _bidAmount;
            bid.time = block.timestamp;
            siteBids.push(totalBid);
        }
        
        EventPlaceBid(_bidder, _siteId, totalBid, _bidAmount);
    }
    
    // get data
    
    function getBidInfo(uint32 _bidId) constant external returns(address bidder, uint8 siteId, uint amount, uint time) {
        BiddingInfo memory bid = bids[_bidId];
        bidder = bid.bidder;
        siteId = bid.siteId;
        amount = bid.amount;
        time = bid.time;
    }
    
    function getBidBySiteIndex(uint8 _siteId, uint _index) constant external returns(address bidder, uint32 bidId, uint8 siteId, uint amount, uint time) {
        bidId = sites[_siteId][_index];
        if (bidId > 0) {
            BiddingInfo memory bid = bids[bidId];
            bidder = bid.bidder;
            siteId = bid.siteId;
            amount = bid.amount;
            time = bid.time;
        }
    }

    function countBid(uint8 _siteId) constant external returns(uint) {
        return sites[_siteId].length;
    }
    
    function getLowestBid(uint8 _siteId) constant external returns(uint lowestAmount) {
        uint32[] storage siteBids = sites[_siteId];
        lowestAmount = 0;
        for (uint index = 0; index < siteBids.length; index++) {
            if (lowestAmount == 0 || bids[siteBids[index]].amount < lowestAmount) {
                lowestAmount = bids[siteBids[index]].amount;
            }
        }
    }
}