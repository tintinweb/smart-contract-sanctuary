//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

contract PresalePush is Ownable {
    using SafeMath for uint256;
    IERC20 public MoonCoin;

    mapping(address => uint256) public presaleTokens;
    address[] public presaleAddress;

    uint256 public totalSent;
 

    uint256 PrivateSaleTokenRate = 159642401;
    uint256 PublicSaleTokenRate  = 141904356;


    constructor(address _MoonCoinAddress) public {
        MoonCoin = IERC20(_MoonCoinAddress);
        addPresaleData();
    }

    function getTotalSent() public view returns (uint256){
        return (totalSent);
    }

/*
Important notes: first get coins from meme contract to here through transfer function. 
In transfer: reciepent is presalepush contract address
amount: it should be mentioned in whole with 9 decimal points it self. So to do 1 bill : enter: 1,000,000,000,000,000,000
Then use this contract push call.
*/

    function addPresaleData() internal {
	
	
presaleTokens[0x01C65CD29C2297B8062f45D190e9b59C4A287Db5] = 1140000000000;
presaleTokens[0x0429de8B3Fd17e553d5C6830301f756e07EEf068] = 948000000000;
presaleTokens[0x0783FD17d11589b59Ef7837803Bfb046c025C5Af] = 30000000000;
presaleTokens[0x0982D27AE0D8e4e614441B97597b3552a406953A] = 86394000000;
presaleTokens[0x0a680558F6cCaA0C3d5a675795484E45aC969D5b] = 125000000000;
presaleTokens[0x0aCBdF7a9ec91a9dc59944658Eb4c6bf99c6c037] = 120000000000;
presaleTokens[0x0AE4A76105e8646D401A4FbA206BC5a581dEd071] = 1308000000000;
presaleTokens[0x0b40fEe81742239a79de229802ad946fa25fc317] = 60000000000;
presaleTokens[0x0Fc58F8F1b078A35A69C951E3E8AE477fb5FDEf1] = 83300000000;
presaleTokens[0x110bB5F1AE7224e92C07AD7d46f73a6eF7c658F7] = 28680000000;
presaleTokens[0x12505b31F8463212b7Ef1725A71617c6cd29DD58] = 118660000000;
presaleTokens[0x125A4E781228eBeE6c55d23103562B084cAd25B0] = 236000000000;
presaleTokens[0x1262b5826aa0993aBC5494C9b1Fe4ff5a46cbD07] = 118000000000;
presaleTokens[0x1572Ca9ef546072a0759c80428775656c379B550] = 11900000000;
presaleTokens[0x15c8B4e98D4C7D38Af534672Cb805c6469414537] = 60000000000;
presaleTokens[0x15eb1880C4dA06705CE54855E5ee025241c2fbf3] = 360000000000;
presaleTokens[0x1653914B2B0e4346b100243e2A51Eadfe442eEc4] = 120000000000;
presaleTokens[0x166726ae0B0D93a011e50c1CBdBbaa39dC2B2Ea2] = 119500000000;
presaleTokens[0x1869d0b8eE03a7c806bdb72aD4274FCf68505a9d] = 1200000000000;
presaleTokens[0x1873B6131b60A4119a3f804381Bb7C5601958A39] = 480000000000;
presaleTokens[0x19d337a4A175dD54B112D9259a5babcF3326ED5C] = 13200000000;
presaleTokens[0x1A2B44A3faC5405D54E24D6Da8D8286F88951F27] = 180000000000;
presaleTokens[0x1Cfc7eb1cdD78CAe3B4632fe1f9af7ba9246B0b8] = 486591000000;
presaleTokens[0x1F2b3CF0B8D0261219A188E5c434307284967459] = 273000000000;
presaleTokens[0x2017d41466878F45B468fAe8F23ECf5D70cDD5B6] = 12000000000;
presaleTokens[0x212c5AE33F8668B700C62EE90b146f043a1EAeE8] = 120000000000;
presaleTokens[0x231D26DEE15429869E738918B34EBfD905a5Af01] = 1121265600000;
presaleTokens[0x241CA6E4a328556400cFbC08D5E930CEe49C1843] = 48000000000;
presaleTokens[0x25358A3F01904F11AC068FD59e1BD23d7AE0336D] = 30000000000;
presaleTokens[0x2556aBe961126df0357e73fEC8B7acE664504A8B] = 36000000000;
presaleTokens[0x26602aB59536b285A335005f2d54572907df03c8] = 360000000000;
presaleTokens[0x268E19388D34A7cFf57b0f757Be9c4a66B923162] = 59500000000;
presaleTokens[0x27429CAaF89a50354Dcd285557593480B5b0Bf13] = 12000000000;
presaleTokens[0x279A71c73fD6944eAC6a8215b8945A17C578087D] = 36000000000;
presaleTokens[0x28Eb9a306183Ce400fe3c5ec2C2C379D2bfd96c0] = 119000000000;
presaleTokens[0x2B11FC8e94F49AA44e9fc9f3F990388c98813d75] = 67235000000;
presaleTokens[0x2Bf64CC1f1958eE4232886d2A8d2E55Fa642A5AC] = 366400000000;
presaleTokens[0x2BfE4779A613940166539dC3e3284747638B6543] = 12000000000;
presaleTokens[0x2E33B57B708a2Fbd6A62610E60e421057c24596c] = 168000000000;
presaleTokens[0x2FC36bAAC681f901Ce8BC67f9388357Eb1114Ef7] = 119000000000;
presaleTokens[0x304bfeB9C4a75287ebA57DD3A752d52C2e95E5a9] = 36600000000;
presaleTokens[0x30Ab00E624C10bE9690b41eE85c04907F63fBF91] = 24000000000;
presaleTokens[0x30d98b688f6DAbcd0A12849ee4AE1Cc047b49912] = 11800000000;
presaleTokens[0x316e19608542ffde812945d2052A37A97A2BdC75] = 60000000000;
presaleTokens[0x351319EFDCc2D11150D8c6bc112c05B5BDDe9D93] = 238000000000;
presaleTokens[0x36a40e3319979587CD421A97d28AC1FB63eE22ae] = 11900000000;
presaleTokens[0x36EadB93a0dDf11227e6bE8F04Ec158917193F35] = 11900000000;
presaleTokens[0x3790837fBE7Bb168A1Edb80E12d4321Ee0f63FEb] = 744000000000;
presaleTokens[0x37e014215902BA306dA13464A613F2E38578A6d0] = 12000000000;
presaleTokens[0x3849845Ea99Ad9eF03FFf671d13b376639cf3fb5] = 24000000000;
presaleTokens[0x3aAb0746E776bFeE231707F2A470cCebE189eD80] = 262800000000;
presaleTokens[0x3cCD3A52a1C4495dF4F934362E34bA74409044cf] = 156000000000;
presaleTokens[0x3Ec4cF4C792a1c6bB62B47A7f9C7F840041B4d6e] = 33600000000;
presaleTokens[0x3F8fB73f42d7e2E44Ccd2713EaE17E23D2265DbF] = 119773500000;
presaleTokens[0x3FaCbbcFf75766ea860dCaB4B687DB70d4477EC1] = 43080000000;
presaleTokens[0x3FccE040026C5eB73cC437F2633403Bda735Cc21] = 47600000000;
presaleTokens[0x40530efC3EC8D7571EC240C559AfF5A98DF4c39d] = 45300000000;
presaleTokens[0x407AD0f23f5Ded868C5D10569bD73b06261F5556] = 53550000000;
presaleTokens[0x40B0A18B6A47746Ef7b8b76bD481C6cff7bc23F3] = 540000000000;
presaleTokens[0x4464e71B50a0a604E4d2e7DF14d76bFd462D0fdd] = 180000000000;
presaleTokens[0x4623539B49D6a46872d056b295671E671D8877d8] = 37500000000;
presaleTokens[0x4631b466989CfE33113a43cE62682aCb6d550df4] = 144000000000;
presaleTokens[0x47549a4A188B4f66981791E994f8faA5490CA162] = 11900000000;
presaleTokens[0x497206C990db435DB0f52CC25bbC1d322b5c7140] = 24000000000;
presaleTokens[0x4a7A07EeBFEe63FD011bd1280395c52E8b1E8e0C] = 23800000000;
presaleTokens[0x4AF83A7c0aC89b54F3A8dD3BCEEEEd9A62bA4f9f] = 600000000000;
presaleTokens[0x4BDa8c8503156cEDB900297258c6AC572Ae45bf0] = 11900000000;
presaleTokens[0x4E9083294410BDb63F3766513ef5333E31944230] = 120000000000;
presaleTokens[0x4ea7766a1559A8c76dCC7b1E2914c5687FcCb71f] = 501060000000;
presaleTokens[0x4EaCF19bEC5912E3608FD41f6f53C439a6366832] = 1001980000000;
presaleTokens[0x523387Ea8f9b57C23A27e755bfd41ee8aC74a3eA] = 14400000000;
presaleTokens[0x52B52D5C4eB154161b51c52d5D021bf020a4ADcc] = 30000000000;
presaleTokens[0x52CDc472A31A462589cF8190087F54b5AB69d2B5] = 23800000000;
presaleTokens[0x551e39586e4f1Dd9997E0Ec83c2bB30C8C1eD643] = 298800000000;
presaleTokens[0x55517886630BE66523F2C5C027C490166c656F37] = 1798310000000;
presaleTokens[0x561a4D5D24Df36020d721aefeb34B890EEA5Fe5D] = 120000000000;
presaleTokens[0x563178f7E9658B9ba5E9B44686f22534E7C5134A] = 240000000000;
presaleTokens[0x5631ebb2C6f63EAae9a4CD676939a00b58aB1FCd] = 12000000000;
presaleTokens[0x5705309c95273D14a08e526F5EfEa11Ab4bB06fA] = 12000000000;
presaleTokens[0x5729a47E4377a78b03502A51b5dfbbDD8f2fa7C2] = 33000000000;
presaleTokens[0x57CA263C4539fbE35dA41FbF2257be5E76A91Cf0] = 60000000000;
presaleTokens[0x586706ee53b33FFCEc6b2993b22d4b87769D98ED] = 535500000000;
presaleTokens[0x594AB9eBa797d5A977747125912B81F4aE8536C7] = 23800000000;
presaleTokens[0x5a111BA98ab387aAB4Fa7c7284DE7746f94784A5] = 60000000000;
presaleTokens[0x5A72aEEB4d435413323AD7e76FE72318D641945b] = 240000000000;
presaleTokens[0x5B7c05424a6F0A499404F262c5c5EB407e882396] = 53040000000;
presaleTokens[0x5Bc5579Fa5849F08fDb560C3DB2683C7C430874B] = 42000000000;
presaleTokens[0x5C05b3A300602b6a91e58839fBF7e4EE2c5525c8] = 18000000000;
presaleTokens[0x5D3766bf86329B65b7FAFC7137e2a954AffA3bce] = 531700000000;
presaleTokens[0x5E3bBe7eEC540CE19a519570d30fCb074349CB2f] = 11356200;
presaleTokens[0x5F5ccAa7F4b32F2B47E876F05C29911622ffC1CA] = 236000000000;
presaleTokens[0x5F81e51903031555551F771c1276a7d67CBB0a9A] = 11900000000;
presaleTokens[0x5f8568aD07413Eb409247eE2A31C33c0ce82f19d] = 35700000000;
presaleTokens[0x5fbB9e41945dbD9D0fE02914247864bEa52f15d3] = 39600000000;
presaleTokens[0x5FBbC3F1e3B09b1416E14dB73Ca338e9728aF4F5] = 18000000000;
presaleTokens[0x60996B71CC68cEe871f2B34eCF457A3b574fa744] = 1680000000000;
presaleTokens[0x62808118c4110644b2A9f965Cce10A1E7282aE77] = 23800000000;
presaleTokens[0x6296e92cE1027d93F53Bf784D42195dD0a6Ab7d3] = 42000000000;
presaleTokens[0x62acDaa04C322D66138DC7E0A2D91106b0658AA4] = 66600000000;
presaleTokens[0x63F06788670D8FE1e8994f88029b611B7A63821A] = 372000000000;
presaleTokens[0x66A160B8fc1b30521dC8aC82A40286614D717EdB] = 59500000000;
presaleTokens[0x6722A73da2f233Ac009E97991Dff9929A0Ed58f1] = 34800000000;
presaleTokens[0x68785F00e121A25c00857726A4194Dd54494d432] = 72000000000;
presaleTokens[0x6B31EecCd068a97aa643D58fe7F4d98eA70d5271] = 12000000000;
presaleTokens[0x6B53a40e413E9980b6D17c9D6Cba0687ddCb1B51] = 12000000000;
presaleTokens[0x6C4f9013ff46329C28a06BF9623162421DB5f343] = 238000000000;
presaleTokens[0x6dc175B7Fd8fDE4fCD3BF531AEA7e181ea68657B] = 1104000000000;
presaleTokens[0x6EEE51ee0E3aF41360bD45d6C9F687EbF458a224] = 320100000000;
presaleTokens[0x6F3AB92eCb078E1Cf892Cea10AB99997750411d9] = 30000000000;
presaleTokens[0x70dbd0379E0EFa1e03258eeD0E85E349Fa2CF021] = 132000000000;
presaleTokens[0x71961AaB51dAe6351d69d5Da13A05dCB28d50f5C] = 118000000000;
presaleTokens[0x72c376a44903c664b690D1ecf786c6a8497B03D5] = 41650000000;
presaleTokens[0x72f22d8977020D4ad8170f420E5991cbe9fE7D42] = 178500000000;
presaleTokens[0x73735652c3BeBE6C42723a30cDB8678eA58cfDc7] = 180000000000;
presaleTokens[0x73898CbF1Ec904FEeDe00886068FFE2DB69a3B7D] = 1283000000000;
presaleTokens[0x73EA5ACd464037330004AD9b50B3006ef2Ac6e2e] = 119000000000;
presaleTokens[0x76176615C5E06705BdADC40Ff938a39fE762584E] = 500002300000;
presaleTokens[0x76E4a671a6E1A062DC213A70327AE283900F8EC2] = 59500000000;
presaleTokens[0x78CA7Fc6D93c3dC62d498e7eFe7712a6CcF61343] = 12000000000;
presaleTokens[0x78E242C8099f97DA3b5bf8f8718325a83C7DeA5b] = 240000000000;
presaleTokens[0x7aC770212E9AD22ae9053FbaD61CfDabfc4E07Bf] = 48000000000;
presaleTokens[0x7BC89e312d866AA7737Ece63204C2D318606CE2F] = 239674000000;
presaleTokens[0x81617aE87Ee20d4C5392b1B83B9525320f97EbBC] = 31200000000;
presaleTokens[0x81F735eD0587170205E59675d25Bf20b64553241] = 30940000000;
presaleTokens[0x8310F1EbDEd39e8A08c195b052a08444e2a75336] = 404400000000;
presaleTokens[0x864DB360581F8f1f833D56f97876919eA791DB2F] = 119000000000;
presaleTokens[0x86d42B9869E008db1Be11E17Bbe35eAEBe031E38] = 235200000000;
presaleTokens[0x87D4448724DfbA4cB8b0b14E1a6bED9725109bA6] = 153400000000;
presaleTokens[0x87f1Bc647f18A02540B1e3075621aba96E2b1d36] = 18000000000;
presaleTokens[0x884513ddB81Fe5FE2A7323A6ca98a0E7e70EDB21] = 462000000000;
presaleTokens[0x898F8495975168F7894f1Aca9521372Bc8a7E292] = 357000000000;
presaleTokens[0x8Bae67B4a6D6Df32096dF855bc55b7cF4d2DC11d] = 101050000000;
presaleTokens[0x8CA270B9af47482D71c5631278A65e270Bac02a4] = 12000000000;
presaleTokens[0x8dd808910856DAec5522C4dE7894709687CF0019] = 25200000000;
presaleTokens[0x8fd3db07f7e7Eb03B00C090E46b7aD4842234B0E] = 238000000000;
presaleTokens[0x91B92bbD2332A4564f205D996dc505D4457221fa] = 19200000000;
presaleTokens[0x91d28bf8FE216968D57E2F0204b11D21D116f755] = 29750000000;
presaleTokens[0x942C6B580af6B2A53e3f93C345e79cccE69531f8] = 23800000000;
presaleTokens[0x94DEbC57081C4c58Dd69F4DFCE589b82fc3C2866] = 714000000000;
presaleTokens[0x94Eacdd1810E86D5D3C718B96D7A9CEb7C55c578] = 120000000000;
presaleTokens[0x954749DD5b73Be3a63E1c529165Ed14FF64192d7] = 36000000000;
presaleTokens[0x95Bc77a5b4D46218c546ba35EfD3f80cACa73D55] = 119000000000;
presaleTokens[0x95C6d0f794b9c629C94b1Cbd9bbF4c290D326F99] = 120000000000;
presaleTokens[0x98a84DA0F285F3Bd4d9319a8822c44290CDb8D07] = 840000000000;
presaleTokens[0x98d80eD82a3e68157139E2d9Ea6b137e9a358f7D] = 78000000000;
presaleTokens[0x995d4C14061690758332E765166fBE123bfd2642] = 35800000000;
presaleTokens[0x99D7a3a24c947Cb65510c6Ca48AD2c5a27f20B43] = 18000000000;
presaleTokens[0x9b67c18e5508EbD71972d22f0e202E6c967bE760] = 11900000000;
presaleTokens[0x9C3950b6c38f86D0ad356f461E287e5A80798aD1] = 23600000000;
presaleTokens[0x9cBe889E93ab481D78cB8Ea27C97e1eC2Cfb0213] = 120000000000;
presaleTokens[0x9d137f55A278Cd591C1Fa6aAC92643E4CCFC4778] = 12000000000;
presaleTokens[0x9e01B67B83AA360076dE9803FD68Abd07F95B07f] = 23800000000;
presaleTokens[0x9E06e29A9c0a664EDA2C7da8B405B299E632C3d8] = 48000000000;
presaleTokens[0xA4A2d8102a6f5b95e6FaCFf48637959e83D2F1Cd] = 54000000000;
presaleTokens[0xA59Dfc6BAce0bFfB63BACe2F3DE22d8a2B5Ce1B2] = 120000000000;
presaleTokens[0xA6Ff79150f1743abd42e804a6B4102E87c20DfA6] = 23800000000;
presaleTokens[0xa711A29C5824D2C3cE71a4e9BBCb10293e8E95D4] = 1188000000000;
presaleTokens[0xa7637F14E3fF3762601aA032d1603a86Ba0Da592] = 348000000000;
presaleTokens[0xA81599Eac76045fce181Ae0D83A5843C39867AD4] = 23800000000;
presaleTokens[0xa943A14Dda16a964346cBe9aA5253F7Ed8c46598] = 112238000000;
presaleTokens[0xA98D5098CA8DF66d2C3eE5a73F0ac2414F4D710c] = 44400000000;
presaleTokens[0xa9Df23De8369d4784a169a4CAcDcc4A9fB7D5775] = 472000000000;
presaleTokens[0xaCBFF5286F4cA050572B18d704E096a6aFF8827f] = 24000000000;
presaleTokens[0xACE4cB4F5f093FD25FDC29D56Ab36df2Bd309B5E] = 120000000000;
presaleTokens[0xAFC1a5cB605bBd1aa5F6415458BC45cD7554d08b] = 120000000000;
presaleTokens[0xB20bF6D7f60059dd5dE46F3F0F32665a259ea6C0] = 178500000000;
presaleTokens[0xb392AAAa7a33B876D693b1Dbd771D1e095a7d11F] = 11900000000;
presaleTokens[0xB54A2CF4B7A204b2a5FB0915BA439a40ad2d1481] = 35900000000;
presaleTokens[0xB681ddC6409C01Aef47D9c5C19B2b5aEbff270CF] = 26568000000;
presaleTokens[0xB68e99da23a3B29C36297fce9F78EB3070466B26] = 480000000000;
presaleTokens[0xb6A58AeA67Feb8695B00a3ADB05B48634b67aeCc] = 142800000000;
presaleTokens[0xb7BbEcE8D4454b0F988FDDf2f20409014cdC50f8] = 24000000000;
presaleTokens[0xbaf8E77d45DbA841092f66aeF6A809533A7faa7D] = 511700000000;
presaleTokens[0xBb48d9B48274BC62b2A7D24362C05986Bb7205B2] = 696200000000;
presaleTokens[0xbD9B88bBbF1FD8BEd5C29b103E1ce84cC6f3d863] = 120000000000;
presaleTokens[0xbDBacFC7b0584e02B6e3f28200216529B7dc7A10] = 48000000000;
presaleTokens[0xbEFFc39C91542C7d42407Bbbff984E950DBA2904] = 1320000000000;
presaleTokens[0xBfE23452D71E66064DE21c757392A34A2216DEe5] = 12000000000;
presaleTokens[0xc072f3da6cec7947FfEcb1f5Beb3499045458BC1] = 120000000000;
presaleTokens[0xC0aE40249B6e58b55DCa0C8e0707b3FAd04b4b33] = 180000000000;
presaleTokens[0xc0f0A6f5f76FA0dc892942845F1a500690ACf0d1] = 60000000000;
presaleTokens[0xC2fc360Ebe63B52c67371788946D7ba482a24Ac5] = 200634000000;
presaleTokens[0xc3249C87d16eBca335a76AEF4DeDBE32736d1f1A] = 51960000000;
presaleTokens[0xC3b93D3A718F96141d8B9C98E7dfA4eeBb685840] = 118000000000;
presaleTokens[0xC559829041f295BEfe37fd4AFCc7d47a4998d4ef] = 24000000000;
presaleTokens[0xc5B7a3d3d230F5115233Bc38107178c93E984C5A] = 149250000000;
presaleTokens[0xc7719FEc0a61F17cc790fc33B5c1c6a78C00F1eA] = 47400000000;
presaleTokens[0xC88CC65A0022bAeF28c36A4f415687d566E8098F] = 119000000000;
presaleTokens[0xCb8926180FBa3AdBDf124D5eBf1D6E9811548EB7] = 178500000000;
presaleTokens[0xCC8b0d940F3C450593b06e92e74C96b7908765f1] = 11900000000;
presaleTokens[0xcC9dd673259F4171116949bB658379fFA9b8a7BD] = 24000000000;
presaleTokens[0xcCA0fFa560Ee5Caf204a8106e291719b2348C633] = 612000000000;
presaleTokens[0xcCF54ABE19255907B02Ea5DDA8eD6D778Bdd041a] = 238000000000;
presaleTokens[0xCDeceeAA985Aef51A45C79418F3EC9254C22e680] = 119000000000;
presaleTokens[0xCE0dc5cCfE9B2240AFb0246c18b7649AAc31eC83] = 35700000000;
presaleTokens[0xcEE50E870565DC60091e1D2cD16f25384553DA48] = 54000000000;
presaleTokens[0xD064999B09E553Ef14a5cDF28b4E1e9160234c46] = 180000000000;
presaleTokens[0xD3b210905B05BB356CD9F5BE2CAeD44E46424437] = 119000000000;
presaleTokens[0xd59a14Cb89672ad53752670f67170E2F23d883fD] = 201840000000;
presaleTokens[0xD6f2a25263864E82f41590CcA7044208ed4db090] = 378544000000;
presaleTokens[0xDA147Fdf35f892e16C8da7484E724e419d02Ac3b] = 119000000000;
presaleTokens[0xDA26aD04579e6245AfD89530B7157895750025Fe] = 416500000000;
presaleTokens[0xdAC6a9c767E949B741D940238B301476e02eF1d9] = 120000000000;
presaleTokens[0xdb11D879878DA3e4534afce697a2baee04D75b60] = 119000000000;
presaleTokens[0xdC39Fd104414619C2EBCF13a19e14ED98195FFCF] = 334800000000;
presaleTokens[0xdCc77FD7b2B0BD9376C6A77567f42E8a0Df8f260] = 23900000000;
presaleTokens[0xE0c83B19a59A13F1E45FaC16efc4C0101258Df60] = 311000000000;
presaleTokens[0xE23Ae6aA3730e0B159bA9Ea9B1d0d28c842f4BeE] = 18000000000;
presaleTokens[0xe241f2c344281e1e9fe5f23E139326eF7Db60564] = 134470000000;
presaleTokens[0xe29CE30A957A447027a171c7CFDAf3D255F32a9F] = 59500000000;
presaleTokens[0xe341d077a0cfba74f492cd0d06F6be3b7C0aF1C9] = 540000000000;
presaleTokens[0xe42CfA6263Ed1511c864A5E6af67ADB66c766ED8] = 240000000000;
presaleTokens[0xE4844d2171d2c3A6BBc5979904e61f8b6a680f6a] = 12000000000;
presaleTokens[0xE4Cc46c35C391439c6Ef139295d2cfbA34EA4A0E] = 342200000000;
presaleTokens[0xE69a6159094Ae2A467175271a31C68a658AAc73E] = 26400000000;
presaleTokens[0xe726849Cb67765aA6E18D1a3Fe9F371B02061064] = 60000000000;
presaleTokens[0xE75934A1F2921F21d07663bE760107a958fD8c30] = 59300000000;
presaleTokens[0xE8E2d703A26ecD9E98C8d4792592403FA9E57947] = 106840000000;
presaleTokens[0xE99f945574F09a246be455b8AE4DE80c9d3677c3] = 20400000000;
presaleTokens[0xeA0a1ce786d023AbF387028E578a2d7536eeA483] = 23800000000;
presaleTokens[0xeaCF7aC996D2e31F19736F36d0F693A373221DeE] = 59500000000;
presaleTokens[0xEB5cd7F76401FF5fB96AaD009b9617961Ba0e8a6] = 12000000000;
presaleTokens[0xEc964b6c91abde8f583F744de48da87b9F43035E] = 60000000000;
presaleTokens[0xED4855E0636265487d32257A790dc68378ADd575] = 12000000000;
presaleTokens[0xEF108D51cb6BdB039234631777feb377aec636eB] = 11900000000;
presaleTokens[0xEf3BB8e75E4d5828dE16F38D8d2832704122034c] = 288000000000;
presaleTokens[0xf07cF12b40367BB500578a2AD20Fa38b796775ca] = 12000000000;
presaleTokens[0xf0a0b569734A74e20A2d5F7f2F9D042c4930c686] = 162000000000;
presaleTokens[0xf0B1FE283CD9BfABa76378Bb6cA0E541ba1226F9] = 24000000000;
presaleTokens[0xf0F31Ac0cd7179c13c030CA692954dD991bb9E31] = 60000000000;
presaleTokens[0xf2f4D8e3A65920E3Ab7334e4E0E93741346B4d4a] = 180000000000;
presaleTokens[0xf2F90FE3eE6a0C7E77F08aa9B3F96dF0D11dE99c] = 131400000000;
presaleTokens[0xf369c84fE46e80b8FE50147E2DC995E48D2E03ED] = 35700000000;
presaleTokens[0xf5Bdb24adc2534c9BC91313252D292738312f2D9] = 54000000000;
presaleTokens[0xf60ea272936489126C4329767A9f4922A99610A7] = 356000000000;
presaleTokens[0xF79E69F8c4165A03537BaFb18800F233d472Ce32] = 618800000000;
presaleTokens[0xF876A7C57054460282f4Ee1B5528c9d170026907] = 1200000000000;
presaleTokens[0xfb4a4b24117eE72342786449457adF8BBe718231] = 24000000000;
presaleTokens[0xFd5A5D8f76371D8a481482c7F8BbFB0f1dE4D4D6] = 166600000000;
presaleTokens[0xFdbbA04493b474C6De0E0e43fF110C0185Af7643] = 11900000000;
presaleTokens[0xFDFb8274435eB53EDcbA3176b570B6d5Fc0C1108] = 283200000000;
presaleTokens[0xFf6f33768Df7A93F983f0a9C96Fa24d4890E1677] = 236000000000;
presaleTokens[0xff7ab435fa838755b97782E850735355B982B2EF] = 185316000000;


presaleAddress.push(0x01C65CD29C2297B8062f45D190e9b59C4A287Db5);
presaleAddress.push(0x0429de8B3Fd17e553d5C6830301f756e07EEf068);
presaleAddress.push(0x0783FD17d11589b59Ef7837803Bfb046c025C5Af);
presaleAddress.push(0x0982D27AE0D8e4e614441B97597b3552a406953A);
presaleAddress.push(0x0a680558F6cCaA0C3d5a675795484E45aC969D5b);
presaleAddress.push(0x0aCBdF7a9ec91a9dc59944658Eb4c6bf99c6c037);
presaleAddress.push(0x0AE4A76105e8646D401A4FbA206BC5a581dEd071);
presaleAddress.push(0x0b40fEe81742239a79de229802ad946fa25fc317);
presaleAddress.push(0x0Fc58F8F1b078A35A69C951E3E8AE477fb5FDEf1);
presaleAddress.push(0x110bB5F1AE7224e92C07AD7d46f73a6eF7c658F7);
presaleAddress.push(0x12505b31F8463212b7Ef1725A71617c6cd29DD58);
presaleAddress.push(0x125A4E781228eBeE6c55d23103562B084cAd25B0);
presaleAddress.push(0x1262b5826aa0993aBC5494C9b1Fe4ff5a46cbD07);
presaleAddress.push(0x1572Ca9ef546072a0759c80428775656c379B550);
presaleAddress.push(0x15c8B4e98D4C7D38Af534672Cb805c6469414537);
presaleAddress.push(0x15eb1880C4dA06705CE54855E5ee025241c2fbf3);
presaleAddress.push(0x1653914B2B0e4346b100243e2A51Eadfe442eEc4);
presaleAddress.push(0x166726ae0B0D93a011e50c1CBdBbaa39dC2B2Ea2);
presaleAddress.push(0x1869d0b8eE03a7c806bdb72aD4274FCf68505a9d);
presaleAddress.push(0x1873B6131b60A4119a3f804381Bb7C5601958A39);
presaleAddress.push(0x19d337a4A175dD54B112D9259a5babcF3326ED5C);
presaleAddress.push(0x1A2B44A3faC5405D54E24D6Da8D8286F88951F27);
presaleAddress.push(0x1Cfc7eb1cdD78CAe3B4632fe1f9af7ba9246B0b8);
presaleAddress.push(0x1F2b3CF0B8D0261219A188E5c434307284967459);
presaleAddress.push(0x2017d41466878F45B468fAe8F23ECf5D70cDD5B6);
presaleAddress.push(0x212c5AE33F8668B700C62EE90b146f043a1EAeE8);
presaleAddress.push(0x231D26DEE15429869E738918B34EBfD905a5Af01);
presaleAddress.push(0x241CA6E4a328556400cFbC08D5E930CEe49C1843);
presaleAddress.push(0x25358A3F01904F11AC068FD59e1BD23d7AE0336D);
presaleAddress.push(0x2556aBe961126df0357e73fEC8B7acE664504A8B);
presaleAddress.push(0x26602aB59536b285A335005f2d54572907df03c8);
presaleAddress.push(0x268E19388D34A7cFf57b0f757Be9c4a66B923162);
presaleAddress.push(0x27429CAaF89a50354Dcd285557593480B5b0Bf13);
presaleAddress.push(0x279A71c73fD6944eAC6a8215b8945A17C578087D);
presaleAddress.push(0x28Eb9a306183Ce400fe3c5ec2C2C379D2bfd96c0);
presaleAddress.push(0x2B11FC8e94F49AA44e9fc9f3F990388c98813d75);
presaleAddress.push(0x2Bf64CC1f1958eE4232886d2A8d2E55Fa642A5AC);
presaleAddress.push(0x2BfE4779A613940166539dC3e3284747638B6543);
presaleAddress.push(0x2E33B57B708a2Fbd6A62610E60e421057c24596c);
presaleAddress.push(0x2FC36bAAC681f901Ce8BC67f9388357Eb1114Ef7);
presaleAddress.push(0x304bfeB9C4a75287ebA57DD3A752d52C2e95E5a9);
presaleAddress.push(0x30Ab00E624C10bE9690b41eE85c04907F63fBF91);
presaleAddress.push(0x30d98b688f6DAbcd0A12849ee4AE1Cc047b49912);
presaleAddress.push(0x316e19608542ffde812945d2052A37A97A2BdC75);
presaleAddress.push(0x351319EFDCc2D11150D8c6bc112c05B5BDDe9D93);
presaleAddress.push(0x36a40e3319979587CD421A97d28AC1FB63eE22ae);
presaleAddress.push(0x36EadB93a0dDf11227e6bE8F04Ec158917193F35);
presaleAddress.push(0x3790837fBE7Bb168A1Edb80E12d4321Ee0f63FEb);
presaleAddress.push(0x37e014215902BA306dA13464A613F2E38578A6d0);
presaleAddress.push(0x3849845Ea99Ad9eF03FFf671d13b376639cf3fb5);
presaleAddress.push(0x3aAb0746E776bFeE231707F2A470cCebE189eD80);
presaleAddress.push(0x3cCD3A52a1C4495dF4F934362E34bA74409044cf);
presaleAddress.push(0x3Ec4cF4C792a1c6bB62B47A7f9C7F840041B4d6e);
presaleAddress.push(0x3F8fB73f42d7e2E44Ccd2713EaE17E23D2265DbF);
presaleAddress.push(0x3FaCbbcFf75766ea860dCaB4B687DB70d4477EC1);
presaleAddress.push(0x3FccE040026C5eB73cC437F2633403Bda735Cc21);
presaleAddress.push(0x40530efC3EC8D7571EC240C559AfF5A98DF4c39d);
presaleAddress.push(0x407AD0f23f5Ded868C5D10569bD73b06261F5556);
presaleAddress.push(0x40B0A18B6A47746Ef7b8b76bD481C6cff7bc23F3);
presaleAddress.push(0x4464e71B50a0a604E4d2e7DF14d76bFd462D0fdd);
presaleAddress.push(0x4623539B49D6a46872d056b295671E671D8877d8);
presaleAddress.push(0x4631b466989CfE33113a43cE62682aCb6d550df4);
presaleAddress.push(0x47549a4A188B4f66981791E994f8faA5490CA162);
presaleAddress.push(0x497206C990db435DB0f52CC25bbC1d322b5c7140);
presaleAddress.push(0x4a7A07EeBFEe63FD011bd1280395c52E8b1E8e0C);
presaleAddress.push(0x4AF83A7c0aC89b54F3A8dD3BCEEEEd9A62bA4f9f);
presaleAddress.push(0x4BDa8c8503156cEDB900297258c6AC572Ae45bf0);
presaleAddress.push(0x4E9083294410BDb63F3766513ef5333E31944230);
presaleAddress.push(0x4ea7766a1559A8c76dCC7b1E2914c5687FcCb71f);
presaleAddress.push(0x4EaCF19bEC5912E3608FD41f6f53C439a6366832);
presaleAddress.push(0x523387Ea8f9b57C23A27e755bfd41ee8aC74a3eA);
presaleAddress.push(0x52B52D5C4eB154161b51c52d5D021bf020a4ADcc);
presaleAddress.push(0x52CDc472A31A462589cF8190087F54b5AB69d2B5);
presaleAddress.push(0x551e39586e4f1Dd9997E0Ec83c2bB30C8C1eD643);
presaleAddress.push(0x55517886630BE66523F2C5C027C490166c656F37);
presaleAddress.push(0x561a4D5D24Df36020d721aefeb34B890EEA5Fe5D);
presaleAddress.push(0x563178f7E9658B9ba5E9B44686f22534E7C5134A);
presaleAddress.push(0x5631ebb2C6f63EAae9a4CD676939a00b58aB1FCd);
presaleAddress.push(0x5705309c95273D14a08e526F5EfEa11Ab4bB06fA);
presaleAddress.push(0x5729a47E4377a78b03502A51b5dfbbDD8f2fa7C2);
presaleAddress.push(0x57CA263C4539fbE35dA41FbF2257be5E76A91Cf0);
presaleAddress.push(0x586706ee53b33FFCEc6b2993b22d4b87769D98ED);
presaleAddress.push(0x594AB9eBa797d5A977747125912B81F4aE8536C7);
presaleAddress.push(0x5a111BA98ab387aAB4Fa7c7284DE7746f94784A5);
presaleAddress.push(0x5A72aEEB4d435413323AD7e76FE72318D641945b);
presaleAddress.push(0x5B7c05424a6F0A499404F262c5c5EB407e882396);
presaleAddress.push(0x5Bc5579Fa5849F08fDb560C3DB2683C7C430874B);
presaleAddress.push(0x5C05b3A300602b6a91e58839fBF7e4EE2c5525c8);
presaleAddress.push(0x5D3766bf86329B65b7FAFC7137e2a954AffA3bce);
presaleAddress.push(0x5E3bBe7eEC540CE19a519570d30fCb074349CB2f);
presaleAddress.push(0x5F5ccAa7F4b32F2B47E876F05C29911622ffC1CA);
presaleAddress.push(0x5F81e51903031555551F771c1276a7d67CBB0a9A);
presaleAddress.push(0x5f8568aD07413Eb409247eE2A31C33c0ce82f19d);
presaleAddress.push(0x5fbB9e41945dbD9D0fE02914247864bEa52f15d3);
presaleAddress.push(0x5FBbC3F1e3B09b1416E14dB73Ca338e9728aF4F5);
presaleAddress.push(0x60996B71CC68cEe871f2B34eCF457A3b574fa744);
presaleAddress.push(0x62808118c4110644b2A9f965Cce10A1E7282aE77);
presaleAddress.push(0x6296e92cE1027d93F53Bf784D42195dD0a6Ab7d3);
presaleAddress.push(0x62acDaa04C322D66138DC7E0A2D91106b0658AA4);
presaleAddress.push(0x63F06788670D8FE1e8994f88029b611B7A63821A);
presaleAddress.push(0x66A160B8fc1b30521dC8aC82A40286614D717EdB);
presaleAddress.push(0x6722A73da2f233Ac009E97991Dff9929A0Ed58f1);
presaleAddress.push(0x68785F00e121A25c00857726A4194Dd54494d432);
presaleAddress.push(0x6B31EecCd068a97aa643D58fe7F4d98eA70d5271);
presaleAddress.push(0x6B53a40e413E9980b6D17c9D6Cba0687ddCb1B51);
presaleAddress.push(0x6C4f9013ff46329C28a06BF9623162421DB5f343);
presaleAddress.push(0x6dc175B7Fd8fDE4fCD3BF531AEA7e181ea68657B);
presaleAddress.push(0x6EEE51ee0E3aF41360bD45d6C9F687EbF458a224);
presaleAddress.push(0x6F3AB92eCb078E1Cf892Cea10AB99997750411d9);
presaleAddress.push(0x70dbd0379E0EFa1e03258eeD0E85E349Fa2CF021);
presaleAddress.push(0x71961AaB51dAe6351d69d5Da13A05dCB28d50f5C);
presaleAddress.push(0x72c376a44903c664b690D1ecf786c6a8497B03D5);
presaleAddress.push(0x72f22d8977020D4ad8170f420E5991cbe9fE7D42);
presaleAddress.push(0x73735652c3BeBE6C42723a30cDB8678eA58cfDc7);
presaleAddress.push(0x73898CbF1Ec904FEeDe00886068FFE2DB69a3B7D);
presaleAddress.push(0x73EA5ACd464037330004AD9b50B3006ef2Ac6e2e);
presaleAddress.push(0x76176615C5E06705BdADC40Ff938a39fE762584E);
presaleAddress.push(0x76E4a671a6E1A062DC213A70327AE283900F8EC2);
presaleAddress.push(0x78CA7Fc6D93c3dC62d498e7eFe7712a6CcF61343);
presaleAddress.push(0x78E242C8099f97DA3b5bf8f8718325a83C7DeA5b);
presaleAddress.push(0x7aC770212E9AD22ae9053FbaD61CfDabfc4E07Bf);
presaleAddress.push(0x7BC89e312d866AA7737Ece63204C2D318606CE2F);
presaleAddress.push(0x81617aE87Ee20d4C5392b1B83B9525320f97EbBC);
presaleAddress.push(0x81F735eD0587170205E59675d25Bf20b64553241);
presaleAddress.push(0x8310F1EbDEd39e8A08c195b052a08444e2a75336);
presaleAddress.push(0x864DB360581F8f1f833D56f97876919eA791DB2F);
presaleAddress.push(0x86d42B9869E008db1Be11E17Bbe35eAEBe031E38);
presaleAddress.push(0x87D4448724DfbA4cB8b0b14E1a6bED9725109bA6);
presaleAddress.push(0x87f1Bc647f18A02540B1e3075621aba96E2b1d36);
presaleAddress.push(0x884513ddB81Fe5FE2A7323A6ca98a0E7e70EDB21);
presaleAddress.push(0x898F8495975168F7894f1Aca9521372Bc8a7E292);
presaleAddress.push(0x8Bae67B4a6D6Df32096dF855bc55b7cF4d2DC11d);
presaleAddress.push(0x8CA270B9af47482D71c5631278A65e270Bac02a4);
presaleAddress.push(0x8dd808910856DAec5522C4dE7894709687CF0019);
presaleAddress.push(0x8fd3db07f7e7Eb03B00C090E46b7aD4842234B0E);
presaleAddress.push(0x91B92bbD2332A4564f205D996dc505D4457221fa);
presaleAddress.push(0x91d28bf8FE216968D57E2F0204b11D21D116f755);
presaleAddress.push(0x942C6B580af6B2A53e3f93C345e79cccE69531f8);
presaleAddress.push(0x94DEbC57081C4c58Dd69F4DFCE589b82fc3C2866);
presaleAddress.push(0x94Eacdd1810E86D5D3C718B96D7A9CEb7C55c578);
presaleAddress.push(0x954749DD5b73Be3a63E1c529165Ed14FF64192d7);
presaleAddress.push(0x95Bc77a5b4D46218c546ba35EfD3f80cACa73D55);
presaleAddress.push(0x95C6d0f794b9c629C94b1Cbd9bbF4c290D326F99);
presaleAddress.push(0x98a84DA0F285F3Bd4d9319a8822c44290CDb8D07);
presaleAddress.push(0x98d80eD82a3e68157139E2d9Ea6b137e9a358f7D);
presaleAddress.push(0x995d4C14061690758332E765166fBE123bfd2642);
presaleAddress.push(0x99D7a3a24c947Cb65510c6Ca48AD2c5a27f20B43);
presaleAddress.push(0x9b67c18e5508EbD71972d22f0e202E6c967bE760);
presaleAddress.push(0x9C3950b6c38f86D0ad356f461E287e5A80798aD1);
presaleAddress.push(0x9cBe889E93ab481D78cB8Ea27C97e1eC2Cfb0213);
presaleAddress.push(0x9d137f55A278Cd591C1Fa6aAC92643E4CCFC4778);
presaleAddress.push(0x9e01B67B83AA360076dE9803FD68Abd07F95B07f);
presaleAddress.push(0x9E06e29A9c0a664EDA2C7da8B405B299E632C3d8);
presaleAddress.push(0xA4A2d8102a6f5b95e6FaCFf48637959e83D2F1Cd);
presaleAddress.push(0xA59Dfc6BAce0bFfB63BACe2F3DE22d8a2B5Ce1B2);
presaleAddress.push(0xA6Ff79150f1743abd42e804a6B4102E87c20DfA6);
presaleAddress.push(0xa711A29C5824D2C3cE71a4e9BBCb10293e8E95D4);
presaleAddress.push(0xa7637F14E3fF3762601aA032d1603a86Ba0Da592);
presaleAddress.push(0xA81599Eac76045fce181Ae0D83A5843C39867AD4);
presaleAddress.push(0xa943A14Dda16a964346cBe9aA5253F7Ed8c46598);
presaleAddress.push(0xA98D5098CA8DF66d2C3eE5a73F0ac2414F4D710c);
presaleAddress.push(0xa9Df23De8369d4784a169a4CAcDcc4A9fB7D5775);
presaleAddress.push(0xaCBFF5286F4cA050572B18d704E096a6aFF8827f);
presaleAddress.push(0xACE4cB4F5f093FD25FDC29D56Ab36df2Bd309B5E);
presaleAddress.push(0xAFC1a5cB605bBd1aa5F6415458BC45cD7554d08b);
presaleAddress.push(0xB20bF6D7f60059dd5dE46F3F0F32665a259ea6C0);
presaleAddress.push(0xb392AAAa7a33B876D693b1Dbd771D1e095a7d11F);
presaleAddress.push(0xB54A2CF4B7A204b2a5FB0915BA439a40ad2d1481);
presaleAddress.push(0xB681ddC6409C01Aef47D9c5C19B2b5aEbff270CF);
presaleAddress.push(0xB68e99da23a3B29C36297fce9F78EB3070466B26);
presaleAddress.push(0xb6A58AeA67Feb8695B00a3ADB05B48634b67aeCc);
presaleAddress.push(0xb7BbEcE8D4454b0F988FDDf2f20409014cdC50f8);
presaleAddress.push(0xbaf8E77d45DbA841092f66aeF6A809533A7faa7D);
presaleAddress.push(0xBb48d9B48274BC62b2A7D24362C05986Bb7205B2);
presaleAddress.push(0xbD9B88bBbF1FD8BEd5C29b103E1ce84cC6f3d863);
presaleAddress.push(0xbDBacFC7b0584e02B6e3f28200216529B7dc7A10);
presaleAddress.push(0xbEFFc39C91542C7d42407Bbbff984E950DBA2904);
presaleAddress.push(0xBfE23452D71E66064DE21c757392A34A2216DEe5);
presaleAddress.push(0xc072f3da6cec7947FfEcb1f5Beb3499045458BC1);
presaleAddress.push(0xC0aE40249B6e58b55DCa0C8e0707b3FAd04b4b33);
presaleAddress.push(0xc0f0A6f5f76FA0dc892942845F1a500690ACf0d1);
presaleAddress.push(0xC2fc360Ebe63B52c67371788946D7ba482a24Ac5);
presaleAddress.push(0xc3249C87d16eBca335a76AEF4DeDBE32736d1f1A);
presaleAddress.push(0xC3b93D3A718F96141d8B9C98E7dfA4eeBb685840);
presaleAddress.push(0xC559829041f295BEfe37fd4AFCc7d47a4998d4ef);
presaleAddress.push(0xc5B7a3d3d230F5115233Bc38107178c93E984C5A);
presaleAddress.push(0xc7719FEc0a61F17cc790fc33B5c1c6a78C00F1eA);
presaleAddress.push(0xC88CC65A0022bAeF28c36A4f415687d566E8098F);
presaleAddress.push(0xCb8926180FBa3AdBDf124D5eBf1D6E9811548EB7);
presaleAddress.push(0xCC8b0d940F3C450593b06e92e74C96b7908765f1);
presaleAddress.push(0xcC9dd673259F4171116949bB658379fFA9b8a7BD);
presaleAddress.push(0xcCA0fFa560Ee5Caf204a8106e291719b2348C633);
presaleAddress.push(0xcCF54ABE19255907B02Ea5DDA8eD6D778Bdd041a);
presaleAddress.push(0xCDeceeAA985Aef51A45C79418F3EC9254C22e680);
presaleAddress.push(0xCE0dc5cCfE9B2240AFb0246c18b7649AAc31eC83);
presaleAddress.push(0xcEE50E870565DC60091e1D2cD16f25384553DA48);
presaleAddress.push(0xD064999B09E553Ef14a5cDF28b4E1e9160234c46);
presaleAddress.push(0xD3b210905B05BB356CD9F5BE2CAeD44E46424437);
presaleAddress.push(0xd59a14Cb89672ad53752670f67170E2F23d883fD);
presaleAddress.push(0xD6f2a25263864E82f41590CcA7044208ed4db090);
presaleAddress.push(0xDA147Fdf35f892e16C8da7484E724e419d02Ac3b);
presaleAddress.push(0xDA26aD04579e6245AfD89530B7157895750025Fe);
presaleAddress.push(0xdAC6a9c767E949B741D940238B301476e02eF1d9);
presaleAddress.push(0xdb11D879878DA3e4534afce697a2baee04D75b60);
presaleAddress.push(0xdC39Fd104414619C2EBCF13a19e14ED98195FFCF);
presaleAddress.push(0xdCc77FD7b2B0BD9376C6A77567f42E8a0Df8f260);
presaleAddress.push(0xE0c83B19a59A13F1E45FaC16efc4C0101258Df60);
presaleAddress.push(0xE23Ae6aA3730e0B159bA9Ea9B1d0d28c842f4BeE);
presaleAddress.push(0xe241f2c344281e1e9fe5f23E139326eF7Db60564);
presaleAddress.push(0xe29CE30A957A447027a171c7CFDAf3D255F32a9F);
presaleAddress.push(0xe341d077a0cfba74f492cd0d06F6be3b7C0aF1C9);
presaleAddress.push(0xe42CfA6263Ed1511c864A5E6af67ADB66c766ED8);
presaleAddress.push(0xE4844d2171d2c3A6BBc5979904e61f8b6a680f6a);
presaleAddress.push(0xE4Cc46c35C391439c6Ef139295d2cfbA34EA4A0E);
presaleAddress.push(0xE69a6159094Ae2A467175271a31C68a658AAc73E);
presaleAddress.push(0xe726849Cb67765aA6E18D1a3Fe9F371B02061064);
presaleAddress.push(0xE75934A1F2921F21d07663bE760107a958fD8c30);
presaleAddress.push(0xE8E2d703A26ecD9E98C8d4792592403FA9E57947);
presaleAddress.push(0xE99f945574F09a246be455b8AE4DE80c9d3677c3);
presaleAddress.push(0xeA0a1ce786d023AbF387028E578a2d7536eeA483);
presaleAddress.push(0xeaCF7aC996D2e31F19736F36d0F693A373221DeE);
presaleAddress.push(0xEB5cd7F76401FF5fB96AaD009b9617961Ba0e8a6);
presaleAddress.push(0xEc964b6c91abde8f583F744de48da87b9F43035E);
presaleAddress.push(0xED4855E0636265487d32257A790dc68378ADd575);
presaleAddress.push(0xEF108D51cb6BdB039234631777feb377aec636eB);
presaleAddress.push(0xEf3BB8e75E4d5828dE16F38D8d2832704122034c);
presaleAddress.push(0xf07cF12b40367BB500578a2AD20Fa38b796775ca);
presaleAddress.push(0xf0a0b569734A74e20A2d5F7f2F9D042c4930c686);
presaleAddress.push(0xf0B1FE283CD9BfABa76378Bb6cA0E541ba1226F9);
presaleAddress.push(0xf0F31Ac0cd7179c13c030CA692954dD991bb9E31);
presaleAddress.push(0xf2f4D8e3A65920E3Ab7334e4E0E93741346B4d4a);
presaleAddress.push(0xf2F90FE3eE6a0C7E77F08aa9B3F96dF0D11dE99c);
presaleAddress.push(0xf369c84fE46e80b8FE50147E2DC995E48D2E03ED);
presaleAddress.push(0xf5Bdb24adc2534c9BC91313252D292738312f2D9);
presaleAddress.push(0xf60ea272936489126C4329767A9f4922A99610A7);
presaleAddress.push(0xF79E69F8c4165A03537BaFb18800F233d472Ce32);
presaleAddress.push(0xF876A7C57054460282f4Ee1B5528c9d170026907);
presaleAddress.push(0xfb4a4b24117eE72342786449457adF8BBe718231);
presaleAddress.push(0xFd5A5D8f76371D8a481482c7F8BbFB0f1dE4D4D6);
presaleAddress.push(0xFdbbA04493b474C6De0E0e43fF110C0185Af7643);
presaleAddress.push(0xFDFb8274435eB53EDcbA3176b570B6d5Fc0C1108);
presaleAddress.push(0xFf6f33768Df7A93F983f0a9C96Fa24d4890E1677);
presaleAddress.push(0xff7ab435fa838755b97782E850735355B982B2EF);


// dummy accounts, if any
presaleTokens[0xe2A4f820cCcA0053557775ffe5cdb6d48fCb94b3] = 12000000000;
presaleTokens[0x4699457e5e4DDcefa69E9b8057080D4c86193424] = 12000000000;
presaleTokens[0xF605FcF9bC61B29F75dDf5fddAeAEaaCB9510501] = 12000000000;
presaleTokens[0xFa50C7E354e4EE7657d2F1A188F630aC3cbBbEdE] = 12000000000;
presaleTokens[0x8a18e8a93b424CfbDB3d807f5A532Db363C82A25] = 12000000000;
presaleTokens[0xD4dDE16Bd4c528Dc9B069D46436c1f736cD07885] = 12000000000;
presaleTokens[0x8766c625038F8b15695775fcCD449b7855911721] = 12000000000;
presaleTokens[0x5B17Ec82B083bd173D8bFd52bE127D817DB30d90] = 12000000000;
presaleTokens[0x610EFCe032f1c423b9B52D2Fe63383fD75c04e7A] = 12000000000;
presaleTokens[0x1422D510Db7376B7A10348f5D6a7Ee4e7633b214] = 12000000000;

presaleAddress.push(0xe2A4f820cCcA0053557775ffe5cdb6d48fCb94b3);
presaleAddress.push(0x4699457e5e4DDcefa69E9b8057080D4c86193424);
presaleAddress.push(0xF605FcF9bC61B29F75dDf5fddAeAEaaCB9510501);
presaleAddress.push(0xFa50C7E354e4EE7657d2F1A188F630aC3cbBbEdE);
presaleAddress.push(0x8a18e8a93b424CfbDB3d807f5A532Db363C82A25);
presaleAddress.push(0xD4dDE16Bd4c528Dc9B069D46436c1f736cD07885);
presaleAddress.push(0x8766c625038F8b15695775fcCD449b7855911721);
presaleAddress.push(0x5B17Ec82B083bd173D8bFd52bE127D817DB30d90);
presaleAddress.push(0x610EFCe032f1c423b9B52D2Fe63383fD75c04e7A);
presaleAddress.push(0x1422D510Db7376B7A10348f5D6a7Ee4e7633b214);


      
    }

	

function recoverLostBNB() public  onlyOwner {
        address payable owner = msg.sender;
        owner.transfer(address(this).balance);
    }	


    function withdrawRemaining() public onlyOwner{
        MoonCoin.transfer(address(owner()), MoonCoin.balanceOf(address(this)));
    }

    function pushTheTokens() public onlyOwner {
        for (uint256 i = 0; i < presaleAddress.length; i++) {
            uint256 amountToSend = presaleTokens[presaleAddress[i]].mul(10**9);
            totalSent += amountToSend;
            MoonCoin.transfer(presaleAddress[i], amountToSend);
        }
    }




}

