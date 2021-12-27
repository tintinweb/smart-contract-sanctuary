// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract INFTicket {
    /** ERC-721 INTERFACE */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /** CUSTOM INTERFACE */
    function nextTokenId() public returns(uint256) {}
    function mintTo(address _to) external {}
    function burn(uint256 tokenId) external {}
}

contract NFTicketContest is Ownable, VRFConsumerBase {
    using Strings for uint256;

    IERC20 public WETH;

    /** CONTRACTS */
    INFTicket public nfticket;

    /** CONTEST */
    uint256 public NFT_PER_CONTEST = 1024;
    uint256 public ELIMINATION_ROUNDS = 10;
    uint256 public MINTS_PER_USER = 1024;
    uint256 public MINT_PRICE = 0.05 ether;
    uint256 public activeContestId;

    /** MAPPINGS */
    mapping(uint256 => mapping(address => uint256)) public addressToMints;    
    mapping(uint256 => mapping(uint256 => uint256)) public nftToSlot;
    mapping(uint256 => mapping(uint256 => uint256)) public slotToNft;
    mapping(uint256 => uint256) public nftToContest;
    mapping(uint256 => uint256[]) public contestToVrf;

    struct Contest { 
        // General info
        uint256 ticketStartIndex;
        uint256 ticketCount;

        //Elimination
        uint256 eliminationsLeft;
        uint256 eliminatedLowerBound;
        uint256 eliminatedUpperBound;
        
        // Contest
        uint256 prizePot;
        uint256 withdrawable;
        uint256 minted;

        // SCHEDULING
        uint256 mintDuration;
        uint256 eliminationDuration;
        uint256 contestStart;

        // WIN
        uint256 winnerToken;
        address winnerAddress;
    }

    Contest[] public contests;
    uint256 public carryOverPrize;
    mapping(uint256 => mapping(uint256 => uint256)) public mintCache;

    /** VRF */
    bytes32 internal keyHash;
    uint256 internal fee;

    /** PRESALE */
    bytes32 public preSaleMerkleRoot = "";
    bool public isPreSaleActive = false;
    
    /** EVENTS */
    event SetServerAddress(address _serverAddress);
    event CreateNewContest(uint256 _id);
    event Mint(address _minter, uint256 _amount);
    event Elimination(uint256 _round, uint256 _left);
    event RequestedRandomness(bytes32 _requestId);
    event FulfillRandomness(bytes32 _requestId, uint256 _randomness);
    event Finalize(address _winner, uint256 _token, uint256 _prize);
    event MassBurned(uint256 amount);

    /** MODIFIERS */
    modifier isMintingPeriod() {
        require(contests.length > 0, "NO CONTEST EXISTS");
        Contest memory _contest = contests[activeContestId];
        require(block.timestamp > _contest.contestStart, "Contest not started");
        require(block.timestamp <= _contest.contestStart + _contest.mintDuration, "Mint phase over");
        _;
    }

    modifier isNextEliminationPeriod() {
        require(contests.length > 0, "NO CONTEST EXISTS");
        Contest memory _contest = contests[activeContestId];
        uint256 _eliminationIndex = ELIMINATION_ROUNDS - _contest.eliminationsLeft;
        require(_contest.eliminationsLeft > 0, "Contest is finished");
        require(block.timestamp >= _contest.contestStart + _contest.mintDuration + (_contest.eliminationDuration * _eliminationIndex), "Elimination round not active.");
        require(contestToVrf[activeContestId].length < ELIMINATION_ROUNDS, "Max random numbers for contest received");
        _;
    }

    modifier canFinalize() {
        require(contests.length > 0, "NO CONTEST EXISTS");
        Contest memory _contest = contests[activeContestId];
        require(_contest.eliminationsLeft == 0, "Contest not finished yet");
        require(_contest.prizePot > 0, "Contest already finalized");
        _;
    }

     modifier checkMintProof(bytes32[] calldata proof) {
         if (isPreSaleActive) {
             bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(proof, preSaleMerkleRoot, leaf), "INVALID PROOF");   
         }
        _;
    }
    
    constructor(
        address _ERC721TokenAddress,
        address _WETH,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint _fee
    ) Ownable() VRFConsumerBase(
            _vrfCoordinator, 
            _link
    ) {
        nfticket = INFTicket(_ERC721TokenAddress);
        WETH = IERC20(_WETH);
        keyHash = _keyHash;
        fee = _fee;
    }


    /** HELPERS */

    function _msgSender()
        override
        internal
        view
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    function drawSlot(uint256 remaining, uint256 contestId) internal returns (uint256 index) {
        //RNG
        uint256 i = uint256(keccak256(abi.encodePacked(msg.sender, remaining, contestId))) % remaining;

        // if there's a cache at cache[i] then use it
        // otherwise use i itself
        index = mintCache[contestId][i] == 0 ? i : mintCache[contestId][i];

        // grab a number from the tail
        mintCache[contestId][i] = mintCache[contestId][remaining - 1] == 0 ? remaining - 1 : mintCache[contestId][remaining - 1];
    }


    /** CONTEST */

    function newContest(uint256 startOfContest, uint256 mintPeriod, uint256 eliminiationPeriod) external onlyOwner {
        if (contests.length > 0) {
            Contest memory _lastContest = contests[activeContestId];
            require(_lastContest.eliminationsLeft == 0, "CONTEST STILL ACTIVE");        
        }

        Contest memory _contest = Contest({
            ticketStartIndex: nfticket.nextTokenId(),
            ticketCount: NFT_PER_CONTEST,

            eliminationsLeft: ELIMINATION_ROUNDS,
            eliminatedLowerBound: 0,
            eliminatedUpperBound: NFT_PER_CONTEST,

            prizePot: carryOverPrize,
            withdrawable: 0,
            minted: 0,

            mintDuration: mintPeriod,
            eliminationDuration: eliminiationPeriod,
            contestStart: startOfContest,

            winnerToken: 0,
            winnerAddress: address(0)
        });

        carryOverPrize = 0;
        contests.push(_contest);
        activeContestId = contests.length - 1;
        emit CreateNewContest(activeContestId);
    }

    function canMint(uint256 _nextMint, uint256 _lastMintId, uint256 amount) internal view {
        require(_nextMint + amount <= _lastMintId, "Max NFTs minted for this contest");        
        require(WETH.allowance(msg.sender, address(this)) == MINT_PRICE * amount, "WETH SENT NOT CORRECT");
        require(addressToMints[activeContestId][msg.sender] + amount <= MINTS_PER_USER, "Sender already minted max");
    }

    function mint(uint256 amount, bytes32[] calldata proof) external payable isMintingPeriod checkMintProof(proof) {
        Contest storage _contest = contests[activeContestId];
        uint256 _nextMint = nfticket.nextTokenId();
        uint256 _lastMintId = _contest.ticketStartIndex + NFT_PER_CONTEST;

        canMint(_nextMint, _lastMintId, amount);

        for (uint i = 0; i < amount; i++) {            
            nfticket.mintTo(msg.sender);            

            uint256 _slotNumber = drawSlot(_lastMintId - _nextMint, activeContestId);
            require(slotToNft[activeContestId][_slotNumber] == 0, "slot already taken");

            nftToSlot[activeContestId][_nextMint] = _slotNumber;
            slotToNft[activeContestId][_slotNumber] = _nextMint;
            nftToContest[_nextMint] = activeContestId;

            _nextMint =  nfticket.nextTokenId();
            _contest.minted = _contest.minted + 1;
        }
        
        addressToMints[activeContestId][msg.sender] = addressToMints[activeContestId][msg.sender] + amount;

        uint256 WETHValue = MINT_PRICE * amount;
        uint256 _withdrawable = WETHValue / (10 * 3);
        uint256 _prizePot = WETHValue - _withdrawable;

        _contest.withdrawable = _contest.withdrawable + _withdrawable;
        _contest.prizePot = _contest.prizePot + _prizePot;

        WETH.transferFrom(msg.sender, address(this), WETHValue);

        emit Mint(msg.sender, amount);
    }

    function getRandomNumber() external isNextEliminationPeriod returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "NOT ENOUGH LINK");
        requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        contestToVrf[activeContestId].push(randomness);
        emit FulfillRandomness(requestId, randomness);
    }

    function triggerElimination() external isNextEliminationPeriod {
        Contest storage _contest = contests[activeContestId];
        uint256 _eliminationIndex = ELIMINATION_ROUNDS - _contest.eliminationsLeft;
        
        require(contestToVrf[activeContestId][_eliminationIndex] != 0, "NO VRF VALUE FOUND FOR THIS ROUND");
        
        uint256 decision = contestToVrf[activeContestId][_eliminationIndex] % 1;
        if (decision == 0) {
            _contest.eliminatedUpperBound = _contest.eliminatedUpperBound - (NFT_PER_CONTEST / (2 ** (_eliminationIndex + 1)));
        } else {
            _contest.eliminatedLowerBound = _contest.eliminatedLowerBound + (NFT_PER_CONTEST / (2 ** (_eliminationIndex + 1)));
        }

        _contest.eliminationsLeft = _contest.eliminationsLeft - 1;
    }

    function finalize() external canFinalize {
        Contest storage _contest = contests[activeContestId];

        uint256 _winningSlot = _contest.eliminatedLowerBound;
        uint _winnerNFT = slotToNft[activeContestId][_winningSlot];
        _contest.winnerToken = _winnerNFT;

        (bool success, bytes memory _data) = address(nfticket).call(abi.encodeWithSignature("ownerOf(uint256)", _winnerNFT));
    
        if (success) {
            address _winner = address(uint160(bytes20(_data)));
            _contest.winnerAddress = _winner;

            uint256 _toTransfer = _contest.prizePot;
            _contest.prizePot = 0;
            WETH.transfer(_winner, _toTransfer);

            emit Finalize(_winner, _winnerNFT, _contest.prizePot);
        } else {
            carryOverPrize = carryOverPrize + _contest.prizePot;
            _contest.prizePot = 0;
            emit Finalize(address(0), _winnerNFT, _contest.prizePot);
        }

        WETH.transfer(owner(), _contest.withdrawable);
       _contest.withdrawable = 0;
    }


    /** VIEW */

    function contestsLength() external view returns (uint256) {
        return contests.length;
    }

    function isTokenBurned(uint256 tokenId) public view returns (bool) {
        uint256 contestId = nftToContest[tokenId];
        Contest memory _contest = contests[contestId];
        uint256 slot = nftToSlot[contestId][tokenId];
        return slot < _contest.eliminatedLowerBound || slot >= _contest.eliminatedUpperBound;
    }


    /** OWNER */

    function massBurnTickets(uint256[] calldata ids) external onlyOwner {
        require(ids.length <= 100, "CANNOT BURN MORE THAN 100 NFTS AT A TIME ");
        uint256 burned = 0;

        for(uint i = 0; i < ids.length; i++) {
            if (!isTokenBurned(ids[i])) {
                continue;
            } else {
                (bool success,) = address(nfticket).call(abi.encodeWithSignature("burn(uint256)", ids[i]));
                if (success) {
                    burned = burned + 1;
                }
            }
        }

        emit MassBurned(burned);
    }

    function setTicket(address _newTicketAddress) external onlyOwner {
        nfticket = INFTicket(_newTicketAddress);
    }

    function setNFTsPerContest(uint256 _newNftsPerContests) external onlyOwner {
        NFT_PER_CONTEST = _newNftsPerContests;
    }

    function setEliminationRounds(uint256 _newEliminationRounds) external onlyOwner {
        ELIMINATION_ROUNDS = _newEliminationRounds;
    }

    function setMintsPerUser(uint256 _newMintsPerUser) external onlyOwner {
        MINTS_PER_USER = _newMintsPerUser;
    }

    function setMintPrice(uint256 _newMintPrice) external onlyOwner {
        MINT_PRICE = _newMintPrice;
    }

    function setPreSaleActive(bool newState) external onlyOwner {
        isPreSaleActive = newState;
    }

    function setPreSaleMerkleRoot(bytes32 _newRoot) external onlyOwner {
        preSaleMerkleRoot = _newRoot;
    }

    function withdrawMatic() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "MATIC Transfer failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

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
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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
  ) internal pure returns (uint256) {
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
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}