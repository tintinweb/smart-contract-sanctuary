pragma solidity ^0.4.25;

contract GFInterface
{
    function createContract(string contract_type_str) public payable returns(address);
}

contract TokenInterface
{
    function initialize(string _name, string _symbol, uint _decimals, uint _totalSupplyInTokens) public;
    function setPlatform(address new_platform) public;
    function transfer(address to, uint256 value) public returns (bool);
}

contract Seller
{
    address constant gf = 0xc42d5F0E55aA907E485510A72c6b4dd827eC1A23;

    function createErc20Token(string _name, string _symbol, uint _totalSupplyInTokens) public payable returns (address)
    {
        address token = GFInterface(gf).createContract.value(msg.value)("ERC20Token");
        TokenInterface(token).initialize(_name, _symbol, 18, _totalSupplyInTokens);
        TokenInterface(token).transfer(msg.sender, _totalSupplyInTokens);
        TokenInterface(token).setPlatform(msg.sender);
        return token;
    }
}