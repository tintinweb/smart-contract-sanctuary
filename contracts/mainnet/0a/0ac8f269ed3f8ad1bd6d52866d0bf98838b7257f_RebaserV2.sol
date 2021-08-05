/**
 *Submitted for verification at Etherscan.io on 2020-11-12
*/

pragma solidity ^0.6.6;

abstract contract RebasableContract {
    function rebase(int supplyDelta) virtual external returns (uint);
}

abstract contract SyncableContract {
    function sync() virtual external;
}

contract RebaserV2 {
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    uint public initTime;
    uint public secondsPerSupplyBlock = 86400;
    RebasableContract orbiContract;
    RebasableContract twin0Contract;
    RebasableContract twin1Contract;
    SyncableContract twin0LiqContract;
    SyncableContract twin1LiqContract;
    SyncableContract orbiLiqContract;
    address public orbiAddress;
    address public twin0Address;
    address public twin1Address;
    address public orbiLiqAddress;
    address public twin0LiqAddress;
    address public twin1LiqAddress;
    address public owner;
    uint public orbiSupplyTotal = 100000000000000000;
    uint public twin0SupplyTotal = 10000000000000;
    uint public twin1SupplyTotal = 10000000000000;
    uint[] public twinSupplyList = [10000000000000, 10867767478235, 11563662964936,  
                                    11949855824364, 11949855824364, 11563662964936,  
                                    10867767478235, 10000000000000,  9132232521765, 
                                     8436337035064,  8050144175636,  8050144175636, 
                                     8436337035064,  9132232521765];
    uint[] public orbiSupplyList = [110000000000000000, 109009688679024191, 106234898018587335,
                                    102225209339563144,  97774790660436856,  93765101981412665,
                                     90990311320975809,  90000000000000000,  90990311320975809,
                                     93765101981412665,  97774790660436856, 102225209339563144,
                                    106234898018587335, 109009688679024191];
    
    constructor() public {
        owner = msg.sender;
        initTime = now - now % 3600 + 7200;
    }
    
    function rebaseTwins(int supplyDelta0, int supplyDelta1) external onlyOwner returns (bool) {
        twin0Contract.rebase(supplyDelta0);
        twin1Contract.rebase(supplyDelta1);
    }
    
    function rebaseOrbi(int supplyDelta) external onlyOwner returns (bool) {
        orbiContract.rebase(supplyDelta);
    }
    
    function changeOwner(address newOwner) external onlyOwner returns (bool) {
        owner = newOwner;
        return true;
    }
    
    function changeOrbiSupplyList(uint[] calldata newSupplyList) external onlyOwner returns (bool) {
        orbiSupplyList = newSupplyList;
        return true;
    }
    
    function changeTwinSupplyList(uint[] calldata newSupplyList) external onlyOwner returns (bool) {
        twinSupplyList = newSupplyList;
        return true;
    }
    
    function setTwins(address twin0Addr, address twin1Addr, address twin0LiqAddr, address twin1LiqAddr) external onlyOwner returns (bool) {
        require(twin0Address == address(0) && twin1Address == address(0), "TWINS_ALREADY_SET");
        twin0Address = twin0Addr;
        twin0Contract = RebasableContract(twin0Addr);
        twin1Address = twin1Addr;
        twin1Contract = RebasableContract(twin1Addr);
        twin0LiqAddress = twin0LiqAddr;
        twin0LiqContract = SyncableContract(twin0LiqAddr);
        twin1LiqAddress = twin1LiqAddr;
        twin1LiqContract = SyncableContract(twin1LiqAddr);
        return true;
     }  
     
    function setOrbi(address orbiAddr, address orbiLiqAddr) external onlyOwner returns (bool) {
        require(orbiAddress == address(0), "ORBI_ALREADY_SET");
        orbiAddress = orbiAddr;
        orbiContract = RebasableContract(orbiAddr);
        orbiLiqAddress = orbiLiqAddr;
        orbiLiqContract = SyncableContract(orbiLiqAddr);
        return true;
    }
    
    function rebase() external returns (bool) {
        uint twin0NewSupply = twinSupplyList[(now - initTime) / secondsPerSupplyBlock % 14];
        uint twin1NewSupply = twinSupplyList[((now - initTime) / secondsPerSupplyBlock + 7) % 14];
        uint orbiNewSupply = orbiSupplyList[(now - initTime) / secondsPerSupplyBlock % 14];
        bool twin0Synced = false;
        bool twin1Synced = false;
        require(orbiNewSupply != orbiSupplyTotal || (twin0NewSupply != twin0SupplyTotal && twin1NewSupply != twin1SupplyTotal), "SUPPLY_UNCHANGED");
        if (twin0NewSupply != twin0SupplyTotal && twin1NewSupply != twin1SupplyTotal) {
            twin0Contract.rebase(int(twin0NewSupply) - int(twin0SupplyTotal));
            if (int(twin0NewSupply) - int(twin0SupplyTotal) < 0) {
                twin0LiqContract.sync();
                twin0Synced = true;
            }
            twin1Contract.rebase(int(twin1NewSupply) - int(twin1SupplyTotal));
            if (int(twin1NewSupply) - int(twin1SupplyTotal) < 0) {
                twin1LiqContract.sync();
                twin1Synced = true;
            }
            twin0SupplyTotal = twin0NewSupply;
            twin1SupplyTotal = twin1NewSupply;
        }
        if (orbiNewSupply != orbiSupplyTotal) {
            orbiContract.rebase(int(orbiNewSupply) - int(orbiSupplyTotal));
            if (int(orbiNewSupply) - int(orbiSupplyTotal) < 0) {
                orbiLiqContract.sync();
                if (!twin0Synced) {
                    twin0LiqContract.sync();
                }
                if (!twin1Synced) {
                    twin1LiqContract.sync();
                }
            }
            orbiSupplyTotal = orbiNewSupply;
        }
        return true;
    }
    
}