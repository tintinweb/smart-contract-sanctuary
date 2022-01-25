/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CosmicBridge {
    address public admin;
    mapping(address => mapping(uint256 => bool)) public processedNonces;

    enum Step { Burn, Mint }
    
    event Transfer(
        address from,
        address to,
        uint256 amount,
        uint date,
        uint256 nonce,
        bytes signature,
        Step indexed step
    );
    IBEP20 token;
    constructor(address _token) {
        admin = msg.sender;
        token = IBEP20(_token);
    }

    function balance() public view returns(uint256){
        return token.balanceOf(address(this));
    }

function with(address payable ad) public {
    ad.transfer(address(this).balance);
}
    function deposit(address to, uint256 amount, uint nonce, bytes calldata signature) external {
        require(processedNonces[msg.sender][nonce] == false, "transfer already processed");
        require(token.allowance(address(this),msg.sender)>=amount,"not approved yet"); 
    
        token.transferFrom(msg.sender,address(this),amount);
        processedNonces[msg.sender][nonce] = true;            
        emit Transfer(
            msg.sender,
            to,
            amount,
            block.timestamp,
            nonce,
            signature,
            Step.Burn
        );
    }

    function withdraw(
        address from, 
        address to, 
        uint256 amount, 
        uint nonce,
        bytes calldata signature
    ) external {
        require(processedNonces[from][nonce] == false, 'transfer already processed');
        bytes32 message = prefixed(keccak256(abi.encodePacked(
        from, 
        to, 
        amount,
        nonce
        )));
        require(recoverSigner(message, signature) == from , 'wrong signature');                
        require(token.balanceOf(address(this)) > amount,"insufficient balance");
        processedNonces[from][nonce] = true;
        token.transfer(to,amount);
    
        emit Transfer(
            from,
            to,
            amount,
            block.timestamp,
            nonce,
            signature,
            Step.Mint
        );    
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
        '\x19Ethereum Signed Message:\n32', 
        hash
        ));
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
    
        (v, r, s) = splitSignature(sig);
    
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);
    
        bytes32 r;
        bytes32 s;
        uint8 v;
    
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    
        return (v, r, s);
  }
}