/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity 0.8.0;


contract Likelion_15 {
    //YunJun Lee

    // bytes32[] Merkle;
    // uint[] transactions;

    
    // function pushTransaction(uint _transaction) public {
    //     transactions.push(_transaction);
    // }

    // function makeMerkle() public{


    //     for (uint i=0; i<transactions.length; i+=2){
    //         bytes32 tree =keccak256(abi.encodePacked(transactions[i], transactions[i+1])) ;
    //          Merkle.push(tree) ;
    //     }
    //     for(uint i=0; i<Merkle.length; i+=2){
    //         Merkle.push(keccak256(abi.encodePacked(Merkle[i], Merkle[i+1])));
    //         //delete Merkle[0] ;
    //         //delete Merkle[0] ;
    //         //i-=1;
    //     }
        
    //     //return Merkle[0];
    // }
    //     function showMerkle2() public returns (bytes32) {
        
    //     return Merkle[Merkle.length-1];
    // }
    
    function f(uint a, uint b, uint c, uint d, uint e, uint f) public view returns(uint){
        uint count =0;
        if (a%2==0){
            count+=1;
        }
        if (b%2==0){
            count+=1;
        }
        if (c%2==0){
            count+=1;
        }
        if (d%2==0){
            count+=1;
        }
        if (e%2==0){
            count+=1;
        }
        if (f%2==0){
            count+=1;
        }
        return count;
    }
    
}