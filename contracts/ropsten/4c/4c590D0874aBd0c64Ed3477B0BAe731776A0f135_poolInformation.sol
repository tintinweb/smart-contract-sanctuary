/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

pragma solidity "0.8.0";

 contract poolInformation{
   
   PoolCharacteristics[3] public PoolInformation;
   
   struct PoolCharacteristics {
        uint256 offeringAmountPool; // amount of tokens offered for the pool (in offeringTokens)
        uint256 priceA; // lower  price for pool2 in lpToken/offeringToken
        uint256 priceB; // higher price for pool2 in lpToken/offeringToken
        uint256 totalAmountPool; // total amount pool deposited (in LP tokens)
    }

    constructor(uint offering, uint pricea, uint priceb, uint totaltmount)public{
        PoolInformation[0].offeringAmountPool = offering;
        PoolInformation[0].priceA = pricea;
        PoolInformation[0].priceB = priceb;
        PoolInformation[0].totalAmountPool = totaltmount;
    }

    function setPoolCharacteristics(uint8 _pid, uint offeringamount, uint priceA, uint priceB, uint totaltmount) public{
        PoolInformation[_pid].offeringAmountPool = offeringamount;
        PoolInformation[_pid].priceA = priceA;
        PoolInformation[_pid].priceB = priceB;
        PoolInformation[_pid].totalAmountPool = totaltmount;
    }

    function viewPoolInformation(uint256 _pid)
    external
    view
    returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            PoolInformation[_pid].offeringAmountPool,
            PoolInformation[_pid].priceA,
            PoolInformation[_pid].priceB,
            PoolInformation[_pid].totalAmountPool
        );
    }
}