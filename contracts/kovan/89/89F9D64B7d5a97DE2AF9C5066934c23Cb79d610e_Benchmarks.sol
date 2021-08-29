/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

pragma solidity ^0.5.0;

interface Cybor {
    function retrieve() external view returns (
            uint[4] memory totalBorrowsVariables,
            uint[4] memory variableBorrowRates
        );
}

contract Benchmarks{
    uint constant RAY = 10 ** 27;
    
     function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
    
    function stableCoinsVWAP() public view returns(uint vwap) {
        Cybor cybor = Cybor(0x417403Ae1567FE4E542665fa602a58871764daE1);
        uint[4] memory totalBorrowsVariables;
        uint[4] memory variableBorrowRates;
        
        (totalBorrowsVariables, variableBorrowRates) = cybor.retrieve();
        
        uint volumeRateDotProduct;
        uint totalVolume;
        
        for(uint i; i < totalBorrowsVariables.length; i++) {
            volumeRateDotProduct += rmul(totalBorrowsVariables[i], variableBorrowRates[i]);
            totalVolume += totalBorrowsVariables[i];
        }
        
        vwap = rdiv(volumeRateDotProduct, totalVolume);
    }
 }