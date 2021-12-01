// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";

// Part: rarity_gold

interface rarity_gold {
    function balanceof(uint256) external returns (uint256);
    function transfer(uint256, uint256, uint256) external returns (bool);
}

// Part: rarity_manifested
interface rarity_manifested {
    function summon(uint) external;
    function next_summoner() external view returns (uint);
    function approve(address, uint256) external;
    function getApproved(uint256) external view returns (address);
    function ownerOf(uint256) external view returns (address);
}

contract BoxingIGame is Ownable {
    string public constant name = "Rarity Boxing";
    string public constant symbol = "boxing";
    
    // Rarity Contracts
    rarity_manifested constant rm = rarity_manifested(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    rarity_gold constant       gold = rarity_gold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
    
    uint public immutable BOX_SUMMONER_ID;
    uint256 public ftmDepositAmount = 0;
    
    mapping(uint256 => uint256) public goldBalances;
    mapping(uint256 => uint256) goldTimestamp;
    
    mapping(address => uint256) public ftmBalances;
    mapping(address => uint256) ftmTimestamp;
    
    constructor() {
        BOX_SUMMONER_ID = rm.next_summoner();
        rm.summon(11);
        ftmDepositAmount = 0;
    }
    
    function deposit_gold(uint256 _from, uint256 _amount) external payable {
        require(_isOwner(_from), "!owner");
        require(goldBalances[_from] == 0, "last gold game uncomplete!");
        
        rm.approve(address(this), _from);
        
        require(gold.transfer(_from, BOX_SUMMONER_ID, _amount), "deposit gold failure!");
        
        goldBalances[_from] = _amount;
        goldTimestamp[_from] = block.timestamp;
        
    }

    function withdraw_gold(uint256 _id) external payable {
        require(_isOwner(_id), "!owner");
        require(goldBalances[_id] > 0, "not enough balance!");
        require(block.timestamp >= (goldTimestamp[_id] + 86400), "one day at least!");
        
        uint256 _amount = goldBalances[_id];
        goldBalances[_id] = 0;
  
        require(gold.transfer(BOX_SUMMONER_ID, _id, _amount), "wihdraw deposit failure!");
        
    }
    
    function claim_gold(uint256 _winner, uint256 _loser) external onlyOwner {
        require((goldBalances[_winner] + goldBalances[_loser]) > 0, "not enough balance!");
       
        uint256 _amount = goldBalances[_winner] + goldBalances[_loser];
        goldBalances[_winner] = 0;
        goldBalances[_loser] = 0;
        require(gold.transfer(BOX_SUMMONER_ID, _winner, _amount), "claim gold failure!");

    }
    
    function dogfall_gold(uint256 _id) external onlyOwner {
        require(goldBalances[_id] > 0, "not enough balance!");
        
        uint256 _amount = goldBalances[_id];
        goldBalances[_id] = 0;
        require(gold.transfer(BOX_SUMMONER_ID, _id, _amount),"dogfall gold failure!");
    
    }

    
    function deposit_ftm(uint256 _amount) external payable{
        require(ftmBalances[msg.sender] == 0, "last ftm game uncomplete!");
        require(_amount >= 1 ether, "at least 1 ether!");
        require(msg.value > _amount, "not enough deposit!");
        
        ftmBalances[msg.sender] = _amount;
        ftmDepositAmount += _amount;
        ftmTimestamp[msg.sender] = block.timestamp;
         
    }
    
    function withdraw_ftm(address _to) external onlyOwner {
        require(ftmBalances[_to] > 0, "no balance!");
        require(ftmDepositAmount >= ftmBalances[_to], "beyond total deposit!");
        require(block.timestamp  >= (ftmTimestamp[_to] + 86400), "one day at least!");
        
        uint256 _amount = ftmBalances[_to];
        ftmBalances[_to] = 0;
        ftmDepositAmount -= _amount;
        payable(_to).transfer(_amount);
    }
    
    function claim_ftm(address _winner, address _loser) external onlyOwner {
        require((ftmBalances[_winner] + ftmBalances[_loser]) > 0, "no balance!");
        require(ftmDepositAmount >= (ftmBalances[_winner] + ftmBalances[_loser]), "beyond total deposit!");
        
        uint256 _amount = ftmBalances[_winner] + ftmBalances[_loser];
        ftmBalances[_winner] = 0;
        ftmBalances[_loser] = 0;
        ftmDepositAmount -= _amount;
        
        payable(_winner).transfer(_amount);
        
    }
    
     function dogfall_ftm(address _addr) external onlyOwner {
        require(ftmBalances[_addr] > 0, "no balance!");
        require(ftmDepositAmount >= ftmBalances[_addr], "beyond total deposit!");
        
        uint256 _amount = ftmBalances[_addr];
        ftmBalances[_addr] = 0;
        ftmDepositAmount -= _amount;
        
        payable(_addr).transfer(_amount);

    }
    
    function _isOwner(uint _id) internal view returns (bool) {
        return rm.ownerOf(_id) == msg.sender;
    }

    function withdrawFees(
        address to
    ) external onlyOwner {
        require(address(this).balance > ftmDepositAmount, "not enough balance!");
        
        uint256 _take = address(this).balance - ftmDepositAmount;
        payable(to).transfer(_take);
    }
    
    function withdraw(
        address to
    ) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}