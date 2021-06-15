/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.4.26;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is IERC20 {
    string  public name = "eVoting Token";
    string  public symbol = "eToken";
    uint256 public totalSupply = 1200000000000000000000000000; // 120 million tokens
    address public owner;
    
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;

    constructor() public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }
    // To get the name of the token
    function name() public view returns (string) {
        return name;
    }
    // To get the symbol of the token
    function symbol() public view returns (string) {
        return symbol;
    }
    
    // To get the total tokens regardless of the owner
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    // To get the token balance of a specific account using the address 
    function balanceOf(address _tokenAddress) public view returns (uint256 balance){
        return balanceOf[_tokenAddress];
    }
    
    // To transfer tokens to a specific address
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[owner] >= _value, "Balance not enough");
        balanceOf[owner] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(owner, _to, _value);
        return true;
    }
    
    // To transfer tokens to from one address to a specific address
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], "Sender Balance is low");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}
contract VotingContract {
    struct Voter {
        address[] proposal;
        uint numOfVotes;
        bool voterRegistered;
    }
    struct Proposal {
        address[] votersInFavour;
        address[] votersInRejection;
        address[] voter;
        uint voteCount;
        uint countYes;
        uint countNo;
        mapping(address => bool) castYes;
        mapping(address => bool) castNo;
        string proposalName;
        string proposalDesc;
        bool proposalRegistered;
        bool accepted;
    }

    mapping(address => Proposal) public proposals;
    mapping(address => Voter) public voters;
    address[] public proposalAddress;
    address[] public voterAddress;
    uint public voterCount = 0;
    uint public proposalCount = 0;
    address public owner;
    address private tokenAddress;
    ERC20 token;
    address[] public acceptedProposal;
    address[] public yesVoters;

    
    event tokensDeposited (
        address depositer, 
        uint tokenAmount
    );        
    
    
    constructor(address _tokenAddress) public {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function registerProposal(string _proposalName, string _proposalDesc) public {

        require(proposals[msg.sender].proposalRegistered != true, "You already have one registered proposal");
       
        // Check if the proposal owner is a voter
        for (uint i = 0; i<voterAddress.length; i++ ){
            
            require(voterAddress[i] != msg.sender, "Voter cannot register a proposal");
        }
    
        // Add voter to the proposalList    
        proposalAddress.push(msg.sender);
        
        proposals[msg.sender].proposalName = _proposalName;
        proposals[msg.sender].proposalDesc = _proposalDesc;
        proposals[msg.sender].accepted = false;
        proposals[msg.sender].proposalRegistered = true;
         
        proposalCount++;
    }
    
    function registerVoter() public {
        
        require(voters[msg.sender].voterRegistered != true, "Voter is already registered");
        
        // Check if the voter is a proposal owner
        for (uint i = 0; i<proposalAddress.length; i++ ){
            
            require(proposalAddress[i] != msg.sender, "Proposal owner cannot register as a voter");
        }
    
        // Add voter to the voterList    
        voterAddress.push(msg.sender);
    
        voters[msg.sender].numOfVotes = 0;
        voters[msg.sender].voterRegistered = true;
        
        voterCount++;
    }
    
    function voteInFavour(address prop) public {
        address _proposalAddress = prop;
        require(msg.sender != _proposalAddress, "You cannot vote for yourself");
    
        // If voter is a proposal owner, revert()
        for ( uint i = 0; i<proposalAddress.length; i++ ){
            
            require(proposalAddress[i] != msg.sender, "Owner of any proposal cannot vote");    
        }
        
        // Check if we have any voters registered, revert()
            
            // require(voterAddress.length > 0, "Not voters yet");

            require(voters[msg.sender].voterRegistered == true, "Voter is not registered");
        // for (uint j = 0; j < voterAddress.length; j++ ){
        //     require(msg.sender == voterAddress[j], "Voter does not exist");
        // }
        
        for (uint k = 0; k < voterAddress.length; k++ ){
        
        // Check if the Voter is casting vote to itself, revert()
            
            require(voterAddress[k] != _proposalAddress, "Voter cannot cast vote to itself");
        }        
      
        for (uint l = 0; l < proposals[_proposalAddress].voter.length; l++ ){
        
          // Check if voter has already casted vote for this proposal

                require(proposals[_proposalAddress].voter[l] != msg.sender, "Voter has already casted vote" );
        }
        
        // Cast the vote for this proposal
                proposals[_proposalAddress].voter.push(msg.sender);   
                voters[msg.sender].proposal.push(_proposalAddress);
                proposals[_proposalAddress].votersInFavour.push(msg.sender);
                proposals[_proposalAddress].voteCount += 1;
                proposals[_proposalAddress].countYes += 1;
                proposals[_proposalAddress].castYes[msg.sender] = true;
                voters[msg.sender].numOfVotes += 1;
        }
        
    function voteInRejection(address prop) public {
        address _proposalAddress = prop;
        require(msg.sender != _proposalAddress, "You cannot vote for yourself");
    
        // If voter is a proposal owner, revert()
        for ( uint i = 0; i<proposalAddress.length; i++ ){
            
            require(proposalAddress[i] != msg.sender, "Owner of any proposal cannot vote");    
        }
        
        // Check if we have any voters registered, revert()
            
            // require(voterAddress.length > 0, "Not voters yet");

            require(voters[msg.sender].voterRegistered == true, "Voter is not registered");
        
        for (uint k = 0; k < voterAddress.length; k++ ){
        
        // Check if the Voter is casting vote to itself, revert()
            
            require(voterAddress[k] != _proposalAddress, "Voter cannot cast vote to itself");
        }        
      
        for (uint l = 0; l < proposals[_proposalAddress].voter.length; l++ ){
        
          // Check if voter has already casted vote for this proposal

                require(proposals[_proposalAddress].voter[l] != msg.sender, "Voter has already casted vote" );
        }
        
        // Cast the vote for this proposal
                proposals[_proposalAddress].voter.push(msg.sender);   
                voters[msg.sender].proposal.push(_proposalAddress);
                proposals[_proposalAddress].votersInRejection.push(msg.sender);
                proposals[_proposalAddress].voteCount += 1;
                proposals[_proposalAddress].countNo += 1;
                proposals[_proposalAddress].castNo[msg.sender] = true;
                voters[msg.sender].numOfVotes += 1;
        }
    
    function winningProposal() public onlyOwner returns (address) {
        for (uint8 prop = 0; prop < proposalAddress.length; prop++)
            if (proposals[proposalAddress[prop]].countYes > proposals[proposalAddress[prop]].countNo) {
                acceptedProposal.push(proposalAddress[prop]);
                proposals[proposalAddress[prop]].accepted = true;
            }
        for (uint8 acc = 0; acc < acceptedProposal.length; acc++) {    
            for (uint8 user = 0; user < proposals[acceptedProposal[acc]].votersInFavour.length; user++) {
                 yesVoters.push(proposals[acceptedProposal[acc]].votersInFavour[user]);
            }        
            depositTokens(yesVoters);
        }
    }
    
    function depositTokens(address[] yVoters) internal {
        token = ERC20(tokenAddress);
        
        for (uint8 u = 0; u < yVoters.length; u++) {
        // Add ERC20 tokens to user address
                token.transfer(yVoters[u], 1000);
        }
    }
}