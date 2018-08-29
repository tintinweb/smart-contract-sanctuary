pragma solidity 0.4.24;

contract NostrodamusI { 
    function prophecise(bytes32 exact) public;
    function theWord() public view returns(bytes32 exact);
}

contract NostradamusCaller {

    event LogDepositReceived(address sender, uint256 value);
    
    constructor() public {
    }

    function propheciseExecute (address theAddress) public returns (bytes32 exact) {
        
        NostrodamusI nostrodamusI = NostrodamusI(theAddress);
        //Get resulting address
        bytes32 resultingAddress = keccak256(abi.encodePacked(address(this), block.number, blockhash(block.number),  block.timestamp, theAddress));

        nostrodamusI.prophecise(resultingAddress);
        
        return (resultingAddress);
    }
    
    function() public payable {  emit LogDepositReceived(msg.sender,msg.value); }
   
}