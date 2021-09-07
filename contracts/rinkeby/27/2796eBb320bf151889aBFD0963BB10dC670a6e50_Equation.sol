pragma solidity ^0.6.6;

contract Equation{
    uint256 public equationResult;
     uint256 public _number;
     uint256 public i;

    function equation () public returns (uint256) {

        bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) ));
           //bytes2 equation = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes2(predictableRandom[2]) >> 16 );
        uint256 base = 35+((55*uint256(uint8(predictableRandom[3])))/255);



      _number = 100+((55*uint256(uint8(predictableRandom[3])))/255) / 2;

     equationResult = ((_number +block.timestamp * base) % base);
     i =  equationResult % 2;


     
    }

    function getEquationResult() public view returns(uint256){
        return equationResult;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}