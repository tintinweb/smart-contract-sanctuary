/* ==================================================================== */
/* Copyright (c) 2018 The ether.online Project.  All rights reserved.
/* 
/* https://ether.online  The first RPG game of blockchain 
/*  
/* authors rickhunter.shen@gmail.com   
/*         ssesunding@gmail.com            
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

contract AccessNoWithdraw is AccessAdmin {
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

    modifier onlyManager() { 
        require(msg.sender == addrService || msg.sender == addrAdmin || msg.sender == addrFinance);
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
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
}

interface IAgonFight {
    function calcFight(uint64 _mFlag, uint64 _cFlag, uint256 _aSeed, uint256 _fSeed) external pure returns(uint64);
}

contract ActionAgon is AccessNoWithdraw {
    using SafeMath for uint256; 

    event CreateAgon(uint64 indexed agonId, address indexed master, uint64 indexed outFlag);
    event CancelAgon(uint64 indexed agonId, address indexed master, uint64 indexed outFlag);
    event ChallengeAgon(uint64 indexed agonId, address indexed master, uint64 indexed outFlag, address challenger);
    event ResolveAgon(uint64 indexed agonId, address indexed master, uint64 indexed outFlag, address challenger);

    struct Agon {
        address master;
        address challenger;
        uint64 agonPrice;
        uint64 outFlag;
        uint64 agonFlag;    
        uint64 result;      // 1-win, 2-lose, 99-cancel
    }

    Agon[] agonArray;
    address public poolContract;
    IAgonFight fightContract;

    mapping (address => uint64[]) public ownerToAgonIdArray;
    uint256 public maxAgonCount = 6;
    uint256 public maxResolvedAgonId = 0; 
    uint256[5] public agonValues = [0.05 ether, 0.2 ether, 0.5 ether, 1 ether, 2 ether];

    function ActionAgon() public {
        addrAdmin = msg.sender;
        addrService = msg.sender;
        addrFinance = msg.sender;

        Agon memory order = Agon(0, 0, 0, 0, 1, 1);
        agonArray.push(order);
    }

    function() external {}

    function setArenaPool(address _addr) external onlyAdmin {
        require(_addr != address(0));
        poolContract = _addr;
    }

    function setMaxAgonCount(uint256 _count) external onlyAdmin {
        require(_count > 0 && _count < 20);
        require(_count != maxAgonCount);
        maxAgonCount = _count;
    }

    function setAgonFight(address _addr) external onlyAdmin {
        fightContract = IAgonFight(_addr);
    }

    function setMaxResolvedAgonId() external {
        uint256 length = agonArray.length;
        for (uint256 i = maxResolvedAgonId; i < length; ++i) {
            if (agonArray[i].result == 0) {
                maxResolvedAgonId = i - 1;
                break;
            }
        }
    }

    function setAgonValues(uint256[5] values) external onlyAdmin {
        require(values[0] >= 0.001 ether);
        require(values[1] >= values[0]);
        require(values[2] >= values[1]);
        require(values[3] >= values[2]);
        require(values[4] >= values[3]);
        require(values[4] <= 10 ether);     // 10 ether < 2^64
        require(values[0] % 1000000000 == 0);
        require(values[1] % 1000000000 == 0);
        require(values[2] % 1000000000 == 0);
        require(values[3] % 1000000000 == 0);
        require(values[4] % 1000000000 == 0);
        agonValues[0] = values[0];
        agonValues[1] = values[1];
        agonValues[2] = values[2];
        agonValues[3] = values[3];
        agonValues[4] = values[4];
    }

    function newAgon(uint64 _outFlag, uint64 _valId) external payable whenNotPaused {
        require(ownerToAgonIdArray[msg.sender].length < maxAgonCount);
        require(_valId >= 0 && _valId <= 4);
        require(msg.value == agonValues[_valId]);
        
        uint64 newAgonId = uint64(agonArray.length);
        agonArray.length += 1;
        Agon storage agon = agonArray[newAgonId];
        agon.master = msg.sender;
        agon.agonPrice = uint64(msg.value);    // 10 ether < 2^64
        agon.outFlag = _outFlag;

        ownerToAgonIdArray[msg.sender].push(newAgonId);

        CreateAgon(uint64(newAgonId), msg.sender, _outFlag);
    } 

    function _removeAgonIdByOwner(address _owner, uint64 _agonId) internal {
        uint64[] storage agonIdArray = ownerToAgonIdArray[_owner];
        uint256 length = agonIdArray.length;
        require(length > 0);
        uint256 findIndex = 99;
        for (uint256 i = 0; i < length; ++i) {
            if (_agonId == agonIdArray[i]) {
                findIndex = i;
            }
        }
        require(findIndex != 99);
        if (findIndex != (length - 1)) {
            agonIdArray[findIndex] = agonIdArray[length - 1];
        } 
        agonIdArray.length -= 1;
    }

    function cancelAgon(uint64 _agonId) external {
        require(_agonId < agonArray.length);
        Agon storage agon = agonArray[_agonId];
        require(agon.result == 0);
        require(agon.challenger == address(0));
        require(agon.master == msg.sender);

        agon.result = 99;
        _removeAgonIdByOwner(msg.sender, _agonId);
        msg.sender.transfer(agon.agonPrice);

        CancelAgon(_agonId, msg.sender, agon.outFlag);
    }

    function cancelAgonForce(uint64 _agonId) external onlyService {
        require(_agonId < agonArray.length);
        Agon storage agon = agonArray[_agonId];
        require(agon.result == 0);
        require(agon.challenger == address(0));

        agon.result = 99;
        _removeAgonIdByOwner(agon.master, _agonId);
        agon.master.transfer(agon.agonPrice);

        CancelAgon(_agonId, agon.master, agon.outFlag);
    }

    function newChallenge(uint64 _agonId, uint64 _flag) external payable whenNotPaused {
        require(_agonId < agonArray.length);
        Agon storage agon = agonArray[_agonId];
        require(agon.result == 0);
        require(agon.master != msg.sender);
        require(uint256(agon.agonPrice) == msg.value);
        require(agon.challenger == address(0));

        agon.challenger = msg.sender;
        agon.agonFlag = _flag;
        ChallengeAgon(_agonId, agon.master, agon.outFlag, msg.sender);
    }

    function fightAgon(uint64 _agonId, uint64 _mFlag, uint256 _aSeed, uint256 _fSeed) external onlyService {
        require(_agonId < agonArray.length);
        Agon storage agon = agonArray[_agonId];
        require(agon.result == 0 && agon.challenger != address(0));
        require(fightContract != address(0));
        uint64 fRet = fightContract.calcFight(_mFlag, agon.agonFlag, _aSeed, _fSeed);
        require(fRet == 1 || fRet == 2);
        agon.result = fRet;
        _removeAgonIdByOwner(agon.master, _agonId);
        uint256 devCut = uint256(agon.agonPrice).div(10);
        uint256 winVal = uint256(agon.agonPrice).mul(2).sub(devCut);
        if (fRet == 1) {
            agon.master.transfer(winVal);
        } else {
            agon.challenger.transfer(winVal);
        }
        if (poolContract != address(0)) {
            uint256 pVal = devCut.div(2);
            poolContract.transfer(pVal);
            addrFinance.transfer(devCut.sub(pVal));
        } else {
            addrFinance.transfer(devCut);
        }
        ResolveAgon(_agonId, agon.master, agon.outFlag, agon.challenger);
    }

    function getAgon(uint256 _agonId) external view
        returns(
            address master,
            address challenger,
            uint64 agonPrice,
            uint64 outFlag,
            uint64 agonFlag,
            uint64 result
        )
    {
        require(_agonId < agonArray.length);
        Agon memory agon = agonArray[_agonId];
        master = agon.master;
        challenger = agon.challenger;
        agonPrice = agon.agonPrice;
        outFlag = agon.outFlag;
        agonFlag = agon.agonFlag;
        result = agon.result;
    }

    function getAgonArray(uint64 _startAgonId, uint64 _count) external view
        returns(
            uint64[] agonIds,
            address[] masters,
            address[] challengers,
            uint64[] agonPrices,           
            uint64[] agonOutFlags,
            uint64[] agonFlags,
            uint64[] results
        ) 
    {
        uint64 length = uint64(agonArray.length);
        require(_startAgonId < length);
        require(_startAgonId > 0);
        uint256 maxLen;
        if (_count == 0) {
            maxLen = length - _startAgonId;
        } else {
            maxLen = (length - _startAgonId) >= _count ? _count : (length - _startAgonId);
        }
        agonIds = new uint64[](maxLen);
        masters = new address[](maxLen);
        challengers = new address[](maxLen);
        agonPrices = new uint64[](maxLen);
        agonOutFlags = new uint64[](maxLen);
        agonFlags = new uint64[](maxLen);
        results = new uint64[](maxLen);
        uint256 counter = 0;
        for (uint64 i = _startAgonId; i < length; ++i) {
            Agon storage tmpAgon = agonArray[i];
            agonIds[counter] = i;
            masters[counter] = tmpAgon.master;
            challengers[counter] = tmpAgon.challenger;
            agonPrices[counter] = tmpAgon.agonPrice;
            agonOutFlags[counter] = tmpAgon.outFlag;
            agonFlags[counter] = tmpAgon.agonFlag;
            results[counter] = tmpAgon.result;
            counter += 1;
            if (counter >= maxLen) {
                break;
            }
        }
    }

    function getMaxAgonId() external view returns(uint256) {
        return agonArray.length - 1;
    }

    function getAgonIdArray(address _owner) external view returns(uint64[]) {
        return ownerToAgonIdArray[_owner];
    }
}