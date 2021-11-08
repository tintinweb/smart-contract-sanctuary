// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICombatDragons.sol";
import "./presale-data/firstPresaleData.sol";

contract FirstPresale is Ownable {
    using SafeMath for uint256;
    ICombatDragons public cDragons;

    uint256 public beginningOfSale;
    uint256 public constant PRICE = 7e16; // 0.07 ETH
    uint256 public constant AMOUNT_PER_ADDRESS = 5;

    mapping(address => uint256) public mintedByAddress;

    constructor(address _cDragons, uint256 _beginningOfSale) {
        cDragons = ICombatDragons(_cDragons);
        beginningOfSale = _beginningOfSale;
    }

    // fallback function can be used to mint cDragons
    receive() external payable {
        uint256 numOfcDragonss = msg.value.div(PRICE);

        mintNFT(numOfcDragonss);
    }

    /**
     * @dev Main sale function. Mints cDragons
     */
    function mintNFT(uint256 numberOfcDragonss) public payable {
        require(block.timestamp >= beginningOfSale, "sale not open");
        require(
            block.timestamp <= beginningOfSale.add(48 hours),
            "presale ended"
        );
        require(isWhitelisted(), "address not listed");

        require(
            mintedByAddress[msg.sender].add(numberOfcDragonss) <=
                AMOUNT_PER_ADDRESS,
            "Exceeds AMOUNT_PER_ADDRESS"
        );

        require(
            PRICE.mul(numberOfcDragonss) == msg.value,
            "Ether value sent is incorrect"
        );

        mintedByAddress[msg.sender] = mintedByAddress[msg.sender].add(
            numberOfcDragonss
        );

        for (uint256 i; i < numberOfcDragonss; i++) {
            cDragons.mint(msg.sender);
        }
    }

    function isWhitelisted() private view returns (bool) {
        address payable[432] memory listed = PresaleData.getWhitelisted();
        for (uint256 index = 0; index < listed.length; index++) {
            if (msg.sender == listed[index]) {
                return true;
            }
        }
        return false;
    }

    // owner mode
    function removeFunds() external onlyOwner {
        uint256 funds = address(this).balance;
        uint256 jShare = funds.mul(48).div(100);
        (bool success1, ) = 0x9b84a019CcaD110fA4602D9479B532Ff7D27F01B.call{
            value: jShare
        }("");

        uint256 donShare = funds.mul(15).div(100);
        (bool success2, ) = 0x7734af82A0dbeEd27903aDAe00784E69b9EB155e.call{
            value: donShare
        }("");

        uint256 pShare = funds.mul(15).div(100);
        (bool success3, ) = 0xc27aa218950d40c2cCC74241a3d0d779b52666f3.call{
            value: pShare
        }("");

        uint256 digShare = funds.mul(15).div(100);
        (bool success4, ) = 0x2f788b3074583945fE68De7CED0971EDccAd2c20.call{
            value: digShare
        }("");

        uint256 t1Share = funds.mul(5).div(100);
        (bool success5, ) = 0xfe34cDe84a4E0ebe795218448dC12165C1827B45.call{
            value: t1Share
        }("");

        uint256 nexxShare = funds.mul(2).div(100);
        (bool success6, ) = 0x005ef5716c3Fb61a9a963b2d3c7f9718676e0Ef6.call{
            value: nexxShare
        }("");

        (bool success, ) = owner().call{value: address(this).balance}("");
        require(
            success &&
                success1 &&
                success2 &&
                success3 &&
                success4 &&
                success5 &&
                success6,
            "funds were not sent properly"
        );
    }

    function removeDustFunds() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

interface ICombatDragons is IERC721Enumerable {
    function mint(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

library PresaleData {
    function getWhitelisted()
        public
        pure
        returns (address payable[432] memory)
    {
        return [
            0x086FeC4a44Fdba71565129d7c2E2e16D52b1F54d,
            0x32F130D2e8F0561D292cFd90CE505Fb063E303c8,
            0x837d8462c0F66821eF177d2979eadFeFff694e35,
            0x9429716E42e2024E5731c26F613231B0F759Cedf,
            0x2847E472A7F56c1693A815F2CA50F30d3d263F4E,
            0x6Ff412F54E10588A2CF0442cCfB228f866ff1684,
            0x8CECa142D8ca90F797B755C81Ab202EaAe619b79,
            0xf7321609DB01389294d973d37587Ef89EB8be2C5,
            0x54372e2b338C4bE299B75CB54D914822dB32A63F,
            0x96625FD47b4749650A0154ED24a0Ba74abf7afDb,
            0x403a419BcFB064B06f2980f9a6a55f76c74C4f27,
            0xE4eDfA92838988Efd79df87b432D37F3aa8Fb333,
            0x7d764fDcE7464D4f1486968efb27ebb481c8D7ab,
            0xC96371F6864F1743970374294Ee9f03b44D9B60F,
            0x49cAc40095a447829d4998F24b9A3127B87E5Fdf,
            0x3559dCb5f242599991331BCd74E000da853e42fb,
            0xeA2eFF0888e4761c7CB6f5Af9a6090e862Ac604f,
            0x88c36AaC04487C1CB8E998Cb76f6dd9cF10854b9,
            0x07460a6986598566ea167AC3b84B82201c8498f0,
            0x568092fb0aA37027a4B75CFf2492Dbe298FcE650,
            0x86e4A9D4761EF4a960B9c62465d63C71B01AdFA4,
            0x9aCdbD9a9fdC0cDe2bb4A44Aa14825d3057f52fA,
            0xf65c40f09299501F24D397Bd8342c17F12A3a8dF,
            0x2843f4f6f09566ABA98C59DcA7a41346178E3E5F,
            0x78773a9977BDC34E3034d5f0247490E602392a1b,
            0xb5f844289b88decE5169544039aC5De286068C4F,
            0xD0CE2B2e833132DFa3ABa872362C30E6c21F76b2,
            0x00f09F87a2e15c9666F37ad48c01e180E66381Ed,
            0xF6F7a57598A11419385dF885fF8ea8F1da885Dc0,
            0x87FCb251ead8093d2eb5E760258a0D5793422020,
            0x4B8Db3EeE0dBf35a3D13d910e48Ab29b57EAf381,
            0xF138984Bd659edd8DE38fb2FebEdae8bED5E0255,
            0xC692b2a9a4CA174a7B1a3A94C26aa2F08349dfF4,
            0x73fE2eeA5D8277f17e9255C86F57B55f8e5BB76b,
            0xF6E1A43EB08120b2e0eDfADDdD53E1d5B71e86e8,
            0x9F6eF7F909929A57620e4E1693E3B4361b0996E8,
            0x4C3183Cdb600Cc0666cfde7b8745f12A5C520078,
            0x102a3D686c71b5ab33358Bf34f398EDB5ac1151d,
            0xBd74c35965465512347a3D520DEaa32F458E058B,
            0x9e1Ef34c00666EE78F098981F240DcEa19591279,
            0xB5071E20a825471a5499cf58eBBc702acfF51ef1,
            0x318C35bAC8cB26145D5D6d20A80d00968EFd7d37,
            0xAB2197d99b601a89Dccd320231A348a0429F93e8,
            0x574Dff221131DD87B995263c823FC2cc069497D6,
            0x556162C3798B731B5cE052436fB9a79D1F7F5f1C,
            0x12Ba86526230d5310a16420D4794c2A50EC5Dd9A,
            0xBA64444d6d16D3661644464140d2dEC3708Ad332,
            0xB321fbc842AfffCA3D23cFA477EA7b29bC29e1B6,
            0xC06de8f5c5EE8f47e335Ef3111C76dc3ED6008eB,
            0x41d776F23037Eb4AfBE4d7E89c4C9Bd03D000544,
            0xd783453B3754D046CafD1973D7Bc0EBC22f90104,
            0xb609cadc5C97B5d4f00311aDaBE351abFE6BCC38,
            0x0A7Dd6591271b5dd1E73Ccf5aF6895B6A370D297,
            0x8011F9Bb55e6BEeC05BcE1e64Ff669eAC33afDa4,
            0x3CCc3b5584CdF44550bF6A97229332F55B0854F2,
            0x00741285Ce4d9e7b5cb99E68e181d7f344CFA70c,
            0x454b28CE1b0Cd551AA533203f81cF3d17b1DAcfD,
            0xBE7B419De8bC4E96980F600e76fC5962a2a76FB8,
            0xF79499Efc49D196fE0aefFc331Fab2577B8106b6,
            0xe731CEC7F89768C37aDAE9ffD69E7442131Fec1B,
            0x3BF2fE6BFB2c713fd82ca4b93f1Fbb507A389671,
            0xF46c76deAdfc076913A5175f94091b240e33Fa37,
            0x7AA8F0fAaB2Dca4Fe090A7EC3c5cD61abBef1C9B,
            0xDC93D5A9b0BFE49182DAd923C589898E97884E71,
            0xB365Bf238a4d613c1C222ff1838D7236996864cF,
            0x2B0eC94E217d27B4B9a4B9CDcEFB682309cD2331,
            0x1aDd9Eaa7768b810B553373C68D38744FB7084E5,
            0xc796203Ef3AA5d4787A530d2Eb7AC49Aa9a4f64B,
            0xCB1aE3D9BFa3A653b1223e0133017CF44248F73A,
            0xCAA4954431b6EafC5624a8cE2271dD702E44d302,
            0xe15474E7a6fB790b4abc032fF5ccb3139d4C878c,
            0xeE0201E07db325a5D732AeB9b9Fba7b5B8E92c2A,
            0x7BB97095baBBeF6a99c931B9799C619AA497397B,
            0x9D3b27dd4532Ce6d1Ac770d09530c57019F41AdA,
            0x35808843a413347f4452148f37d1CCdd381EC539,
            0x009de8D287f1c2d5808B20e3Aa9f0c02A724D0E5,
            0xA3d83cA657170c10f50c81cf49B1E86A81f0E815,
            0x0775a23372a9A1572B2138f0eb5069A60f6b8b05,
            0x4dDe5fE9E6b36D3A6E540B4357188e716B0F74Ff,
            0xDcD082a4520929dcE240cD1E5233339f7e15c661,
            0x525A52E0C790A9AE84752BfE1d761278fd2dcF61,
            0x82bCe34398a30a338E15bCe3E2a228b81ccb2040,
            0x3464C55075dDCB205c3F9968C90Ae94e52E682e3,
            0x3Fa3b6e00CFA24f5d37C03b37fcd2Fa5a0f700D0,
            0xeeAa7e778AB03c4af8e8598C4A1db7348a49e614,
            0xc23be914242330a2Cb1f869cb96DDFD122f5666f,
            0xF0bF1C59ee9b78A2Ce5763165e1B6B24Cb35fD8A,
            0x27eE8FA6a70a8F156008EDe28C7B8ea5F72fFdF3,
            0x951cBbaDF5C62a18644C5EE56Cb314c6DD9d8366,
            0xF07aEacF6825f1F0308457B2e0127589F2aFef15,
            0xedce28477d41a0a266a33fF7E8c4c323d7Aa3448,
            0xDcd9eB477943518fF5911d405373cfb3b2711ff5,
            0xE9Cc4F546CBab8A1BDF7e6E3e37851C6250d28F2,
            0x94eF50aFAc9c04572813F36Fb8D676EB400de278,
            0x3bD9a7e5a02717c3dBE7f39E98784Cf285E3A81B,
            0xc42Ff2A724eFec3E3A49C6E62643aF1F5596113B,
            0x5D46ed7405A8A87492cd139fcd38BCE60CB5030E,
            0xF3E7754BcF2159b11199291659162d6c200E1bD4,
            0x3383b5B049010330c06C45bD188D2Ee519c8eBD9,
            0x94A6CFb7E9206e75C4De90A4972f7CD3975B9A75,
            0x0788d7e71B2D9049ad662C52E0171FbC4DF973BC,
            0x891AA27Af08e3bc78e00f239355e7D9b646B0A25,
            0x2fb197c272879CACA350Fe0DbFE0e4de4984403E,
            0x24d8119DFd2D2039Cd4b2c198396D23526F9A0E5,
            0x9F105819fdf91d27353EEe613Dd37e1514c80306,
            0x2D4E694146767d4151b697A9a99C332880b0DF5d,
            0x33b832eAee5Bfe4dc8455599fcE963a39c885FF4,
            0xC079Ea4A29C8Cb6AfE2CBed2F85beB6c0476AF3c,
            0x9CC1E62604517E36f9A37dF14B015535526F54c2,
            0x266452479c0675eDF6fe9e71B0953C45e0e2d3f4,
            0xfbC046c534DC3BB3Fcc0B533Cc4b0B49D35D367A,
            0xbB1b4d9229b7D13ea71D858d5cD90Bb86c14FDAF,
            0xab0b0dD7e4EaB0F9e31a539074a03f1C1Be80879,
            0x398341cdC3F4DD1ac0654C537eBdF9DE73199465,
            0x8E5C6D4E49b07d05ADe227f89e1bBdB7B7082b50,
            0x762E1f80aC479A2252Ec289e1e98d9b2135DFD41,
            0x410DdF65e174fb3286939e126AbF54794601a5AE,
            0x07C7bCe85fb3F71c5c8C3CdEA79f9F7212A8162D,
            0xb78196b3e667841047d1Bb1365AB8fB3d46aB1A8,
            0x42A448602747D7783673e76737dbf330952143ad,
            0x7101546623C6fca318Fccab5aA0d966162CB5A83,
            0x9d79F12e677822C2d3F9745e422Cb1CdBc5A41AA,
            0xD1070b725dca993c9ccDAf80C6E7c57d626F3f56,
            0xbC59f1695C62F9B89a17DFE6080542445d7ADda8,
            0xf9960aFF0BC9a4aFDd934e6902D26E6072af5eAA,
            0x740E9f6C04E7277C7d3AE02bC34f9170099b2926,
            0xE882c7e3B8E8869cb182472649e71ff0802AFbB8,
            0xcfB464Ed219145518247C22797f066f57859375D,
            0xAaB6d07c3529e4d6Ac82E288B45Bc91DC38858dB,
            0xd209E78E0795b776eF8C66a013A8314d43FD1fe9,
            0xf13E04F88047C7a012320C953a0d846B6F858b96,
            0x164bBC953119960858Ce5dB4f7de9DdEE072092e,
            0x37caD5Ab25Ae20C449514491D6BD76D6845ad4E6,
            0x1e868E0F5948Fc94ed99DDe0d0AbA939E7677b47,
            0x1b46D512E2D22cD4c5186d34525EE2bfAE70ecbE,
            0x643DcBC92592A2B24d9CAC834713f112Ceb8Ba60,
            0xD1d9E0eB3AD4277Ce90a5c68781c8E5fC18e56D0,
            0xe7d146d300d93f284080a79c2F063b5E2afD502c,
            0x94fF1e7d124c10126A5133E389deEcdAC6185590,
            0xfFA4D998539CC03b97bbC5FfAB6232e08dD5201f,
            0x6192a758e431051f28e27EcfF388FF99ee998F2e,
            0xdD15553673126d386f9E735d0cc56a96E59Cc095,
            0x394bC1EE5687397b354943516D04f07b28967fF3,
            0xE7e207E94d07a370DE80e7d38093B49a7217eC23,
            0x496030689Bbee22510cf41244fCe4D5eBE4fb767,
            0x6c99e8eA19074D37Badb3a2826bE8A1088e7877c,
            0x5017729A41F315075BbA1e669B0D8e8a5e4db8C6,
            0x8448b2FE4c0D1588f4Cf57232423Ca80F3277DC4,
            0xcFeee429a333Afcf89E6Ae5BCCaf9aDb01AbA6EB,
            0x9f1E19C805Bc2DF9D0c00d6622E6Ed386A0CA30D,
            0xD6d90B2B2B1013DAa9Ef8706DFa81898B532bb3A,
            0xb57c0b622A5a5FCdeb22E49953210fd4c1DE2194,
            0xC456d38AfB6A48C15E7eEAac9b32c451846808A3,
            0x14A4F24fB43e9aCE7b1A83D72dfc1C3D40686517,
            0x6F2D34e20eBD3a04ccD7F51d43c2947F7330c790,
            0x9d5B6019E36161FF3001Ec096637Ac6ee97c2C0f,
            0x539cC566dF7E993EA578487fA0FB3b8937E63B40,
            0xAa4A36fdACEE9a45AB98b194646aD7C6a21ac708,
            0x4c652B45d117BEFcdC4b39cAEC0a5fe035DFd888,
            0x385EF5CC27E783Bb99814EA095fc41f138C4157B,
            0x3186041E3764CCE675a20C6826218CaE4758f692,
            0x446b08A5a85EC9939611DD2Ef251B779bcbBed8a,
            0x9b665c49016732D9E3Ab2c1f47e2A96a8a46849D,
            0xE8c1BC0A06b0D9E68A34768EC3c67868D4a37948,
            0xF1003E0A0dC0b0f47a82434B7559280100CA1Fa1,
            0x0347d14600A9dAFD3C882060E5c657d39f4A6062,
            0xb280d927fdDB14b352a3C1686E616B6010140975,
            0xACf7a536bF5B83dF7C76C1acC7e5b95462E5F22B,
            0x5e07fB29aA7fB940188eF1654D13818Dbc5aFCd9,
            0x62A800203BD217b6d80bcf076745FC6C10CFC28F,
            0xB2819D9f42d3FEdd1fbcfF42bA3d11f22Ea9ca94,
            0x827eD5F2cc8EeeCB85AEB4EEAD46bE9BB95e8766,
            0x827bF5006a21275919879182c8Fb5F7287C1dBB4,
            0x300009caa17472487e248D4fB43Fe32bb2595cD3,
            0x6bD86973cD86e01cdD3D237f0C2c99B7bE751082,
            0x828eeac6d87c8656c0B59AC9C824bA5EB7132b02,
            0x71355378826307Eb08d9e42faE914F62494246C2,
            0x3f95345ea352b9Fe7cA2b6Ce19845D9B7a2218d4,
            0xF08d3C566Cc0177128AF93ae3Fd7958b51f1E129,
            0x45C2188Ec89ccE1F0d08b41fFE6C7EFB7E72479F,
            0x384d2223B8812601B287b52dEb719865a781E0F5,
            0xDF5896a7BB61E8b55460608c3410294aBce14585,
            0xCF266509d20b01771D81d2dcD127562c4E44Cc19,
            0xf329D15E72a6AbeD9F9290F1065312819f43727a,
            0x00063dDB30be7Bc2292583D5f143E9d6E6228440,
            0x62A2D31c84B9b08ad622677178FEeC19EE79c648,
            0x84c8A590ed9Bfa25645747625371DC1E7FB25a61,
            0xAfBa7d2e1Bb51ceC9C71E1E2D5fcAb435274a7f4,
            0x8230919c090FCa2943154ab1dEe553B559636539,
            0x7e824e1BA47eAE465fa9BC50b4b48E8E78eD8700,
            0x4E7B20fF53923cc2befAb8FB9bE3258D99f3b894,
            0xB11808B6c8577616cEb8A1cc574FdC4083b292F5,
            0x38B613B83620E8EA1703d74Bdf3e880B92976B19,
            0x0646575Bf7f62f7D6B6Ed395d7934860159bafEe,
            0xA26fC904f3A558c0321E2D893c3D0AAcCa987726,
            0x4130a43C7eefCa02Dce917715B889F9EeC01D2E8,
            0x537eCBb7B168897385F03d3C4EA378730b47B139,
            0xc4c718Ff0a865ABbDDF7A90adAa24e82cDd28923,
            0xf4D3652FAaC7358829B55e2A5D99BFd4D3f2B0fC,
            0x824Df19ee0ad07F69C985320d4846Ea073B15337,
            0x4f960d763e2d153299F310432fD8e16F75cc9BCa,
            0x84Ab549f907475f6ad211d465Ba54e41D665bAf3,
            0xEd8d3c6D813F80f21a62Ad82BC058a92D439aD9A,
            0xd0C9845FC3C24eeD21803FCF11564eE782598eb0,
            0x2B4f7FEC7D0C9D94993EBB3FeDC0F87f0cEB7e5c,
            0x100434EAC207BF528C4AFE11063Ea1c50cbAE219,
            0x8eD71298FC514fE08640F6b4AD3Adf9C06d03a9B,
            0x477430E5d51a00A0d09f8c3CBe3dB4AeF7ca8eD6,
            0x1be393F5248A15A9E3e6c04Dcbbf9eDD7FBd7Cf5,
            0x76c691D146E8447B941CAF1c25A96a4483Eb9dc7,
            0x5311C1FC5f7a0bfb8c5298eD8D2a5b187a03270d,
            0x8136eFBd9593651EE58f53B9f9830D4Ec0dFEF1c,
            0x42E3830529fdb1F3ED553fe8C32492a01a535C50,
            0x016D4412299A7B77b61078E73BAC9d6de4821000,
            0xe6BFA53825E20136C013DdfA7E7289fcAE33D5dc,
            0x0f6c71f0583e88429CDAb4a40eD07E82D8291E96,
            0xf640D2cb93C3eE248A6D133aAE391a1241538666,
            0x0f3e24932Ee132984f13a0c6101424BC13e9eDe9,
            0x4c54BD629ACB1DaedB3349023a239b4923b8589b,
            0x2E6701CAEC4dA139f1b58645e42e038D2e437183,
            0x79122374eCBaD9cbA0dDF0e0A5F1B676462677B4,
            0x7cdFa7DFC1c6759b5B893a2ABE41D010F9Dd79A7,
            0x166f84aAbCD797dF4AFF767C61fddb386198c62B,
            0x1E8a0Fcff10d4365809472f998F6131e788053Ff,
            0x4ffF3735B7648231bA3b857FFb87787Ba12FcafA,
            0x3c23bC73645A2c63c37C49606C3E2450f470ab2d,
            0x3fE167eD835fB3B28a555a5470b355202d27F436,
            0x445537dBfC407673d66E2c8A86216257aDDd91C0,
            0xBCE0419634f5D1b7790306ec4178f50A14292f55,
            0xE53A7513Ca766F5173DCa5ace3B0cc25D133CE70,
            0x460D4d6dC8b61eC8bf07b23c0ef1D3abb1eb1981,
            0x7107882331B28eE7E6db6bA88546A01D1122b01d,
            0x3fB840c9F362407Eeb62b221f712D78fECCfC80B,
            0x156d4df4f57B5450F1cc7919A5bE1cFd7306894B,
            0x56D3f3a73C48391F413E1D9353165FdB0C7dda3C,
            0xF4e4b655cfB04b8F68C2F636a603fE1603A19e6A,
            0xDd5D0529791DF91907e8210d8bF0721c6C198434,
            0x9692256322C771d06a19347aF575A97110896554,
            0x35C2D950fd3f204c1cdA9BDBB4858B5ABb8b6a46,
            0x01f3B7DF2AeDeF25daDb4f2ed085dE307617B979,
            0x0529A96880602A82348788fc2bDb8FF8A62AC8a6,
            0xD2d520c99319dfa386E08CC28b052c006C707af1,
            0x10064F27352725CB5E30eE2e530Dd0fb0DdA949c,
            0xd7c2D979Cb643a5B81c8B508c011bC0aE5599042,
            0x851de88ceb5cC4E9f5407D5f277CA61940dEf4e0,
            0xE527CE94580057c75468E22f470ad6A31d93607E,
            0xd62dEB9161D8dEb2b35095BB59964EB9adC0575e,
            0x1ecedC1badF45730F649eDE2788EE91770599ADA,
            0x97DA20Dc2BD46174dA79D71a385B7248527fbEE6,
            0xFD5873b0E11dfA1f848995E34fC017De9F5A3d98,
            0x9De4E4cc181d9d1966ab58E07378EF225425ccF0,
            0xd7382dE5A85485Da6a79885E6757B108EBebc758,
            0x08C65Dd23982D6E30A678C54A4AA9245c0d1b80f,
            0x53b31f7d62cB3b31fd7f17983fb575abd0904d37,
            0xBDE89a2376a91e3Ee8e17F086b0Ca181242408a5,
            0xA6B19a17f9445AF48E59423cDd4fc3A425dE0B20,
            0x4e51e9f0655d9Cb452Cc73676166F1080fa0D923,
            0xB8e3c76373B28c359da29855a4b192Fd54510b20,
            0xA56de1BAA57Cd70D2F15C30b356aBb48221B83c7,
            0x17C7E9D59A9DfF32eAB3DC73B22893560a3510d5,
            0x0278C4336c2b9eFc8EE495775b2ed37AEB650B4b,
            0x1E28C9931c8696F03C6404754b99f11F796335e6,
            0x6AC2e6EB797b29aCb46d0C860c7F2a13fa0DD55d,
            0xc5730aDeC1F3829b0497a58e255B5E77df510CCa,
            0x01e374d355BeC5E6921Ab438fEf08399898D9A2f,
            0x3B65487e3E5070A2A253F0e2Ea32cDb41EF6892c,
            0xa0153DBf3e250E9bA57726302b51f7b8e4430b54,
            0xd9718542D7832B322e92Fa03F408D02a4d47C2c5,
            0x4082906f95FfDcF91eFE09EBB7e9eEEA1A243466,
            0x20148934F6bA904562128495a007Cf1D4f3B11A7,
            0xE183094bB311BF5d39B832352a7af40e43a531e8,
            0x339e2F6BaA1E2d607095ADfC032f1D9161cA34D9,
            0x599231a41fCb8739Ba41257152d048f6D5D808e8,
            0x718446A2856473d856143A7190D6c288194F9D09,
            0x1FffE5453e72Df4908f0056c2e092435981D683c,
            0x4B90293176B8c83af97A885f1477ee789Fd66a21,
            0x4b7c48DdF9f51fBDDaF1933ff09db0e4833BE79e,
            0xdA2B21B404DA9c9551D7b8be11DE2A1C1dC2930E,
            0x777D1EC3bc71Cf21a3147737721A165c53138b26,
            0x5B9B250497E9834094B2C5e0065CCa15e3E2b8f6,
            0xa8d3B18515B5d1b3fA4b0be8766BDeef78371115,
            0xAF9461c47840ac87FCfD372788b9942414d06E08,
            0x72506bC4C4B9094d91066449B09f3a3d7C37De77,
            0xEf35Ce7a82691Ffc07a51266EaBf10552bdEE6c9,
            0x676782764506eAf1aE442c48991f0FB43e81dB3c,
            0xCDc722CC2f47d95f9621F1cFbe867A09688d61a5,
            0xea45bc8E9a949e8C43bfb97F8553228a79be164e,
            0xF4A512F95E50ecc0926986C62E505ee7DAb50678,
            0xBf7d45a93F7bD4B0D89d047c73BC1Baae1516855,
            0x6fdC0097C07fBE223244aC7c7B4E568F7405B485,
            0xeE12a5EEB529344E98A1A5E6506BD1187cE9c43e,
            0x9897D3436511006458cfa467fe4372982FE6A94a,
            0x8aEF508Cb71d3aeb80Bf27646F3Fe125A0d9d6A4,
            0x9c18F43BC2C8166Cc59103EbDeC9d53f5B128cbA,
            0x33cccFD5f67e68E534DdcF51c6920a0a81230488,
            0xEA4CE13Df8866683F9461DCA8C002C0e76Afcc94,
            0xaA993A40732873c430d29Fb8D8016BF861aD0614,
            0x89D7653b9d8c3A6024032eA4094B16E24F1B7472,
            0x7E8897163C50beC16af612b5A26Ca7dBA9B602De,
            0x7193ec4504363fDB5229b09b3999cB563bA65a7D,
            0xC6342a3d298F2E6D9EB4304d18f9074C80e7C781,
            0x744FaA7B4bB5F3964946f15BC5B6FC76d2540973,
            0xd433fB5A905DF485e82D76b6E1F97ff69fcADA30,
            0x0354D96B1d150F9d9523747187648F97819F2e2B,
            0xA511462bB3f308F415189C8B503C9499Aaa8620d,
            0xA28CDd60bCF443eA117659013928cc56AEdc572e,
            0x50f6866be52085478DD2c7fE9c04443448293e5E,
            0x81Be3E734271F2102f3e411e898ad1A7467f59AD,
            0xc98a194D958572368c683e601BF244f2c9009443,
            0x0ea9fbc98126Ce00e69251542b6fC4691b3902Bb,
            0x0E1bE40f157a35207a20Ae9E2F76659461750E99,
            0xe4AfeeF97d66447b319e13b10B60d0470c406df6,
            0x97d78082DB138cb5AF0aA5C583048F28cF49331e,
            0x1De6B4954392F0BfFbB2615621a77F4C6CB046a3,
            0xcb6CcC1625e4946F4E08548aEeA02a55CdB6acCE,
            0xaA56A08B2E99D7E9DF274e362204f2683785d7DA,
            0x0F604cA62d28b5DF6121ed49A2F7C6f1F0B62826,
            0xD6e4f9693c05D8af67A40f1CcBc16318F6a5C524,
            0x606E10A0F38B936F86Ba98E11496CB5677952C09,
            0x1F0e2849cCbb64FB8C2333d3E8C754d516e1393C,
            0x4b6704ab2065315726905befBeC99Bd333536F69,
            0x3c93C61298743D136E7E8D9B23404CbD88E3261F,
            0x1Fa0c42a65B51ABdd384C1bba97992CA478DF4e7,
            0x17a9085B6782e9fFc03Cbb74A8a7EA37423ea353,
            0x7a364c669fdd11a6a7E6976FCd5Bb9Fb4b3C2782,
            0xF1Dbf0Ef1450B6F0cB03949C24e659343619fABD,
            0xF39b92a1fff76E7F400867C4c60D5d63d8EA9C4C,
            0xE198e1dD7988686d191ed201a3a1455Fe2fD92e6,
            0xAF469690b0D394c1541D7Bf9296D873EaDf1b508,
            0x1e7fC39b439af603A3ea41B0f50931E3078Ce19E,
            0x3bDc75b240aeeBD7A266eDf867B8aD5c30760a3C,
            0xF007D06D4B98eDf9da0C4Eef3A9C7Dcb9198d064,
            0x85706d3b49d24D444e1c5d4D65F2653069B64F2D,
            0x0965290539099054Ca569d4d534Ff52c1BE4870f,
            0x1cF54b443CecdA6e802806b675bB5d525cC1C3D3,
            0x7d50F334ce712A7A416B4Cb32D8a65CcaDC03e47,
            0xb17F784a673231c50B1700811Bd96fA900540a65,
            0x0b9e93E2C6d088A5d60a8eE30D377103207c7e93,
            0x2B051f34db329D72A0f4cF180A2dce1129E8EF02,
            0x54D031E6e03b4Dc8f8BB318FA5410c46aF063bfD,
            0xE05D996099C5e98F9A11eb990b8a3bf72fFE160E,
            0xa749AeA20262C6f50539753A7ee0823C7754906e,
            0xF2D0674979a1dDC7fB06C28F9Cf611D20BfE0466,
            0xD64935968435121A3E7174cEA694DE1EEa85faEE,
            0x379ad057C001e3C6796256A6629eA41a817adf4c,
            0xEbDd4029A6CFd3A91261eAE9c6557B07872bC6d9,
            0x68C1fF43B1a4C092e856190fa8319C9645A86b54,
            0xec3fe9a94D25FC5682028E7C324D9240C006a25c,
            0x5707be16804B94416f1f184bA6Cd8Eb5cad5a99B,
            0xa6B53E2597AA09A26e3F1A219096E18b8Dd0277c,
            0xD502d966f2B50e4C1768efFe99D4C7C90C3a7625,
            0x31eb40beAc067DAfF9af9930cE5Fd9fCaFA95714,
            0x29e7aaCA586F983cA0e713a0793D4f9FBf62aFae,
            0xfaa9E08a7D466525801CDE790F5C970c01CdaCB0,
            0x88e2f7C6792F10f430eD7E691103B5033eE2333d,
            0x24b5a94808282154387b6cc1d52e87C4fC4e0c70,
            0xeffdbe79DBe3Bdd7C1ab718486C4F822FEf3b1BB,
            0x31963b060d71ee24A6d458B75AA85E63b99Bd7fB,
            0x6792c2B39E4b11de4506F140b33F368089F4bB76,
            0xEd1A9E046bEdb13Eb801AEd473eA142e18Eb0a4b,
            0xeEE1eD12e3EdD4c42230Fee8daB8D46eF51d6bDC,
            0xcB7b8A1DBE163cB3CCff2fbc4E55BcA30cDA300A,
            0x78616Db12462D2236E4ce8F5861c299bc85a087d,
            0xf20C8002A384CFb0eC91971FFaEeD521d0cd241b,
            0x5922bAD12c8ba6a2EF7Fd1e8f99578719F6Bf6Ca,
            0xc0D17c952BC35e0310aAD44C2304380Fed057BDc,
            0x0F5e6C11C553BB43c47be504b7b06BDE8652678b,
            0xB6Ac36FEA087e4bF5f21f90Bf6b65f2596718ce5,
            0xffd05882f96e410a1CF293ECA26409DF0E7C866B,
            0x396923817FAaA87C86561E70e94ED88d584CD42D,
            0x1b89fb3FD8203ab92f8402C1942414739b9E9C29,
            0xE108bfa196efc9a09b105f14dF767DB4821714D5,
            0x23A729FFFD9F6EeC43613AA5b9e960c1c8d9f924,
            0x6030643A8425EBca5D77875868a602127E9878E1,
            0x283F18292AA24109D110689D63562FE633904F83,
            0x7b700aF8cA260C3Aa6816dd8BcD163c7621DAd27,
            0x69F34C600f58e833688c595929ddA89A859e9863,
            0xD4220BB843E35d0DdD1ccC035E9A1b0e5216620f,
            0x0AF829e0F7A59AcEd231652Ca024CC0E729e7b5a,
            0xF3E93F069C34052e7f1A1bc671EFc6485ccF7DAF,
            0x9b84a019CcaD110fA4602D9479B532Ff7D27F01B,
            0x0e89d51dD6b2b21e9bE790B2BDc92bB881969F39,
            0x0A5634b922C1264501FAcA8EfB667018998D1a8f,
            0xB26bb33099682cfB3d1b8127526bc7d91eCdef21,
            0xE2d9E6605f157EE2400CAa361b21cb4c4856afB2,
            0xBc28C1D6Dd33822F647b1858e5BB137917E911C7,
            0x6De9393274b9f5ffb6f3b09F9747a519320D6959,
            0xF45C67deF8586F064A7fD343eB9CB906A02e855E,
            0x2FB0cC2474513f61E299B84068fACbd0f841AC04,
            0xFb2CAE586615BF43D04c33CCE2355F3939C87EFC,
            0x2B4e94f5F03fDE04a404959D5a920848b7633faB,
            0xE6745b96B70FfbFbd4aE19b9E3cB4bA23989cD46,
            0x40a8d390584A3BF64e74E245bF0506F244B13a1D,
            0x23Da567cf9A56D6946028f6455DFf4c2Ad79aaF0,
            0x0A91D4187977Ba2e74d78DEEd3F3b5a8077F7d80,
            0xbd4191E4E6Ce30B0C4A14D62548D35a6dF93E50E,
            0xc5e162D39fc0A92c6Bec2E18603e44aeeE56d6B5,
            0x239264bF4647C70E84380E13844A150c1A1caCaB,
            0x4Fb617415ed31c54684d6bAcd56db55FeFb0678c,
            0x76AEbB93eEbE2e8b83A44242cb370DBb709a47F8,
            0xdC72F401760A8068E8D9B0caCcEDf8C5801B0711,
            0xb77b2cddd60CFd880583294c2f71bf128d55Fa56,
            0x64Af0FEa7146B28E29E2C87737d008785163047d,
            0xd93Be0194b25ee0E61Ef3eC8523a49f822919379,
            0x3927F8F4B98D89821700BB1a8D1ceb066113d178,
            0xf51722Ca40BeA1e21534DF9cc22dC5903D732f16,
            0xdF93060B443EFDfa3f15b7CC2ab144A6950087c3,
            0x9c1Ac11D82F3D423E69F68009C36796cDc5AE5E9,
            0x529f91738Eb50b30E09ad12627AEC5764ECEB1eE,
            0x724524e4F040F71da7b3B93cf1c2Af904c371D7e,
            0xCA7080A463706725E1632145cfcc7dB53eD25f96,
            0x18Fc8940309C4F58806A67C101aFe0d3bD16E424,
            0xD883290c1F206F7F951AdE8cC80b9493C1170A53,
            0xe0B55b2E216dd2490d4980e104318a7f7bEcC9a1,
            0xE6099b8b93C53ff17913F0b1Ed134cA674Ef98C4,
            0x6529F517bE7e2EE56AD948798c3c4C59F362c628,
            0x6cB83B3923A55e0Fb5Dde37E29c720B926E142EA,
            0xc293bA9130B6F5db3556E3798058ba7BEA8Aec6F,
            0x511fB913eE83434F5Ac37F2246eD8BEC17959699,
            0x9Edd069aCcf979F744CE3FBBebf54507eAD29a21,
            0x546030a537F366DB5E8031D960832160fd3162Db,
            0x2c0b6D848eFb1d0CB3541e9944830D87CCA93B00,
            0xd354b51CA68030D16CAf91177b546c5ebaab0277,
            0xe05006Dc1369ef6BBcFd696A38a573C8C28A8E7C,
            0xB7f08c3bDAdE5f2562d561502F56A976fE3E03c5,
            0x824c8b516B91eCDB33fEdb9C9C7eDF2c741Eb277,
            0x1540BC00a9Af63a5e08CF8B48B71F41A06e8C0bf,
            0x41a1e76edAC29BFa2039Cf1E91f93e2210D369C6,
            0x7E28FD69635bf4ab6246f58631123270e9528413,
            0x9F97bc4Cd56Bb4D14Fa0302f7dDDE02241011eD5,
            0x2f788b3074583945fE68De7CED0971EDccAd2c20,
            0x519B8faF8b4eD711F4Aa2B01AA1E3BaF3B915ac9
        ];
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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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