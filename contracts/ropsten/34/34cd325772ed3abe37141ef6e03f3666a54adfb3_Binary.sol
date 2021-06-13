/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity ^0.8.0;

interface UniswapAnchoredView {
    function price(string memory symbol) external view returns (uint);
}

contract Binary {
    
    address uniAddr = 0x922018674c12a7F0D394ebEEf9B58F186CdE13c1;
    
    function look() external view returns (uint) {
            UniswapAnchoredView viewa = UniswapAnchoredView(uniAddr);
            uint price = viewa.price("ETH");
            return price;
    }
    
}