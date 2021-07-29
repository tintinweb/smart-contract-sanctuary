//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';
import './IERC721TokenCreator.sol';
import './IERC721Creator.sol';

/**
 * @dev Registry token creators and tokens that implement iERC721Creator
 * @notice Thanks SuperRare! There is no afflication between SuperRare and 1stDibs
 */
contract FirstDibsCreatorRegistry is Ownable, IERC721TokenCreator {
    /**
     * @dev contract address => token ID mapping to payable creator address
     */
    mapping(address => mapping(uint256 => address payable)) private tokenCreators;

    /**
     * @dev Mapping of addresses that implement IERC721Creator.
     */
    mapping(address => bool) public iERC721Creators;

    /**
     * @dev Initializes the contract setting the iERC721Creators with the provided addresses.
     * @param _iERC721CreatorContracts address[] to set as iERC721Creators.
     */
    constructor(address[] memory _iERC721CreatorContracts) public {
        require(
            _iERC721CreatorContracts.length < 1000,
            'constructor: Cannot mark more than 1000 addresses as IERC721Creator'
        );
        for (uint8 i = 0; i < _iERC721CreatorContracts.length; i++) {
            require(
                _iERC721CreatorContracts[i] != address(0),
                'constructor: Cannot set the null address as an IERC721Creator'
            );
            iERC721Creators[_iERC721CreatorContracts[i]] = true;
        }
    }

    /**
     * @dev Gets the creator of the _tokenId on _nftAddress
     * @param _nftAddress address of the ERC721 contract
     * @param _tokenId uint256 ID of the token
     * @return payble address of the creator
     */
    function tokenCreator(address _nftAddress, uint256 _tokenId)
        external
        view
        override
        returns (address payable)
    {
        if (tokenCreators[_nftAddress][_tokenId] != address(0)) {
            return tokenCreators[_nftAddress][_tokenId];
        }

        if (iERC721Creators[_nftAddress]) {
            return IERC721Creator(_nftAddress).tokenCreator(_tokenId);
        }

        return address(0);
    }

    /**
     * @dev Sets _creator of the _tokenId on _nftAddress
     * @param _nftAddress address of the token contract
     * @param _creator payble address of the creator
     * @param _tokenId uint256 ID of the token
     */
    function setTokenCreator(
        address _nftAddress,
        address payable _creator,
        uint256 _tokenId
    ) external onlyOwner {
        require(
            _nftAddress != address(0),
            'FirstDibsCreatorRegistry: token address cannot be null'
        );
        require(_creator != address(0), 'FirstDibsCreatorRegistry: creator address cannot be null');
        tokenCreators[_nftAddress][_tokenId] = _creator;
    }

    /**
     * @dev Set an address as an IERC721Creator
     * @param _nftAddress address of the IERC721Creator contract
     */
    function setIERC721Creator(address _nftAddress) external onlyOwner {
        require(
            _nftAddress != address(0),
            'FirstDibsCreatorRegistry: token address cannot be null'
        );
        iERC721Creators[_nftAddress] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.6.12;

/**
 * @title IERC721 Non-Fungible Token Creator basic interface
 * @dev Interop with other systems supporting this interface
 * @notice Original license and source here: https://github.com/Pixura/pixura-contracts
 */
interface IERC721TokenCreator {
    /**
     * @dev Gets the creator of the _tokenId on _nftAddress
     * @param _nftAddress address of the ERC721 contract
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.6.12;

/**
 * @title IERC721 Non-Fungible Token Creator basic interface
 * @dev Interop with other systems supporting this interface
 * @notice Original license and source here: https://github.com/Pixura/pixura-contracts
 */
interface IERC721Creator {
    /**
     * @dev Gets the creator of the _tokenId
     * @param _tokenId uint256 ID of the token
     * @return address of the creator of _tokenId
     */
    function tokenCreator(uint256 _tokenId) external view returns (address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1348
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}