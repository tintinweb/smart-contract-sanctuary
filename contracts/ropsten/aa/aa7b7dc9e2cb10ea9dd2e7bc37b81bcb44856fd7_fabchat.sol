/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// Ropsten account address - 0x725e7d1770Eb5fe54dd7f8c69211F47f6AC4E752
// Contract - 0xAa7B7DC9e2cB10ea9dd2e7bc37b81bcB44856fD7
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract fabchat {
    
    struct message{
        string msg;
        string username;
        uint flags;
        bool anonymity;
        address[] flaggers;
    }
    
    struct shmsg{
        string msg;
        string username;
    }
    
    string[] usernames=["admin"];
    mapping (address => bool) private Postedmsg;
    mapping (address => string) private Users;
    message[] messages;
    uint postedusers=0;
    uint registeredusers=0;
    
    // compare whether two strings are equal
    function stringcompare(string memory a, string memory b) internal returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        }
        else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }
    
    // users register by providing usernames
    function register(string memory userName) public {
       // cannot register twice        
       require(bytes(Users[msg.sender]).length==0,"Already registered");   
       
       // cannot take already registered username
       uint k=0;    
       for (uint p = 0; p < usernames.length; p++) {
           if(stringcompare(usernames[p],userName)==true){
               k=1;
               break;
           }
       }
       require(k!=1,"Username Taken");
       usernames.push(userName);
       registeredusers+=1;
       Users[msg.sender]=userName;
       Postedmsg[msg.sender]=false;
    }
    
    // post anonymous messages by paying a certain amount of fee, 100 wei
    function sendanonymousmsg(string memory userMsg, string memory userName) public payable{
        require(msg.value>=100 wei,"Not enough funds provided");
        require(bytes(Users[msg.sender]).length>0,"Please register to send messages");
        string memory comp=Users[msg.sender];
        require(stringcompare(comp,userName)==true,"Please post with correct username");
        
        address[] memory temp;
        messages.push(message({
                msg: userMsg,
                username: userName,
                flags: 0,
                anonymity:true,
                flaggers:temp
            }));
            
        if(Postedmsg[msg.sender]==true){
            postedusers++;
        }
        Postedmsg[msg.sender]=true;
    }
    
    
    // post non-anonymous messages free of cost
    function sendnonanonymousmsg(string memory userMsg, string memory userName) public{
        require(bytes(Users[msg.sender]).length>0,"Please register to send messages");
        string memory comp=Users[msg.sender];
        require(stringcompare(comp,userName)==true,"Please post with correct username");
        
        address[] memory temp;
        messages.push(message({
                msg: userMsg,
                username: userName,
                flags: 0,
                anonymity:false,
                flaggers:temp
            })); 
        
        if(Postedmsg[msg.sender]==true){
            postedusers++;
        }
        Postedmsg[msg.sender]=true;
    }
    
    // flag message
    function flagmsg(uint msgnumber) public{
        require(bytes(Users[msg.sender]).length>0,"Please register to flag messages");
        require(msgnumber>=0 && msgnumber<messages.length, "Please enter correct msg number");
        require(stringcompare(Users[msg.sender],messages[msgnumber].username)==false, "cannot flag own message");
        
        // cannot flag same message twice
        uint k=0;
        for (uint p = 0; p < messages[msgnumber].flaggers.length; p++) {
            if(messages[msgnumber].flaggers[p]==msg.sender){
                k=1;
                break;
            }
        }
        require(k!=1,"Cannot flag same message twice");
        
        messages[msgnumber].flags+=1;
        messages[msgnumber].flaggers.push(msg.sender);
        
        // if no. of flags is greater than half the number of registered users
        if(messages[msgnumber].flags>(registeredusers/2)){
            // anonymous post's username is revealed while querying
            if(messages[msgnumber].anonymity==true){
                messages[msgnumber].anonymity=false;
            }
            // non-anonymous post is removed
            else{
                delete messages[msgnumber];
                messages[msgnumber]=messages[messages.length-1];
                messages.pop();
                
            }
        }
        // if an anonymous post is made non-anonymous, then it requires only 1 more flag to be removed
    }
    
    // get single message by msgid
    function getmsg(uint msgid) public view returns (string memory, string memory){
        require(bytes(Users[msg.sender]).length>0,"Please register to see messages");
        require(msgid>=0 && msgid<messages.length, "Please enter correct msg number");
        string memory Msg=messages[msgid].msg;
        string memory Username;
        if(messages[msgid].anonymity==true){
            Username="Anonymous";
        }
        else{
            Username=messages[msgid].username;
        }
        return (Msg,Username);
    }
    
    // get all messages
    function getallmessages() public view returns (shmsg[] memory){
        require(bytes(Users[msg.sender]).length>0,"Please register to see messages");
        shmsg[] memory temp= new shmsg[](messages.length);
        for (uint p = 0; p < messages.length; p++) {
            temp[p].msg=messages[p].msg;
            if (messages[p].anonymity == true) {
                temp[p].username="Anonymous";
            }
            else{
                temp[p].username=messages[p].username;
            }
        }
        return temp;
    
        
    }
}