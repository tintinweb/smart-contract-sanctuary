/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMolochSummoner {
    function summonMoloch(
        address[] memory _summoner,
        address[] memory _approvedTokens,
        uint256 _periodDuration,
        uint256 _votingPeriodLength,
        uint256 _gracePeriodLength,
        uint256 _proposalDeposit,
        uint256 _dilutionBound,
        uint256 _processingReward,
        uint256[] memory _summonerShares
    ) external returns (address);
}

interface IMinionFactory {
    function summonMinion(address moloch, string memory details, uint256 minQuorum) external returns (address);
}

interface IRicardianLLC {
    function mintLLC(address to) external payable;
}

/// @notice Summon a Moloch DAO v2 (daohaus.club) with Minion and optional LLC formation maintained by LexDAO (ricardian.gitbook.io).
contract MolochSummonerV2x { 
    IMolochSummoner constant dhMolochSummoner = IMolochSummoner(0x38064F40B20347d58b326E767791A6f79cdEddCe);
    IMinionFactory constant dhMinionFactory = IMinionFactory(0x7EDfBDED3077Bc035eFcEA1835359736Fa342209);
    IRicardianLLC constant ricardianLLC = IRicardianLLC(0x43B644a01d87025c9046F12eE4cdeC7E04258eBf);
    
    address constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant rai = 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919;
    address constant wETH  = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event SummonMoloch(address indexed moloch, address indexed minion);
    
    function summonMoloch(string calldata details) external returns (address moloch, address minion) {
        address[] memory _summoner = new address[](1);
        _summoner[0] = msg.sender;
        
        address[] memory _approvedTokens = new address[](3);
        _approvedTokens[0] = dai;
        _approvedTokens[1] = rai;
        _approvedTokens[2] = wETH;
        
        uint256[] memory _summonerShares = new uint256[](1);
        _summonerShares[0] = 100;
        
        moloch = dhMolochSummoner.summonMoloch( // summon Moloch w/ std presets
            _summoner,
            _approvedTokens,
            17280,
            35,
            35,
            0,
            3,
            0,
            _summonerShares);
        minion = dhMinionFactory.summonMinion(moloch, details, 50); // summon 'nifty' Minion
        emit SummonMoloch(moloch, minion);
    }
    
    function summonMolochLLC(string calldata details) external payable returns (address moloch, address minion) {
        address[] memory _summoner = new address[](1);
        _summoner[0] = msg.sender;
        
        address[] memory _approvedTokens = new address[](3);
        _approvedTokens[0] = dai;
        _approvedTokens[1] = rai;
        _approvedTokens[2] = wETH;
        
        uint256[] memory _summonerShares = new uint256[](1);
        _summonerShares[0] = 100;
        
        moloch = dhMolochSummoner.summonMoloch( // summon Moloch w/ std presets
            _summoner,
            _approvedTokens,
            17280,
            35,
            35,
            0,
            3,
            0,
            _summonerShares);
        minion = dhMinionFactory.summonMinion(moloch, details, 50); // summon 'nifty' Minion
        ricardianLLC.mintLLC{value: msg.value}(minion); // form LLC for DAO and deposit registration NFT into Minion - fwd any ether to Ricardian LLC mgmt
        emit SummonMoloch(moloch, minion);
    }
}