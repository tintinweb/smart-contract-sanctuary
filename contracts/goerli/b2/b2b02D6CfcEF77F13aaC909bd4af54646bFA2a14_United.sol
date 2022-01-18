// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./IUnionNFT.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract United  is ReentrancyGuard{

    address payable owner;

    address private nftContract; 

    //PROPOSALS state variables
    enum Proposal {PENDING, ACCEPTED, DECLINED}
    Proposal proposal;
    uint public cost = 0.01 ether;
    uint public timeToRespond = 5 minutes;


    struct ReqUnion{
        address to;
        address from;
        uint8 proposalStatus;
        uint proposalNumber;
        uint createdAt;
        bool exists;
        bool expired;
    }

    mapping(address => ReqUnion) public proposals;
    uint public proposalsCounter = 0;
    mapping(uint => ReqUnion) public proposalsMade;

    //UNIONS state variables
    enum Status {TOGETHER, PAUSED, SEPARATED}
    Status status;
    struct Union {
        address from;
        address to;
        uint currentStatus;
        uint registryNumber;
        uint createdAt;
        bool exists;
    }
  
    uint public updateStatusCost = 0.005 ether;
    
    uint public registryCounter  = 0;
    mapping(uint => Union) public unionRegistry;
    mapping(address => Union) public unionWith;


    constructor(){
        owner = payable(msg.sender);
    }


    modifier onlyOwner {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    //EVENTS

    //PROPOSAL EVENTS
    event ProposalSubmitted(address indexed to, address indexed from, uint indexed _timestamp, uint _status );

    event ProposalResponded(address indexed to, address indexed from, uint indexed _timestamp, uint _status );

    event ProposalCancelled(address indexed to, address indexed from);

    //UNION EVENTS
    event GotUnited(address indexed from, address indexed to, uint  _status,
    uint indexed _timestamp, uint  _registrationNumber);

    event UnionStatusUpdated(address indexed from, address indexed to, uint  _status,
    uint indexed _timestamp, uint  _registrationNumber);

    //ERRORS
    error AlreadyPending (string message);

    //BURNED
    event Burned(uint id, bool);


    function propose(address _to) external payable{
        require(msg.value >= cost, "Insufficient amount");
        require(_to != msg.sender, "Can't registry with yourself as a partner");
        //check if msg.sender is already united
        require(unionWith[msg.sender].exists == false, "You are already united");
        //avoid proposals to a person already in a relationship
        require(unionWith[_to].exists == false, "This address is already in a relationship");
        // if time to answer expired clear proposal in order to propose again
        if(proposals[msg.sender].exists == true && block.timestamp > proposals[msg.sender].createdAt + timeToRespond){
            ReqUnion memory reqReset = proposals[msg.sender];
            //get the addresses involved
            address from = reqReset.from;
            address to = reqReset.to;
            //reset proposal
            proposalsMade[reqReset.proposalNumber].proposalStatus=2;
            reqReset.exists = false;
            reqReset.expired = true;
            proposals[to] = reqReset;
            proposals[from] = reqReset;
            emit ProposalCancelled(to, from);
        } else if(proposals[msg.sender].exists == true && block.timestamp < proposals[msg.sender].createdAt + timeToRespond){
            revert AlreadyPending("You've got a pending or accepted proposal");
        }
        //create proposal
        ReqUnion memory request;
        request.to = _to;
        request.from = msg.sender;
        request.createdAt = block.timestamp;
        request.proposalNumber = proposalsCounter;
        request.exists = true;
        proposals[_to]= request;
        proposals[msg.sender]= request;
        proposalsMade[proposalsCounter] = request;
        proposalsCounter++;

        emit ProposalSubmitted(_to, msg.sender, block.timestamp, uint8(proposal));
    }

    function respondToProposal(Proposal response, string calldata ens1, string calldata ens2) external {
        //shouldnt be expired
        require(block.timestamp < proposals[msg.sender].createdAt + timeToRespond, "Proposal expired");
        //Only the address who was invited to be united should respond to the proposal.
        require(proposals[msg.sender].to == msg.sender, "You cant respond your own proposal, that's scary");
        //Proposal status must be "PENDING"
        require(proposals[msg.sender].proposalStatus == 0, "This proposal has already been responded");
        //instance in from the proposal in storage
        ReqUnion memory acceptOrDecline = proposals[msg.sender];
         //get the addresses involved
        address from = acceptOrDecline.from;
        address to = acceptOrDecline.to;
        //if declined cancel and reset proposal
         if(uint8(response) == 2){
            acceptOrDecline.expired = true;
            acceptOrDecline.exists = false;
            acceptOrDecline.proposalStatus = uint8(response);
            proposals[to] = acceptOrDecline;
            proposals[from] = acceptOrDecline;
            proposalsMade[acceptOrDecline.proposalNumber] = acceptOrDecline;
            emit ProposalCancelled(to, from);
            return;
        }
        //accept scenario
        if(uint8(response) == 1){
        acceptOrDecline.proposalStatus = uint8(response);
        acceptOrDecline.createdAt = block.timestamp;
        proposals[to] = acceptOrDecline;
        proposals[from] = acceptOrDecline;
        proposalsMade[acceptOrDecline.proposalNumber] = acceptOrDecline;
        getUnited(from, to, ens1, ens2 );
        } emit ProposalResponded(to, from, block.timestamp, uint8(response));

    }

    
    function cancelOrResetProposal() public { 
        ReqUnion memory currentProposal = proposals[msg.sender];
        address to = currentProposal.to;
        address from = currentProposal.from;
        currentProposal.proposalStatus = 2;
        currentProposal.expired = true;
        currentProposal.exists = false;   
        proposals[to] = currentProposal;
        proposals[from] = currentProposal;
        proposalsMade[currentProposal.proposalNumber] = currentProposal;
        emit ProposalCancelled(to, from);
    }

    
   function getUnited( address _from , address _to, string calldata ens1, string calldata ens2)  internal {
        Union memory union;
        union.from = _from;
        union.to = msg.sender;
        union.createdAt = block.timestamp;
        union.exists = true;
        union.registryNumber = registryCounter;
        unionRegistry[registryCounter] = union;
        unionWith[msg.sender]= union;
        unionWith[_from] = union;
        registryCounter++;

        IUnionNFT(nftContract).mint(_from, _to, ens1, ens2);
        emit GotUnited(_from,  msg.sender, uint8(status), block.timestamp, registryCounter);
   }

    function updateUnion(Status newStatus) external payable {
        require(msg.value >= updateStatusCost, "Insufficient amount");
        //only people in that union can modify the status
        require(unionWith[msg.sender].to == msg.sender ||
         unionWith[msg.sender].from == msg.sender, "You're address doesn't exist on the union registry" );
         //once separated cannot modify status
         require(unionWith[msg.sender].currentStatus != 2, "You are separated, make another proposal");
        Union memory unionUpdated = unionWith[msg.sender];
        address from = unionUpdated.from;
        address to = unionUpdated.to;
        unionUpdated.currentStatus = uint8(newStatus);
        unionUpdated.createdAt = block.timestamp;
        if(uint8(newStatus) == 2){
            unionUpdated.exists = false;
            //function to clear proposals made and free users for make new ones.
            cancelOrResetProposal();
        }
        unionRegistry[unionUpdated.registryNumber] = unionUpdated;
        unionWith[to] = unionUpdated;
        unionWith[from] = unionUpdated;

        emit UnionStatusUpdated(from, to, uint(newStatus), block.timestamp, unionUpdated.registryNumber);
    }


    function getTokenUri(uint256 _tokenId) external view returns(string memory){
       (string memory uri) = IUnionNFT(nftContract).tokenURI(_tokenId);
       return uri;
    }

    function getTokenIDS(address _add) external view returns (uint[] memory){
        (uint[] memory ids)=  IUnionNFT(nftContract).ownedNFTS(_add);
        return ids;
    }
   
    function burn(uint256 tokenId) external {
         IUnionNFT(nftContract).burn(tokenId, msg.sender);
         emit Burned(tokenId, true);
    }

    //Only owner
    function setNftContractAddress(address _ca) external onlyOwner{
        nftContract = _ca;
    }

    function modifyTimeToRespond (uint t) external onlyOwner{
        timeToRespond = t;
    } 
    function modifyProposalCost(uint amount) external onlyOwner{
        cost = amount;
    }
    function modifyStatusUpdateCost(uint amount) external onlyOwner{
        updateStatusCost = amount;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = payable(newOwner);
    }

    function withdraw() external  onlyOwner nonReentrant{
        uint amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface IUnionNFT {
    function mint(address from, address to,  string calldata ens1,string calldata ens2)  external ;
    function tokenURI(uint256 tokenId)  external view returns (string memory);
    function ownedNFTS(address _owner) external view returns(uint256[] memory);
    function burn(uint256 tokenId, address _add) external;
 }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}