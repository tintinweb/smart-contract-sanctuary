/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// Younwoo Noh

/*
3. 1부터 25까지의 숫자중에서 2,3,5,7로 나누어 떨어지지 않는 숫자들의 합과 개수 그리고 이들을 보관하고 있는 배열을 구하시오. 
합과 개수는 1개의 함수에서 볼 수 있어야 하며, 배열 내 몇번째 요소가 무엇인지 알 수 있게 해주는 함수가 필요하다.
*/


pragma solidity 0.8.0;

contract Likelion_3 {
    
    uint[] numbers;
    uint a = 1;
    uint b = 0;
    uint count = 0;
    uint sum = 0;
    
    function div(uint a, uint b) public view returns(uint sum, uint count) {
        for(a=1; a<=25; a++) {
            if(a%2 != 0) {
                sum += a;
                count += 1;
                a++;
            }
        }
    }
    
    function pushn1(uint a) public {
        numbers.push(a);
    }
    
    function get(uint a) public view returns(uint){
        return numbers[a-1];
    }
}