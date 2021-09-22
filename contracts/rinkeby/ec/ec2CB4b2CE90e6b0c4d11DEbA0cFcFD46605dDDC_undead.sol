/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

//Creator @razzor_tweet

pragma solidity ^0.8.0;

interface Mortal {
  function deatYet() external view returns (bytes32);
}

contract undead{
        bytes20 public want;
        bytes20 public mask;
        address public owner;
        uint256 public wordLength;
        mapping (bytes32 => bool) public UnDeAD;
        
     
        constructor(bytes20 _want, bytes20 _mask, uint256 _wordLength){
            want = _want;
            mask = _mask;
            wordLength = _wordLength;
            owner = msg.sender;
        }
    
        
        function deadOrAlive(address _addr) external {
            require(!UnDeAD[keccak256(abi.encodePacked(_addr))], "Not Twice");
            uint256 size;
            require(mortality(_addr), "Want Blood");
            assembly {
                size := extcodesize(_addr)
            }
            require(size == 15);
            Mortal mortal = Mortal(_addr);
            bytes32 answerMe = mortal.deatYet();
            string memory identity = bytes32ToString(answerMe <<= (4 * 52));
            require(keccak256(abi.encodePacked(identity)) == keccak256(abi.encodePacked("UnDeAD")), "MORTAL!");
            UnDeAD[keccak256(abi.encodePacked(_addr))] = true;

        }
      
        function mortality(address _addr) internal returns (bool) {
        bytes20 addr = bytes20(_addr);
        for (uint256 i = 0; i <= (40 - wordLength); i++) {
            if (addr & mask == want) {
                return true;
            }
            mask <<= 4;
            want <<= 4;
        }
        return false;
    }
    

    //==========================Administrative Functions==========================
    
        modifier onlyOwner(){
            require(msg.sender == owner, "Not the owner");
            _;
        }
        
        
        function transferOwnership(address newOwner) external onlyOwner{
            owner = newOwner;
        }
        
        
        function updateWantMask(bytes20 _want, bytes20 _mask, uint256 _wordLength) external onlyOwner{
            want = _want;
            mask = _mask;
            wordLength = _wordLength;
        }
        
    //==========================Helper Functions========================== 
    
        function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
    
}