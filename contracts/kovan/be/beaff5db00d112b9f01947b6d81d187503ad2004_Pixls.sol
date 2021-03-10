/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity >=0.7.0;

contract Pixls {

    /**
    * @dev Mints yourself a Pixl. Or more. You do you.
    */
    
    function totalSupply() public view returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return 7000;
    }
    
    uint REVEAL_TIMESTAMP = 1615298100;
    
    function setRevealTimestamp (uint REVEAL) public {
        REVEAL_TIMESTAMP = REVEAL;
    }
    
    function mintAPixl(uint256 numberOfPixls) public payable {
        // Some exceptions that need to be handled.
        uint getPixlMaxAmount = 2;
        uint MAX_PIXL_SUPPLY = 6000;
        require(totalSupply() < MAX_PIXL_SUPPLY, "Sale has already ended.");
        require(numberOfPixls > 0, "You cannot mint 0 Pixls.");
        //require(numberOfPixls <= getPixlMaxAmount(), "You are not allowed to buy this many Pixls at once in this price tier.");
        // require(SafeMath.add(totalSupply(), numberOfPixls) <= MAX_PIXL_SUPPLY, "Exceeds maximum Pixl supply. Please try to mint less Pixls.");
        // require(SafeMath.mul(getPixlPrice(), numberOfPixls) == msg.value, "Amount of Ether sent is not correct.");

        // Mint the amount of provided Pixls.
        for (uint i = 0; i < numberOfPixls; i++) {
            uint mintIndex = totalSupply();
            // if (block.timestamp < REVEAL_TIMESTAMP) {
            //     _mintedBeforeReveal[mintIndex] = true;
            // }
            //_safeMint(msg.sender, mintIndex);
        }

        // Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        // Set the starting block index when the sale concludes either time-wise or the supply runs out.
        // if (startingIndexBlock == 0 && (totalSupply() == MAX_PIXL_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
        //     startingIndexBlock = block.number;
        // }
    }
}