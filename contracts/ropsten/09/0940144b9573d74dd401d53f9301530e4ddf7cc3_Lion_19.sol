/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

//Jinseon Moon
pragma solidity 0.8.0;

contract Lion_19 {
    
    mapping (address => bool) voters;
    mapping (string => uint) purposes;
    string[] purposes_list;
    
    function setPurposes(string memory _puposes) public{
        purposes_list.push(_puposes);
        purposes[_puposes] = 0;
    }
    
    
    function vote(string memory _puposes ,bool vote) public {
        require(voters[msg.sender] == false, "already voted");
        
        if(vote == true){
            purposes[_puposes] += 1;
        }
        
        voters[msg.sender] = true;
        
    }
    
    function CheckVote() public view returns(string memory) {
        if(voters[msg.sender] == true){
         return "already voted";
        } else {
            return "not voted";
        }
    }
    
    
    function AgreeRate(string memory _puposes) public view returns(uint){
        return purposes[_puposes] / 15 * 100;
    }
    
}