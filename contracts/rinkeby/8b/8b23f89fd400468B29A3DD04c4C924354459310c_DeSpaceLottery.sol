/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT

//DeSpace NFT Lottery Contract 2021.10 */
//** Author: Henry Onyebuchi */

pragma solidity 0.8.4;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}



interface IDESNFT is IERC721 {
    /**
     * @dev Returns true if "addr" is an admin 
     */
    function isAdmin(address addr) external view returns (bool);

    /**
     * @dev Returns true if "addr" is a super admin 
     */
    function hasRole(bytes32 role, address addr) external view returns (bool);
}

contract DeSpaceLottery is 
    VRFConsumerBase, 
    ERC721Holder {

    //State Variables
    IDESNFT desNFT;
    IERC721 nft;
    IERC20 token;
    uint public dropIds;
    uint fee;
    bytes32 keyHash;
    address payable public platformWallet;

    //struct
    struct Lottery {
        address nft;
        address holder;
        uint[] nftIds;
        uint[] winners;
        uint price;
        uint period;
        uint tickets;
        uint trials;
        uint desPerTicket;
    }

    struct User {
        uint deposits;
        uint release;
    }

    mapping(uint => Lottery) public lotteries;
    mapping(address => User) public users;
    mapping(bytes32 => uint) requestIdToDrop;
    mapping(uint => mapping(address => bool)) played;
    mapping(uint => mapping(uint => address)) numToPlayer;

    event NewLottery(
        address indexed creator,
        address indexed nft,
        address indexed holder,
        uint[] tokenId, 
        uint length,
        uint tickets,
        uint price, 
        uint endTimeStamp
    );  
    
    event VerifiableResult(
        uint indexed dropId,
        uint[] winners,
        uint price,
        bytes32 requestId
    );

    event Claimed(
        address indexed user,
        address indexed nft,
        uint tokenId,
        uint value
    );
    
    event PlatformWalletSet(
        address admin, 
        address newPlatformWallet
    );

    event NewDeposit(
        address indexed user,
        uint amount
    );

    event DepositWithdrawn(
        address indexed user,
        uint amount
    );

    /** On RINKEBY 
      * Item	Value
      * LINK	0x01BE23585060835E02B77ef475b0Cc51aA1e0709
      * VRF Coordinator	0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
      * Key Hash	0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
      * Fee	0.1 LINK
      */
    constructor(
        address vrfCoordinator, 
        address link, 
        address _nft,
        address _token,
        address _platformWallet)
        VRFConsumerBase(vrfCoordinator, link) {
        
        desNFT = IDESNFT(_nft);
        token = IERC20(_token);
        platformWallet = payable(_platformWallet);
        fee = 0.1 * 10 ** 18;         //0.1 LINK
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
    }

    //modifier for only super admin call
    modifier onlyNFTAdmin() {

        require(
            desNFT.isAdmin(msg.sender),
            "Error: only NFT admin can call"
        );

        _;
    }

    //Modifier to check all conditions are met before bid
    modifier buyConditions(
        uint _dropId) {
        
        Lottery memory lottery = lotteries[_dropId];
        
        require(
            lottery.period != 0, 
            "Error: lottery does not exist"
        );

        require(
            lottery.period > block.timestamp, 
            "Error: lottery has ended"
        );

        require(
            !played[_dropId][msg.sender],
            "Error: can only play once"
        );

        uint slots = getSlot(_dropId, msg.sender);
        
        require(
            slots > 0, 
            "Error: Not enough staked DES"
        );

        _;
    }

    function createDrop(
        address _nft,
        address _holder,
        uint[] memory _tokenIds,
        uint _price,
        uint _numOfTickts,
        uint _desPerTicket,
        uint _seconds
        ) external onlyNFTAdmin() returns(uint dropID) {

        require(
            _nft != address(0)
            && _holder != address(0),  
            "Error: cannot input the zero address"
        );

        require(
            _price != 0 
            && _seconds != 0
            && _numOfTickts != 0
            && _desPerTicket != 0,
            "Error: cannot input 0 values"
        );

        dropIds++;
        dropID = dropIds;
        Lottery storage lottery = lotteries[dropID];
        
        for (uint i; i < _tokenIds.length; i++) {
            require(
                IERC721(_nft).ownerOf(_tokenIds[i]) == _holder,
                "Error: holder does not own NFT"
            );
            lottery.nftIds.push(_tokenIds[i]);
        }
        
        lottery.nft = _nft;
        lottery.holder = _holder;
        lottery.price = _price;
        lottery.tickets = _numOfTickts;
        lottery.period = block.timestamp + _seconds;
        lottery.desPerTicket = _desPerTicket;
        
        emit NewLottery(
            msg.sender,
            _nft,
            _holder,
            _tokenIds, 
            _tokenIds.length,
            _numOfTickts,
            _price, 
            lottery.period
        );
    }

    function deposit(
        uint _amount
        ) external returns(bool success) {

        require(
            _amount > 0,
            "Error: cannot deposit 0 value"
        );

        require(
            token.transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Error: failed when collecting tokens from user"
        );

        users[msg.sender].deposits += _amount;

        emit NewDeposit(
            msg.sender,
            _amount
        );

        return true;
    }

    function withdrawDeposit(
        uint _amount
        ) external returns(bool success) {

        User storage user = users[msg.sender];

        require(
            _amount <= user.deposits,
            "Error: not enough balance to withdraw"
        );

        require(
            block.timestamp >= user.release,
            "Error: locked. come back after lottery"
        );

        user.deposits -= _amount;
        
        require(
            token.transfer(
                msg.sender,
                _amount
            ),
            "Error: failed when sending tokens to user"
        );

        emit DepositWithdrawn(
            msg.sender,
            _amount
        );

        return true;
    }

    function playLottery(
        uint _dropId) 
        external buyConditions(_dropId) returns(uint[] memory tickets) {
        
        Lottery storage lottery = lotteries[_dropId];
        
        played[_dropId][msg.sender] = true;
        uint trials = lottery.trials;
        uint slots = getSlot(_dropId, msg.sender);

        users[msg.sender].release += (block.timestamp + 2 days);

        for (uint i = trials; i < trials + slots; i++) {
            uint ticket = i + 1;
            numToPlayer[_dropId][ticket] = msg.sender;
            lottery.trials++;
            tickets[i] = ticket;
        }
    }

    function closeLottery(
        uint _dropId
        ) external onlyNFTAdmin() returns(bytes32 requestId){
        
        Lottery storage lottery = lotteries[_dropId];

        require(
            lottery.period != 0, 
            "Error: lottery does not exist"
        );

        require(
            lottery.period <= block.timestamp, 
            "Lottery has not ended"
        );

        require(
            LINK.balanceOf(address(this)) >= fee, 
            "Not enough LINK to pay fee"
        );

        requestId = requestRandomness(
            keyHash, fee
        );

        requestIdToDrop[requestId] = _dropId;
    }

    function fulfillRandomness(
        bytes32 requestId, 
        uint randomness) 
        internal override {

        uint dropId = requestIdToDrop[requestId];

        Lottery storage lottery = lotteries[dropId];
        
        uint[] memory winners = _expand(
            randomness, 
            lottery
        );

        lottery.winners = winners;

        emit VerifiableResult(
            dropId,
            winners,
            lottery.price, 
            requestId
        );
    }

    function claimWin(
        uint _dropId
        ) external payable {

        Lottery storage lottery = lotteries[_dropId];

        require(
            played[_dropId][msg.sender],
            "Error: only lottery participants"
        );

        require(
            lottery.price == msg.value,
            "Error: must send correct value"
        );

        platformWallet.transfer(msg.value);

        address[] memory winners = getWinners(_dropId);

        for (uint i = 0; i < winners.length; i++) {
            if (winners[i] == msg.sender) {
                
                numToPlayer[_dropId][lottery.winners[i]] = address(0);

                IERC721(lottery.nft).transferFrom(
                    lottery.holder,
                    msg.sender,
                    lottery.nftIds[i]
                );

                emit Claimed(
                    msg.sender,
                    lottery.nft,
                    lottery.nftIds[i],
                    msg.value
                );

                revert();
            }
        }
        revert("Not among winners or already claimed");
    }

    function getWinners(
        uint _dropId
        ) public view returns(address[] memory winners) {

        Lottery memory lottery = lotteries[_dropId];
        uint length = lottery.winners.length;

        if(length > 0) {
            for(uint i = 0; i < length; i++) {

                winners[i] = numToPlayer[_dropId][lottery.winners[i]];
            }
        }
    }

    function getSlot(
        uint _dropId,
        address _user
        ) public view returns(uint tickets) {

        Lottery memory lottery = lotteries[_dropId];
        uint total = users[_user].deposits;
        
        if (
            total > 0 
            && !played[_dropId][_user]
            && lottery.tickets != 0
        ) 
        return total / lottery.desPerTicket;
        return 0;
    }

    function _expand(
        uint randomValue, 
        Lottery memory lottery
        ) internal pure returns(
            uint[] memory expandedValues
        ) {
        
        uint n = lottery.nftIds.length;
        expandedValues = new uint[](n);

        for (uint i = 0; i < n; i++) {
            expandedValues[i] = (
                uint(
                    keccak256(
                        abi.encode(
                            randomValue, 
                            i
                        )
                    )
                ) + randomValue
            ) % lottery.tickets;
        }
        return expandedValues;
    }

    function setPlatformWallet(
        address _newPlatformWallet
        ) external onlyNFTAdmin() {
        
        require(
            _newPlatformWallet != platformWallet, 
            "Error: already receipient"
        );
        platformWallet = payable(_newPlatformWallet);
        emit PlatformWalletSet(msg.sender, _newPlatformWallet);
    }
}