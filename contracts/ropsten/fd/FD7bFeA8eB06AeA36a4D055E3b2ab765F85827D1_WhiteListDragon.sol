/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

contract WhiteListDragon {
    

    mapping(address => bool) public whiteList;    
    
    function addWhiteList(address[] memory owners) public {

        for (uint32 i = 0 ; i < owners.length ; i ++) {
            whiteList[owners[i]] = true;
        }
    }
}