pragma solidity ^0.4.25;

contract GFInterface
{
    function createContract(string contract_type_str) public payable returns (address);
}

contract TokenInterface
{
    function initialize(string _name, string _symbol, uint _decimals, uint _totalSupplyInTokens) public;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract TokenSeller
{
    address constant gf = 0x070037f3f9AA224B0311bC86C5f3Af04b0B559fe;

    function createErc20Token(string _name, string _symbol, uint _totalSupplyInTokens) public payable returns (address)
    {
        return createErc20Token(_name,_symbol, 18, _totalSupplyInTokens);
    }

    function createErc20Token(string _name, string _symbol, uint _decimals, uint _totalSupplyInTokens) public payable returns (address)
    {
        address token = GFInterface(gf).createContract.value(msg.value)("ERC20Token");
        TokenInterface(token).initialize(_name, _symbol, _decimals, _totalSupplyInTokens);
        TokenInterface(token).transfer(msg.sender, TokenInterface(token).balanceOf(address(this)));
        return token;
    }
}