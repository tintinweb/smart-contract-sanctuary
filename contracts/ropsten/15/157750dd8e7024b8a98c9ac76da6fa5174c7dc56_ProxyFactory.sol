/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-28
*/

pragma solidity >=0.6.0 <0.7.0;


library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint256(_data));
    }
}


contract ProxyFactory {
    event ProxyCreated(address minimalProxy);

    mapping(address => address) public registry;

    function computeAddress(uint256 salt, address implementation)
        public
        view
        returns (address)
    {
        return
            Create2.computeAddress(
                keccak256(abi.encodePacked(salt)),
                keccak256(getContractCreationCode(implementation)),
                address(this)
            );
    }

    function deploy(
        uint256 salt,
        address implementation
    ) public {
        address minimalProxy = Create2.deploy(
            0,
            keccak256(abi.encodePacked(salt)),
            getContractCreationCode(implementation)
        );
        registry[msg.sender] = minimalProxy;
        require(address(this) != address(0), "invalid address");
        address payable wallet = address(uint160(minimalProxy));
        MinimalProxy(wallet).authorize(
            address(this),
            msg.sender
        );
        emit ProxyCreated(minimalProxy);
    }

    function getContractCreationCode(address logic)
        internal
        pure
        returns (bytes memory)
    {
        bytes10 creation = 0x3d602d80600a3d3981f3;
        bytes10 prefix = 0x363d3d373d3d3d363d73;
        bytes20 targetBytes = bytes20(logic);
        bytes15 suffix = 0x5af43d82803e903d91602b57fd5bf3;
        return abi.encodePacked(creation, prefix, targetBytes, suffix);
    }
}

contract ProxyStorage {
    // wallet owner address
    address public owner;
}

contract MinimalProxy is
    ProxyStorage
{
    // Transaction Executed event
    event Executed(bool status);

    modifier onlyProxyOwner {
        require(msg.sender == owner, "MinimalProxy: Not Owner");
        _;
    }

    function authorize(
        address _factory,
        address _owner
    ) external {
        require(
            ProxyFactory(_factory).registry(_owner) == address(this),
            "Unauthorized Execution"
        );
        owner = _owner;
    }


    function isContract(address _target) internal view returns(bool) {
      uint32 size;
      assembly {
        size := extcodesize(_target)
      }
      return (size > 0);
    }

    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes32 response)
    {
        require(_target != address(0), "Invalid Address");
        require(msg.sender == owner, "Unauthorized Execution");
        require(isContract(_target), "Target is not a Contract");
        // call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                32
            )
            response := mload(0) // load delegatecall output
            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    revert(0, 0)
                }
        }
        // if delegation successful
        emit Executed(true);
    }
}