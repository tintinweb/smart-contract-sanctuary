/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

pragma solidity ^0.5.17;

interface AvastarsContract {
        function useTraits(uint256 _primeId, bool[12] calldata _traitFlags) external;
}

contract AvastarsInterface {
    
        constructor() public {
            Avastars = AvastarsContract(AvastarsAddress);
        }
        
        address public AvastarsAddress = 0x30E011460AB086a0daA117DF3c87Ec0c283A986E;
        
        AvastarsContract Avastars;
        
        function burnReplicantTraits(uint[5] memory avastarIDs, bool[12][5] memory avastarTraits) public {
            
            uint256 totalAvastars = avastarIDs.length;
            bool[12] memory iTraits;
            
            for (uint i = 0; i < totalAvastars; i = i + 1){
                iTraits = avastarTraits[i];
                Avastars.useTraits(avastarIDs[i],iTraits);
            }
        }
        
}