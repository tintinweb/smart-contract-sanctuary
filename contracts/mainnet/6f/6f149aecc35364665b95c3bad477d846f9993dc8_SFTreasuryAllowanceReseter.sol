/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

pragma solidity 0.6.7;

abstract contract StabilityFeeTreasuryLike {
    function getAllowance(address) virtual public view returns (uint256, uint256);
    function setTotalAllowance(address, uint256) virtual external;
}
contract SFTreasuryAllowanceReseter {
    // --- Variables ---
    StabilityFeeTreasuryLike public treasury;

    // --- Events ---
    event ResetTotalAllowance(address account);

    constructor(address treasury_) public {
        require(treasury_ != address(0), "SFTreasuryAllowanceReseter/null-treasury");
        treasury = StabilityFeeTreasuryLike(treasury_);
    }

    /*
    * @notify Reset the total allowance for an address that has a positive perBlock allowance
    */
    function resetTotalAllowance(address account) external {
        (, uint perBlockAllowance) = treasury.getAllowance(account);
        require(perBlockAllowance > 0, "SFTreasuryAllowanceReseter/null-per-block-allowance");
        treasury.setTotalAllowance(account, uint(-1));
        emit ResetTotalAllowance(account);
    }
}