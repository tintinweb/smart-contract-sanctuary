// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;




///  _           _   _         _    _                                         _     
/// | |_ ___ ___| |_|_|___ ___| |  | |_ ___ ___ ___ ___ ___ _____ ___        |_|___ 
/// |  _| .'|  _|  _| |  _| .'| |  |  _| .'|   | . |  _| .'|     |_ -|   _   | | . |
/// |_| |__,|___|_| |_|___|__,|_|  |_| |__,|_|_|_  |_| |__,|_|_|_|___|  |_|  |_|___|
///                                            |___|                                
///
///                                                              tacticaltangrams.io




///  _                   _       
/// |_|_____ ___ ___ ___| |_ ___ 
/// | |     | . | . |  _|  _|_ -|
/// |_|_|_|_|  _|___|_| |_| |___|
///         |_|                  

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./State.sol";
import "./Team.sol";
import "./VRFD20.sol";




///  _     _           ___                 
/// |_|___| |_ ___ ___|  _|___ ___ ___ ___ 
/// | |   |  _| -_|  _|  _| .'|  _| -_|_ -|
/// |_|_|_|_| |___|_| |_| |__,|___|___|___|

interface TangramContract {
    function getGeneration(uint tokenId) external pure returns (uint);
    function getTanMetadata(uint tokenId, uint generation, uint generationSeed) external pure returns (string memory);
}




///              _               _      _____         
///  ___ ___ ___| |_ ___ ___ ___| |_   |_   _|___ ___ 
/// |  _| . |   |  _|  _| .'|  _|  _|    | | | .'|   |
/// |___|___|_|_|_| |_| |__,|___|_|      |_| |__,|_|_|                                                  

/// @title Tactical Tangrams main Tan contract
/// @author tacticaltangrams.io
/// @notice Tracks all Tan operations for tacticaltangrams.io. This makes this contract the OpenSea Tan collection
contract Tan is
    ERC721Enumerable,
    Ownable,
    Pausable,
    State,
    Team,
    VRFD20 {




    /// @notice Emit Generation closing event; triggered by swapping 80+ Tans for the current generation
    /// @param generation Generation that is closing
    event GenerationClosing(uint generation);

    /// @notice Emit Generation closed event
    /// @param generation Generation that is closed
    event GenerationClosed(uint generation);




    ///                  _               _           
    ///  ___ ___ ___ ___| |_ ___ _ _ ___| |_ ___ ___ 
    /// |  _| . |   |_ -|  _|  _| | |  _|  _| . |  _|
    /// |___|___|_|_|___|_| |_| |___|___|_| |___|_|  

    /// @notice Deployment constructor
    /// @param _name                    ERC721 name of token
    /// @param _symbol                  ERC721 symbol of token
    /// @param _openPremintAtDeployment Opens premint directly at contract deployment
    /// @param _vrfCoordinator          Chainlink VRF Coordinator address
    /// @param _link                    LINK token address
    /// @param _keyHash                 Public key against which randomness is created
    /// @param _fee                     VRF Chainlink fee in LINK
    /// @param _teamAddresses           List of team member's addresses; first address is emergency address
    /// @param _tangramContract         Address for Tangram contract
    constructor(
            address payable[TEAM_SIZE] memory _teamAddresses,
            string memory                     _name,
            string memory                     _symbol,
            bool                              _openPremintAtDeployment,
            address                           _vrfCoordinator,
            address                           _link,
            bytes32                           _keyHash,
            uint                              _fee,
            address                           _tangramContract
        )

        ERC721(
            _name,
            _symbol
        )

        Team(
            _teamAddresses
        )

        VRFD20(
            _vrfCoordinator,
            _link,
            _keyHash,
            _fee
        )
    {
        vrfCoordinator = _vrfCoordinator;
        setTangramContract(_tangramContract);

        if (_openPremintAtDeployment)
        {
            changeState(
                StateType.DEPLOYED,
                StateType.PREMINT);
        }
    }




    ///        _     _   
    ///  _____|_|___| |_ 
    /// |     | |   |  _|
    /// |_|_|_|_|_|_|_|  

    uint constant public MAX_MINT         = 15554;
    uint constant public MAX_TANS_OG      = 7;
    uint constant public MAX_TANS_WL      = 7;
    uint constant public MAX_TANS_PUBLIC  = 14;

    uint constant public PRICE_WL         = 2 * 1e16;
    uint constant public PRICE_PUBLIC     = 3 * 1e16;

    bytes32 private merkleRootOG = 0x67a345396a56431c46add239308b6fcfbab7dbf09287447d3f5f2458c0cccdc5;
    bytes32 private merkleRootWL = 0xf6c54efaf65ac33f79611e973313be91913aaf019de02d6d3ae1e6566f75929a;

    mapping (address => bool) private addressPreminted;
    mapping (uint    => uint) public mintCounter;

    string private constant INVALID_NUMBER_OF_TANS = "Invalid number of tans or no more tans left";

    /// @notice Get maximum number of mints for the given generation
    /// @param generation Generation to get max mints for
    /// @return Maximum number of mints for generation
    function maxMintForGeneration(uint generation) public pure
        generationBetween(generation, 1, 7)
        returns (uint)
    {
        if (generation == 7) {
            return 55;
        }
        if (generation == 6) {
            return 385;
        }
        if (generation == 5) {
            return 980;
        }
        if (generation == 4) {
            return 2310;
        }
        if (generation == 3) {
            return 5005;
        }
        if (generation == 2) {
            return 9156;
        }

        return MAX_MINT;
    }


    /// @notice Get number of mints for the given generation for closing announcement
    /// @param generation Generation to get max mints for
    /// @return Maximum number of mints for generation
    function maxMintForGenerationBeforeClosing(uint generation) public pure
        generationBetween(generation, 2, 6)
        returns (uint)
    {
        if (generation == 6) {
            return 308;
        }
        if (generation == 5) {
            return 784;
        }
        if (generation == 4) {
            return 1848;
        }
        if (generation == 3) {
            return 4004;
        }

        return 7325;
    }


    /// @notice Get the lowest Tan ID for a given generation
    /// @param generation Generation to get lowest ID for
    /// @return Lowest Tan ID for generation
    function mintStartNumberForGeneration(uint generation) public pure
        generationBetween(generation, 1, 7)
        returns (uint)
    {
        uint tmp = 1;
        for (uint gen = 1; gen <= 7; gen++) {
            if (generation == gen) {
                return tmp;
            }
            tmp += maxMintForGeneration(gen);
        }

        return 0;
    }


    /// @notice Public mint method. Checks whether the paid price is correct and max. 14 Tans are minted per tx
    /// @param numTans number of Tans to mint
    function mint(uint numTans) external payable
        forPrice(numTans, PRICE_PUBLIC, msg.value)
        inState(StateType.MINT)
        limitTans(numTans, MAX_TANS_PUBLIC)
    {
        mintLocal(numTans);
    }


    /// @notice Mint helper method
    /// @dev All checks need to be performed before calling this method
    /// @param numTans number of Tans to mint
    function mintLocal(uint numTans) private
        inEitherState(StateType.PREMINT, StateType.MINT)
        whenNotPaused()
    {
        for (uint mintedTan = 0; mintedTan < numTans; mintedTan++) {
            _mint(_msgSender(), totalSupply() + 1);
        }        
    }


    /// @notice Mint next-gen Tans at Tangram swap
    /// @param numTans number of Tans to mint
    /// @param _for Address to mint Tans for
    function mintForNextGeneration(uint numTans, address _for) external
        generationBetween(currentGeneration, 1, 6)
        inStateOrAbove(StateType.GENERATIONSTARTED)
        onlyTangramContract()
        whenNotPaused()
    {
        uint nextGeneration = currentGeneration + 1;

        uint maxMintForNextGeneration = maxMintForGeneration(nextGeneration);

        require(
            mintCounter[nextGeneration] + numTans <= maxMintForNextGeneration,
            INVALID_NUMBER_OF_TANS
        );

        for (uint mintedTan = 0; mintedTan < numTans; mintedTan++) {
            _mint(
                _for,
                mintStartNumberForGeneration(nextGeneration) + mintCounter[nextGeneration]++
            );
        }
    }


    /// @notice OG mint method. Allowed once per OG minter, OG proof is by merkle proof. Max 7 Tans allowed
    /// @dev Method is not payable since OG mint for free
    /// @param merkleProof Merkle proof of minter address for OG tree
    /// @param numTans     Number of Tans to mint
    function mintOG(bytes32[] calldata merkleProof, uint numTans) external
        inEitherState(StateType.PREMINT, StateType.MINT)
        isValidMerkleProof(merkleRootOG, merkleProof)
        limitTans(numTans, MAX_TANS_OG)
        oneMint()
    {
        addressPreminted[_msgSender()] = true;
        mintLocal(numTans);
    }


    /// @notice WL mint method. Allowed once per WL minter, WL proof is by merkle proof. Max 7 Tans allowed
    /// @param merkleProof Merkle proof of minter address for WL tree
    /// @param numTans     Number of Tans to mint
    function mintWL(bytes32[] calldata merkleProof, uint numTans) external payable
        forPrice(numTans, PRICE_WL, msg.value)
        inEitherState(StateType.PREMINT, StateType.MINT)
        isValidMerkleProof(merkleRootWL, merkleProof)
        limitTans(numTans, MAX_TANS_WL)
        oneMint()
    {
        addressPreminted[_msgSender()] = true;
        mintLocal(numTans);
    }


    /// @notice Update merkle roots for OG/WL minters
    /// @param og OG merkle root
    /// @param wl WL merkle root
    function setMerkleRoot(bytes32 og, bytes32 wl) external
        onlyOwner()
    {
        merkleRootOG = og;
        merkleRootWL = wl;
    }


    /// @notice Require correct paid price
    /// @dev WL and public mint pay a fixed price per Tan
    /// @param numTans   Number of Tans to mint
    /// @param unitPrice Fixed price per Tan
    /// @param ethSent   Value of ETH sent in this transaction
    modifier forPrice(uint numTans, uint unitPrice, uint ethSent) {
        require(
            numTans * unitPrice == ethSent,
            "Wrong value sent"
        );
        _;
    }


    /// @notice Verify provided merkle proof to given root
    /// @dev Root is manually generated before contract deployment. Proof is automatically provided by minting site based on connected wallet address.
    /// @param root  Merkle root to verify against
    /// @param proof Merkle proof to verify
    modifier isValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
        require(
            MerkleProof.verify(proof, root, keccak256(abi.encodePacked(_msgSender()))),
            "Invalid proof"
        );
        _;
    }


    /// @notice Require a valid number of Tans
    /// @param numTans Number of Tans to mint
    /// @param maxTans Maximum number of Tans to allow
    modifier limitTans(uint numTans, uint maxTans) {
        require(
            numTans >= 1 &&
            numTans <= maxTans &&
            totalSupply() + numTans <= MAX_MINT,
            INVALID_NUMBER_OF_TANS
        );
        _;
    }


    /// @notice Require maximum one mint per address
    /// @dev OG and WL minters have this restriction
    modifier oneMint() {
        require(
            addressPreminted[_msgSender()] == false,
            "Only one premint allowed"
        );
        _;
    }




    ///      _       _       
    ///  ___| |_ ___| |_ ___ 
    /// |_ -|  _| .'|  _| -_|
    /// |___|_| |__,|_| |___|                     

    /// @notice Change to mint stage; this is an implicit action when "mint" is called when shouldPublicMintBeOpen == true
    /// @dev Can only be called over Chainlink VRF random response
    function changeStateGenerationClosed() internal virtual override
        generationBetween(currentGeneration, 1, 7)
        inEitherState(StateType.GENERATIONSTARTED, StateType.GENERATIONCLOSING)
        onlyTeamMemberOrOwner()
    {
        if (currentGeneration < 7) {
            lastGenerationSeedRequestTimestamp = 0;
            requestGenerationSeed(currentGeneration + 1);
        }

        emit GenerationClosed(currentGeneration);
    }


    /// @notice Change to mint stage; this is an implicit action when "mint" is called when shouldPublicMintBeOpen == true
    /// @dev Can only be called over Chainlink VRF random response
    function changeStateGenerationClosing() internal virtual override
        inState(StateType.GENERATIONSTARTED)
        onlyTangramContract()
    {
        emit GenerationClosing(currentGeneration);
    }


    /// @notice Change to mint stage; this is an implicit action when "mint" is called when shouldPublicMintBeOpen == true
    /// @dev Can only be called over Chainlink VRF random response
    function changeStateGenerationStarted() internal virtual override
        inEitherState(StateType.MINTCLOSED, StateType.GENERATIONCLOSED)
        onlyVRFCoordinator()
    {
    }


    /// @notice Change to mint stage; this is an implicit action when "mint" is called when shouldPublicMintBeOpen == true
    /// @dev Can also be called over setState method
    function changeStateMint() internal virtual override
        inState(StateType.PREMINT)
        onlyTeamMemberOrOwner()
    {
    }


    /// @notice Request Gen-1 seed, payout caller's funds
    /// @dev Caller's funds are only paid when this method was invoked from a team member's address; not the owner's address
    function changeStateMintClosed() internal virtual override
        inState(StateType.MINT)
        onlyTeamMemberOrOwner()
    {
        requestGenerationSeed(1);
    }


    /// @notice Request Gen-1 seed, payout caller's funds
    /// @dev Caller's funds are only paid when this method was invoked from a team member's address; not the owner's address
    function changeStateMintClosedAfter() internal virtual override
        inState(StateType.MINTCLOSED)
        onlyTeamMemberOrOwner()
    {
        mintCounter[1] = totalSupply();
        mintBalanceTotal = address(this).balance - secondaryBalanceTotal;
        if (!emergencyCalled && isTeamMember(_msgSender()) && address(this).balance > 0)
        {
            payout();
        }
    }


    /// @notice Change to premint stage
    /// @dev This is only allowed by the contract owner, either by means of deployment or later execution of setState
    function changeStatePremint() internal virtual override
        inState(StateType.DEPLOYED)
        onlyTeamMemberOrOwner()
    {
    }


    /// @notice Set new state
    /// @dev Use this for non-automatic state changes (e.g. open premint, close generation)
    /// @param _to New state to change to
    function setState(StateType _to) external
        onlyTeamMemberOrOwner()
    {
        changeState(state, _to);
    }


    /// @notice Announce generation close
    function setStateGenerationClosing() external
        onlyTangramContract()
    {
        changeState(state, StateType.GENERATIONCLOSING);
    }




    ///                _                           
    ///  ___ ___ ___ _| |___ _____ ___ ___ ___ ___ 
    /// |  _| .'|   | . | . |     |   | -_|_ -|_ -|
    /// |_| |__,|_|_|___|___|_|_|_|_|_|___|___|___|

    address private immutable vrfCoordinator;

    /// @notice Generation seed received, open generation
    /// @dev Only possibly when mint is closed or previous generation has been closed. Seed is in VRFD20.generationSeed[generation]. Event is NOT emitted from contract address.
    /// @param generation Generation for which seed has been received
    function processGenerationSeedReceived(uint generation) internal virtual override
        inEitherState(StateType.MINTCLOSED, StateType.GENERATIONCLOSED)
        onlyVRFCoordinator()
    {
        require(
            generation == currentGeneration + 1,
            "Invalid seed generation"
        );

        currentGeneration = generation;

        state = StateType.GENERATIONSTARTED;

        // Emitting stateChanged event is useless, as this is in the VRF Coordinator's tx context
    }


    /// @notice Re-request generation seed
    /// @dev Only possible before starting new generation. Requests seed for the next generation. Important checks performed by internal method.
    function reRequestGenerationSeed() external
        inEitherState(StateType.MINT, StateType.GENERATIONCLOSED)
        onlyTeamMemberOrOwner()
    {
        requestGenerationSeed(currentGeneration + 1);
    }


    /// @notice Require that the sender is Chainlink's VRF Coordinator
    modifier onlyVRFCoordinator() {
        require(
            _msgSender() == vrfCoordinator,
            "Only VRF Coordinator"
        );
        _;
    }




    ///                      _   
    ///  ___ ___ _ _ ___ _ _| |_ 
    /// | . | .'| | | . | | |  _|
    /// |  _|__,|_  |___|___|_|  
    /// |_|     |___|            

    string private constant TX_FAILED = "TX failed";

    /// @notice Pay out all funds directly to the emergency wallet
    /// @dev Only emergency payouts can be used; personal payouts are locked
    function emergencyPayout() external
        onlyTeamMemberOrOwner()
    {
        emergencyCalled = true;
        (bool sent,) = teamAddresses[0].call{value: address(this).balance}("");
        require(
            sent,
            TX_FAILED
        );
    }


    /// @notice Pay the yet unpaid funds to the caller, when it is a team member
    /// @dev Does not work after emergency payout was used. Implement secondary share payouts
    function payout() public
        emergencyNotCalled()
        inStateOrAbove(StateType.MINTCLOSED)
    {
        (bool isTeamMember, uint teamIndex) = getTeamIndex(_msgSender());
        require(
            isTeamMember,
            "Invalid address"
        );

        uint shareIndex = teamIndex * TEAM_SHARE_RECORD_SIZE;

        uint mintShare = 0;
        if (mintSharePaid[teamIndex] == false) {
            mintSharePaid[teamIndex] = true;
            mintShare = (mintBalanceTotal * teamShare[shareIndex + TEAM_SHARE_MINT_OFFSET]) / 1000;
        }
        
        uint secondaryShare = 0;
        if (secondaryBalanceTotal > teamShare[shareIndex + TEAM_SHARE_SECONDARY_PAID_OFFSET]) {
            uint secondaryShareToPay = secondaryBalanceTotal - teamShare[shareIndex + TEAM_SHARE_SECONDARY_PAID_OFFSET];
            teamShare[shareIndex + TEAM_SHARE_SECONDARY_PAID_OFFSET] = secondaryBalanceTotal;
            secondaryShare = (secondaryShareToPay * teamShare[shareIndex + TEAM_SHARE_SECONDARY_OFFSET]) / 1000;
        }

        uint total = mintShare + secondaryShare;
        require(
            total > 0,
            "Nothing to pay"
        );

        (bool sent,) = payable(_msgSender()).call{value: total}("");
        require(
            sent,
            TX_FAILED
        );
    }


    /// @notice Keep track of total secondary sales earnings
    receive() external payable
    {
        secondaryBalanceTotal += msg.value;
    }


    /// @notice Require emergency payout to not have been called
    modifier emergencyNotCalled() {
        require(
            false == emergencyCalled,
            "Emergency called"
        );
        _;
    }



    ///              ___ ___ ___   
    ///  ___ ___ ___|_  |_  |_  |  
    /// | -_|  _|  _| | |  _|_| |_ 
    /// |___|_| |___| |_|___|_____|


    /// @notice Burn token on behalf of Tangram contract
    /// @dev Caller needs to verify token ownership
    /// @param tokenId Token ID to burn
    function burn(uint256 tokenId) external 
        onlyTangramContract()
        whenNotPaused()
    {
        _burn(tokenId);
    }


    /// @notice Return metadata url (placeholder) or base64-encoded metadata when gen-1 has started
    /// @dev Overridden from OpenZeppelin's implementation to skip the unused baseURI check
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "Nonexistent token"
        );
        
        if (state <= StateType.MINTCLOSED)
        {
            return string(abi.encodePacked(
                METADATA_BASE_URI,
                "placeholder",
                JSON_EXT
            ));
        }

        uint generation = tangramContract.getGeneration(tokenId);
        require(
            generation <= currentGeneration,
            INVALID_GENERATION
        );

        return tangramContract.getTanMetadata(tokenId, generation, generationSeed[generation]);
    }




    ///            _         _     _       
    ///  _____ ___| |_ ___ _| |___| |_ ___ 
    /// |     | -_|  _| .'| . | .'|  _| .'|
    /// |_|_|_|___|_| |__,|___|__,|_| |__,|

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(
            METADATA_BASE_URI,
            METADATA_CONTRACT,
            JSON_EXT
        ));
    }




    ///                          _ 
    ///  ___ ___ ___ ___ ___ ___| |
    /// | . | -_|   | -_|  _| .'| |
    /// |_  |___|_|_|___|_| |__,|_|
    /// |___|                      

    uint private mintBalanceTotal      = 0;
    uint private secondaryBalanceTotal = 0;
    uint public  currentGeneration     = 0;

    string private constant METADATA_BASE_URI = 'https://tacticaltangrams.io/metadata/';
    string private constant METADATA_CONTRACT = 'contract_tan';
    string private constant JSON_EXT          = '.json';

    string private constant INVALID_GENERATION = "Invalid generation";
    string private constant ONLY_TEAM_MEMBER   = "Only team member";

    modifier generationBetween(uint generation, uint from, uint to) {
        require(
            generation >= from && generation <= to,
            INVALID_GENERATION
        );
        _;
    }

    /// @notice Require that the sender is a team member
    modifier onlyTeamMember() {
        require(
            isTeamMember(_msgSender()),
            ONLY_TEAM_MEMBER
        );
        _;
    }


    /// @notice Require that the sender is a team member or the contract owner
    modifier onlyTeamMemberOrOwner() {
        require(
            _msgSender() == owner() || isTeamMember(_msgSender()),
            string(abi.encodePacked(ONLY_TEAM_MEMBER, " or owner"))
        );
        _;
    }




    ///              _               _      _____                           
    ///  ___ ___ ___| |_ ___ ___ ___| |_   |_   _|___ ___ ___ ___ ___ _____ 
    /// |  _| . |   |  _|  _| .'|  _|  _|    | | | .'|   | . |  _| .'|     |
    /// |___|___|_|_|_| |_| |__,|___|_|      |_| |__,|_|_|_  |_| |__,|_|_|_|
    ///                                                  |___|                      

    TangramContract tangramContract;
    address tangramContractAddress;

    /// @notice Set Tangram contract address
    /// @param _tangramContract Address for Tangram contract
    function setTangramContract(address _tangramContract) public
        onlyOwner()
    {
        tangramContractAddress = _tangramContract;
        tangramContract = TangramContract(_tangramContract);
    }


    /// @notice Require that the sender is the Tangram contract
    modifier onlyTangramContract() {
        require(
            _msgSender() == tangramContractAddress,
            "Only Tangram contract"
        );
        _;
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;




///  _           _   _         _    _                                         _     
/// | |_ ___ ___| |_|_|___ ___| |  | |_ ___ ___ ___ ___ ___ _____ ___        |_|___ 
/// |  _| .'|  _|  _| |  _| .'| |  |  _| .'|   | . |  _| .'|     |_ -|   _   | | . |
/// |_| |__,|___|_| |_|___|__,|_|  |_| |__,|_|_|_  |_| |__,|_|_|_|___|  |_|  |_|___|
///                                            |___|                                
///
///                                                              tacticaltangrams.io




///              _               _      _____ _       _       
///  ___ ___ ___| |_ ___ ___ ___| |_   |   __| |_ ___| |_ ___ 
/// |  _| . |   |  _|  _| .'|  _|  _|  |__   |  _| .'|  _| -_|
/// |___|___|_|_|_| |_| |__,|___|_|    |_____|_| |__,|_| |___|

/// @title Tactical Tangrams State contract
/// @author tacticaltangrams.io
/// @notice Implements the basis for Tactical Tangram's state machine
abstract contract State {


    /// @notice Emit state changes
    /// @param oldState Previous state
    /// @param newState Current state
    event StateChanged(StateType oldState, StateType newState);


    /// @notice Change to new state when state change is allowed
    /// @dev Virtual methods changeState* have to be implemented. Invalid state changes have to be reverted in each changeState* method
    /// @param _from State to change from
    /// @param _to   State to change to
    function changeState(StateType _from, StateType _to) internal
    {
        require(
            (_from != _to) &&
            (StateType.ALL == _from || state == _from),
            INVALID_STATE_CHANGE
        );

        bool stateChangeHandled = false;

        if (StateType.PREMINT == _to)
        {
            stateChangeHandled = true;
            changeStatePremint();
        }
        else if (StateType.MINT == _to)
        {
            stateChangeHandled = true;
            changeStateMint();
        }
        else if (StateType.MINTCLOSED == _to)
        {
            stateChangeHandled = true;
            changeStateMintClosed();
        }

        // StateType.GENERATIONSTARTED cannot be set over setState, this is done implicitly by processGenerationSeedReceived

        else if (StateType.GENERATIONCLOSING == _to)
        {
            stateChangeHandled = true;
            changeStateGenerationClosing();
        }
        else if (StateType.GENERATIONCLOSED == _to)
        {
            stateChangeHandled = true;
            changeStateGenerationClosed();
        }

        require(
            stateChangeHandled,
            INVALID_STATE_CHANGE
        );

        state = _to;

        emit StateChanged(_from, _to);

        if (StateType.MINTCLOSED == _to) {
            changeStateMintClosedAfter();
        }
    }


    function changeStatePremint()           internal virtual;
    function changeStateMint()              internal virtual;
    function changeStateMintClosed()        internal virtual;
    function changeStateMintClosedAfter()   internal virtual;
    function changeStateGenerationStarted() internal virtual;
    function changeStateGenerationClosing() internal virtual;
    function changeStateGenerationClosed()  internal virtual;


    /// @notice Verify allowed states
    /// @param _either Allowed state
    /// @param _or     Allowed state
    modifier inEitherState(StateType _either, StateType _or) {
        require(
            (state == _either) || (state == _or),
            INVALID_STATE
        );
        _;
    }


    /// @notice Verify allowed state
    /// @param _state Allowed state
    modifier inState(StateType _state) {
        require(
            state == _state,
            INVALID_STATE
        );
        _;
    }



    /// @notice Verify allowed minimum state
    /// @param _state Minimum allowed state
    modifier inStateOrAbove(StateType _state) {
        require(
            state >= _state,
            INVALID_STATE
        );
        _;
    }


    /// @notice List of states for Tactical Tangrams
    /// @dev When in states GENERATIONSTARTED, GENERATIONCLOSING or GENERATIONCLOSED, Tan.currentGeneration indicates the current state
    enum StateType
    {
        ALL               ,
        DEPLOYED          , // contract has been deployed
        PREMINT           , // only OG and WL minting allowed
        MINT              , // only public minting allowed
        MINTCLOSED        , // no more minting allowed; total mint income stored, random seed for gen 1 requested
        GENERATIONSTARTED , // random seed available, Tans revealed
        GENERATIONCLOSING , // 80-100% Tans swapped
        GENERATIONCLOSED    // 100% Tans swapped, random  seed for next generation requested for gen < 7
    }


    StateType public state = StateType.DEPLOYED;


    string private constant INVALID_STATE        = "Invalid state";
    string private constant INVALID_STATE_CHANGE = "Invalid state change";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;




///  _           _   _         _    _                                         _     
/// | |_ ___ ___| |_|_|___ ___| |  | |_ ___ ___ ___ ___ ___ _____ ___        |_|___ 
/// |  _| .'|  _|  _| |  _| .'| |  |  _| .'|   | . |  _| .'|     |_ -|   _   | | . |
/// |_| |__,|___|_| |_|___|__,|_|  |_| |__,|_|_|_  |_| |__,|_|_|_|___|  |_|  |_|___|
///                                            |___|                                
///
///                                                              tacticaltangrams.io




///  _                   _       
/// |_|_____ ___ ___ ___| |_ ___ 
/// | |     | . | . |  _|  _|_ -|
/// |_|_|_|_|  _|___|_| |_| |___|
///         |_|                  

import "@openzeppelin/contracts/utils/Context.sol";




///              _               _      _____               
///  ___ ___ ___| |_ ___ ___ ___| |_   |_   _|___ ___ _____ 
/// |  _| . |   |  _|  _| .'|  _|  _|    | | | -_| .'|     |
/// |___|___|_|_|_| |_| |__,|___|_|      |_| |___|__,|_|_|_|
                                                        
/// @title Tactical Tangrams Team contract
/// @author tacticaltangrams.io
/// @notice Contains wallet and share details for personal payouts
contract Team is Context {

    uint internal constant TEAM_SIZE = 4;
    uint internal constant TEAM_SHARE_RECORD_SIZE = 3;
    uint internal constant TEAM_SHARE_MINT_OFFSET = 0;
    uint internal constant TEAM_SHARE_SECONDARY_OFFSET = 1;
    uint internal constant TEAM_SHARE_SECONDARY_PAID_OFFSET = 2;




    ///                  _               _           
    ///  ___ ___ ___ ___| |_ ___ _ _ ___| |_ ___ ___ 
    /// |  _| . |   |_ -|  _|  _| | |  _|  _| . |  _|
    /// |___|___|_|_|___|_| |_| |___|___|_| |___|_|  

    /// @notice Deployment constructor
    /// @dev Initializes team addresses. Note that this is only meant for deployment flexibility; the team size and rewards are fixed in the contract
    /// @param _teamAddresses    List of team member's addresses; first address is emergency address
    constructor(address payable[TEAM_SIZE] memory _teamAddresses)
    {
        for (uint teamIndex = 0; teamIndex < teamAddresses.length; teamIndex++)
        {
            teamAddresses[teamIndex] = _teamAddresses[teamIndex];
        }

    }


    /// @notice Returns the team member's index based on wallet address
    /// @param _address Wallet address of team member
    /// @return (bool, index) where bool indicates whether the given address is a team member
    function getTeamIndex(address _address) internal view returns (bool, uint) {
        for (uint index = 0; index < TEAM_SIZE; index++) {
            if (_address == teamAddresses[index]) {
                return (true, index);
            }
        }

        return (false, 0);
    }


    /// @notice Checks whether given address is a team member
    /// @param _address Address to check team membership for
    /// @return True when _address is a team member, False otherwise
    function isTeamMember(address _address) internal view returns (bool) {
        (bool _isTeamMember,) = getTeamIndex(_address);
        return _isTeamMember;
    }


    /// @notice Team member's addresses
    /// @dev Team member information in other arrays can be found at the corresponding index.
    address payable[TEAM_SIZE] internal teamAddresses;

    /// @notice The emergency address is used when things go wrong; no personal payout is possible anymore after emergency payout
    bool internal emergencyCalled = false;

    /// @notice Mint shares are paid out only once per address, after public minting has closed
    bool[TEAM_SIZE] internal mintSharePaid = [ false, false, false, false ];

    /// @notice Mint and secondary sales details per team member
    /// @dev Flattened array: [[<mint promille>, <secondary sales promille>, <secondary sales shares paid>], ..]
    uint[TEAM_SIZE * TEAM_SHARE_RECORD_SIZE] internal teamShare = [
        450, 287, 0,
        300, 287, 0,
        215, 286, 0,
         35, 140, 0
    ];
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;




///  _           _   _         _    _                                         _     
/// | |_ ___ ___| |_|_|___ ___| |  | |_ ___ ___ ___ ___ ___ _____ ___        |_|___ 
/// |  _| .'|  _|  _| |  _| .'| |  |  _| .'|   | . |  _| .'|     |_ -|   _   | | . |
/// |_| |__,|___|_| |_|___|__,|_|  |_| |__,|_|_|_  |_| |__,|_|_|_|___|  |_|  |_|___|
///                                            |___|                                
///
///                                                              tacticaltangrams.io




///  _                   _       
/// |_|_____ ___ ___ ___| |_ ___ 
/// | |     | . | . |  _|  _|_ -|
/// |_|_|_|_|  _|___|_| |_| |___|
///         |_|                  

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";



///              _               _      _____ _____ _____ ___ ___ 
///  ___ ___ ___| |_ ___ ___ ___| |_   |  |  | __  |   __|_  |   |
/// |  _| . |   |  _|  _| .'|  _|  _|  |  |  |    -|   __|  _| | |
/// |___|___|_|_|_| |_| |__,|___|_|     \___/|__|__|__|  |___|___|
                                                              
/// @title Tactical Tangrams VRP20 randomness contract
/// @author tacticaltangrams.io, based on a sample taken from https://docs.chain.link/docs/chainlink-vrf/
/// @notice Requests random seed for each generation
abstract contract VRFD20 is VRFConsumerBase {




    ///                  _               _           
    ///  ___ ___ ___ ___| |_ ___ _ _ ___| |_ ___ ___ 
    /// |  _| . |   |_ -|  _|  _| | |  _|  _| . |  _|
    /// |___|___|_|_|___|_| |_| |___|___|_| |___|_|  

    /// @notice Deployment constructor
    /// @dev Note that these parameter values differ per network, see https://docs.chain.link/docs/vrf-contracts/
    /// @param _vrfCoordinator Chainlink VRF Coordinator address
    /// @param _link           LINK token address
    /// @param _keyHash        Public key against which randomness is created
    /// @param _fee            VRF Chainlink fee in LINK
    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint _fee)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        keyHash = _keyHash;
        fee = _fee;
    }


    /// @notice Request generation seed
    /// @dev Only request when last request is: older than 30 minutes and (seed has not been requested or received) and (previous generation seed has been received)
    /// @param requestForGeneration Generation for which to request seed
    function requestGenerationSeed(uint requestForGeneration) internal
        lastGenerationSeedRequestTimedOut()
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );

        // Do not check whether seed has already been requested; requests can theoretically timeout
        require(
            (generationSeed[requestForGeneration] == 0) ||            // not requested
            (generationSeed[requestForGeneration] == type(uint).max), // not received
            "Seed already requested or received"
        );

        // Verify that previous generation seed has been received, when applicable
        if (requestForGeneration > 1)
        {
            require(
                generationSeed[requestForGeneration-1] != type(uint).max,
                "Previous generation seed not received"
            );
        }

        lastGenerationSeedRequestTimestamp = block.timestamp;

        bytes32 requestId = requestRandomness(keyHash, fee);
        generationSeedRequest[requestId] = requestForGeneration;
        generationSeed[requestForGeneration] = type(uint).max;
    }


    /// @notice Cast uint256 to bytes
    /// @param x Value to cast from
    /// @return b Bytes representation of x
    function toBytes(uint256 x) private pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }


    /// @notice Receive generation seed
    /// @dev Only possible when generation seed has not been received yet
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint generation = generationSeedRequest[requestId];

        require(
            (generation >= 1) && (generation <= 7),
            "Invalid generation"
        );

        if (generation > 1)
        {
            require(
                generationSeed[generation-1] != type(uint).max,
                "Previous generation seed not received"
            );
        }

        require(
            generationSeed[generation] == type(uint).max,
            "Random number not requested or already received"
        );

        generationSeed[generation] = randomness;
        generationHash[generation] = keccak256(toBytes(randomness));

        processGenerationSeedReceived(generation);
    }




    /// @notice Method invoked when randomness for a valid request has been received
    /// @dev Implement this method in inheriting contract. Random number is stored in generationSeed[generation]
    /// @param generation Generation number for which random number has been received
    function processGenerationSeedReceived(uint generation) virtual internal;


    /// @notice Allow re-requesting of generation seeds after GENERATION_SEED_REQUEST_TIMEOUT (30 minutes)
    /// @dev In the very unlikely event that a request is never answered, re-requesting should be allowed
    modifier lastGenerationSeedRequestTimedOut()
    {
        require(
            (lastGenerationSeedRequestTimestamp + GENERATION_SEED_REQUEST_TIMEOUT) < block.timestamp,
            "Not timed out"
        );
        _;
    }


    /// @notice Chainlink fee in LINK for VRF
    /// @dev Set this to 0.1 LINK for Rinkeby, 2 LINK for mainnet
    uint private immutable fee;

    bytes32 private immutable keyHash;

    uint lastGenerationSeedRequestTimestamp = 0;
    uint GENERATION_SEED_REQUEST_TIMEOUT    = 1800; // 30 minutes request timeout

    mapping(bytes32 => uint) public generationSeedRequest;
    mapping(uint    => uint) public generationSeed;
    mapping(uint    => bytes32) public generationHash;
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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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