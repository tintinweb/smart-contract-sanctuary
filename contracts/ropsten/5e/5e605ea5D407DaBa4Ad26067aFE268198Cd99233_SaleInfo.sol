/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

pragma solidity 0.8.7;

interface ISale 
{
    function calculateTokensReceived(uint)
        external
        view
        returns (uint);

    function calculatePricePerToken(uint)
        external
        view
        returns(uint);

    function raised()
        external
        view
        returns(uint);
}

contract SaleInfo 
{

    ISale public Sale;

    constructor(ISale _SaleAddress) 
    {
        Sale = _SaleAddress;
    }

    function getSaleInfo(uint _supplied)
    public
    view
    returns(uint price, uint tokensReceived, uint raised)
    {
        price = Sale.calculatePricePerToken(_supplied);
        tokensReceived = Sale.calculateTokensReceived(_supplied);
        raised = Sale.raised();
    }

}