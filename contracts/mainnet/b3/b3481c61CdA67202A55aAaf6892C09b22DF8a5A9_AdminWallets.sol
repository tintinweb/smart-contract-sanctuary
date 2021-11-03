/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0

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
contract AdminWallets is Ownable {

    address private OWNER_WALLET = 0x2565053B002ea3C52dC533C00838335Bf49D0FE9; // Need to set owner wallet also in VotingLogic.sol
    address private DIVERSITY_WALLET = 0xe2165a834F93C39483123Ac31533780b9c679ed4; // EX AUSTIN
    address private ASSETBENDER_WALLET = 0x650802BD9dF24DF295241684185265196f88BA7D; // EX LUKE
    address private MARKETING_WALLET = 0x9cE09Fd065f2C6b5668b458627608F561b3B1336; // EX INFLUENCER
    address private DIVINETREASURY_WALLET = 0x650802BD9dF24DF295241684185265196f88BA7D; // EX BUYBACK

    mapping(address => bool) private EMPEROR_LIST; 

    uint256 private _presaleRound = 1;
    bool private _presaleActive = true;

    mapping(uint256 => mapping(address => bool)) private PRESALE_ACCOUNTS;

    // Wallet setters.
    function setOwnerWallet(address _OWNER_WALLET) external onlyOwner {
        OWNER_WALLET = _OWNER_WALLET;
    }

    function setDiversityWallet(address _DIVERSITY_WALLET) external onlyOwner {
        DIVERSITY_WALLET = _DIVERSITY_WALLET;
    }

    function setAssetBenderWallet(address _ASSETBENDER_WALLET) external onlyOwner {
        ASSETBENDER_WALLET = _ASSETBENDER_WALLET;
    }

    function setMarketingWallet(address _MARKETING_WALLET) external onlyOwner {
        MARKETING_WALLET = _MARKETING_WALLET;
    }

    function setDivineTreasuryWallet(address _DIVINETREASURY_WALLET) external onlyOwner {
        DIVINETREASURY_WALLET = _DIVINETREASURY_WALLET;
    }

    // Wallet getters.
    function getOwnerWallet() external view returns(address) {
        return OWNER_WALLET;
    }

    function getDiversityWallet() external view returns(address) {
        return DIVERSITY_WALLET;
    }

    function getAssetBenderWallet() external view returns(address) {
        return ASSETBENDER_WALLET;
    }

    function getMarketingWallet() external view returns(address) {
        return MARKETING_WALLET;
    }

    function getDivineTreasuryWallet() external view returns(address) {
        return DIVINETREASURY_WALLET;
    }


    // Emperor list functions.
    function joinEmperorList(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            EMPEROR_LIST[accounts[i]] = true;
        }
    }

    function isInEmperorList(address account) external view returns(bool) {
        return EMPEROR_LIST[account];
    }

    // Presale functions.
    function setAccountInPresale(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            PRESALE_ACCOUNTS[_presaleRound][accounts[i]] = true;
        }
    }

    function setNewPresaleRound() external onlyOwner {
        _presaleRound += 1;
    }
    
    function setNewPresaleRoundExact(uint256 integer) external onlyOwner {
        _presaleRound = integer;
    }

    function setPresaleState(bool _bool) external onlyOwner {
        _presaleActive = _bool;
    }

    function isPresaleActive() external view returns(bool) {
        return _presaleActive;
    }

    function getCurrentPresaleRound() external view returns(uint256) {
        return _presaleRound;
    }

    function isAllowedAtPresale(uint256 round, address account) external view returns(bool) {
        return PRESALE_ACCOUNTS[round][account];
    }
}