// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ICryptoPunksMarket.sol";

// todo
// - deal with bad voting price, too high, too low
// - more constrain on buy & sell price?
// - what if multi punks are bought
// - safe: + - * /
contract CrowdFundingPunk is
    ERC20("CrowdFundingPunk", "CFP"),
    ERC721Holder,
    Ownable
{
    using SafeMath for uint256;

    uint256 MaxPunkIndex = 9999;

    Process public process;

    uint256 public fundingEndAt;
    uint256 public bidEndAt;

    uint256 public crowdFundingTarget;

    ICryptoPunksMarket public cryptoPunksMarket;

    event AtProcess(Process);

    event Bidding(uint256 indexed punkIndex, uint256 price);
    event ExitBidding(uint256 indexed punkIndex);

    event GetPunk(uint256 indexed punkIndex);

    event OfferPunkForSale(uint256 indexed punkIndex, uint256 price);
    event NoLongerOfferPunkForSale(uint256 indexed punkIndex);
    event SoldPunk(uint256 indexed punkIndex);

    enum Process {
        FUNDING, //      receive fund; vote for buy price
        FUNDING_FAIL, // exit with fund
        BID, //          bid for punk; receive fund; vote for buy price
        BID_FAIL, //     exit with fund
        BID_COMPLETE, // vote for sell price
        PARTY_IS_OVER // exit with remaining Ethers
    }

    struct PriceVote {
        uint256 punkIndex;
        uint256 price;
    }
    struct PriceSum {
        uint256 priceWeightSum; // p1*w1 + p2*w2 + ... + pn*wn
        uint256 weightSum; //         w1 +    w2 + ... +    wn
    }

    // buy
    mapping(address => PriceVote) public funderToBuyPriceVoteMap;
    mapping(uint256 => PriceSum) public punkToBuyPriceSumMap;
    // sell
    mapping(address => PriceVote) public funderToSellPriceVoteMap;
    mapping(uint256 => PriceSum) public punkToSellPriceSumMap;

    uint256 public remainingsPerToken;

    constructor(uint256 _crowdFundingTarget, address _cryptoPunkContractAdx) {
        require(_cryptoPunkContractAdx != address(0), "invalid punks contract");

        process = Process.FUNDING;
        emit AtProcess(process);

        fundingEndAt = block.timestamp + 2 weeks;
        crowdFundingTarget = _crowdFundingTarget;

        cryptoPunksMarket = ICryptoPunksMarket(_cryptoPunkContractAdx);
    }

    // receive refund from CryptoPunkMarket
    receive() external payable {}

    //  ______ _    _ _   _ _____ _____ _   _  _____
    // |  ____| |  | | \ | |  __ \_   _| \ | |/ ____|
    // | |__  | |  | |  \| | |  | || | |  \| | |  __
    // |  __| | |  | | . ` | |  | || | | . ` | | |_ |
    // | |    | |__| | |\  | |__| || |_| |\  | |__| |
    // |_|     \____/|_| \_|_____/_____|_| \_|\_____|

    function fund() public payable {
        require(msg.value > 0, "fund with ETH");
        require(
            process == Process.FUNDING || process == Process.BID,
            "only fund when FUNDING or BID"
        );

        _mint(msg.sender, msg.value);
    }

    function fundWithVote(uint256 punkIndex, uint256 price) public payable {
        require(price >= 1 ether, "bad buy price");

        cleanExistVoteForBuyPrice(msg.sender);
        fund();
        castNewVoteForBuyPrice(msg.sender, punkIndex, price);
    }

    function voteBuyPrice(uint256 punkIndex, uint256 price) public {
        require(price == 0 || price >= 1 ether, "bad buy price");

        cleanExistVoteForBuyPrice(msg.sender);
        castNewVoteForBuyPrice(msg.sender, punkIndex, price);
    }

    function removeBadBuyPrice(address funder) public onlyOwner {
        cleanExistVoteForBuyPrice(funder);
    }

    // token transfer will update price votes
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // buy price
        updateVoteForTokenTransfer(from, to, amount, funderToBuyPriceVoteMap, punkToBuyPriceSumMap, true);
        // sell price
        updateVoteForTokenTransfer(from, to, amount, funderToSellPriceVoteMap, punkToSellPriceSumMap, false);
    }

    function updateVoteForTokenTransfer(
        address from,
        address to,
        uint256 amount,
        mapping(address => PriceVote) storage priceVoteMap,
        mapping(uint256 => PriceSum) storage priceSumMap,
        bool isBuyPriceVote
    ) internal {
        // only need update votes at certain processes
        if (isBuyPriceVote) {
            if (process != Process.FUNDING && process != Process.BID) {
                return;
            }
        } else {
            if (process != Process.BID_COMPLETE) {
                return;
            }
        }

        PriceVote storage voteFrom = priceVoteMap[from];
        if (voteFrom.price > 0) {
            PriceSum storage priceSum = priceSumMap[voteFrom.punkIndex];
            priceSum.priceWeightSum = priceSum.priceWeightSum.sub(
                voteFrom.price.mul(amount)
            );
            priceSum.weightSum = priceSum.weightSum.sub(amount);
        }

        PriceVote storage voteTo = priceVoteMap[to];
        if (voteTo.price > 0) {
            PriceSum storage priceSum = priceSumMap[voteTo.punkIndex];
            priceSum.priceWeightSum = priceSum.priceWeightSum.add(
                voteTo.price.mul(amount)
            );
            priceSum.weightSum = priceSum.weightSum.add(amount);
        }
    }

    function cleanExistVoteForBuyPrice(address funder) internal {
        PriceVote storage priceVote = funderToBuyPriceVoteMap[funder];
        if (priceVote.price == 0) {
            return;
        }

        PriceSum storage priceSum = punkToBuyPriceSumMap[priceVote.punkIndex];

        uint256 funderBalance = balanceOf(funder);
        priceSum.priceWeightSum = priceSum.priceWeightSum.sub(
            priceVote.price.mul(funderBalance)
        );
        priceSum.weightSum = priceSum.weightSum.sub(funderBalance);

        priceVote.punkIndex = 0;
        priceVote.price = 0;
    }

    function castNewVoteForBuyPrice(
        address funder,
        uint256 punkIndex,
        uint256 price
    ) internal {
        PriceVote storage priceVote = funderToBuyPriceVoteMap[funder];
        priceVote.punkIndex = punkIndex;
        priceVote.price = price;

        // price zero means revoke vote
        if (price == 0) {
            return;
        }

        uint256 funderBalance = balanceOf(funder);
        PriceSum storage punkPriceSum = punkToBuyPriceSumMap[punkIndex];

        punkPriceSum.priceWeightSum = punkPriceSum.priceWeightSum.add(
            price.mul(funderBalance)
        );
        punkPriceSum.weightSum = punkPriceSum.weightSum.add(funderBalance);
    }

    function exitForFundingFail() external {
        if (isFundingFailed() && process != Process.FUNDING_FAIL) {
            markFundingAsFail();
        }

        require(process == Process.FUNDING_FAIL, "only exit at FUNDING_FAIL");

        uint256 bal = balanceOf(msg.sender);

        _burn(msg.sender, bal);

        (bool success, ) = payable(msg.sender).call{value: bal}("");
        require(success, "Transfer failed");
    }

    function markFundingAsFail() public {
        require(process == Process.FUNDING, "only fail when FUNDING");
        require(block.timestamp > fundingEndAt, "only fail after END");
        require(
            address(this).balance < crowdFundingTarget,
            "only fail if target not reached"
        );

        process = Process.FUNDING_FAIL;
        emit AtProcess(process);
    }

    function isFundingFailed() public view returns (bool) {
        if (process == Process.FUNDING_FAIL) {
            return true;
        }

        if (
            process == Process.FUNDING &&
            block.timestamp > fundingEndAt &&
            address(this).balance < crowdFundingTarget
        ) {
            return true;
        }

        return false;
    }

    //   ____ _____ _____
    //  |  _ \_   _|  __ \
    //  | |_) || | | |  | |
    //  |  _ < | | | |  | |
    //  | |_) || |_| |__| |
    //  |____/_____|_____/

    function startBidProcess() public {
        require(process == Process.FUNDING, "must at FUNDING");
        require(
            address(this).balance >= crowdFundingTarget,
            "funding target not met"
        );

        process = Process.BID;
        bidEndAt = block.timestamp + 4 weeks;

        emit AtProcess(process);
    }

    function markBidAsFail() public {
        require(process == Process.BID, "only fail when BID");
        require(block.timestamp > bidEndAt, "only fail after END");
        require(
            cryptoPunksMarket.balanceOf(address(this)) == 0,
            "already owns punk"
        );

        process = Process.BID_FAIL;
        emit AtProcess(process);
    }

    function isBidFailed() public view returns (bool) {
        if (process == Process.BID_FAIL) {
            return true;
        }

        if (
            process == Process.BID &&
            block.timestamp > bidEndAt &&
            cryptoPunksMarket.balanceOf(address(this)) == 0
        ) {
            return true;
        }

        return false;
    }

    function exitForBidFail() public {
        if (process != Process.BID_FAIL && isBidFailed()) {
            markBidAsFail();
        }

        require(process == Process.BID_FAIL, "only exit at BID_FAIL");

        uint256 bal = balanceOf(msg.sender);

        _burn(msg.sender, bal);

        (bool success, ) = payable(msg.sender).call{value: bal}("");
        require(success, "Transfer failed");
    }

    // no callback for bid, need call notifyGetPunk() if bid accepted
    function enterBidForPunkAtMarket(uint256 punkIndex, uint256 suggestPrice)
        public
        onlyOwner
    {
        require(process == Process.BID, "must at BID");
        require(isThePunkWeChooseToBuy(punkIndex), "not the chosen punk");

        uint256 votingPrice = getBuyPriceForPunk(punkIndex);
        require(suggestPrice <= votingPrice, "price too high");

        address(cryptoPunksMarket).call{value: suggestPrice}(
            abi.encodeWithSignature("enterBidForPunk(uint256)", punkIndex)
        );

        emit Bidding(punkIndex, suggestPrice);
    }

    function cancelBidForPunkAtMarket(uint256 punkIndex) public onlyOwner {
        cryptoPunksMarket.withdrawBidForPunk(punkIndex);
        emit ExitBidding(punkIndex);
    }

    function buyPunkAtMarket(uint256 punkIndex) public onlyOwner {
        require(process == Process.BID, "must at BID");
        require(isThePunkWeChooseToBuy(punkIndex), "not the chosen punk");

        ICryptoPunksMarket.Offer memory offer = cryptoPunksMarket
            .punksOfferedForSale(punkIndex);

        uint256 votingPrice = getBuyPriceForPunk(punkIndex);
        require(offer.minValue <= votingPrice, "price too high");

        address(cryptoPunksMarket).call{value: offer.minValue}(
            abi.encodeWithSignature("buyPunk(uint256)", punkIndex)
        );
        emit GetPunk(punkIndex);
    }

    function nofityGetPunk(uint256 punkIndex) public {
        require(isPunkOwner(punkIndex), "not punk owner");
        emit GetPunk(punkIndex);
    }

    function isThePunkWeChooseToBuy(uint256 punkIndex)
        public
        view
        returns (bool)
    {
        PriceSum storage priceSum = punkToBuyPriceSumMap[punkIndex];

        // vote >= 10%
        return priceSum.weightSum * 10 >= totalSupply();
    }

    function getBuyPriceForPunk(uint256 punkIndex)
        public
        view
        returns (uint256)
    {
        PriceSum storage priceSum = punkToBuyPriceSumMap[punkIndex];
        if (priceSum.weightSum <= 0) {
            return 0;
        }

        return priceSum.priceWeightSum.div(priceSum.weightSum);
    }

    // satisefied with the punk(s) we get, enter next process
    function setBidAsComplete() public onlyOwner {
        require(process == Process.BID, "must at BID");
        require(
            cryptoPunksMarket.balanceOf(address(this)) > 0,
            "must be punk owner"
        );

        process = Process.BID_COMPLETE;
        emit AtProcess(process);
    }

    //  ____ _____ _____      _____ ____  __  __ _____  _      ______ _______ ______
    // |  _ \_   _|  __ \    / ____/ __ \|  \/  |  __ \| |    |  ____|__   __|  ____|
    // | |_) || | | |  | |  | |   | |  | | \  / | |__) | |    | |__     | |  | |__
    // |  _ < | | | |  | |  | |   | |  | | |\/| |  ___/| |    |  __|    | |  |  __|
    // | |_) || |_| |__| |  | |___| |__| | |  | | |    | |____| |____   | |  | |____
    // |____/_____|_____/    \_____\____/|_|  |_|_|    |______|______|  |_|  |______|

    function voteSellPrice(uint256 punkIndex, uint256 price) public {
        require(process == Process.BID_COMPLETE, "only at BID_COMPLETE");
        require(isPunkOwner(punkIndex), "not punk owner");

        PriceVote storage vote = funderToSellPriceVoteMap[msg.sender];
        PriceSum storage prePriceSum = punkToSellPriceSumMap[vote.punkIndex];

        // clean exist vote
        if (vote.price > 0) {
            prePriceSum.priceWeightSum = prePriceSum.priceWeightSum.sub(
                vote.price.mul(balanceOf(msg.sender))
            );
            prePriceSum.weightSum = prePriceSum.weightSum.sub(
                balanceOf(msg.sender)
            );
        }

        // update vote
        vote.punkIndex = punkIndex;
        vote.price = price;

        if (price > 0) {
            PriceSum storage newPriceSum = punkToSellPriceSumMap[punkIndex];

            newPriceSum.priceWeightSum = newPriceSum.priceWeightSum.add(
                price.mul(balanceOf(msg.sender))
            );
            newPriceSum.weightSum = newPriceSum.weightSum.add(
                balanceOf(msg.sender)
            );
        }
    }

    function removeBadSellPrice(address funder) public onlyOwner {
        PriceVote storage vote = funderToSellPriceVoteMap[funder];
        if (vote.price == 0) {
            return;
        }

        uint256 funderBalance = balanceOf(funder);
        PriceSum storage priceSum = punkToSellPriceSumMap[vote.punkIndex];

        priceSum.priceWeightSum = priceSum.priceWeightSum.sub(
            vote.price.mul(funderBalance)
        );
        priceSum.weightSum = priceSum.weightSum.sub(funderBalance);

        vote.price = 0;
    }

    function offerPunkForSale(uint256 punkIndex, uint256 suggestPrice)
        external
        onlyOwner
    {
        require(isThePunkWeChooseToSell(punkIndex), "punk not for sale yet");

        PriceSum storage priceSum = punkToSellPriceSumMap[punkIndex];
        uint256 price = priceSum.priceWeightSum.div(priceSum.weightSum);

        require(suggestPrice >= price, "sale price too low");

        cryptoPunksMarket.offerPunkForSale(punkIndex, suggestPrice);
        emit OfferPunkForSale(punkIndex, suggestPrice);
    }

    function punkNoLongerForSale(uint256 punkIndex) external onlyOwner {
        cryptoPunksMarket.punkNoLongerForSale(punkIndex);
        emit NoLongerOfferPunkForSale(punkIndex);
    }

    function acceptBidForPunk(uint256 punkIndex, uint256 suggestPrice)
        external
        onlyOwner
    {
        require(isThePunkWeChooseToSell(punkIndex), "punk not for sale yet");

        PriceSum storage priceSum = punkToSellPriceSumMap[punkIndex];
        uint256 price = priceSum.priceWeightSum.div(priceSum.weightSum);

        require(suggestPrice >= price, "sale price too low");

        cryptoPunksMarket.acceptBidForPunk(punkIndex, suggestPrice);
        cryptoPunksMarket.withdraw();

        emit SoldPunk(punkIndex);
    }

    function isThePunkWeChooseToSell(uint256 punkIndex)
        public
        view
        returns (bool)
    {
        PriceSum storage priceSum = punkToSellPriceSumMap[punkIndex];

        // vote >= 80%
        return priceSum.weightSum.mul(100) >= totalSupply().mul(80);
    }

    //  _____        _____ _________     __   _____  _____     ______      ________ _____
    // |  __ \ /\   |  __ \__   __\ \   / /  |_   _|/ ____|   / __ \ \    / /  ____|  __ \
    // | |__) /  \  | |__) | | |   \ \_/ /     | | | (___    | |  | \ \  / /| |__  | |__) |
    // |  ___/ /\ \ |  _  /  | |    \   /      | |  \___ \   | |  | |\ \/ / |  __| |  _  /
    // | |  / ____ \| | \ \  | |     | |      _| |_ ____) |  | |__| | \  /  | |____| | \ \
    // |_| /_/    \_\_|  \_\ |_|     |_|     |_____|_____/    \____/   \/   |______|_|  \_\

    function setPartyAsOver() public {
        require(process == Process.BID_COMPLETE, "must be BID_COMPLETE");
        // check all punks are sold
        require(
            cryptoPunksMarket.balanceOf(address(this)) == 0,
            "still has punk"
        );

        process = Process.PARTY_IS_OVER;
        emit AtProcess(process);

        uint256 bal = address(this).balance;

        //thank the host with a tip
        uint256 tip = bal / 100;
        payable(owner()).call{value: tip}("");

        remainingsPerToken = bal.sub(tip).mul(1e18).div(totalSupply());
    }

    function exitParty() public {
        require(
            process == Process.PARTY_IS_OVER,
            "withdraw when PARTY_IS_OVER"
        );

        uint256 bal = balanceOf(msg.sender);

        _burn(msg.sender, bal);

        uint256 amount = bal.mul(remainingsPerToken).div(1e18);
        payable(msg.sender).call{value: amount}("");
    }

    function isPunkOwner(uint256 punkIndex) internal view returns (bool) {
        return
            punkIndex <= MaxPunkIndex &&
            cryptoPunksMarket.punkIndexToAddress(punkIndex) == address(this);
    }

    function isProudOwnerOfTheCryptoPunk(address adx)
        external
        view
        returns (bool)
    {
        return
            cryptoPunksMarket.balanceOf(address(this)) > 0 &&
            balanceOf(adx) > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

// pragma solidity ^0.4.8;
pragma solidity ^0.7.0;
pragma abicoder v2;

interface ICryptoPunksMarket {

    // You can use this hash to verify the image file containing all the punks
    // string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    // address owner;

    // string public standard = 'CryptoPunks';
    // string public name;
    // string public symbol;
    // uint8 public decimals;
    // uint256 public totalSupply;

    // uint public nextPunkIndexToAssign = 0;

    // bool public allPunksAssigned = false;
    // uint public punksRemainingToAssign = 0;

    // //mapping (address => uint) public addressToPunkIndex;
    // mapping (uint => address) public punkIndexToAddress;
    function punkIndexToAddress(uint) external view returns (address);

    // /* This creates an array with all balances */
    // mapping (address => uint256) public balanceOf;
    function balanceOf(address) external view returns(uint);

    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint punkIndex;
        address bidder;
        uint value;
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    // mapping (uint => Offer) public punksOfferedForSale;
    function punksOfferedForSale(uint) external view returns (Offer memory);
    

    // // A record of the highest punk bid
    // mapping (uint => Bid) public punkBids;

    // mapping (address => uint) public pendingWithdrawals;

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint indexed punkIndex, uint minValue, address indexed toAddress);
    event PunkBidEntered(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBidWithdrawn(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBought(uint indexed punkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);

    function allInitialOwnersAssigned() external;

    function getPunk(uint punkIndex) external;

    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint punkIndex) external;
    function punkNoLongerForSale(uint punkIndex) external;
    function offerPunkForSale(uint punkIndex, uint minSalePriceInWei) external;
    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) external;
    function buyPunk(uint punkIndex) payable external;
    function withdraw() external;
    function enterBidForPunk(uint punkIndex) payable external;
    function acceptBidForPunk(uint punkIndex, uint minPrice) external;
    function withdrawBidForPunk(uint punkIndex) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}