/**
 *Submitted for verification at polygonscan.com on 2021-12-06
*/

pragma solidity ^0.5.10;

contract HelloWorld {
    // public 키워드: 컨트랙트블록 바깥에서도 변수 접근 가능
    // 다른 컨트랙트 혹은 sdk가 가치를 부를 수 있는 함수를 생성한다.
    string public message;

    constructor(string memory initMessage) public {
        // Takes a string value and stores the value in the memory data storage area,
        // setting 'message' to that value
        message = initMessage;
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }

}