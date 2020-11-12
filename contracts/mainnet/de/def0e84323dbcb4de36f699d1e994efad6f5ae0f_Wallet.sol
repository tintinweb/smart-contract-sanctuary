// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

abstract contract MultiSig {
    mapping(address => bool) s_owners;

    address s_markedForRemoval;

    struct Action {
        address owner;
        uint256 value;
        uint256 height;
        bytes32 data;
    }

    Action public s_action;

    event MultiSigRequest(address indexed from, bytes4 indexed selector, uint256 value, bytes32 hashedData);
    event MultiSigExecute(address indexed from, bytes4 indexed selector, uint256 value, bytes32 hashedData);
    event MultiSigCancel(address indexed from);
    event MultiSigReplaceOwnerCall(address indexed by, address indexed from, address indexed to);

    constructor(address owner1, address owner2, address owner3) public {
        require(owner1 != address(0), "MultiSig: owner1 cannot be 0");
        require(owner2 != address(0), "MultiSig: owner2 cannot be 0");
        require(owner3 != address(0), "MultiSig: owner3 cannot be 0");
        require(owner1 != owner2, "MultiSig: owner1 cannot be owner2");
        require(owner2 != owner3, "MultiSig: owner2 cannot be owner3");
        require(owner1 != owner3, "MultiSig: owner1 cannot be owner3");
        s_owners[owner1] = true;
        s_owners[owner2] = true;
        s_owners[owner3] = true;
    }

    modifier multiSig2of3 (uint256 value) {
      require(s_owners[msg.sender] && msg.sender != s_markedForRemoval, 'MultiSig: only owners that are not being removed');
      bytes32 hashedData = keccak256(msg.data);
      s_action.height = block.number;
      if (s_action.owner == address(0)) {
          s_action.owner = msg.sender;
          s_action.data = hashedData;
          s_action.value = value;
          emit MultiSigRequest(msg.sender, sig(msg.data), value, hashedData);
          return;
      }
      require(s_action.owner != msg.sender, 'MultiSig: same owner cannot sign twice');
      require(s_action.value == value, 'MultiSig: must sign the same value');
      require(s_action.data == hashedData, 'MultiSig: must sign the same data');
      s_action.owner = address(0);
      emit MultiSigExecute(msg.sender, sig(msg.data), value, hashedData);
      _;
    }

    function cancel() external {
      require(s_owners[msg.sender], 'MultiSig: only owners can cancel');
      require(s_markedForRemoval != msg.sender, 'MultiSig: only owners that are not being replaced can cancel');
      s_action.owner = address(0);
      s_markedForRemoval = address(0);
      emit MultiSigCancel(msg.sender);
    }

    function replaceOwner(address owner, address newOwner) external {
      require(owner != address(0), 'MultiSig: owner cannot be 0');
      require(newOwner != address(0), 'MultiSig: new Owner cannot be 0');
      require(s_owners[owner] == true, 'MultiSig: owner must exist');
      require(owner != msg.sender, "MultiSig: senders cannot replace themselves");
      require(s_owners[newOwner] == false, 'MultiSig: new owner must not exist');
      s_markedForRemoval = owner;
      emit MultiSigReplaceOwnerCall(msg.sender, owner, newOwner);
      _replaceOwner(owner, newOwner);
    }

    function isOwner() external view returns (bool) {
      return s_owners[msg.sender];
    }

    function sig(bytes calldata data) pure public returns (bytes4) {
      if (data.length < 4) {
        return bytes4(0);
      }
      return(
        data[0] |
        (bytes4(data[1]) >> 8) |
        (bytes4(data[2]) >> 16) |
        (bytes4(data[3]) >> 24)
      );
    }

    function _replaceOwner(address owner, address newOwner)
      private
      multiSig2of3(0)
    {
      s_owners[owner] = false;
      s_owners[newOwner] = true;
      s_markedForRemoval = address(0);
    }
}

contract Wallet is MultiSig {
    address s_target;

    event Received(address indexed from, uint256 value);
    event Transfered(address indexed to, uint256 value);
    event ContractDeployed(address at);
    event ContractDeployed2(address at);

    constructor(address owner1, address owner2, address owner3)
        MultiSig(owner1, owner2, owner3)
        public
    {
    }

    receive () external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback () external multiSig2of3(0) {
        require(s_target != address(0), "Wallet: no target");

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            calldatacopy(0x00, 0x00, calldatasize())
            let res := call(
                gas(),
                sload(s_target_slot),
                0x00,
                0x00,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0x00, 0x00, returndatasize())
            if res { return(0x00, returndatasize()) }
            revert(0x00, returndatasize())
        }
    }

    function transferOwnEther_(address payable to, uint256 value)
        external
        multiSig2of3(0)
    {
        to.transfer(value);
        emit Transfered(to, value);
    }

    function deployContract_(bytes memory bytecode) external multiSig2of3(0) returns (address addr) {
        require(bytecode.length != 0, "Wallet: bytecode length is zero");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed(addr);
    }

    function deployContract2_(bytes memory bytecode, bytes32 salt) external multiSig2of3(0) returns (address addr) {
        require(bytecode.length != 0, "Wallet: bytecode length is zero");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed2(addr);
    }

    function setOwnTarget_(address target) external multiSig2of3(0) {
        s_target = target;
    }

    function getOwnTarget_() external view returns (address) {
        return s_target;
    }
}