/**
 *Submitted for verification at polygonscan.com on 2021-12-15
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
    function decimals() external view returns (uint8);
}

/**
 * @dev Partial interface of the marketplace contract according to the needs of the staking nft contract.
 */
interface IMarketplace {
    function adminBurn(uint256 tokenId) external;
    function adminMint(uint32 profileId, address to, uint256 tokenId) external;
    function getProfileIdByTokenId(uint256 tokenId) external returns (uint32);
    function getSellPriceById(uint32 profileID) external  view returns (uint256);
}

/**
 * @dev Partial interface of the NFT contract according to the needs of the staking nft contract.
 */
interface INFT {
    function ownerOf(uint256 tokenId) external returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract StakingNft is Ownable, IERC721Receiver {
    struct Deposit {
        address userAddress;
        uint256 amount;
        uint256 unlock;
        uint256 lastMarketIndex;
        uint256 updatedAt; // timestamp, is resettled to block.timestamp when changed
        uint256 accumulatedYield; // used to store reward when changed
        uint256 tokensNumber;
    }
    mapping (uint256 => Deposit) _deposits;
    mapping (address => uint256) _usersDepositIndex;
    mapping (uint256 => address) _tokenRegistry; // tokenId => userAddress
    mapping (address => mapping (uint256 => uint256)) _userTokenRegistry; // userAddress => RegistryIndex => tokenId
    mapping (address => mapping (uint256 => uint256)) _userTokenIndexes; // userAddress => tokenId => RegistryIndex
    mapping (uint256 => uint256) _tokenPrice;

    uint256 _depositsNumber;
    uint256 _batchLimit = 100;
    uint256 _year = 365 * 24 * 3600;
    uint256 _apr;
    uint256 _shift = 1 ether; // used for exponent shifting when calculation with decimals
    uint256 _marketIndex = _shift; // initial market index, used to take care of APR changes
    uint256 _marketIndexLastTime = block.timestamp; // last time when market index was updated
    uint256 _lockTime; // period when unstake is prohibited
    IERC20 _etnaContract;
    IMarketplace _marketplaceContract;
    INFT _nftContract;

    constructor (
        address etnaAddress,
        address marketplaceAddress,
        address nftAddress,
        address newOwner
    ) {
        require(etnaAddress != address(0), 'Token address can not be zero');
        require(marketplaceAddress != address(0), 'Marketplace contract address can not be zero');
        require(nftAddress != address(0), 'NFT token address can not be zero');
        require(newOwner != address(0), 'Owner address can not be zero');

        _etnaContract = IERC20(etnaAddress);
        _marketplaceContract = IMarketplace(marketplaceAddress);
        _nftContract = INFT(nftAddress);
        transferOwnership(newOwner);
    }

    function stake (uint256[] memory tokenIds) external returns (bool) {
        require(tokenIds.length > 0, 'No token ids provided');

        uint256 depositIndex = _usersDepositIndex[msg.sender];
        if (depositIndex == 0) {
            _depositsNumber ++;
            depositIndex = _depositsNumber;
            _deposits[depositIndex] = Deposit({
                userAddress: msg.sender,
                amount: 0,
                unlock: _lockTime + block.timestamp,
                lastMarketIndex: _marketIndex,
                updatedAt: block.timestamp,
                accumulatedYield: 0,
                tokensNumber: 0
            });
            _usersDepositIndex[msg.sender] = depositIndex;
        }
        _updateYield(depositIndex);
        _addTokens(msg.sender, depositIndex, tokenIds);

        return true;
    }

    function unStake (uint256[] memory tokenIds) external returns (bool) {
        require(tokenIds.length > 0, 'No token ids provided');

        uint256 depositIndex = _usersDepositIndex[msg.sender];
        require(depositIndex > 0, 'Deposit is not found');
        _updateYield(depositIndex);
        _withdrawTokens(msg.sender, depositIndex, tokenIds);

        return true;
    }

    function _addTokens(address userAddress, uint256 depositIndex, uint256[] memory tokenIds) internal returns (bool) {
        for (uint256 i; i < tokenIds.length; i ++) {
            if (i >= _batchLimit) break;
            if (_tokenRegistry[tokenIds[i]] != address(0)) continue;

            uint32 profileId = _marketplaceContract.getProfileIdByTokenId(tokenIds[i]);
            uint256 price = _marketplaceContract.getSellPriceById(profileId);
            if (!(price > 0)) continue;

            try _nftContract.ownerOf(tokenIds[i]) returns (address tokenOwner) {
                if (tokenOwner != userAddress) continue;

                _nftContract.safeTransferFrom(
                    userAddress,
                    address(this),
                    tokenIds[i]
                );
                if (_deposits[depositIndex].unlock > block.timestamp) {
                    _deposits[depositIndex].unlock = block.timestamp + _lockTime;
                }
                _tokenPrice[tokenIds[i]] = price;
                _deposits[depositIndex].tokensNumber ++;
                _deposits[depositIndex].amount += price;
                _userTokenRegistry
                    [userAddress]
                    [_deposits[depositIndex].tokensNumber] = tokenIds[i];
                _userTokenIndexes
                    [userAddress]
                    [tokenIds[i]] = _deposits[depositIndex].tokensNumber;
                _tokenRegistry[tokenIds[i]] = userAddress;
            } catch {}
        }

        return true;
    }

    function _withdrawTokens(address userAddress, uint256 depositIndex, uint256[] memory tokenIds) internal returns (bool) {
        require(_deposits[depositIndex].unlock <= block.timestamp, 'Deposit is locked yet');
        for (uint256 i; i < tokenIds.length; i ++) {
            if (i >= _batchLimit) break;
            if (_tokenRegistry[tokenIds[i]] != userAddress) continue;

            _deposits[depositIndex].amount -= _tokenPrice[tokenIds[i]];
            uint256 index = _userTokenIndexes[userAddress][tokenIds[i]];
            if (index < _deposits[depositIndex].tokensNumber) {
                _userTokenRegistry[userAddress][index] =
                    _userTokenRegistry[userAddress][_deposits[depositIndex].tokensNumber];
                _userTokenIndexes[userAddress][_userTokenRegistry[userAddress][index]] = index;
            }
            _userTokenRegistry[userAddress][_deposits[depositIndex].tokensNumber] = 0;
            _deposits[depositIndex].tokensNumber --;
            _tokenRegistry[tokenIds[i]] = address(0);

            _nftContract.safeTransferFrom(
                address(this),
                userAddress,
                tokenIds[i]
            );
        }

        return true;
    }

    function withdrawYield (uint256 amount) external returns (bool) {
        uint256 depositIndex = _usersDepositIndex[msg.sender];
        require(depositIndex > 0, 'Deposit is not found');
        require(amount > 0, 'Amount should be greater than zero');
        _updateYield(depositIndex);
        require(_deposits[depositIndex].accumulatedYield >= amount, 'Not enough yield at deposit');

        _deposits[depositIndex].accumulatedYield -= amount;
        uint256 balance = _etnaContract.balanceOf(address(this));
        require(amount <= balance, 'Not enough contract balance');
        _etnaContract.transfer(msg.sender, amount);

        return true;
    }

    function adminSetApr (
        uint16 apr
    ) external onlyOwner returns (bool) {
        uint256 period = block.timestamp - _marketIndexLastTime;
        uint256 marketFactor = _shift +
            _shift * _apr * period / 10000 / _year;
        _marketIndex = _marketIndex * marketFactor / _shift;
        _apr = apr;
        _marketIndexLastTime = block.timestamp;

        return true;
    }

    function adminSetLockTime (
        uint256 lockTime
    ) external onlyOwner returns (bool) {
        _lockTime = lockTime;

        return true;
    }

    function adminSetBatchLimit (
        uint256 batchLimit
    ) external onlyOwner returns (bool) {
        require(batchLimit > 0, 'Batch limit should be greater than zero');
        _batchLimit = batchLimit;

        return true;
    }

    function adminWithdrawNft (uint256[] memory tokenIds) external onlyOwner
        returns (bool) {
        for (uint256 i; i < tokenIds.length; i ++) {
            try _nftContract.safeTransferFrom(address(this), msg.sender, tokenIds[i]) {} catch {}
        }
        return true;
    }

    function adminWithdrawEtna (uint256 amount) external onlyOwner
        returns (bool) {
        uint256 balance = _etnaContract.balanceOf(address(this));
        require(amount <= balance, 'Not enough contract balance');
        _etnaContract.transfer(msg.sender, amount);
        return true;
    }

    function adminSetEtnaContract (address tokenAddress) external onlyOwner returns (bool) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        _etnaContract = IERC20(tokenAddress);
        return true;
    }

    function adminSetMarketplaceContract (address tokenAddress) external onlyOwner returns (bool) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        _marketplaceContract = IMarketplace(tokenAddress);
        return true;
    }

    function adminSetNftContract (address tokenAddress) external onlyOwner returns (bool) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        _nftContract = INFT(tokenAddress);
        return true;
    }

    // internal functions
    function _updateYield (uint256 depositIndex) internal returns (bool) {
        uint256 yield = _calculateYield(depositIndex);
        _deposits[depositIndex].accumulatedYield += yield;
        _deposits[depositIndex].updatedAt = block.timestamp;
        _deposits[depositIndex].lastMarketIndex =
            _marketIndex;

        return true;
    }

    function getDepositsNumber () external view returns (uint256) {
        return _depositsNumber;
    }

    function getDeposit (uint256 depositIndex) external view
        returns (address, uint256, uint256, uint256, uint256, uint256) {
        return (
            _deposits[depositIndex].userAddress,
            _deposits[depositIndex].amount,
            _deposits[depositIndex].unlock,
            _deposits[depositIndex].updatedAt,
            _deposits[depositIndex].accumulatedYield,
            _deposits[depositIndex].tokensNumber
        );
    }

    function getUserDeposit (address userAddress) external view
        returns (uint256, address, uint256, uint256, uint256, uint256, uint256) {
        uint256 depositIndex = _usersDepositIndex[userAddress];
        return (
            depositIndex,
            _deposits[depositIndex].userAddress,
            _deposits[depositIndex].amount,
            _deposits[depositIndex].unlock,
            _deposits[depositIndex].updatedAt,
            _deposits[depositIndex].accumulatedYield,
            _deposits[depositIndex].tokensNumber
        );
    }

    function getTokenStaker (uint256 tokenId) external view returns (address) {
        return _tokenRegistry[tokenId];
    }

    function getLastTokenPrice (uint256 tokenId) external view returns (uint256) {
        return _tokenPrice[tokenId];
    }

    function getUserTokensNumber (address userAddress) external view returns (uint256) {
        uint256 depositIndex = _usersDepositIndex[userAddress];
        return _deposits[depositIndex].tokensNumber;
    }

    function getUserTokenByIndex (address userAddress, uint256 index) external view returns (uint256) {
        return _userTokenRegistry[userAddress][index];
    }

    function getDepositLastMarketIndex (uint256 depositIndex) external view returns (uint256) {
        return _deposits[depositIndex].lastMarketIndex;
    }

    function getEtnaContract () external view returns (address) {
        return address(_etnaContract);
    }

    function getMarketplaceContract () external view returns (address) {
        return address(_marketplaceContract);
    }

    function getNftContract () external view returns (address) {
        return address(_nftContract);
    }

    function getApr () external view returns (uint256) {
        return _apr;
    }

    function getLockTime () external view returns (uint256) {
        return _lockTime;
    }

    function getBatchLimit () external view returns (uint256) {
        return _batchLimit;
    }

    function getMarketIndexLastTime () external view returns (uint256) {
        return _marketIndexLastTime;
    }

    function getMarketIndex () external view returns (uint256) {
        return _marketIndex;
    }

    function calculateYield (uint256 depositIndex) external view returns (uint256) {
        return _calculateYield(depositIndex);
    }

    function _calculateYield (uint256 depositIndex) internal view returns (uint256) {
        uint256 marketIndex = _marketIndex;

        uint256 extraPeriodStartTime = _marketIndexLastTime;
        if (extraPeriodStartTime < _deposits[depositIndex].updatedAt) {
            extraPeriodStartTime = _deposits[depositIndex].updatedAt;
        }
        uint256 extraPeriod = block.timestamp - extraPeriodStartTime;

        if (extraPeriod > 0) {
            uint256 marketFactor = _shift +
                _shift * _apr * extraPeriod / 10000 / _year;
            marketIndex = marketIndex * marketFactor / _shift;
        }

        uint256 newAmount = _deposits[depositIndex].amount
            * marketIndex
            / _deposits[depositIndex].lastMarketIndex;

        uint256 yield = newAmount - _deposits[depositIndex].amount;

        return yield;
    }

    function getEtnaBalance () external view returns (uint256) {
        return _etnaContract.balanceOf(address(this));
    }

    /**
    * @dev Standard callback fot the ERC721 token receiver.
    */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}