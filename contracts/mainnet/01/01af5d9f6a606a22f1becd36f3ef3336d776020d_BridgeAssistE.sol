/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract BridgeAssistE {
    
    struct Bridge {
        uint256 amount;
        uint256 nonce;
    }
    
    address public owner;
    IERC20 public TKN = IERC20(0x3873965e73d9A21F88e645ce40B7db187FDE4931);
    string name = "Plethori";
    string version = "1";
    uint256 chainId;
    address verifyingContract;
    bytes32 salt;
    bytes32 DOMAIN_SEPARATOR;
    
    mapping(address => uint) public nonces;
    
    constructor() {
        owner = msg.sender;
        uint _chainId;
        assembly {
            _chainId := chainid()
        }
        chainId = _chainId;
        verifyingContract = address(this);
        salt = keccak256(abi.encode(block.timestamp, verifyingContract));
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            verifyingContract,
            salt
        ));
    }
    
    
    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
    
    event Collect(address indexed sender, uint256 amount);
    event Dispense(address indexed sender, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);
    
    function hashBridge(uint256 _amount, uint256 _nonce) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
           DOMAIN_SEPARATOR,
           keccak256(abi.encode(
                keccak256("Bridge(uint256 amount,uint256 nonce)"),
                _amount,
                _nonce
            ))
        ));
    }
    
    function collect(address _sender, uint256 _amount, uint256 _nonce, bytes32 sigR, bytes32 sigS, uint8 sigV ) external restricted returns (bool success) {
        require(verify(_sender, _amount, _nonce, sigR, sigS, sigV ), "Wrong Metamask sign!");
        require(TKN.transferFrom(_sender, address(this), _amount), "transferFrom() failure. Make sure that your balance is not lower than the allowance you set");
        nonceIncrement(_sender);
        emit Collect(_sender, _amount);
        return true;
    }

    function dispense(address _sender, uint256 _amount) external restricted returns (bool success) {
        require(TKN.transfer(_sender, _amount), "transfer() failure. Contact contract owner");
        emit Dispense(_sender, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) external restricted {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }
    
    function getInfo(address _user) external view returns(uint256, uint256, uint256){
        require(_user != address(0), "Invalid address!");
        return (TKN.balanceOf(_user), TKN.allowance(_user, address(this)), nonces[_user]);
    }
    
    function verify(address signer, uint256 _amount, uint256 _nonce, bytes32 sigR, bytes32 sigS, uint8 sigV) public view returns (bool) {
        require(_nonce == nonces[signer], "Wrong nonce!");
        return signer == ecrecover(hashBridge(_amount, _nonce), sigV, sigR, sigS);
    }
    
    function DOMAIN_INFO() external view returns (string memory, string memory, uint256, address, bytes32) {
        return (name, version, chainId, verifyingContract, salt);
    }
    
    function USER_DOMAIN_INFO(address _user) external view returns (string memory, string memory, uint256, address, bytes32, uint256) {
        return (name, version, chainId, verifyingContract, salt, nonces[_user]);
    }
    
    function nonceIncrement(address signer) internal {
        nonces[signer] += 1;
    }
}