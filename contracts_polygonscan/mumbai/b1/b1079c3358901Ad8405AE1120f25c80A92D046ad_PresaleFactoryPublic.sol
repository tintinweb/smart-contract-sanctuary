// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interface.sol";

contract LessLibrary is Ownable {
    address public usd;
    address[] public factoryAddress = new address[](2);

    uint256 private minInvestorBalance = 1000 * 1e18;
    uint256 private votingTime = 5 minutes; //three days
    uint256 private registrationTime = 5 minutes; // one day
    uint256 private minVoterBalance = 500 * 1e18; // minimum number of  tokens to hold to vote
    uint256 private minCreatorStakedBalance = 10000 * 1e18; // minimum number of tokens to hold to launch rocket
    uint8 private feePercent = 2;
    uint256 private usdFee;
    address private uniswapRouter; // uniswapV2 Router
    address payable private lessVault;
    address private devAddress;
    PresaleInfo[] private presaleAddresses; // track all presales created

    mapping(address=> bool) public stablecoinWhitelist;

    mapping(address => bool) private isPresale;
    mapping(bytes32 => bool) private usedSignature;
    mapping(address => bool) private signers; //adresses that can call sign functions

    struct PresaleInfo {
        bytes32 title;
        address presaleAddress;
        string description;
        bool isCertified;
        uint256 openVotingTime;
    }

    modifier onlyDev() {
        require(owner() == msg.sender || msg.sender == devAddress, "onlyDev");
        _;
    }

    modifier onlyPresale() {
        require(isPresale[msg.sender], "Not presale");
        _;
    }

    modifier onlyFactory() {
        require(factoryAddress[0] == msg.sender || factoryAddress[1] == msg.sender, "onlyFactory");
        _;
    }

    modifier factoryIndexCheck(uint8 _index){
        require(_index == 0 || _index == 1, "Invalid index");
        _;
    }

    constructor(address _dev, address payable _vault, address _uniswapRouter, address _usd, address[] memory _stablecoins, uint8 _usdDecimals) {
        require(_dev != address(0) && _vault != address(0) && _usdDecimals > 0, "Wrong params");
        devAddress = _dev;
        lessVault = _vault;
        uniswapRouter = _uniswapRouter;
        usd = _usd;
        usdFee = 1000 * 10 ** _usdDecimals;
        for(uint256 i=0; i <_stablecoins.length; i++){
            stablecoinWhitelist[_stablecoins[i]] = true;
        }
    }

    function setFactoryAddress(address _factory, uint8 _index) external onlyDev factoryIndexCheck(_index){
        require(_factory != address(0), "not 0");
        factoryAddress[_index] = _factory;
    }

    function setUsdFee(uint256 _newAmount) external onlyDev {
        require(_newAmount > 0, "0 amt");
        usdFee = _newAmount;
    }

    function setUsdAddress(address _newAddress) external onlyDev {
        require(_newAddress != address(0), "0 addr");
        usd = _newAddress;
    }

    function addPresaleAddress(
        address _presale,
        bytes32 _title,
        string memory _description,
        bool _type,
        uint256 _openVotingTime
    )
        external
        onlyFactory
        returns (uint256)
    {
        presaleAddresses.push(PresaleInfo(_title, _presale, _description, _type, _openVotingTime));
        isPresale[_presale] = true;
        return presaleAddresses.length - 1;
    }

    function addOrRemoveStaiblecoin(address _stablecoin, bool _isValid) external onlyDev {
        require(_stablecoin != address(0), "Not 0 addr");
        if(_isValid){
            require(!stablecoinWhitelist[_stablecoin], "Wrong param");
        }
        else {
            require(stablecoinWhitelist[_stablecoin], "Wrong param");
        }
        stablecoinWhitelist[_stablecoin] = _isValid;
    }

    function changeDev(address _newDev) external onlyDev {
        require(_newDev != address(0), "Wrong new address");
        devAddress = _newDev;
    }

    function setVotingTime(uint256 _newVotingTime) external onlyDev {
        require(_newVotingTime > 0, "Wrong new time");
        votingTime = _newVotingTime;
    }

    function setRegistrationTime(uint256 _newRegistrationTime) external onlyDev {
        require(_newRegistrationTime > 0, "Wrong new time");
        registrationTime = _newRegistrationTime;
    }

    function setUniswapRouter(address _uniswapRouter) external onlyDev {
        uniswapRouter = _uniswapRouter;
    }

    function setSingUsed(bytes memory _sign, address _presale) external {
        require(isPresale[_presale], "u have no permition");
        usedSignature[keccak256(_sign)] = true;
    }

    function addOrRemoveSigner(address _address, bool _canSign) external onlyDev {
        signers[_address] = _canSign;
    }

    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    function getUsdFee() external view returns(uint256, address) {
        return (usdFee, usd);
    }

    function isValidStablecoin(address _stablecoin) external view returns (bool) {
        return stablecoinWhitelist[_stablecoin];
    }

    function getPresaleAddress(uint256 id) external view returns (address) {
        return presaleAddresses[id].presaleAddress;
    }

    function getVotingTime() external view returns(uint256){
        return votingTime;
    }

    function getRegistrationTime() external view returns(uint256){
        return registrationTime;
    }

    function getMinInvestorBalance() external view returns (uint256) {
        return minInvestorBalance;
    }

    function getDev() external view onlyFactory returns (address) {
        return devAddress;
    }

    function getMinVoterBalance() external view returns (uint256) {
        return minVoterBalance;
    }
    //back!!!
    function getMinYesVotesThreshold(uint256 totalStakedAmount) external pure returns (uint256) {
        uint256 stakedAmount = totalStakedAmount;
        return stakedAmount / 10;
    }

    function getFactoryAddress(uint8 _index) external view factoryIndexCheck(_index) returns (address) {
        return factoryAddress[_index];
    }

    function getMinCreatorStakedBalance() external view returns (uint256) {
        return minCreatorStakedBalance;
    }

    function getUniswapRouter() external view returns (address) {
        return uniswapRouter;
    }

    function calculateFee(uint256 amount) external view onlyPresale returns(uint256){
        return amount * feePercent / 100;
    }

    function getVaultAddress() external view onlyPresale returns(address payable){
        return lessVault;
    }

    function getArrForSearch() external view returns(PresaleInfo[] memory) {
        return presaleAddresses;
    }
    
    function _verifySigner(bytes32 data, bytes memory signature, uint8 _index)
        public
        view
        factoryIndexCheck(_index)
        returns (bool)
    {
        address messageSigner =
            ECDSA.recover(data, signature);
        require(
            isSigner(messageSigner),
            "Unauthorised signer"
        );
        return true;
    }

    function getSignUsed(bytes memory _sign) external view returns(bool) {
        return usedSignature[keccak256(_sign)];
    }

    function isSigner(address _address) internal view returns (bool) {
        return signers[_address];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./PresalePublic.sol";

contract PresaleFactoryPublic {
    LessLibrary public immutable safeLibrary;
    /* ERC20 public lessToken;
    PresalePublic presale; */
    address public owner;

    uint256 private lastTierTime = 1200;

    struct PresaleInfo {
        address tokenAddress;
        uint256 tokenPriceInWei;
        uint256 hardCapInWei;
        uint256 softCapInWei;
        uint256 openVotingTime;
        uint256 openTime;
        uint256 closeTime;
        uint256 _tokenAmount;
        bytes _signature;
        uint256 _timestamp;
        uint8[4] poolPercentages;
        uint256[5] stakingTiers;
    }

    struct PresalePancakeSwapInfo {
        uint256 listingPriceInWei;
        uint256 lpTokensLockDurationInDays;
        uint8 liquidityPercentageAllocation;
        uint256 liquidityAllocationTime;
    }

    struct PresaleStringInfo {
        bytes32 saleTitle;
        bytes32 linkTelegram;
        bytes32 linkGithub;
        bytes32 linkTwitter;
        bytes32 linkWebsite;
        string linkLogo;
        string description;
        string whitepaper;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyDev {
        require(msg.sender == owner || safeLibrary.getDev() == msg.sender);
        _;
    }

    event PublicPresaleCreated(
        uint256 presaleId,
        address creator,
        address presaleAddress,
        address tokenAddress,
        uint256 timeForLiquidity
    );
    event Received(address indexed from, uint256 amount);

    constructor(address _bscsInfoAddress) {
        safeLibrary = LessLibrary(_bscsInfoAddress);
        owner = msg.sender;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function createPresale(
        PresaleInfo calldata _info,
        PresalePancakeSwapInfo calldata _cakeInfo,
        PresaleStringInfo calldata _stringInfo
    ) external payable returns (uint256 presaleId) {
        require(!safeLibrary.getSignUsed(_info._signature), "used sign");
        // signature check
        require(
            safeLibrary._verifySigner(
                keccak256(abi.encodePacked(
                    _info.tokenAddress,
                    msg.sender,
                    _info._tokenAmount,
                    _info._timestamp
                )),
                _info._signature,
                0
            ),
            "invalid signature"
        );
        require(
            safeLibrary.getMinCreatorStakedBalance() <= _info._tokenAmount,
            "not enough staked tokens"
        );
        //timing check
        require(
            _info.openTime > block.timestamp &&
                _info.openVotingTime + safeLibrary.getVotingTime() + safeLibrary.getRegistrationTime() <= 
                _info.openTime &&
                _info.closeTime - _info.openTime > lastTierTime &&
                _info.closeTime < _cakeInfo.liquidityAllocationTime,
            "timing err"
        );
        require(
            _info.tokenPriceInWei > 0 &&
                _info.softCapInWei > 0 &&
                _info.hardCapInWei > 0 &&
                _info.hardCapInWei >= _info.softCapInWei &&
                _cakeInfo.listingPriceInWei > 0 &&
                _cakeInfo.liquidityPercentageAllocation > 0 &&
                _cakeInfo.lpTokensLockDurationInDays >= 30,
            "Wrong params"
        );

        ERC20 _token = ERC20(_info.tokenAddress);

      
        //uint256 feeEth = Calculations.usdtToEthFee(address(safeLibrary)); //PROD
        uint256 feeEth = 500000000;
        require(msg.value >= feeEth && feeEth > 0, "value<=0");

        // maxLiqPoolTokenAmount, maxTokensToBeSold, requiredTokenAmount
        uint256[] memory tokenAmounts = new uint256[](3);
        
        tokenAmounts = Calculations.countAmountOfTokens(
            _info.hardCapInWei,
            _info.tokenPriceInWei,
            _cakeInfo.listingPriceInWei,
            _cakeInfo.liquidityPercentageAllocation,
            _token.decimals()
        );

        PresalePublic presale = new PresalePublic(
            payable(address(this)),
            address(safeLibrary),
            safeLibrary.owner(),
            safeLibrary.getDev()
        );
        require(
            _token.transferFrom(msg.sender, address(presale), tokenAmounts[2]),
            "can't get ur tkns"
        );
        payable(address(presale)).transfer(feeEth);
        initializePresalePublic(
            presale,
            [tokenAmounts[1], tokenAmounts[0], feeEth],
            _info,
            _cakeInfo,
            _stringInfo
        );
        presaleId = safeLibrary.addPresaleAddress(
            address(presale),
            _stringInfo.saleTitle,
            _stringInfo.description,
            false,
            _info.openVotingTime
        );
        presale.setPresaleId(presaleId);
        safeLibrary.setSingUsed(_info._signature, address(presale));
        emit PublicPresaleCreated(
            presaleId,
            msg.sender,
            address(presale),
            _info.tokenAddress,
            _cakeInfo.liquidityAllocationTime
        );
    }

    function initializePresalePublic(
        PresalePublic _presale,
        uint256[3] memory _tokensForSaleLiquidityFee,
        PresaleInfo calldata _info,
        PresalePancakeSwapInfo calldata _cakeInfo,
        PresaleStringInfo calldata _stringInfo
    ) internal {
        _presale.init(
            [msg.sender, _info.tokenAddress],
            [
                _info.tokenPriceInWei,
                _tokensForSaleLiquidityFee[0],
                _tokensForSaleLiquidityFee[1],
                _info.softCapInWei,
                _info.hardCapInWei,
                _info.openVotingTime,
                _info.openTime,
                _info.closeTime,
                _tokensForSaleLiquidityFee[2]
            ]
        );
        _presale.setUniswapInfo(
            _cakeInfo.listingPriceInWei,
            _cakeInfo.lpTokensLockDurationInDays,
            _cakeInfo.liquidityPercentageAllocation,
            _cakeInfo.liquidityAllocationTime
        );
        _presale.setStringInfo(
            _stringInfo.saleTitle,
            _stringInfo.linkTelegram,
            _stringInfo.linkGithub,
            _stringInfo.linkTwitter,
            _stringInfo.linkWebsite,
            _stringInfo.linkLogo,
            _stringInfo.description,
            _stringInfo.whitepaper
        );
        _presale.setArrays(_info.poolPercentages, _info.stakingTiers);
    }

    function migrateTo(address payable _newFactory) external onlyDev {
        _newFactory.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/Calculations.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PresalePublic is ReentrancyGuard {
    uint256 public id;

    address payable public factoryAddress;
    address public platformOwner;
    LessLibrary public lessLib;

    PresaleInfo public generalInfo;
    PresaleUniswapInfo public uniswapInfo;
    PresaleStringInfo public stringInfo;
    IntermediateVariables public intermediate;

    bool private initiate;
    bool private withdrawedFunds;
    address private lpAddress;
    uint256 private lpAmount;
    address private devAddress;
    uint256 private tokenMagnitude;
    address private WETHAddress;

    mapping(address => uint256) public voters;
    mapping(address => bool) public claimed; // if 1, it means investor already claimed the tokens or got a refund
    mapping(address => Investment) public investments; // total wei invested per address

    mapping(address => bool) public whitelistTier;

    address[][5] public whitelist; //for backend

    uint8[4] public poolPercentages;
    uint256[5] public stakingTiers;

    TicketsInfo[] public tickets;

    uint256[4] private tiersTimes = [1200, 900, 600, 300]; // 1h55m-> 1h45m -> 1h30m -> 1h
    uint256 private lpDaySeconds = 30; // one day

    struct TicketsInfo {
        address user;
        uint256 ticketAmount;
    }

    struct PresaleInfo {
        address creator;
        address token;
        uint256 tokenPriceInWei;
        uint256 hardCapInWei;
        uint256 softCapInWei;
        uint256 tokensForSaleLeft;
        uint256 tokensForLiquidityLeft;
        uint256 openTimeVoting;
        uint256 closeTimeVoting;
        uint256 openTimePresale;
        uint256 closeTimePresale;
        uint256 collectedFee;
    }

    struct IntermediateVariables {
        bool cancelled;
        bool liquidityAdded;
        uint256 beginingAmount;
        uint256 raisedAmount;
        uint256 raisedAmountBeforeLiquidity;
        uint256 participants;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 lastTotalStakedAmount;
    }

    struct PresaleUniswapInfo {
        uint256 listingPriceInWei;
        uint256 lpTokensLockDurationInDays;
        uint8 liquidityPercentageAllocation;
        uint256 liquidityAllocationTime;
        uint256 unlockTime;
    }

    struct PresaleStringInfo {
        bytes32 saleTitle;
        bytes32 linkTelegram;
        bytes32 linkGithub;
        bytes32 linkTwitter;
        bytes32 linkWebsite;
        string linkLogo;
        string description;
        string whitepaper;
    }

    struct Investment {
        uint256 amountEth;
        uint256 amountTokens;
    }

    modifier onlyFabric() {
        require(factoryAddress == msg.sender);
        _;
    }

    modifier onlyPlatformOwner() {
        require(platformOwner == msg.sender);
        _;
    }

    modifier onlyPresaleCreator() {
        require(msg.sender == generalInfo.creator);
        _;
    }

    modifier onlyOwners() {
        require(
            msg.sender == generalInfo.creator || msg.sender == platformOwner,
            "Only owner"
        );
        _;
    }

    modifier notCreator() {
        require(msg.sender != generalInfo.creator, "No permition");
        _;
    }

    modifier liquidityAdded() {
        require(intermediate.liquidityAdded, "Add liquidity");
        _;
    }

    modifier onlyWhenOpenVoting() {
        require(
            block.timestamp >= generalInfo.openTimeVoting &&
                block.timestamp <= generalInfo.closeTimeVoting,
            "Voting closed"
        );
        _;
    }

    modifier onlyWhenOpenPresale() {
        uint256 nowTime = block.timestamp;
        require(
            nowTime >= generalInfo.openTimePresale &&
                nowTime <= generalInfo.closeTimePresale,
            "No presales"
        );
        _;
    }

    modifier presaleIsNotCancelled() {
        require(!intermediate.cancelled);
        _;
    }

    modifier votesPassed(uint256 totalStakedAmount) {
        require(
            intermediate.yesVotes >= intermediate.noVotes,
            "Not enough yes votes"
        );
        require(
            intermediate.yesVotes >=
                lessLib.getMinYesVotesThreshold(totalStakedAmount),
            "Votes less min.treshold"
        );
        require(
            block.timestamp >= generalInfo.closeTimeVoting,
            "Voting is open"
        );
        _;
    }

    modifier openRegister() {
        require(
            block.timestamp >=
                generalInfo.openTimePresale - lessLib.getRegistrationTime() &&
                block.timestamp < generalInfo.openTimePresale,
            "Not registration time"
        );
        _;
    }

    receive() external payable {}

    constructor(
        address payable _factory,
        address _library,
        address _platformOwner,
        address _devAddress
    ) {
        require(
            _factory != address(0) &&
                _library != address(0) &&
                _platformOwner != address(0) &&
                _devAddress != address(0)
        );
        lessLib = LessLibrary(_library);
        factoryAddress = _factory;
        platformOwner = _platformOwner;
        devAddress = _devAddress;
        //generalInfo.closeTimeVoting = block.timestamp + lessLib.getVotingTime();
    }

    function init(
        address[2] memory _creatorToken,
        uint256[9] memory _priceTokensForSaleLiquiditySoftHardOpenCloseFee
    ) external onlyFabric {
        require(
            _creatorToken[0] != address(0) && _creatorToken[1] != address(0),
            "0 addr"
        );
        require(!initiate, "already inited");

        require(
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[5] >=
                block.timestamp,
            "not voting"
        );

        generalInfo = PresaleInfo(
            _creatorToken[0],
            _creatorToken[1],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[0],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[4],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[3],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[1],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[2],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[5],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[5] +
                lessLib.getVotingTime(),
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[6],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[7],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[8]
        );

        uint256 tokenDecimals = ERC20(_creatorToken[1]).decimals();
        tokenMagnitude = uint256(10)**uint256(tokenDecimals);
        intermediate
            .beginingAmount = _priceTokensForSaleLiquiditySoftHardOpenCloseFee[
            1
        ];
        initiate = true;
    }

    function setUniswapInfo(
        uint256 price,
        uint256 duration,
        uint8 percent,
        uint256 allocationTime
    ) external onlyFabric {
        uniswapInfo = PresaleUniswapInfo(
            price,
            duration,
            percent,
            allocationTime,
            0
        );
    }

    function setStringInfo(
        bytes32 _saleTitle,
        bytes32 _linkTelegram,
        bytes32 _linkGithub,
        bytes32 _linkTwitter,
        bytes32 _linkWebsite,
        string calldata _linkLogo,
        string calldata _description,
        string calldata _whitepaper
    ) external onlyFabric {
        stringInfo = PresaleStringInfo(
            _saleTitle,
            _linkTelegram,
            _linkGithub,
            _linkTwitter,
            _linkWebsite,
            _linkLogo,
            _description,
            _whitepaper
        );
    }

    function setArrays(
        uint8[4] memory _poolPercentages,
        uint256[5] memory _stakingTiers
    ) external onlyFabric {
        poolPercentages = _poolPercentages;
        stakingTiers = _stakingTiers;
    }

    function getWhitelist(uint256 _tier)
        external
        view
        returns (address[] memory)
    {
        return whitelist[5 - _tier];
    }

    function isWhitelisting() external view returns (bool) {
        return
            block.timestamp <= generalInfo.openTimePresale &&
            block.timestamp >=
            generalInfo.openTimePresale - lessLib.getRegistrationTime();
    }

    function register(
        uint256 _tokenAmount,
        uint256 _tier,
        uint256 _timestamp,
        bytes memory _signature
    )
        external
        openRegister
        notCreator
        votesPassed(intermediate.lastTotalStakedAmount)
    {
        require(_tier > 0 && _tier < 6, "wr tier");
        require(!lessLib.getSignUsed(_signature), "used sign");
        bytes memory encoded = abi.encodePacked(
            _tokenAmount,
            msg.sender,
            address(this),
            _timestamp
        );
        require(
            lessLib._verifySigner(keccak256(encoded), _signature, 0),
            "w sign"
        );

        require(!whitelistTier[msg.sender], "al. whitelisted");
        if (_tier < 3)
            tickets.push(
                TicketsInfo(msg.sender, _tokenAmount / (500 * tokenMagnitude))
            );
        whitelistTier[msg.sender] = true;
        whitelist[5 - _tier].push(msg.sender);
        lessLib.setSingUsed(_signature, address(this));
    }

    function vote(
        bool _yes,
        uint256 _stakingAmount,
        uint256 _timestamp,
        bytes memory _signature,
        uint256 _totalStakedAmount
    ) external onlyWhenOpenVoting presaleIsNotCancelled notCreator {
        require(!lessLib.getSignUsed(_signature), "used sign");
        require(
            lessLib._verifySigner(
                keccak256(
                    abi.encodePacked(
                        _stakingAmount,
                        msg.sender,
                        address(this),
                        _timestamp
                    )
                ),
                _signature,
                0
            )
        );

        require(_stakingAmount >= lessLib.getMinVoterBalance(), "scant bal");
        require(voters[msg.sender] == 0, "a.voted");

        voters[msg.sender] = _stakingAmount;
        if (_yes) {
            intermediate.yesVotes = intermediate.yesVotes + _stakingAmount;
        } else {
            intermediate.noVotes = intermediate.noVotes + _stakingAmount;
        }
        intermediate.lastTotalStakedAmount = _totalStakedAmount;
        lessLib.setSingUsed(_signature, address(this));
    }

    // _tokenAmount only for non bnb tokens
    // poolPercentages starts from 5th to 2nd teirs
    // Staking tiers also starts from 5th to 2nd tiers
    function invest(
        bytes memory _signature,
        uint256 _stakedAmount,
        uint256 _timestamp
    )
        public
        payable
        presaleIsNotCancelled
        onlyWhenOpenPresale
        votesPassed(intermediate.lastTotalStakedAmount)
        nonReentrant
        notCreator
    {
        require(whitelistTier[msg.sender], "not whitelisted");

        require(!lessLib.getSignUsed(_signature), "used sign");
        bytes memory encoded = abi.encodePacked(
            _stakedAmount,
            msg.sender,
            address(this),
            _timestamp
        );
        require(
            lessLib._verifySigner(keccak256(encoded), _signature, 0),
            "wrong sign"
        );

        uint256 tokensLeft;
        uint256 tokensSold = intermediate.beginingAmount -
            generalInfo.tokensForSaleLeft;
        uint256 nowTime = block.timestamp;

        uint256[5] memory poolAmounts;
        uint256 prevPoolsTotalAmount;
        for (uint256 i = 0; i < 4; i++) {
            poolAmounts[i] =
                (intermediate.beginingAmount * poolPercentages[i]) /
                100;
        }

        if (nowTime < generalInfo.openTimePresale + tiersTimes[3]) {
            require(_stakedAmount >= stakingTiers[0], "TIER 5");
            tokensLeft = poolAmounts[0] - tokensSold;
        } else if (nowTime < generalInfo.openTimePresale + tiersTimes[2]) {
            require(_stakedAmount >= stakingTiers[1], "TIER 4");
            prevPoolsTotalAmount = poolAmounts[0];
            tokensLeft = poolAmounts[1] + prevPoolsTotalAmount - tokensSold;
        } else if (nowTime < generalInfo.openTimePresale + tiersTimes[1]) {
            require(_stakedAmount >= stakingTiers[2], "TIER 3");
            prevPoolsTotalAmount = poolAmounts[0] + poolAmounts[1];
            tokensLeft = poolAmounts[2] + prevPoolsTotalAmount - tokensSold;
        } else if (nowTime < generalInfo.openTimePresale + tiersTimes[0]) {
            require(_stakedAmount >= stakingTiers[3], "TIER 2");
            prevPoolsTotalAmount =
                poolAmounts[0] +
                poolAmounts[1] +
                poolAmounts[2];
            tokensLeft = poolAmounts[3] + prevPoolsTotalAmount - tokensSold;
        } else {
            require(_stakedAmount >= stakingTiers[4], "TIER 1");
            tokensLeft = generalInfo.tokensForSaleLeft;
        }
        uint256 reservedTokens = getTokenAmount(msg.value);
        require(intermediate.raisedAmount < generalInfo.hardCapInWei, "H cap");
        require(tokensLeft >= reservedTokens, "Not enough tokens in pool");
        require(msg.value > 0, "<0");
        uint256 totalInvestmentInWei = investments[msg.sender].amountEth +
            msg.value;

        if (investments[msg.sender].amountEth == 0) {
            intermediate.participants += 1;
        }

        intermediate.raisedAmount += msg.value;
        investments[msg.sender].amountEth = totalInvestmentInWei;
        investments[msg.sender].amountTokens += reservedTokens;
        generalInfo.tokensForSaleLeft -= reservedTokens;
        lessLib.setSingUsed(_signature, address(this));
    }

    function withdrawInvestment(address payable to, uint256 amount)
        external
        nonReentrant
    {
        require(block.timestamp >= generalInfo.openTimePresale, "early");
        //require(investments[msg.sender].amountEth != 0, "n investor");
        require(investments[msg.sender].amountEth >= amount, "not enough amt");
        require(amount > 0, "0 amt");
        if (!intermediate.cancelled) {
            require(
                !intermediate.liquidityAdded &&
                    intermediate.raisedAmount < generalInfo.softCapInWei,
                "afterCap withdraw"
            );
        }
        require(to != address(0), "0 addr");
        if (investments[msg.sender].amountEth - amount == 0) {
            intermediate.participants -= 1;
        }
        to.transfer(amount);
        uint256 reservedTokens = getTokenAmount(amount);
        intermediate.raisedAmount -= amount;
        investments[msg.sender].amountEth -= amount;
        investments[msg.sender].amountTokens -= reservedTokens;
        generalInfo.tokensForSaleLeft += reservedTokens;
    }

    function claimTokens() external nonReentrant liquidityAdded {
        require(
            block.timestamp >= generalInfo.closeTimePresale &&
                !claimed[msg.sender] &&
                investments[msg.sender].amountEth > 0,
            "Cant claim tkns"
        );
        claimed[msg.sender] = true; // make sure this goes first before transfer to prevent reentrancy
        IERC20(generalInfo.token).transfer(
            msg.sender,
            investments[msg.sender].amountTokens
        );
    }

    function addLiquidity() external presaleIsNotCancelled nonReentrant {
        require(msg.sender == devAddress, "only dev");
        require(
            uniswapInfo.liquidityAllocationTime <= block.timestamp,
            "early"
        );

        require(block.timestamp >= generalInfo.closeTimePresale, "n closed");
        require(!intermediate.liquidityAdded, "already added");
        require(
            intermediate.raisedAmount >= generalInfo.softCapInWei,
            "sCap n riched"
        );
        uint256 raisedAmount = intermediate.raisedAmount;
        if (raisedAmount == 0) {
            intermediate.liquidityAdded = true;
            return;
        }

        uint256 liqPoolEthAmount = (raisedAmount *
            uniswapInfo.liquidityPercentageAllocation) / 100;
        uint256 liqPoolTokenAmount = (liqPoolEthAmount * tokenMagnitude) /
            uniswapInfo.listingPriceInWei;

        require(
            generalInfo.tokensForLiquidityLeft >= liqPoolTokenAmount,
            "no liquidity"
        );

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(
            address(lessLib.getUniswapRouter())
        );

        IERC20 token = IERC20(generalInfo.token);

        token.approve(address(uniswapRouter), liqPoolTokenAmount);

        uint256 amountEth;

        (, amountEth, lpAmount) = uniswapRouter.addLiquidityETH{
            value: liqPoolEthAmount
        }(
            address(token),
            liqPoolTokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 15 minutes
        );

        intermediate.raisedAmountBeforeLiquidity = intermediate.raisedAmount;
        intermediate.raisedAmount -= amountEth;

        //require(lpAmount != 0, "lpAmount not null");

        IUniswapV2Factory02 uniswapFactory = IUniswapV2Factory02(
            uniswapRouter.factory()
        );
        lpAddress = uniswapFactory.getPair(
            uniswapRouter.WETH(),
            address(token)
        );

        generalInfo.tokensForLiquidityLeft -= liqPoolTokenAmount;
        intermediate.liquidityAdded = true;
        uniswapInfo.unlockTime =
            block.timestamp +
            (uniswapInfo.lpTokensLockDurationInDays * lpDaySeconds);
    }

    function collectFundsRaised()
        external
        presaleIsNotCancelled
        nonReentrant
        onlyPresaleCreator
        liquidityAdded
    {
        require(
            intermediate.raisedAmountBeforeLiquidity >=
                generalInfo.softCapInWei,
            "sCap n riched"
        );
        require(!withdrawedFunds, "only once");
        withdrawedFunds = true;

        uint256 fee = lessLib.calculateFee(
            intermediate.raisedAmountBeforeLiquidity
        );
        lessLib.getVaultAddress().transfer(fee);
        payable(generalInfo.creator).transfer(intermediate.raisedAmount - fee);

        uint256 unsoldTokensAmount = generalInfo.tokensForSaleLeft +
            generalInfo.tokensForLiquidityLeft;
        if (unsoldTokensAmount > 0) {
            require(
                IERC20(generalInfo.token).transfer(
                    generalInfo.creator,
                    unsoldTokensAmount
                ),
                "can't send tokens"
            );
        }
    }

    function refundLpTokens()
        external
        presaleIsNotCancelled
        nonReentrant
        onlyPresaleCreator
        liquidityAdded
    {
        require(lpAmount != 0 && block.timestamp >= uniswapInfo.unlockTime);
        require(
            IERC20(lpAddress).transfer(generalInfo.creator, lpAmount),
            "transf.fail"
        );
        lpAmount = 0;
    }

    function collectFee() external nonReentrant {
        require(generalInfo.collectedFee > 0, "already withdrawn");
        require(
            block.timestamp >= generalInfo.closeTimeVoting,
            "only after voting"
        );
        uint256 collectedFee = generalInfo.collectedFee;
        generalInfo.collectedFee = 0;
        if (
            intermediate.yesVotes >= intermediate.noVotes &&
            intermediate.yesVotes > 0 &&
            intermediate.yesVotes >=
            lessLib.getMinYesVotesThreshold(
                intermediate.lastTotalStakedAmount
            ) &&
            !intermediate.cancelled
        ) {
            payable(platformOwner).transfer(collectedFee);
        } else {
            intermediate.cancelled = true;
            payable(generalInfo.creator).transfer(collectedFee);
            uint256 bal = IERC20(generalInfo.token).balanceOf(address(this));
            if (bal > 0) {
                require(
                    IERC20(generalInfo.token).transfer(
                        generalInfo.creator,
                        bal
                    ),
                    "con't get ur tkns"
                );
            }
        }
    }

    function changeCloseTimeVoting(uint256 _newCloseTime)
        external
        presaleIsNotCancelled
        onlyOwners
    {
        //uint256 openTimePresale = generalInfo.openTimePresale;
        require(
            block.timestamp < _newCloseTime &&
                _newCloseTime + 86400 <= generalInfo.openTimePresale
        );
        generalInfo.closeTimeVoting = _newCloseTime;
    }

    function changePresaleTime(uint256 _newOpenTime, uint256 _newCloseTime)
        external
        presaleIsNotCancelled
        onlyOwners
    {
        require(block.timestamp < generalInfo.openTimePresale, "started");
        require(
            generalInfo.closeTimeVoting + lessLib.getRegistrationTime() <
                _newOpenTime &&
                _newCloseTime - _newOpenTime > tiersTimes[0] && // 6900 &&
                _newCloseTime < uniswapInfo.liquidityAllocationTime
        );
        generalInfo.openTimePresale = _newOpenTime;
        generalInfo.closeTimePresale = _newCloseTime;
    }

    function cancelPresale() external presaleIsNotCancelled {
        if (
            intermediate.raisedAmountBeforeLiquidity <
            generalInfo.softCapInWei &&
            block.timestamp >= generalInfo.closeTimePresale
        ) {
            require(msg.sender == generalInfo.creator, "only pres creator");
        } else {
            require(msg.sender == platformOwner, "only platf own");
        }
        uint256 bal = IERC20(generalInfo.token).balanceOf(address(this));
        if (bal > 0) {
            require(
                IERC20(generalInfo.token).transfer(generalInfo.creator, bal),
                "con't get ur tkns"
            );
        }
        intermediate.cancelled = true;
    }

    function getPresaleId() external view returns (uint256) {
        return id;
    }

    function setPresaleId(uint256 _id) external onlyFabric {
        if (id != 0) {
            require(id != _id);
        }
        id = _id;
    }

    function getMyVote() external view returns (uint256) {
        return voters[msg.sender];
    }

    function getGenInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            generalInfo.tokensForSaleLeft,
            generalInfo.tokensForLiquidityLeft,
            generalInfo.collectedFee
        );
    }

    function getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        return (_weiAmount * tokenMagnitude) / generalInfo.tokenPriceInWei;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory02 {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LessLibrary.sol";

library Calculations {
    function swapNativeToEth(
        address presale,
        address _library,
        address nativeToken,
        uint256 liqPoolEthAmount
    ) external returns (uint256) {
        LessLibrary safeLibrary = LessLibrary(_library);
        IUniswapV2Router02 uniswap = IUniswapV2Router02(
            safeLibrary.getUniswapRouter()
        );
        address[] memory path = new address[](2);
        path[0] = nativeToken;
        path[1] = uniswap.WETH();
        uint256[] memory amount = uniswap.getAmountsOut(liqPoolEthAmount, path);
        amount = uniswap.swapTokensForExactETH(
            amount[1],
            liqPoolEthAmount,
            path,
            presale,
            block.timestamp + 15 minutes
        );
        return amount[1];
    }

    function usdtToEthFee(address _library)
        external
        view
        returns (uint256 feeEth)
    {
        LessLibrary safeLibrary = LessLibrary(_library);
        IUniswapV2Router02 uniswap = IUniswapV2Router02(
            safeLibrary.getUniswapRouter()
        );
        (uint256 feeFromLib, address tether) = safeLibrary.getUsdFee();
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = tether;

        uint256[] memory amounts = uniswap.getAmountsIn(feeFromLib, path);
        return amounts[0];
    }

    function countAmountOfTokens(
        uint256 _hardCap,
        uint256 _tokenPrice,
        uint256 _liqPrice,
        uint256 _liqPerc,
        uint8 _decimals
    ) external pure returns (uint256[] memory) {
        uint256[] memory tokenAmounts = new uint256[](3);
        if (_liqPrice != 0 && _liqPerc != 0) {
            tokenAmounts[0] = ((_hardCap *
                _liqPerc *
                (uint256(10)**uint256(_decimals))) / (_liqPrice * 100));
            require(tokenAmounts[0] > 0, "Wrokng");
        }

        tokenAmounts[1] =
            (_hardCap  * (uint256(10)**uint256(_decimals))) / _tokenPrice;
        tokenAmounts[2] = tokenAmounts[0] + tokenAmounts[1];
        require(tokenAmounts[1] > 0, "Wrong parameters");
        return tokenAmounts;
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

// SPDX-License-Identifier: MIT

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

// SPDX-License-Identifier: MIT

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

