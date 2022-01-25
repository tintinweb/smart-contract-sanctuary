// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Address.sol";
import "./SafeMath.sol";
import "./IBEP20.sol";
import "./Ownable.sol";
import "./Conditions.sol";
import "./Variables.sol";

// Contract contains no comments or less comments due to chain contract file size issue.

contract SafeColiseum is Context, IBEP20, Ownable {
    // Contract imports
    using SafeMath for uint256;
    using Address for address;

    string private _name =  Variables._name;
    string private _symbol =  Variables._symbol;
    uint8 private _decimals = Variables._decimals;
    uint256 private _initial_total_supply =  Variables._initial_total_supply;
    uint256 private _total_supply = Variables._initial_total_supply;

    address private _owner;
    uint256 private _total_holder = 0;
    uint256 private _total_seller = 0;

    uint256 private _burning_till_now = 0; // initial burning token count is 0
    uint256 private _pending_contribution_to_distribute = 0; // contribution collection till now, after last distribution

    mapping(address => Variables.wallet_details) private _wallets;
    address[] private _holders;
    address[] private _sellers;
    mapping(address => bool) private _sellers_check;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => Variables.ctc_approval_details) private _ctc_approvals; // Contains Approval Details for CTC
    
    constructor() {
        // initial wallet adding process on contract launch
        _initialize_default_wallet_and_rules();
        _wallets[msg.sender].balance = _total_supply;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _total_supply);

        // Intial Transfers
        _transfer(msg.sender, Variables._director_wallet_1, Variables._director_supply_each);
        _transfer(msg.sender, Variables._director_wallet_2, Variables._director_supply_each);
        _transfer(msg.sender, Variables._marketing_wallet, Variables._marketing_expansion_supply);
        _transfer(msg.sender, Variables._governance_wallet, Variables._governance_supply);
        _transfer(msg.sender, Variables._liquidity_wallet, Variables._liquidity_supply);
        _transfer(msg.sender, Variables._pool_airdrop_wallet, Variables._pool_airdrop_supply);
        _transfer(msg.sender, Variables._ifo_wallet, Variables._ifo_supply);
        _transfer(
            msg.sender,
            Variables._development_wallet,
            Variables._development_expansion_supply
        );
        _transfer(msg.sender, Variables._future_team_wallet, Variables._future_team_supply);
    }

    function _create_wallet(address addr,Variables.type_of_wallet w_type, bool is_investor) private {
        bool contribution = false;
        bool whale = false;
        bool dump = false;
        bool investor = is_investor;
        if (
            w_type == Variables.type_of_wallet.DirectorWallet ||
            w_type == Variables.type_of_wallet.MarketingWallet ||
            w_type == Variables.type_of_wallet.GovernanceWallet ||
            w_type == Variables.type_of_wallet.DevelopmentWallet ||
            w_type == Variables.type_of_wallet.DexPairWallet ||
            w_type == Variables.type_of_wallet.GeneralWallet
        ) {
            contribution = true;
        }
        if (
            w_type == Variables.type_of_wallet.DirectorWallet ||
            w_type == Variables.type_of_wallet.MarketingWallet ||
            w_type == Variables.type_of_wallet.GovernanceWallet ||
            w_type == Variables.type_of_wallet.DevelopmentWallet ||
            w_type == Variables.type_of_wallet.GeneralWallet
        ) {
            whale = true;
        }
        if (
            w_type == Variables.type_of_wallet.DirectorWallet ||
            w_type == Variables.type_of_wallet.GeneralWallet
        ) {
            dump = true;
        }
        if (w_type == Variables.type_of_wallet.GenesisWallet) {
            _wallets[addr] = Variables.wallet_details(
                w_type,
                _total_supply,
                0,
                0,
                SCOLTLibrary.parseTimestamp(block.timestamp),
                SCOLTLibrary.parseTimestamp(block.timestamp),
                contribution,
                whale,
                dump,
                investor
            );
        } else {
            _wallets[addr] = Variables.wallet_details(
                w_type,
                0,
                0,
                0,
                SCOLTLibrary.parseTimestamp(block.timestamp),
                SCOLTLibrary.parseTimestamp(block.timestamp),
                contribution,
                whale,
                dump,
                investor
            );
        }
        if (
            w_type != Variables.type_of_wallet.GenesisWallet &&
            w_type != Variables.type_of_wallet.IfoWallet &&
            w_type != Variables.type_of_wallet.LiquidityWallet &&
            w_type != Variables.type_of_wallet.MarketingWallet &&
            w_type != Variables.type_of_wallet.PoolOrAirdropWallet &&
            w_type != Variables.type_of_wallet.DevelopmentWallet &&
            w_type != Variables.type_of_wallet.UnsoldTokenWallet &&
            w_type != Variables.type_of_wallet.DexPairWallet &&
            w_type != Variables.type_of_wallet.UndefinedWallet
        ) {
            _total_holder += 1;
            _holders.push(addr);
        }
    }

    function _initialize_default_wallet_and_rules() private {
        _create_wallet(msg.sender, Variables.type_of_wallet.GenesisWallet, false); // Adding Ginesis wallets
        _create_wallet(Variables._director_wallet_1, Variables.type_of_wallet.DirectorWallet, false); // Adding Directors 1 wallets
        _create_wallet(Variables._director_wallet_2, Variables.type_of_wallet.DirectorWallet, false); // Adding Directors 2 wallets
        _create_wallet(Variables._marketing_wallet, Variables.type_of_wallet.MarketingWallet, false); // Adding Marketing Wallets
        _create_wallet(Variables._liquidity_wallet, Variables.type_of_wallet.LiquidityWallet, false); // Adding Liquidity Wallets
        _create_wallet(Variables._governance_wallet, Variables.type_of_wallet.GovernanceWallet, false); // Adding Governance Wallets
        _create_wallet(Variables._pool_airdrop_wallet, Variables.type_of_wallet.PoolOrAirdropWallet, false); // Adding PoolOrAirdropWallet Wallet
        _create_wallet(Variables._future_team_wallet, Variables.type_of_wallet.FutureTeamWallet, false); // Adding FutureTeamWallet Wallet
        _create_wallet(Variables._ifo_wallet, Variables.type_of_wallet.IfoWallet, false); // Adding IFO Wallet
        _create_wallet(Variables._development_wallet, Variables.type_of_wallet.DevelopmentWallet, false); // Adding Development Wallet
        _create_wallet(Variables._unsold_token_wallet, Variables.type_of_wallet.UnsoldTokenWallet, false); // Adding Unsold Token Wallet
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
        return  _pending_contribution_to_distribute;
    }

    function holderDetails() public view returns (uint256, address[] memory) {
        return (_total_holder, _holders);
    }

    function addSellerWallet(address account) public onlyOwner returns (bool) {
        require(account.isContract(), "SCOLT : Only Contract(DEX) can be seller");
        if (_wallets[account].wallet_type == Variables.type_of_wallet.UndefinedWallet) {
            if (account.isContract()) {
                _create_wallet(account, Variables.type_of_wallet.DexPairWallet, false);
            } else {
                _create_wallet(account, Variables.type_of_wallet.GeneralWallet, false);
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

    function removeSellerWallet(address account) public onlyOwner returns (bool) {
        require(account.isContract(), "SCOLT : Need Contract Address");
        _sellers_check[account] = false;
        _total_seller -= 1;
        return true;
    }

    function checkAccountIsSeller(address account) public view returns (bool) {
        return _sellers_check[account];
    }

    function getAccountDetails(address account)
        public
        view
        returns (Variables.wallet_details memory)
    {
        return _wallets[account];
    }

    function publicAirdrop(address[] memory recipients, uint256[] memory amounts) public returns (bool) {
        Variables.wallet_details storage sender = _wallets[msg.sender];
        require(sender.wallet_type == Variables.type_of_wallet.PoolOrAirdropWallet,"SCOLT : You are not allowed to do airdrop");
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            total = total.add(amounts[i]);
        }
        require(sender.balance >= total, "SCOLT : Not enough balance for airdrop.");
        for (uint256 i = 0; i < recipients.length; i++) {
            if (_wallets[recipients[i]].wallet_type == Variables.type_of_wallet.UndefinedWallet) {
                _create_wallet(recipients[i], Variables.type_of_wallet.GeneralWallet, false);
            } else {
                require(_wallets[recipients[i]].wallet_type == Variables.type_of_wallet.GeneralWallet, "SCOLT : Not all recipients are GeneralWallet");
            }
            sender.balance = sender.balance.sub(amounts[i].mul(10**_decimals));
            _wallets[recipients[i]].balance = _wallets[recipients[i]].balance.add(amounts[i].mul(10**_decimals));
        }
        emit PublicAirDrop(total, recipients.length, block.timestamp);
        return true;
    }

    function profitAirdrop(uint256 amount) public onlyOwner returns (bool) {
        uint256 total_eligible_token = 0;
        uint256 distribution_till_now = 0;
        uint256 amount_to_transfer;
        uint256 eligibale_account_counter = 0;
        for (uint256 i = 0; i < _total_holder; i++) {
            if (
                _wallets[_holders[i]].balance >=
                Variables._profit_distribution_eligibility
            ) {
                eligibale_account_counter += 1;
                total_eligible_token = total_eligible_token.add(
                    _wallets[_holders[i]].balance
                );
            }
        }
        for (uint256 i = 0; i < _total_holder; i++) {
            if (
                _wallets[_holders[i]].balance >=
                Variables._profit_distribution_eligibility
            ) {
                amount_to_transfer = (
                    amount.mul(
                        (_wallets[_holders[i]].balance.mul(10**_decimals))
                            .div(total_eligible_token)
                    )
                ).div(10**_decimals);
                _wallets[_holders[i]].balance = _wallets[_holders[i]]
                    .balance
                    .add(amount_to_transfer);
                _wallets[_owner].balance = _wallets[_owner]
                    .balance
                    .sub(amount_to_transfer);
                distribution_till_now += amount_to_transfer;
            }
        }
        emit ProfitAirDrop(
            eligibale_account_counter,
            distribution_till_now,
            total_eligible_token,
            block.timestamp
        );
        return true;
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
        require(owner != address(0), "SCOLT : Approve from the zero address");
        require(spender != address(0), "SCOLT : Approve to the zero address");
        require(_wallets[owner].balance >= amount, "SCOLT : Can not allow more than balance.");
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "SCOLT :transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "SCOLT :decreased allowance below zero"));
        return true;
    }

    // Function to add investment partner
    function addInvestmentPartner(address partner_address)
        public
        onlyOwner
        returns (bool)
    {
        if (
            _wallets[partner_address].wallet_type == Variables.type_of_wallet.UndefinedWallet
        ) {
            revert(
                "SCOLT : New wallet address is not allowed to be investment partner."
            );
        }
        if (_wallets[partner_address].wallet_type != Variables.type_of_wallet.GeneralWallet) {
            revert(
                "SCOLT : Other than GeneralWallet are not allowed to be investment partner."
            );
        }
        _wallets[partner_address].is_investor = true;
        _wallets[partner_address].joining_date = SCOLTLibrary.parseTimestamp(
            block.timestamp
        );
        return true;
    }

    function _contribution_airdrop() internal {
        uint256 total_eligible_token = 0;
        uint256 distribution_till_now = 0;
        uint256 amount_to_transfer;
        uint256 eligibale_account_counter = 0;
        if (_pending_contribution_to_distribute >= Variables._contribution_distribute_after) {
            for (uint256 i = 0; i < _total_holder; i++) {
                if (
                    _wallets[_holders[i]].balance >=
                    Variables._contribution_distribution_eligibility
                ) {
                    eligibale_account_counter += 1;
                    total_eligible_token = total_eligible_token.add(
                        _wallets[_holders[i]].balance
                    );
                }
            }
            for (uint256 i = 0; i < _total_holder; i++) {
                if (
                    _wallets[_holders[i]].balance >=
                    Variables._contribution_distribution_eligibility
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
            emit ContributionAirDropUpdate(
                eligibale_account_counter,
                distribution_till_now,
                total_eligible_token,
                block.timestamp
            );
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
        require(sender != address(0), "SCOLT :transfer from the zero address");
        require(recipient != address(0), "SCOLT :transfer to the zero address");
        require(
            _wallets[sender].balance >= amount,
            "SCOLT :transfer amount exceeds balance"
        );

        if (_wallets[sender].wallet_type == Variables.type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            if (sender.isContract()) {
                _create_wallet(sender, Variables.type_of_wallet.DexPairWallet, false);
            } else {
                _create_wallet(sender, Variables.type_of_wallet.GeneralWallet, false);
            }
        }
        if (_wallets[recipient].wallet_type == Variables.type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            if (recipient.isContract()) {
                _create_wallet(recipient, Variables.type_of_wallet.DexPairWallet, false);
            } else {
                _create_wallet(recipient, Variables.type_of_wallet.GeneralWallet, false);
            }
        }

        Variables.distribution_variables memory dv;
        bool sender_contribution_deduct;
        address sendfrom;

        // checking SCOLT rules before transfer
        SCOLTLibrary._checkrules(
            _wallets[sender],
            _wallets[recipient],
            _ctc_approvals[sender],
            Variables.checkrules_additional_var(
                sender,
                recipient,
                amount,
                _sellers_check[recipient],
                _sellers_check[sender]
            )
        );
        _wallets[sender].balance = _wallets[sender].balance.sub(amount);
        _wallets[recipient].balance = _wallets[recipient].balance.add(
            amount
        );
        emit Transfer(sender, recipient, amount);
        (
            dv,
            sender_contribution_deduct,
            _wallets[Variables._marketing_wallet],
            _wallets[Variables._development_wallet],
            _pending_contribution_to_distribute,
            _total_supply,
            _burning_till_now
        ) = SCOLTLibrary.contributionsCalc(
            _wallets[sender],
            _wallets[recipient],
            _wallets[Variables._marketing_wallet],
            _wallets[Variables._development_wallet],
            Variables.function_addresses(
                _owner,
                sender,
                address(this)
            ),
            Variables.function_amounts(
                amount,
                _pending_contribution_to_distribute,
                _initial_total_supply,
                _total_supply,
                _burning_till_now
            )
        );

        if (sender_contribution_deduct == false || sender.isContract()) {
            sendfrom = recipient;
            _wallets[recipient].balance = _wallets[recipient].balance.sub(dv.total_contributions);
        } else {
            sendfrom = sender;
            _wallets[sender].balance = _wallets[sender].balance.sub(dv.total_contributions);
        }

        // emit Transfer(sendfrom, Variables._marketing_wallet, dv.marketing_contributions);
        // emit Transfer(sendfrom, Variables._development_wallet, dv.development_contributions);
        // emit ContributionAddedToContributionDistributionVariable(dv.holder_contributions);
        // emit Burn(sendfrom, dv.burn_amount);
        // emit Transfer(sendfrom, address(0), dv.burn_amount);

        emit ContributionDeductionAndBurningLog(
            dv.marketing_contributions,
            dv.development_contributions,
            dv.holder_contributions,
            dv.burn_amount
        );

        _contribution_airdrop(); // check and make airdrops of contributions

        _wallets[sender] = SCOLTLibrary._after_transfer_updates(
            amount,
            _wallets[sender],
            _sellers_check[recipient]
        );
    }

    // This function manages to get aproval from user wallet to intiate CTC.
    // Only wallet holder can initiate any kind of CTC Transfers.
    function chainToChainApproval(
        string memory uctcid,
        bool burn_or_mint,
        uint256 amount
    ) public returns (bool) {
        Variables.wallet_details storage transferer_wallet = _wallets[_msgSender()];

        // checking rule for CTC, only GeneralWallet type user can initiate CTC Transfer
        require(
            !_msgSender().isContract(),
            "SCOLT : Contract type of wallet can not initiate C2C transfer."
        );
        if (!burn_or_mint) {
            require(
                transferer_wallet.wallet_type != Variables.type_of_wallet.UndefinedWallet,
                "SCOLT : Only SCOLT holder can initiate C2C transfer."
            );
        }
        if (transferer_wallet.is_investor) {
            require(
                SCOLTLibrary._check_time_condition(
                    block.timestamp,
                    SCOLTLibrary.toTimestampFromDateTime(transferer_wallet.joining_date),
                    Variables._investor_swap_lock_days
                ),
                "SCOLT : Investor account can perform any transfer after 180 days only."
            );
        }
        require(
            transferer_wallet.balance >= amount,
            "SCOLT :Insufficient balance for CTC transfer."
        );

        // Adding Details To CTC
        _ctc_approvals[_msgSender()] = Variables.ctc_approval_details(
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
        Variables.wallet_details storage transferer_wallet = _wallets[transferer];
        Variables.ctc_approval_details storage transferer_ctc_details = _ctc_approvals[
            transferer
        ];

        // Checking CTC conditions
        require(
            keccak256(bytes(transferer_ctc_details.uctcid)) ==
                keccak256(bytes(uctcid)),
            "SCOLT : Invalid Transfer token provided."
        );
        require(
            transferer_ctc_details.burn_or_mint == false,
            "SCOLT : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.used == false,
            "SCOLT : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.allowed_till >= block.timestamp,
            "SCOLT : Transfer token expired."
        );
        require(
            transferer_wallet.balance >= transferer_ctc_details.amount,
            "SCOLT :Insufficient balance for CTC transfer."
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
        Variables.type_of_wallet oc_wallet_type,
        uint256 lastday_total_sell,
        uint256 concurrent_sale_day_count,
        uint256 last_sale_date,
        uint256 joining_date,
        string memory uctcid
    ) public onlyOwner returns (bool) {
        Variables.wallet_details storage transferer_wallet = _wallets[transferer];
        Variables.ctc_approval_details storage transferer_ctc_details = _ctc_approvals[
            transferer
        ];

        // Checking CTC conditions
        require(
            keccak256(bytes(transferer_ctc_details.uctcid)) ==
                keccak256(bytes(uctcid)),
            "SCOLT : Invalid Transfer token provided."
        );
        require(
            transferer_ctc_details.burn_or_mint == true,
            "SCOLT : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.used == false,
            "SCOLT : Invalid Transfer Details."
        );
        require(
            transferer_ctc_details.allowed_till >= block.timestamp,
            "SCOLT : Transfer token expired."
        );
        if (transferer_wallet.wallet_type != Variables.type_of_wallet.UndefinedWallet) {
            require(
                transferer_wallet.wallet_type == oc_wallet_type,
                "SCOLT : Can not perform C2C transfer within differnt wallet type."
            );
        }

        // Checking if wallet is already available or not
        if (transferer_wallet.wallet_type == Variables.type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            _create_wallet(transferer, oc_wallet_type, false);
            transferer_wallet = _wallets[transferer];
            transferer_wallet.lastday_total_sell = lastday_total_sell;
            transferer_wallet.concurrent_sale_day_count = concurrent_sale_day_count;
            transferer_wallet.last_sale_date = SCOLTLibrary.parseTimestamp(last_sale_date);
            transferer_wallet.joining_date = SCOLTLibrary.parseTimestamp(joining_date);
        } else {
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
                SCOLTLibrary.toTimestampFromDateTime(transferer_wallet.last_sale_date) <
                last_sale_date
            ) {
                transferer_wallet.last_sale_date = SCOLTLibrary.parseTimestamp(
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