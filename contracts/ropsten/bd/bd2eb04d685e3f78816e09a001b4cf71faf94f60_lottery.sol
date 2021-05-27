/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity >=0.4.22 < 0.6.8;

contract lottery {

    string[] public prizes;
    string prize;

    
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
        uint256 index = random%_length;
        prize = prizes[index];
        for (uint i = index; i < prizes.length - 1; i++){
            prizes[i] = prizes[i + 1];
        }
        delete prizes[prizes.length - 1];    
    }
    
}