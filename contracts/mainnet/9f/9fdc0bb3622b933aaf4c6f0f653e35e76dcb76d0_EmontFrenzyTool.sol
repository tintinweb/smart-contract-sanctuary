pragma solidity ^0.4.19;

// copyright contact@emontalliance.com

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

contract EmontFrenzyInterface {
     function addBonus(uint _pos, uint _amount) external;
}


contract EmontFrenzyTool is BasicAccessControl {
    
    // address
    address public frenzyContract;
    
    function EmontFrenzyTool(address _frenzyContract) public {
        frenzyContract = _frenzyContract;
    }
    
    function updateContract(address _frenzyContract) onlyModerators external {
        frenzyContract = _frenzyContract;
    }
    
    function addBonus(uint _pos1, uint _pos2, uint _pos3, uint _pos4, uint _pos5, 
        uint _pos6, uint _pos7, uint _pos8, uint _pos9, uint _pos10, uint _amount) onlyModerators external {
            
        EmontFrenzyInterface frenzy = EmontFrenzyInterface(frenzyContract);
        
        if (_pos1 > 0) {
            frenzy.addBonus(_pos1, _amount);
        }
        if (_pos2 > 0) {
            frenzy.addBonus(_pos2, _amount);
        }
        if (_pos3 > 0) {
            frenzy.addBonus(_pos3, _amount);
        }
        if (_pos4 > 0) {
            frenzy.addBonus(_pos4, _amount);
        }
        if (_pos5 > 0) {
            frenzy.addBonus(_pos5, _amount);
        }
        if (_pos6 > 0) {
            frenzy.addBonus(_pos6, _amount);
        }
        if (_pos7 > 0) {
            frenzy.addBonus(_pos7, _amount);
        }
        if (_pos8 > 0) {
            frenzy.addBonus(_pos8, _amount);
        }
        if (_pos9 > 0) {
            frenzy.addBonus(_pos9, _amount);
        }
        if (_pos10 > 0) {
            frenzy.addBonus(_pos10, _amount);
        }
    }
}