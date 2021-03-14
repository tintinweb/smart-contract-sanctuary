/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

pragma solidity^0.7.4;
contract EsempioSmartContract {
        struct ScrivisuEthereum {
        string MessaggioDallaBlockchain_;
        }
    address TitolareContratto;
       constructor() public {
        TitolareContratto = msg.sender;
    }
    modifier sviluppatoreFrancesco() {
    if (msg.sender == TitolareContratto) {
        _;
    }
}    
   ScrivisuEthereum[] public leggiBlockchain;
   function InserisciDati( string memory MessaggioDallaBlockchain_ ) public sviluppatoreFrancesco {
   leggiBlockchain.push(ScrivisuEthereum( MessaggioDallaBlockchain_));
   }
}