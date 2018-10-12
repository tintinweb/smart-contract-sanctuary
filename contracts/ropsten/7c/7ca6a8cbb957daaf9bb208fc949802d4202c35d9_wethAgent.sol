pragma solidity ^0.4.25;
contract modifiedWeth {

    function deposit(uint amount) public payable;

    function withdraw(uint amount) public;

    function transfer(address dst, uint amount) public  returns (bool);

    function totalSupply() public view returns (uint);
    
     function () public payable;
}


contract wethAgent {

    address public owner;

    modifiedWeth w;//calling contract of modifiedWeth, of lab3 assignment.

    constructor() public payable {

        owner = msg.sender;
    }


    function set_modified_weth_address(address addr) public {

        w = modifiedWeth(addr);

    }

    function callDeposit(uint amount) public returns(bool) {

         w.deposit(amount);

      return true;
   }

    function callTransfer(address dst, uint amount) public returns(bool)   {

        require(w.transfer(dst , amount));

        return true;

    }
    
    function callWithdraw(uint amount) public returns (bool) {

        w.withdraw(amount);

        return true;  

    }

    function getBalanceOfModifiedWeth() public returns (uint) {

        return w.totalSupply();
    }

}