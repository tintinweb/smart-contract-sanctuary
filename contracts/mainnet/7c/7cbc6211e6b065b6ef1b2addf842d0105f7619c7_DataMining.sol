/* ==================================================================== */
/* Copyright (c) 2018 The ether.online Project.  All rights reserved.
/* 
/* https://ether.online  The first RPG game of blockchain 
/*  
/* authors <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2b59424840435e455f4e590558434e456b4c464a424705484446">[email&#160;protected]</a>   
/*         <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a5d6d6c0d6d0cbc1cccbc2e5c2c8c4ccc98bc6cac8">[email&#160;protected]</a>            
/* ==================================================================== */

pragma solidity ^0.4.20;

contract AccessAdmin {
    bool public isPaused = false;
    address public addrAdmin;  

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    function AccessAdmin() public {
        addrAdmin = msg.sender;
    }  

    modifier onlyAdmin() {
        require(msg.sender == addrAdmin);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused {
        require(isPaused);
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

contract AccessService is AccessAdmin {
    address public addrService;
    address public addrFinance;

    modifier onlyService() {
        require(msg.sender == addrService);
        _;
    }

    modifier onlyFinance() {
        require(msg.sender == addrFinance);
        _;
    }

    function setService(address _newService) external {
        require(msg.sender == addrService || msg.sender == addrAdmin);
        require(_newService != address(0));
        addrService = _newService;
    }

    function setFinance(address _newFinance) external {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_newFinance != address(0));
        addrFinance = _newFinance;
    }

    function withdraw(address _target, uint256 _amount) 
        external 
    {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_amount > 0);
        address receiver = _target == address(0) ? addrFinance : _target;
        uint256 balance = this.balance;
        if (_amount < balance) {
            receiver.transfer(_amount);
        } else {
            receiver.transfer(this.balance);
        }      
    }
}

interface IDataMining {
    function getRecommender(address _target) external view returns(address);
    function subFreeMineral(address _target) external returns(bool);
}

interface IDataEquip {
    function isEquiped(address _target, uint256 _tokenId) external view returns(bool);
    function isEquipedAny2(address _target, uint256 _tokenId1, uint256 _tokenId2) external view returns(bool);
    function isEquipedAny3(address _target, uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3) external view returns(bool);
}

contract DataMining is AccessService, IDataMining {
    event RecommenderChange(address indexed _target, address _recommender);
    event FreeMineralChange(address indexed _target, uint32 _accCnt);

    /// @dev Recommend relationship map
    mapping (address => address) recommendRelation;
    /// @dev Free mining count map
    mapping (address => uint32) freeMineral;
    /// @dev Trust contract
    mapping (address => bool) actionContracts;

    function DataMining() public {
        addrAdmin = msg.sender;
        addrService = msg.sender;
        addrFinance = msg.sender;
    }

    function setRecommender(address _target, address _recommender) 
        external
        onlyService
    {
        require(_target != address(0));
        recommendRelation[_target] = _recommender;
        RecommenderChange(_target, _recommender);
    }

    function setRecommenderMulti(address[] _targets, address[] _recommenders) 
        external
        onlyService
    {
        uint256 targetLength = _targets.length;
        require(targetLength <= 64);
        require(targetLength == _recommenders.length);
        address addrZero = address(0);
        for (uint256 i = 0; i < targetLength; ++i) {
            if (_targets[i] != addrZero) {
                recommendRelation[_targets[i]] = _recommenders[i];
                RecommenderChange(_targets[i], _recommenders[i]);
            }
        }
    }

    function getRecommender(address _target) external view returns(address) {
        return recommendRelation[_target];
    }

    function addFreeMineral(address _target, uint32 _cnt)  
        external
        onlyService
    {
        require(_target != address(0));
        require(_cnt <= 32);
        uint32 oldCnt = freeMineral[_target];
        freeMineral[_target] = oldCnt + _cnt;
        FreeMineralChange(_target, freeMineral[_target]);
    }

    function addFreeMineralMulti(address[] _targets, uint32[] _cnts)
        external
        onlyService
    {
        uint256 targetLength = _targets.length;
        require(targetLength <= 64);
        require(targetLength == _cnts.length);
        address addrZero = address(0);
        uint32 oldCnt;
        uint32 newCnt;
        address addr;
        for (uint256 i = 0; i < targetLength; ++i) {
            addr = _targets[i];
            if (addr != addrZero && _cnts[i] <= 32) {
                oldCnt = freeMineral[addr];
                newCnt = oldCnt + _cnts[i];
                assert(oldCnt < newCnt);
                freeMineral[addr] = newCnt;
                FreeMineralChange(addr, freeMineral[addr]);
            }
        }
    }

    function setActionContract(address _actionAddr, bool _useful) external onlyAdmin {
        actionContracts[_actionAddr] = _useful;
    }

    function getActionContract(address _actionAddr) external view onlyAdmin returns(bool) {
        return actionContracts[_actionAddr];
    }

    function subFreeMineral(address _target) external returns(bool) {
        require(actionContracts[msg.sender]);
        require(_target != address(0));
        uint32 cnts = freeMineral[_target];
        assert(cnts > 0);
        freeMineral[_target] = cnts - 1;
        FreeMineralChange(_target, cnts - 1);
        return true;
    }

    function getFreeMineral(address _target) external view returns(uint32) {
        return freeMineral[_target];
    }
}