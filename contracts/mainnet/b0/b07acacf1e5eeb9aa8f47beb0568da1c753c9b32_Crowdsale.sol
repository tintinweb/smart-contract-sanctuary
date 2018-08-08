pragma solidity ^0.4.8;

interface token
{
    function transfer(address receiver, uint256 amount) returns (bool success);
    function transferFrom(address from, address to, uint256 amount) returns (bool success);
    function balanceOf(address owner) constant returns (uint256 balance);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

contract Crowdsale
{
    address public owner;
    address public seller;
    address public ContractAddress;
    uint public amountRaised;
    uint public price;
    uint public ethereumPrice;
    token public tokenReward;
    address public walletOut1;
    address public walletOut2;

    event FundTransfer(address backer, uint amount, bool isContribution);

    function Crowdsale()
    {
        // Avatar
        walletOut1 = 0x594ae2a6aeab6f5e74bba0958cec21ec4dcd7f1e;
        // A
        walletOut2 = 0x7776eab79aeff7a1c09d8c49a7f3caf252c26451;

        // адрес продавца
        seller = 0x7776eab79aeff7a1c09d8c49a7f3caf252c26451;

        owner = msg.sender;

        price = 15;
        tokenReward = token(0xcd389f4873e8fbce7925b1d57804842043a3bf36);
        ethereumPrice = 447;
    }

    function changeOwner(address newOwner) onlyowner
    {
        owner = newOwner;
    }

    modifier onlyowner()
    {
        if (msg.sender == owner) _;
    }

    /* модификатор проверяющий "вызывает продавец или вызывает владелец контракта?" */
    modifier isSetPrice()
    {
        if (msg.sender == seller || msg.sender == owner) _;
    }

    function () payable
    {
        uint256 amount = msg.value;
        amountRaised += amount;
        uint256 amountOut1 = amount / 2;
        uint256 amountOut2 = amount - amountOut1;

        uint256 amountWei = amount;
        uint priceUsdCentEth = ethereumPrice * 100;
        uint priceUsdCentAvr = price;
        uint256 amountAvrAtom = ((amountWei * priceUsdCentEth) / priceUsdCentAvr) / 10000000000;

        if (tokenReward.balanceOf(ContractAddress) < amountAvrAtom) {
            throw;
        }
        tokenReward.transfer(msg.sender, amountAvrAtom);

        walletOut1.transfer(amountOut1);
        walletOut2.transfer(amountOut2);

        FundTransfer(msg.sender, amount, true);
    }

    function setWalletOut1(address wallet) onlyowner
    {
        walletOut1 = wallet;
    }

    function setWalletOut2(address wallet) onlyowner
    {
        walletOut2 = wallet;
    }

    function sendAVR(address wallet, uint256 amountAvrAtom) onlyowner
    {
        tokenReward.transfer(wallet, amountAvrAtom);
    }

    function setContractAddress(address wallet) onlyowner
    {
        ContractAddress = wallet;
    }

    // uint usdCentCostOfEachToken - цена в центах
    function setPrice(uint usdCentCostOfEachToken) onlyowner
    {
        price = usdCentCostOfEachToken;
    }

    // uint usd - цена в долларах
    function setEthPrice(uint usd) isSetPrice
    {
        ethereumPrice = usd;
    }
}