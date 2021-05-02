/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

contract Hello{
    string public name;
    
    constructor() public{
        name = "106501005 ㄉ智慧合約!";
    }
    
    function setName(string _name) public{
        name = _name;
    }
}