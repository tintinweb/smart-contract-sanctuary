/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

contract pic_board{
    string private wellcome_pictext;
    string private description;
    
        
    mapping(string=>string) picSet;
    string[] picNames;
    
    string avoidcoli;
    
    
    constructor(string  memory _wellcomePicText, string memory _description) public {
        wellcome_pictext = _wellcomePicText;
        description = _description;
    }
    
    function rt_wellcome_pictext() public view returns(string memory)
    {
        return wellcome_pictext;
    }
    
    
    function rt_description() public view returns(string memory)
    {
        return description;
    }
    
    
    
    function addPic(string memory _name, string memory _editPic) public
    {
        picSet[_name] = _editPic;
        picNames.push(_name);
    }
    
    function getallName() public view returns(string[] memory)
    {
        return picNames;
        
        
        //pragma experimental ABIEncoderV2;
    }
    
    function showPic(string memory _name) public view returns(string memory)
    {
        return picSet[_name];
    }
    

}