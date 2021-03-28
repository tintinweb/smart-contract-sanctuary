pragma solidity ^0.5.17;

import "./ERC20Detailed.sol";
import "./BurnableToken.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract STUDToken is ERC20Detailed, BurnableToken {
    using SafeMath for uint256;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     * @param _initialTotalSupply Total supply of STUD Token.
     * @param _owner Owner of the STUD Token.
     */
    constructor (uint256 _initialTotalSupply, address payable _owner) public {
        _name = "Studyum Token";
        _symbol = "STUD";
        _decimals = 18;
        _totalSupply = _initialTotalSupply;
        _balances[_owner] = _totalSupply;
        transferOwnership(_owner);
        emit Transfer(address(0), _owner, _totalSupply);
    }

    /**
     * @dev Used for bulk transfering. It can be used by anyone. Useful for airdrop.
     * @param beneficiaries Array of addresses to receive tokens.
     * @param amounts Array of token amounts addresses should receive.
     */
    function bulkTransfer(address[] calldata beneficiaries, uint256[] calldata amounts) external {
        require(beneficiaries.length > 0, "Beneficiaries shouldn't be empty.");
        require(beneficiaries.length == amounts.length, "Array lengths should be equal.");
        uint256 amountSum = 0;
        for (uint256 i=0; i<beneficiaries.length; i++) {
            require(beneficiaries[i] != address(0), "Beneficiary is address zero.");
            require(amounts[i]>0, "Amount is zero.");
            amountSum += amounts[i];
        }
        require(amountSum <= balanceOf(msg.sender), "Sender amount too low.");
        for (uint256 i=0; i<beneficiaries.length; i++) {
            transfer(beneficiaries[i], amounts[i]);
        }
        emit BulkTransfer(msg.sender, amountSum, beneficiaries.length);
    }

    
    /**
     * @dev Revertible fallback to prevent Ether deposits.
     */
    function () external payable {
        revert("Revert the ETH.");
    }

    /**
     * @dev Claim mistakenly sent tokens to the contract.
     * @param _tokenAddress Address of the token to be extracted.
     */
    function claimTokens(address _tokenAddress) public onlyOwner {
        if (_tokenAddress == address(0)) {
            owner().transfer(address(this).balance);
            return;
        }

        IERC20 token = IERC20(_tokenAddress);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
        emit ClaimedTokens(_tokenAddress, owner(), balance);
    }

    /**
     * @dev Emitted when the mistakenly sent tokens are claimed.
     */
    event ClaimedTokens(address _token, address _owner, uint256 _amount);
    /**
     * @dev Emitted when the bulk transfer is executed.
     */    
    event BulkTransfer(address _sender, uint256 _totalAmount, uint256 _beneficiaryCount);

}