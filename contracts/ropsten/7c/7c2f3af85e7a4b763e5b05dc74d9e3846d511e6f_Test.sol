pragma solidity ^0.5.2;

contract Test{
    
    string private message = &#39;Hello World!&#39;;
    address owner = 0xee02C889aC99335327847fb8f8097b5ecA1Ae43e;
    
    modifier onlyOwner(){
        if(msg.sender != owner){
            revert();
        }
        _;
    }
    
    function getMessage() public view returns(string memory _message){
        return message;
    }    
    
    function setMessage(string memory _message) public onlyOwner {
        message = _message;
    }
}