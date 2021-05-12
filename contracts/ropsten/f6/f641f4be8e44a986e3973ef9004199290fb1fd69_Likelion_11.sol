/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_11 {
    string[] class = ["Ava","Becky","Charlse","Devy","Elice","Fabian"];
    
    function total() public view returns(uint,uint) {
        return(class.length,10-class.length);
    }
    function append(string memory a) public {
        class.push(a);
    }
    function check() public view returns(bool){
        bool result = false;
        for(uint i=0; i<class.length; i++){
            if(keccak256(bytes(class[i]))==keccak256(bytes("Sophia"))){
                result = true;
                return(result);
            }
        }
    }
}