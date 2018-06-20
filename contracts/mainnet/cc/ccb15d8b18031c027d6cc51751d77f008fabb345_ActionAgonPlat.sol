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

interface IBitGuildToken {
    function transfer(address _to, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external; 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) external returns (bool);
    function balanceOf(address _from) external view returns(uint256);
}

interface IAgonFight {
    function calcFight(uint64 _mFlag, uint64 _cFlag, uint256 _aSeed, uint256 _fSeed) external pure returns(uint64);
}

contract ActionAgonPlat is AccessService {
    using SafeMath for uint256; 

    event CreateAgonPlat(uint64 indexed agonId, address indexed master, uint64 indexed outFlag);
    event CancelAgonPlat(uint64 indexed agonId, address indexed master, uint64 indexed outFlag);
    event ChallengeAgonPlat(uint64 indexed agonId, address indexed master, uint64 indexed outFlag, address challenger);
    event ResolveAgonPlat(uint64 indexed agonId, address indexed master, uint64 indexed outFlag, address challenger);

    struct Agon {
        address master;
        address challenger;
        uint64 agonPrice;
        uint64 outFlag;
        uint64 agonFlag;    
        uint64 result;      // 1-win, 2-lose, 99-cancel
    }

    Agon[] agonArray;
    IAgonFight fightContract;
    IBitGuildToken public bitGuildContract;

    mapping (address => uint64[]) public ownerToAgonIdArray;
    uint256 public maxAgonCount = 6;
    uint256 public maxResolvedAgonId = 0; 
    uint256[5] public agonValues;

    function ActionAgonPlat(address _platAddr) public {
        addrAdmin = msg.sender;
        addrService = msg.sender;
        addrFinance = msg.sender;

        bitGuildContract = IBitGuildToken(_platAddr);

        Agon memory order = Agon(0, 0, 0, 0, 1, 1);
        agonArray.push(order);
        agonValues[0] = 3000000000000000000000;
        agonValues[1] = 12000000000000000000000;
        agonValues[2] = 30000000000000000000000;
        agonValues[3] = 60000000000000000000000;
        agonValues[4] = 120000000000000000000000;
    }

    function() external {}

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
        require(values[0] >= 100);
        require(values[1] >= values[0]);
        require(values[2] >= values[1]);
        require(values[3] >= values[2]);
        require(values[4] >= values[3]);
        require(values[4] <= 600000); 
        require(values[0] % 100 == 0);
        require(values[1] % 100 == 0);
        require(values[2] % 100 == 0);
        require(values[3] % 100 == 0);
        require(values[4] % 100 == 0);
        agonValues[0] = values[0].mul(1000000000000000000);
        agonValues[1] = values[1].mul(1000000000000000000);
        agonValues[2] = values[2].mul(1000000000000000000);
        agonValues[3] = values[3].mul(1000000000000000000);
        agonValues[4] = values[4].mul(1000000000000000000);
    }

    function _getExtraParam(bytes _extraData) internal pure returns(uint64 p1, uint64 p2, uint64 p3) {
        p1 = uint64(_extraData[0]);
        p2 = uint64(_extraData[1]);
        uint64 index = 2;
        uint256 val = 0;
        uint256 length = _extraData.length;
        while (index < length) {
            val += (uint256(_extraData[index]) * (256 ** (length - index - 1)));
            index += 1;
        }
        p3 = uint64(val);
    }

    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes _extraData) 
        external 
        whenNotPaused 
    {
        require(msg.sender == address(bitGuildContract));
        require(_extraData.length > 2 && _extraData.length <= 10);
        var (p1, p2, p3) = _getExtraParam(_extraData);
        if (p1 == 0) {
            _newAgon(p3, p2, _sender, _value);
        } else if (p1 == 1) {
            _newChallenge(p3, p2, _sender, _value);
        } else {
            require(false);
        }
    }

    function _newAgon(uint64 _outFlag, uint64 _valId, address _sender, uint256 _value) internal {
        require(ownerToAgonIdArray[_sender].length < maxAgonCount);
        require(_valId >= 0 && _valId <= 4);
        require(_value == agonValues[_valId]);
        
        require(bitGuildContract.transferFrom(_sender, address(this), _value));

        uint64 newAgonId = uint64(agonArray.length);
        agonArray.length += 1;
        Agon storage agon = agonArray[newAgonId];
        agon.master = _sender;
        agon.agonPrice = uint64(_value.div(1000000000000000000)); 
        agon.outFlag = _outFlag;

        ownerToAgonIdArray[_sender].push(newAgonId);

        CreateAgonPlat(uint64(newAgonId), _sender, _outFlag);
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
        bitGuildContract.transfer(msg.sender, uint256(agon.agonPrice).mul(1000000000000000000));

        CancelAgonPlat(_agonId, msg.sender, agon.outFlag);
    }

    function cancelAgonForce(uint64 _agonId) external onlyService {
        require(_agonId < agonArray.length);
        Agon storage agon = agonArray[_agonId];
        require(agon.result == 0);
        require(agon.challenger == address(0));

        agon.result = 99;
        _removeAgonIdByOwner(agon.master, _agonId);
        bitGuildContract.transfer(agon.master, uint256(agon.agonPrice).mul(1000000000000000000));

        CancelAgonPlat(_agonId, agon.master, agon.outFlag);
    }

    function _newChallenge(uint64 _agonId, uint64 _flag, address _sender, uint256 _value) internal {
        require(_agonId < agonArray.length);
        Agon storage agon = agonArray[_agonId];
        require(agon.result == 0);
        require(agon.master != _sender);
        require(uint256(agon.agonPrice).mul(1000000000000000000) == _value);
        require(agon.challenger == address(0));

        require(bitGuildContract.transferFrom(_sender, address(this), _value));

        agon.challenger = _sender;
        agon.agonFlag = _flag;
        ChallengeAgonPlat(_agonId, agon.master, agon.outFlag, _sender);
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
            bitGuildContract.transfer(agon.master, winVal.mul(1000000000000000000));
        } else {
            bitGuildContract.transfer(agon.challenger, winVal.mul(1000000000000000000));
        }

        ResolveAgonPlat(_agonId, agon.master, agon.outFlag, agon.challenger);
    }

    function getPlatBalance() external view returns(uint256) {
        return bitGuildContract.balanceOf(this);
    }

    function withdrawPlat() external {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        uint256 balance = bitGuildContract.balanceOf(this);
        require(balance > 0);
        bitGuildContract.transfer(addrFinance, balance);
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