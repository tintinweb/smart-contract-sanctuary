/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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
  function _msgSender() internal virtual view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal virtual view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
// File: contracts/utils/Roles.sol

pragma solidity >=0.6.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

pragma solidity ^0.6.2;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
  /**
   * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
   */
  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  /**
   * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
   * transfers.
   */
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  /**
   * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
   * `approved`.
   */
  event ApprovalForAll(
    address indexed account,
    address indexed operator,
    bool approved
  );

  /**
   * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
   *
   * If an {URI} event was emitted for `id`, the standard
   * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
   * returned by {IERC1155MetadataURI-uri}.
   */
  event URI(string value, uint256 indexed id);

  /**
   * @dev Returns the amount of tokens of token type `id` owned by `account`.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256);

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns (uint256[] memory);

  /**
   * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
   *
   * Emits an {ApprovalForAll} event.
   *
   * Requirements:
   *
   * - `operator` cannot be the caller.
   */
  function setApprovalForAll(address operator, bool approved) external;

  /**
   * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(address account, address operator)
    external
    view
    returns (bool);

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

// File: contracts/ToshiDojo.sol



pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface ToshimonMinter {
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external;

  function setApprovalForAll(address _operator, bool _approved) external;

  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool isOperator);

  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  function totalSupply(uint256 _id) external view returns (uint256);

  function tokenMaxSupply(uint256 _id) external view returns (uint256);

  function burn(
    address _account,
    uint256 _id,
    uint256 _amount
  ) external;

  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) external;
  function mintBatch(address user, uint256[] calldata ids, uint256[] calldata amounts)
        external;
}

interface ToshiCoin {
  function totalSupply() external view returns (uint256);

  function totalClaimed() external view returns (uint256);

  function addClaimed(uint256 _amount) external;

  function setClaimed(uint256 _amount) external;

  function transfer(address receiver, uint256 numTokens)
    external
    returns (bool);

  function transferFrom(
    address owner,
    address buyer,
    uint256 numTokens
  ) external returns (bool);

  function balanceOf(address owner) external view returns (uint256);

  function mint(address _to, uint256 _amount) external;

  function burn(address _account, uint256 value) external;
}


contract ToshiDojo is Ownable {
  using SafeMath for uint256;

  ToshimonMinter public toshimonMinter;
  ToshiCoin public toshiCoin;
  uint256 public minterPackId;
  uint256 public packPriceInToshiCoin;
  uint256 public packsPurchased;
  uint256 public packsRedeemed;
  bytes private prevHash;

  uint256[] public probabilities;
  uint256[][] public cardRanges;
  uint256[] public probabilitiesRare;
  uint256[][] public cardRangesRare; 


  event Redeemed(
    address indexed _user,
    uint256[] indexed _cardIds,
    uint256[] indexed _quantities
  );

  constructor() public {
    toshimonMinter = ToshimonMinter(0xd2d2a84f0eB587F70E181A0C4B252c2c053f80cB);
    toshiCoin = ToshiCoin(0x3EEfF4487F64bF73cd9D99e83D837B0Ef1F58247);
    minterPackId = 0;
    packPriceInToshiCoin = 1000000000000000000;
    prevHash = abi.encodePacked(block.timestamp, msg.sender);
    probabilities = [350,600,780,930,980,995,1000];
    cardRanges = [[uint256(1),uint256(102)],[uint256(103),uint256(180)],[uint256(181),uint256(226)],[uint256(227),uint256(248)],[uint256(249),uint256(258)],[uint256(259),uint256(263)],[uint256(264),uint256(264)]];
    probabilitiesRare = [700,930,980,995,1000];
    cardRangesRare = [[265,291],[292,307],[308,310],[311,311],[312,312]];


  }

  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'Not eoa');
    _;
  }

  function setMinterPackId(uint256 _minterPackId) external onlyOwner {
    minterPackId = _minterPackId;
  }


  function setPackPriceInToshiCoin(uint256 _packPriceInToshiCoin)
    external
    onlyOwner
  {
    packPriceInToshiCoin = _packPriceInToshiCoin;
  }

  function tokenMaxSupply(uint256 _cardId) external view returns (uint256) {
    return toshimonMinter.tokenMaxSupply(_cardId);
  }

  function totalSupply(uint256 _cardId) external view returns (uint256) {
    return toshimonMinter.totalSupply(_cardId);
  }


  function addPack(
    uint256[] memory _probabilities,
    uint256[][] memory _cardRanges,
    uint256[] memory _probabilitiesRare,
    uint256[][] memory _cardRangesRare
    
  ) public onlyOwner {
    require(_probabilities.length > 0, 'probabilities cannot be empty');
    require(_cardRanges.length > 0, 'cardRanges cannot be empty');
    require(_probabilitiesRare.length > 0, 'probabilities rare cannot be empty');
    require(_cardRangesRare.length > 0, 'cardRanges rare cannot be empty');


    probabilities = _probabilities;
    cardRanges = _cardRanges;
    probabilitiesRare = _probabilitiesRare;
    cardRangesRare = _cardRangesRare;


  }

  function updateprobabilities(uint256[] memory _probabilities)
    external
    onlyOwner
  {
    probabilities = _probabilities;
  }

  function updateCardRanges(uint256[][] memory _cardRanges)
    external
    onlyOwner
  {
    cardRanges = _cardRanges;
  }
    function updateProbabilitiesRare(uint256[] memory _probabilitiesRare)
    external
    onlyOwner
  {
    probabilitiesRare = _probabilitiesRare;
  }

  function updateCardRangesRare(uint256[][] memory _cardRangesRare)
    external
    onlyOwner
  {
    cardRangesRare = _cardRangesRare;
  }





  // Purchase one or more card packs for the price in ToshiCoin
  function purchasePack(uint256 amount) public {
    require(packPriceInToshiCoin > 0, 'Pack does not exist');
    require(
      toshiCoin.balanceOf(msg.sender) >= packPriceInToshiCoin.mul(amount),
      'Not enough toshiCoin for pack'
    );

    toshiCoin.burn(msg.sender, packPriceInToshiCoin.mul(amount));
    packsPurchased = packsPurchased.add(amount);
    toshimonMinter.mint(msg.sender, minterPackId, amount, '');
  }
  
  // Redeem a random card pack (Not callable by contract, to prevent exploits on RNG)

  function redeemPack(uint256 _packsToRedeem) external {
     require(
      toshimonMinter.balanceOf(msg.sender, minterPackId) >= _packsToRedeem,
      'Not enough pack tokens'
    );

    toshimonMinter.burn(msg.sender, minterPackId, _packsToRedeem);

    uint256 probability;
    uint256 max;
    uint256 min; 
    uint256[] memory _cardsToMint = new uint256[](312);
    uint256[] memory _cardsToMintCount = new uint256[](312);
    uint256 cardIdWon;
    uint256 rng = _rngSimple(_rng());


    for (uint256 i = 0; i < _packsToRedeem; ++i) {

      for (uint256 j = 0; j < 7; ++j) {
          probability = rng % 1000;
          for (uint256 _probIndex = 0; _probIndex < probabilities.length; ++_probIndex) {
            if(probability < probabilities[_probIndex]){
              max = cardRanges[_probIndex][1];
              min = cardRanges[_probIndex][0];
              break;
            }
          }
          rng = _rngSimple(rng);
          cardIdWon = (rng % (max + 1 - min)) + min;
          _cardsToMint[cardIdWon - 1] = cardIdWon;
          _cardsToMintCount[cardIdWon - 1] = _cardsToMintCount[cardIdWon - 1] + 1;
      }
      
      // run for rare packs start
      probability = rng % 1000;
      for (uint256 _probIndex = 0; _probIndex < probabilitiesRare.length; ++_probIndex) {
        if(probability < probabilitiesRare[_probIndex]){
          max = cardRangesRare[_probIndex][1];
          min = cardRangesRare[_probIndex][0];
          break;
        }
      }
      rng = _rngSimple(rng);
      cardIdWon = (rng % (max + 1 - min)) + min;
      _cardsToMint[cardIdWon - 1] = cardIdWon;
      _cardsToMintCount[cardIdWon - 1] = _cardsToMintCount[cardIdWon - 1] + 1;
    }
    
    
    emit Redeemed(msg.sender,_cardsToMint,_cardsToMintCount);
    toshimonMinter.mintBatch(msg.sender,_cardsToMint,_cardsToMintCount);
  }
  
  
  // Utility function to check if a value is inside an array
  function _isInArray(uint256 _value, uint256[] memory _array)
    internal
    pure
    returns (bool)
  {
    uint256 length = _array.length;
    for (uint256 i = 0; i < length; ++i) {
      if (_array[i] == _value) {
        return true;
      }
    }

    return false;
  }


  // This is a pseudo random function, but considering the fact that redeem function is not callable by contract,
  // and the fact that ToshiCoin is not transferable, this should be enough to protect us from an attack
  // I would only expect a miner to be able to exploit this, and the attack cost would not be worth it in our case
  function _rng() internal returns (uint256) {
    bytes32 ret = keccak256(prevHash);
    prevHash = abi.encodePacked(ret,block.coinbase,msg.sender);
    return uint256(ret);
  }
  function _rngSimple(uint256 seed) internal pure returns (uint256) {

    return uint256(keccak256(abi.encodePacked(seed)));
  }
}