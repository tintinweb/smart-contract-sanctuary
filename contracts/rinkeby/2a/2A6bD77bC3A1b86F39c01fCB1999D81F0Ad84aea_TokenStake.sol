pragma solidity ^0.7.0;
import "./TokenFactory.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract TokenStake {
    using SafeMath for uint256;

    TokenFactory tokenFactory;
    IBEP20 iart;
    mapping(address => uint256) numberOfStaked;
    mapping(uint256 => address) stakeToAddress;
    mapping(uint256 => TokenStake) stakeIdToStake;
    mapping(address => uint256[]) rewardHistory;
    mapping(uint256 => uint256) accumulatedRewards;

    uint256 stakeCounter;
    uint256 public rewardCof = 10**16 * 3 * 10 * 50; // 15 IART per second
    uint256 public totalDistributed;
    address owner;
    bool stakingEnabled;
    uint256 totalStakedValue;
    uint256 stakeUpdateCounter;

    event Harvest(address sender, uint256 amount);
    event AddedStake(address sender, uint256 stakeId);
    event RemovedStake(address sender, uint256 stakeId);

    struct TokenStake {
        uint256 tokenId;
        uint256 startTime;
        uint256 stakeId;
        uint256 rewardCof;
        uint256 initialStartTime;
        uint256 tokenValue;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "ROWN");
        _;
    }

    constructor(
        address _owner,
        address styliart,
        address _tokenFactory
    ) {
        tokenFactory = TokenFactory(_tokenFactory);
        iart = IBEP20(styliart);
        stakingEnabled = true;
        owner = _owner;
    }

    function setBepAddress(address bep) external onlyOwner {
        iart = IBEP20(bep);
    }

    function withDraw() external onlyOwner {
        iart.transfer(msg.sender, iart.balanceOf(address(this)));
        msg.sender.transfer(address(this).balance);
    }

    function setRewardCof(uint256 cof) external onlyOwner {
        rewardCof = cof;
    }

    function withdrawToken(address bep20) external {
        require(msg.sender == owner, "NOWN");
        IBEP20 bep20 = IBEP20(bep20);
        bep20.transfer(owner, bep20.balanceOf(address(this)));
    }

    function addStake(uint256 tokenId) external {
        require(stakingEnabled == true, "NEABLD");
        require(tokenFactory.isSuper(tokenId) == true, "NSPR");
        tokenFactory.transferFrom(msg.sender, address(this), tokenId);

        uint256 _tokenValue = _valueOf(tokenId);
        totalStakedValue = totalStakedValue.add(_tokenValue);
        uint256 _reward = getCurrentInterestRate(_tokenValue);

        TokenStake memory _tokenStake =
            TokenStake(
                tokenId,
                block.timestamp,
                stakeCounter,
                _reward,
                block.timestamp,
                _tokenValue
            );
        stakeToAddress[stakeCounter] = msg.sender;
        stakeIdToStake[stakeCounter] = _tokenStake;
        emit AddedStake(msg.sender, stakeCounter);
        stakeCounter++;
        numberOfStaked[msg.sender]++;
        updateRates();
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 stakeId) external {
        require(stakeToAddress[stakeId] == msg.sender, "NOWN");

        TokenStake memory _tokenStake = stakeIdToStake[stakeId];

        tokenFactory.transferFrom(
            address(this),
            msg.sender,
            _tokenStake.tokenId
        );

        _tokenStake.startTime = block.timestamp;
        stakeIdToStake[stakeId] = _tokenStake;

        delete stakeToAddress[_tokenStake.stakeId];

        numberOfStaked[msg.sender] = numberOfStaked[msg.sender].sub(1);
        stakeCounter = stakeCounter.sub(1);
        totalStakedValue = totalStakedValue.sub(_tokenStake.tokenValue);
    }

    function _valueOf(uint256 tokenId) internal view returns (uint256) {
        (, , , , , uint256 value) = tokenFactory.counterToToken(tokenId);
        return value;
    }

    function removeStake(uint256 stakeId) external {
        require(stakeToAddress[stakeId] == msg.sender, "NOWN");

        TokenStake memory _tokenStake = stakeIdToStake[stakeId];

        uint256 reward =
            calculateReward(
                _tokenStake.startTime,
                _tokenStake.rewardCof,
                stakeId
            );
        accumulatedRewards[stakeId] = 0;

        require(iart.balanceOf(address(this)) >= reward, "FUND");
        iart.transfer(msg.sender, reward);
        emit Harvest(msg.sender, reward);
        totalDistributed += reward;

        tokenFactory.transferFrom(
            address(this),
            msg.sender,
            _tokenStake.tokenId
        );

        _tokenStake.startTime = block.timestamp;
        stakeIdToStake[stakeId] = _tokenStake;

        delete stakeToAddress[_tokenStake.stakeId];

        numberOfStaked[msg.sender] = numberOfStaked[msg.sender].sub(1);
        stakeCounter = stakeCounter.sub(1);
        totalStakedValue = totalStakedValue.sub(_tokenStake.tokenValue);
        emit RemovedStake(msg.sender, stakeId);
        emit Harvest(msg.sender, reward);
        updateRates();
    }

    function refundAllStakes() external onlyOwner {
        for (uint256 i = 0; i < stakeCounter; i++) {
            TokenStake memory stake = stakeIdToStake[i];
            if (
                tokenFactory.ownerOf(stake.tokenId) == address(this) &&
                stakeToAddress[i] != address(0)
            ) {
                tokenFactory.transferFrom(
                    address(this),
                    stakeToAddress[i],
                    stake.tokenId
                );
            }
        }
    }

    function setStakingEnabled(bool _enabled) external onlyOwner {
        stakingEnabled = _enabled;
    }

    function getStakes()
        public
        view
        returns (
            uint256[] memory tokenId,
            uint256[] memory startTime,
            uint256[] memory stakeId,
            uint256[] memory currentReward
        )
    {
        uint256 count = numberOfStaked[msg.sender];
        tokenId = new uint256[](count);
        startTime = new uint256[](count);
        stakeId = new uint256[](count);
        currentReward = new uint256[](count);

        uint256 _counter = 0;

        for (uint256 i = 0; i < stakeCounter; i++) {
            if (stakeToAddress[i] == msg.sender) {
                tokenId[_counter] = stakeIdToStake[i].tokenId;
                startTime[_counter] = stakeIdToStake[i].startTime;
                stakeId[_counter] = stakeIdToStake[i].stakeId;
                currentReward[_counter] = calculateReward(
                    stakeIdToStake[i].startTime,
                    stakeIdToStake[i].rewardCof,
                    i
                );

                _counter++;
            }
        }

        return (tokenId, startTime, stakeId, currentReward);
    }

    function getCurrentInterestRate(uint256 value)
        public
        view
        returns (uint256)
    {
        return rewardCof.mul(value).div(totalStakedValue);
        // (0.03 * 100 / 1000) * seconds
    }

    function calculateReward(
        uint256 startTime,
        uint256 _reward,
        uint256 stakeId
    ) public view returns (uint256) {
        uint256 time = block.timestamp - startTime;
        if (time > 30 days) {
            time = 30 days;
        }
        return time.mul(_reward).add(accumulatedRewards[stakeId]); // time *  (0.03 * 100 / 1000)
    }

    function updateAllRates() public {
        // VERY HIGH TRANSACTION COST
        for (uint256 i = 0; i < stakeCounter; i++) {
            if (stakeToAddress[i] != address(0)) {
                TokenStake memory stake = stakeIdToStake[i];
                accumulatedRewards[i] = calculateReward(
                    stake.startTime,
                    stake.rewardCof,
                    i
                );

                stake.rewardCof = getCurrentInterestRate(stake.tokenValue);
                stake.startTime = block.timestamp;
                stakeIdToStake[i] = stake;
            }
        }
    }

    function updateRates() public {
        uint256 startingValue = stakeUpdateCounter;
        uint256 interestRate = getCurrentInterestRate(1);
        for (uint256 i = 0; i < 30; i++) {
            if (stakeToAddress[stakeUpdateCounter] != address(0)) {
                TokenStake memory stake = stakeIdToStake[stakeUpdateCounter];
                accumulatedRewards[stakeUpdateCounter] = calculateReward(
                    stake.startTime,
                    stake.rewardCof,
                    stakeUpdateCounter
                );
                stake.rewardCof = interestRate.mul(stake.tokenValue);
                stake.startTime = block.timestamp;
                stakeIdToStake[stakeUpdateCounter] = stake;
            }

            stakeUpdateCounter += 1;
            if (stakeUpdateCounter == stakeCounter) stakeUpdateCounter = 0;
            if (stakeUpdateCounter == startingValue && i != 0) break;
        }
    }

    function claimRewards() external returns (bool) {
        (, , uint256[] memory stakeId, uint256[] memory currentReward) =
            getStakes();

        uint256 reward = 0;
        for (uint256 i = 0; i < stakeId.length; i++) {
            accumulatedRewards[stakeId[i]] = 0;
            stakeIdToStake[stakeId[i]].startTime = block.timestamp;
            stakeIdToStake[stakeId[i]].rewardCof = getCurrentInterestRate(
                stakeIdToStake[stakeId[i]].tokenValue
            );
            reward = reward.add(currentReward[i]);
        }

        require(iart.balanceOf(address(this)) >= reward, "FUND");
        iart.transfer(msg.sender, reward);
        totalDistributed += reward;

        updateRates();

        emit Harvest(msg.sender, reward);
        return true;
    }
}

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "./StockManager.sol";

contract TokenFactory is IERC721, ERC165, IERC721Enumerable {
    // Safe math implementation
    using SafeMath for uint256;

    // Helpful modifiers
    modifier onlyOwner {
        require(msg.sender == _contractOwner);
        _;
    }

    modifier requireValue(uint256 cost) {
        require(msg.value >= cost, "Not enough balance"); // Check if balance is enough
        if (msg.value > cost) {
            msg.sender.transfer(msg.value.sub(cost)); // Refund if extra
        }
        _;
    }

    modifier packStock(uint256 packId) {
        require(stockManager.availableStock(packId), "Out of stock");
        _;
    }
    // Events
    event MergeEvent(
        address indexed owner,
        uint256 indexed imageId,
        uint256 indexed styleId,
        uint256 tokenId
    );
    event SplitEvent(
        address indexed sender,
        uint256 id,
        uint256 indexed imageId,
        uint256 indexed styleId,
        uint256 tokenId
    );
    event BuyEvent(address indexed sender, uint256 packId);

    address private _contractOwner;
    uint256 public tokenCounter;
    StockManager stockManager;

    // Important
    uint256 SEPERATION_COST = 0.001 ether; // Style-Image seperation cost

    enum TokenType {IMAGE_TOKEN, STYLE_TOKEN, SUPER_TOKEN}

    // Token structs
    struct SuperTkn {
        uint256 counterId;
        uint256 imageId;
        uint256 styleId;
        TokenType tokenType;
        uint256 root;
        uint256 value;
    }

    struct SuperData {
        uint256 icid;
        uint256 scid;
        uint256 iroot;
        uint256 sroot;
    }

    mapping(uint256 => address) private counterToAddress;
    mapping(address => uint256) public numberOfTokensOwned; // Number of tokens owned by user, for loop purposes
    mapping(bytes32 => address) private requestIdToSender;
    mapping(uint256 => SuperTkn) public counterToToken;
    mapping(uint256 => SuperData) public superToRoot;
    mapping(uint256 => uint256) public painterIdToPrice;
    mapping(uint256 => uint256) public counterToPainter;

    // ERC721
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private styliApprovals;

    // Constructor
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    string private _baseURI;

    constructor() {
        _contractOwner = msg.sender;
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function _setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */

    modifier requireOwnership(uint256 tokenId) {
        require(
            counterToAddress[tokenId] == msg.sender,
            "You are not the owner"
        );
        _;
    }

    function _isApprovedOrOwner(uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(tokenCounter > tokenId, "NXN");
        address owner = counterToAddress[tokenId];
        return (msg.sender == owner ||
            styliApprovals[tokenId] == msg.sender ||
            isApprovedForAll(owner, msg.sender));
    }

    function getApproved(uint256 tokenId)
        external
        view
        virtual
        override
        returns (address operator)
    {
        require(tokenCounter > tokenId, "NONEXST");
        return styliApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != msg.sender, "ERC721:ATC");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(tokenCounter > tokenId, "NONEXST");
        string memory base = baseURI();
        return string(abi.encodePacked(base, uint2str(tokenId)));
    }

    function setPainter(uint256 index, uint256 price) external onlyOwner {
        painterIdToPrice[index] = price;
    }

    function name() external view returns (string memory _name) {
        return "StyliArt";
    }

    function symbol() external view returns (string memory _symbol) {
        return "STYLIART";
    }

    function totalSupply() external view override returns (uint256) {
        return tokenCounter;
    }

    function tokenByIndex(uint256 index)
        external
        view
        override
        returns (uint256)
    {
        require(tokenCounter > index, "NXN");
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        override
        returns (uint256 tokenId)
    {
        uint256[] memory owned = getPacksByOwner(owner);
        return owned[index];
    }

    function setAddress(address _stockManager) external onlyOwner {
        if (_stockManager != address(0)) {
            stockManager = StockManager(_stockManager);
        }
    }

    function getAddrStockManager() external view returns (address) {
        return address(stockManager);
    }

    function _transferInternal(
        address _from,
        address _to,
        uint256 tokenId
    ) internal {
        counterToAddress[tokenId] = _to;
        numberOfTokensOwned[_from] = numberOfTokensOwned[_from].sub(1);
        numberOfTokensOwned[_to] = numberOfTokensOwned[_to].add(1);
        emit Transfer(_from, _to, tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 tokenId
    ) external virtual override {
        require(_isApprovedOrOwner(tokenId), "NBN");
        _transferInternal(_from, _to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(tokenId), "NBN");
        _transferInternal(from, to, tokenId);
        require(counterToAddress[tokenId] == to);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        require(_isApprovedOrOwner(tokenId), "NBN");
        _transferInternal(from, to, tokenId);
        require(counterToAddress[tokenId] == to);
    }

    function approve(address _approved, uint256 _tokenId)
        external
        override
        requireOwnership(_tokenId)
    {
        styliApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function getPacksByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory owned = new uint256[](numberOfTokensOwned[_owner]);
        uint256 counter = 0;
        for (uint256 i = 0; i < tokenCounter; i++) {
            if (counterToAddress[i] == _owner) {
                owned[counter] = i;
                counter += 1;
            }
        }
        return owned;
    }

    function middleRand(uint256 max, uint256 salt)
        internal
        view
        returns (uint256)
    {
        uint256 number = 0;
        for (uint256 i = 0; i < 10; i++) {
            number += ((rand(salt) % 100000001) * max) / 10;
        }
        return number / 100000000;
    }

    function rand(uint256 salt) internal view returns (uint256) {
        uint256 seed =
            uint256(
                keccak256(
                    abi.encodePacked(
                        salt +
                            block.timestamp +
                            block.difficulty +
                            ((
                                uint256(
                                    keccak256(abi.encodePacked(block.coinbase))
                                )
                            ) / (block.timestamp)) +
                            block.gaslimit +
                            ((
                                uint256(keccak256(abi.encodePacked(msg.sender)))
                            ) / (block.timestamp)) +
                            block.number
                    )
                )
            );

        return seed;
    }

    function getPayment(uint256 packId) internal returns (bool) {
        address paymentType = stockManager.paymentType(packId);
        uint256 cost = stockManager.getPriceOf(packId);

        if (paymentType == address(0)) {
            require(msg.value >= cost, "Not enough balance"); // Check if balance is enough
            if (msg.value > cost) {
                msg.sender.transfer(msg.value.sub(cost)); // Refund if extra
            }
        } else {
            IBEP20 bep20token = IBEP20(paymentType);
            require(
                bep20token.allowance(msg.sender, address(this)) >= cost,
                "NALW"
            );
            bep20token.transferFrom(msg.sender, address(this), cost);
        }
        return true;
    }

    function buyPack(uint256 packId) external payable packStock(packId) {
        bool done = getPayment(packId);
        require(done == true, "NPN");
        uint256 typeOfToken = stockManager.getTypeOf(packId);
        TokenType matokentype;

        for (uint8 i = 0; i < stockManager.getNumberOfOut(packId); i++) {
            uint256 styleId = 0;
            uint256 imageId = 0;
            uint256 currentIdOfType = stockManager.getCurrentCounterOf(packId);
            bool sonuc = stockManager.increaseCounter(packId);
            require(sonuc);

            if (typeOfToken == 0) {
                imageId = currentIdOfType;
                matokentype = TokenType.IMAGE_TOKEN;
            } else {
                styleId = currentIdOfType;
                matokentype = TokenType.STYLE_TOKEN;
            }

            (uint256 min, uint256 max) = stockManager.packToBoundaries(packId);

            uint256 value = middleRand(max - min, i) + min;

            SuperTkn memory tkn =
                SuperTkn(
                    tokenCounter,
                    imageId,
                    styleId,
                    matokentype,
                    packId,
                    value
                );

            _mintToken(msg.sender, tkn);
        }

        emit BuyEvent(msg.sender, packId);
    }

    // @ Seperate
    // Seperates Supertoken => ImageToken, StyleToken
    function separate(uint256 id)
        external
        payable
        requireOwnership(id)
        requireValue(SEPERATION_COST)
        returns (uint256, uint256)
    {
        SuperTkn memory token = counterToToken[id];
        require(token.tokenType == TokenType.SUPER_TOKEN);

        SuperData memory data = superToRoot[id];

        numberOfTokensOwned[msg.sender] = numberOfTokensOwned[msg.sender].add(
            2
        );
        counterToAddress[data.icid] = msg.sender;
        counterToAddress[data.scid] = msg.sender;

        emit Transfer(address(0), msg.sender, data.icid);
        emit Transfer(address(0), msg.sender, data.scid);

        _burnToken(msg.sender, id);

        emit SplitEvent(msg.sender, id, data.icid, data.scid, id);

        return (data.icid, data.scid);
    }

    // Mint Token
    function _mintToken(address _from, SuperTkn memory token)
        internal
        returns (uint256)
    {
        uint256 _tokenId = tokenCounter;
        token.counterId = _tokenId;
        require(counterToAddress[_tokenId] == address(0)); // Address 0 check
        counterToAddress[_tokenId] = _from;
        counterToToken[_tokenId] = token;
        numberOfTokensOwned[_from] = numberOfTokensOwned[_from].add(1);
        tokenCounter = tokenCounter.add(1);
        emit Transfer(address(0), _from, _tokenId);
        return _tokenId;
    }

    // Burn Token
    function _burnToken(address _from, uint256 _tokenId) internal {
        numberOfTokensOwned[_from] = numberOfTokensOwned[_from].sub(1);
        delete counterToAddress[_tokenId];
    }

    // @ Merge
    // Merges ImageToken, StyleToken => Supertoken
    function merge(
        uint256 imageId,
        uint256 styleId,
        uint256 painterId
    )
        external
        payable
        requireOwnership(imageId)
        requireOwnership(styleId)
        requireValue(painterIdToPrice[painterId])
        returns (uint256)
    {
        // Generate new merged token
        require(painterIdToPrice[painterId] != 0, "HMNS");
        SuperTkn memory _imageToken = counterToToken[imageId];
        SuperTkn memory _styleToken = counterToToken[styleId];
        require(_imageToken.imageId != 0, "0X1");
        require(_styleToken.styleId != 0, "0X2");
        // Mint new token
        uint256 value = _imageToken.value + _styleToken.value;
        SuperTkn memory _merged =
            SuperTkn(
                0,
                _imageToken.imageId,
                _styleToken.styleId,
                TokenType.SUPER_TOKEN,
                0,
                value
            );

        uint256 _id = _mintToken(msg.sender, _merged);
        superToRoot[_id] = SuperData(
            imageId,
            styleId,
            _imageToken.root,
            _styleToken.root
        );
        counterToPainter[_id] = painterId;

        // update imagetoken and styletoken
        _burnToken(msg.sender, imageId);
        _burnToken(msg.sender, styleId);

        emit MergeEvent(msg.sender, imageId, styleId, _id);
        return _id;
    }

    // Withdraws current balance
    function withdraw() external onlyOwner {
        address payable _owner = address(uint160(_contractOwner));
        _owner.transfer(address(this).balance);
    }

    function withdrawToken(address erc20) external onlyOwner {
        IBEP20 bep20 = IBEP20(erc20);
        bep20.transfer(_contractOwner, bep20.balanceOf(address(this)));
    }

    // Balance of
    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        return numberOfTokensOwned[_owner];
    }

    function isSuper(uint256 token) external view returns (bool) {
        if (counterToToken[token].tokenType == TokenType.SUPER_TOKEN) {
            return true;
        } else {
            return false;
        }
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        virtual
        override
        returns (address)
    {
        return counterToAddress[_tokenId];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.7.0;
import "@openzeppelin/contracts/introspection/ERC165.sol";

interface ERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
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

pragma solidity ^0.7.0;

contract StockManager {
    mapping(uint256 => uint256) maxStock;
    mapping(uint256 => uint256) currentCounter;
    mapping(uint256 => uint256) price;
    mapping(uint256 => uint256) numberOfOut;
    mapping(uint256 => uint256) idToType; // 0 or 1
    mapping(uint256 => bool) packExists;
    mapping(uint256 => address) public paymentType;
    mapping(uint256 => bool) packAvailable;
    mapping(uint256 => Boundaries) public packToBoundaries;

    struct Boundaries {
        uint256 min;
        uint256 max;
    }

    uint256 packIdCounter;

    address private owner;
    address private father;

    event PackCreated(
        uint256 packId,
        uint256 maxStock,
        uint256 packType,
        uint256 price,
        uint256 min,
        uint256 max
    );

    constructor(address _owner, address _tokenFactory) {
        owner = _owner;
        father = _tokenFactory;
        packIdCounter = 1;
    }

    modifier requireFather() {
        require(msg.sender == father, "NFN");
        _;
    }

    modifier requireOwner() {
        require(msg.sender == owner, "NWN");
        _;
    }

    modifier requireExists(uint256 packId) {
        require(packExists[packId], "NEXST");
        _;
    }

    modifier requireAvailable(uint256 packId) {
        require(packAvailable[packId], "NAVLB");
        _;
    }

    function getAvailablePacks() external view returns (uint256[] memory) {
        uint256[] memory available = new uint256[](packIdCounter);
        uint256 z = 0;
        for (uint256 i = 0; i < packIdCounter; i++) {
            if (packAvailable[i]) {
                available[z] = i;
                z = z + 1;
            }
        }
        return available;
    }

    function getPackInfoByAddresses(uint256[] calldata idList)
        external
        view
        returns (
            uint256[] memory _list_maxStock,
            uint256[] memory _list_currentCounter,
            uint256[] memory _list_price,
            uint256[] memory _list_numberOut,
            uint256[] memory _list_type
        )
    {
        _list_maxStock = new uint256[](idList.length);
        _list_currentCounter = new uint256[](idList.length);
        _list_price = new uint256[](idList.length);
        _list_numberOut = new uint256[](idList.length);
        _list_type = new uint256[](idList.length);

        for (uint256 i = 0; i < idList.length; i++) {
            _list_maxStock[i] = maxStock[idList[i]];
            _list_currentCounter[i] = currentCounter[idList[i]];
            _list_price[i] = price[idList[i]];
            _list_numberOut[i] = numberOfOut[idList[i]];
            _list_type[i] = idToType[idList[i]];
        }

        return (
            _list_maxStock,
            _list_currentCounter,
            _list_price,
            _list_numberOut,
            _list_type
        );
    }

    function createPack(
        uint256 _maxStock,
        uint256 _numberOut,
        uint256 _type,
        uint256 _price,
        uint256 _min,
        uint256 _max,
        address _paymentType
    ) external requireOwner {
        uint256 _id = packIdCounter;
        packExists[_id] = true;
        maxStock[_id] = _maxStock;
        packAvailable[_id] = true;
        idToType[_id] = _type;
        numberOfOut[_id] = _numberOut;
        price[_id] = _price;
        currentCounter[_id] = 1;
        paymentType[_id] = _paymentType;
        packToBoundaries[_id] = Boundaries(_min, _max);
        emit PackCreated(packIdCounter, _maxStock, _type, _price, _min, _max);
        packIdCounter = packIdCounter + 1;
    }

    function getTypeOf(uint256 id)
        external
        view
        requireExists(id)
        returns (uint256)
    {
        return idToType[id];
    }

    function getMaxStockOf(uint256 id)
        external
        view
        requireExists(id)
        returns (uint256)
    {
        return maxStock[id];
    }

    function getCurrentCounterOf(uint256 id)
        external
        view
        requireExists(id)
        returns (uint256)
    {
        return currentCounter[id];
    }

    function getPriceOf(uint256 id)
        external
        view
        requireExists(id)
        returns (uint256)
    {
        return price[id];
    }

    function getNumberOfOut(uint256 id)
        external
        view
        requireExists(id)
        returns (uint256)
    {
        return numberOfOut[id];
    }

    function setPriceOf(uint256 id, uint256 _price)
        external
        requireExists(id)
        requireOwner
    {
        price[id] = _price;
    }

    function setMaxMin(
        uint256 _id,
        uint256 _min,
        uint256 _max
    ) external requireExists(_id) requireOwner {
        packToBoundaries[_id] = Boundaries(_min, _max);
    }

    function setPaymentTypeOf(uint256 id, address _paymentType)
        external
        requireExists(id)
        requireOwner
    {
        paymentType[id] = _paymentType;
    }

    function setMaxStockOf(uint256 id, uint256 max)
        external
        requireExists(id)
        requireOwner
    {
        maxStock[id] = max;
    }

    function setNumberOutOf(uint256 id, uint256 _numberof)
        external
        requireExists(id)
        requireOwner
    {
        numberOfOut[id] = _numberof;
    }

    function setTypeOf(uint256 id, uint256 _type)
        external
        requireExists(id)
        requireOwner
    {
        idToType[id] = _type % 2;
    }

    function setAvailableOf(uint256 id, bool _avab)
        external
        requireExists(id)
        requireOwner
    {
        packAvailable[id] = _avab;
    }

    function increaseCounter(uint256 id)
        external
        requireFather
        requireExists(id)
        requireAvailable(id)
        returns (bool)
    {
        currentCounter[id] = currentCounter[id] + 1;
        return true;
    }

    function availableStock(uint256 id)
        external
        view
        requireExists(id)
        returns (bool)
    {
        uint256 max = maxStock[id];
        uint256 current = currentCounter[id];
        uint256 included = numberOfOut[id];
        if (current - 1 + included <= max) return true;
        return false;
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

