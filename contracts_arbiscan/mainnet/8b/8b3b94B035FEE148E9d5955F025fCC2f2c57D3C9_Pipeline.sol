/**
 *Submitted for verification at arbiscan.io on 2021-09-23
*/

pragma solidity >=0.7.0 <0.9.0;


interface IDistributor {
      function distribute() external;
}

interface IEscrow {
    function convertToEth() external;
    function updateRecipient(address newRecipient) external;
}

contract Pipeline {
    
    function push() public {
        
        //nyan
        IEscrow(0xce789f111A51599c9908039Fb922e0945AB555be).convertToEth();
        //ppegg
        IEscrow( 0x2906c88AE542Deda106cB3E8E65071F99DBE1a95).convertToEth();
        
        //sushi/spell
        IEscrow( 0x20040D11Fe3baE1AD0F23ac8958faf370F5CFcf4).convertToEth();
        
        IDistributor(0x14897d1510F60640f7C2E5a3eEA48f21EDDD40dB).distribute();
    }
}