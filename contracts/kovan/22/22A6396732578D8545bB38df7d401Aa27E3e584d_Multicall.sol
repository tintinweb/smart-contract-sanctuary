/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;


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
    
    struct AddMint {
        bool status;
    }
    
    struct AddBurn {
        bool status;
    }
    
    struct openmint {
        bool status;
        bytes callData;
        address target;
        bool approveStatus;
    }
    
    struct openburn {
        address target;
        bool status;
        bytes callData;
        bool approveStatus;
    }
    
    address public owner;
    address public minter;
    address public burner;
    address public superAdmin;
    uint public mintId;
    uint public burnId;
    address[] public minters;
    address[] public burners;
    
    mapping(address => bool)public mintUsers;
    mapping(address => bool)public burnUsers;
    mapping(bytes => uint)public mintHash;
    mapping(bytes => uint)public burnHash;
    mapping(uint => bool)public mintAdmin;
    mapping(uint => bool)public mintSuperAdmin;
    mapping(uint => bool)public burnAdmin;
    mapping(uint => bool)public burnSuperAdmin;
    mapping(uint => mintDetails)public mintApprovalusers;
    mapping(uint => burnDetails)public burnApprovalusers;
    mapping(address => AddMint)public mintStatus;
    mapping(address => AddBurn)public burnStatus;
    mapping(address => openmint)public openMintApproval;
    mapping(address => openburn)public openBurnApproval;
    
    
    event mint(address indexed from,address indexed users,uint amount,address target,bytes hash,uint id);
    event burn(address indexed from,address indexed users,uint amount,address target,bytes hash,uint id);
    event MinterInitiate(address indexed from,address[] minters,uint time);
    event Minters(address indexed from,address[] mintusers,uint time);
    event Burners(address indexed from,address[] burnusers,uint time);
    event MintersApproval(address indexed from,address[] mintusers,uint time);
    event BurnersApproval(address indexed from,address[] mintusers,uint time);
    event OpenMintInitiate(address indexed from,address User,uint256 Amount,address Target,uint time);
    event OpenBurnInitiate(address indexed from,address User,uint256 Amount,address Target,uint time);
    event OpenMintApproval(address indexed from,address Target,bytes _data,uint time);
    event OpenBurnApproval(address indexed from,address Target,bytes _data,uint time);
    
    constructor (address _admin,address _superAdmin)  {
        owner = _admin;
        superAdmin = _superAdmin;
    }
    
     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == superAdmin,"No access");
        _;
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
    
    function adminMintApproval(uint id) public onlyOwner {
           if (msg.sender == owner) {
               require(mintAdmin[id] == false,"Already approved");
               mintAdmin[id] = true;
           }
           if (msg.sender == superAdmin) {
               require(mintSuperAdmin[id] == false,"Already approved");
               mintSuperAdmin[id] = true;
           }
           if (mintAdmin[id] == true && mintSuperAdmin[id] == true) {
           mintDetails[] memory err = new mintDetails[](1);
           err[0] = mintDetails(mintApprovalusers[id].target,mintApprovalusers[id].callData);
           submitMintTransaction(2,id,err);
           }
    }
    
    function burnInitaiate(address user,uint256 amount,address _target)public {
       require(msg.sender == burner || burnUsers[msg.sender] == true,"No access other to burn");
       burnId++;
       bytes memory demo = abi.encodeWithSignature("burn(address,uint256)",user, amount);
        burnHash[demo] = burnId;
        burnApprovalusers[burnId].target = _target;
        burnApprovalusers[burnId].callData = demo;
        emit burn(msg.sender,user,amount,_target,demo,burnId);

    }
    
    function adminBurnApproval(uint id)public onlyOwner {
           if (msg.sender == owner) {
               require(burnAdmin[id] == false,"Already approved");
               burnAdmin[id] = true;
           }
           if (msg.sender == superAdmin) {
               require(burnSuperAdmin[id] == false,"Already approved");
               burnSuperAdmin[id] = true;
           }
           if (burnAdmin[id] == true && burnSuperAdmin[id] == true) {
           burnDetails[] memory err = new burnDetails[](2);
           err[0] = burnDetails(burnApprovalusers[id].target,burnApprovalusers[id].callData);
           submitBurnTransaction(2,id,err);
           }
    }
    
    function openMint(address user,uint256 amount,address _target) public onlyOwner{
         require(openMintApproval[owner].status == false || openMintApproval[superAdmin].status == false,"Already initiate");
         bytes memory demo = abi.encodeWithSignature("mint(address,uint256)",user, amount);
         openMintApproval[msg.sender].callData = demo;
         openMintApproval[msg.sender].status = true;
         openMintApproval[msg.sender].target = _target;
         emit OpenMintInitiate(msg.sender,user,amount,_target,block.timestamp);
    }
    
    function openMintApprove() public onlyOwner {
        require(openMintApproval[owner].status == true || openMintApproval[superAdmin].status == true,"Not initiated");
        address _target;
        bytes memory _data;
        if (openMintApproval[owner].status == true) {
            require(msg.sender == superAdmin,"Superadmin only wants to approve");
            _target = openMintApproval[owner].target;
            _data = openMintApproval[owner].callData;
            delete openMintApproval[owner].target;
            delete openMintApproval[owner].callData;
        }
        else {
            require(msg.sender == owner,"Superadmin only wants to approve");
            _target = openMintApproval[superAdmin].target;
            _data = openMintApproval[superAdmin].callData;
             delete openMintApproval[superAdmin].target;
             delete openMintApproval[superAdmin].callData;
        }
        openMintApproval[msg.sender].approveStatus = true;
        mintDetails[] memory _mint = new mintDetails[](1);
        _mint[0] = mintDetails(_target,_data);
        submitMintTransaction(1,0,_mint);
        emit OpenMintApproval(msg.sender,_target,_data,block.timestamp);
        
     }
     
      function openBurn(address user,uint256 amount,address _target) public onlyOwner{
         require(openBurnApproval[owner].status == false || openBurnApproval[superAdmin].status == false,"Already initiate");
         bytes memory demo = abi.encodeWithSignature("burn(address,uint256)",user, amount);
         openBurnApproval[msg.sender].callData = demo;
         openBurnApproval[msg.sender].status = true;
         openBurnApproval[msg.sender].target = _target;
         emit OpenBurnInitiate(msg.sender,user,amount,_target,block.timestamp);
    }
    
    function openBurnApprove() public onlyOwner {
        require(openBurnApproval[owner].status == true || openBurnApproval[superAdmin].status == true,"Not initiated");
        address _target;
        bytes memory _data;
        if (openBurnApproval[owner].status == true) {
            require(msg.sender == superAdmin,"Superadmin only wants to approve");
            _target = openBurnApproval[owner].target;
            _data = openBurnApproval[owner].callData;
            delete openBurnApproval[owner].target;
            delete openBurnApproval[owner].callData;
        }
        else {
            require(msg.sender == owner,"Superadmin only wants to approve");
            _target = openBurnApproval[superAdmin].target;
            _data = openBurnApproval[superAdmin].callData;
             delete openBurnApproval[superAdmin].target;
             delete openBurnApproval[superAdmin].callData;
        }
        openBurnApproval[msg.sender].approveStatus = true;
        burnDetails[] memory _mint = new burnDetails[](1);
        _mint[0] = burnDetails(_target,_data);
        submitBurnTransaction(1,0,_mint);
         emit OpenBurnApproval(msg.sender,_target,_data,block.timestamp);
     }
     
    function submitMintTransaction(uint8 _flag,uint id,mintDetails[] memory calls) internal returns (uint256 blockNumber, bytes[] memory returnData) {
        if (_flag == 1) {
        if (msg.sender == owner || msg.sender == superAdmin) {
            require(openMintApproval[msg.sender].approveStatus == true);
            openMintApproval[msg.sender].approveStatus = false;
        }
        }
        else if (_flag == 2) {
            require(mintAdmin[id] == true && mintSuperAdmin[id] == true,"no access");
        }
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
       
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    
    function submitBurnTransaction(uint8 _flag,uint id,burnDetails[] memory calls) internal returns (uint256 blockNumber, bytes[] memory returnData) {
        if (_flag == 1) {
        if (msg.sender == owner || msg.sender == superAdmin) {
            require(openBurnApproval[msg.sender].approveStatus == true);
            openBurnApproval[msg.sender].approveStatus = false;
        }
        }
        else if (_flag == 2) {
            require(burnAdmin[id] == true && burnSuperAdmin[id] == true,"no access");
        }
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    
    function updateAddress(address _owner,address _superadmin) public onlyOwner{
        owner = _owner;
        superAdmin = _superadmin;
    }
    
     function addMinter(address[] memory _minter)public onlyOwner {
        require(mintStatus[owner].status == false && mintStatus[superAdmin].status == false,"Previous initiate not approved");
        for (uint i = 0; i<_minter.length;i++){
            minters.push(_minter[i]);
        }
        mintStatus[msg.sender].status = true;
        emit Minters(msg.sender,_minter,block.timestamp);
    }
    
    function mintApprove(address[] memory _minter) public onlyOwner{
        require(mintStatus[owner].status == true || mintStatus[superAdmin].status == true,"Minters not initiate");
        if (mintStatus[owner].status == true) {
            require(msg.sender == superAdmin,"only super admin will approve");
             mintStatus[owner].status = false;
        }
        else if (mintStatus[superAdmin].status == true){
            require(msg.sender == owner,"only owner will approve");
            mintStatus[superAdmin].status = false;
        }
        for (uint i = 0; i < _minter.length;i++) {
            mintUsers[_minter[i]] = true;
            }
        emit MintersApproval(msg.sender,_minter,block.timestamp);
    }
    
    function addBurner(address[] memory _burner)public onlyOwner{
        require(burnStatus[owner].status == false && burnStatus[superAdmin].status == false,"Previous initiate not approved");
        for (uint i = 0; i<_burner.length;i++){
            burners.push(_burner[i]);
        }
        burnStatus[msg.sender].status = true;
        emit Burners(msg.sender,_burner,block.timestamp);
    }
    
    function burnApprove(address[] memory _burner) public onlyOwner {
        require(burnStatus[owner].status == true || burnStatus[superAdmin].status == true,"Minters not initiate");
        if (burnStatus[owner].status == true) {
            require(msg.sender == superAdmin,"only super admin will approve");
             burnStatus[owner].status = false;
        }
        else if (burnStatus[superAdmin].status == true){
            require(msg.sender == owner,"only owner will approve");
            burnStatus[superAdmin].status = false;
        }
        for (uint i = 0; i < _burner.length;i++) {
            burnUsers[_burner[i]] = true;
            }
        emit BurnersApproval(msg.sender,_burner,block.timestamp);
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