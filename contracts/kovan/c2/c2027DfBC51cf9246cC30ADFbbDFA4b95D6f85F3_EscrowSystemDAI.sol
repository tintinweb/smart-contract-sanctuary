/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

pragma solidity ^0.8.10;

    interface DaiToken {
    function balanceOf(address guy) external view returns (uint);
    
    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
 
contract EscrowSystemDAI {

constructor()  public{
        daitoken = DaiToken(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }
DaiToken daitoken;




    fallback() external payable {
       
    }
     struct Voter {      
        bool[99] voted;  
        uint[99] VoteWeight;
        address[99] ProposalAddress;
        bool[99] funded;
        uint[99] AmountFunded;
        uint[99] round;
        uint b;
    }
    struct Proposal {
        uint TotalVoterCount;
        uint CurrentVoteTally;
        uint round;
        string[99] RoundDescription;
        string Description;
        uint AmountFunded;
        address ProposalAddress;
        uint total;
        uint[99] RequestedAmounts;
        uint i;
        uint ReturnFundsVote;
        bool setamountaddress; 
        uint TotalChecker;
        bool FundsReleased;
}
        mapping(address => Voter) public voters;
        mapping(address => Proposal) public Proposals;

       

        function FundProposal(uint amount, address ProposalAddress, uint identifier) public {
        
        require(amount>0);
        Voter storage sender = voters[msg.sender];
        Proposal storage proposal1 = Proposals[ProposalAddress];
        amount=amount*1000000000000000000;
        daitoken.transferFrom(msg.sender, address(this), amount);
        proposal1.AmountFunded=proposal1.AmountFunded+amount;

        if (!sender.funded[identifier]){
        sender.funded[identifier] = true;
        sender.ProposalAddress[identifier]=ProposalAddress;
        proposal1.TotalVoterCount++; 
        }
        
        sender.AmountFunded[identifier]=sender.AmountFunded[identifier]+amount;
        
            }

     function vote (int number, address ProposalAddress, uint identifier) public  {
       

        Voter storage sender = voters[msg.sender];
        Proposal storage Proposal = Proposals[ProposalAddress];
        //VotingAllowed;
        //address payable ProposalAddressPayable= payable(sender.ProposalAddress[identifier]);
        if(sender.round[identifier]==0){
            sender.round[identifier]++;
        }

             require(Proposal.round == sender.round[identifier] && sender.funded[identifier] == true && sender.ProposalAddress[identifier] == ProposalAddress );
            

              if (number>0){
            Proposal.CurrentVoteTally=Proposal.CurrentVoteTally+sender.AmountFunded[identifier];
        }
        else {
            Proposal.ReturnFundsVote=Proposal.ReturnFundsVote+sender.AmountFunded[identifier];
        }
     //   Proposal.AmountVoted++;
         
        //Proposal.VoterRatio = (Proposal.AmountVoted/Proposal.TotalVoterCount);
        sender.round[identifier]++;
         }



function MakeProposal (uint amount, address payable Deposit, string memory Description) public payable {
Proposal storage proposal1 = Proposals[Deposit];
require (proposal1.setamountaddress != true);
amount=amount*1000000000000000000;
proposal1.Description=Description;
proposal1.total=amount;
proposal1.ProposalAddress=Deposit;
proposal1.round++;
proposal1.setamountaddress=true;
}

function RequestAmounts (uint amount, address payable ProposalAddress, string memory RoundDescription) public payable returns(uint){
    require (ProposalAddress == msg.sender);
    Proposal storage proposal1 = Proposals[ProposalAddress];
  
   

if ((proposal1.TotalChecker+amount)<=(proposal1.total)){
   if(proposal1.i<=0){
       //proposal1.RequestedAmounts[proposal1.i]=0;
       proposal1.RequestedAmounts[0]=0;
        proposal1.i++;
    }
    amount=amount*1000000000000000000;
    proposal1.RequestedAmounts[proposal1.i]=amount;
    proposal1.RoundDescription[proposal1.i]=RoundDescription;
    proposal1.TotalChecker = proposal1.TotalChecker+proposal1.RequestedAmounts[proposal1.i];
    proposal1.i++;
}
else{}
}


function GetProposalDetails(address ProposalAddress)public view returns (uint[5] memory){
Proposal storage proposal1 = Proposals[ProposalAddress];
uint[5] memory ProposalDetails;
uint a;
uint ProposalFundsSpent;
    for (a=0; a<proposal1.round; a++){
        ProposalFundsSpent=ProposalFundsSpent+proposal1.RequestedAmounts[a];

    }
ProposalDetails[0]=proposal1.total;
ProposalDetails[1]=proposal1.AmountFunded;
ProposalDetails[2]=proposal1.RequestedAmounts[proposal1.round];
ProposalDetails[3]=proposal1.CurrentVoteTally;
ProposalDetails[4]=ProposalFundsSpent;
    return ProposalDetails;

}
function GetRequestAmounts(address payable ProposalAddress, uint position) public  view  returns (uint) {
Proposal storage proposal1 = Proposals[ProposalAddress];
    return proposal1.RequestedAmounts[position];
}


function GetTotal(address payable ProposalAddress) public view  returns(uint){
Proposal storage proposal1 = Proposals[ProposalAddress];
return proposal1.total;
}

function GetRoundDescription(address ProposalAddress) public view returns (string memory){
    Proposal storage proposal1 = Proposals[ProposalAddress];
    return proposal1.RoundDescription[proposal1.round];
}

function GetDescription(address ProposalAddress) public view returns(string memory){
    Proposal storage proposal1 = Proposals[ProposalAddress];
    return proposal1.Description;
}






    function releasefunds(address ProposalAddress) public payable {
    Proposal storage proposal1 = Proposals[ProposalAddress];
    require (proposal1.AmountFunded >= proposal1.total);
    require (proposal1.CurrentVoteTally>((proposal1.total/100)*90));
    address payable ProposalAddressPayable = payable(ProposalAddress);
    daitoken.approve(ProposalAddressPayable, proposal1.RequestedAmounts[proposal1.round]);
    daitoken.transferFrom(address(this), ProposalAddressPayable, proposal1.RequestedAmounts[proposal1.round]);
    proposal1.round++;
    
    
        proposal1.CurrentVoteTally=0;
    
    }
    function GetBalance () public view returns (uint){
        return address(this).balance;

    }
   

    function ReturnFunds(uint identifier, address ProposalAddress) public payable{
    Voter storage sender = voters[msg.sender];    
    Proposal storage proposal1 = Proposals[ProposalAddress];
    require (proposal1.ReturnFundsVote>((proposal1.total/100)*10));
    
    uint a;
    uint SenderRefund;
    uint ProposalFundsSpent;
    uint ProposalFundsLeft;

    for (a=0; a<proposal1.round; a++){
        ProposalFundsSpent=ProposalFundsSpent+proposal1.RequestedAmounts[a];

    }
    
    ProposalFundsLeft=proposal1.total-ProposalFundsSpent;
    SenderRefund=(sender.AmountFunded[identifier]*100);
    SenderRefund=(SenderRefund/proposal1.total);
    SenderRefund=(SenderRefund*(ProposalFundsLeft));
    SenderRefund=SenderRefund/100;
    daitoken.approve(msg.sender, SenderRefund);
    daitoken.transferFrom(address(this),msg.sender, SenderRefund);
   
    }

   



  


}