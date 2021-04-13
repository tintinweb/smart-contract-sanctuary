// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract TokenLock is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;

    struct TokenGate {
        uint256 startTime;
        uint256 amount;
        uint16 Duration;
        uint16 daysClaimed;
        uint256 totalClaimed;
        address recipient;
    }

    event GateAdded(address indexed recipient);
    event GateTokensClaimed(address indexed recipient, uint256 amountClaimed);
    event GateRevoked(address recipient, uint256 amountVested, uint256 amountNotVested);

    ERC20 public token;
    
    mapping (address => TokenGate) private ReleaseAddresses;

    constructor(ERC20 _token) {
        token = _token;
    }
    
    function addTokenGate(
        address _recipient,
        uint256 _amount,
        uint16 _DurationInDays,
        uint16 _vestingCliffInDays    
    ) 
        external
        onlyOwner
    {
        require(ReleaseAddresses[_recipient].amount == 0, "Gate already exists, must revoke first.");
        require(_vestingCliffInDays >= 0, "Cliff not less than 0 days");
        require(_DurationInDays >= 0, "Duration not less than 0 days");
        
        uint256 amountVestedPerDay = _amount.div(_DurationInDays);
        require(amountVestedPerDay >= 0, "amountVestedPerDay > 0");

        // Transfer the gated tokens under the control of the vesting contract
        require(token.transferFrom(owner(), address(this), _amount));

        TokenGate memory releaseaddress = TokenGate({
            startTime: currentTime() + _vestingCliffInDays * 1 days,
            amount: _amount,
            Duration: _DurationInDays,
            daysClaimed: 0,
            totalClaimed: 0,
            recipient: _recipient
        });
        ReleaseAddresses[_recipient] = releaseaddress;
        emit GateAdded(_recipient);
    }

    function claimVestedTokens() external {
        uint16 daysVested;
        uint256 amountVested;
        (daysVested, amountVested) = calculateTokenClaim(msg.sender);
        require(amountVested > 0, "Vested must be greater than 0");

        TokenGate storage tokenRelease = ReleaseAddresses[msg.sender];
        tokenRelease.daysClaimed = uint16(tokenRelease.daysClaimed.add(daysVested));
        tokenRelease.totalClaimed = uint256(tokenRelease.totalClaimed.add(amountVested));
        
        require(token.transfer(tokenRelease.recipient, amountVested), "no tokens");
        emit GateTokensClaimed(tokenRelease.recipient, amountVested);
    }

    function revokeTokenGate(address _recipient) 
        external 
        onlyOwner
    {
        TokenGate storage tokenRelease = ReleaseAddresses[_recipient];
        uint16 daysVested;
        uint256 amountVested;
        (daysVested, amountVested) = calculateTokenClaim(_recipient);

        uint256 amountNotVested = (tokenRelease.amount.sub(tokenRelease.totalClaimed)).sub(amountVested);

        require(token.transfer(owner(), amountNotVested));
        require(token.transfer(_recipient, amountVested));

        tokenRelease.startTime = 0;
        tokenRelease.amount = 0;
        tokenRelease.Duration = 0;
        tokenRelease.daysClaimed = 0;
        tokenRelease.totalClaimed = 0;
        tokenRelease.recipient = address(0);

        emit GateRevoked(_recipient, amountVested, amountNotVested);
    }

    function getGateStartTime(address _recipient) public view returns(uint256) {
        TokenGate storage tokenRelease = ReleaseAddresses[_recipient];
        return tokenRelease.startTime;
    }

    function getGateAmount(address _recipient) public view returns(uint256) {
        TokenGate storage tokenRelease = ReleaseAddresses[_recipient];
        return tokenRelease.amount;
    }

    function calculateTokenClaim(address _recipient) private view returns (uint16, uint256) {
        TokenGate storage tokenRelease = ReleaseAddresses[_recipient];

        require(tokenRelease.totalClaimed < tokenRelease.amount, "Release fully claimed");

        if (currentTime() < tokenRelease.startTime) {
            return (0, 0);
        }

        uint elapsedDays = currentTime().sub(tokenRelease.startTime - 1 days).div(1 days);

        if (elapsedDays >= tokenRelease.Duration) {
            uint256 remainingTokens = tokenRelease.amount.sub(tokenRelease.totalClaimed);
            return (tokenRelease.Duration, remainingTokens);
        } else {
            uint16 daysVested = uint16(elapsedDays.sub(tokenRelease.daysClaimed));
            uint256 amountVestedPerDay = tokenRelease.amount.div(uint256(tokenRelease.Duration));
            uint256 amountVested = uint256(daysVested.mul(amountVestedPerDay));
            return (daysVested, amountVested);
        }
    }

    function currentTime() private view returns(uint256) {
        return block.timestamp;
    }
}