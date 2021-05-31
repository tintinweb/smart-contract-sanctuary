/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity ^0.6.7;

interface IBorrowerOperations {

    function openTrove(uint _maxFee, uint _LUSDAmount, address _upperHint, address _lowerHint) external payable;
    function addColl(address _upperHint, address _lowerHint) external payable;
    function moveETHGainToTrove(address _user, address _upperHint, address _lowerHint) external payable;
    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;
    function withdrawLUSD(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;
    function repayLUSD(uint _amount, address _upperHint, address _lowerHint) external;
    function closeTrove() external;
    function adjustTrove(uint _maxFee, uint _collWithdrawal, uint _debtChange, bool isDebtIncrease, address _upperHint, address _lowerHint) external payable;
    function claimCollateral() external;
    function getCompositeDebt(uint _debt) external pure returns (uint);
}

contract Lev {

    function takeLoan(
        address borrowerOperations
    ) public {

        IBorrowerOperations(borrowerOperations)
            .adjustTrove(0, 0, 500000000000000000, true, msg.sender, msg.sender);

    }

}