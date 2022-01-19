/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity ^0.7.6;
pragma abicoder v2;

contract Master {
    receive() external payable {}


    struct aBid {
        bool answered;
        bool withdrawn;
        string id;
        string answerId;
        uint timeLimit;
        uint time;
        uint sum;
        address payable beneficiaryAddress; 
        address payable ownerAddress; 
    }

    mapping(address => string[]) contracts;
    mapping(address => string[]) beneficiaries;
    mapping(string => aBid) bids;

    function getBidsContract() public view returns(string[] memory) {
        return contracts[msg.sender];
    }

    function getBidsBeneficiary() public view returns(string[] memory) {
        return beneficiaries[msg.sender];
    }

    function getBid(string calldata id) public view returns(bool, bool, string memory, uint, uint, uint, address payable, address payable) {
        aBid storage bid = bids[id];
        require(bid.ownerAddress == msg.sender || bid.beneficiaryAddress == msg.sender);
        string memory answerId = bid.answerId;
        return (bid.answered, bid.withdrawn, answerId, bid.timeLimit, bid.time, bid.sum, bid.ownerAddress, bid.beneficiaryAddress); 
    }


    function makeNew(address payable solver, string calldata id, uint timeLimit) payable public {
        address(this).transfer(msg.value);
        contracts[msg.sender].push(id);
        beneficiaries[solver].push(id);
        bids[id] = aBid({
            answered: false, 
            withdrawn: false, 
            id: id, 
            answerId: "", 
            timeLimit: timeLimit,
            time: block.timestamp, 
            sum: msg.value, 
            beneficiaryAddress: solver, 
            ownerAddress: msg.sender});
    }
   
    function withdrawExpiredBid(string calldata id) external {
      aBid storage bid = bids[id];  
      require(bid.ownerAddress == msg.sender && bid.answered == false && bid.withdrawn == false && block.timestamp - bids[id].time > bids[id].timeLimit); 
      // send back the eth here    
      bid.withdrawn = true;
      payable(msg.sender).transfer(bid.sum); 
    }
   
    function RewardSolvedBid(string calldata id, string calldata answerId) external  {
       aBid storage bid = bids[id];
       require(bid.beneficiaryAddress == msg.sender && bid.answered == false && bid.withdrawn == false && block.timestamp - bids[id].time < bids[id].timeLimit );
       bid.answered = true;
       bid.answerId = answerId;
       payable(bid.beneficiaryAddress).transfer(bid.sum);
    }
   
}