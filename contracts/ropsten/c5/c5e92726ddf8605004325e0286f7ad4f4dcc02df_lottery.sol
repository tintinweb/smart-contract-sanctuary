/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity >=0.4.22 < 0.6.8;

contract lottery {

    string[] public prizes;
    string public prize;

    
    function addPrize(string memory _addPrize) public {
        prizes.push(_addPrize);            
    }

    function getPrizeCount() public view returns(uint) {
        return prizes.length;
    }
    
    function getPrize() public view returns(string memory){
        return prize;     
    }
    
    function deletePrize() public {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now)));
        uint256 _length = prizes.length;
        prize = prizes[random%_length];
        prizes[random%_length] = prizes[prizes.length - 1];
        prizes[prizes.length - 1] = prize;
        prizes.pop();
    }
}