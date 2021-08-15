/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

contract ContractFactory {

    event ContractDeployed(address callerAddress, address contractAddress);

    address public owner;
    uint256 public fee;

    constructor() {
        owner = msg.sender;
        fee = 0.01 ether;
    }

    function setOwner(address _to) public {
        require(owner == msg.sender, 'Not owner');
        require(_to != address(0), 'Zero address');
        owner = _to;
    }

    function setFee(uint256 _fee) public {
        require(owner == msg.sender, 'Not owner');
        fee = _fee;
    }

    function withdrawFee(address payable _to) public {
        require(owner == msg.sender, 'Not owner');
        require(_to != address(0), 'Zero address');
        _to.transfer(address(this).balance);
    }

    /**
     * deploy contract by salt, contract bytecode.
     */
    function deployContract(bytes32 salt, bytes memory contractBytecode) public payable {
        require(msg.value == fee, 'Invalid fee');
        address addr;
        assembly {
            addr := create2(0, add(contractBytecode, 0x20), mload(contractBytecode), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed(msg.sender, addr);
    }

    /**
     * deploy contract by salt, contract bytecode and constructor args.
     */
    function deployContractWithConstructor(bytes32 salt, bytes memory contractBytecode, bytes memory constructorArgs) public payable {
        require(msg.value == fee, 'Invalid fee');
        // deploy contracts with constructor (address):
        bytes memory payload = abi.encodePacked(contractBytecode, constructorArgs);
        address addr;
        assembly {
            addr := create2(0, add(payload, 0x20), mload(payload), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed(msg.sender, addr);
    }
}