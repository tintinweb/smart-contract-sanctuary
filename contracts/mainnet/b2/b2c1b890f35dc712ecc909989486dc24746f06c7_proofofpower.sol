contract proofofpower {
    
    bytes[6] public whitepaper;
    uint counter;
    function uploadData(bytes _data) public returns (uint){
        whitepaper[counter] = _data;
        counter++;
    }
}