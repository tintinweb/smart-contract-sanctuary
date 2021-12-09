/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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

interface ICyberWayNFT {

    function transferFrom(address from, address to, uint256 tokenId) external;

    function mint(address to, uint8 kind_, uint8 newColorFrame_, uint8 rand_) external returns(uint256);

    function burn(uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function getTokenKind(uint256 tokenId) external view returns(uint8);

    function getTokenColor(uint256 tokenId) external view returns(uint8);

    function getTokenRand(uint256 tokenId) external view returns(uint8);
}

contract Farming is Ownable{

    mapping(address => mapping(uint256 => uint256))public userInfo; //  user => (tokenId => timeToLock)

    IERC20 public cyberToken;
    ICyberWayNFT public cyberNft;

    uint256 public basicLockPeriod = 201600; //blocks -  3 sec per block / 7 days
    uint256 private _tokenPerBlock = 2e18; // 2 tokens

    event NFTDeposited(address sender, uint256 id, uint256 startBlock);
    event NFTWithdrawn(address sender, uint256 id, uint256 amount);
    event NFTEmergencyWithdrawn(address sender, uint256 id, uint256 block);
    event NFTDeposited();

    constructor(address nft, address token) {
        cyberNft = ICyberWayNFT(nft);
        cyberToken = IERC20(token);
    }


    function depositFarmingToken(uint256 id) public {
        require(userInfo[msg.sender][id] == 0, "Farming: is exist");
        cyberNft.transferFrom(msg.sender, address(this), id);
        userInfo[msg.sender][id] = block.number;
        emit NFTDeposited(msg.sender, id, userInfo[msg.sender][id]);
    }


    function withdrawFarmingToken(uint256 id) public {
        require(userInfo[msg.sender][id] + basicLockPeriod <= block.number, "Farming: incorrect period");
        require(userInfo[msg.sender][id] != 0, "Farming: Sender isn't token's owner");

        uint256 amount = pendingToken(msg.sender, id);
        userInfo[msg.sender][id] = 0;

        cyberToken.transfer(msg.sender, amount);
        cyberNft.transferFrom(address(this), msg.sender, id);
        emit NFTWithdrawn(msg.sender, id, amount);
    }


    // WARNING: don't update, when you have active farmers, you will have incorrect amount
    function setTokenPerBlock(uint256 newAmount) public onlyOwner {
        require(newAmount != 0, "Farming:");
        _tokenPerBlock = newAmount;
    }


    // WARNING: don't update, when you have active farmers, you will have incorrect amount
    function setBasicLockPeriod(uint256 newAmount) public onlyOwner {
        require(newAmount != 0, "Farming: zero amount");
        basicLockPeriod = newAmount;
    }


    function emergencyWithdrawFarmingToken(uint256 id) public {
        require(userInfo[msg.sender][id] != 0, "Farming: Sender isn't token's owner");
        userInfo[msg.sender][id] = 0;
        cyberNft.transferFrom(address(this), msg.sender, id);
        emit NFTEmergencyWithdrawn(msg.sender, id, block.number);
    }


    function pendingToken(address user, uint256 id) public view returns (uint256) {
        require(userInfo[user][id] != 0, "Farming: User doesn't exist");
        return (block.number - userInfo[user][id]) * _tokenPerBlock;
    }


    function getCurrentBlockReward() public view returns (uint256) {
        return _tokenPerBlock;
    }
}