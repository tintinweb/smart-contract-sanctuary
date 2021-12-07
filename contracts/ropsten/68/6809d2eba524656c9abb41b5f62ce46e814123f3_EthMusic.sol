/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * Elijah Jasso, 2021
 */
 
 contract EthMusic {
    address private owner;
    int32 private f0; // tuning frequency, will be in format 440.0hz = 44000
    int32 private noteFadeInTime;
    int32 private noteSustainTime;
    int32 private noteFadeOutTime;
    int32 private chordProgressionStyle; // 1 to 5
    int32 private chordPlayStyle; // 1 to 5
    int32 private chordFamily; // 0 to 7
    
    constructor() {
        owner = msg.sender;
            
        f0 = 44000; // 440.00
        noteFadeInTime = 4000;
        noteSustainTime = 1000;
        noteFadeOutTime = 3000;
        chordProgressionStyle = 1;
        chordPlayStyle = 1;
        chordFamily = 1;
    }
    
    // setter functions
    function setF0(int32 newF0) public {
        require(newF0 > 400 && newF0 < 500);
        f0 = newF0;
    }
    
    function setNoteFadeInTime(int32 newFadeInTime) public {
        require(newFadeInTime > 0 && newFadeInTime < 10000);
        noteFadeInTime = newFadeInTime;
    }

    function setNoteSustainTime(int32 newSustainTime) public {
        require(newSustainTime > 0 && newSustainTime < 10000);
        noteSustainTime = newSustainTime;
    }
    
    function setNoteFadeOutTime(int32 newFadeOutTime) public {
        require(newFadeOutTime > 0 && newFadeOutTime < 10000);
        noteFadeOutTime = newFadeOutTime;
    }

    function setChordProgressionStyle(int32 newChordProgressionStyle) public {
        require(newChordProgressionStyle >= 1 && newChordProgressionStyle <= 5);
        chordProgressionStyle = newChordProgressionStyle;
    }

    function setChordPlayStyle(int32 newChordPlayStyle) public {
        require(newChordPlayStyle >= 1 && newChordPlayStyle <= 5);
        chordPlayStyle = newChordPlayStyle;
    }

    function setChordFamily(int32 newChordFamily) public {
        require(newChordFamily >= 0 && newChordFamily <= 7);
        chordFamily = newChordFamily;
    }

    // getter functions
    function getF0() public view returns (int32) {
        return f0;
    }
    
    function getNoteFadeInTime() public view returns (int32) {
        return noteFadeInTime;
    }

    function getNoteSustainTime() public view returns (int32) {
        return noteSustainTime;
    }
    
    function getNoteFadeOutTime() public view returns (int32) {
        return noteFadeOutTime;
    }

    function getChordProgressionStyle() public view returns (int32) {
        return chordProgressionStyle;
    }

    function getChordPlayStyle() public view returns (int32) {
        return chordPlayStyle;
    }

    function getChordFamily() public view returns (int32) {
        return chordFamily;
    }
 }