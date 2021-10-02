// SPDX-License-Identifier: MIT
/*
Unlock over 60 months							
*/
pragma solidity 0.8.6;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";

contract MATEcosystemClaim is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    IBEP20 public MAT;

    // uint256 public VESTING_FIRST_DURATION = 86400 * 30; //1 month
    uint256 public constant VESTING_FIRST_DURATION = 1800; //30 mons for testing
    // uint256 public VESTING_SECOND_DURATION = 86400 * 30 *36; //36 months
    uint256 public constant VESTING_SECOND_DURATION = 3600; //1 hour months

    uint256 public constant RELEASE_FIRST_DURATION = 5;

    uint256 public startTimeFirst;
    uint256 public endTimeFirst;
    // uint256 public startTimeSecond;
    uint256 public endTimeSecond;

    uint8 public stage;

    address public ECOSYSTEM_ADDRESS =
        0x83e9af907958d775385Eb24fb2716199329536Df;

    // address public ECOSYSTEM_ADDRESS =
    //     0x329e5Ef459F76630a2208C6d74e057c7295159a1;

    uint256 lock;
    uint256 released;

    event Claim(address indexed account, uint256 amount, uint256 time);

    constructor(IBEP20 _mat) {
        MAT = IBEP20(_mat);
        stage = 0;
        lock = 25000000000000000000000000; //25,000,000 MAT
    }

    function setTgeTime(uint256 _tge) public onlyOwner {
        require(stage == 0, "Can not setup tge");
        startTimeFirst = _tge;
        endTimeFirst = startTimeFirst + VESTING_FIRST_DURATION;
        endTimeSecond = endTimeFirst + VESTING_SECOND_DURATION;

        stage = 1;
    }

    function claim() external nonReentrant {
        require(stage == 1, "Can not claim now");
        require(block.timestamp > startTimeFirst, "still locked");
        require(_msgSender() == ECOSYSTEM_ADDRESS, "Address invalid");
        require(lock > released, "no locked");

        uint256 amount = canUnlockAmount();
        require(amount > 0, "Nothing to claim");

        released += amount;

        MAT.transfer(_msgSender(), amount);

        emit Claim(_msgSender(), amount, block.timestamp);
    }

    function canUnlockAmount() public view returns (uint256) {
        if (block.timestamp < startTimeFirst) {
            return 0;
        } else if (
            block.timestamp >= startTimeFirst && block.timestamp <= endTimeFirst
        ) {
            uint256 releasedTime = block.timestamp - startTimeFirst;
            uint256 totalUnlockFirstDuration = (lock * RELEASE_FIRST_DURATION) /
                100;
            return
                (totalUnlockFirstDuration * releasedTime) /
                VESTING_FIRST_DURATION -
                released;
        } else if (
            block.timestamp >= endTimeFirst && block.timestamp <= endTimeSecond
        ) {
            uint256 totalUnlockFirstDuration = (lock * RELEASE_FIRST_DURATION) /
                100;
            uint256 totalUnlockSecondDutaion = lock - totalUnlockFirstDuration;

            uint256 releasedTime = block.timestamp - endTimeFirst;

            return
                totalUnlockFirstDuration +
                (totalUnlockSecondDutaion * releasedTime) /
                VESTING_SECOND_DURATION -
                released;
        } else if (block.timestamp >= endTimeSecond) {
            return lock - released;
        }
    }

    function info()
        external
        view
        returns (
            uint8,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (stage == 0)
            return (
                stage,
                startTimeFirst,
                endTimeFirst,
                endTimeSecond,
                lock,
                released,
                0
            );
        return (
            stage,
            startTimeFirst,
            endTimeFirst,
            endTimeSecond,
            lock,
            released,
            canUnlockAmount()
        );
    }

    /* ========== EMERGENCY ========== */
    function governanceRecoverUnsupported(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(
            _token != address(MAT) ||
                MAT.balanceOf(address(this)) - _amount >= lock - released,
            "Not enough locked amount left"
        );
        IBEP20(_token).transfer(_to, _amount);
    }
}