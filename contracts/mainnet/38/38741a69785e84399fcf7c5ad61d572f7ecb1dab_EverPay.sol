/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma abicoder v2;

contract EverPay {
    // Event
    event Submission(
        bytes32 indexed id,
        uint256 indexed proposalID,
        bytes32 indexed everHash,
        address owner,
        address to,
        uint256 value,
        bytes data
    );
    event SubmissionFailure(
        bytes32 indexed id,
        uint256 indexed proposalID,
        bytes32 indexed everHash,
        address owner,
        address to,
        uint256 value,
        bytes data
    );
    event Execution(
        bytes32 indexed id,
        uint256 indexed proposalID,
        bytes32 indexed everHash,
        address to,
        uint256 value,
        bytes data
    );
    event ExecutionFailure(
        bytes32 indexed id,
        uint256 indexed proposalID,
        bytes32 indexed everHash,
        address to,
        uint256 value,
        bytes data
    );
    // event Revocation(address indexed sender, bytes32 indexed id); // TODO
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    event OperatorChange(address indexed operator);
    event PausedChange(bool paused);
    // Event End

    // Storage & Struct
    uint256 public chainID;
    bool public paused;
    address public operator;
    uint256 public required;
    address[] public owners;
    mapping(address => bool) public isOwner;

    mapping(bytes32 => bool) public executed;// tx id => bool
    mapping(bytes32 => mapping(address => bool)) public confirmations;
    // Storage & Struct End

    // Modifier
    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount >= _required && ownerCount != 0 && _required != 0,
            "invalid_required"
        );
        _;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this), "not_wallet");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "not_operator");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    // Modifier End

    // Manage
    function getPaused() public view returns (bool) {
        return paused;
    }

    function getOperator() public view returns (address) {
        return operator;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getRequire() public view returns (uint256) {
        return required;
    }

    function setOperator(address _operator) public onlyWallet {
        require(_operator != address(0), "null_address");

        operator = _operator;

        emit OperatorChange(operator);
    }

    function setPaused(bool _paused) public onlyOperator {
        paused = _paused;

        emit PausedChange(paused);
    }

    function addOwner(address owner) public onlyWallet {
        require(owner != address(0), "null_address");

        isOwner[owner] = true;
        owners.push(owner);

        emit OwnerAddition(owner);
    }

    function removeOwner(address owner) public onlyWallet {
        require(isOwner[owner], "no_owner_found");

        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();

        if (required > owners.length) {
            changeRequirement(owners.length);
        }

        OwnerRemoval(owner);
    }

    function replaceOwner(address owner, address newOwner) public onlyWallet {
        require(isOwner[owner], "no_owner_found");
        require(newOwner != address(0), "null_address");

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;

        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

    function changeRequirement(uint256 _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    // Manage End

    // Base
    receive() external payable {
        if (msg.value != 0) emit Deposit(msg.sender, msg.value);
    }

    constructor(address[] memory _owners, uint256 _required) validRequirement(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }

        owners = _owners;
        required = _required;

        uint256 _chainID;
        assembly {
            _chainID := chainid()
        }
        chainID = _chainID;
    }

    function submit(
        uint256 proposalID, // ar tx id
        bytes32 everHash,
        address to,
        uint256 value,
        bytes memory data,
        bytes[] memory sigs
    ) public whenNotPaused returns (bytes32, bool) {
        bytes32 id = txHash(proposalID, everHash, to, value, data);
        require(!executed[id], "tx_executed");

        for (uint256 i = 0; i < sigs.length; i++) {
            address owner = ecAddress(id, sigs[i]);
            if (!isOwner[owner]) {
                emit SubmissionFailure(id, proposalID, everHash, owner, to, value, data);
                continue;
            }

            confirmations[id][owner] = true;
            emit Submission(id, proposalID, everHash, owner, to, value, data);
        }

        if (!isConfirmed(id)) return (id, false);
        executed[id] = true;

        (bool ok, ) = to.call{value: value}(data);
        if (ok) {
            emit Execution(id, proposalID, everHash, to, value, data);
        } else {
            emit ExecutionFailure(id, proposalID, everHash, to, value, data);
        }

        return (id, true);
    }

    // execute multi calls
    function executes(address[] memory tos, uint256[] memory values, bytes[] memory datas) payable public onlyWallet {
        require(tos.length == values.length, "invalid_length");
        require(tos.length == datas.length, "invalid_length");

        for (uint256 i = 0; i < tos.length; i++) {
          (bool ok, ) = tos[i].call{value: values[i]}(datas[i]);
          require(ok, "executed_falied");
        }
    }

    function isConfirmed(bytes32 id) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[id][owners[i]]) count += 1;
            if (count >= required) return true;
        }

        return false;
    }

    // Base End

    // Utils
    function txHash(uint256 proposalID, bytes32 everHash, address to, uint256 value, bytes memory data) public view returns (bytes32) {
        return keccak256(abi.encodePacked(chainID, address(this), proposalID, everHash, to, value, data));
    }

    function ecAddress(bytes32 id, bytes memory sig)
        public
        pure
        returns (address)
    {
        require(sig.length == 65, "invalid_sig_len");

        uint8 v;
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }

        require(v == 27 || v == 28, "invalid_sig_v");

        return
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", id)
                ), v, r, s
            );
    }
    // Utils End
}