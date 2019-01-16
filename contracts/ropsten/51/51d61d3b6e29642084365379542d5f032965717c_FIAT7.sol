pragma solidity ^0.4.25;
contract FIAT7 {
    string public name     = "Wrapped Fiat";
    string public symbol   = "WFIAT";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint fiat);
    event  Transfer(address indexed src, address indexed dst, uint fiat);
    event  Deposit(address indexed dst, uint fiat);
    event  Withdrawal(address indexed src, uint fiat);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() public payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint fiat) public {
        require(balanceOf[msg.sender] >= fiat);
        balanceOf[msg.sender] -= fiat;
        msg.sender.transfer(fiat);
        emit Withdrawal(msg.sender, fiat);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint fiat) public returns (bool) {
        allowance[msg.sender][guy] = fiat;
        emit Approval(msg.sender, guy, fiat);
        return true;
    }

    function transfer(address dst, uint fiat) public returns (bool) {
        return transferFrom(msg.sender, dst, fiat);
    }

    function transferFrom(address src, address dst, uint fiat)
        public
        returns (bool)
    {
        require(balanceOf[src] >= fiat);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= fiat);
            allowance[src][msg.sender] -= fiat;
        }

        balanceOf[src] -= fiat;
        balanceOf[dst] += fiat;

        emit Transfer(src, dst, fiat);

        return true;
    }
}