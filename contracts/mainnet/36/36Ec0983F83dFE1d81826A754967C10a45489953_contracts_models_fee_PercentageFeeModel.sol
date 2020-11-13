pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IFeeModel.sol";

contract PercentageFeeModel is IFeeModel {
    using SafeMath for uint256;

    address payable public beneficiary;

    constructor(address payable _beneficiary) public {
        beneficiary = _beneficiary;
    }

    function getFee(uint256 _txAmount)
        external
        pure
        returns (uint256 _feeAmount)
    {
        _feeAmount = _txAmount.div(10); // Precision is decreased by 1 decimal place
    }
}
