pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
}
contract KiOS_Standard {
    function payment() public payable returns(bool);
}
contract KiOS_Intermediary {
    address public admin;
    address public reference;
    address public token;
    address public customer;
    uint public wei_ask;
    uint public fee;
    uint public bill;
    event AdminUpdated(address indexed _adminNew, address indexed _adminOld);
    event CustomerUpdated(address indexed _costumerNew, address indexed _costumerOld);
    event TaxPaid(address indexed _feeReceiver, uint _feeCollected);
    event Purchased(address indexed _buyer, address indexed _token, uint _estimate, uint _value, uint _fee);
    event Withdraw(address indexed _tokenAddress, uint _value);
    constructor(address _admin, address _reference, address _customer, address _token, uint _estimate, uint _fee) public {
        admin = _admin;
        reference = _reference;
        customer = _customer;
        token = _token;
        wei_ask = _estimate;
        fee = _fee;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    modifier onlyCustomer() {
        require(msg.sender == customer);
        _;
    }
    function getBalance() internal view returns(uint) {
        return ERC20(token).balanceOf(address(this));
    }
    // Admin area start here
    function updateAdmin(address adminNew) public onlyAdmin returns(bool) {
        require(adminNew != address(0) && address(this) != adminNew);
        admin = adminNew;
        emit AdminUpdated(adminNew, msg.sender);
        return true;
    }
    // End of admin area
    
    // Customer area start here
    function updateCustomer(address customerNew) public onlyCustomer returns(bool) {
        require(customerNew != address(0) && address(this) != customerNew);
        customer = customerNew;
        emit CustomerUpdated(customerNew, msg.sender);
        return true;
    }
    function updateToken(address tokenNew, uint weiNew) public onlyCustomer returns(bool) {
        require(tokenNew != address(0));
        if (tokenNew != token) {
            if (getBalance() > 0) withdrawToken();
            token = tokenNew;
        }
        wei_ask = weiNew;
        return true;
    }
    function withdrawToken() public onlyCustomer returns(bool) {
        uint x = getBalance();
        require(x > 0);
        if (!ERC20(token).transfer(customer, x))
        revert();
        emit Withdraw(token, x);
        return true;
    }
    function withdraw() public onlyCustomer returns(bool) {
        uint x = address(this).balance;
        if (bill > 0) {
            x -= bill;
            if (!KiOS_Standard(admin).payment.value(bill)())
            admin.transfer(bill);
            emit TaxPaid(admin, bill);
            bill = 0;
        }
        require(x > 0);
        if (!KiOS_Standard(customer).payment.value(x)())
        customer.transfer(x);
        emit Withdraw(address(0), x);
        return true;
    }
    // End of customer area
    
    // Public Area
    function payment() public payable returns(bool) {
        require(msg.value >= wei_ask);
        uint avail = getBalance();
        require(avail > 0);
        if (!ERC20(token).transfer(msg.sender, avail)) revert();
        bill += fee;
        emit Purchased(msg.sender, token, wei_ask, avail, fee);
        return true;
    }
    function() public payable {
        if (msg.value >= wei_ask) payment();
    }
}
contract KiOS_Factory {
    address public contractCreator = msg.sender;
    address public contractReference = address(0);
    function generate(address _contractAdmin, address _contractCustomer, address _contractToken, uint _contractEstimate, uint _contractFee) public returns(address) {
        require(msg.sender == contractCreator);
        return address(new KiOS_Intermediary(_contractAdmin, contractReference, _contractCustomer, _contractToken, _contractEstimate, _contractFee));
    }
    function setup(address _creator, address _reference) public returns(bool) {
        require(msg.sender == contractCreator);
        require(_creator != address(this) && address(0) != _creator);
        require(_reference != address(0) && address(this) != _reference);
        contractCreator = _creator;
        contractReference = _reference;
        return true;
    }
}