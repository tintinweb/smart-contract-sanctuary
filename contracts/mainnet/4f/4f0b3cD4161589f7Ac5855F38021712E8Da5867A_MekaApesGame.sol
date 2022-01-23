// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./MekaApesERC721.sol";
import "./OogearERC20.sol";
import "./IDMT_ERC20.sol";

enum OogaType { ROBOOOGA, MEKAAPE }

struct OogaAttributes {
    OogaType oogaType;
    uint8 level;

    bool staked;
    address stakedOwner;

    uint256 lastClaimTimestamp;
    uint256 savedReward;

    uint256 lastRewardPerPoint;
    uint256 stakedMegaIndex;
}

struct Prices {
    uint256 mintPrice;
    uint256 mintStakePrice;
    uint256[] mintOGprice;
    uint256[] mintOGstakePrice;
    uint256 mintDMTstakePrice;
    uint256[] roboLevelupPrice;
    uint256 mekaMergePrice;
}

struct PricesGetter {
    uint256 mintPrice;
    uint256 mintStakePrice;
    uint256 mintOGprice;
    uint256 mintOGstakePrice;
    uint256 mintDMTstakePrice;
    uint256[] roboLevelupPrice;
    uint256 mekaMergePrice;
}

struct RandomsGas {
    uint256 mintBase;
    uint256 mintPerToken;
    uint256 mintPerTokenStaked;
    uint256 unstakeBase;
    uint256 unstakePerToken;
    uint256 mergeBase;
}

struct InitParams {
    MekaApesERC721 erc721Contract_;
    OogearERC20 ogToken_;
    IDMT_ERC20 dmtToken_;
    IERC721 oogaVerse_;
    address mintSigWallet_;
    address randomProvider_;
    Prices prices_;
    RandomsGas randomsGas_;
    uint256[] mintOGpriceSteps_;
    uint256[] roboOogaRewardPerSec_;
    uint256[] roboOogaMinimalRewardToUnstake_;
    uint256[] roboOogaRewardAttackProbabilities_;
    uint256[] megaLevelProbabilities_;
    uint256[] mekaLevelSharePoints_;
    uint256[] megaTributePoints_;
    uint256 claimTax_;
    uint256 maxMintWithDMT_;
    uint256 mintSaleAmount_;
    uint256 maxTokenSupply_;
    uint256 maxOgSupply_;
    uint256 addedOgForRewardsAtEnd_;
    uint256 ethMintAttackChance_;
    uint256 dmtMintAttackChance_;
    uint256 ogMintAttackChance_;
    uint256 randomMekaProbability_;
    uint256 publicMintAllowance_;
    uint256 maxMintedRewardTokens_;
    address[] mintETHWithdrawers_;
    uint256[] mintETHWithdrawersPercents_;
}

struct MintSignature {
    uint256 mintAllowance;
    uint8 _v;
    bytes32 _r; 
    bytes32 _s;
}

enum RandomRequestType { MINT, UNSTAKE, MERGE }

struct RandomRequest {
    RandomRequestType requestType;
    address user;
    bool active;
}

struct ClaimRequest {
    uint256 totalMekaReward;
    uint256[] roboOogas;
    uint256[] roboOogasAmounts;
}

struct MintRequest {
    uint32 startFromId;
    uint8 amount;
    uint8 attackChance;
    bool toStake;
}

contract MekaApesGame is OwnableUpgradeable {

    MekaApesERC721 public erc721Contract;
    OogearERC20 public ogToken;
    IDMT_ERC20 public dmtToken;
    IERC721 public oogaVerse;

    address public mintSigWallet;
    address public randomProvider;

    Prices public prices;
    RandomsGas public randomsGas;

    uint256[] public mintOGpriceSteps;
    uint256 public currentOgPriceStep;

    uint256[] public roboOogaRewardPerSec;
    uint256[] public roboOogaMinimalRewardToUnstake;
    uint256[] public roboOogaRewardAttackProbabilities;

    uint256 public claimTax;

    uint256 public nextTokenId;

    uint256 public tokensMintedWithDMT;
    uint256 public maxMintWithDMT;

    uint256 public ethMintAttackChance;
    uint256 public dmtMintAttackChance;
    uint256 public ogMintAttackChance;
    uint256 public ATTACK_CHANCE_DENOM;

    uint256 public randomMekaProbability;

    uint256[] public megaLevelProbabilities;

    uint256[] public mekaLevelSharePoints;
    uint256[] public megaTributePoints;

    uint256 public mekaTotalRewardPerPoint;
    uint256 public mekaTotalPointsStaked;

    uint256[][4] public megaStaked;

    mapping(uint256 => OogaAttributes) public oogaAttributes;

    mapping(uint256 => bool) public oogaEvolved;

    uint256 public publicMintAllowance;
    bool public publicMintStarted;
    mapping(address => uint256) public numberOfMintedOogas;

    uint256 public mintSaleAmount;
    bool public mintSale;
    bool public gameActive;

    uint256 public ogMinted;
    uint256 public maxOgSupply;
    uint256 public addedOgForRewardsAtEnd;

    uint256 public maxTokenSupply;

    uint256 public totalMintedRewardTokens;
    uint256 public maxMintedRewardTokens;

    uint256 public totalRandomTxFee;
    uint256 public totalRandomTxFeeWithdrawn;

    uint256 public totalMintETH;
    mapping(address => uint256) public withdrawerPercent;
    mapping(address => uint256) public withdrawerLastTotalMintETH;

    uint256 public nextRandomRequestId;
    mapping(uint256 => RandomRequest) public randomRequests;
    mapping(uint256 => MintRequest) public mintRequests;
    mapping(uint256 => ClaimRequest) public claimRequests;
    mapping(uint256 => uint256) public mergeRequests;
    uint256 public nextClaimWithoutRandomId;

    event MintMultipleRobo(address indexed account, uint256 startFromTokenId, uint256 amount);
    event MekaConvert(uint256 indexed tokenId);
    event OogaAttacked(uint256 indexed oogaId, address indexed tributeAccount, uint256 tributeOogaId);
    event BabyOogaEvolve(address indexed account, uint256 indexed oogaId, uint256 indexed newTokenId);
    event StakeOoga(uint256 indexed oogaId, address indexed account);
    event UnstakeOoga(uint256 indexed oogaId, address indexed account);
    event ClaimReward(uint256 indexed claimId, address indexed account, uint256 indexed tokenId, uint256 amount);
    event TaxReward(uint256 indexed claimId, uint256 totalTax);
    event AttackReward(uint256 indexed claimId, uint256 indexed tokenId, uint256 amount);
    event LevelUpRoboOoga(address indexed account, uint256 indexed oogaId, uint256 newLevel);
    event MergeMekaApes(address indexed account, uint256 oogaIdSave, uint256 indexed oogaIdBurn);
    event MegaMerged(uint256 indexed tokenId, uint256 megaLevel);

    event RequestRandoms(uint256 indexed requestId, uint256 requestSeed);
    event ReceiveRandoms(uint256 indexed requestId, uint256 entropy);

    function initialize(
        InitParams calldata initParams
    ) public initializer {
        __Ownable_init();

        erc721Contract = initParams.erc721Contract_;
        ogToken = initParams.ogToken_;
        dmtToken = initParams.dmtToken_;
        oogaVerse = initParams.oogaVerse_;

        mintSigWallet = initParams.mintSigWallet_;
        randomProvider = initParams.randomProvider_;

        nextRandomRequestId = 1;
        nextClaimWithoutRandomId = 100000000;

        nextTokenId = 1;

        tokensMintedWithDMT = 0;

        maxMintWithDMT = initParams.maxMintWithDMT_;
        mintSaleAmount = initParams.mintSaleAmount_;
        maxTokenSupply = initParams.maxTokenSupply_;

        ogMinted = 0;
        maxOgSupply = initParams.maxOgSupply_;
        addedOgForRewardsAtEnd = initParams.addedOgForRewardsAtEnd_;

        ethMintAttackChance = initParams.ethMintAttackChance_;
        dmtMintAttackChance = initParams.dmtMintAttackChance_;
        ogMintAttackChance = initParams.ogMintAttackChance_;

        randomMekaProbability = initParams.randomMekaProbability_;

        mintSale = true;
        gameActive = true;  

        publicMintAllowance = initParams.publicMintAllowance_;
        publicMintStarted = false;

        totalMintedRewardTokens = 0;
        maxMintedRewardTokens = initParams.maxMintedRewardTokens_;

        mekaTotalRewardPerPoint = 0;
        mekaTotalPointsStaked = 0;
        megaLevelProbabilities = initParams.megaLevelProbabilities_;
        mekaLevelSharePoints = initParams.mekaLevelSharePoints_;
        megaTributePoints = initParams.megaTributePoints_;

        prices = initParams.prices_;
        randomsGas = initParams.randomsGas_;

        totalRandomTxFee = 0;
        totalRandomTxFeeWithdrawn = 0;

        mintOGpriceSteps = initParams.mintOGpriceSteps_;
        currentOgPriceStep = 1;

        roboOogaRewardPerSec = initParams.roboOogaRewardPerSec_;
        roboOogaMinimalRewardToUnstake = initParams.roboOogaMinimalRewardToUnstake_;
        roboOogaRewardAttackProbabilities = initParams.roboOogaRewardAttackProbabilities_;

        claimTax = initParams.claimTax_;

        for(uint256 i=0; i<initParams.mintETHWithdrawers_.length; i++) {
            withdrawerPercent[initParams.mintETHWithdrawers_[i]] = initParams.mintETHWithdrawersPercents_[i];
            withdrawerLastTotalMintETH[initParams.mintETHWithdrawers_[i]] = 0;
        }
    }

    function changePrices(Prices memory prices_) external onlyOwner {
        prices = prices_;
    }

    function changePublicMintStarted(bool publicMintStarted_) external onlyOwner {
        publicMintStarted = publicMintStarted_;
    }

    function changeGameActive(bool gameActive_) external onlyOwner {
        gameActive = gameActive_;
    }

    function changeMintSale(bool mintSale_) external onlyOwner {
        mintSale = mintSale_;
    }

    function changeRandomsGas(RandomsGas memory randomsGas_) external onlyOwner {
        randomsGas = randomsGas_;
    }

    function changeMintOGPriceSteps(uint256[] calldata mintOGpriceSteps_) external onlyOwner {
        mintOGpriceSteps = mintOGpriceSteps_;
    }

    function changeRoboParameters(
        uint256[] calldata roboOogaRewardPerSec_,
        uint256[] calldata roboOogaMinimalRewardToUnstake_,
        uint256[] calldata roboOogaRewardAttackProbabilities_
    )
        external onlyOwner
    {
        roboOogaRewardPerSec = roboOogaRewardPerSec_;
        roboOogaMinimalRewardToUnstake = roboOogaMinimalRewardToUnstake_;
        roboOogaRewardAttackProbabilities = roboOogaRewardAttackProbabilities_;
    }

    function changeMekaParameters(
        uint256[] calldata megaLevelProbabilities_,
        uint256[] calldata mekaLevelSharePoints_,
        uint256[] calldata megaTributePoints_
    )
        external onlyOwner
    {
        megaLevelProbabilities = megaLevelProbabilities_;
        mekaLevelSharePoints = mekaLevelSharePoints_;
        megaTributePoints = megaTributePoints_;
    }

    function changeSettings(
        uint256 claimTax_,
        uint256 maxMintWithDMT_,
        uint256 mintSaleAmount_,
        uint256 maxTokenSupply_,
        uint256 maxOgSupply_,
        uint256 addedOgForRewardsAtEnd_,
        uint256 ethMintAttackChance_,
        uint256 dmtMintAttackChance_,
        uint256 ogMintAttackChance_,
        uint256 randomMekaProbability_
    ) 
        external onlyOwner 
    {
        claimTax = claimTax_;
        maxMintWithDMT = maxMintWithDMT_;
        mintSaleAmount = mintSaleAmount_;
        maxTokenSupply = maxTokenSupply_;
        maxOgSupply = maxOgSupply_;
        addedOgForRewardsAtEnd = addedOgForRewardsAtEnd_;
        ethMintAttackChance = ethMintAttackChance_;
        dmtMintAttackChance = dmtMintAttackChance_;
        ogMintAttackChance = ogMintAttackChance_;
        randomMekaProbability = randomMekaProbability_;
    }

    function totalMintedTokens() public view returns(uint256) {
        return nextTokenId - 1;
    } 

    function getPrices() public view returns(PricesGetter memory) {
        return PricesGetter(
            prices.mintPrice,
            prices.mintStakePrice,
            prices.mintOGprice[ currentOgPriceStep ],
            prices.mintOGstakePrice[ currentOgPriceStep ],
            prices.mintDMTstakePrice,
            prices.roboLevelupPrice,
            prices.mekaMergePrice
        );
    }

    function mintRandomGas(uint256 amount, bool staking) public view returns(uint256) {
        return randomsGas.mintBase + amount*randomsGas.mintPerToken + (staking ? (amount-1)*randomsGas.mintPerTokenStaked : 0);
    }

    function unstakeRandomGas(uint256 roboAmount) public view returns(uint256) {
        return randomsGas.unstakeBase + roboAmount*randomsGas.unstakePerToken;
    }

    function mergeRandomGas() public view returns(uint256) {
        return randomsGas.mergeBase;
    }

    function allowedToMint(address account, uint256 mintAllowance) external view returns(uint256) {
        return mintAllowance + ((publicMintStarted) ? publicMintAllowance : 0) - numberOfMintedOogas[account];
    }

    function requestRandoms() internal returns (uint256) {
        emit RequestRandoms(nextRandomRequestId, nextRandomRequestId);
        nextRandomRequestId++;
        return nextRandomRequestId - 1;
    }

    function _receiveRandoms(uint256 requestId, uint256 entropy) private {
        emit ReceiveRandoms(requestId, entropy);

        RandomRequest storage request = randomRequests[requestId];

        if(!request.active) return;

        request.active = false;

        if (request.requestType == RandomRequestType.MINT) {
            receiveMintRandoms(request.user, requestId, entropy);
        } else if (request.requestType == RandomRequestType.MERGE) {
            receiveMergeRandoms(requestId, entropy);
        } else if (request.requestType == RandomRequestType.UNSTAKE) {
            receiveUnstakeRandoms(request.user, requestId, entropy);
        }
    }

    function receiveRandoms(uint256 requestId, uint256 entropy) external { 
        require(msg.sender == randomProvider, "E60");
        _receiveRandoms(requestId, entropy);
    }

    function receiveMultipleRandoms(uint256[] calldata requestIds, uint256[] calldata entropies) external {
        require(msg.sender == randomProvider, "E60");

        uint256 length = requestIds.length;
        for(uint256 i=0; i<length; i++) {
            _receiveRandoms(requestIds[i], entropies[i]);
        }

        uint256 randomTxFeeAmount = totalRandomTxFee - totalRandomTxFeeWithdrawn;
        if (randomTxFeeAmount > 0.3 ether) {
            totalRandomTxFeeWithdrawn += randomTxFeeAmount;
            payable(randomProvider).transfer(randomTxFeeAmount);
        }
    }

    function withdrawRandomTxFee(uint256 amount) external {
        require(msg.sender == randomProvider, "E99");
        require(totalRandomTxFee - totalRandomTxFeeWithdrawn <= amount, "E98");
        totalRandomTxFeeWithdrawn += amount;
        payable(randomProvider).transfer(amount);
    } 

    function _ogMint(address toAddress, uint256 amount) private {

        uint256 toMint = amount;

        if (ogMinted + amount > maxOgSupply) {
            toMint = maxOgSupply - ogMinted;

            gameActive = false;
            ogToken.mint(address(this), addedOgForRewardsAtEnd);
        }

        ogToken.mint(toAddress, toMint);
    }

    function _mintMekaOoga(address toAddress) private returns (uint256) {
        uint256 tokenId = nextTokenId;
        nextTokenId++;

        if (nextTokenId >= mintOGpriceSteps[currentOgPriceStep]) {
            currentOgPriceStep++;
        }

        erc721Contract.mint(toAddress, tokenId);

        oogaAttributes[tokenId].oogaType = OogaType.MEKAAPE;
        oogaAttributes[tokenId].level = 0;
        
        return tokenId;
    }

    function _mintMultipleRoboOoga(address toAddress, uint256 amount) private returns(uint256) {

        uint256 startFromTokenId = nextTokenId;

        nextTokenId += amount;

        if (nextTokenId >= mintOGpriceSteps[currentOgPriceStep]) {
            currentOgPriceStep++;
        }

        erc721Contract.mintMultiple(toAddress, startFromTokenId, amount);

        for(uint256 i=0; i<amount; i++) {
            oogaAttributes[startFromTokenId + i].level = 1;
        }

        emit MintMultipleRobo(toAddress, startFromTokenId, amount);

        return startFromTokenId;
    }  

    function requestMintRoboOogas(address toAddress, uint256 amount, bool toStake, uint256 attackChance) private { 
        
        uint256 randomsAmount;
        if (attackChance > 0) {
            randomsAmount = 2*amount;
        } else {
            randomsAmount = amount;
        }

        uint256 requestId = requestRandoms();
        randomRequests[requestId] = RandomRequest(RandomRequestType.MINT, toAddress, true);
        mintRequests[requestId] = MintRequest(uint32(nextTokenId), uint8(amount), uint8(attackChance), toStake);

        _mintMultipleRoboOoga(address(this), amount);
    }

    function getTotalMegaTributePointsStaked() private view returns(uint256) {
        uint256 totalTributePoints = 0;
        for(uint256 i=1; i<=3; i++) {
            totalTributePoints += megaTributePoints[i] * megaStaked[i].length;
        }
        return totalTributePoints;
    }

    function _getStakedMega(uint256 rndTributePoint) private view returns(uint256) {
        uint256 totalSum = 0;
        for(uint256 i=1; i<=3; i++) {
            uint256 levelSum = megaTributePoints[i] * megaStaked[i].length;

            if (rndTributePoint < totalSum + levelSum) {
                uint256 pickedIndex = (rndTributePoint - totalSum) / megaTributePoints[i];
                return megaStaked[i][pickedIndex];
            }

            totalSum += levelSum;
        }

        return 0;
    }

    function _getNextRandom(uint256 maxNumber, uint256 entropy, uint256 bits) private pure returns (uint256, uint256) {
        uint256 maxB = (uint256(1)<<bits);
        if (entropy < maxB) entropy = uint256(keccak256(abi.encode(entropy)));
        uint256 rnd = (entropy & (maxB - 1)) % maxNumber;
        return (rnd, entropy >> bits);
    }

    function _getNextRandomProbability(uint256 entropy) private pure returns (uint256, uint256) {
        if (entropy < 1048576) entropy = uint256(keccak256(abi.encode(entropy)));
        return(entropy & 1023, entropy >> 10);
    }

    function attackOogaMint(uint256 tokenId, uint256 totalTributePointStaked, uint256 entropy) private returns (uint256) {
        
        uint256 rndTributePoint; 

        (rndTributePoint, entropy) = _getNextRandom(totalTributePointStaked, entropy, 25);
        
        uint256 payTributeOoga = _getStakedMega(rndTributePoint);

        erc721Contract.transferFrom(address(this), oogaAttributes[payTributeOoga].stakedOwner, tokenId);
        emit OogaAttacked(tokenId, oogaAttributes[payTributeOoga].stakedOwner, payTributeOoga);
        
        return entropy;
    }

    function receiveMintRandoms(address user, uint256 requestId, uint256 entropy) private { 

        uint256 rnd;

        MintRequest storage mintReq = mintRequests[requestId];

        for(uint256 tokenId = mintReq.startFromId; tokenId < mintReq.startFromId + mintReq.amount; tokenId++) {

            OogaAttributes storage ooga = oogaAttributes[tokenId];

            (rnd, entropy) = _getNextRandomProbability(entropy);

            if (rnd < randomMekaProbability) {
                ooga.oogaType = OogaType.MEKAAPE;
                ooga.level = 0;
                emit MekaConvert(tokenId);
            }

            bool attacked = false;

            if (mintReq.attackChance > 0) {
                (rnd, entropy) = _getNextRandomProbability(entropy);
                if (rnd < mintReq.attackChance) {
                    uint256 totalTributePointStaked = getTotalMegaTributePointsStaked();
                    if (totalTributePointStaked > 0) {
                        entropy = attackOogaMint(tokenId, totalTributePointStaked, entropy);
                        attacked = true;
                    }
                }
            }

            if (!attacked) {
                if (mintReq.toStake) {
                    _stakeToken(tokenId, user, true);
                } else {
                    erc721Contract.transferFrom(address(this), user, tokenId);
                }
            }
        }
    }   

    function isBabyOogaEvolved(uint256 oogaId) public view returns(bool) {
        return oogaEvolved[oogaId];
    }

    function _evolveBabyOoga(uint256 oogaId) private {

        require(oogaId >= 2002001, "E11");
        require(oogaEvolved[oogaId] == false, "E12");
        require(oogaVerse.ownerOf(oogaId) == msg.sender, "E13");

        oogaEvolved[oogaId] = true;

        uint256 newTokenId = _mintMekaOoga(msg.sender);

        emit BabyOogaEvolve(msg.sender, oogaId, newTokenId); 
    }

    function evolveBabyOogas(uint256[] calldata tokenIds) external {
        require(!mintSale && gameActive, "E01");

        for(uint256 i=0; i<tokenIds.length; i++) {
            _evolveBabyOoga(tokenIds[i]);
        }
    }

    function _verifyMintSig(MintSignature memory sig, address acc) private view returns (bool) {
        bytes32 messageHash = keccak256(abi.encode(acc, sig.mintAllowance));
        bytes32 signedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address signer = ecrecover(signedMessageHash, sig._v, sig._r, sig._s);
        return signer == mintSigWallet;
    }

    function mintRewardTokens(address toAddress, uint256 amount) external payable onlyOwner {
        require(amount + totalMintedRewardTokens <= maxMintedRewardTokens, "E97");

        uint256 randomTxFee = mintRandomGas(amount, false) * block.basefee;

        require(msg.value >= randomTxFee, "E96");
        totalRandomTxFee += msg.value;

        requestMintRoboOogas(toAddress, amount, false, 0);
    }

    function mint(uint256 amount, bool toStake, MintSignature memory sig) external payable {
        require(mintSale, "E00");

        if (totalMintedTokens() + amount > mintSaleAmount) {
            amount = mintSaleAmount - totalMintedTokens();
            mintSale = false;
        }

        if (sig.mintAllowance > 0) {
            require(_verifyMintSig(sig, msg.sender), "E20");
        }

        uint256 maxAllowed = sig.mintAllowance + ((publicMintStarted) ? publicMintAllowance : 0);
        require(numberOfMintedOogas[msg.sender] + amount <= maxAllowed, "E21");
        numberOfMintedOogas[msg.sender] += amount;

        uint256 price;
        if (toStake) {
            price = prices.mintStakePrice;
        } else {
            price = prices.mintPrice;
        }

        require(msg.value >= amount * price, "E22");

        uint256 randomTxFee = mintRandomGas(amount, toStake) * block.basefee;

        totalMintETH += msg.value - randomTxFee;
        totalRandomTxFee += randomTxFee;

        requestMintRoboOogas(msg.sender, amount, toStake, ethMintAttackChance);
    }

    function mintWithOG(uint256 amount, bool toStake) external payable {
        require(!mintSale && gameActive, "E01");
        require(totalMintedTokens() + amount <= maxTokenSupply, "E31");

        require(msg.value >= mintRandomGas(amount, toStake) * block.basefee, "E33");
        totalRandomTxFee += msg.value;

        uint256 price;
        if (toStake) {
            price = prices.mintOGstakePrice[currentOgPriceStep];
        } else {
            price = prices.mintOGprice[currentOgPriceStep];
        }
        
        ogToken.transferFrom(msg.sender, address(this), price * amount);

        requestMintRoboOogas(msg.sender, amount, toStake, ogMintAttackChance);
    }

    function mintWithDMT(uint256 amount) external payable {
        require(!mintSale && gameActive, "E01");
        require(totalMintedTokens() + amount <= maxTokenSupply, "E32");
        require(tokensMintedWithDMT + amount <= maxMintWithDMT, "E51");

        require(msg.value >= mintRandomGas(amount, true) * block.basefee, "E34");
        totalRandomTxFee += msg.value;

        dmtToken.transferFrom(msg.sender, address(this), prices.mintDMTstakePrice * amount);

        requestMintRoboOogas(msg.sender, amount, true, dmtMintAttackChance);

        tokensMintedWithDMT += amount;
    }

    function _stakeToken(uint256 tokenId, address stakedOwner, bool minting) private {
        OogaAttributes storage ooga = oogaAttributes[tokenId];

        if (!minting) {
            erc721Contract.transferFrom(stakedOwner, address(this), tokenId);
        }

        ooga.staked = true;
        ooga.stakedOwner = stakedOwner;
        ooga.lastClaimTimestamp = block.timestamp;
        ooga.savedReward = 0;

        if (ooga.oogaType == OogaType.MEKAAPE) {
            mekaTotalPointsStaked += mekaLevelSharePoints[ooga.level];
            ooga.lastRewardPerPoint = mekaTotalRewardPerPoint;

            if (ooga.level > 0) {
                ooga.stakedMegaIndex = megaStaked[ooga.level].length;
                megaStaked[ooga.level].push(tokenId);
            }
        }

        emit StakeOoga(tokenId, stakedOwner);
    }

    function stake(uint256[] calldata tokenIds) external {
        require(gameActive, "E01");

        for(uint256 i=0; i<tokenIds.length; i++) {
            require(erc721Contract.ownerOf(tokenIds[i]) == msg.sender, "E41");
            _stakeToken(tokenIds[i], msg.sender, false);
        }
    }

    function _unstakeToken(uint256 tokenId) private {
        OogaAttributes storage ooga = oogaAttributes[tokenId];

        address oogaOwner = ooga.stakedOwner;

        ooga.staked = false;
        ooga.stakedOwner = address(0x0);

        if (ooga.oogaType == OogaType.MEKAAPE) {
            mekaTotalPointsStaked -= mekaLevelSharePoints[ooga.level];

            if (ooga.level > 0) {
                uint256 lastOogaId = megaStaked[ooga.level][ megaStaked[ooga.level].length - 1 ];
                megaStaked[ooga.level][ooga.stakedMegaIndex] = lastOogaId;
                megaStaked[ooga.level].pop();
                oogaAttributes[lastOogaId].stakedMegaIndex = ooga.stakedMegaIndex;
            }
        }

        ooga.stakedMegaIndex = 0;

        erc721Contract.transferFrom(address(this), oogaOwner, tokenId);

        emit UnstakeOoga(tokenId, oogaOwner);
    }

    function receiveUnstakeRandoms(address user, uint256 claimId, uint256 entropy) private {

        ClaimRequest storage claim = claimRequests[claimId];

        uint256 totalReward = 0;
        uint256 totalAttacked = 0;
        uint256 rnd;

        uint256 len = claim.roboOogas.length;

        for(uint256 i=0; i<len; i++) {

            (rnd, entropy) = _getNextRandomProbability(entropy);

            if (rnd < roboOogaRewardAttackProbabilities[ oogaAttributes[claim.roboOogas[i]].level ]) {
                totalAttacked += claim.roboOogasAmounts[i];
                emit AttackReward(claimId, claim.roboOogas[i], claim.roboOogasAmounts[i]);
            } else {
                totalReward += claim.roboOogasAmounts[i];
                emit ClaimReward(claimId, user, claim.roboOogas[i], claim.roboOogasAmounts[i]); 
            }

            claimRequests[claimId].roboOogas[i] = 0;
            claimRequests[claimId].roboOogasAmounts[i] = 0;
        }

        _addMekaRewards(totalAttacked);
        _ogMint(user, totalReward + claim.totalMekaReward);
    }

    function unstake(uint256[] calldata tokenIds) external payable {
        require(gameActive, "E01");
        uint256 roboAmount = _claim(tokenIds, true);

        require(msg.value >= unstakeRandomGas(roboAmount) * block.basefee, "E35");
        totalRandomTxFee += msg.value;
    }

    function _addMekaRewards(uint256 amount) private {
        _ogMint(address(this), amount);
        if(mekaTotalPointsStaked > 0){
            mekaTotalRewardPerPoint += amount / mekaTotalPointsStaked;
        }
    }

    function _claim(uint256[] calldata tokenIds, bool unstaking) private returns (uint256) { 
        uint256 totalRoboReward = 0;
        uint256 totalMekaReward = 0;
        uint256 totalTax = 0;

        uint256 claimId;

        if (unstaking) {
            claimId = nextRandomRequestId;
        } else {
            claimId = nextClaimWithoutRandomId;
        }

        ClaimRequest storage claim = claimRequests[claimId];

        for(uint256 i=0; i<tokenIds.length; i++) {

            OogaAttributes storage ooga = oogaAttributes[tokenIds[i]];
            require(ooga.staked == true && ooga.stakedOwner == msg.sender, "E91");

            uint256 reward = claimAvailableAmount(tokenIds[i]);

            if (ooga.oogaType == OogaType.ROBOOOGA) {
                uint256 taxable = (reward * claimTax) / 100;
                totalRoboReward += reward - taxable;
                totalTax += taxable;

                ooga.lastClaimTimestamp = block.timestamp;

                if (unstaking) {
                    require(reward >= roboOogaMinimalRewardToUnstake[ooga.level], "E92");
                    claim.roboOogas.push(tokenIds[i]);
                    claim.roboOogasAmounts.push(reward - taxable);
                } else {
                    emit ClaimReward(claimId, msg.sender, tokenIds[i], reward - taxable);
                }

            } else {
                totalMekaReward += reward;
                
                ooga.lastRewardPerPoint = mekaTotalRewardPerPoint;

                emit ClaimReward(claimId, msg.sender, tokenIds[i], reward);
            }

            if (unstaking) {
                _unstakeToken(tokenIds[i]);
            }

            ooga.savedReward = 0;
        }

        if (unstaking && claim.roboOogas.length > 0) {
            claim.totalMekaReward = totalMekaReward;

            uint256 requestId = requestRandoms();
            randomRequests[requestId] = RandomRequest(RandomRequestType.UNSTAKE, msg.sender, true);
            
        } else {
            _ogMint(msg.sender, totalMekaReward+totalRoboReward);
        }

        if (totalTax > 0) {
            _addMekaRewards(totalTax);
            emit TaxReward(claimId, totalTax);
        }

        return claim.roboOogas.length;
    }

    function claimReward(uint256[] calldata tokenIds) external {
        require(gameActive, "E01");
        _claim(tokenIds, false);
    }

    function claimAvailableAmount(uint256 tokenId) public view returns(uint256) {

        OogaAttributes memory ooga = oogaAttributes[tokenId];

        if (ooga.oogaType == OogaType.ROBOOOGA) {
            return ooga.savedReward + 
                    (block.timestamp - oogaAttributes[tokenId].lastClaimTimestamp) * roboOogaRewardPerSec[ooga.level];
        } else {
            return (mekaTotalRewardPerPoint - ooga.lastRewardPerPoint) * mekaLevelSharePoints[ooga.level];
        }
    }

    function claimAvailableAmountMultipleTokens(uint256[] calldata tokenIds) public view returns(uint256[] memory result) {
        result = new uint256[](tokenIds.length);
        for(uint256 i=0; i<tokenIds.length; i++) {
            result[i] = claimAvailableAmount(tokenIds[i]);
        }

        return result;
    }

    function levelUpRoboOooga(uint256 tokenId) external {
        require(!mintSale && gameActive, "E01");

        OogaAttributes storage ooga = oogaAttributes[tokenId];

        require(erc721Contract.ownerOf(tokenId) == msg.sender || ooga.stakedOwner == msg.sender , "E72");

        require(ooga.oogaType == OogaType.ROBOOOGA && ooga.level < 4, "E71");

        if (ooga.staked) {
            ooga.savedReward += claimAvailableAmount(tokenId);
            ooga.lastClaimTimestamp = block.timestamp;
        }

        dmtToken.transferFrom(msg.sender, address(this), prices.roboLevelupPrice[ooga.level]);

        ooga.level++;

        emit LevelUpRoboOoga(msg.sender, tokenId, ooga.level);
    }

    function _getMegaLevel(uint256 rnd) private view returns(uint8) {
        for(uint8 i=0; i<3; i++) {
            if (rnd < megaLevelProbabilities[i]) return 1+i;
        }
        
        return 0;
    }

    function receiveMergeRandoms(uint256 requestId, uint256 entropy) private { 
        uint256 tokenId = mergeRequests[requestId];

        OogaAttributes storage ooga =  oogaAttributes[tokenId];

        uint256 rnd;
        (rnd, entropy) = _getNextRandomProbability(entropy);
        ooga.level = _getMegaLevel(rnd);

        if (ooga.staked == true) {
            mekaTotalPointsStaked += mekaLevelSharePoints[ooga.level] - mekaLevelSharePoints[0];
            
            ooga.stakedMegaIndex = megaStaked[ooga.level].length;
            megaStaked[ooga.level].push(tokenId);
        }

        emit MegaMerged(tokenId, ooga.level);
    }

    function requestMergeMeka(uint256 tokenId) private {
        uint256 requestId = requestRandoms();
        randomRequests[requestId] = RandomRequest(RandomRequestType.MERGE, msg.sender, true);
        mergeRequests[requestId] = tokenId;
    }

    function mergeMekaApes(uint256 tokenIdSave, uint256 tokenIdBurn) external payable {
        require(!mintSale && gameActive, "E01");
        require(tokenIdSave != tokenIdBurn, "E81");

        require(msg.value >= randomsGas.mergeBase * block.basefee, "E36");
        totalRandomTxFee += msg.value;

        OogaAttributes storage oogaSave = oogaAttributes[tokenIdSave];
        OogaAttributes storage oogaBurn = oogaAttributes[tokenIdBurn];

        require(erc721Contract.ownerOf(tokenIdSave) == msg.sender || (oogaSave.staked && oogaSave.stakedOwner == msg.sender), "E84");
        require(erc721Contract.ownerOf(tokenIdBurn) == msg.sender || (oogaBurn.staked && oogaBurn.stakedOwner == msg.sender), "E85");

        require(oogaSave.oogaType == OogaType.MEKAAPE && oogaBurn.oogaType == OogaType.MEKAAPE, "E82");
        require(oogaSave.level == 0 && oogaBurn.level == 0, "E83");

        uint256 reward = 0;
        if (oogaSave.staked == true) {
            uint256 rewardAvailable = claimAvailableAmount(tokenIdSave);
            reward += rewardAvailable;
            oogaSave.lastRewardPerPoint = mekaTotalRewardPerPoint;
            emit ClaimReward(nextRandomRequestId, msg.sender, tokenIdSave, rewardAvailable);
        }

        if (oogaBurn.staked == true) {
            uint256 rewardAvailable = claimAvailableAmount(tokenIdBurn);
            reward += rewardAvailable;
            oogaBurn.lastRewardPerPoint = mekaTotalRewardPerPoint;
            emit ClaimReward(nextRandomRequestId, msg.sender, tokenIdBurn, rewardAvailable);
            _unstakeToken(tokenIdBurn);
        }

        if (prices.mekaMergePrice > reward) {
            ogToken.transferFrom(msg.sender, address(this), prices.mekaMergePrice - reward);
        } else {
            _ogMint(msg.sender, reward - prices.mekaMergePrice);
        }

        requestMergeMeka(tokenIdSave);

        erc721Contract.burn(tokenIdBurn);

        emit MergeMekaApes(msg.sender, tokenIdSave, tokenIdBurn);
    }

    function withdrawMintETH(uint256 amount) external {
        require(withdrawerPercent[msg.sender] > 0, "E94");

        uint256 maxAmount = ( (totalMintETH - withdrawerLastTotalMintETH[msg.sender]) * withdrawerPercent[msg.sender] ) / 100;
        if (amount > maxAmount) amount = maxAmount;

        withdrawerLastTotalMintETH[msg.sender] = totalMintETH;

        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20(IERC20 token, address toAddress, uint256 amount) external onlyOwner {
        token.transfer(toAddress, amount);
    }

    function withdrawERC721(IERC721 token, address toAddress, uint256 tokenId) external onlyOwner {
        token.transferFrom(address(this), toAddress, tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MekaApesERC721 is ERC721Upgradeable, OwnableUpgradeable {

    address public constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    address public gameContract;

    string public baseURI;

    string public _contractURI;

    function initialize(
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_,
        string memory contractURI_
    ) public initializer {

        __ERC721_init(name_, symbol_);
        __Ownable_init();

       
        baseURI = baseURI_;
        _contractURI = contractURI_;
    }

    function setGameContract(address gameContract_) external onlyOwner {
         gameContract = gameContract_;
    }   

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    function mint(address account, uint256 tokenId) external {
        require(msg.sender == gameContract, "E1");
        _mint(account, tokenId);
    }

    function mintMultiple(address account, uint256 startFromTokenId, uint256 amount) external {
        require(msg.sender == gameContract, "E1");
        for(uint256 i=0; i<amount; i++) {
            _mint(account, startFromTokenId + i);
        }
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == gameContract, "E2");
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "E3");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, uintToStr(tokenId), ".json")) : "";
    }

    function changeBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender) || spender == gameContract);
    }

    function uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract OogearERC20 is ERC20, Ownable {

    address public gameContract;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable() {

    }

    function setGameContract(address gameContract_) external onlyOwner {
         gameContract = gameContract_;
    }   

    function mint(address account, uint256 amount) external {
        require(msg.sender == gameContract, "E1");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        require(msg.sender == gameContract, "E2");
        _burn(account, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount || msg.sender == gameContract, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDMT_ERC20 {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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