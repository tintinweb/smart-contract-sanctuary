/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;
contract Probando{
    uint256 public contador;
    string public ownerName;
    address public owner;


    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }

    constructor(string memory _ownerName){
        ownerName=_ownerName;
        owner=msg.sender;
    }
    function agregarContador(uint256 _numero) public {
        contador+=_numero;
    }
    function restarContador(uint256 _numero) public {
        contador-=_numero;
    }
    function depositarFondos(uint256 _weis) public payable returns(bool){
        require(msg.value>=_weis);
        return true;
    }
    function verFondoCuenta() public view returns(uint256){
        return address(this).balance;
    }
    function withdrawFounds()public onlyOwner returns(bool){
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }
    }