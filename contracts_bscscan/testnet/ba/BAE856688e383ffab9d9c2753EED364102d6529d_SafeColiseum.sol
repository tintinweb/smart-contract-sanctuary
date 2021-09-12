// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Address.sol"; 
import "./SafeMath.sol"; 
import "./IBEP20.sol";

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
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract SafeColiseum is Context, IBEP20, Ownable {

    // Contract imports 
    using SafeMath for uint256;
    using Address for address;

    // Baisc contract variable declaration 
    string private _name = "SafeColiseum";
    string private _symbol = "SCOM";
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
    uint256 private _max_sell_per = 5;
    uint256 private _max_sell_amount = 5000; // whaever is less 
    uint256 private _max_concurrent_sale_day = 2;
    uint256 private _colling_days = 1;
    uint256 private _max_sell_per_director_per_day = 10000;
    uint256 private _inverstor_swap_lock_days = 180; // after 180 days will behave as normal purchase user.

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
        UnsoldTokenWallet
    }

    struct wallet_details {
        type_of_wallet wallet_type;
        uint256 balance;
        uint256 purchase;
        uint256 concurrent_sale_day_count;
        uint256 last_sale_date; 
        uint256 joining_date;
        uint256 lastday_total_sell;
        bool fee_apply;
        bool antiwhale_apply;
        bool anti_dump;
        bool is_investor;
    }

    mapping ( address => wallet_details ) private _wallets;
    address[] private _holders;
    mapping (address => bool) public _sellers;

    // SCOM Specific Wallets
    address private _director_wallet_1 = 0xd26a3AF81Eb0fd83f064b8c9f12AfCD923FA8F19;
    address private _director_wallet_2 = 0xba44b38b7b89A251A60C506915794F5Ac9156735;
    address private _marketing_wallet = 0x870d2d1af5604c265bDAf031386c1710972df625;
    address private _governance_wallet = 0x97Abe576E2f52B0D262D353Ea904892516068fb5;
    address private _liquidity_wallet = 0x08502f482FCb9FDE3A41866Ef41D796602f99281;
    address private _pool_airdrop_wallet = 0xcA4b115F0326070d9d1833d2F8DE2882C835063D;
    address private _future_team_wallet = 0x0f241406490eC9d5e292A77e6D4d405D871b4617;
    address private _ifo_wallet = 0xd0F9D1eAcDceC7737B016Fb9693AB50e007F3f04;
    address private _development_wallet = 0xbd2A6b7D5c6b8B23db9d6F5Eaa4735514Bacbb0c;
    address private _holder_fee_airdrop_wallet = 0x337e00151A0e3F796436c3121B17b6Fd5AC7b275;
    address private _unsold_token_wallet = 0xC65fF1B1304Fc6d87215B982F214B5b58ebe790A;

    constructor () {
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
       _transfer(msg.sender, _development_wallet, _development_expansion_supply);
    }

    function _create_wallet(address addr, type_of_wallet w_type, bool fee, bool whale, bool dump, bool inverstor) private {
        if ( w_type == type_of_wallet.GenesisWallet ) {
            _wallets[addr] = wallet_details( 
                w_type, _total_supply, 0, 0, block.timestamp, block.timestamp, 0, fee, whale, dump, inverstor
            );
        } else {
            _wallets[addr] = wallet_details( 
                w_type, 0, 0, 0, block.timestamp, block.timestamp, 0, fee, whale, dump, inverstor
            );
        }
        if ( w_type !=  type_of_wallet.GenesisWallet && w_type !=  type_of_wallet.IfoWallet && w_type !=  type_of_wallet.LiquidityWallet && w_type !=  type_of_wallet.MarketingWallet && w_type !=  type_of_wallet.PoolOrAirdropWallet && w_type !=  type_of_wallet.DevelopmentWallet ) {
            _total_holder+=1;
            _holders.push(addr);
        }
    }

    function _initialize_default_wallet_and_rules() private {
        _create_wallet(msg.sender, type_of_wallet.GenesisWallet, false, false, false, false);                          // Adding Ginesis wallets
        _create_wallet(_director_wallet_1, type_of_wallet.DirectorWallet, true, true, true, false);                    // Adding Directors 1 wallets
        _create_wallet(_director_wallet_2, type_of_wallet.DirectorWallet, true, true, true, false);                    // Adding Directors 2 wallets
        _create_wallet(_marketing_wallet, type_of_wallet.MarketingWallet, true, true, false, false);                   // Adding Marketing Wallets
        _create_wallet(_liquidity_wallet, type_of_wallet.LiquidityWallet, false, false, false, false);                 // Adding Liquidity Wallets
        _create_wallet(_governance_wallet, type_of_wallet.GovernanceWallet, true, false, false, false);                // Adding Governance Wallets
        _create_wallet(_pool_airdrop_wallet, type_of_wallet.PoolOrAirdropWallet, false, false, false, false);          // Adding PoolOrAirdropWallet Wallet
        _create_wallet(_future_team_wallet, type_of_wallet.FutureTeamWallet, false, false, false, false);              // Adding FutureTeamWallet Wallet
        _create_wallet(_ifo_wallet, type_of_wallet.IfoWallet, false, false, false, false);                             // Adding IFO Wallet
        _create_wallet(_development_wallet, type_of_wallet.DevelopmentWallet, false, false, false, false);             // Adding Development Wallet
        _create_wallet(_holder_fee_airdrop_wallet, type_of_wallet.FeeDistributionWallet, false, false, false, false);  // Adding Holder Fee Airdrop Wallet
        _create_wallet(_unsold_token_wallet, type_of_wallet.UnsoldTokenWallet, false, false, false, false);            // Adding Unsold Token Wallet

        // Marking default seller wallets so future transfer from this will be considered as purchase
        _sellers[msg.sender]=true;              // genesis will be seller wallet 
        _sellers[_unsold_token_wallet]=true;    // unsold token wallet is seller wallet 
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

    function addSellerWallet(address seller) public onlyOwner returns (bool) {
        if ( _wallets[seller].wallet_type ==  type_of_wallet.UndefinedWallet) {
            _create_wallet(seller, type_of_wallet.GeneralWallet, false, false, false, false);
        } else {
            _wallets[seller].fee_apply = false;
            _wallets[seller].antiwhale_apply = false;
            _wallets[seller].anti_dump = false;
        }
        _sellers[seller]=true;
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, recipient, amount);
        return true;
    }
    
    function getAccountType(address account) public view onlyOwner returns (type_of_wallet) {
        return _wallets[account].wallet_type;
    }

    // Function to add investment partner
    function addInvestmentPartner(address partner_address) public onlyOwner returns (bool) {
        if ( _wallets[partner_address].wallet_type ==  type_of_wallet.UndefinedWallet) {
            _create_wallet(partner_address, type_of_wallet.GeneralWallet, true, true, true, true);
        } else {
            _wallets[partner_address].is_investor = true;
            _wallets[partner_address].joining_date = block.timestamp; // Changing joining date as current date today for old accounts.
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "SCOM: approve from the zero address");
        require(spender != address(0), "SCOM: approve to the zero address");
        emit Approval(owner, spender, amount);
    }

    function _checkrules(address sender, address recipient, uint256 amount) internal view {
        wallet_details storage sender_wallet = _wallets[sender];
        wallet_details storage recipient_wallet = _wallets[recipient];

        if (sender_wallet.wallet_type == type_of_wallet.GenesisWallet) {
            return ;
        }

        require( (recipient_wallet.wallet_type == type_of_wallet.GenesisWallet && sender_wallet.wallet_type != type_of_wallet.GeneralWallet), "SCOM : You can not send your tokens back to genesis wallet" );

        if ( sender_wallet.is_investor ) {
            require( block.timestamp <= (sender_wallet.joining_date + ( _inverstor_swap_lock_days * 1 days )), "SCOM : Investor account can perform any transfer after 180 days only");
        }

        if (_sellers[recipient]) {
            require(sender_wallet.wallet_type == type_of_wallet.FutureTeamWallet || sender_wallet.wallet_type == type_of_wallet.SellerWallet || sender_wallet.wallet_type == type_of_wallet.FeeDistributionWallet || sender_wallet.wallet_type == type_of_wallet.UnsoldTokenWallet, "SCOM : You are not allowed to sell token from your wallet type");
        }

        if ( _sellers[recipient] && sender_wallet.anti_dump ) {
            // This is for anti dump for all wallet

            // Director account restriction check.
            if (sender_wallet.wallet_type != type_of_wallet.DirectorWallet) {
                require((block.timestamp < (sender_wallet.last_sale_date + 1 days)) && ( sender_wallet.last_sale_date + amount > _max_sell_per_director_per_day ), "SCOM : Director can only send 10000 SCOM every 24 hours");
            }

            // General account restriction check.
            if (sender_wallet.wallet_type != type_of_wallet.GeneralWallet) {
                require(sender_wallet.concurrent_sale_day_count >= _max_concurrent_sale_day && block.timestamp >= sender_wallet.concurrent_sale_day_count + ( _colling_days * 1 days ), "SCOM : Concurrent sell for more than 6 days not allowed. You can not sell for next 72 Hours"); 
                require((block.timestamp < (sender_wallet.last_sale_date + 1 days)) && (( sender_wallet.lastday_total_sell + amount > _max_sell_amount || sender_wallet.lastday_total_sell + amount > ((_max_sell_per * sender_wallet.lastday_total_sell) / 100))), "SCOM : Can not sell more than 5000 SCOM or 5% of total SCOM of your account in past 24 hours.");
            }
        } 

    }

    function _after_transfer_updates(address sender, address recipient, uint256 amount) internal {
        wallet_details storage sender_wallet = _wallets[sender];
        wallet_details storage recipient_wallet = _wallets[recipient];

        // Updating last day sell and sell timestamp from block to manage antidump in future
        
        // For purchase Whale rule
        if ( _sellers[sender] ) {
            if (recipient_wallet.wallet_type == type_of_wallet.GeneralWallet) {
                recipient_wallet.purchase.add(amount);
            }
        }
        // For Antidump rule
        if ( _sellers[recipient] ) {
            // General wallet supporting entries
            if (sender_wallet.wallet_type == type_of_wallet.GeneralWallet) {
                if ( block.timestamp > (sender_wallet.last_sale_date + 1 days) ) {
                    sender_wallet.lastday_total_sell = 0; // reseting director sale at 24 hours 
                    if ( block.timestamp > (sender_wallet.last_sale_date + ( 2 * 1 days ) ) ) {
                        sender_wallet.concurrent_sale_day_count = 1;
                    } else {
                        sender_wallet.concurrent_sale_day_count.add(1);
                    }
                    sender_wallet.last_sale_date = block.timestamp;
                    sender_wallet.lastday_total_sell.add(amount);
                } else {
                    sender_wallet.lastday_total_sell.add(amount);
                }
            }
            // Director wallet supporting entries
            if (sender_wallet.wallet_type != type_of_wallet.DirectorWallet) {
                if ( block.timestamp > (sender_wallet.last_sale_date + 1 days) ) {
                    sender_wallet.lastday_total_sell = 0; // reseting director sale at 24 hours 
                    sender_wallet.last_sale_date = block.timestamp;
                    sender_wallet.lastday_total_sell = sender_wallet.lastday_total_sell + amount;
                } else {
                    sender_wallet.lastday_total_sell = sender_wallet.lastday_total_sell + amount;
                }
            }
        }
    }

    function _fees(address sender, address recipient, uint256 amount) internal virtual returns (uint256, bool){
        if ( sender == _owner || sender == address(this) ) {
            return (0, true);
        }
        wallet_details storage sender_wallet = _wallets[sender];
        // wallet_details storage recipient_Wallet = _wallets[recipient];

        if ( sender_wallet.fee_apply == false ) {
            return (0, true);
        }

        uint256 total_fees = 0;
        uint256 marketing_fees = 0;
        uint256 development_fees = 0;
        uint256 holder_fees = 0;
        uint256 burn_amount = 0;

        // Calculate fees based on whale or not whale
        if (sender_wallet.balance >= _whale_per && sender_wallet.antiwhale_apply == true ) {
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
        if ( _total_supply < (_initial_total_supply / 2) ) {
            total_fees = total_fees.sub(burn_amount);
            burn_amount=0;
        }

       bool sender_fee_deduct = false;

        if (sender_wallet.balance >= amount + total_fees) {
            if (marketing_fees > 0 ) {
                _wallets[_marketing_wallet].balance = _wallets[_marketing_wallet].balance.add(marketing_fees);
                emit Transfer(sender, _marketing_wallet, marketing_fees);
            }
            
            if ( development_fees > 0 ) {
                _wallets[_development_wallet].balance = _wallets[_development_wallet].balance.add(development_fees);
                emit Transfer(sender, _development_wallet, development_fees);
            }

            if ( holder_fees > 0 ) {
                _wallets[_holder_fee_airdrop_wallet].balance = _wallets[_holder_fee_airdrop_wallet].balance.add(holder_fees);
                emit Transfer(sender, _holder_fee_airdrop_wallet, holder_fees);
            }

            if ( burn_amount > 0) {
                _total_supply = _total_supply.sub(burn_amount);
                _burning_till_now = _burning_till_now.add(burn_amount);
                emit Burn(sender, burn_amount);
                emit Transfer(sender, address(0), burn_amount); 
            }
            sender_fee_deduct = true;
        } else {
            if (marketing_fees > 0 ) {
                _wallets[_marketing_wallet].balance = _wallets[_marketing_wallet].balance.add(marketing_fees);
                emit Transfer(recipient, _marketing_wallet, marketing_fees);
            }
            
            if ( development_fees > 0 ) {
                _wallets[_development_wallet].balance = _wallets[_development_wallet].balance.add(development_fees);
                emit Transfer(recipient, _development_wallet, development_fees);
            }

            if ( holder_fees > 0 ) {
                _wallets[_holder_fee_airdrop_wallet].balance = _wallets[_holder_fee_airdrop_wallet].balance.add(holder_fees);
                emit Transfer(recipient, _holder_fee_airdrop_wallet, holder_fees);
            }

            if ( burn_amount > 0) {
                _total_supply = _total_supply.sub(burn_amount);
                _burning_till_now = _burning_till_now.add(burn_amount);
                emit Burn(recipient, burn_amount);
                emit Transfer(recipient, address(0), burn_amount); 
            }
        }

        return (total_fees, sender_fee_deduct);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "SCOM: transfer from the zero address");
        require(recipient != address(0), "SCOM: transfer to the zero address");
        require(_wallets[sender].balance >= amount, "SCOM: transfer amount exceeds balance");

        if ( _wallets[sender].wallet_type ==  type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
            _create_wallet(sender, type_of_wallet.GeneralWallet, true, true, true, false);
        }
        if ( _wallets[recipient].wallet_type ==  type_of_wallet.UndefinedWallet) {
            // Initializing customer wallet if not in contract
             _create_wallet(recipient, type_of_wallet.GeneralWallet, true, true, true, false);
        }

        // checking SCOM rules before transfer 
        _checkrules(sender, recipient, amount);

        uint256 total_fees;
        bool sender_fee_deduct;
        (total_fees, sender_fee_deduct) = _fees(sender, recipient, amount);

        if ( sender_fee_deduct == true ) {
            uint256 r_amount = amount.add(total_fees);
            _wallets[sender].balance = _wallets[sender].balance.sub(r_amount);
            _wallets[recipient].balance = _wallets[recipient].balance.add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            uint256 r_amount = amount.sub(total_fees);
            _wallets[sender].balance = _wallets[sender].balance.sub(amount);
            _wallets[recipient].balance = _wallets[recipient].balance.add(r_amount);
            emit Transfer(sender, recipient, r_amount);
        }
        
        _after_transfer_updates(sender, recipient, amount);
    }
}

// First Beta Test Contract ID: 0x51909A05F2C3De211014161E96E6bC8FA96f313D