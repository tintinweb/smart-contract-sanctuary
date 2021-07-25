/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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

contract LiquidlyMining is Context, Ownable {

    mapping (address => uint) public balanceOf;

    struct UserDeopsit {
        uint256 tokenBalanceOf;
        uint256 lastRewardTime;
        uint256 everyDrop;
    }

    mapping (address => UserDeopsit) public usersToken;

    address public admin;
    IERC20 public token;
    uint private space = 60 * 60 * 24; 
    // uint private space = 1; 

    constructor(address _token) {
        admin = msg.sender;
        token = IERC20(_token);
    }

    receive() external payable {
    }

    function depositHT(uint amount) public payable {
        token.transferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender] += msg.value;
        usersToken[msg.sender] = UserDeopsit({
            tokenBalanceOf: amount + usersToken[msg.sender].tokenBalanceOf,
            lastRewardTime: block.timestamp,
            everyDrop: (amount + usersToken[msg.sender].tokenBalanceOf) /100
        });
    }

    function claimReward() public {
        require(balanceOf[msg.sender] > 0);
        require(usersToken[msg.sender].tokenBalanceOf > 0);
        require(block.timestamp > usersToken[msg.sender].lastRewardTime + space);

        usersToken[msg.sender].tokenBalanceOf -= usersToken[msg.sender].everyDrop;
        usersToken[msg.sender].lastRewardTime = block.timestamp;
        token.transfer(msg.sender, usersToken[msg.sender].everyDrop);
    }

    function withdraw(uint amount, address[] memory users, uint[] memory amounts, uint nonce, bytes memory signature) external {
        require(balanceOf[msg.sender] > 0);
        require(users.length == amounts.length);
        require(verify(admin, amount, users, amounts, nonce, signature));

        balanceOf[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        for (uint256 index = 0; index < users.length; index++) {
            payable(users[index]).transfer(amounts[index]);
        }
    }

    function getMessageHash( uint amount, address[] memory users, uint[] memory amounts, uint _nonce )
        public pure returns (bytes32){
        return keccak256(abi.encodePacked(amount, users, amounts, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) private pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(
        address _signer,
        uint amount, address[] memory users, uint[] memory amounts, uint _nonce,
        bytes memory signature
    )
        private pure returns (bool)
    {
        bytes32 messageHash = getMessageHash(amount, users, amounts, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        private pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "invalid signature length");
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function setAdmin(address _admin) external onlyOwner() {
        admin = _admin;
    }

}