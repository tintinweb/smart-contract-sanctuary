contract NewApp {
    function call_contract(address _address) public {

        _address.transfer(1 ether);
    }
// 0xDaE558C6d300010BE4AC90387225822f547Fe55D
}

contract Attack {
    function testrevert() public {
        revert();
    }
    
}