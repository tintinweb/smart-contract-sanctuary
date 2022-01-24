/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/preventa.sol


pragma solidity ^0.8.7;





contract PresaleTag is Ownable, ReentrancyGuard {
    AggregatorV3Interface internal priceFeed;
    mapping(address => Vesting) infoVesting;
    mapping(address => uint256) balanceVesting;
    mapping(address => bool) vesting;
    mapping(address => bool) noVesting;
    mapping(address => bool) invest;
    mapping(address => uint256) quantityBuy;
    mapping(address => bool) withdrawalWhitelistStatus;
    uint256 totalBuy;
    bool initGame;

    struct Vesting {
        uint256 firstBalance;
        uint8 numberWithdrawal;
        uint256 firstBuyDate;
        uint256 quote;
        uint256 lastBalance;
    }

    uint256 priceWhitelist = 6 ;
    uint256 maxWhitelist = 100;
    uint256 priceInvestor = 8;
    event Buy(address buyer, uint256 value);
    event TagBalanceGame(address buyer, uint256 value);
    event InvestorBuy(address buyer, uint256 initValue, uint256 balance);
    event WithdrawalVesting(address buyer, uint256 value, uint256 balance);

    constructor() {
        // TESTNET
        priceFeed = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
        initGame = false;

        //MAINNET
        // 	0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        vesting[0x5F12472D9579e03A9C0FaA2e204D7e1F80521E72] = true;
        vesting[0xfF966De0eFfEA07F14EC884dC358672dEDA460a5] = true;
        vesting[0x90bFF9603B1aA6D1504D0ad96394f26E57756518] = true;
        vesting[0x803b19b8eFba94d0F6674f7250E5290704B82ed0] = true;
        vesting[0x36Bbf3A86Df1CC53f9369DfF108012da8B19b20e] = true;
        vesting[0x2D588bF4D60C89f4f8e46F8c9e7dFAa76Aadb974] = true;
        vesting[0xe97147676461f03a61671efacF613d079dEB28f5] = true;
        vesting[0x7cCffEe1c8BA3F26FAEFDf11Ed55B75876515914] = true;
        vesting[0xB0F69e532633b506C6C30bD828772Bde5191d79B] = true;
        vesting[0x7E45BAB4079B2c64b3a33d4A6475Bb9a20E6e701] = true;
        vesting[0xFC73BCadF13942Ad353dBD4f53a0216413921b32] = true;
        vesting[0x23705C206826136AF1813C71EEBc0755193d1A48] = true;
        vesting[0xCCca402f251b8f9c002B4fb19BC1E31F7579079F] = true;
        vesting[0x32D1dF522588e407684AbA34833C6146F686191B] = true;
        vesting[0xEe225DD65A9217c199beb253668F790e9b77E3c2] = true;
        vesting[0xC61008fE3267f18B1E8e722A4ECd54e2b40a8BE9] = true;
        vesting[0xD231E769b664F5b46d35f2A5990b64675106e945] = true;
        vesting[0xc141cc35480b1F0b407ff5C57356ddc4BE06888d] = true;
        vesting[0x9f7181e2952A2f314A7DF7D348aD079C3443E61b] = true;
        vesting[0xb97CEd6513974473072A50266bb6244b95Edd902] = true;
        vesting[0x697917A5B261f31bf9e721A1ebBf1F4b6f05DEd1] = true;
        vesting[0xFFCf4a83e7dAf00AEEeC1a0c18Cc673A33295458] = true;
        vesting[0x0a27284b7EDb757746a014D36f69863ebEfa672b] = true;
        vesting[0xFCe73cFd558B30c0D0e22a177e66F52712a74488] = true;
        vesting[0x17bB21f4C6DD9C5809e1f08C642a15966DC838e9] = true;
        vesting[0xFfF2BF8E34a2b4a38CA0E6d2B621C0E13Ae3f9f7] = true;
        vesting[0x1451a6CfAe562E5DC1EA87C357F875008E1B786F] = true;
        vesting[0x10566cd48EBc0044FA3e72909Ba12635F2A3a1d0] = true;
        vesting[0x4d7ecF06aB8fAE3646E02aC32a30e77E33926A73] = true;
        vesting[0xd2e5a138A49f99795107F421a9f3Eb41537a974D] = true;
        vesting[0xc6B3D9867bA7929d20f8983FeAf43075860eCA68] = true;
        vesting[0x43a394eCDE21F18c5569435E9da5E5683A97c99a] = true;
        vesting[0x228caE4c3e91548AE04906b83d8041FE705AA977] = true;
        vesting[0x7AB422B4f3581919bAF0b62E08d2982298e5012E] = true;
        vesting[0x763CD14545179bA435d97862509cd211786F8a6d] = true;
        vesting[0x78F007EF2ec162Dd26290BFF423ED3B730F8Fbb0] = true;
        vesting[0x37D03b4Bfa14311852A740acC0a80ACa77BFaEa7] = true;
        vesting[0x3A9E18a870dd5750058A08901Ccf588F394124CC] = true;
        vesting[0x093f5aFBA80818EaaA65A5D5f537dE33E1380eb2] = true;
        vesting[0x8410B3f6cBa32c2d69696a2dC33b514d98957676] = true;
        vesting[0x61D11522790fC56419eA262b2959bbA0763FB372] = true;
        vesting[0x8d1AABA048A5B4ecAF040d34552ca8c6f456e9d9] = true;
        vesting[0xDA58B35e39Ba5a424432c139C7ECbd06A119cF2E] = true;
        vesting[0x14c44b0DE19493c6D414451516b0700d5CB34ACb] = true;
        vesting[0xc837E220fA24FA9B42477C18f0ee9B7793abEc6b] = true;
        vesting[0x491027A6Cf9f6C85f35C7d4c4A85871C15627318] = true;
        vesting[0x617F488e5113d5432F05C53B26294418CC0dda7E] = true;
        vesting[0x61560bE69d3104d304d2eaD957579A7304a2A6B0] = true;
        vesting[0xe4CB838Fa92f26562136ad94723b3442A037D843] = true;
        vesting[0x0a38aFaa76dBDf4B2a0359212f17eaA28209381f] = true;
        vesting[0x9D0fe86632548AD64D3E8C8A698A31A86BaE8430] = true;
        vesting[0x9f83fd90305296AF9273f4Af725b2A68B0fDFC62] = true;
        vesting[0x182F3cD6079A358410D72E188CEC0bb235d1Ce6E] = true;
        vesting[0xeEcd4Ff719c384F04b76747B808890005706Df7f] = true;
        vesting[0x51Ec1CCB05cb2446008242C9F8d565917c3B41E1] = true;
        vesting[0xe8C0B0F3D84022736644C7E90b056B32E35Dc5C9] = true;
        vesting[0xAe66072a24a121fB11129d36F0FeA8510F33763B] = true;
        vesting[0xA9406CD391B3bA176BdB9A78eE10183C2a60Cf95] = true;
        vesting[0xf35B5a70FB33Cb5e4a3399DCe4eab17746F13776] = true;
        vesting[0xfc226C30b73Fc9F3BD7c039D6D8653c191410772] = true;
        vesting[0x87f5119010c0269c741352561361DA30c547a867] = true;
        vesting[0xC74575BBA9d8fd80d2eD29387f13F4CE1Ad7e55B] = true;
        vesting[0xA447ef5FCA1c3a5Dab9c187bFA32263c31146748] = true;
        vesting[0xA16a06904863cC2B24692fC6475aA38b6691CCc1] = true;
        vesting[0x701353ab7E30e814D4986a9a3c0aC2095a18122d] = true;
        vesting[0x311E709765819833B5FDe2786977D67B7f0f2641] = true;
        vesting[0xdBea26c6A3093a6c78494E8CD8BEdaddb60D243F] = true;
        vesting[0xaf4Ce9617139940c0eFe44Daf9bD4A2711C80151] = true;
        vesting[0xB138D2A843A20D58d49555112b229576e32BcC45] = true;
        vesting[0x3Ef95d500BcF9beBbb1Da03c386aFAB95c21e728] = true;
        vesting[0x05474d8905F472f7bC7C50afCcE6e25FE6cc867f] = true;
        vesting[0xb712b69a483B0051b5F8DecEA36BdCfc8ee723CE] = true;
        vesting[0x378f64bd7F21853ce6cCc5d7A7A2700660521004] = true;
        vesting[0xf9E031101DaB9b33b2697210f1651bB516c76C01] = true;
        vesting[0x5BDD6aFE9493952fbf2500Fb11e4221Ff4fa16bB] = true;
        vesting[0x57ee1b8984D9D955f872E0e51e9ffbb90B30B71C] = true;
        vesting[0x46E4A242c03AC11Eab12b5AF01885D379edc453a] = true;
        vesting[0x8590A8900DA2eFF00e317C92D84751844eda6DeC] = true;
        vesting[0x823515Efae87F1905b70ab642e9563c187D46d94] = true;
        vesting[0x71b545310555bd1B785001e16B6498C23031BDD6] = true;
        vesting[0xCc3c4BBdA83dDbAE5D138c34229821Dd3E5FED66] = true;
        vesting[0xdf0872355A2e2466Fd2471F7E3adaE2E1F255811] = true;
        vesting[0xfbeA999c4f6B5d02B31E38F3b7c55E541F4104E9] = true;
        vesting[0xdaaED75b0BFAAadDf6Dc436988D21c085c907f39] = true;
        vesting[0x5741A68a12b07E129AB87bc7cF81920704e7C36F] = true;
        vesting[0xCE8851f065c55a8c2FD21a68F4B0738F6CA86Af8] = true;
        vesting[0x2bdC2360f68488C61d9DAC187b17Bb9F797063f5] = true;
        vesting[0x49fE7aA0C65238F154d6aa9ed944dA4cf4b424f6] = true;
        vesting[0x44Aa88f94a951DE41B34255A7B01FBD86C2Bc83A] = true;
        vesting[0xb5667ef03C68F9Ef3BC18FdBdeEBaf740aBfddA4] = true;
        vesting[0x023c0D2A43409920263c889b0242A3B15A89e8Fe] = true;
        vesting[0x82747d84A281Ef0329dC411E48c7da2d310de60B] = true;
        vesting[0xA76d1ed8a3B07E3ce4D3ABBE5DF9569Dcba37CF1] = true;
        vesting[0x0A1150Bc37Cd18BB1Fb9217Dc279ED6672Ca7561] = true;
        vesting[0xa63B3e623363606Ab922070Ae4baD35792758aF3] = true;
        vesting[0x8C972508a062C84Bb52185d44D88f32AAA8e8c34] = true;
        vesting[0x01e67E00edbC8667D8db3222E8546685AE17570C] = true;
        vesting[0x290A6935dCd882A985216335EaBb275a80F12448] = true;
        vesting[0xF6F21f11609D51C2f350C14048c62d0340c66b7e] = true;
        vesting[0x4d64557be43255c3ca7090e407D554A30cD12B2b] = true;
        vesting[0xb66c102Ce7103B754598a030BA6B44c41Aa9bD6d] = true;
        vesting[0x25e10EaD226C6827d5ff45E726Fb94C93096DbDE] = true;
        vesting[0x47FCb7729169a024F95301721475dA0B45376675] = true;
        vesting[0x2C63e9726f9BDCE6dAcA92E3b30103D2a851c317] = true;
        vesting[0x471beE2fb686342ec03C04bD73a6F4F5c9E5dbB6] = true;
        vesting[0x4fE039eE6BEf38158bd4252F4AeDd98025c24C4C] = true;
        vesting[0xA514abf98dd2D9BaFC99182032019102a0aD829F] = true;
        vesting[0xa68E2611523926aC34254C7EEB75afEA2A6829a4] = true;
        vesting[0x5bA44Af2895D367DBbdaD25ad6A17076eB631694] = true;
        vesting[0xbCAA440EBC50044D12B64C55791c665e0D9E1C0A] = true;
        vesting[0x83311471c0B5B2573F0A656dA03CF379B433c3eC] = true;
        vesting[0xd6F1DF17D8dCc2FB3e50515EFe38801056c5d511] = true;
        vesting[0x739270cD86E96811Cfff12d325727B26A7e57Fac] = true;
        vesting[0xb7F6E6A3465eF6a205Bc6Fec07d149B747490030] = true;
        vesting[0x00ff38A24500C4397E5255914813dCEEed83Cc8D] = true;
        vesting[0x3369dAA074c263126EB73f0cE37d2987910B72F8] = true;
        vesting[0xE8f471F595d0b6cF7cEa0F05Fc1F675A7e84B603] = true;
        vesting[0x24cbF7f7d71c49c87e722294A2A4d0d70Ac9f98B] = true;
        vesting[0x87c3aAaf2db11d0325d22B8bf06725f5c711F8e4] = true;
        vesting[0x496Baa5Ed731CC40942A0Fd9C1bE45c7D56e25c0] = true;
        vesting[0x57bd251F277730399e076d9F668Da415c79f8bE2] = true;
        vesting[0x59fD3aCD0fc0Ceed759CfDBe7Da18fe8b78F0C31] = true;
        vesting[0xE3007dB8aEB514f73E69067de7A95228B0f4fC7C] = true;
        vesting[0xa04009CC41259c35bfFf797Ec42Da986a61b817B] = true;
        vesting[0xdb36Aed475C88A66Fe42534Af8f6083412798a91] = true;
        vesting[0x09A853904d6776Dc4afa8B06173e51dFc213E67d] = true;
        vesting[0x3621a5030bcE26Ca7319486f60C2CcCE3109726c] = true;
        vesting[0xeb8BFDd3E498fd69FCc1b35D626fB2Dd5680C308] = true;
        vesting[0xD65Acd0687EFB726766e9B2FF45516Fd0Eb6A753] = true;
        vesting[0xF7Ad12e5F2D7027009E51019f992fE4D2d75DC37] = true;
        vesting[0x6f1a3760a8621d243026A64c761305DA9C3665dd] = true;
        vesting[0xaFf18686741216059D7b21D2dB5A9B97cc6b8742] = true;
        vesting[0xa8B17d25efc57313CB462bCAF6ff0DE66e52709F] = true;
        vesting[0x11565B57b204c14B97c10395A144d7079C0df1d3] = true;
        vesting[0x7ac78d45323C689f21D4BA48Fa7a0098cecA7F1D] = true;
        vesting[0xf31f2311E8856373BcAB70FaC14D4BA5124F3BC8] = true;
        vesting[0xcA548707E94cA4815FCBAD96C50308baeA83b100] = true;
        vesting[0xA11f35AD75729391C2A554D32c284F0d3B227e27] = true;
        vesting[0x3e5655BE176Fd65abF7628E42CeeE32E3500DFB4] = true;
        vesting[0x304d19f8C4F4b90111b5375948A7A01f59446Cad] = true;
        vesting[0x0b98C75D968b0355597F863aaDAce10b110cF1Ab] = true;
        vesting[0x9a5f48Ab2a469c3C54B885f12A003B17a8D8f2F4] = true;
        vesting[0xa1f75Ce15743E0B4D9910d0Ceee429412d111b16] = true;
        vesting[0x9E27bB13bA8D265Dc090940c19B5fC895C099F50] = true;
        vesting[0x8457B70921F90f397B5126819aEB32a2ac7d5F33] = true;
        vesting[0xe0b857807a0Bb3502aE0196977fd8AF8Ec0c01c8] = true;
        vesting[0x8A46335059C42b2303ccCCd0dC6bb50545DF859f] = true;
        vesting[0x121822cB3E7b555f178623942117818e80836d85] = true;
        vesting[0xEF0f44e96DA9367386fBb2197ac7A057124547ec] = true;
        vesting[0xe05eBF2e76aE5793135bACbad39e82b1D0dDAF5B] = true;
        vesting[0xDe97a6119C9c3dFD3fcAFb1952D90D1Ac5969477] = true;
        vesting[0x79ED00107A503e07E74f3ab7939f9Ca4bb012bCb] = true;
        vesting[0x8919caC4e2460965824349c9faDA4a5623B1Ea0a] = true;
        vesting[0x62AA7aBEEbeBa1D2352B6217136612Ddf9A80834] = true;
        vesting[0x89538171Ad9FeD9C06E5116aCe976D116a5FA186] = true;
        vesting[0xf6b2631EFFf5c2D6e684Cd5D27427d15a7c64fB3] = true;
        vesting[0x35Fea11799302D7ED8960f10019244b51D02EE25] = true;
        vesting[0x37B5Fc13f71d83773893c6fA9714d982cC7624FA] = true;
        vesting[0x91044C5683Ba010f2ccd23D488EAaF72B8A2614e] = true;
        vesting[0xC93B0e2C0a0FDB0802aD267Dd9BBa8BA7ACd3e7A] = true;
        vesting[0x58641551E3D1dD62be90f072e4904Ad155F6bc5D] = true;
        vesting[0x3D6184223DD0d5239947793746fAEc00B63Ae990] = true;
        vesting[0x7ca58E5664B487CCE7871eEf880B56E60fcBdF8B] = true;
        vesting[0x81a228bF1A00E9d415396904713e67DC114cfB7b] = true;
        vesting[0x9cCb19f3099e7037d5a7e4AD0ECa47132E26654A] = true;
        vesting[0xE3441472789c89f156619D27b101C94C70e9F6D3] = true;
        vesting[0xD13AbE1A715667567F03d02CD2696d01EAe50501] = true;
        vesting[0x3219ce6863F13247e02452E2ef5C7337Df14a7CE] = true;
        vesting[0xC8E939400e9aA8022F4500e7800090aBA0769C4C] = true;
        vesting[0x82B1cEd5C7B7A52C930f1A5De775f5BdF68F22ee] = true;
        vesting[0x1db58b0aBAb0D6b21313e63029546Fa3d13EdecA] = true;
        vesting[0x0023DCE2e4C711e95d5EffB092e0b1b91eFA2779] = true;
        vesting[0xA66bA027b31938D67B8221E8245Aa0f737294276] = true;
        vesting[0x8779ed418dA4f9651687Ea62c2F2f612eCe95009] = true;
        vesting[0x4C4767314099FcAfE3BC1a7590f3254d80296EB3] = true;
        vesting[0x10f732115C53105d2501173521722Be222246d51] = true;
        vesting[0x76a48af4a2280EE580534F067bE880b6f8aBdDD1] = true;
        vesting[0x9a00c4Fb551b3A813B88444b9e6c2D77922b2129] = true;
        vesting[0x81c3eDF0B1ddF62f714C42C712766D9C48353E90] = true;
        vesting[0xc3fBC8240f63147C52a306F42010ECbB049b80E5] = true;
        vesting[0xDA6B5d4be1643905D9265B56e4Fb9326582b9F93] = true;
        vesting[0xc20Da5AE91d51542099C747420dD677797B98D61] = true;
        vesting[0xcA44cb3e6337222bfdbd6f113B6ADe4AA65BC357] = true;
        vesting[0xc590175E458b83680867AFD273527Ff58f74c02b] = true;
        vesting[0x85B2Dad00920d0ED1740f401600b96dc414A7170] = true;
        vesting[0x01222ba3C7a109375040B72705995Af9Bd5f4907] = true;
        vesting[0xF775194cFa920dEAF20813455475bD82e0BF8180] = true;
        vesting[0xAFc839A410eC10559BfA3159351e270D552512F4] = true;
        vesting[0xc728F2dAC6CEf1dF193f05E69DEc73cF1Bc1B89C] = true;
        vesting[0x2Af61988333b4d565CFe50E196f7C08EA89DA1C1] = true;
        vesting[0xa10bF17024FAF59F2130525f4c69758F5205736F] = true;
        vesting[0x5D5e12b5e53933a4e7e5Aad4B12A1C94791B3389] = true;
        vesting[0xd0dB2581A8D34313f0B2D69839170853C7061ec4] = true;
        vesting[0x22EB6300B7435032Cc5b93D9F3221971a49A21B9] = true;
        vesting[0x40D5a0AB1F94F561f37f72731055F30d1fcD9cfa] = true;
        vesting[0x5DcE7412dAC1860B1c9EaCEaE3a09eD2F4eC7600] = true;
        vesting[0x4faAa0FCA1Ac3cacf57A53399B2a9ce2096194ef] = true;
        vesting[0x99c69B9A42194E92A83D32DB094e0d036A1e9ce5] = true;
        vesting[0xE6487E7CFBE00Cba04C298F79AbFd642CF5Ea1eF] = true;
        vesting[0x861D63f9f7732d4e311b4cDaf772aB2dC071F153] = true;
        vesting[0x921FF22C7661564B921196Fe4E4935BbCA9E8503] = true;
        vesting[0x442b60D78D83e580A9ED547A639314bCBD862247] = true;
        vesting[0x861D44a9C638e7c3a92690F578F567189435a9F2] = true;
        vesting[0xdCC756848676ff7c93554c8b1982322FCB16DA79] = true;
        vesting[0x095446A6EaF77637cAd221A89C3c133ada34335D] = true;
        vesting[0x55dD29669233CB10E6E8E98d002b19441d797C34] = true;
        vesting[0x52870e5E36318442301bAd8D560085152f055ab8] = true;
        vesting[0x79f1ba8AEf632E24F8a354Fad37305555673327a] = true;
        vesting[0x2CE68799416c7b2b70FA9448aA7Fdd507b4A9A4a] = true;
        vesting[0x23d121d441b1D32362338D522d89B8E536Edc565] = true;
        vesting[0x825accDf3c625337D7f8001387BE78c1F57bfCA0] = true;
        vesting[0x8E78c77079b693956263283754935CF04e07A1C8] = true;
        vesting[0x49cf8F510c50FB5eECBBeFDFd5cefEcB12290Cf8] = true;
        vesting[0x6FFD9dE7CeE2A3e57AFc2AC92Ec79806985ed22F] = true;
        vesting[0x69E4d704D7Af0575dD8e0f94a8b10015A6d5B1C9] = true;
        vesting[0xa7dF360fA0A7DB7961a0aAf71723Bf5DcCC425cE] = true;
        vesting[0xBd39EE8dEe5E8Cdf0d61593D9D93aBB4351B3844] = true;
        vesting[0xc9Effea25750B2E683F447D612c3734941cC68B5] = true;
        vesting[0x8cBb460DE82cCbF54C4d0580Ea2a2960E45F1759] = true;
        vesting[0xF197a22C630946B9bff32b735B05b64745fE432D] = true;
        vesting[0xe4E4474CCB0c5F51797Bf4a947f434bEe280Cf65] = true;
        vesting[0xC5e406B0a2A0D01D5282E93DFa95E035E8DA3390] = true;
        vesting[0x3154Ac14F1D712C92C9dFa1a62152D91BA931fA2] = true;
        vesting[0x2edEB88892CA33505fC5e07d7E9d1527A968DE0d] = true;
        vesting[0x288CE499E97a07834Df8205ACbA1511d52e2B262] = true;
        vesting[0xCB2906Ab6543F28a33eE0d46fA6d3BA5413bd846] = true;
        vesting[0xdA9ba05d57208e905c4C031B8Ac5b050ccCf4471] = true;
        vesting[0x2bb9C2EB7002EC8855856e332A5C0bE13ab7169B] = true;
        vesting[0x6FBcB1Dc80C3a77DEdC9e24F7eB870766f7C7a4A] = true;
        vesting[0x6cc41Ad59d62920d867C5d6d2d138109156dCC52] = true;
        vesting[0x850175dae427d3159fDb59d16Fa8d30fa13b1577] = true;
        vesting[0x427cF8401d0A83e723ad518309E9BC4e866DAf9f] = true;
        vesting[0x76C18251A9786101be2f67f8fBAC3DB6dfF252c0] = true;
        vesting[0x434FC3043a4a3b0EE43c50dFB86B16C4b3B759D6] = true;
        vesting[0x87986c7cbb766e79ED855803fe72F416eaC5Cd98] = true;
        vesting[0xc246C5b69F9cFaF48B3301d822Ae1cc37D4552F5] = true;
        vesting[0xD5616F6694846073FeF6EE9F8234705313DE1B9E] = true;
        vesting[0xF659D3446c2A1424b4045645B84705c95a160072] = true;
        vesting[0x3c783c21a0383057D128bae431894a5C19F9Cf06] = true;
        vesting[0x6845C5258D4057183ecA757f286a6a04421Ab95c] = true;
        vesting[0x967e394A6B931c127B33A67B6f3000137FB36007] = true;
        vesting[0x552136Ec8E793dC28774e6ECD8D59cE14BF4F86d] = true;
        vesting[0x6368d51514513Df902c3C5453c22f86f758a53E6] = true;
        vesting[0x84A3ACe08561056953afBa7f6c13B859a48E22e1] = true;
        vesting[0x6c5Ed5e4DBce9BC6A50Df323Edc570fC0414E305] = true;
        vesting[0x7A239Ea1ED4133a941D5E1296d09fBaEf85189c1] = true;
        vesting[0x37291710B3Fe4A99493FDF945710e44E36d9aC08] = true;
        vesting[0x70FBaB48981d1457B67aB8e083A6B32c481e8172] = true;
        vesting[0x1acbCc835D24aa1B641776D4F350ed8e2773784d] = true;
        vesting[0x140e3a84B9DEF8B2e0b0e0f9c250d328a4D094b6] = true;
        vesting[0x74364A654D380A8979ae81FDb69BE2b68eE73982] = true;
        vesting[0x7444F1A7090b01BBa3dfdF781834A0bB226f8F65] = true;
        vesting[0x469273Aea70B64889B91bb77e790a06d7F0eB09f] = true;
        vesting[0x7599099b63553ecaDcffA995Bcc0970465E75c74] = true;
        vesting[0xAb3a25FB02De8c61335674669e9A5D08eecdC554] = true;
        vesting[0x679B6c92c2fbFd8D8c7Ac6D6FBb81CbeD1738aD4] = true;
        vesting[0x3697F3A3Cc5F04C6DB5C69848a9eA0e81C2779Ac] = true;
        vesting[0x20f53937D5A5E868892E47b465b2566dC4664fCc] = true;
        vesting[0xe7e5E7C8E4cEb260c79eD5CF70F3f04F67108CA1] = true;
        vesting[0x44C228e902E5d5393720f95F81Fff93f908A37c1] = true;
        vesting[0x7DCF43DB8c3F75F64437bA37A5929f91CeE3F4E2] = true;
        vesting[0x4CA3e556aD23c61b63D267D2e759332F9807124C] = true;
        vesting[0x8d6fFF072dfB2AA920a40281b2Ecd7bFAF4F19e7] = true;
        vesting[0x9252C1A2Ae462Ba59e413153e339A329c992E32a] = true;
        vesting[0xe3D86e4Db20a72CFE7c22fC2ac5d70F7707FCC4a] = true;
        vesting[0x0726E03D673698197d422a0Cb13df71ED4614897] = true;
        vesting[0xeB6603B44911fd310861126929A8230AB0518DC8] = true;
        vesting[0xA9EddF55878e04112daF1aE2f2f461A0c71fA2A6] = true;
        vesting[0x1824aA03F4279FE20D9a335f0709bCC6D3ba3902] = true;
        vesting[0x7bfCdBf1A8F15c0BcD89F794B89f206E40378600] = true;
        vesting[0xcA1F15754Eb1dd30586Ae1c02a1Fb683496099ac] = true;
        vesting[0x9464De5059b6C917569888f2146d5660De7fF6BB] = true;
        vesting[0xDeBEEEF8087C07c854F3d938e0AD1E7C7f764336] = true;
        vesting[0x24037Abf1939Ad5F4EC427d31B40157BA3766F50] = true;
        vesting[0xceB4366DDBB65a95945307a41B9cA89d16e6f6dD] = true;
        vesting[0xe8C0e6b6C7E26db0E3D85CAA7dAD7102868a3f45] = true;
        vesting[0x68975cB2467b7eF623584F0807a44a61fCbaF747] = true;
        vesting[0xE62EEC84330A739987bf2156b6A516f68e28766D] = true;
        noVesting[0xfE1b3E980619D317e7dC5C0029330dc1EB33Ce6f] = true;
        noVesting[0x7147B009Ae88B5Cd0d14171639d9FB03f47afe4d] = true;
        noVesting[0xA8687cA9fF8d52eB72263197f826A3ad8C5b3493] = true;
        noVesting[0xB1424D112C2C79FcA4d5d5f892b1F13D2BADA56C] = true;
        noVesting[0x8A7ef0851CdcD40974C4b09b7A71350455a2925A] = true;
        noVesting[0x6dD77A6eb27f55Aa3B55670c4267321Fb0ACFeB7] = true;
        noVesting[0xc305F4288eb50830a0d0123ef1260B7c8cA92033] = true;
        noVesting[0xAC32e89EE0745FB6aD5Ea68A13d4E95d0Fe7BF37] = true;
        noVesting[0x8Ed6dBF56E4485776883A59a18AfAF59566E9227] = true;
        noVesting[0xd1F8b55A519EBd75571A777a8797bF4d3fAf8e39] = true;
        noVesting[0x3206fED6ebb374a748fbF77C0bE6A2E5f64488a8] = true;
        noVesting[0x07E8bC8cA5Eb3Ac83e31A49846eCBe756F6019e0] = true;
        noVesting[0x0fF85275B5415C7f6F7224f56B5F6ad5f554a057] = true;
        noVesting[0xe99EAbBCe14A0C90B168024f11f2c4e74cd80575] = true;
        noVesting[0xA7eadCB1006844F40Fa3646A61cfBbD2768156f7] = true;
        noVesting[0xc785d66201E62bcCe9a51bba85B41135dE79c599] = true;
        noVesting[0xc59E2427718547b2E856D9f7194fC218Cd12DA8a] = true;
    }

    // Token TAG Address
    IERC20 public token = IERC20(0x7A9f17D9D03402002E9Ca5d31C8472a520376Fa6);

    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function buy() public payable nonReentrant returns (bool) {
        require(
            token.balanceOf(address(this)) > 0,
            "El balance del token del contrato es igual a 0"
        );
        require(
            msg.value < token.balanceOf(address(this)),
            "No existe el balance del token en el contrato"
        );
        uint256 _first = msg.value* uint256(getLatestPrice());
        uint256 _dolar = _first/ 1000000000000000000 ;
        uint256 _cantTag = (_dolar * 10**18) / priceWhitelist;
        require(
            token.balanceOf(address(this)) > _cantTag,
            "No existe esa cantidad para comprar"
        );
        require(
            maxWhitelist * 10**16 > msg.value,
            "No puedes comprar mas de 0.5 BNB"
        );
        require(
            quantityBuy[msg.sender] + msg.value > maxWhitelist * 10**16,
            "No puedes comprar mas de 1 BNB"
        );
        if (vesting[msg.sender]) {
            quantityBuy[msg.sender] = quantityBuy[msg.sender] + msg.value;
            uint256 expend = _cantTag / 2;
            token.transfer(msg.sender, expend);
            uint256 balanceGame = _cantTag - expend;
            emit TagBalanceGame(msg.sender, balanceGame);
        } else if (noVesting[msg.sender]) {
            quantityBuy[msg.sender] = quantityBuy[msg.sender] + msg.value;
            token.transfer(msg.sender, _cantTag);
        }
        totalBuy = totalBuy + msg.value;
        emit Buy(msg.sender, msg.value);
        return true;
    }

    function buyInvestors() public payable nonReentrant returns (bool) {
        require(invest[msg.sender], "No puedes usar esta funcion");
        uint256 _first = (msg.value) * (uint256(getLatestPrice()));
        uint256 _dolar = _first / (1000000000000000000);
        uint256 _cantTag = (_dolar * 10**18) / priceWhitelist;
        uint256 quote = _cantTag / 10;
        uint256 totalTransferFirst = quote * 4;
        infoVesting[msg.sender].firstBalance = _cantTag;
        infoVesting[msg.sender].numberWithdrawal = 0;
        infoVesting[msg.sender].firstBuyDate = block.timestamp;
        infoVesting[msg.sender].quote = quote;
        infoVesting[msg.sender].lastBalance = _cantTag - totalTransferFirst;
        token.transfer(msg.sender, totalTransferFirst);

        return true;
    }

    function withdrawalVesting() public nonReentrant onlyOwner returns (bool) {
        uint8 numberWithdrawal = infoVesting[msg.sender].numberWithdrawal + 1;
        require(infoVesting[msg.sender].lastBalance > 0, "No se tiene balance");
        infoVesting[msg.sender].numberWithdrawal = numberWithdrawal;
        uint256 timeWithdrawal = infoVesting[msg.sender].firstBuyDate + numberWithdrawal * 7 days;
        require(
            block.timestamp > timeWithdrawal,
            "Aun no puedes retirar tu dinero"
        );
        require(
            infoVesting[msg.sender].lastBalance > infoVesting[msg.sender].quote,
            "No tienes la cantidad minima para retiro"
        );
        infoVesting[msg.sender].lastBalance = infoVesting[msg.sender].lastBalance - infoVesting[msg.sender].quote;
        token.transfer(msg.sender, infoVesting[msg.sender].quote);
        emit WithdrawalVesting(msg.sender, infoVesting[msg.sender].quote, infoVesting[msg.sender].lastBalance);
        return true;
    }

    function addToInvestor(address investor) public onlyOwner {
        invest[investor] = true;
    }

    function startGame() public onlyOwner {
        initGame = true;
    }

    function removeFromBlackList(address account) public onlyOwner {
        invest[account] = false;
    }
}