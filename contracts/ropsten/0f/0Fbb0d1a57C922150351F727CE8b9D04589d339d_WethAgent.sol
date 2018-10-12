pragma solidity ^0.4.25;

contract WethAgent {
    
    address public owner;
    ModifiedWETH w;
    
    constructor() public payable {
        owner = msg.sender;
    }

    function set_modified_weth_address(address addr) public {
        w = ModifiedWETH(addr);
    }
    
    function callModifiedDeposit(uint depositAmount) public payable {
        w.deposit(depositAmount);
    }
                
    function callModifiedWithdraw(uint withdrawAmount) public {
        w.withdraw(withdrawAmount);
    }
            
    function callModifiedContractBalance() public view returns (uint) {
        w.contractBalance();
        return w.contractBalance();
    }
    
    function callModifiedTransfer(address dst, uint amount) public returns (bool) {
        w.wethTransfer(dst, amount);
        return w.wethTransfer(dst, amount);
    }
    
    function callThisContractBalance() public view returns (uint) {
        return address(this).balance;
    }
}

contract ModifiedWETH {
    function deposit(uint depositAmount) public payable;
    function wethTransfer(address dst, uint amount) public returns (bool);
    function withdraw(uint withdrawAmount) public;
    function contractBalance() public view returns (uint);
}