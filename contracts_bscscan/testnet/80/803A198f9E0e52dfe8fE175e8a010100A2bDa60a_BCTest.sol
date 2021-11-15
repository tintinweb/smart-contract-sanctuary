pragma solidity >=0.4.22 <0.9.0;

contract BCTest {
    uint stt = 1;

    function welcome(uint _stt) external pure returns (uint) {
        return _stt * uint(keccak256(abi.encodePacked(_stt)));
    }
}

