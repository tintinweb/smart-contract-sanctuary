/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

pragma solidity ^0.8.1;

contract Sheesh 
{
    string public walter;
    address public ichBinDerSenat;

    constructor(){
        ichBinDerSenat = msg.sender;
    }

    function setWalter(string memory _text) public 
    {
        walter = _text;
    }

    function narutoHijack() public payable
    {

    }

    function getBalance() public view returns(uint)
    {
        return address(this).balance;
    }

    function withdrawMoney(address payable _to) public
    {
        require(ichBinDerSenat == msg.sender, "Dann handelt es sich um verrat.");
        _to.transfer(getBalance());
    }
}