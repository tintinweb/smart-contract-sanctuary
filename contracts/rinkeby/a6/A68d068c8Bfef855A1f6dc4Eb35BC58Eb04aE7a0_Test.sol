contract Test {
    function payme() payable public {
    }

    function getBal() public returns (uint) {
        return address(this).balance;
    }
}

