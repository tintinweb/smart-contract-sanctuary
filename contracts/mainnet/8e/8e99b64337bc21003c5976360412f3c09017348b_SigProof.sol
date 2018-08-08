contract SigProof {
    address public whitehat = 0xb0719bdac19fd64438450d3b5aedd3a4f100cba6;
    bytes public massTeamMsgHash = hex"191f8e6b533ae64600273df1ecb821891e1c649326edfc7921aeea37c1960586";
    string public dontPanic = "all funds will be returned to mass team after identity verification";
    bool public signedByWhiteHat = false;
    
    function SigProof() {}
    
    function () {
        assert(msg.sender == whitehat); // proves tx signed by white hat
        signedByWhiteHat = true;
    }
}