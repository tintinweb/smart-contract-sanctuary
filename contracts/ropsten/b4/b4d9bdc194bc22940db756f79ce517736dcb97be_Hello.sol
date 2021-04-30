/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

contract Hello{
    string public name;
    constructor()public{
        name="106403019!";
    }
    
    function setName(string _name) public{
        name=_name;
    }
}