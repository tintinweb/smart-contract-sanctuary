pragma solidity ^0.6.0;


// The Reentrancy Checker causes failures if it is successfully able to re-enter a contract.
// How to use:
// 1. Call setTransactionData with the transaction data you want the Reentrancy Checker to reenter the calling
//    contract with.
// 2. Get the calling contract to call into the reentrancy checker with any call. The fallback function will receive
//    this call and reenter the contract with the transaction data provided in 1. If that reentrancy call does not
//    revert, then the reentrancy checker reverts the initial call, likely causeing the entire transaction to revert.
//
// Note: the reentrancy checker has a guard to prevent an infinite cycle of reentrancy. Inifinite cycles will run out
// of gas in all cases, potentially causing a revert when the contract is adequately protected from reentrancy.
contract ReentrancyChecker {
    bytes public txnData;
    bool hasBeenCalled;

    // Used to prevent infinite cycles where the reentrancy is cycled forever.
    modifier skipIfReentered {
        if (hasBeenCalled) {
            return;
        }
        hasBeenCalled = true;
        _;
        hasBeenCalled = false;
    }

    function setTransactionData(bytes memory _txnData) public {
        txnData = _txnData;
    }

    function _executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) private returns (bool success) {
        // Mostly copied from:
        // solhint-disable-next-line max-line-length
        // https://github.com/gnosis/safe-contracts/blob/59cfdaebcd8b87a0a32f87b50fead092c10d3a05/contracts/base/Executor.sol#L23-L31
        // solhint-disable-next-line no-inline-assembly

        assembly {
            let inputData := add(data, 0x20)
            let inputDataSize := mload(data)
            success := call(gas(), to, value, inputData, inputDataSize, 0, 0)
        }
    }

    fallback() external skipIfReentered {
        // Attampt to re-enter with the set txnData.
        bool success = _executeCall(msg.sender, 0, txnData);

        // Fail if the call succeeds because that means the re-entrancy was successful.
        require(!success, "Re-entrancy was successful");
    }
}
