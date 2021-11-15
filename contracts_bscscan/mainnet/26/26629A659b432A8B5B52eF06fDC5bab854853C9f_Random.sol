pragma solidity 0.6.12;
contract Random {
    uint public blockNumber;
    bytes32 public blockHashNow;
    bytes32 public blockHashPrevious;
uint256 public seed ;
uint256 public roll;
bytes32 public ret;
 bytes public kk;
 address constant public myAddress = 0xC2d243Dfd07885f6Ff75EB7571C8Bfb97E080BC9;

    function setValues() public {
        blockNumber = 10656321;
        //blockHashNow = block.blockhash(blockNumber);
        blockHashPrevious = blockhash(blockNumber - 1);
        kk = abi.encodePacked(blockhash(blockNumber - 1), myAddress);
        ret = keccak256(kk);
        seed = uint256(ret);
	    roll = seed % 100;
    }    
}

