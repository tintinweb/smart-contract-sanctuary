pragma solidity ^0.4.23;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/NetworkSettings.sol

// solhint-disable-line



/// @title Atonomi Network Settings
/// @notice This contract controls all owner configurable variables in the network
contract NetworkSettings is Ownable {
    /// @title Registration Fee
    /// @notice Manufacturer pays token to register a device
    /// @notice Manufacturer will recieve a share in any reputation updates for a device
    uint256 public registrationFee;

    /// @title Activiation Fee
    /// @notice Manufacturer or Device Owner pays token to activate device
    uint256 public activationFee;

    /// @title Default Reputation Reward
    /// @notice The default reputation reward set for new manufacturers
    uint256 public defaultReputationReward;

    /// @title Reputation Share for IRN Nodes
    /// @notice percentage that the irn node or auditor receives (remaining goes to manufacturer)
    uint256 public reputationIRNNodeShare;

    /// @title Block threshold
    /// @notice the number of blocks that need to pass between reputation updates to gain the full reward
    uint256 public blockThreshold;

    /// @notice emitted everytime the registration fee changes
    /// @param _sender ethereum account of participant that made the change
    /// @param _amount new fee value in ATMI tokens
    event RegistrationFeeUpdated(
        address indexed _sender,
        uint256 _amount
    );

    /// @notice emitted everytime the activation fee changes
    /// @param _sender ethereum account of participant that made the change
    /// @param _amount new fee value in ATMI tokens
    event ActivationFeeUpdated(
        address indexed _sender,
        uint256 _amount
    );

    /// @notice emitted everytime the default reputation reward changes
    /// @param _sender ethereum account of participant that made the change
    /// @param _amount new fee value in ATMI tokens
    event DefaultReputationRewardUpdated(
        address indexed _sender,
        uint256 _amount
    );

    /// @notice emitted everytime owner changes the contributation share for reputation authors
    /// @param _sender ethereum account of participant that made the change
    /// @param _percentage new percentage value
    event ReputationIRNNodeShareUpdated(
        address indexed _sender,
        uint256 _percentage
    );

    /// @notice emitted everytime the block threshold is changed
    /// @param _sender ethereum account who made the change
    /// @param _newBlockThreshold new value for all token pools
    event RewardBlockThresholdChanged(
        address indexed _sender,
        uint256 _newBlockThreshold
    );

    /// @notice Constructor for Atonomi Reputation contract
    /// @param _registrationFee initial registration fee on the network
    /// @param _activationFee initial activation fee on the network
    /// @param _defaultReputationReward initial reputation reward on the network
    /// @param _reputationIRNNodeShare share that the reputation author recieves (remaining goes to manufacturer)
    /// @param _blockThreshold the number of blocks that need to pass to receive the full reward
    constructor(
        uint256 _registrationFee,
        uint256 _activationFee,
        uint256 _defaultReputationReward,
        uint256 _reputationIRNNodeShare,
        uint256 _blockThreshold) public {
        require(_activationFee > 0, "activation fee must be greater than 0");
        require(_registrationFee > 0, "registration fee must be greater than 0");
        require(_defaultReputationReward > 0, "default reputation reward must be greater than 0");
        require(_reputationIRNNodeShare > 0, "new share must be larger than zero");
        require(_reputationIRNNodeShare < 100, "new share must be less than 100");

        activationFee = _activationFee;
        registrationFee = _registrationFee;
        defaultReputationReward = _defaultReputationReward;
        reputationIRNNodeShare = _reputationIRNNodeShare;
        blockThreshold = _blockThreshold;
    }

    /// @notice sets the global registration fee
    /// @param _registrationFee new fee for registrations in ATMI tokens
    /// @return true if successful, otherwise false
    function setRegistrationFee(uint256 _registrationFee) public onlyOwner returns (bool) {
        require(_registrationFee > 0, "new registration fee must be greater than zero");
        require(_registrationFee != registrationFee, "new registration fee must be different");
        registrationFee = _registrationFee;
        emit RegistrationFeeUpdated(msg.sender, _registrationFee);
        return true;
    }

    /// @notice sets the global activation fee
    /// @param _activationFee new fee for activations in ATMI tokens
    /// @return true if successful, otherwise false
    function setActivationFee(uint256 _activationFee) public onlyOwner returns (bool) {
        require(_activationFee > 0, "new activation fee must be greater than zero");
        require(_activationFee != activationFee, "new activation fee must be different");
        activationFee = _activationFee;
        emit ActivationFeeUpdated(msg.sender, _activationFee);
        return true;
    }

    /// @notice sets the default reputation reward for new manufacturers
    /// @param _defaultReputationReward new reward for reputation score changes in ATMI tokens
    /// @return true if successful, otherwise false
    function setDefaultReputationReward(uint256 _defaultReputationReward) public onlyOwner returns (bool) {
        require(_defaultReputationReward > 0, "new reputation reward must be greater than zero");
        require(_defaultReputationReward != defaultReputationReward, "new reputation reward must be different");
        defaultReputationReward = _defaultReputationReward;
        emit DefaultReputationRewardUpdated(msg.sender, _defaultReputationReward);
        return true;
    }

    /// @notice sets the global reputation reward share allotted to the authors and manufacturers
    /// @param _reputationIRNNodeShare new percentage of the reputation reward allotted to author
    /// @return true if successful, otherwise false
    function setReputationIRNNodeShare(uint256 _reputationIRNNodeShare) public onlyOwner returns (bool) {
        require(_reputationIRNNodeShare > 0, "new share must be larger than zero");
        require(_reputationIRNNodeShare < 100, "new share must be less than to 100");
        require(reputationIRNNodeShare != _reputationIRNNodeShare, "new share must be different");
        reputationIRNNodeShare = _reputationIRNNodeShare;
        emit ReputationIRNNodeShareUpdated(msg.sender, _reputationIRNNodeShare);
        return true;
    }

    /// @notice sets the global block threshold for rewards
    /// @param _newBlockThreshold new value for all token pools
    /// @return true if successful, otherwise false
    function setRewardBlockThreshold(uint _newBlockThreshold) public onlyOwner returns (bool) {
        require(_newBlockThreshold != blockThreshold, "must be different");
        blockThreshold = _newBlockThreshold;
        emit RewardBlockThresholdChanged(msg.sender, _newBlockThreshold);
        return true;
    }
}