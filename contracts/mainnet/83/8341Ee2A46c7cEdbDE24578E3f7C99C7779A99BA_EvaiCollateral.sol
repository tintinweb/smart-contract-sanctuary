/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
 
pragma solidity ^0.8.0;
 
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
 function allowance(address owner, address spender) external view returns (uint256);
 
 /**
 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
 *
 * Returns a boolean value indicating whether the operation succeeded.
 *
 * IMPORTANT: Beware that changing an allowance with this method brings the risk
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
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 
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
 
// File: contracts/EVAICollateral.sol
 
// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.3;
 
/// @title EvaiCollateral Contract
/// @notice This contract is used to lock EVAI.IO ERC20 tokens as collateral for bridged BEP20 tokens on BSC
 
contract EvaiCollateral {
 IERC20 evaiETHToken;
 address owner;
 
 mapping(address => mapping(bytes32 => bool)) public processedTransactions;
 
 event BrigeFromBEP20(uint256 _amount);
 
 constructor(address _token) {
 evaiETHToken = IERC20(_token);
 owner = msg.sender;
 }
 
 function getLockedTokens() view public returns(uint256 lockedTokens) {
 lockedTokens = evaiETHToken.balanceOf(address(this)); 
 }
 
 function bridgeFromBEP20 (bytes32 _txhash,address _from,uint256 tokens,uint256 nonce,bytes calldata signature) public {
 require(msg.sender == owner,"EvaiCollateral: Caller is not owner");
 require(tokens <= evaiETHToken.balanceOf(address(this)),"Not Enough Tokens");
 bytes32 message = prefixed(keccak256(abi.encodePacked(
 _txhash,_from,tokens,nonce)));
 require(processedTransactions[msg.sender][_txhash] == false,"Transfer already processed");
 require(recoverSigner(message,signature) == _from,"Wrong Address");
 processedTransactions[msg.sender][_txhash] = true;
 evaiETHToken.approve(address(this),tokens);
 evaiETHToken.transferFrom(address(this), _from,tokens);
 emit BrigeFromBEP20(tokens);
 }
 
 function prefixed(bytes32 hash) internal pure returns (bytes32) {
 return keccak256(abi.encodePacked(
 '\x19Ethereum Signed Message:\n32',hash
 ));
 }
 
 function recoverSigner(bytes32 message, bytes memory signature) internal pure returns(address) {
 uint8 v;
 bytes32 r;
 bytes32 s;
 
 (v,r,s) = splitSignature(signature);
 
 return ecrecover(message,v,r,s);
 
 }
 
 function splitSignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
 require(signature.length == 65,"EVAICOLLATERAL: Length should be 65");
 
 //bytes32 r;
 //bytes32 s;
 //uint8 v;
 
 assembly {
 // First 32 bytes, after the length prefix
 r := mload(add(signature,32))
 // second 32 Bytes
 s := mload(add(signature,64))
 //Final byte ( first byte of the next 32 bytes)
 v := byte(0,mload(add(signature,96)))
 }
 
 return(v,r,s);
 }
 
 
 
}