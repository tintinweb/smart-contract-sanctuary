pragma solidity ^0.4.16;

// copyright <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2e4d41405a4f4d5a6e6b5a464b5c4b434140004d4143">[email&#160;protected]</a>

contract BasicAccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    function BasicAccessControl() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}

contract EtheremonTransformSetting is BasicAccessControl {
    
    uint32[] public randomClassIds = [32, 97, 80, 73, 79, 81, 101, 103, 105];
    mapping(uint32 => uint8) public layingEggLevels;
    mapping(uint32 => uint8) public layingEggDeductions;
    mapping(uint32 => uint8) public transformLevels;
    mapping(uint32 => uint32) public transformClasses;
    
    function setConfigClass(uint32 _classId, uint8 _layingLevel, uint8 _layingCost, uint8 _transformLevel, uint32 _tranformClass) onlyModerators public {
        layingEggLevels[_classId] = _layingLevel;
        layingEggDeductions[_classId] = _layingCost;
        transformLevels[_classId] = _transformLevel;
        transformClasses[_classId] = _tranformClass;
    }
    
    function addRandomClass(uint32 _newClassId) onlyModerators public {
        if (_newClassId > 0) {
            for (uint index = 0; index < randomClassIds.length; index++) {
                if (randomClassIds[index] == _newClassId) {
                    return;
                }
            }
            randomClassIds.push(_newClassId);
        }
    }
    
    function removeRandomClass(uint32 _oldClassId) onlyModerators public {
        uint foundIndex = 0;
        for (; foundIndex < randomClassIds.length; foundIndex++) {
            if (randomClassIds[foundIndex] == _oldClassId) {
                break;
            }
        }
        if (foundIndex < randomClassIds.length) {
            randomClassIds[foundIndex] = randomClassIds[randomClassIds.length-1];
            delete randomClassIds[randomClassIds.length-1];
            randomClassIds.length--;
        }
    }
    
    function initMonsterClassConfig() onlyModerators external {
        setConfigClass(1, 0, 0, 20, 38);
        setConfigClass(2, 0, 0, 20, 39);
        setConfigClass(3, 0, 0, 26, 40);
        setConfigClass(4, 0, 0, 20, 41);
        setConfigClass(5, 0, 0, 20, 42);
        setConfigClass(6, 0, 0, 25, 43);
        setConfigClass(7, 0, 0, 28, 44);
        setConfigClass(8, 0, 0, 25, 45);
        setConfigClass(9, 0, 0, 27, 46);
        setConfigClass(10, 0, 0, 29, 47);
        setConfigClass(11, 0, 0, 25, 48);
        setConfigClass(12, 0, 0, 26, 49);
        setConfigClass(18, 0, 0, 28, 50);
        setConfigClass(20, 0, 0, 20, 51);
        setConfigClass(24, 0, 0, 39, 89);
        setConfigClass(25, 0, 0, 20, 52);
        setConfigClass(26, 0, 0, 21, 53);
        setConfigClass(27, 0, 0, 28, 54);
        
        setConfigClass(28, 35, 5, 28, 55);
        setConfigClass(29, 35, 5, 27, 56);
        setConfigClass(30, 35, 5, 28, 57);
        setConfigClass(31, 34, 5, 27, 58);
        setConfigClass(32, 34, 5, 27, 59);
        setConfigClass(33, 33, 5, 28, 60);
        setConfigClass(34, 31, 5, 21, 61);
        
        setConfigClass(37, 34, 5, 26, 62);
        setConfigClass(38, 0, 0, 40, 64);
        setConfigClass(39, 0, 0, 40, 65);
        setConfigClass(41, 0, 0, 39, 66);
        setConfigClass(42, 0, 0, 42, 67);
        setConfigClass(51, 0, 0, 37, 68);
        setConfigClass(52, 0, 0, 39, 69);
        setConfigClass(53, 0, 0, 38, 70);
        setConfigClass(61, 0, 0, 39, 71);
        setConfigClass(62, 0, 0, 5, 63);
        
        setConfigClass(77, 36, 5, 32, 82);
        setConfigClass(78, 35, 5, 30, 83);
        setConfigClass(79, 32, 5, 23, 84);
        setConfigClass(80, 35, 5, 29, 85);
        setConfigClass(81, 34, 5, 24, 86);
        setConfigClass(84, 0, 0, 38, 87);
        
        setConfigClass(86, 0, 0, 41, 88);
        setConfigClass(89, 0, 0, 42, 158);
        setConfigClass(90, 0, 0, 28, 91);
        setConfigClass(91, 0, 0, 38, 92);
        setConfigClass(93, 0, 0, 28, 94);
        setConfigClass(94, 0, 0, 38, 95);
        
        setConfigClass(97, 35, 5, 32, 98);
        setConfigClass(99, 34, 5, 30, 100);
        setConfigClass(101, 36, 5, 31, 102);
        setConfigClass(103, 39, 7, 30, 104);
        setConfigClass(106, 34, 5, 31, 107);
        setConfigClass(107, 0, 0, 43, 108);
        
        setConfigClass(116, 0, 0, 27, 117);
        setConfigClass(117, 0, 0, 37, 118);
        setConfigClass(119, 0, 0, 28, 120);
        setConfigClass(120, 0, 0, 37, 121);
        setConfigClass(122, 0, 0, 29, 123);
        setConfigClass(123, 0, 0, 36, 124);
        setConfigClass(125, 0, 0, 26, 126);
        setConfigClass(126, 0, 0, 37, 127);
        setConfigClass(128, 0, 0, 26, 129);
        setConfigClass(129, 0, 0, 38, 130);
        setConfigClass(131, 0, 0, 27, 132);
        setConfigClass(132, 0, 0, 37, 133);
        setConfigClass(134, 0, 0, 35, 135);
        setConfigClass(136, 0, 0, 36, 137);
        setConfigClass(138, 0, 0, 36, 139);
        setConfigClass(140, 0, 0, 35, 141);
        setConfigClass(142, 0, 0, 36, 143);
        setConfigClass(144, 0, 0, 34, 145);
        setConfigClass(146, 0, 0, 36, 147);
        setConfigClass(148, 0, 0, 26, 149);
        setConfigClass(149, 0, 0, 37, 150);
        
        setConfigClass(151, 0, 0, 36, 152);
        setConfigClass(156, 0, 0, 38, 157);
    }
    
    // read access
    
    function getRandomClassId(uint _seed) constant external returns(uint32) {
        return randomClassIds[_seed % randomClassIds.length];
    }
    
    function getLayEggInfo(uint32 _classId) constant external returns(uint8 layingLevel, uint8 layingCost) {
        layingLevel = layingEggLevels[_classId];
        layingCost = layingEggDeductions[_classId];
    }
    
    function getTransformInfo(uint32 _classId) constant external returns(uint32 transformClassId, uint8 level) {
        transformClassId = transformClasses[_classId];
        level = transformLevels[_classId];
    }
    
    function getClassTransformInfo(uint32 _classId) constant external returns(uint8 layingLevel, uint8 layingCost, uint8 transformLevel, uint32 transformCLassId) {
        layingLevel = layingEggLevels[_classId];
        layingCost = layingEggDeductions[_classId];
        transformLevel = transformLevels[_classId];
        transformCLassId = transformClasses[_classId];
    }
}