/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

/// @title Multicall - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }
    
    struct mintDetails {
        address target;
        bytes callData;
    }
    
    struct burnDetails {
        address target;
        bytes callData;
    }
    
    address public owner;
    address public minter;
    address public burner;
    address public superAdmin;
    uint public mintId;
    uint public burnId;
    address[] public minters;
    address[] public burners;
    uint[] public mintList;
    
    mapping(address => bool)public mintUsers;
    mapping(address => bool)public burnUsers;
    mapping(bytes => uint)public mintHash;
    mapping(bytes => uint)public burnHash;
    mapping(uint => bool)public mintAdmin;
    mapping(uint => bool)public mintSuperAdmin;
    mapping(uint => bool)public burnAdmin;
    mapping(uint => bool)public burnSuperAdmin;
    mapping(uint => mintDetails)public mintApprovalusers;
    mapping(uint => mintDetails)public burnApprovalusers;
    
    event mint(address indexed from,address indexed users,uint amount,address target,bytes hash,uint id);
    event burn(address indexed from,address indexed users,uint amount,address target,bytes hash,uint id);
    
    constructor (address _admin,address _superAdmin)  {
        owner = _admin;
        superAdmin = _superAdmin;
    }
    
    function mintInitaiate(address user,uint256 amount,address _target)public {
       require(msg.sender == minter || mintUsers[msg.sender] == true,"No access other to mint");
       mintId++;
       bytes memory demo = abi.encodeWithSignature("mint(address,uint256)",user, amount);
        mintHash[demo] = mintId;
        mintApprovalusers[mintId].target = _target;
        mintApprovalusers[mintId].callData = demo;
        emit mint(msg.sender,user,amount,_target,demo,mintId);
    }
    
    function adminMintApproval(uint id)public {
        require(msg.sender == owner || msg.sender == superAdmin,"No access");
           if (msg.sender == owner) {
               mintAdmin[id] = true;
           }
           if (msg.sender == superAdmin) {
               mintSuperAdmin[id] = true;
           }
           if (mintAdmin[id] == true && mintSuperAdmin[id] == true) {
           bytes memory err1;
           mintDetails[] memory err = new mintDetails[](1);
           err[0] = mintDetails(mintApprovalusers[id].target,mintApprovalusers[id].callData);
           submitMintTransaction(id,err);
           }
          
    }
    
    function burnInitaiate(address user,uint256 amount,address _target)public {
       require(msg.sender == burner || burnUsers[msg.sender] == true,"No access other to burn");
       burnId++;
       bytes memory demo = abi.encodeWithSignature("burn(address,uint256)",user, amount);
        burnHash[demo] = mintId;
        burnApprovalusers[mintId].target = _target;
        burnApprovalusers[mintId].callData = demo;
        emit burn(msg.sender,user,amount,_target,demo,burnId);

    }
    
    function adminBurnApproval(uint id)public {
        require(msg.sender == owner || msg.sender == superAdmin,"No access");
           if (msg.sender == owner) {
               burnAdmin[id] = true;
           }
           if (msg.sender == superAdmin) {
               burnSuperAdmin[id] = true;
           }
           if (burnAdmin[id] == true && burnSuperAdmin[id] == true) {
           bytes memory err1;
           burnDetails[] memory err = new burnDetails[](1);
           err[0] = burnDetails(burnApprovalusers[id].target,burnApprovalusers[id].callData);
           submitBurnTransaction(id,err);
           }
          
    }
    
    
    function submitMintTransaction(uint id,mintDetails[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        require(msg.sender == owner || msg.sender == superAdmin || mintAdmin[id] == true && mintSuperAdmin[id] == true,"no access");
      
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
       
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    
    function submitBurnTransaction(uint id,burnDetails[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
         require(msg.sender == owner || msg.sender == superAdmin || burnAdmin[id] == true && burnSuperAdmin[id] == true,"no access");
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    
    function updateAddress(address _owner,address _superadmin) public {
        require(msg.sender == owner || msg.sender == superAdmin,"No access");
        owner = _owner;
        superAdmin = _superadmin;
    }
    
     function addMinter(address[] memory _minter)public {
        require(msg.sender == owner || msg.sender == superAdmin ,"Only Owner");
        for (uint i = 0; i<_minter.length;i++){
            minters.push(_minter[i]);
            mintUsers[_minter[i]] = true;
        }
    }
    
    function addBurner(address[] memory _burner)public {
        require(msg.sender == owner || msg.sender == superAdmin,"OnlyOwner");
        for (uint i = 0; i<_burner.length;i++){
            burners.push(_burner[i]);
            burnUsers[_burner[i]] = true;
        }
    }
    
    
    // Helper functions
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}