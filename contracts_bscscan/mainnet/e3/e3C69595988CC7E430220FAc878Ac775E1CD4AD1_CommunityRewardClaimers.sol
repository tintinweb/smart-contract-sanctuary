// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../ClamNFT/IClam.sol";
import "../PearlNFT/IPearl.sol";
import "../RNG/IRNG.sol";

library CommunityRewardClaimersStorage {
    function earlyMarketingWinners() internal pure returns (address payable[97] memory) {
        return [
            0xca3990c454ba3B6852A3363cFf4CEc6C66CEbAcE,
            0x5c55d596e7a8774b238c12E60a73215993F0142c,
            0xEc2996F891ad3d764158F90d2F7134f973334790,
            0xD91850d690a678e48B91680B54b5A2DB7Ef612A1,
            0x56f34afe7b6C8c658DCD5CF8C41004CCFB50AEF5,
            0xF9DD707e87Db48Ca7d845cE480dDED411157B4e3,
            0xEf18d342FaE9c175E02A4Ab6eD3A7D63F2255AC1,
            0x03352123C0C4E17e0663336102f822A40F1De4f6,
            0x2Aae542a20cAB453318c5B5725D796280Fc4De30,
            0xcdaa7494c029833781C5957229243b3E4Ea5072D,
            0xC5E6721E5e5424034867fE747065D6711c6E1A4e,
            0x5f5893545E53Bc4c9D79ddbeb441425F666be954,
            0x4043Fe1Ed89EB32D8F3d786920f8bf1980D051cE,
            0x1416D63CFcFCD3a15a67A1e5F8C4Bc303288A6CF,
            0xc1d9af01a545C03b7EBf3E8bd72837c853B7f4a8,
            0x4FBc808372609Dc17301f789Af59E16B7006ed1A,
            0x727AC146846bD23D45F239782426542fd382F1f0,
            0x348e6063b315D415cc609Bea1c046C7341FFf9fF,
            0xCd83252F2BD84e87A31AF6065a13bE183852FcB0,
            0x7306d52F1867E0D492f5e390Af9D24892E6beBEE,
            0xe34C21298175A50c9ecEB19D17DF7e59c329586c,
            0xb5f49D58276085a43aDA287D6590879879B470b3,
            0x7a2cB69AB4cf5f26A344A682E0105961ea1dB44D,
            0x523D84fc44Bfc3BAE1360F93C46a11E13DA43D85,
            0xA069F2204CAB4862c861925AD40b113D158A5E2F,
            0x74999A38AAC4185E10A0D1C9717c7dEBa4DCe857,
            0x1f2ad8F924d5988522e3e3B209faBF0932d51723,
            0x4fe8e13aAd140F4Fe61743A48dF1Cd27fCF80648,
            0x3B3845CCcE5C96c67D61355af232cAe7F5C2B5Cd,
            0xA9c42C7f5a5f1f017F3978F98Df901F47e7fda94,
            0xc1D46c1f4695836E1Abc18DdEc53C9C119dA51D0,
            0xb9ef85Fb70E233D574479fBF02eAfbC72EFD1e6E,
            0xD365752F06e0Afc9E665260d9B264Ac347743020,
            0xb8fc316d8263262F33939855Dd0BD8A7ae0ed5e7,
            0x28FcfcF26eeDD652a2D5884Bbc07338221DE34BE,
            0x37FFe79d00C8c33E3f9622ac940e46BFa56d70a7,
            0xA011A2379E884826ec192bd7f46b2aFa6C356Dc1,
            0x0e01536C59Ac4c883C12F80E3225029C8d69ce17,
            0x383F95A0c543079Aad6d20288eB999Eb4B94A592,
            0xdc90FE4ecb4fC8Aa7155E52bD72902f389B716A7,
            0x31c053249e26F62d16CeA697AcaF50241C395927,
            0xe96e94B09e533c7e099A31671f342c898D54ffE1,
            0x28AB643F1da4ee9f3282b70bC6bBd957f9215c3c,
            0x3D075Fa474269a9856F12ea70f56aFa3d7542Af6,
            0x6107F283EC9512DD9992e544be42370C51Fce27D,
            0xBed4967C98048632C54AE2158E353662413Bcc12,
            0x92FFea8aE534Bee00B62e057CC7e6878Fe00E508,
            0x4fAbc775209E6533D05ee6E81f0F1Ef8d296D194,
            0xeAf5b8f7aEcF9CFfBe38746923Bf9cfDD86BB883,
            0xF4c76a2cF17Becc328c2b1aAc4Cc1A6576582084,
            0xa2b4c41451943E4Aa8d668eb4643e587acE61209,
            0x34ca844Ec08BbE4f2012B420569784FE605E2518,
            0xFb4f449399641859d0de129ea92FC204B1A8c912,
            0x29879B0e2fC75ab57e89521BCDb70E3b1785ED78,
            0xC58D6d7DFd33230E35B02113580c9319029E9D2a,
            0xCB2DB422097c39Bcc6BD04b1e779677e8c158d17,
            0x45B2B5B959b141987580DafC5b11885f86F9F698,
            0x5a11d19aFf54caB61bf855C72dC7E13A0BC82e33,
            0x82b7Fd3Ea917BB9a3C90D226A499C4B7d99eE204,
            0x77C7b0C23cbE2079D6004Bd781929be141eB90a0,
            0xF309fbFebDa864B3979Cb62399f89ecb2Cc29D33,
            0x0311b7217ad693a58448b9C114c5Ddd549EBA11F,
            0xD531E4f44d6e19D3a2a7703520611f194b568A16,
            0xf1EB72b191da75a93385Ee3D23a11811E3905d60,
            0xEE8A894b2a2276A521E054e4191432BD369314fB,
            0x205D3509Dd37a6a7fb1422929aa3411493021c25,
            0x1C13523aC378A097d83e04C3602Ad8703492d6Aa,
            0x1FB125Cf593fA1D16409eB0D5030546b81c2F66f,
            0xd2031DE6d91855636EcBB9d14309767A0214FE38,
            0xA1c599bC340C32040060EEe6d361A7764424eA85,
            0x727E8D628e9F3138B6153E252730F146e9af9386,
            0x097708D17625dA05d48B575910Bf64a16A6e598B,
            0x327f004A6c0764e68A4F9A683f2BeD82A1d7d55b,
            0x8dF3af6c59D1D41519998215D537436D5f47CC54,
            0xEf7f91ACe09A20B58a1561aae1D8623AcC98C68E,
            0xf75d15133029d174710445892F4f6189E587810d,
            0xaa2DE786c559B2b88E8D22f964A3678808B09f83,
            0x78FE749f966D14446549fA60CD8cF03ebd76CE1C,
            0xDb85391e28017b25a45486108c4ac58D22Bb433e,
            0xE92d6cd0CaEdfD960db31260265cD1dbcda3358C,
            0xC3E37b6894021D64c866aB771DcB0D10013ab74C,
            0x2E21A3d02C8AD121eBACeD68459411271b9F5040,
            0x8aBE59200E6c65D7a4940d12292f3f0B6d3F18f8,
            0x2d4eB91CdDeA03a2A55CcCa343147ECA764076e2,
            0xe58c8f0a003858742b9A4C0BE0133a13c3c7AdC0,
            0xd2B41B2209de76ed2B6224e9204248d055ee20c8,
            0x5AD92baD78ADD32442E89f60aaaE0fcb8E2AF00D,
            0xd886Cb4Ce818566F2e7932F32fC16BfE7005acC7,
            0x031543014965F071bc5283D4f74AAF615F15D510,
            0x72110c7117Ee3D0BC77D4682107EA04b02312ED6,
            0x6232d7a6085D0Ab8F885292078eEb723064a376B,
            0x66f6794168b6E0c8A55a675ea262625304E755f7,
            0xB90C99761c27a30B41E604e9e08A613909c8c641,
            0x29671580Fe09898305aD6750484301F152F09679,
            0x8EbA6755a003E877989282632596ca5c76FCb0cA,
            0x68219fF257c04a5f8ebD922140fCeb7142f27a1d,
            0x2661EDC99dB2addf22Ab20A8dE2330CA1834b431
        ];
    }
}

contract CommunityRewardClaimers is Ownable {
    using SafeMath for uint256;
    IClam public clam;
    IPearl public pearl;
    IRNG public rng;

    bool public paused;

    mapping(address => bytes32) public rngRequestHashFromRewardBeneficiary;
    mapping(address => bool) public userClaimedReward;
    mapping(address => bool) public pearlAwardee;
    mapping(address => bool) public clamAwardee;
    mapping(address => bool) public clamMaximaAwardee;

    uint256 private constant PEARLS_REMAINING = 10;
    uint8[10] private PEARL_BODY_COLOR_NUMBER;
    uint8[6] private PEARL_SHAPE_NUMBER;

    event RewardClaimed(address indexed beneficiary, bytes32 requestHash);
    event RewardCollected(address indexed beneficiary, uint256 tokenId, address nftType, bool isMaxima);

    constructor(
        address _clam,
        address _pearl,
        address _rng
    ) {
        require(_clam != address(0) && _pearl != address(0) && _rng != address(0), "CommunityRewardClaimers: !empty");

        clam = IClam(_clam); // NOTE: need to make this contract a minter role to Clam
        pearl = IPearl(_pearl); // NOTE: need to make this contract a minter role to Pearl
        rng = IRNG(_rng); // NOTE: need to make this contract a bonafide role to RNG

        address payable[97] memory claimers = CommunityRewardClaimersStorage.earlyMarketingWinners();
        for (uint256 i = 0; i < claimers.length; i++) {
            pearlAwardee[claimers[i]] = true;
        }
    }

    // fallback function can be used to claim reward
    receive() external payable {
        claimReward();
    }

    /**
     * @dev Claim reward
     */
    function claimReward() public payable {
        require(isAwardee(_msgSender()), "CommunityRewardClaimers: address is not allowed to claim reward");
        require(!paused, "CommunityRewardClaimers: reward claims paused");

        require(
            rngRequestHashFromRewardBeneficiary[msg.sender] == bytes32(0),
            "CommunityRewardClaimers: Please collect reward"
        );
        require(!userClaimedReward[msg.sender], "CommunityRewardClaimers: You already claimed");

        uint256 oracleFee = rng.getOracleFee();
        require(msg.value >= oracleFee, "CommunityRewardClaimers: BNB value sent is not correct. Must pay oracle fee");

        userClaimedReward[msg.sender] = true;

        bytes32 hashRequest = rng.requestRNG{value: oracleFee}(msg.sender);

        rngRequestHashFromRewardBeneficiary[msg.sender] = hashRequest;

        emit RewardClaimed(msg.sender, hashRequest);
    }

    // collect NFT
    function collectReward() external {
        require(
            rngRequestHashFromRewardBeneficiary[msg.sender] != bytes32(0),
            "CommunityRewardClaimers: Can't collect reward without claiming it first. You may have also already claimed your reward"
        );

        bytes32 requestHash = rngRequestHashFromRewardBeneficiary[msg.sender];
        rngRequestHashFromRewardBeneficiary[msg.sender] = bytes32(0); // zero buyer's hashRequest

        uint256 rand = rng.getRNGFromHashRequest(requestHash);
        require(
            rand != uint256(0),
            "CommunityRewardClaimers: Can't collect reward as RNG for tokenId has not been received yet"
        );

        bool isMaxima; // initialized as false. Undeclared to save gas
        address rewardType;

        if (pearlAwardee[msg.sender]) {
            rewardType = address(pearl);
            pearl.mint(msg.sender, rand, PEARLS_REMAINING, PEARL_BODY_COLOR_NUMBER, PEARL_SHAPE_NUMBER);
        } else if (clamMaximaAwardee[msg.sender]) {
            isMaxima = true;
            rewardType = address(clam);
            clam.mint(msg.sender, rand, isMaxima);
        } else {
            rewardType = address(clam);
            clam.mint(msg.sender, rand, isMaxima);
        }

        emit RewardCollected(msg.sender, rand, rewardType, isMaxima);
    }

    function isAwardee(address claimer) public view returns (bool) {
        if (pearlAwardee[claimer] || clamAwardee[claimer] || clamMaximaAwardee[claimer]) return true;

        return false;
    }

    // *** owner mode *** //
    function addPearlAwardee(address[] memory accounts) external onlyOwner {
        for (uint256 index; index < accounts.length; index++) {
            pearlAwardee[accounts[index]] = true;
        }
    }

    function addClamMaximaAwardee(address[] memory accounts) external onlyOwner {
        for (uint256 index; index < accounts.length; index++) {
            clamMaximaAwardee[accounts[index]] = true;
        }
    }

    /// @dev send BNB in case some get stuck
    function inCaseBNBGetStuck(uint256 amount) external onlyOwner {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "CommunityRewardClaimers: amount can't be transferred out");
    }

    function togglePauseSale() public onlyOwner {
        paused = !paused;
    }
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
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";

interface IClam is IERC721EnumerableUpgradeable {
    struct ClamInfo {
        bool isMaxima;
        bool isAlive;
        uint256 birthTime;
        uint256 pearlsProduced;
        uint256 pearlProductionDelay;
        uint256 pearlProductionCapacity;
        uint256 dna;
        uint256 pearlProductionStart;
        uint256[] producedPearlIds;
    }

    function mint(
        address,
        uint256,
        bool
    ) external;

    function mintMaxima(address, uint256) external;

    function mintCommunityReward(
        address,
        uint256,
        bool
    ) external;

    function canCurrentlyProducePearl(uint256) external returns (bool);

    function canStillProducePearls(uint256) external view returns (bool);

    function incrementPearlCounter(uint256, uint256) external;

    function setNewProductionDelay(uint256, uint256) external;

    function getPearlProductionDelay(uint256) external view returns (uint256);

    function setNewProductionStart(uint256, uint256) external;

    function getPearlProductionStart(uint256) external view returns (uint256);

    function clamData(uint256)
        external
        view
        returns (
            bool,
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getPearlTraits(uint256) external view returns (uint8[10] memory, uint8[6] memory);

    function burn(uint256) external;

    event ClamHarvested(address user, uint256 clamId);
    event IncubationTimeSet(uint256 incubationTime);
    event ProductionDelaySet(uint256 clamId);
    event ProductionStartSet(uint256 clamId, uint256 timestamp);
    event PearlCounterIncremented(uint256 clamId);
    event ClamMaximaMonthlyCapSet(uint256 newCap);
    event DNADecoderSet(address newDnaDecoder);
    event PriceForShellSet(uint256 clamPriceForShell, uint256 pearlPriceForShell);
    event ProductionCapacitySet(uint256 minPearlProductionCapacity, uint256 maxPearlProductionCapacity);
    event ProductionDelayRangeSet(uint256 minPearlProductionDelay, uint256 maxPearlProductionDelay);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";

interface IPearl is IERC721EnumerableUpgradeable {
    /// @notice Info about pearl
    /// `birthTime` block timestamp of birth
    /// `dna` random generated number
    /// `pearlsRemaining` amount of pearls that mother clam had left when giving birth to this pearl. The lower the amount, the rarer the pearl should be
    struct PearlInfo {
        uint256 birthTime;
        uint256 dna;
        uint256 pearlsRemaining;
    }

    function pearlData(uint256)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function mint(
        address,
        uint256,
        uint256,
        uint8[10] memory,
        uint8[6] memory
    ) external;

    function burn(uint256) external;

    function nextPearlId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IRNG {
    function getOracleFee() external view returns (uint256);

    function requestRNG(address) external payable returns (bytes32);

    function getRNGFromHashRequest(bytes32) external view returns (uint256);
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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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

