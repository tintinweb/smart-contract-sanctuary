pragma solidity ^0.4.25;

/*
* CryptoMiningWar - Blockchain-based strategy game
* Author: InspiGames
* Website: https://cryptominingwar.github.io/
*/

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
contract CryptoEngineerOldInterface {
    address public gameSponsor;
    uint256 public gameSponsorPrice;
    
    function getBoosterData(uint256 /*idx*/) public view returns (address /*_owner*/,uint256 /*_boostRate*/, uint256 /*_basePrice*/) {}
    function calculateCurrentVirus(address /*_addr*/) external view returns(uint256 /*_currentVirus*/) {}
    function getPlayerData(address /*_addr*/) external view returns(uint256 /*_engineerRoundNumber*/, uint256 /*_virusNumber*/, uint256 /*_virusDefence*/, uint256 /*_research*/, uint256 /*_researchPerDay*/, uint256 /*_lastUpdateTime*/, uint256[8] /*_engineersCount*/, uint256 /*_nextTimeAtk*/, uint256 /*_endTimeUnequalledDef*/) {}
}
interface CryptoArenaOldInterface {
    function getData(address _addr) 
    external
    view
    returns(
        uint256 /*_virusDef*/,
        uint256 /*_nextTimeAtk*/,
        uint256 /*_endTimeUnequalledDef*/,
        bool    /*_canAtk*/,
        // engineer
        uint256 /*_currentVirus*/, 
        // mingin war
        uint256 /*_currentCrystals*/
    );
}

contract CryptoEngineerNewInterface {
    mapping(uint256 => EngineerData) public engineers;
     struct EngineerData {
            uint256 basePrice;
            uint256 baseETH;
            uint256 baseResearch;
            uint256 limit;
     }

    function setBoostData(uint256 /*idx*/, address /*owner*/, uint256 /*boostRate*/, uint256 /*basePrice*/ ) external pure {}
    function setPlayerEngineersCount( address /*_addr*/, uint256 /*idx*/, uint256 /*_value*/ ) external pure {}
    function setGameSponsorInfo( address /*_addr*/, uint256 /*_value*/ ) external pure {}
    function setPlayerResearch( address /*_addr*/, uint256 /*_value*/ ) external pure {}
    function setPlayerVirusNumber( address /*_addr*/, uint256 /*_value*/ ) external pure {}
    function setPlayerLastUpdateTime( address /*_addr*/) external pure {}
}
interface CryptoArenaNewInterface {
    function setPlayerVirusDef(address /*_addr*/, uint256 /*_value*/) external pure; 
}
contract CryptoLoadEngineerOldData {
    // engineer info
	address public administrator;
    bool public loaded;

    mapping(address => bool) public playersLoadOldData;
   
    CryptoEngineerNewInterface public EngineerNew;
    CryptoEngineerOldInterface public EngineerOld;    
    CryptoArenaNewInterface    public ArenaNew;
    CryptoArenaOldInterface    public ArenaOld;

    modifier isAdministrator()
    {
        require(msg.sender == administrator);
        _;
    }

    //--------------------------------------------------------------------------
    // INIT CONTRACT 
    //--------------------------------------------------------------------------
    constructor() public {
        administrator = msg.sender;
        // set interface main contract
       EngineerNew = CryptoEngineerNewInterface(0xd7afbf5141a7f1d6b0473175f7a6b0a7954ed3d2);
       EngineerOld = CryptoEngineerOldInterface(0x69fd0e5d0a93bf8bac02c154d343a8e3709adabf);
       ArenaNew    = CryptoArenaNewInterface(0x77c9acc811e4cf4b51dc3a3e05dc5d62fa887767);
       ArenaOld    = CryptoArenaOldInterface(0xce6c5ef2ed8f6171331830c018900171dcbd65ac);

    }

    function () public payable
    {
    }
    /**
        * @dev MainContract used this function to verify game&#39;s contract
        */
        function isContractMiniGame() public pure returns(bool _isContractMiniGame)
        {
        	_isContractMiniGame = true;
        }
    //@dev use this function in case of bug
    function upgrade(address addr) public isAdministrator
    {
        selfdestruct(addr);
    }
    function loadEngineerOldData() public isAdministrator 
    {
        require(loaded == false);
        loaded = true;
        address gameSponsor      = EngineerOld.gameSponsor();
        uint256 gameSponsorPrice = EngineerOld.gameSponsorPrice();
        EngineerNew.setGameSponsorInfo(gameSponsor, gameSponsorPrice);
        for(uint256 idx = 0; idx < 5; idx++) {
            mergeBoostData(idx);
        }
    }
    function mergeBoostData(uint256 idx) private
    {
        address owner;
        uint256 boostRate;
        uint256 basePrice;
        (owner, boostRate, basePrice) = EngineerOld.getBoosterData(idx);

        if (owner != 0x0) EngineerNew.setBoostData(idx, owner, boostRate, basePrice);
    }
    function loadOldData() public 
    {
        require(tx.origin == msg.sender);
        require(playersLoadOldData[msg.sender] == false);

        playersLoadOldData[msg.sender] = true;

        uint256[8] memory engineersCount; 
        uint256 virusDef;
        uint256 researchPerDay;
        
        uint256 virusNumber = EngineerOld.calculateCurrentVirus(msg.sender);
        // /function getPlayerData(address /*_addr*/) external view returns(uint256 /*_engineerRoundNumber*/, uint256 /*_virusNumber*/, uint256 /*_virusDefence*/, uint256 /*_research*/, uint256 /*_researchPerDay*/, uint256 /*_lastUpdateTime*/, uint256[8] /*_engineersCount*/, uint256 /*_nextTimeAtk*/, uint256 /*_endTimeUnequalledDef*/) 
        (, , , , researchPerDay, , engineersCount, , ) = EngineerOld.getPlayerData(msg.sender);

        (virusDef, , , , , ) = ArenaOld.getData(msg.sender);

        virusNumber = SafeMath.sub(virusNumber, SafeMath.mul(researchPerDay, 432000));
        uint256 research = 0;
        uint256 baseResearch = 0;

        for (uint256 idx = 0; idx < 8; idx++) {
            if (engineersCount[idx] > 0) {
                (, , baseResearch, ) = EngineerNew.engineers(idx);
                EngineerNew.setPlayerEngineersCount(msg.sender, idx, engineersCount[idx]);
                research = SafeMath.add(research, SafeMath.mul(engineersCount[idx], baseResearch));
            }    
        }
        EngineerNew.setPlayerLastUpdateTime(msg.sender);
        if (research > 0)    EngineerNew.setPlayerResearch(msg.sender, research);
        
        if (virusNumber > 0) EngineerNew.setPlayerVirusNumber(msg.sender, virusNumber);

        if (virusDef > 0)    ArenaNew.setPlayerVirusDef(msg.sender, virusDef);
    }

}