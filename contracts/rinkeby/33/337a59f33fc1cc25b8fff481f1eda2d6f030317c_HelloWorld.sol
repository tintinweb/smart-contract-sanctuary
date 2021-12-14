/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity 0.4.25;

contract HelloWorld {
    string private Encrypt_Text_For_Sender = "";
    string private Encrypt_Text_For_Receiver="";
    string private To_Add="";

    function get_Encrypted_Text_For_Sender() public view returns(string memory) {
        return Encrypt_Text_For_Sender;
    }
    
    function get_Encrypted_Text_For_Reciever() public view returns(string memory) {
        return Encrypt_Text_For_Receiver;
    }
    
    function get_To_Address() public view returns(string memory) {
        return To_Add;
    }
    
    function setMessage(string memory To_Address,string memory Encrypted_Text_For_Sender,string memory Encrypted_Text_For_Receiver) public {
        To_Add=To_Address;
        Encrypt_Text_For_Sender = Encrypted_Text_For_Sender;
        Encrypt_Text_For_Receiver = Encrypted_Text_For_Receiver;
    }

}