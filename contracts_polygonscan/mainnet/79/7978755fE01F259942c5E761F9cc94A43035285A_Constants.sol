// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

import "../interfaces/IConstants.sol";

contract Constants is IConstants {

    //Common
    address public override statisticsContract;
    address public override helpersContract;
    address public override pooTokenContract;
    address public override userAccountContract;

    //Poos
    address public override PoosContract;
    address public override PooFightContract;
    address public override PooLevelHandlerContract;
    address public override PoosMarketplaceContract;
    address public override PooPowerUpHandlerContract;
    address public override PooTamagotchiContract;

    //Dumplings
    address public override DumplingsContract;
    address public override DumplingFightContract;
    address public override DumplingLevelHandlerContract;
    address public override DumplingsMarketplaceContract;
    address public override DumplingPowerUpHandlerContract;
    address public override DumplingTamagotchiContract;

    event HelpersContractChanged(address indexed _contract);
    event PoosContractChanged(address indexed _contract);
    event UserAccountContractChanged(address indexed _contract);
    event PooLevelHandlerContractChanged(address indexed _contract);
    event DumplingLevelHandlerContractChanged(address indexed _contract);
    event PoosMarketplaceContractChanged(address indexed _contract);
    event DumplingsContractChanged(address indexed _contract);
    event DumplingsMarketplaceContractChanged(address indexed _contract);
    event PooPowerUpHandlerContractChanged(address indexed _contract);
    event DumplingPowerUpHandlerContractChanged(address indexed _contract);
    event PooTamagotchiContractChanged(address indexed _contract);
    event DumplingTamagotchiContractChanged(address indexed _contract);
    event PooFightContractChanged(address indexed _contract);
    event DumplingFightContractChanged(address indexed _contract);
    event PooTokenContractChanged(address indexed _contract);
    event RevChanged(address indexed _new);
    event PricesChanged(uint _tokenAmountForMint, uint _priceForHundredPowerUp, uint _priceForTwoHundredPowerUp, uint _priceForThreeHundredPowerUp);
    event XpChanged(uint indexed _winnerXP, uint indexed _loserXP);
    event OwnerChanged(address indexed _newOwner);
    event BlocksBetweenRestPointChanged(uint indexed _newBlocks);
    event BlocksBetweenHungerPointForPooChanged(uint indexed _newBlocks);
    event BlocksBetweenHungerPointForDumplingChanged(uint indexed _newBlocks);
    event SaleFeePercentageChanged(uint indexed _newSellFee);
    event FightExhaustionChanged(uint indexed _newExhaustion);
    event DumplingsPercentageOfParentChanged(uint indexed _newDumplingsPercentageOfParent);
    event PooTokenForFeedChanged(uint indexed _newPooTokenForFeed);
    event PooTokenForInstantExhaustionResetChanged(uint indexed _newPooTokenForInstantExhaustionReset);
    event PooTokenForResurrectChanged(uint indexed _newPooTokenForResurrect);
    event PooTokenForRenamePooChanged(uint indexed _newPooTokenForRenamePoo);
    event PooTokenForFightChanged(uint indexed _newPooTokenForFight);
    event PooTokenForDumplingMintChanged(uint indexed _newPooTokenForDumplingMint);
    event BlocksBetweenDumplingMintForPooChanged(uint indexed _newBlocksBetweenDumplingMintForPoo);
    event BlocksBetweenPooRewardForRandomFightsChanged(uint indexed _newBlocksBetweenPooRewardForRandomFights);
    event BlocksBetweenPooRewardForIndividualFightsChanged(uint indexed _newBlocksBetweenPooRewardForIndividualFights);
    event PooRewardForFightChanged(uint indexed _newPooRewardForFight);
    event AllowedContractAdded(address indexed _contract);
    event AllowedContractRemoved(address indexed _contract);
    event ConstantsContractChanged(address indexed _contract);
    event OwnerRewardPercentageChanged(uint indexed _newDevRewardPercentage);
    event RevRewardPercentageChanged(uint indexed _newRevRewardPercentage);

    // 50 MATIC
    uint public pooMintCosts = 50000000000000000000;
    // 250 POO
    uint public tokenAmountForMint = 250000000000000000000;
    // 10 POO
    uint public pooTokenForFeed = 10000000000000000000;
    // 50 POO = 50000000000000000000
    uint public pooTokenForInstantExhaustionReset = 1000000000000000000;
    // 150 POO
    uint public pooTokenForResurrect = 150000000000000000000;
    // 250 POO
    uint public pooTokenForRenamePoo = 250000000000000000000;
    // 12.5 POO
    uint public pooTokenForFight = 12500000000000000000;
    // 200 POO
    uint public pooTokenForDumplingMint = 200000000000000000000;
    // 10 POO
    uint public pooTokenForHundredPowerUp = 10000000000000000000;
    // 20 POO
    uint public pooTokenForTwoHundredPowerUp = 20000000000000000000;
    // 25 POO
    uint public pooTokenForThreeHundredPowerUp = 25000000000000000000;
    // 50 POO reward for fights = 50000000000000000000
    uint public pooRewardForFight = 100000000000000000000;

    // every 15m
    uint public override blocksBetweenRestPoint = 450;

    // every 15m dead after 1day
    uint public blocksBetweenHungerPointForDumpling = 450;

    // every 30m dead after 2day
    uint public blocksBetweenHungerPointForPoo = 900;

    /// 10%
    uint public saleFeePercentage = 10;

    uint public fightExhaustion = 21;

    /// 10%
    uint public dumplingsPercentageOfParent = 10;

    // every 6 days = 259200
    uint public blocksBetweenDumplingMintForPoo = 1;

    // every 6h = 10800
    uint public blocksBetweenPooRewardForRandomFights = 1;

    // every 3h = 5400
    uint public blocksBetweenPooRewardForIndividualFights = 1;

    // base factor for dinamically increasing the blocks between  Dumpling minutes
    // every 6 days = 259200
    uint public baseBlockBetweenDumplingMint = 259200;

    uint public maxMintableDumplingsForPoo = 2;

    // reward percentage
    uint public ownerRewardPercentage = 60;
    uint public revRewardPercentage = 40;


    uint public winnerXp = 25;
    uint public loserXp = 9;

    address public owner;
    address public rev;

    constructor() {
        owner = msg.sender;
        rev = payable(0xA2F5783e206DF376f77cd54caF3780581016FE87);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "The sender of the message needs to be the contract owner.");
        _;
    }

    function setPooMintCosts(uint _newCosts) public onlyOwner {
        pooMintCosts = _newCosts;
    }

    function setMaxMintableDumplingsForPoo(uint _newMax) public onlyOwner {
        maxMintableDumplingsForPoo = _newMax;
    }

    function setStatisticsContract(address _address) public onlyOwner {
        statisticsContract = _address;
        emit ConstantsContractChanged(_address);
    }

    function setHelpersContract(address _address) public onlyOwner {
        helpersContract = _address;
        emit HelpersContractChanged(_address);
    }

    function setPoosContract(address _address) public onlyOwner {
        PoosContract = _address;
        emit PoosContractChanged(_address);
    }

    function setUserAccountContract(address _address) public onlyOwner {
        userAccountContract = _address;
        emit UserAccountContractChanged(_address);
    }

    function setPooLevelHandlerContract(address _address) public onlyOwner {
        PooLevelHandlerContract = _address;
        emit PooLevelHandlerContractChanged(_address);
    }

    function setDumplingLevelHandlerContract(address _address) public onlyOwner {
        DumplingLevelHandlerContract = _address;
        emit DumplingLevelHandlerContractChanged(_address);
    }

    function setPoosMarketplaceContract(address _address) public onlyOwner {
        PoosMarketplaceContract = _address;
        emit PoosMarketplaceContractChanged(_address);
    }

    function setDumplingsContract(address _address) public onlyOwner {
        DumplingsContract = _address;
        emit DumplingsContractChanged(_address);
    }

    function setDumplingsMarketplaceContract(address _address) public onlyOwner {
        DumplingsMarketplaceContract = _address;
        emit DumplingsMarketplaceContractChanged(_address);
    }

    function setPooPowerUpHandlerContract(address _address) public onlyOwner {
        PooPowerUpHandlerContract = _address;
        emit PooPowerUpHandlerContractChanged(_address);
    }

    function setDumplingPowerUpHandlerContract(address _address) public onlyOwner {
        DumplingPowerUpHandlerContract = _address;
        emit DumplingPowerUpHandlerContractChanged(_address);
    }

    function setPooTamagotchiContract(address _address) public onlyOwner {
        PooTamagotchiContract = _address;
        emit PooTamagotchiContractChanged(_address);
    }

    function setDumplingTamagotchiContract(address _address) public onlyOwner {
        DumplingTamagotchiContract = _address;
        emit DumplingTamagotchiContractChanged(_address);
    }

    function setPooFightContract(address _address) public onlyOwner {
        PooFightContract = _address;
        emit PooFightContractChanged(_address);
    }

    function setDumplingFightContract(address _address) public onlyOwner {
        DumplingFightContract = _address;
        emit DumplingFightContractChanged(_address);
    }

    function setPooTokenContract(address _address) public onlyOwner {
        pooTokenContract = _address;
        emit PooTokenContractChanged(_address);
    }

    function setOwner(address _address) public onlyOwner {
        owner = _address;
        emit OwnerChanged(_address);
    }

    function setRev(address _address) public onlyOwner {
        rev = _address;
        emit RevChanged(_address);
    }

    function setBlocksBetweenRestPoint(uint _newBlocksBetweenRestPoint) public onlyOwner {
        blocksBetweenRestPoint = _newBlocksBetweenRestPoint;
        emit BlocksBetweenRestPointChanged(_newBlocksBetweenRestPoint);
    }

    function setBlocksBetweenHungerPointForPoo(uint _newBlocksBetweenHungerPointForPoo) public onlyOwner {
        blocksBetweenHungerPointForPoo = _newBlocksBetweenHungerPointForPoo;
        emit BlocksBetweenHungerPointForPooChanged(_newBlocksBetweenHungerPointForPoo);
    }

    function setBlocksBetweenHungerPointForDumpling(uint _newBlocksBetweenHungerPointForDumpling) public onlyOwner {
        blocksBetweenHungerPointForDumpling = _newBlocksBetweenHungerPointForDumpling;
        emit BlocksBetweenHungerPointForDumplingChanged(_newBlocksBetweenHungerPointForDumpling);
    }

    function setPrices(uint _tokenAmountForMint, uint _pooTokenForHundredPowerUp, uint _pooTokenForTwoHundredPowerUp, uint _pooTokenForThreeHundredPowerUp) public onlyOwner {
        tokenAmountForMint = _tokenAmountForMint;
        pooTokenForHundredPowerUp = _pooTokenForHundredPowerUp;
        pooTokenForTwoHundredPowerUp = _pooTokenForTwoHundredPowerUp;
        pooTokenForThreeHundredPowerUp = _pooTokenForThreeHundredPowerUp;
        emit PricesChanged(_tokenAmountForMint, _pooTokenForHundredPowerUp, _pooTokenForTwoHundredPowerUp, _pooTokenForThreeHundredPowerUp);
    }

    function setXp(uint _winnerXP, uint _loserXP) public onlyOwner {
        winnerXp = _winnerXP;
        loserXp = _loserXP;
        emit XpChanged(_winnerXP, _loserXP);
    }

    function setSaleFeePercentage(uint _newSaleFeePercentage) public onlyOwner {
        saleFeePercentage = _newSaleFeePercentage;
        emit SaleFeePercentageChanged(_newSaleFeePercentage);
    }

    function setFightExhaustion(uint _newExhaustion) public onlyOwner {
        fightExhaustion = _newExhaustion;
        emit FightExhaustionChanged(_newExhaustion);
    }

    function setDumplingsPercentageOfParent(uint _newDumplingsPercentageOfParent) public onlyOwner {
        dumplingsPercentageOfParent = _newDumplingsPercentageOfParent;
        emit DumplingsPercentageOfParentChanged(_newDumplingsPercentageOfParent);
    }

    function setpooTokenForFeed(uint _pooTokenForFeed) public onlyOwner {
        pooTokenForFeed = _pooTokenForFeed;
        emit PooTokenForFeedChanged(_pooTokenForFeed);
    }

    function setpooTokenForInstantExhaustionReset(uint _pooTokenForInstantExhaustionReset) public onlyOwner {
        pooTokenForInstantExhaustionReset = _pooTokenForInstantExhaustionReset;
        emit PooTokenForInstantExhaustionResetChanged(_pooTokenForInstantExhaustionReset);
    }

    function setpooTokenForResurrect(uint _pooTokenForResurrect) public onlyOwner {
        pooTokenForResurrect = _pooTokenForResurrect;
        emit PooTokenForResurrectChanged(_pooTokenForResurrect);
    }

    function setpooTokenForRenamePoo(uint _pooTokenForRenamePoo) public onlyOwner {
        pooTokenForRenamePoo = _pooTokenForRenamePoo;
        emit PooTokenForRenamePooChanged(_pooTokenForRenamePoo);
    }

    function setpooTokenForFight(uint _pooTokenForFight) public onlyOwner {
        pooTokenForFight = _pooTokenForFight;
        emit PooTokenForFightChanged(_pooTokenForFight);
    }

    function setpooTokenForDumplingMint(uint _pooTokenForDumplingMint) public onlyOwner {
        pooTokenForDumplingMint = _pooTokenForDumplingMint;
        emit PooTokenForDumplingMintChanged(_pooTokenForDumplingMint);
    }

    function setBlocksBetweenDumplingMintForPoo(uint _newBlocksBetweenDumplingMintForPoo) public onlyOwner {
        blocksBetweenDumplingMintForPoo = _newBlocksBetweenDumplingMintForPoo;
        emit BlocksBetweenDumplingMintForPooChanged(_newBlocksBetweenDumplingMintForPoo);
    }

    function setblocksBetweenPooRewardForRandomFights(uint _newblocksBetweenPooRewardForRandomFights) public onlyOwner {
        blocksBetweenPooRewardForRandomFights = _newblocksBetweenPooRewardForRandomFights;
        emit BlocksBetweenPooRewardForRandomFightsChanged(_newblocksBetweenPooRewardForRandomFights);
    }

    function setblocksBetweenPooRewardForIndividualFights(uint _newblocksBetweenPooRewardForIndividualFights) public onlyOwner {
        blocksBetweenPooRewardForIndividualFights = _newblocksBetweenPooRewardForIndividualFights;
        emit BlocksBetweenPooRewardForIndividualFightsChanged(_newblocksBetweenPooRewardForIndividualFights);
    }

    function setpooRewardForFight(uint _newpooRewardForFight) public onlyOwner {
        pooRewardForFight = _newpooRewardForFight;
        emit PooRewardForFightChanged(_newpooRewardForFight);
    }

    function setOwnerRewardsPercentage(uint _newOwnerRewardsPercentage) public onlyOwner {
        ownerRewardPercentage = _newOwnerRewardsPercentage;
        emit OwnerRewardPercentageChanged(_newOwnerRewardsPercentage);
    }

    function setRevRewardsPercentage(uint _newRevRewardsPercentage) public onlyOwner {
        revRewardPercentage = _newRevRewardsPercentage;
        emit RevRewardPercentageChanged(_newRevRewardsPercentage);
    }

    function getContracts() public view returns (address[16] memory) {
        return [statisticsContract,
        helpersContract,
        pooTokenContract,
        userAccountContract,
        PoosContract,
        PooFightContract,
        PooLevelHandlerContract,
        PoosMarketplaceContract,
        PooPowerUpHandlerContract,
        PooTamagotchiContract,
        DumplingsContract,
        DumplingFightContract,
        DumplingLevelHandlerContract,
        DumplingsMarketplaceContract,
        DumplingPowerUpHandlerContract,
        DumplingTamagotchiContract];
    }

    function getPrices() public view returns (uint[11] memory) {
        return [
        pooMintCosts,
        tokenAmountForMint,
        pooTokenForFeed,
        pooTokenForInstantExhaustionReset,
        pooTokenForResurrect,
        pooTokenForRenamePoo,
        pooTokenForFight,
        pooTokenForDumplingMint,
        pooTokenForHundredPowerUp,
        pooTokenForTwoHundredPowerUp,
        pooTokenForThreeHundredPowerUp];
    }

    function getInfo() public view returns (uint[11] memory) {
        return [
        pooRewardForFight,
        blocksBetweenRestPoint,
        blocksBetweenHungerPointForDumpling,
        blocksBetweenHungerPointForPoo,
        fightExhaustion,
        dumplingsPercentageOfParent,
        blocksBetweenDumplingMintForPoo,
        blocksBetweenPooRewardForRandomFights,
        blocksBetweenPooRewardForIndividualFights,
        baseBlockBetweenDumplingMint,
        maxMintableDumplingsForPoo];
    }

}

// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

interface IConstants {

    function statisticsContract() external view returns (address);

    function helpersContract() external view returns (address);

    function PooFightContract() external view returns (address);

    function DumplingFightContract() external view returns (address);

    function pooTokenContract() external view returns (address);

    function userAccountContract() external view returns (address);

    function PoosContract() external view returns (address);

    function PooLevelHandlerContract() external view returns (address);

    function PoosMarketplaceContract() external view returns (address);

    function PooPowerUpHandlerContract() external view returns (address);

    function PooTamagotchiContract() external view returns (address);

    function DumplingsContract() external view returns (address);

    function DumplingLevelHandlerContract() external view returns (address);

    function DumplingsMarketplaceContract() external view returns (address);

    function DumplingPowerUpHandlerContract() external view returns (address);

    function DumplingTamagotchiContract() external view returns (address);

    function tokenAmountForMint() external view returns (uint);

    function pooTokenForFeed() external view returns (uint);

    function pooTokenForInstantExhaustionReset() external view returns (uint);

    function pooTokenForResurrect() external view returns (uint);

    function pooTokenForRenamePoo() external view returns (uint);

    function pooTokenForFight() external view returns (uint);

    function pooTokenForDumplingMint() external view returns (uint);

    function pooTokenForHundredPowerUp() external view returns (uint);

    function pooTokenForTwoHundredPowerUp() external view returns (uint);

    function pooTokenForThreeHundredPowerUp() external view returns (uint);

    function winnerXp() external view returns (uint);

    function loserXp() external view returns (uint);

    function owner() external view returns (address);

    function rev() external view returns (address);

    function blocksBetweenRestPoint() external view returns (uint);

    function blocksBetweenHungerPointForPoo() external view returns (uint);

    function blocksBetweenHungerPointForDumpling() external view returns (uint);

    function saleFeePercentage() external view returns (uint);

    function fightExhaustion() external view returns (uint);

    function dumplingsPercentageOfParent() external view returns (uint);

    function blocksBetweenDumplingMintForPoo() external view returns (uint);

    function blocksBetweenPooRewardForRandomFights() external view returns (uint);

    function blocksBetweenPooRewardForIndividualFights() external view returns (uint);

    function pooRewardForFight() external view returns (uint);

    function baseBlockBetweenDumplingMint() external view returns (uint);

    function ownerRewardPercentage() external view returns (uint);

    function revRewardPercentage() external view returns (uint);

    function maxMintableDumplingsForPoo() external view returns (uint);

    function pooMintCosts() external view returns (uint);

}