/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

pragma solidity^0.8.0;
contract InteractContract
{
    string public name;
    string public occupation;
    constructor() public
    {
        name="Aman";
        occupation="Development";
    }
    function getPersonName() public view returns(string memory)
    {
        return name;
    }
    function getPersonOccupation() public view returns(string memory)
    {
        return occupation;
    }
}