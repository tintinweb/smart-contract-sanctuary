/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity 0.7.0; 

interface IERC20 {
    function transferFrom(address _token, address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _token, address _to, uint256 _value) external returns (bool success);
}

interface ERC20 {
    function allowance(address owner, address spender) external returns (uint256 amount);
    function balanceOf(address account) external view returns (uint256);
}

contract Vote {
    struct Voter {
        uint weight; 
        bool voted;
    }
    struct Proposal {
        bytes32 name; 
        uint voteCount; 
    }

    address immutable auer = msg.sender;
    mapping (address => Voter) voters;
    Proposal[] proposals;
    
    mapping(address => uint256) amounts;
    address tokenAddress = address(0);
    address transferAddress = address(0);
    uint lockTime;
    uint voteTime;
    uint releaseTime;
    uint amountMax;
    
   
    constructor(){
        
    }
    
    function initVote(bytes32[] memory proposalNames,address tokenAdr,uint locks,uint votes,uint releases,uint amount,address transfer) public {
        require(auer == msg.sender, "no author");
        require(transferAddress == address(0), "have init");
        require(tokenAdr == address(0), "address error");
     	tokenAddress = tokenAdr;
     	lockTime = locks;
     	voteTime = votes;
     	releaseTime = releases;
     	amountMax = amount;
        transferAddress = transfer;
        voters[auer].weight=1;
        for(uint i=0;i<proposalNames.length;i++){
            proposals.push(Proposal({
                name:proposalNames[i],
                voteCount:0
            }));
        }
    }
   
    function lockPosition(uint256 amount) public{
        require(block.timestamp * 1000 <= lockTime,"lockTime end");
        require(ERC20(tokenAddress).allowance(msg.sender,transferAddress) >= amount,"approve error");
        IERC20(transferAddress).transferFrom(tokenAddress,msg.sender, transferAddress , amount);
        if(amounts[msg.sender]>0){
            amounts[msg.sender] = amounts[msg.sender] + amount;
        }else{
            amounts[msg.sender] = amount;
        }
        if(amounts[msg.sender]>=amountMax){
          if(!voters[msg.sender].voted&&voters[msg.sender].weight==0){
              voters[msg.sender].weight=1;
          }
        }
    }
    
    function withdraw() public {
        require(block.timestamp * 1000 >= releaseTime,"no releaseTime");
        require(amounts[msg.sender]>0,"no amount");
        require(ERC20(tokenAddress).balanceOf(transferAddress) >= amounts[msg.sender],"no enough amount");
        IERC20(transferAddress).transfer(tokenAddress,msg.sender, amounts[msg.sender]);
        amounts[msg.sender] = 0;
        voters[msg.sender].weight = 0;
    }

    function vote(uint proposal) public{
        require(block.timestamp * 1000 <= voteTime,"voteTime end");
        require(proposal<proposals.length,"proposal error");
        Voter memory sender = voters[msg.sender];
        require(!sender.voted && sender.weight > 0, "already voted");
        voters[msg.sender].voted = true;
        proposals[proposal].voteCount = proposals[proposal].voteCount + sender.weight;
    }

    function getWinProposal() public view virtual returns(uint[] memory){
        uint winCount = 0;
        for(uint proposal = 0; proposal <proposals.length; proposal++){
            if(winCount < proposals[proposal].voteCount){
                winCount = proposals[proposal].voteCount;
            }
        }
        uint[] memory win = new uint[](0);
        if(winCount > 0){
            uint len = 0;
            for(uint proposal = 0; proposal <proposals.length; proposal++){
                if(winCount == proposals[proposal].voteCount){
                    len = len + 1;
                }
            }
            win = new uint[](len);
            uint idx = 0;
            for(uint proposal = 0; proposal <proposals.length; proposal++){
                if(winCount == proposals[proposal].voteCount){
                    win[idx] = proposal;
                    idx = idx + 1;
                }
            }
        }
        return win;
    }
    
    function getBlockTime() public view virtual returns (uint256){
        return block.timestamp * 1000;
    }
    
    function getVoteCount(uint proposal) view virtual public returns(uint){
        return proposals[proposal].voteCount;
    }
    
      
    function getName(uint proposal) view virtual public returns(bytes32){
        return proposals[proposal].name;
    }

}