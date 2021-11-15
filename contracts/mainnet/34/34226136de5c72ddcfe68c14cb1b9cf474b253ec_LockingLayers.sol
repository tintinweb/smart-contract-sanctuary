pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT



import "./ILockingLayers.sol";
import "./VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev LockingLayers is an ERC721 contract that contains the logic and source of ownership
 * for Whole Picture. The core mechanics breakdown as follows:
 *   - Each artwork consists of 4 layers. 
 *   - A Layer contain a canvasId.
 *   - Each layer shifts its canvasId after X blocks, unless the layer is locked.
 *   - Layers are revealed over time, and the entire process ends after all layers are revelaed and
 *     all layer shifts have finished.
 *   
 * Schema is:
 *   - artworkId => owned by address
 *     - canvasIds[NUM_LAYERS] => owned by artwork => NUM_LAYERS = 4 so each artwork ownes 4 canvasIds
 *
 * Layer Mappings:
 *   - Mappings from canvasId => canvas are stored offchain in IPFS. Mapping json file can be viewed
 *   - at ipfs://QmZ7Lpf5T4NhawAKsWAmomG5sxkSN6USfRVRW5nMzjrHdD
 * 
 * IMPORTANT NOTES:
 *  - canvasIds and actionIds are 1 indexed, not 0 indexed. This is because a 0 index signifies that
 *  a layer is not locked, and an actionId of 0 signifies that the action has not happened yet.
 */
contract LockingLayers is ILockingLayers, ERC721, VRFConsumerBase, Ownable {
    using SafeMath for uint256;


    // Total number of artworks to create
    uint16 constant TOTAL_ARTWORK_SUPPLY = 1200;


    // The layerIds owned by each artwork
    uint8 constant NUM_LAYERS = 4;


    // Actions are shifts per each layer
    // NOTE: all actions are 1 indexed, not 0 indexed. This is because an action idx of
    // 0 means that layer does nto exist yet
    uint8 constant ACTIONS_PER_LAYER = 5;


    // Defines number blocks required to trigger an action
    uint16 constant BLOCKS_PER_ACTION = 4444;


    // Total number of actions for the project
    uint16 constant MAX_ACTIONS = ACTIONS_PER_LAYER * NUM_LAYERS;


    // There will be the same number of layerIds because each artwork is guaranteed to have 4 layers
    uint16 constant NUM_CANVAS_IDS = TOTAL_ARTWORK_SUPPLY;


    // Number of artworks in each tier
    uint16[3] totalArtworksInTier = [200, 800, 200];


    // remaining artworks in each tier that can be purchased
    uint16[3] artworksRemainingInTier = [200, 800, 200];


    // CID of the mappings from canvasId to canvas! View on ipfs.
    string constant provinanceRecord = "QmZ7Lpf5T4NhawAKsWAmomG5sxkSN6USfRVRW5nMzjrHdD";


    // First artwork will be id of 0
    uint16 nextArtworkId = 0;


    // Records the official 
    uint256 private _startBlock = 0;

   
    // True once artwork has begun (once VRF has been received)
    bool private isArtworkStarted = false; 


    // Block that stores first time of first purchase
    uint256 public firstPurchaseBlock = 0;


    // If not all artworks are sold, will trigger start this many blocks after first artwork purchased
    uint256 public constant AUTOMATIC_START_BLOCK_DELAY = 184000;


    // Mapping to the artwork tier for each token
    // artworkId => tier
    mapping(uint256 => ArtworkTier) public artworkTier;

    
    // The constant number of locks for each purchase tier.
    uint8[4] locksPerTier = [1, 2, 4];


    // Remaining locks per artwork -- each lock will decrement value
    // artworkId => _locksRemaining
    mapping(uint256 => uint8) _locksRemaining;


    // A record of locked layers for each token:
    // artworkId => lockedCanvasId[NUM_LAYERS]
    // NOTE: a value of 0 signifies that a layer is NOT locked
    //   - Example: 
    //     - lockedLayersForToken[100][1] = 10
    //       - can be read as artworkId 100 has layer 1 (0 indexed) locked with canvasId 10.
    //     - lockedLayerForToken[100][0] = 0
    //       - can be read as artworkId 100's layer 0 is NOT locked
    mapping(uint256 => uint16[NUM_LAYERS]) lockedLayersForToken;


    // A record of if an artwork is locked and at which action it was locked.
    // canvasId => actionId[NUM_LAYERS] -> ~7 actions per layer so uint8 is good for actionId
    // canvasIds are reused for each layer to save on storage costs.
    //   - Example:
    //     - lockedLayerHistory[10][1] = 2
    //       - can be read as canvasId 10 for second layer (0 indexed) was locked on action 2
    //     - lockedLayerHistory[10][2] = 0
    //       - can be read as canvasId 10 has NOT BEEN LOCKED for third layer
    mapping(uint16 => uint8[NUM_LAYERS]) lockedLayerHistory;


    // Offsets for layerIds for each layer, used when finding base id for next layer
    // The [0] index is set by Chainlink VRF (https://docs.chain.link/docs/chainlink-vrf-api-reference)
    // Later indexes are only influenced by participants locking layers, so the artwork is
    // more connected with the behaviour of the participants.
    // INVARIANT: Can only change for future UNLOCKED layer, can never be altered for 
    // past layers. Needs to be deterministic for past/current layers. 
    //   - Example:
    //     - layerIdStartOffset[1] = 19413
    //     - can be read as the starting canvasId will be offset by 19413
    uint256[NUM_LAYERS] public canvasIdStartOffsets;

    // CHAINLINK VRF properties -- want to keep locally to test gas spend
    bytes32 constant keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 constant vrfFee = 2000000000000000000;

    // Store the current URI -- URI may change if domain is updated
    string baseURI = "https://su3p5zea28.execute-api.us-west-1.amazonaws.com/prod/metadata/";

    constructor() 
        ERC721("Whole Picture", "WP") 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        )    
    public {

    }

    /** 
      * @dev Metadata base uri    
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

   

    /**
     * @dev Returns the currnet price in wei for an artwork in a given tier.
     * Pricing is a bonding curve, using 4 quadratic easing sections:
     *   - Enthusiast tier is an ease out curve
     *   - Collector tier is ease in segment until midway point, then ease out
     *   - Strata tier is ease in.
     */
    function currentPrice(ArtworkTier tier) public override view returns (uint256) {
        if(artworksRemainingInTier[uint256(tier)] == 0) {
            return 0;
        }

        uint256 min;
        uint256 max;
        uint256 numerator;
        uint256 denominator;
        
        if(tier == ArtworkTier.ENTHUSIAST) {
            min = 1 * 1 ether / 10;
            max = 5 * 1 ether / 10;
            numerator = totalArtworksInTier[0] - artworksRemainingInTier[0];
            denominator = totalArtworksInTier[0];

        }
        else if(tier == ArtworkTier.COLLECTOR) {
            uint256 collectorMin =  5 * 1 ether / 10;
            uint256 collectorMax = 25 * 1 ether / 10;
            uint256 midwayPrice = collectorMin + (collectorMax - collectorMin) / 2;
            uint256 midwayArtworks = totalArtworksInTier[1] / 2;
            if(artworksRemainingInTier[1] > midwayArtworks){
                // invert so switch min and max
                min = midwayPrice;
                max = collectorMin;
                numerator = midwayArtworks - (totalArtworksInTier[1] - artworksRemainingInTier[1]);
                denominator = midwayArtworks;
            } else {
                min = midwayPrice;
                max = collectorMax;
                numerator = midwayArtworks - artworksRemainingInTier[1];
                denominator = midwayArtworks;
            }
        }
        else {
            // Strata tier so return STRATA_TIER price
            // inverted so switch max and min
            max = 25 * 1 ether / 10;
            min = 4 * 1 ether / 1;
            numerator = artworksRemainingInTier[2] - 1; // inverted so use remaining for numerator
            denominator = totalArtworksInTier[2] - 1; // minus one so ends on 4
        }
        
        return easeInQuad(min, max, numerator, denominator);
    }


    /**
     * @dev Get the price and available artworks for a given tier
     *   - Returns:
     *      - uint256 => PRICE in wei
     *      - uint256 => available artworks
     */
    function getTierPurchaseData(ArtworkTier tier) public override view returns (uint256, uint16) {
        return (currentPrice(tier), artworksRemainingInTier[uint256(tier)]);
    }


    /**
     * @dev Returns the number of artworks issued.
     */
    function totalArtworks() public override pure returns (uint16) {
        return TOTAL_ARTWORK_SUPPLY;
    }


    /**
     * @dev Returns the total artworks remaining across all tiers.
     */
    function availableArtworks() public override view returns (uint16) {
        return artworksRemainingInTier[0] + artworksRemainingInTier[1] + artworksRemainingInTier[2];
    }


    /**
     * @dev The number of blocks remaining until next layer is revealed.
     */
    function blocksUntilNextLayerRevealed() public override view returns (uint256) {
        if(!hasStarted()) {
            return 0;
        }
        return ((getAction()) * BLOCKS_PER_ACTION + startBlock()) - block.number;
    }


    /**
     * @dev Checks if an artwork can lock the current layer.
     *   - if no locks remaining or if layer is already locked, cannot lock
     */
    function canLock(uint256 artworkId) public override view returns (bool) {
        // check locks
        return (_locksRemaining[artworkId] > 0);
    }


    /**
     * @dev Checks if an artwork can lock the current layer.
     *   - if no locks remaining or if layer is already locked, cannot lock
     */
    function locksRemaining(uint256 artworkId) public view returns (uint8) {
        // check locks
        return _locksRemaining[artworkId];
    }


    /**
     * @dev Get canvasIds for each layer for artwork.
     */
    function getCanvasIds(uint256 artworkId) public override view returns (uint16, uint16, uint16, uint16) {
        // ensure no ids sent if hasn't started or artwork doesn't exist
        if(!hasStarted() || !_exists(artworkId)) {
            return (0, 0, 0, 0);
        }

        (uint8 currentLayer, uint8 currentAction) = getCurrentLayerAndAction();

        // initialize array, all values start at 0
        uint16[NUM_LAYERS] memory canvasIds;

        // now need to loop through all layers
        for(uint8 i = 0; i <= currentLayer; i++) {
            uint8 layerAction;

            // check if we are on the current (topmost) layer, in which case we use the current action
            if(i == currentLayer) {
                layerAction = currentAction;
            } else {
                // otherwise we use the final action for previous layer
                layerAction = ACTIONS_PER_LAYER;
            }

            // now get the canvasId for action for target layer
            canvasIds[i] = getCanvasIdForAction(artworkId, i, layerAction);
        }
        return (canvasIds[0], canvasIds[1], canvasIds[2], canvasIds[3]);
    }


    /**
     * @dev Returns the startBlock for the artwork.
     * There are two conditions for the artwork to start -- either all artworks are sold,
     * or the automatic trigger started after the first artwork has sold has been reached.
     */
    function startBlock() public view returns (uint256) {    
        return _startBlock;      
    }


    /**
     * @dev Check whether the artwork has started.
     */
    function hasStarted() public view returns (bool) {
        return startBlock() != 0;
    }


    /**
     * @dev Gets the overall action since the start of the process.
     * NOTE: Actions are 1 indexed! 0 means no actions because has not begun.
     */
    function getAction() public view returns (uint8) {
        if(!hasStarted()) {
            return 0;
        }

        uint256 elapsedBlocks = block.number.sub(startBlock());
        // actions are 1 indexed so need to add 1
        uint256 actionsElapsed = elapsedBlocks.div(BLOCKS_PER_ACTION) + 1;
        uint256 clampedActions = Math.min(actionsElapsed, MAX_ACTIONS);
        // console.log("ElapsedBlocks: %s", elapsedBlocks);
        return uint8(clampedActions);
    }


    /**
     * @dev Returns the current layer as well as the current action.
     *   - Returns:
     *     - (layer, actionInLayer)
     *   - If action == 0, then layer is not revealed
     */
    function getCurrentLayerAndAction() public view returns (uint8, uint8) {
        
        uint8 totalActions = getAction();
        
        // ensure we return 
        if(totalActions == 0) {
            return (0, 0);
        }

        // need to subtract 1 because actions start at 1
        uint8 actionZeroIndexed = totalActions - 1;

        uint8 currentLayer = (actionZeroIndexed) / ACTIONS_PER_LAYER;
         
        uint8 currentActionZeroIndexed = actionZeroIndexed - (currentLayer * ACTIONS_PER_LAYER);
        
        // re-add 1 to restore 1 index
        uint8 currentAction = currentActionZeroIndexed + 1;

        return (currentLayer, currentAction);
    }

    /**
     * @dev Purchases an artwork.
     *   - Returns the artworkID of purchased work.
     *   - Reverts if insuffiscient funds or no artworks left.
     */
    function purchase(ArtworkTier tier) public override payable returns (uint256) {
        require(artworksRemainingInTier[uint256(tier)] > 0, "No artworks remaining in tier!");

        // Validate payment amount
        uint256 weiRequired = currentPrice(tier);
        require(msg.value >= weiRequired, "Not enough payment sent!");
        
        uint256 newArtworkId = nextArtworkId;

        // check if first sale, and if so set first sale block
        if(newArtworkId == 0) {
            firstPurchaseBlock = block.number;
        }

        // mint new artwork!
        _safeMint(_msgSender(), newArtworkId);

        // record tier and the number of locks
        artworkTier[newArtworkId] = tier;
        _locksRemaining[newArtworkId] = locksPerTier[uint256(tier)];

        // decrement artworks available in tier
        artworksRemainingInTier[uint256(tier)] -= 1;

        // incriment artwork to the next artworkId
        nextArtworkId++;

        // check if all artworks sold, then trigger startBlock if not already started
        if(nextArtworkId == TOTAL_ARTWORK_SUPPLY) {
            if(!hasStarted()) {

                requestStartArtwork();
            } 
        }



        emit ArtworkPurchased(newArtworkId, uint8(tier));

        return newArtworkId;
    }

    /**
     * @dev Request to start the artwork!
     *   - Acheived by requesting a random number from Chainlink VRF.
     *   - Will automatically be requested after the last sale -- or can be requested
     *     manually once sale period has ended.
     * Requirements:
     *   Can only occur after:
     *     - All works have been sold
     *     - Sale period ended (X blocks past the block of the first purchase)
     *     - Has not already been started
     *     - Enough LINK on contract
     */
    function requestStartArtwork() public returns (bytes32) {
        require(!hasStarted(), "Artwork has already been started!");
        
        // Require all artworks sold or after sale period has ended
        require(
            availableArtworks() == 0 || 
            firstPurchaseBlock > 0 && block.number > firstPurchaseBlock + AUTOMATIC_START_BLOCK_DELAY,
            "Cannot start the artwork before all works are sold out or until after sale period"
        );




        // Request randomness from VRF
        return requestRandomness(keyHash, vrfFee, block.number);

    }


    /** 
     * @dev Respond to Chainlink VRF
     *   - This will start artwork if not already started
     */
    function fulfillRandomness(bytes32 /*requestId*/, uint256 randomness) internal override {
        startArtwork(randomness);
    }


    /**
     * @dev Start the artwork! This sets the start seed and start block.
     *   - Can only be called once
     */
    function startArtwork(uint256 randomSeed) internal {
        // Ensure start block not already set (in case random number requested twice before being fulfilled)
        require(!hasStarted(), "Artwork has already started, seed cannot be set twice!");



        // Set start block and the start seed, which kicks off the artwork experience!!!!!
        _startBlock = block.number;

        // The first canvas start is the random Seed!
        canvasIdStartOffsets[0] = randomSeed % TOTAL_ARTWORK_SUPPLY;
    }


    /**
     * @dev Lock artwork layer.
     *   - Reverts if cannot lock.
     *   - Emits LayerLocked event
     */
    function lockLayer(uint256 artworkId) public override {

        require(hasStarted(), "Art event has not begun!");

        require(_exists(artworkId), "Artwork does not exist!");

        // require locking party to be owner
        require(_msgSender() == ownerOf(artworkId), "Must be artwork owner!");

        // require locks remaining
        require(canLock(artworkId), "No locks remaining!");

        // first determine active layer and current action
        (uint8 currentLayer, uint8 currentAction) = getCurrentLayerAndAction();
        
        // Ensure we are not on action 0, which means cannot lock
        require(currentAction > 0, "Canvas is not yet revealed!");

        // recreate history to determine current canvas
        uint16 currentCanvasId = getCanvasIdForAction(artworkId, currentLayer, currentAction);
        
        // ensure not already locked so user does not waste lock
        uint8 currLockedValue = lockedLayerHistory[currentCanvasId][currentLayer];
        require(currLockedValue == 0, "Layer must not be already locked!");
        require(currentCanvasId > 0, "Invalid canvas id of 0!"); // is this needed???

        // update locked layer by idx mapping
        lockedLayersForToken[artworkId][currentLayer] = currentCanvasId;

        // update canvasId locked layer mapping
        lockedLayerHistory[currentCanvasId][currentLayer] = currentAction;

        // Update start canvasId offset for next layer
        if(currentLayer < NUM_LAYERS - 1) {

            canvasIdStartOffsets[currentLayer + 1] = (block.number + canvasIdStartOffsets[currentLayer]) % TOTAL_ARTWORK_SUPPLY;
        }



        _locksRemaining[artworkId] -= 1;
        emit LayerLocked(artworkId, currentLayer, currentCanvasId);
    }


    /**
     * @dev Valid canvasIds are always 1 indexed! An index of 0 means canvas is not yet revealed.
     */
    function incrimentCanvasId(uint16 canvasId) internal pure returns (uint16) {
        return (canvasId % NUM_CANVAS_IDS) + 1;
    }


    /**
     * @dev Gets the corresponding canvasId for an artwork and layer at a given action.
     *   This function calculates the current canvas by starting at first canvas of the current
     *   layer and recreating past actions, which leads to the current valid layer.
     *     - Each artworkID should ALWAYS return a unique canvas ID for the same action state.
     *     - CanvasIds are 1 indexed, so a revealed canvas should NEVER return 0!
     */
    function getCanvasIdForAction(uint256 artworkId, uint8 layer, uint8 action) internal view returns (uint16) {        

        // If we are on 0 action, layer is not revealed no valid canvasId
        if(action == 0) {
            return 0;
        }

        // If artwork does not exist, return 0
        if(!_exists(artworkId)) {
            return 0;
        }

        // If canvas is locked, return the locked canvasId
        uint16 lockedCanvasId = lockedLayersForToken[artworkId][layer];
        if(lockedCanvasId != 0) {

            return lockedCanvasId;
        }

        // first canvasId is 1 INDEXED => the offset + the artwork id + 1
        uint16 currCanvasId = uint16(((canvasIdStartOffsets[layer] + artworkId) % (NUM_CANVAS_IDS)) + 1);

        // We begin at action 1, and then find corresponding canvasId. Then we incriment for each
        // action while also checking if canvasId has been locked in the past. This will be expensive
        // when many layers are locked.

        
        // this will start on second action, and then work way up to latest final action
        for(uint8 i = 1; i < action; i++) {

            // incriment the currentCanvasId
            currCanvasId = incrimentCanvasId(currCanvasId);

            // check if this canvas was locked on a previous action
            uint8 canvasLockedOnAction = lockedLayerHistory[currCanvasId][layer];
            
            // TODO: Prevent infinite loop just in case??

            // while canvasId was locked on a previous action, incriment the current canvasId
            while( canvasLockedOnAction != 0 && canvasLockedOnAction <= i) {

                // advance canvas step
                currCanvasId = incrimentCanvasId(currCanvasId);
                canvasLockedOnAction = lockedLayerHistory[currCanvasId][layer];
            }
        }

        return currCanvasId;
    }

    
    /**
     * @dev Ease in quadratic lerp function -- x * x, invert for ease out
     */
    function easeInQuad(uint256 min, uint256 max, uint256 numerator, uint256 denominator) 
        internal pure returns (uint256) 
    {
        if(min <= max) {
            // min + (max - min) * x^2
            return (max.sub(min)).mul(numerator).mul(numerator).div(denominator).div(denominator).add(min);
        }
        // inverted -> max - (max - min) * x^2
        return min.sub((min.sub(max)).mul(numerator).mul(numerator).div(denominator).div(denominator));
    }


    /**
     * @dev Updates the URI in case of domain change or switch to IPFS in the future;
     */
    function setBaseURI(string calldata newURI) public onlyOwner {
        baseURI = newURI;
    }
    

    /**
     * @dev Withdrawl funds to owner
     *   - This saves gas vs if each payment was sent to owner
     */
    function withdrawlFunds() public {
        (bool success, ) = address(0x1Df3260ea86d338404aC49F3D33cec477a46A827).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT




/**
 * @dev Interface for locking layer artwork project. Implemented interface will allow for functional website.
 */
interface ILockingLayers {

    /** Artwork tier, used for pricing, # layers locked, and gallery benefits */
    enum ArtworkTier {
        ENTHUSIAST,
        COLLECTOR,
        STRATA
    }

    /**
     * @dev Emitted when layer successfully locked.
     */
    event LayerLocked(uint256 artworkId, uint8 layer, uint256 canvasId);

    /**
     * @dev Emit on purchase to know which artwork tier and original owner
     */
    event ArtworkPurchased(uint256 artworkId, uint8 tier);

    /**
     * @dev Returns the current price to buy an artwork in wei.
     */
    function currentPrice(ArtworkTier tier) external view returns (uint256);

    /**
     * @dev Returns the number of artworks issued.
     */
    function totalArtworks() external view returns (uint16);

    /**
     * @dev Returns the total artworks remaining across all tiers.
     */
    function availableArtworks() external view returns (uint16);

    /**
     * @dev Get the price and available artworks for a given tier
     *   - Returns:
     *      - uint256 => PRICE in wei
     *      - uint256 => available artworks
     */
    function getTierPurchaseData(ArtworkTier tier) external view returns (uint256, uint16); 

    /**
     * @dev Get canvasIds for each layer for artwork.
     */
    function getCanvasIds(uint256 artworkId) external view returns (uint16, uint16, uint16, uint16);

    /**
     * @dev The number of blocks remaining until next layer is revealed.
     */
    function blocksUntilNextLayerRevealed() external view returns (uint256);

    /**
     * @dev Checks if an artwork can lock the current layer.
     */
    function canLock(uint256 artworkId) external view returns (bool);

    /**
     * @dev Purchases an artwork.
     *   - Returns the artworkID of purchased work.
     *   - Reverts if insuffiscient funds or no artworks left.
     */
    function purchase(ArtworkTier tier) external payable returns (uint256);

    /**
     * @dev Lock artwork layer.
     *   - Reverts if cannot lock.
     */
    function lockLayer(uint256 artworkId) external; 



}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
/* EDITED FOR COMPATABILITY WITH 0.8.0 COMPILER */
/* Edited on 22/04/2021 by Jasper Degens */



// Trimmed down interface for just VRF functions
import "./LinkTokenInterfaceSimplified.sol";

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
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

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
   * @param _seed seed mixed into the input of the VRF.
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterfaceSimplified immutable internal LINK;
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
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterfaceSimplified(_link);
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "./extensions/IERC721Enumerable.sol";
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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


interface LinkTokenInterfaceSimplified {
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


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
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
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
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

