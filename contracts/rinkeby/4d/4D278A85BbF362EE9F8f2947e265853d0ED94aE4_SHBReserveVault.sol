pragma solidity 0.7.6;

// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./SafeMath.sol";

/// @notice Vault for SHB reserve token i.e. cBSN
contract SHBReserveVault {
    using SafeMath for uint256;

    IERC20 public shbToken;

    IERC20 public cBSNToken;

    uint256 public immutable cBSNPerSHB;

    uint256 public immutable vaultUnlockedFromBlockNumber;

    /// @param _shbToken SHB Token address
    /// @param _cBSNToken cBSN Token address
    /// @param _cBSNPerSHB Amount of cBSN user will receive per SHB (no decimal places i.e. 1000 and not 1000 x 10^18)
    /// @param _vaultUnlockedFromBlockNumber Block number when SHB holders will be able to exchange SHB for cBSN
    constructor(
        IERC20 _shbToken,
        IERC20 _cBSNToken,
        uint256 _cBSNPerSHB,
        uint256 _vaultUnlockedFromBlockNumber
    ) {
        shbToken = _shbToken;
        cBSNToken = _cBSNToken;
        cBSNPerSHB = _cBSNPerSHB;
        vaultUnlockedFromBlockNumber = _vaultUnlockedFromBlockNumber;
    }

    /// @notice Claim all cBSN attached to SHB balance of sender
    function claimUsingFullSHBBalance() external {
        claim(shbToken.balanceOf(msg.sender));
    }

    /// @notice Claim cBSN in exchange for a specific amount of SHB
    /// @notice Only callable after vaultUnlockedFromBlockNumber
    /// @param _shbAmount Amount of SHB being exchanged
    function claim(uint256 _shbAmount) public {
        require(block.number > vaultUnlockedFromBlockNumber, "Reserve vault locked");
        uint256 cBSNClaimAmount = _shbAmount.mul(cBSNPerSHB);
        shbToken.transferFrom(msg.sender, address(this), _shbAmount);
        cBSNToken.transfer(msg.sender, cBSNClaimAmount);
    }
}