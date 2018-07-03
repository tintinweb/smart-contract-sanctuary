pragma solidity ^0.4.19;

// copyright contact@etheremon.com

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


contract EtheremonEnergy is BasicAccessControl {
    
    struct Energy {
        uint freeAmount;
        uint paidAmount;
        uint lastClaim;
    }
    
    struct EnergyPackage {
        uint ethPrice;
        uint emontPrice;
        uint energy;
    }
    
    mapping(address => Energy) energyData;
    mapping(uint => EnergyPackage) paidPackages;
    uint public claimMaxAmount = 10;
    uint public claimTime = 30 * 60; // in second
    uint public claimAmount = 1;
    
    // address
    address public paymentContract;
    
    // event
    event EventEnergyUpdate(address indexed player, uint freeAmount, uint paidAmount, uint lastClaim);
    
    modifier requirePaymentContract {
        require(paymentContract != address(0));
        _;
    }
    
    function EtheremonEnergy(address _paymentContract) public {
        paymentContract = _paymentContract;
    }
    
    // moderator
    
    function withdrawEther(address _sendTo, uint _amount) onlyModerators public {
        if (_amount > address(this).balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }
    
    function setPaidPackage(uint _packId, uint _ethPrice, uint _emontPrice, uint _energy) onlyModerators external {
        EnergyPackage storage pack = paidPackages[_packId];
        pack.ethPrice = _ethPrice;
        pack.emontPrice = _emontPrice;
        pack.energy = _energy;
    }
    
    function setConfig(address _paymentContract, uint _claimMaxAmount, uint _claimTime, uint _claimAmount) onlyModerators external {
        paymentContract = _paymentContract;
        claimMaxAmount = _claimMaxAmount;
        claimTime = _claimTime;
        claimAmount = _claimAmount;
    }
    
    function topupEnergyByToken(address _player, uint _packId, uint _token) requirePaymentContract external {
        if (msg.sender != paymentContract) revert();
        EnergyPackage storage pack = paidPackages[_packId];
        if (pack.energy == 0 || pack.emontPrice != _token)
            revert();

        Energy storage energy = energyData[_player];
        energy.paidAmount += pack.energy;
        
        EventEnergyUpdate(_player, energy.freeAmount, energy.paidAmount, energy.lastClaim);
    }
    
    // public update
    
    function safeDeduct(uint _a, uint _b) pure public returns(uint) {
        if (_a < _b) return 0;
        return (_a - _b);
    }
    
    function topupEnergy(uint _packId) isActive payable external {
        EnergyPackage storage pack = paidPackages[_packId];
        if (pack.energy == 0 || pack.ethPrice != msg.value)
            revert();

        Energy storage energy = energyData[msg.sender];
        energy.paidAmount += pack.energy;
        
        EventEnergyUpdate(msg.sender, energy.freeAmount, energy.paidAmount, energy.lastClaim);
    }
    
    function claimEnergy() isActive external {
        Energy storage energy = energyData[msg.sender];
        uint period = safeDeduct(block.timestamp, energy.lastClaim);
        uint energyAmount = (period / claimTime) * claimAmount;
        
        if (energyAmount == 0) revert();
        if (energyAmount > claimMaxAmount) energyAmount = claimMaxAmount;
        
        energy.freeAmount += energyAmount;
        energy.lastClaim = block.timestamp;
        
        EventEnergyUpdate(msg.sender, energy.freeAmount, energy.paidAmount, energy.lastClaim);
    }
    
    // public get
    function getPlayerEnergy(address _player) constant external returns(uint freeAmount, uint paidAmount, uint lastClaim) {
        Energy storage energy = energyData[_player];
        return (energy.freeAmount, energy.paidAmount, energy.lastClaim);
    }
    
    function getClaimableAmount(address _trainer) constant external returns(uint) {
        Energy storage energy = energyData[_trainer];
        uint period = safeDeduct(block.timestamp, energy.lastClaim);
        uint energyAmount = (period / claimTime) * claimAmount;
        if (energyAmount > claimMaxAmount) energyAmount = claimMaxAmount;
        return energyAmount;
    }
}