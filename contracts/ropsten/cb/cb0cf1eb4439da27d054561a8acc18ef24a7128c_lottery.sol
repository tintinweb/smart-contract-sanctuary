/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity >=0.4.22 < 0.6.8;

contract lottery {

    string[] public prizes;
    
    constructor(string memory initMessage) public {
        prizes.push(initMessage);
    }
    
    function addPrize(string memory _addPrize) public {
        prizes.push(_addPrize);            
    }

    function getPrizeCount() public view returns(uint) {
        return prizes.length;
    }
    
    function getPrize() public view returns(string memory){
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now)));
        uint256 _length = prizes.length;
        return prizes[random%_length];            
    }
    
}