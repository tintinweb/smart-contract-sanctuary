contract Part1 {
    address public owner;
    string public message = "sample";
    
    event Message();
    
    constructor(){
        owner = msg.sender;
    }
    
    function getOwner() constant public returns(address) {
        return owner;
    }
    
    function getMessage() constant public returns(string) {
        emit Message();
        return message;
    }
    
    function setOwner(address newOwner) public {
        owner = newOwner;
    }
}