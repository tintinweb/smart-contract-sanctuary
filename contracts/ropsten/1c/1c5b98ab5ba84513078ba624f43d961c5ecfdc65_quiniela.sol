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
        teams[1]= "Germany";
        teams[2]= "Argentina";
        teams[3]= "Australia";
        teams[4]= "Belgium";
        teams[5]= "Brazil";
        teams[6]= "Colombia";
        teams[7]= "Costa Rica";
        teams[8]= "Croatia";
        teams[9]= "Denmark";
        teams[10]= "Egypt";
        teams[11]= "England";
        teams[12]= "France";
        teams[13]= "Iceland";
        teams[14]= "Ir Iran";
        teams[15]= "Japan";
        teams[16]= "Korea Republic";
        teams[17]= "Mexico";
        teams[18]= "Morocco";
        teams[19]= "Nigeria";
        teams[20]= "Panama";
        teams[21]= "Peru";
        teams[22]= "Poland";
        teams[23]= "Portugal";
        teams[24]= "Russia";
        teams[25]= "Saudi Arabia";
        teams[26]= "Senegal";
        teams[27]= "Serbia";
        teams[28]= "Spain";
        teams[29]= "Sweden";
        teams[30]= "Switzerland";
        teams[31]= "Tunisia";
        teams[32]= "Uruguay";
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