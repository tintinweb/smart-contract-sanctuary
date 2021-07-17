// SPDX-License-Identifier: MIT

/**
 * In memory of Selma
 */

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

contract SelmaLocker {
    using Address for address;

    struct TokenDetails {
        uint256 amount;
        uint256 releaseTime;
        address beneficiary;
    }

    event TokensLocked(
        address token,
        uint256 amount,
        uint256 releaseTime,
        address depositor,
        address beneficiary
    );
    event TokensReleased(
        address token,
        uint256 amount,
        address depositor,
        address beneficiary
    );
    event LockExtended(
        address token,
        uint256 newReleaseTime,
        address depositor,
        address beneficiary
    );

    // Depositor => Token => Details
    mapping (address => mapping (IERC20 => TokenDetails)) private _locks;

    function lockToken(address tokenAddress, uint256 amount, uint256 releaseTime_) external {
        require(releaseTime_ > block.timestamp, "Release time must be in the future");
        require(amount > 0, "Locked amount must be greater than zero");

        TokenDetails memory tokenDetails = TokenDetails(amount, releaseTime_, msg.sender);
        IERC20 token = IERC20(tokenAddress);

        _locks[msg.sender][token] = tokenDetails;
        require(token.allowance(msg.sender, address(this)) >= amount, "Contract is not approved");
        require(token.transferFrom(msg.sender, address(this), amount));

        emit TokensLocked(tokenAddress, amount, releaseTime_, msg.sender, msg.sender);
    }

    function lockToken(
        address tokenAddress, 
        uint256 amount, 
        uint256 releaseTime_, 
        address beneficiary
    ) external {
        require(releaseTime_ > block.timestamp, "Release time must be in the future");
        require(amount > 0, "Locked amount must be greater than zero");

        TokenDetails memory tokenDetails = TokenDetails(amount, releaseTime_, beneficiary);
        IERC20 token = IERC20(tokenAddress);

        _locks[msg.sender][token] = tokenDetails;
        require(token.allowance(msg.sender, address(this)) >= amount, "Contract is not approved");
        require(token.transferFrom(msg.sender, address(this), amount));

        emit TokensLocked(tokenAddress, amount, releaseTime_, msg.sender, beneficiary);
    }

    function extendLock(address tokenAddress, address depositor, uint256 newReleaseTime) external {
        IERC20 token = IERC20(tokenAddress);
        TokenDetails memory tokenDetails = _locks[depositor][token];

        require(msg.sender == tokenDetails.beneficiary, "Unauthorized caller");
        require(newReleaseTime > tokenDetails.releaseTime, "Can't decrease release time");
        require(tokenDetails.amount > 0, "No tokens locked");

        _locks[depositor][token].releaseTime = newReleaseTime;

        emit LockExtended(tokenAddress, newReleaseTime, depositor, tokenDetails.beneficiary);
    }

    function releaseToken(address tokenAddress, address depositor) external {
        IERC20 token = IERC20(tokenAddress);
        TokenDetails memory tokenDetails = _locks[depositor][token];

        require(msg.sender == tokenDetails.beneficiary, "Unauthorized caller");
        require(block.timestamp >= tokenDetails.releaseTime, "Lock is not expired");
        require(tokenDetails.amount > 0, "No tokens locked");

        _locks[depositor][token].amount = 0;
        require(token.transfer(tokenDetails.beneficiary, tokenDetails.amount));

        emit TokensReleased(tokenAddress, tokenDetails.amount, depositor, tokenDetails.beneficiary);
    }

    function releaseTime(address tokenAddress, address depositor) external view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return _locks[depositor][token].releaseTime;
    }
}