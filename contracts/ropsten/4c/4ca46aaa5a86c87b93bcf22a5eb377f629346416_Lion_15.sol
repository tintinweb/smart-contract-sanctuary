/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//Jinseon Moon
pragma solidity 0.8.1;

contract Lion_15 {
    string[] listTx;
    bytes32 roothash;
    
    
    function PutTx(string memory a) public {
        string[] memory templist;
        
        if(listTx.length < 4){
            
            listTx.push(a);    
        }
        
        
        if(listTx.length == 1){
            roothash = keccak256(abi.encodePacked(listTx[0], listTx[0]));
            
        }else if(listTx.length ==2) {
            roothash = keccak256(abi.encodePacked(listTx[0], listTx[1]));
        }else if(listTx.length == 3) {
            roothash = keccak256(abi.encodePacked(listTx[0], listTx[1], listTx[2], listTx[2]));
        }else if(listTx.length == 4){
            roothash = keccak256(abi.encodePacked(listTx[0], listTx[1], listTx[2], listTx[3]));
        }
    }
    
    
    function getRoothash() public view returns(bytes32, string[] memory){
        return(roothash, listTx);
    }
    
    function checkTx(string memory a) public view returns(bool){
        
        if(listTx.length ==1){
            
        }else if(listTx.length == 2) {
            
        }else if(listTx.length == 3) {
            
        }else if(listTx.length == 4) {
            
        }
        
    }
    
}