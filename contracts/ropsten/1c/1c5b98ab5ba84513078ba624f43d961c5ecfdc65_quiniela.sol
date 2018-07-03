pragma solidity ^0.4.24;


contract quiniela{
    
    struct user{
        bool used;
        uint place1;
        uint place2;
        uint place3;
        string name;
        uint256 date;
        bool voted;
        
    }
    
    address [] public winners;
   
    bool public toVote;
    uint public votes;
    uint public antiVotes;
    
    address [] public players;
    mapping (uint => string) public teams;
    address public constant admin= 0x001f6896B61406CC8dAe25401a591447956f8ACa;
    mapping (address => user) public users;
    
    uint public constant cost= .2 ether;
    
    
    constructor() public{
        teams[1]= &quot;Germany&quot;;
        teams[2]= &quot;Argentina&quot;;
        teams[3]= &quot;Australia&quot;;
        teams[4]= &quot;Belgium&quot;;
        teams[5]= &quot;Brazil&quot;;
        teams[6]= &quot;Colombia&quot;;
        teams[7]= &quot;Costa Rica&quot;;
        teams[8]= &quot;Croatia&quot;;
        teams[9]= &quot;Denmark&quot;;
        teams[10]= &quot;Egypt&quot;;
        teams[11]= &quot;England&quot;;
        teams[12]= &quot;France&quot;;
        teams[13]= &quot;Iceland&quot;;
        teams[14]= &quot;Ir Iran&quot;;
        teams[15]= &quot;Japan&quot;;
        teams[16]= &quot;Korea Republic&quot;;
        teams[17]= &quot;Mexico&quot;;
        teams[18]= &quot;Morocco&quot;;
        teams[19]= &quot;Nigeria&quot;;
        teams[20]= &quot;Panama&quot;;
        teams[21]= &quot;Peru&quot;;
        teams[22]= &quot;Poland&quot;;
        teams[23]= &quot;Portugal&quot;;
        teams[24]= &quot;Russia&quot;;
        teams[25]= &quot;Saudi Arabia&quot;;
        teams[26]= &quot;Senegal&quot;;
        teams[27]= &quot;Serbia&quot;;
        teams[28]= &quot;Spain&quot;;
        teams[29]= &quot;Sweden&quot;;
        teams[30]= &quot;Switzerland&quot;;
        teams[31]= &quot;Tunisia&quot;;
        teams[32]= &quot;Uruguay&quot;;
    }
    
    modifier onlyAdmin() {
        
        require(msg.sender == admin);
        _;
    }

    
    function addUser(uint _place1, uint _place2, uint _place3, string _name, string _password)public  payable{
        require(test(_password)); 
        require(!users[msg.sender].used);
        users[msg.sender].place1=_place1;
        users[msg.sender].place2=_place2;
        users[msg.sender].place3=_place3;
        
        users[msg.sender].name=_name;
        users[msg.sender].date=now;
        users[msg.sender].used=true;
        players.push(msg.sender);
    }
    
    function test(string _cad) private pure returns(bool){
        return keccak256(_cad) == 0x5ef430484c393ecf4ebdc9c8b2de0ccf64d0ff112c2248638324da4f239c0a57;
    }
    
    function setWinners(address [] _winners) public onlyAdmin(){
       require(!toVote);
       winners= _winners;
       toVote= true;
     
    }
    
    function winnersLength() public constant returns(uint){
        return winners.length;
    }
    
    function vote(bool _vote) public returns (bool){
        require(toVote);
        require(users[msg.sender].voted == false);
        users[msg.sender].voted=true;
        
        if(_vote){
            votes+=1;
            if(votes > (playersLength()/2)){
                payMoney();
            }
        }else{
            antiVotes+=1;
            if(antiVotes > (playersLength()/2)){
                returnMoney();
            }
        }
        
        
        
        return true;
    }
    
    function payMoney() private{
        uint toPay= address(this).balance/(winners.length);
        
        for(uint x= 0;x<winners.length-1;x++){
            winners[x].transfer(toPay);
        }
        winners[(winners.length)-1].transfer(address(this).balance);
    }
    
    function returnMoney() private{
        
        for(uint x=0; x< playersLength()-1;x++){
            players[x].transfer(cost);
        }
    }
    
    function playersLength() public constant returns(uint){
        return players.length;
    }
    
     /* Function to recover the funds on the contract */
    function kill() public onlyAdmin() {
        selfdestruct(admin);
    }
    
    
    
    
}