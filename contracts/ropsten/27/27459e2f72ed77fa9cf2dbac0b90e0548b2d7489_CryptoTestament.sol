/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: UNLICENSED
// LiberDApps
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

contract CryptoTestament {
    address payable private contractOwner;
    uint256 private serviceFeePercent;

    enum TestamentStatus {
        OPEN,
        CANCELLED,
        EXECUTED
    }

    struct Testament {
        uint256 timestamp;
        address senderAddress;
        address beneficiaryAddress;
        uint256 testamentAmount;
        uint256 unlockTimestamp;
        string encryptedTestament;
        string testamentHash;
        TestamentStatus status;
    }

    Testament[] private testaments;

    event SetFeePercent(uint256 _oldFeePercent, uint256 _newFeePercent);

    event CreateTestament(
        address _senderAddress,
        address _beneficiaryAddress,
        uint256 _totalAmount,
        uint256 _feeAmount,
        uint256 _testamentAmount,
        uint256 _daysBeforeUnlock,
        TestamentStatus _status
    );

    constructor() {
        contractOwner = payable(msg.sender);
        setServiceFeePercent(2);
    }

    modifier onlyOwner() {
        require(
            msg.sender == contractOwner,
            "Ownable: caller is not the owner"
        );
        _;
    }

    function setServiceFeePercent(uint256 _newServiceFeePercent)
        public
        onlyOwner
    {
        require(
            _newServiceFeePercent >= 0,
            "Service fee (in percentage) must be >= 0."
        );
        require(
            _newServiceFeePercent < 100,
            "Service fee (in percentage) must be < 100."
        );
        uint256 oldFeePercent = serviceFeePercent;
        serviceFeePercent = _newServiceFeePercent;
        emit SetFeePercent(oldFeePercent, _newServiceFeePercent);
    }

    function getServiceFeePercent() public view returns (uint256) {
        return serviceFeePercent;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function makeTestament(
        address _toAddress,
        uint256 _daysBeforeUnlock,
        string calldata _encryptedTestament,
        string calldata _testamentHash
    ) public payable {
        // We require at least 1 Wei when making testaments.
        require(msg.value >= 1, "Deposit must be at least 1 Wei.");

        // Avoid a null address beneficiary.
        require(_toAddress != address(0x0));

        // We require at least 1 day for unlock time.
        require(
            _daysBeforeUnlock >= 1,
            "Days before unlock must be at least 1."
        );

        // Calculate the service fees and deduct it from the testament amount.
        // The 'testamentAmount' is the amount that will be available either:
        // - When the testament maker decides to cancel it and get the coins back.
        // - When the beneficiary withdraws the coins.
        // IMPORTANT:
        // - The div() method will round the fee amount down. For example, if you create a testament with 10 WEI and
        // the service fee is 7%, the actual fee amount will be 0 (0.7 rounded down), not 1 (0.7 rounded up), i.e.,
        // the fee amount will always benefit the user, not the contract :)
        uint256 receivedAmount = msg.value;
        uint256 feeAmount = div(
            mul(receivedAmount, getServiceFeePercent()),
            100
        );
        uint256 testamentAmount = sub(receivedAmount, feeAmount);

        // Pay the service fee (if any).
        if (feeAmount > 0) {
            contractOwner.transfer(feeAmount);
        }

        // Create the testament.
        testaments.push(
            Testament(
                block.timestamp,
                msg.sender,
                _toAddress,
                testamentAmount,
                block.timestamp + _daysBeforeUnlock * 60,
                _encryptedTestament,
                _testamentHash,
                TestamentStatus.OPEN
            )
        );

        // Log for auditing purposes.
        emit CreateTestament(
            msg.sender,
            _toAddress,
            receivedAmount,
            feeAmount,
            testamentAmount,
            _daysBeforeUnlock,
            TestamentStatus.OPEN
        );
    }

    function cancelTestament(uint256 _testamentId) public {
        require(_testamentId >= 0, "Testament ID should be >= 0.");
        require(
            _testamentId < testaments.length,
            "Testament ID out of bounds."
        );

        Testament storage testament = testaments[_testamentId];
        require(
            testament.senderAddress == msg.sender,
            "You can't cancel a testament that you have not created!"
        );
        require(
            testament.status == TestamentStatus.OPEN,
            "This testament is no longer available."
        );

        // To avoid re-entrant isses, FIRST, we'll update the testament status so that further attempts
        //to cancel or execute it  will fail -- as expected.
        // Then, and only then, we refund the testament maker.
        // More about that security procedure: ...
        testament.status = TestamentStatus.CANCELLED;
        payable(testament.senderAddress).transfer(testament.testamentAmount);
    }

    function executeTestament(uint256 _testamentId) public {
        require(_testamentId >= 0, "Testament ID should be >= 0.");
        require(
            _testamentId < testaments.length,
            "Testament ID out of bounds."
        );

        Testament storage testament = testaments[_testamentId];
        require(
            testament.beneficiaryAddress == msg.sender,
            "You can't execute a testament that does not belong to you!"
        );
        require(
            testament.status == TestamentStatus.OPEN,
            "This testament is no longer available."
        );
        require(
            block.timestamp >= testament.unlockTimestamp,
            "You can't execute this contract yet. Please, try again later."
        );

        // To avoid re-entrant isses, FIRST, we'll update the testament status so that further attempts
        //to cancel or execute it  will fail -- as expected.
        // Then, and only then, we transfer the coins to the beneficiary.
        // More about that security procedure: ...
        testament.status = TestamentStatus.EXECUTED;
        payable(testament.beneficiaryAddress).transfer(
            testament.testamentAmount
        );
    }

    function getTestaments() public view returns (Testament[] memory) {
        return testaments;
    }

    /**
     * Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division overflow");
        uint256 c = a / b;
        return c;
    }
}