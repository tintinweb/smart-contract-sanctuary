contract Destruct {
    function go() public {
        selfdestruct(address(0x0));
    }
}

contract Test{
    
    event hash(bytes32,address);
    
    bytes32[] public arr;
    
    function getCreate2Address(bytes32 salt, bytes memory init_code, address addr) public view returns (address c2addr){
        bytes32 temp = keccak256(abi.encodePacked(bytes1(0xff), addr, salt, keccak256((init_code))));
        uint mask = (2 ** 160) - 1;
        assembly {
            c2addr := and(temp, mask)
        }

    }
    
    function getCreate2Address(bytes32 salt, bytes memory init_code) internal view returns (address) {
        return getCreate2Address(salt, init_code, address(this));
    }
    
    function ext(address target) internal returns (bytes32) {
        bytes32 targ;
        assembly {
            targ := extcodehash(target) 
        } 
        return targ;
    }
    
    function deploy(bytes memory init_code, bytes32 salt, uint value) public returns (address){
        uint length = init_code.length;
        address depl;
        assembly{
            depl := create2(value, add(init_code, 0x20), length, salt)
        }
        return depl;
    }
    
    function TestCTR() public {
        bytes memory init_code = hex&#39;6080604052348015600f57600080fd5b5060988061001e6000396000f3fe6080604052348015600f57600080fd5b50600436106045576000357c0100000000000000000000000000000000000000000000000000000000900480630f59f83a14604a575b600080fd5b60506052565b005b600073ffffffffffffffffffffffffffffffffffffffff16fffea165627a7a723058205e79b20d129418323075a1b585c45fb70c1249aed2537d8b15bca2d22149d5350029&#39;;
        address depl = getCreate2Address(bytes32("test"), init_code);
        bytes32 exthash = ext(depl);
        emit hash(exthash, depl);
        arr.push(exthash);
        deploy(init_code, bytes32("test"), 0);
        exthash = ext(depl);
        arr.push(exthash);
        emit hash(exthash, depl);
        Destruct(depl).go();
        exthash = ext(depl);
        arr.push(exthash);
        emit hash(exthash, depl);
    }
    
    
}