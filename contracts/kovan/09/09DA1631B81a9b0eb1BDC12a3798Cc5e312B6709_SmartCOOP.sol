// SPDX-License-Identifier: MIT

/**
 * @title SmartCOOP
 * @author Ilija Petronijevic
 * @notice Contract should be use only as proof of basic concept for smart contract usage in the field of agricultural cooperatives.
 */

pragma solidity 0.8.0;

import "ERC20.sol";
import "AggregatorV3Interface.sol";
import "Ownable.sol";
import "Pausable.sol";

contract SmartCOOP is Pausable, Ownable {
    ERC20 private coopToken;
    AggregatorV3Interface private priceFeed;

    uint256 private constant RASPBERRY_PRICE = 9;

    // State variables

    address[] public s_warehouseStock;

    struct Cooperant {
        uint256 feePayed;
        uint256 kg;
    }

    struct Bidder {
        uint256 totalPayed;
        uint256 kgBought;
    }

    mapping(address => Cooperant) public s_cooperants;
    mapping(address => Bidder) public s_bidders;

    /**
     *@dev We use COOPToken (ERC20 based OpenZeppelin implementation) address to instatiate this contract inside SmartCOOP and to call
     * transfer function from within depositFruitsToCoop function. Then we use chanilink Kovan test net address to instatiate interface which
     * will provide to us real time ETH/USD price feed.
     * IMPORTANT: if we deploy this contract localy get_contract and get_acount funcitons from scripts/helpful_scripts.py will notice that we
     * are deploying localy and instead of chainlink Kovan test net interface we will deploy mock to be used in context od local enviroment.
     * What means that there is no need for any additional intervention or configuration from side of developer. This contract will be fully
     * operational in Kovan testnet enviroment as well as in local ganache dev enviroment with Chainlink price feed.
     */
    constructor(address contractAddress, address chainlinkPrice) {
        coopToken = ERC20(contractAddress);
        priceFeed = AggregatorV3Interface(chainlinkPrice);
    }

    // Events

    event NewMember(address sender, uint256 amount);
    event DepositFruits(address cooperant, uint256 kilograms);
    event TransferMade(
        string messageToProducer,
        uint256 inEthProducer,
        string messageToCoop,
        uint256 inEthCoop
    );
    event NotEnoughGoods(string message);
    event ToContract(address sender, uint256 amount);
    event WithdrawConfirmation(address receiver, uint256 amount);
    event COOPTokenTransferConfirmation(address receiver, uint256 amount);

    // Modifiers

    ///@dev control that that function can be called only by SmartCOOP members (depositFruitsToCOOP function)
    modifier onlyMembers() {
        require(
            s_cooperants[msg.sender].feePayed != 0,
            "Please become SmartCOOP member"
        );
        _;
    }

    ///@dev Controling that function can be called only by EOA which is not already registered as SmartCOOP members (becomeCoopMember function)
    modifier onlyNewMembers() {
        require(
            s_cooperants[msg.sender].feePayed == 0,
            "You already pay mebership fee"
        );
        _;
    }

    ///@dev Controlling the fee paid when we call becomeCoopMember function is more then 1000 wei
    modifier minimumFee() {
        require(msg.value >= 1000, "Yearly fee is minimum 1000 wei");
        _;
    }

    // Functions

    /// @notice Allowing new EOA to become SmartCOOP member
    /// @return If execution was successful function will return true
    function becomeCoopMember()
        public
        payable
        whenNotPaused
        onlyNewMembers
        minimumFee
        returns (bool)
    {
        s_cooperants[msg.sender].feePayed += msg.value;
        emit NewMember(msg.sender, msg.value);
        return true;
    }

    /// @notice Allowing EOA which already pay SmartCOOP membership fee to deposit fruits to SmartCOOP warehouse
    /// @param _kg Passing number of kilograms producer would like to deploy to warehouse
    /// @return If execution was successful function will return true
    function depositFruitsToCOOP(uint256 _kg)
        public
        whenNotPaused
        onlyMembers
        returns (bool)
    {
        s_cooperants[msg.sender].kg += _kg;
        s_warehouseStock.push(msg.sender);
        coopTokenTransferTo(msg.sender, _kg * (10**18));
        emit DepositFruits(msg.sender, _kg);
        return true;
    }

    /**
     * @notice This function will allow any EOA that is not already member of cooperative to bid for fruits inside SmartCOOP warhouse.
     * @dev RASPBERRY_PRICE is hard coded because there is no out of the box chainlink date feed for raspberry price and alterantive solution includes using
     * HTTP GET request to external API using chainlink request&receive data cycle. What we consider to be a bit out of scope of this project and inital
     * ambition.
     * @param _amount uint256 for amount of fruits bidder would like to buy
     * @return If execution was successful function will return true
     */
    function bid(uint256 _amount) public payable whenNotPaused returns (bool) {
        for (
            uint256 warehouseStockIndex = 0;
            warehouseStockIndex < s_warehouseStock.length;
            warehouseStockIndex++
        ) {
            address inStockCooperantAddress = s_warehouseStock[
                warehouseStockIndex
            ];
            if (s_cooperants[inStockCooperantAddress].kg <= _amount) {
                uint256 totalPrice = s_cooperants[inStockCooperantAddress].kg *
                    RASPBERRY_PRICE;
                uint256 priceWeiProducer = (ethUSD(totalPrice) / 100) * 95;
                uint256 priceWeiCOOP = (ethUSD(totalPrice) / 100) * 5;

                (bool sentProducer, ) = inStockCooperantAddress.call{
                    value: priceWeiProducer
                }("");
                require(sentProducer, "Failed to send Ether");
                delete s_warehouseStock[warehouseStockIndex];
                _amount -= s_cooperants[inStockCooperantAddress].kg;
                s_bidders[msg.sender].totalPayed += totalPrice;
                s_bidders[msg.sender].kgBought += s_cooperants[
                    inStockCooperantAddress
                ].kg;
                s_cooperants[inStockCooperantAddress].kg = 0;
                emit TransferMade(
                    "To your account was transfered",
                    priceWeiProducer,
                    "And on COOP account",
                    priceWeiCOOP
                );
            } else if (s_cooperants[inStockCooperantAddress].kg >= _amount) {
                s_cooperants[inStockCooperantAddress].kg -= _amount;
                uint256 totalPrice = _amount * RASPBERRY_PRICE;
                uint256 priceWeiProducer = (ethUSD(totalPrice) / 100) * 95;
                uint256 priceWeiCOOP = (ethUSD(totalPrice) / 100) * 5;
                s_bidders[msg.sender].kgBought += _amount;
                s_bidders[msg.sender].totalPayed += totalPrice;

                (bool sentProducer, ) = inStockCooperantAddress.call{
                    value: priceWeiProducer
                }("");
                require(sentProducer, "Failed to send Ether");
                emit TransferMade(
                    "To your account was transfered",
                    priceWeiProducer,
                    "And on COOP account",
                    priceWeiCOOP
                );
            } else {
                emit NotEnoughGoods(
                    "There si no enough raspberries in warehouse"
                );
            }
        }
        return true;
    }

    /// @notice This function is used to transfer COOPTokens to producer account in equal amount to fruits he deposit to warehouse.
    /// @dev Used only inside depositFruitsToCOOP function.
    /// @param receiver Passing address to which COOPToken will be transferred.
    /// @param _kg Number of kilograms of fruits producer deploy to warehouse. Based on this argument he will receive equal amount of COOPTokens.
    /// @return If execution was successful function will return true.
    function coopTokenTransferTo(address receiver, uint256 _kg)
        private
        returns (bool)
    {
        emit COOPTokenTransferConfirmation(receiver, _kg);
        return coopToken.transfer(receiver, _kg);
    }

    /// @notice This function is used to withdraw eth from SmartCOOP account
    /// @dev By modifier onlyOwner we restrict right to call this function only to EOA who deploy both SmartCOOP and COOPToken
    /// @return If execution was successful function will return true
    function withdraw() public onlyOwner returns (bool) {
        uint256 coopBalance = address(this).balance;
        (bool sent, ) = owner().call{value: address(this).balance}("");
        emit WithdrawConfirmation(owner(), coopBalance);
        require(sent, "Failed to send Ether");
        return true;
    }

    /// @notice This function is used to provide overview of user SmartCOOP account
    /// @param _user We pass user address as argument
    /// @return If executed sucesfully function will return 3 values: 1) how much user pay SmartCOOP fee; 2) Total amount of kg user currenly have in
    /// SmartCOOP warehouse; 3) Total amount of COOPTokens he/she receive
    function getUserAccountBalance(address _user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            s_cooperants[_user].feePayed,
            s_cooperants[_user].kg,
            coopToken.balanceOf(_user) / (10**18)
        );
    }

    /// @notice This function is used to provide overview of bidder SmartCOOP account
    /// @param _bidder We pass bidder address
    /// @return If executed successfully function will return 2 values: 1) total payed for all goods bidder bought; 2) Total amount of kg bidder bought
    // from SmartCOOP
    function getBidderAccountBalance(address _bidder)
        public
        view
        returns (uint256, uint256)
    {
        return (s_bidders[_bidder].totalPayed, s_bidders[_bidder].kgBought);
    }

    receive() external payable {
        emit ToContract(msg.sender, msg.value);
    }

    fallback() external {
        revert();
    }

    /// @dev This function is used to block usage of becomeCoopMember, depositFruitsToCOOP and bid functions in case of bugs or hacks. Pause function
    /// can be called only by EOA who deploy COOPTOkena and SmartCOOP and it is inherited from OpenZeppelin Pausable smart contract.
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev This function is used to unpause usage of becomeCoopMember, deposit FruitsToCOOP and bid functions.
    function unpause() public onlyOwner {
        _unpause();
    }

    /** @notice This function is used to get ETH/USD price ration from Chainlink price data feed. This function is used to calculate how much bidder needs
     * to pay for fruits he bought from SmartCOOP and how much SmartCOOP should trnasfer to producer.
     * @dev In case we deploy contracts to local dev enviroment get_contract and get_acount fuctions from scripts/helpful_scripts.py will deploy mock
     * contract to be used in context of local dev. enviroment. In case we deploy to Kovan test net same function will deploy adequte contracts and use
     * proper account for this purpose.
     * @return This function returns price (int256 data type) provided by Chainlink price date feed
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /// @notice Used for calculating amount of wei from USD total
    /// @param _amount Price in USD which should be converetd to wei
    /// @return Amount of wei to be payed
    function ethUSD(uint256 _amount) public view returns (uint256) {
        uint256 denominator = uint256(getLatestPrice());
        uint256 ethInUsdAmount = ((_amount * 1000000000000000000000) /
            denominator) * 100000;
        return ethInUsdAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Context.sol";

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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

import "Context.sol";
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
    constructor () {
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

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}