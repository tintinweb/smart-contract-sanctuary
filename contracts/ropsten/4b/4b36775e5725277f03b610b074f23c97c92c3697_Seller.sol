pragma solidity ^0.4.25;

contract GFInterface
{
    function createContract(string contract_type_str) public payable;
}

contract TokenInterface
{
    function initialize(string _name, string _symbol, uint _decimals, uint _totalSupplyInTokens) public;
    function setPlatform(address new_platform) public;
    function transfer(address to, uint256 value) public returns (bool);
}

contract Seller
{
    address gf = 0xc42d5F0E55aA907E485510A72c6b4dd827eC1A23;

    function createErc20Token(string _name, string _symbol, uint _totalSupplyInTokens) public payable
    {
        GFInterface(gf).createContract.value(msg.value)("ERC20Token");
        address token = address(0); // на самом деле надо получить от фабрики
        TokenInterface(token).initialize(_name, _symbol, 18, _totalSupplyInTokens);
        TokenInterface(token).transfer(msg.sender, _totalSupplyInTokens);
        TokenInterface(token).setPlatform(msg.sender);
    }
}