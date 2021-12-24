//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Lottery
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';

import './Whitelistable.sol';
import './ERC1155DataStorage.sol';
import './StakingAddble.sol';

interface ITokenConverter {
    function convertTwo(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) external view returns (uint256);

    function convertChained(address[] memory _tokens, uint256 _amount)
        external
        view
        returns (uint256 amt);
}

contract Lottery is Whitelistable, ERC1155Holder {
    struct Drop {
        uint256 id;
        uint256 amount;
        ERC1155DataStorage nft;
        address[] stakings;
        uint256 amountOfTickets;
        uint256 priceInBase;
        uint256 tookTickets;
        DropStatus status;
        uint256 period;
        uint256 startTimestamp;
        uint256 endTimestamp;
        address[] users;
        address[] winners;
        mapping(address => uint256) winnedTokens;
        mapping(address => bool) played;
        mapping(address => bool) claimed;
        mapping(address => uint256) ticketsAmount;
        mapping(address => bool) legalTokens;
        mapping(address => address) baseTokens;
        address[] legalTokensArray;
        mapping(uint256 => address) ticketsToUser;
        mapping(address => uint256) nftPrices;
        mapping(address => uint256) prices;
    }

    mapping(address => uint256) public extraTickets;
    mapping(uint256 => mapping(address => uint256)) public deposited;
    mapping(uint256 => mapping(address => uint256)) public stakedSlotsInDrop;

    struct User {
        uint256 deposit;
        uint256 release;
    }

    enum DropStatus {
        PENDING,
        STARTED,
        STOPPED
    }

    enum UserStatus {
        PENDING,
        WON,
        LOST
    }

    address public platformWallet;
    uint256 public stakedPeriod = 48 hours;

    ITokenConverter public tokenConverter =
        ITokenConverter(0xe2bf8ef5E2b24441d5B2649A3Dc6D81afC1a9517);

    address public BUSD;

    IERC20 public token;

    uint256 public dropCounter;
    mapping(uint256 => Drop) public drops;
    mapping(address => User) public users;

    event DropCreated(address indexed sender, uint256 dropId);
    event DropStarted(address indexed sender, uint256 dropId);
    event DropClosed(address indexed sender, uint256 dropId);
    event UserPlayed(address indexed sender, uint256 dropId);
    event UserClaimed(address indexed sender, uint256 dropId, uint256 id, uint256 amount);

    event PlatformWalletChanged(address indexed sender, address platformWallet_);
    event StakedPeriodChanged(address indexed sender, uint256 stakedPeriod_);

    constructor(
        IERC20 token_,
        address owner_,
        address platformWallet_,
        address busd
    ) {
        platformWallet = platformWallet_;
        token = token_;
        transferOwnership(owner_);
        BUSD = busd;
    }

    // admin functions

    struct Pair {
        address token;
        address baseCurrency;
        uint256 nftPrice;
        uint256 price;
    }

    /// @dev creates nft and drop simultaneously
    function createDropWithNFT(
        ERC1155DataStorage nft,
        string memory uri,
        ERC1155DataStorage.Data memory data_,
        uint256 amount,
        address[] memory stakings,
        uint256 priceInBase,
        Pair[] memory legalTokens,
        uint256 amountOfTickets,
        uint256 period
    ) external onlyWhitelist {
        uint256 id = nft.create(uri, data_);
        nft.mint(address(this), id, amount);

        createDrop(
            nft,
            id,
            amount,
            stakings,
            priceInBase,
            legalTokens,
            amountOfTickets,
            period
        );
    }

    /// @dev ADMIN ONLY: creates new drop
    function createDrop(
        ERC1155DataStorage nft,
        uint256 id,
        uint256 amount,
        address[] memory stakings,
        uint256 priceInBase,
        Pair[] memory legalTokens,
        uint256 amountOfTickets,
        uint256 period
    ) public onlyWhitelist {
        require(
            priceInBase != 0 && amountOfTickets != 0 && period != 0,
            'Cannot input zero values'
        );

        uint256 dropId = dropCounter;
        dropCounter++;

        Drop storage drop = drops[dropId];

        drop.id = id;
        drop.amount = amount;
        drop.stakings = stakings;
        drop.priceInBase = priceInBase;
        drop.amountOfTickets = amountOfTickets;
        drop.status = DropStatus.PENDING;
        drop.period = period;
        drop.nft = nft;

        uint256 length = legalTokens.length;
        for (uint256 i = 0; i < length; i++) {
            drop.legalTokensArray.push(legalTokens[i].token);
            drop.legalTokens[legalTokens[i].token] = true;
            drop.baseTokens[legalTokens[i].token] = legalTokens[i].baseCurrency;
            drop.nftPrices[legalTokens[i].token] = legalTokens[i].nftPrice;
            drop.prices[legalTokens[i].token] = legalTokens[i].price;
        }

        emit DropCreated(msg.sender, dropId);
    }

    struct ExtraTicket {
        address user;
        uint256 tickets;
    }

    /// @dev ADMIN ONLY: starts drop with `dropId`
    function openLottery(uint256 dropId) public onlyWhitelist {
        Drop storage drop = drops[dropId];
        require(
            drop.status == DropStatus.PENDING,
            'Lottery does not exist or already lauched'
        );

        drop.startTimestamp = block.timestamp;
        drop.endTimestamp = block.timestamp + drop.period;

        drop.status = DropStatus.STARTED;

        emit DropStarted(msg.sender, dropId);
    }

    /// @dev sets extraTickets globaly
    function setExtraTickets(ExtraTicket[] memory extraTickets_) public onlyWhitelist {
        uint256 length = extraTickets_.length;
        for (uint256 i = 0; i < length; i++)
            extraTickets[extraTickets_[i].user] = extraTickets_[i].tickets;
    }

    /// @dev closes the drop, and sends nfts to the winners
    function closeLottery(uint256 dropId) external onlyWhitelist {
        Drop storage drop = drops[dropId];

        require(drop.endTimestamp != 0, 'Lottery does not exist');
        require(
            drop.endTimestamp <= block.timestamp ||
                drop.amountOfTickets == drop.tookTickets,
            'Lottery has not ended'
        );

        if (drop.users.length == 0) {
            drop.nft.safeTransferFrom(
                address(this),
                msg.sender,
                drop.id,
                drop.amount,
                ''
            );
            closeForceLottery(dropId);
            return;
        }

        returnDeposites(dropId);
        winProcess(dropId);
        closeForceLottery(dropId);
    }

    /// @dev return all deposites
    function returnDeposites(uint256 dropId) public onlyWhitelist {
        Drop storage drop = drops[dropId];
        uint256 amountOfUsers = drop.users.length;
        for (uint256 i = 0; i < amountOfUsers; i++) {
            deposited[wrapAddresses(drop.stakings)][drop.users[i]] -=
                stakedSlotsInDrop[dropId][drop.users[i]] *
                drop.priceInBase;
        }
    }

    /// @dev process wins
    function winProcess(uint256 dropId) public onlyWhitelist {
        Drop storage drop = drops[dropId];
        uint256 amount = drop.amount;

        for (uint256 i = 0; i < amount; i++) {
            address winner = drop.ticketsToUser[
                randomInt(1, drop.tookTickets, (i + 1) * i)
            ];
            drop.winnedTokens[winner] += 1;
        }
    }

    /// @dev close drop force
    function closeForceLottery(uint256 dropId) public onlyWhitelist {
        Drop storage drop = drops[dropId];
        drop.status = DropStatus.STOPPED;
        emit DropClosed(msg.sender, dropId);
    }

    /// @dev changes platformWallet
    function setPlatformWallet(address platformWallet_) external onlyOwner {
        platformWallet = platformWallet_;
        emit PlatformWalletChanged(msg.sender, platformWallet_);
    }

    /// @dev changes stakedPeriod
    function setStakedPeriod(uint256 stakedPeriod_) external onlyOwner {
        stakedPeriod = stakedPeriod_;
        emit StakedPeriodChanged(msg.sender, stakedPeriod_);
    }

    // // participate in lottery
    // uint256 public nextShitIndex;

    // function doALotOfShit(uint256 gasLimit) external {
    //     uint256 gasThreshold = gasleft() - gasLimit;
    //     for (uint256 i = nextShitIndex; i < lotOfShit.length; i++) {
    //         // FIRST check gas
    //         if (gasleft() < gasThreshold) {
    //             nextShitIndex = i;
    //             emit DidWeFinish(false); // For auto-continue if using worker
    //             return;
    //         }
    //         // SECOND do what is needed to be done
    //         // doShit()...
    //     }
    //     emit DidWeFinish(true);
    // }

    /// @dev adds user to participent in lottery
    function playLottery(uint256 dropId, uint256 ticketAmount) external {
        Drop storage drop = drops[dropId];
        require(drop.endTimestamp != 0, 'Lottery does not exist');
        require(drop.status == DropStatus.STARTED, 'Lottery has ended or not started');
        require(!drop.played[msg.sender], 'Can only play once');

        uint256 slots = maxTickets(dropId, msg.sender);

        slots = ticketAmount > slots ? slots : ticketAmount;

        require(slots > 0, 'Error: Not enough staked DES');

        uint256 stakedSlots = 0;

        if (extraTickets[msg.sender] != 0) {
            if (slots <= extraTickets[msg.sender]) {
                stakedSlots = 0;
                extraTickets[msg.sender] -= slots;
            } else {
                stakedSlots = slots - extraTickets[msg.sender];
                extraTickets[msg.sender] = 0;
            }
        }

        deposited[wrapAddresses(drops[dropId].stakings)][msg.sender] +=
            stakedSlots *
            drops[dropId].priceInBase;

        stakedSlotsInDrop[dropId][msg.sender] = stakedSlots;

        for (uint256 i = 0; i < slots; i++) {
            drop.ticketsToUser[i + drop.tookTickets] = msg.sender;
        }

        drop.ticketsAmount[msg.sender] = slots;
        drop.tookTickets += slots;
        drop.played[msg.sender] = true;
        drop.users.push(msg.sender);

        emit UserPlayed(msg.sender, dropId);
    }

    // TODO:
    function claimWin(uint256 dropId, IERC20 otherToken) external {
        Drop storage drop = drops[dropId];

        require(drop.played[msg.sender], 'Only lottery participants');

        uint256 winnedTokens = drop.winnedTokens[msg.sender];
        require(winnedTokens > 0, 'You didnt win the token');

        uint256 nftPriceInToken = winnedTokens * drop.nftPrices[address(otherToken)];
        uint256 priceInToken = drop.prices[address(otherToken)];

        require(
            otherToken.balanceOf(msg.sender) >= priceInToken + nftPriceInToken,
            'Not enough'
        );

        otherToken.transferFrom(
            msg.sender,
            address(this),
            priceInToken + nftPriceInToken
        );
        drop.nft.safeTransferFrom(address(this), msg.sender, drop.id, winnedTokens, '');

        drop.claimed[msg.sender] = true;
        emit UserClaimed(msg.sender, dropId, drop.id, winnedTokens);
    }

    // view functions
    function getTotalDeposit(address user, uint256 dropId)
        public
        view
        returns (uint256 ticketsAmount)
    {
        uint256 totalSum = sumStaking(user, drops[dropId].stakings);
        uint256 deposit = totalSum -
            deposited[wrapAddresses(drops[dropId].stakings)][user];
        if (
            deposit > 0 &&
            !drops[dropId].played[user] &&
            drops[dropId].amountOfTickets != 0
        ) return deposit;
        return 0;
    }

    function sumStaking(address user, address[] memory stakings)
        public
        view
        returns (uint256)
    {
        uint256 length = stakings.length;
        uint256 sum = 0;
        for (uint256 i = 0; i < length; i++) {
            StakingAddble staking = StakingAddble(stakings[i]);
            if ((block.timestamp - staking.getStake(user).startStaking) < stakedPeriod)
                continue;
            sum += staking.getStake(user).amount;
        }
        return sum;
    }

    function wrapAddresses(address[] memory addresses) public pure returns (uint256) {
        uint256 length = addresses.length;
        uint256 acc = 0;
        for (uint256 i = 0; i < length; i++) {
            acc += uint256(uint160(addresses[i]));
        }
        return acc;
    }

    function getStatus(address user, uint256 dropId)
        public
        view
        returns (UserStatus status)
    {
        Drop storage drop = drops[dropId];
        if (drop.status == DropStatus.STARTED) return UserStatus.PENDING;
        else if (drop.winnedTokens[user] > 0) return UserStatus.WON;
        else return UserStatus.LOST;
    }

    /// @dev returns max amount of tickets that user can claim
    function maxTickets(uint256 dropId, address user) public view returns (uint256) {
        Drop storage drop = drops[dropId];
        uint256 deposit = getTotalDeposit(user, dropId);
        uint256 slots = deposit / drops[dropId].priceInBase;
        uint256 total = slots + extraTickets[user];
        slots = total < drop.amountOfTickets - drop.tookTickets
            ? total
            : drop.amountOfTickets - drop.tookTickets;

        return slots;
    }

    // // util functions

    /// @dev creates random number from `from` include to `to` exclude with addition inforamation `salt`
    function randomInt(
        uint256 from,
        uint256 to,
        uint256 salt
    ) public view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, msg.sender, salt)
            )
        );
        return (randomNumber % (to - from)) + from;
    }

    // TODO:

    struct InfoUserDrop {
        uint256 dropId;
        uint256 id;
        uint256 amount;
        address[] stakings;
        UserStatus status;
        bool claimed;
        uint256 priceInBase;
        uint256 tickets;
        uint256 amountOfTickets;
        uint256 tookTickets;
        uint256 period;
        uint256 startTimestamp;
        uint256 endTimestamp;
        address nft;
        ERC1155DataStorage.Data data;
        string uri;
        uint256 winned;
    }

    function infoBundlerUserDrop(address user, uint256 dropId)
        public
        view
        returns (InfoUserDrop memory infoUserDrop)
    {
        Drop storage drop = drops[dropId];
        infoUserDrop.dropId = dropId;
        infoUserDrop.id = drop.id;
        infoUserDrop.amount = drop.amount;
        infoUserDrop.stakings = drop.stakings;
        infoUserDrop.status = getStatus(user, dropId);
        infoUserDrop.claimed = drop.claimed[user];
        infoUserDrop.priceInBase = drop.priceInBase;
        infoUserDrop.tickets = drop.ticketsAmount[user];
        infoUserDrop.amountOfTickets = drop.amountOfTickets;
        infoUserDrop.tookTickets = drop.tookTickets;
        infoUserDrop.period = drop.period;
        infoUserDrop.startTimestamp = drop.startTimestamp;
        infoUserDrop.endTimestamp = drop.endTimestamp;
        infoUserDrop.nft = address(drop.nft);
        infoUserDrop.data = drop.nft.data(drop.id);
        infoUserDrop.uri = drop.nft.uri(drop.id);
        infoUserDrop.winned = drop.winnedTokens[user];
    }

    function infoBundlerUser(address user)
        public
        view
        returns (InfoUserDrop[] memory infoUserDrops)
    {
        uint256 amount;

        for (uint256 dropId = 0; dropId < dropCounter; dropId++) {
            if (drops[dropId].played[user]) amount++;
        }

        InfoUserDrop[] memory infoUserDrops_ = new InfoUserDrop[](amount);
        amount = 0;

        for (uint256 dropId = 0; dropId < dropCounter; dropId++) {
            if (drops[dropId].played[user]) {
                infoUserDrops_[amount] = infoBundlerUserDrop(user, dropId);
                amount++;
            }
        }
        return infoUserDrops_;
    }

    struct InfoDrop {
        uint256 dropId;
        DropStatus status;
        uint256 id;
        uint256 amount;
        address nft;
        address[] stakings;
        uint256 priceInBase;
        uint256 amountOfTickets;
        uint256 tookTickets;
        uint256 period;
        uint256 startTimestamp;
        uint256 endTimestamp;
        ERC1155DataStorage.Data data;
        string uri;
        address[] legalTokens;
    }

    function infoBundlerDrop(uint256 dropId)
        public
        view
        returns (InfoDrop memory infoDrop)
    {
        Drop storage drop = drops[dropId];
        infoDrop.dropId = dropId;
        infoDrop.status = drop.status;
        infoDrop.id = drop.id;
        infoDrop.amount = drop.amount;
        infoDrop.nft = address(drop.nft);
        infoDrop.stakings = drop.stakings;
        infoDrop.priceInBase = drop.priceInBase;
        infoDrop.amountOfTickets = drop.amountOfTickets;
        infoDrop.tookTickets = drop.tookTickets;
        infoDrop.period = drop.period;
        infoDrop.startTimestamp = drop.startTimestamp;
        infoDrop.endTimestamp = drop.endTimestamp;
        infoDrop.data = drop.nft.data(drop.id);
        infoDrop.uri = drop.nft.uri(drop.id);
        infoDrop.legalTokens = drop.legalTokensArray;
    }

    function infoBundlerAll() external view returns (InfoDrop[] memory infoDrops) {
        InfoDrop[] memory infoDrops_ = new InfoDrop[](dropCounter);
        for (uint256 i = 0; i < dropCounter; i++) {
            infoDrops_[i] = infoBundlerDrop(i);
        }
        return infoDrops_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Whitelistable
 * @author gotbit
 */

import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract Whitelistable is Ownable {
    mapping(address => bool) public whitelist;

    event AddedToWhitelist(address indexed user, bool status, uint256 timestamp);

    function setWhitelistUser(address user, bool status) external onlyOwner {
        whitelist[user] = status;
        emit AddedToWhitelist(user, status, block.timestamp);
    }

    function setWhitelistUsers(address[] memory users, bool status) external onlyOwner {
        uint256 length = users.length;
        for (uint256 i = 0; i < length; i++) {
            whitelist[users[i]] = status;
            emit AddedToWhitelist(users[i], status, block.timestamp);
        }
    }

    function isWhitelist(address user) public view returns (bool response) {
        return whitelist[user] || user == owner();
    }

    modifier onlyWhitelist() {
        require(isWhitelist(msg.sender), 'This method can call only whitelist user');
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC1155DataStorage
 * @author gotbit
 */

import './ERC1155Extended.sol';

contract ERC1155DataStorage is ERC1155Extended {
    struct Data {
        string name_;
        address artist;
        uint256 grade;
        uint256 power;
        string rarity;
        uint256 nftPrice;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) ERC1155Extended(name_, symbol_, owner_) {}

    mapping(uint256 => Data) public datas;

    event UpdatedTokenData(uint256 indexed id, Data data_);

    /// @dev creates new id of token
    function create(string memory uri_, Data memory data_)
        external
        onlyRole(CREATOR_ROLE)
        returns (uint256 id)
    {
        emit Created(msg.sender, idCounter);

        idCounter++;
        setTokenURI(idCounter - 1, uri_);
        setTokenData(idCounter - 1, data_);
        return idCounter - 1;
    }

    function setTokenData(uint256 id, Data memory data_)
        public
        exist(id)
        onlyRole(CREATOR_ROLE)
    {
        datas[id] = data_;
        emit UpdatedTokenData(id, data_);
    }

    function data(uint256 id) external view exist(id) returns (Data memory data_) {
        return datas[id];
    }

    function infoBundleForTokenData(uint256 id)
        external
        view
        returns (string memory uri_, Data memory data_)
    {
        return (uri(id), datas[id]);
    }

    struct InfoUserData {
        uint256 id;
        uint256 balance;
        string uri;
        Data data;
    }

    function infoBundleForUserData(address user)
        external
        view
        returns (InfoUserData[] memory infoUserData)
    {
        InfoUserData[] memory infoUserData_ = new InfoUserData[](idCounter);
        for (uint256 id = 0; id < idCounter; id++) {
            infoUserData_[id] = InfoUserData({
                id: id,
                balance: balanceOf(user, id),
                uri: uri(id),
                data: datas[id]
            });
        }
        return infoUserData_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Staking
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Whitelistable.sol';

contract StakingAddble is Whitelistable {
    struct Stake {
        uint256 lastHarvest;
        uint256 startStaking;
        uint256 amount;
        uint256 boost;
    }

    IERC20 public mainToken;

    address public dividends;

    uint256 public rate = 10;
    uint256 public constant beforeCutoff = 15;
    uint256 public constant afterCutoff = 10;

    uint256 public constant year = 365 days;

    uint256 public constant cutoff = 48 hours;
    uint256 public constant stakePeriod = 0;
    uint256 public constant maxStakePeriod = year;

    mapping(address => Stake) public stakes;

    event Staked(address indexed who, uint256 startTime, uint256 amount);
    event Harvested(address indexed who, uint256 value, uint256 toDividends);
    event Unstaked(address indexed who, uint256 amount);
    event AddedAmount(address indexed who, uint256 amount);
    event Boosted(address indexed who, uint256 boost);
    event SettedDividends(address indexed who);
    event SettedRate(address indexed who, uint256 rate);

    constructor(
        address owner_,
        address token_,
        address dividends_
    ) {
        mainToken = IERC20(token_);
        dividends = dividends_;
        transferOwnership(owner_);
    }

    function stake(uint256 amount_) external {
        require(stakes[msg.sender].startStaking == 0, 'You have already staked');
        require(amount_ > 0, 'Amount must be greater then zero');
        require(mainToken.balanceOf(msg.sender) >= amount_, 'You dont enough DES');
        require(maxReward(amount_) < mainToken.balanceOf(address(this)), 'Pool is empty');

        stakes[msg.sender] = Stake(block.timestamp, block.timestamp, amount_, 0);
        emit Staked(msg.sender, block.timestamp, amount_);

        mainToken.transferFrom(msg.sender, address(this), amount_);
    }

    function addAmount(uint256 amount_) external {
        require(stakes[msg.sender].startStaking != 0, 'You dont have stake');
        require(amount_ > 0, 'Amount must be greater then zero');

        stakes[msg.sender].amount += amount_;

        emit AddedAmount(msg.sender, amount_);
    }

    function maxReward(uint256 amount_) public view returns (uint256) {
        return (amount_ * rate) / 100;
    }

    function harvest() public returns (uint256 value, uint256 toDividends) {
        require(stakes[msg.sender].startStaking != 0, 'You dont have stake');

        (uint256 value_, uint256 toDividends_) = harvested(msg.sender);
        require(mainToken.balanceOf(address(this)) >= (value_ + toDividends_), 'Contract doesnt have enough DES');

        stakes[msg.sender].lastHarvest = block.timestamp;
        emit Harvested(msg.sender, value_, toDividends_);

        require(mainToken.transfer(msg.sender, value_), 'Transfer issues');
        require(mainToken.transfer(dividends, toDividends_), 'Transfer issues');

        return (value_, toDividends_);
    }

    function harvested(address who_) public view returns (uint256 value_, uint256 toDividends_) {
        if (stakes[who_].lastHarvest == 0) return (0, 0);

        Stake memory stake_ = stakes[who_];

        uint256 timeNow = block.timestamp;
        if ((block.timestamp - stake_.startStaking) > maxStakePeriod) {
            timeNow = stake_.startStaking + maxStakePeriod;
        }

        uint256 timePassed_ = timeNow - stake_.lastHarvest;
        uint256 percentDiv_ = timePassed_ < cutoff ? beforeCutoff : afterCutoff;

        uint256 reward_ = (stake_.amount * timePassed_ * (rate + stake_.boost)) / (100 * year);
        uint256 toDiv_ = (reward_ * percentDiv_) / 100;

        return (reward_ - toDiv_, toDiv_);
    }

    function unstake() external {
        require(stakes[msg.sender].startStaking != 0, 'You dont have stake');
        require((block.timestamp - stakes[msg.sender].startStaking) >= stakePeriod, 'Time does not pass');

        harvest();

        uint256 amount_ = stakes[msg.sender].amount;
        require(mainToken.balanceOf(address(this)) >= amount_, 'Contract doesnt have enough DES');

        delete stakes[msg.sender];
        emit Unstaked(msg.sender, amount_);

        require(mainToken.transfer(msg.sender, amount_), 'Transfer issues');
    }

    function getStake(address user_) external view returns (Stake memory) {
        return stakes[user_];
    }

    function setRate(uint256 rate_) external onlyOwner {
        rate = rate_;
        emit SettedRate(msg.sender, rate_);
    }

    function setBoost(address for_, uint256 boost_) external onlyWhitelist {
        stakes[for_].boost = boost_;
        emit Boosted(for_, boost_);
    }

    function setDividends(address newDividends_) external onlyOwner {
        dividends = newDividends_;
        emit SettedDividends(newDividends_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC1155Extended
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract ERC1155Extended is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER');
    bytes32 public constant CREATOR_ROLE = keccak256('CREATOR');

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public idCounter = 1;

    mapping(uint256 => string) public uris;

    event Created(address who, uint256 id);
    event UpdatedTokenURI(uint256 indexed tokenId, string uri_);

    modifier exist(uint256 id) {
        require(id < idCounter, 'ERC1155Extended: id does not exist');
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) ERC1155('') {
        name = name_;
        symbol = symbol_;
        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev mints `amount` tokens `to` with `id`
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external exist(id) onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, '');
    }

    /// @dev mints `amounts` tokens `to` with `ids`
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, '');
    }

    /// @dev creates new id of token
    function create(string memory uri_)
        external
        onlyRole(CREATOR_ROLE)
        returns (uint256 id)
    {
        emit Created(msg.sender, idCounter);
        idCounter++;
        setTokenURI(idCounter - 1, uri_);
        return idCounter - 1;
    }

    /// @dev sets token uri for id
    function setTokenURI(uint256 id, string memory uri_)
        public
        exist(id)
        onlyRole(CREATOR_ROLE)
    {
        uris[id] = uri_;
        emit UpdatedTokenURI(id, uri_);
    }

    /// @dev grants minter role to user
    function grantRoleMinter(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, user);
    }

    /// @dev revokes minter role from user
    function revokeRoleMinter(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, user);
    }

    /// @dev grants creator role to user
    function grantRoleCreator(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(CREATOR_ROLE, user);
    }

    /// @dev revokes creator role from user
    function revokeRoleCreator(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(CREATOR_ROLE, user);
    }

    /// @dev returns uri for `id`
    function uri(uint256 id) public view override exist(id) returns (string memory uri_) {
        return uris[id];
    }

    function infoBundleForToken(uint256 id)
        external
        view
        exist(id)
        returns (string memory uri_)
    {
        return uri(id);
    }

    struct InfoUser {
        uint256 id;
        uint256 balance;
        string uri;
    }

    function infoBundleForUser(address user)
        external
        view
        returns (InfoUser[] memory infoUser)
    {
        InfoUser[] memory infoUser_ = new InfoUser[](idCounter);
        for (uint256 i = 0; i < idCounter; i++) {
            infoUser_[i] = InfoUser({id: i, balance: balanceOf(user, i), uri: uri(i)});
        }
        return infoUser_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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