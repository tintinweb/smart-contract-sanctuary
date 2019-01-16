pragma solidity >=0.4.0 <0.6.0;

contract MainContract {

    address public owner;
    bytes32 public code = &#39;&#39;;

    constructor() public {
        owner = msg.sender;
    }

    function () external payable {

    }

    function escrow(address created_address) public returns (bool) {
        require (keccak256(at(created_address)) == code, &#39;not valid&#39;);
        created_address.transfer(address(this).balance);
        return true;
    }

    function setCode(bytes32 _code) public returns (bool) {
        require (code == &#39;&#39;);
        code = _code;
        return true;
    }

    function countCode(bytes memory code_raw) public pure returns (bytes32) {
        return keccak256(code_raw);
    }

    function at(address _addr) public view returns (bytes memory o_code) {
        assembly {
        // retrieve the size of the code, this needs assembly
        let size := extcodesize(_addr)
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        o_code := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(o_code, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }

    function testRawCodeByAddress(address created_address) public view returns(bytes memory) {
        return at(created_address);
    }

    function testCodeByAddress(address created_address) public view returns(bytes32) {
        return keccak256(at(created_address));
    }
}