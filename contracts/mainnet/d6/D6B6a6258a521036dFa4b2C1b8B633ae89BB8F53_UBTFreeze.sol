pragma solidity 0.4.15;

contract ERC20Interface {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approved(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

contract UBTFreeze {
    address constant public RECEIVER = 0xa814147abAB7B7C4AE0914F9aF9EeaE201454219;
    uint constant public DEADLINE = 1554912000; // April 10th 2019, 2pm CET
    ERC20Interface constant UBT = ERC20Interface(0x8400D94A5cb0fa0D041a3788e395285d61c9ee5e);

    function transferAfterDeadline() returns(bool) {
        require(now > DEADLINE);
        require(UBT.transfer(RECEIVER, UBT.balanceOf(this)));
        return true;
    }
}