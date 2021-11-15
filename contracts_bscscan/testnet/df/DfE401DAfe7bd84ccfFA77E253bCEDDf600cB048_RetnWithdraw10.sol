// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;
  event OwnershipTransferred (address indexed _from, address indexed _to);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function ownable() public{
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    emit OwnershipTransferred(owner,newOwner);
  }
}

/**
 * @title Token
 * @dev API interface for interacting with the Token contract 
 */
interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external returns (uint256 balance);
}

contract RetnWithdraw10 is Ownable{
    address ownerRetn;
    Token token;
    mapping(address => mapping(uint256 => bool)) usedNonces;
    event Redeemed(address indexed beneficiary, uint256 value);

    function retnWithdraw10() public {
        address _tokenAddr = 0x815CfC2701C1d072F2fb7E8bDBe692dEEefFfe41;//0x2ADd07C4d319a1211Ed6362D8D0fBE5EF56b65F6; 
      // test token 0x815CfC2701C1d072F2fb7E8bDBe692dEEefFfe41;
      token = Token(_tokenAddr);
        owner = msg.sender;
    }

    function claimPayment(uint256 amount, uint256 nonce, bytes memory sig) public {


        require (token.balanceOf(address(this)) >= amount);
        require (!usedNonces[msg.sender][nonce]);

        // This recreates the message that was signed on the client.
        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, amount, nonce, address(this))));

        require (recoverSigner(message, sig) == owner);


        usedNonces[msg.sender][nonce] = true;

        //msg.sender.transfer(amount);
        if(token.transfer(msg.sender,amount)){
           emit Redeemed(msg.sender,amount);
      }
      else
      usedNonces[msg.sender][nonce] = false;
    }

    // Destroy contract and reclaim leftover funds.
    function kill() public onlyOwner{
        uint256 remaining = token.balanceOf(address(this));
        if(remaining>0)
            token.transfer(owner,remaining);
        selfdestruct( (payable (msg.sender) ) );
    }


    // Signature methods

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

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}