/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Game {

    uint public fightPrice = 1 ether;
    address public owner;
    string public mySecretKey = "Fuck Thief";
    uint public result;

    uint[] commonProbability;
    uint[] rareProbability;
    uint[] legendProbability;
    uint[] commonReward;
    uint[] rareReward;
    uint[] legendReward;

    event FightLog(address fightAddress, uint reward);
 
    RedCatV2 redcatsContract = RedCatV2(0xb93ec545CB46334c065B67225813c5C8d24Ebbd7);

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    //預設開啟要有機率和多少獎池
    constructor() {
        owner = msg.sender;
    }

    //玩
    function play() public payable {
        require(msg.value == fightPrice, "money sent is not correct");
        require(address(this).balance == 0, "pool no money");

        result = random() % 6161;

        if(getNFTOwnerCount(msg.sender) > 0) {
            // if(result <= haveNFTProbability[0]) {
            //     emit FightLog(msg.sender, 1);
            // } else if(result <= haveNFTProbability[1]) {
       
            // } else if(result >= haveNFTProbability[1] && result <= haveNFTProbability[2]) {
         
            // } else if(result <= haveNFTProbability[3]) {
           
            // } else if(result <= haveNFTProbability[4]) {
           
            // } else if(result <= haveNFTProbability[5]) {
           
            // } else if(result <= haveNFTProbability[6]) {
        
            // } else if(result <= haveNFTProbability[7]) {
        
            // } else if(result <= haveNFTProbability[8]) {
            
            // } else {
                
            // }       
        } else {
            emit FightLog(msg.sender, 0);
        }
    }

    //設置機率
    function setCommonProbability(uint[] calldata _commonProbability) public onlyOwner {
        commonProbability = _commonProbability;
    }

    function setRareProbability(uint[] calldata _rareProbability) public onlyOwner {
        rareProbability = _rareProbability;
    }

    function setLegendProbability(uint[] calldata _legendProbability) public onlyOwner {
        legendProbability = _legendProbability;
    }

    //設置獎勵       
    function setCommonReward(uint[] calldata _commonReward) public onlyOwner {
        commonReward = _commonReward;
    }

    function setRareReward(uint[] calldata _rareReward) public onlyOwner {
        rareReward = _rareReward;
    }

    function setLegendReward(uint[] calldata _legendReward) public onlyOwner {
        legendReward = _legendReward;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    //取得機率 
    function getCommonProbability() public view onlyOwner returns (uint[] memory) {
        return commonProbability;
    }

    function getRareProbability() public view onlyOwner returns (uint[] memory) {
        return rareProbability;
    }

    function getLegendProbability() public view onlyOwner returns (uint[] memory) {
        return legendProbability;
    }

    //取得獎勵       
    function getCommonReward() public view onlyOwner returns (uint[] memory) {
        return commonReward;
    }

    function getRareReward() public view onlyOwner returns (uint[] memory) {
        return rareReward;
    }

    function getLegendReward() public view onlyOwner returns (uint[] memory) {
        return legendReward;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(mySecretKey, block.number, block.timestamp)));
    }

    function getPool() public view returns(uint256) {
        return address(this).balance;
    }

    function getNFTOwnerCount(address _owner) public view returns (uint256) {
        return redcatsContract.walletOfOwner(_owner).length;
    }

    function getRarity(uint tokenId) public view returns (uint) {
        return redcatsContract.getRarity(tokenId);
    }
}

interface RedCatV2  {
    function walletOfOwner(address) external view returns (uint256[] memory);
    function getRarity(uint) external  view returns (uint256);
}