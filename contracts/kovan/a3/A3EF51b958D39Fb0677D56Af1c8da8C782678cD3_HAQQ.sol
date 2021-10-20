//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// import "hardhat/console.sol";

/*
* OpenZeppelin ERC20
* https://docs.openzeppelin.com/contracts/4.x/erc20
*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
* OpenZeppelin Ownable
* https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable
*/
import "@openzeppelin/contracts/access/Ownable.sol";

/*
* OpenZeppelin Pausable
* https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable
* see also example on https://docs.openzeppelin.com/contracts/4.x/wizard
*/
//import "@openzeppelin/contracts/security/Pausable.sol";
// > Note: we use own public variable 'tokenTransfersAllowed' instead,
// because this makes the state of the contract more understandable from its variables.

/*
* Chainlink data feed
* See: https://docs.chain.link/docs/beginners-tutorial/#6a-using-chainlink-data-feeds
* https://docs.chain.link/docs/get-the-latest-price/#solidity
*/
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract HAQQ is ERC20, Ownable {

    /* ChainLink */
    AggregatorV3Interface internal priceFeed;

    /*
    * Struct that represents current tier data:
    * at witch amount of issued (sold) tokens tier starts (first tier start at 0),
    * token price in USD during this tier,
    * minimum amount of tokens to for purchase in this tier
    */
    struct Tier {
        uint startsOnTokensSold;
        uint tokenPriceInUsdCents;
        uint minPurchaseTokens;
    }

    /*
    * contains predefined values for each tier
    */
    mapping(uint => Tier) public tiers;

    /*
    * indicates which tier (from 1 to 3) is currently running
    */
    uint public currentTier;

    /*
    * By default users can not move purchased tokens, until it will be allowed by the contract owner,
    */
    bool public tokenTransfersAllowed;

    /*
    * Indicates that sale is running;
    */
    bool public saleIsRunning;

    /*
    * Decimals
    * See: https://docs.openzeppelin.com/contracts/4.x/erc20#a-note-on-decimals
    * Please, note that using decimals > 0, we actually work with the smallest unit, not token itself
    * and 'token' represents corresponding amount of smallest unit
    * (like working with cents, not with dollar; or working with wei, not with ETH)
    */
    function decimals() public view override returns (uint8) {
        return 6;
    }

    constructor() ERC20("Islamic Coin", "HAQQ") {

        // Token sale has to be started manually by the contract owner
        saleIsRunning = false;

        // all token transfers are paused until allowed by the contract owner
        tokenTransfersAllowed = false;

        // different values for Ethereum mainnet (production) and Kovan testnet (development and testing)
        if (block.chainid == 1) {
            /**
            * ChainLink
            * Network: MainNet
            * Aggregator: ETH/USD
            * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            */
            priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

            // ==== Tiers:
            // 1
            tiers[1].startsOnTokensSold = 0;
            tiers[1].tokenPriceInUsdCents = 200;
            tiers[1].minPurchaseTokens = 25000;
            // 2
            tiers[2].startsOnTokensSold = 10000000;
            tiers[2].tokenPriceInUsdCents = 1000;
            tiers[2].minPurchaseTokens = 10000;
            // 3
            tiers[3].startsOnTokensSold = 20000000;
            tiers[3].tokenPriceInUsdCents = 1800;
            tiers[3].minPurchaseTokens = 2500;
        } else if (block.chainid == 42) {
            /**
            * ChainLink
            * Network: Kovan
            * Aggregator: ETH/USD
            * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
            */
            priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
            // ==== Tiers:
            // 1
            tiers[1].startsOnTokensSold = 0;
            tiers[1].tokenPriceInUsdCents = 2;
            tiers[1].minPurchaseTokens = 7;
            // 2
            tiers[2].startsOnTokensSold = 100;
            tiers[2].tokenPriceInUsdCents = 3;
            tiers[2].minPurchaseTokens = 4;
            // 3
            tiers[3].startsOnTokensSold = 200;
            tiers[3].tokenPriceInUsdCents = 4;
            tiers[3].minPurchaseTokens = 2;
        }

        currentTier = 1;
    }

    /*
    * Event to be emitted with switching to the next tier
    */
    event TierUpgraded(uint indexed from, uint indexed to);

    function _upgradeTier() private {
        // if, after minting, total amount of the issued tokens reaches next tier starting point,
        // upgrade current tier
        if (currentTier < 3) {
            if (totalSupply() >= tiers[3].startsOnTokensSold * (10 ** decimals())) {
                uint _from = currentTier;
                currentTier = 3;
                emit TierUpgraded(_from, currentTier);
            } else if (currentTier < 2 && totalSupply() >= tiers[2].startsOnTokensSold * (10 ** decimals())) {
                uint _from = currentTier;
                currentTier = 2;
                emit TierUpgraded(_from, currentTier);
            }
        }
    }

    /*
    * Allows contract owner to update tier manually
    */
    function upgradeTierManually() external onlyOwner returns (bool success) {
        require(currentTier < 3, "Tier can not be upgraded");
        uint _from = currentTier;
        currentTier = currentTier + 1;
        emit TierUpgraded(_from, currentTier);
        return true;
    }

    /*
    * Event to be emitted when token transfers are unblocked.
    */
    event TokenTransfersAllowed(address indexed by);

    /*
    * This function allows transfers of purchased tokens.
    * Transfers can not be blocked/paused after this.
    */
    function allowTokenTransfers() public onlyOwner returns (bool success) {
        tokenTransfersAllowed = true;
        emit TokenTransfersAllowed(msg.sender);
        return true;
    }

    /*
    * Overrides _beforeTokenTransfer, so before the contract owner allows transfers,
    * all transfers exempt minting (which technically is a transfer from zero account to a user)
    * are blocked.
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from != address(0)) {
            require(tokenTransfersAllowed, "Token transfers are not allowed");
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    /*
    * Event to be emitted when token sale begins
    */
    event SaleStarted(address indexed startedBy);

    /*
    * Contract owner should start token sale manually
    */
    function startSale() public onlyOwner returns (bool success) {
        saleIsRunning = true;
        emit SaleStarted(msg.sender);
        return true;
    }

    /*
    * Event to be emitted when sale is stopped.
    */
    event SaleStopped(address indexed stoppedBy);

    /*
    * Token sale has to be stopped by the contract owner manually
    */
    function stopSale() public onlyOwner returns (bool success) {
        saleIsRunning = false;
        emit SaleStopped(msg.sender);
        return true;
    }

    /*
    * Receives current ETH/USD price from the ChainLink ETH/USD price feed
    * See an example on:
    * https://docs.chain.link/docs/beginners-tutorial/#6a-using-chainlink-data-feeds
    * https://github.com/smartcontractkit/hardhat-starter-kit/blob/main/contracts/PriceConsumerV3.sol
    * See also:
    * https://ethereum.stackexchange.com/questions/98531/price-conversion-using-chainlink-ethusd-price/98686
    * returned value has 8 decimals of precision, i.e. result 355045809273 means ETH = $3,550.45809273 (result/10**8)
    *
    * We also allow user to call this function from web UI, to update current ETH/USD price with timestamp
    *
    */
    function getChainLinkEthUsdPrice() public view returns (uint, uint) {
        (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return (uint(price), timeStamp);
    }

    /*
    * Event to be emitted when new tokens are purchased
    * (in addition to Transfer event with transfer from 0 address to user)
    */
    event TokensPurchaseInfo (
        address indexed purchasedBy,
        uint indexed currentTier,
        uint msgValueInWei,
        uint currentEthUsdPrice,
        uint ethUsdPriceTimeStamp,
        uint msgValueInUsdCents,
        uint tokensAmount
    );
    /*
    * This function receives ETH from user and mint corresponding amounts of tokens to ETH sender address.
    * If, after minting, total amount of issued tokens reaches the next tier, switches to next tier
    */
    function _buyTokens() private returns (bool success){

        require(msg.value > 0, 'Message value should be > 0');

        // if token sale is not running, function should revert
        require(saleIsRunning, "Sale is not running");

        // amount of tokens to be purchased
        (uint price, uint timeStamp) = getChainLinkEthUsdPrice();
        // uint ethPriceInUsdCents = price/10**6;
        // uint msgValueInEth = msg.value/(10**18)
        // uint msgValueInUsdCents = msgValueInEth * ethPriceInUsdCents;
        // uint msgValueInUsdCents = (msg.value/(10**18)) * (price/10**6);
        // uint msgValueInUsdCents = msg.value/(10**18) * price/10**6;
        uint msgValueInUsdCents = msg.value * price / 10 ** 24;
        //
        uint tokensAmount = msgValueInUsdCents / tiers[currentTier].tokenPriceInUsdCents;

        // if amount is less than required in curren tier, function should revert
        require(tokensAmount >= tiers[currentTier].minPurchaseTokens, "The purchased amount ot tokens is less than the required minimum ");

        uint amountToMint = tokensAmount * (10 ** decimals());
        // mint new tokens to user address
        // (using OpenZeppelin ERC20 _mint function (transfer from zero address)
        _mint(msg.sender, amountToMint);

        emit TokensPurchaseInfo(
            msg.sender,
            currentTier,
            msg.value,
            price,
            timeStamp,
            msgValueInUsdCents,
            amountToMint
        );

        _upgradeTier();

        return true;
    }

    /*
    * Safe version of purchase tokens, if tier was already changed, will revert, unlike just sending tokens to contract
    * address, which will sell tokens on curren tier price
    */
    function buyTokens(uint _tier) external payable returns (bool success){
        require(_tier == currentTier, "Tier changed already");
        return _buyTokens();
    }

    /*
    * This function allows user to buy tokens just by sending ETH to this contract address
    * For using fallback function see:
    * https://docs.soliditylang.org/en/v0.8.9/contracts.html#receive-ether-function
    * https://docs.soliditylang.org/en/v0.8.9/contracts.html#fallback-function
    *
    * it will sell tokens at current tier price, thus price can be changed after tx was sent
    */
    fallback() external payable {
        _buyTokens();
    }

    /*
    * Event to be emitted, when contract owner withdraws collected ETH from this contract
    */
    event Withdrawal(address indexed to, address indexed by, uint sumInWei);

    /*
    * This function transfers all collected ETH to contract owner address.
    * For using .transfer() see:
    * https://docs.soliditylang.org/en/v0.8.9/common-patterns.html?highlight=withdraw#withdrawal-from-contracts
    */
    function withdrawAllEthToOwner() public onlyOwner returns (bool success) {

        emit Withdrawal(owner(), msg.sender, address(this).balance);

        payable(owner()).transfer(address(this).balance);

        return true;
    }

    /* ======== accept stable coins */

    /*  Addresses of tokens we accept as a payment for our tokens */
    mapping(address => bool) public acceptedCoins;

    /* Event to be emitted, when new accepted coin added  */
    event newAcceptedCoinAdded (address indexed coinAddress, address indexed addedBy);

    /*
    * Contract owner can add new accepted coin.
    * Because we operate in cents, accepted usd stable coin should support cents
    * (most, or all of them of them are, usual they have decimals == 6)
    */
    function addAcceptedCoin(address _address) external onlyOwner returns (bool success){
        ERC20 acceptedCoinContract = ERC20(_address);
        uint8 acceptedCoinDecimals = acceptedCoinContract.decimals();
        require(acceptedCoinDecimals >= 2, 'Accepted coin decimals should be > 2');
        acceptedCoins[_address] = true;
        emit newAcceptedCoinAdded(_address, msg.sender);
        return true;
    }

    /*
    * emitted in addition to Transfer event, when new tokens minted in exchange to
    * tokens (usd stable coins) sent by user
    */
    event TokensExchanged(
        address indexed acceptedCoinContract,
        uint coinsReceived,
        uint8 acceptedCoinDecimals,
        uint indexed currentTier,
        uint currentPriceInCents,
        uint ourTokensMinted,
        address indexed mintedToAddress
    );

    /*
    * Mint new tokens in exchange to accepted stable coins
    * Here we don't use ChainLink ETH/USD price feed, as we assume
    * the price of the accepted token is equal to one dollar
    */
    function exchangeTokens(uint _amountInAcceptedCoins, address _tokenAddress, uint _tier) external returns (bool success){

        require(_amountInAcceptedCoins > 0, 'Amount should be > 0');

        // prevent buying tokens after price/tier is changed
        require(_tier == currentTier, "Tier changed already");

        // if token sale is not running, function should revert
        require(saleIsRunning, "Sale is not running");

        // coin should be in acceptedCoins list
        require(acceptedCoins[_tokenAddress], "This coin is not accepted");

        ERC20 acceptedCoinContract = ERC20(_tokenAddress);
        // user should pre-allow access to his/her tokens in acceptedCoinContract
        require(
            acceptedCoinContract.allowance(msg.sender, address(this)) >= _amountInAcceptedCoins,
            "Allowance less than required amount"
        );

        uint8 acceptedCoinDecimals = acceptedCoinContract.decimals();
        uint oneCentInAcceptedCoins = (10 ** acceptedCoinDecimals) / 100;
        uint acceptedCoinsSumInCents = _amountInAcceptedCoins / oneCentInAcceptedCoins;
        uint tokensAmount = acceptedCoinsSumInCents / tiers[currentTier].tokenPriceInUsdCents;

        // if amount is less than required in curren tier, function should revert
        require(tokensAmount >= tiers[currentTier].minPurchaseTokens, "The amount ot tokens to exchange is less than the required minimum ");

        if (acceptedCoinContract.transferFrom(msg.sender, address(this), _amountInAcceptedCoins)) {
            uint amountToMint = tokensAmount * (10 ** decimals());
            // mint new tokens to user address
            // (using OpenZeppelin ERC20 _mint function (transfer from zero address)
            _mint(msg.sender, amountToMint);

            emit TokensExchanged(
                _tokenAddress,
                _amountInAcceptedCoins,
                acceptedCoinDecimals,
                currentTier,
                tiers[currentTier].tokenPriceInUsdCents,
                amountToMint,
                msg.sender
            );

            _upgradeTier();

            return true;

        } else {
            return false;
        }
    }

    function withdrawAcceptedCoinToOwner(address _acceptedCoinAddress) external onlyOwner returns (bool success){
        ERC20 acceptedCoinContract = ERC20(_acceptedCoinAddress);
        uint ourBalance = acceptedCoinContract.balanceOf(address(this));
        if (acceptedCoinContract.transfer(msg.sender, ourBalance)) {
            return true;
        } else {
            return false;
        }
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

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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