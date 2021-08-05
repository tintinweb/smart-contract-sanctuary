/**
 *Submitted for verification at Etherscan.io on 2020-11-21
*/

//SPDX-License-Identifier: unlicensed
pragma solidity ^0.7.0;

contract Boxes  {
    
    //other shit
    address payable owner;
    address payable[18] boxes;

    address[18] lastResultAddresses;
    uint256[18] lastResultAmounts;
    uint256 gameNumber;
    uint256 gameBlockFinishedOn;
    
    //split it, cos, bugsz
    function getBoxes1() public view returns (address, address, address, address, address, address, address, address) {
        return (boxes[0], boxes[1], boxes[2], boxes[3], boxes[4], boxes[5], boxes[6], boxes[7]);
    }
    
    function getBoxes2() public view returns (address, address, address, address, address, address, address) {
        return (boxes[8], boxes[9], boxes[10], boxes[11], boxes[12], boxes[13], boxes[14]);
    }

    function getJackpots() public view returns (uint256,uint256,uint256) {
        return (jackpotMini, jackpotMega, jackpotUltra);
    }
    
    function getLastGameResults() public view returns (address[18] memory, uint256[18] memory, uint256, uint256) {
        return (lastResultAddresses, lastResultAmounts, gameNumber, gameBlockFinishedOn);
    }

    // function debugSetBoxes() public {
    //     for(uint xo=0; xo < boxes.length; xo++){
    //         boxes[xo] = msg.sender;
    //     }
    // }
    
    uint256[18] boxPayoutAmounts;
    
    event debugShit(uint256);

    uint256 jackpotMini;
    uint256 jackpotMega;
    uint256 jackpotUltra;
    
    
    address payable[3]  jackpotWinners;
    uint256[3]  jackpotAmts;
    
    event gameResults(address[18], uint256[18], uint256, uint256);
    
    function random(uint256 maxBruh, uint256 nonce) private view returns (uint256) {
        //NOTE: This is INCLUSIVE, and NEVER PRODUCES 0;, i.e. random(3) = [1,2,3];
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
        ) % maxBruh;
        randomnumber = randomnumber + 1;
        nonce++;
        return randomnumber;
    }

     constructor() {
        owner = msg.sender;
    }
    
    function buyBox(uint256 boxNumber) public payable{
        
                    
        if(boxNumber > 15){
            revert("Learn to count cunt");
        }
        
        if(msg.value >= 50000000000000000) {
            //they sent enough
            if(boxes[boxNumber] == address(0)){
                //box is empty, it's for sale
                boxes[boxNumber] = msg.sender;
            } else {
                revert("Box already bought by some other Chad");
            }
        } else {
            revert("Send more monkeys ya cheap cunt");
        }
    }
    

    
    function finishGame() public payable returns(uint256[18] memory, address payable[18] memory){
        //NOTE: Jackpot winners/amounts are put in the last 3 slots of each array
        
        //reset some shit, stack was too deep so had to make them in storage, cunts.
        jackpotWinners[0] = 0x0000000000000000000000000000000000000000;
        jackpotWinners[1] = 0x0000000000000000000000000000000000000000;
        jackpotWinners[2] = 0x0000000000000000000000000000000000000000;
        jackpotAmts[0] = 0;
        jackpotAmts[1] = 0;
        jackpotAmts[2] = 0;
        
        for(uint zx=0; zx < boxes.length; zx++){
            boxes[zx] = msg.sender;
        }

        //check that all boxes have been purchased
        bool allBoxesPurchased = true;
        for(uint i=0; i < boxes.length; i++){
            if(boxes[i] == address(0)){
                allBoxesPurchased = false;
            }
        }
        
        uint256 jackpotWinHappenedMini = 0;
        uint256 jackpotWinHappenedMega = 0;
        uint256 jackpotWinHappenedUltra = 0;
        
        if(allBoxesPurchased == false){
            // revert("Game not done cunt, so fuck the fuck off");
        }
        
        //work out if its time to jackpot bruhhh
        if(random(10, 1337) == 1){
            jackpotWinHappenedMini = jackpotMini;
            jackpotMini = 0;
        }
        
        if(random(50, 13378) == 1){
            jackpotWinHappenedMega = jackpotMega;
            jackpotMega = 0;
        }
        
        if(random(200, 13379) == 1){
            jackpotWinHappenedUltra = jackpotUltra;
            jackpotUltra = 0;
        }
        
        //workout payouts for everything
        uint256  bigChunks = 200000000000000000;
        uint256  mediumChunks = 50000000000000000;
        uint256 tinyChunks = 50000000000000000;
        
        uint256 tempRandom;
        uint256 counterbruh;
        
        while(bigChunks > 0){
            tempRandom = random(15, counterbruh);
            boxPayoutAmounts[tempRandom - 1] = boxPayoutAmounts[tempRandom - 1] + 100000000000000000;
            bigChunks = bigChunks - 100000000000000000;
            counterbruh++;
        }
        
        while(mediumChunks > 0){
            tempRandom = random(15, counterbruh);
            boxPayoutAmounts[tempRandom - 1] = boxPayoutAmounts[tempRandom - 1] + 50000000000000000;
            mediumChunks = mediumChunks - 50000000000000000;
            counterbruh++;
        }

        while(tinyChunks > 0){
            tempRandom = random(15, counterbruh);
            boxPayoutAmounts[tempRandom - 1] = boxPayoutAmounts[tempRandom - 1] + 25000000000000000;
            tinyChunks = tinyChunks - 25000000000000000;
            counterbruh++;
        }
        
        //big chunk
        tempRandom = random(15, counterbruh);
        boxPayoutAmounts[tempRandom - 1] = boxPayoutAmounts[tempRandom - 1] + 250000000000000000;

        
        if(jackpotWinHappenedMini > 0){
            //payout jackpot mini
            uint256 anotherTempRandom = random(15, counterbruh);
            jackpotWinners[0] = boxes[anotherTempRandom];
            jackpotAmts[0] = jackpotWinHappenedMini;
            
            //transfer then emit a fucking event bruhhh
            jackpotMini = 0; //reset to zeero
            jackpotWinners[0].transfer(jackpotWinHappenedMini);
            counterbruh++;
        }
        
        //megaaaa
        if(jackpotWinHappenedMega > 0){
            //payout jackpot mega
            uint256 anotherTempRandom = random(15, counterbruh);
            jackpotWinners[1] = boxes[anotherTempRandom];
            jackpotAmts[1] = jackpotWinHappenedMega;
            
            //transfer then emit a fucking event bruhhh
            jackpotMega = 0; //reset to zeero
            jackpotWinners[1].transfer(jackpotWinHappenedMega);
            counterbruh++;
        }
        
        //ultraaaa
        if(jackpotWinHappenedUltra > 0){
            //payout jackpot ultra
            uint256 anotherTempRandom = random(15, counterbruh);
            jackpotWinners[2] = boxes[anotherTempRandom];
            jackpotAmts[2] = jackpotWinHappenedUltra;
            
            //transfer then emit a fucking event bruhhh
            jackpotUltra = 0; //reset to zeero
            jackpotWinners[2].transfer(jackpotWinHappenedUltra);
            counterbruh++;
        }
        
        
        for(uint uu=0; uu < 15; uu++){
            if(boxPayoutAmounts[uu] > 0 ){
            boxes[uu].transfer(boxPayoutAmounts[uu]);
            }
        }
        
        //add to the jackpots (same amount every time)
        jackpotMini = jackpotMini + 20000000000000000;
        jackpotMega = jackpotMega + 25000000000000000;
        jackpotUltra = jackpotUltra + 30000000000000000;
        
        //pay the devs everything left, minus jackpots, minus a safe balance left on the contract
        uint256 safezone = jackpotMini + jackpotMega + jackpotUltra + 100000000000000000;
        uint256 amountToPayDevs = address(this).balance - safezone;
        
        //min amount to pay devs is 0.1 ether
        if(amountToPayDevs  > 100000000000000000){
            owner.transfer(amountToPayDevs);
        }
        

        
        boxPayoutAmounts[15] = jackpotAmts[0];
        boxPayoutAmounts[16] = jackpotAmts[1];
        boxPayoutAmounts[17] = jackpotAmts[2];
        boxes[15] = jackpotWinners[0];
        boxes[16] = jackpotWinners[1];
        boxes[17] = jackpotWinners[2];

        
        gameNumber = gameNumber + 1;
        gameBlockFinishedOn = block.number;
        
        for(uint ii=0; ii < 18; ii++){
            lastResultAddresses[ii] = boxes[ii];
            lastResultAmounts[ii] = boxPayoutAmounts[ii];
            boxPayoutAmounts[ii] = 0;
            boxes[ii] = 0x0000000000000000000000000000000000000000;
        }
        
        emit gameResults(lastResultAddresses, lastResultAmounts, gameNumber, gameBlockFinishedOn);
        
    
    }
    
    // function cashout() public payable{
    //     msg.sender.transfer(address(this).balance - 0.01 ether);
    // }
    
        fallback() external payable {}
        
            receive() external payable {}

}