/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity =0.6.12;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = 0xc47b3410c1203B8f6701642Bb84Ae8Cd1C78D82d; //TBC
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface ETFloftOld{
  function buyLoft(uint256[5] calldata numbers, uint256 times) external;
  function round() external returns (uint256);
}


contract ETFloft is Ownable{
  using SafeMath for uint256;

  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
          // Check the signature length
          if (signature.length != 65) {
              revert("ECDSA: invalid signature length");
          }

          // Divide the signature in r, s and v variables
          bytes32 r;
          bytes32 s;
          uint8 v;

          // ecrecover takes the signature parameters, and the only way to get them
          // currently is to use assembly.
          // solhint-disable-next-line no-inline-assembly
          assembly {
              r := mload(add(signature, 0x20))
              s := mload(add(signature, 0x40))
              v := byte(0, mload(add(signature, 0x60)))
          }

          return recover(hash, v, r, s);
      }
   /**
       * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
       * `r` and `s` signature fields separately.
       */
      function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
          // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
          // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
          // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
          // signatures from current libraries generate a unique signature with an s-value in the lower half order.
          //
          // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
          // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
          // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
          // these malleable signatures as well.
          require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
          require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

          // If the signature is valid (and not malleable), return the signer address
          address signer = ecrecover(hash, v, r, s);
          require(signer != address(0), "ECDSA: invalid signature");

          return signer;
      }

  address public ETFtoken  = address(0x9E101C3a19e38a02B3c2fCf0D2Be4CE62C846488); //TBC
  address public oldLoft   = address(0xa482246fFFBf92659A22525820C665D4aFfCF97B); //TBC

  mapping(address=> uint256) public claimedETF;

  function recycleETF(address to, uint256 amount) public onlyOwner{
      TransferHelper.safeTransfer(ETFtoken, to, amount);
  }

  constructor() public {
      TransferHelper.safeApprove(ETFtoken, oldLoft, uint(-1));
  }
  
  function claimETF(uint256 claim2amount, bytes32 hash, bytes memory signature) public{
      bytes memory prefix = hex"19457468657265756d205369676e6564204d6573736167653a0a3532";
      require(keccak256(abi.encodePacked(prefix, msg.sender, claim2amount))==hash);
      require(recover(hash, signature) == address(0x0009595Ee9616B3EFc1a31C3826c7dDC82E8dB2e));
      require(claim2amount>=claimedETF[msg.sender], "nothing to claim");
      uint256 amount = claim2amount.sub(claimedETF[msg.sender]);
      claimedETF[msg.sender] = claim2amount;
      TransferHelper.safeTransfer(ETFtoken, msg.sender, amount);
  }

  event newLoft(address indexed buyer, uint8[5] numbers, uint64 round, uint8 times);

  function buyLoft(uint256[5] calldata numbers, uint256 times) public{
      require (times <= 100);
      TransferHelper.safeTransferFrom(ETFtoken, msg.sender, address(this), 2 ether * times);
      uint8[5] memory num;
      for(uint i;i<5;i++){
        num[i] = uint8(numbers[i]);
      }
      emit newLoft(msg.sender, num, uint64(ETFloftOld(oldLoft).round()), uint8(times));
      ETFloftOld(oldLoft).buyLoft(numbers, times);
  }

}