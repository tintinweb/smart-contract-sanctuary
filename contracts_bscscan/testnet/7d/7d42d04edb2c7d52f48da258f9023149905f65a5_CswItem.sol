pragma solidity ^0.8.0;

import "./CswItemPreset.sol";

contract CswItem is CswItemPreset {

   constructor() CswItemPreset("Crypto Space War Item", "CSWI", "https://nft.cryptospacewar.com/items/") {}

}