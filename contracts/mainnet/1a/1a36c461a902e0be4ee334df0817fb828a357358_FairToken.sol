pragma solidity >=0.7.0 <0.9.0;

import "ERC20Burnable.sol";
import "SafeMath.sol";

contract FairToken is ERC20Burnable {
    using SafeMath for uint256;
    string public constant launchMessage = "A KittyKoin is Born";
    string public constant litePaper = "https://pastebin.com/raw/2Ww4rBXf";
    string public constant litePaperSHA2Hash = "f57e20924bc135bbf01315feb0cdf0f1fd442d241fd596d3a323fc0c5bd37955  2Ww4rBXf"; 
    
    constructor (string memory myname, string memory mysymbol) ERC20 (myname, mysymbol) {
        _mint(msg.sender, 10 ** 28);
    }
    
    string[] public adMessages;
    uint[] public adPayments;
    uint[] public burnTimes;
    address[] public burners; 
    
    function burnToAdvertise(string calldata adMessage, uint adPayment) public returns(uint) { // advertising is simply burning tokens with a message (e.g. "save the whales" or "Nike is great")
        require(adPayment > (10**9) );
        _burn(msg.sender, adPayment);
        adMessages.push(adMessage);
        adPayments.push(adPayment);
        burnTimes.push(block.timestamp);
        burners.push(msg.sender);
        return adMessages.length;
    }
    
    function getAdScores() public view returns(uint[] memory adScores) {
        adScores = new uint[](adMessages.length);
        for(uint ctr=0; ctr<adMessages.length; ctr++) {
            adScores[ctr] = ( adPayments[ctr]*31622400 )/( block.timestamp - burnTimes[ctr] );
            if( adScores[ctr] == 0) { // lowest adScore possible is 1.
                adScores[ctr] = 1;
            }
        }
        return adScores;
    }
    
    function getAdvertLeaderboard(uint topN) public view returns(string[] memory topAdverts, address[] memory topBurners) { 
        uint[] memory adScores = getAdScores();

        topAdverts = new string[](topN);
        topBurners = new address[](topN);

        for(uint ctr=0; ctr<topN; ctr++) { // This is the iterator over ranking
        
            uint maxScore = 0;
            uint maxIndex = 0;
        
            for(uint ctr3=0; ctr3<adMessages.length; ctr3++) { // find the highest score
                if(adScores[ctr3] > maxScore) { // Updates the masScore and maxIndex
                    maxScore = adScores[ctr3];
                    maxIndex = ctr3;
                }
            } // After this loop, maxScore should have the maximum score remaining, and maxIndex is that score's index
            if(maxScore == 0) { // 0 is a sentinel for "already recorded". A max of zero means that we're iterating over no more ads.
                return (topAdverts, topBurners); 
            }
            adScores[maxIndex] = 0; // 0 is a sentinel showing that this index has already been recorded.
            
            topAdverts[ctr] = adMessages[maxIndex]; // put the highest score into the topAdverts
            topBurners[ctr] = burners[maxIndex];
        }
        return(topAdverts,topBurners);
    }
}