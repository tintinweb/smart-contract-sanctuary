pragma solidity >=0.4.22 <0.7.0;
    
import "./Owner.sol";
import "./SafeMath.sol"; 
import "./RSAProofFactory.sol";
//import "./VRF.sol";
//import "./EllipticCurve.sol";
//import "./BytesLib.sol";
    
/** @title A simulator for coin flips between two parties
  * @author Peter Allemann
  * @notice This contract aims to simulate a bet on a coin flip between the owner of the contract and another party.
  * @dev Bet limits and betRewardFactorInPercent should be adjusted according to ones own needs.
  */
contract CoinFlipperV2 is Owner {
        
    using SafeMath for uint256;
            
        uint256[2] private publicKey;
        /// Will extend the alphastring to prevent replay attacks
        uint256 private betCounter = 0;
        bytes private extendedAlphaString;

        /// Adjustable
        uint256 private betUpperLimit = 1 ether;
        /// Adjustable
        uint256 private betLowerLimit = 0.00001 ether;
        /// Should be lower than 200 in order to incentivice the owner to resolve bets. Resolving bets costs the owner.
        uint256 private betRewardFactorInPercent = 195;
        uint256 private commitBlockNmbr;
        /// Adjustable, 7 blocks ~= 2 min
        uint256 private commitRevealDelay = 7 ;
        /// Adjustable, 420 blocks ~= 120 min
        uint256 private commitResolveDelay = 420;

        struct Bet {
          address payable playerAddress;
          uint256 betAmount;
          bytes32 betCommit;
        }

        Bet private currentBet;

        enum Stage {
          Setup,
          Commit,
          Reveal,
          Resolve
        }

        Stage private stage = Stage.Setup;

        event Commit(address playerAddress, uint256 betAmount);
        event Reveal(address playerAddress, bytes extendedAlphaString);
        event Resolve(address playerAddress);

        /** @author Peter Allemann
          * @notice The owner of the contract has to set the public key accoring to his chosen secret key.
          * @dev If a wrong (not corresponding to the chosen secret key) is set, the contract and its Ether-balance are at risk of becomming inaccessible.
          * @param _pkModulus is the modulus of the public key (RSA)
          * @param _pkExponent is the public exponent of the public key (RSA)
          */
        function setPublicKey(uint256 _pkModulus, uint256 _pkExponent) external isOwner {
            require(Stage.Setup == stage || Stage.Commit == stage, "Ongoing bet in progress.");
            
            publicKey[0] = _pkModulus;
            publicKey[1] = _pkExponent;

            stage = Stage.Commit;
        }
        
        /** @author Peter Allemann
          * @notice Allows a party to participate in the next bet.
          * @param _betCommit is a commit to the betters part of the seed used to generate pseudorandomness.
          * The _betCommit has to be obtained by calculating Keccak256(_alphaString).
          */
        function commitBet(bytes32 _betCommit) external payable {
            require(Stage.Setup != stage, "Public key has not been set yet.");
            require(betUpperLimit >= msg.value, "Bet surpasses upper limit for allowed bets.");
            require(betLowerLimit <= msg.value, "Bet is below lower limit for allowed bets.");
            require(betRewardFactorInPercent*msg.value/100 <= address(this).balance, "Not enough funds to reward a winning bet.");
            require(Stage.Commit == stage, "Ongoing bet in progress.");

            currentBet = Bet(msg.sender, msg.value, _betCommit);
            commitBlockNmbr = block.number;

            stage = Stage.Reveal;
            emit Commit(currentBet.playerAddress, currentBet.betAmount);
        }

        /** @author Peter Allemann
          * @notice Once a player has commited to a bet and the required amount of blocks have been minded, he can reveal his alpha-string.
          * The delay is necessary in order to prevent the contract owner from taking measures not to include a commit in the blockchain (censoring).
          * It is in the Betters own interest not to send the _alphaString to the network before the commitRevealDelay has been passed.
          * @param _alphaString is the alphastring which is to be used in the VRF and from which the commit (Keccak256(_alphaString) has been created.
          */
        function revealBet(bytes calldata _alphaString) external {
          require(Stage.Reveal == stage, "No bet has been commited yet.");
          require(block.number >= commitBlockNmbr + commitRevealDelay, "Not enough blocks have been mined since the bet has been placed.");
          require(keccak256(_alphaString) == currentBet.betCommit, "Keccak(_alphaString) does not match betCommit.");

          setExtendedAlphaString(_alphaString);

          stage = Stage.Resolve;
          emit Reveal(currentBet.playerAddress, extendedAlphaString);
        }
        
        /** @author Peter Allemann
          * @notice Extends the seed of the better with a counting integer in order to prevent replaying the same seed.
          * @dev Overflow in a counting integer should not be an issue as long as only 1 is added with each bet (uint256).
          * @param _alphaString is the alpha-string provided by the Better.
          */
        function setExtendedAlphaString(bytes memory _alphaString) private {
            betCounter = betCounter.add(1);
            extendedAlphaString = abi.encodePacked(betCounter, _alphaString);
        }

        /** @author Peter Allemann
          * @notice Allows the owner of the contract to resolve the bet, once it has been placed.
          * @dev If the owner does not resolve an ongoing bet, his and the betters balance become locked and the contract does not provide any functionality until the bet gets resolved. This should incentivice the owner to resolve bets even if he is about to lose.
          * @param _proof is the proof created from the extended alpha-string provided by the better and the secret key from the owner using the _SECP256K1_SHA256_TAI_ cipher suite (SHA256 and Secp256k1).
          */
        function resolveBet(bytes calldata _proof) external isOwner {
            require(Stage.Resolve == stage, "There is no bet going on at the moment.");
//            uint256[4] memory proof = VRF.decodeProof(_proof);
//            require(VRF.verify(publicKey, proof, extendedAlphaString), "Provided proof is invalid.");
            require(RSAProofFactory.verifyProof(publicKey, extendedAlphaString, _proof), "Provided proof is invalid.");
            
            /// proof[0], and proof[1] are x,y-coordinates of the gamma point.
//            if(0 == uint256(VRF.gammaToHash(proof[0], proof[1])) % 2) {
            if(0 == uint256(RSAProofFactory.proofToHash(_proof)) % 2) {
                currentBet.playerAddress.transfer(betRewardFactorInPercent*currentBet.betAmount/100);
            }

            /// This should be released manually with a separate function in order to give the owner a guaranteed window in which he is able to withdraw funds.
            stage = Stage.Commit;
            emit Resolve(currentBet.playerAddress);
        }
        
        /** @author Peter Allemann
          * @notice Returns the complete alpha-string for the currently ongoing bet or the last played bet.
          * @return extendedAlphaString is the alpha-string for the currently ongoing bet or the last played bet.
          */
        function getAlpha() external view returns (bytes memory) {
            return extendedAlphaString;
        }
        
        /** @author Peter Allemann
          * @notice Allows the contract to receive Ether from which future winning bets will be rewarded.
          */
        function receiveEther() external payable {}
    
        /** @author Peter Allemann
          * @notice Allows the owner of the contract to withdraw his funds from the contract.
          * @dev Can only be called if there are no bets currently in place (i.e. all bets are already resolved) to prevent the owner from withdrawing funds in case he is about to lose on the next bet.
          * @param _withdrawAmount specifies the amount of wei the owner wants to withdraw from the contract.
          */
        function withdraw(uint _withdrawAmount) external isOwner {
            require(Stage.Commit == stage, "Ongoing bet in progress.");
            require(_withdrawAmount <= address(this).balance, "Withdraw amount greater than current balance.");
            
            msg.sender.transfer(_withdrawAmount);
        }
    
        /** @author Peter Allemann
          * @notice Allows to read the current amount of Wei that is owned by the contract which is also defines the upper limit for placable bets.
          * @return balance is the current amount of wei that is owned by the contract.
          */
        function getBalance() public view returns(uint) {
            return address(this).balance;
        }
}

pragma solidity >=0.4.22 <0.7.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

pragma solidity >=0.4.22 <0.7.0;
    
import "./SafeMath.sol"; 

/** @title A contract that allows to create and verify RSA based VRF proofs.
  * @author Peter Allemann
  * @notice This contract allows to create and verify RSA based VRF proofs as well as to derive pseudorandomness from such proofs.
  */
library RSAProofFactory {
        
  using SafeMath for uint256;
    
  /** @author Peter Allemann
    * @notice Creates a RSA-VRF-proof from a secret key and an alphastring. Secret keys should never be sent over a live network. Only use this function on a local testnetwork.
    * @dev The only reason this function remains in the contract is for testing purposes.
    * @param _K is the secret key used to generate the proof. _K[0] is the modulus. _K[1] is the secret exponent.
    * @param _alphaString is an arbitrarily choosen byte string that serves as part of the seed for the VRF.
    */
  function createProof(uint256[2] memory _K, bytes memory _alphaString) public view returns (bytes memory) {
    // 1.
    bytes memory oneString = I2OSP(1, 1);

    // 2.
    uint256 k = deriveK(_K[0]);
    bytes memory EM = MGF1(abi.encodePacked(oneString, I2OSP(k, 4), I2OSP(_K[0], k), _alphaString), k - 1);

    // 3.
    uint256 m = OS2IP(EM);

    // 4.
    uint256 s = RSASP1(_K, m);

    // 5.
    bytes memory piString = I2OSP(s, k);

    // 6.
    return piString;
  }

  /** @author Peter Allemann
    * @notice Derives pseudorandomness from the generated proof via use of SHA-256.
    * @param _piString is the RSA-VRF-proof.
    * @return betaString is the provided pseudorandomness.
    */
  function proofToHash(bytes memory _piString) public pure returns (bytes32) {

    // 1.
    bytes memory twoString = I2OSP(2, 1);

    // 2.
    bytes32 betaString = sha256(abi.encodePacked(twoString, _piString));

    // 3.
    return betaString;
  }

  /** @author Peter Allemann
    * @notice Verifies whether a provided proof was indeed generated with the correct secret key.
    * @param _publicKey is the public key corresponding to the secret key used to form the proof (_piString).
    * _publicKey[0] is the modulus. _publicKey[1] is the public exponent.
    * @param _alphaString is part of the seed that was used in order to generate the proof (_piString).
    * @param _piString is the proof that was generated from the secret key and the _alphaString.
    * @return Returns True if the provided proof (_piString) was generated in a sound manner, False otherwise.
    */
  function verifyProof(uint256[2] memory _publicKey, bytes memory _alphaString, bytes memory _piString) public view returns (bool) {

    // 1.
    uint256 s = OS2IP(_piString);

    // 2.
    uint256 m = RSAVP1(_publicKey, s);

    // 3.
    uint256 k = deriveK(_publicKey[0]);
    bytes memory EM = I2OSP(m, k - 1);

    // 4.
    bytes memory oneString = I2OSP(1, 1);

    // 5.
    bytes memory EM2 = MGF1(abi.encodePacked(oneString, I2OSP(k, 4), I2OSP(_publicKey[0], k), _alphaString), k - 1);

    // 6.
    return keccak256(EM) == keccak256(EM2);
  }

  /** @author Peter Allemann
    * @notice Produces an octet string of a desired length from an integer.
    * @param _x is the integer which is to be converted into an octet string.
    * @param _xLen is the desired length of the octet string.
    * @return octetString is the converted integer in octet string form.
    */
  function I2OSP(uint256 _x, uint256 _xLen) public pure returns (bytes memory) {
    require(32 >= _xLen, "_xLen too large.");

    // 1.
    if ( 32 == _xLen) {
      require(115792089237316195423570985008687907853269984665640564039457584007913129639935 >= _x, "integer too large");
    } else {
      require((256**_xLen) > _x, "integer too large");
    }

    // 2.
    bytes memory intAsBytes = abi.encodePacked(_x);

    // 3.
    bytes memory octetString;
    for(uint i=32-_xLen; i<32; i++) {
      octetString = abi.encodePacked(octetString, intAsBytes[i]);
    }

    return octetString;
  }

  /** @author Peter Allemann
    * @notice Derives the length of the RSA modulus in octets.
    * @param _modulus is the RSA modulus.
    * @return The lengh of the RSA modulus in octets.
    */
  function deriveK(uint256 _modulus) public pure returns (uint256) {
    for(uint i=0; i<32; i++) {
      if(2**(i*8) > _modulus) { return i; }
    }
    return 32;
  }

  /** @author Peter Allemann
    * @notice Mask generation function.
    * @dev It is assumed, that sha256 is used as hash function.
    * @param _mgfSeed will be used as part of the seed for the SHA-256 function.
    * @param _maskLen defines the desired output length of the octet string.
    * @return An octet string with the desired octet length of _maskLen.
    */
  // Assuming sha256 is used as Hash
  function MGF1(bytes memory _mgfSeed, uint256 _maskLen) public pure returns (bytes memory) {
    uint256 hLen = 32; // sha256 hLen

    // 1.
    require(_maskLen <= (2**32)*hLen, "mask too long");

    // 2.
    bytes memory T;

    // 3.
    uint256 upperLimit = ceil(_maskLen, hLen);
    uint256 i=0;
    bytes memory c;
    do {
      c = I2OSP(i, 4);
      T = abi.encodePacked(T, sha256(abi.encodePacked(_mgfSeed, c)));
      i++;
    } while(i < upperLimit);

    // 4.
    return leadingOctets(_maskLen, T);
  }

  /** @author Peter Allemann
    * @notice Helper function. Divides two numbers and rounds up the result to the next integer.
    * @param _num is the numerator.
    * @param _denum is the denumerator.
    * @return Returns _num divided by _denum rounded up to the next integer.
    */
  function ceil(uint256 _num, uint256 _denum) public pure returns (uint256) {
    require(0 != _denum, "_denum must not be zero");
    return ((_num + _denum - 1) / _denum);
  }

  /** @author Peter Allemann
    * @notice Will return the first few octets of an octet string.
    * @param _nmbr specifies the amount of octets that should be returned.
    * @param _octetString is the octet string from which the first few octets will come.
    * @return firstOctets is the octet string containing the first _nmbr of octets from _octetString.
    */
  function leadingOctets(uint256 _nmbr, bytes memory _octetString) public pure returns (bytes memory) {
    require(_octetString.length >= _nmbr, "Cannot return more _nmbr of octets than _octetString contains");

    bytes memory firstOctets;
    for(uint i=0; i<_nmbr; i++) {
      firstOctets = abi.encodePacked(firstOctets, _octetString[i]);
    }
    return firstOctets;
  }

  /** @author Peter Allemann
    * @notice Converts an octet string to a non-negative integer.
    * @param _octetString is the octet string that is to be converted.
    * @return The octet string in form of an integer.
    */
  function OS2IP(bytes memory _octetString) public pure returns (uint256) {
    require(32 >= _octetString.length, "_octetString must be no longer than 32 octets.");

    // 1. & 2.
    bytes32 octetString32;
    uint256 lengthDifference = 32 - _octetString.length;
    for(uint i=0; i<_octetString.length; i++) {
      octetString32 |= bytes32(_octetString[i] & 0xFF) >> ((i + lengthDifference)  * 8);
    }

    // 3.
    return uint256(octetString32);
  }

  /** @author Peter Allemann
    * @notice RSA signature primitive. Given a secret key and an input, it raises the input to the secret RSA exponent modulo n.
    * @param _K is the secret RSA key.
    * @param _m is the input.
    * @return Returns _m raised to the secret RSA exponent modulo n.
    */
  function RSASP1(uint256[2] memory _K, uint256 _m) public view returns (uint256) {
    // 1.
    require(_m < _K[0], "message representative out of range");

    // 2.
    uint256 s = modularExp(_m, _K[1], _K[0]);

    // 3.
    return s;
  }

  /** @author Peter Allemann
    * @notice RSA verification primitive. Given a public key an an input, raises the input to the public RSA exponent modulo n.
    * @param _K is the secret RSA key.
    * @param _s is the input.
    * @return Returns _s raised to the secret RSA exponent modulo n.
    */
  function RSAVP1(uint256[2] memory _K, uint256 _s) public view returns (uint256) {

    // 1.
    require(_s < _K[0], "signature representative out of range");

    // 2.
    uint256 m = modularExp(_s, _K[1], _K[0]);

    // 3.
    return m;
  }

  /** @author Peter Allemann
    * @notice Calculates x^e%m in assembly for efficiency reasons.
    * @param base is the base (x in x^e%m)
    * @param e is the exponent (e in x^e%m)
    * @param m is the modulus (m in x^e%m)
    * @return o is base raised to the power of e modulus m.
    */
  function modularExp(uint base, uint e, uint m) public view returns (uint o) {
    assembly {
      // define pointer
      let p := mload(0x40)
      // store data assembly-favouring ways
      mstore(p, 0x20)             // Length of Base
      mstore(add(p, 0x20), 0x20)  // Length of Exponent
      mstore(add(p, 0x40), 0x20)  // Length of Modulus
      mstore(add(p, 0x60), base)  // Base
      mstore(add(p, 0x80), e)     // Exponent
      mstore(add(p, 0xa0), m)     // Modulus
      //if iszero(staticcall(sub(gas, 2000), 0x05, p, 0xc0, p, 0x20)) {
      if iszero(staticcall(not(0), 0x05, p, 0xc0, p, 0x20)) {
        revert(0, 0)
      }
      // data
      o := mload(p)
      }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/contracts/RSAProofFactory.sol": {
      "RSAProofFactory": "0x2Ba47D11858e785e225E01ed47b2635734Ea9070"
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}