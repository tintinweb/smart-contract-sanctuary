/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

contract infoAboutMe
{
    string name;
    string info;
    address owner;
    constructor (string memory _name, string memory _info)
    {
        name = _name;
        info = _info;
        owner = msg.sender;
    }
    
    modifier OnlyOwner(){
        require(msg.sender == owner, "Only owner can do this!");
        _;
    }
    
    function getName() public view returns(string memory)
    {
        return name;
    }
    function getInfo() public view returns(string memory)
    {
        return info;
    }
    function setInfo(string memory _info) OnlyOwner public 
    { 
      info = _info;
    }
}