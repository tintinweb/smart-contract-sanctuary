/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity >=0.7.0 <0.9.0;
//SPDX-License-Identifier: UNLICENSED
contract C {
    uint u;
    function f() virtual public   {
         u = 3;
    }
    function f6() public pure virtual returns(uint) {
        return(5);
    }
}

contract B is C {
    function f1() public returns(uint)  {
        u = 2;
        return(u);
    }
    function f6() public pure override returns(uint){
        return(9);
    }
}

contract A is B {
    event Transfer(address indexed _to, uint value);
    uint public x;
   
    mapping(uint => uint) public tokenId;
    
     
    function f11(uint id) public   {
       //x = B.f1();
       tokenId[id] = 100;
    }
    function fz(uint id) public {
       // A.f();
        delete tokenId[id];
    }
    function f_map(uint id) public {
        
        x = tokenId[id];
        require(x<= 3,"it should be less than 3");
    }
    function withdraw(address _address, uint256 _amount) public {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }
     receive() external payable {}
     function sendViaTransfer() external payable {
        // This function is no longer recommended for sending Ether.
        address payable _to;
        _to =  payable(this);
        _to.transfer(msg.value);
        emit Transfer(_to,msg.value);
    }
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    }