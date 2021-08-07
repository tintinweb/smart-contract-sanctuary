/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

pragma solidity >=0.7.0 <0.9.0;


contract Uloziste
{
    string text;
   
    
    function read() public view returns (string memory) 
    {
        
        return text;
    }
    
    function write(string memory zprava) public
    {
    
    
        
        if(msg.sender==address(0x28c34D4cB555bD7c02A930A069EC1BA762BC5F9b))
        {
            text = zprava;
        }
    }
    
    
}