// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./AdminAccess.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract TokenVesting is AdminAccess, ReentrancyGuard {
    using SafeMath for uint256;

    /**
     * @dev a Chunk is a period of time in which the beneficiary can receive the same amount of token each time a followUpDuration passes,
     * starting from effectiveDate (in relative to startTime).
     */
    struct Chunk {
        uint32 effectiveDate; // Duration from startTime that the chunk becomes effective
        uint256 amountPerUnlock;
        uint32 followUps;
        uint32 followUpDuration;
    }

    struct BeneficiaryInfo {
        uint32 index; // Location of beneficiary in beneficiaryAddresses.
        Chunk[] chunks;
        uint256 claimedAmount;
    }

    event StartTimeSet(uint256 _startTime);
    event BeneficiaryAdded(address indexed _beneficiary, uint32 _index);
    event BeneficiaryRemoved(address indexed _beneficiary);
    event TokenClaimed(address indexed _beneficiary, uint256 _amount);

    IBEP20 public token;
    uint256 public startTime;
    bool public isOnlyAdminCanRelease;
    mapping(address => BeneficiaryInfo) public beneficiaries;
    address[] public beneficiaryAddresses;

    constructor(IBEP20 _token, uint256 _startTime) {
        token = _token;
        editStartTime(_startTime);
        beneficiaryAddresses.push(address(0));
        isOnlyAdminCanRelease = true;
    }

    function editStartTime(uint256 _newTime) public onlyAdmin {
        startTime = _newTime;
        emit StartTimeSet(startTime);
    }

    /**
     * @dev Function for admin to add another beneficiary, initiate with chunks.
     */
    function addBeneficiary(address _beneficiary, Chunk[] calldata _chunks)
        external
        onlyAdmin
    {
        require(
            beneficiaries[_beneficiary].index == 0,
            "TokenVesting: Beneficiary already existed"
        );

        uint32 _index = uint32(beneficiaryAddresses.length);
        beneficiaries[_beneficiary].index = _index;
        addChunks(_beneficiary, _chunks);
        beneficiaryAddresses.push(_beneficiary);

        emit BeneficiaryAdded(_beneficiary, _index);
    }

    /**
     * @dev Function for admin to add more chunks for a specific beneficiary.
     */
    function addChunks(address _beneficiary, Chunk[] memory _chunks)
        public
        onlyAdmin
    {
        require(
            beneficiaries[_beneficiary].index > 0,
            "TokenVesting: Beneficiary not existed"
        );

        Chunk[] storage _beneficiaryChunks = beneficiaries[_beneficiary].chunks;

        for (uint256 _i = 0; _i < _chunks.length; _i++) {
            _beneficiaryChunks.push(_chunks[_i]);
        }
    }

    /**
     * @dev Remove beneficiary, only used in rare cases that need some modifications.
     */
    function removeBeneficiary(address _beneficiary) external onlyAdmin {
        require(
            beneficiaries[_beneficiary].index > 0,
            "TokenVesting: Beneficiary not existed"
        );

        uint32 _currentIndex = beneficiaries[_beneficiary].index;
        uint256 _lastIndex = beneficiaryAddresses.length.sub(1);

        // Replace by last item in array
        beneficiaryAddresses[_currentIndex] = beneficiaryAddresses[_lastIndex];
        beneficiaries[beneficiaryAddresses[_currentIndex]]
            .index = _currentIndex;
        beneficiaryAddresses.pop();

        delete beneficiaries[_beneficiary];

        emit BeneficiaryRemoved(_beneficiary);
    }

    /**
     * @dev Remove beneficiary, only used in rare cases that need some modifications.
     */
    function getBeneficiaryList() external view returns (address[] memory) {
        return beneficiaryAddresses;
    }

    /**
     * @dev Query chunks of a beneficiary.
     */
    function beneficiaryChunks(address _beneficiary)
        external
        view
        returns (Chunk[] memory _chunks)
    {
        _chunks = beneficiaries[_beneficiary].chunks;
    }

    /**
     * @dev Query total allocated token, both unlocked and locked.
     */
    function totalAllocatedAmount(address _beneficiary)
        external
        view
        returns (uint256 _amount)
    {
        Chunk[] storage _chunks = beneficiaries[_beneficiary].chunks;

        for (uint256 _i = 0; _i < _chunks.length; _i++) {
            Chunk storage _chunk = _chunks[_i];
            _amount = _amount.add(
                _chunk.amountPerUnlock.mul(uint256(1).add(_chunk.followUps))
            );
        }
    }

    function unlockedAmount(address _beneficiary)
        public
        view
        returns (uint256 _totalUnlocked, uint256 _claimable)
    {
        _totalUnlocked = unlockedAt(_beneficiary, block.timestamp);

        uint256 _claimedAmount = beneficiaries[_beneficiary].claimedAmount;
        _claimable = _totalUnlocked.sub(_claimedAmount);
    }

    function unlockedAt(address _beneficiary, uint256 _timestamp)
        public
        view
        returns (uint256 _totalUnlocked)
    {
        Chunk[] storage _chunks = beneficiaries[_beneficiary].chunks;

        for (uint256 _i = 0; _i < _chunks.length; _i++) {
            Chunk storage _chunk = _chunks[_i];

            if (startTime.add(_chunk.effectiveDate) <= _timestamp) {
                // Calculate how many follow-ups have occured
                uint256 followUps = 0;

                if (_chunk.followUpDuration > 0) {
                    followUps = _timestamp
                        .sub(startTime.add(_chunks[_i].effectiveDate))
                        .div(_chunk.followUpDuration);
                }

                if (followUps > _chunk.followUps) {
                    followUps = _chunk.followUps;
                }

                // There are (followUps + 1) unlocks have happened
                _totalUnlocked = _totalUnlocked.add(
                    _chunk.amountPerUnlock.mul(followUps.add(1))
                );
            }
        }
    }

    /**
     * @dev Allows beneficiary to claim claimable tokens
     */
    function claimToken(address _beneficiary,uint256 _claimAmount) external nonReentrant {
        if(isOnlyAdminCanRelease){
            require(isAdmin(_msgSender()),"You don't have permission.");
        }
        (uint256 _totalUnlocked, uint256 _claimable) = unlockedAmount(
            _beneficiary
        );
        require(_claimable > 0, "TokenVesting: No claimable amount");
        require(_claimAmount <= _claimable, "TokenVesting: Claim amout exceeds Claimable amount");

        beneficiaries[_beneficiary].claimedAmount += _claimAmount;
        token.transfer(_beneficiary, _claimAmount);

        emit TokenClaimed(_beneficiary, _claimAmount);
    }

    function setIsOnlyAdminCanRelease(bool _value) onlyAdmin external{
        isOnlyAdminCanRelease = _value;
    }
}