pragma solidity 0.5.16;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

// ----------------------------------------------------------------------------------
// Holds the Airdrop Token balance on contract address
// AirdropAdmin can authorize addresses to receive airdrop.
// Users have to claim their airdrop actively or Admin initiates transfer.
// ----------------------------------------------------------------------------------

contract MorpherAirdrop is Ownable {
    using SafeMath for uint256;

// ----------------------------------------------------------------------------
// Mappings for authorized / claimed airdrop
// ----------------------------------------------------------------------------
    mapping(address => uint256) private airdropClaimed;
    mapping(address => uint256) private airdropAuthorized;

    uint256 public totalAirdropAuthorized;
    uint256 public totalAirdropClaimed;

    address public airdropAdmin;
    address public morpherToken;

// ----------------------------------------------------------------------------
// Events
// ----------------------------------------------------------------------------
    event AirdropSent(address indexed _operator, address indexed _recipient, uint256 _amountClaimed, uint256 _amountAuthorized);
    event SetAirdropAuthorized(address indexed _recipient, uint256 _amountClaimed, uint256 _amountAuthorized);

    constructor(address _airdropAdminAddress, address _morpherToken, address _coldStorageOwnerAddress) public {
        setAirdropAdmin(_airdropAdminAddress);
        setMorpherTokenAddress(_morpherToken);
        transferOwnership(_coldStorageOwnerAddress);
    }

    modifier onlyAirdropAdmin {
        require(msg.sender == airdropAdmin, "MorpherAirdrop: can only be called by Airdrop Administrator.");
        _;
    }

// ----------------------------------------------------------------------------
// Administrative functions
// ----------------------------------------------------------------------------
    function setAirdropAdmin(address _address) public onlyOwner {
        airdropAdmin = _address;
    }

    function setMorpherTokenAddress(address _address) public onlyOwner {
        morpherToken = _address;
    }

// ----------------------------------------------------------------------------
// Get airdrop amount authorized for or claimed by address
// ----------------------------------------------------------------------------
    function getAirdropClaimed(address _userAddress) public view returns (uint256 _amount) {
        return airdropClaimed[_userAddress];
    }

    function getAirdropAuthorized(address _userAddress) public view returns (uint256 _balance) {
        return airdropAuthorized[_userAddress];
    }

    function getAirdrop(address _userAddress) public view returns(uint256 _claimed, uint256 _authorized) {
        return (airdropClaimed[_userAddress], airdropAuthorized[_userAddress]);
    }

// ----------------------------------------------------------------------------
// Airdrop Administrator can authorize airdrop amount per address
// ----------------------------------------------------------------------------
    function setAirdropAuthorized(address _userAddress, uint256 _authorized) public onlyAirdropAdmin {
        // Can only set authorized amount to be higher than claimed
        require(_authorized >= airdropClaimed[_userAddress], "MorpherAirdrop: airdrop authorized must be larger than claimed.");
        // Authorized amount can be higher or lower than previously authorized amount, adjust accordingly
        totalAirdropAuthorized = totalAirdropAuthorized.sub(getAirdropAuthorized(_userAddress)).add(_authorized);
        airdropAuthorized[_userAddress] = _authorized;
        emit SetAirdropAuthorized(_userAddress, airdropClaimed[_userAddress], _authorized);
    }

// ----------------------------------------------------------------------------
// User claims their entire airdrop
// ----------------------------------------------------------------------------
    function claimAirdrop() public {
        uint256 _amount = airdropAuthorized[msg.sender].sub(airdropClaimed[msg.sender]);
        _sendAirdrop(msg.sender, _amount);
    }

// ----------------------------------------------------------------------------
// User claims part of their airdrop
// ----------------------------------------------------------------------------
    function claimSomeAirdrop(uint256 _amount) public {
        _sendAirdrop(msg.sender, _amount);
    }

// ----------------------------------------------------------------------------
// Administrator sends user their entire airdrop
// ----------------------------------------------------------------------------
    function adminSendAirdrop(address _recipient) public onlyAirdropAdmin {
        uint256 _amount = airdropAuthorized[_recipient].sub(airdropClaimed[_recipient]);
        _sendAirdrop(_recipient, _amount);
    }

// ----------------------------------------------------------------------------
// Administrator sends user part of their airdrop
// ----------------------------------------------------------------------------
    function adminSendSomeAirdrop(address _recipient, uint256 _amount) public onlyAirdropAdmin {
        _sendAirdrop(_recipient, _amount);
    }

// ----------------------------------------------------------------------------
// Administrator sends user entire airdrop
// ----------------------------------------------------------------------------
    function _sendAirdrop(address _recipient, uint256 _amount) private {
        require(airdropAuthorized[_recipient] >= airdropClaimed[_recipient].add(_amount), "MorpherAirdrop: amount exceeds authorized airdrop amount.");
        airdropClaimed[_recipient] = airdropClaimed[_recipient].add(_amount);
        totalAirdropClaimed = totalAirdropClaimed.add(_amount);
        IERC20(morpherToken).transfer(_recipient, _amount);
        emit AirdropSent(msg.sender, _recipient, airdropClaimed[_recipient], airdropAuthorized[_recipient]);
    }

// ----------------------------------------------------------------------------
// Administrator sends user part of their airdrop
// ----------------------------------------------------------------------------
    function adminAuthorizeAndSend(address _recipient, uint256 _amount) public onlyAirdropAdmin {
        setAirdropAuthorized(_recipient, getAirdropAuthorized(_recipient).add(_amount));
        _sendAirdrop(_recipient, _amount);
    }

// ------------------------------------------------------------------------
// Don't accept ETH
// ------------------------------------------------------------------------
    function () external payable {
        revert("MorpherAirdrop: you can't deposit Ether here");
    }
}