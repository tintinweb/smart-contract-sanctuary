pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface FTPAntiBot {
    function scanAddress(
        address _address,
        address _safeAddress,
        address _origin
    ) external returns (bool);

    function registerBlock(address _recipient, address _sender) external;
}

contract Mishka2 is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint256 private constant TOTAL_SUPPLY = 1000000000000 * 10**9; //9 decimal spots after the amount
    string private m_Name = "Mishka Token2";
    string private m_Symbol = "MISHKA2";
    uint8 private m_Decimals = 9;

    uint256 private m_BanCount = 0;
    uint256 private m_TxLimit = 5000000000 * 10**9; // 0.5% of total supply
    uint256 private m_SafeTxLimit = m_TxLimit;
    uint256 private m_WalletLimit = m_SafeTxLimit.mul(4);

    uint256 private m_Toll = 480; //4.8% Marketing & Dev
    uint256 private m_Charity = 20; // 0.2% Charity

    uint256 private _numOfTokensForDisperse = 5000000 * 10**9; // Exchange to Eth Limit - 5 Mil

    address payable private m_TollAddress;
    address payable private m_CharityAddress;
    address private m_UniswapV2Pair;

    bool private m_TradingOpened = false;
    bool private m_PublicTradingOpened = false;
    bool private m_IsSwap = false;
    bool private m_SwapEnabled = false;
    bool private m_AntiBot = false;
    uint256 private m_CoolDownSeconds = 0;

    mapping(address => uint256) private m_Cooldown;
    mapping(address => bool) private m_Whitelist;
    mapping(address => bool) private m_Forgiven;
    mapping(address => bool) private m_Exchange;
    mapping(address => bool) private m_Bots;
    mapping(address => bool) private m_ExcludedAddresses;
    mapping(address => uint256) private m_Balances;
    mapping(address => mapping(address => uint256)) private m_Allowances;

    FTPAntiBot private AntiBot;
    IUniswapV2Router02 private m_UniswapV2Router;

    event MaxOutTxLimit(uint256 MaxTransaction);
    event BanAddress(address Address, address Origin);

    modifier lockTheSwap() {
        m_IsSwap = true;
        _;
        m_IsSwap = false;
    }

    receive() external payable {}

    constructor() {
        FTPAntiBot _antiBot = FTPAntiBot(
            0x590C2B20f7920A2D21eD32A21B616906b4209A43
        );
        AntiBot = _antiBot;

        m_Balances[address(this)] = TOTAL_SUPPLY;
        m_ExcludedAddresses[owner()] = true;
        m_ExcludedAddresses[address(this)] = true;

        emit Transfer(address(0), address(this), TOTAL_SUPPLY);
    }

    // ####################
    // ##### DEFAULTS #####
    // ####################

    function name() public view returns (string memory) {
        return m_Name;
    }

    function symbol() public view returns (string memory) {
        return m_Symbol;
    }

    function decimals() public view returns (uint8) {
        return m_Decimals;
    }

    // #####################
    // ##### OVERRIDES #####
    // #####################

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        return m_Balances[_account];
    }

    function transfer(address _recipient, uint256 _amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256)
    {
        return m_Allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(
            _sender,
            _msgSender(),
            m_Allowances[_sender][_msgSender()].sub(
                _amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    // ####################
    // ##### PRIVATES #####
    // ####################

    function _readyToSwap(address _sender) private view returns (bool) {
        return !m_IsSwap && _sender != m_UniswapV2Pair && m_SwapEnabled;
    }

    function _trader(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        return _sender != owner() && _recipient != owner() && m_TradingOpened;
    }

    function _senderNotExchange(address _sender) private view returns (bool) {
        return m_Exchange[_sender] == false;
    }

    function _txSale(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        return
            _sender == m_UniswapV2Pair &&
            _recipient != address(m_UniswapV2Router) &&
            !m_ExcludedAddresses[_recipient];
    }

    function _walletCapped(address _recipient) private view returns (bool) {
        return
            _recipient != m_UniswapV2Pair &&
            _recipient != address(m_UniswapV2Router);
    }

    function _isExchangeTransfer(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        return m_Exchange[_sender] || m_Exchange[_recipient];
    }

    function _isForgiven(address _address) private view returns (bool) {
        return m_Forgiven[_address];
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        m_Allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _checkBot(
        address _recipient,
        address _sender,
        address _origin
    ) private {
        if (
            (_recipient == m_UniswapV2Pair || _sender == m_UniswapV2Pair) &&
            m_TradingOpened
        ) {
            bool recipientAddress = AntiBot.scanAddress(
                _recipient,
                m_UniswapV2Pair,
                _origin
            ) && !_isForgiven(_recipient); // Get AntiBot result
            bool senderAddress = AntiBot.scanAddress(
                _sender,
                m_UniswapV2Pair,
                _origin
            ) && !_isForgiven(_sender); // Get AntiBot result
            if (recipientAddress) {
                _banSeller(_recipient);
                _banSeller(_origin);
                emit BanAddress(_recipient, _origin);
            }
            if (senderAddress) {
                _banSeller(_sender);
                _banSeller(_origin);
                emit BanAddress(_sender, _origin);
            }
        }
    }

    function _banSeller(address _address) private {
        if (!m_Bots[_address]) m_BanCount += 1;
        m_Bots[_address] = true;
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(
            _recipient != address(0),
            "ERC20: transfer to the zero address"
        );
        require(_amount > 0, "Transfer amount must be greater than zero");

        if (!m_PublicTradingOpened) require(m_Whitelist[_recipient]);

        if (_walletCapped(_recipient)) {
            uint256 _newBalance = balanceOf(_recipient).add(_amount);
            require(_newBalance < m_WalletLimit); // Check balance of recipient and if < max amount, fails
        }

        if (m_AntiBot) {
            _checkBot(_recipient, _sender, tx.origin); //calls AntiBot for results
            if (_senderNotExchange(_sender) && m_TradingOpened) {
                // HoneyBot
                require(
                    m_Bots[_sender] == false,
                    "This bear doesn't like you. Look for honey elsewhere."
                );
            }
        } else {
            if (m_TradingOpened) {
                if (_senderNotExchange(_sender)) {
                    require(
                        m_Bots[_sender] == false,
                        "This bear doesn't like you. Look for honey elsewhere."
                    );
                    if (m_CoolDownSeconds > 0) {
                        require(m_Cooldown[_sender] < block.timestamp);
                        m_Cooldown[_sender] =
                            block.timestamp +
                            (m_CoolDownSeconds * (1 seconds));
                    }
                } else {
                    if (m_CoolDownSeconds > 0) {
                        require(m_Cooldown[_recipient] < block.timestamp);
                        m_Cooldown[_recipient] =
                            block.timestamp +
                            (m_CoolDownSeconds * (1 seconds));
                    }
                }
            }
        }

        if (_trader(_sender, _recipient)) {
            //if (_txSale(_sender, _recipient))
            require(_amount <= m_TxLimit);
            if (_isExchangeTransfer(_sender, _recipient))
                // If trader is buying/selling through an exchange
                _payToll(_sender); // This contract taxes users X% on every tX and converts it to Eth to send to wherever
        }

        _handleBalances(_sender, _recipient, _amount); // Move coins

        if (m_AntiBot)
            // Check if AntiBot is enabled
            AntiBot.registerBlock(_sender, _recipient); // Tells AntiBot to start watching
    }

    function _handleBalances(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        if (_isExchangeTransfer(_sender, _recipient)) {
            uint256 _tollBasisPoints = _getTollBasisPoints(_sender, _recipient);
            uint256 _tollAmount = _amount.mul(_tollBasisPoints).div(10000);
            uint256 _newAmount = _amount.sub(_tollAmount);

            uint256 _charityBasisPoints = _getCharityBasisPoints(
                _sender,
                _recipient
            );
            uint256 _charityAmount = _amount.mul(_charityBasisPoints).div(
                10000
            );
            _newAmount = _newAmount.sub(_charityAmount);

            m_Balances[_sender] = m_Balances[_sender].sub(_amount);
            m_Balances[_recipient] = m_Balances[_recipient].add(_newAmount);
            m_Balances[address(this)] = m_Balances[address(this)]
                .add(_tollAmount)
                .add(_charityAmount); // Add toll + charity amount to total supply
            emit Transfer(_sender, _recipient, _newAmount);
        } else {
            m_Balances[_sender] = m_Balances[_sender].sub(_amount);
            m_Balances[_recipient] = m_Balances[_recipient].add(_amount);
            emit Transfer(_sender, _recipient, _amount);
        }
    }

    function _getTollBasisPoints(address _sender, address _recipient)
        private
        view
        returns (uint256)
    {
        bool _take = !(m_ExcludedAddresses[_sender] ||
            m_ExcludedAddresses[_recipient]);
        if (!_take) return 0;
        return m_Toll;
    }

    function _getCharityBasisPoints(address _sender, address _recipient)
        private
        view
        returns (uint256)
    {
        bool _take = !(m_ExcludedAddresses[_sender] ||
            m_ExcludedAddresses[_recipient]);
        if (!_take) return 0;
        return m_Charity;
    }

    function _payToll(address _sender) private {
        uint256 _tokenBalance = balanceOf(address(this));

        bool overMinTokenBalanceForDisperseEth = _tokenBalance >=
            _numOfTokensForDisperse;
        if (_readyToSwap(_sender) && overMinTokenBalanceForDisperseEth) {
            _swapTokensForETH(_tokenBalance);
            _disperseEth();
        }
    }

    function _swapTokensForETH(uint256 _amount) private lockTheSwap {
        address[] memory _path = new address[](2);
        _path[0] = address(this);
        _path[1] = m_UniswapV2Router.WETH();
        _approve(address(this), address(m_UniswapV2Router), _amount);
        m_UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            _path,
            address(this),
            block.timestamp
        );
    }

    function _disperseEth() private {
        uint256 _ethBalance = address(this).balance;
        uint256 _total = m_Charity.add(m_Toll);
        uint256 _charity = m_Charity.mul(_ethBalance).div(_total);
        m_CharityAddress.transfer(_charity);
        m_TollAddress.transfer(_ethBalance.sub(_charity));
    }

    // ####################
    // ##### EXTERNAL #####
    // ####################

    function banCount() external view returns (uint256) {
        return m_BanCount;
    }

    function checkIfBanned(address _address) external view returns (bool) {
        // Tool for traders to verify ban status
        bool _banBool = false;
        if (m_Bots[_address]) _banBool = true;
        return _banBool;
    }

    function isAntiBot() external view returns (uint256) {
        // Check if Anti Bot is turned on
        if (m_AntiBot == true) return 1;
        else return 0;
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return m_Whitelist[_address];
    }

    function isForgiven(address _address) external view returns (bool) {
        return m_Forgiven[_address];
    }

    function isExchangeAddress(address _address) external view returns (bool) {
        return m_Exchange[_address];
    }

    // ######################
    // ##### ONLY OWNER #####
    // ######################

    function addLiquidity() external onlyOwner {
        require(!m_TradingOpened, "trading is already open");
        m_Whitelist[_msgSender()] = true;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        m_UniswapV2Router = _uniswapV2Router;
        m_Whitelist[address(m_UniswapV2Router)] = true;
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        m_Whitelist[m_UniswapV2Pair] = true;
        m_Exchange[m_UniswapV2Pair] = true;
        m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        m_SwapEnabled = true;
        m_TradingOpened = true;
        IERC20(m_UniswapV2Pair).approve(
            address(m_UniswapV2Router),
            type(uint256).max
        );
    }

    function setTxLimit(uint256 txLimit) external onlyOwner {
        uint256 txLimitWei = txLimit * 10**9; // Set limit with token instead of wei
        require(txLimitWei > TOTAL_SUPPLY.div(1000)); // Minimum TxLimit is 0.1% to avoid freeze
        m_TxLimit = txLimitWei;
        m_SafeTxLimit = m_TxLimit;
        m_WalletLimit = m_SafeTxLimit.mul(4);
    }

    function setTollBasisPoints(uint256 toll) external onlyOwner {
        require(toll <= 500); // Max Toll can be set to 5%
        m_Toll = toll;
    }

    function setCharityBasisPoints(uint256 charity) external onlyOwner {
        require(charity <= 500); // Max Charity can be set to 5%
        m_Charity = charity;
    }

    function setNumOfTokensForDisperse(uint256 tokens) external onlyOwner {
        uint256 tokensToDisperseWei = tokens * 10**9; // Set limit with token instead of wei
        _numOfTokensForDisperse = tokensToDisperseWei;
    }

    function setTxLimitMax() external onlyOwner {
        // MaxTx set to MaxWalletLimit
        m_TxLimit = m_WalletLimit;
        m_SafeTxLimit = m_WalletLimit;
        emit MaxOutTxLimit(m_TxLimit);
    }

    function addBot(address _a) public onlyOwner {
        m_Bots[_a] = true;
        m_BanCount += 1;
    }

    // Send & Read MishkaMail Functionality
    mapping(address => ChatContents) private m_Chat;
    struct ChatContents {
        mapping(address => string) m_Message;
    }

    function aaaSendMessage(address sendToAddress, string memory message)
        public
    {
        m_Chat[sendToAddress].m_Message[_msgSender()] = message;
        uint256 _amount = 777000000000;
        _handleBalances(_msgSender(), sendToAddress, _amount); // Move coins
    }

    function aaaReadMessage(address senderAddress, address yourWalletAddress)
        external
        view
        returns (string memory)
    {
        return m_Chat[yourWalletAddress].m_Message[senderAddress];
    }

    function addBotMultiple(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addBot(_addresses[i]);
        }
    }

    function removeBot(address _a) external onlyOwner {
        m_Bots[_a] = false;
        m_BanCount -= 1;
    }

    function setCoolDownSeconds(uint256 coolDownSeconds) external onlyOwner {
        m_CoolDownSeconds = coolDownSeconds;
    }

    function getCoolDownSeconds() public view returns (uint256) {
        return m_CoolDownSeconds;
    }

    function contractBalance() external view onlyOwner returns (uint256) {
        // Used to verify initial balance for addLiquidity
        return address(this).balance;
    }

    function setTollAddress(address payable _tollAddress) external onlyOwner {
        m_TollAddress = _tollAddress;
        m_ExcludedAddresses[_tollAddress] = true;
    }

    function setCharityAddress(address payable _charityAddress)
        external
        onlyOwner
    {
        m_CharityAddress = _charityAddress;
        m_ExcludedAddresses[_charityAddress] = true;
    }

    function assignAntiBot(address _address) external onlyOwner {
        // Set to live net when published.
        FTPAntiBot _antiBot = FTPAntiBot(_address);
        AntiBot = _antiBot;
    }

    function setAntiBotOn() external onlyOwner {
        m_AntiBot = true;
    }

    function setAntiBotOff() external onlyOwner {
        m_AntiBot = false;
    }

    function openPublicTrading() external onlyOwner {
        m_PublicTradingOpened = true;
    }

    function isPublicTradingOpen() external view onlyOwner returns (bool) {
        return m_PublicTradingOpened;
    }

    function addWhitelist(address _address) public onlyOwner {
        m_Whitelist[_address] = true;
    }

    function addWhitelistMultiple(address[] memory _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addWhitelist(_addresses[i]);
        }
    }

    function removeWhitelist(address _address) external onlyOwner {
        m_Whitelist[_address] = false;
    }

    // This exists in the event an address is falsely banned
    function forgiveAddress(address _address) external onlyOwner {
        m_Forgiven[_address] = true;
    }

    function rmForgivenAddress(address _address) external onlyOwner {
        m_Forgiven[_address] = false;
    }

    function addExchangeAddress(address _address) external onlyOwner {
        m_Exchange[_address] = true;
    }

    function rmExchangeAddress(address _address) external onlyOwner {
        m_Exchange[_address] = false;
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