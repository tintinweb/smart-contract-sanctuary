pragma solidity ^0.4.24;

/**
 * @title Eliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */
contract ECRecovery {

    /**
    * @dev Recover signer address from a message by using their signature
    * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
    * @param sig bytes signature, the signature is generated using web3.eth.sign()
    */
    function recover(bytes32 hash, bytes sig)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
        // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }
}


/**
 * @title Auction state channel
 */
contract AuctionChannel is ECRecovery {
    
    // phase constants
    uint8 public constant PHASE_OPEN = 0;
    uint8 public constant PHASE_CHALLENGE = 1;
    uint8 public constant PHASE_CLOSED = 2;
    
    // auctioneer address
    address public auctioneer;

    // assistant address
    address public assistant;

    // current phase
    uint8 public phase;

    // minimum bid value
    uint256 public minBidValue;

    // challenge period in blocks
    uint256 public challengePeriod;

    // closing block number
    uint256 public closingBlock;

    // winner id
    bytes public winnerBidder;

    // winner bid value
    uint256 public winnerBidValue;


    /**
     * CONSTRUCTOR
     *
     * @dev Initialize the AuctionChannel
     * @param _auctioneer auctioneer address
     * @param _assistant assistant address
     * @param _challengePeriod challenge period in blocks
     * @param _minBidValue minimum winner bid value
     * @param _signatureAuctioneer signature of the auctioneer
     * @param _signatureAssistant signature of the assistant
     */ 
    constructor
    (
        address _auctioneer,
        address _assistant,
        uint256 _challengePeriod,
        uint256 _minBidValue,
        bytes _signatureAuctioneer,
        bytes _signatureAssistant
    )
        public
    {
        bytes32 _fingerprint = keccak256(
            abi.encodePacked(
                "openingAuctionChannel",
                _auctioneer,
                _assistant,
                _challengePeriod,
                _minBidValue
            )
        );

        _fingerprint = toEthSignedMessageHash(_fingerprint);

        require(_auctioneer == recover(_fingerprint, _signatureAuctioneer));
        require(_assistant == recover(_fingerprint, _signatureAssistant));

        auctioneer = _auctioneer;
        assistant = _assistant;
        challengePeriod = _challengePeriod;
        minBidValue = _minBidValue;
    }
   
    /**
     * @dev Update winner bid
     * @param _isAskBid is it AskBid
     * @param _bidder bidder id
     * @param _bidValue bid value
     * @param _previousBidHash hash of the previous bid
     * @param _signatureAssistant signature of the assistant
     * @param _signatureAuctioneer signature of the auctioneer
     */
    function updateWinnerBid(
        bool _isAskBid,
        bytes _bidder,
        uint256 _bidValue,
        bytes _previousBidHash,
        bytes _signatureAssistant,
        bytes _signatureAuctioneer
    ) 
        external
    {
        tryClose();

        require(phase != PHASE_CLOSED);

        require(!_isAskBid);
        require(_bidValue > winnerBidValue);
        require(_bidValue >= minBidValue);

        bytes32 _fingerprint = keccak256(
            abi.encodePacked(
                "auctionBid",
                _isAskBid,
                _bidder,
                _bidValue,
                _previousBidHash
            )
        );

        _fingerprint = toEthSignedMessageHash(_fingerprint);

        require(auctioneer == recover(_fingerprint, _signatureAuctioneer));
        require(assistant == recover(_fingerprint, _signatureAssistant));
        
        winnerBidder = _bidder;
        winnerBidValue = _bidValue;

        // start challenge period
        closingBlock = block.number + challengePeriod;
        phase = PHASE_CHALLENGE;  
    }

    /**
     * @dev Close the auction
     */
    function tryClose() public {
        if (phase == PHASE_CHALLENGE && block.number > closingBlock) {
            phase = PHASE_CLOSED;
        }
    }
}