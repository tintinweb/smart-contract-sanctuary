contract NewApp {
    function call_contract(address _address) public {
        _address.call(bytes4(keccak256("testrevert()")));
        _address.transfer(1 ether);
    }
}

contract Attack {
    function testrevert() public {
        revert();
    }
    
}