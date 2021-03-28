pragma solidity ^0.5.17;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract STUDTeamVesting is Ownable {
    using SafeMath for uint256;

    address private _beneficiary;
    uint256 private _ieoEndTime; 
    uint256 private _totalAmount;
    uint256 private _withdrawnAmount = 0;
    uint256[] private _months = [0, 6, 12, 18, 21, 24, 27, 30, 33, 36];
    uint256[] private _percentages = [100, 100, 100, 100, 100, 100, 100, 100, 100, 100];
    IERC20 private _token;
    uint256 private constant _daysInMonth = 30 days;

    /**
     * @dev Prevents other adresses except beneficiary.
     */
    modifier onlyBeneficiary {
        require(msg.sender == _beneficiary, "Sender has to be already set as a beneficiary");
        _;
    }

    /**
     * @dev Get the benficiary address.
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiaryAddress Address of the beneficiary to whom vested tokens are transferred.
     * @param token Address of the token which will be vested.
     * @param ieoEndTime IEO end time in UNIX.
     * @param totalAmount Total amount of tokens stored in contract.
     */
    constructor (address token, address payable owner, address payable beneficiaryAddress, uint256 ieoEndTime, uint256 totalAmount) public {
        require(token != address(0), "Token is the zero address.");
        require(owner != address(0), "Owner is the zero address.");
        require(beneficiaryAddress != address(0), "Beneficiary is the zero address.");
        require(ieoEndTime > block.timestamp, "IEO end time should be bigger than current timestamp.");
        require(totalAmount > 0, "Total Amount should be bigger than 0.");

        _token = IERC20(token);
        _beneficiary = beneficiaryAddress;
        _ieoEndTime = ieoEndTime;
        _totalAmount = totalAmount;
        transferOwnership(owner);
    }

    /**
     * @dev Current amount of tokens possible to withdraw from contract.
     */
     function withdrawable() public view returns (uint256) {
        uint256 percentageSum = 0;
        for (uint256 i = 0; i<_months.length; i++) {
    	    uint256 tempTime = _ieoEndTime + _months[i] * _daysInMonth;
    	    if (block.timestamp > tempTime) {
    		    percentageSum += _percentages[i];
    	    }
        }
        return _totalAmount * percentageSum / 1000.0 - _withdrawnAmount;
    }

    /**
     * @dev Withdraws the tokens from contract to beneficiary address.
     */
    function withdraw() public onlyBeneficiary  {
        uint256 withdrawableAmount = withdrawable();
        _withdrawnAmount += withdrawableAmount;
        require (withdrawableAmount > 0, "Withdrawable amount must be greater than zero.");
        _token.transfer(_beneficiary, withdrawableAmount);
        emit TokensWithdrawed(_beneficiary, withdrawableAmount);
    }

    /**
     * @dev Returns the timestamps of each payout. Beacause a month can have different number
     * of days, months are represented as 30 day period in contract.
     */
    function getTimestamps() public view returns (uint256[] memory) {
    	uint256[] memory timestamps = new uint256[](_months.length);
    	for (uint256 i = 0; i<_months.length; i++) {
    		uint256 timestamp = _ieoEndTime + _months[i] * _daysInMonth;
    		timestamps[i] = timestamp;
        }
    	return timestamps;
    }

    /**
     * @dev Returns the IEO end time in UNIX timestamp
     */
    function getIeoEndTime() public view returns (uint256) {
        return _ieoEndTime;
    }

    /**
     * @dev Returns the total amount of tokens which was set during contract deployment.
     */
    function getTotalAmount() public view returns (uint256) {
        return _totalAmount;
    }

    /**
     * @dev Returns currently withdrawn amount from contract.
     */
    function getWithDrawnAmount() public view returns (uint256) {
        return _withdrawnAmount;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * @param _newBeneficiary New beneficiary address
     */
    function changeBeneficiary(address payable _newBeneficiary) public onlyOwner {
        require(_newBeneficiary != address(0), "Ownable: new owner is the zero address");
        emit BeneficiaryChanged(_beneficiary, _newBeneficiary);
        _beneficiary = _newBeneficiary;
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
     * @dev Emitted when the tokens are withdrawn from contract.
     */
    event TokensWithdrawed(address beneficiary, uint256 amount);
    /**
     * @dev Emitted when the mistakenly sent tokens are claimed.
     */
    event ClaimedTokens(address _token, address _owner, uint256 _amount);
    /**
     * @dev Emitted when a new beneficiary has been set.
     */
    event BeneficiaryChanged(address _beneficiary, address _newBeneficiary);


}