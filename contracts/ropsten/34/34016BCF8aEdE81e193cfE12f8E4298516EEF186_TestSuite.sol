/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity 0.5.4;
pragma experimental ABIEncoderV2;


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller&#39;s account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller&#39;s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender&#39;s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller&#39;s
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library Callable {
    struct CallResult {
        bool success;
        bytes data;
    }

    function makeCall(address to, bytes memory payload) internal returns(CallResult memory) {
        (bool success, bytes memory resultRaw) = address(to).call(payload);
        return CallResult(success, resultRaw);
    }
}


contract TestAccount {
    using Callable for address;

    function transfer(TestAccount to, uint256 value, address token) external returns(Callable.CallResult memory) {
        return token.makeCall(abi.encodeWithSignature("transfer(address,uint256)", to, value));
    }

    function approve(TestAccount spender, uint256 value, address token) external returns(Callable.CallResult memory) {
        return token.makeCall(abi.encodeWithSignature("approve(address,uint256)", spender, value));
    }

    function transferFrom(TestAccount from, TestAccount to, uint256 value, address token) external returns(Callable.CallResult memory) {
        return token.makeCall(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value));
    }
}


library TestedToken {
    using Callable for address;

    function totalSupply(address token) internal returns(Callable.CallResult memory) {
        return token.makeCall(abi.encodeWithSignature("totalSupply()"));
    }

    function balanceOf(address token, TestAccount who) internal returns(Callable.CallResult memory) {
        return token.makeCall(abi.encodeWithSignature("balanceOf(address)", who));
    }

    function allowance(address token, TestAccount owner, TestAccount spender) internal returns(Callable.CallResult memory) {
        return token.makeCall(abi.encodeWithSignature("allowance(address,address)", owner, spender));
    }

    function name(address token) internal returns(Callable.CallResult memory) {
        return token.makeCall(abi.encodeWithSignature("name()"));
    }

    function symbol(address token) internal returns(Callable.CallResult memory) {
        return token.makeCall(abi.encodeWithSignature("symbol()"));
    }

    function decimals(address token) internal returns(Callable.CallResult memory) {
        return token.makeCall(abi.encodeWithSignature("decimals()"));
    }
}


library TestUtils {
    function returnAndRevert(bool result) internal returns(bool) {
        assembly {
             let memOffset := mload(0x40)
             mstore(memOffset, result)
             mstore(0x40, add(memOffset, 32))
             revert(memOffset, 32)
        }
    }

    function expectTrue(Callable.CallResult memory callResult) internal returns(Callable.CallResult memory) {
        bytes memory data = callResult.data;
        if (!callResult.success) {
            returnAndRevert(false);
        }
        if (data.length != 32) {
            returnAndRevert(false);
        }
        bool result = abi.decode(data, (bool));
        if (!result) {
            returnAndRevert(false);
        }
        return callResult;
    }

    function expectEqual(Callable.CallResult memory callResult, uint expectedResult) internal returns(Callable.CallResult memory) {
        uint parsedData = toUInt(callResult);
        if (parsedData != expectedResult) {
            returnAndRevert(false);
        }
        return callResult;
    }

    function expectUInt(Callable.CallResult memory callResult) internal returns(Callable.CallResult memory) {
        if (!callResult.success || callResult.data.length != 32) {
            returnAndRevert(false);
        }
        return callResult;
    }

    function expectNonEmptyResult(Callable.CallResult memory callResult) internal returns(Callable.CallResult memory) {
        if (!callResult.success || callResult.data.length == 0) {
            returnAndRevert(false);
        }
        return callResult;
    }

    function expectSuccess(Callable.CallResult memory callResult) internal returns(Callable.CallResult memory) {
        if (!callResult.success) {
            returnAndRevert(false);
        }
        return callResult;
    }

    function expectRevert(Callable.CallResult memory callResult) internal returns(Callable.CallResult memory) {
        if (callResult.success) {
            returnAndRevert(false);
        }
        return callResult;
    }

    function toBool(Callable.CallResult memory callResult) internal returns(bool) {
        if (callResult.data.length != 32) {
            return false;
        }
        return abi.decode(callResult.data, (bool));
    }

    function toUInt(Callable.CallResult memory callResult) internal returns(uint) {
        expectUInt(callResult);
        return abi.decode(callResult.data, (uint));
    }
}


contract TestSuite {
    using TestUtils for Callable.CallResult;
    using TestedToken for address;
    using Callable for address;

    mapping(address => uint) public testResults;
    TestAccount[3] public testAccounts;

    bytes4[22] private testSignatures = [
        bytes4(keccak256(bytes("existenceTransferTest(address)"))),
        bytes4(keccak256(bytes("existenceApproveTest(address)"))),
        bytes4(keccak256(bytes("existenceTransferFromTest(address)"))),
        bytes4(keccak256(bytes("existenceAllowance(address)"))),
        bytes4(keccak256(bytes("existenceBalanceOf(address)"))),
        bytes4(keccak256(bytes("existenceTotalSupplyTest(address)"))),
        bytes4(keccak256(bytes("existenceName(address)"))),
        bytes4(keccak256(bytes("existenceSymbol(address)"))),
        bytes4(keccak256(bytes("existenceDecimals(address)"))),
        bytes4(keccak256(bytes("basicApproveTest(address)"))),
        bytes4(keccak256(bytes("approveZeroTokensTest(address)"))),
        bytes4(keccak256(bytes("allowanceRewriteTest(address)"))),
        bytes4(keccak256(bytes("basicTransferTest(address)"))),
        bytes4(keccak256(bytes("transferZeroTokensTest(address)"))),
        bytes4(keccak256(bytes("transferMoreThanBalanceTest(address)"))),
        bytes4(keccak256(bytes("basicTransferFromTest(address)"))),
        bytes4(keccak256(bytes("transferFromWithoutAllowanceTest(address)"))),
        bytes4(keccak256(bytes("transferFromNotFullAllowanceTest(address)"))),
        bytes4(keccak256(bytes("transferFromChangeAllowanceTest(address)"))),
        bytes4(keccak256(bytes("transferFromMoreThanAllowedTest(address)"))),
        bytes4(keccak256(bytes("transferFromOnBehalf(address)"))),
        bytes4(keccak256(bytes("transferFromLowFunds(address)")))
    ];

    modifier revertAfter() {
        _;
        TestUtils.returnAndRevert(true);
    }

    constructor() public {
        testAccounts[0] = new TestAccount();
        testAccounts[1] = new TestAccount();
        testAccounts[2] = new TestAccount();
    }

    function existenceTransferTest(address token) external revertAfter returns(bool) {

        testAccounts[0].transfer(testAccounts[1], 1000, token).expectTrue();
    }

    function existenceApproveTest(address token) external revertAfter returns(bool) {
        testAccounts[0].approve(testAccounts[1], 1000, token).expectTrue();
    }

    function existenceTransferFromTest(address token) external revertAfter returns(bool) {
        testAccounts[0].approve(testAccounts[1], 1000, token).expectTrue();
        testAccounts[1].transferFrom(testAccounts[0], testAccounts[1], 1000, token).expectTrue();
    }

    function existenceTotalSupplyTest(address token) external revertAfter returns(bool) {
        token.totalSupply().expectUInt();
    }

    function existenceBalanceOf(address token) external revertAfter returns(bool) {
        token.balanceOf(testAccounts[0]).expectUInt();
    }

    function existenceAllowance(address token) external revertAfter returns(bool) {
        token.allowance(testAccounts[0], testAccounts[1]).expectUInt();
    }

    function existenceName(address token) external revertAfter returns(bool) {
        token.name().expectNonEmptyResult();
    }

    function existenceSymbol(address token) external revertAfter returns(bool) {
        token.symbol().expectNonEmptyResult();
    }

    function existenceDecimals(address token) external revertAfter returns(bool) {
        uint tokenDecimals = token.decimals().toUInt();
        if (tokenDecimals >= 77) {
            TestUtils.returnAndRevert(false);
        }
    }

    function basicApproveTest(address token) external revertAfter returns(bool) {
        testAccounts[0].approve(testAccounts[1], 1000, token).expectTrue();
        token.allowance(testAccounts[0], testAccounts[1]).expectEqual(1000);
    }

    function approveZeroTokensTest(address token) external revertAfter returns(bool) {
        testAccounts[0].approve(testAccounts[1], 0, token).expectTrue();
        token.allowance(testAccounts[0], testAccounts[1]).expectEqual(0);
    }

    function allowanceRewriteTest(address token) external revertAfter returns(bool) {
        testAccounts[0].approve(testAccounts[1], 1000, token).expectTrue();
        token.allowance(testAccounts[0], testAccounts[1]).expectEqual(1000);
        testAccounts[0].approve(testAccounts[1], 2000, token).expectTrue();
        token.allowance(testAccounts[0], testAccounts[1]).expectEqual(2000);
    }

    function basicTransferTest(address token) external revertAfter returns(bool) {
        uint balance0Old = token.balanceOf(testAccounts[0]).toUInt();
        uint balance1Old = token.balanceOf(testAccounts[1]).toUInt();

        testAccounts[0].transfer(testAccounts[1], 1000, token).expectTrue();
        token.balanceOf(testAccounts[0]).expectEqual(balance0Old - 1000);
        token.balanceOf(testAccounts[1]).expectEqual(balance1Old + 1000);
    }

    function transferZeroTokensTest(address token) external revertAfter returns(bool) {
        uint balance0Old = token.balanceOf(testAccounts[0]).toUInt();
        uint balance1Old = token.balanceOf(testAccounts[1]).toUInt();

        testAccounts[0].transfer(testAccounts[1], 0, token).expectTrue();
        token.balanceOf(testAccounts[0]).expectEqual(balance0Old);
        token.balanceOf(testAccounts[1]).expectEqual(balance1Old);
    }

    function transferMoreThanBalanceTest(address token) external revertAfter returns(bool) {
        uint balance0Old = token.balanceOf(testAccounts[0]).toUInt();
        token.balanceOf(testAccounts[1]).toUInt();

        testAccounts[0].transfer(testAccounts[1], balance0Old + 1, token).expectRevert();
    }

    function basicTransferFromTest(address token) external revertAfter returns(bool) {
        uint balance0Old = token.balanceOf(testAccounts[0]).toUInt();
        uint balance1Old = token.balanceOf(testAccounts[1]).toUInt();

        testAccounts[0].approve(testAccounts[1], 1000, token).expectTrue();
        testAccounts[1].transferFrom(testAccounts[0], testAccounts[1], 1000, token).expectTrue();

        token.balanceOf(testAccounts[0]).expectEqual(balance0Old - 1000);
        token.balanceOf(testAccounts[1]).expectEqual(balance1Old + 1000);
        token.allowance(testAccounts[0], testAccounts[1]).expectEqual(0);
    }

    function transferFromWithoutAllowanceTest(address token) external revertAfter returns(bool) {
        testAccounts[0].approve(testAccounts[1], 0, token).expectTrue();
        token.balanceOf(testAccounts[0]).toUInt();
        token.balanceOf(testAccounts[1]).toUInt();

        testAccounts[1].transferFrom(testAccounts[0], testAccounts[1], 1, token).expectRevert();
    }

    function transferFromNotFullAllowanceTest(address token) external revertAfter returns(bool) {
        uint balance0Old = token.balanceOf(testAccounts[0]).toUInt();
        uint balance1Old = token.balanceOf(testAccounts[1]).toUInt();

        testAccounts[0].approve(testAccounts[1], 1000, token).expectTrue();
        testAccounts[1].transferFrom(testAccounts[0], testAccounts[1], 600, token).expectTrue();

        token.balanceOf(testAccounts[0]).expectEqual(balance0Old - 600);
        token.balanceOf(testAccounts[1]).expectEqual(balance1Old + 600);
        token.allowance(testAccounts[0], testAccounts[1]).expectEqual(400);
    }

    function transferFromMoreThanAllowedTest(address token) external revertAfter returns(bool) {
        testAccounts[0].approve(testAccounts[1], 600, token).expectTrue();
        token.balanceOf(testAccounts[0]).toUInt();
        token.balanceOf(testAccounts[1]).toUInt();

        testAccounts[1].transferFrom(testAccounts[0], testAccounts[1], 601, token).expectRevert();
    }

    function transferFromChangeAllowanceTest(address token) external revertAfter returns(bool) {
        testAccounts[0].approve(testAccounts[1], 1000, token).expectTrue();
        uint balance0Old = token.balanceOf(testAccounts[0]).toUInt();
        uint balance1Old = token.balanceOf(testAccounts[1]).toUInt();

        testAccounts[1].transferFrom(testAccounts[0], testAccounts[1], 600, token).expectTrue();
        token.balanceOf(testAccounts[0]).expectEqual(balance0Old - 600);
        token.balanceOf(testAccounts[1]).expectEqual(balance1Old + 600);

        testAccounts[0].approve(testAccounts[1], 0, token).expectTrue();
        testAccounts[1].transferFrom(testAccounts[0], testAccounts[1], 400, token).expectRevert();
    }

    function transferFromLowFunds(address token) external revertAfter returns(bool) {
        uint balance0 = token.balanceOf(testAccounts[0]).toUInt();
        testAccounts[0].approve(testAccounts[1], balance0 + 1, token).expectTrue();
        testAccounts[1].transferFrom(testAccounts[0], testAccounts[1], balance0 + 1, token).expectRevert();
    }

    function transferFromOnBehalf(address token) external revertAfter returns(bool) {
        uint balance0Old = token.balanceOf(testAccounts[0]).toUInt();
        uint balance1Old = token.balanceOf(testAccounts[1]).toUInt();
        uint balance2Old = token.balanceOf(testAccounts[2]).toUInt();

        testAccounts[0].approve(testAccounts[2], 1000, token).expectTrue();
        testAccounts[2].transferFrom(testAccounts[0], testAccounts[1], 1000, token).expectTrue();
        token.allowance(testAccounts[0], testAccounts[2]).expectEqual(0);
        token.balanceOf(testAccounts[0]).expectEqual(balance0Old - 1000);
        token.balanceOf(testAccounts[1]).expectEqual(balance1Old + 1000);
        token.balanceOf(testAccounts[2]).expectEqual(balance2Old);
    }

    function callTest(uint testNum, address token) internal returns(bool) {
        bytes memory payload = abi.encodeWithSelector(testSignatures[testNum], token);
        return address(this).makeCall(payload).toBool();
    }

    function runTests(address token, address customer) external returns(uint) {
        require(msg.sender == address(this), "use check() function to run tests");
        IERC20(token).transferFrom(customer, address(testAccounts[0]), 1000);

        // run tests
        uint testsPassed = 1;  // make the least bit equal to 1 to point out tests were run
        uint totalTests = testSignatures.length;
        for (uint testNum = 0; testNum < totalTests; ++testNum) {
            // call test
            bool testResult = callTest(testNum, token);
            // decode result and save
            if (testResult) {
                testsPassed += 1<<(testNum+1);
            }
        }

        // return testsPassed and revert
        assembly {
             let memOffset := mload(0x40)
             mstore(memOffset, testsPassed)
             mstore(0x40, add(memOffset, 32))
             revert(memOffset, 32)
        }
    }

    function check(address token) external returns(uint) {
        testResults[token] = 1;  // make the least bit equal to 1 to point out tests were run
        bytes memory payload = abi.encodeWithSignature("runTests(address,address)", token, msg.sender);
        Callable.CallResult memory callResult = address(this).makeCall(payload);
        if (callResult.data.length != 32) {
            return 1;
        }
        uint testsPassed = abi.decode(callResult.data, (uint));
        if (testsPassed <= 1) {
            return 1;
        }
        testResults[token] = testsPassed;
        return testsPassed;
    }
}