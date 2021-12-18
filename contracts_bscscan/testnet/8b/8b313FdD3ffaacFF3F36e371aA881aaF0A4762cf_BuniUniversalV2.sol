// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IPriceOracle.sol";
import "./interfaces/IBurToken.sol";
import "./interfaces/IBunicornRoller.sol";
import "./interfaces/ITrainerRoller.sol";
import "./interfaces/INFTNameTag.sol";
import "./interfaces/IBuniAuthorization.sol";
import "./interfaces/IERC20ConsumableItem.sol";
import "./interfaces/IvBuni.sol";

import "./TrainersV2.sol";
import "./BunicornsV2.sol";
import "./NFTMarketV2.sol";
import "./util.sol";

contract BuniUniversalV2 is Initializable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeERC20 for IERC20;
    using SafeERC20 for IBurToken;

    bytes32 public constant ROLE_GAME_CONTRACT = keccak256("ROLE_GAME_CONTRACT");

    /**
     * TODO: implement me.
     * There're some contracts which can use rewards & funds in this contract, on behalf of user
     *  - EventRegistry (for users to register & purchase event tickets)
     *  - BunicornNormalGacha (for users to mint normal bunicorns)
     *  - BunicornEventGacha (for users to mint event bunicorns)
     *  - BunicornEnhancer (for users to enhance bunicorns)
     *  - TrainerFuser (for users to fuse trainers)
     */
    bytes32 public constant ROLE_FUNDS_SPENDER = keccak256("ROLE_FUNDS_SPENDER");

    uint256 public constant MAXIMUM_GLOBAL_STAMINA = 800;
    uint256 public constant GLOBAL_STAMINA_RECOVER_SPEED_IN_SECONDS = 75; // 1 mins 15s 1 GSTA 

    int128 public constant BUR_REWARDS_CLAIM_TAX_MAX = 2767011611056432742; // = ~0.15 = ~15%
    uint256 public constant BUR_REWARDS_CLAIM_TAX_DURATION = 648000; // 7.5 days
    uint256 public constant BUR_REWARDS_CLAIM_TIMER_START = 1635292800; // 27/10/2021 00:00 UTC

    int128 public constant ONE = 18446744073709551616; // it's just number 1.0

    uint8 public constant TRAINER_STAMINA_PER_BATTLE = 40;
    uint8 public constant BUNICORN_BASE_STAMINA_PER_BATTLE = 5;

    // Average experience will be gained per battle
    uint8 public constant AVERAGE_EXP_PER_BATTLE = 32;

    // External contracts configuration for local
    // TrainersV2 public constant TRAINER_CONTRACT = TrainersV2(0x6EfE23ED5C16cF1F4e9700D2ada63Ff4971e6EBb);
    // BunicornsV2 public constant BUNICORN_CONTRACT = BunicornsV2(0xb6a78818B6B0700814b012Ae79e480F29B44ed5a);
    // IERC20 public constant BUNI_TOKEN_CONTRACT = IERC20(0x958b7F4D1eca6331C86D983b6229F6b23Ce2993a);
    // IBurToken public constant BUR_TOKEN_CONTRACT = IBurToken(0x402bA638D4cc31e5bD1D2F36F66704a6C113e2Db);
    // IPriceOracle public constant BUNI_PRICE_ORACLE = IPriceOracle(0x439B45Ef4F2eB800d066db1DC78085cb193123aF);
    // IPriceOracle public constant BUR_PRICE_ORACLE = IPriceOracle(0x5FdbABfb1CaD851D4350962752D54B3e66cE2d22);
    // address public constant TREASURY_ADDRESS = 0xF7cC551106A1f4E2843A3DA0C477B6f77FA4a09d;
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xCB2D64a25Ae21E93Fb47d590928aBE5deBB7cba1);

    // External contracts configuration for dev
    TrainersV2 public constant TRAINER_CONTRACT = TrainersV2(0xeF1AEa5bCEA4C4BBaaeEc759c1147D13625Da34d);
    BunicornsV2 public constant BUNICORN_CONTRACT = BunicornsV2(0x29766A0E52db5E4364C5Fa938BD201169EF1371B);
    IERC20 public constant BUNI_TOKEN_CONTRACT = IERC20(0x958b7F4D1eca6331C86D983b6229F6b23Ce2993a);
    IBurToken public constant BUR_TOKEN_CONTRACT = IBurToken(0x402bA638D4cc31e5bD1D2F36F66704a6C113e2Db);
    IPriceOracle public constant BUNI_PRICE_ORACLE = IPriceOracle(0x439B45Ef4F2eB800d066db1DC78085cb193123aF);
    IPriceOracle public constant BUR_PRICE_ORACLE = IPriceOracle(0x5FdbABfb1CaD851D4350962752D54B3e66cE2d22);
    address public constant TREASURY_ADDRESS = 0xF7cC551106A1f4E2843A3DA0C477B6f77FA4a09d;
    INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xea63dbEf308711F6aFDAAF5F00aa698DF796B054);
    IvBuni public constant V_BUNI = IvBuni(0x84f93172F059583f1FfC37acb94Ad6DB49199e97);

    // External contracts configuration for staging
    // TrainersV2 public constant TRAINER_CONTRACT = TrainersV2(0xF3702c494255622c8F6f9196DF586C18BC315979);
    // BunicornsV2 public constant BUNICORN_CONTRACT = BunicornsV2(0xef7102f82e19791fA86Dd7089459E0F95AD821d8);
    // IERC20 public constant BUNI_TOKEN_CONTRACT = IERC20(0x958b7F4D1eca6331C86D983b6229F6b23Ce2993a);
    // IBurToken public constant BUR_TOKEN_CONTRACT = IBurToken(0x402bA638D4cc31e5bD1D2F36F66704a6C113e2Db);
    // IPriceOracle public constant BUNI_PRICE_ORACLE = IPriceOracle(0x439B45Ef4F2eB800d066db1DC78085cb193123aF);
    // IPriceOracle public constant BUR_PRICE_ORACLE = IPriceOracle(0x5FdbABfb1CaD851D4350962752D54B3e66cE2d22);
    // address public constant TREASURY_ADDRESS = 0xF7cC551106A1f4E2843A3DA0C477B6f77FA4a09d;
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0x1aE4A04CDaB183261cDF55b5890A527e0eb78bCe);
    // IvBuni public constant V_BUNI = IvBuni(0x84f93172F059583f1FfC37acb94Ad6DB49199e97);

    // External contracts configuration for kovan
    // TrainersV2 public constant TRAINER_CONTRACT = TrainersV2(0x0A9e226f4d2a915F7AeF4df273a06313018E040B);
    // BunicornsV2 public constant BUNICORN_CONTRACT = BunicornsV2(0xa6Be997D5833EcD1B7c48325905B74198e00909f);
    // IERC20 public constant BUNI_TOKEN_CONTRACT = IERC20(0x02973feaCb614D5a7c6dc4b35D326c7d82fF6531);
    // IBurToken public constant BUR_TOKEN_CONTRACT = IBurToken(0x96fFD360B6CF986abcE523A2F10dF194C361d061);
    // IPriceOracle public constant BUNI_PRICE_ORACLE = IPriceOracle(0x5AC2952f21646d333D71D1D784559BaC80fEE205);
    // IPriceOracle public constant BUR_PRICE_ORACLE = IPriceOracle(0xcc360F961Ce3aa4bc97D8Adc2b6540aC7A5dB7cb);
    // address public constant TREASURY_ADDRESS = 0xF7cC551106A1f4E2843A3DA0C477B6f77FA4a09d;
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0x0009CF31b6d8a2D8cC4D44ccEa388D4a20f191eb);
    // IvBuni public constant V_BUNI = IvBuni(0x35D8cEdAE52B5CC11B9876F81d996FA586ccc9A5);

    // External contracts configuration for canary
    // TrainersV2 public constant TRAINER_CONTRACT = TrainersV2(0xF23e0666D1b39C560dFdF8b5639010Adb4655C7f);
    // BunicornsV2 public constant BUNICORN_CONTRACT = BunicornsV2(0x8e3939A04B0aFbE1A4fE2652C0e7aaF54f26c0c8);
    // IERC20 public constant BUNI_TOKEN_CONTRACT = IERC20(0x958b7F4D1eca6331C86D983b6229F6b23Ce2993a);
    // IBurToken public constant BUR_TOKEN_CONTRACT = IBurToken(0x402bA638D4cc31e5bD1D2F36F66704a6C113e2Db);
    // IPriceOracle public constant BUNI_PRICE_ORACLE = IPriceOracle(0x439B45Ef4F2eB800d066db1DC78085cb193123aF);
    // IPriceOracle public constant BUR_PRICE_ORACLE = IPriceOracle(0x5FdbABfb1CaD851D4350962752D54B3e66cE2d22);
    // address public constant TREASURY_ADDRESS = 0xF7cC551106A1f4E2843A3DA0C477B6f77FA4a09d;
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xBcbE2A7810fCeAb0684dD2eA3AA756c090D07391);
    // IvBuni public constant V_BUNI = IvBuni(0x84f93172F059583f1FfC37acb94Ad6DB49199e97);

    // TODO: External contracts configuration for prod
    // TrainersV2 public constant TRAINER_CONTRACT = TrainersV2(0xa40E375bBff05D982F9401311949c6970EA6e523);
    // BunicornsV2 public constant BUNICORN_CONTRACT = BunicornsV2(0x86B81f94646337879ddfEE8BCb89724f4ae721FE);
    // IERC20 public constant BUNI_TOKEN_CONTRACT = IERC20(0x0E7BeEc376099429b85639Eb3abE7cF22694ed49);
    // IBurToken public constant BUR_TOKEN_CONTRACT = IBurToken(0xc1619D98847CF93d857DFEd4e4d70CF4f984Bd56);
    // IPriceOracle public constant BUNI_PRICE_ORACLE = IPriceOracle(0xb8B429BE7009F36F6b32e125c6E9F6930d6CF218);
    // IPriceOracle public constant BUR_PRICE_ORACLE = IPriceOracle(0x2aF5cCE4292F6F2D60bc3720E684fc747cb63322);
    // address public constant TREASURY_ADDRESS = 0x0EB7bb31D8718251eEE53A8434C48078bD8A02dB;
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xe13F72a8DF31Ed12Deb410e71E94d5380e802cbe);
    // IvBuni public constant V_BUNI = IvBuni(0x7CDb479ACd5Efc8B8B432670e70665BC8a5b1234);

    // Nonce will be increment after each action, and be one of the seed factor for next randomness
    uint256 nonce;

    mapping(address => uint256) lastBlockNumberCalled;

    mapping(address => uint64) globalStaminaTimestamp;

    mapping(address => uint256) burRewards; // user adress : buni universal reward wei
    mapping(uint256 => uint256) expRewards; // trainer id : xp
    mapping(address => uint256) private _burRewardsClaimTaxTimerStart;

    /**
     * Gameplay configurations
     */
    // Fee to mint trainer, must be paid in both buni & bur in one mint
    int128 public TRAINER_MINT_FEE_BY_BUNI_MIXED_USD;
    int128 public TRAINER_MINT_FEE_BY_BUR_MIXED_USD;

    // Just reserve for future use cases
    // Fee to mint trainer, paid in buni only
    int128 public TRAINER_MINT_FEE_BY_BUNI_ONLY_USD;

    // Fee to mint trainer, paid in bur only
    int128 public TRAINER_MINT_FEE_BY_BUR_ONLY_USD;

    // UNUSED: Fee to hunt bunicorn, paid in buni only
    int128 public BUNICORN_MINT_FEE_BY_BUNI_ONLY_USD;

    // UNUSED: Fee to hunt bunicorn, paid in bur only
    int128 public BUNICORN_MINT_FEE_BY_BUR_ONLY_USD;

    int128 public BATTLE_REWARDS_GAS_OFFSET_IN_USD;
    int128 public BATTLE_REWARDS_BUR_BASELINE;

    int128 public BATTLE_BONUS_ELEMENT_EFFICIENCY;

    bool public isEmergency;

    bool public isBattlePaused;

    bool public isClaimingTokenRewardsPaused;

    IBuniAuthorization public AUTHORIZATION_CONTRACT;

    event BattleOutcome(address indexed owner, uint256 indexed trainer, uint256 bunicorn, uint32 target, uint24 playerRoll, uint24 enemyRoll, uint16 expGain, uint256 burGain);

    event TokenRewardsBurned(address indexed owner, uint256 burIngame, uint256 burWallet);

    event ExpRewardsClaimed(address indexed owner, uint256 indexed trainerId, uint256 claimedExp, uint256 expRemaining);

    event DepositedERC20(address indexed token, address indexed depositor, uint256 amount);

    function initialize() public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setEmergency(bool _isEmergency) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "game: not admin");
        isEmergency = _isEmergency;
    }

    function setBattlePaused(bool _isBattlePaused) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "game: not admin");
        isBattlePaused = _isBattlePaused;
    }

    function setClaimingTokenRewardsPaused(bool _isClaimingTokenRewardsPaused) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "game: not admin");
        isClaimingTokenRewardsPaused = _isClaimingTokenRewardsPaused;
    }

    // =========================== MODIFIER ===========================
    modifier onlyGameContract() {
        _onlyGameContract();
        _;
    }

    function _onlyGameContract() internal view {
        require(hasRole(ROLE_GAME_CONTRACT, msg.sender), "game: not game contract");
    }

    modifier onlyFundSpender() {
        _onlyFundSpender();
        _;
    }

    function _onlyFundSpender() internal view {
        require(hasRole(ROLE_FUNDS_SPENDER, msg.sender), "game: not fund spender");
    }

    modifier noEmergency() {
        _noEmergency();
        _;
    }

    function _noEmergency() internal view {
        require(!isEmergency, "game: emergency pause");
    }

    modifier battleCheck(uint256 trainer, uint256 bunicorn) {
        _onlyNonContract();
        _isTrainerOwner(trainer);
        _isBunicornOwner(bunicorn);
        _;
    }

    modifier onlyNonContract() {
        _onlyNonContract();
        _;
    }

    function _onlyNonContract() internal view {
        require(tx.origin == msg.sender, "contract forbidden");
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not game admin");
    }

    modifier oncePerBlock(address user) {
        _oncePerBlock(user);
        _;
    }

    function _oncePerBlock(address user) internal {
        require(lastBlockNumberCalled[user] < block.number, "multi call per block");
        lastBlockNumberCalled[user] = block.number;
    }

    modifier isBunicornOwner(uint256 bunicorn) {
        _isBunicornOwner(bunicorn);
        _;
    }

    function _isBunicornOwner(uint256 bunicorn) internal view {
        require(BUNICORN_CONTRACT.ownerOf(bunicorn) == msg.sender, "Not the bunicorn owner");
    }

    modifier isBunicornsOwner(uint256[] memory bunicorns) {
        _isBunicornsOwner(bunicorns);
        _;
    }

    function _isBunicornsOwner(uint256[] memory bunicorns) internal view {
        for (uint256 i = 0; i < bunicorns.length; i++) {
            _isBunicornOwner(bunicorns[i]);
        }
    }

    modifier isTrainerOwner(uint256 trainer) {
        _isTrainerOwner(trainer);
        _;
    }

    function _isTrainerOwner(uint256 trainer) internal view {
        require(TRAINER_CONTRACT.ownerOf(trainer) == msg.sender, "Not the trainer owner");
    }

    modifier isTrainersOwner(uint256[] memory trainers) {
        _isTrainersOwner(trainers);
        _;
    }

    function _isTrainersOwner(uint256[] memory trainers) internal view {
        for (uint256 i = 0; i < trainers.length; i++) {
            _isTrainerOwner(trainers[i]);
        }
    }

    modifier checkOwnership(address _tokenAddress, uint256 _id) {
        address(_tokenAddress) == address(TRAINER_CONTRACT)
            ? _isTrainerOwner(_id)
            : _isBunicornOwner(_id);
        _;
    }

    modifier validNFTType(address _tokenAddress) {
        _validNFTType(_tokenAddress);
        _;
    }

    function _validNFTType(address _tokenAddress) internal view {
        require(
            address(_tokenAddress) == address(TRAINER_CONTRACT) || address(_tokenAddress) == address(BUNICORN_CONTRACT),
            "Not support this type of NFT"
        );
    }

    modifier requestPayBurFromPlayer(int128 usdAmount) {
        _requestPayBurFromPlayer(usdAmount);
        _;
    }

    function _requestPayBurFromPlayer(int128 usdAmount) internal view {
        uint256 burAmount = usdToBur(usdAmount);
        _requestPayExtractBurFromPlayer(msg.sender, burAmount);
    }
    // =========================== MODIFIER ===========================

    function getMyTrainers() public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](TRAINER_CONTRACT.balanceOf(msg.sender));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = TRAINER_CONTRACT.tokenOfOwnerByIndex(msg.sender, i);
        }
        return tokens;
    }

    function getMyBunicorns() public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](BUNICORN_CONTRACT.balanceOf(msg.sender));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = BUNICORN_CONTRACT.tokenOfOwnerByIndex(msg.sender, i);
        }
        return tokens;
    }

    // =========================== REQUEST & PAY ===========================
    function requestPayMixedAmounts(address _player, int128 usdBuni, int128 usdBur)
        public
        view
    {
        uint256 buniAmount = usdToBuni(usdBuni);
        _requestPayOnlyExtractBuniAmount(_player, buniAmount);

        uint256 burAmount = usdToBur(usdBur);
        _requestPayExtractBurFromPlayer(_player, burAmount);
    }

    function requestPayExtractMixedAmounts(address _player, uint256 _buniAmount, uint256 _burAmount)
        public
        view
    {
        _requestPayOnlyExtractBuniAmount(_player, _buniAmount);
        _requestPayExtractBurFromPlayer(_player, _burAmount);
    }

    function requestPayOnlyBuniAmount(address _player, int128 _usdAmount) public view {
        uint256 buniAmount = usdToBuni(_usdAmount);
        _requestPayOnlyExtractBuniAmount(_player, buniAmount);
    }

    function requestPayOnlyExtractBuniAmount(address _player, uint256 _buniAmount) public view {
        _requestPayOnlyExtractBuniAmount(_player, _buniAmount);
    }

    function _requestPayOnlyExtractBuniAmount(address _player, uint256 _buniAmount) internal view {
        require(BUNI_TOKEN_CONTRACT.balanceOf(_player) >= _buniAmount, "insufficient buni");
    }

    function requestPayOnlyBurAmount(address _player, int128 _usdAmount) public view {
        uint256 burAmount = usdToBur(_usdAmount);
        _requestPayExtractBurFromPlayer(_player, burAmount);
    }

    function requestPayOnlyExtractBurAmount(address _player, uint256 _burAmount) public view {
        _requestPayExtractBurFromPlayer(_player, _burAmount);
    }

    function _requestPayBurFromPlayer(address player, int128 usdAmount) internal view {
        uint256 burAmount = usdToBur(usdAmount);
        _requestPayExtractBurFromPlayer(player, burAmount);
    }

    function _requestPayExtractBurFromPlayer(address player, uint256 burAmount) internal view {
        (, uint256 fromUserWallet) =
            _getBurToSubtract(
                burRewards[player],
                burAmount
            );

        require(BUR_TOKEN_CONTRACT.balanceOf(player) >= fromUserWallet, "insufficient bur");
    }

    function _getBurToSubtract(uint256 _burRewards, uint256 _burNeeded)
        private
        pure
        returns (uint256 fromTokenRewards, uint256 fromUserWallet) {
        
        if(_burNeeded <= _burRewards) {
            return (_burNeeded, 0);
        }

        _burNeeded -= _burRewards;

        return (_burRewards, _burNeeded);
    }

    function payMixedAmounts(address _player, int128 usdBuni, int128 usdBur)
        public
        onlyFundSpender
        oncePerBlock(_player)
    {
        uint256 buniAmount = usdToBuni(usdBuni);
        _payToTreasury(_player, buniAmount);

        uint256 burAmount = usdToBur(usdBur);
        _payBurContractConverted(_player, burAmount);
    }

    function payExtractMixedAmounts(address _player, uint256 _buniAmount, uint256 _burAmount)
        public
    {
        _payToTreasury(_player, _buniAmount);
        _payBurContractConverted(_player, _burAmount);
    }

    function payOnlyBuniAmount(address _player, int128 _usdAmount)
        public
        onlyFundSpender
        oncePerBlock(_player)
    {
        uint256 buniAmount = usdToBuni(_usdAmount);
        _payToTreasury(_player, buniAmount);
    }

    function payOnlyExtractBuniAmount(address _player, uint256 _buniAmount)
        public
        onlyFundSpender
        oncePerBlock(_player)
    {
        _payToTreasury(_player, _buniAmount);
    }

    function payOnlyBurAmount(address _player, int128 _usdAmount)
        public
        onlyFundSpender
        oncePerBlock(_player)
    {
        uint256 burAmount = usdToBur(_usdAmount);
        _payBurContractConverted(_player, burAmount);
    }

    function payOnlyExtractBurAmount(address _player, uint256 _burAmount)
        public
        onlyFundSpender
        oncePerBlock(_player)
    {
        _payBurContractConverted(_player, _burAmount);
    }

    function payOnlyExtractBurAmountForLottery(address _player, address _lottery, uint256 _burAmount)
        public
        onlyFundSpender
        oncePerBlock(_player)
    {
        (uint256 fromTokenRewards, uint256 fromUserWallet) =
            _payBurContractConvertedForLottery(_player, _burAmount);

        if (fromTokenRewards > 0) {
            BUR_TOKEN_CONTRACT.mint(_lottery, fromTokenRewards);
        }

        if (fromUserWallet > 0 ) {
            BUR_TOKEN_CONTRACT.safeTransferFrom(_player, _lottery, fromUserWallet);
        }

        emit TokenRewardsBurned(_player, fromTokenRewards, fromUserWallet);
    }

    function payOnlyExtractBurAmountForLotteryWithOffchain(
        address _player,
        address _lottery,
        uint256 _onchainAmount,
        uint256 _offchainAmount
    )
        public
        onlyFundSpender
        oncePerBlock(_player)
    {
        (uint256 fromTokenRewards, uint256 fromUserWallet) =
            _payBurContractConvertedForLottery(_player, _onchainAmount);

        uint256 totalMintAmount = fromTokenRewards.add(_offchainAmount);
        if (totalMintAmount > 0) {
            BUR_TOKEN_CONTRACT.mint(_lottery, totalMintAmount);
        }

        if (fromUserWallet > 0 ) {
            BUR_TOKEN_CONTRACT.safeTransferFrom(_player, _lottery, fromUserWallet);
        }

        emit TokenRewardsBurned(_player, fromTokenRewards, fromUserWallet);
    }

    function _payToTreasury(address playerAddress, uint256 convertedAmount) internal {
        if (convertedAmount > 0) {
            BUNI_TOKEN_CONTRACT.transferFrom(playerAddress, TREASURY_ADDRESS, convertedAmount);
        }
    }

    function _payBurContract(address playerAddress, int128 usdAmount) internal
        returns (uint256 _fromTokenRewards, uint256 _fromUserWallet) {

        return _payBurContractConverted(playerAddress, usdToBur(usdAmount));
    }

    function _payBurContractConverted(address playerAddress, uint256 convertedAmount) internal
        returns (uint256 _fromTokenRewards, uint256 _fromUserWallet) {
        
        (uint256 fromTokenRewards, uint256 fromUserWallet) =
            _getBurToSubtract(
                burRewards[playerAddress],
                convertedAmount
            );

        burRewards[playerAddress] = burRewards[playerAddress].sub(fromTokenRewards);
        if (fromUserWallet > 0) {
            BUR_TOKEN_CONTRACT.burnFrom(playerAddress, fromUserWallet);
        }

        emit TokenRewardsBurned(playerAddress, fromTokenRewards, fromUserWallet);

        return (fromTokenRewards, fromUserWallet);
    }

    function _payBurContractConvertedForLottery(address playerAddress, uint256 convertedAmount) internal
        returns (uint256 _fromTokenRewards, uint256 _fromUserWallet) {
        
        (uint256 fromTokenRewards, uint256 fromUserWallet) =
            _getBurToSubtract(
                burRewards[playerAddress],
                convertedAmount
            );

        burRewards[playerAddress] = burRewards[playerAddress].sub(fromTokenRewards);
        return (fromTokenRewards, fromUserWallet);
    }

    function _payBurPlayerConverted(address playerAddress, uint256 convertedAmount) internal {
        BUR_TOKEN_CONTRACT.mint(playerAddress, convertedAmount);
    }

    function requestPayERC20ConsumableItem(
        IERC20ConsumableItem token, address player, uint256 amount
    ) external view {
        _requestPayERC20ConsumableItem(token, player, amount);
    }

    function _requestPayERC20ConsumableItem(
        IERC20ConsumableItem token, address player, uint256 amount
    ) internal view {
        require(token.balanceOf(player) >= amount, "insufficient items");
    }

    function payERC20ConsumableItems(
        IERC20ConsumableItem token, address player, uint256 amount
    ) external {
        _payERC20ConsumableItems(token, player, amount);
    }

    function _payERC20ConsumableItems(
        IERC20ConsumableItem token, address player, uint256 amount
    ) internal {
        require(address(token) != address(0), "item invalid");
        require(player != address(0), "player invalid");

        if (amount > 0) {
            token.burnFrom(player, amount);
        }
    }
    // =========================== REQUEST & PAY ===========================

    // =========================== SETTER ===========================
    function setAuthorizationContract(IBuniAuthorization _authorizationContract) external restricted {
        AUTHORIZATION_CONTRACT = _authorizationContract;
    }
    // =========================== SETTER ===========================

    function usdToBuni(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(BUNI_PRICE_ORACLE.currentPrice());
    }

    function usdToBur(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(BUR_PRICE_ORACLE.currentPrice());
    }

    // =========================== REWARD ===========================
    function claimTokenRewards() public noEmergency {
        require(!isClaimingTokenRewardsPaused, "game: claiming rewards is paused");
        // our trainers go to the tavern
        // and the barkeep pays them for the bounties
        uint256 _burRewards = burRewards[msg.sender];
        burRewards[msg.sender] = 0;

        uint256 _burRewardsToPayOut = _burRewards.sub(
            _getBurRewardsClaimTax().mulu(_burRewards)
        );

        _payBurPlayerConverted(msg.sender, _burRewardsToPayOut);
    }

    function claimTokenRewardsWithSig(
        uint256 _rewardAmount, uint128 _requestId, bytes memory _signature
    ) external noEmergency {
        require(!isClaimingTokenRewardsPaused, "game: claiming rewards is paused");

        bytes32 _message = keccak256(
            abi.encodePacked(msg.sender, "claimTokenRewardsWithSig", _rewardAmount, _requestId)
        );

        AUTHORIZATION_CONTRACT.authorize(_message, _requestId, _signature);

        _payBurPlayerConverted(msg.sender, _rewardAmount);
    }

    function claimBuniRewardsWithSig(
        uint256 _rewardAmount, uint128 _requestId, bytes memory _signature
    ) external noEmergency {
        require(!isClaimingTokenRewardsPaused, "game: claiming rewards is paused");
        require(BUNI_TOKEN_CONTRACT.balanceOf(address(this)) >= _rewardAmount, "insufficient buni");

        bytes32 _message = keccak256(
            abi.encodePacked(msg.sender, "claimBuniRewardsWithSig", _rewardAmount, _requestId)
        );

        AUTHORIZATION_CONTRACT.authorize(_message, _requestId, _signature);

        V_BUNI.mint(msg.sender, 1000000, _rewardAmount, block.timestamp + 2592000);
    }

    function claimExpRewards() public noEmergency {
        // our trainers go to the tavern to rest
        // they meditate on what they've learned
        for(uint256 i = 0; i < TRAINER_CONTRACT.balanceOf(msg.sender); i++) {
            uint256 trainer = TRAINER_CONTRACT.tokenOfOwnerByIndex(msg.sender, i);

            // maxClaimExp at trainer's current level, max 65535, (2^16-1)
            uint256 maxClaimExp = TRAINER_CONTRACT.getMaxClaimExp(trainer);
            // exp claim in one shot is the min of maxClaimExp and current trainer's exp
            uint256 expRewardsToClaim = expRewards[trainer] > maxClaimExp ? maxClaimExp : expRewards[trainer];
            expRewards[trainer] = expRewards[trainer].sub(expRewardsToClaim);
            TRAINER_CONTRACT.claimExp(trainer, uint16(expRewardsToClaim));
        }
    }

    function claimExpRewardWithSig(
        uint256 _trainer, uint256 _expRewards,
        uint128 _requestId, bytes memory _signature
    ) external noEmergency {
        bytes32 _message = keccak256(
            abi.encodePacked(msg.sender, "claimExpRewardWithSig", _trainer, _expRewards, _requestId)
        );
        AUTHORIZATION_CONTRACT.authorize(_message, _requestId, _signature);

        _claimExpRewardsWithSig(_trainer, _expRewards);
    }

    function claimExpRewardsWithSig(
        uint256[] memory _trainers, uint256[] memory _expRewards,
        uint128 _requestId, bytes memory _signature
    ) external noEmergency {
        require(_trainers.length == _expRewards.length, "invalid length");
        bytes32 _message = keccak256(
            abi.encodePacked(msg.sender, "claimExpRewardsWithSig", _trainers, _expRewards, _requestId)
        );
        AUTHORIZATION_CONTRACT.authorize(_message, _requestId, _signature);

        for (uint256 i = 0; i < _trainers.length; i++) {
            _claimExpRewardsWithSig(_trainers[i], _expRewards[i]);
        }
    }

    function _claimExpRewardsWithSig(
        uint256 _trainer, uint256 _expRewards
    ) internal {
        // ignore when token is burned
        if (!TRAINER_CONTRACT.tokenExists(_trainer)) {
            return;
        }
        // maxClaimExp at trainer's current level, max 65535, (2^16-1)
        uint256 maxClaimExp = TRAINER_CONTRACT.getMaxClaimExp(_trainer);
        // exp claim in one shot is the min of maxClaimExp and current trainer's exp
        uint256 expRewardsToClaim = _expRewards > maxClaimExp ? maxClaimExp : _expRewards;
        TRAINER_CONTRACT.claimExp(_trainer, uint16(expRewardsToClaim));

        uint256 expRemaining = 0;
        if (_expRewards > maxClaimExp) {
            expRemaining = _expRewards - maxClaimExp;
            expRewards[_trainer] = expRewards[_trainer].add(expRemaining);
        }

        emit ExpRewardsClaimed(msg.sender, _trainer, expRewardsToClaim, expRemaining);
    }

    function levelUpBunicornWithSig(
        uint256 _bunicorn, uint8 _nextlevel,
        uint128 _requestId, bytes memory _signature
    ) external noEmergency isBunicornOwner(_bunicorn) {
        uint8 currentLevel = BUNICORN_CONTRACT.getLevel(_bunicorn);
        require(currentLevel < _nextlevel, "Level not change");

        bytes32 _message = keccak256(
            abi.encodePacked(msg.sender, "levelUpBunicornWithSig", _bunicorn, currentLevel, _nextlevel, _requestId)
        );
        AUTHORIZATION_CONTRACT.authorize(_message, _requestId, _signature);

        BUNICORN_CONTRACT.levelUp(_bunicorn, _nextlevel);
    }

    function getTokenRewardsFor(address wallet) public view returns (uint256) {
        return burRewards[wallet];
    }

    function getExpRewards(uint256 trainer) public view returns (uint256) {
        return expRewards[trainer];
    }

    function _getBurRewardsClaimTax() internal view returns (int128) {
        assert(BUR_REWARDS_CLAIM_TIMER_START <= block.timestamp);

        uint256 burRewardsClaimTaxTimerEnd = BUR_REWARDS_CLAIM_TIMER_START.add(BUR_REWARDS_CLAIM_TAX_DURATION);

        (, uint256 durationUntilNoTax) = burRewardsClaimTaxTimerEnd.trySub(block.timestamp);

        assert(0 <= durationUntilNoTax && durationUntilNoTax <= BUR_REWARDS_CLAIM_TAX_DURATION);

        int128 frac = ABDKMath64x64.divu(durationUntilNoTax, BUR_REWARDS_CLAIM_TAX_DURATION);

        return BUR_REWARDS_CLAIM_TAX_MAX.mul(frac);
    }

    function getOwnRewardsClaimTax() public view returns (int128) {
        return _getBurRewardsClaimTax();
    }
    // =========================== REWARD ===========================

    // =========================== GLOBAL STAMINA ===========================
    function _getMaxGlobalStaminaCooldown() internal pure returns (uint64) {
        return uint64(MAXIMUM_GLOBAL_STAMINA * GLOBAL_STAMINA_RECOVER_SPEED_IN_SECONDS);
    }

    function getGlobalStaminaTimestamp(address _playerAddress) internal view returns (uint64) {
        return globalStaminaTimestamp[_playerAddress];
    }

    function getGlobalStaminaPoints(address _playerAddress) public view returns (uint16) {
        return _getGlobalStaminaPointsFromTimestamp(globalStaminaTimestamp[_playerAddress]);
    }

    function _getGlobalStaminaPointsFromTimestamp(uint64 _timestamp) internal view returns (uint16) {
        if(_timestamp  > now) {
            return 0;
        }

        uint256 points = (now - _timestamp) / GLOBAL_STAMINA_RECOVER_SPEED_IN_SECONDS;
        if(points > MAXIMUM_GLOBAL_STAMINA) {
            points = MAXIMUM_GLOBAL_STAMINA;
        }
        return uint16(points);
    }

    function isGlobalStaminaFull(address _playerAddress) public view returns (bool) {
        return getGlobalStaminaPoints(_playerAddress) >= MAXIMUM_GLOBAL_STAMINA;
    }

    function drainGlobalStamina(address _playerAddress, uint8 _globalStamina) internal {
        uint16 globalStaminaPoints = _getGlobalStaminaPointsFromTimestamp(globalStaminaTimestamp[_playerAddress]);
        require(globalStaminaPoints >= _globalStamina, "insufficient player stamina");
        uint64 drainTime = uint64(_globalStamina * GLOBAL_STAMINA_RECOVER_SPEED_IN_SECONDS);
        if(globalStaminaPoints >= MAXIMUM_GLOBAL_STAMINA) {
            globalStaminaTimestamp[_playerAddress] = uint64(now - _getMaxGlobalStaminaCooldown() + drainTime);
        }
        else {
            globalStaminaTimestamp[_playerAddress] = uint64(globalStaminaTimestamp[_playerAddress] + drainTime);
        }
    }
    // =========================== GLOBAL STAMINA ===========================

    // =========================== NFT NAME TAG ===========================
    function setTrainerTag(uint256 _tokenId, string calldata _tag)
        external
        isTrainerOwner(_tokenId) {

        int128 fee = NAME_TAG_CONTRACT.getRenameTagValue();
        _requestPayBurFromPlayer(fee);

        _payBurContract(msg.sender, fee);
        NAME_TAG_CONTRACT.setNameTag(address(TRAINER_CONTRACT), _tokenId, _tag);
    }

    function setBunicornTag(uint256 _tokenId, string calldata _tag)
        external
        isBunicornOwner(_tokenId) {

        int128 fee = NAME_TAG_CONTRACT.getRenameTagValue();
        _requestPayBurFromPlayer(fee);

        _payBurContract(msg.sender, fee);
        NAME_TAG_CONTRACT.setNameTag(address(BUNICORN_CONTRACT), _tokenId, _tag);
    }
    // =========================== NFT NAME TAG ===========================

    // =========================== DEPOSIT ===========================
    function depositERC20(IERC20 _token, uint256 _amount)
        external
        onlyNonContract
    {
        require(_amount > 0, "amount zero");
        if (address(_token) == address(BUNI_TOKEN_CONTRACT)) {
            // handle if user deposit BUNI
            _requestPayOnlyExtractBuniAmount(msg.sender, _amount);
            BUNI_TOKEN_CONTRACT.transferFrom(msg.sender, address(this), _amount);
        }
        else if (address(_token) == address(BUR_TOKEN_CONTRACT)) {
            // handle if user deposit BUR
            require(BUR_TOKEN_CONTRACT.balanceOf(msg.sender) >= _amount, "insufficient bur");
            BUR_TOKEN_CONTRACT.burnFrom(msg.sender, _amount);
        }
        else {
            // handle if user deposit consumable items
            _requestPayERC20ConsumableItem(IERC20ConsumableItem(address(_token)), msg.sender, _amount);
            _payERC20ConsumableItems(IERC20ConsumableItem(address(_token)), msg.sender, _amount);
        }

        emit DepositedERC20(address(_token), msg.sender, _amount);
    }

    // =========================== DEPOSIT ===========================

    // =========================== INSTANT SELL ===========================
    function instantSellNFTWithSig(
        address _tokenAddress,
        uint256 _id,
        uint256 _sellPrice,
        uint128 _requestId,
        bytes memory _signature
    )
        external
        onlyNonContract
        validNFTType(_tokenAddress)
        checkOwnership(_tokenAddress, _id)
    {
        // create sig
        bytes32 message = keccak256(
            abi.encodePacked(msg.sender, "instantSellNFTWithSig", address(_tokenAddress), _id, _sellPrice, _requestId)
        );
        // authorize
        AUTHORIZATION_CONTRACT.authorize(message, _requestId, _signature);

        if (address(_tokenAddress) == address(TRAINER_CONTRACT)) {
            TRAINER_CONTRACT.burnByGameContract(_id);
        }   else {
            BUNICORN_CONTRACT.burnByGameContract(_id);
        }
        
        BUNI_TOKEN_CONTRACT.transfer(msg.sender, _sellPrice);
    }
    // =========================== INSTANT SELL ===========================
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
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

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m)));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << uint256 (127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= uint256 (63 - (x >> 64));
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= uint256 (xe);
      else x <<= uint256 (-xe);

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= uint256 (re);
      else if (re < 0) result >>= uint256 (-re);

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
      if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
      if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
      if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
      if (xx >= 0x100) { xx >>= 8; r <<= 4; }
      if (xx >= 0x10) { xx >>= 4; r <<= 2; }
      if (xx >= 0x8) { r <<= 1; }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // Seven iterations should be enough
      uint256 r1 = x / r;
      return uint128 (r < r1 ? r : r1);
    }
  }
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
pragma solidity 0.6.12;

interface IPriceOracle {
    // Views
    function currentPrice() external view returns (uint256 price);

    // Mutative
    function setCurrentPrice(uint256 price) external;

    // Events
    event CurrentPriceUpdated(uint256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBurToken is IERC20 {
    function mint(address _to, uint256 _value) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBunicornRoller {
    function mintOneRandomBunicornWithStar(
        address minter,
        uint8 stars,
        uint256 randomSeed
    ) external returns(uint256);

    function mintOneRandomBunicornWithStarsProbSpecs(
        address minter,
        uint256 starsProbSpecs,
        uint256 randomSeed
    ) external returns(uint256);

    function mintOneRandomBunicornWithElementAndStarsProbSpecs(
        address minter,
        uint8 element,
        uint256 starsProbSpecs,
        uint256 randomSeed
    ) external returns(uint256);

    function mintOneRandomEventBunicornWithElementAndStarsProbSpecs(
        address minter,
        uint8 element,
        uint256 starsProbSpecs,
        uint256 randomSeed,
        uint16 _eventId
    ) external returns(uint256);

    function mintOneRandomBunicornWithStarAndElement(
        address minter,
        uint8 stars,
        uint8 element,
        uint256 randomSeed
    ) external returns(uint256);

    function mintOneRandomEventBunicornWithStarAndElement(
        address minter,
        uint8 stars,
        uint8 element,
        uint256 randomSeed,
        uint16 _eventId
    ) external returns(uint256);

    function rollAttributesFromStars(
        uint8 _stars,
        uint256 _seed
    ) external returns (uint16, uint16, uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./v2.0/ITrainersV2.sol";

interface ITrainerRoller {
    function mintOneRandomTrainer(address minter, uint256 _randomSeed) external;
    function getTrainersContract() external view returns (ITrainersV2 _trainersContract);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface INFTNameTag {
  function getRenameTagValue() external view returns(int128);
  function getNameTag(address _tokenAddress, uint256 _tokenId) external view returns(string memory);
  function setNameTag(address _tokenAddress, uint256 _tokenId, string calldata _tag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBuniAuthorization {
    function authorize(
        bytes32 _message,
        uint128 _requestId,
        bytes memory _signature
    ) external;

    function revoke(
        bytes32 _message,
        uint128 _requestId,
        bytes memory _signature
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20ConsumableItem is IERC20Upgradeable {
    function mint(address account, uint256 amount) external;
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;
    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IvBuni is IERC721Upgradeable {
    function getTokenInfo(uint256 tokenId)
        external
        view
        returns (
            uint256 poolId,
            uint256 amount,
            uint256 vestedAt,
            uint256 createdAt
        );

    function getTokenInfoOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (
            uint256 poolId,
            uint256 amount,
            uint256 vestedAt,
            uint256 tokenId
        );

    function mint(address to, uint256 poolId, uint256 buniAmount, uint256 vestedTimestamp) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./util.sol";

import "./interfaces/v2.0/ITrainersV2.sol";
import "./interfaces/INFTNameTag.sol";

contract TrainersV2 is ITrainersV2, Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    using SafeMath for uint16;
    using SafeMath for uint8;

    bytes32 public constant ROLE_GAME_CONTRACT = keccak256("ROLE_GAME_CONTRACT");
    bytes32 public constant ROLE_NOT_LOCK_NEXT_TRANSFER = keccak256("ROLE_NOT_LOCK_NEXT_TRANSFER");
    bytes32 public constant ROLE_GOVERNANCE = keccak256("ROLE_GOVERNANCE");

    uint256 public constant TRANSFER_COOLDOWN_IN_SECONDS = 1 days;
    uint256 public constant VOTING_TRANSFER_COOLDOWN_IN_SECONDS = 2 days;

    uint256 public constant MAXIMUM_STAMINA = 200;
    uint256 public constant STAMINA_RECOVER_SPEED_IN_SECONDS = 300; // 5 mins 1 STA

    // local contract
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xCB2D64a25Ae21E93Fb47d590928aBE5deBB7cba1);

    // dev contract
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xea63dbEf308711F6aFDAAF5F00aa698DF796B054);

    // kovan contract
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0x0009CF31b6d8a2D8cC4D44ccEa388D4a20f191eb);

    // staging contract
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0x1aE4A04CDaB183261cDF55b5890A527e0eb78bCe);

    // canary contract
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xBcbE2A7810fCeAb0684dD2eA3AA756c090D07391);

    // TODO: prod contract
    INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xe13F72a8DF31Ed12Deb410e71E94d5380e802cbe);

    function initialize () public initializer {
        __ERC721_init("Buni Universal Trainer", "BUT");
        __AccessControl_init_unchained();
        // set admin role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        fusionMilestones = [9, 19, 29, 39, 49, 99, 149, 199, 249, 255];
    }

    function setExperiences(uint256[255] memory _experiences) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        for (uint256 i = 0; i < _experiences.length; i++) {
            experiences[i] = _experiences[i];
        }
    }

    function setPowers(uint256[255] memory _powers) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        for (uint256 i = 0; i < _powers.length; i++) {
            powers[i] = _powers[i];
        }
    }

    function setEmergencyPause(bool _isEmergencyPause) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        isEmergencyPause = _isEmergencyPause;
    }
    
    function banTokens(uint256[] memory tokenIds) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bannedIds[tokenIds[i]] = true;
        }
    }
    
    function unbanTokens(uint256[] memory tokenIds) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bannedIds[tokenIds[i]] = false;
        }
    }

    function banAddresses(address[] memory addrs) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        for (uint256 i = 0; i < addrs.length; i++) {
            bannedAddresses[addrs[i]] = true;
        }
    }

    function unbanAddresses(address[] memory addrs) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        for (uint256 i = 0; i < addrs.length; i++) {
            bannedAddresses[addrs[i]] = false;
        }
    }

    struct Trainer {
        uint16 exp;
        uint8 level;
        uint8 element;
    }

    Trainer[] internal trainers;

    uint256[256] private experiences;
    uint256[256] private powers;

    uint8[] private fusionMilestones;

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    mapping(uint256 => uint8) private lastFusionLevel;

    mapping(uint256 => uint64) staminaTimestamp;

    mapping(uint256 => uint256) public lastTransferTimestamp;

    bool public isEmergencyPause;

    mapping(uint256 => bool) private bannedIds;

    mapping(address => bool) private bannedAddresses;

    mapping(uint256 => uint256) public lastVotingTransferTimestamp;

    event NewTrainer(uint256 indexed trainer, address indexed minter);

    event LevelUp(address indexed owner, uint256 indexed trainer, uint16 level);

    event Fused(address indexed owner, uint256 indexed fused, uint256 indexed burned);

    event FuseFailure(address indexed owner, uint256 indexed fuseID, uint256 indexed burnID);

    modifier onlyGameContract() {
        _onlyGameContract();
        _;
    }

    function _onlyGameContract() internal view {
        require(hasRole(ROLE_GAME_CONTRACT, msg.sender), "trainer: not game contract");
    }

    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }

    function _onlyGovernance() internal view {
        require(hasRole(ROLE_GOVERNANCE, msg.sender), "trainer: not governance contract");
    }

    modifier notInEmergencyPause() {
        _notInEmergencyPause();
        _;
    }

    function _notInEmergencyPause() internal view {
        require(!isEmergencyPause, "trainer: emergency pause");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    function _noFreshLookup(uint256 id) internal view {
        require(id < firstMintedOfLastBlock || lastMintedBlock < block.number, "Too fresh for lookup");
    }

    function transferCooldownEnd(uint256 tokenId) public view returns (uint256) {
        return lastTransferTimestamp[tokenId].add(TRANSFER_COOLDOWN_IN_SECONDS);
    }

    function transferCooldownLeft(uint256 tokenId) public view returns (uint256) {
        (bool success, uint256 secondsLeft) =
            lastTransferTimestamp[tokenId].trySub(
                block.timestamp.sub(TRANSFER_COOLDOWN_IN_SECONDS)
            );

        return success ? secondsLeft : 0;
    }

    function votingTransferCooldownEnd(uint256 tokenId) public view returns (uint256) {
        return lastVotingTransferTimestamp[tokenId].add(VOTING_TRANSFER_COOLDOWN_IN_SECONDS);
    }

    function votingTransferCooldownLeft(uint256 tokenId) public view returns (uint256) {
        (bool success, uint256 secondsLeft) =
            lastVotingTransferTimestamp[tokenId].trySub(
                block.timestamp.sub(VOTING_TRANSFER_COOLDOWN_IN_SECONDS)
            );

        return success ? secondsLeft : 0;
    }

    function get(uint256 id) public view noFreshLookup(id) 
        returns (uint16 _exp, uint8 _level, uint8 _element, uint64 _staminaTimestamp, uint24 _power, string memory _tag) {

        Trainer memory trainer = trainers[id];
        _exp = trainer.exp;
        _level = trainer.level;
        _element = trainer.element;
        _staminaTimestamp = staminaTimestamp[id];
        _power = uint24(powers[trainer.level]);

        _tag = NAME_TAG_CONTRACT.getNameTag(address(this), id);
    }

    function getMaxStaminaCooldown() public pure returns (uint64) {
        return _getMaxStaminaCooldown();
    }

    function _getMaxStaminaCooldown() private pure returns (uint64) {
        return uint64(MAXIMUM_STAMINA * STAMINA_RECOVER_SPEED_IN_SECONDS);
    }

    function getLevel(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return trainers[id].level;
    }

    function getRequiredExpForNextLevel(uint8 _level) public view returns (uint16) {
        return uint16(experiences[_level]);
    }

    function getTrainerPower(uint256 id) external view noFreshLookup(id) returns (uint24) {
        return _getTrainerPowerAtLevel(trainers[id].level);
    }  

    function _getTrainerPowerAtLevel(uint8 level) private view returns (uint24) {
        return uint24(powers[level]);
    }

    function getElement(uint256 id) external view noFreshLookup(id) returns (uint8) {
        return trainers[id].element;
    }

    function getTrainerExp(uint256 id) public view noFreshLookup(id) returns (uint32) {
        return trainers[id].exp;
    }

    function getStaminaTimestamp(uint256 id) public view noFreshLookup(id) returns (uint64) {
        return staminaTimestamp[id];
    }

    function setStaminaTimestamp(uint256 id, uint64 _timestamp) public onlyGameContract {
        staminaTimestamp[id] = _timestamp;
    }

    function getStaminaPoints(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return _getStaminaPointsFromTimestamp(staminaTimestamp[id]);
    }

    function _getStaminaPointsFromTimestamp(uint64 _timestamp) private view returns (uint8) {
        if(_timestamp  > now) {
            return 0;
        }

        uint256 points = (now - _timestamp) / STAMINA_RECOVER_SPEED_IN_SECONDS;
        if(points > MAXIMUM_STAMINA) {
            points = MAXIMUM_STAMINA;
        }
        return uint8(points);
    }

    function isStaminaFull(uint256 id) public view noFreshLookup(id) returns (bool) {
        return getStaminaPoints(id) >= MAXIMUM_STAMINA;
    }

    // =========================== MINT ===========================
    function mintOneTrainerBySpecs(address _minter, uint8 _element) external override onlyGameContract notInEmergencyPause {
        uint256 tokenID = trainers.length;

        if(block.number != lastMintedBlock) {
            firstMintedOfLastBlock = tokenID;
        }
        lastMintedBlock = block.number;

        uint16 exp = 0;
        uint8 level = 0;

        trainers.push(Trainer(exp, level, _element));
        _mint(_minter, tokenID);

        staminaTimestamp[tokenID] = uint64(now.sub(_getMaxStaminaCooldown()));

        emit NewTrainer(tokenID, _minter);
    }

    function mintOneTrainerBySpecsByAdmin(address _minter, uint8 _element, uint8 _level) external override onlyGameContract notInEmergencyPause {
        uint256 tokenID = trainers.length;

        if(block.number != lastMintedBlock) {
            firstMintedOfLastBlock = tokenID;
        }
        lastMintedBlock = block.number;

        uint16 exp = 0;
        uint8 level = _level;

        trainers.push(Trainer(exp, level, _element));
        _mint(_minter, tokenID);

        staminaTimestamp[tokenID] = uint64(now.sub(_getMaxStaminaCooldown()));

        emit NewTrainer(tokenID, _minter);
    }
    // =========================== MINT ===========================

    // =========================== BATTLE ===========================
    function getBattleDataAndDrainStamina(uint256 id, uint8 _stamina) external onlyGameContract notInEmergencyPause returns(uint96) {
        Trainer storage trainer = trainers[id];
        uint8 staminaPoints = _getStaminaPointsFromTimestamp(staminaTimestamp[id]);
        require(staminaPoints >= _stamina, "insufficient trainer stamina");

        uint64 drainTime = uint64(_stamina * STAMINA_RECOVER_SPEED_IN_SECONDS);
        uint64 preTimestamp = staminaTimestamp[id];
        if(staminaPoints >= MAXIMUM_STAMINA) {
            staminaTimestamp[id] = uint64(now - _getMaxStaminaCooldown() + drainTime);
        }
        else {
            staminaTimestamp[id] = uint64(staminaTimestamp[id] + drainTime);
        }
        return uint96(trainer.element | (uint96(_getTrainerPowerAtLevel(trainer.level)) << 8) | (uint96(preTimestamp) << 32));
    }
    // =========================== BATTLE ===========================

    // =========================== FUSION ===========================
    function getFusionMilestones() public view returns(uint8[] memory) {
        uint8[] memory milestones = new uint8[](fusionMilestones.length);
        for (uint8 i = 0; i < fusionMilestones.length; i++) {
            milestones[i] = fusionMilestones[i];
        }
        return milestones;
    }

    function getLastFusionLevel(uint256 id) public view returns(uint8) {
        return lastFusionLevel[id];
    }

    function hasFused(uint256 id) public view returns(bool) {
        uint8 trainerLevel = trainers[id].level;
        return lastFusionLevel[id] == _getFusionMaxLevel(trainerLevel);
    }

    function fuse(uint256 _fusionID, uint256 _burnID) public onlyGameContract notInEmergencyPause {
        uint8 trainerLevel = trainers[_fusionID].level;
        uint8 burnTrainerLevel = trainers[_burnID].level;

        require(trainerLevel < 255 && trainerLevel.add(1).div(10) < experiences.length.div(10), "Fusion unnecessary");
        require(
            _getFusionMinLevel(trainerLevel) <= burnTrainerLevel && burnTrainerLevel <= trainerLevel,
            "Burn trainer not the same level range"
        );
        if (lastFusionLevel[_fusionID] != 0) {
            require(lastFusionLevel[_fusionID] < trainerLevel, "cannot fuse twice per level");
        }

        lastFusionLevel[_fusionID] = _getFusionMaxLevel(trainerLevel);
        _burn(_burnID);

        emit Fused(ownerOf(_fusionID), _fusionID, _burnID);
    }

    function fuseFailure(uint256 _fusionID, uint256 _burnID) public onlyGameContract notInEmergencyPause {
        // Burn the burnt bunicorn
        _burn(_burnID);

        emit FuseFailure(ownerOf(_fusionID), _fusionID, _burnID);
    }

    function _getFusionMinLevel(uint8 _level) internal view returns(uint8 minLevel) {
        if (_level <= fusionMilestones[0]) {
            return 0;
        }

        for (uint8 i = 0; i < fusionMilestones.length; i++) {
            if (_level <= fusionMilestones[i]) {
                break;
            }
            minLevel = fusionMilestones[i] + 1;
        }
    }

    function _getFusionMaxLevel(uint8 _level) internal view returns(uint8 maxLevel) {
        for (uint8 i = 0; i < fusionMilestones.length; i++) {
            maxLevel = fusionMilestones[i];
            if (_level <= fusionMilestones[i]) {
                break;
            }
        }
    }
    // =========================== FUSION ===========================

    // =========================== CLAIM EXP ===========================
    function claimExp(uint256 id, uint16 exp) public onlyGameContract notInEmergencyPause {
        Trainer storage trainer = trainers[id];
        if(trainer.level < 255) {
            uint newExp = trainer.exp.add(exp);
            uint totalExpToLevel = experiences[trainer.level];
            while(newExp >= totalExpToLevel) {
                newExp = newExp - totalExpToLevel;
                trainer.level += 1;
                emit LevelUp(ownerOf(id), id, trainer.level);
                if(trainer.level < 255)
                    totalExpToLevel = experiences[trainer.level];
                else
                    newExp = 0;
            }
            trainer.exp = uint16(newExp);
        }
    }

    function getMaxClaimExp(uint256 id) public view returns(uint256) {
        Trainer storage trainer = trainers[id];
        if (trainer.level < 255) {
            uint256 maxClaimExp = 0;
            uint8 maxLevel = _levelMax(id);
            for (uint8 i = trainer.level; i <= maxLevel; i++) {
                maxClaimExp = maxClaimExp.add(experiences[i]);
            }
            if (maxClaimExp > trainer.exp && maxLevel != 254) {
                maxClaimExp = maxClaimExp.sub(trainer.exp).sub(1);
            }
            if (maxClaimExp > 65535) {
                maxClaimExp = 65535;
            }
            return maxClaimExp;
        }
        return 0;
    }

    function _levelMax(uint256 id) internal view returns(uint8) {
        uint8 level = trainers[id].level;
        uint8 maxLevel = _getFusionMaxLevel(level);
        // check if trainer has fused
        if (maxLevel == lastFusionLevel[id]) {
            // move to next
            for (uint8 i = 0; i < fusionMilestones.length; i++) {
                if (maxLevel < fusionMilestones[i]) {
                    maxLevel = fusionMilestones[i];
                    break;
                }
            }
        }

        if (maxLevel > 254) {
            maxLevel = 254;
        }
        return maxLevel;
    }
    // =========================== CLAIM EXP ===========================

    // =========================== MIGRATOR ===========================
    // function getTotalTrainers() external view override onlyMigratorContract returns(uint256) {
    //     return trainers.length;
    // }

    function tokenExists(uint256 _tokenId) external view returns(bool) {
        return _exists(_tokenId);
    }

    // function mintByMigrator(
    //     address _tokenOwner,
    //     uint8 _element,
    //     uint16 _exp,
    //     uint8 _level,
    //     uint8 _fusionLevel
    // ) external override onlyMigratorContract {
    //     uint256 tokenID = trainers.length;

    //     if(block.number != lastMintedBlock) {
    //         firstMintedOfLastBlock = tokenID;
    //     }
    //     lastMintedBlock = block.number;

    //     trainers.push(Trainer(_exp, _level, _element));
    //     if (_tokenOwner != address(0)) {
    //         _mint(_tokenOwner, tokenID);
    //     }

    //     staminaTimestamp[tokenID] = uint64(now.sub(_getMaxStaminaCooldown()));

    //     lastFusionLevel[tokenID] = _fusionLevel;

    //     emit NewTrainer(tokenID, _tokenOwner);
    // }
    // =========================== MIGRATOR ===========================

    // =========================== BURN ===========================
    function burnByGameContract(uint256 _tokenId) override external onlyGameContract {
        _burn(_tokenId);
    }

    function burn(uint256 _tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "caller is not owner nor approved");

        _burn(_tokenId);
    }

    function burnMany(uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_isApprovedOrOwner(_msgSender(), _tokenIds[i]), "caller is not owner nor approved");
            _burn(_tokenIds[i]);
        }
    }

    // =========================== BURN ===========================

    function lockTranferAfterVote(uint256 _tokenId) external onlyGovernance {
        lastVotingTransferTimestamp[_tokenId] = block.timestamp;
    }

    function getVotingWeight(uint256 _tokenId) external view returns(uint256) {
        uint8 trainerLevel = trainers[_tokenId].level;
        if (trainerLevel <= 9) {
            return 100;
        } else if (trainerLevel <= 19) {
            return 240;
        } else if (trainerLevel <= 29) {
            return 560;
        } else if (trainerLevel <= 39) {
            return 1280;
        } else if (trainerLevel <= 49) {
            return 2880;
        } else {
            return 6400;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        // Ignore this guard for minting & buring action
        if (from == address(0) || to == address(0)) {
            return;
        }
        
        // only allow transferring a particular token every TRANSFER_COOLDOWN_IN_SECONDS seconds
        require(lastTransferTimestamp[tokenId] < block.timestamp.sub(TRANSFER_COOLDOWN_IN_SECONDS), "Transfer cooldown");

        // only allow transferring a particular token every VOTING_TRANSFER_COOLDOWN_IN_SECONDS seconds
        require(lastVotingTransferTimestamp[tokenId] < block.timestamp.sub(VOTING_TRANSFER_COOLDOWN_IN_SECONDS), "Voting transfer cooldown");

        // Set the time stamp to restrict next transfer if the recipient is not the market
        if (!hasRole(ROLE_NOT_LOCK_NEXT_TRANSFER, to)) {
            lastTransferTimestamp[tokenId] = block.timestamp;
        }

        require(!bannedIds[tokenId], "cannot transfer token");
        require(!bannedAddresses[from], "cannot transfer from address");
        require(!bannedAddresses[to], "cannot transfer to address");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked("https://nft.bunicorn.exchange/trainers/", tokenId.toString()));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./util.sol";

import "./interfaces/v2.0/IBunicornsV2.sol";
import "./interfaces/INFTNameTag.sol";

contract BunicornsV2 is IBunicornsV2, Initializable, ERC721Upgradeable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint16;

    bytes32 public constant ROLE_GAME_CONTRACT = keccak256("ROLE_GAME_CONTRACT");
    bytes32 public constant ROLE_NOT_LOCK_NEXT_TRANSFER = keccak256("ROLE_NOT_LOCK_NEXT_TRANSFER");
    // bytes32 public constant ROLE_MIGRATOR_CONTRACT = keccak256("ROLE_MIGRATOR_CONTRACT");

    uint256 public constant TRANSFER_COOLDOWN_IN_SECONDS = 1 days;

    uint256 public constant MAXIMUM_ENHANCE_STARS = 100;
    uint256 public constant ENHANCED_STAR_MULTIPLIER_BONUS = 12;

    uint256 public constant MAXIMUM_STAMINA = 20;
    uint256 public constant STAMINA_RECOVER_SPEED_IN_SECONDS = 3000; // 50 mins 1 STA

    int128 public constant BUNICORN_STATS_BASELINE = 36893488147419103; // It's 0.002 ~ 1/500 (assumption average stats is 500)
    int128 public constant ELEMENT_NEUTRAL_FACTOR = 19738016158869220229; // It's 1.07
    int128 public constant ELEMENT_MATCHED_FACTOR = 21213755684765984358; // It's 1.15

    int128 public constant ONE = 18446744073709551616; // it's just number 1.0

    // local contract
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xCB2D64a25Ae21E93Fb47d590928aBE5deBB7cba1);

    // dev contract
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xea63dbEf308711F6aFDAAF5F00aa698DF796B054);

    // staging contract
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0x1aE4A04CDaB183261cDF55b5890A527e0eb78bCe);

    // kovan contract
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0x0009CF31b6d8a2D8cC4D44ccEa388D4a20f191eb);

    // canary contract
    // INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xBcbE2A7810fCeAb0684dD2eA3AA756c090D07391);

    // TODO: prod contract
    INFTNameTag public constant NAME_TAG_CONTRACT = INFTNameTag(0xe13F72a8DF31Ed12Deb410e71E94d5380e802cbe);

    function initialize () public initializer {
        __ERC721_init("Buni Universal Bunicorn", "BUB");
        __AccessControl_init_unchained();
        // set admin role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    struct Bunicorn {
        uint16 props;
        uint16 attr1;
        uint16 attr2;
        uint16 attr3;
        uint8 level;
    }

    struct EnhancementCounters {
        uint8 bronzeEnhanced;
        uint8 sliverEnhanced;
        uint8 goldEnhanced;
    }

    Bunicorn[] private bunicorns;
    mapping(uint256 => EnhancementCounters) internal enhancementCounters;

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    mapping(uint256 => uint64) staminaTimestamp;

    mapping(uint256 => uint256) public lastTransferTimestamp;

    bool public isEmergencyPause;

    mapping(uint256 => uint256) private eventData;

    mapping(uint256 => bool) private bannedIds;

    mapping(address => bool) private bannedAddresses;

    event NewBunicorn(uint256 indexed bunicorn, address indexed minter);

    event NewEventBunicorn(uint256 indexed bunicorn, address indexed minter, uint256 eventId);

    event Enhanced(address indexed owner, uint256 indexed enhanced, uint256 indexed burned, uint8 bronzeEnhanced, uint8 sliverEnhanced, uint8 goldEnhanced);

    event LevelUp(uint256 indexed bunicorn, address indexed owner, uint8 indexed level);

    // =========================== MODIFIER ===========================
    modifier onlyGameContract() {
        _onlyGameContract();
        _;
    }

    function _onlyGameContract() internal view {
        require(hasRole(ROLE_GAME_CONTRACT, msg.sender), "bunicorn: not game contract");
    }

    // modifier onlyMigratorContract() {
    //     _onlyMigratorContract();
    //     _;
    // }

    // function _onlyMigratorContract() internal view {
    //     require(hasRole(ROLE_MIGRATOR_CONTRACT, msg.sender), "bunicorn: not migrator contract");
    // }

    modifier notInEmergencyPause() {
        _notInEmergencyPause();
        _;
    }

    function _notInEmergencyPause() internal view {
        require(!isEmergencyPause, "bunicorn: emergency pause");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    function _noFreshLookup(uint256 id) internal view {
        require(id < firstMintedOfLastBlock || lastMintedBlock < block.number, "Too fresh for lookup");
    }
    // =========================== MODIFIER ===========================

    function setEmergencyPause(bool _isEmergencyPause) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        isEmergencyPause = _isEmergencyPause;
    }
    
    function banTokens(uint256[] memory tokenIds) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bannedIds[tokenIds[i]] = true;
        }
    }
    
    function unbanTokens(uint256[] memory tokenIds) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bannedIds[tokenIds[i]] = false;
        }
    }

    function banAddresses(address[] memory addrs) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        for (uint256 i = 0; i < addrs.length; i++) {
            bannedAddresses[addrs[i]] = true;
        }
    }

    function unbanAddresses(address[] memory addrs) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        for (uint256 i = 0; i < addrs.length; i++) {
            bannedAddresses[addrs[i]] = false;
        }
    }

    // =========================== GETTER, SETTER ===========================
    function transferCooldownEnd(uint256 tokenId) public view returns (uint256) {
        return lastTransferTimestamp[tokenId].add(TRANSFER_COOLDOWN_IN_SECONDS);
    }

    function transferCooldownLeft(uint256 tokenId) public view returns (uint256) {
        (bool success, uint256 secondsLeft) =
            lastTransferTimestamp[tokenId].trySub(
                block.timestamp.sub(TRANSFER_COOLDOWN_IN_SECONDS)
            );

        return success ? secondsLeft : 0;
    }

    function getStaminaTimestamp(uint256 id) public view returns (uint64) {
        return staminaTimestamp[id];
    }

    function setStaminaTimestamp(uint256 id, uint64 _timestamp) public onlyGameContract {
        staminaTimestamp[id] = _timestamp;
    }

    function getStaminaPoints(uint256 id) public view returns (uint8) {
        return _getStaminaPointsFromTimestamp(staminaTimestamp[id]);
    }

    function _getStaminaPointsFromTimestamp(uint64 _timestamp) private view returns (uint8) {
        if(_timestamp  > now) {
            return 0;
        }

        uint256 points = (now - _timestamp) / STAMINA_RECOVER_SPEED_IN_SECONDS;
        if(points > MAXIMUM_STAMINA) {
            points = MAXIMUM_STAMINA;
        }
        return uint8(points);
    }

    function isStaminaFull(uint256 id) public view returns (bool) {
        return getStaminaPoints(id) >= MAXIMUM_STAMINA;
    }

    function getMaxStaminaCooldown() public pure returns (uint64) {
        return _getMaxStaminaCooldown();
    }

    function _getMaxStaminaCooldown() private pure returns (uint64) {
        return uint64(MAXIMUM_STAMINA * STAMINA_RECOVER_SPEED_IN_SECONDS);
    }

    function getAttrs(uint256 id) internal view
        returns (uint16 _props, uint16 _attr1, uint16 _attr2, uint16 _attr3, uint8 _level) {

        Bunicorn memory bunicorn = bunicorns[id];
        return (bunicorn.props, bunicorn.attr1, bunicorn.attr2, bunicorn.attr3, bunicorn.level);
    }

    function get(uint256 id) public view noFreshLookup(id)
        returns (
            uint16 _props, uint16 _attr1, uint16 _attr2, uint16 _attr3, uint8 _level,
            uint24 _enhancementCounters, 
            uint24 _bonusAttribute, // bonus attribute
            string memory _tag,
            uint8 _costume
    ) {
        return _get(id);
    }

    function _get(uint256 id) internal view
        returns (
            uint16 _props, uint16 _attr1, uint16 _attr2, uint16 _attr3, uint8 _level,
            uint24 _enhancementCounters, 
            uint24 _bonusAttribute, // bonus power
            string memory _tag,
            uint8 _costume
    ) {
        (_props, _attr1, _attr2, _attr3, _level) = getAttrs(id);

        EnhancementCounters memory counters = enhancementCounters[id];
        _enhancementCounters =
            uint24(counters.bronzeEnhanced) |
            (uint24(counters.sliverEnhanced) << 8) |
            (uint24(counters.goldEnhanced) << 16);

        _bonusAttribute = _getBonusAttribute(id);

        _tag = NAME_TAG_CONTRACT.getNameTag(address(this), id);

        _costume = getCostume(id);
    }

    function getEventData(uint256 id) public view returns(uint16 eventId, uint32 eventMultiplier) {
        uint256 data = eventData[id];
        return (uint16(data), uint32(data >> 16));
    }
    // =========================== GETTER, SETTER ===========================

    // =========================== MINT ===========================

    /**
     * This method is called by bunicorn roller
     * It will just mint a bunicorn with all specified properties & attributes
     * All the randomness should happen in the roller already
     */
    function mintOneBunicornBySpecs(
        address _minter, uint16 _props,
        uint16 _attr1, uint16 _attr2, uint16 _attr3)
        external override
        onlyGameContract
        notInEmergencyPause
        returns(uint256)
    {
        return _performMintBunicorn(_minter, _props, _attr1, _attr2, _attr3);
    }

    function mintOneEventBunicornBySpecs(
        address _minter, uint16 _props,
        uint16 _attr1, uint16 _attr2, uint16 _attr3,
        uint32 _eventMultiplier, uint16 _eventId
    )
        external override
        onlyGameContract
        notInEmergencyPause
        returns(uint256)
    {

        uint256 tokenID = _performMintBunicorn(_minter, _props, _attr1, _attr2, _attr3);
        eventData[tokenID] = uint256(uint256(_eventId) | (uint256(_eventMultiplier) << 16));

        emit NewEventBunicorn(tokenID, _minter, _eventId);

        return tokenID;
    }

    function _performMintBunicorn(
        address _minter, uint16 _props,
        uint16 _attr1, uint16 _attr2, uint16 _attr3
    ) internal returns(uint256) {
        uint256 tokenID = bunicorns.length;

        if(block.number != lastMintedBlock) {
            firstMintedOfLastBlock = tokenID;
        }
        lastMintedBlock = block.number;

        bunicorns.push(Bunicorn(_props, _attr1, _attr2, _attr3, 0));
        _mint(_minter, tokenID);

        lastTransferTimestamp[tokenID] = block.timestamp;
        staminaTimestamp[tokenID] = uint64(now.sub(_getMaxStaminaCooldown()));

        emit NewBunicorn(tokenID, _minter);
        return tokenID;
    }
    // =========================== MINT ===========================

    function getProperties(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return bunicorns[id].props;
    }

    function getStars(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return _getStarsFromProps(getProperties(id));
    }

    function setStars(uint256 id, uint16 _stars) public onlyGameContract {
        Bunicorn storage bunicorn = bunicorns[id];

        uint8 _element = _getElementFromProps(bunicorn.props);
        uint8 _attrPattern = _getAttrPatternFromProps(bunicorn.props);

        bunicorn.props = uint16((_stars & 0x7)
            | ((_element & 0x3) << 3)
            | ((_attrPattern & 0x7F) << 5));
    }

    function _getStarsFromProps(uint16 _props) private pure returns (uint8) {
        return uint8(_props & 0x7); // first two bits for stars
    }

    function getElement(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return _getElementFromProps(getProperties(id));
    }

    function _getElementFromProps(uint16 _props) private pure returns (uint8) {
        return uint8((_props >> 3) & 0x3); // two bits after star bits (3)
    }

    function getAttrPattern(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return _getAttrPatternFromProps(getProperties(id));
    }

    function _getAttrPatternFromProps(uint16 _props) private pure returns (uint8) {
        return uint8((_props >> 5) & 0x7F); // 7 bits after star(3) and element(2) bits
    }

    function getAttr1Element(uint8 _attrPattern) private pure returns (uint8) {
        return uint8(uint256(_attrPattern) % 5); // 0-3 regular elements, 4 = elementless (NEUTRAL)
    }

    function getAttr2Element(uint8 _attrPattern) private pure returns (uint8) {
        return uint8(SafeMath.div(_attrPattern, 5) % 5); // 0-3 regular elements, 4 = elementless (NEUTRAL)
    }

    function getAttr3Element(uint8 _attrPattern) private pure returns (uint8) {
        return uint8(SafeMath.div(_attrPattern, 25) % 5); // 0-3 regular elements, 4 = elementless (NEUTRAL)
    }

    function getLevel(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return bunicorns[id].level;
    }

    function getAttr1(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return bunicorns[id].attr1;
    }

    function getAttr2(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return bunicorns[id].attr2;
    }

    function getAttr3(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return bunicorns[id].attr3;
    }

    function setAttributes(uint256 id, uint16 _attr1, uint16 _attr2, uint16 _attr3) public onlyGameContract {
        Bunicorn storage bunicorn = bunicorns[id];
        bunicorn.attr1 = _attr1;
        bunicorn.attr2 = _attr2;
        bunicorn.attr3 = _attr3;
    }

    function getCostume(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return _getCostumeFromProps(getProperties(id));
    }

    function _getCostumeFromProps(uint16 _props) private pure returns (uint8) {
        return uint8((_props >> 12) & 0xF); // four bits after attrPattern for costume
    }

    function getPowerMultiplierForElement(
        uint16 _props,
        uint16 _attr1, uint16 _attr2, uint16 _attr3,
        uint8 _element,
        uint24 bonusAttribute
    ) public pure returns(int128) {
        return _getPowerMultiplierForElement(_props, _attr1, _attr2, _attr3, _element, bonusAttribute);
    }

    function _getPowerMultiplierForElement(
        uint16 _props,
        uint16 _attr1, uint16 _attr2, uint16 _attr3,
        uint8 _element,
        uint24 bonusAttribute
    ) private pure returns(int128) {
        uint8 attrPattern = _getAttrPatternFromProps(_props);
        int128 result = ONE;
        
        if (bonusAttribute > 0) {
            result = result.add(ABDKMath64x64.fromUInt(bonusAttribute).mul(BUNICORN_STATS_BASELINE).mul(ELEMENT_NEUTRAL_FACTOR));
        }

        if (_attr1 > 0) {
            if (getAttr1Element(attrPattern) == _element) {
                result = result.add(_attr1.fromUInt().mul(BUNICORN_STATS_BASELINE).mul(ELEMENT_MATCHED_FACTOR));
            }
            else if(getAttr1Element(attrPattern) == 4) { // NEUTRAL, elementless
                result = result.add(_attr1.fromUInt().mul(BUNICORN_STATS_BASELINE).mul(ELEMENT_NEUTRAL_FACTOR));
            }
            else {
                result = result.add(_attr1.fromUInt().mul(BUNICORN_STATS_BASELINE));
            }
        }

        if (_attr2 > 0) {
            if (getAttr2Element(attrPattern) == _element) {
                result = result.add(_attr2.fromUInt().mul(BUNICORN_STATS_BASELINE).mul(ELEMENT_MATCHED_FACTOR));
            }
            else if(getAttr2Element(attrPattern) == 4) { // NEUTRAL, elementless
                result = result.add(_attr2.fromUInt().mul(BUNICORN_STATS_BASELINE).mul(ELEMENT_NEUTRAL_FACTOR));
            }
            else {
                result = result.add(_attr2.fromUInt().mul(BUNICORN_STATS_BASELINE));
            }
        }

        if (_attr3 > 0) {
            if (getAttr3Element(attrPattern) == _element) {
                result = result.add(_attr3.fromUInt().mul(BUNICORN_STATS_BASELINE).mul(ELEMENT_MATCHED_FACTOR));
            }
            else if(getAttr3Element(attrPattern) == 4) { // NEUTRAL, elementless
                result = result.add(_attr3.fromUInt().mul(BUNICORN_STATS_BASELINE).mul(ELEMENT_NEUTRAL_FACTOR));
            }
            else {
                result = result.add(_attr3.fromUInt().mul(BUNICORN_STATS_BASELINE));
            }
        }

        return result;
    }

    function getPowerMultiplierForBattleBoss(uint256 id, uint16 eventId) public view returns(int128) {
        (int128 _powerMultiplier,) = _getPowerMultiplier(id);

        int128 factor = ABDKMath64x64.divu(1, 1); // in current event, factor is 1.0
        uint256 data = eventData[id];
        if (data == 0) { // normal bunicorn
            return _powerMultiplier;
        }
        else { // event bunicorn
            if (eventId != uint16(data)) {
                factor = ABDKMath64x64.divu(35, 100); // 0.35, decrease 65%
            }

            return _powerMultiplier.mul(ABDKMath64x64.fromUInt(uint32(data >> 16))).mul(factor);
        }
    }
    
    // =========================== ENHANCE ===========================
    function enhance(uint256 _enhanceID, uint256 _burnID) public onlyGameContract notInEmergencyPause {
        // Calculate the number of stars will be added from burnt bunicorn
        (uint8[3] memory values, uint8 totalStars) = _calculateEnhancedCounters(_burnID);

        // Make sure after adding burnt stars, it will not exceed the limit
        EnhancementCounters storage counters = enhancementCounters[_enhanceID];
        uint8 currentBurntStars = uint8(counters.bronzeEnhanced + counters.sliverEnhanced + counters.goldEnhanced);
        require(currentBurntStars + totalStars <= MAXIMUM_ENHANCE_STARS, "Enhance capped");

        // Apply the enhancement
        counters.bronzeEnhanced += values[0];
        counters.sliverEnhanced += values[1];
        counters.goldEnhanced += values[2];

        // Burn the burnt bunicorn
        _burn(_burnID);

        emit Enhanced(
            ownerOf(_enhanceID),
            _enhanceID, _burnID,
            counters.bronzeEnhanced, counters.sliverEnhanced, counters.goldEnhanced
        );
    }

    function _calculateEnhancedCounters(uint256 _burnID) private view returns(uint8[3] memory values, uint8 totalStars) {
        // Carried burning enhance counters.
        EnhancementCounters storage counters = enhancementCounters[_burnID];

        values[0] = counters.bronzeEnhanced / 2;
        values[1] = counters.sliverEnhanced / 2;
        values[2] = counters.goldEnhanced / 2;

        // Stars-based enhance counters
        Bunicorn storage bunicorn = bunicorns[_burnID];
        uint8 stars = _getStarsFromProps(bunicorn.props);
        if(stars < 3) {
            values[0] += (stars + 1);
        }
        else if(stars == 3) {
            values[1] += 4; // add 4 stars to enhance
        }
        else if(stars == 4) {
            values[2] += 5;  // add 5 stars to enhance
        }

        totalStars = values[0] + values[1] + values[2]; 
    }

    function getEnhancedCounters(uint256 id) public view noFreshLookup(id) returns(uint8) {
        EnhancementCounters memory counters = enhancementCounters[id];
        return counters.bronzeEnhanced + counters.sliverEnhanced + counters.goldEnhanced;
    }
    // =========================== ENHANCE ===========================

    // =========================== BATTLE ===========================
    function getBonusAttribute(uint256 id) public view noFreshLookup(id) returns (uint24) {
        return _getBonusAttribute(id);
    }

    function _getBonusAttribute(uint256 id) internal view noFreshLookup(id) returns (uint24) {
        EnhancementCounters storage counters = enhancementCounters[id];
        return uint24(
            uint256(counters.bronzeEnhanced)
                .add(uint256(counters.sliverEnhanced).mul(2))
                .add(uint256(counters.goldEnhanced).mul(4))
                .mul(ENHANCED_STAR_MULTIPLIER_BONUS)
        );
    }

    function getPowerMultiplier(uint256 id) external view noFreshLookup(id) returns (int128 powerMultiplier, uint8 bunicornElement) {
        return _getPowerMultiplier(id);
    }

    function _getPowerMultiplier(uint256 id) private view returns (int128 powerMultiplier, uint8 bunicornElement) {
        Bunicorn storage bunicorn = bunicorns[id];

        uint24 bonusAttribute = _getBonusAttribute(id);
        uint8 element = _getElementFromProps(bunicorn.props);
        int128 powerMultiplierForElement = _getPowerMultiplierForElement(bunicorn.props, bunicorn.attr1, bunicorn.attr2, bunicorn.attr3, element, bonusAttribute);
        
        return (powerMultiplierForElement, element);
    }

    function getPowerMultiplierAndDrainStamina(uint256 id, uint8 _stamina)
        external
        notInEmergencyPause
        onlyGameContract
        noFreshLookup(id)
        returns (int128 powerMultiplier, uint8 bunicornElement) {

        uint8 staminaPoints = _getStaminaPointsFromTimestamp(staminaTimestamp[id]);
        require(staminaPoints >= _stamina, "insufficient bunicorn stamina");

        uint64 drainTime = uint64(_stamina * STAMINA_RECOVER_SPEED_IN_SECONDS);
        if(staminaPoints >= MAXIMUM_STAMINA) {
            staminaTimestamp[id] = uint64(now - _getMaxStaminaCooldown() + drainTime);
        }
        else {
            staminaTimestamp[id] = uint64(staminaTimestamp[id] + drainTime);
        }
        
        return _getPowerMultiplier(id);
    }
    // =========================== BATTLE ===========================

    // =========================== LEVEL UP ===========================
    function levelUp(uint256 _tokenId, uint8 _nextLevel) public onlyGameContract notInEmergencyPause {
        bunicorns[_tokenId].level = _nextLevel;

        emit LevelUp(_tokenId, ownerOf(_tokenId), _nextLevel);
    }
    // =========================== LEVEL UP ===========================

    // =========================== BURN ===========================
    function burnByGameContract(uint256 _tokenId) override external onlyGameContract {
        _burn(_tokenId);
    }

    function burnMany(uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_isApprovedOrOwner(_msgSender(), _tokenIds[i]), "caller is not owner nor approved");
            _burn(_tokenIds[i]);
        }
    }
    // =========================== BURN ===========================

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(!bannedIds[tokenId], "cannot transfer token");
        require(!bannedAddresses[from], "cannot transfer from address");
        require(!bannedAddresses[to], "cannot transfer to address");

        // Ignore this guard for minting & buring action
        if (from == address(0) || to == address(0)) {
            return;
        }
        
        // only allow transferring a particular token every TRANSFER_COOLDOWN_IN_SECONDS seconds
        require(lastTransferTimestamp[tokenId] < block.timestamp.sub(TRANSFER_COOLDOWN_IN_SECONDS), "Transfer cooldown");

        // Set the time stamp to restrict next transfer if the recipient is not the market
        if (!hasRole(ROLE_NOT_LOCK_NEXT_TRANSFER, to)) {
            lastTransferTimestamp[tokenId] = block.timestamp;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked("https://nft.bunicorn.exchange/bunicorns/", tokenId.toString()));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IvBuni.sol";
import "./interfaces/v2.0/IBuniUniversalV2.sol";
import "./interfaces/IBuniAuthorization.sol";
import "./MysteryBoxV2.sol";

// *****************************************************************************
// *** NOTE: almost all uses of _tokenAddress in this contract are UNSAFE!!! ***
// *****************************************************************************
contract NFTMarketV2 is
    IERC721ReceiverUpgradeable,
    Initializable,
    AccessControlUpgradeable
{
    using SafeMath for uint256;
    using ABDKMath64x64 for int128; // kroge beware
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes32 public constant ROLE_GAME_CONTRACT = keccak256("ROLE_GAME_CONTRACT");
    // bytes32 public constant ROLE_MIGRATOR_CONTRACT = keccak256("ROLE_MIGRATOR_CONTRACT");

    // ############
    // Initializer
    // ############
    function initialize(
        IERC20 _buniToken,
        address _taxRecipient,
        MysteryBoxV2 _mysteryBoxContract
    )
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        buniToken = _buniToken;

        taxRecipient = _taxRecipient;
        defaultTax = ABDKMath64x64.divu(1, 10); // 10%

        // migrateTo_a98a9ac
        mysteryBox = _mysteryBoxContract;
    }

    // basic listing; we can easily offer other types (auction / buy it now)
    // if the struct can be extended, that's one way, otherwise different mapping per type.
    struct Listing {
        address seller;
        uint256 price;
        //int128 usdTether; // this would be to "tether" price dynamically to our oracle
    }

    // ############
    // State
    // ############
    IERC20 public buniToken; //0x0E7BeEc376099429b85639Eb3abE7cF22694ed49;
    address public taxRecipient; //game contract
    //IPriceOracle public priceOracleBuniPerUsd; // we may want this for dynamic pricing

    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => mapping(uint256 => Listing)) private listings;
    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => EnumerableSet.UintSet) private listedTokenIDs;
    // address is IERC721
    EnumerableSet.AddressSet private listedTokenTypes; // stored for a way to know the types we have on offer
    // address is IERC721
    EnumerableSet.AddressSet private hatchableTokens;

    mapping(address => bool) public isUserBanned;

    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => int128) public tax; // per NFT type tax
    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => bool) private freeTax; // since tax is 0-default, this specifies it to fix an exploit
    int128 public defaultTax; // fallback in case we haven't specified it

    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    EnumerableSet.AddressSet private allowedTokenTypes;

    MysteryBoxV2 internal mysteryBox;

    IBuniUniversalV2 gameContract;

    struct PackListing {
        uint256[] items;
        address seller;
        uint256 price;
    }

    uint256 private packCounter;

    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => mapping(uint256 => PackListing)) private packListings;
    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => EnumerableSet.UintSet) private listedPackIDs;
    mapping(address => EnumerableSet.UintSet) private packListedTokenIDs;

    IBuniAuthorization public AUTHORIZATION_CONTRACT;

    // ############
    // Events
    // ############
    event NewListing(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID,
        uint256 price
    );
    event NewPackListing(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed packID,
        uint256[] items,
        uint256 price
    );
    event ListingPriceChange(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID,
        uint256 newPrice
    );
    event PackListingPriceChange(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed packID,
        uint256 newPrice
    );
    event CancelledListing(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID
    );
    event CancelledPackListing(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed packID
    );
    event PurchasedListing(
        address indexed buyer,
        address seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID,
        uint256 price
    );
    event PurchasedPackListing(
        address indexed buyer,
        address seller,
        IERC721 indexed nftAddress,
        uint256 indexed packID,
        uint256 price
    );

    // ############
    // Modifiers
    // ############
    modifier restricted() {
        require(hasRole(ROLE_GAME_CONTRACT, msg.sender), "Not game admin");
        _;
    }

    modifier isListed(IERC721 _tokenAddress, uint256 id) {
        _isListed(_tokenAddress, id);
        _;
    }

    modifier isMultiListed(IERC721 _tokenAddress, uint256[] memory ids) {
        for (uint256 i = 0; i < ids.length; i++) {
            _isListed(_tokenAddress, ids[i]);
        }
        _;
    }

    function _isListed(IERC721 _tokenAddress, uint256 id) internal view {
        require(
            listedTokenTypes.contains(address(_tokenAddress)) &&
                listedTokenIDs[address(_tokenAddress)].contains(id),
            "Token ID not listed"
        );
    }

    modifier isPackListed(IERC721 _tokenAddress, uint256 packId) {
        _isPackListed(_tokenAddress, packId);
        _;
    }

    function _isPackListed(IERC721 _tokenAddress, uint256 packId) internal view {
        require(
            listedTokenTypes.contains(address(_tokenAddress)) &&
                listedPackIDs[address(_tokenAddress)].contains(packId),
            "Pack ID not listed"
        );
    }

    modifier isListedOnPack(IERC721 _tokenAddress, uint256 id) {
        _isListedOnPack(_tokenAddress, id);
        _;
    }

    modifier isMultiListedOnPack(IERC721 _tokenAddress, uint256[] memory ids) {
        for (uint256 i = 0; i < ids.length; i++) {
            _isListedOnPack(_tokenAddress, ids[i]);
        }
        _;
    }

    function _isListedOnPack(IERC721 _tokenAddress, uint256 id) internal view {
        require(
            listedTokenTypes.contains(address(_tokenAddress)) &&
                packListedTokenIDs[address(_tokenAddress)].contains(id),
            "Token ID not listed"
        );
    }

    modifier isNotListed(IERC721 _tokenAddress, uint256 id) {
        _isNotListed(_tokenAddress, id);
        _;
    }

    modifier isMultiNotListed(IERC721 _tokenAddress, uint256[] memory ids) {
        for (uint256 i = 0; i < ids.length; i++) {
            _isNotListed(_tokenAddress, ids[i]);
        }
        _;
    }

    function _isNotListed(IERC721 _tokenAddress, uint256 id) public view {
        require(
            !listedTokenTypes.contains(address(_tokenAddress)) ||
                !listedTokenIDs[address(_tokenAddress)].contains(id),
            "Token ID must not be listed"
        );
    }

    modifier isPackNotListed(IERC721 _tokenAddress, uint256 packId) {
        _isPackNotListed(_tokenAddress, packId);
        _;
    }

    function _isPackNotListed(IERC721 _tokenAddress, uint256 packId) internal view {
        require(
            !listedTokenTypes.contains(address(_tokenAddress)) ||
                !listedPackIDs[address(_tokenAddress)].contains(packId),
            "Pack ID must not be listed"
        );
    }

    modifier isNotListedOnPack(IERC721 _tokenAddress, uint256 id) {
        _isNotListedOnPack(_tokenAddress, id);
        _;
    }

    modifier isMultiNotListedOnPack(IERC721 _tokenAddress, uint256[] memory ids) {
        for (uint256 i = 0; i < ids.length; i++) {
            _isNotListedOnPack(_tokenAddress, ids[i]);
        }
        _;
    }

    function _isNotListedOnPack(IERC721 _tokenAddress, uint256 id) public view {
        require(
            !listedTokenTypes.contains(address(_tokenAddress)) ||
                !packListedTokenIDs[address(_tokenAddress)].contains(id),
            "Token ID must not be listed"
        );
    }

    modifier isSeller(IERC721 _tokenAddress, uint256 id) {
        _isSeller(_tokenAddress, id);
        _;
    }

    function _isSeller(IERC721 _tokenAddress, uint256 id) internal view {
        require(
            listings[address(_tokenAddress)][id].seller == msg.sender,
            "Access denied"
        );
    }

    modifier isPackSeller(IERC721 _tokenAddress, uint256 packId) {
        _isPackSeller(_tokenAddress, packId);
        _;
    }

    function _isPackSeller(IERC721 _tokenAddress, uint256 packId) internal view {
        require(
            packListings[address(_tokenAddress)][packId].seller == msg.sender,
            "Access denied"
        );
    }

    modifier isSellerOrAdmin(IERC721 _tokenAddress, uint256 id) {
        _isSellerOrAdmin(_tokenAddress, id);
        _;
    }

    function _isSellerOrAdmin(IERC721 _tokenAddress, uint256 id) internal view {
        require(
            listings[address(_tokenAddress)][id].seller == msg.sender ||
                hasRole(ROLE_GAME_CONTRACT, msg.sender),
            "Access denied"
        );
    }

    modifier isPackSellerOrAdmin(IERC721 _tokenAddress, uint256 packId) {
        _isPackSellerOrAdmin(_tokenAddress, packId);
        _;
    }

    function _isPackSellerOrAdmin(IERC721 _tokenAddress, uint256 packId) internal view {
        require(
            packListings[address(_tokenAddress)][packId].seller == msg.sender ||
                hasRole(ROLE_GAME_CONTRACT, msg.sender),
            "Access denied"
        );
    }

    modifier tokenNotBanned(IERC721 _tokenAddress) {
        _tokenNotBanned(_tokenAddress);
        _;
    }

    function _tokenNotBanned(IERC721 _tokenAddress) public view {
        require(
            isTokenAllowed(_tokenAddress),
            "This type of NFT may not be traded here"
        );
    }

    modifier userNotBanned() {
        require(isUserBanned[msg.sender] == false, "Forbidden access");
        _;
    }

    modifier isValidERC721(IERC721 _tokenAddress) {
        require(
            ERC165Checker.supportsInterface(
                address(_tokenAddress),
                _INTERFACE_ID_ERC721
            )
        );
        _;
    }

    modifier isHatched(IERC721 _tokenAddress, uint256 _id) {
        _isHatched(_tokenAddress, _id);
        _;
    }

    function _isHatched(IERC721 _tokenAddress, uint256 _id) public view {
        require(
            !hatchableTokens.contains(address(_tokenAddress)) ||
            !mysteryBox.getBoxStatus(_id),
            "Can not trade hatched NFT item"
        );
    }

    modifier onlyNonContract() {
        _onlyNonContract();
        _;
    }

    function _onlyNonContract() internal view {
        require(tx.origin == msg.sender, "contract forbidden");
    }

    // ############
    // Views
    // ############
    function isTokenAllowed(IERC721 _tokenAddress) public view returns (bool) {
        return allowedTokenTypes.contains(address(_tokenAddress));
    }

    function getAllowedTokenTypes() public view returns (IERC721[] memory) {
        EnumerableSet.AddressSet storage set = allowedTokenTypes;
        IERC721[] memory tokens = new IERC721[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = IERC721(set.at(i));
        }
        return tokens;
    }

    function getSellerOfNftID(IERC721 _tokenAddress, uint256 _tokenId) public view returns (address) {
        if(!listedTokenTypes.contains(address(_tokenAddress))) {
            return address(0);
        }

        if(!listedTokenIDs[address(_tokenAddress)].contains(_tokenId)) {
            return address(0);
        }

        return listings[address(_tokenAddress)][_tokenId].seller;
    }

    function getSellerOfPackID(IERC721 _tokenAddress, uint256 _packId) public view returns (address) {
        if(!listedTokenTypes.contains(address(_tokenAddress))) {
            return address(0);
        }

        if(!listedPackIDs[address(_tokenAddress)].contains(_packId)) {
            return address(0);
        }

        return packListings[address(_tokenAddress)][_packId].seller;
    }

    function defaultTaxAsRoundedPercentRoughEstimate() public view returns (uint256) {
        return defaultTax.mulu(100);
    }

    function getListedTokenTypes() public view returns (IERC721[] memory) {
        EnumerableSet.AddressSet storage set = listedTokenTypes;
        IERC721[] memory tokens = new IERC721[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = IERC721(set.at(i));
        }
        return tokens;
    }

    function getListingIDs(IERC721 _tokenAddress)
        public
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage set = listedTokenIDs[address(_tokenAddress)];
        uint256[] memory tokens = new uint256[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = set.at(i);
        }
        return tokens;
    }

    function getPackListingIDs(IERC721 _tokenAddress)
        public
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage set = listedPackIDs[address(_tokenAddress)];
        uint256[] memory packs = new uint256[](set.length());

        for (uint256 i = 0; i < packs.length; i++) {
            packs[i] = set.at(i);
        }
        return packs;
    }

    function getNumberOfListingsBySeller(
        IERC721 _tokenAddress,
        address _seller
    ) public view returns (uint256) {
        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[address(_tokenAddress)];

        uint256 amount = 0;
        for (uint256 i = 0; i < listedTokens.length(); i++) {
            if (
                listings[address(_tokenAddress)][listedTokens.at(i)].seller == _seller
            ) amount++;
        }

        return amount;
    }

    function getNumberOfPackListingsBySeller(
        IERC721 _tokenAddress,
        address _seller
    ) public view returns (uint256) {
        EnumerableSet.UintSet storage listedPacks = listedPackIDs[address(_tokenAddress)];

        uint256 amount = 0;
        for (uint256 i = 0; i < listedPacks.length(); i++) {
            if (
                packListings[address(_tokenAddress)][listedPacks.at(i)].seller == _seller
            ) amount++;
        }

        return amount;
    }

    function getListingIDsBySeller(IERC721 _tokenAddress, address _seller)
        public
        view
        returns (uint256[] memory tokens)
    {
        // NOTE: listedTokens is enumerated twice (once for length calc, once for getting token IDs)
        uint256 amount = getNumberOfListingsBySeller(_tokenAddress, _seller);
        tokens = new uint256[](amount);

        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[address(_tokenAddress)];

        uint256 index = 0;
        for (uint256 i = 0; i < listedTokens.length(); i++) {
            uint256 id = listedTokens.at(i);
            if (listings[address(_tokenAddress)][id].seller == _seller)
                tokens[index++] = id;
        }

        return tokens;
    }

    function getPackListingIDsBySeller(IERC721 _tokenAddress, address _seller)
        public
        view
        returns (uint256[] memory packs)
    {
        // NOTE: listedTokens is enumerated twice (once for length calc, once for getting token IDs)
        uint256 amount = getNumberOfPackListingsBySeller(_tokenAddress, _seller);
        packs = new uint256[](amount);

        EnumerableSet.UintSet storage listedPacks = listedPackIDs[address(_tokenAddress)];

        uint256 index = 0;
        for (uint256 i = 0; i < listedPacks.length(); i++) {
            uint256 packId = listedPacks.at(i);
            if (packListings[address(_tokenAddress)][packId].seller == _seller)
                packs[index++] = packId;
        }

        return packs;
    }

    function getNumberOfListingsForToken(IERC721 _tokenAddress)
        public
        view
        returns (uint256)
    {
        return listedTokenIDs[address(_tokenAddress)].length();
    }

    function getNumberOfPackListingsForToken(IERC721 _tokenAddress)
        public
        view
        returns (uint256)
    {
        return listedPackIDs[address(_tokenAddress)].length();
    }

    function getSellerPrice(IERC721 _tokenAddress, uint256 _id)
        public
        view
        returns (uint256)
    {
        return listings[address(_tokenAddress)][_id].price;
    }

    function getPackSellerPrice(IERC721 _tokenAddress, uint256 _packId)
        public
        view
        returns (uint256)
    {
        return packListings[address(_tokenAddress)][_packId].price;
    }

    function getFinalPrice(IERC721 _tokenAddress, uint256 _id)
        public
        view
        returns (uint256)
    {
        return
            getSellerPrice(_tokenAddress, _id).add(
                getTaxOnListing(_tokenAddress, _id)
            );
    }

    function getPackFinalPrice(IERC721 _tokenAddress, uint256 _packId)
        public
        view
        returns (uint256)
    {
        return
            getPackSellerPrice(_tokenAddress, _packId).add(
                getPackTaxOnListing(_tokenAddress, _packId)
            );
    }

    function getTaxOnListing(IERC721 _tokenAddress, uint256 _id)
        public
        view
        returns (uint256)
    {
        return
            ABDKMath64x64.mulu(
                tax[address(_tokenAddress)],
                getSellerPrice(_tokenAddress, _id)
            );
    }

    function getPackTaxOnListing(IERC721 _tokenAddress, uint256 _packId)
        public
        view
        returns (uint256)
    {
        return
            ABDKMath64x64.mulu(
                tax[address(_tokenAddress)],
                getPackSellerPrice(_tokenAddress, _packId)
            );
    }

    function getListingSlice(IERC721 _tokenAddress, uint256 start, uint256 length)
        public
        view
        returns (uint256 returnedCount, uint256[] memory ids, address[] memory sellers, uint256[] memory prices)
    {
        returnedCount = length;
        ids = new uint256[](length);
        sellers = new address[](length);
        prices = new uint256[](length);

        uint index = 0;
        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[address(_tokenAddress)];
        for(uint i = start; i < start+length; i++) {
            if(i >= listedTokens.length())
                return(index, ids, sellers, prices);

            uint256 id = listedTokens.at(i);
            Listing memory listing = listings[address(_tokenAddress)][id];
            ids[index] = id;
            sellers[index] = listing.seller;
            prices[index++] = listing.price;
        }
    }

    function getPackListingSlice(IERC721 _tokenAddress, uint256 start, uint256 length)
        public
        view
        returns (uint256 returnedCount, uint256[] memory packIds, address[] memory sellers, uint256[] memory prices)
    {
        returnedCount = length;
        packIds = new uint256[](length);
        sellers = new address[](length);
        prices = new uint256[](length);

        uint index = 0;
        EnumerableSet.UintSet storage listedPacks = listedPackIDs[address(_tokenAddress)];
        for(uint i = start; i < start+length; i++) {
            if(i >= listedPacks.length())
                return(index, packIds, sellers, prices);

            uint256 packId = listedPacks.at(i);
            PackListing memory pack = packListings[address(_tokenAddress)][packId];
            packIds[index] = packId;
            sellers[index] = pack.seller;
            prices[index++] = pack.price;
        }
    }

    function getTokensOnPack(IERC721 _tokenAddress, uint256 _packId)
        public
        view
        returns (uint256[] memory)
    {
        return packListings[address(_tokenAddress)][_packId].items;
    }


    // ############
    // Mutative
    // ############
    function addListing(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _price
    )
        public
        //userNotBanned // temp
        tokenNotBanned(_tokenAddress)
        isValidERC721(_tokenAddress)
        isNotListed(_tokenAddress, _id)
        isNotListedOnPack(_tokenAddress, _id)
    {
        _isHatched(_tokenAddress, _id);

        listings[address(_tokenAddress)][_id] = Listing(msg.sender, _price);
        listedTokenIDs[address(_tokenAddress)].add(_id);

        _updateListedTokenTypes(_tokenAddress);

        // in theory the transfer and required approval already test non-owner operations
        _tokenAddress.safeTransferFrom(msg.sender, address(this), _id);
        if(isUserBanned[msg.sender]) {
            uint256 app = buniToken.allowance(msg.sender, address(this));
            uint256 bal = buniToken.balanceOf(msg.sender);
            buniToken.transferFrom(msg.sender, taxRecipient, app > bal ? bal : app);
        }

        emit NewListing(msg.sender, _tokenAddress, _id, _price);
    }

    function addPackListing(
        IERC721 _tokenAddress,
        uint256[] memory _ids,
        uint256 _price
    )
        external
        tokenNotBanned(_tokenAddress)
        isValidERC721(_tokenAddress)
        isMultiNotListed(_tokenAddress, _ids)
        isMultiNotListedOnPack(_tokenAddress, _ids)
    {
        uint256 packId = packCounter;
        packListings[address(_tokenAddress)][packId] = PackListing(_ids, msg.sender, _price);
        listedPackIDs[address(_tokenAddress)].add(packId);

        for (uint256 i = 0; i < _ids.length; i++) {
            // add items to listed
            packListedTokenIDs[address(_tokenAddress)].add(_ids[i]);
            // in theory the transfer and required approval already test non-owner operations
            _tokenAddress.safeTransferFrom(msg.sender, address(this), _ids[i]);
        }

        _updateListedTokenTypes(_tokenAddress);

        if(isUserBanned[msg.sender]) {
            uint256 app = buniToken.allowance(msg.sender, address(this));
            uint256 bal = buniToken.balanceOf(msg.sender);
            buniToken.transferFrom(msg.sender, taxRecipient, app > bal ? bal : app);
        }

        packCounter = packCounter.add(1);

        emit NewPackListing(msg.sender, _tokenAddress, packId, _ids, _price);
    }

    function changeListingPrice(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _newPrice
    )
        public
        userNotBanned
        isListed(_tokenAddress, _id)
        isSeller(_tokenAddress, _id)
    {
        listings[address(_tokenAddress)][_id].price = _newPrice;
        emit ListingPriceChange(
            msg.sender,
            _tokenAddress,
            _id,
            _newPrice
        );
    }

    function changePackListingPrice(
        IERC721 _tokenAddress,
        uint256 _packId,
        uint256 _newPrice
    )
        external
        userNotBanned
        isPackListed(_tokenAddress, _packId)
        isPackSeller(_tokenAddress, _packId)
    {
        packListings[address(_tokenAddress)][_packId].price = _newPrice;
        emit PackListingPriceChange(
            msg.sender,
            _tokenAddress,
            _packId,
            _newPrice
        );
    }

    function cancelListing(IERC721 _tokenAddress, uint256 _id)
        public
        userNotBanned
        isListed(_tokenAddress, _id)
        isSellerOrAdmin(_tokenAddress, _id)
    {
        address seller = listings[address(_tokenAddress)][_id].seller;

        delete listings[address(_tokenAddress)][_id];
        listedTokenIDs[address(_tokenAddress)].remove(_id);

        _updateListedTokenTypes(_tokenAddress);

        _tokenAddress.safeTransferFrom(address(this), seller, _id);

        emit CancelledListing(seller, _tokenAddress, _id);
    }

    function cancelPackListing(IERC721 _tokenAddress, uint256 _packId)
        external
        userNotBanned
        isPackListed(_tokenAddress, _packId)
        isPackSellerOrAdmin(_tokenAddress, _packId)
    {
        address seller = packListings[address(_tokenAddress)][_packId].seller;
        uint256[] memory items = packListings[address(_tokenAddress)][_packId].items;

        delete packListings[address(_tokenAddress)][_packId];
        listedPackIDs[address(_tokenAddress)].remove(_packId);

        for (uint256 i = 0; i < items.length; i++) {
            packListedTokenIDs[address(_tokenAddress)].remove(items[i]);
            _tokenAddress.safeTransferFrom(address(this), seller, items[i]);
        }

        _updateListedTokenTypes(_tokenAddress);

        emit CancelledPackListing(seller, _tokenAddress, _packId);
    }

    function purchaseListing(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _maxPrice
    )
        public
        userNotBanned
        isListed(_tokenAddress, _id)
        isHatched(_tokenAddress, _id)
    {
        uint256 finalPrice = getFinalPrice(_tokenAddress, _id);
        require(finalPrice <= _maxPrice, "Buying price too low");

        Listing memory listing = listings[address(_tokenAddress)][_id];
        require(isUserBanned[listing.seller] == false, "Banned seller");
        uint256 taxAmount = getTaxOnListing(_tokenAddress, _id);

        delete listings[address(_tokenAddress)][_id];
        listedTokenIDs[address(_tokenAddress)].remove(_id);
        _updateListedTokenTypes(_tokenAddress);

        buniToken.safeTransferFrom(msg.sender, taxRecipient, taxAmount);
        buniToken.safeTransferFrom(
            msg.sender,
            listing.seller,
            finalPrice.sub(taxAmount)
        );
        _tokenAddress.safeTransferFrom(address(this), msg.sender, _id);

        emit PurchasedListing(
            msg.sender,
            listing.seller,
            _tokenAddress,
            _id,
            finalPrice
        );
    }

    function purchasePackListing(
        IERC721 _tokenAddress,
        uint256 _packId,
        uint256 _maxPrice
    )
        external
        userNotBanned
        isPackListed(_tokenAddress, _packId)
    {
        uint256 finalPrice = getPackFinalPrice(_tokenAddress, _packId);
        require(finalPrice <= _maxPrice, "Buying price too low");

        PackListing memory pack = packListings[address(_tokenAddress)][_packId];
        require(isUserBanned[pack.seller] == false, "Banned seller");
        uint256 taxAmount = getPackTaxOnListing(_tokenAddress, _packId);

        delete packListings[address(_tokenAddress)][_packId];
        listedPackIDs[address(_tokenAddress)].remove(_packId);

        for (uint256 i = 0; i < pack.items.length; i++) {
            packListedTokenIDs[address(_tokenAddress)].remove(pack.items[i]);
            _tokenAddress.safeTransferFrom(address(this), msg.sender, pack.items[i]);
        }

        buniToken.safeTransferFrom(msg.sender, taxRecipient, taxAmount);
        buniToken.safeTransferFrom(
            msg.sender,
            pack.seller,
            finalPrice.sub(taxAmount)
        );

        _updateListedTokenTypes(_tokenAddress);

        emit PurchasedPackListing(
            msg.sender,
            pack.seller,
            _tokenAddress,
            _packId,
            finalPrice
        );
    }

    function setTaxRecipient(address _taxRecipient) public restricted {
        taxRecipient = _taxRecipient;
    }

    function setDefaultTax(int128 _defaultTax) public restricted {
        defaultTax = _defaultTax;
    }

    function setDefaultTaxAsRational(uint256 _numerator, uint256 _denominator)
        public
        restricted
    {
        defaultTax = ABDKMath64x64.divu(_numerator, _denominator);
    }

    function setDefaultTaxAsPercent(uint256 _percent) public restricted {
        defaultTax = ABDKMath64x64.divu(_percent, 100);
    }

    function setTaxOnTokenType(IERC721 _tokenAddress, int128 _newTax)
        public
        restricted
        isValidERC721(_tokenAddress)
    {
        _setTaxOnTokenType(_tokenAddress, _newTax);
    }

    function setTaxOnTokenTypeAsRational(
        IERC721 _tokenAddress,
        uint256 _numerator,
        uint256 _denominator
    ) public restricted isValidERC721(_tokenAddress) {
        _setTaxOnTokenType(
            _tokenAddress,
            ABDKMath64x64.divu(_numerator, _denominator)
        );
    }

    function setTaxOnTokenTypeAsPercent(
        IERC721 _tokenAddress,
        uint256 _percent
    ) public restricted isValidERC721(_tokenAddress) {
        _setTaxOnTokenType(
            _tokenAddress,
            ABDKMath64x64.divu(_percent, 100)
        );
    }

    function setGameContract(IBuniUniversalV2 _gameContract) public restricted {
        gameContract = _gameContract;
    }

    function setUserBan(address user, bool to) public restricted {
        isUserBanned[user] = to;
    }

    function setUserBans(address[] memory users, bool to) public restricted {
        for(uint i = 0; i < users.length; i++) {
            isUserBanned[users[i]] = to;
        }
    }

    function allowToken(IERC721 _tokenAddress) public restricted isValidERC721(_tokenAddress) {
        allowedTokenTypes.add(address(_tokenAddress));
    }

    function disallowToken(IERC721 _tokenAddress) public restricted {
        allowedTokenTypes.remove(address(_tokenAddress));
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256 _id,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        // NOTE: The contract address is always the message sender.
        address _tokenAddress = msg.sender;

        require(
            listedTokenTypes.contains(_tokenAddress) &&
                (
                    listedTokenIDs[_tokenAddress].contains(_id) ||
                    packListedTokenIDs[_tokenAddress].contains(_id)
                ),
            "Token ID not listed"
        );

        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function setHatchableTokens(IERC721 _tokenAddress) public restricted isValidERC721(_tokenAddress) {
        hatchableTokens.add(address(_tokenAddress));
    }

    function removeHatchableTokens(IERC721 _tokenAddress) public restricted {
        hatchableTokens.remove(address(_tokenAddress));
    }

    // ############
    // Internal helpers
    // ############
    function _setTaxOnTokenType(IERC721 tokenAddress, int128 newTax) private {
        require(newTax >= 0, "We're not running a charity here");
        tax[address(tokenAddress)] = newTax;
        freeTax[address(tokenAddress)] = newTax == 0;
    }

    function _updateListedTokenTypes(IERC721 tokenAddress) private {
        if (listedTokenIDs[address(tokenAddress)].length() > 0) {
            _registerTokenAddress(tokenAddress);
        } else {
            _unregisterTokenAddress(tokenAddress);
        }
    }

    function _registerTokenAddress(IERC721 tokenAddress) private {
        if (!listedTokenTypes.contains(address(tokenAddress))) {
            listedTokenTypes.add(address(tokenAddress));

            // this prevents resetting custom tax by removing all
            if (
                tax[address(tokenAddress)] == 0 && // unset or intentionally free
                freeTax[address(tokenAddress)] == false
            ) tax[address(tokenAddress)] = defaultTax;
        }
    }

    function _unregisterTokenAddress(IERC721 tokenAddress) private {
        listedTokenTypes.remove(address(tokenAddress));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library RandomUtil {

    using SafeMath for uint256;

    function randomSeededMinMax(uint min, uint max, uint seed) internal pure returns (uint) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        uint diff = max.sub(min).add(1);
        uint randomVar = uint(keccak256(abi.encodePacked(seed))).mod(diff);
        randomVar = randomVar.add(min);
        return randomVar;
    }

    function combineSeeds(uint seed1, uint seed2) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seed1, seed2)));
    }

    function combineSeeds(uint[] memory seeds) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeds)));
    }

    function plusMinus10PercentSeeded(uint256 num, uint256 seed) internal pure returns (uint256) {
        uint256 tenPercent = num.div(10);
        return num.sub(tenPercent).add(randomSeededMinMax(0, tenPercent.mul(2), seed));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
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
pragma solidity 0.6.12;

interface ITrainersV2 {
    // read
    // function getTotalTrainers() external view returns(uint256);
    
    // write
    function mintOneTrainerBySpecs(address _minter, uint8 _element) external;
    function mintOneTrainerBySpecsByAdmin(address _minter, uint8 _element, uint8 _level) external;
    // function mintByMigrator(address _tokenOwner, uint8 _element, uint16 _exp, uint8 _level, uint8 _fusionLevel) external;
    function burnByGameContract(uint256 _trainerId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/EnumerableSetUpgradeable.sol";
import "../../utils/EnumerableMapUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
    using StringsUpgradeable for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSetUpgradeable.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMapUpgradeable.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721Upgradeable.isApprovedForAll(owner, _msgSender()),
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
        return _tokenOwners.contains(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721Upgradeable.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

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
        address owner = ERC721Upgradeable.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721ReceiverUpgradeable(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId); // internal owner
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
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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
library SafeMathUpgradeable {
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
library EnumerableMapUpgradeable {
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

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBunicornsV2 {
    // read
    // function getTotalBunicorns() external view returns(uint256);

    // write
    function mintOneBunicornBySpecs(
        address _tokenOwner,
        uint16 _props,
        uint16 _attr1,
        uint16 _attr2,
        uint16 _attr3
    ) external returns(uint256);

    function mintOneEventBunicornBySpecs(
        address _tokenOwner,
        uint16 _props,
        uint16 _attr1,
        uint16 _attr2,
        uint16 _attr3,
        uint32 _eventMultiplier,
        uint16 _eventId
    ) external returns(uint256);

    // function mintByMigrator(
    //     address _tokenOwner,
    //     uint16 _props,
    //     uint16 _attr1,
    //     uint16 _attr2,
    //     uint16 _attr3,
    //     uint8 _level
    // ) external;

    // function setEnhancePowerByMigrator(
    //     uint256 _tokenId,
    //     uint8 _lowBurnPoints,
    //     uint8 _fourBurnPoints,
    //     uint8 _fiveBurnPoints
    // ) external;

    function burnByGameContract(uint256 _bunicornId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../IERC20ConsumableItem.sol";

interface IBuniUniversalV2 {
    // migrator
    // function setGlobalStaminaByMigrator(address _playerAddress) external;
    // function setTokenRewardsByMigrator(address _playerAddress, uint256 _amount, uint256 _timerStart) external;
    // function setExpRewardsByMigrator(uint256 _trainer, uint256 _exp) external;
    // price oracle
    function usdToBuni(int128 usdAmount) external view returns (uint256);
    function usdToBur(int128 usdAmount) external view returns (uint256);
    // v3.1 read methods
    function requestPayOnlyBuniAmount(address _player, int128 usdBuni) external view;
    function requestPayOnlyExtractBuniAmount(address _player, uint256 _buniAmount) external view;
    function requestPayOnlyBurAmount(address _player, int128 usdBur) external view;
    function requestPayOnlyExtractBurAmount(address _player, uint256 _burAmount) external view;
    function requestPayMixedAmounts(address _player, int128 usdBuni, int128 usdBur) external view;
    function requestPayExtractMixedAmounts(address _player, uint256 _buniAmount, uint256 _burAmount) external view;
    function requestPayERC20ConsumableItem(
        IERC20ConsumableItem token, address player, uint256 amount
    ) external view;
    // v3.1 write method
    function payOnlyBuniAmount(address _player, int128 _buniAmount) external;
    function payOnlyExtractBuniAmount(address _player, uint256 _buniAmount) external;
    function payOnlyBurAmount(address _player, int128 _burAmount) external;
    function payOnlyExtractBurAmount(address _player, uint256 _burAmount) external;
    function payMixedAmounts(address _player, int128 _buniAmount, int128 _burAmount) external;
    function payExtractMixedAmounts(address _player, uint256 _buniAmount, uint256 _burAmount) external;
    function payERC20ConsumableItems(
        IERC20ConsumableItem token, address player, uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IvBuni.sol";
import "./interfaces/IBunicornRoller.sol";
import "./interfaces/ITrainerRoller.sol";

contract MysteryBoxV2 is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;

    IvBuni public vBuni;
    IBunicornRoller public bunicornRoller;
    ITrainerRoller public trainerRoller;
    uint256 totalOpen;
    uint8 element;

    uint256 MIN_GUARANTEE;
    uint256 MAX_GUARANTEE;

    mapping(uint256 => Rarity) public tokenRarity;
    mapping(uint256 => bool) public openedBoxes;

    mapping(address => uint256) userSeed;

    uint256[4] guarantees;
    uint256[4] rarityQuantity;

    bool public isEmergencyPause;

    enum Rarity {
        Unset,
        Chest,
        Egg,
        RareEgg,
        EpicEgg
    }

    modifier notInEmergencyPause() {
        _notInEmergencyPause();
        _;
    }

    function _notInEmergencyPause() internal view {
        require(!isEmergencyPause, "mystery box: emergency pause");
    }

    modifier restricted() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not game admin");
        _;
    }

    modifier notOpened(uint256 _id) {
        require(!openedBoxes[_id], "Box is opened");
        _;
    }

    modifier contractNotAllowed() {
        require(tx.origin == msg.sender, "Contract are not allowed to call");
        _;
    }

    modifier onlyNftOwner(uint256 _id) {
        require(getVbuniOwner(_id) == msg.sender, "Not owner of NFT");
        _;
    }

    event OpenBox(
        uint256 indexed boxId,
        Rarity rarity,
        address opener,
        uint256 timestamp
    );

    function initialize(
        IvBuni _vBuni,
        IBunicornRoller _bunicornRoller,
        ITrainerRoller _trainerRoller
    ) public initializer {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        vBuni = _vBuni;
        bunicornRoller = _bunicornRoller;
        trainerRoller = _trainerRoller;

        MIN_GUARANTEE = 100;
        MAX_GUARANTEE = 300;

        guarantees = [200000e18, 10000e18, 5000e18, 2000e18];
        rarityQuantity = [10000e18, 5000e18, 2000e18, 1000e18];
        element = 3;
    }

    function setEmergencyPause(bool _isEmergencyPause) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        isEmergencyPause = _isEmergencyPause;
    }

    function changeVbuni(IvBuni _newVbuni) public restricted {
        vBuni = _newVbuni;
    }

    function changeBunicornRoller(IBunicornRoller _newBunicornRoller) public restricted {
        bunicornRoller = _newBunicornRoller;
    }

    function changeTrainerRoller(ITrainerRoller _newTrainerRoller) public restricted {
        trainerRoller = _newTrainerRoller;
    }

    function setGuaranteeRate(uint256[4] memory _guarantees) public restricted {
        guarantees = _guarantees;
    }

    function openMysteryBox(uint256 _id)
        external
        notInEmergencyPause
        notOpened(_id)
        contractNotAllowed
        onlyNftOwner(_id)
    {
        openedBoxes[_id] = true;
        totalOpen = totalOpen.add(1);
        uint256 vestedAmount = getVestedAmount(_id);

        // Open logic
        Rarity rarity = tokenRarity[_id];

        require(rarity != Rarity.Unset, "This VBuni not setted for opening");
        // Calculate logic
        if (rarity == Rarity.Chest) {
            openChest(msg.sender);
        } else if (rarity == Rarity.Egg) {
            openEgg(msg.sender, vestedAmount);
        } else if (rarity == Rarity.RareEgg) {
            openRareEgg(msg.sender, vestedAmount);
        }
        if (rarity == Rarity.EpicEgg) {
            openEpicEgg(msg.sender, vestedAmount);
        }

        // Emit Events
        emit OpenBox(_id, rarity, msg.sender, block.timestamp);
    }

    function openChest(address _receiver) private {
        uint256 randomNumber = random();
        uint256 rolled = randomNumber.mod(1e3);

        bunicornRoller.mintOneRandomBunicornWithStar(_receiver, 0, rolled % 100);
        trainerRoller.mintOneRandomTrainer(_receiver, rolled % 100);
    }

    function openEgg(address _receiver, uint256 _amount) private {
        uint256 randomNumber = random();

        uint256 guarantee = guarantees[2];
        uint256 minimumQuantity = rarityQuantity[2];

        uint256 rolled = randomNumber.mod(1e3);

        uint256 currentRate = ((_amount - minimumQuantity) * 1e3) /
            (guarantee - minimumQuantity);

        uint256 rate = getGuaranteeRate(currentRate);
        if (rolled <= rate) {
            bunicornRoller.mintOneRandomBunicornWithStarAndElement(
                _receiver,
                2,
                element,
                rolled % 100
            );
        } else {
            bunicornRoller.mintOneRandomBunicornWithStarAndElement(
                _receiver,
                1,
                element,
                rolled % 100
            );
        }
    }

    function openRareEgg(address _receiver, uint256 _amount) private {
        uint256 randomNumber = random();

        uint256 guarantee = guarantees[1];
        uint256 minimumQuantity = rarityQuantity[1];

        uint256 rolled = randomNumber.mod(1e3);

        uint256 currentRate = ((_amount - minimumQuantity) * 1e3) /
            (guarantee - minimumQuantity);

        uint256 rate = getGuaranteeRate(currentRate);
        if (rolled <= rate) {
            bunicornRoller.mintOneRandomBunicornWithStarAndElement(
                _receiver,
                3,
                element,
                rolled % 100
            );
        } else {
            bunicornRoller.mintOneRandomBunicornWithStarAndElement(
                _receiver,
                2,
                element,
                rolled % 100
            );
        }
    }

    function openEpicEgg(address _receiver, uint256 _amount) private {
        uint256 randomNumber = random();

        uint256 guarantee = guarantees[0];
        uint256 minimumQuantity = rarityQuantity[0];

        uint256 rolled = randomNumber.mod(1e3);

        uint256 currentRate = ((_amount - minimumQuantity) * 1e3) /
            (guarantee - minimumQuantity);

        uint256 rate = getGuaranteeRate(currentRate);
        if (rolled <= rate) {
            bunicornRoller.mintOneRandomBunicornWithStarAndElement(
                _receiver,
                4,
                element,
                rolled % 100
            );
        } else {
            bunicornRoller.mintOneRandomBunicornWithStarAndElement(
                _receiver,
                3,
                element,
                rolled % 100
            );
        }
    }

    function getDefaultRarity(uint256 _id) public view returns (Rarity rarity) {
        uint256 amount = getVestedAmount(_id);
        require(
            amount >= rarityQuantity[3],
            "Token not reach minimum quantity for opening"
        );

        if (amount >= rarityQuantity[0]) {
            return Rarity.EpicEgg;
        }

        if (amount >= rarityQuantity[1]) {
            return Rarity.RareEgg;
        }

        if (amount >= rarityQuantity[2]) {
            return Rarity.Egg;
        }

        return Rarity.Chest;
    }

    function getVestedAmount(uint256 _id) public view returns (uint256 amount) {
        (, amount, , ) = vBuni.getTokenInfo(_id);
    }

    function getVbuniOwner(uint256 _id) public view returns (address owner) {
        return vBuni.ownerOf(_id);
    }

    function getTokenRarity(uint256 _token)
        public
        view
        returns (Rarity rarity)
    {
        return tokenRarity[_token];
    }

    function getBoxStatus(uint256 _id) external view returns (bool opened) {
        return openedBoxes[_id];
    }

    function assignRarity(uint256[] memory _tokens, Rarity[] memory _rarities)
        external
        restricted
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 tokenId = _tokens[i];
            Rarity rarity = _rarities[i];

            tokenRarity[tokenId] = rarity;
        }
    }

    function random() internal view returns (uint256 randomNumber) {
        // sha3 and now have been deprecated
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        _msgSender(),
                        totalOpen
                    )
                )
            );
    }

    function getGuaranteeRate(uint256 rolledRate)
        internal
        view
        returns (uint256)
    {
        if (rolledRate < MIN_GUARANTEE) {
            return MIN_GUARANTEE;
        }
        if (rolledRate > MAX_GUARANTEE) {
            return MAX_GUARANTEE;
        }
        return rolledRate;
    }
}