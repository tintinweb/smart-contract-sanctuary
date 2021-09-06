pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Pair.sol";


/// Distributes a random Card for a set price
contract LootCrate is IERC721Receiver, VRFConsumerBase, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 public immutable startBlock;

    IERC20 public immutable inputCurrency;
    IUniswapV2Pair public immutable inputCurrencyLiqPool;

    uint256 public priceInMatic = 42 * (10 ** 18);
    uint256 constant FP112 = 2 ** 112;
    uint256 public cumulativePrice;
    uint256 public priceLastUpdated;
    uint256 public smoothedPackPrice;
    uint256 public smoothingPercent = 10;

    // the following config is for chainlink on polygon
    bytes32 internal constant keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    uint256 internal constant fee = 0.0001 * 10 ** 18;
    uint256 public pendingSpins;

    mapping(bytes32 => address) public request2address;

    struct Card {
        uint256 cardId;
        address contractAddress;
        bool isNFT;
        bool isRare;
        uint256 amountOrID;
    }

    struct Pack {
        uint256 permPackIdx;
        Card card1;
        Card card2;
        Card card3;
    }

    // all packs ever
    Pack[] public permPacks;
    // live packs
    Pack[] public packs;

    mapping(address => uint256[]) public userPurchasesMap;
    mapping(address => uint256) public userClaimedCountMap;

    uint256[] public purchases;

    uint256 public cardIdCount = 0;

    event LootCratePurchased(address buyerAddress, uint256 maticPrice, uint256 inputCurrencyPrice);
    event CardDeliveredToBuyer(uint256 indexed cardId, address contractAddress, address recipient, uint256 amountOrId, bool isNFT, bool isRare);
    event PackPurchaseComplete(uint256 indexed packId, address recipient);
    event OwnersInputCurrencyWithdrawn(address recipient, uint256 amount);
    event PackAddedByOwner(uint256 indexed packId);
    event MaticPriceSet(uint256 newPrice);
    event PackRemovedByOwners(address recipient, uint256 indexed packId);

    constructor(uint256 _startBlock, address _inputCurrency, address inputCurrencyWmaticPair)
        public
        Ownable()
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
        ) {
        startBlock = _startBlock;

        inputCurrency = IERC20(_inputCurrency);

        inputCurrencyLiqPool = IUniswapV2Pair(inputCurrencyWmaticPair);

        // initiate price tracking
        // we are converting 75 matic to inputCurrency, so we want to track
        // the price for the token which isn't inputCurrency
        cumulativePrice = _inputCurrency == IUniswapV2Pair(inputCurrencyWmaticPair).token0()
            ? IUniswapV2Pair(inputCurrencyWmaticPair).price1CumulativeLast()
            : IUniswapV2Pair(inputCurrencyWmaticPair).price0CumulativeLast();

        (uint112 reserve0, uint112 reserve1, uint256 pairLastUpdated) =
                IUniswapV2Pair(inputCurrencyWmaticPair).getReserves();
        priceLastUpdated = pairLastUpdated;
        smoothedPackPrice = _inputCurrency == IUniswapV2Pair(inputCurrencyWmaticPair).token0()
            ? priceInMatic * reserve0 / reserve1
            : priceInMatic * reserve1 / reserve0;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function getNumberOfPermPacks() external view returns (uint256) {
        return permPacks.length;
    }

    function getRemainingNumberOfPacks() external view returns (uint256) {
        return packs.length;
    }

    function getNumberOfPurchases() external view returns (uint256)  {
        return purchases.length;
    }

    function getNumberOfUserPurchases(address customerAddress) external view returns (uint256)  {
        return userPurchasesMap[customerAddress].length;
    }

    function getNumberOfPendingUserWithdraws(address customerAddress) public view returns (uint256)  {
        return userPurchasesMap[customerAddress].length - userClaimedCountMap[customerAddress];
    }

    function getLastXUserPurchases(address customerAddress, uint256 length) external view returns (Pack[] memory){
        require(customerAddress != address(0), "customer address can't be 0");

        uint256[] storage userPurchases = userPurchasesMap[customerAddress];

        if (length > userPurchases.length)
            length = userPurchases.length;

        Pack[] memory fechedUserPurchases = new Pack[](length);

        if (userPurchases.length == 0)
            return fechedUserPurchases;

        bool hasReachedZero = false;

        uint256 pos = userPurchases.length - 1;

        uint256 zeroOrXDown = pos - (length - 1);

        uint256 idx = 0;

        // we scan up to 40 cards down, to help target specific cards if cards are being removed.
        while (pos>=zeroOrXDown && !hasReachedZero) {
            if (pos == 0)
                hasReachedZero = true;

            fechedUserPurchases[idx] = permPacks[userPurchases[pos]];

            if (pos > 0)
                pos = pos - 1;

            idx = idx + 1;
        }

        return fechedUserPurchases;
    }

    function getLastXPurchases(uint256 length) external view returns (Pack[] memory){
        if (length > purchases.length)
            length = purchases.length;

        Pack[] memory fechedPacks = new Pack[](length);

        if (purchases.length == 0)
            return fechedPacks;

        bool hasReachedZero = false;

        uint256 pos = purchases.length - 1;

        uint256 zeroOrXDown = pos - (length - 1);

        uint256 idx = 0;

        // we scan up to 40 cards down, to help target specific cards if cards are being removed.
        while (pos>=zeroOrXDown && !hasReachedZero) {
            if (pos == 0)
                hasReachedZero = true;

            fechedPacks[idx] = permPacks[purchases[pos]];

            if (pos > 0)
                pos = pos - 1;

            idx = idx + 1;
        }

        return fechedPacks;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender && !address(msg.sender).isContract(), "caller not EOA!");
        _;
    }

    /// Buy 3 random cards for an amount in inputCurrency, corresponding to the set price in matic, according to current conversion rate
    /// Calls out to chainlink, chainlink in turn then completes the transaction by calling our contract.
    function buyThreeRandomCards(uint256 maxPricePerPack) external nonReentrant onlyEOA {
        require(startBlock <= block.number, "this loot crate hasn't unlocked yet!");
        require(packs.length > pendingSpins, "Sold out!");

        // securely transfer inputCurrency token payment to this contract
        uint256 currentPrice = getCurrentPriceInInputCurrency();
        require(maxPricePerPack >= currentPrice, "current price exceeds max price");

        inputCurrency.safeTransferFrom(msg.sender, address(this), currentPrice);

        // initiate distribution of Cards via chainlink
        bytes32 requestId = getRandomNumber();
        // gets decremented in fulfillRandomness
        pendingSpins = pendingSpins + 1;
        request2address[requestId] = msg.sender;

        emit LootCratePurchased(msg.sender, priceInMatic, currentPrice);
    }

    /// Internal callback to retrieve a random number from chainlink
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

        return requestRandomness(keyHash, fee);
    }

    /// Internal function called from chainlink to finalize the random Card distribution
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // defensively decrement number of pending (which gets incremented in buyThreeRandomCards)

        pendingSpins = pendingSpins == 0
            ? 0
            : pendingSpins - 1;

        if (packs.length == 0)
            return;

        address requester = request2address[requestId];
        delete request2address[requestId];

        uint256 idx = randomness % packs.length;

        userPurchasesMap[requester].push(packs[idx].permPackIdx);
        purchases.push(packs[idx].permPackIdx);

        removePack(idx);
    }

    /// Remove a pack at index from list of packs
    function removePack(uint256 idx) internal {
        // replace pack and removed idx with last
        packs[idx] = packs[packs.length - 1];
        // remove the last pack list entry
        packs.pop();
    }

    /// withdraw the users pending packs they need to claim. numPacks = 0, means withdraw all.
    function withdrawPacks(address customerAddress, uint256 numPacks) external nonReentrant {
        uint256 pendingWithdrawals = getNumberOfPendingUserWithdraws(customerAddress);
        require(pendingWithdrawals > 0, "user currently has no purchases!");

        if (numPacks == 0 || numPacks > pendingWithdrawals)
            numPacks = pendingWithdrawals;

        uint256[] storage permPackIdxs = userPurchasesMap[customerAddress];

        // we claim from 0 idx upwards.
        uint256 i = userClaimedCountMap[customerAddress];

        for (;i<userClaimedCountMap[customerAddress] + numPacks;i++) {
            Pack storage pack = permPacks[permPackIdxs[i]];

            sendCard(customerAddress, pack.card1);
            sendCard(customerAddress, pack.card2);
            sendCard(customerAddress, pack.card3);

            emit PackPurchaseComplete(pack.permPackIdx, customerAddress);
        }

        userClaimedCountMap[customerAddress] = i;
    }

    /// Update TWAP-tracked price, with spot price as lower bound
    function getCurrentPriceInInputCurrency() internal returns (uint256) {
        (, , uint256 pairLastUpdated) = inputCurrencyLiqPool.getReserves();

        uint256 timeDelta;
        unchecked {
            timeDelta = pairLastUpdated - priceLastUpdated;
        }

        if (timeDelta > 0) {

            // retrieve the most recently stored price accumulation from pair
            uint256 cumulativeLast = address(inputCurrency) == inputCurrencyLiqPool.token0()
                ? inputCurrencyLiqPool.price1CumulativeLast()
                : inputCurrencyLiqPool.price0CumulativeLast();

            // below check handles overflow of cumulative price in pair
            if (cumulativeLast > cumulativePrice) {
                // convert price in matic to price in inputCurrency (and remove 2 ** 112 scaling)
                uint256 price = priceInMatic * (cumulativeLast - cumulativePrice) / timeDelta / FP112;

                // weighted sum of cached price and incoming new price
                smoothedPackPrice = (price * (100 - smoothingPercent) + smoothedPackPrice * smoothingPercent) / 100;
            }

            // update local sstate
            cumulativePrice = cumulativeLast;
            priceLastUpdated = pairLastUpdated;
        }

        uint256 spotPrice = getSpotPriceInInputCurrency();
        if (spotPrice > smoothedPackPrice) {
            smoothedPackPrice = spotPrice;
        }

        return smoothedPackPrice;
    }

    /// Spot price is current ratio of reserves in token pair
    function getSpotPriceInInputCurrency() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) =
                inputCurrencyLiqPool.getReserves();

        return inputCurrencyLiqPool.token0() == address(inputCurrency)
            ? priceInMatic * reserve0 / reserve1
            : priceInMatic * reserve1 / reserve0;
    }

    //////////////////////// Below are onlyOwner functions ////////////////////////

    /// withdraw inputCurrency earnings
    function withdrawAccumulatedFunds(address recipient) external onlyOwner {

        emit OwnersInputCurrencyWithdrawn(recipient, inputCurrency.balanceOf(address(this)));
        inputCurrency.safeTransfer(recipient, inputCurrency.balanceOf(address(this)));
    }

    /// Set smoothing factor
    function setSmoothingPercent(uint256 smoothing) external onlyOwner {
        require(100 > smoothing, "It's a percentage");
        smoothingPercent = smoothing;
    }

    function initCard(uint8 idx, address[] memory contractAddressArr, uint256[] memory amountOrIDArr,  bool[] memory isNFTArr,  bool[] memory isRareArr) internal returns (Card memory){
        Card memory card;
        card.cardId = cardIdCount;
        cardIdCount++;
        card.contractAddress =  contractAddressArr[idx];
        require(isNFTArr[idx] || !isNFTArr[idx] && amountOrIDArr[idx] > 0, "empty erc20 card");
        card.amountOrID = amountOrIDArr[idx];
        card.isNFT = isNFTArr[idx];
        card.isRare = isRareArr[idx];

        return card;
    }

    /// Add new pack to the contract
    function addPack(address sender, address[] calldata contractAddressArr, uint256[] calldata amountOrIDArr,  bool[] calldata isNFTArr,  bool[] calldata isRareArr) external nonReentrant onlyOwner {
        require(contractAddressArr.length == 3, "!length");
        require(contractAddressArr.length == amountOrIDArr.length, "!length");
        require(amountOrIDArr.length == isNFTArr.length, "!length");
        require(isNFTArr.length == isRareArr.length, "!length");
        require(sender != address(0), "bad sender address");

        Card memory card1;
        card1 = initCard(0, contractAddressArr, amountOrIDArr, isNFTArr, isRareArr);

        Card memory card2;
        card2 = initCard(1, contractAddressArr, amountOrIDArr, isNFTArr, isRareArr);

        Card memory card3;
        card3 = initCard(2, contractAddressArr, amountOrIDArr, isNFTArr, isRareArr);

        card1.amountOrID = bringInCard(sender, card1);
        card2.amountOrID = bringInCard(sender, card2);
        card3.amountOrID = bringInCard(sender, card3);

        packs.push(Pack(permPacks.length, card1, card2, card3));
        permPacks.push(Pack(permPacks.length, card1, card2, card3));

        emit PackAddedByOwner(permPacks.length - 1);
    }

    function sendCard(address customerAddress, Card storage card) internal {
        if (!card.isNFT)
            IERC20(card.contractAddress).safeTransfer(customerAddress, card.amountOrID);
        else
            IERC721(card.contractAddress).transferFrom(address(this), customerAddress, card.amountOrID);

        emit CardDeliveredToBuyer(card.cardId, card.contractAddress, customerAddress, card.amountOrID, card.isNFT, card.isRare);
    }

    function bringInCard(address sender, Card memory card) internal returns (uint256) {
        if (!card.isNFT) {
            uint256 beforeBalance = IERC20(card.contractAddress).balanceOf(address(this));
            IERC20(card.contractAddress).safeTransferFrom(sender, address(this), card.amountOrID);

            return IERC20(card.contractAddress).balanceOf(address(this)) - beforeBalance;
        }

        IERC721(card.contractAddress).transferFrom(sender, address(this), card.amountOrID);
        return card.amountOrID;
    }

    /// Set the price, as expressed in matic
    function setPriceInMatic(uint256 p) external onlyOwner {
        priceInMatic = p;

        emit MaticPriceSet(priceInMatic);
    }
}