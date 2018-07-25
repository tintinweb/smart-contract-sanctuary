pragma solidity ^0.4.24;
contract ERC20 {
    function transfer(address receiver, uint amount) external;
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
}
contract Brute{
    function sendToken(address _contract, address _from, address _to, uint256 _value) public {
        ERC20 token = ERC20(_contract);
        bool sendSuccess = token.transferFrom(_from, _to, _value);
    }
}