// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract s0BoosterPack is Ownable{

    IERC20 iBusd;
    INFT iNFT;
    uint constant price = 60*10e17;
    uint constant season = 0;
    uint constant maximum = 5;

    mapping (address=>uint) public qtyGoblin;
    mapping (address=>uint) public qtyUndead;
    mapping (address=>uint) public qtyDemon;
    mapping (address=>uint[]) public claimsGoblin;
    mapping (address=>uint[]) public claimsUndead;
    mapping (address=>uint[]) public claimsDemon;
    mapping (address=>bool) whitelist;

    event claimCreated(address buyer, string pack, uint[] claims);
    event NFTClaimed(address to);

    constructor(address nftAdd, address token){

        iNFT = INFT(nftAdd);
        iBusd = IERC20(token);

    }

    function setWhitelist(address[] memory whitelist_, bool white) external onlyOwner{
        for(uint i=0; i<whitelist_.length; i++){
            whitelist[whitelist_[i]] = white;
        }
    }

    function buy(uint amount_, string memory pack) external {
        uint value = price*amount_;

        require(whitelist[msg.sender], "Sorry, you are not in the whitelist");
        require(iBusd.balanceOf(msg.sender) >= value, "Not enough token!");

        if (keccak256(abi.encodePacked(pack)) == keccak256(abi.encodePacked("Goblin"))){
            qtyGoblin[msg.sender] += amount_;
            for(uint i=0;i < amount_; i++){
                claimsGoblin[msg.sender].push(block.number + 3 + i);
            }
        } else if (keccak256(abi.encodePacked(pack)) == keccak256(abi.encodePacked("Undead"))){
            qtyUndead[msg.sender] += amount_;
            for(uint i=0;i < amount_; i++){
                claimsUndead[msg.sender].push(block.number + 3 + i);
            }
        } else {
            qtyDemon[msg.sender] += amount_;
            for(uint i=0;i < amount_; i++){
                claimsDemon[msg.sender].push(block.number + 3 + i);
            }
        }

        iBusd.transferFrom(msg.sender, address(this), value);

        emit claimCreated(msg.sender, "Goblin", claimsGoblin[msg.sender]);
        emit claimCreated(msg.sender, "Undead", claimsUndead[msg.sender]);
        emit claimCreated(msg.sender, "Demon", claimsDemon[msg.sender]);

    }

    function claimGoblin() external{

        require(block.number > claimsGoblin[msg.sender][claimsGoblin[msg.sender].length-1], "Last claim block not mined yet.");

        for(uint i=0;i < claimsGoblin[msg.sender].length; i++){
            uint blockNumber = claimsGoblin[msg.sender][i];
            uint rand = uint(keccak256(abi.encodePacked(blockhash(blockNumber)))) % 100;

            string memory family;

            if (rand < 40){
                family = "Goblin";
            }
            else if (rand < 70){
                family = "Demon";
            } else {
                family = "Undead";
            }

            iNFT.safeMint(msg.sender, blockNumber, season, family);

            emit NFTClaimed(msg.sender);
        }

        delete claimsGoblin[msg.sender];

    }

    function claimDemon() external{

        require(block.number > claimsDemon[msg.sender][claimsDemon[msg.sender].length-1], "Last claim block not mined yet.");

        for(uint i=0;i < claimsDemon[msg.sender].length; i++){
            uint blockNumber = claimsDemon[msg.sender][i];
            uint rand = uint(keccak256(abi.encodePacked(blockhash(blockNumber)))) % 100;

            string memory family;

            if (rand < 40){
                family = "Demon";
            }
            else if (rand < 70){
                family = "Goblin";
            } else {
                family = "Undead";
            }

            iNFT.safeMint(msg.sender, blockNumber, season, family);

            emit NFTClaimed(msg.sender);
        }

        delete claimsDemon[msg.sender];

    }

    function claimUndead() external{

        require(block.number > claimsUndead[msg.sender][claimsUndead[msg.sender].length-1], "Last claim block not mined yet.");

        for(uint i=0;i < claimsUndead[msg.sender].length; i++){
            uint blockNumber = claimsUndead[msg.sender][i];
            uint rand = uint(keccak256(abi.encodePacked(blockhash(blockNumber)))) % 100;

            string memory family;

            if (rand < 40){
                family = "Undead";
            }
            else if (rand < 70){
                family = "Goblin";
            } else {
                family = "Demon";
            }

            iNFT.safeMint(msg.sender, blockNumber, season, family);

            emit NFTClaimed(msg.sender);
        }

        delete claimsUndead[msg.sender];

    }

    function withdrawToken (uint amount_, address token_) external onlyOwner {
        IERC20 _token = IERC20(token_);
        _token.transfer(msg.sender, amount_);
    }

}

interface INFT{

    function safeMint(address to, uint blockNumber, uint season_, string memory family) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}