/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// GyungHwan Lee

pragma solidity 0.8.0;

contract likelion_3 {
    // list type[] name;
    uint[] numbers;
    
    string[] names;
    
    function ex() public returns (uint, uint) {
        uint n = 0;
        uint c = 0;
        
        for(uint a = 1; a <= 25 ; a ++){
            if ( a%2 == 0){
                continue;
            }else if( a%3 == 0){
                continue;
            }else if ( a%5 == 0){
                continue;
            }else if ( a%7 == 0){
                continue;
            }else{
                n += a;
                c += 1;
            }
            numbers.push(a);
        }
        return (n, c);
    }
    function getnumbers(uint a) public view returns (uint) {
        return numbers[a-1];
    }
}