pragma solidity >=0.6.0 <0.9.0;

contract BusinessNumbersTest {
    uint256 businessNumber = 0;
    uint256[] numbers;

    function store(uint256 _businessNumber) public {
        businessNumber = _businessNumber;
        numbers.push(_businessNumber);
    }

    function retrieve() public view returns (uint256) {
        return businessNumber;
    }
}