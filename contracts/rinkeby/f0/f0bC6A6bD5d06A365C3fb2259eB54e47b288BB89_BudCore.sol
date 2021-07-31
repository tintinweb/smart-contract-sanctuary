pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGeneScience.sol";

contract BudBase is Ownable {


    /* ========== ENUM ========== */

    /**
     * @dev Bud can be in one of the two state:
     *
     * SEED -       When 2 Buds Breed a new baby SEED is born 
     *
     * GROWN -      When the seed is GROWN a Bud is born! `gene`, `thc`, and `cbd` are determined
     *               in this state.
     *
     */
    enum BudGrowthState {SEED, GROWN}

    /* ========== PUBLIC STATE VARIABLES ========== */

    /**
     * @dev payment required to use growing if it's done automatically
     * assigning to 0 indicate growing action is not automatic paid in FTM
     */
    uint256 public autoGrowingFee = 0;

    /**
     * @dev Base breeding REWARD fee
     */
    uint256 public baseBreedingFee = 10e18; // 10 REWARD TOKENS

    /**
     * @dev REWARD ERC20 contract address
     */
    IERC20 public reward;

    /**
     * @dev 10% of the breeding REWARD fee goes to the dev team
     */
    address public devAddress;

    /**
     * @dev 10% of the breeding REWARD fee goes to artist 
     */
    address public artistAddress;

    /**
     * @dev 80% of the breeding REWARD fee goes to `stakingAddress`
     */
    address public stakingAddress;

    /**
     * @dev number of percentage breeding REWARD fund goes to devAddress
     * dev percentage = devBreedingPercentage / 100
     * staking percentage = (100 - devBreedingPercentage) / 100
     */
    uint256 public devBreedingPercentage = 10;

     /**
     * @dev number of percentage breeding REWARD fund goes to devAddress
     * dev percentage = devBreedingPercentage / 100
     * staking percentage = (100 - devBreedingPercentage) / 100
     */
    uint256 public artistBreedingPercentage = 10;

    /**
     * @dev An approximation of currently how many seconds are in between blocks.
     */
    uint256 public secondsPerBlock = 1;

    /**
     * @dev amount of time a new born Bud needs to wait before participating in breeding activity.
     *
     *          CURRENTLY ON 1 HOUR FOR TESTING
     *
     */
    uint256 public newBornBreedingCoolDown = uint256(1 hours);
    
    /**
     * @dev amount of time an seed needs to wait to be grown
     */
    uint256 public seedingDuration = uint256(5 minutes);


    /**
     * @dev when two Bud just bred, the breeding multiplier will doubled to control
     * Bud's population. This is the amount of time each parent must wait for the
     * breeding multiplier to reset back to 1
     *
     *          CURRENTLY ON 1 HOUR FOR TESTING
     *
     */
    uint256 public breedingMultiplierCoolDown = uint256(2 hours);

    /**
     * @dev hard cap on the maximum hatching cost multiplier it can reach to
     */
    uint16 public maxBreedCostMultiplier = 16;

    /**
     * @dev Gen0 generation factor
     */
    uint64 public constant GEN0_GENERATION_FACTOR = 10;

    /**
     * @dev maximum gen-0 Bud thc. This is to prevent contract owner from
     * creating arbitrary thc for gen-0 Bud
     */
    uint32 public constant MAX_GEN0_THC = 40;

     /**
     * @dev maximum gen-0 Bud cbd. This is to prevent contract owner from
     * creating arbitrary cbd for gen-0 Bud
     */
    uint32 public constant MAX_GEN0_CBD = 60;
    
    /**
     * @dev hatching fee increase with higher REWARD generation
     */
    uint256 public generationBreedingFeeMultiplier = 2;

    /**
     * @dev gene science contract address for genetic combination algorithm.
     */
    IGeneScience public geneScience;

    /* ========== INTERNAL STATE VARIABLES ========== */

    /**
     * @dev An array containing the Bud struct for all Buds in existence. The ID
     * of each Bud is the index into this array.
     */
    Bud[] internal buds;

    /**
     * @dev mapping from BudIDs to an address where Bud owner approved address to use
     * this bud for breeding. addrss can breed with this bud multiple times without limit.
     * This will be resetted everytime someone transfered the Bud.
     */
    EnumerableMap.UintToAddressMap internal budAllowedToAddress;

    /* ========== Bud STRUCT ========== */

    /**
     * @dev Everything about your Bud is stored in here. Each Bud's appearance
     * is determined by the gene. The thc associated with each Bud is also
     * related to the gene
     */
    struct Bud {
        // TheaBud genetic code.
        uint256 gene;
        // the Bud thc level
        uint32 thc;
        // the Bud cbd level
        uint32 cbd;
        // The timestamp from the block when this Bud came into existence.
        uint64 birthTime;
        // The minimum timestamp Bud needs to wait to avoid hatching multiplier
        uint64 breedingCostMultiplierEndBlock;
        // hatching cost multiplier
        uint16 breedingCostMultiplier;
        // The ID of the parents of this Bud, set to 0 for gen0 Bud.
        uint32 matronId;

        uint32 sireId;
        // The "generation number" of this Bud. The generation number of an Buds
        // is the smaller of the two generation numbers of their parents, plus one.
        uint16 generation;
        // The minimum timestamp new born Bud needs to wait to breed seed.
        uint64 newBornBreedingCooldownEndBlock;
        // The generation factor buffs Bud thc level
        uint64 generationFactor;
        // defines current Bud state
        BudGrowthState state;
    }

    


    /* ========== VIEW ========== */

    function getTotalBud() external view returns (uint256) {
        return buds.length;
    }


    /* ========== OWNER MUTATIVE FUNCTION ========== */

    /**
     * @param _seedingDuration seeding duration
     */
    function setSeedingDuration(uint256 _seedingDuration) external onlyOwner {
        seedingDuration = _seedingDuration;
    }


    /**
     * @param _stakingAddress staking address
     */
    function setStakingAddress(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }

    /**
     * @param _devAddress dev address
     */
    function setDevAddress(address _devAddress) external onlyDev {
        devAddress = _devAddress;
    }

    /**
     * @param _artistAddress artist address
     */
    function setArtistAddress(address _artistAddress) external onlyDev {
        artistAddress = _artistAddress;
    }

    /**
     * @param _maxBreedCostMultiplier max hatch cost multiplier
     */
    function setMaxBreedCostMultiplier(uint16 _maxBreedCostMultiplier)
        external
        onlyOwner
    {
        maxBreedCostMultiplier = _maxBreedCostMultiplier;
    }

    /**
     * @param _devBreedingPercentage base generation factor
     */
    function setDevBreedingPercentage(uint256 _devBreedingPercentage)
        external
        onlyOwner
    {
        require(
            devBreedingPercentage <= 100,
            "CryptoBuds: invalid breeding percentage - must be between 0 and 100"
        );
        devBreedingPercentage = _devBreedingPercentage;
    }

    /**
     * @param _generationBreedingFeeMultiplier multiplier
     */
    function setGenerationBreedingFeeMultiplier(
        uint256 _generationBreedingFeeMultiplier
    ) external onlyOwner {
        generationBreedingFeeMultiplier = _generationBreedingFeeMultiplier;
    }

    /**
     * @param _baseBreedingFee base birthing
     */
    function setBaseBreedingFee(uint256 _baseBreedingFee) external onlyOwner {
        baseBreedingFee = _baseBreedingFee;
    }

    /**
     * @param _newBornBreedingCoolDown new born cool down
     */
    function setNewBornBreedingCoolDown(uint256 _newBornBreedingCoolDown) external onlyOwner {
        newBornBreedingCoolDown = _newBornBreedingCoolDown;
    }

    /**
     * @param _breedingMultiplierCoolDown base birthing
     */
    function setBreedingMultiplierCoolDown(uint256 _breedingMultiplierCoolDown)
        external
        onlyOwner
    {
        breedingMultiplierCoolDown = _breedingMultiplierCoolDown;
    }

    /**
     * @dev update how many seconds per blocks are currently observed.
     * @param _secs number of seconds
     */
    function setSecondsPerBlock(uint256 _secs) external onlyOwner {
        secondsPerBlock = _secs;
    }

    /**
     * @dev only owner can update autoCrackingFee
     */
    function setAutoGrowFee(uint256 _autoGrowingFee) external onlyOwner {
        autoGrowingFee = _autoGrowingFee;
    }

    /**
     * @dev owner can upgrading gene science
     */
    function setGeneScience(IGeneScience _geneScience) external onlyOwner {
        require(
            _geneScience.isGeneScience(),
            "CryptoBuds: invalid gene science contract"
        );

        // Set the new contract address
        geneScience = _geneScience;
    }

    /**
     * @dev owner can update ALPA erc20 token location
     */
    function setRewardContract(IERC20 _reward) external onlyOwner {
        reward = _reward;
    }

    /* ========== MODIFIER ========== */

    /**
     * @dev Throws if called by any account other than the dev.
     */
    modifier onlyDev() {
        require(
            devAddress == _msgSender(),
            "CryptoBuds: caller is not the dev"
        );
        _;
    }
}

pragma solidity >=0.7.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./BudToken.sol";
import "../interfaces/ICryptoBud.sol";

contract BudBreed is BudToken, ICryptoBud, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    /* ========== EVENTS ========== */

    // The Hatched event is fired when two bud successfully hached an seed.
    event BreedingComplete(
        uint256 indexed seedId,
        uint256 matronId,
        uint256 sireId,
        uint256 seedingcooldownEndBlock
    );

    // The GrantedToBreed event is fired whne an bud's owner granted
    // addr account to use BudId as sire to breed.
    event GrantedToBreed(uint256 indexed budId, address addr);

    /* ========== VIEWS ========== */

    /**
     * Returns all the relevant information about a specific bud.
     * @param _id The ID of the bud of interest.
     */
    function getBud(uint256 _id)
        external
        override
        view
        returns (
            uint256 id,
            uint256 seedingcooldownEndBlock,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 breedingCostMultiplier,
            uint256 breedingCostMultiplierEndBlock,
            uint256 generation,
            uint256 gene,
            uint256 thc,
            uint256 cbd,
            uint256 state
        )
    {
        Bud storage bud = buds[_id];
        id = _id;
        seedingcooldownEndBlock = bud.newBornBreedingCooldownEndBlock;
        birthTime = bud.birthTime;
        matronId = bud.matronId;
        sireId = bud.sireId;
        breedingCostMultiplier = bud.breedingCostMultiplier;
        if (bud.breedingCostMultiplierEndBlock <= block.number) {
            breedingCostMultiplier = 1;
        }
        breedingCostMultiplierEndBlock = bud.breedingCostMultiplierEndBlock;
        generation = bud.generation;
        gene = bud.gene;
        thc = bud.thc;
        cbd = bud.cbd;
        state = uint256(bud.state);
    }


    function _getBaseBreedingCost(uint256 _generation)
        internal
        view
        returns (uint256)
    {
        return
            baseBreedingFee.add(
                _generation.mul(generationBreedingFeeMultiplier).mul(1e18)
            );
    }

    /**
     * @dev Calculating breeding REWARD cost
     */
    function breedingRewardCost(uint256 _matronId, uint256 _sireId)
        external
        view
        returns (uint256)
    {
        return _breedingRewardCost(_matronId, _sireId, false);
    }


    /**
     * @dev Checks to see if a given seed passed seedingcooldownEndBlock and ready to grow
     * @param _id bud seed ID
     */

    function isReadyToGrow(uint256 _id) external view returns (bool) {
        Bud storage bud = buds[_id];
        return
            (bud.state == BudGrowthState.SEED) &&
            (bud.newBornBreedingCooldownEndBlock <= uint64(block.number));
    }

    /* ========== EXTERNAL MUTATIVE FUNCTIONS  ========== */

    /**
     * Grants permission to another account to sire with one of your buds.
     * @param _addr The address that will be able to use sire for breeding.
     * @param _sireId a bud _addr will be able to use for breeding as sire.
     */
    function grandPermissionToBreed(address _addr, uint256 _sireId)
        external
        override
    {
        require(
            isOwnerOf(msg.sender, _sireId),
            "CryptoBuds: You do not own sire bud"
        );

        budAllowedToAddress.set(_sireId, _addr);
        emit GrantedToBreed(_sireId, _addr);
    }

    /**
     * check if `_addr` has permission to user bud `_id` to breed with as sire.
     */
    function hasPermissionToBreedAsSire(address _addr, uint256 _id)
        external
        override
        view
        returns (bool)
    {
        if (isOwnerOf(_addr, _id)) {
            return true;
        }

        return budAllowedToAddress.get(_id) == _addr;
    }

    /**
     * Clear the permission on bud for another user to use to breed.
     * @param _budId a bud to clear permission .
     */
    function clearPermissionToBreed(uint256 _budId) external override {
        require(
            isOwnerOf(msg.sender, _budId),
            "CryptoBuds: You do not own this bud"
        );

        budAllowedToAddress.remove(_budId);
    }

    /**
     * @dev Breed an baby bud seed with two bud you own (_matronId and _sireId).
     * Requires a pre-payment of the fee given out to the first caller of crack()
     * @param _matronId The ID of the bud acting as matron
     * @param _sireId The ID of the bud acting as sire
     * @return The hatched bud seed ID
     */
    function breed(uint256 _matronId, uint256 _sireId)
        external
        override
        payable
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        address msgSender = msg.sender;

        // Checks for autogrow payment.
        require(
            msg.value >= autoGrowingFee,
            "CryptoBuds: Required autoGrowingFee not sent"
        );

        // Checks for JUICY payment
        require(
            reward.allowance(msgSender, address(this)) >=
                _breedingRewardCost(_matronId, _sireId, true),
            "CryptoBuds: Required hetching JUICY fee not sent"
        );

        // Checks if matron and sire are valid mating pair
        require(
            _ownerPermittedToBreed(msgSender, _matronId, _sireId),
            "CryptoBuds: Invalid permission"
        );

        // Grab a reference to the potential matron
        Bud storage matron = buds[_matronId];

        // Make sure matron isn't pregnant, or in the middle of a siring cooldown
        require(
            _isReadyToBreed(matron),
            "CryptoBuds: Matron is not yet ready to Breed"
        );

        // Grab a reference to the potential sire
        Bud storage sire = buds[_sireId];

        // Make sure sire isn't pregnant, or in the middle of a siring cooldown
        require(
            _isReadyToBreed(sire),
            "CryptoBuds: Sire is not yet ready to Breed"
        );

        // Test that matron and sire are a valid mating pair.
        require(
            _isValidMatingPair(matron, _matronId, sire, _sireId),
            "CryptoBuds: Matron and Sire are not valid mating pair"
        );

        // All checks passed, Bud gets pregnant!
        return _breedSeed(_matronId, _sireId);
    }

    /**
     * @dev seed is ready to crack and give life to baby bud!
     * @param _id A Bud seed that's ready to crack.
     */
    function grow(uint256 _id) external override nonReentrant {
        // Grab a reference to the seed in storage.
        Bud storage seed = buds[_id];

        // Check that the seed is a valid bud.
        require(seed.birthTime != 0, "CryptoBuds: not valid seed");
        require(
            seed.state == BudGrowthState.SEED,
            "CryptoBuds: not a valid seed"
        );

        // Check that the matron is pregnant, and that its time has come!
        require(_isReadyToGrow(seed), "CryptoBuds: seed cant be grown yet");

        // Grab a reference to the sire in storage.
        Bud storage matron = buds[seed.matronId];
        Bud storage sire = buds[seed.sireId];

         // Call the sooper-sekret gene mixing operation.
        (
            uint256 childGene,
            uint256 childTHC,
            uint256 childCBD,
            uint256 generationFactor
        ) = geneScience.mixGenes(
            matron.gene,
            sire.gene,
            seed.generation,
            uint256(seed.newBornBreedingCooldownEndBlock).sub(1)
        );

        seed.gene = childGene;
        seed.thc = uint32(childTHC);
        seed.cbd = uint32(childCBD);
        seed.state = BudGrowthState.GROWN;
        seed.newBornBreedingCooldownEndBlock = uint64(
            (newBornBreedingCoolDown.div(secondsPerBlock)).add(block.number)
        );
        seed.generationFactor = uint64(generationFactor);
        
        // Send the growing fee to the person who made birth happen.
        if (autoGrowingFee > 0) {
            msg.sender.transfer(autoGrowingFee);
        }

        // emit the born event
        emit GrownSingle(_id, childGene, childTHC, childCBD);
    }

    /* ========== PRIVATE FUNCTION ========== */

    /**
     * @dev Recalculate the breedingCostMultiplier for bud after breed.
     * If breedingCostMultiplierEndBlock is less than current block number
     * reset breedingCostMultiplier back to 2, otherwize multiply breedingCostMultiplier by 2. Also update
     * breedingCostMultiplierEndBlock.
     */
    function _refreshBreedingMultiplier(Bud storage _bud) private {
        if (_bud.breedingCostMultiplierEndBlock < block.number) {
            _bud.breedingCostMultiplier = 2;
        } else {
            uint16 newMultiplier = _bud.breedingCostMultiplier * 2;
            if (newMultiplier > maxBreedCostMultiplier) {
                newMultiplier = maxBreedCostMultiplier;
            }

            _bud.breedingCostMultiplier = newMultiplier;
        }
        _bud.breedingCostMultiplierEndBlock = uint64(
            (breedingMultiplierCoolDown.div(secondsPerBlock)).add(block.number)
        );
    }

    function _ownerPermittedToBreed(
        address _sender,
        uint256 _matronId,
        uint256 _sireId
    ) private view returns (bool) {
        // owner must own matron, othersize not permitted
        if (!isOwnerOf(_sender, _matronId)) {
            return false;
        }

        // if owner owns sire, it's permitted
        if (isOwnerOf(_sender, _sireId)) {
            return true;
        }

        // if sire's owner has given permission to _sender to breed,
        // then it's permitted to breed
        if (budAllowedToAddress.contains(_sireId)) {
            return budAllowedToAddress.get(_sireId) == _sender;
        }

        return false;
    }

    /**
     * @dev Checks that a given bud is able to breed. Requires that the
     * current cooldown is finished (for sires) and also checks that there is
     * no pending pregnancy.
     */
    function _isReadyToBreed(Bud storage _bud)
        private
        view
        returns (bool)
    {
        return
            (_bud.state == BudGrowthState.GROWN) &&
            (_bud.newBornBreedingCooldownEndBlock < uint64(block.number));
    }

    /**
     * @dev Checks to see if a given bud is pregnant and (if so) if the gestation
     * period has passed.
     */

    function _isReadyToGrow(Bud storage _seed) private view returns (bool) {
        return
            (_seed.state == BudGrowthState.SEED) &&
            (_seed.newBornBreedingCooldownEndBlock < uint64(block.number));
    }

    /**
     * @dev Calculating breeding ALPA cost for internal usage.
     */
    function _breedingRewardCost(
        uint256 _matronId,
        uint256 _sireId,
        bool _strict
    ) private view returns (uint256) {
        uint256 blockNum = block.number;
        if (!_strict) {
            blockNum = blockNum + 1;
        }

        Bud storage sire = buds[_sireId];
        uint256 sireBreedingBase = _getBaseBreedingCost(sire.generation);
        uint256 sireMultiplier = sire.breedingCostMultiplier;
        if (sire.breedingCostMultiplierEndBlock < blockNum) {
            sireMultiplier = 1;
        }

        Bud storage matron = buds[_matronId];
        uint256 matronBreedingBase = _getBaseBreedingCost(matron.generation);
        uint256 matronMultiplier = matron.breedingCostMultiplier;
        if (matron.breedingCostMultiplierEndBlock < blockNum) {
            matronMultiplier = 1;
        }

        return
            (sireBreedingBase.mul(sireMultiplier)).add(
                matronBreedingBase.mul(matronMultiplier)
            );
    }


    /**
     * @dev Internal utility function to initiate breeding seed, assumes that all breeding
     *  requirements have been checked.
     */
    function _breedSeed(uint256 _matronId, uint256 _sireId)
        private
        returns (uint256)
    {
        // Transfer birthing ALPA fee to this contract
        uint256 rewardCost = _breedingRewardCost(_matronId, _sireId, true);

        uint256 devAmount = rewardCost.mul(devBreedingPercentage).div(100);
        uint256 artistAmount = rewardCost.mul(artistBreedingPercentage).div(100);
        uint256 stakingAmount = rewardCost.mul(100 - devBreedingPercentage - artistBreedingPercentage).div(
            100
        );

        assert(reward.transferFrom(msg.sender, devAddress, devAmount));
        assert(reward.transferFrom(msg.sender, artistAddress, artistAmount));
        assert(reward.transferFrom(msg.sender, stakingAddress, stakingAmount));

        // Grab a reference to the Buds from storage.
        Bud storage sire = buds[_sireId];
        Bud storage matron = buds[_matronId];

        // refresh breeding multiplier for both parents.
        _refreshBreedingMultiplier(sire);
        _refreshBreedingMultiplier(matron);

        // Determine the lower generation number of the two parents
        uint256 parentGen = matron.generation;
        if (sire.generation < matron.generation) {
            parentGen = sire.generation;
        }

        // child generation will be 1 larger than min of the two parents generation;
        uint256 childGen = parentGen.add(1);

        // Determine when the seed will be cracked
        uint256 seedingcooldownEndBlock = (seedingDuration.div(secondsPerBlock)).add(
            block.number
        );
        
        uint256 seedID = _createSeed(
            _matronId,
            _sireId,
            childGen,
            seedingcooldownEndBlock,
            msg.sender
        );

        // Emit the BreedingComplete event.
        emit BreedingComplete(seedID, _matronId, _sireId, seedingcooldownEndBlock);

        return seedID;
    }

    /**
     * @dev Internal check to see if a given sire and matron are a valid mating pair.
     * @param _matron A reference to the Bud struct of the potential matron.
     * @param _matronId The matron's ID.
     * @param _sire A reference to the Bud struct of the potential sire.
     * @param _sireId The sire's ID
     */
    function _isValidMatingPair(
        Bud storage _matron,
        uint256 _matronId,
        Bud storage _sire,
        uint256 _sireId
    ) private view returns (bool) {
        // A Bud can't breed with itself
        if (_matronId == _sireId) {
            return false;
        }

        // Bud can't breed with their parents.
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        return true;
    }

    /**
     * @dev openzeppelin ERC1155 Hook that is called before any token transfer
     * Clear any BudAllowedToAddress associated to the bud
     * that's been transfered
     */
    function _beforeTokenTransfer(
        address,
        address,
        address,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            if (budAllowedToAddress.contains(ids[i])) {
                budAllowedToAddress.remove(ids[i]);
            }
        }
    }
}

pragma solidity >=0.7.0;

import "./BudOperator.sol";

contract BudCore is BudOperator {
    /**
     * @dev Initializes crypto bud contract.
     * @param _reward ALPA ERC20 contract address
     * @param _devAddress dev address.
     * @param _stakingAddress staking address.
      * @param _artistAddress artist address.
     */
    constructor(
        IERC20 _reward,
        IGeneScience _geneScience,
        address _operator,
        address _devAddress,
        address _stakingAddress,
        address _artistAddress,
        string memory _uriString
    )  {
        reward = _reward;
        geneScience = _geneScience;
        operator = _operator;
        devAddress = _devAddress;
        stakingAddress = _stakingAddress;
        artistAddress = _artistAddress;
        // start with the mythical genesis bud
        _createGen0Bud(uint256(-1), 0, 0, msg.sender);
        _setURI(_uriString);
    }

    /* ========== OWNER MUTATIVE FUNCTION ========== */

    /**
     * @dev Allows owner to withdrawal the balance available to the contract.
     */
    function withdrawBalance(uint256 _amount, address payable _to)
        external
        onlyOwner
    {
        _to.transfer(_amount);
    }

    /**
     * @dev pause crypto bud contract stops any further hatching.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause crypto bud contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

pragma solidity >=0.7.0;


import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IGeneScience.sol";
import "../interfaces/ICryptoBudThcListener.sol";
import "./BudBreed.sol";

contract BudOperator is BudBreed {
    using Address for address;

    address public operator;

    /*
     * bytes4(keccak256('onCryptoBudEnergyChanged(uint256,uint256,uint256)')) == 0x5a864e1c
     */
    bytes4
        private constant _INTERFACE_ID_CRYPTO_BUD_THC_LISTENER = 0x5a864e1c;

    /* ========== EVENTS ========== */

    /**
     * @dev Event for when bud's thc changed from `fromEnergy`
     */
    event ThcChanged(
        uint256 indexed id,
        uint256 oldThc,
        uint256 newThc
    );

    event CbdChanged(
        uint256 indexed id,
        uint256 oldCbd,
        uint256 newCbd
    );
    /* ========== OPERATOR ONLY FUNCTION ========== */

    function updateBudThc(
        address _owner,
        uint256 _id,
        uint32 _newThc
    ) external onlyOperator nonReentrant {
        require(_newThc > 0, "CryptoBuds: invalid thc");

        require(
            isOwnerOf(_owner, _id),
            "CryptoBuds: bud does not belongs to owner"
        );

        Bud storage thisBud = buds[_id];
        uint32 oldThc = thisBud.thc;
        thisBud.thc = _newThc;

        emit ThcChanged(_id, oldThc, _newThc);
        _doSafeEnergyChangedAcceptanceCheck(_owner, _id, oldThc, _newThc);
    }

    /**
     * @dev Transfers operator role to different address
     * Can only be called by the current operator.
     */
    function transferOperator(address _newOperator) external onlyOperator {
        require(
            _newOperator != address(0),
            "CryptoBuds: new operator is the zero address"
        );
        operator = _newOperator;
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Throws if called by any account other than operator.
     */
    modifier onlyOperator() {
        require(
            operator == _msgSender(),
            "CryptoBuds: caller is not the operator"
        );
        _;
    }

    /* =========== PRIVATE ========= */

    function _doSafeEnergyChangedAcceptanceCheck(
        address _to,
        uint256 _id,
        uint256 _oldThc,
        uint256 _newThc
    ) private {
        if (_to.isContract()) {
            if (
                IERC165(_to).supportsInterface(
                    _INTERFACE_ID_CRYPTO_BUD_THC_LISTENER
                )
            ) {
                ICryptoBudThcListener(_to).onCryptoBudThcChanged(
                    _id,
                    _oldThc,
                    _newThc
                );
            }
        }
    }
}

pragma solidity >=0.7.0;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./BudBase.sol";

contract BudToken is BudBase, ERC1155("") {
    /* ========== EVENTS ========== */

    /**
     * @dev Emitted when single `budId` bud with `gene` and `thc` is born
     */
    event GrownSingle(uint256 indexed budId, uint256 gene, uint256 thc, uint256 cbd);

    /**
     * @dev Equivalent to multiple {GrownSingle} events
     */
    event GrownBatch(uint256[] budIds, uint256[] genes, uint256[] thc, uint256[] cbd);

    /* ========== VIEWS ========== */

    /**
     * @dev Check if `_budId` is owned by `_account`
     */
    function isOwnerOf(address _account, uint256 _budId)
        public
        view
        returns (bool)
    {
        return balanceOf(_account, _budId) == 1;
    }

    /* ========== OWNER MUTATIVE FUNCTION ========== */

    /**
     * @dev Allow contract owner to update URI to look up all bud metadata
     */
    function setURI(string memory _newuri) external onlyOwner {
        _setURI(_newuri);
    }

    /**
     * @dev Allow contract owner to create generation 0 bud with `_gene`,
     *   `_thc` and transfer to `owner`
     *
     * Requirements:
     *
     * - `_thc` must be less than or equal to MAX_GEN0_ENERGY
     */
    function createGen0Bud(
        uint256 _gene,
        uint256 _thc,
        uint256 _cbd,
        address _owner
    ) external onlyOwner {
        address budOwner = _owner;
        if (budOwner == address(0)) {
            budOwner = owner();
        }

        _createGen0Bud(_gene, _thc, _cbd, budOwner);
    }

    /**
     * @dev Equivalent to multiple {createGen0Bud} function
     *
     * Requirements:
     *
     * - all `_energies` must be less than or equal to MAX_GEN0_ENERGY
     */
    function createGen0BudBatch(
        uint256[] memory _genes,
        uint256[] memory _thcs,
        uint256[] memory _cbds,
        address _owner
    ) external onlyOwner {
        address budOwner = _owner;
        if (budOwner == address(0)) {
            budOwner = owner();
        }

        _createGen0BudBatch(_genes, _thcs, _cbds, _owner);
    }

    /* ========== INTERNAL ALPA GENERATION ========== */

    /**
     * @dev Create an bud seed. Seeds `gene``thc` will assigned to 0
     * initially and won't be determined until egg is cracked.
     */
    function _createSeed(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _seedingcooldownEndBlock,
        address _owner
    ) internal returns (uint256) {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));
       

        Bud memory _bud = Bud({
            gene: 0,
            thc: 0,
            cbd: 0, 
            birthTime: uint64(block.timestamp),
            breedingCostMultiplierEndBlock: 0,
            breedingCostMultiplier: 1,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            newBornBreedingCooldownEndBlock: uint64(_seedingcooldownEndBlock),
            generation: uint16(_generation),
            generationFactor: 0,
            state: BudGrowthState.SEED

        });

        buds.push(_bud);
        uint256 seedId = buds.length - 1;

        _mint(_owner, seedId, 1, "");

        return seedId;
    }

    /**
     * @dev Internal gen-0 bud creation function
     *
     * Requirements:
     *
     * - `_thc` must be less than or equal to MAX_GEN0_ENERGY
     */
    function _createGen0Bud(
        uint256 _gene,
        uint256 _thc,
        uint256 _cbd,
        address _owner
    ) internal returns (uint256) {
        require(_thc <= MAX_GEN0_THC, "CryptoBuds: invalid thc");
        require(_cbd <= MAX_GEN0_CBD, "CryptoBuds: invalid cbd");
       
        Bud memory _bud = Bud({
            gene: _gene,
            thc: uint32(_thc),
            cbd: uint32(_cbd),
            birthTime: uint64(block.timestamp),
            breedingCostMultiplierEndBlock: 0,
            breedingCostMultiplier: 1,
            matronId: 0,
            sireId: 0,
            newBornBreedingCooldownEndBlock: 0,
            generation: 0,
            generationFactor: GEN0_GENERATION_FACTOR,
            state: BudGrowthState.GROWN
          
        });

        buds.push(_bud);
        uint256 newBudID = buds.length - 1;

        _mint(_owner, newBudID, 1, "");

        // emit the born event
        emit GrownSingle(newBudID, _gene, _thc, _cbd);

        return newBudID;
    }

    /**
     * @dev Internal gen-0 bud batch creation function
     *
     * Requirements:
     *
     * - all `_energies` must be less than or equal to MAX_GEN0_ENERGY
     */
    function _createGen0BudBatch(
        uint256[] memory _genes,
        uint256[] memory _thcs,
        uint256[] memory _cbds,
        address _owner
    ) internal returns (uint256[] memory) {
        require(
            _genes.length > 0,
            "CryptoBuds: must pass at least one genes"
        );
        require(
            _genes.length == _thcs.length,
            "CryptoBuds: genes and thc length mismatch"
        );
        require(
            _genes.length == _cbds.length,
            "CryptoBuds: genes and cbd length mismatch"
        );
        uint256 budIdStart = buds.length;
        uint256[] memory ids = new uint256[](_genes.length);
        uint256[] memory amount = new uint256[](_genes.length);

        for (uint256 i = 0; i < _genes.length; i++) {
            require(
                _thcs[i] <= MAX_GEN0_THC,
                "CryptoBuds: invalid THC"
            );
            require(
                _cbds[i] <= MAX_GEN0_CBD,
                "CryptoBuds: invalid CBD"
            );

           
            Bud memory _bud = Bud({
                gene: _genes[i],
                thc: uint32(_thcs[i]),
                cbd: uint32(_cbds[i]),
                birthTime: uint64(block.timestamp),
                breedingCostMultiplierEndBlock: 0,
                breedingCostMultiplier: 1,
                matronId: 0,
                sireId: 0,
                newBornBreedingCooldownEndBlock: 0,
                generation: 0,
                generationFactor: GEN0_GENERATION_FACTOR,
                state: BudGrowthState.GROWN
        
            });

            buds.push(_bud);
            ids[i] = budIdStart + i;
            amount[i] = 1;
        }

        _mintBatch(_owner, ids, amount, "");

        emit GrownBatch(ids, _genes, _thcs, _cbds);

        return ids;
    }
}

pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ICryptoBud is IERC1155 {
    function getBud(uint256 _id)
        external
        view
        returns (
            uint256 id,
            uint256 seedingcooldownEndBlock,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 breedingCostMultiplier,
            uint256 breedingCostMultiplierEndBlock,
            uint256 generation,
            uint256 gene,
            uint256 thc,
            uint256 cbd,
            uint256 state
        );

    function hasPermissionToBreedAsSire(address _addr, uint256 _id)
        external
        view
        returns (bool);

    function grandPermissionToBreed(address _addr, uint256 _sireId) external;

    function clearPermissionToBreed(uint256 _budId) external;

    function breed(uint256 _matronId, uint256 _sireId)
        external
        payable
        returns (uint256);

    
    function grow(uint256 _id) external;

}

pragma solidity >=0.7.0;

import "@openzeppelin/contracts/introspection/IERC165.sol";

interface ICryptoBudThcListener is IERC165 {
    /**
        @dev Handles the Bud thc change callback.
        @param id The id of the Bud which the thc changed
        @param oldThc The ID of the token being transferred
        @param newThc The amount of tokens being transferred
    */
    function onCryptoBudThcChanged(
        uint256 id,
        uint256 oldThc,
        uint256 newThc
    ) external;
}

pragma solidity >=0.7.0;

interface IGeneScience {

    function isGeneScience() external pure returns (bool);

    /**
     * @dev given genes of bud 1 & 2, return a genetic combination
     * @param genes1 genes of matron
     * @param genes2 genes of sire
     * @param generation child generation
     * @param targetBlock target block child is intended to be born
     * return gene child gene
     * return thc thc associated with the gene
     * return generationFactor buffs child thc, higher the generation larger the generationFactor
     *   thc = gene thc * generationFactor
     */
    function mixGenes(
        uint256 genes1,
        uint256 genes2,
        uint256 generation,
        uint256 targetBlock
    )
        external
        
        returns (
            uint256 gene, 
            uint256 thc, 
            uint256 cbd, 
            uint256 generationFactor
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../utils/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) public {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 10
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}