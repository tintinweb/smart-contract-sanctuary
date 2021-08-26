/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: VestingFinalSeconds.sol


pragma solidity 0.8.0;


interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/*
Inspired by and based on following vesting contract:
https://gist.github.com/rstormsf/7cfb0c6b7a835c0c67b4a394b4fd9383
*/
contract TechTokenVesting is Ownable {

    event GrantAdded(address indexed recipient, uint256 grantId);
    event GrantTokensClaimed(address indexed recipient, uint256 amountClaimed);
    event GrantRemoved(address recipient, uint256 amountVested, uint256 amountNotVested);
    event ChangedAdmin(address admin);

    enum VGroup{ Ecosystem_community,
                Development_Tech,
                Development_Mktg,
                Founders,
                Team,
                Advisors,
                DEX_Liquidity,
                Seed,
                Private_TGE,
                Private_Linear,
                Public_TGE,
                Public_Linear,
                Removed_Grant,
                Custom1,
                Custom2,
                Custom3}

    struct Grant {
        uint256 startTime;
        uint256 amount;
        uint16 vestingDuration; // In seconds
        uint16 vestingCliff;    // In seconds
        uint16 secondsClaimed; // wtf?
        address recipient;
        uint256 totalClaimed;
    }

    // Category of Vesting Group    
    struct VestingGroup {
        uint8 vestingDuration; // In seconds
        uint8 vestingCliff; // In seconds
        uint8 percent_tSupply;  // percent of total supply 
    }

    mapping (uint256 => Grant) public tokenGrants;
    mapping (address => uint[]) private activeGrants;
    mapping (VGroup => VestingGroup) private parameter; // Enum mapped to Struct

    address public admin;
    uint256 public totalVestingCount = 1;
    ERC20 public immutable techToken;
    uint24 constant internal SECONDS_PER_DAY = 86400;

    /// @notice There are two admin roles - admin and owner
    /// in case of need/risk, owner can substitute/change admin
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner(), "Not Admin");
        _;
    }
    modifier onlyValidAddress(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this) && _recipient != address(techToken), "not valid _recipient");
        _;
    }

    constructor(ERC20 _techToken)  {
        require(address(_techToken) != address(0), "invalid token address");
        admin = msg.sender;
        techToken = _techToken;
    }

    /// @notice Add vesting parameters for specific VestingGroup into mapping "parameters"
    /// Needs to be called before calling addTokenGrant
    function addVestingGroupParameter(VGroup _name, 
                            uint8 _vestingDurationInSeconds, 
                            uint8 _vestingCliffInSeconds, 
                            uint8 _percent) 
                            external onlyAdmin{
        require(_vestingDurationInSeconds >= _vestingCliffInSeconds, "Duration < Cliff");
        parameter[_name] = VestingGroup(_vestingDurationInSeconds, _vestingCliffInSeconds, _percent);
    }

    /// @notice Add one or more token grants
    /// The amount of tokens here needs to be preapproved for this TokenVesting contract before calling this function
    /// @param _recipient Address of the token grant recipient
    /// @param _name Vesting group name, which is mapped to its specific parameters 
    /// @param _startTime Grant start time in seconds (unix timestamp)
    /// @param _amount Total number of tokens in grant
    function addTokenGrant(address[] calldata _recipient, 
                            VGroup[] calldata _name, 
                           uint256[] calldata _startTime,
                           uint256[] calldata _amount)
                            external onlyAdmin {
        require(_recipient.length <= 20, "Limit of 20 grants in one call exceeded");
        require(_recipient.length == _name.length, "Different array length");
        require(_recipient.length == _startTime.length, "Different array length");
        require(_recipient.length == _amount.length, "Different array length");
        
        for(uint i=0;i<_recipient.length;i++) {
            require(_amount[i] > 0, "Amount <= 0");

            Grant memory grant = Grant({
                startTime: _startTime[i] == 0 ? currentTime() : _startTime[i],
                amount: _amount[i],
                vestingDuration: parameter[_name[i]].vestingDuration,
                vestingCliff: parameter[_name[i]].vestingCliff,
                secondsClaimed: 0,
                totalClaimed: 0,
                recipient: _recipient[i]
            });

            tokenGrants[totalVestingCount] = grant;
            activeGrants[_recipient[i]].push(totalVestingCount);

            // Transfer the grant tokens under the control of the vesting contract
            require(techToken.transferFrom(msg.sender, address(this), _amount[i]), "transfer failed");

            emit GrantAdded(_recipient[i], totalVestingCount);
            totalVestingCount++;    //grantId
        }
    }

    /// @notice Allows a grant recipient to claim their vested tokens. Errors if no tokens have vested
    /// It is advised recipients check they are entitled to claim via `calculateGrantClaim` before calling this
    function claimVestedTokens(uint256 _grantId) external {
        uint16 timeVested;
        uint256 amountVested;
        (timeVested, amountVested) = calculateGrantClaim(_grantId);
        require(amountVested > 0, "amountVested is 0");

        Grant storage tokenGrant = tokenGrants[_grantId];
        tokenGrant.secondsClaimed = uint16(tokenGrant.secondsClaimed+(timeVested));
        tokenGrant.totalClaimed = uint256(tokenGrant.totalClaimed+(amountVested));

        require(techToken.transfer(tokenGrant.recipient, amountVested), "token transfer failed");
        emit GrantTokensClaimed(tokenGrant.recipient, amountVested);
    }

    /// @notice Terminate token grant transferring all vested tokens to the `_grantId`
    /// and returning all non-vested tokens to the Admin
    /// Secured to the Admin only
    /// @param _grantId grantId of the token grant recipient
    function removeTokenGrant(uint256 _grantId) 
        external 
        onlyAdmin
    {
        Grant storage tokenGrant = tokenGrants[_grantId];
        address recipient = tokenGrant.recipient;
        uint16 timeVested;
        uint256 amountVested;
        (timeVested, amountVested) = calculateGrantClaim(_grantId);

        uint256 amountNotVested = (tokenGrant.amount-(tokenGrant.totalClaimed))-(amountVested);

        tokenGrant.startTime = 0;
        tokenGrant.amount = 0;
        tokenGrant.vestingDuration = 0;
        tokenGrant.vestingCliff = 0;
        tokenGrant.secondsClaimed = 0;
        tokenGrant.totalClaimed = 0;
        tokenGrant.recipient = address(0);

        if (amountVested > 0) require(techToken.transfer(recipient, amountVested), "token transfer failed"); 
        if (amountNotVested > 0) require(techToken.transfer(owner(), amountNotVested), "transfer of not-vested tokens failed");
    
        // Non-vested tokens remain in smart contract
        // They can be withdrawn only using addTokenGrant 
        // if (amountNotVested > 0) require(techToken.transfer(msg.sender, amountNotVested), "token transfer failed");

        emit GrantRemoved(recipient, amountVested, amountNotVested);
    }

    function changeAdmin(address _newAdmin) 
        external 
        onlyOwner
        onlyValidAddress(_newAdmin)
    {
        admin = _newAdmin;
        emit ChangedAdmin(_newAdmin);
    }

    function getActiveGrants(address _recipient) public view returns(uint256[] memory){
        return activeGrants[_recipient];
    }

    /// @notice Calculate the vested and unclaimed seconds and tokens available for `_grantId` to claim
    /// Due to rounding errors once grant duration is reached, returns the entire left grant amount
    /// Returns (0, 0) if cliff has not been reached
    function calculateGrantClaim(uint256 _grantId) public view returns (uint16, uint256) {
        Grant storage tokenGrant = tokenGrants[_grantId];

        // For grants created with a future start date, that hasn't been reached, return 0, 0
        if (currentTime() < tokenGrant.startTime) {
            return (0, 0);
        }

        // Check cliff was reached
        uint elapsedTime = currentTime()-(tokenGrant.startTime);
        uint elapsedSeconds = elapsedTime;

        if (elapsedSeconds < tokenGrant.vestingCliff) {
            return (uint16(elapsedSeconds), 0);
        }

        // If over vesting duration, all tokens vested
        if (elapsedSeconds >= tokenGrant.vestingDuration) {
            uint256 remainingGrant = tokenGrant.amount-(tokenGrant.totalClaimed);
            return (tokenGrant.vestingDuration, remainingGrant);
        } else {
            uint16 timeVested = uint16(elapsedSeconds-(tokenGrant.secondsClaimed));
            uint256 amountVestedPerSecond = tokenGrant.amount/(uint256(tokenGrant.vestingDuration));
            uint256 amountVested = uint256(timeVested*(amountVestedPerSecond));
            return (timeVested, amountVested);
        }
    }

    function currentTime() public view returns(uint256) {
        return block.timestamp;
    }

    function tokensVestedPerSecond(uint256 _grantId) public view returns(uint256) {
        Grant memory tokenGrant = tokenGrants[_grantId];
        return tokenGrant.amount/(uint256(tokenGrant.vestingDuration));
    }

}