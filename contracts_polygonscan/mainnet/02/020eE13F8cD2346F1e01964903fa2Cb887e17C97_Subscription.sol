//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./DarkMatter.sol";
import "./GenerationManager.sol";
import "./StableCoinAcceptor.sol";
import "./Exchange.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IStackOsNFTBasic.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Subscription is Ownable, ReentrancyGuard {
    IERC20 internal stackToken;
    GenerationManager internal generations;
    DarkMatter internal darkMatter;
    StableCoinAcceptor internal stableAcceptor;
    Exchange internal exchange;
    address internal taxAddress;

    uint256 internal constant HUNDRED_PERCENT = 10000;
    uint256 public constant MONTH = 28 days;

    uint256 public dripPeriod = 700 days;
    uint256 public forgivenessPeriod = 7 days;
    uint256 public price = 1e18;
    uint256 public maxPrice = 5000e18;
    uint256 public bonusPercent = 2000;
    uint256 public taxReductionAmount = 2500;
    uint256 public period;
    bool public isOnlyFirstGeneration;

    enum withdrawStatus {
        withdraw,
        purchase
    }

    struct Period {
        uint256 balance;
        uint256 subsNum;
        uint256 endAt;
        mapping(uint256 => mapping(uint256 => PeriodTokenData)) pd; 
    }

    struct PeriodTokenData {
        bool isSub;
        uint256 withdrawn;
    }

    struct Bonus {
        uint256 total;
        uint256 lastTxDate;
        uint256 releasePeriod;
        uint256 lockedAmount;
    }

    struct Deposit {
        uint256 balance; // amount without bonus
        Bonus[] reward; // bonuses
        uint256 tax; // tax percent on withdraw
        uint256 nextPayDate; // you can subscribe after this date, but before deadline to reduce tax
    }

    mapping(uint256 => Period) public p;
    mapping(uint256 => mapping(uint256 => Deposit)) public deposits; // generationId => tokenId => Deposit
    mapping(uint256 => mapping(uint256 => uint256)) public overflow; // generationId => tokenId => withdraw amount

    modifier restrictGeneration(uint256 generationId) {
        requireCorrectGeneration(generationId);
        _;
    }

    constructor(
        IERC20 _stackToken,
        GenerationManager _generations,
        DarkMatter _darkMatter,
        StableCoinAcceptor _stableAcceptor,
        Exchange _exchange,
        address _taxAddress,
        uint256 _forgivenessPeriod,
        uint256 _price,
        uint256 _bonusPercent,
        uint256 _taxReductionAmount
    ) {
        stackToken = _stackToken;
        generations = _generations;
        darkMatter = _darkMatter;
        stableAcceptor = _stableAcceptor;
        exchange = _exchange;
        taxAddress = _taxAddress;
        forgivenessPeriod = _forgivenessPeriod;
        price = _price;
        bonusPercent = _bonusPercent;
        taxReductionAmount = _taxReductionAmount;
    }    
    
    /*
     * @title If set, then only 1st generation allowed to use contract, otherwise only generations above 1st can.
     * @dev Could only be invoked by the contract owner.
     */
    function setOnlyFirstGeneration() external onlyOwner {
        isOnlyFirstGeneration = true;
    }

    /*
     * @title Set drip perdiod
     * @param Amount of seconds required to release bonus
     * @dev Could only be invoked by the contract owner.
     */
    function setDripPeriod(uint256 _seconds) external onlyOwner {
        require(_seconds > 0, "Cant be zero");
        dripPeriod = _seconds;
    }

    /*
     * @title Set subscription price
     * @param New price in USD
     * @dev Could only be invoked by the contract owner.
     */
    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Cant be zero");
        price = _price;
    }

    /*
     * @title Set max subscription price, usde only if contract locked to 1st generation
     * @param New price in USD
     * @dev Could only be invoked by the contract owner.
     */
    function setMaxPrice(uint256 _maxPrice) external onlyOwner {
        require(_maxPrice > 0, "Cant be zero");
        maxPrice = _maxPrice;
    }

    /*
     * @title Set bonus added for each subscription on top of it's price
     * @param Bonus percent
     * @dev Could only be invoked by the contract owner.
     */
    function setBonusPercent(uint256 _percent) external onlyOwner {
        require(_percent <= HUNDRED_PERCENT, "invalid basis points");
        bonusPercent = _percent;
    }

    /*
     * @title Set tax reduction amount
     * @param Amount to subtract from tax on each subscribed month in a row
     * @dev Could only be invoked by the contract owner
     */
    function setTaxReductionAmount(uint256 _amount) external onlyOwner {
        require(_amount <= HUNDRED_PERCENT, "invalid basis points");
        taxReductionAmount = _amount;
    }

    /*
     * @title Set time frame that you have to resubscribe to keep TAX reducing
     * @param Amount of seconds
     * @dev Could only be invoked by the contract owner
     */
    function setForgivenessPeriod(uint256 _seconds) external onlyOwner {
        require(_seconds > 0, "Cant be zero");
        forgivenessPeriod = _seconds;
    }  
    
    /*
     * @title Reverts if passed generationId doesn't match desired generation by the contract.
     * @title This is used in modifier.
     * @dev Could only be invoked by the contract owner.
     */
    function requireCorrectGeneration(uint256 generationId) internal view {
        if(isOnlyFirstGeneration)
            require(generationId == 0, "Generaion should be 0");
        else
            require(generationId > 0, "Generaion shouldn't be 0");
    }

    /*
     *  @title Pay subscription
     *  @param Generation id
     *  @param Token id
     *  @param Amount user wish to pay, used only in 1st generation
     *  @param Address of supported stablecoin
     *  @param Whether to pay with STACK token
     *  @dev Caller must approve us to spend `price` amount of `_stablecoin` or stack token.
     */
    function subscribe(
        uint256 generationId,
        uint256 tokenId,
        uint256 _payAmount,
        IERC20 _stablecoin,
        bool _payWithStack
    ) 
        public 
        nonReentrant 
        restrictGeneration(generationId)
    {
        if(!_payWithStack)
            require(
                stableAcceptor.supportsCoin(_stablecoin), 
                "Unsupported stablecoin"
            );

        uint256 _price = price;
        if(isOnlyFirstGeneration) {
            _price = _payAmount;
            require(
                _payAmount >= price && _payAmount <= maxPrice, 
                "Wrong pay amount"
            );
        }

        _subscribe(generationId, tokenId, _price, _stablecoin, _payWithStack);

        // active sub reward logic
        updatePeriod();
        p[period].subsNum += 1;
        p[period].pd[generationId][tokenId].isSub = true;
    }

    function _subscribe(
        uint256 generationId,
        uint256 tokenId,
        uint256 _price,
        IERC20 _stablecoin,
        bool _payWithStack
    ) internal {
        require(generationId < generations.count(), "Generation doesn't exist");
        require(
            generations.get(generationId).exists(tokenId), 
            "Token doesn't exists"
        );

        Deposit storage deposit = deposits[generationId][tokenId];
        require(deposit.nextPayDate < block.timestamp, "Cant pay in advance");

        if (deposit.nextPayDate == 0) {
            deposit.nextPayDate = block.timestamp;
            deposit.tax = HUNDRED_PERCENT;
        }

        // Paid after deadline?
        if (deposit.nextPayDate + forgivenessPeriod < block.timestamp) {
            deposit.nextPayDate = block.timestamp;
            deposit.tax = HUNDRED_PERCENT;
        }

        deposit.tax = subOrZero(deposit.tax, taxReductionAmount);
        deposit.nextPayDate += MONTH;

        // convert stablecoin to stack token
        uint256 amount;
        if(_payWithStack) {
            _stablecoin = stableAcceptor.stablecoins(0);
            // get stack amount we need to sell to get `price` amount of usd
            amount = exchange.getAmountIn(
                _price, 
                _stablecoin, 
                stackToken
            );
            stackToken.transferFrom(msg.sender, address(this), amount);
        } else {
            _stablecoin.transferFrom(msg.sender, address(this), _price);
            _stablecoin.approve(address(exchange), _price);
            amount = exchange.swapExactTokensForTokens(
                _price, 
                _stablecoin,
                stackToken
            );
        }

        deposit.balance += amount;

        // bonuses logic
        updateBonuses(generationId, tokenId);
        uint256 bonusAmount = amount * bonusPercent / HUNDRED_PERCENT;
        deposit.reward.push(Bonus({
            total: bonusAmount, 
            lastTxDate: block.timestamp, 
            releasePeriod: dripPeriod, 
            lockedAmount: bonusAmount
        }));
    }

    /*
     *  @title End period if its time
     *  @dev Called automatically from other functions, but can be called manually
     */
    function updatePeriod() public {
        if (p[period].endAt < block.timestamp) {
            period += 1;
            p[period].endAt = block.timestamp + MONTH;
        }
    }    

    /*
     *  @title Handle fee sent from minting
     *  @return Whether fee received or not
     *  @dev Called automatically from stack NFT contract, but can be called manually
     *  @dev Will receive tokens if previous period has active subs
     */
    function onReceiveStack(uint256 _amount) 
        external 
        returns 
        (bool _isTransfered) 
    {

        updatePeriod();

        if(p[period - 1].subsNum == 0) {
            return false;
        } else {
            p[period - 1].balance += _amount;
            stackToken.transferFrom(msg.sender, address(this), _amount);
        }
        return true;
    }

    /*
     *  @title Withdraw active subs reward
     *  @param Generation id
     *  @param Token ids
     *  @param Period ids
     *  @dev Caller must own tokens
     *  @dev Periods must be ended and tokens should have subscription during periods
     */
    function withdraw2(
        uint256 generationId, 
        uint256[] calldata tokenIds,
        uint256[] calldata periods
    )
        external
        restrictGeneration(generationId)
    {
        updatePeriod();

        uint256 toWithdraw;
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                darkMatter.isOwnStackOrDarkMatter(
                    msg.sender,
                    generationId,
                    tokenId
                ),
                "Not owner"
            );
            for (uint256 o; o < periods.length; o++) {
                require(periods[o] < period, "Period not ended");
                Period storage pr = p[periods[o]];
                require(pr.subsNum > 0, "No subs in period");
                require(
                    pr.pd[generationId][tokenId].isSub, 
                    "Was not subscribed"
                );
                        
                uint256 share = pr.balance / pr.subsNum;
                toWithdraw += (share - pr.pd[generationId][tokenId].withdrawn);
                pr.pd[generationId][tokenId].withdrawn = share; 
            }
        }
        stackToken.transfer(msg.sender, toWithdraw);
    }
    /*
     *  @dev Calculate dripped amount and remove fully released bonuses from array.
     */
    function updateBonuses(
        uint256 generationId,
        uint256 tokenId
    ) private {
        Deposit storage deposit = deposits[generationId][tokenId];
        uint256 index;
        for (uint256 i; i < deposit.reward.length; i++) {
            Bonus storage bonus = deposit.reward[i];

            uint256 withdrawAmount = 
                (bonus.total / bonus.releasePeriod) * 
                (block.timestamp - bonus.lastTxDate);

            if (withdrawAmount > bonus.lockedAmount)
                withdrawAmount = bonus.lockedAmount;
            
            overflow[generationId][tokenId] += withdrawAmount;
            bonus.lockedAmount -= withdrawAmount;
            bonus.lastTxDate = block.timestamp;

            // We assume that bonuses drained one by one starting from the first one.
            // Then if our array looks like this [--++] where - is drained bonuses,
            // we shift all + down to replace all -, then our array is [++--]
            // Then we can pop all - as we only able to remove elements from the end of array.
            if(bonus.lockedAmount == 0) 
                index = i+1;
            else if(index > 0) {
                uint256 currentIndex = i - index;

                deposit.reward[currentIndex] = 
                    deposit.reward[i];
                delete deposit.reward[i];
            }
        }

        for (uint256 i = deposit.reward.length; i > 0; i--) {
            if(deposit.reward[i - 1].lockedAmount > 0) break;
            deposit.reward.pop();
        }
    }

    /*
     *  @title Withdraw deposit taking into account bonus and tax
     *  @param Generation id
     *  @param Token ids
     *  @dev Caller must own `tokenIds`
     *  @dev Tax resets to maximum on withdraw
     */
    function withdraw(uint256 generationId, uint256[] calldata tokenIds)
        external
        nonReentrant
        restrictGeneration(generationId)
    {
        updatePeriod();
        for (uint256 i; i < tokenIds.length; i++) {
            _withdraw(
                generationId,
                tokenIds[i],
                withdrawStatus.withdraw,
                0,
                0,
                IERC20(address(0))
            );
        }
    }

   /*
     * @title Purchase StackNFTs
     * @param Generation id to withdraw
     * @param Token ids to withdraw
     * @param Generation id to mint
     * @param Amount to mint
     * @param Supported stablecoin to use to buy stack token
     * @dev Withdraw tokens must be owned by the caller
     * @dev Generation should be greater than 0
     */
    function purchaseNewNft(
        uint256 withdrawGenerationId,
        uint256[] calldata withdrawTokenIds,
        uint256 purchaseGenerationId,
        uint256 amountToMint,
        IERC20 _stablecoin
    ) 
        external 
        nonReentrant 
        restrictGeneration(withdrawGenerationId)
    {
        require(stableAcceptor.supportsCoin(_stablecoin), "Unsupported stablecoin");
        require(purchaseGenerationId > 0, "Cant purchase generation 0");
        updatePeriod();

        for (uint256 i; i < withdrawTokenIds.length; i++) {
            _withdraw(
                withdrawGenerationId,
                withdrawTokenIds[i],
                withdrawStatus.purchase,
                purchaseGenerationId,
                amountToMint,
                _stablecoin
            );
        }
    }

    function _withdraw(
        uint256 generationId,
        uint256 tokenId,
        withdrawStatus allocationStatus,
        uint256 purchaseGenerationId,
        uint256 amountToMint,
        IERC20 _stablecoin
    ) internal {
        require(generationId < generations.count(), "Generation doesn't exist");
        require(
            darkMatter.isOwnStackOrDarkMatter(
                msg.sender,
                generationId,
                tokenId
            ),
            "Not owner"
        );
        Deposit storage deposit = deposits[generationId][tokenId];

        // if not subscribed
        if (deposit.nextPayDate < block.timestamp) {
            deposit.nextPayDate = 0;
            deposit.tax = HUNDRED_PERCENT - taxReductionAmount;
        }

        uint256 amountWithdraw = deposit.balance;
        updateBonuses(generationId, tokenId);
        uint256 bonusAmount = overflow[generationId][tokenId];
        overflow[generationId][tokenId] = 0;

        require(
            amountWithdraw + bonusAmount <= stackToken.balanceOf(address(this)),
            "Not enough balance on bonus wallet"
        );

        deposit.balance = 0;

        // early withdraw tax
        if (deposit.tax > 0) {
            uint256 tax = (amountWithdraw * deposit.tax) / HUNDRED_PERCENT;
            amountWithdraw -= tax;
            stackToken.transfer(taxAddress, tax);
        }

        amountWithdraw += bonusAmount;
        require(amountWithdraw > 0, "Already withdrawn");

        if (allocationStatus == withdrawStatus.purchase) {

            uint256 amountToConvert = IStackOsNFTBasic(
                address(generations.get(purchaseGenerationId))
            ).getFromRewardsPrice(amountToMint, address(_stablecoin));

            require(amountWithdraw > amountToConvert, "Not enough earnings");

            stackToken.approve(
                address(generations.get(purchaseGenerationId)), 
                amountToConvert
            );

            IStackOsNFTBasic(
                address(generations.get(purchaseGenerationId))
            ).mintFromSubscriptionRewards(
                amountToMint, 
                amountToConvert, 
                msg.sender
            );

            // Add rest back to pending rewards
            amountWithdraw -= amountToConvert;
            overflow[generationId][tokenId] = amountWithdraw;
        } else {
            stackToken.transfer(msg.sender, amountWithdraw);
            deposit.tax = HUNDRED_PERCENT;
        }
    }

   /*
     * @title Get pending reward amount
     * @param StackNFT generation id
     * @param Token id
     * @dev Doesn't account deposit amount, only bonuses
     */
    function pendingReward(uint256 _generationId, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        Deposit memory deposit = deposits[_generationId][_tokenId];

        uint256 totalPending;

        for (uint256 i; i < deposit.reward.length; i++) {
            Bonus memory bonus = deposit.reward[i];

            uint256 amount = 
                (bonus.total / bonus.releasePeriod) * 
                (block.timestamp - bonus.lastTxDate);

            if (amount > bonus.lockedAmount)
                amount = bonus.lockedAmount;
            totalPending += amount;
        }

        return totalPending + overflow[_generationId][_tokenId];
    }
    
    /*
     *  @title Subtract function, on underflow returns zero.
     */
    function subOrZero(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IStackOsNFT.sol";
import "./GenerationManager.sol";
import "./Whitelist.sol";

contract DarkMatter is Whitelist, ERC721, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    GenerationManager private generations;

    // total amount of NFT deposited from any generation
    mapping(address => uint256) private deposits; 
    // owner => current incomplete DarkMatter id
    mapping(address => uint256) private lastUserDarkMatter; 
    // owner => DarkMatter ids
    mapping(address => uint256[]) private toBeMinted; 
    // generation => StackNFT id => DarkMatter id
    mapping(uint256 => mapping(uint256 => uint256)) private stackToDarkMatter; 

    // DarkMatter id => generation => StackNFT ids 
    mapping(uint256 => mapping(uint256 => uint256[])) private darkMatterToStack; 
    // mapping(address => bool) _whitelist;
    
    // number of StackNFTs that must be deposited in order to be able to mint a DarkMatter.
    uint256 immutable mintPrice; 

    constructor(GenerationManager _generations, uint256 _mintPrice)
        ERC721("DarkMatter", "DM")
    {
        generations = _generations;
        mintPrice = _mintPrice;
    }

    /*
     * @title Return stack token ids owned by DarkMatter token.
     * @param DarkMatter token id.
     */
    function ID(uint256 _darkMatterId)
        public
        view
        returns (uint256[][] memory)
    {
        uint256[][] memory stackTokenIds = new uint256[][](generations.count());
        for(uint256 i; i < stackTokenIds.length; i ++) {
            stackTokenIds[i] = darkMatterToStack[_darkMatterId][i];
        }
        return stackTokenIds;
    }

    /*
     * @title Returns true if `_wallet` owns either StackNFT or DarkMatterNFT that owns this StackNFT.
     * @param Address of wallet.
     * @param StackNFT generation id.
     * @param StackNFT token id.
     */
    function isOwnStackOrDarkMatter(
        address _wallet,
        uint256 generationId,
        uint256 tokenId
    ) public view returns (bool) {
        if (
            _exists(stackToDarkMatter[generationId][tokenId]) &&
            ownerOf(generationId, tokenId) == _wallet
        ) {
            return true;
        }
        return generations.get(generationId).ownerOf(tokenId) == _wallet;
    }

    /*
     * @title Returns owner of StackNFT.
     * @param StackNFT address.
     * @param StackNFT token id.
     * @dev The returned address owns StackNFT or DarkMatter that owns this StackNFT. 
     */
    function ownerOfStackOrDarkMatter(IStackOsNFT _stackOsNFT, uint256 tokenId)
        public
        view
        returns (address)
    {
        uint256 generationId = generations.getIDByAddress(address(_stackOsNFT));
        if (_exists(stackToDarkMatter[generationId][tokenId])) {
            return ownerOf(generationId, tokenId);
        }
        return _stackOsNFT.ownerOf(tokenId);
    }

    /*
     * @title Returns owner of the DarkMatterNFT that owns StackNFT.
     * @param StackNFT generation id.
     * @param StackNFT token id.
     */
    function ownerOf(uint256 generationId, uint256 tokenId)
        public
        view
        returns (address)
    {
        return ownerOf(stackToDarkMatter[generationId][tokenId]);
    }

    /*
     *  @title Deposit StackNFTs.
     *  @param StackNFT generation id.
     *  @param Token ids.
     *  @dev StackNFT generation must be added in manager prior to deposit.
     */
    function deposit(uint256 generationId, uint256[] calldata tokenIds)
        external
        nonReentrant
    {
        require(generationId < generations.count(), "Generation doesn't exist");
        IStackOsNFT stackNFT = generations.get(generationId);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            stackNFT.transferFrom(msg.sender, address(this), tokenId);

            if (deposits[msg.sender] == 0) {
                lastUserDarkMatter[msg.sender] = _tokenIdCounter.current();
                _tokenIdCounter.increment();
            }
            deposits[msg.sender] += 1;
            if (deposits[msg.sender] == mintPrice) {
                deposits[msg.sender] -= mintPrice;
                darkMatterToStack[lastUserDarkMatter[msg.sender]][generationId].push(tokenId);
                toBeMinted[msg.sender].push(lastUserDarkMatter[msg.sender]);
            } else {
                darkMatterToStack[lastUserDarkMatter[msg.sender]][generationId].push(tokenId);
            }
            stackToDarkMatter[generationId][tokenId] = lastUserDarkMatter[
                msg.sender
            ];
        }
    }

    /*
     *  @title Mints a DarkMatterNFT for the caller.
     *  @dev Caller must have deposited `mintPrice` number of StackNFT of any generation.
     */
    function mint() public nonReentrant {
        require(toBeMinted[msg.sender].length > 0, "Not enough deposited");
        while (toBeMinted[msg.sender].length > 0) {
            _mint(
                msg.sender,
                toBeMinted[msg.sender][toBeMinted[msg.sender].length - 1]
            );
            toBeMinted[msg.sender].pop();
        }
    }

    /*
     *  @title Override to make use of whitelist.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721)
        onlyWhitelisted
    {
        super._transfer(from, to, tokenId);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IStackOsNFT.sol";
import "./StackOsNFTBasic.sol";

contract GenerationManager is Ownable, ReentrancyGuard {
    using Strings for uint256;

    address stableAcceptor;
    address exchange;
    address dao;
    address distr;

    IStackOsNFT[] private generations;
    mapping(address => uint256) private ids;

    struct Deployment {
        string name;
        string symbol;
        address stackToken;
        address darkMatter;
        address subscription;
        address sub0;
        uint256 participationFee;
        uint256 subsFee;
        uint256 daoFee;
        uint256 distrFee;
        uint256 maxSupplyGrowthPercent;
        uint256 transferDiscount;
        uint256 timeLock;
        address royaltyAddress;
        address market;
    }
    Deployment deployment;

    modifier onlyOwnerOrStackContract() {
        require(owner() == _msgSender() || isAdded(_msgSender()), "Caller is not the owner or stack contract");
        _;
    }

    constructor() {}

    function adjustAddressSettings(
        address _stableAcceptor,
        address _exchange,
        address _dao,
        address _distr
    )
        public
        onlyOwner
    {
        stableAcceptor = _stableAcceptor;
        exchange = _exchange;
        dao = _dao;
        distr = _distr;
    }

    /*
     * @title Save settings for auto deployment.
     * @param _maxSupplyGrowthPercent increase max supply for new contract by this percent.
     * @dev Could only be invoked by the contract owner.
     */
    function setupDeploy(
        string memory _name,
        string memory _symbol,
        address _stackToken,
        address _darkMatter,
        address _subscription,
        address _sub0,
        uint256 _participationFee,
        uint256 _subsFee,
        uint256 _maxSupplyGrowthPercent,
        uint256 _transferDiscount,
        uint256 _timeLock,
        address _royaltyAddress
    ) public onlyOwner {
        require(_maxSupplyGrowthPercent <= 10000, "invalid basis points");
        deployment.name = _name;
        deployment.symbol = _symbol;
        deployment.stackToken = _stackToken;
        deployment.darkMatter = _darkMatter;
        deployment.subscription = _subscription;
        deployment.sub0 = _sub0;
        deployment.participationFee = _participationFee;
        deployment.subsFee = _subsFee;
        deployment.maxSupplyGrowthPercent = _maxSupplyGrowthPercent;
        deployment.transferDiscount = _transferDiscount;
        deployment.timeLock = _timeLock;
        deployment.royaltyAddress = _royaltyAddress;
    }

    /*
     * @title Save additional settings for auto deployment.
     * @param Address of market.
     * @dev Could only be invoked by the contract owner.
     * @dev Must be called along with first setup function.
     */
    function setupDeploy2(
        address _market,
        uint256 _daoFee,
        uint256 _distrFee
    ) public onlyOwner {
        deployment.market = _market;
        deployment.daoFee = _daoFee;
        deployment.distrFee = _distrFee;
    }

    /*
     * @title Called by StackNFTBasic once it reaches max supply.
     * @dev Could only be invoked by the last StackOsNFTBasic generation.
     * @dev Generation id is appended to the name. 
     */
    function deployNextGenPreset() public returns (IStackOsNFTBasic) 
    {
        // Can only be called from StackNFT contracts
        uint256 callerGenerationId = getIDByAddress(msg.sender);
        // Cannot deploy next generation if it's already exists
        require(callerGenerationId == generations.length - 1, 
            "Next generation already deployed"
        );

        IStackOsNFT caller = get(callerGenerationId);
        uint256 maxSupply = caller.getMaxSupply() * 
            (deployment.maxSupplyGrowthPercent + 10000) / 10000;
        string memory name = string(abi.encodePacked(
            deployment.name,
            " ",
            uint256(count() + 1).toString()
        ));
        StackOsNFTBasic stack = StackOsNFTBasic(
            address(
                new StackOsNFTBasic()
            )
        );
        stack.setName(name);
        stack.setSymbol(deployment.symbol);
        stack.initialize(
            deployment.stackToken,
            deployment.darkMatter,
            deployment.subscription,
            deployment.sub0,
            deployment.royaltyAddress,
            stableAcceptor,
            exchange,
            deployment.participationFee,
            maxSupply,
            deployment.transferDiscount,
            deployment.timeLock
        );
        add(IStackOsNFT(address(stack)));
        stack.setFees(deployment.subsFee, deployment.daoFee, deployment.distrFee);
        stack.adjustAddressSettings(dao, distr);
        stack.whitelist(address(deployment.darkMatter));
        stack.whitelist(address(deployment.market));
        stack.transferOwnership(Ownable(msg.sender).owner());
        return IStackOsNFTBasic(address(stack));
    }

    /*
     * @title Add next generation of StackNFT.
     * @param IStackOsNFT address.
     * @dev Could only be invoked by the contract owner or StackNFT contract.
     * @dev Address should be unique.
     */
    function add(IStackOsNFT _stackOS) public onlyOwnerOrStackContract {
        require(address(_stackOS) != address(0), "Must be not zero-address");
        for (uint256 i; i < generations.length; i++) {
            require(generations[i] != _stackOS, "Address already added");
        }
        ids[address(_stackOS)] = generations.length;
        generations.push(_stackOS);
    }

    /*
     * @title Deploy new StackOsNFTBasic manually.
     * @dev Additional setup is required after deploy: 
     * @dev Whitelist DarkMatter and Market.
     * @dev Call to setFees.
     * @dev Adjust address settings.
     * @dev Example of full setup can be seen in deployNextGenPreset.
     */

    function deployNextGen(
        string memory _name,
        string memory _symbol,
        address _stackToken,
        address _darkMatter,
        address _subscription,
        address _sub0,
        uint256 _participationFee,
        uint256 _maxSupply,
        uint256 _transferDiscount,
        uint256 _timeLock,
        address _royaltyAddress
    ) public onlyOwner returns (IStackOsNFTBasic) {
        StackOsNFTBasic stack = StackOsNFTBasic(
            address(
                new StackOsNFTBasic()
            )
        );
        stack.setName(_name);
        stack.setSymbol(_symbol);
        stack.initialize(
            _stackToken,
            _darkMatter,
            _subscription,
            _sub0,
            _royaltyAddress,
            stableAcceptor,
            exchange,
            _participationFee,
            _maxSupply,
            _transferDiscount,
            _timeLock
        );
        add(IStackOsNFT(address(stack)));
        stack.transferOwnership(msg.sender);
        return IStackOsNFTBasic(address(stack));
    }

    /*
     * @title Get total number of generations added.
     */
    function count() public view returns (uint256) {
        return generations.length;
    }

    /*
     * @title Get generation of StackNFT contract by id.
     * @param Generation id.
     * @dev Must be valid generation id to avoid out-of-bounds error.
     */
    function get(uint256 generationId) public view returns (IStackOsNFT) {
        return generations[generationId];
    }

    /*
     * @title Get generation ID by address.
     * @param Stack NFT contract address
     */
    function getIDByAddress(address _nftAddress) public view returns (uint256) {
        uint256 generationID = ids[_nftAddress];
        if (generationID == 0) {
            require(address(get(0)) == _nftAddress, "Not Correct Address");
        }
        return generationID;
    }

    /*
     * @title Returns whether StackNFT contract is added to this manager.
     * @param Stack NFT contract address
     */
    function isAdded(address _nftAddress) public view returns (bool) {
        uint256 generationID = ids[_nftAddress];
        return generations.length > generationID && address(get(generationID)) == _nftAddress;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StableCoinAcceptor {

    IERC20[] public stablecoins;

    constructor(
        IERC20[] memory _stables
    ) {
        stablecoins = _stables;
    }

    /*
     * @title Whether provided stablecoin is supported.
     * @param Address to lookup.
     */

    function supportsCoin(IERC20 _address) public view returns (bool) {
        for(uint256 i; i < stablecoins.length; i++) {
            if(_address == stablecoins[i]) {
                return true;
            }
        }
        return false;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Exchange {

    IUniswapV2Router02 private router;

    constructor (address _router) {
        router = IUniswapV2Router02(_router);
    }

    /*
     *  @title Swap exact ETH for tokens
     *  @param Address of token to receive
     */
    function swapExactETHForTokens(
        IERC20 token
    ) public payable returns (uint256) {
        uint256 deadline = block.timestamp + 1200;
        address[] memory path = new address[](2);
        path[0] = address(router.WETH());
        path[1] = address(token);
        uint256[] memory amountOutMin = router.getAmountsOut(msg.value, path);
        uint256[] memory amounts = router.swapExactETHForTokens{value: msg.value}(
            amountOutMin[1],
            path,
            address(msg.sender),
            deadline
        );
        return amounts[1];
    }

    /*
     *  @title Swap exact tokens for tokens using path tokenA > WETH > tokenB
     *  @param Amount of tokenA to spend
     *  @param Address of tokenA to spend
     *  @param Address of tokenB to receive
     */

    function swapExactTokensForTokens(
        uint256 amountA, 
        IERC20 tokenA, 
        IERC20 tokenB
    ) public returns (uint256) {

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenA.approve(address(router), amountA);

        uint256 deadline = block.timestamp + 1200;
        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(router.WETH());
        path[2] = address(tokenB);
        uint256[] memory amountOutMin = router.getAmountsOut(amountA, path);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountA,
            amountOutMin[2],
            path,
            address(msg.sender),
            deadline
        );
        return amounts[2];
    }

    /*
     *  @title Get amount of tokenIn needed to buy amountOut of tokenOut using path tokenIn > WETH > tokenOut
     */

    function getAmountIn(
        uint256 amountOut, 
        IERC20 tokenOut, 
        IERC20 tokenIn
    ) public view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn);
        path[1] = address(router.WETH());
        path[2] = address(tokenOut);
        uint256[] memory amountsIn = router.getAmountsIn(amountOut, path);
        return amountsIn[0];
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IStackOsNFT.sol";

interface IStackOsNFTBasic is IStackOsNFT {


    function setName(
        string memory name_
    ) external;

    function setSymbol(
        string memory symbol_
    ) external;

    function mintFromSubscriptionRewards(
        uint256 _nftAmount,
        uint256 _stackAmount,
        address _to
    ) external;

    function mintFromRoyaltyRewards(
        uint256 _mintNum,
        address _stablecoin,
        address _to
    ) external returns (uint256);
    

    function getFromRewardsPrice(uint256 _nftAmount, address _stablecoin)
        external
        view
        returns (uint256);

    function price()
        external
        view
        returns (uint256);

    function rewardDiscount()
        external
        view
        returns (uint256);

    function transferFromLastGen(address _ticketOwner, uint256 _amount)
        external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IStackOsNFT is IERC721 {

    function whitelist(address _addr) external;

    function getMaxSupply() external view returns (uint256);

    function getDelegatee(uint256 _tokenId) external view returns (address);

    function transferOwnership(address newOwner) external;

    function exists(uint256 _tokenId) external returns (bool);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Whitelist is Ownable {

    mapping(address => bool) _whitelist;
 
    modifier onlyWhitelisted () {
        require(_whitelist[_msgSender()], "Not whitelisted for transfers");
        _;
    }

    /*
     *  @title Whitelist address to transfer tokens.
     *  @param Address to whitelist.
     *  @dev Caller must be owner of the contract.
     */
    function whitelist(address _addr) public onlyOwner {
        _whitelist[_addr] = true;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721/extensions/CustomERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IStackOsNFT.sol";
import "./Subscription.sol";
import "./StableCoinAcceptor.sol";
import "./Exchange.sol";
import "./Whitelist.sol";
import "./Royalty.sol";

contract StackOsNFTBasic is
    Whitelist,
    CustomERC721,
    CustomERC721URIStorage
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    IERC20 private stackToken;
    DarkMatter private darkMatter;
    Subscription private subscription;
    Subscription private sub0;
    Royalty private royaltyAddress;
    StableCoinAcceptor stableAcceptor;
    GenerationManager private generations;
    Exchange private exchange;
    address private daoAddress;
    address private royaltyDistrAddress;

    uint256 public timeLock;
    uint256 public adminWithdrawableAmount;
    uint256 public rewardDiscount;
    uint256 private maxSupply;
    uint256 private totalSupply;
    uint256 private participationFee;
    uint256 private transferDiscount;
    uint256 internal subsFee;
    uint256 internal daoFee;
    uint256 internal distrFee;
    uint256 constant maxMintRate = 10;

    mapping(uint256 => address) private delegates;
    mapping(address => uint256) private totalMinted;
    mapping(address => uint256) private lastMintAt;

    bool private salesStarted;
    string private URI = "https://google.com/";

    bool private initialized;

    /*
     * @title Must be deployed only by GenerationManager
     */
    constructor() {
        
        require(Address.isContract(msg.sender), "Must be deployed by generation manager");
        generations = GenerationManager(msg.sender);
    }

    function initialize(
        address _stackToken,
        address _darkMatter,
        address _subscription,
        address _sub0,
        address _royaltyAddress,
        address _stableAcceptor,
        address _exchange,
        uint256 _participationFee,
        uint256 _maxSupply,
        uint256 _transferDiscount,
        uint256 _timeLock
    ) public onlyOwner {
        require(initialized == false, "Already initialized");
        initialized = true;
        
        stackToken = IERC20(_stackToken);
        darkMatter = DarkMatter(_darkMatter);
        subscription = Subscription(_subscription);
        sub0 = Subscription(_sub0);
        royaltyAddress = Royalty(payable(_royaltyAddress));
        stableAcceptor = StableCoinAcceptor(_stableAcceptor);
        exchange = Exchange(_exchange);

        participationFee = _participationFee;
        maxSupply = _maxSupply;
        transferDiscount = _transferDiscount;
        timeLock = block.timestamp + _timeLock;
    }

    /*
     * @title Set token name.
     * @dev Could only be invoked by the contract owner.
     */
    function setName(string memory name_) public onlyOwner {
        _name = name_;
    }

    /*
     * @title Set token symbol.
     * @dev Could only be invoked by the contract owner.
     */
    function setSymbol(string memory symbol_) public onlyOwner {
        _symbol = symbol_;
    }

    /*
     * @title Adjust address settings
     * @param Dao address
     * @param Royalty distribution address
     * @dev Could only be invoked by the contract owner.
     */

    function adjustAddressSettings(
        address _dao, 
        address _distr
    )
        public
        onlyOwner
    {
        daoAddress = _dao;
        royaltyDistrAddress = _distr;
    }

    /*
     * @title Set discont applied on mint from subscription or royalty rewards
     * @param percent
     * @dev Could only be invoked by the contract owner.
     */

    function setRewardDiscount(uint256 _rewardDiscount) public onlyOwner {
        require(_rewardDiscount <= 10000, "invalid basis points");
        rewardDiscount = _rewardDiscount;
    }

    /*
     * @title Set amounts taken from mint
     * @param % that is sended to Subscription contract 
     * @param % that is sended to dao
     * @param % that is sended to royalty distribution
     * @dev Could only be invoked by the contract owner.
     */

    function setFees(uint256 _subs, uint256 _dao, uint256 _distr)
        public
        onlyOwner
    {
        require(_subs <= 10000 && _dao <= 10000 && _distr <= 10000, "invalid fee basis points");
        subsFee = _subs;
        daoFee = _dao;
        distrFee = _distr;
    }

    /*
     * @title Get max supply
     */
    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    /*
     * @title Get token's delegatee.
     * @dev Returns zero-address if token not delegated.
     */

    function getDelegatee(uint256 _tokenId) public view returns (address) {
        return delegates[_tokenId];
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    
    /*
     * @title Get mint price in USD
     */
    function price() public view returns (uint256) {
        return participationFee;
    }

    /*
     * @title Called by 1st generation as part of `transferTickets`
     * @param Wallet to mint tokens to
     * @param Amount of STACK token received
     * @dev Could only be invoked by the StackNFT contract.
     * @dev It receives stack token and use it to mint NFTs at a discount
     */
    function transferFromLastGen(address _ticketOwner, uint256 _amount) public {

        // check that caller is generation 1 contract 
        require(
            address(generations.get(0)) == msg.sender, 
            "Not Correct Address"
        );
        IERC20 stablecoin = stableAcceptor.stablecoins(0);
        stackToken.transferFrom(msg.sender, address(this), _amount);
        stackToken.approve(address(exchange), _amount);
        uint256 usdAmount = exchange.swapExactTokensForTokens(
            _amount, 
            stackToken, 
            stablecoin
        );

        uint256 participationFeeDiscount = participationFee
            .mul(10000 - transferDiscount)
            .div(10000);

        uint256 ticketAmount = usdAmount.div(participationFeeDiscount);
        uint256 depositAmount = participationFeeDiscount.mul(ticketAmount);

        // stablecoin.transferFrom(msg.sender, address(this), amount);
        stablecoin.approve(address(exchange), usdAmount);
        uint256 stackDepositAmount = exchange.swapExactTokensForTokens(
            depositAmount, 
            stablecoin,
            stackToken
        );
        uint256 stackLeftOverAmount = exchange.swapExactTokensForTokens(
            usdAmount - depositAmount,
            stablecoin,
            stackToken
        );

        stackToken.transfer(
            _ticketOwner,
            stackLeftOverAmount
        );

        stackDepositAmount = sendFees(stackDepositAmount);

        adminWithdrawableAmount += stackDepositAmount;
        for (uint256 i; i < ticketAmount; i++) {
            _mint(_ticketOwner);
        }
    }

    /*
     * @title Allow to buy NFT's.
     * @dev Could only be invoked by the contract owner.
     */

    function startSales() public onlyOwner {
        salesStarted = true;
    }

    /*
     * @title User mint a token amount.
     * @param Number of tokens to mint.
     * @param Address of supported stablecoin
     * @dev Sales should be started before mint.
     */

    function mint(uint256 _nftAmount, IERC20 _stablecoin) public {
        require(salesStarted, "Sales not started");
        require(stableAcceptor.supportsCoin(_stablecoin), "Unsupported stablecoin");

        uint256 amountIn = participationFee.mul(_nftAmount);
        _stablecoin.transferFrom(msg.sender, address(this), amountIn);
        _stablecoin.approve(address(exchange), amountIn);
        uint256 stackAmount = exchange.swapExactTokensForTokens(
            amountIn, 
            _stablecoin,
            stackToken
        );

        stackAmount = sendFees(stackAmount);

        adminWithdrawableAmount += stackAmount;
        for (uint256 i; i < _nftAmount; i++) {
            _mint(msg.sender);
        }
    }

    /*
     * @title Called when user want to mint and pay with bonuses from subscriptions.
     * @param Amount to mint
     * @param Address of supported stablecoin
     * @param Address to mint to
     * @dev Can only be called by Subscription contract.
     * @dev Sales should be started before mint.
     */

    function mintFromSubscriptionRewards(
        uint256 _nftAmount,
        uint256 _stackAmount,
        address _to
    ) external {
        require(salesStarted, "Sales not started");
        require(
            msg.sender == address(subscription),
            "Not Subscription Address"
        );

        stackToken.transferFrom(msg.sender, address(this), _stackAmount);

        _stackAmount = sendFees(_stackAmount);

        adminWithdrawableAmount += _stackAmount;
        for (uint256 i; i < _nftAmount; i++) {
            _mint(_to);
        }

    }

    /*
     * @title Get how much stack token we need to sell to receive amount of USD needed to mint `_nftAmount`
     * @param Amount to mint
     * @param Address of supported stablecoin
     */
    function getFromRewardsPrice(uint256 _nftAmount, address _stablecoin)
        external 
        view
        returns (uint256)
    {
        uint256 discountAmount = participationFee -
            (participationFee * rewardDiscount) /
            10000;
        uint256 amountOut = discountAmount.mul(_nftAmount);
        return exchange.getAmountIn(amountOut, IERC20(_stablecoin), stackToken);
    }

    /*
     * @title Called when user want to mint and pay with bonuses from royalties.
     * @param Amount to mint
     * @param Address of supported stablecoin
     * @param Address to mint to
     * @dev Can only be called by Royalty contract.
     * @dev Sales should be started before mint.
     */

    function mintFromRoyaltyRewards(
        uint256 _mintNum, 
        address _stablecoin, 
        address _to
    ) 
        public
        returns (uint256)
    {
        require(salesStarted, "Sales not started");
        require(msg.sender == address(royaltyAddress), "Not Royalty Address");
        uint256 discountAmount = participationFee -
            (participationFee * rewardDiscount) /
            10000;
            
        uint256 amountIn = discountAmount.mul(_mintNum);
        IERC20(_stablecoin).transferFrom(msg.sender, address(this), amountIn);
        IERC20(_stablecoin).approve(address(exchange), amountIn);
        uint256 stackAmount = exchange.swapExactTokensForTokens(
            amountIn, 
            IERC20(_stablecoin),
            stackToken
        );

        stackAmount = sendFees(stackAmount);

        adminWithdrawableAmount += stackAmount;
        for (uint256 i; i < _mintNum; i++) {
            _mint(_to);
        }
        return amountIn;
    }

    /*
     * @returns left over amount after fees subtracted
     * @dev Take fees out of `_amount`
     */

    function sendFees(uint256 _amount) internal returns (uint256) {

        uint256 subsPart = _amount * subsFee / 10000;
        uint256 daoPart = _amount * daoFee / 10000;
        uint256 distrPart = _amount * distrFee / 10000;
        _amount = _amount - subsPart - daoPart - distrPart;

        uint256 subsPartHalf = subsPart / 2;

        stackToken.approve(address(sub0), subsPartHalf);
        stackToken.approve(address(subscription), subsPartHalf);
        // if subs contract don't take it, send to dao 
        if(sub0.onReceiveStack(subsPartHalf) == false) {
            daoPart += (subsPartHalf);
        }
        if(subscription.onReceiveStack(subsPartHalf) == false) {
            daoPart += (subsPartHalf);
        }
        stackToken.transfer(address(daoAddress), daoPart);
        stackToken.transfer(address(royaltyDistrAddress), distrPart);

        return _amount;
    }

    function _delegate(address _delegatee, uint256 tokenId) private {
        require(
            msg.sender ==
                darkMatter.ownerOfStackOrDarkMatter(
                    IStackOsNFT(address(this)),
                    tokenId
                ),
            "Not owner"
        );
        require(delegates[tokenId] == address(0), "Already delegated");
        delegates[tokenId] = _delegatee;
        royaltyAddress.onDelegate(tokenId);
    }

    /*
     * @title Delegate NFT.
     * @param Address of delegatee.
     * @param tokenIds to delegate.
     * @dev Caller must own token.
     * @dev Delegation can be done only once.
     */

    function delegate(address _delegatee, uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            _delegate(_delegatee, tokenIds[i]);
        }
    }

    // is reentrancy attack possible?
    function _mint(address _address) internal {
        require(totalSupply < maxSupply, "Max supply reached");

        uint256 timeSinceLastMint = block.timestamp - lastMintAt[_address];
        uint256 unlocked = timeSinceLastMint / 1 minutes;
        if (unlocked > totalMinted[_address])
            unlocked = totalMinted[_address];
        totalMinted[_address] -= unlocked;

        lastMintAt[_address] = block.timestamp;

        require(
            totalMinted[_address] < maxMintRate,
            "Minting too fast"
        );

        totalMinted[_address] += 1;

        uint256 _current = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        totalSupply += 1;
        _safeMint(_address, _current);
        _setTokenURI(_current, URI);

        if(totalSupply == maxSupply) {
            generations.deployNextGenPreset();
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) 
        internal 
        override(CustomERC721) 
        onlyWhitelisted 
    {
        super._transfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(CustomERC721, CustomERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(CustomERC721, CustomERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /*
     * @title Contract owner can withdraw collected fees.
     * @dev Caller must be contract owner, timelock should be passed.
     */
    function adminWithdraw() public onlyOwner {
        require(block.timestamp > timeLock, "Locked!");
        stackToken.transfer(msg.sender, adminWithdrawableAmount);
        adminWithdrawableAmount = 0;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../CustomERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract CustomERC721URIStorage is CustomERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GenerationManager.sol";
import "./DarkMatter.sol";
import "./interfaces/IStackOsNFT.sol";
import "./interfaces/IStackOsNFTBasic.sol";
import "./Exchange.sol";

contract Royalty is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private counter; // counting cycles

    uint256 private constant HUNDRED_PERCENT = 10000;
    GenerationManager private generations;
    DarkMatter private darkMatter;
    Exchange private exchange;
    IERC20 private WETH; // for Matic network
    address payable private feeAddress;
    uint256 private feePercent;

    uint256 private minEthToStartCycle;
    uint256 private constant CYCLE_DURATION = 30 days;

    struct Cycle {
        uint256 startTimestamp; // cycle started timestamp
        uint256 balance; // how much deposited during cycle
        uint256 delegatedCount; // how much tokens delegated when cycle started
        mapping(uint256 => mapping(uint256 => bool)) isClaimed; // whether reward for this token in this cycle is claimed
    }

    mapping(uint256 => Cycle) private cycles; 
    mapping(uint256 => mapping(uint256 => int256)) addedAt; // at which cycle the token were added
    uint256 totalDelegated;

    constructor(
        GenerationManager _generations,
        DarkMatter _darkMatter,
        Exchange _exchange,
        address payable _feeAddress,
        uint256 _minEthToStartCycle
    ) {
        generations = _generations;
        darkMatter = _darkMatter;
        exchange = _exchange;
        feeAddress = _feeAddress;
        minEthToStartCycle = _minEthToStartCycle;
    }

    /*
     * @title Callback called when Stack NFT is delegated.
     */
    function onDelegate(uint256 tokenId) public {
        require(
            generations.isAdded(msg.sender), 
            "Caller must be StackNFT contract"
        );
        uint256 generationId = generations.getIDByAddress(msg.sender);
        addedAt[generationId][tokenId] = int256(counter.current());
        if (cycles[counter.current()].delegatedCount == 0)
            addedAt[generationId][tokenId] = -1;
        totalDelegated += 1;
    }

    /*
     * @title Deposit royalty so that NFT holders can claim it later.
     */
    receive() external payable {
        checkDelegationsForFirstCycle();

        // take fee from deposits
        uint256 feePart = ((msg.value * feePercent) / HUNDRED_PERCENT);

        // is current cycle lasts enough?
        if (
            cycles[counter.current()].startTimestamp + CYCLE_DURATION <
            block.timestamp
        ) {
            // is current cycle got enough ether?
            if (cycles[counter.current()].balance >= minEthToStartCycle) {
                // start new cycle
                counter.increment();
                // save count of delegates that exists on start of cycle
                cycles[counter.current()].delegatedCount = totalDelegated;
                cycles[counter.current()].startTimestamp = block.timestamp;

                cycles[counter.current()].balance += msg.value - feePart;
            } else {
                cycles[counter.current()].balance += msg.value - feePart;
            }
        } else {
            cycles[counter.current()].balance += msg.value - feePart;
        }

        feeAddress.call{value: feePart}("");
    }

    /**
     * @dev Ensures that a cycle cannot start if there is no delegated StackOS NFTs.
     */
    function checkDelegationsForFirstCycle() private {
        // this should be true for the first cycle only, 
        // even if there is already delegates exists, this cycle still dont know about it
        if (cycles[counter.current()].delegatedCount == 0) {
            // we can't start first cycle without delegated NFTs, so with this we 'restart' first cycle,
            // this dont allow to end first cycle with perTokenReward = 0 and balance > 0
            cycles[counter.current()].startTimestamp = block.timestamp;
            /*
                The following check is need to prevent ETH hang on first cycle forever.
                If first ever delegation happens at the same block with receiving eth here,
                then no one can claim for the first cycle, because when claiming royalty
                there is check: tokenDelegationTime < cycleStartTime
            */
            if (totalDelegated > 0) {
                // we can still get 0 here, then in next ifs we will just receive eth for cycle
                cycles[counter.current()]
                    .delegatedCount = totalDelegated;
            }
        }
    }

    /*
     * @title Set fee address
     * @param fee address
     * @dev Could only be invoked by the contract owner.
     */
    function setFeeAddress(address payable _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "Must be not zero-address");
        feeAddress = _feeAddress;
    }    

    /*
     * @title Set WETH address, probably should be used on Matic network
     * @param WETH address
     * @dev Could only be invoked by the contract owner.
     */
    function setWETH(IERC20 _WETH) external onlyOwner {
        require(address(_WETH) != address(0), "Must be not zero-address");
        WETH = _WETH;
    }

    /*
     * @title Set fee percent taken of each deposit
     * @param fee basis points
     * @dev Could only be invoked by the contract owner.
     */
    function setFeePercent(uint256 _percent) external onlyOwner {
        require(feePercent <= HUNDRED_PERCENT, "invalid fee basis points");
        feePercent = _percent;
    }

    /*
     * @title Claim royalty for holding delegated NFTs 
     * @param StackOS generation id 
     * @param Token ids
     * @dev tokens must be delegated and owned by the caller
     */
    function claim(uint256 _generationId, uint256[] calldata _tokenIds)
        external
    {
        _claim(_generationId, _tokenIds, 0, false, IERC20(address(0)), false);
    }

    /*
     * @title Same as `claim` but holders receive WETH
     * @dev tokens must be delegated and owned by the caller
     * @dev WETH address must be set by the admin
     */
    function claimWETH(uint256 _generationId, uint256[] calldata _tokenIds)
        external
    {
        require(address(WETH) != address(0), "Wrong WETH address");
        _claim(_generationId, _tokenIds, 0, false, IERC20(address(0)), true);
    }

    /*
     * @title Purchase StackNFTs for royalties, caller will receive the left over amount of royalties
     * @param StackNFT generation id
     * @param Token ids
     * @param Amount to mint
     * @param Supported stablecoin to use to buy stack token
     * @dev tokens must be delegated and owned by the caller
     */
    function purchaseNewNft(
        uint256 _generationId,
        uint256[] calldata _tokenIds,
        uint256 _mintNum,
        IERC20 _stablecoin 
    ) external {
        require(_generationId > 0, "Must be not first generation");
        _claim(_generationId, _tokenIds, _mintNum, true, _stablecoin, false);
    }

    function _claim(
        uint256 generationId,
        uint256[] calldata tokenIds,
        uint256 _mintNum,
        bool _mint,
        IERC20 _stablecoin,
        bool _claimWETH
    ) internal {
        require(address(this).balance > 0, "No royalty");
        IStackOsNFT stack = generations.get(generationId);
        require(
            stack.balanceOf(msg.sender) > 0 ||
                darkMatter.balanceOf(msg.sender) > 0,
            "You dont have NFTs"
        );

        checkDelegationsForFirstCycle();

        if (
            cycles[counter.current()].startTimestamp + CYCLE_DURATION <
            block.timestamp
        ) {
            if (cycles[counter.current()].balance >= minEthToStartCycle) {
                counter.increment();
                cycles[counter.current()].delegatedCount = totalDelegated;
                cycles[counter.current()].startTimestamp = block.timestamp;
            }
        }

        if (counter.current() > 0) {
            uint256 reward;

            // iterate over tokens from args
            for (uint256 i; i < tokenIds.length; i++) {
                uint256 tokenId = tokenIds[i];

                require(
                    darkMatter.isOwnStackOrDarkMatter(
                        msg.sender,
                        generationId,
                        tokenId
                    ),
                    "Not owner"
                );
                require(
                    stack.getDelegatee(tokenId) != address(0),
                    "NFT should be delegated"
                );

                for (uint256 o; o < counter.current(); o++) {
                    if (
                        // should be able to claim only once for cycle
                        cycles[o].isClaimed[generationId][tokenId] == false
                        // is this token delegated before this cycle start?
                        && addedAt[generationId][tokenId] < int256(o)
                    ) {
                        reward += cycles[o].balance / cycles[o].delegatedCount;
                        cycles[o].isClaimed[generationId][
                            tokenId
                        ] = true;
                    }
                }
            }

            if (reward > 0) {
                if (_mint == false) {
                    if(_claimWETH) {
                        uint256 wethReceived = exchange.swapExactETHForTokens{value: reward}(WETH);
                        WETH.transfer(msg.sender, wethReceived);
                    } else {
                        (bool success, ) = payable(msg.sender).call{value: reward}(
                            ""
                        );
                        require(success, "Transfer failed");
                    }
                } else {
                    IStackOsNFTBasic stackNFT = IStackOsNFTBasic(address(generations.get(generationId)));
                    uint256 usdReceived = exchange.swapExactETHForTokens{value: reward}(_stablecoin);
                    _stablecoin.approve(address(stackNFT), usdReceived);

                    uint256 spendAmount = stackNFT.mintFromRoyaltyRewards(
                        _mintNum,
                        address(_stablecoin), 
                        msg.sender
                    );
                    _stablecoin.transfer(msg.sender, usdReceived - spendAmount);
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract CustomERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = CustomERC721.ownerOf(tokenId);
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
        address owner = CustomERC721.ownerOf(tokenId);
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
        address owner = CustomERC721.ownerOf(tokenId);

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
        require(CustomERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(CustomERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}