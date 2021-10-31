// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

interface Factory {
    function mint(address) external;
}

interface Pass {
    function balanceOf(address) external view returns (uint256);
}

contract CCCStore is Ownable, VRFConsumerBase {
    Pass public pass;
    Factory public cccFactory;

    /**
        Numbers for CCC Factory
     */
    uint256 public constant maxCCC = 10000;

    /**
        Team withdraw fund
     */
    // claimed
    bool internal claimed = false;

    bytes32 internal keyHash;
    uint256 internal fee;

    /**
        Team allocated CCC
     */
    // CCC which is minted by the owner
    uint256 public preMintedCCC = 0;     //
    // MAX CCC which owner can mint
    uint256 public constant maxPreMintCCC = 50;

    /**
        Mint Pass
     */
    uint256 public newlyMintedCCCWithPass = 0;
    uint256 public constant maxCCCPerPass = 5;
    mapping(address => uint256) public mintedCCCOf;
    mapping(string => uint256) public whitelistNFTOwnerPasses;

    /**
        Scheduling
     */
    uint256 public openingHours;
    uint256 public constant operationSecondsForVIP =  60 * 30;//3600 * 9; // 9 hours
    uint256 public constant operationSeconds = 3600 * 48; // 24 hours

    /**
        Ticket
     */
    uint256 public ticketPrice = 0.00008 ether;
    uint256 public totalTickets = 0;
    mapping(address => ticket) public ticketsOf;
    struct ticket {
        uint256 index; // Incl
        uint256 amount;
    }

    /**
        Security
     */
    uint256 public constant maxMintPerTx = 30;

    /**
        Raffle
     */
    uint256 public raffleNumber;
    uint256 public offsetInSlot;
    uint256 public slotSize;
    uint256 public lastTargetIndex; // index greater than this is dis-regarded
    mapping(address => result) public resultOf;
    struct result {
        bool executed;
        uint256 validTicketAmount;
    }

    event SetPass(address pass);
    event SetCCCFactory(address cccFactory);
    event SetTicketPrice(uint256 price);
    event SetOpeningHours(uint256 openingHours);
    event SetWhitelistNFTOwnerPasses(string nft, uint256 amount);
    event MintWithPass(address account, uint256 amount, uint256 changes);
    event TakingTickets(address account, uint256 amount, uint256 changes);
    event RunRaffle(uint256 raffleNumber);
    event SetResult(
        address account,
        uint256 validTicketAmount,
        uint256 changes
    );
    event MintCCC(address account, uint256 mintRequestAmount);
    event Withdraw(address to);
    event SetChainlinkFee(uint256);
    event SetChainlinkKeyHash(bytes32);

    constructor() VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        ){
            keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
            fee = 0.1 * 10 ** 18;
        }

    modifier whenOpened() {
        require(
            block.timestamp >= openingHours + operationSecondsForVIP,
            "Store is not opened"
        );
        require(
            block.timestamp <
                openingHours + operationSecondsForVIP + operationSeconds,
            "Store is closed"
        );
        _;
    }

    modifier whenVIPOpened() {
        require(block.timestamp >= openingHours, "Store is not opened for VIP");
        require(
            block.timestamp < openingHours + operationSecondsForVIP,
            "Store is closed for VIP"
        );
        _;
    }

    function setPass(Pass _pass) external onlyOwner {
        pass = _pass;
        emit SetPass(address(_pass));
    }

    function setCCCFactory(Factory _cccFactory) external onlyOwner {
        cccFactory = _cccFactory;
        emit SetCCCFactory(address(_cccFactory));
    }

    function setTicketPrice(uint256 _price) external onlyOwner {
        ticketPrice = _price * 1 ether;
        emit SetTicketPrice(_price);
    }

    function setOpeningHours(uint256 _openingHours) external onlyOwner {
        openingHours = _openingHours;
        emit SetOpeningHours(_openingHours);
    }

    function setWhitelistNFTOwnerPasses(string calldata _nft, uint256 _amount) external onlyOwner {
        whitelistNFTOwnerPasses[_nft] = _amount;
        emit SetWhitelistNFTOwnerPasses(_nft, _amount);
    }

    // Do not update newlyMintedCCC to prevent withdrawal  // what is this
    function preMintCCC(address[] memory recipients) external onlyOwner {
        require(
            block.timestamp <
                openingHours + operationSecondsForVIP + operationSeconds,
            "Not available after ticketing period"
        );
        uint256 totalRecipients = recipients.length;

        require(
            totalRecipients > 0,
            "Number of recipients must be greater than 0"
        );
        require(
            preMintedCCC + totalRecipients <= maxPreMintCCC,
            "Exceeds max pre-mint CCC"
        );

        for (uint256 i = 0; i < totalRecipients; i++) {
            address to = recipients[i];
            require(to != address(0), "receiver can not be empty address");
            cccFactory.mint(to);
        }

        preMintedCCC += totalRecipients;
    }

    function mintWithPass(uint256 _amount) external payable whenVIPOpened {
        require(_amount <= maxMintPerTx, "mint amount exceeds maximum");
        require(_amount > 0, "Need to mint more than 0");

        uint256 mintedCCC = mintedCCCOf[msg.sender];
        uint256 passAmount = pass.balanceOf(msg.sender);
        require(
            passAmount * maxCCCPerPass - mintedCCC >= _amount,
            "Not enough Pass"
        );

        uint256 totalPrice = ticketPrice * _amount;
        require(totalPrice <= msg.value, "Not enough money");

        for (uint256 i = 0; i < _amount; i += 1) {
            cccFactory.mint(msg.sender);
        }

        mintedCCCOf[msg.sender] = mintedCCC + _amount;
        newlyMintedCCCWithPass += _amount;

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintWithPass(msg.sender, _amount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function takingTickets(uint256 _amount) external payable whenOpened {
        require(_amount > 0, "Need to take ticket more than 0");

        ticket storage myTicket = ticketsOf[msg.sender];
        require(myTicket.amount == 0, "Already registered");

        uint256 totalPrice = ticketPrice * _amount;
        require(totalPrice <= msg.value, "Not enough money");

        myTicket.index = totalTickets;
        myTicket.amount = _amount;

        totalTickets = totalTickets + _amount;

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit TakingTickets(msg.sender, _amount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function runRaffle(uint256 _raffleNumber) public onlyOwner {
        require(raffleNumber == 0, "raffle number is already set");

        raffleNumber = _raffleNumber;
        uint256 remainingCCC = maxCCC - preMintedCCC - newlyMintedCCCWithPass;

        // Hopefully consider that totalTickets number is more than remainingCCC
        // Actually this number can be controlled from team by taking tickets
        slotSize = totalTickets / remainingCCC;
        offsetInSlot = _raffleNumber % slotSize;
        lastTargetIndex = slotSize * remainingCCC - 1;

        emit RunRaffle(_raffleNumber);
    }

    function calculateValidTicketAmount(
        uint256 index,
        uint256 amount,
        uint256 _slotSize,
        uint256 _offsetInSlot,
        uint256 _lastTargetIndex
    ) internal pure returns (uint256 validTicketAmount) {
        /**

        /_____fio___\___________________________________/lio\___________
                v   f |         v     |         v     |     l   v     |
        ______slot #n__|___slot #n+1___|____slot #n+2__|____slot #n+3__|

            f : first index (incl.)
            l : last index (incl.)
            v : win ticket
            fio : first index offset
            lio : last index offset
            n, n+1,... : slot index
            
            v in (slot #n+1) is ths firstWinIndex
            v in (slot #n+2) is ths lastWinIndex
        */
        uint256 lastIndex = index + amount - 1; // incl.
        if (lastIndex > _lastTargetIndex) {
            lastIndex = _lastTargetIndex;
        }

        uint256 firstIndexOffset = index % _slotSize;
        uint256 lastIndexOffset = lastIndex % _slotSize;

        uint256 firstWinIndex;
        if (firstIndexOffset <= _offsetInSlot) {
            firstWinIndex = index + _offsetInSlot - firstIndexOffset;
        } else {
            firstWinIndex =
                index +
                _slotSize +
                _offsetInSlot -
                firstIndexOffset;
        }

        // Nothing is selected
        if (firstWinIndex > _lastTargetIndex) {
            validTicketAmount = 0;
        } else {
            uint256 lastWinIndex;
            if (lastIndexOffset >= _offsetInSlot) {
                lastWinIndex = lastIndex + _offsetInSlot - lastIndexOffset;
            } else if (lastIndex < _slotSize) {
                lastWinIndex = 0;
            } else {
                lastWinIndex =
                    lastIndex +
                    _offsetInSlot -
                    lastIndexOffset -
                    _slotSize;
            }

            if (firstWinIndex > lastWinIndex) {
                validTicketAmount = 0;
            } else {
                validTicketAmount =
                    (lastWinIndex - firstWinIndex) /
                    _slotSize +
                    1;
            }
        }
    }

    function calculateMyResult() external {
        require(raffleNumber > 0, "raffle number is not set yet");

        ticket storage myTicket = ticketsOf[msg.sender];
        require(myTicket.amount > 0, "No available ticket");

        result storage myResult = resultOf[msg.sender];
        require(!myResult.executed, "Already checked");

        uint256 validTicketAmount = calculateValidTicketAmount(
            myTicket.index,
            myTicket.amount,
            slotSize,
            offsetInSlot,
            lastTargetIndex
        );

        myResult.validTicketAmount = validTicketAmount;
        myResult.executed = true;

        uint256 remainingTickets = myTicket.amount - validTicketAmount;
        uint256 changes = remainingTickets * ticketPrice;

        emit SetResult(msg.sender, validTicketAmount, changes);
        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function mintCCC() external {
        result storage myResult = resultOf[msg.sender];

        require(myResult.executed, "result is not calculated yet");
        require(myResult.validTicketAmount > 0, "No valid tickets");

        uint256 mintRequestAmount = 0;

        if (myResult.validTicketAmount > maxMintPerTx) {
            mintRequestAmount = maxMintPerTx;
            myResult.validTicketAmount -= maxMintPerTx;
        } else {
            mintRequestAmount = myResult.validTicketAmount;
            myResult.validTicketAmount = 0;
        }

        for (uint256 i = 0; i < mintRequestAmount; i += 1) {
            cccFactory.mint(msg.sender);
        }

        emit MintCCC(msg.sender, mintRequestAmount);
    }

    /** 
     * Requests randomness from the chainlink cryptoverse
     */
    function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
     * @notice messageFromTheUniverse is used as a seed to ensure fairness in our NFT assignment procedure
     * @notice chosenLeader is used to find a leader amongst the guardians every human epoch
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        runRaffle(randomness);
    }

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
        emit SetChainlinkKeyHash(_keyHash);
    }

    function setChainlinkFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit SetChainlinkFee(_fee);
    }


    // withdraw eth for sold CCC
    function withdraw(address payable _to) external onlyOwner {
        require(_to != address(0), "receiver can not be empty address");
        require(!claimed, "Already claimed");
        require(
            maxCCC - maxPreMintCCC <= totalTickets + newlyMintedCCCWithPass,
            "Not enough ethers are collected"
        );

        uint256 withdrawalAmount = ticketPrice * (maxCCC - maxPreMintCCC);

        // Send eth to designated receiver
        emit Withdraw(_to);

        claimed = true;
        _to.transfer(withdrawalAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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