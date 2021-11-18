/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.5.1;
contract HiWorld2{
    
    bool StatusLight;
    uint256 MyOpen = block.timestamp + 60;
    uint256 AlbinaOpen = block.timestamp + 60*40;
    uint256 AllOpen = block.timestamp + 60*60*10;
    
    address owner;
    address AlbinaAdress;
    
    enum Light{Green, Yellow, Red}
    Light lght;
    
    constructor() public{
       StatusLight = true;
       lght = Light.Green;
       owner = msg.sender;
       AlbinaAdress = 0x47C1C218f11077ef303591cb6B2056DC6ea3063F;
    }
    
    modifier timeOpen(){
        uint256 timeB = block.timestamp;
        require(
        (timeB>MyOpen && msg.sender == owner)
        ||(timeB>AlbinaOpen && msg.sender == AlbinaAdress) 
        ||(timeB>AllOpen));
        _;
    }
    
    function OnOffLight() public timeOpen{
        StatusLight = !StatusLight;
    }
    
    function GetStatusLight() public view returns(string memory)
    {
        return StatusLight ? "On" : "Off";
    }
    
    function NewLight(Light newL) public timeOpen
    {
        if(StatusLight)
            lght = newL;
    }
    
    function NextLight() public timeOpen
    {
        if(!StatusLight)
            return;
        UpdateStatuc();
    }
    
    function GetLight() public view returns(string memory)
    {
        return GetThisLight();
    }
    
    
    
    
    
    function GetThisLight() private  view returns(string memory)
    {
        if(lght == Light.Green)
            return "Green";
        else if(lght == Light.Yellow)
           return "Yellow";
        else 
             return "Red";
    }
    
    function UpdateStatuc() private
    {
        if(lght == Light.Green)
            lght = Light.Yellow;
        else if(lght == Light.Yellow)
            lght = Light.Red;
        else
            lght = Light.Green;
    }
}