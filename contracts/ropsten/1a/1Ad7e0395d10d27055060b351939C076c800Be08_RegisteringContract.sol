// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRegisteringContract.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract RegisteringContract is IRegisteringContract, Ownable {
	using SafeMath for uint256;
	mapping(address => UserInfo) public userInfo;
	mapping(bytes32 => NameInfo) public nameInfo;

	uint256 lockingAmount = 1e17;
	uint256 ExpireDuration = 1000;
	uint256 feePerByte = 1e9;
	
	modifier checkName(bytes32 _nameHash) {
		NameInfo storage name = nameInfo[_nameHash];
		UserInfo storage user = userInfo[_msgSender()];
		if ( name.isRegistered && block.timestamp - name.activeTime < ExpireDuration) {
			name.isActive = false;
			user.lockedAmount = user.lockedAmount.sub(lockingAmount);
		}
		_;
	}

	/* Signature Verification

	How to Sign and Verify
	# Signing
	1. Create message to sign
	2. Hash the message
	3. Sign the hash (off chain, keep your private key secret)

	# Verify
	1. Recreate hash from the original message
	2. Recover signer from signature and hash
	3. Compare recovered signer to claimed signer
	*/


	/* 1. Unlock MetaMask account
	ethereum.enable()
	*/

	/* 2. Get message hash to sign
	getNameHash(
		"coffee and donuts"
	)

	hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
	*/
	function getNameHash(
		string memory _name
	)
		public pure returns (bytes32)
	{
		return keccak256(abi.encodePacked(_name));
	}

	/* 3. Sign message hash
	# using browser
	account = "copy paste account of signer here"
	ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

	# using web3
	web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

	Signature will be different for different accounts
	0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
	*/
	function getEthSignedNameHash(bytes32 _nameHash) public pure returns (bytes32) {
		/*
		Signature is produced by signing a keccak256 hash with the following format:
		"\x19Ethereum Signed Message\n" + len(msg) + msg
		*/
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _nameHash));
	}

	/* 4. Verify signature
	signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
	message = "coffee and donuts"
	signature =
		0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
	*/
	function verify(
		address _signer,
		bytes32 _nameHash,
		bytes memory signature
	)
		public pure returns (bool)
	{
		bytes32 ethSignednameHash = getEthSignedNameHash(_nameHash);

		return recoverSigner(ethSignednameHash, signature) == _signer;
	}

	function recoverSigner(bytes32 _ethSignednameHash, bytes memory _signature)
		public pure returns (address)
	{
		(bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

		return ecrecover(_ethSignednameHash, v, r, s);
	}

	function splitSignature(bytes memory sig)
		public pure returns (bytes32 r, bytes32 s, uint8 v)
	{
		require(sig.length == 65, "invalid signature length");

		assembly {
			r := mload(add(sig, 32))
			s := mload(add(sig, 64))
			v := byte(0, mload(add(sig, 96)))
		}
	}

	function bookNameWithHash(bytes32 _nameHash) external payable checkName(_nameHash){
		NameInfo storage name = nameInfo[_nameHash];

		require(!name.isActive, "bookNameWithHash: name already registered!");
		require(msg.value >= lockingAmount + feePerByte * _nameHash.length, "bookNameWithHash: not enough");

		name.nameOwner = _msgSender();
		UserInfo storage user = userInfo[_msgSender()];
		user.amount = user.amount.add(lockingAmount);

		name.isBooked = true;
		name.isActive = true;
		name.activeTime = block.timestamp;
	}

	function registerName(string memory _name, bytes memory _signature) external checkName(getNameHash(_name)){
		NameInfo storage name = nameInfo[getNameHash(_name)];

		require(!name.isActive, "registerName: name already registered");
		require(verify(_msgSender(), getNameHash(_name), _signature), "registerName: invalid signature.");
		require(name.isBooked, "registerName: you didnt booked the name yet.");
		require(name.nameOwner == _msgSender(), "you didnt book the name");

		name.isRegistered = true;

		UserInfo storage user = userInfo[_msgSender()];
		user.lockedAmount = user.lockedAmount.add(lockingAmount);
	}

	function withdraw(uint256 amount, string memory _name) external checkName(getNameHash(_name)){
		UserInfo storage user = userInfo[_msgSender()];

		require(user.amount >= amount, "withdraw: dont have enough tokens");
		require(user.amount >= user.lockedAmount, "withdraw: dont have enough tokens");

		if (user.amount.sub(user.lockedAmount) >= amount) {
			user.amount = user.amount.sub(amount);
			(bool sent,) = _msgSender().call{value: amount}("");
			require(sent, "Failed to send Ether");
		}
	}

	function renew(string memory _name, bytes memory _signature) external payable checkName(getNameHash(_name)) {
		NameInfo storage name = nameInfo[getNameHash(_name)];
		UserInfo storage user = userInfo[_msgSender()];
		require(verify(_msgSender(), getNameHash(_name), _signature), "renew: invalid signature.");
		require(name.isBooked, "renew: you didnt book the name yet.");
		require(!name.isActive, "renew: your name still active now");
		require(user.amount.sub(user.lockedAmount).add(msg.value) >= lockingAmount ,"renew: not enough tokens");

		user.lockedAmount = user.lockedAmount.add(lockingAmount);
		user.amount = user.amount.add(msg.value);
		name.isActive = true;
		name.activeTime = block.timestamp;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IRegisteringContract {

    struct NameInfo {
        bool isRegistered;
        uint256 activeTime;
        bool isActive;
        bool isBooked;
        address nameOwner;
    }

    struct UserInfo {
        uint256 lockedAmount;
        uint256 amount;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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