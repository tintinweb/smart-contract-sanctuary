// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Address.sol";
import "./SafeMath.sol";
import "./IBEP20.sol";
import "./DateTime.sol";
import "./Ownable.sol";

contract TestDummy is Context, IBEP20, Ownable, DateTime {
    // Contract imports
    using SafeMath for uint256;
    using Address for address;

    // Baisc contract variable declaration
    string private _name = "TestDummy";
    string private _symbol = "TEDU";
    uint8 private _decimals = 8;
    uint256 private _initial_total_supply = 210000000 * 10**_decimals;
    uint256 private _total_supply = 210000000 * 10**_decimals;
    address private _owner;
    uint256 private _total_holder = 0;
    uint256 private _total_seller = 0;

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

    // Transaction contribution AirDrop variable
    uint256 private _contribution_distribute_after = 100 * 10**_decimals;
    uint256 private _contribution_distribution_eligibility = 10 * 10**_decimals;
    uint256 private _pending_contribution_to_distribute = 0; // contribution collection till now, after last distribution

    // Burning till total of 50% supply
    uint256 private _burning_till = _total_supply / 2;
    uint256 private _burning_till_now = 0; // initial burning token count is 0

    // Whale defination
    uint256 private _whale_per = (_total_supply / 100); // 1% of total tokans consider tobe whale

    // contribution structure defination, this will be in % ranging from 0 - 100
    uint256 private _normal_contribution_per = 2;
    uint256 private _whale_contribution_per = 5;

    // below is percentage, consider _normal_contribution_per as 100%
    uint256 private _normal_marketing_share = 25;
    uint256 private _normal_development_share = 7;
    uint256 private _normal_holder_share = 43;
    uint256 private _normal_burning_share = 25;

    // below is percentage, consider _whale_contribution_per as 100%
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
    uint256 private _investor_swap_lock_days = 2; // after 180 days will behave as normal purchase user.

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
        UnsoldTokenWallet,
        DexPairWallet
    }

    struct wallet_details {
        type_of_wallet wallet_type;
        uint256 balance;
        uint256 purchase;
        uint256 lastday_total_sell;
        uint256 concurrent_sale_day_count;
        _DateTime last_sale_date;
        _DateTime joining_date;
        bool contribution_apply;
        bool antiwhale_apply;
        bool anti_dump;
        bool is_investor;
    }

    mapping(address => wallet_details) private _wallets;
    address[] private _holders;
    address[] private _sellers;
    mapping(address => bool) private _sellers_check;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Chain To Chain Transfer Process Variables
    struct ctc_approval_details {
        bool has_value;
        string uctcid;
        uint256 allowed_till;
        bool used;
        bool burn_or_mint; // false = burn, true = mint
        uint256 amount;
    }
    uint256 private _ctc_aproval_validation_timespan = 300; // In Seconds
    mapping(address => ctc_approval_details) private _ctc_approvals; // Contains Approval Details for CTC

    // TEDU Specific Wallets
    address private _director_wallet_1 = 0xd26a3AF81Eb0fd83f064b8c9f12AfCD923FA8F19;
    address private _director_wallet_2 = 0xba44b38b7b89A251A60C506915794F5Ac9156735;
    address private _marketing_wallet = 0x870d2d1af5604c265bDAf031386c1710972df625;
    address private _governance_wallet = 0x97Abe576E2f52B0D262D353Ea904892516068fb5;
    address private _liquidity_wallet = 0x08502f482FCb9FDE3A41866Ef41D796602f99281;
    address private _pool_airdrop_wallet = 0xcA4b115F0326070d9d1833d2F8DE2882C835063D;
    address private _future_team_wallet = 0x0f241406490eC9d5e292A77e6D4d405D871b4617;
    address private _ifo_wallet = 0xd0F9D1eAcDceC7737B016Fb9693AB50e007F3f04;
    address private _development_wallet = 0xbd2A6b7D5c6b8B23db9d6F5Eaa4735514Bacbb0c;
    address private _unsold_token_wallet = 0xC65fF1B1304Fc6d87215B982F214B5b58ebe790A;

    // Custom Event for making log entry for contract
    event ContributionAirDropUpdate(
        uint256 _total_beneficiary_count,
        uint256 _distributed_amount,
        uint256 _total_eligible_circulation,
        uint256 _timestamp
    );
    event ContributionAddedToContributionDistributionVariable(uint256 contribution);

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
        _transfer(msg.sender, _future_team_wallet, _future_team_supply);
    }

    function _create_wallet(address addr, type_of_wallet w_type, bool is_investor) private {
        bool contribution = false;
        bool whale = false;
        bool dump = false;
        bool investor = is_investor;
        if (
            w_type == type_of_wallet.DirectorWallet ||
            w_type == type_of_wallet.MarketingWallet ||
            w_type == type_of_wallet.GovernanceWallet ||
            w_type == type_of_wallet.DevelopmentWallet ||
            w_type == type_of_wallet.DexPairWallet ||
            w_type == type_of_wallet.GeneralWallet
        ) {
            contribution = true;
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
                contribution,
                whale,
                dump,
                investor
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
                contribution,
                whale,
                dump,
                investor
            );
        }
        if (
            w_type != type_of_wallet.GenesisWallet &&
            w_type != type_of_wallet.IfoWallet &&
            w_type != type_of_wallet.LiquidityWallet &&
            w_type != type_of_wallet.MarketingWallet &&
            w_type != type_of_wallet.PoolOrAirdropWallet &&
            w_type != type_of_wallet.DevelopmentWallet &&
            w_type != type_of_wallet.UnsoldTokenWallet &&
            w_type != type_of_wallet.DexPairWallet &&
            w_type != type_of_wallet.UndefinedWallet
        ) {
            _total_holder += 1;
            _holders.push(addr);
        }
    }

    function _initialize_default_wallet_and_rules() private {
        _create_wallet(msg.sender, type_of_wallet.GenesisWallet, false); // Adding Ginesis wallets
        _create_wallet(_director_wallet_1, type_of_wallet.DirectorWallet, false); // Adding Directors 1 wallets
        _create_wallet(_director_wallet_2, type_of_wallet.DirectorWallet, false); // Adding Directors 2 wallets
        _create_wallet(_marketing_wallet, type_of_wallet.MarketingWallet, false); // Adding Marketing Wallets
        _create_wallet(_liquidity_wallet, type_of_wallet.LiquidityWallet, false); // Adding Liquidity Wallets
        _create_wallet(_governance_wallet, type_of_wallet.GovernanceWallet, false); // Adding Governance Wallets
        _create_wallet(_pool_airdrop_wallet, type_of_wallet.PoolOrAirdropWallet, false); // Adding PoolOrAirdropWallet Wallet
        _create_wallet(_future_team_wallet, type_of_wallet.FutureTeamWallet, false); // Adding FutureTeamWallet Wallet
        _create_wallet(_ifo_wallet, type_of_wallet.IfoWallet, false); // Adding IFO Wallet
        _create_wallet(_development_wallet, type_of_wallet.DevelopmentWallet, false); // Adding Development Wallet
        _create_wallet(_unsold_token_wallet, type_of_wallet.UnsoldTokenWallet, false); // Adding Unsold Token Wallet

        // Marking default seller wallets so future transfer from this will be considered as purchase
        _sellers_check[msg.sender] = true; // genesis will be seller wallet
        _sellers.push(msg.sender);
        _total_seller += 1;
        _sellers_check[_unsold_token_wallet] = true; // unsold token wallet is seller wallet
        _sellers.push(_unsold_token_wallet);
        _total_seller += 1;
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

    function pendingFeeToDistribute() public view returns (uint256) {
        return _pending_contribution_to_distribute;
    }

    function holderDetails() public view returns (uint256, address[] memory) {
        return (_total_holder, _holders);
    }

    function addSellerWallet(address account) public onlyOwner returns (bool) {
        require(account.isContract(), "TEDU : Only Contract(DEX) can be seller");
        if (_wallets[account].wallet_type == type_of_wallet.UndefinedWallet) {
            if (account.isContract()) {
                _create_wallet(account, type_of_wallet.DexPairWallet, false);
            } else {
                _create_wallet(account, type_of_wallet.GeneralWallet, false);
            }
        } else {
            _wallets[account].contribution_apply = true;
            _wallets[account].antiwhale_apply = false;
            _wallets[account].anti_dump = false;
        }
        _sellers_check[account] = true;
        _total_seller += 1;
        return true;
    }

    function checkAccountIsSeller(address account) public view returns (bool) {
        return _sellers_check[account];
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

    // Need to check condition for approval method.
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "TEDU :approve from the zero address");
        require(spender != address(0), "TEDU :approve to the zero address");
        // require(_wallets[owner].wallet_type != type_of_wallet.GeneralWallet && _wallets[owner].wallet_type != type_of_wallet.UndefinedWallet, "TEDU :Only registered wallet allowed for approval.");
        //TODO : Aproval logic goes here.
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TEDU :transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TEDU :decreased allowance below zero"));
        return true;
    }

    // Function to add investment partner
    function addInvestmentPartner(address partner_address)
        public
        onlyOwner
        returns (bool)
    {
        if (
            _wallets[partner_address].wallet_type == type_of_wallet.UndefinedWallet
        ) {
            revert(
                "TEDU : New wallet address is not allowed to be investment partner."
            );
        }
        if (_wallets[partner_address].wallet_type != type_of_wallet.GeneralWallet) {
            revert(
                "TEDU : Other than GeneralWallet are not allowed to be investment partner."
            );
        }
        _wallets[partner_address].is_investor = true;
        _wallets[partner_address].joining_date = parseTimestamp(
            block.timestamp
        );
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

        ctc_approval_details storage transferer_ctc_details = _ctc_approvals[
            sender
        ];

        // Checking if sender requested for any C2C transfer or not
        if (transferer_ctc_details.has_value) {
            if (transferer_ctc_details.allowed_till >= block.timestamp) {
                if (!transferer_ctc_details.used) {
                    revert(
                        "TEDU : You can not make transfer while applied for C2C transfer."
                    );
                }
            }
        }

        // Inter seller transfer not allowed
        if (_sellers_check[recipient]) {
            if (_sellers_check[sender]) {
                revert("TEDU : Inter seller exchange is not allowed.");
            }
        }

        // Checking if sender or reciver is contract or not and also registered seller or not
        // Only Liquidity Wallet can create new pair in dex. ( Unregister Contract )
        if (
            recipient.isContract()
        ) {
            if (_sellers_check[recipient]) {
                if (
                    sender_wallet.wallet_type == type_of_wallet.UndefinedWallet ||
                    sender_wallet.wallet_type == type_of_wallet.DexPairWallet ||
                    sender_wallet.wallet_type == type_of_wallet.FutureTeamWallet
                ) {
                    revert(
                        "TEDU : You are not allowed to send tokens to DexPairWallet"
                    );
                }
            } else {
                if (
                    sender_wallet.wallet_type != type_of_wallet.LiquidityWallet
                ) {
                    revert(
                        "TEDU : You are trying to reach unregistered DexPairWallet."
                    );
                }
            }
        }

        if (
            sender.isContract()
        ) {
            if (!_sellers_check[sender]) {
                if (
                    recipient_wallet.wallet_type != type_of_wallet.LiquidityWallet
                ) {
                    revert(
                        "TEDU : Unregistered DexPairWallet are not allowed to send tokens."
                    );
                }
            }
        }

        if (
            sender_wallet.wallet_type != type_of_wallet.GenesisWallet &&
            sender_wallet.wallet_type != type_of_wallet.DirectorWallet &&
            sender_wallet.wallet_type != type_of_wallet.UnsoldTokenWallet &&
            sender_wallet.wallet_type != type_of_wallet.GeneralWallet &&
            sender_wallet.wallet_type != type_of_wallet.DexPairWallet &&
            sender_wallet.wallet_type != type_of_wallet.FutureTeamWallet
        ) {
            if ( sender_wallet.wallet_type != type_of_wallet.LiquidityWallet ) {
                require(_sellers_check[recipient] && recipient.isContract(), "TEDU : This type of wallet is not allowed to do this transaction.");
            } else {
                require(recipient.isContract(), "TEDU : This type of wallet is not allowed to do this transaction.");
            }
        }

        // Rules for marketing and poolairdrop
        if (
            sender_wallet.wallet_type == type_of_wallet.MarketingWallet ||
            sender_wallet.wallet_type == type_of_wallet.PoolOrAirdropWallet
        ) {
            require(
                recipient_wallet.wallet_type == type_of_wallet.GeneralWallet || recipient.isContract(),
                "TEDU : This type of wallet is not allowed to do this transaction."
            );
        }

        // FutureTeamWallet Only can send to GeneralWallet and recieve from genesis
        if ( sender_wallet.wallet_type == type_of_wallet.FutureTeamWallet ) {
            require(
                recipient_wallet.wallet_type == type_of_wallet.GeneralWallet,
                "TEDU : You are not allowed to send any tokens other than General Type of Wallet."
            );
        }
        if ( recipient_wallet.wallet_type == type_of_wallet.FutureTeamWallet ) {
            require(
                sender_wallet.wallet_type == type_of_wallet.GenesisWallet,
                "TEDU : You are not allowed to send any tokens to Future Team Wallet."
            );
        }

        // Checking investor block rule, time based
        if (sender_wallet.is_investor) {
            require(
                _check_time_condition(
                    block.timestamp,
                    toTimestampFromDateTime(sender_wallet.joining_date),
                    _investor_swap_lock_days
                ),
                "TEDU : Investor account can perform any transfer after 180 days only"
            );
        }

        if (_sellers_check[recipient] && sender_wallet.anti_dump) {
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
                            "TEDU : Director can only send 10000 TEDU every 24 hours"
                        );
                    }
                } else {
                    if (
                        sender_wallet.lastday_total_sell + amount >
                        _max_sell_per_director_per_day
                    ) {
                        revert(
                            "TEDU : Director can only send 10000 TEDU every 24 hours"
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
                                    "TEDU : You can not sell more than 5000 TEDU in past 24 hours."
                                );
                            }
                        } else {
                            if (
                                sender_wallet.lastday_total_sell + amount >
                                _max_sell_amount_normal
                            ) {
                                revert(
                                    "TEDU : You can not sell more than 2000 TEDU in past 24 hours."
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
                                "TEDU : Concurrent sell for more than 6 days not allowed. You can not sell for next 72 Hours"
                            );
                        } else {
                            if (
                                sender_wallet.balance >= _whale_per &&
                                sender_wallet.antiwhale_apply == true
                            ) {
                                if (amount > _max_sell_amount_whale) {
                                    revert(
                                        "TEDU : You can not sell more than 5000 TEDU in past 24 hours."
                                    );
                                }
                            } else {
                                if (amount > _max_sell_amount_normal) {
                                    revert(
                                        "TEDU : You can not sell more than 2000 TEDU in past 24 hours."
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
                                    "TEDU : You can not sell more than 5000 TEDU in past 24 hours."
                                );
                            }
                        } else {
                            if (
                                sender_wallet.lastday_total_sell + amount >
                                _max_sell_amount_normal
                            ) {
                                revert(
                                    "TEDU : You can not sell more than 2000 TEDU in past 24 hours."
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
                                    "TEDU : You can not sell more than 5000 TEDU in past 24 hours."
                                );
                            }
                        } else {
                            if (amount > _max_sell_amount_normal) {
                                revert(
                                    "TEDU : You can not sell more than 2000 TEDU in past 24 hours."
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

        // For purchase rule
        if (_sellers_check[sender]) {
            if (recipient_wallet.wallet_type == type_of_wallet.GeneralWallet) {
                recipient_wallet.purchase = recipient_wallet.purchase.add(
                    amount
                );
            }
        }

        // For Antidump rule
        if (_sellers_check[recipient]) {
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

    function _contributions(
        address sender,
        address recipient,
        uint256 amount,
        bool emitevent
    ) internal virtual returns (uint256, bool) {
        if (sender == _owner || sender == address(this)) {
            return (0, true);
        }
        wallet_details storage sender_wallet = _wallets[sender];
        wallet_details storage recipient_Wallet = _wallets[recipient];

        if (sender_wallet.contribution_apply == false) {
            return (0, true);
        }

        uint256 total_contributions = 0;
        uint256 marketing_contributions = 0;
        uint256 development_contributions = 0;
        uint256 holder_contributions = 0;
        uint256 burn_amount = 0;

        // Calculate contributions based on whale or not whale
        if (
            sender_wallet.balance >= _whale_per &&
            sender_wallet.antiwhale_apply == true
        ) {
            total_contributions = ((amount * _whale_contribution_per) / 100);
            marketing_contributions = ((total_contributions * _whale_marketing_share) / 100);
            development_contributions = ((total_contributions * _whale_development_share) / 100);
            holder_contributions = ((total_contributions * _whale_holder_share) / 100);
            burn_amount = ((total_contributions * _whale_burning_share) / 100);
        } else {
            total_contributions = ((amount * _normal_contribution_per) / 100);
            marketing_contributions = ((total_contributions * _normal_marketing_share) / 100);
            development_contributions = ((total_contributions * _normal_development_share) / 100);
            holder_contributions = ((total_contributions * _normal_holder_share) / 100);
            burn_amount = ((total_contributions * _normal_burning_share) / 100);
        }

        // add cut to defined acounts
        if (_total_supply < (_initial_total_supply / 2)) {
            total_contributions = total_contributions.sub(burn_amount);
            burn_amount = 0;
        }

        bool sender_contribution_deduct = false;

        // if contract type wallet then following condtion is default false
        if (
            (sender_wallet.balance >= amount + total_contributions) &&
            (recipient_Wallet.wallet_type != type_of_wallet.DexPairWallet)
        ) {
            if (marketing_contributions > 0) {
                _wallets[_marketing_wallet].balance = _wallets[
                    _marketing_wallet
                ].balance.add(marketing_contributions);
                if (emitevent) {
                    emit Transfer(sender, _marketing_wallet, marketing_contributions);
                }
            }

            if (development_contributions > 0) {
                _wallets[_development_wallet].balance = _wallets[
                    _development_wallet
                ].balance.add(development_contributions);
                if (emitevent) {
                    emit Transfer(sender, _development_wallet, development_contributions);
                }
            }

            if (holder_contributions > 0) {
                _pending_contribution_to_distribute = _pending_contribution_to_distribute.add(
                    holder_contributions
                );
                if (emitevent) {
                    emit ContributionAddedToContributionDistributionVariable(holder_contributions);
                }
            }

            if (burn_amount > 0) {
                _total_supply = _total_supply.sub(burn_amount);
                _burning_till_now = _burning_till_now.add(burn_amount);
                if (emitevent) {
                    emit Burn(sender, burn_amount);
                    emit Transfer(sender, address(0), burn_amount);
                }
            }
            sender_contribution_deduct = true;
        } else {
            if (marketing_contributions > 0) {
                _wallets[_marketing_wallet].balance = _wallets[
                    _marketing_wallet
                ].balance.add(marketing_contributions);
                if (emitevent) {
                    emit Transfer(recipient, _marketing_wallet, marketing_contributions);
                }
            }

            if (development_contributions > 0) {
                _wallets[_development_wallet].balance = _wallets[
                    _development_wallet
                ].balance.add(development_contributions);
                if (emitevent) {
                    emit Transfer(recipient, _development_wallet, development_contributions);
                }
            }

            if (holder_contributions > 0) {
                _pending_contribution_to_distribute = _pending_contribution_to_distribute.add(
                    holder_contributions
                );
                if (emitevent) {
                    emit ContributionAddedToContributionDistributionVariable(holder_contributions);
                }
            }

            if (burn_amount > 0) {
                _total_supply = _total_supply.sub(burn_amount);
                _burning_till_now = _burning_till_now.add(burn_amount);
                if (emitevent) {
                    emit Burn(recipient, burn_amount);
                    emit Transfer(recipient, address(0), burn_amount);
                }
            }
        }

        if (sender_wallet.wallet_type == type_of_wallet.DexPairWallet) {
            sender_contribution_deduct = false;
        }

        return (total_contributions, sender_contribution_deduct);
    }

    function _contribution_airdrop(bool emitevent) internal {
        uint256 total_eligible_token = 0;
        uint256 distribution_till_now = 0;
        uint256 amount_to_transfer;
        uint256 eligibale_account_counter = 0;
        if (_pending_contribution_to_distribute >= _contribution_distribute_after) {
            for (uint256 i = 0; i < _total_holder; i++) {
                if (
                    _wallets[_holders[i]].balance >=
                    _contribution_distribution_eligibility
                ) {
                    eligibale_account_counter += 1;
                    total_eligible_token = total_eligible_token.add(
                        _wallets[_holders[i]].balance
                    );
                }
            }
            for (uint256 i = 0; i < eligibale_account_counter; i++) {
                if (
                    _wallets[_holders[i]].balance >=
                    _contribution_distribution_eligibility
                ) {
                    amount_to_transfer = (
                        _pending_contribution_to_distribute.mul(
                            (_wallets[_holders[i]].balance.mul(10**_decimals))
                                .div(total_eligible_token)
                        )
                    ).div(10**_decimals);
                    _wallets[_holders[i]].balance = _wallets[_holders[i]]
                        .balance
                        .add(amount_to_transfer);
                    distribution_till_now += amount_to_transfer;
                }
            }
            if (emitevent) {
                emit ContributionAirDropUpdate(
                    eligibale_account_counter,
                    distribution_till_now,
                    total_eligible_token,
                    block.timestamp
                );
            }
            _pending_contribution_to_distribute = _pending_contribution_to_distribute.sub(
                distribution_till_now
            );
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "TEDU :transfer from the zero address");
        require(recipient != address(0), "TEDU :transfer to the zero address");
        require(
            _wallets[sender].balance >= amount,
            "TEDU :transfer amount exceeds balance"
        );

        if (_wallets[sender].wallet_type == type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            if (sender.isContract()) {
                _create_wallet(sender, type_of_wallet.DexPairWallet, false);
            } else {
                _create_wallet(sender, type_of_wallet.GeneralWallet, false);
            }
        }
        if (_wallets[recipient].wallet_type == type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            if (recipient.isContract()) {
                _create_wallet(recipient, type_of_wallet.DexPairWallet, false);
            } else {
                _create_wallet(recipient, type_of_wallet.GeneralWallet, false);
            }
        }

        // checking TEDU rules before transfer
        _checkrules(sender, recipient, amount);

        if (sender.isContract()) {
            _wallets[sender].balance = _wallets[sender].balance.sub(amount);
            _wallets[recipient].balance = _wallets[recipient].balance.add(
                amount
            );
            emit Transfer(sender, recipient, amount);
            uint256 total_contributions;
            bool sender_contribution_deduct;
            (total_contributions, sender_contribution_deduct) = _contributions(sender, recipient, amount, sender.isContract());
        } else {
            uint256 total_contributions;
            bool sender_contribution_deduct;
            (total_contributions, sender_contribution_deduct) = _contributions(sender, recipient, amount, !sender.isContract());

            if (sender_contribution_deduct == true) {
                uint256 r_amount = amount.add(total_contributions);
                _wallets[sender].balance = _wallets[sender].balance.sub(r_amount);
                _wallets[recipient].balance = _wallets[recipient].balance.add(
                    amount
                );
                emit Transfer(sender, recipient, amount);
            } else {
                uint256 r_amount = amount.sub(total_contributions);
                _wallets[sender].balance = _wallets[sender].balance.sub(amount);
                _wallets[recipient].balance = _wallets[recipient].balance.add(
                    r_amount
                );
                emit Transfer(sender, recipient, r_amount);
            }
            _contribution_airdrop(!sender.isContract()); // check and make airdrops of contributions
        }

        _after_transfer_updates(sender, recipient, amount);
    }

    // This function manages to get aproval from user wallet to intiate CTC.
    // Only wallet holder can initiate any kind of CTC Transfers.
    function chainToChainApproval(
        string memory uctcid,
        bool burn_or_mint,
        uint256 amount
    ) public returns (bool) {
        wallet_details storage transferer_wallet = _wallets[_msgSender()];

        // checking rule for CTC, only GeneralWallet type user can initiate CTC Transfer
        require(
            !_msgSender().isContract(),
            "TEDU : Contract type of wallet can not initiate C2C transfer."
        );
        if (!burn_or_mint) {
            require(
                transferer_wallet.wallet_type != type_of_wallet.UndefinedWallet,
                "TEDU : Only TEDU holder can initiate C2C transfer."
            );
        }
        if (transferer_wallet.is_investor) {
            require(
                _check_time_condition(
                    block.timestamp,
                    toTimestampFromDateTime(transferer_wallet.joining_date),
                    _investor_swap_lock_days
                ),
                "TEDU : Investor account can perform any transfer after 180 days only."
            );
        }
        require(
            transferer_wallet.balance >= amount,
            "TEDU :Insufficient balance for CTC transfer."
        );

        // Adding Details To CTC
        _ctc_approvals[_msgSender()] = ctc_approval_details(
            true,
            uctcid,
            block.timestamp + (300 * 1 seconds),
            false,
            burn_or_mint,
            amount * 10**_decimals
        );

        return true;
    }

    function chainToChainTransferBurn(address transferer, string memory uctcid)
        public
        onlyOwner
        returns (bool)
    {
        wallet_details storage transferer_wallet = _wallets[transferer];
        ctc_approval_details storage transferer_ctc_details = _ctc_approvals[
            transferer
        ];

        // Checking CTC conditions
        require(
            keccak256(bytes(transferer_ctc_details.uctcid)) ==
                keccak256(bytes(uctcid)),
            "TEDU : Invalid Transfer token provided."
        );
        require(
            transferer_ctc_details.burn_or_mint == false,
            "TEDU : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.used == false,
            "TEDU : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.allowed_till >= block.timestamp,
            "TEDU : Transfer token expired."
        );
        require(
            transferer_wallet.balance >= transferer_ctc_details.amount,
            "TEDU :Insufficient balance for CTC transfer."
        );

        _total_supply = _total_supply.sub(transferer_ctc_details.amount);
        // _burning_till_now = _burning_till_now.add(transferer_ctc_details.amount); not doing this as it is been transfered to other chain. not an official burn.
        emit Burn(transferer, transferer_ctc_details.amount);
        emit Transfer(transferer, address(0), transferer_ctc_details.amount);
        transferer_wallet.balance = transferer_wallet.balance.sub(
            transferer_ctc_details.amount
        );

        transferer_ctc_details.used = true; // To stop token being used for multiple times.
        delete _ctc_approvals[transferer];
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
        ctc_approval_details storage transferer_ctc_details = _ctc_approvals[
            transferer
        ];

        // Checking CTC conditions
        require(
            keccak256(bytes(transferer_ctc_details.uctcid)) ==
                keccak256(bytes(uctcid)),
            "TEDU : Invalid Transfer token provided."
        );
        require(
            transferer_ctc_details.burn_or_mint == true,
            "TEDU : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.used == false,
            "TEDU : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.allowed_till >= block.timestamp,
            "TEDU : Transfer token expired."
        );
        if (transferer_wallet.wallet_type != type_of_wallet.UndefinedWallet) {
            require(
                transferer_wallet.wallet_type == oc_wallet_type,
                "TEDU : Can not perform C2C transfer within differnt wallet type."
            );
        }

        // Checking if wallet is already available or not
        if (transferer_wallet.wallet_type == type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            _create_wallet(transferer, oc_wallet_type, false);
            transferer_wallet = _wallets[transferer];
            transferer_wallet.purchase = purchase;
            transferer_wallet.lastday_total_sell = lastday_total_sell;
            transferer_wallet
                .concurrent_sale_day_count = concurrent_sale_day_count;
            transferer_wallet.last_sale_date = parseTimestamp(last_sale_date);
            transferer_wallet.joining_date = parseTimestamp(joining_date);
        } else {
            transferer_wallet.purchase = transferer_wallet.purchase.add(
                purchase
            );
            transferer_wallet.lastday_total_sell = transferer_wallet
                .lastday_total_sell
                .add(lastday_total_sell);
            if (
                transferer_wallet.concurrent_sale_day_count <
                concurrent_sale_day_count
            ) {
                transferer_wallet
                    .concurrent_sale_day_count = concurrent_sale_day_count;
            }
            if (
                toTimestampFromDateTime(transferer_wallet.last_sale_date) <
                last_sale_date
            ) {
                transferer_wallet.last_sale_date = parseTimestamp(
                    last_sale_date
                );
            }
        }

        _total_supply = _total_supply.add(transferer_ctc_details.amount);
        emit Mint(transferer, transferer_ctc_details.amount);
        emit Transfer(address(0), transferer, transferer_ctc_details.amount); // Minting same amount of token as other C2C Chain.
        transferer_wallet.balance = transferer_wallet.balance.add(
            transferer_ctc_details.amount
        );

        transferer_ctc_details.used = true; // To stop token being used for multiple times.
        delete _ctc_approvals[transferer];
        return true;
    }

}