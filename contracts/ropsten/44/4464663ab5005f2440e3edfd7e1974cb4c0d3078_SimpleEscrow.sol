pragma solidity ^0.4.18;
 
contract SimpleEscrow {
    
    uint public PERIOD = 1 days;
    
    uint public SAFE_PERIOD = 1 days;
    
    address public developerWallet = 0x7f8E22396589025dF47c0d2772f18d19245a2562;
    
    address public customerWallet;
    
    uint public started;
    
    uint public orderLastDate;
    
    uint public safeLastDate;
 
    address public owner;
 
    function SimpleEscrow() public {
        owner = msg.sender;
    }
 
    modifier onlyCustomer() {
        require(msg.sender == customerWallet);
        _;
    }
 
    modifier onlyDeveloper() {
        require(msg.sender == developerWallet);
        _;
    }
    
    function setDeveloperWallet(address newDeveloperWallet) public {
        require(msg.sender == owner);
        developerWallet = newDeveloperWallet;
    }
 
    function completed() public onlyCustomer {
        developerWallet.transfer(this.balance);
    }
 
    function orderNotAccepted() public onlyCustomer {
        require(now >= orderLastDate);
        safeLastDate += SAFE_PERIOD;
    }
 
    function failedByDeveloper() public onlyDeveloper {
        customerWallet.transfer(this.balance);
    }
    
    function completeOrderBySafePeriod() public onlyDeveloper {
        require(now >= safeLastDate);
        developerWallet.transfer(this.balance);
    }
    
    function () external payable {
        require(customerWallet == address(0x0));
        customerWallet = msg.sender;
        started = now;
        orderLastDate = started + PERIOD;
        safeLastDate = orderLastDate + SAFE_PERIOD;
    }
    
}