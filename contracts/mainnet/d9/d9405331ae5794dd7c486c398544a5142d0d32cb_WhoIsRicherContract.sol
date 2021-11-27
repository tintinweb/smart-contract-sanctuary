/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: contracts/WhoIsRicher.sol


pragma solidity ^0.8.7;




contract WhoIsRicherContract is Context, Ownable, ERC165 {
  string _name = 'WhoIsRicher';
  string _symbol = 'WIR';
  string _tokenURI = 'https://cdn.whoisricher.io/metadata.json';

  address _richest;
  uint256 _wealth = 0 ether;
  address _communityWinner;
  uint8 _communitySharePercentage = 2;

  mapping(address => uint256) _pendingWithdrawals;

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId,
    uint256 wealth
  );

  event CommunityWinnerChanged(address indexed to);

  event CommunitySharePercentageChanged(uint8 percentage);

  constructor() {
    _richest = owner();
    _communityWinner = _richest;

    emit Transfer(address(0), _richest, 1, 0 ether);
    emit CommunityWinnerChanged(_richest);
    emit CommunitySharePercentageChanged(_communitySharePercentage);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(tokenId == 1, 'TokenURI query for nonexistent token');
    return _tokenURI;
  }

  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), 'Balance query for the zero address');
    if (owner == _richest) return 1;
    return 0;
  }

  function ownerOf(uint256 tokenId) public view returns (address owner) {
    require(tokenId == 1, 'OwnerOf query for nonexistent token');
    return _richest;
  }

  function wealth() public view returns (uint256) {
    return _wealth;
  }

  function minimumBid() public view returns (uint256) {
    return _minimumBid();
  }

  function renounceOwnership() public virtual override onlyOwner {
    require(false, 'Renouncing not allowed');
  }

  function becomeRichest() public payable {
    address sender = _msgSender();
    require(sender != _richest, 'You are already the richest!');
    require(msg.value >= _minimumBid(), 'Minimal amount not reached');

    address previousRichest = _richest;

    uint256 deltaWealth = msg.value - _wealth;
    uint256 richestShare = (deltaWealth * 75) / 100;
    uint256 communityShare = (deltaWealth * _communitySharePercentage) / 100;
    uint256 developerShare = deltaWealth - (richestShare + communityShare);

    _pendingWithdrawals[previousRichest] += _wealth + richestShare;
    _pendingWithdrawals[_communityWinner] += communityShare;
    _pendingWithdrawals[owner()] += developerShare;

    _richest = sender;
    _wealth = msg.value;

    emit Transfer(previousRichest, _richest, 1, _wealth);
  }

  function withdraw() public {
    address sender = _msgSender();
    uint256 amount = _pendingWithdrawals[sender];
    require(amount > 0, 'No pending withdrawals');

    _pendingWithdrawals[sender] = 0;
    payable(sender).transfer(amount);
  }

  function setCommunityWinner(address newCommunityWinner)
    public
    onlyOwner
    returns (address)
  {
    require(
      _communityWinner != newCommunityWinner,
      'New community winner has to be someone new'
    );
    _communityWinner = newCommunityWinner;

    emit CommunityWinnerChanged(_communityWinner);
    return _communityWinner;
  }

  function setCommunitySharePercentage(uint8 communitySharePercentage)
    public
    onlyOwner
    returns (uint8)
  {
    require(
      communitySharePercentage <= 25,
      'Community share has to be equal or below 25 in order to not cut from title holders'
    );
    _communitySharePercentage = communitySharePercentage;

    emit CommunitySharePercentageChanged(_communitySharePercentage);

    return _communitySharePercentage;
  }

  function getCommunityWinner() public view returns (address) {
    return _communityWinner;
  }

  function getWithdrawableAmount() public view returns (uint256) {
    return _pendingWithdrawals[_msgSender()];
  }

  function _minimumBid() private view returns (uint256) {
    return (_wealth * 11) / 10;
  }
}