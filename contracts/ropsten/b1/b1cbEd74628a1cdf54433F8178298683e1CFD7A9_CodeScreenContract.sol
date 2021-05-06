/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity >=0.4.22 <0.9.0;

contract CodeScreenContract {

    enum Type { User, Admin }

    struct UserDetail {
        uint userId;
        Type level;
        address createdBy;
        address userAddress;
        uint createdAt;
        uint paidIn;
        bool voted;
    }

    struct Fund {
        bytes32 fundName;
        uint votes;
    }

    // Create any vars here
    UserDetail[] userList;
    Fund[] funds;
    
    uint private winProposal;
    address public adminAddress;
    mapping(address => uint) public userIndex;   // 1-indexed

    constructor(bytes32[] memory ProposedDefiFundNames) public {
        // TODO Implement
        
        adminAddress = msg.sender;
        
        uint fundsLength = ProposedDefiFundNames.length;
        for(uint i = 0 ; i < fundsLength ; i ++)
        {
            funds.push(Fund({
                fundName : ProposedDefiFundNames[i],
                votes : 0
            }));
        }
        winProposal = 0;
        
        // add the contract deployer as  a User.
        userList.push(UserDetail({
                userId : 1,
                level : Type.User,
                createdBy : address(0x0),
                userAddress : msg.sender,
                createdAt : block.timestamp,
                paidIn : 0,
                voted:false
        }));
        
        userIndex[msg.sender] = userList.length;
    }

    // Called by admins to add a new user
    function addNewUser(address _userAddress, uint _userId) public returns (bool) {
        // TODO Implement
        require(msg.sender == adminAddress, "error: caller is not admin");
        require(userIndex[_userAddress] == 0, "error: duplicated user");
        
        userList.push(UserDetail({                      // add new user
                userId : _userId,
                level : Type.User,
                createdBy : adminAddress,
                userAddress : _userAddress,
                createdAt : block.timestamp,
                paidIn : 0,
                voted:false
        }));
        
        userIndex[_userAddress] = userList.length;      // save user's index
        return true;
    }

    // Called by admins to get user details
    function getUserDetails(address _userAddress) public view returns (uint, Type, address, uint) {
        // TODO Implement
        // Return in order of userId, level, userAddress, paidIn
        
        require(msg.sender == adminAddress, "error : caller is not admin");
        require(userIndex[_userAddress] > 0, "error : invalid user");
        
        uint256 Id = userIndex[_userAddress] - 1;
        
        return (userList[Id].userId, userList[Id].level, userList[Id].userAddress, userList[Id].paidIn);
    }

    // Called by a user to deposit money into the contract
    function deposit() public payable {
        // TODO Implement
        
        require(userIndex[msg.sender] > 0, "error: invalid user");
        
        uint256 Id = userIndex[msg.sender] - 1;
        userList[Id].paidIn += msg.value;
    }

    // Called by a user to vote on a fund
    function vote(uint proposal) public {
        // TODO Implement
        
        require(proposal < funds.length, "error: invalid proposal");
        require(userIndex[msg.sender] > 0, "error: invalid user");
        require(userList[userIndex[msg.sender] - 1].voted == false, "error: already voted");
        
        userList[userIndex[msg.sender] - 1].voted = true;
        funds[proposal].votes ++;
        if(funds[proposal].votes > funds[winProposal].votes)
        {
            winProposal = proposal;
        }
    }

    // Called by a user to view the fund currently winning
    function winningProposal() public view returns (uint winningProposal_) {
        // TODO Implement
        
        winningProposal_ = winProposal;
    }
}