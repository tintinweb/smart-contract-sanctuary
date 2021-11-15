pragma solidity 0.6.12;
contract Random {
    uint public blockNumber;
    bytes32 public blockHashNow;
    bytes32 public blockHashPrevious;
uint256 public seed ;
uint256 public roll;
    function setValues() public {
        blockNumber = 10656321;
        //blockHashNow = block.blockhash(blockNumber);
        blockHashPrevious = blockhash(blockNumber - 1);
        seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), '0xc2d243dfd07885f6ff75eb7571c8bfb97e080bc9')));
	    roll = seed % 100;
    }    
}

