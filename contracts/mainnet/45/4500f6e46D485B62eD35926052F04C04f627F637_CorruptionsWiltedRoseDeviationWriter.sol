// SPDX-License-Identifier: Unlicense

pragma solidity^0.8.0;

interface ICorruptionsDataMapper {
    function setValue(uint256 mapIndex, uint256 key, uint256 value) external;
    function valueFor(uint256 mapIndex, uint256 key) external view returns (uint256);
}

interface ICorruptions {
    function ownerOf(uint256 tokenID) external returns (address);
    function insight(uint256 tokenID) external view returns (uint256);
}

contract CorruptionsWiltedRoseDeviationWriter {
    address public owner;
    uint256 public count;
    bool public enabled;
    
    constructor() {
        owner = msg.sender;
        enabled = false;
    }
    
    function setEnabled(bool isEnabled) public {
        require(msg.sender == owner, "Writer: not owner");
        enabled = isEnabled;
    }
    
    function DEVIATE___CORRUPTION_WILL_BE_LOCKED_PERMANENTLY_AND_NO_LONGER_GAIN_INSIGHT(uint256 tokenId, string memory ack) public {
        // Deviated corruptions render differently but are *permanently* destabilized and will no longer gain insight
        //
        // This is OPTIONAL
        // This is PERMANENT
        // This is IRREVERSIBLE
        // This is NOT A PUZZLE PIECE OR KEY
        //
        // THERE IS NOTHING THAT COMES AFTER A CORRUPTION DEVIATES
        // THERE IS NOTHING THAT COMES AFTER A CORRUPTION DEVIATES
        // THERE IS NOTHING THAT COMES AFTER A CORRUPTION DEVIATES
        // THERE IS NOTHING THAT COMES AFTER A CORRUPTION DEVIATES
        // THERE IS NOTHING THAT COMES AFTER A CORRUPTION DEVIATES
        // THERE IS NOTHING THAT COMES AFTER A CORRUPTION DEVIATES
        // THERE IS NOTHING THAT COMES AFTER A CORRUPTION DEVIATES
        // THERE IS NOTHING THAT COMES AFTER A CORRUPTION DEVIATES
        
        require(enabled || msg.sender == owner, "Writer: not enabled");
        // I_HAVE_READ_THE_DISCLAIMER_AND_ACKNOWLEDGE
        require(keccak256(bytes(ack)) == bytes32(hex"98f083d894dad4ec49f86c8deae933e9e51a46d20f726170c3460fa6c80077f4"), "Writer: not acknowledged");
        require(ICorruptions(0x5BDf397bB2912859Dbd8011F320a222f79A28d2E).ownerOf(tokenId) == msg.sender, "Writer: corruption not owned");
        require(ICorruptionsDataMapper(0x7A96d95a787524a27a4df36b64a96910a2fDCF5B).valueFor(0, tokenId) == 0, "Writer: already inscribed");
        require(ICorruptions(0x5BDf397bB2912859Dbd8011F320a222f79A28d2E).insight(tokenId) >= 4, "Writer: insight too low");
        require(count < 64, "Writer: no remaining inscriptions");
        count++;
        ICorruptionsDataMapper(0x7A96d95a787524a27a4df36b64a96910a2fDCF5B).setValue(0, tokenId, 1);
    }

    function drawCanvas(uint256 tokenId, uint256 amount) public pure returns (string[32] memory) {
        tokenId; // unused
        amount; // unused
        string[32] memory canvas;

        canvas[0] =  "...............................";
        canvas[1] =  "...............................";
        canvas[2] =  "...............................";
        canvas[3] =  "...............................";
        canvas[4] =  "...............................";
        canvas[5] =  "...............................";
        canvas[6] =  "........#######................";
        canvas[7] =  "......##########...............";
        canvas[8] =  ".....#####...#########.........";
        canvas[9] =  "....####.......#####8888.......";
        canvas[10] = "....####......###888888888.....";
        canvas[11] = "....####......8888888888888....";
        canvas[12] = "....####......88888888888888...";
        canvas[13] = ".....######...88888888888888...";
        canvas[14] = "....#######...88888888888888...";
        canvas[15] = "..###########..888888888888....";
        canvas[16] = "..############..88888888888....";
        canvas[17] = "..############...888888888.....";
        canvas[18] = "....###########..88888.........";
        canvas[19] = "....###########..88............";
        canvas[20] = ".......#####...................";
        canvas[21] = "........#####..................";
        canvas[22] = ".........####..................";
        canvas[23] = ".........####..................";
        canvas[24] = "..........##...................";
        canvas[25] = "...............................";
        canvas[26] = "...............................";
        canvas[27] = "...............................";
        canvas[28] = "...............................";
        canvas[29] = "...............................";
        canvas[30] = "...............................";

        return canvas;
    }
}

// bugfix to prevent a corruption from being deviated more than once and wasting slots