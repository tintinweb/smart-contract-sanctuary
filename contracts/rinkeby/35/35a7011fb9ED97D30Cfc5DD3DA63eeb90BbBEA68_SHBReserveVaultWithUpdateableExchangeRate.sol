pragma solidity 0.7.6;

// SPDX-License-Identifier: MIT

import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

/// @notice Vault for SHB reserve token i.e. cBSN
/// @dev Ownable + pausable contract
contract SHBReserveVaultWithUpdateableExchangeRate is Ownable, Pausable {
    using SafeMath for uint256;

    IERC20 public shbToken;

    IERC20 public cBSNToken;

    uint256 public cBSNPerSHB;

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

    /// @notice Claim cBSN in exchange for a specific amount of a SHB
    /// @notice Only callable after vaultUnlockedFromBlockNumber
    /// @dev action only possible
    /// @param _amount Amount of input token being exchanged for cBSN
    function claim(uint256 _amount) public whenNotPaused {
        require(block.number > vaultUnlockedFromBlockNumber, "Reserve vault locked");
        require(_amount > 0, "Amount cannot be zero");

        shbToken.transferFrom(msg.sender, address(this), _amount);

        uint256 cBSNClaimAmount = _amount.mul(cBSNPerSHB);
        cBSNToken.transfer(msg.sender, cBSNClaimAmount);
    }

    /// @notice Allows contract owner to be able to update SHB > cBSN exchange rate
    /// @param _cBSNPerSHB new exchange rate
    function updatecBSNPerSHBExchangeRate(uint256 _cBSNPerSHB) external onlyOwner {
        cBSNPerSHB = _cBSNPerSHB;
    }

    /// @notice Allows contract owner to transfer cBSN
    /// @param _recipient cBSN recipient
    /// @param _amount of cBSN to transfer
    function transfercBSN(address _recipient, uint256 _amount) external onlyOwner {
        cBSNToken.transfer(_recipient, _amount);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}