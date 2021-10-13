pragma solidity ^0.8.0;

contract Balances {

    struct  MinerBalances  {

        uint foremen;
        uint goldMiner;
        uint skilledGoldMiner;
        uint silverMiner;
        uint skilledSilverMiner;
        uint coalMiner;
        uint skilledCoalMiner;
        uint ironMiner;
        uint skilledIronMiner;
        uint stoneMiner;
        uint skilledStoneMiner;
        }

    mapping(uint=>string) minerBalances;
    mapping (address => mapping (string => uint)) public minerBalancesByTypes;
    address public lastCaller;

    function _createMinerTypeData() private returns(MinerBalances memory ){

        return MinerBalances(0,0,0,0,0,0,0,0,0,0,0);

    }

    function getMinerBalancesByTypes(string memory minerType) public view returns(uint) {

        return minerBalancesByTypes[msg.sender][minerType];
    }

    function setMinerBalancesByTypes(string memory minerType, address owner) public {
//        MinerBalances memory minerBalances = minerBalancesByTypes[owner];
        minerBalancesByTypes[owner][minerType] +=1;
//        minerBalances.minerType
    }


}