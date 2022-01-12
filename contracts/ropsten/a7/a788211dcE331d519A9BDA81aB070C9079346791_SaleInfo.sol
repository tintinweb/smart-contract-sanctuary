/**
 *Submitted for verification at Etherscan.io on 2022-01-12
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

    function tokensIssued()
        external
        view
        returns(uint);
    
    function raised()
        external
        view
        returns(uint);

    function addToRaised(uint256 _addition)
        external;

    function subractFromRaised(uint256 _sub)
        external;

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
    returns(uint price, uint tokensReceived, uint raised, uint tokensIssued)
    {
        price = Sale.calculatePricePerToken(_supplied);
        tokensReceived = Sale.calculateTokensReceived(_supplied);
        raised = Sale.raised();
        tokensIssued = Sale.tokensIssued();
    }

    function addRaised(uint _add)
    external
    {
        Sale.addToRaised(_add);
    }

    function subtractRaised(uint _sub)
    external
    {
        Sale.subractFromRaised(_sub);
    }

}