/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

interface IMerge {
    function balanceOf(address account) external view returns (uint256);
    function massOf(uint256 tokenId) external view returns (uint256);
    function tokenOf(address account) external view returns (uint256);
    function getValueOf(uint256 tokenId) external view returns (uint256);
    function decodeClass(uint256 value) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function isWhitelisted(address account) external view returns (bool);
    function isBlacklisted(address account) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
}

interface IWalletProxyManager {
    function indexToWallet(uint256 class, uint256 index) external view returns (address);
    function currentIndex(uint256 class) external view returns (uint256);
}

interface IWalletProxyFactory {
    function createWallet(uint256 class) external returns (address);
}

contract Router is Ownable {
    /**
     * @dev Emitted when `account` contributes `tokenId` with `mass` to DAO.
     */
    event Contribute(address indexed account, address indexed wallet, uint256 tokenId, uint256 indexed class, uint256 weight);

    address public merge;  // The Merge contract

    address public gToken;  // Governance token

    address public manager;  // Wallet proxy manager

    address public factory;  // factory contract address

    address public contender;  // AlphaMass contender wallet, only tier 1 NFTs are sent to this AlphaMass wallet

    address public red;  // red wallet for tier 4

    address public yellow;  // yellow wallet for tier 3

    address public blue;  // blue wallet for tier 2

    uint256 public constant WEIGHT_MULTIPLIER = 10_000 * 1e9;  // a multiplier to mass

    uint256 public BONUS_MULTIPLIER;  // a bonus multiplier in percentage

    uint256 public cap;  // The soft cap for a wallet of a certain classId

    bool public isEnded; // a bool indicator on whether the game has ended.

    mapping(address => bool) public specialWallets;  // DAO, contender, blue, red, yellow are all special wallets

    /**
     * @param merge_ address contract address of merge
     * @param gToken_ address contract address of governance token
     * @param manager_ address contract address for wallet manager
     * @param factory_ address contract address for wallet factory
     * @param contender_ address AlphaMass Contender wallet
     * @param blue_ address wallet for tier blue
     * @param yellow_ address wallet for tier yellow
     * @param red_ address wallet for tier red
     */
    constructor(
        address merge_,
        address gToken_,
        address manager_,
        address factory_,
        address contender_,
        address blue_,
        address yellow_,
        address red_)
    {
        if (merge_ == address(0) ||
            gToken_ == address(0) ||
            manager_ == address(0) ||
            factory_ == address(0) ||
            contender_ == address(0) ||
            blue_ == address(0) ||
            yellow_ == address(0) ||
            red_ == address(0)) revert("Invalid address");

        cap = 50;  // soft cap
        BONUS_MULTIPLIER = 120;

        merge = merge_;
        gToken = gToken_;
        manager = manager_;
        factory = factory_;
        contender = contender_;
        blue = blue_;
        yellow = yellow_;
        red = red_;

        specialWallets[contender] = true;
        specialWallets[blue] = true;
        specialWallets[yellow] = true;
        specialWallets[red] = true;
    }

    /**
     * @dev Make a contribution with the nft in the caller's wallet.
     */
    function contribute() external {
        require(!isEnded, "Already ended");
        address account = _msgSender();
        require(!_validateAccount(account), "Invalid caller");

        _contribute(account);
    }

    /**
     * @dev Toggle the special status of a wallet between true and false.
     */
    function toggleSpecialWalletStatus(address wallet) external onlyOwner {
        specialWallets[wallet] = !specialWallets[wallet];
    }

    /**
     * @dev Transfer NFTs if there is any in this contract to address `to`.
     */
    function transfer(address to) external onlyOwner {
        require(isEnded, "Not ended");
        uint256 tokenId = _tokenOf(address(this));
        require(tokenId != 0, "No token to be transferred in this contract");
        require(specialWallets[to], "Must transfer to a special wallet");

        _transfer(address(this), to, tokenId);
    }

    /**
     * @dev Required by {IERC721-safeTransferFrom}.
     */
    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev End the game of competing in Pak Merge.
     */
    function endGame() external onlyOwner {
        require(!isEnded, "Already ended");
        isEnded = true;
    }

    /**
     * @dev Set the soft cap for each wallet.
     */
    function setCap(uint256 cap_) external onlyOwner {
        cap = cap_;
    }

    /**
     * @dev Set the wallet `contender_` for AlphaMass contentder.
     */
    function setContenderWallet(address contender_) external onlyOwner {
        contender = contender_;
    }

    /**
     * @dev Set the wallet `red_` for red tier.
     */
    function setRed(address red_) external onlyOwner {
        red = red_;
    }

    /**
     * @dev Set the wallet `yellow_` for yellow tier.
     */
    function setYellow(address yellow_) external onlyOwner {
        yellow = yellow_;
    }

    /**
     * @dev Set the wallet `blue_` for blue tier.
     */
    function setBlue(address blue_) external onlyOwner {
        blue = blue_;
    }

    /**
     * @dev Set the `multiplier_` for BONUS_MULTIPLIER.
     */
    function setBonusMultiplier(uint256 multiplier_) external onlyOwner {
        if (multiplier_ < 100 || multiplier_ >= 200) revert("Out of range");

        BONUS_MULTIPLIER = multiplier_;
    }

    /**
     * @dev Returns the current active `tokenId` for a given `class`.
     */
    function getTokenIdForClass(uint256 class) external view returns (uint256) {
        return _tokenOf(_getWalletByClass(class));
    }

    /**
     * @dev Returns all `tokenId`s for a given `class`.
     */
    function getTokenIdsForClass(uint256 class) external view returns (uint256[] memory) {
        uint256 index = _getClassIndex(class);
        uint256[] memory tokenIds = new uint256[](index+1);
        if (index == 0) {
            tokenIds[0] = _tokenOf(_getWalletByClass(class));
            return tokenIds;
        } else {
            for (uint256 i = 0; i < index+1; i++) {
                tokenIds[i] = _tokenOf(_getWalletByIndex(class, i));
            }
            return tokenIds;
        }
    }

    /**
     * @dev Execute the logic of making a contribution by `account`.
     */
    function _contribute(address account) private {
        uint256 tokenId = _tokenOf(account);
        uint256 weight = _massOf(tokenId);
        (address targetWallet, uint256 class) = _getTargetWallet(tokenId);

        _transfer(account, targetWallet, tokenId);
        _mint(account, weight);

        emit Contribute(account, targetWallet, tokenId, class, weight);
    }

    /**
     * @dev Returns the wallet address for given `class` and `index`.
     */
    function _getWalletByIndex(uint256 class, uint256 index) private view returns (address) {
        return IWalletProxyManager(manager).indexToWallet(class, index);
    }

    /**
     * @dev Returns the currently active wallet address by `class`.
     */
    function _getClassIndex(uint256 class) private view returns (uint256) {
        return IWalletProxyManager(manager).currentIndex(class);
    }

    /**
     * @dev Returns the target wallet address by `class` and `tokenId`.
     */
    function _getTargetWallet(uint256 tokenId) private returns (address wallet, uint256 class) {
        uint256 tier = _tierOf(tokenId);
        class = _classOf(tokenId);

        if (tier == 4) {
            wallet = red;
        } else if (tier == 3) {
            wallet = yellow;
        } else if (tier == 2) {
            wallet = blue;
        } else if (tier == 1) {
            if (_massOf(tokenId) >= cap) {
                wallet = contender;
            } else {
                wallet = _getWalletByClass(class);

                // No wallet for this class has been created yet.
                if (wallet == address(0)) {
                    wallet = _createWalletByClass(class);
                    require(wallet == _getWalletByClass(class), "Mismatch");
                } else {
                    uint256 _tokenId = _tokenOf(wallet);
                    if (_tokenId != 0) {
                        if (_massOf(_tokenId) >= cap) {  // Current wallet has reached the cap
                            wallet = _createWalletByClass(class);
                            require(wallet == _getWalletByClass(class), "Mismatch");
                        } else {
                            if (_classOf(_tokenId) != class) {
                                wallet = _createWalletByClass(class);
                                require(wallet == _getWalletByClass(class), "Mismatch");
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * @dev Creates a new wallet for a given `class`.
     */
    function _createWalletByClass(uint256 class) private returns (address) {
        return IWalletProxyFactory(factory).createWallet(class);
    }

    /**
     * @dev Returns the currently active wallet address by `class`.
     */
    function _getWalletByClass(uint256 class) private view returns (address) {
        uint256 index = _getClassIndex(class);
        return IWalletProxyManager(manager).indexToWallet(class, index);
    }

    /**
     * @dev Mint governance tokens based on the weight of NFT the caller contributed
     */
    function _mint(address to, uint256 weight) private {
        IERC20Mintable(gToken).mint(to, weight * WEIGHT_MULTIPLIER * BONUS_MULTIPLIER / 100);
    }

    /**
     * @dev Transfer NFT with `tokenId` from address `from` to address `to`.
     * Checking if address `to` is valid is built in the function safeTransferFrom.
     */
    function _transfer(address from, address to, uint256 tokenId) private {
        _beforeTokenTransfer(from, to, tokenId);
        IMerge(merge).safeTransferFrom(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev A hook function checking if the mass of the NFT in the `to` wallet
     * has reached the soft cap before it is being transferred.
     */
    function _beforeTokenTransfer(address, address to, uint256) private view {
        if (!specialWallets[to]) {
            if (_tokenOf(to) != 0) {  // a non-existent token
                require(_massOf(_tokenOf(to)) < cap, "Exceeding cap");
            }
        }
    }

    /**
     * @dev A hook function creates a new wallet with the same class to `tokenId`
     * if the `to` wallet has reached the soft cap.
     */
    function _afterTokenTransfer(address, address to, uint256 tokenId) private {
        if (!specialWallets[to]) {
            if (_massOf(_tokenOf(to)) >= cap) {
                _createWalletByClass(_classOf(tokenId));
            }
        }
    }

    /**
     * @dev Returns if a given account is whitelisted or blacklisted, or does not
     * have a Merge NFT.
     */
    function _validateAccount(address account) private view returns (bool) {
        bool cond1 = IMerge(merge).isWhitelisted(account);
        bool cond2 = IMerge(merge).isBlacklisted(account);
        bool cond3 = _balanceOf(account) == 0;
        return cond1 || cond2 || cond3;
    }

    function _getKey(string memory name) private view returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }


    /**
     * @dev Retrieves the class/tier of token with `tokenId`.
     */
    function _tierOf(uint256 tokenId) private view returns (uint256) {
        return IMerge(merge).decodeClass(_valueOf(tokenId));
    }

    /**
     * @dev Retrieves the class of token with `tokenId`, i.e., the last two digits
     * of `tokenId`.
     */
    function _classOf(uint256 tokenId) private pure returns (uint256) {
        return tokenId % 100;
    }

    /**
     * @dev Retrieves the value of token with `tokenId`.
     */
    function _valueOf(uint256 tokenId) private view returns (uint256) {
        return IMerge(merge).getValueOf(tokenId);
    }

    /**
     * @dev Returns the `tokenId` held by `account`. Returns 0 if `account`
     * does not have a token.
     */
    function _tokenOf(address account) private view returns (uint256) {
        return IMerge(merge).tokenOf(account);
    }

    /**
     * @dev Returns the `mass` of a token given `tokenId`.
     */
    function _massOf(uint256 tokenId) private view returns (uint256) {
        return IMerge(merge).massOf(tokenId);
    }

    /**
     * @dev Returns the balance of an `account`, either 0 or 1.
     */
    function _balanceOf(address account) private view returns (uint256) {
        return IMerge(merge).balanceOf(account);
    }
}