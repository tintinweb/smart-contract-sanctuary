/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity >=0.4.21 <0.6.0 ;

contract decision{
	
	struct Voter{
		
		uint weight;  
		bool voted;
		address delegate;
		uint vote;  
	}

	struct Proposal{
		
		bytes32 name;
		uint votecount;

	}

	address public chairman;

	mapping(address => Voter) public voters;


	Proposal[] public proposals;

	constructor(bytes32[] memory proposalname) public {
			chairman = msg.sender;
			voters[chairman].weight=1;
			
			for(uint i=0;i<proposalname.length;i++){
				
				proposals.push(
					Proposal({
						name:proposalname[i],
						votecount:0
					})	
				);

			}

	}
  

	function getright2voter(address voter) public {
		
			require(msg.sender == chairman);

			require(!voters[voter].voted);

			require(voters[voter].weight !=0 );

			voters[voter].weight=1;
			
	}

	function delegate(address to) public {
		
		Voter storage sender = voters[msg.sender];

		require(!sender.voted);

		require(to!=msg.sender);

		while(voters[to].delegate!=address(0)){
			
			to = voters[to].delegate;

			require(to != msg.sender);
		}

		sender.voted = true;
		sender.delegate = to;
		if(voters[to].voted){
			proposals[voters[to].vote].votecount+=sender.weight;
		}else{
			voters[to].weight+=sender.weight;
		}

	}

	function vote(uint proposal) public {
		
		Voter storage voter = voters[msg.sender];

		require(!voter.voted);
	
		proposals[proposal].votecount += voter.weight;
		
		voter.voted = true;
		voter.vote = proposal;

	}

	function winnerProposal() public  view returns(uint proposal){
		
	uint	winnerproposal  = 0;
		for(uint i=0;i<proposals.length;i++){
			if(winnerproposal<proposals[i].votecount){
				winnerproposal = proposals[i].votecount;
				proposal = i;
			}
		}

		
	}

	function winnername() public view returns(bytes32 name){

		name = proposals[winnerProposal()].name;
	}
	

}