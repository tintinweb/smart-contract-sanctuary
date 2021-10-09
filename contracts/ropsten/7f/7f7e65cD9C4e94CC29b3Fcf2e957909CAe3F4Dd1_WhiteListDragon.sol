/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

contract WhiteListDragon {
    
    constructor(string memory args){

    }

    mapping(address => bool) _whiteList;
    
    function addWhiteList(address[] memory owners) public {
        for (uint32 i = 0 ; i < owners.length ; i ++) {
            _whiteList[owners[i]] = true;
        }
    }
}