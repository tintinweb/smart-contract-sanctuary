/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

contract OtherContract {

    uint firstNumber;
    uint secondNumber;

    constructor (uint _firstNumber, uint _secondNumber) public {
        firstNumber = _firstNumber;
        secondNumber = _secondNumber;
    }

    function multiplyNumbers() external view returns(uint) {
        return firstNumber * secondNumber;
    }
}