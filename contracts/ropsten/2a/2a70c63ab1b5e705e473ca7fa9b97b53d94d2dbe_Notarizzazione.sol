/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

pragma solidity =0.4.26;

contract Notarizzazione {
    struct ArchiviaPerSempre {
        string MessaggioDallaBlockchain_;
}

address TitolareContratto;
constructor() public {
    TitolareContratto = msg.sender;
}

modifier sviluppatoreCapo() {
    if (msg.sender == TitolareContratto) {
        _;
    }
}

ArchiviaPerSempre[] public leggiBlockChain;
function InserisciDati (string MessaggioDallaBlockchain_) public sviluppatoreCapo {
    leggiBlockChain.push(ArchiviaPerSempre(MessaggioDallaBlockchain_));
    }
}