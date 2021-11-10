// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

/** @title Paladin Token contract  */
/// @author Paladin
/*
    Contract that manages locked tokens.
    Tokens can be released according to a vesting schedule, with a cliff and a vesting period
    If set at creation, vesting can be revoked by the owner
*/
contract TokenVesting is Ownable {
    using SafeERC20 for IERC20;


    // Storage : 

    // ERC20 token locked in the contract
    IERC20 public pal;

    // address to receive the tokens
    address public beneficiary;

    // dates are in seconds
    uint256 public start;
    // durations are in seconds
    uint256 public cliff;
    uint256 public duration;

    // vesting contract was initalized
    bool public initialized = false;
    // beneficiary accepted the vesting terms
    bool public accepted;

    // vesting can be set as revocable when created, and allow owner to revoke unvested tokens
    bool public revocable;
    bool public revoked;

    // amount of tokens locked when starting the 
    uint256 public lockedAmount;
    uint256 public totalReleasedAmount;


    // Events : 

    event TokensReleased(uint256 releasedAmount);
    event TokenVestingRevoked(uint256 revokedAmount);
    event LockAccepted();
    event LockCanceled();


    //Modifiers : 

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "TokenVesting: Caller not beneficiary");
        _;
    }

    modifier onlyIfAccepted() {
        require(initialized && accepted, "TokenVesting: Vesting not accepted");
        _;
    }


    // Constructor : 
    /**
     * @dev Creates the vesting contract
     * @param _palAddress address of the locked token (PAL token)
     */
    constructor(
        address _admin,
        address _palAddress
    ){
        require(_admin != address(0), "TokenVesting: admin is address zero");
        require(_palAddress != address(0), "TokenVesting: incorrect PAL address");

        pal = IERC20(_palAddress);

        transferOwnership(_admin);
    }


    // Functions : 

    /**
     * @dev Initializes the vesting contract with a cliff. Cliff can be 0
     * @param _beneficiary address receiving the vested tokens
     * @param _lockedAmount amount of tokens locked in the contract
     * @param _startTimestamp timestamp when the vesting starts (Unix Timestamp)
     * @param _cliffDuration duration of the cliff period (in seconds)
     * @param _duration duration of the vesting period (in seconds)
     * @param _revocable is vesting revocable
     */
    function initialize(
        address _beneficiary,
        uint256 _lockedAmount,
        uint256 _startTimestamp, //Unix Timestamp
        uint256 _cliffDuration, //in seconds
        uint256 _duration, //in seconds
        bool _revocable
    ) external onlyOwner {
        require(initialized == false, "TokenVesting: Already initialized");


        require(_beneficiary != address(0), "TokenVesting: beneficiary is address zero");
        require(_lockedAmount > 0, "TokenVesting: locked amount is null");
        require(_duration > 0, "TokenVesting: duration is null");
        require(_cliffDuration <= _duration, "TokenVesting: cliff longer than duration");
        require(_startTimestamp + _duration > block.timestamp, "TokenVesting: incorrect vesting dates");


        beneficiary = _beneficiary;

        lockedAmount = _lockedAmount;

        start = _startTimestamp;
        cliff = _cliffDuration;
        duration = _duration;

        revocable = _revocable;

        initialized = true;
        
    }

    function acceptLock() external onlyBeneficiary {
        require(initialized, "TokenVesting: Contract not initialized");
        require(lockedAmount == pal.balanceOf(address(this)), "TokenVesting: Token amount not correct");

        accepted = true;

        emit LockAccepted();
    }


    function cancelLock() external onlyOwner {
        require(accepted == false, "TokenVesting: Cannot cancel accepted contract");

        pal.safeTransfer(owner(), pal.balanceOf(address(this)));

        emit LockCanceled();
    }


    function release() external onlyIfAccepted onlyBeneficiary {
        uint256 unreleasedAmount = _releasableAmount();

        require(unreleasedAmount > 0, "TokenVesting: No tokens to release");

        totalReleasedAmount = totalReleasedAmount + unreleasedAmount;

        pal.safeTransfer(beneficiary, unreleasedAmount);

        emit TokensReleased(unreleasedAmount);
    }


    function releasableAmount() external view returns (uint256){
        return _releasableAmount();
    }


    function _vestedAmount() private view returns (uint256) {
        if (block.timestamp < start + cliff || !accepted) {
            return 0;
        } else if (block.timestamp >= start + duration || revoked) {
            return pal.balanceOf(address(this)) + totalReleasedAmount;
        } else {
            return (lockedAmount * (block.timestamp - start)) / duration;
        }
    }


    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount() - totalReleasedAmount;
    }


    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyBeneficiary {
        // Cannot recover the locked token
        require(tokenAddress != address(pal), "TokenVesting: Cannot recover locked tokens");

        IERC20(tokenAddress).safeTransfer(beneficiary, tokenAmount);
    }


    // Admin Functions : 

    function revoke() external onlyOwner {
        require(revocable, "TokenVesting: Not revocable");
        require(!revoked, "TokenVesting: Already revoked");

        uint256 remaingingAmount = pal.balanceOf(address(this));

        uint256 unreleasedAmount = _releasableAmount();
        uint256 revokedAmount = remaingingAmount - unreleasedAmount;

        revoked = true;

        pal.safeTransfer(owner(), revokedAmount);

        emit TokenVestingRevoked(revokedAmount);
    }

}