//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./MiniStayPuft.sol";

/// @author Andrew Parker
/// @title GBA Viewer
/// @notice MiniStayPuft NFT periphery contract, for GBA website

contract GBAViewer {

    MiniStayPuft msp;                // MiniStayPuft main contract
    GBAWhitelist whitelist;          // GBA whitelist contract
    IGBATrapsPartial traps;              // GBA whitelist contract

    uint constant COOLDOWN = 10;    //Reserve cooldown block interval
    uint constant PRESALE_LIMIT = 2000;
    uint8 constant WHITELIST_RESERVE_LIMIT = 2;
    uint16 constant TOTAL_MOB_COUNT = 500;  //total number of mobs that can exist


    /// Constructor
    /// @param _msp Address of MiniStayPuft contract
    /// @param _whitelist Address of Whitelist contract
    /// @param _traps Address of GBATraps contract
    constructor(address _msp, address _traps, address _whitelist){
        msp = MiniStayPuft(_msp);
        whitelist = GBAWhitelist(_whitelist);
        traps = IGBATrapsPartial(_traps);
    }



    /// Can Reserve
    /// @notice Is a given address out of cooldown
    /// @param reservist Address to check
    /// @return Cooldown is over
    function canReserve(address reservist) public view returns(bool){
        (uint8 _whitelistReserveCount, uint24 blockNumber, uint16[] memory tokenIds) = msp.mintReserveState(reservist);
            _whitelistReserveCount;
            tokenIds;
        return blockNumber == 0 || block.number > uint(blockNumber) + COOLDOWN;
    }

    /// Reserved Count
    /// @notice Number of tokens that have been reserved
    function reservedCount() public view returns(uint){
        (uint _tokenCount, MiniStayPuft.Phase _phase, uint mobMax) = msp.contractState();
        _phase;


        //_tokenCount doesnt include caught mobs
        uint _reserved = _tokenCount;

        if( mobMax == 0){
            //all mobs caught
            _reserved += TOTAL_MOB_COUNT;
        }else if(mobMax > TOTAL_MOB_COUNT){
            //only a few left
            _reserved += TOTAL_MOB_COUNT;
        }else{
            //3 in motion
            _reserved += mobMax;
        }


        return _reserved - msp.totalSupply();

    }

    /// Can PreReserve
    /// @notice Can an address with given proof mint in PreReserve phase. Returns number remaining they can mint. (0 if not whitelisted)
    /// @param proof Merkle proof
    /// @param listee address to check
    /// @return Number tht can be minted
    function canPreReserve(bytes32[] memory proof, address listee) public view returns(uint){
        if (!whitelist.isWhitelisted(proof,listee) || reservedCount() >= PRESALE_LIMIT )return 0;

        (uint8 _whitelistReserveCount, uint24 blockNumber, uint16[] memory tokenIds) = msp.mintReserveState(listee);
        blockNumber;tokenIds;

        return WHITELIST_RESERVE_LIMIT - _whitelistReserveCount;
    }

    /// Can TrapMintWhitelisted
    /// @notice Can an address with given proof mint a trap. Returns false if not whitelisted or minted
    /// @param proof Merkle proof
    /// @param listee address to check
    /// @return Number tht can be minted
    function canTrapMintWhitelisted(bytes32[] memory proof, address listee) public view returns(bool){
        if (!whitelist.isWhitelisted(proof,listee)) return false;

        return !traps.hasMinted(listee);
    }

    /// Can TrapMintPublic
    /// @notice Can an address with given proof mint a trap. Returns false if not public  or has minted
    /// @param minter address to check
    /// @return Number tht can be minted
    function canTrapMintPublic(address minter) public view returns(bool){
        if(
            !traps.saleStarted() ||
            traps.whitelistEndTime() > block.timestamp
        ){
            return false;
        }

        return !traps.hasMinted(minter);
    }





    /// Countdown
    /// @notice Gets current countdown state, and also inferred pause state.
    /// @return counting False if paused, or if not a phase with a countdown
    /// @return time Time in secs until countdown ends (always 0 if not counting)
    function countdown() public view returns(bool counting, uint time){
        (uint _tokenCount, MiniStayPuft.Phase _phase, uint mobMax) = msp.contractState();
        _tokenCount; mobMax;

       (bool _paused,uint _startTime,uint _pauseTime) = msp.pauseState();
        _startTime;_pauseTime;

        if(_paused){
            return (false,0);
        }
        if(_phase == MiniStayPuft.Phase.Init){
            return(false,0);
        }else if(_phase == MiniStayPuft.Phase.PreReserve){
            return(true,_startTime + 2 hours - block.timestamp);
        }else if(_phase == MiniStayPuft.Phase.Reserve){
            return(true,_startTime + 1 days + 2 hours - block.timestamp);
        }else{
            return(false,0);
        }
    }

    /// Contract Sub State
    /// @dev just a way of getting some vars for Contract State and not hitting stack too deep
    function contractSubState() public view returns (MiniStayPuft.Phase _phase, bool _paused){
        uint _tokenCount; uint mobMax;
        (_tokenCount, _phase, mobMax) = msp.contractState();
        _tokenCount;mobMax;
        uint _startTime;
        uint _pauseTime;
        (_paused, _startTime, _pauseTime) = msp.pauseState();
        _startTime;_pauseTime;

        return (_phase,_paused);
    }

    /// Contract State
    /// @notice Gets current contract state, for initial page load.
    /// @return _totalSupply Total supply of minted MSPs
    /// @return reserved Number of reserved, unclaimed MSPs
    /// @return _phase current phase
    /// @return _counting False if paused, or if not a phase with a countdown
    /// @return _time Time in secs until countdown ends (always 0 if not counting)
    /// @return _paused Is currently paused
    /// @return trapsSupply Number of traps that exist
    /// @return trapsMintState Current mint state for traps contract
    /// @return blockNumber current block number
    function contractState() public view returns(uint _totalSupply, uint reserved, MiniStayPuft.Phase _phase, bool _counting, uint _time, bool _paused, uint trapsSupply, IGBATrapsPartial.State trapsMintState, uint blockNumber){
        (_counting, _time) = countdown();
        (_phase,_paused) = contractSubState();

        return (
            msp.totalSupply(),

            reservedCount(),
            _phase,

            _counting, _time,_paused,
            traps.totalSupply(),
            traps.mintState(),
        block.number);
    }

    /// My State
    /// @notice Gets current contract state, specific to msg.sender
    /// @param merkleProof Merkle proof for msg.sender if listee
    /// @return myBalance Number of Ronins owned
    /// @return myReserved number of reserved, unclaimed MSP
    /// @return cooldown Block number of last reservation
    /// @return _canPreReserve Can PreReserve
    /// @return _canReserve Can Reserve
    /// @return myMobs Array of mobs currently in msg.sender's wallet
    /// @return blockNumber current block number
    function myState(bytes32[] memory merkleProof) public view returns(uint myBalance, uint myReserved, uint cooldown, uint _canPreReserve, bool _canReserve, uint[3] memory myMobs, uint blockNumber){
        (uint8 _whitelistReserveCount, uint24 _cooldown, uint16[] memory _tokenIds) = msp.mintReserveState(msg.sender);
        _whitelistReserveCount;

        myMobs;
        for(uint i = 0; i < 3; i++){
            try msp.getMobTokenId(i) returns (uint _tokenId) {
                try msp.ownerOf(_tokenId) returns (address owner) {
                    if(owner == msg.sender){
                        myMobs[i] = _tokenId;
                    }
                }catch{
                    myMobs[i] = 0;
                }
            } catch {
                myMobs[i] = 0;
            }
        }


        return (msp.balanceOf(msg.sender),
        _tokenIds.length,
        _cooldown,
        canPreReserve(merkleProof,msg.sender),
        canReserve(msg.sender),
        myMobs,
        block.number);
    }

    /// My Trap State
    /// @notice Gets current trap contract state, specific to msg.sender
    /// @param merkleProof Merkle proof for msg.sender if listee
    /// @return myBalance Number of Ronins owned
    /// @return _canTrapMintWhitelisted Can Trap Mint whitelisted
    /// @return _canTrapMintPublic Can Trap mint public
    /// @return blockNumber current block number
    function myTrapState(bytes32[] memory merkleProof) public view returns(uint myBalance, bool _canTrapMintWhitelisted,bool _canTrapMintPublic, uint blockNumber){

        return (traps.balanceOf(msg.sender),
        canTrapMintWhitelisted(merkleProof,msg.sender),
        canTrapMintPublic(msg.sender),
        block.number);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Enumerable.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC165.sol";

import "./IGBATrapsPartial.sol";
import "./Ownable.sol";

import "./GBAWhitelist.sol";

/// @author Andrew Parker
/// @title Ghost Busters: Afterlife Mini Stay Puft NFT contract
contract MiniStayPuft is IERC721, IERC721Metadata, IERC165, Ownable{

    enum Phase{Init,PreReserve,Reserve,Final} // Launch phase
    struct Reservation{
        uint24 block;       // Using uint24 to store block number is fine for the next 2.2 years
        uint16[] tokens;    // TokenIDs reserved by person
    }
    bool paused = true;                 // Sale pause state
    bool unpausable;                    // Unpausable
    uint startTime;                     // Timestamp of when preReserve phase started (adjusts when paused/unpaused)
    uint pauseTime;                     // Timestamp of pause
    uint16 tokenCount;                  // Total tokens minted and reserved. (not including caught mobs)

    uint16 tokensGiven;                     // Total number of giveaway token's minted
    uint16 constant TOKENS_GIVEAWAY = 200;  // Max number of giveaway tokens

    uint constant PRICE_MINT = 0.08 ether;    // Mint cost

    string __uriBase;       // Metadata URI base
    string __uriSuffix;     // Metadata URI suffix

    uint constant COOLDOWN = 10;            // Min interval in blocks to reserve
    uint16 constant TRANSACTION_LIMIT = 10; // Max tokens reservable in one transaction

    mapping(address => Reservation) reservations;       // Mapping of buyer to reservations
    mapping(address => uint8) whitelistReserveCount;    // Mapping of how many times listees have preReserved
    uint8 constant WHITELIST_RESERVE_LIMIT = 2;         // Limit of how many tokens a listee can preReserve
    uint constant PRESALE_LIMIT = 2000;                 // Max number of tokens that can be preReserved
    uint presaleCount;                                  // Number of tokens that have been preReserved


    event Pause(bool _pause,uint _startTime,uint _pauseTime);
    event Reserve(address indexed reservist, uint indexed tokenId);
    event Claim(address indexed reservist, uint indexed tokenId);

    //MOB VARS
    address trapContract;   // Address of Traps contract
    address whitelist;      // Address of Whitelist contract

    uint16 constant SALE_MAX = 10000;       // Max number of tokens that can be sold
    uint16[4] mobTokenIds;                  // Partial IDs of current mobs. 4th slot is highest id (used to detect mob end)
    uint16 constant TOTAL_MOB_COUNT = 500;  // Total number of mobs that will exist

    uint constant MOB_OFFSET = 100000;      // TokenId offset for mobs

    bool mobReleased = false;               // Has mob been released
    bytes32 mobHash;                        // Current mob data


    mapping(address => uint256) internal balances;                      // Mapping of balances (not including active mobs)
    mapping (uint256 => address) internal allowance;                    // Mapping of allowances
    mapping (address => mapping (address => bool)) internal authorised; // Mapping of token allowances

    mapping(uint256 => address) owners;  // Mapping of owners (not including active mobs)

    uint[] tokens;      // Array of tokenIds (not including active mobs)

    mapping (bytes4 => bool) internal supportedInterfaces;


    constructor(string memory _uriBase, string memory _uriSuffix, address _trapContract, address _whitelist){

        supportedInterfaces[0x80ac58cd] = true; //ERC721
        supportedInterfaces[0x5b5e139f] = true; //ERC721Metadata
        supportedInterfaces[0x01ffc9a7] = true; //ERC165

        mobTokenIds[0] = 1;
        mobTokenIds[1] = 2;
        mobTokenIds[2] = 3;
        mobTokenIds[3] = 3;

        trapContract = _trapContract;
        whitelist = _whitelist;

        __uriBase = _uriBase;
        __uriSuffix = _uriSuffix;

        //Init mobHash segments
        mobHash =
            shiftBytes(bytes32(uint(0)),0) ^ // Random data that changes every tx to even out gas costs
            shiftBytes(bytes32(uint(1)),1) ^ // Number of owners to base ownership calcs on for mob 0
            shiftBytes(bytes32(uint(1)),2) ^ // Number of owners to base ownership calcs on for mob 1
            shiftBytes(bytes32(uint(1)),3) ^ // Number of owners to base ownership calcs on for mob 2
            shiftBytes(bytes32(uint(0)),4);  // Location data for calculating ownership of all mobs
    }

    /// Mint-Reserve State
    /// @notice Get struct properties of reservation mapping for given address, as well as preReserve count.
    /// @dev Combined these to lower compiled contract size (Spurious Dragon).
    /// @param _tokenOwner Address of reservation data to check
    /// @return _whitelistReserveCount Number of times address has pre-reserved
    /// @return blockNumber Block number of last reservation
    /// @return tokenIds Array of reserved, unclaimed tokens
    function mintReserveState(address _tokenOwner)  public view returns(uint8 _whitelistReserveCount, uint24 blockNumber, uint16[] memory tokenIds){
        return (whitelistReserveCount[_tokenOwner],reservations[_tokenOwner].block,reservations[_tokenOwner].tokens);
    }

    /// Contract State
    /// @notice View function for various contract state properties
    /// @dev Combined these to lower compiled contract size (Spurious Dragon).
    /// @return _tokenCount Number of tokens reserved or minted (not including mobs)
    /// @return _phase Current launch phase
    /// @return mobMax Uint used to calculate IDs and number if mobs in circulation.
    function contractState() public view returns(uint _tokenCount, Phase _phase, uint mobMax){
        return (tokenCount,phase(),mobTokenIds[3]);
    }



    /// Pre-Reserve
    /// @notice Pre-reserve tokens during Pre-Reserve phase if whitelisted. Max 2 per address. Must pay mint fee
    /// @param merkleProof Merkle proof for your address in the whitelist
    /// @param _count Number of tokens to reserve
    function preReserve(bytes32[] memory merkleProof, uint8 _count) external payable{
        require(!paused,"paused");
        require(phase() == Phase.PreReserve,"phase");
        require(msg.value >= PRICE_MINT * _count,"PRICE_MINT");
        require(whitelistReserveCount[msg.sender] + _count <= WHITELIST_RESERVE_LIMIT,"whitelistReserveCount");
        require(presaleCount + _count < PRESALE_LIMIT,"PRESALE_LIMIT");
        require(GBAWhitelist(whitelist).isWhitelisted(merkleProof,msg.sender),"whitelist");

        whitelistReserveCount[msg.sender] += _count;
        presaleCount += _count;
        _reserve(_count,msg.sender,true);
    }


    /// Mint Giveaway
    /// @notice Mint tokens for giveaway
    /// @param numTokens Number of tokens to mint
    function mintGiveaway(uint16 numTokens) public onlyOwner {
        require(tokensGiven + numTokens <= TOKENS_GIVEAWAY,"tokensGiven");
        require(tokenCount + numTokens <= SALE_MAX,"SALE_MAX");
        for(uint i = 0; i < numTokens; i++){
            tokensGiven++;
            _mint(msg.sender,++tokenCount);
        }
    }

    /// Withdraw All
    /// @notice Withdraw all Eth from mint fees
    function withdrawAll() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /// Reserve
    /// @notice Reserve tokens. Max 10 per tx, one tx per 10 blocks. Can't be called by contracts. Must be in Reserve phase. Must pay mint fee.
    /// @param _count Number of tokens to reserve
    /// @dev requires tx.origin == msg.sender
    function reserve(uint16 _count) public payable{
        require(msg.sender == tx.origin,"origin");
        require(!paused,"paused");
        require(phase() == Phase.Reserve,"phase");
        require(_count <= TRANSACTION_LIMIT,"TRANSACTION_LIMIT");
        require(msg.value >= uint(_count) * PRICE_MINT,"PRICE MINT");

        _reserve(_count,msg.sender,false);
    }


    /// Internal Reserve
    /// @notice Does the work in both Reserve and PreReserve
    /// @param _count Number of tokens being reserved
    /// @param _to Address that is reserving
    /// @param ignoreCooldown Don't revert for cooldown.Used in pre-reserve
    function _reserve(uint16 _count, address _to, bool ignoreCooldown) internal{
        require(tokenCount + _count <= SALE_MAX, "SALE_MAX");
        require(ignoreCooldown ||
            reservations[_to].block == 0 || block.number >= uint(reservations[_to].block) + COOLDOWN
        ,"COOLDOWN");

        for(uint16 i = 0; i < _count; i++){
            reservations[address(_to)].tokens.push(++tokenCount);

            emit Reserve(_to,tokenCount);
        }
        reservations[_to].block = uint24(block.number);

    }


    /// Claim
    /// @notice Mint reserved tokens
    /// @param reservist Address with reserved tokens.
    /// @param _count Number of reserved tokens mint.
    /// @dev Allows anyone to call claim for anyone else. Will mint to the address that made the reservations.
    function claim(address reservist, uint _count) public{
        require(!paused,"paused");
        require(
            phase() == Phase.Final
        ,"phase");

        require( reservations[reservist].tokens.length >= _count, "_count");
        for(uint i = 0; i < _count; i++){
            uint tokenId = uint(reservations[reservist].tokens[reservations[reservist].tokens.length - 1]);
            reservations[reservist].tokens.pop();
            _mint(reservist,tokenId);
            emit Claim(reservist,tokenId);
        }

        updateMobStart();
        updateMobFinish();
    }


    /// Mint
    /// @notice Mint unreserved tokens. Must pay mint fee.
    /// @param _count Number of reserved tokens mint.
    function mint(uint _count) public payable{
        require(!paused,"paused");
        require(
            phase() == Phase.Final
        ,"phase");
        require(msg.value >= _count * PRICE_MINT,"PRICE");

        require(tokenCount + uint16(_count) <= SALE_MAX,"SALE_MAX");

        for(uint i = 0; i < _count; i++){
            _mint(msg.sender,uint(++tokenCount));
        }

        updateMobStart();
        updateMobFinish();
    }


    /// Update URI
    /// @notice Update URI base and suffix
    /// @param _uriBase URI base
    /// @param _uriSuffix URI suffix
    /// @dev Pushing size limits (Spurious Dragon), so rather than having an explicit lock function, it can be implicit by renouncing ownership.
    function updateURI(string memory _uriBase, string memory _uriSuffix) public onlyOwner{
        __uriBase   = _uriBase;
        __uriSuffix = _uriSuffix;
    }


    /// Phase
    /// @notice Internal function to calculate current Phase
    /// @return Phase (enum value)
    function phase() internal view returns(Phase){
        uint _startTime = startTime;
        if(_startTime == 0){
            return Phase.Init;
        }else if(block.timestamp <= _startTime + 2 hours){
            return Phase.PreReserve;
        }else if(block.timestamp <= _startTime + 2 hours + 1 days && tokenCount < SALE_MAX){
            return Phase.Reserve;
        }else{
            return Phase.Final;
        }
    }

    /// Pause State
    /// @notice Get current pause state
    /// @return _paused Contract is paused
    /// @return _startTime Start timestamp of Cat phase (adjusted for pauses)
    /// @return _pauseTime Timestamp of pause
    function pauseState() view public returns(bool _paused,uint _startTime,uint _pauseTime){
        return (paused,startTime,pauseTime);
    }


    /// Disable pause
    /// @notice Disable mint pausability
    function disablePause() public onlyOwner{
        if(paused) togglePause();
        unpausable = true;
    }

    /// Toggle pause
    /// @notice Toggle pause on/off
    function togglePause() public onlyOwner{
        if(startTime == 0){
            startTime = block.timestamp;
            paused = false;
            emit Pause(false,startTime,pauseTime);
            return;
        }
        require(!unpausable,"unpausable");

        bool _pause = !paused;
        if(_pause){
            pauseTime = block.timestamp;
        }else if(pauseTime != 0){
            startTime += block.timestamp - pauseTime;
            delete pauseTime;
        }
        paused = _pause;
        emit Pause(_pause,startTime,pauseTime);
    }


    /// Get Mob Owner
    /// @notice Internal func to calculate the owner of a given mob for a given mob hash
    /// @param _mobIndex Index of mob to check (0-2)
    /// @param _mobHash Mob hash to base calcs off
    /// @return Address of the calculated owner
    function getMobOwner(uint _mobIndex, bytes32 _mobHash) internal view returns(address){
        bytes32 mobModulo = extractBytes(_mobHash, _mobIndex + 1);
        bytes32 locationHash = extractBytes(_mobHash,4);

        uint hash = uint(keccak256(abi.encodePacked(locationHash,_mobIndex,mobModulo)));
        uint index = hash % uint(mobModulo);

        address _owner = owners[tokens[index]];

        if(mobReleased){
            return _owner;
        }else{
            return address(0);
        }
    }

    /// Get Mob Token ID (internal)
    /// @notice Internal func to calculate mob token ID given an index
    /// @dev Doesn't check invalid vals, inferred by places where its used and saves gas
    /// @param _mobIndex Index of mob to calculate
    /// @return tokenId of mob
    function _getMobTokenId(uint _mobIndex) internal view returns(uint){
        return MOB_OFFSET+uint(mobTokenIds[_mobIndex]);
    }

    /// Get Mob Token ID
    /// @notice Calculate mob token ID given an index
    /// @dev Doesn't fail for _mobIndex = 3, because of Spurious Dragon and because it doesnt matter
    /// @param _mobIndex Index of mob to calculate
    /// @return tokenId of mob
    function getMobTokenId(uint _mobIndex) public view returns(uint){
        uint tokenId = _getMobTokenId(_mobIndex);
        require(tokenId != MOB_OFFSET,"no token");
        return tokenId;
    }

    /// Extract Bytes
    /// @notice Get the nth 4-byte chunk from a bytes32
    /// @param data Data to extract bytes from
    /// @param index Index of chunk
    function extractBytes(bytes32 data, uint index) internal pure returns(bytes32){
        uint inset = 32 * ( 7 -  index );
        uint outset = 32 * index;
        return ((data  << outset) >> outset) >> inset;
    }

    /// Extract Bytes
    /// @notice Bit shift a bytes32 for XOR packing
    /// @param data Data to bit shift
    /// @param index How many 4-byte segments to shift it by
    function shiftBytes(bytes32 data, uint index) internal pure returns(bytes32){
        uint inset = 32 * ( 7 -  index );
        return data << inset;
    }

    /// Release Mob
    /// @notice Start Mob
    function releaseMob() public onlyOwner{
        require(!mobReleased,"released");
        require(tokens.length > 0, "no mint");

        mobReleased = true;

        bytes32 _mobHash = mobHash;                                         //READ
        uint eliminationBlock = block.number - (block.number % 245) - 10;    //READ

        bytes32 updateHash  = extractBytes(keccak256(abi.encodePacked(_mobHash)),0);

        bytes32 mobModulo = bytes32(tokens.length);
        bytes32 destinationHash = extractBytes( blockhash(eliminationBlock),4) ;

        bytes32 newMobHash =    shiftBytes(updateHash,0) ^                                                //WRITE
                                shiftBytes(mobModulo,1) ^
                                shiftBytes(mobModulo,2) ^
                                shiftBytes(mobModulo,3) ^
                                shiftBytes(destinationHash,4);

        for(uint i = 0; i < 3; i++){
            uint _tokenId = _getMobTokenId(i);                                       //READ x 3
            emit Transfer(address(0),getMobOwner(i,newMobHash),_tokenId);           //EMIT x 3 max
        }

        mobHash = newMobHash;
    }

    /// Update Mobs Start
    /// @notice Internal - Emits all the events sending mobs to 0. First part of mobs moving
    function updateMobStart() internal{
        if(!mobReleased || mobTokenIds[3] == 0) return;

        //BURN THEM
        bytes32 _mobHash = mobHash;                                         //READ
        for(uint i = 0; i < 3; i++){
            uint _tokenId = _getMobTokenId(i);                                       //READ x 3
            if(_tokenId != MOB_OFFSET){
                emit Transfer(getMobOwner(i,_mobHash),address(0),_tokenId);           //READx3, EMIT x 3 max
            }
        }
    }

    /// Update Mobs Finish
    /// @notice Internal - Calculates mob owners and emits events sending to them. Second part of mobs moving
    function updateMobFinish() internal {
        if(!mobReleased) {
            require(gasleft() > 100000,"gas failsafe");
            return;
        }
        if(mobTokenIds[3] == 0) return;

        require(gasleft() > 64500,"gas failsafe");

        bytes32 _mobHash = mobHash;                                         //READ
        uint eliminationBlock = block.number - (block.number % 245) - 10;    //READ

        bytes32 updateHash  = extractBytes(keccak256(abi.encodePacked(_mobHash)),0);

        bytes32 mobModulo0 = extractBytes(_mobHash,1);
        bytes32 mobModulo1 = extractBytes(_mobHash,2);
        bytes32 mobModulo2 = extractBytes(_mobHash,3);

        bytes32 destinationHash = extractBytes( blockhash(eliminationBlock),4);

        bytes32 newMobHash = shiftBytes(updateHash,0) ^
                                shiftBytes(mobModulo0,1) ^
                                shiftBytes(mobModulo1,2) ^
                                shiftBytes(mobModulo2,3) ^
                                shiftBytes(destinationHash,4);

        mobHash = newMobHash; //WRITE

        for(uint i = 0; i < 3; i++){
            uint _tokenId = _getMobTokenId(i);                                       //READ x 3
            if(_tokenId != MOB_OFFSET){
                emit Transfer(address(0),getMobOwner(i,newMobHash),_tokenId);         //READx3, EMIT x 3 max
            }
        }
    }


    /// Update Catch Mob
    /// @notice Catch a mob that's in your wallet
    /// @param _mobIndex Index of mob to catch
    /// @dev Mints real token and updates mobs
    function catchMob(uint _mobIndex) public {
        IGBATrapsPartial(trapContract).useTrap(msg.sender);

        require(_mobIndex < 3,"mobIndex");
        bytes32 _mobHash = mobHash;
        address mobOwner = getMobOwner(_mobIndex,_mobHash);
        require(msg.sender == mobOwner,"owner");

        updateMobStart();   //Kill all mobs

        bytes32 updateHash  = extractBytes(_mobHash,0);

        bytes32[3] memory mobModulo;

        for(uint i = 0; i < 3; i++){
            mobModulo[i] = extractBytes(_mobHash,i + 1);
        }

        uint mobTokenId = _getMobTokenId(_mobIndex);                //READ

        //Mint real one
        _mint(msg.sender,mobTokenId+MOB_OFFSET);

        bool mintNewMob = true;
        if(mobTokenIds[3] < TOTAL_MOB_COUNT){
            mobTokenIds[_mobIndex] =  ++mobTokenIds[3];
        }else{
            mintNewMob = false;

            //if final 3
            mobTokenIds[3]++;
            mobTokenIds[_mobIndex] = 0;

            if(mobTokenIds[3] == TOTAL_MOB_COUNT + 3){
                //if final mob, clear last slot to identify end condition
                delete mobTokenIds[3];
            }
        }

        mobModulo[_mobIndex] = bytes32(tokens.length);

        uint eliminationBlock = block.number - (block.number % 245) - 10;    //READ
        bytes32 destinationHash = extractBytes( blockhash(eliminationBlock),4);

        mobHash = shiftBytes(updateHash,0) ^                       //WRITE
                    shiftBytes(mobModulo[0],1) ^
                    shiftBytes(mobModulo[1],2) ^
                    shiftBytes(mobModulo[2],3) ^
                    shiftBytes(destinationHash,4);

        updateMobFinish(); //release mobs
    }

    /// Mint (internal)
    /// @notice Mints real tokens as per ERC721
    /// @param _to Address to mint it for
    /// @param _tokenId Token to mint
    function _mint(address _to,uint _tokenId) internal{
        emit Transfer(address(0), _to, _tokenId);

        owners[_tokenId] =_to;
        balances[_to]++;
        tokens.push(_tokenId);
    }

    /// Is Valid Token (internal)
    /// @notice Checks if given tokenId exists (Doesn't apply to mobs)
    /// @param _tokenId TokenId to check
    function isValidToken(uint256 _tokenId) internal view returns(bool){
        return owners[_tokenId] != address(0);
    }

    /// Require Valid (internal)
    /// @notice Reverts if given token doesn't exist
    function requireValid(uint _tokenId) internal view{
        require(isValidToken(_tokenId),"valid");
    }

    /// Balance Of
    /// @notice ERC721 balanceOf func, includes active mobs
    function balanceOf(address _owner) external override view returns (uint256){
        uint _balance = balances[_owner];
        bytes32 _mobHash = mobHash;
        for(uint i = 0; i < 3; i++){
            if(getMobOwner(i, _mobHash) == _owner){
                _balance++;
            }
        }
        return _balance;
    }

    /// Owner Of
    /// @notice ERC721 ownerOf func, includes active mobs
    function ownerOf(uint256 _tokenId) public override view returns(address){
        bytes32 _mobHash = mobHash;
        for(uint i = 0; i < 3; i++){
            if(_getMobTokenId(i) == _tokenId){
                address owner = getMobOwner(i,_mobHash);
                require(owner != address(0),"invalid");
                return owner;
            }
        }
        requireValid(_tokenId);
        return owners[_tokenId];
    }

    /// Approve
    /// @notice ERC721 function
    function approve(address _approved, uint256 _tokenId)  external override{
        address _owner = owners[_tokenId];
        require( _owner == msg.sender                    //Require Sender Owns Token
            || authorised[_owner][msg.sender]                //  or is approved for all.
            ,"permission");
        emit Approval(_owner, _approved, _tokenId);
        allowance[_tokenId] = _approved;
    }

    /// Get Approved
    /// @notice ERC721 function
    function getApproved(uint256 _tokenId) external view override returns (address) {
//        require(isValidToken(_tokenId),"invalid");
        requireValid(_tokenId);
        return allowance[_tokenId];
    }

    /// Is Approved For All
    /// @notice ERC721 function
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return authorised[_owner][_operator];
    }

    /// Set Approval For All
    /// @notice ERC721 function
    function setApprovalForAll(address _operator, bool _approved) external override {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        authorised[msg.sender][_operator] = _approved;
    }

    /// Transfer From
    /// @notice ERC721 function
    /// @dev Fails for mobs
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        requireValid(_tokenId);

        //Check Transferable
        //There is a token validity check in ownerOf
        address _owner = owners[_tokenId];

        require ( _owner == msg.sender             //Require sender owns token
            //Doing the two below manually instead of referring to the external methods saves gas
            || allowance[_tokenId] == msg.sender      //or is approved for this token
            || authorised[_owner][msg.sender]          //or is approved for all
        ,"permission");
        require(_owner == _from,"owner");
        require(_to != address(0),"zero");

        updateMobStart();

        emit Transfer(_from, _to, _tokenId);

        owners[_tokenId] =_to;

        balances[_from]--;
        balances[_to]++;

        //Reset approved if there is one
        if(allowance[_tokenId] != address(0)){
            delete allowance[_tokenId];
        }

        updateMobFinish();
    }

    /// Safe Transfer From
    /// @notice ERC721 function
    /// @dev Fails for mobs
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public override {
        transferFrom(_from, _to, _tokenId);

        //Get size of "_to" address, if 0 it's a wallet
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            IERC721TokenReceiver receiver = IERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),"receiver");
        }

    }

    /// Safe Transfer From
    /// @notice ERC721 function
    /// @dev Fails for mobs
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        safeTransferFrom(_from,_to,_tokenId,"");
    }


    /// Name
    /// @notice ERC721 Metadata function
    /// @return _name Name of token
    function name() external pure override returns (string memory _name){
        return "Ghostbusters: Afterlife Collectibles";
    }

    /// Symbol
    /// @notice ERC721 Metadata function
    /// @return _symbol Symbol of token
    function symbol() external pure override returns (string memory _symbol){
        return "GBAC";
    }

    /// Token URI
    /// @notice ERC721 Metadata function (includes active mobs)
    /// @param _tokenId ID of token to check
    /// @return URI (string)
    function tokenURI(uint256 _tokenId) public view  override returns (string memory) {
        ownerOf(_tokenId); //includes validity check

        return string(abi.encodePacked(__uriBase,toString(_tokenId),__uriSuffix));
    }

    /// To String
    /// @notice Converts uint to string
    /// @param value uint to convert
    /// @return String
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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



    // ENUMERABLE FUNCTIONS (not actually needed for compliance but everyone likes totalSupply)
    function totalSupply() public view returns (uint256){
        uint highestMob = mobTokenIds[3];
        if(!mobReleased || highestMob == 0){
            return tokens.length;
        }else if(highestMob < TOTAL_MOB_COUNT){
            return tokens.length + 3;
        }else{
            return tokens.length + 3 - (TOTAL_MOB_COUNT - highestMob);
        }

    }

    function supportsInterface(bytes4 interfaceID) external override view returns (bool){
        return supportedInterfaces[interfaceID];
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author Andrew Parker
/// @title Ghost Busters: Afterlife Traps NFT contract partial interface
/// @notice For viewer func, and also for MSP because Traps relies on OpenZepp and MSP uses pure 721 implementation.
interface IGBATrapsPartial{
    enum State { Paused, Whitelist, Public, Final}

    function useTrap(address owner) external;

    function tokensClaimed() external view returns(uint);
    function hasMinted(address minter) external view returns(bool);
    function saleStarted() external view returns(bool);
    function whitelistEndTime() external view returns(uint);
    function balanceOf(address _owner) external view returns (uint256);
    function mintState() external view returns(State);
    function countdown() external view returns(uint);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * OpenZeppelin's Ownable, but without Context, because it saves about 500 bytes
 *   and compiled contract is pushing limits of Spurious Dragon and is unnecessary.

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
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
        require(owner() == msg.sender, "onlyOwner");
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
        require(newOwner != address(0), "zero");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @author Andrew Parker
/// @title GBA Whitelist NFT Contract
/// @notice Implementation of OpenZeppelin MerkleProof contract for GBA MiniStayPuft and Traps NFTs
contract GBAWhitelist{
    bytes32 merkleRoot;

    /// Constructor
    /// @param _merkleRoot root of merkle tree
    constructor(bytes32 _merkleRoot){
        merkleRoot = _merkleRoot;
    }

    /// Is Whitelisted
    /// @notice Is a given address whitelisted based on proof provided
    /// @param proof Merkle proof
    /// @param claimer address to check
    /// @return Is whitelisted
    function isWhitelisted(bytes32[] memory proof, address claimer) public view returns(bool){
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof,merkleRoot,leaf);
    }
}

// SPDX-License-Identifier: MIT

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

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}