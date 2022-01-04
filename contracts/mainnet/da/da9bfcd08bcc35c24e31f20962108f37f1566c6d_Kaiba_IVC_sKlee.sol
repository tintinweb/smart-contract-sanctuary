/**
 *Submitted for verification at Etherscan.io on 2022-01-02
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


contract Kaiba_IVC_sKlee {
    using SafeMath for uint256;

    bool locked;
    mapping(address => bool) is_team;
    mapping(address => mapping(uint256 => bool)) public can_synth;
    mapping(address => mapping(string => uint256)) public estimated_paid;

     modifier safe() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyTeam {
        require(is_team[msg.sender]);
        _;
    }

    address public owner;
    mapping (address => bool) is_synthetizer;
    bool synth_open;

    constructor() {
        owner = msg.sender;
        is_team[owner] = true;
        is_synthetizer[owner] = true;
        ERC20 from_erc = ERC20(0x382f0160c24f5c515A19f155BAc14d479433A407);
        klee.deployed = true;
        klee.totalSupply = from_erc.totalSupply();
        klee.balance_url = "";
        klee.original_token = 0x382f0160c24f5c515A19f155BAc14d479433A407;
        klee.pair_address = 0x8044E86CA1963E099a7E70594D72bC96a088Fed2;
        klee.name = from_erc.name();
        klee.ticker = from_erc.symbol();  
    }

    struct SVT_Synth { // This struct defines a typical SVT token
        bool deployed;
        string balance_url;
        address tokenOwner;
        uint256 totalSupply;
        uint256 circulatingSupply;
        bytes32 name;
        bytes32 ticker;
        bool isBridged;
        address original_token;
        address pair_address;
        address SVT_Liquidity_storage;
        mapping(address => bool) synthesis_control;
    }

    
        SVT_Synth klee;
         

    function grant_synth(address addy, bool booly) public onlyTeam {
        is_synthetizer[addy] = booly;
    }

    function modify_svt_klee(address to_bridge, address pair, string calldata url) public safe {
        require(is_synthetizer[msg.sender] || synth_open, "Unauthorized");
        ERC20 from_erc = ERC20(to_bridge);
        klee.deployed = true;
        klee.totalSupply = from_erc.totalSupply();
        klee.balance_url = url;
        klee.original_token = to_bridge;
        klee.pair_address = pair;
        klee.name = from_erc.name();
        klee.ticker = from_erc.symbol();        
     }


     function operate_svt_klee_update(string calldata url) public {
        require(is_synthetizer[msg.sender], "Not authorized");
        require(klee.deployed, "No assets");
        klee.balance_url = url;
    }

    function start_retrieve(address addy, string calldata hashed) payable public {
        estimated_paid[addy][hashed] = msg.value;
    }

    function gas_paid(address addy, string calldata hashed) public view returns (uint256) {
        return estimated_paid[addy][hashed];
    }

    function get_synthetic_svt_liquidity() external  view returns (address, address, uint256, uint256) {
        require(klee.deployed, "SVT Token does not exist");
        IUniswapV2Pair pair = IUniswapV2Pair(klee.pair_address);
        address token0_frompair = pair.token0();
        address token1_frompair = pair.token1();
        (uint Res0, uint Res1,) = pair.getReserves();
        return(token0_frompair, token1_frompair, Res0, Res1);
    }



}