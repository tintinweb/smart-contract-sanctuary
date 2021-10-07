// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/**
 * @title ERC721
 * @dev Abstract base implementation for ERC721 functions utilized within dispensary contract.
 */
abstract contract ERC721 {
    using SafeMath for uint256;
    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
    function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256 tokenId);
    function balanceOf(address owner) external view virtual returns (uint256 balance);
}

contract FreeBohoEvent is ERC721Holder, Ownable {
    using SafeMath for uint256;

    /**************************************************************/
    /*********************** Events & Vars ************************/
    /**************************************************************/
    // Boho Bones ERC721 Contract
    ERC721 public bohoBonesContract = ERC721(0x6B521ADC1Ca2fC6819dddB66b24e458FeD0780c6);

    mapping(address => uint256) public freeBohoBonesClaims;
    uint256 public totalClaimed = 0;

    // Bool to pause/unpause gift event
    bool public isActive = false;

    /**
     * @param claimee Address of the claimee.
     * @param amount Amount claimed.
     * @param totalClaimed Total claimed so far.
     */
    event Claim(address claimee, uint256 amount, uint256 totalClaimed);

    /**
     * @param claimee Address of the claimee.
     * @param numClaims aa
     */
    event ClaimCheck(address claimee, uint256 numClaims);

    /**************************************************************/
    /************************ Constructor *************************/
    /**************************************************************/
    constructor() {
        freeBohoBonesClaims[0x1d3F0BaE0dD29aaEaCECC7F73b3A236a61369dD7] = 5;
        freeBohoBonesClaims[0x8cE584fe9609fe2F0EFD1a8b9b7fc4846C32e679] = 3;
        freeBohoBonesClaims[0xD8f76F9B09984150ae868DEB81ECBf33352f9fD8] = 1;
        freeBohoBonesClaims[0xA5C8C195E6136F29Ef27d9ab9Cccb4440B981B96] = 1;
        freeBohoBonesClaims[0xC830A16B73EEF1b47FeB25210b0E40BE06C5f8eF] = 1;
        freeBohoBonesClaims[0xEa704D7c14D0073C5548ed19b73bfD060a618079] = 1;
        freeBohoBonesClaims[0x1D144AE3991C86504a38aA9A3EB4CCD27fa4af72] = 1;
        freeBohoBonesClaims[0x0B3B6585e71c2175667360cce8dDe426D4B63f88] = 1;
        freeBohoBonesClaims[0x491E7B27d69597EF6b2cAB4002Da3B9C0229943c] = 1;
        freeBohoBonesClaims[0x30104D7F97d93b06A907589d122491A4527a0a9b] = 1;
        freeBohoBonesClaims[0x0BbF707661Ec707cf3d0f78A053558da88Cb086c] = 14;
        freeBohoBonesClaims[0x73Ac429c11f80480D50eD48cDA7D84d36A3375aa] = 1;
        freeBohoBonesClaims[0xa5C065337C5bADb5f5De5376d3AfB97f510Aa193] = 1;
        freeBohoBonesClaims[0x3Df9e23C1e069702D86736BE5C2f425b9e528835] = 1;
        freeBohoBonesClaims[0xE463d56e80da7292A90faF77bA3F7524F0a0dCCd] = 1;
        freeBohoBonesClaims[0x8DD23f498DD5543D2EB4fc25E7126B38e764c1AC] = 29;
        freeBohoBonesClaims[0xd9888eEFfab4b0a215C8af47923d80190beAcd5b] = 1;
        freeBohoBonesClaims[0xf269a8883a87AdB37CCe8a5de21Df504796654f5] = 1;
        freeBohoBonesClaims[0xB74FA1c2BDA1D5b5FFC9C5818088F4CFD1De3376] = 1;
        freeBohoBonesClaims[0xE9cF68cdDB318e142fA40D60C4458425F78Ab18E] = 2;
        freeBohoBonesClaims[0x617970384Ef3f78c67bcd47D0554E26a0bA315Fa] = 1;
        freeBohoBonesClaims[0x7fb6F52996ba02884Fd4Cd136bB2af3D8909c56C] = 1;
        freeBohoBonesClaims[0x7bE2f3eB66634762ba9b00287104e3f904a7A982] = 1;
        freeBohoBonesClaims[0x849fc8D14979b3525F00D022DD1a600Ed45fEd23] = 1;
        freeBohoBonesClaims[0x1a968C13bE8eafFaDa60d3d0A1128aB4B914960A] = 1;
        freeBohoBonesClaims[0xE2aB3D4d0684eBF9D994dAbA3AcD91caCD99D862] = 1;
        freeBohoBonesClaims[0xBF72F634b1938f3dFA6e11c92C2AA115e55497dC] = 1;
        freeBohoBonesClaims[0x73EfD6D8CB6AC17e147944b27a7a9890a8bc48b1] = 1;
        freeBohoBonesClaims[0x6f0290eEe760B6e025ff1546ec1154546c71C203] = 1;
        freeBohoBonesClaims[0xEB878d6728CB326360049FE1F14E3F48B4fFAFdd] = 1;
        freeBohoBonesClaims[0xC2F33614aE5EC27B4b27785A74aeF12EC45087C0] = 1;
        freeBohoBonesClaims[0x5e62F8E89823e90dA13Fec734A4388e36721db9d] = 1;
        freeBohoBonesClaims[0x50869083Fd81B1858864bF72b843a060De7Fa695] = 1;
        freeBohoBonesClaims[0xD74597B0D23753d186d79f96Da01a0b73cAe98aA] = 1;
        freeBohoBonesClaims[0x1Bb01159AB168ACD0Cc055eAD980729A2ADAe919] = 2;
        freeBohoBonesClaims[0x4E10b980073D5Db98A10352a70c7BdDc78CCa0A6] = 1;
        freeBohoBonesClaims[0xb1F63d177fD6A8Df51e85Ed0DBbf498f1D778C84] = 1;
        freeBohoBonesClaims[0xEb6C72D50a6F9fA53e25946085373d40c4437e99] = 1;
        freeBohoBonesClaims[0x2d021B60d85A36a3Cc25fbc9959A1749a8Dbd697] = 2;
        freeBohoBonesClaims[0xE55E2d78b143BA8f52e5e5EFb35c97455022e27c] = 1;
        freeBohoBonesClaims[0xe542fFa2D9FB68F7F72f7E6b1A1d629650cBdE2E] = 1;
        freeBohoBonesClaims[0x3ad13bC4030129269537F7fF97Cb14B9b94465Fd] = 1;
        freeBohoBonesClaims[0x94C0aF134A748f4E973455Fc3D6c4130e47DDb5d] = 1;
        freeBohoBonesClaims[0xAcf63dc3a045E5B530A3c1aE8F92565368e7BbeF] = 1;
        freeBohoBonesClaims[0x7cF85fdC696EE5A9f872c3408dDb57c587aDC079] = 1;
        freeBohoBonesClaims[0x017715B9A71DaBed2DdAE0BBBb6b0896509C8212] = 1;
        freeBohoBonesClaims[0x2Ac8507AC54FbBf114FDf5520E3D9BD0f738C281] = 1;
        freeBohoBonesClaims[0x7768FBc67afecF2b4Caee9D1841ad14637D13652] = 1;
        freeBohoBonesClaims[0xB14Ff6a76573DB4FebeC7E002ea5CB01bfCeF784] = 5;
        freeBohoBonesClaims[0x49f407e2Af4b1305f61b5F65e660eC2a65DD588b] = 1;
        freeBohoBonesClaims[0xEB421fE44B25dA86982CDc36c525D5f1BAAFcfcA] = 1;
        freeBohoBonesClaims[0x902222853F4885A685962bd191D885c0A5b92Fc7] = 1;
        freeBohoBonesClaims[0x263994646816dBfD5849F44dec7909fc2c1f8037] = 1;
        freeBohoBonesClaims[0x2DfC6f2EB7f89EA1ad1C785c94e407e658EBc645] = 1;
        freeBohoBonesClaims[0x3f4772105eE6bFF1241A8564D32525Bb46725401] = 1;
        freeBohoBonesClaims[0xe2817B82845A19D93E817EDfB0F68E78f34D35A5] = 1;
        freeBohoBonesClaims[0x780da7C973cCF18b06A837Be4c966308Cd28D263] = 1;
        freeBohoBonesClaims[0x8d4B4c1eC39148E22c296c0090f7D4f3478cFE75] = 1;
        freeBohoBonesClaims[0x5aA91fc20C63C03f0C6e108FaDcFe521F117Bbd4] = 1;
        freeBohoBonesClaims[0x0b9c75E3786Fbe0c7c795C4fEe19111693b529C8] = 1;
        freeBohoBonesClaims[0xEFAa2607F171b6df935aC679253734223A3275a4] = 5;
        freeBohoBonesClaims[0x7642afA2F917Be8DEe1e4e16033A8CA3B8389aB3] = 1;
        freeBohoBonesClaims[0xd45858221bc7170BA813495f8C777c006189F910] = 3;
        freeBohoBonesClaims[0x50D356d2440c0e2Bcdbb2f26f7fFBfAd135358FE] = 1;
        freeBohoBonesClaims[0x6B796152085318d1c415762e9d876E50593E1B9F] = 1;
        freeBohoBonesClaims[0x9F9E9430D66b6B05EA0E007E8E957a9Ba41ad1D1] = 1;
        freeBohoBonesClaims[0x49E7C2De8b8e4886CE2511Bec96325f96F2D71C3] = 1;
        freeBohoBonesClaims[0xeb67a9E45d3D74f3794Dd716651d40Ef97Fc1b51] = 1;
        freeBohoBonesClaims[0x207d48a7C63960451bD3E02A0A43AA66f550196E] = 1;
        freeBohoBonesClaims[0xd1Af703A834d074617785c989291eC0067Faa56F] = 1;
        freeBohoBonesClaims[0x3361Ed013fEf5fBa7b7a19C6de6EdcF686813820] = 1;
        freeBohoBonesClaims[0xDB720e23034d380F414bb31c142B501622458a1B] = 1;
        freeBohoBonesClaims[0x92DbC41f895d65fE7081cc2bEE91E9EAae7EA1c7] = 1;
        freeBohoBonesClaims[0x80136fE63bdB22b981D5C6E2738bd2216fB05C67] = 1;
        freeBohoBonesClaims[0x0C190A40D2925fB44D1e114963A8C642b8117A49] = 1;
        freeBohoBonesClaims[0x0c4037B72A0C63340FB530690EA123C612665A34] = 1;
        freeBohoBonesClaims[0xa54d7BD6E82152E061097869b9f478c800e103E4] = 1;
        freeBohoBonesClaims[0x215792FC17032988abEb64BdAeC23487AC384694] = 1;
        freeBohoBonesClaims[0x5966A41fd8588Ae21FD0A01DB36d1ba8C07D1eA5] = 1;
        freeBohoBonesClaims[0xC7Ff03e2bf706BD0b45d59dd964bd9c39De1eC2D] = 18;
        freeBohoBonesClaims[0x112B22a9664a22D02426713EC9ffeB072f64E291] = 1;
        freeBohoBonesClaims[0x3043ec75e223C7c1aE74bcFA7EAab906f9ADC883] = 1;
        freeBohoBonesClaims[0xEc7641e298aF02c19171451381C570327389b0c2] = 3;
        freeBohoBonesClaims[0x7d340fAA2A5cB6dEAaD18393477249334312a249] = 1;
        freeBohoBonesClaims[0x70781b7a217FB5798431225e829ab90A314a6845] = 1;
        freeBohoBonesClaims[0x39dB72Dc9494Ed36Fffd3A3458f1eb969213E9A1] = 2;
        freeBohoBonesClaims[0x5EB57983CA289A3F06c25Bb968D467283AB9925C] = 2;
        freeBohoBonesClaims[0xBa44c50261348505F988Dc44F564568358B68EE6] = 1;
        freeBohoBonesClaims[0x72eA3953c6444cE68Ccaf23B93C306e56A591Db2] = 1;
        freeBohoBonesClaims[0xc63412bfeA02513132d829d9C396510a8065E564] = 1;
        freeBohoBonesClaims[0xD6e0Ce6a9A5AB32e0ac25F3c0241831268c70BF3] = 1;
        freeBohoBonesClaims[0xc1b52456b341f567dFC0Ee51Cae40d35F507129E] = 7;
        freeBohoBonesClaims[0xDd4C53C7747660fb9954E5fc7B36f94b4A297922] = 3;
        freeBohoBonesClaims[0xb3a3eed660EA4C43Caf8774cfA3e09049C798468] = 4;
        freeBohoBonesClaims[0xb8F5EE84E27497345dea6a1815027A41C8eaA7Eb] = 1;
        freeBohoBonesClaims[0xa627734D74AAb4D17c9EF358e5b44B0f951499E9] = 1;
        freeBohoBonesClaims[0xe397dD922a12149Dc346c405c89c4cdbf5ae99FC] = 2;
        freeBohoBonesClaims[0x98F32222F1A9ED6A2E71FfC7c322bEE1A8AE5f2A] = 5;
        freeBohoBonesClaims[0x33094A50A0e29A22a2DAd090006fE27E3A2f0deb] = 1;
        freeBohoBonesClaims[0xbd87223189f01ad1A5aa35324744A70edeEF24Bc] = 3;
        freeBohoBonesClaims[0xc0114E2fCBc7fa985452AA73C986F947716c4b84] = 1;
        freeBohoBonesClaims[0x91107D20346BbBa8AeF12f34b541F3ec39a70575] = 1;
        freeBohoBonesClaims[0xA06941D533f7714f12387381284d7af21f58764e] = 1;
        freeBohoBonesClaims[0x6dd0E9b9bF3a19B89297FE22914C87F0e3402A96] = 1;
        freeBohoBonesClaims[0xad0178f0bD6366c8ea06148D3250FDc1103Cb555] = 25;
        freeBohoBonesClaims[0xf27BdcD155cC9f5e90baFE616D2E8cEe47609A7A] = 1;
        freeBohoBonesClaims[0x94F23611cBd115cdB78Acdc1401028a5526904Df] = 1;
        freeBohoBonesClaims[0x9678C36Dc13FF1c48bdEFfa0CC0Da14C4fFd4D92] = 1;
        freeBohoBonesClaims[0x36A8A94153514202E1a0b957659fE2599B1eB0F1] = 1;
    }

    /**************************************************************/
    /******************** Function Modifiers **********************/
    /**************************************************************/
    /**
     * @dev Prevents a function from running if contract is paused
     */
    modifier eventIsActive() {
        require(isActive == true, "FreeBohoEvent: Gift event has paused or ended.");
        _;
    }

    /**
     * @param claimee address of the claimee checking claimed status for.
     * @dev Prevents repeat claims for a given claimee.
     */
    modifier isNotClaimed(address claimee) {
        uint256 claimed = isClaimed(claimee);
        require(claimed == 0, "FreeBohoEvent: You have no more free Bohos to claim.");
        _;
    }

    /**************************************************************/
    /******************** Getter Functions ************************/
    /**************************************************************/
    /**
     * @param claimee Address of the claimee we are checking claimed status for.
     * @dev Returns a boolean indicating if address has any free bohos to claim.
     */
    function isClaimed(address claimee) public returns (uint256) {
        return freeBohoBonesClaims[claimee];
    }


    /**************************************************************/
    /************** Access Controlled Functions *******************/
    /**************************************************************/
    /**
     * @dev Sets the gift event to unpaused if paused, and paused if unpaused.
     * @dev Can only be called by contract owner.
     */
    function flipEventState() public onlyOwner {
        isActive = !isActive;
    }

    /**
     * @param newBohoBonesContractAddress Address of the new Boho Bones ERC721 contract.
     * @dev Sets the address for the referenced Boho Bones ERC721 contract.
     * @dev Can only be called by contract owner.
     */
    function setBohoBonesContractAddress(address newBohoBonesContractAddress) public onlyOwner {
        bohoBonesContract = ERC721(newBohoBonesContractAddress);
    }

    /**
     * @dev Provides method for withdrawing Boho Bones NFTs from contract, if necessary.
     * @dev Can only be called by contract owner.
     */
    function withdrawAll() public onlyOwner {
        uint256 balance = bohoBonesContract.balanceOf(address(this));

        for (uint256 i = 0; i < balance; i++) {
            bohoBonesContract.safeTransferFrom(
                address(this),
                msg.sender,
                bohoBonesContract.tokenOfOwnerByIndex(address(this), i)
            );
            totalClaimed = totalClaimed.add(1);
        }
    }

    /**
     * @dev Claims all free bohos for the given address.
     * @dev Can only be called when gift event is active.
     * @dev Can only be called by the owner of the free bohos.
     */
    function megaClaimFreeBohos() public eventIsActive {
        emit ClaimCheck(msg.sender, freeBohoBonesClaims[msg.sender]);

        // for (uint256 i = 0; i < freeBohoBonesClaims[msg.sender]; i++) {
        //     bohoBonesContract.safeTransferFrom(
        //         address(this),
        //         msg.sender,
        //         bohoBonesContract.tokenOfOwnerByIndex(address(this), i)
        //     );
        //     totalClaimed = totalClaimed.add(1);
        // }

        // Emit claim event
        // emit Claim(msg.sender, freeBohoBonesClaims[msg.sender], totalClaimed);
        
        // Remove address from free boho list
        // delete freeBohoBonesClaims[msg.sender];
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

{
  "optimizer": {
    "enabled": true,
    "runs": 500
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "libraries": {}
}