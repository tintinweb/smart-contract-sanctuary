pragma solidity ^0.4.24;

// File: contracts/Genetic.sol

// solhint-disable-next-line
pragma solidity ^0.4.23;


contract Genetic {

    // TODO mutations
    // maximum number of random mutations per chromatid
    uint8 public constant R = 5;

    // solhint-disable-next-line function-max-lines
    function breed(uint256[2] mother, uint256[2] father, uint256 seed) internal view returns (uint256[2] memOffset) {
        // Meiosis I: recombining alleles (Chromosomal crossovers)

        // Note about optimization I: no cell duplication,
        //  producing 2 seeds/eggs per cell is enough, instead of 4 (like humans do)

        // Note about optimization II: crossovers happen,
        //  but only 1 side of the result is computed,
        //  as the other side will not affect anything.

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // allocate output
            // 1) get the pointer to our memory
            memOffset := mload(0x40)
            // 2) Change the free-memory pointer to keep our memory
            //     (we will only use 64 bytes: 2 values of 256 bits)
            mstore(0x40, add(memOffset, 64))


            // Put seed in scratchpad 0
            mstore(0x0, seed)
            // Also use the timestamp, best we could do to increase randomness
            //  without increasing costs dramatically. (Trade-off)
            mstore(0x20, timestamp)

            // Hash it for a universally random bitstring.
            let hash := keccak256(0, 64)

            // Byzantium VM does not support shift opcodes, will be introduced in Constantinople.
            // Soldity itself, in non-assembly, also just uses other opcodes to simulate it.
            // Optmizer should take care of inlining, just declare shiftR ourselves here.
            // Where possible, better optimization is applied to make it cheaper.
            function shiftR(value, offset) -> result {
                result := div(value, exp(2, offset))
            }

            // solhint-disable max-line-length
            // m_context << Instruction::SWAP1 << u256(2) << Instruction::EXP << Instruction::SWAP1 << (c_leftSigned ? Instruction::SDIV : Instruction::DIV);

            // optimization: although one side consists of multiple chromatids,
            //  we handle them just as one long chromatid:
            //  only difference is that a crossover in chromatid i affects chromatid i+1.
            //  No big deal, order and location is random anyway
            function processSide(fatherSrc, motherSrc, rngSrc) -> result {

                {
                    // initial rngSrc bit length: 254 bits

                    // Run the crossovers
                    // =====================================================

                    // Pick some crossovers
                    // Each crossover is spaced ~64 bits on average.
                    // To achieve this, we get a random 7 bit number, [0, 128), for each crossover.

                    // 256 / 64 = 4, we need 4 crossovers,
                    //  and will have 256 / 127 = 2 at least (rounded down).

                    // Get one bit determining if we should pick DNA from the father,
                    //  or from the mother.
                    // This changes every crossover. (by swapping father and mother)
                    {
                        if eq(and(rngSrc, 0x1), 0) {
                            // Swap mother and father,
                            // create a temporary variable (code golf XOR swap costs more in gas)
                            let temp := fatherSrc
                            fatherSrc := motherSrc
                            motherSrc := temp
                        }

                        // remove the bit from rng source, 253 rng bits left
                        rngSrc := shiftR(rngSrc, 1)
                    }

                    // Don&#39;t push/pop this all the time, we have just enough space on stack.
                    let mask := 0

                    // Cap at 4 crossovers, no more than that.
                    let cap := 0
                    let crossoverLen := and(rngSrc, 0x7f) // bin: 1111111 (7 bits ON)
                    // remove bits from hash, e.g. 254 - 7 = 247 left.
                    rngSrc := shiftR(rngSrc, 7)
                    let crossoverPos := crossoverLen

                    // optimization: instead of shifting with an opcode we don&#39;t have until Constantinople,
                    //  keep track of the a shifted number, updated using multiplications.
                    let crossoverPosLeading1 := 1

                    // solhint-disable-next-line no-empty-blocks
                    for { } and(lt(crossoverPos, 256), lt(cap, 4)) {

                        crossoverLen := and(rngSrc, 0x7f) // bin: 1111111 (7 bits ON)
                        // remove bits from hash, e.g. 254 - 7 = 247 left.
                        rngSrc := shiftR(rngSrc, 7)

                        crossoverPos := add(crossoverPos, crossoverLen)

                        cap := add(cap, 1)
                    } {

                        // Note: we go from right to left in the bit-string.

                        // Create a mask for this crossover.
                        // Example:
                        // 00000000000001111111111111111110000000000000000000000000000000000000000000000000000000000.....
                        // |Prev. data ||Crossover here  ||remaining data .......
                        //
                        // The crossover part is copied from the mother/father to the child.

                        // Create the bit-mask
                        // Create a bitstring that ignores the previous data:
                        // 00000000000001111111111111111111111111111111111111111111111111111111111111111111111111111.....
                        // First create a leading 1, just before the crossover, like:
                        // 00000000000010000000000000000000000000000000000000000000000000000000000.....
                        // Then substract 1, to get a long string of 1s
                        // 00000000000001111111111111111111111111111111111111111111111111111111111111111111111111111.....
                        // Now do the same for the remain part, and xor it.
                        // leading 1
                        // 00000000000000000000000000000010000000000000000000000000000000000000000000000000000000000.....
                        // sub 1
                        // 00000000000000000000000000000001111111111111111111111111111111111111111111111111111111111.....
                        // xor with other
                        // 00000000000001111111111111111111111111111111111111111111111111111111111111111111111111111.....
                        // 00000000000000000000000000000001111111111111111111111111111111111111111111111111111111111.....
                        // 00000000000001111111111111111110000000000000000000000000000000000000000000000000000000000.....

                        // Use the final shifted 1 of the previous crossover as the start marker
                        mask := sub(crossoverPosLeading1, 1)

                        // update for this crossover, (and will be used as start for next crossover)
                        crossoverPosLeading1 := mul(1, exp(2, crossoverPos))
                        mask := xor(mask,
                                    sub(crossoverPosLeading1, 1)
                        )

                        // Now add the parent data to the child genotype
                        // E.g.
                        // Mask:         00000000000001111111111111111110000000000000000000000000000000000000000000000000000000000....
                        // Parent:       10010111001000110101011111001010001011100000000000010011000001000100000001011101111000111....
                        // Child (pre):  00000000000000000000000000000001111110100101111111000011001010000000101010100000110110110....
                        // Child (post): 00000000000000110101011111001011111110100101111111000011001010000000101010100000110110110....

                        // To do this, we run: child_post = child_pre | (mask & father)
                        result := or(result, and(mask, fatherSrc))

                        // Swap father and mother, next crossover will take a string from the other.
                        let temp := fatherSrc
                        fatherSrc := motherSrc
                        motherSrc := temp
                    }

                    // We still have a left-over part that was not copied yet
                    // E.g., we have something like:
                    // Father: |            xxxxxxxxxxxxxxxxxxx          xxxxxxxxxxxxxxxxxxxxxxxx            ....
                    // Mother: |############                   xxxxxxxxxx                        xxxxxxxxxxxx....
                    // Child:  |            xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx....
                    // The ############ still needs to be applied to the child, also,
                    //  this can be done cheaper than in the loop above,
                    //  as we don&#39;t have to swap anything for the next crossover or something.

                    // At this point we have to assume 4 crossovers ran,
                    //  and that we only have 127 - 1 - (4 * 7) = 98 bits of randomness left.
                    // We stopped at the bit after the crossoverPos index, see "x":
                    // 000000000xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.....
                    // now create a leading 1 at crossoverPos like:
                    // 000000001000000000000000000000000000000000000000000000000000000000000000000.....
                    // Sub 1, get the mask for what we had.
                    // 000000000111111111111111111111111111111111111111111111111111111111111111111.....
                    // Invert, and we have the final mask:
                    // 111111111000000000000000000000000000000000000000000000000000000000000000000.....
                    mask := not(sub(crossoverPosLeading1, 1))
                    // Apply it to the result
                    result := or(result, and(mask, fatherSrc))

                    // Random mutations
                    // =====================================================

                    // random mutations
                    // Put rng source in scratchpad 0
                    mstore(0x0, rngSrc)
                    // And some arbitrary padding in scratchpad 1,
                    //  used to create different hashes based on input size changes
                    mstore(0x20, 0x434f4c4c454354205045504553204f4e2043525950544f50455045532e494f21)
                    // Hash it for a universally random bitstring.
                    // Then reduce the number of 1s by AND-ing it with other *different* hashes.
                    // Each bit in mutations has a probability of 0.5^5 = 0.03125 = 3.125% to be a 1
                    let mutations := and(
                            and(
                                and(keccak256(0, 32), keccak256(1, 33)),
                                and(keccak256(2, 34), keccak256(3, 35))
                            ),
                            keccak256(0, 36)
                    )

                    result := xor(result, mutations)

                }
            }


            {

                // Get 1 bit of pseudo randomness that will
                //  determine if side #1 will come from the left, or right side.
                // Either 0 or 1, shift it by 5 bits to get either 0x0 or 0x20, cheaper later on.
                let relativeFatherSideLoc := mul(and(hash, 0x1), 0x20) // shift by 5 bits = mul by 2^5=32 (0x20)
                // Either 0 or 1, shift it by 5 bits to get either 0x0 or 0x20, cheaper later on.
                let relativeMotherSideLoc := mul(and(hash, 0x2), 0x10) // already shifted by 1, mul by 2^4=16 (0x10)

                // Now remove the used 2 bits from the hash, 254 bits remaining now.
                hash := div(hash, 4)

                // Process the side, load the relevant parent data that will be used.
                mstore(memOffset, processSide(
                    mload(add(father, relativeFatherSideLoc)),
                    mload(add(mother, relativeMotherSideLoc)),
                    hash
                ))

                // The other side will be the opposite index: 1 -> 0, 0 -> 1
                // Apply it to the location,
                //  which is either 0x20 (For index 1) or 0x0 for index 0.
                relativeFatherSideLoc := xor(relativeFatherSideLoc, 0x20)
                relativeMotherSideLoc := xor(relativeMotherSideLoc, 0x20)

                mstore(0x0, seed)
                // Second argument will be inverse,
                //  resulting in a different second hash.
                mstore(0x20, not(timestamp))

                // Now create another hash, for the other side
                hash := keccak256(0, 64)

                // Process the other side
                mstore(add(memOffset, 0x20), processSide(
                    mload(add(father, relativeFatherSideLoc)),
                    mload(add(mother, relativeMotherSideLoc)),
                    hash
                ))

            }

        }

        // Sample input:
        // ["0xAAABBBBBBBBCCCCCCCCAAAAAAAAABBBBBBBBBBCCCCCCCCCAABBBBBBBCCCCCCCC","0x4444444455555555555555556666666666666644444444455555555555666666"]
        //
        // ["0x1111111111112222222223333311111111122222223333333331111112222222","0x7777788888888888999999999999977777777777788888888888999999997777"]

        // Expected results (or similar, depends on the seed):
        // 0xAAABBBBBBBBCCCCCCCCAAAAAAAAABBBBBBBBBBCCCCCCCCCAABBBBBBBCCCCCCCC < Father side A
        // 0x4444444455555555555555556666666666666644444444455555555555666666 < Father side B

        // 0x1111111111112222222223333311111111122222223333333331111112222222 < Mother side A
        // 0x7777788888888888999999999999977777777777788888888888999999997777 < Mother side B

        //   xxxxxxxxxxxxxxxxx           xxxxxxxxx                         xx
        // 0xAAABBBBBBBBCCCCCD99999999998BBBBBBBBF77778888888888899999999774C < Child side A
        //   xxx                       xxxxxxxxxxx
        // 0x4441111111112222222223333366666666666222223333333331111112222222 < Child side B

        // And then random mutations, for gene pool expansion.
        // Each bit is flipped with a 3.125% chance

        // Example:
        //a2c37edc61dca0ca0b199e098c80fd5a221c2ad03605b4b54332361358745042 < random hash 1
        //c217d04b19a83fe497c1cf6e1e10030e455a0812a6949282feec27d67fe2baa7 < random hash 2
        //2636a55f38bed26d804c63a13628e21b2d701c902ca37b2b0ca94fada3821364 < random hash 3
        //86bb023a85e2da50ac233b946346a53aa070943b0a8e91c56e42ba181729a5f9 < random hash 4
        //5d71456a1288ab30ddd4c955384d42e66a09d424bd7743791e3eab8e09aa13f1 < random hash 5
        //0000000800800000000000000000000200000000000000000000020000000000 < resulting mutation
        //aaabbbbbbbbcccccd99999999998bbbbbbbbf77778888888888899999999774c < original
        //aaabbbb3bb3cccccd99999999998bbb9bbbbf7777888888888889b999999774c < mutated (= original XOR mutation)
    }

    // Generates (psuedo) random Pepe DNA
    function randomDNA(uint256 seed) internal pure returns (uint256[2] memOffset) {

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // allocate output
            // 1) get the pointer to our memory
            memOffset := mload(0x40)
            // 2) Change the free-memory pointer to keep our memory
            //     (we will only use 64 bytes: 2 values of 256 bits)
            mstore(0x40, add(memOffset, 64))

            // Load the seed into 1st scratchpad memory slot.
            // adjacent to the additional value (used to create two distinct hashes)
            mstore(0x0, seed)

            // In second scratchpad slot:
            // The additional value can be any word, as long as the caller uses
            //  it (second hash needs to be different)
            mstore(0x20, 0x434f4c4c454354205045504553204f4e2043525950544f50455045532e494f21)


            // // Create first element pointer of array
            // mstore(memOffset, add(memOffset, 64)) // pointer 1
            // mstore(add(memOffset, 32), add(memOffset, 96)) // pointer 2

            // control block to auto-pop the hash.
            {
                // L * N * 2 * 4 = 4 * 2 * 2 * 4 = 64 bytes, 2x 256 bit hash

                // Sha3 is cheaper than sha256, make use of it
                let hash := keccak256(0, 64)

                // Store first array value
                mstore(memOffset, hash)

                // Now hash again, but only 32 bytes of input,
                //  to ignore make the input different than the previous call,
                hash := keccak256(0, 32)
                mstore(add(memOffset, 32), hash)

            }

        }
    }

}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/Usernames.sol

// solhint-disable-next-line
pragma solidity ^0.4.19;


contract Usernames {

    mapping(address => bytes32) public addressToUser;
    mapping(bytes32 => address) public userToAddress;

    event UserNamed(address indexed user, bytes32 indexed username);

    /**
     * Claim a username. Frees up a previously used one
     * @param _username to claim
     */
    function claimUsername(bytes32 _username) external {
        require(userToAddress[_username] == address(0));// Username must be free

        if (addressToUser[msg.sender] != bytes32(0)) { // If user already has username free it up
            userToAddress[addressToUser[msg.sender]] = address(0);
        }

        //all is well assign username
        addressToUser[msg.sender] = _username;
        userToAddress[_username] = msg.sender;

        emit UserNamed(msg.sender, _username);

    }

}

// File: contracts/Beneficiary.sol

// solhint-disable-next-line
pragma solidity ^0.4.24;



/** @title Beneficiary */
contract Beneficiary is Ownable {
    address public beneficiary;

    constructor() public {
        beneficiary = msg.sender;
    }

    /**
     * @dev Change the beneficiary address
     * @param _beneficiary Address of the new beneficiary
     */
    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }
}

// File: contracts/Affiliate.sol

// solhint-disable-next-line
pragma solidity ^0.4.25;



/** @title Affiliate */
contract Affiliate is Ownable {
    mapping(address => bool) public canSetAffiliate;
    mapping(address => address) public userToAffiliate;

    /** @dev Allows an address to set the affiliate address for a user
      * @param _setter The address that should be allowed
      */
    function setAffiliateSetter(address _setter) public onlyOwner {
        canSetAffiliate[_setter] = true;
    }

    /**
     * @dev Set the affiliate of a user
     * @param _user user to set affiliate for
     * @param _affiliate address to set
     */
    function setAffiliate(address _user, address _affiliate) public {
        require(canSetAffiliate[msg.sender]);
        if (userToAffiliate[_user] == address(0)) {
            userToAffiliate[_user] = _affiliate;
        }
    }

}

// File: contracts/interfaces/ERC721.sol

contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public returns (bool) ;
    function transfer(address _to, uint256 _tokenId) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

// File: contracts/interfaces/PepeInterface.sol

contract PepeInterface is ERC721{
    function cozyTime(uint256 _mother, uint256 _father, address _pepeReceiver) public returns (bool);
    function getCozyAgain(uint256 _pepeId) public view returns(uint64);
}

// File: contracts/AuctionBase.sol

// solhint-disable-next-line
pragma solidity ^0.4.24;





/** @title AuctionBase */
contract AuctionBase is Beneficiary {
    mapping(uint256 => PepeAuction) public auctions;//maps pepes to auctions
    PepeInterface public pepeContract;
    Affiliate public affiliateContract;
    uint256 public fee = 37500; //in 1 10000th of a percent so 3.75% at the start
    uint256 public constant FEE_DIVIDER = 1000000; //Perhaps needs better name?

    struct PepeAuction {
        address seller;
        uint256 pepeId;
        uint64 auctionBegin;
        uint64 auctionEnd;
        uint256 beginPrice;
        uint256 endPrice;
    }

    event AuctionWon(uint256 indexed pepe, address indexed winner, address indexed seller);
    event AuctionStarted(uint256 indexed pepe, address indexed seller);
    event AuctionFinalized(uint256 indexed pepe, address indexed seller);

    constructor(address _pepeContract, address _affiliateContract) public {
        pepeContract = PepeInterface(_pepeContract);
        affiliateContract = Affiliate(_affiliateContract);
    }

    /**
     * @dev Return a pepe from a auction that has passed
     * @param  _pepeId the id of the pepe to save
     */
    function savePepe(uint256 _pepeId) external {
        // solhint-disable-next-line not-rely-on-time
        require(auctions[_pepeId].auctionEnd < now);//auction must have ended
        require(pepeContract.transfer(auctions[_pepeId].seller, _pepeId));//transfer pepe back to seller

        emit AuctionFinalized(_pepeId, auctions[_pepeId].seller);

        delete auctions[_pepeId];//delete auction
    }

    /**
     * @dev change the fee on pepe sales. Can only be lowerred
     * @param _fee The new fee to set. Must be lower than current fee
     */
    function changeFee(uint256 _fee) external onlyOwner {
        require(_fee < fee);//fee can not be raised
        fee = _fee;
    }

    /**
     * @dev Start a auction
     * @param  _pepeId Pepe to sell
     * @param  _beginPrice Price at which the auction starts
     * @param  _endPrice Ending price of the auction
     * @param  _duration How long the auction should take
     */
    function startAuction(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration) public {
        require(pepeContract.transferFrom(msg.sender, address(this), _pepeId));
        // solhint-disable-next-line not-rely-on-time
        require(now > auctions[_pepeId].auctionEnd);//can only start new auction if no other is active

        PepeAuction memory auction;

        auction.seller = msg.sender;
        auction.pepeId = _pepeId;
        // solhint-disable-next-line not-rely-on-time
        auction.auctionBegin = uint64(now);
        // solhint-disable-next-line not-rely-on-time
        auction.auctionEnd = uint64(now) + _duration;
        require(auction.auctionEnd > auction.auctionBegin);
        auction.beginPrice = _beginPrice;
        auction.endPrice = _endPrice;

        auctions[_pepeId] = auction;

        emit AuctionStarted(_pepeId, msg.sender);
    }

    /**
     * @dev directly start a auction from the PepeBase contract
     * @param  _pepeId Pepe to put on auction
     * @param  _beginPrice Price at which the auction starts
     * @param  _endPrice Ending price of the auction
     * @param  _duration How long the auction should take
     * @param  _seller The address selling the pepe
     */
    // solhint-disable-next-line max-line-length
    function startAuctionDirect(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration, address _seller) public {
        require(msg.sender == address(pepeContract)); //can only be called by pepeContract
        //solhint-disable-next-line not-rely-on-time
        require(now > auctions[_pepeId].auctionEnd);//can only start new auction if no other is active

        PepeAuction memory auction;

        auction.seller = _seller;
        auction.pepeId = _pepeId;
        // solhint-disable-next-line not-rely-on-time
        auction.auctionBegin = uint64(now);
        // solhint-disable-next-line not-rely-on-time
        auction.auctionEnd = uint64(now) + _duration;
        require(auction.auctionEnd > auction.auctionBegin);
        auction.beginPrice = _beginPrice;
        auction.endPrice = _endPrice;

        auctions[_pepeId] = auction;

        emit AuctionStarted(_pepeId, _seller);
    }

  /**
   * @dev Calculate the current price of a auction
   * @param  _pepeId the pepeID to calculate the current price for
   * @return currentBid the current price for the auction
   */
    function calculateBid(uint256 _pepeId) public view returns(uint256 currentBid) {
        PepeAuction storage auction = auctions[_pepeId];
        // solhint-disable-next-line not-rely-on-time
        uint256 timePassed = now - auctions[_pepeId].auctionBegin;

        // If auction ended return auction end price.
        // solhint-disable-next-line not-rely-on-time
        if (now >= auction.auctionEnd) {
            return auction.endPrice;
        } else {
            // Can be negative
            int256 priceDifference = int256(auction.endPrice) - int256(auction.beginPrice);
            // Always positive
            int256 duration = int256(auction.auctionEnd) - int256(auction.auctionBegin);

            // As already proven in practice by CryptoKitties:
            //  timePassed -> 64 bits at most
            //  priceDifference -> 128 bits at most
            //  timePassed * priceDifference -> 64 + 128 bits at most
            int256 priceChange = priceDifference * int256(timePassed) / duration;

            // Will be positive, both operands are less than 256 bits
            int256 price = int256(auction.beginPrice) + priceChange;

            return uint256(price);
        }
    }

  /**
   * @dev collect the fees from the auction
   */
    function getFees() public {
        beneficiary.transfer(address(this).balance);
    }


}

// File: contracts/CozyTimeAuction.sol

// solhint-disable-next-line
pragma solidity ^0.4.24;



/** @title CozyTimeAuction */
contract CozyTimeAuction is AuctionBase {
    // solhint-disable-next-line
    constructor (address _pepeContract, address _affiliateContract) AuctionBase(_pepeContract, _affiliateContract) public {

    }

    /**
     * @dev Start an auction
     * @param  _pepeId The id of the pepe to start the auction for
     * @param  _beginPrice Start price of the auction
     * @param  _endPrice End price of the auction
     * @param  _duration How long the auction should take
     */
    function startAuction(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration) public {
        // solhint-disable-next-line not-rely-on-time
        require(pepeContract.getCozyAgain(_pepeId) <= now);//need to have this extra check
        super.startAuction(_pepeId, _beginPrice, _endPrice, _duration);
    }

    /**
     * @dev Start a auction direclty from the PepeBase smartcontract
     * @param  _pepeId The id of the pepe to start the auction for
     * @param  _beginPrice Start price of the auction
     * @param  _endPrice End price of the auction
     * @param  _duration How long the auction should take
     * @param  _seller The address of the seller
     */
    // solhint-disable-next-line max-line-length
    function startAuctionDirect(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration, address _seller) public {
        // solhint-disable-next-line not-rely-on-time
        require(pepeContract.getCozyAgain(_pepeId) <= now);//need to have this extra check
        super.startAuctionDirect(_pepeId, _beginPrice, _endPrice, _duration, _seller);
    }

    /**
     * @dev Buy cozy right from the auction
     * @param  _pepeId Pepe to cozy with
     * @param  _cozyCandidate the pepe to cozy with
     * @param  _candidateAsFather Is the _cozyCandidate father?
     * @param  _pepeReceiver address receiving the pepe after cozy time
     */
    // solhint-disable-next-line max-line-length
    function buyCozy(uint256 _pepeId, uint256 _cozyCandidate, bool _candidateAsFather, address _pepeReceiver) public payable {
        require(address(pepeContract) == msg.sender); //caller needs to be the PepeBase contract

        PepeAuction storage auction = auctions[_pepeId];
        // solhint-disable-next-line not-rely-on-time
        require(now < auction.auctionEnd);// auction must be still going

        uint256 price = calculateBid(_pepeId);
        require(msg.value >= price);//must send enough ether
        uint256 totalFee = price * fee / FEE_DIVIDER; //safe math needed?

        //Send ETH to seller
        auction.seller.transfer(price - totalFee);
        //send ETH to beneficiary

        address affiliate = affiliateContract.userToAffiliate(_pepeReceiver);

        //solhint-disable-next-line
        if (affiliate != address(0) && affiliate.send(totalFee / 2)) { //if user has affiliate
            //nothing just to suppress warning
        }

        //actual cozytiming
        if (_candidateAsFather) {
            if (!pepeContract.cozyTime(auction.pepeId, _cozyCandidate, _pepeReceiver)) {
                revert();
            }
        } else {
          // Swap around the two pepes, they have no set gender, the user decides what they are.
            if (!pepeContract.cozyTime(_cozyCandidate, auction.pepeId, _pepeReceiver)) {
                revert();
            }
        }

        //Send pepe to seller of auction
        if (!pepeContract.transfer(auction.seller, _pepeId)) {
            revert(); //can&#39;t complete transfer if this fails
        }

        if (msg.value > price) { //return ether send to much
            _pepeReceiver.transfer(msg.value - price);
        }

        emit AuctionWon(_pepeId, _pepeReceiver, auction.seller);//emit event

        delete auctions[_pepeId];//deletes auction
    }

    /**
     * @dev Buy cozytime and pass along affiliate
     * @param  _pepeId Pepe to cozy with
     * @param  _cozyCandidate the pepe to cozy with
     * @param  _candidateAsFather Is the _cozyCandidate father?
     * @param  _pepeReceiver address receiving the pepe after cozy time
     * @param  _affiliate Affiliate address to set
     */
    //solhint-disable-next-line max-line-length
    function buyCozyAffiliated(uint256 _pepeId, uint256 _cozyCandidate, bool _candidateAsFather, address _pepeReceiver, address _affiliate) public payable {
        affiliateContract.setAffiliate(_pepeReceiver, _affiliate);
        buyCozy(_pepeId, _cozyCandidate, _candidateAsFather, _pepeReceiver);
    }
}

// File: contracts/Haltable.sol

// solhint-disable-next-line
pragma solidity ^0.4.24;



contract Haltable is Ownable {
    uint256 public haltTime; //when the contract was halted
    bool public halted;//is the contract halted?
    uint256 public haltDuration;
    uint256 public maxHaltDuration = 8 weeks;//how long the contract can be halted

    modifier stopWhenHalted {
        require(!halted);
        _;
    }

    modifier onlyWhenHalted {
        require(halted);
        _;
    }

    /**
     * @dev Halt the contract for a set time smaller than maxHaltDuration
     * @param  _duration Duration how long the contract should be halted. Must be smaller than maxHaltDuration
     */
    function halt(uint256 _duration) public onlyOwner {
        require(haltTime == 0); //cannot halt if it was halted before
        require(_duration <= maxHaltDuration);//cannot halt for longer than maxHaltDuration
        haltDuration = _duration;
        halted = true;
        // solhint-disable-next-line not-rely-on-time
        haltTime = now;
    }

    /**
     * @dev Unhalt the contract. Can only be called by the owner or when the haltTime has passed
     */
    function unhalt() public {
        // solhint-disable-next-line
        require(now > haltTime + haltDuration || msg.sender == owner);//unhalting is only possible when haltTime has passed or the owner unhalts
        halted = false;
    }

}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/interfaces/ERC721TokenReceiver.sol

/// @dev Note: the ERC-165 identifier for this interface is 0xf0b9e5ba
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    ///  unless throwing
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

// File: contracts/PepeBase.sol

// solhint-disable-next-line
pragma solidity ^0.4.24;

// solhint-disable func-order










contract PepeBase is Genetic, Ownable, Usernames, Haltable {

    uint32[15] public cozyCoolDowns = [ //determined by generation / 2
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(15 minutes),
        uint32(30 minutes),
        uint32(45 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

    struct Pepe {
        address master; //The master of the pepe
        uint256[2] genotype; //all genes stored here
        uint64 canCozyAgain; //time when pepe can have nice time again
        uint64 generation; //what generation?
        uint64 father; //father of this pepe
        uint64 mother; //mommy of this pepe
        uint8 coolDownIndex;
    }

    mapping(uint256 => bytes32) public pepeNames;

    //stores all pepes
    Pepe[] public pepes;

    bool public implementsERC721 = true; //signal erc721 support

    // solhint-disable-next-line const-name-snakecase
    string public constant name = "Crypto Pepe";
    // solhint-disable-next-line const-name-snakecase
    string public constant symbol = "CPEP";

    mapping(address => uint256[]) private wallets;
    mapping(address => uint256) public balances; //amounts of pepes per address
    mapping(uint256 => address) public approved; //pepe index to address approved to transfer
    mapping(address => mapping(address => bool)) public approvedForAll;

    uint256 public zeroGenPepes; //how many zero gen pepes are mined
    uint256 public constant MAX_PREMINE = 100;//how many pepes can be premined
    uint256 public constant MAX_ZERO_GEN_PEPES = 1100; //max number of zero gen pepes
    address public miner; //address of the miner contract

    modifier onlyPepeMaster(uint256 _pepeId) {
        require(pepes[_pepeId].master == msg.sender);
        _;
    }

    modifier onlyAllowed(uint256 _tokenId) {
        // solhint-disable-next-line max-line-length
        require(msg.sender == pepes[_tokenId].master || msg.sender == approved[_tokenId] || approvedForAll[pepes[_tokenId].master][msg.sender]); //check if msg.sender is allowed
        _;
    }

    event PepeBorn(uint256 indexed mother, uint256 indexed father, uint256 indexed pepeId);
    event PepeNamed(uint256 indexed pepeId);

    constructor() public {

        Pepe memory pepe0 = Pepe({
            master: 0x0,
            genotype: [uint256(0), uint256(0)],
            canCozyAgain: 0,
            father: 0,
            mother: 0,
            generation: 0,
            coolDownIndex: 0
        });

        pepes.push(pepe0);
    }

    /**
     * @dev Internal function that creates a new pepe
     * @param  _genoType DNA of the new pepe
     * @param  _mother The ID of the mother
     * @param  _father The ID of the father
     * @param  _generation The generation of the new Pepe
     * @param  _master The owner of this new Pepe
     * @return The ID of the newly generated Pepe
     */
    // solhint-disable-next-line max-line-length
    function _newPepe(uint256[2] _genoType, uint64 _mother, uint64 _father, uint64 _generation, address _master) internal returns (uint256 pepeId) {
        uint8 tempCoolDownIndex;

        tempCoolDownIndex = uint8(_generation / 2);

        if (_generation > 28) {
            tempCoolDownIndex = 14;
        }

        Pepe memory _pepe = Pepe({
            master: _master, //The master of the pepe
            genotype: _genoType, //all genes stored here
            canCozyAgain: 0, //time when pepe can have nice time again
            father: _father, //father of this pepe
            mother: _mother, //mommy of this pepe
            generation: _generation, //what generation?
            coolDownIndex: tempCoolDownIndex
        });

        if (_generation == 0) {
            zeroGenPepes += 1; //count zero gen pepes
        }

        //push returns the new length, use it to get a new unique id
        pepeId = pepes.push(_pepe) - 1;

        //add it to the wallet of the master of the new pepe
        addToWallet(_master, pepeId);

        emit PepeBorn(_mother, _father, pepeId);
        emit Transfer(address(0), _master, pepeId);

        return pepeId;
    }

    /**
     * @dev Set the miner contract. Can only be called once
     * @param _miner Address of the miner contract
     */
    function setMiner(address _miner) public onlyOwner {
        require(miner == address(0));//can only be set once
        miner = _miner;
    }

    /**
     * @dev Mine a new Pepe. Can only be called by the miner contract.
     * @param  _seed Seed to be used for the generation of the DNA
     * @param  _receiver Address receiving the newly mined Pepe
     * @return The ID of the newly mined Pepe
     */
    function minePepe(uint256 _seed, address _receiver) public stopWhenHalted returns(uint256) {
        require(msg.sender == miner);//only miner contract can call
        require(zeroGenPepes < MAX_ZERO_GEN_PEPES);

        return _newPepe(randomDNA(_seed), 0, 0, 0, _receiver);
    }

    /**
     * @dev Premine pepes. Can only be called by the owner and is limited to MAX_PREMINE
     * @param  _amount Amount of Pepes to premine
     */
    function pepePremine(uint256 _amount) public onlyOwner stopWhenHalted {
        for (uint i = 0; i < _amount; i++) {
            require(zeroGenPepes <= MAX_PREMINE);//can only generate set amount during premine
            //create a new pepe
            // 1) who&#39;s genes are based on hash of the timestamp and the number of pepes
            // 2) who has no mother or father
            // 3) who is generation zero
            // 4) who&#39;s master is the manager

            // solhint-disable-next-line
            _newPepe(randomDNA(uint256(keccak256(abi.encodePacked(block.timestamp, pepes.length)))), 0, 0, 0, owner);

        }
    }

    /**
     * @dev CozyTime two Pepes together
     * @param  _mother The mother of the new Pepe
     * @param  _father The father of the new Pepe
     * @param  _pepeReceiver Address receiving the new Pepe
     * @return If it was a success
     */
    function cozyTime(uint256 _mother, uint256 _father, address _pepeReceiver) external stopWhenHalted returns (bool) {
        //cannot cozyTime with itself
        require(_mother != _father);
        //caller has to either be master or approved for mother
        // solhint-disable-next-line max-line-length
        require(pepes[_mother].master == msg.sender || approved[_mother] == msg.sender || approvedForAll[pepes[_mother].master][msg.sender]);
        //caller has to either be master or approved for father
        // solhint-disable-next-line max-line-length
        require(pepes[_father].master == msg.sender || approved[_father] == msg.sender || approvedForAll[pepes[_father].master][msg.sender]);
        //require both parents to be ready for cozytime
        // solhint-disable-next-line not-rely-on-time
        require(now > pepes[_mother].canCozyAgain && now > pepes[_father].canCozyAgain);
        //require both mother parents not to be father
        require(pepes[_mother].mother != _father && pepes[_mother].father != _father);
        //require both father parents not to be mother
        require(pepes[_father].mother != _mother && pepes[_father].father != _mother);

        Pepe storage father = pepes[_father];
        Pepe storage mother = pepes[_mother];


        approved[_father] = address(0);
        approved[_mother] = address(0);

        uint256[2] memory newGenotype = breed(father.genotype, mother.genotype, pepes.length);

        uint64 newGeneration;

        newGeneration = mother.generation + 1;
        if (newGeneration < father.generation + 1) { //if father generation is bigger
            newGeneration = father.generation + 1;
        }

        _handleCoolDown(_mother);
        _handleCoolDown(_father);

        //sets pepe birth when mother is done
        // solhint-disable-next-line max-line-length
        pepes[_newPepe(newGenotype, uint64(_mother), uint64(_father), newGeneration, _pepeReceiver)].canCozyAgain = mother.canCozyAgain; //_pepeReceiver becomes the master of the pepe

        return true;
    }

    /**
     * @dev Internal function to increase the coolDownIndex
     * @param _pepeId The id of the Pepe to update the coolDown of
     */
    function _handleCoolDown(uint256 _pepeId) internal {
        Pepe storage tempPep = pepes[_pepeId];

        // solhint-disable-next-line not-rely-on-time
        tempPep.canCozyAgain = uint64(now + cozyCoolDowns[tempPep.coolDownIndex]);

        if (tempPep.coolDownIndex < 14) {// after every cozy time pepe gets slower
            tempPep.coolDownIndex++;
        }

    }

    /**
     * @dev Set the name of a Pepe. Can only be set once
     * @param _pepeId ID of the pepe to name
     * @param _name The name to assign
     */
    function setPepeName(uint256 _pepeId, bytes32 _name) public stopWhenHalted onlyPepeMaster(_pepeId) returns(bool) {
        require(pepeNames[_pepeId] == 0x0000000000000000000000000000000000000000000000000000000000000000);
        pepeNames[_pepeId] = _name;
        emit PepeNamed(_pepeId);
        return true;
    }

    /**
     * @dev Transfer a Pepe to the auction contract and auction it
     * @param  _pepeId ID of the Pepe to auction
     * @param  _auction Auction contract address
     * @param  _beginPrice Price the auction starts at
     * @param  _endPrice Price the auction ends at
     * @param  _duration How long the auction should run
     */
    // solhint-disable-next-line max-line-length
    function transferAndAuction(uint256 _pepeId, address _auction, uint256 _beginPrice, uint256 _endPrice, uint64 _duration) public stopWhenHalted onlyPepeMaster(_pepeId) {
        _transfer(msg.sender, _auction, _pepeId);//transfer pepe to auction
        AuctionBase auction = AuctionBase(_auction);

        auction.startAuctionDirect(_pepeId, _beginPrice, _endPrice, _duration, msg.sender);
    }

    /**
     * @dev Approve and buy. Used to buy cozyTime in one call
     * @param  _pepeId Pepe to cozy with
     * @param  _auction Address of the auction contract
     * @param  _cozyCandidate Pepe to approve and cozy with
     * @param  _candidateAsFather Use the candidate as father or not
     */
    // solhint-disable-next-line max-line-length
    function approveAndBuy(uint256 _pepeId, address _auction, uint256 _cozyCandidate, bool _candidateAsFather) public stopWhenHalted payable onlyPepeMaster(_cozyCandidate) {
        approved[_cozyCandidate] = _auction;
        // solhint-disable-next-line max-line-length
        CozyTimeAuction(_auction).buyCozy.value(msg.value)(_pepeId, _cozyCandidate, _candidateAsFather, msg.sender); //breeding resets approval
    }

    /**
     * @dev The same as above only pass an extra parameter
     * @param  _pepeId Pepe to cozy with
     * @param  _auction Address of the auction contract
     * @param  _cozyCandidate Pepe to approve and cozy with
     * @param  _candidateAsFather Use the candidate as father or not
     * @param  _affiliate Address to set as affiliate
     */
    // solhint-disable-next-line max-line-length
    function approveAndBuyAffiliated(uint256 _pepeId, address _auction, uint256 _cozyCandidate, bool _candidateAsFather, address _affiliate) public stopWhenHalted payable onlyPepeMaster(_cozyCandidate) {
        approved[_cozyCandidate] = _auction;
        // solhint-disable-next-line max-line-length
        CozyTimeAuction(_auction).buyCozyAffiliated.value(msg.value)(_pepeId, _cozyCandidate, _candidateAsFather, msg.sender, _affiliate); //breeding resets approval
    }

    /**
     * @dev get Pepe information
     * @param  _pepeId ID of the Pepe to get information of
     * @return master
     * @return genotype
     * @return canCozyAgain
     * @return generation
     * @return father
     * @return mother
     * @return pepeName
     * @return coolDownIndex
     */
    // solhint-disable-next-line max-line-length
    function getPepe(uint256 _pepeId) public view returns(address master, uint256[2] genotype, uint64 canCozyAgain, uint64 generation, uint256 father, uint256 mother, bytes32 pepeName, uint8 coolDownIndex) {
        Pepe storage tempPep = pepes[_pepeId];

        master = tempPep.master;
        genotype = tempPep.genotype;
        canCozyAgain = tempPep.canCozyAgain;
        generation = tempPep.generation;
        father = tempPep.father;
        mother = tempPep.mother;
        pepeName = pepeNames[_pepeId];
        coolDownIndex = tempPep.coolDownIndex;
    }

    /**
     * @dev Get the time when a pepe can cozy again
     * @param  _pepeId ID of the pepe
     * @return Time when the pepe can cozy again
     */
    function getCozyAgain(uint256 _pepeId) public view returns(uint64) {
        return pepes[_pepeId].canCozyAgain;
    }

    /**
     *  ERC721 Compatibility
     *
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @dev Get the total number of Pepes
     * @return total Returns the total number of pepes
     */
    function totalSupply() public view returns(uint256 total) {
        total = pepes.length - balances[address(0)];
        return total;
    }

    /**
     * @dev Get the number of pepes owned by an address
     * @param  _owner Address to get the balance from
     * @return balance The number of pepes
     */
    function balanceOf(address _owner) external view returns (uint256 balance) {
        balance = balances[_owner];
    }

    /**
     * @dev Get the owner of a Pepe
     * @param  _tokenId the token to get the owner of
     * @return _owner the owner of the pepe
     */
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = pepes[_tokenId].master;
    }

    /**
     * @dev Get the id of an token by its index
     * @param _owner The address to look up the tokens of
     * @param _index Index to look at
     * @return tokenId the ID of the token of the owner at the specified index
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint256 tokenId) {
        //The index must be smaller than the balance,
        // to guarantee that there is no leftover token returned.
        require(_index < balances[_owner]);

        return wallets[_owner][_index];
    }

    /**
     * @dev Private method that ads a token to the wallet
     * @param _owner Address of the owner
     * @param _tokenId Pepe ID to add
     */
    function addToWallet(address _owner, uint256 _tokenId) private {
        uint256[] storage wallet = wallets[_owner];
        uint256 balance = balances[_owner];
        if (balance < wallet.length) {
            wallet[balance] = _tokenId;
        } else {
            wallet.push(_tokenId);
        }
        //increase owner balance
        //overflow is not likely to happen(need very large amount of pepes)
        balances[_owner] += 1;
    }

    /**
     * @dev Remove a token from a address&#39;s wallet
     * @param _owner Address of the owner
     * @param _tokenId Token to remove from the wallet
     */
    function removeFromWallet(address _owner, uint256 _tokenId) private {
        uint256[] storage wallet = wallets[_owner];
        uint256 i = 0;
        // solhint-disable-next-line no-empty-blocks
        for (; wallet[i] != _tokenId; i++) {
            // not the pepe we are looking for
        }
        if (wallet[i] == _tokenId) {
            //found it!
            uint256 last = balances[_owner] - 1;
            if (last > 0) {
                //move the last item to this spot, the last will become inaccessible
                wallet[i] = wallet[last];
            }
            //else: no last item to move, the balance is 0, making everything inaccessible.

            //only decrease balance if _tokenId was in the wallet
            balances[_owner] -= 1;
        }
    }

    /**
     * @dev Internal transfer function
     * @param _from Address sending the token
     * @param _to Address to token is send to
     * @param _tokenId ID of the token to send
     */
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        pepes[_tokenId].master = _to;
        approved[_tokenId] = address(0);//reset approved of pepe on every transfer

        //remove the token from the _from wallet
        removeFromWallet(_from, _tokenId);

        //add the token to the _to wallet
        addToWallet(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev transfer a token. Can only be called by the owner of the token
     * @param  _to Addres to send the token to
     * @param  _tokenId ID of the token to send
     */
    // solhint-disable-next-line no-simple-event-func-name
    function transfer(address _to, uint256 _tokenId) public stopWhenHalted
        onlyPepeMaster(_tokenId) //check if msg.sender is the master of this pepe
        returns(bool)
    {
        _transfer(msg.sender, _to, _tokenId);//after master modifier invoke internal transfer
        return true;
    }

    /**
     * @dev Approve a address to send a token
     * @param _to Address to approve
     * @param _tokenId Token to set approval for
     */
    function approve(address _to, uint256 _tokenId) external stopWhenHalted
        onlyPepeMaster(_tokenId)
    {
        approved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    /**
     * @dev Approve or revoke approval an address for al tokens of a user
     * @param _operator Address to (un)approve
     * @param _approved Approving or revoking indicator
     */
    function setApprovalForAll(address _operator, bool _approved) external stopWhenHalted {
        if (_approved) {
            approvedForAll[msg.sender][_operator] = true;
        } else {
            approvedForAll[msg.sender][_operator] = false;
        }
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Get approved address for a token
     * @param _tokenId Token ID to get the approved address for
     * @return The address that is approved for this token
     */
    function getApproved(uint256 _tokenId) external view returns (address) {
        return approved[_tokenId];
    }

    /**
     * @dev Get if an operator is approved for all tokens of that owner
     * @param _owner Owner to check the approval for
     * @param _operator Operator to check approval for
     * @return Boolean indicating if the operator is approved for that owner
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return approvedForAll[_owner][_operator];
    }

    /**
     * @dev Function to signal support for an interface
     * @param interfaceID the ID of the interface to check for
     * @return Boolean indicating support
     */
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        if (interfaceID == 0x80ac58cd || interfaceID == 0x01ffc9a7) { //TODO: add more interfaces the contract supports
            return true;
        }
        return false;
    }

    /**
     * @dev Safe transferFrom function
     * @param _from Address currently owning the token
     * @param _to Address to send token to
     * @param _tokenId ID of the token to send
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external stopWhenHalted {
        _safeTransferFromInternal(_from, _to, _tokenId, "");
    }

    /**
     * @dev Safe transferFrom function with aditional data attribute
     * @param _from Address currently owning the token
     * @param _to Address to send token to
     * @param _tokenId ID of the token to send
     * @param _data Data to pass along call
     */
    // solhint-disable-next-line max-line-length
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external stopWhenHalted {
        _safeTransferFromInternal(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Internal Safe transferFrom function with aditional data attribute
     * @param _from Address currently owning the token
     * @param _to Address to send token to
     * @param _tokenId ID of the token to send
     * @param _data Data to pass along call
     */
    // solhint-disable-next-line max-line-length
    function _safeTransferFromInternal(address _from, address _to, uint256 _tokenId, bytes _data) internal onlyAllowed(_tokenId) {
        require(pepes[_tokenId].master == _from);//check if from is current owner
        require(_to != address(0));//throw on zero address

        _transfer(_from, _to, _tokenId); //transfer token

        if (isContract(_to)) { //check if is contract
            // solhint-disable-next-line max-line-length
            require(ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, _data) == bytes4(keccak256("onERC721Received(address,uint256,bytes)")));
        }
    }

    /**
     * @dev TransferFrom function
     * @param _from Address currently owning the token
     * @param _to Address to send token to
     * @param _tokenId ID of the token to send
     * @return If it was successful
     */
    // solhint-disable-next-line max-line-length
    function transferFrom(address _from, address _to, uint256 _tokenId) public stopWhenHalted onlyAllowed(_tokenId) returns(bool) {
        require(pepes[_tokenId].master == _from);//check if _from is really the master.
        require(_to != address(0));
        _transfer(_from, _to, _tokenId);//handles event, balances and approval reset;
        return true;
    }

    /**
     * @dev Utility method to check if an address is a contract
     * @param _address Address to check
     * @return Boolean indicating if the address is a contract
     */
    function isContract(address _address) internal view returns (bool) {
        uint size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_address) }
        return size > 0;
    }

}