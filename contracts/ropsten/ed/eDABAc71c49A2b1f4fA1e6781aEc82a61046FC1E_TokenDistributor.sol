/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.4.25;

/**
 * This is library to add additiioiond substractiion functions into smart contract
 * */
contract SafeMath
{
    function add(uint256 a, uint256 b) internal pure returns (uint)
    {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint)
    {
        assert(b <= a);
        return  a - b;
    }
}  
contract TokenDistributor is SafeMath
{
    uint256 public totalSupply;
    string public name;
    string public symbol;
    address public owner;
    
    struct VotingData
    {
        address voter;
        string status;
    }
    
    VotingData[]  VotingArray;
    mapping(address => uint256) investorBal; //Maps the address with their token balance
    mapping(address => string) investorVoteStatus; // Maps the address with the vote they give (GOOD or BAD);
    
    event VotingStatus(address, string); // Event To write information when voting is done 
    event DistriBute(address, uint256); // Event to write information ahen distribute happens
    /**
     * Contructor function to create token having symbol, total supply, and updates admin balance
     **/
    constructor(string memory name_, string memory symbol_, uint256 totalsupply_) public
    {
        name = name_;
        symbol = symbol_;
        totalSupply = totalsupply_;
        owner = msg.sender;
        investorBal[owner]= totalsupply_;
    }
    
    /**
     * GetVoterStatus Returns the voting status if it is good or bad
     * **/
    function getVoterStatus(address who) public view returns(string memory)
    {
        return investorVoteStatus[who];
    }
  
    function RegisterInvestorVote(string votingStatus) public returns(bool)
    {
        require(investorBal[msg.sender] > 5,"Voting cannot be done due to less token holding");
        investorVoteStatus[msg.sender] = votingStatus;
        address own =   msg.sender;
        VotingData memory localStruct ;
        localStruct.voter = msg.sender;
        localStruct.status = votingStatus;
        VotingArray.push(localStruct);
        emit VotingStatus(own, votingStatus);
        return true;
       
    }
    function distributeTokenByAdmin(address who, uint8 amount) public returns(bool)
    {
        require(msg.sender == owner, "Only admin can call this API");
        require(investorBal[owner] > amount , "Admin does not have sufficient balance");
        investorBal[owner] = sub(investorBal[owner],amount);
        investorBal[who] = add(investorBal[who],amount);
        emit DistriBute( msg.sender,amount);
        return true;
    }
    function getBalanceOfToken(address who) public view returns(uint256)
    {
        return investorBal[who];
    }
   
}