pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


/**
 * @title KYC contract interface
 */
contract KYC {
    
    /**
     * Get KYC expiration timestamp in second.
     *
     * @param _who Account address
     * @return KYC expiration timestamp in second
     */
    function expireOf(address _who) external view returns (uint256);

    /**
     * Get KYC level.
     * Level is ranging from 0 (lowest, no KYC) to 255 (highest, toughest).
     *
     * @param _who Account address
     * @return KYC level
     */
    function kycLevelOf(address _who) external view returns (uint8);

    /**
     * Get encoded nationalities (country list).
     * The uint256 is represented by 256 bits (0 or 1).
     * Every bit can represent a country.
     * For each listed country, set the corresponding bit to 1.
     * To do so, up to 256 countries can be encoded in an uint256 variable.
     * Further, if country blacklist of an ICO was encoded by the same way,
     * it is able to use bitwise AND to check whether the investor can invest
     * the ICO by the crowdsale.
     *
     * @param _who Account address
     * @return Encoded nationalities
     */
    function nationalitiesOf(address _who) external view returns (uint256);

    /**
     * Set KYC status to specific account address.
     *
     * @param _who Account address
     * @param _expiresAt Expire timestamp in seconds
     * @param _level KYC level
     * @param _nationalities Encoded nationalities
     */
    function setKYC(
        address _who, uint256 _expiresAt, uint8 _level, uint256 _nationalities) 
        external;

    event KYCSet (
        address indexed _setter,
        address indexed _who,
        uint256 _expiresAt,
        uint8 _level,
        uint256 _nationalities
    );
}


/**
 * @title Fusions KYC contract
 */
contract FusionsKYC is KYC, Ownable {

    struct KYCStatus {
        uint256 expires;
        uint8 kycLevel;
        uint256 nationalities;
    }

    mapping(address => KYCStatus) public kycStatuses;

    function expireOf(address _who) 
        external view returns (uint256)
    {
        return kycStatuses[_who].expires;
    }

    function kycLevelOf(address _who)
        external view returns (uint8)
    {
        return kycStatuses[_who].kycLevel;
    }

    function nationalitiesOf(address _who) 
        external view returns (uint256)
    {
        return kycStatuses[_who].nationalities;
    }    
    
    function setKYC(
        address _who, 
        uint256 _expiresAt,
        uint8 _level,
        uint256 _nationalities
    )
        external
        onlyOwner
    {
        require(
            _who != address(0),
            "Failed to set expiration due to address is 0x0."
        );

        emit KYCSet(
            msg.sender,
            _who,
            _expiresAt,
            _level,
            _nationalities
        );

        kycStatuses[_who].expires = _expiresAt;
        kycStatuses[_who].kycLevel = _level;
        kycStatuses[_who].nationalities = _nationalities;
    }
}