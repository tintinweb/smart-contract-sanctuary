/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Swappable.sol

pragma solidity 0.8.2;


/// swappable.xyz contract for governing swaps
contract Swappable is Ownable {
    /// Supported Swappable Standards
    enum Standard {
        ERC_1155,
        ERC_721,
        ERC_20,
        CRYPTO_PUNK
    }

    /// Token structure
    struct Token {
        address _contract;
        uint256 _tokenId;
        uint256 _amount;
        Standard _standard;
    }

    mapping(uint256 => Token) public tokens;
    uint256 public tokenCount = 0;

    /// Swap definition
    struct Swap {
        address _fromAddress;
        address _toAddress;
        uint256 _expiry;
        uint256[] _from;
        uint256[] _to;
    }

    /// Swap tracking
    mapping(uint256 => Swap) public swaps;

    /// Track the number of swaps
    uint256 public swapCount = 0;

    /// Owner to swap tracking
    mapping(address => uint256[]) public ownerSwaps;

    /// Swap Fee
    uint256 public swapFee = 0;

    /// Event tracking when swaps are created
    event SwapCreated(address indexed from, address indexed to, uint256 indexed swapId);

    /// Event tracking when swaps are completed
    event SwapExecuted(uint256 indexed swapId, Swap swap);

    /// number of swaps I own
    function numberOfSwapsIOwn(address swapOwner) public view returns(uint256) {
        uint256[] memory swapIndexes = ownerSwaps[swapOwner];
        return swapIndexes.length;
    }

    /// fallback function
    fallback() external payable {
    }

    // receive function
    receive() external payable {
    }

    /// Set the fee for creating a swappable
    function setSwapFee(uint256 _swapFee) public onlyOwner {
        swapFee = _swapFee;
    }

    /// Transfer specified amount of funds in this contract to a destination address
    function transferFunds(address payable _destination, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "_amount is greater than the balance in this account");
        _destination.transfer(_amount);
    }

    /// get full detail from a swap
    function swapsGrid(uint256 _index) public view
        returns(uint256 swapId, uint256 expiry,  uint256[] memory to, uint256[] memory from, address fromAddress, address toAddress)
    {
        return (
            _index,
            swaps[_index]._expiry,
            swaps[_index]._to,
            swaps[_index]._from,
            swaps[_index]._fromAddress,
            swaps[_index]._toAddress);
    }

    /// Create a swap
    function createSwap(
        address _fromAddress,
        address _toAddress,
        address[] memory _fromContracts,
        uint256[] memory _fromTokenIds,
        uint256[] memory _fromAmount,
        Standard[] memory _fromStandards,
        address[] memory _toContracts,
        uint256[] memory _toTokenIds,
        uint256[] memory _toAmount,
        Standard[] memory _toStandards,
        uint256 _expiry
    ) public payable {
        require(_fromContracts.length > 0 && _fromTokenIds.length > 0 && _fromStandards.length > 0,
            'from parameters must be greater than zero');
        require(_fromContracts.length == _fromTokenIds.length && _fromContracts.length == _fromStandards.length,
            'from parameters must be the same size');
        require(_toContracts.length > 0 && _toTokenIds.length > 0 && _toStandards.length > 0,
            'to parameters must be greater than zero');
        require(_toContracts.length == _toTokenIds.length && _toContracts.length == _toStandards.length,
            'to parameters must be the same size');
        require(msg.value >= swapFee, 'eth value must be greater or equal to swapFee');
        require(_expiry > block.timestamp, 'expiry must be greater than block timestamp');

        // check to make sure that all from contract tokens are owned by fromAddress
        for (uint i=0; i<_fromContracts.length; i++) {
            if (_fromStandards[i] == Standard.ERC_1155) {
                ERC1155_Abstract erc1155 = ERC1155_Abstract(_fromContracts[i]);
                uint256 balance = erc1155.balanceOf(_fromAddress, _fromTokenIds[i]);
                require(balance >= _fromAmount[i], 'from address should own erc1155 tokens it is trying to swap');
            } else if (_fromStandards[i] == Standard.ERC_721) {
                ERC721_Abstract erc721 = ERC721_Abstract(_fromContracts[i]);
                address _tokenOwner = erc721.ownerOf(_fromTokenIds[i]);
                require(_fromAddress == _tokenOwner, 'from address should be erc721 owner');
            } else if (_fromStandards[i] == Standard.ERC_20) {
                ERC20_Abstract erc20 = ERC20_Abstract(_fromContracts[i]);
                uint256 balance = erc20.balanceOf(_fromAddress);
                require(balance >= _fromAmount[i], 'from address should own erc20 tokens it is trying to swap');
            }
        }

        //  check to make sure that all to contract tokens are owned by toAddress
        for (uint i=0; i<_toContracts.length; i++) {
            if (_toStandards[i] == Standard.ERC_1155) {
                ERC1155_Abstract erc1155 = ERC1155_Abstract(_toContracts[i]);
                uint256 balance = erc1155.balanceOf(_toAddress, _toTokenIds[i]);
                require(balance >= _toAmount[i], 'to address should own erc1155 tokens it is trying to swap');
            } else if (_toStandards[i] == Standard.ERC_721) {
                ERC721_Abstract erc721 = ERC721_Abstract(_toContracts[i]);
                address _tokenOwner = erc721.ownerOf(_toTokenIds[i]);
                require(_toAddress == _tokenOwner, 'to address should be erc721 owner');
            } else if (_toStandards[i] == Standard.ERC_20) {
                // TODO @rmageden for some reason the balance is being challenged on local network in app
                ERC20_Abstract erc20 = ERC20_Abstract(_toContracts[i]);
                uint256 balance = erc20.balanceOf(_toAddress);
                require(balance >= _toAmount[i], 'to address should own erc20 tokens it is trying to swap');
            }
        }

        // From Tokens
        uint[] memory _fromTokenTracker = new uint[](_fromContracts.length);
        for (uint i = 0; i < _fromContracts.length; i++) {
            tokenCount++;
            tokens[tokenCount] = Token(
                _fromContracts[i],
                _fromTokenIds[i],
                _fromAmount[i],
                _fromStandards[i]
            );
            _fromTokenTracker[i] = tokenCount;
        }

        // To Tokens
        uint[] memory _toTokenTracker = new uint[](_toContracts.length);
        for (uint i = 0; i < _toContracts.length; i++) {
            tokenCount++;
            tokens[tokenCount] = Token(
                _toContracts[i],
                _toTokenIds[i],
                _toAmount[i],
                _toStandards[i]
            );
            _toTokenTracker[i] = tokenCount;
        }

        // Add Swap Record
        swapCount++;
        swaps[swapCount] = Swap({
            _fromAddress: _fromAddress,
            _toAddress: _toAddress,
            _expiry : _expiry,
            _from : new uint256[](0),
            _to : new uint256[](0)
            }
        );
        for (uint i = 0; i < _toTokenTracker.length; i++) {
            swaps[swapCount]._to.push(_toTokenTracker[i]);
        }
        for (uint i = 0; i < _fromTokenTracker.length; i++) {
            swaps[swapCount]._from.push(_fromTokenTracker[i]);
        }

        // Add Owner Record
        ownerSwaps[msg.sender].push(swapCount);
        emit SwapCreated(_fromAddress, _toAddress, swapCount);
    }

    /// Execute the swap
    function executeSwap(uint256 swapId) public {
        Swap memory swap = swaps[swapId];
        require(msg.sender == swap._toAddress, 'swap executor must own the wallet specified in the creation of the swap');

        // To Token Swap
        for (uint i=0; i<swap._to.length; i++) {
            uint256 index = swap._to[i];
            Token memory token = tokens[index];
            if (token._standard == Standard.ERC_1155) {
                erc1155SafeTransferFrom(
                    token._contract,
                    swap._toAddress,
                    swap._fromAddress,
                    token._tokenId,
                    token._amount
                );
            } else if (token._standard == Standard.ERC_721) {
                erc721SafeTransferFrom(
                    token._contract,
                    swap._toAddress,
                    swap._fromAddress,
                    token._tokenId
                );
            } else if (token._standard == Standard.ERC_20) {
                erc20TransferFrom(
                    token._contract,
                    swap._toAddress,
                    swap._fromAddress,
                    token._amount);
            }
        }

        // From Token Swap
        for (uint i=0; i<swap._from.length; i++) {
            uint256 index = swap._from[i];
            Token memory token = tokens[index];
            if (token._standard == Standard.ERC_1155) {
                erc1155SafeTransferFrom(
                    token._contract,
                    swap._fromAddress,
                    swap._toAddress,
                    token._tokenId,
                    token._amount
                );
            } else if (token._standard == Standard.ERC_721) {
                erc721SafeTransferFrom(
                    token._contract,
                    swap._fromAddress,
                    swap._toAddress,
                    token._tokenId
                );
            } else if (token._standard == Standard.ERC_20) {
                erc20TransferFrom(
                    token._contract,
                    swap._fromAddress,
                    swap._toAddress,
                    token._amount);
            }
        }

        emit SwapExecuted(swapId, swap);
    }

    function erc1155SafeTransferFrom(
        address _contractAddress,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount) private {

        ERC1155_Abstract erc1155 = ERC1155_Abstract(_contractAddress);
        erc1155.safeTransferFrom(_from, _to, _tokenId, _amount, '');
    }

    function erc721SafeTransferFrom(
        address _contractAddress,
        address _from,
        address _to,
        uint256 _tokenId
    ) private {

        ERC721_Abstract erc721 = ERC721_Abstract(_contractAddress);
        erc721.safeTransferFrom(_from, _to, _tokenId);
    }

    function erc20TransferFrom(
        address _contractAddress,
        address _from,
        address _to,
        uint256 _amount
    ) private {

        ERC20_Abstract erc20 = ERC20_Abstract(_contractAddress);
        erc20.transferFrom(_from, _to, _amount);
    }
}


abstract contract ERC1155_Abstract {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual;

    function balanceOf(address _address, uint256 _tokenId) public virtual view returns(uint256 _balance);
}

abstract contract ERC721_Abstract {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function ownerOf(uint256 tokenId) public virtual view returns(address _address);
}

abstract contract ERC20_Abstract {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual;

    function balanceOf(address owner) public virtual view returns(uint256 _balance);
}