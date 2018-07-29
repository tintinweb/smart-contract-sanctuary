//***********************************************************
//
// created with pyetherchain.EtherChainAccount(address).describe_contract()
// see: https://github.com/tintinweb/pyetherchain
//
// Date:     Fri Jul 27 16:05:32 2018
//
// Name:     None
// Address:  1e143b2588705dfea63a17f2032ca123df995ce0
// Swarm:    
//
//
// Constructor Args: constructor None () returns ()
//
//
// Transactions : <disabled>
//
//***************************
contract ClassicCheck {
       function isClassic() constant returns (bool isClassic);
}

contract SafeConditionalHFTransfer {

    bool classic;
    
    function SafeConditionalHFTransfer() {
        classic = ClassicCheck(0x882fb4240f9a11e197923d0507de9a983ed69239).isClassic();
    }
    
    function classicTransfer(address to) {
        if (!classic) 
            msg.sender.send(msg.value);
        else
            to.send(msg.value);
    }
    
    function transfer(address to) {
        if (classic)
            msg.sender.send(msg.value);
        else
            to.send(msg.value);
    }
    
}