/**
 *Submitted for verification at polygonscan.com on 2021-09-18
*/

// SPDX-License-Identifier: MIT
  pragma solidity 0.8.4;

  library SafeMath {

    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
      // benefit is lost if 'b' is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
      if (a == 0) {
        return 0;
      }

      uint256 c = a * b;
      require(c / a == b, "SafeMath#mul: OVERFLOW");

      return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      // Solidity only automatically asserts when dividing by 0
      require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold

      return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a, "SafeMath#sub: UNDERFLOW");
      uint256 c = a - b;

      return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a, "SafeMath#add: OVERFLOW");

      return c; 
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
      return a % b;
    }

  }

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
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

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
    function balanceOf(address account, uint256 id) external view returns (uint256);

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
    function isApprovedForAll(address account, address operator) external view returns (bool);

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


  interface LinkTokenInterface {

    function allowance(
      address owner,
      address spender
    )
      external
      view
      returns (
        uint256 remaining
      );

    function approve(
      address spender,
      uint256 value
    )
      external
      returns (
        bool success
      );

    function balanceOf(
      address owner
    )
      external
      view
      returns (
        uint256 balance
      );

    function decimals()
      external
      view
      returns (
        uint8 decimalPlaces
      );

    function decreaseApproval(
      address spender,
      uint256 addedValue
    )
      external
      returns (
        bool success
      );

    function increaseApproval(
      address spender,
      uint256 subtractedValue
    ) external;

    function name()
      external
      view
      returns (
        string memory tokenName
      );

    function symbol()
      external
      view
      returns (
        string memory tokenSymbol
      );

    function totalSupply()
      external
      view
      returns (
        uint256 totalTokensIssued
      );

    function transfer(
      address to,
      uint256 value
    )
      external
      returns (
        bool success
      );

    function transferAndCall(
      address to,
      uint256 value,
      bytes calldata data
    )
      external
      returns (
        bool success
      );

    function transferFrom(
      address from,
      address to,
      uint256 value
    )
      external
      returns (
        bool success
      );

  }

  contract VRFRequestIDBase {

    /**
     * @notice returns the seed which is actually input to the VRF coordinator
     *
     * @dev To prevent repetition of VRF output due to repetition of the
     * @dev user-supplied seed, that seed is combined in a hash with the
     * @dev user-specific nonce, and the address of the consuming contract. The
     * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
     * @dev the final seed, but the nonce does protect against repetition in
     * @dev requests which are included in a single block.
     *
     * @param _userSeed VRF seed input provided by user
     * @param _requester Address of the requesting contract
     * @param _nonce User-specific nonce at the time of the request
     */
    function makeVRFInputSeed(
      bytes32 _keyHash,
      uint256 _userSeed,
      address _requester,
      uint256 _nonce
    )
      internal
      pure
      returns (
        uint256
      )
    {
      return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    /**
     * @notice Returns the id for this request
     * @param _keyHash The serviceAgreement ID to be used for this request
     * @param _vRFInputSeed The seed to be passed directly to the VRF
     * @return The id for this request
     *
     * @dev Note that _vRFInputSeed is not the seed passed by the consuming
     * @dev contract, but the one generated by makeVRFInputSeed
     */
    function makeRequestId(
      bytes32 _keyHash,
      uint256 _vRFInputSeed
    )
      internal
      pure
      returns (
        bytes32
      )
    {
      return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
  }
  /** ****************************************************************************
   * @notice Interface for contracts using VRF randomness
   * *****************************************************************************
   * @dev PURPOSE
   *
   * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
   * @dev to Vera the verifier in such a way that Vera can be sure he's not
   * @dev making his output up to suit himself. Reggie provides Vera a public key
   * @dev to which he knows the secret key. Each time Vera provides a seed to
   * @dev Reggie, he gives back a value which is computed completely
   * @dev deterministically from the seed and the secret key.
   *
   * @dev Reggie provides a proof by which Vera can verify that the output was
   * @dev correctly computed once Reggie tells it to her, but without that proof,
   * @dev the output is indistinguishable to her from a uniform random sample
   * @dev from the output space.
   *
   * @dev The purpose of this contract is to make it easy for unrelated contracts
   * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
   * @dev simple access to a verifiable source of randomness.
   * *****************************************************************************
   * @dev USAGE
   *
   * @dev Calling contracts must inherit from VRFConsumerBase, and can
   * @dev initialize VRFConsumerBase's attributes in their constructor as
   * @dev shown:
   *
   * @dev   contract VRFConsumer {
   * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
   * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
   * @dev         <initialization with other arguments goes here>
   * @dev       }
   * @dev   }
   *
   * @dev The oracle will have given you an ID for the VRF keypair they have
   * @dev committed to (let's call it keyHash), and have told you the minimum LINK
   * @dev price for VRF service. Make sure your contract has sufficient LINK, and
   * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
   * @dev want to generate randomness from.
   *
   * @dev Once the VRFCoordinator has received and validated the oracle's response
   * @dev to your request, it will call your contract's fulfillRandomness method.
   *
   * @dev The randomness argument to fulfillRandomness is the actual random value
   * @dev generated from your seed.
   *
   * @dev The requestId argument is generated from the keyHash and the seed by
   * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
   * @dev requests open, you can use the requestId to track which seed is
   * @dev associated with which randomness. See VRFRequestIDBase.sol for more
   * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
   * @dev if your contract could have multiple requests in flight simultaneously.)
   *
   * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
   * @dev differ. (Which is critical to making unpredictable randomness! See the
   * @dev next section.)
   *
   * *****************************************************************************
   * @dev SECURITY CONSIDERATIONS
   *
   * @dev A method with the ability to call your fulfillRandomness method directly
   * @dev could spoof a VRF response with any random value, so it's critical that
   * @dev it cannot be directly called by anything other than this base contract
   * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
   *
   * @dev For your users to trust that your contract's random behavior is free
   * @dev from malicious interference, it's best if you can write it so that all
   * @dev behaviors implied by a VRF response are executed *during* your
   * @dev fulfillRandomness method. If your contract must store the response (or
   * @dev anything derived from it) and use it later, you must ensure that any
   * @dev user-significant behavior which depends on that stored value cannot be
   * @dev manipulated by a subsequent VRF request.
   *
   * @dev Similarly, both miners and the VRF oracle itself have some influence
   * @dev over the order in which VRF responses appear on the blockchain, so if
   * @dev your contract could have multiple VRF requests in flight simultaneously,
   * @dev you must ensure that the order in which the VRF responses arrive cannot
   * @dev be used to manipulate your contract's user-significant behavior.
   *
   * @dev Since the ultimate input to the VRF is mixed with the block hash of the
   * @dev block in which the request is made, user-provided seeds have no impact
   * @dev on its economic security properties. They are only included for API
   * @dev compatability with previous versions of this contract.
   *
   * @dev Since the block hash of the block which contains the requestRandomness
   * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
   * @dev miner could, in principle, fork the blockchain to evict the block
   * @dev containing the request, forcing the request to be included in a
   * @dev different block with a different hash, and therefore a different input
   * @dev to the VRF. However, such an attack would incur a substantial economic
   * @dev cost. This cost scales with the number of blocks the VRF oracle waits
   * @dev until it calls responds to a request.
   */
  abstract contract VRFConsumerBase is VRFRequestIDBase {

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBase expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomness the VRF output
     */
    function fulfillRandomness(
      bytes32 requestId,
      uint256 randomness
    )
      internal
      virtual;

    /**
     * @dev In order to keep backwards compatibility we have kept the user
     * seed field around. We remove the use of it because given that the blockhash
     * enters later, it overrides whatever randomness the used seed provides.
     * Given that it adds no security, and can easily lead to misunderstandings,
     * we have removed it from usage and can now provide a simpler API.
     */
    uint256 constant private USER_SEED_PLACEHOLDER = 0;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of LINK to send with the request
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(
      bytes32 _keyHash,
      uint256 _fee
    )
      internal
      returns (
        bytes32 requestId
      )
    {
      LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
      // This is the seed passed to VRFCoordinator. The oracle will mix this with
      // the hash of the block containing this request to obtain the seed/input
      // which is finally passed to the VRF cryptographic machinery.
      uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
      // nonces[_keyHash] must stay in sync with
      // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
      // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
      // This provides protection against the user repeating their input seed,
      // which would result in a predictable/duplicate output, if multiple such
      // requests appeared in the same block.
      nonces[_keyHash] = nonces[_keyHash] + 1;
      return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface immutable internal LINK;
    address immutable private vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(
      address _vrfCoordinator,
      address _link
    ) {
      vrfCoordinator = _vrfCoordinator;
      LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(
      bytes32 requestId,
      uint256 randomness
    )
      external
    {
      require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
      fulfillRandomness(requestId, randomness);
    }
  }

  contract DNXILottery5 is VRFConsumerBase, Ownable {
      
      using SafeMath for uint256;
      
      uint256 public lotteryStart;
      uint256 public lotteryEnd;
      uint256 public totalNumberOfEntries;
      uint256 public totalNumberOfTickets;
      uint256 public numberOfWinners;

      IERC1155 dnxiToken;
      
      bytes32 internal keyHash;
      uint256 internal fee;

      mapping(address => uint256) lotteryEntryIndex;
      mapping(uint256 => address) lotteryEntryReversed;
      mapping(uint256 => uint256) lotteryEntries;
      mapping(uint256 => uint256) randomNumbers;
      mapping(uint256 => address) winners;
      uint256 randomCounts;
      
      address lotteryTreasury;

      bool paused;
      
      constructor(uint256 _lotteryStart, uint256 _lotteryEnd, uint256 _numberOfWinners,  IERC1155 _dnxiToken) VRFConsumerBase(
              0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
              0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
          ) 
       {
          keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
          fee = 0.0001 * 10 ** 18; // 0.1 LINK (Varies by network)
          
          lotteryStart = _lotteryStart;
          lotteryEnd = _lotteryEnd;
          totalNumberOfEntries = 0;
          totalNumberOfTickets = 0;
          numberOfWinners = _numberOfWinners;
          paused = true;
          
          lotteryTreasury = address(owner());
          
          dnxiToken = _dnxiToken;
      }
      
      function changeEndTime(uint256 endTime) public onlyOwner {
          lotteryEnd = endTime;
      }
      function changeStartTime(uint256 startTime) public onlyOwner {
          lotteryStart = startTime;
      }
      
      function entry(uint256 _amount) public {
          require (paused == false, "E01");
          require (block.timestamp >= lotteryStart, "E02");
          require (block.timestamp <= lotteryEnd, "E03");
          require (_amount > 0, "E04");
          bytes memory b = new bytes(0);
          dnxiToken.safeTransferFrom(msg.sender, address(lotteryTreasury), 1, _amount, b);
          
          if (lotteryEntryIndex[msg.sender] == 0) {
              totalNumberOfEntries = totalNumberOfEntries.add(1);
              lotteryEntryIndex[msg.sender] = totalNumberOfEntries;
              lotteryEntryReversed[totalNumberOfEntries] = msg.sender;
              lotteryEntries[totalNumberOfEntries - 1] = 0;
          }
          
          uint256 entryIndex = lotteryEntryIndex[msg.sender] - 1;
          lotteryEntries[entryIndex] = lotteryEntries[entryIndex].add(_amount);
          totalNumberOfTickets = totalNumberOfTickets.add(_amount);
      }
      
      /** 
       * Requests randomness for distribution
       */
      function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
          require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
          return requestRandomness(keyHash, fee);
      }
      
      function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
          randomNumbers[randomCounts] = randomness;
          randomCounts = randomCounts.add(1);
      }
      
      function getRandomAt(uint256 r) public view returns (uint256) {
          return randomNumbers[r];
      }
      
      
      function pickWinners() public onlyOwner {
          require(randomCounts >= numberOfWinners, "E04");
          for (uint256 i = 0; i < numberOfWinners; i++) {
              uint256 seed = randomNumbers[i];
              uint256 winningTicketIndex = seed % totalNumberOfTickets;
              uint256 countedIndex = 0;
              address winner = address(0);
              for (uint256 j = 0; j < totalNumberOfEntries; j++) {
                  countedIndex = countedIndex.add(lotteryEntries[j]);
                  if (countedIndex >= winningTicketIndex) {
                      winner = lotteryEntryReversed[j+1];
                      break;
                  }
              }
              winners[i] = winner;
          }
      }
      
      function setPaused(bool _paused) public onlyOwner {
          paused = _paused;
      }
      
      function getWinner(uint256 winnerId) public view returns (address) {
          return winners[winnerId];
      }
      
      function withdrawTickets() onlyOwner external {
          bytes memory b = new bytes(0);
          dnxiToken.safeTransferFrom(address(this), address(lotteryTreasury), 1, totalNumberOfTickets, b);
      }
      
      function withdrawFees() onlyOwner external {
          require(payable(msg.sender).send(address(this).balance));
      }
      
      function getTicketsAmountForAddress(address _user) public view returns (uint256) {
          return lotteryEntries[lotteryEntryIndex[_user]-1];
      }
      
      function getTotalEntries() public view returns (uint256) {
          return totalNumberOfTickets;
      }
  }