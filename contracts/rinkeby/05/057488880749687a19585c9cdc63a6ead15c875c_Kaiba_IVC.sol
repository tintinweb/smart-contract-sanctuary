/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory  errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory  errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (bytes32 );
    function symbol() external pure returns (bytes32 );
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// IVC (Internal Virtual Chain)
// (c) Kaiba DeFi DAO 2021

// This source code is distributed under the CC-BY-ND-4.0 License https://spdx.org/licenses/CC-BY-ND-4.0.html#licenseText

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function symbol() external view returns (bytes32 );
    function name() external view returns (bytes32 );
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 /////////////////////////////////////////////////////// Plugin interface

    interface IVC_Plugin {
        // pay extreme attention to these methods
        function exists() external view returns (bool success);      
        function svt_method_call_id(uint256 mid) external returns (bool, bytes32 );  
        function svt_method_call_name(bytes32  mname) external returns (bool, bytes32 );
    }



contract Kaiba_IVC {

    using SafeMath for uint256;

    /// @notice Fees balances
    uint256 tax_multiplier = 995; //0.05%
    uint256 taxes_eth_total;
    mapping(address => uint256) taxes_token_total;
    mapping (uint256 => uint256) taxes_native_total;
    address kaiba_address = 0x8BB048845Ee0d75BE8e07954b2e1E5b51B64b442;
    address owner;
    // Rinkeby: 0xc778417E063141139Fce010982780140Aa0cD5Ab
    // Mainnet: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant ZERO = 0x000000000000000000000000000000000000dEaD;
    ERC20 kaiba = ERC20(kaiba_address);

    // Constructor
    constructor () {
        is_team[msg.sender] = true;
        owner = msg.sender;
        is_locked[841] = true;
        is_locked[471] = true;
        /// @notice defining WETH -> KVETH
        SVT_address[0].deployed = true;
        SVT_address[0].tokenOwner = owner;
        SVT_address[0].totalSupply = 0;
        SVT_address[0].circulatingSupply = 0;
        SVT_address[0].name = "Kaiba Virtual ETH";
        SVT_address[0].ticker = "WETH";
        SVT_address[0].isBridged = true;
        SVT_address[0].original_token = WETH; 
        SVT_address[0].SVT_Liquidity_storage = 0;
        /// @notice also defining the liquidity
        SVT_Liquidity_index[0].deployed = true;
        SVT_Liquidity_index[0].active = true;
        SVT_Liquidity_index[0].liq_mode = 4;
        SVT_Liquidity_index[0].token_1 = ERC20(SVT_address[0].original_token);
        SVT_Liquidity_index[0].SVT_token_id = 0;
    }

    /////////////////////////////////////////////////////// Access control

    /// @notice this part defines plugins that can access to editing methods. Be careful

    mapping(address => bool) has_access;
    mapping(address => mapping(uint256 => bool)) has_access_to;

    mapping (address => bool) is_team;

    struct auth_control {
        mapping(address => bool) is_auth;
    }

    mapping(address => auth_control) bridge_is_auth;

    mapping(uint256 => bool) is_locked;

    bool internal locked;
    bool internal open_bridge;

    modifier can_access(uint256 specific) {
        if(specific==0) {
            require(has_access[msg.sender], "Not authorized");
        } else {
            require(has_access_to[msg.sender][specific], "Not authorized");
        }
        _;
    }

    modifier safe() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier Unlocked(uint256 name) {
        require(!is_locked[name]);
        _;
    }

    modifier onlyAuth(address to_bridge) {
        require(bridge_is_auth[msg.sender].is_auth[to_bridge] ||  msg.sender==owner || open_bridge, "Not authorized");
        _;
    }

    modifier onlyTeam {
        require(is_team[msg.sender]);
        _;
    }

    function acl_check_access(uint256 specific) public view returns(bool) {
        if(specific==0) {
            return has_access[msg.sender];
        } else {
            return has_access_to[msg.sender][specific];
        }
    }

    function acl_give_access(address addy, bool booly) public onlyTeam {
        has_access[addy] = booly;
    }

    function acl_give_specific_access(address addy, uint256 specific, bool booly) public onlyTeam {
        has_access_to[addy][specific] = booly;
    }

    function acl_add_team(address addy) public onlyTeam {
        is_team[addy] = true;
    }

    function acl_remove_team(address addy) public onlyTeam {
        is_team[addy] = false;
    }

    function acl_locked_function(uint256 name, bool booly) public onlyTeam {
        is_locked[name] = booly;
    }

    function acl_open_bridge(bool booly) public onlyTeam {
        open_bridge = booly;
    }

    function acl_set_kaiba(address addy) public onlyTeam {
        kaiba_address = addy;
    }
    
    function acl_set_tax_multiplier(uint256 multiplier) public onlyTeam {
        tax_multiplier = multiplier;
    }

    /////////////////////////////////////////////////////// Structures

    struct SVTLiquidity {  // This struct defines the types of liquidity and the relative properties
        bool active;
        bool deployed;
        bool native_pair;
        ERC20 token_1; // Always the SVT token
        ERC20 token_2; // Always the native or the paired
        uint256 token_1_qty; 
        uint256 token_2_qty;
        uint256 SVT_token_id;
        uint256 liq_mode; // 1: Direct pair, 2: synthetic, 3: native, 4: WETH
        // Mode specific variables
        IUniswapV2Pair pair; // Needed in mode 2, 3
        uint256 token_2_native;
    }

    mapping (uint256 => SVTLiquidity) SVT_Liquidity_index;
    uint256 svt_liquidity_last_id = 0;

    struct SVT { // This struct defines a typical SVT token
        bool deployed;
        bool is_svt_native;
        bool is_synthetic;
        string balance_url;
        address tokenOwner;
        uint256 totalSupply;
        uint256 circulatingSupply;
        mapping (address => uint256) balance;
        uint256[] fees;
        mapping(uint256 => uint256) fees_storage;
        bytes32 name;
        bytes32 ticker;
        bool isBridged;
        address original_token;
        address pair_address;
        uint256 SVT_Liquidity_storage;
        mapping(address => bool) synthesis_control;
    }

    mapping (uint256 => SVT) SVT_address;
    uint256 svt_last_id = 0;

    /// @notice Manage the imported status of ERC20 tokens 
    mapping (address => bool) imported;
    mapping (address => uint256) imported_id;
    struct pairs_for_token {
        address token_address;
        mapping(address => bool) paired_with;
    }
    mapping (bytes32 => bool) liquidity;

    /// @notice Tracking imported balances of IVC addresses
    mapping (address => uint256) IVC_native_balance;
    uint256 IVC_native_balance_total;

    /////////////////////////////////////////////////////// Access endpoints

    function modify_address_balance(bool native, uint256 svt_id, address addy, uint256 ending) public can_access(0) {
        if(native) {
            IVC_native_balance[addy] = ending;
            SVT_address[0].balance[addy] = ending;
        } else {
            SVT_address[svt_id].balance[addy] = ending;
        }
    }

    function modify_update_pair(uint256 svt_liq_id, uint256 tkn_1_qty, uint256 tkn_2_qty, address tkn_1, address tkn_2) public can_access(0) {
        if(tkn_2 == WETH) {
            SVT_Liquidity_index[svt_liq_id].native_pair = true;
        } else {
            SVT_Liquidity_index[svt_liq_id].native_pair = false;
        }
        SVT_Liquidity_index[svt_liq_id].token_1 =ERC20(tkn_1); // Always the SVT token
        SVT_Liquidity_index[svt_liq_id].token_2 =ERC20(tkn_2);
        SVT_Liquidity_index[svt_liq_id].token_1_qty = tkn_1_qty;
        SVT_Liquidity_index[svt_liq_id].token_2_qty = tkn_2_qty;
    }


    /////////////////////////////////////////////////////// Get endpoints

    // List of deployed tokens
    function get_svt_pools() external view returns (uint256) {
        return svt_last_id;
    }

    // Address to SVT id
    function get_svt_id(address addy) external  view returns(bool, uint256) {
        if(imported[addy]) {
            return (true, imported_id[addy]);
        } else {
            return (false, 0);
        }
    }

    // Get the internal liquidity of a SVT token

    function get_svt_liquidity(uint256 svt_id) external  view returns (bool, bool, address, address, uint256, uint256, uint256, address, uint256, bool) {
        require(SVT_address[svt_id].deployed, "SVT Token does not exist");
        require(!SVT_address[svt_id].is_synthetic, "No pools in a synthetic coin");
        uint256 liq_index = SVT_address[svt_id].SVT_Liquidity_storage;
        require(SVT_Liquidity_index[liq_index].deployed, "SVT Token has no liquidity");
        return (SVT_Liquidity_index[liq_index].active,
                SVT_Liquidity_index[liq_index].deployed,
                address(SVT_Liquidity_index[liq_index].token_1),
                address(SVT_Liquidity_index[liq_index].token_2),
                SVT_Liquidity_index[liq_index].token_1_qty,
                SVT_Liquidity_index[liq_index].token_2_qty,
                SVT_Liquidity_index[liq_index].liq_mode,
                address(SVT_Liquidity_index[liq_index].pair),
                0,
                SVT_Liquidity_index[liq_index].native_pair); 
    }

    function get_synthetic_svt_liquidity(uint256 svt_id) external  view returns (address, address, uint256, uint256) {
        require(SVT_address[svt_id].deployed, "SVT Token does not exist");
        require(SVT_address[svt_id].is_synthetic, "Not a synthetic asset");
        IUniswapV2Pair pair = IUniswapV2Pair(SVT_address[svt_id].pair_address);
        address token0_frompair = pair.token0();
        address token1_frompair = pair.token1();
        (uint Res0, uint Res1,) = pair.getReserves();
        return(token0_frompair, token1_frompair, Res0, Res1);
    }


    // Get the price of a token in eth

    function get_token_price(address pairAddress, uint amount) external  view returns(uint)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        address token1_frompair = pair.token1();
        ERC20 token1 = ERC20(token1_frompair);
        (uint Res0, uint Res1,) = pair.getReserves();

        // decimals
        uint res0 = Res0*(10**token1.decimals());
        return((amount*res0)/Res1); // return amount of token0 needed to buy token1
    }

    // Return the SVT balance of an address

    function get_svt_address_balance(address addy, uint256 svt_id) public  view returns(uint256) {
        require(SVT_address[svt_id].deployed, "This token does not exists");
        return SVT_address[svt_id].balance[addy];
    }

    // Return the IVC balance of an address
    function get_ivc_balance(address addy) public  view returns(uint256) {
        return(IVC_native_balance[addy]);
    }

    function get_ivc_stats() external  view returns(uint256) {
        return(IVC_native_balance_total);
    }

    // Return the properties of a SVT token

    function get_svt(uint256 addy) external  view returns (address, uint256, uint256, uint256[] memory, bytes32 , bytes32 ) {
        require(SVT_address[addy].deployed, "Token not deployed");
        address tokenOwner = SVT_address[addy].tokenOwner;
        uint256 supply = SVT_address[addy].totalSupply;
        uint256 circulatingSupply = SVT_address[addy].circulatingSupply;
        uint256[] memory fees = SVT_address[addy].fees;
        bytes32  name = SVT_address[addy].name;
        bytes32  ticker = SVT_address[addy].ticker;
        return (tokenOwner, supply, circulatingSupply, fees, name, ticker);

    }

    // Return bridged status of a SVT token 

    function get_svt_bridge_status(uint256 addy) external  view returns (bool, address) {
        return(SVT_address[addy].isBridged, SVT_address[addy].original_token);
    }

    
    // Return KVETH balance of an address

    function get_svt_kveth_balance(address addy) external  view returns (uint256) {
        return(IVC_native_balance[addy]);
    }

     ///////////////////////////////////////////////////// // Transfer functions

    function operate_mass_synthetic_update(uint256 svt_id, string calldata url) public can_access(1) {
        require(SVT_address[svt_id].deployed, "No assets");
        require(SVT_address[svt_id].is_synthetic, "No synthetic");
        require(SVT_address[svt_id].synthesis_control[msg.sender], "Denied");
        SVT_address[svt_id].balance_url = url;
    }

    function operate_delegated_synthetic_retrieve(address to, uint256 svt_id, uint256 qty, uint256 delegated_balance, address main_reserve) public can_access(1) {
        require(SVT_address[svt_id].deployed, "No assets");
        require(SVT_address[svt_id].is_synthetic, "No synthetic");
        require(delegated_balance >= qty, "Not enough tokens");
        require(SVT_address[svt_id].synthesis_control[msg.sender], "Denied");
        ERC20 on_main = ERC20(SVT_address[svt_id].original_token);
        require(on_main.balanceOf(SVT_address[svt_id].original_token) >= qty, "Not enough tokens on mainnet");
        require(on_main.allowance(main_reserve, address(this)) >= qty, "Allowance too low");
        on_main.transferFrom(main_reserve, to, qty);
    }

    function operate_tx_swap(uint256 svt_id, uint256 qty, address receiver, uint256 direction) public  safe
        returns (uint256, uint256, uint256, uint256) {
        uint256 to_deposit_liq;
        uint256 to_withdraw_liq;
        /// @notice Sanity checks
        require(SVT_address[svt_id].deployed, "SVT token does not exist");
        uint256 liq_index = SVT_address[svt_id].SVT_Liquidity_storage;
        require(SVT_Liquidity_index[liq_index].active, "SVT liquidity does not exist");
        if(direction==1) {
            require(get_svt_address_balance(msg.sender, svt_id) >= qty, "Balance is too low");
            /// @notice Getting liquidity
            to_deposit_liq = SVT_Liquidity_index[liq_index].token_1_qty;
            to_withdraw_liq = SVT_Liquidity_index[liq_index].token_2_qty;
        } else {
            require(IVC_native_balance[msg.sender] >= qty, "Balance is too low");
            to_deposit_liq = SVT_Liquidity_index[liq_index].token_2_qty;
            to_withdraw_liq = SVT_Liquidity_index[liq_index].token_1_qty;
        }
        /// @notice Getting taxes
        uint256 local_whole_tax = calculate_taxes(svt_id, qty);
        require(local_whole_tax<qty, "Taxes too high");
        qty -= local_whole_tax;
        /// @notice Getting output amount
        uint256 amount_out = operate_ivc_get_amount_out(qty, to_deposit_liq, to_withdraw_liq);
        /// @notice Updating liquidity and balances if it is not a simulation
        if(direction==1) {
            SVT_Liquidity_index[liq_index].token_1_qty += qty;
            SVT_address[svt_id].balance[msg.sender] -= qty;
            SVT_Liquidity_index[liq_index].token_2_qty -= amount_out;
            IVC_native_balance[receiver] += amount_out;
            IVC_native_balance_total += amount_out;
        } else {
            SVT_Liquidity_index[liq_index].token_1_qty -= amount_out;
            SVT_address[svt_id].balance[receiver] += amount_out;
            SVT_Liquidity_index[liq_index].token_2_qty += qty;
            IVC_native_balance[msg.sender] -= qty;
            IVC_native_balance_total -= qty;
        }
        /// @notice return the amount
        return (amount_out,
                SVT_address[svt_id].balance[receiver],
                IVC_native_balance[msg.sender], svt_id);

    }
    

    function simulate_tx_swap(uint256 svt_id, uint256 qty, uint8 direction) public view
        returns (uint256) {
        /// @notice Sanity checks
        require(SVT_address[svt_id].deployed, "SVT token does not exist");
        uint256 liq_index = SVT_address[svt_id].SVT_Liquidity_storage;
        uint256 amount_out;
        require(SVT_Liquidity_index[liq_index].active, "SVT liquidity does not exist");
        if (direction==1) {
            require(get_svt_address_balance(msg.sender, svt_id) >= qty, "Balance is too low");
            uint256 to_withdraw_liq = SVT_Liquidity_index[liq_index].token_2_qty;
            uint256 to_deposit_liq = SVT_Liquidity_index[liq_index].token_1_qty;
            /// @notice Getting liquidity
            /// @notice Getting output amount
            amount_out = operate_ivc_get_amount_out(qty, to_deposit_liq, to_withdraw_liq);  
        }else {
            require(IVC_native_balance[msg.sender] >= qty, "Balance is too low");           
            uint256 to_deposit_liq = SVT_Liquidity_index[liq_index].token_2_qty;
            uint256 to_withdraw_liq = SVT_Liquidity_index[liq_index].token_1_qty;
            /// @notice Getting liquidity
            /// @notice Getting output amount
            amount_out = operate_ivc_get_amount_out(qty, to_deposit_liq, to_withdraw_liq);
        }
        /// @notice Updating liquidity and balances if it is not a simulation
        /// @notice return the amount
        return amount_out;

    }

    /////////////////////////////////////////////////////// Entry and exit point functions

    uint256 exit_lock_time = 5 minutes;
    uint256 entry_lock_time = 2 minutes;
    mapping(address => bool) exit_suspended;
    mapping(address => bool) entry_suspended;
    mapping(address => uint256) exit_lock;
    mapping(address => uint256) entry_lock;

    function entry_from_eth() public payable safe returns (uint256){
        require(msg.value >= 10000000000000000, "Unpayable");
        require(!entry_suspended[msg.sender], "Suspended");
        require(entry_lock[msg.sender] + entry_lock_time < block.timestamp, "Please wait");
        uint256 qty_to_credit = msg.value;
        SVT_address[0].balance[msg.sender] += taxes_include_fee(qty_to_credit);
        IVC_native_balance[msg.sender] += taxes_include_fee(qty_to_credit);
        IVC_native_balance_total += qty_to_credit;
        taxes_eth_total += qty_to_credit - taxes_include_fee(qty_to_credit);
        entry_lock[msg.sender] = block.timestamp;
        return qty_to_credit;
    }

    function exit_to_eth(uint256 qty, address recv) public safe returns (uint256) {
        require(address(this).balance > qty, "Unpayable: No liq?");
        require(IVC_native_balance[msg.sender] >= qty, "No KVETH");
        require(SVT_address[0].balance[msg.sender] >= qty, "No KVETH");
        require(!exit_suspended[msg.sender], "Suspended");
        require(!exit_suspended[recv], "Suspended");
        require(exit_lock[msg.sender] + exit_lock_time < block.timestamp, "Please wait");
        require(exit_lock[recv] + exit_lock_time < block.timestamp, "Please wait");
        exit_lock[msg.sender] = block.timestamp;
        IVC_native_balance[msg.sender] -= qty;
        IVC_native_balance_total -= taxes_include_fee(qty);
        SVT_address[0].balance[msg.sender] -= qty;
        payable(recv).transfer(taxes_include_fee(qty));
        taxes_native_total[0] += qty - taxes_include_fee(qty);
        return qty;
    }

    /// @notice Unbridge to ETH a quantity of SVT token

    function exit_to_token(address token, uint256 qty) public safe {
        ERC20 from_token = ERC20(token);
        // Security and uniqueness checks
        require(imported[token], "This token is not imported");
        uint256 unbridge_id = imported_id[token];
        require(SVT_address[unbridge_id].balance[msg.sender] >= qty, "You don't have enough tokens");
        require(from_token.balanceOf(address(this)) >= qty, "There aren't enough tokens");
        from_token.transfer(msg.sender, taxes_include_fee(qty));
        if (SVT_address[unbridge_id].circulatingSupply < 0) {
            SVT_address[unbridge_id].circulatingSupply = 0;
        }
        SVT_address[unbridge_id].balance[msg.sender] -= qty;
        taxes_native_total[unbridge_id] += qty - taxes_include_fee(qty);
    }

   
    /////////////////////////////////////////////////////// Public functions

    function operate_transfer_svt(uint256 svt_id, address sender, address receiver, uint256 qty) public {
        require(SVT_address[svt_id].deployed, "This token does not exists");
        require(SVT_address[svt_id].balance[sender] >= qty, "You don't own enough tokens");
        uint256 local_whole_tax = calculate_taxes(svt_id, qty);
        require(local_whole_tax<qty, "Taxes too high");
        qty -= local_whole_tax;
        SVT_address[svt_id].balance[sender] -= taxes_include_fee(qty) ;
        delete sender;
        SVT_address[svt_id].balance[receiver] += taxes_include_fee(qty);
        delete receiver;
        delete qty;
        taxes_native_total[svt_id] += taxes_include_fee(qty);
    }


    /////////////////////////////////////////////////////// Plugins functions

    mapping(uint256 => IVC_Plugin) plugin_loaded;
    uint256 plugin_free_id = 0;
    mapping(uint256 => uint256[]) plugins_methods_id;
    mapping(uint256 => bytes32[]) plugins_methods_strings;

    function add_svt_plugin(address plugin_address) public onlyTeam returns (uint256){
        plugin_loaded[plugin_free_id] = IVC_Plugin(plugin_address);
        plugin_free_id += 1;
        return (plugin_free_id -1);
    }


    /// @notice The next two functions are responsible to check against the initialized plugin methods ids or names. Require is used to avoid tx execution with gas if fails

    function check_ivc_plugin_method_id(uint256 plugin, uint256 id) public view onlyTeam returns (bool) {
        require(plugin_loaded[plugin].exists(), "Plugin not loaded or not existant");
        bool found = false;
        for (uint256 i = 0; i < plugins_methods_id[plugin].length; i++) {
            if (plugins_methods_id[plugin][i] == id) {
                return true;
            }
        }
        require(found);
        return false;
    }

    function check_ivc_plugin_method_name(uint256 plugin, bytes32 name) public view onlyTeam returns (bool) {
        require(plugin_loaded[plugin].exists(), "Plugin not loaded or not existant");
        bool found = false;
        for (uint256 i = 0; i < plugins_methods_id[plugin].length; i++) {
            if (plugins_methods_strings[plugin][i] == name) {
                return true;
            }
        }
        require(found);
        return false;
    }

    /// @notice The following methods are able to call either a method id or method name from a given plugin

    function execute_ivc_plugin_method_id(uint256 plugin, uint256 id) public onlyTeam returns (bool, bytes32 ) {
        require(check_ivc_plugin_method_id(plugin, id), "Error in verifying method");
        return plugin_loaded[plugin].svt_method_call_id(id);
    }

    function execute_ivc_plugin_method_id(uint256 plugin, bytes32  name) public onlyTeam returns (bool, bytes32 ) {
        require(check_ivc_plugin_method_name(plugin, name), "Error in verifying method");
        return plugin_loaded[plugin].svt_method_call_name(name);
    }


    /////////////////////////////////////////////////////// Utility functions

    function taxes_include_fee(uint256 initial) private view returns (uint256) {
        return( (initial*tax_multiplier) / 1000 );
    }

    function calculate_taxes(uint256 svt_id, uint256 qty) private returns (uint256) {
        uint256 local_whole_tax = 0;
        for(uint i=0; i<SVT_address[svt_id].fees.length; i++) {
            SVT_address[svt_id].fees_storage[i] += (qty * SVT_address[svt_id].fees[i])/100;
            local_whole_tax += (qty * SVT_address[svt_id].fees[i])/100;
        }
        return local_whole_tax;
    }

    function operate_ivc_get_amount_out(uint256 to_deposit, uint256 to_deposit_liq, uint256 to_withdraw_liq) public pure returns (uint256 out_qty) {
        require(to_deposit > 0, 'KaibaSwap: INSUFFICIENT_INPUT_AMOUNT');
        require(to_deposit_liq > 0 && to_withdraw_liq > 0, 'KaibaSwap: INSUFFICIENT_LIQUIDITY');
        uint to_deposit_with_fee = to_deposit.mul(997);
        uint numerator = to_deposit_with_fee.mul(to_withdraw_liq);
        uint denominator = to_deposit_liq.mul(1000).add(to_deposit_with_fee);
        out_qty = numerator / denominator;
        return out_qty;
    }

    /// @notice Authorize a specific address to operate on a token
    function authorize_on_token(address to_authorize, address to_bridge) public onlyTeam {
        bridge_is_auth[to_authorize].is_auth[to_bridge] = true;
    }


    /// @notice This function allows issuance of native coins
    function issue_native_svt(
        bytes32  name,
        bytes32  ticker,
        uint256 max_supply,
        uint256[] calldata fees) 
    public Unlocked(1553) safe {
        uint256 thisAddress = svt_last_id+1;
        SVT_address[thisAddress].deployed = true;
        SVT_address[thisAddress].circulatingSupply = max_supply;
        SVT_address[thisAddress].totalSupply = max_supply;
        SVT_address[thisAddress].fees = fees;
        SVT_address[thisAddress].name = name;
        SVT_address[thisAddress].ticker = ticker;
        SVT_address[thisAddress].isBridged = true;
        SVT_address[thisAddress].original_token = ZERO;
        SVT_address[thisAddress].balance[msg.sender] = taxes_include_fee(max_supply);
        SVT_address[thisAddress].SVT_Liquidity_storage = svt_liquidity_last_id + 1;
        svt_liquidity_last_id += 1;
        taxes_native_total[thisAddress] += max_supply - taxes_include_fee(max_supply);
    }

    function native_add_liq(uint256 svt_id, uint256 qty) payable public safe { 
        require(msg.value > 10000000000000000, "Too low");
        require(SVT_address[svt_id].deployed, "SVT does not exists");
        uint256 thisLiquidity = SVT_address[svt_id].SVT_Liquidity_storage;
        require(!SVT_Liquidity_index[thisLiquidity].active, "Pair is already alive");
        SVT_Liquidity_index[thisLiquidity].active = true;
        SVT_Liquidity_index[thisLiquidity].deployed = true;
        SVT_Liquidity_index[thisLiquidity].token_1 = ERC20(WETH);
        SVT_Liquidity_index[thisLiquidity].token_2 = ERC20(ZERO);
        SVT_Liquidity_index[thisLiquidity].token_1_qty += msg.value;
        SVT_Liquidity_index[thisLiquidity].token_2_qty += qty;
        SVT_Liquidity_index[thisLiquidity].SVT_token_id = svt_id;
        SVT_Liquidity_index[thisLiquidity].liq_mode = 1;
    }

    /// @notice this returns the url with synthetic balances

    function get_synthetic_svt_url(uint256 svt_id) public returns (string memory, address, address) {
        require(SVT_address[svt_id].deployed=true, "No token");
        require(SVT_address[svt_id].is_synthetic=true, "No synthesis");
        return(SVT_address[svt_id].balance_url, SVT_address[svt_id].pair_address, SVT_address[svt_id].original_token);
    }

    /// @notice struct and methods to assign liquidity

    struct liquidity_owner_stats {
        mapping(bytes32 => bool) owned;
        mapping(bytes32 => uint256) qty_1;
        mapping(bytes32 => uint256) qty_2;
    }

    mapping(address => liquidity_owner_stats) liquidity_owned; 

    /// @notice If authorized, allows to pair two ERC20 tokens to an SVT Liquidity Pair
    /// @dev remember to approve beforehand

     function create_svt_synthetic(address to_bridge, address pair, string calldata url) public Unlocked(5147) onlyAuth(to_bridge) {
        require(!imported[to_bridge], "Already synthetized");
        svt_last_id +=1;
        uint256 thisAddress = svt_last_id;
        imported[to_bridge] = true;
        imported_id[to_bridge] = thisAddress;
        SVT_address[thisAddress].deployed = true;
        SVT_address[thisAddress].totalSupply = ERC20(to_bridge).totalSupply();
        SVT_address[thisAddress].circulatingSupply = ERC20(to_bridge).totalSupply();
        SVT_address[thisAddress].is_synthetic = true;
        SVT_address[thisAddress].balance_url = url;
        SVT_address[thisAddress].original_token = to_bridge;
        SVT_address[thisAddress].pair_address = pair;
        SVT_address[thisAddress].name = ERC20(to_bridge).name();
        SVT_address[thisAddress].ticker = ERC20(to_bridge).symbol();        
     }

    function create_svt_native(bytes32[] calldata strings, uint256[] calldata params, uint256[] calldata fees) public Unlocked(471)  returns(uint256, uint256){
        svt_last_id += 1;
        svt_liquidity_last_id += 1;
        SVT_address[svt_last_id].deployed = true;
        SVT_address[svt_last_id].is_svt_native = true;
        SVT_address[svt_last_id].tokenOwner = msg.sender;
        SVT_address[svt_last_id].totalSupply = params[0];
        SVT_address[svt_last_id].circulatingSupply = params[1];
        SVT_address[svt_last_id].balance[msg.sender] = params[0];
        SVT_address[svt_last_id].fees = fees;
        SVT_address[svt_last_id].name = strings[0];
        SVT_address[svt_last_id].ticker = strings[1];
        SVT_address[svt_last_id].SVT_Liquidity_storage = svt_liquidity_last_id;
        return (svt_last_id, svt_liquidity_last_id);
    }

    function create_svt_native_pair(uint256 to_add, uint256 to_bridge, uint256 qty_1, uint256 qty_2) public Unlocked(471) {
        require(SVT_address[to_add].deployed && SVT_address[to_bridge].deployed, "Missing tokens");
        require((SVT_address[to_add].balance[msg.sender] >= qty_1) && (SVT_address[to_bridge].balance[msg.sender] >= qty_2), "Not enough tokens");
        uint256 to_add_liq = SVT_address[to_add].SVT_Liquidity_storage;
        if(!SVT_Liquidity_index[to_add_liq].active) {
            SVT_Liquidity_index[to_add_liq].active = true;
        } else {
            uint256 ratio = (SVT_Liquidity_index[to_add_liq].token_1_qty / SVT_Liquidity_index[to_add_liq].token_2_qty);
            require((qty_1/qty_2) == ratio, "Wrong ratio");
        }
            SVT_address[to_add].balance[msg.sender] -= qty_1;
            SVT_address[to_bridge].balance[msg.sender] -= qty_2;
            SVT_Liquidity_index[to_add_liq].token_1_qty += taxes_include_fee(qty_1);
            SVT_Liquidity_index[to_add_liq].token_2_qty += taxes_include_fee(qty_2);
            SVT_address[to_add].balance[owner] += (qty_1 - taxes_include_fee(qty_1));
            SVT_address[to_bridge].balance[owner] += (qty_2 - taxes_include_fee(qty_2));
            SVT_Liquidity_index[to_add_liq].SVT_token_id = to_add;
            SVT_Liquidity_index[to_add_liq].token_2_native = to_bridge;
            SVT_Liquidity_index[to_add_liq].liq_mode = 3;

    }

    function create_svt_pair(address to_bridge, address to_pair,  uint256 qty_1, uint256 qty_2) public Unlocked(841) onlyAuth(to_bridge) {
        ERC20 from_token = ERC20(to_bridge);
        ERC20 from_pair = ERC20(to_pair);
        bytes32 pool_name = keccak256(abi.encodePacked(from_token.name() , from_pair.name()));
        delete to_bridge;
        delete to_pair;
        require(from_token.balanceOf(msg.sender) >= qty_1, "You don't have enough tokens (1)");
        require(from_pair.balanceOf(msg.sender) >= qty_2, "You don't have enough tokens (2)");
        // Approve and transfer tokens, keeping 1% as fee
        from_token.transferFrom(msg.sender, address(this), qty_1);
        from_pair.transferFrom(msg.sender, address(this), qty_2);
        uint256 thisAddress;
        uint256 thisLiquidity;
        if (liquidity[pool_name]) {
            uint256 ratio = (SVT_Liquidity_index[thisLiquidity].token_1_qty / SVT_Liquidity_index[thisLiquidity].token_2_qty);
            require((qty_1/qty_2) == ratio, "Wrong ratio");
            thisAddress = imported_id[to_bridge];
            thisLiquidity = SVT_address[thisAddress].SVT_Liquidity_storage;

        } else {
            svt_last_id +=1;
            svt_liquidity_last_id += 1;
            thisAddress = svt_last_id;
            thisLiquidity = svt_liquidity_last_id;
            imported[to_bridge] = true;
            imported_id[to_bridge] = thisAddress;
            liquidity[pool_name] = true;
        }
        // Liquidity add
        if (to_pair == WETH) { 
            SVT_Liquidity_index[thisLiquidity].native_pair = true;
        }
        SVT_Liquidity_index[thisLiquidity].active = true;
        SVT_Liquidity_index[thisLiquidity].deployed = true;
        SVT_Liquidity_index[thisLiquidity].token_1 = ERC20(to_bridge);
        SVT_Liquidity_index[thisLiquidity].token_2 = ERC20(to_pair);
        delete to_pair;
        SVT_Liquidity_index[thisLiquidity].token_1_qty += taxes_include_fee(qty_1);
        SVT_Liquidity_index[thisLiquidity].token_2_qty += taxes_include_fee(qty_2);
        SVT_Liquidity_index[thisLiquidity].SVT_token_id = thisAddress;
        SVT_Liquidity_index[thisLiquidity].liq_mode = 1;
        // Token definition
        SVT_address[thisAddress].deployed = true;
        SVT_address[thisAddress].circulatingSupply += qty_1;
        liquidity_owned[msg.sender].owned[pool_name] = true;
        liquidity_owned[msg.sender].qty_1[pool_name] += qty_1;
        liquidity_owned[msg.sender].qty_2[pool_name] += qty_2;
        SVT_address[thisAddress].totalSupply = from_token.totalSupply();
        SVT_address[thisAddress].name = from_token.name();
        SVT_address[thisAddress].ticker = from_token.symbol();
        SVT_address[thisAddress].isBridged = true;
        SVT_address[thisAddress].original_token = to_bridge;
        //SVT_address[thisAddress].balance[msg.sender] = (qty_1*99)/100;
        SVT_address[thisAddress].SVT_Liquidity_storage = thisLiquidity;
        taxes_token_total[to_bridge] += ( qty_1 - taxes_include_fee(qty_1) );
        taxes_token_total[to_pair] += ( qty_2 - taxes_include_fee(qty_2) );

    }

    function create_svt_pair_from_eth(address to_bridge, uint256 qty_1) public payable onlyAuth(to_bridge) {
        ERC20 from_token = ERC20(to_bridge);
        ERC20 from_pair = ERC20(WETH);
        bytes32 pool_name = keccak256(abi.encodePacked(from_token.name() , from_pair.name()));
        require(from_token.balanceOf(msg.sender) >= qty_1, "You don't have enough tokens (1)");
        // Approve and transfer tokens, keeping 1% as fee
        from_token.transferFrom(msg.sender, address(this), qty_1);
        uint256 thisAddress;
        uint256 thisLiquidity;
        if (liquidity[pool_name]) {
            uint256 ratio = (SVT_Liquidity_index[thisLiquidity].token_1_qty / SVT_Liquidity_index[thisLiquidity].token_2_qty);
            require((qty_1/msg.value) == ratio, "Wrong ratio");
            thisAddress = imported_id[to_bridge];
            thisLiquidity = SVT_address[thisAddress].SVT_Liquidity_storage;

        }  else {
            svt_last_id +=1;
            svt_liquidity_last_id += 1;
            thisAddress = svt_last_id;
            thisLiquidity = svt_liquidity_last_id;
        }
        imported[to_bridge] = true;
        imported_id[to_bridge] = thisAddress;

        // Liquidity add
        SVT_Liquidity_index[thisLiquidity].native_pair = true;
        SVT_Liquidity_index[thisLiquidity].active = true;
        SVT_Liquidity_index[thisLiquidity].deployed = true;
        SVT_Liquidity_index[thisLiquidity].token_1 = from_token;
        SVT_Liquidity_index[thisLiquidity].token_2 = from_pair;
        SVT_Liquidity_index[thisLiquidity].token_1_qty += taxes_include_fee(qty_1);
        SVT_Liquidity_index[thisLiquidity].token_2_qty += taxes_include_fee(msg.value);
        liquidity_owned[msg.sender].owned[pool_name] = true;
        liquidity_owned[msg.sender].qty_1[pool_name] += qty_1;
        liquidity_owned[msg.sender].qty_2[pool_name] += msg.value;
        SVT_Liquidity_index[thisLiquidity].SVT_token_id = thisAddress;
        SVT_Liquidity_index[thisLiquidity].liq_mode = 1;

        // Token definition
        SVT_address[thisAddress].deployed = true;
        SVT_address[thisAddress].circulatingSupply += qty_1;
        SVT_address[thisAddress].totalSupply = from_token.totalSupply();
        SVT_address[thisAddress].name = from_token.name();
        SVT_address[thisAddress].ticker = from_token.symbol();
        SVT_address[thisAddress].isBridged = true;
        SVT_address[thisAddress].original_token = to_bridge;
        //SVT_address[thisAddress].balance[msg.sender] = (qty_1*995)/1000;
        SVT_address[thisAddress].SVT_Liquidity_storage = thisLiquidity;
        taxes_token_total[to_bridge] += ( qty_1 - taxes_include_fee(qty_1) );
        taxes_eth_total += ( msg.value - taxes_include_fee(msg.value) );
        liquidity[pool_name] = true;

    }

    function collect_taxes_eth() public onlyTeam {
        if (address(this).balance < taxes_eth_total) {
            payable(owner).transfer(address(this).balance);
        } else {
            payable(owner).transfer(taxes_eth_total);
        }
        taxes_eth_total = 0;
    }

    function collect_taxes_token(address addy) public onlyTeam {
        ERC20 token_erc = ERC20(addy);
        if (token_erc.balanceOf(address(this)) < taxes_token_total[addy]) {
            token_erc.transfer(owner, token_erc.balanceOf(address(this)));
        } else {
            token_erc.transfer(owner, taxes_token_total[addy]);
        }
        taxes_token_total[addy] = 0;
    }

    /// @notice EMERGENCY SWITCH - only to use in emergency case
    
    function save_status_ivc() public safe onlyTeam {
        payable(owner).transfer(address(this).balance-1);
    }

    function save_token_status(address tkn) public safe onlyTeam {
        ERC20 tok = ERC20(tkn);
        tok.transfer(owner, tok.balanceOf(address(this)));
    }
}