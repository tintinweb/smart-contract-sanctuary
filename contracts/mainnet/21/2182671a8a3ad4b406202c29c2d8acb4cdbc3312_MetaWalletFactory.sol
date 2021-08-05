/**
 *Submitted for verification at Etherscan.io on 2020-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
    function approve(address to, uint value) external returns (bool);
}

contract MetaWallet {
    
    string public constant name = "MetaWallet";
    
    address private _owner0;
    address private _owner1;
    
    address private _pendingOwner0;
    address private _pendingOwner1;
    
    constructor(address owner0, address owner1) public {
        _owner0 = owner0;
        _owner1 = owner1;
    }
    
    // @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the execute struct used by the contract
    bytes32 public constant EXECUTE_TYPEHASH = keccak256("Execute(address to,uint value,bytes data,uint nonces,uint deadline)");

    /// @notice The EIP-712 typehash for the send struct used by the contract
    bytes32 public constant SEND_TYPEHASH = keccak256("Send(address to,uint value,uint nonces,uint deadline)");

    /// @notice The EIP-712 typehash for the transfer struct used by the contract
    bytes32 public constant TRANSFER_TYPEHASH = keccak256("Transfer(address token,address to,uint value,uint nonces,uint deadline)");

    /// @notice The EIP-712 typehash for the approve struct used by the contract
    bytes32 public constant APPROVE_TYPEHASH = keccak256("Approve(address token,address to,uint value,uint nonces,uint deadline)");
    
    function transferOwnership(address _newOwner) external {
        require(msg.sender == _owner0 || msg.sender == _owner1, "MetaWallet::transferOwnership: !owner");
        if (msg.sender == _owner0) {
            _pendingOwner0 = _newOwner;
        } else if (msg.sender == _owner1) {
            _pendingOwner1 = _newOwner;
        }
    }
    
    function acceptOwnership() external {
        require(msg.sender == _pendingOwner0 || msg.sender == _pendingOwner1, "MetaWallet::acceptOwnership: !pendingOwner");
        if (msg.sender == _pendingOwner0) {
            _owner0 = _pendingOwner0;
        } else if (msg.sender == _pendingOwner1) {
            _owner1 = _pendingOwner1;
        }
    }
    
    /// @notice A record of states for signing / validating signatures
    uint public nonces;
    
    fallback() external {}
    
    function send(address payable to, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool, bytes memory) {
        require(_verify(keccak256(abi.encode(SEND_TYPEHASH, to, value, nonces++, deadline)), deadline, v, r, s));
        return to.call{value: value}("");
    }
    
    function transfer(address token, address to, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) internal returns (bool) {
        require(_verify(keccak256(abi.encode(TRANSFER_TYPEHASH, token, to, value, nonces++, deadline)), deadline, v, r, s));
        return IERC20(token).transfer(to, value);
    }
    
    function approve(address token, address to, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) internal returns (bool) {
        require(_verify(keccak256(abi.encode(APPROVE_TYPEHASH, token, to, value, nonces++, deadline)), deadline, v, r, s));
        return IERC20(token).approve(to, value);
    }
    
    function _verify(bytes32 structHash, uint deadline, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainId(), address(this)));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        return ((signatory == _owner0 || signatory == _owner1) && now <= deadline);
    }
    
    struct stack {
        address recipients;
        uint values;
        bytes datas;
        uint deadlines; 
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    
    function batch(stack[] calldata stacks) external returns (bool[] memory results, bytes[] memory responses) {
        for (uint i = 0; i < stacks.length; i++) {
            (results[i], responses[i]) = _exec(stacks[i].recipients, stacks[i].values, stacks[i].datas, stacks[i].deadlines, stacks[i].v, stacks[i].r, stacks[i].s);
        }
    }
    
    function execute(address to, uint value, bytes calldata data, uint deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool, bytes memory) {
        return _exec(to, value, data, deadline, v, r, s);
    }
    
    function _exec(address to, uint value, bytes memory data, uint deadline, uint8 v, bytes32 r, bytes32 s) internal returns (bool, bytes memory) {
        require(_verify(keccak256(abi.encode(EXECUTE_TYPEHASH, to, value, data, nonces++, deadline)), deadline, v, r, s));
        return to.call{value: value}(data);
    }
    
    function _getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

contract MetaWalletFactory {
    
    struct stack {
        address wallet;
        address to;
        uint value;
        bytes data;
        uint deadline; 
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    
    struct id {
        uint index0;
        address owner0;
        uint index1;
        address owner1;
    }
    
    mapping(address => address[]) public lookups;
    mapping(address => id) public indexes;
    
    function lookup(address wallet) external view returns (uint index0, address owner0, uint index1, address owner1) {
        return (indexes[wallet].index0, indexes[wallet].owner0, indexes[wallet].index1, indexes[wallet].owner1);
    }
    
    function wallet(address owner, uint index) external view returns (address) {
        return lookups[owner][index];
    }
    
    function wallets(address owner) external view returns (address[] memory) {
        return lookups[owner];
    }
    
    function createWallet(address _owner0, address _owner1) external {
        address _wallet = address(new MetaWallet(_owner0, _owner1));
        indexes[_wallet] = id(lookups[_owner0].length, _owner0, lookups[_owner1].length, _owner1);
        lookups[_owner0].push(_wallet);
        lookups[_owner1].push(_wallet);
        
    }
    
    function batch(stack[] calldata stacks) external returns (bool[] memory results, bytes[] memory responses) {
        for (uint i = 0; i < stacks.length; i++) {
            (results[i], responses[i]) = MetaWallet(stacks[i].wallet).execute(stacks[i].to, stacks[i].value, stacks[i].data, stacks[i].deadline, stacks[i].v, stacks[i].r, stacks[i].s);
        }
    }
}