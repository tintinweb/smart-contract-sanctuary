pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

// @title Escrow
// @notice A token holder contract allowing contract owner to set beneficiary of
// all tokens held by the contract and allowing the beneficiary to withdraw
// the tokens.
contract Escrow is Ownable {
    using SafeERC20 for IERC20;

    event BeneficiaryUpdated(address beneficiary);
    event TokensWithdrawn(address beneficiary, uint256 amount);

    IERC20 public token;
    address public beneficiary;

    constructor(IERC20 _token) public {
        token = _token;
    }

    // @notice Sets the provided address as a beneficiary allowing it to
    // withdraw all tokens from escrow. This function can be called only
    // by escrow owner.
    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
        emit BeneficiaryUpdated(beneficiary);
    }

    // @notice Withdraws all tokens from escrow to the beneficiary.
    // If the beneficiary is not set, caller is not the beneficiary, or there
    // are no tokens in escrow, function fails.
    function withdraw() public {
        require(beneficiary != address(0), "Beneficiary not assigned");
        require(msg.sender == beneficiary, "Caller is not the beneficiary");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to withdraw");

        token.safeTransfer(beneficiary, amount);
        emit TokensWithdrawn(beneficiary, amount);
    }
}