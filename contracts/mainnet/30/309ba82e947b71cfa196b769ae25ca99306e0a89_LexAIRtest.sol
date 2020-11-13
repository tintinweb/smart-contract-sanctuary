pragma solidity 0.5.17;

interface ILexAIR { // brief interface for LexAIR
    function isRegistered(address account) external view returns (bool);
}

contract LexAIRtest {
    uint256 public stuffDone;
    address public LexAIRcontract = 0x365c0F05CCfAE37899b55D79459eB7C0fCB20e3a;
    
    function doAccreditedStuff() external {
        require(ILexAIR(LexAIRcontract).isRegistered(msg.sender), "!registered");
        
        stuffDone += 1;
    }
}