/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT

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

/**
 * @dev Partial interface of the ERC20 standard according to the needs of the e2p contract.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * @dev Partial interface of the marketplace contract according to the needs of the e2p contract.
 */
interface IMarketplace {
    function adminBurn(uint256 tokenId) external;
    function adminMint(uint32 profileId, address to, uint256 tokenId) external;
    function getProfileIdByTokenId(uint256 tokenId) external returns (uint32);
}

interface INFT {
    function ownerOf(uint256 tokenId) external returns (address);
}

contract NFTBridge is Ownable {
    event NewDeposit(uint256 depositId, uint32 profileId, uint256 tokenId, address userAddress);
    event NewCredit(uint256 depositId, uint32 profileId, uint256 tokenId, address userAddress);

    uint256 _depositsNumber;
    uint256 _creditsNumber;
    uint256 _fee;

    address _manager; // address for sending unlock transactions

    struct Deposit {
        uint256 depositId;
        uint32 profileId;
        uint256 tokenId;
        address userAddress;
        uint256 time;
    }
    struct Credit {
        uint256 creditId;
        uint32 profileId;
        uint256 tokenId;
        address userAddress;
        uint256 time;
    }
    mapping (uint256 => Deposit) _deposits;
    mapping (uint256 => Credit) _credits;
    IERC20 _etnaContract;
    IMarketplace _marketplaceContract;
    INFT _nftContract;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyManager() {
        require(_manager == _msgSender(), "Caller is not the manager");
        _;
    }

    constructor (
        address tokenAddress,
        address nftAddress,
        address marketplaceAddress,
        address newOwner,
        address newManager,
        uint256 fee
    ) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        require(marketplaceAddress != address(0), 'Marketplace address can not be zero');
        require(nftAddress != address(0), 'NFT address can not be zero');
        require(newManager != address(0), 'Manager address can not be zero');
        require(newOwner != address(0), 'Owner address can not be zero');

        _etnaContract = IERC20(tokenAddress);
        _marketplaceContract = IMarketplace(marketplaceAddress);
        _nftContract = INFT(nftAddress);
        transferOwnership(newOwner);
        _manager = newManager;
        _fee = fee;
    }

    function depositToken (uint256 tokenId) external returns (bool) {
        require(_etnaContract.transferFrom(msg.sender, address(this), _fee),
            'Fee payment failed, please check ETNA balance and allowance for this contract address');
        uint32 profileId = _marketplaceContract.getProfileIdByTokenId(tokenId);
        require(profileId < 9999999, 'Profile for this token is not found');
        try _nftContract.ownerOf(tokenId) returns (address tokenOwner) {
            require(tokenOwner == msg.sender, 'Sender does not own token');
        } catch {
            revert('Token does not exist');
        }

        _depositsNumber++;
        _marketplaceContract.adminBurn(tokenId);
        Deposit memory depositInstance = Deposit({
            depositId : _depositsNumber,
            profileId : profileId,
            tokenId : tokenId,
            userAddress : msg.sender,
            time : block.timestamp
        });
        _deposits[_depositsNumber] = depositInstance;
        emit NewDeposit(depositInstance.depositId, profileId, tokenId, msg.sender);

        return true;
    }

    function addCredit (uint32 profileId, uint256 tokenId, address userAddress, uint256 depositId) external onlyManager returns (bool) {
        require(depositId == _creditsNumber + 1, 'Gap in credits records is not allowed');
        _marketplaceContract.adminMint(profileId, userAddress, tokenId);
        Credit memory creditInstance = Credit({
            creditId: depositId,
            profileId : profileId,
            tokenId : tokenId,
            userAddress: userAddress,
            time: block.timestamp
        });
        _creditsNumber = depositId;
        _credits[_creditsNumber] = creditInstance;

        return true;
    }

    function withdraw (uint256 amount) external onlyOwner returns (bool) {
        require(_etnaContract.transfer(msg.sender, amount),
            'ETNA withdraw failed');
        return true;
    }

    function getDepositsNumber () external view returns (uint256) {
        return _depositsNumber;
    }

    function getDepositData (uint256 depositId) external view returns (uint32, uint256, address, uint256) {
        return (
            _deposits[depositId].profileId,
            _deposits[depositId].tokenId,
            _deposits[depositId].userAddress,
            _deposits[depositId].time
        );
    }

    function getCreditsNumber () external view returns (uint256) {
        return _creditsNumber;
    }

    function getCreditData (uint256 creditId) external view returns (uint32, uint256, address, uint256) {
        return (
            _credits[creditId].profileId,
            _credits[creditId].tokenId,
            _credits[creditId].userAddress,
            _credits[creditId].time
        );
    }

    function getManager () external view returns (address) {
        return _manager;
    }

    function setManager (address managerAddress) external onlyOwner returns (bool) {
        _manager = managerAddress;
        return true;
    }

    function getFee () external view returns (uint256) {
        return _fee;
    }

    function setFee (uint256 amount) external onlyOwner returns (bool) {
        _fee = amount;
        return true;
    }

    function getEtnaContract () external view returns (address) {
        return address(_etnaContract);
    }

    function setEtnaContract (address tokenAddress) external onlyOwner returns (bool) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        _etnaContract = IERC20(tokenAddress);
        return true;
    }

    function getMarketplaceContract () external view returns (address) {
        return address(_marketplaceContract);
    }

    function setMarketplaceContract (address marketplaceAddress) external onlyOwner returns (bool) {
        require(marketplaceAddress != address(0), 'Marketplace address can not be zero');
        _marketplaceContract = IMarketplace(marketplaceAddress);
        return true;
    }

    function getNftContract () external view returns (address) {
        return address(_nftContract);
    }

    function setNftContract (address nftAddress) external onlyOwner returns (bool) {
        require(nftAddress != address(0), 'NFT address can not be zero');
        _nftContract = INFT(nftAddress);
        return true;
    }
}