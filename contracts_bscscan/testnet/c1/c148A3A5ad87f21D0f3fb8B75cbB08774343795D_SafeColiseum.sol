// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Address.sol";
import "./SafeMath.sol";
import "./IBEP20.sol";
import "./DateTime.sol";

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
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SafeColiseum is Context, IBEP20, Ownable, DateTime {
    // Contract imports
    using SafeMath for uint256;
    using Address for address;

    // Baisc contract variable declaration
    string private _name = "SafeColiseum";
    string private _symbol = "SCOMT17";
    uint8 private _decimals = 8;
    uint256 private _initial_total_supply = 210000000 * 10**_decimals;
    uint256 private _total_supply = 210000000 * 10**_decimals;
    address private _owner;
    uint256 private _total_holder = 0;

    // Token distribution veriables
    uint256 private _pioneer_invester_supply = (11 * _total_supply) / 100;
    uint256 private _ifo_supply = (19 * _total_supply) / 100;
    uint256 private _pool_airdrop_supply = (3 * _total_supply) / 100;
    uint256 private _director_supply_each = (6 * _total_supply) / 100;
    uint256 private _marketing_expansion_supply = (20 * _total_supply) / 100;
    uint256 private _development_expansion_supply = (6 * _total_supply) / 100;
    uint256 private _liquidity_supply = (5 * _total_supply) / 100;
    uint256 private _future_team_supply = (10 * _total_supply) / 100;
    uint256 private _governance_supply = (4 * _total_supply) / 100;
    uint256 private _investment_parter_supply = (10 * _total_supply) / 100;

    // Burning till total of 50% supply
    uint256 private _burning_till = _total_supply / 2;
    uint256 private _burning_till_now = 0; // initial burning token count is 0

    // Whale defination
    uint256 private _whale_per = (_total_supply / 100); // 1% of total tokans consider tobe whale

    // fee structure defination, this will be in % ranging from 0 - 100
    uint256 private _normal_tx_fee = 2;
    uint256 private _whale_tx_fee = 5;

    // below is percentage, consider _normal_tx_fee as 100%
    uint256 private _normal_marketing_share = 25;
    uint256 private _normal_development_share = 7;
    uint256 private _normal_holder_share = 43;
    uint256 private _normal_burning_share = 25;

    // below is percentage, consider _whale_tx_fee as 100%
    uint256 private _whale_marketing_share = 30;
    uint256 private _whale_development_share = 10;
    uint256 private _whale_holder_share = 40;
    uint256 private _whale_burning_share = 20;

    // antidump variables
    uint8 private _diff_in = 1; // 1 = Hours, 2 = Days
    uint256 private _max_sell_amount_whale = 5000 * 10**_decimals; // max for whale
    uint256 private _max_sell_amount_normal = 2000 * 10**_decimals; // max for non-whale
    uint256 private _max_concurrent_sale_day = 2;
    uint256 private _cooling_days = 2;
    uint256 private _max_sell_per_director_per_day = 10000 * 10**_decimals;
    uint256 private _inverstor_swap_lock_days = 2; // after 180 days will behave as normal purchase user.

    // Wallet specific declaration
    // UndefinedWallet : means 0 to check there is no wallet entry in Contract
    enum type_of_wallet {
        UndefinedWallet,
        GenesisWallet,
        DirectorWallet,
        MarketingWallet,
        DevelopmentWallet,
        LiquidityWallet,
        GovernanceWallet,
        GeneralWallet,
        FutureTeamWallet,
        PoolOrAirdropWallet,
        IfoWallet,
        SellerWallet,
        FeeDistributionWallet,
        UnsoldTokenWallet,
        ContractWallet
    }

    struct wallet_details {
        type_of_wallet wallet_type;
        uint256 balance;
        uint256 purchase;
        uint256 lastday_total_sell;
        uint256 concurrent_sale_day_count;
        _DateTime last_sale_date;
        _DateTime joining_date;
        bool fee_apply;
        bool antiwhale_apply;
        bool anti_dump;
        bool is_investor;
    }

    mapping(address => wallet_details) private _wallets;
    address[] private _holders;
    mapping(address => bool) public _sellers;

    // Chain To Chain Transfer Process Variables
    struct ctc_approval_details {
        string uctcid;
        uint256 allowed_till;
        bool used;
        bool burn_or_mint; // false = burn, true = mint
        uint256 amount;
    }
    uint256 private _ctc_aproval_validation_timespan = 300; // In Seconds
    mapping(address => ctc_approval_details) private _ctc_approvals; // Contains Approval Details for CTC

    // SCOM Specific Wallets
    address private _director_wallet_1 = 0xd26a3AF81Eb0fd83f064b8c9f12AfCD923FA8F19; // TX: No limit, RX:
    address private _director_wallet_2 = 0xba44b38b7b89A251A60C506915794F5Ac9156735; // No limit
    address private _marketing_wallet = 0x870d2d1af5604c265bDAf031386c1710972df625; // TX: Only invester and Seller
    address private _governance_wallet = 0x97Abe576E2f52B0D262D353Ea904892516068fb5; // TX: Only seller
    address private _liquidity_wallet = 0x08502f482FCb9FDE3A41866Ef41D796602f99281; // TX: Only seller, RX: Genesis Only
    address private _pool_airdrop_wallet = 0xcA4b115F0326070d9d1833d2F8DE2882C835063D; // TX: Only General wallet and Seller with contract address, RX: Genesis Only
    address private _future_team_wallet = 0x0f241406490eC9d5e292A77e6D4d405D871b4617; // TX: Only General wallet, RX: Genesis Only
    address private _ifo_wallet = 0xd0F9D1eAcDceC7737B016Fb9693AB50e007F3f04; // TX: Seller Only, RX: Genesis Only
    address private _development_wallet = 0xbd2A6b7D5c6b8B23db9d6F5Eaa4735514Bacbb0c; // TX: Seller Only, RX: Genesis Only
    address private _holder_fee_airdrop_wallet = 0x337e00151A0e3F796436c3121B17b6Fd5AC7b275; // TX: General Onlt, RX: All Only Fee
    address private _unsold_token_wallet = 0xC65fF1B1304Fc6d87215B982F214B5b58ebe790A; // TX: All, RX: All

    constructor() {
        // initial wallet adding process on contract launch
        _initialize_default_wallet_and_rules();
        _wallets[msg.sender].balance = _total_supply;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _total_supply);

        // Intial Transfers
        _transfer(msg.sender, _director_wallet_1, _director_supply_each);
        _transfer(msg.sender, _director_wallet_2, _director_supply_each);
        _transfer(msg.sender, _marketing_wallet, _marketing_expansion_supply);
        _transfer(msg.sender, _governance_wallet, _governance_supply);
        _transfer(msg.sender, _liquidity_wallet, _liquidity_supply);
        _transfer(msg.sender, _pool_airdrop_wallet, _pool_airdrop_supply);
        _transfer(msg.sender, _ifo_wallet, _ifo_supply);
        _transfer(
            msg.sender,
            _development_wallet,
            _development_expansion_supply
        );
    }

    function _create_wallet(
        address addr,
        type_of_wallet w_type
    ) private {
        bool fee = false;
        bool whale = false;
        bool dump = false;
        bool inverstor = false;
        if ( 
            w_type == type_of_wallet.DirectorWallet || 
            w_type == type_of_wallet.MarketingWallet || 
            w_type == type_of_wallet.GovernanceWallet ||
            w_type == type_of_wallet.DevelopmentWallet ||
            w_type == type_of_wallet.ContractWallet ||
            w_type == type_of_wallet.GeneralWallet
        ) {
            fee = true;
        }
        if ( 
            w_type == type_of_wallet.DirectorWallet || 
            w_type == type_of_wallet.MarketingWallet || 
            w_type == type_of_wallet.GovernanceWallet ||
            w_type == type_of_wallet.DevelopmentWallet ||
            w_type == type_of_wallet.GeneralWallet
        ) {
            whale = true;
        }
        if ( 
            w_type == type_of_wallet.DirectorWallet ||  
            w_type == type_of_wallet.GeneralWallet
        ) {
            dump = true;
        }
        if (w_type == type_of_wallet.GenesisWallet) {
            _wallets[addr] = wallet_details(
                w_type,
                _total_supply,
                0,
                0,
                0,
                parseTimestamp(block.timestamp),
                parseTimestamp(block.timestamp),
                fee,
                whale,
                dump,
                inverstor
            );
        } else {
            _wallets[addr] = wallet_details(
                w_type,
                0,
                0,
                0,
                0,
                parseTimestamp(block.timestamp),
                parseTimestamp(block.timestamp),
                fee,
                whale,
                dump,
                inverstor
            );
        }
        if (
            w_type != type_of_wallet.GenesisWallet &&
            w_type != type_of_wallet.IfoWallet &&
            w_type != type_of_wallet.LiquidityWallet &&
            w_type != type_of_wallet.MarketingWallet &&
            w_type != type_of_wallet.PoolOrAirdropWallet &&
            w_type != type_of_wallet.DevelopmentWallet
        ) {
            _total_holder += 1;
            _holders.push(addr);
        }
    }

    function _initialize_default_wallet_and_rules() private {
        _create_wallet(
            msg.sender,
            type_of_wallet.GenesisWallet
        ); // Adding Ginesis wallets
        _create_wallet(
            _director_wallet_1,
            type_of_wallet.DirectorWallet
        ); // Adding Directors 1 wallets
        _create_wallet(
            _director_wallet_2,
            type_of_wallet.DirectorWallet
        ); // Adding Directors 2 wallets
        _create_wallet(
            _marketing_wallet,
            type_of_wallet.MarketingWallet
        ); // Adding Marketing Wallets
        _create_wallet(
            _liquidity_wallet,
            type_of_wallet.LiquidityWallet
        ); // Adding Liquidity Wallets
        _create_wallet(
            _governance_wallet,
            type_of_wallet.GovernanceWallet
        ); // Adding Governance Wallets
        _create_wallet(
            _pool_airdrop_wallet,
            type_of_wallet.PoolOrAirdropWallet
        ); // Adding PoolOrAirdropWallet Wallet
        _create_wallet(
            _future_team_wallet,
            type_of_wallet.FutureTeamWallet
        ); // Adding FutureTeamWallet Wallet
        _create_wallet(
            _ifo_wallet,
            type_of_wallet.IfoWallet
        ); // Adding IFO Wallet
        _create_wallet(
            _development_wallet,
            type_of_wallet.DevelopmentWallet
        ); // Adding Development Wallet
        _create_wallet(
            _holder_fee_airdrop_wallet,
            type_of_wallet.FeeDistributionWallet
        ); // Adding Holder Fee Airdrop Wallet
        _create_wallet(
            _unsold_token_wallet,
            type_of_wallet.UnsoldTokenWallet
        ); // Adding Unsold Token Wallet

        // Marking default seller wallets so future transfer from this will be considered as purchase
        _sellers[msg.sender] = true; // genesis will be seller wallet
        _sellers[_unsold_token_wallet] = true; // unsold token wallet is seller wallet
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _total_supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _wallets[account].balance;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function burningTillNow() public view returns (uint256) {
        return _burning_till_now;
    }

    function addSellerWallet(address account) public onlyOwner returns (bool) {
        if (_wallets[account].wallet_type == type_of_wallet.UndefinedWallet) {
            _create_wallet(
                account,
                type_of_wallet.GeneralWallet
            );
        } else {
            _wallets[account].fee_apply = false;
            _wallets[account].antiwhale_apply = false;
            _wallets[account].anti_dump = false;
        }
        _sellers[account] = true;
        return true;
    }

    function checkAccountIsSeller(address account) public view returns (bool) {
        return _sellers[account];
    }

    function getAccountDetails(address account)
        public
        view
        returns (wallet_details memory)
    {
        return _wallets[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, recipient, amount);
        return true;
    }

    // Need to check condition for approval method.
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "SCOM: approve from the zero address");
        require(spender != address(0), "SCOM: approve to the zero address");
        // require(_wallets[owner].wallet_type != type_of_wallet.GeneralWallet && _wallets[owner].wallet_type != type_of_wallet.UndefinedWallet, "SCOM: Only registered wallet allowed for approval.");
        emit Approval(owner, spender, amount);
    }

    // Function to add investment partner
    function addInvestmentPartner(address partner_address)
        public
        onlyOwner
        returns (bool)
    {
        if (
            _wallets[partner_address].wallet_type ==
            type_of_wallet.UndefinedWallet
        ) {
            _create_wallet(
                partner_address,
                type_of_wallet.GeneralWallet
            );
        } else {
            _wallets[partner_address].is_investor = true;
            _wallets[partner_address].joining_date = parseTimestamp(
                block.timestamp
            ); // Changing joining date as current date today for old accounts.
        }
        return true;
    }

    // diff_in = 1 for hours
    // diff_in = 2 for days
    function _check_time_condition(
        uint256 current_timestamp,
        uint256 last_timestamp,
        uint256 diff
    ) internal view returns (bool) {
        if (_diff_in == 1) {
            // Check for hour diff
            if ((current_timestamp - last_timestamp) >= (diff * 3600)) {
                return true;
            } else {
                return false;
            }
        }
        if (_diff_in == 2) {
            // Check for days diff
            if ((current_timestamp - last_timestamp) >= ((diff * 24) * 3600)) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }

    function _checkrules(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        wallet_details storage sender_wallet = _wallets[sender];
        wallet_details storage recipient_wallet = _wallets[recipient];

        if (sender_wallet.wallet_type == type_of_wallet.GenesisWallet) {
            return;
        }

        // Checking if sennder or reciver is contract or not and also registered seller or not
        if (
            recipient.isContract() &&
            sender_wallet.wallet_type == type_of_wallet.GeneralWallet
        ) {
            if (!_sellers[recipient]) {
                revert(
                    "SCOM : You are trying to reach unregistered contract ( considered as seller )."
                );
            }
        }

        // Checking that only regular user can send token back to genesis wallet
        // require( (recipient_wallet.wallet_type != type_of_wallet.GenesisWallet && sender_wallet.wallet_type == type_of_wallet.GeneralWallet), "SCOM : You can not send your tokens back to genesis wallet" );
        if (recipient_wallet.wallet_type == type_of_wallet.GenesisWallet) {
            require(
                sender_wallet.wallet_type == type_of_wallet.GeneralWallet,
                "SCOM : You can not send your tokens back to genesis wallet"
            );
        }

        if (sender_wallet.is_investor) {
            require(
                _check_time_condition(
                    block.timestamp,
                    toTimestampFromDateTime(sender_wallet.joining_date),
                    _inverstor_swap_lock_days
                ),
                "SCOM : Investor account can perform any transfer after 180 days only"
            );
        }

        if (_sellers[recipient]) {
            require(
                sender_wallet.wallet_type != type_of_wallet.FutureTeamWallet,
                "SCOM : You are not allowed to sell token from your wallet type"
            );
            require(
                sender_wallet.wallet_type != type_of_wallet.SellerWallet,
                "SCOM : You are not allowed to sell token from your wallet type"
            );
            require(
                sender_wallet.wallet_type !=
                    type_of_wallet.FeeDistributionWallet,
                "SCOM : You are not allowed to sell token from your wallet type"
            );
            require(
                sender_wallet.wallet_type != type_of_wallet.UnsoldTokenWallet,
                "SCOM : You are not allowed to sell token from your wallet type"
            );
            if (_sellers[sender]) {
                revert("SCOM : Inter seller exchange is not allowed.");
            }
        }

        if (_sellers[recipient] && sender_wallet.anti_dump) {
            // This is for anti dump for all wallet

            // Director account restriction check.
            if (sender_wallet.wallet_type == type_of_wallet.DirectorWallet) {
                if (
                    _check_time_condition(
                        block.timestamp,
                        toTimestampFromDateTime(sender_wallet.last_sale_date),
                        1
                    )
                ) {
                    if (amount > _max_sell_per_director_per_day) {
                        revert(
                            "SCOM : Director can only send 10000 SCOM every 24 hours"
                        );
                    }
                } else {
                    if (
                        sender_wallet.lastday_total_sell + amount >
                        _max_sell_per_director_per_day
                    ) {
                        revert(
                            "SCOM : Director can only send 10000 SCOM every 24 hours"
                        );
                    }
                }
            }

            // General account restriction check.
            if (sender_wallet.wallet_type == type_of_wallet.GeneralWallet) {
                if (
                    sender_wallet.concurrent_sale_day_count >=
                    _max_concurrent_sale_day
                ) {
                    if (
                        !_check_time_condition(
                            block.timestamp,
                            toTimestampFromDateTime(
                                sender_wallet.last_sale_date
                            ),
                            1
                        )
                    ) {
                        if (
                            sender_wallet.balance >= _whale_per &&
                            sender_wallet.antiwhale_apply == true
                        ) {
                            if (
                                sender_wallet.lastday_total_sell + amount >
                                _max_sell_amount_whale
                            ) {
                                revert(
                                    "SCOM : You can not sell more than 5000 SCOM in past 24 hours."
                                );
                            }
                        } else {
                            if (
                                sender_wallet.lastday_total_sell + amount >
                                _max_sell_amount_normal
                            ) {
                                revert(
                                    "SCOM : You can not sell more than 2000 SCOM in past 24 hours."
                                );
                            }
                        }
                    } else {
                        if (
                            !_check_time_condition(
                                block.timestamp,
                                toTimestampFromDateTime(
                                    sender_wallet.last_sale_date
                                ),
                                _cooling_days + 1
                            )
                        ) {
                            revert(
                                "SCOM : Concurrent sell for more than 6 days not allowed. You can not sell for next 72 Hours"
                            );
                        } else {
                            if (
                                sender_wallet.balance >= _whale_per &&
                                sender_wallet.antiwhale_apply == true
                            ) {
                                if (amount > _max_sell_amount_whale) {
                                    revert(
                                        "SCOM : You can not sell more than 5000 SCOM in past 24 hours."
                                    );
                                }
                            } else {
                                if (amount > _max_sell_amount_normal) {
                                    revert(
                                        "SCOM : You can not sell more than 2000 SCOM in past 24 hours."
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (
                        !_check_time_condition(
                            block.timestamp,
                            toTimestampFromDateTime(
                                sender_wallet.last_sale_date
                            ),
                            1
                        )
                    ) {
                        if (
                            sender_wallet.balance >= _whale_per &&
                            sender_wallet.antiwhale_apply == true
                        ) {
                            if (
                                sender_wallet.lastday_total_sell + amount >
                                _max_sell_amount_whale
                            ) {
                                revert(
                                    "SCOM : You can not sell more than 5000 SCOM in past 24 hours."
                                );
                            }
                        } else {
                            if (
                                sender_wallet.lastday_total_sell + amount >
                                _max_sell_amount_normal
                            ) {
                                revert(
                                    "SCOM : You can not sell more than 2000 SCOM in past 24 hours."
                                );
                            }
                        }
                    } else {
                        if (
                            sender_wallet.balance >= _whale_per &&
                            sender_wallet.antiwhale_apply == true
                        ) {
                            if (amount > _max_sell_amount_whale) {
                                revert(
                                    "SCOM : You can not sell more than 5000 SCOM in past 24 hours."
                                );
                            }
                        } else {
                            if (amount > _max_sell_amount_normal) {
                                revert(
                                    "SCOM : You can not sell more than 2000 SCOM in past 24 hours."
                                );
                            }
                        }
                    }
                }
            }
        }
    }

    function _after_transfer_updates(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        wallet_details storage sender_wallet = _wallets[sender];
        wallet_details storage recipient_wallet = _wallets[recipient];

        _DateTime memory tdt = parseTimestamp(block.timestamp);

        _DateTime memory lsd;

        if (_diff_in == 1) {
            // Hour Diff
            lsd = _DateTime(
                tdt.year,
                tdt.month,
                tdt.day,
                tdt.hour,
                0,
                0,
                tdt.weekday
            );
        } else {
            lsd = _DateTime(tdt.year, tdt.month, tdt.day, 0, 0, 0, tdt.weekday);
        }

        // For purchase Whale rule
        if (_sellers[sender]) {
            if (recipient_wallet.wallet_type == type_of_wallet.GeneralWallet) {
                recipient_wallet.purchase = recipient_wallet.purchase + amount;
            }
        }
        // For Antidump rule
        if (_sellers[recipient]) {
            // General wallet supporting entries
            if (sender_wallet.wallet_type == type_of_wallet.GeneralWallet) {
                if (
                    _check_time_condition(
                        block.timestamp,
                        toTimestampFromDateTime(sender_wallet.last_sale_date),
                        1
                    )
                ) {
                    sender_wallet.lastday_total_sell = 0; // reseting sale at 24 hours
                    if (
                        _check_time_condition(
                            block.timestamp,
                            toTimestampFromDateTime(
                                sender_wallet.last_sale_date
                            ),
                            2
                        )
                    ) {
                        sender_wallet.concurrent_sale_day_count = 1;
                    } else {
                        sender_wallet.concurrent_sale_day_count = sender_wallet
                            .concurrent_sale_day_count
                            .add(1);
                    }
                    sender_wallet.last_sale_date = lsd;
                    sender_wallet.lastday_total_sell = sender_wallet
                        .lastday_total_sell
                        .add(amount);
                } else {
                    sender_wallet.lastday_total_sell = sender_wallet
                        .lastday_total_sell
                        .add(amount);
                    if (sender_wallet.concurrent_sale_day_count == 0) {
                        sender_wallet.concurrent_sale_day_count = 1;
                        sender_wallet.last_sale_date = lsd;
                    }
                }
            }
            // Director wallet supporting entries
            if (sender_wallet.wallet_type == type_of_wallet.DirectorWallet) {
                if (
                    _check_time_condition(
                        block.timestamp,
                        toTimestampFromDateTime(sender_wallet.last_sale_date),
                        1
                    )
                ) {
                    sender_wallet.lastday_total_sell = 0; // reseting director sale at 24 hours
                    sender_wallet.last_sale_date = lsd;
                    sender_wallet.lastday_total_sell = sender_wallet
                        .lastday_total_sell
                        .add(amount);
                } else {
                    sender_wallet.lastday_total_sell = sender_wallet
                        .lastday_total_sell
                        .add(amount);
                    if (sender_wallet.concurrent_sale_day_count == 0) {
                        sender_wallet.concurrent_sale_day_count = 1;
                        sender_wallet.last_sale_date = lsd;
                    }
                }
            }
        }
    }

    function _fees(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (uint256, bool) {
        if (sender == _owner || sender == address(this)) {
            return (0, true);
        }
        wallet_details storage sender_wallet = _wallets[sender];
        wallet_details storage recipient_Wallet = _wallets[recipient];

        if (sender_wallet.fee_apply == false) {
            return (0, true);
        }

        uint256 total_fees = 0;
        uint256 marketing_fees = 0;
        uint256 development_fees = 0;
        uint256 holder_fees = 0;
        uint256 burn_amount = 0;

        // Calculate fees based on whale or not whale
        if (
            sender_wallet.balance >= _whale_per &&
            sender_wallet.antiwhale_apply == true
        ) {
            total_fees = ((amount * _whale_tx_fee) / 100);
            marketing_fees = ((total_fees * _whale_marketing_share) / 100);
            development_fees = ((total_fees * _whale_development_share) / 100);
            holder_fees = ((total_fees * _whale_holder_share) / 100);
            burn_amount = ((total_fees * _whale_burning_share) / 100);
        } else {
            total_fees = ((amount * _normal_tx_fee) / 100);
            marketing_fees = ((total_fees * _normal_marketing_share) / 100);
            development_fees = ((total_fees * _normal_development_share) / 100);
            holder_fees = ((total_fees * _normal_holder_share) / 100);
            burn_amount = ((total_fees * _normal_burning_share) / 100);
        }

        // add cut to defined acounts
        if (_total_supply < (_initial_total_supply / 2)) {
            total_fees = total_fees.sub(burn_amount);
            burn_amount = 0;
        }

        bool sender_fee_deduct = false;

        // if contract type wallet then following condtion is default false
        if (
            (sender_wallet.balance >= amount + total_fees) &&
            (recipient_Wallet.wallet_type != type_of_wallet.ContractWallet)
        ) {
            if (marketing_fees > 0) {
                _wallets[_marketing_wallet].balance = _wallets[
                    _marketing_wallet
                ].balance.add(marketing_fees);
                emit Transfer(sender, _marketing_wallet, marketing_fees);
            }

            if (development_fees > 0) {
                _wallets[_development_wallet].balance = _wallets[
                    _development_wallet
                ].balance.add(development_fees);
                emit Transfer(sender, _development_wallet, development_fees);
            }

            if (holder_fees > 0) {
                _wallets[_holder_fee_airdrop_wallet].balance = _wallets[
                    _holder_fee_airdrop_wallet
                ].balance.add(holder_fees);
                emit Transfer(sender, _holder_fee_airdrop_wallet, holder_fees);
            }

            if (burn_amount > 0) {
                _total_supply = _total_supply.sub(burn_amount);
                _burning_till_now = _burning_till_now.add(burn_amount);
                emit Burn(sender, burn_amount);
                emit Transfer(sender, address(0), burn_amount);
            }
            sender_fee_deduct = true;
        } else {
            if (marketing_fees > 0) {
                _wallets[_marketing_wallet].balance = _wallets[
                    _marketing_wallet
                ].balance.add(marketing_fees);
                emit Transfer(recipient, _marketing_wallet, marketing_fees);
            }

            if (development_fees > 0) {
                _wallets[_development_wallet].balance = _wallets[
                    _development_wallet
                ].balance.add(development_fees);
                emit Transfer(recipient, _development_wallet, development_fees);
            }

            if (holder_fees > 0) {
                _wallets[_holder_fee_airdrop_wallet].balance = _wallets[
                    _holder_fee_airdrop_wallet
                ].balance.add(holder_fees);
                emit Transfer(
                    recipient,
                    _holder_fee_airdrop_wallet,
                    holder_fees
                );
            }

            if (burn_amount > 0) {
                _total_supply = _total_supply.sub(burn_amount);
                _burning_till_now = _burning_till_now.add(burn_amount);
                emit Burn(recipient, burn_amount);
                emit Transfer(recipient, address(0), burn_amount);
            }
        }

        return (total_fees, sender_fee_deduct);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "SCOM: transfer from the zero address");
        require(recipient != address(0), "SCOM: transfer to the zero address");
        require(
            _wallets[sender].balance >= amount,
            "SCOM: transfer amount exceeds balance"
        );

        if (_wallets[sender].wallet_type == type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            if (sender.isContract()) {
                _create_wallet(
                    sender,
                    type_of_wallet.ContractWallet
                );
            } else {
                _create_wallet(
                    sender,
                    type_of_wallet.GeneralWallet
                );
            }
        }
        if (_wallets[recipient].wallet_type == type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            if (recipient.isContract()) {
                _create_wallet(
                    recipient,
                    type_of_wallet.ContractWallet
                );
            } else {
                _create_wallet(
                    recipient,
                    type_of_wallet.GeneralWallet
                );
            }
        }

        // checking SCOM rules before transfer
        _checkrules(sender, recipient, amount);

        uint256 total_fees;
        bool sender_fee_deduct;
        (total_fees, sender_fee_deduct) = _fees(sender, recipient, amount);

        if (sender_fee_deduct == true) {
            uint256 r_amount = amount.add(total_fees);
            _wallets[sender].balance = _wallets[sender].balance.sub(r_amount);
            _wallets[recipient].balance = _wallets[recipient].balance.add(
                amount
            );
            emit Transfer(sender, recipient, amount);
        } else {
            uint256 r_amount = amount.sub(total_fees);
            _wallets[sender].balance = _wallets[sender].balance.sub(amount);
            _wallets[recipient].balance = _wallets[recipient].balance.add(
                r_amount
            );
            emit Transfer(sender, recipient, r_amount);
        }

        _after_transfer_updates(sender, recipient, amount);
    }

    // This function manages to get aproval from user wallet to intiate CTC.
    // Only wallet holder can initiate any kind of CTC Transfers.
    function chainToChainApproval(
        string memory uctcid, 
        bool burn_or_mint,
        uint256 amount
    ) public returns (bool)
    {
        wallet_details storage transferer_wallet = _wallets[_msgSender()];

        // checking rule for CTC, only GeneralWallet type user can initiate CTC Transfer
        require(
            !_msgSender().isContract(),
            "SCOM : Contract type of wallet can not initiate C2C transfer."
        );
        if (!burn_or_mint) {
            require(
                transferer_wallet.wallet_type != type_of_wallet.UndefinedWallet,
                "SCOM : Only SCOM holder can initiate C2C transfer."
            );
        }
        if (transferer_wallet.is_investor) {
            require(
                _check_time_condition(
                    block.timestamp,
                    toTimestampFromDateTime(transferer_wallet.joining_date),
                    _inverstor_swap_lock_days
                ),
                "SCOM : Investor account can perform any transfer after 180 days only."
            );
        }
        require( 
            transferer_wallet.balance >= amount, 
            "SCOM: Insufficient balance for CTC transfer." 
        );

        // Adding Details To CTC
        _ctc_approvals[_msgSender()] = ctc_approval_details(
            uctcid,
            block.timestamp + (300 * 1 seconds),
            false,
            burn_or_mint,
            amount
        );

        return true;
    }

    function chainToChainTransferBurn(
        address transferer, 
        string memory uctcid
    ) public onlyOwner returns (bool)
    {
        wallet_details storage transferer_wallet = _wallets[transferer];
        ctc_approval_details storage transferer_ctc_details = _ctc_approvals[transferer];

        // Checking CTC conditions
        require(
            keccak256(bytes(transferer_ctc_details.uctcid)) == keccak256(bytes(uctcid)),
            "SCOM : Invalid Transfer token provided."
        );
        require(
            transferer_ctc_details.burn_or_mint == false,
            "SCOM : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.used == false,
            "SCOM : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.allowed_till >= block.timestamp,
            "SCOM : Transfer token expired."
        );
        require( 
            transferer_wallet.balance >= transferer_ctc_details.amount,
            "SCOM: Insufficient balance for CTC transfer." 
        );

        _total_supply = _total_supply.sub(transferer_ctc_details.amount);
        // _burning_till_now = _burning_till_now.add(transferer_ctc_details.amount); not doing this as it is been transfered to other chain. not an official burn.
        emit Burn(transferer, transferer_ctc_details.amount);
        emit Transfer(transferer, address(0), transferer_ctc_details.amount);

        transferer_wallet.balance = transferer_wallet.balance.sub(transferer_ctc_details.amount);
        transferer_ctc_details.used == true; // To stop token being used for multiple times.

        return true;
    }

    function chainToChainTransferMint(
        address transferer,
        type_of_wallet oc_wallet_type,
        uint256 purchase,
        uint256 lastday_total_sell,
        uint256 concurrent_sale_day_count,
        uint256 last_sale_date,
        uint256 joining_date,
        string memory uctcid
    ) public onlyOwner returns (bool) {
        wallet_details storage transferer_wallet = _wallets[transferer];
        ctc_approval_details storage transferer_ctc_details = _ctc_approvals[transferer];

        // Checking CTC conditions
        require(
            keccak256(bytes(transferer_ctc_details.uctcid)) == keccak256(bytes(uctcid)),
            "SCOM : Invalid Transfer token provided."
        );
        require(
            transferer_ctc_details.burn_or_mint == true,
            "SCOM : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.used == false,
            "SCOM : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.allowed_till >= block.timestamp,
            "SCOM : Transfer token expired."
        );
        if (transferer_wallet.wallet_type != type_of_wallet.UndefinedWallet ) {
            require(
                transferer_wallet.wallet_type == oc_wallet_type,
                "SCOM : Can not perform C2C transfer within differnt wallet type."
            );
        }

        // Checking if wallet is already available or not
        if (transferer_wallet.wallet_type == type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            _create_wallet(
                transferer,
                oc_wallet_type
            );
            transferer_wallet = _wallets[transferer];
            transferer_wallet.purchase = purchase;
            transferer_wallet.lastday_total_sell = lastday_total_sell;
            transferer_wallet.concurrent_sale_day_count = concurrent_sale_day_count;
            transferer_wallet.last_sale_date = parseTimestamp(last_sale_date);
            transferer_wallet.joining_date = parseTimestamp(joining_date);
        } else {
            transferer_wallet.purchase = transferer_wallet.purchase.add(purchase);
            transferer_wallet.lastday_total_sell = transferer_wallet.lastday_total_sell.add(lastday_total_sell);
            if ( transferer_wallet.concurrent_sale_day_count < concurrent_sale_day_count ) {
                transferer_wallet.concurrent_sale_day_count = concurrent_sale_day_count;
            } 
            if ( toTimestampFromDateTime(transferer_wallet.last_sale_date) < last_sale_date ) {
                transferer_wallet.last_sale_date = parseTimestamp(last_sale_date);
            }
        }

        _total_supply = _total_supply.add(transferer_ctc_details.amount);
        emit Transfer(address(0), transferer, transferer_ctc_details.amount); // Minting same amount of token as other C2C Chain.

        transferer_wallet.balance = transferer_wallet.balance.add(transferer_ctc_details.amount);

        transferer_ctc_details.used == true; // To stop token being used for multiple times.
        return true;
    }
}