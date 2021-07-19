//SourceUnit: trashbin.sol

pragma solidity 0.5.8;

contract TheTrashBin {
    address payable private _owner;
    
    mapping (address => bool) _isTrashPicker;
    mapping (address => bool) _isDonator;
    
    event TrashGrabbed(address _picker, uint _tokenID, uint _amount);
    event DonationMade(address _donator, uint _amount, uint _timestamp);
    
    
    modifier onlyDonators() {
        require(_isDonator[msg.sender] = true, 'YOU_HAVE_NOT_DONATED');
        _;
    }

    constructor (address payable _donationRecipient) public {_owner = _donationRecipient;}
    
    function () payable external {donate();}
    
    // If you donate some TRX to me, you can pick through my trash :P
    
    function donate() payable public returns (bool _success) {
        _isDonator[msg.sender] = true;
        
        if (msg.value > 20000000) {
            if (_isTrashPicker[msg.sender] == true) {_isTrashPicker[msg.sender] = false;}
        }
        
        emit DonationMade(msg.sender, msg.value, now);
        return true;
    }
    
    function collectRiches() public returns (bool _success) {
        _owner.transfer(address(this).balance);
        return true;
    }
    
    // Here, pick through my trash... lol
    // You must at least make a TRX donation first though - fair's fair... :)
    
    // Donate once, pick once... :)
    
    function collectTRC10(uint _tokenID, uint _amount) onlyDonators() public returns (bool _success) {
        
        _isTrashPicker[msg.sender] = true;
        msg.sender.transferToken(_tokenID, _amount);
        
        emit TrashGrabbed(msg.sender, _tokenID, _amount);
        return true;
    }
}