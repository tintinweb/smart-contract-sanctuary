/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity >=0.4.22 <0.7.0;

contract pic_board{
    string public wellcome_pictext;
    string public description;
    
        
    mapping(string=>string) picSet;
    string[] picNames;
    
    
    constructor(string  memory _wellcomePicText, string memory _description) public {
        wellcome_pictext = _wellcomePicText;
        description = _description;
    }
    
    
    function addPic(string memory _name, string memory _editPic) public
    {
        picSet[_name] = _editPic;
        picNames.push(_name);
    }
    
    
    function showPic(string memory _name) public view returns(string memory)
    {
        return picSet[_name];
    }
    

}