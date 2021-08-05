/**
 *Submitted for verification at Etherscan.io on 2020-05-08
*/

pragma solidity 0.6.3;
 
// Solidity Interface
 
interface UniswapExchangeInterface {
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
 
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
 
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
 
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
}
 
contract RateCrawlerHelper {
 
    function getTokenRates(UniswapExchangeInterface uniswapExchangeContract, uint[] memory amounts)
    public view
    returns (uint[] memory inputPrices, uint[] memory outputPrices)
    {
        inputPrices = new uint[](amounts.length);
        outputPrices = new uint[](amounts.length);
        bool didReverted = true;
 
        for (uint i = 0; i < amounts.length; i++) {
            (didReverted, inputPrices[i]) = assemblyGetEthToToken(address(uniswapExchangeContract), amounts[i], bytes4(keccak256("getEthToTokenInputPrice(uint256)")));
            if (didReverted) {
                inputPrices[i] = 0;
            }
            (didReverted, outputPrices[i]) = assemblyGetEthToToken(address(uniswapExchangeContract), amounts[i], bytes4(keccak256("getTokenToEthOutputPrice(uint256)")));
            if (didReverted) {
                outputPrices[i] = 0;
            }
        }
    }
 
    function assemblyGetEthToToken(address exh, uint amount, bytes4 sig)
    internal view
    returns (bool, uint)
    {
        uint success;
        uint rate;
        assembly {
            let x := mload(0x40)        // "free memory pointer"
            mstore(x, sig)               // function signature
            mstore(add(x, 0x04), amount)  // src address padded to 32 bytes
            mstore(0x40, add(x, 0x44))    // set free storage pointer to empty space after output
 
        // input size = sig + uint
        // = 4 + 32 = 36 = 0x24
            success := staticcall(
            gas(),
            exh, // contract addr
            x, // Inputs at location x
            0x24, // Inputs size bytes
            add(x, 0x24), // output storage after input
            0x20) // Output size are (uint, uint) = 64 bytes
 
            rate := mload(add(x, 0x24))  //Assign output to rate.
            mstore(0x40, x)    // Set empty storage pointer back to start position
        }
 
        return (success != 1, rate);
    }
}