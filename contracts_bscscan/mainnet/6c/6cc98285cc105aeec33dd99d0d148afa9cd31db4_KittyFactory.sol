pragma solidity >=0.5.0 <0.6.0;

import "./SafeMath.sol";
import "./KittyContract.sol";
import "./KittyAdmin.sol";

contract KittyFactory is KittyContract, KittyAdmin {
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    uint256 public constant CREATION_LIMIT_GEN0 = 65535;
    uint256 public constant NUM_CATTRIBUTES = 10;
    uint256 public constant DNA_LENGTH = 16;
    uint256 public constant RANDOM_DNA_THRESHOLD = 7;
    uint256 internal _gen0Counter;

    // tracks approval for a kittyId in sire market offers
    mapping(uint256 => address) sireAllowedToAddress;

    event Birth(
        address owner,
        uint256 kittyId,
        uint256 mumId,
        uint256 dadId,
        uint256 genes
    );

    /// @dev cooldown duration after breeding
    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
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

    function kittiesOf(address _owner) public view returns (uint256[] memory) {
        // get the number of kittes owned by _owner
        uint256 ownerCount = ownerKittyCount[_owner];
        if (ownerCount == 0) {
            return new uint256[](0);
        }

        // iterate through each kittyId until we find all the kitties
        // owned by _owner
        uint256[] memory ids = new uint256[](ownerCount);
        uint256 i = 1;
        uint256 count = 0;
        while (count < ownerCount || i < kitties.length) {
            if (kittyToOwner[i] == _owner) {
                ids[count] = i;
                count = count.add(1);
            }
            i = i.add(1);
        }

        return ids;
    }

    function getGen0Count() public view returns (uint256) {
        return _gen0Counter;
    }

    function createKittyGen0(uint256 _genes)
        public
        onlyKittyCreator
        returns (uint256)
    {
        require(_gen0Counter < CREATION_LIMIT_GEN0, "gen0 limit exceeded");

        _gen0Counter = _gen0Counter.add(1);
        return _createKitty(0, 0, 0, _genes, msg.sender);
    }

    function _createKitty(
        uint256 _mumId,
        uint256 _dadId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    ) internal returns (uint256) {
        // cooldownIndex should cap at 13
        // otherwise it's half the generation
        uint16 cooldown = uint16(_generation / 2);
        if (cooldown >= cooldowns.length) {
            cooldown = uint16(cooldowns.length - 1);
        }

        Kitty memory kitty = Kitty({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndTime: uint64(now),
            mumId: uint32(_mumId),
            dadId: uint32(_dadId),
            generation: uint16(_generation),
            cooldownIndex: cooldown
        });

        uint256 newKittenId = kitties.push(kitty) - 1;
        emit Birth(_owner, newKittenId, _mumId, _dadId, _genes);

        _transfer(address(0), _owner, newKittenId);

        return newKittenId;
    }

    function breed(uint256 _dadId, uint256 _mumId)
        public
        returns (uint256)
    {
        require(_eligibleToBreed(_dadId, _mumId), "kitties not eligible");

        Kitty storage dad = kitties[_dadId];
        Kitty storage mum = kitties[_mumId];

        // set parent cooldowns
        _setBreedCooldownEnd(dad);
        _setBreedCooldownEnd(mum);
        _incrementBreedCooldownIndex(dad);
        _incrementBreedCooldownIndex(mum);

        // reset sire approval to fase
        _sireApprove(_dadId, _mumId, false);
        _sireApprove(_mumId, _dadId, false);

        // get kitten attributes
        uint256 newDna = _mixDna(dad.genes, mum.genes, now);
        uint256 newGeneration = _getKittenGeneration(dad, mum);

        return _createKitty(_mumId, _dadId, newGeneration, newDna, msg.sender);
    }

    function _eligibleToBreed(uint256 _dadId, uint256 _mumId)
        internal
        view
        onlyApproved(_mumId)
        returns (bool)
    {
        // require(isKittyOwner(_mumId), "not owner of _mumId");
        require(
            isKittyOwner(_dadId) ||
            isApprovedForSiring(_dadId, _mumId),
            "not owner of _dadId or sire approved"
        );
        require(readyToBreed(_dadId), "dad on cooldown");
        require(readyToBreed(_mumId), "mum on cooldown");

        return true;
    }

    function readyToBreed(uint256 _kittyId) public view returns (bool) {
        return kitties[_kittyId].cooldownEndTime <= now;
    }

    function _setBreedCooldownEnd(Kitty storage _kitty) internal {
        _kitty.cooldownEndTime = uint64(
            now.add(cooldowns[_kitty.cooldownIndex])
        );
    }

    function _incrementBreedCooldownIndex(Kitty storage _kitty) internal {
        // only increment cooldown if not at the cap
        if (_kitty.cooldownIndex < cooldowns.length - 1) {
            _kitty.cooldownIndex = _kitty.cooldownIndex.add(1);
        }
    }

    function _getKittenGeneration(Kitty storage _dad, Kitty storage _mum)
        internal
        view
        returns (uint256)
    {
        // generation is 1 higher than max of parents
        if (_dad.generation > _mum.generation) {
            return _dad.generation.add(1);
        }

        return _mum.generation.add(1);
    }

    function _mixDna(
        uint256 _dadDna,
        uint256 _mumDna,
        uint256 _seed
    ) internal pure returns (uint256) {
        (
            uint16 dnaSeed,
            uint256 randomSeed,
            uint256 randomValues
        ) = _getSeedValues(_seed);
        uint256[10] memory geneSizes = [uint256(2), 2, 2, 2, 1, 1, 2, 2, 1, 1];
        uint256[10] memory geneArray;
        uint256 mask = 1;
        uint256 i;

        for (i = NUM_CATTRIBUTES; i > 0; i--) {
            /*
            if the randomSeed digit is >= than the RANDOM_DNA_THRESHOLD
            of 7 choose the random value instead of a parent gene

            Use dnaSeed with bitwise AND (&) and a mask to choose parent gene
            if 0 then Mum, if 1 then Dad

            randomSeed:    8  3  8  2 3 5  4  3 9 8
            randomValues: 62 77 47 79 1 3 48 49 2 8
                           *     *              * *

            dnaSeed:       1  0  1  0 1 0  1  0 1 0
            mumDna:       11 22 33 44 5 6 77 88 9 0
            dadDna:       99 88 77 66 0 4 33 22 1 5
                              M     M D M  D  M                         
            
            childDna:     62 22 47 44 0 6 33 88 2 8

            mask:
            00000001 = 1
            00000010 = 2
            00000100 = 4
            etc
            */
            uint256 randSeedValue = randomSeed % 10;
            uint256 dnaMod = 10**geneSizes[i - 1];
            if (randSeedValue >= RANDOM_DNA_THRESHOLD) {
                // use random value
                geneArray[i - 1] = uint16(randomValues % dnaMod);
            } else if (dnaSeed & mask == 0) {
                // use gene from Mum
                geneArray[i - 1] = uint16(_mumDna % dnaMod);
            } else {
                // use gene from Dad
                geneArray[i - 1] = uint16(_dadDna % dnaMod);
            }

            // slice off the last gene to expose the next gene
            _mumDna = _mumDna / dnaMod;
            _dadDna = _dadDna / dnaMod;
            randomValues = randomValues / dnaMod;
            randomSeed = randomSeed / 10;

            // shift the DNA mask LEFT by 1 bit
            mask = mask * 2;
        }

        // recombine DNA
        uint256 newGenes = 0;
        for (i = 0; i < NUM_CATTRIBUTES; i++) {
            // add gene
            newGenes = newGenes + geneArray[i];

            // shift dna LEFT to make room for next gene
            if (i != NUM_CATTRIBUTES - 1) {
                uint256 dnaMod = 10**geneSizes[i + 1];
                newGenes = newGenes * dnaMod;
            }
        }

        return newGenes;
    }

    function _getSeedValues(uint256 _masterSeed)
        internal
        pure
        returns (
            uint16 dnaSeed,
            uint256 randomSeed,
            uint256 randomValues
        )
    {
        uint256 mod = 2**NUM_CATTRIBUTES - 1;
        dnaSeed = uint16(_masterSeed % mod);

        uint256 randMod = 10**NUM_CATTRIBUTES;
        randomSeed =
            uint256(keccak256(abi.encodePacked(_masterSeed))) %
            randMod;

        uint256 valueMod = 10**DNA_LENGTH;
        randomValues =
            uint256(keccak256(abi.encodePacked(_masterSeed, DNA_LENGTH))) %
            valueMod;
    }

    function isApprovedForSiring(uint256 _dadId, uint256 _mumId)
        public
        view
        returns (bool)
    {
        return sireAllowedToAddress[_dadId] == kittyToOwner[_mumId];
    }

    function sireApprove(
        uint256 _dadId,
        uint256 _mumId,
        bool _isApproved
    ) external onlyApproved(_dadId) {
        _sireApprove(_dadId, _mumId, _isApproved);
    }

    function _sireApprove(
        uint256 _dadId,
        uint256 _mumId,
        bool _isApproved
    ) internal {
        if (_isApproved) {
            sireAllowedToAddress[_dadId] = kittyToOwner[_mumId];
        } else {
            delete sireAllowedToAddress[_dadId];
        }
    }
}