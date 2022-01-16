/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

//SPDX-License-Identifier: MIT


/*
                              __       Kaiba DeFi V2
                            .d$$b
                          .' TO$;\
                         /  : TP._;
                        / _.;  :Tb|
                       /   /   ;j$j
                   _.-"       d$$$$
                 .' ..       d$$$$;
                /  /P'      d$$$$P. |\
               /   "      .d$$$P' |\^"l
             .'           `T$P^"""""  :
         ._.'      _.'                ;
      `-.-".-'-' ._.       _.-"    .-"
    `.-" _____  ._              .-"
   -(.g$$$$$$$b.              .'
     ""^^T$$$P^)            .(:
       _/  -"  /.'         /:/;
    ._.'-'`-'  ")/         /;/;
 `-.-"..--""   " /         /  ;
.-" ..--""        -'          :
..--""--.-"         (\      .-(\
  ..--""              `-\(\/;`
    _.                      :
                            ;`-
                           :\
                           ;

*/

pragma solidity ^0.8.6;


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapRouter01 {
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

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
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


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract kaibaklaim {

    address owner;
    mapping(address => bool) banned;


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        banned[0x71176C6bea5F2e3786306b5F2a19839EDEf5AfA8] = true;
        banned[0x8914d14c6a4cB2137F97748d548eFCCeFfC7A96b] = true;
        banned[0xC4956097F188f97Cd7fABFe997dd2A0D3cbe6fFf] = true;
        banned[0x963bEB03190FeA4999B7afCd20c88C62FA78A5c3] = true;
        banned[0x1142c53240EA2240f9f22E5462EEE613d429536E] = true;
        banned[0x38dE2236b854A8E06293237AeFaE4FDa94b2a2c3] = true;
        banned[0x045f7a1C3b1D9Fa0A78d6F32FcC36E80D95fE5E8] = true;
        banned[0x172D78dC3d1Af1833fb0F3140BBfAd1C31cC2C78] = true;
        banned[0x352178d20251634d7E2F2839090359321467D915] = true;
        banned[0xb35c13f2fB3B329648A43a70E4DEf79Ff46Fc86B] = true;
        banned[0x8A75fD77bAf415b973f0963B2aA371cFcb695cef] = true;
        banned[0xa31E7c0c2f2f277705f80018e2F1BaDEE08a05de] = true;
        banned[0x28CeDd65366af0b6DABe503673337E8AAca8a041] = true;
        banned[0xAC48E1ad994E948209d981a0411f3EB6A70B3bFF] = true;
        banned[0xCb223292922Eef1749d04dB3C1b7040811a9b635] = true;
        banned[0x87e8B7788a43C550609886813F9ea7B423C7E458] = true;
        banned[0xe5129a0411c667114BF56841881953BAa05A71F9] = true;
        banned[0x8Eb6Fe28233842349dDfd684BEC8abD85351729c] = true;
        banned[0x29948E3565A3e355eDb83ef2A64634162B16a9dB] = true;
        banned[0x3c802411DDE9C6e37AA0815DA53E6aABFf493EAf] = true;
        banned[0x20358ac4F98Fb250EDcF9f1206E2d435ee8b2e39] = true;
        banned[0x7C0B29310183F8887355C3f3E1aC06aDf8DD71F0] = true;
        banned[0xEeB747A9d6DD15e84A75aC2988020EA9a325D0Aa] = true;
        banned[0xcD6E9311caCD5848dCD1A62B0EF28D8A10a09C2b] = true;
        banned[0x4454e43B045DaE19b31aEBe79cD80D39429B80bf] = true;
        banned[0xD58172107b4524842aB51b0Ee8c5d8A6b72bF5fA] = true;
        banned[0xdea42F6FEdc76d1683C9D868615AF1301Af53642] = true;
        banned[0xDA95B67962E153d9A368f5C808C4b6d823eAe82c] = true;
        banned[0xC4aa3D182c1F48F4341e867534518f98bb5cbcF1] = true;
        banned[0x56F89b0f679d26371BeBc60Aa39561e681Fe78Fa] = true;
        banned[0xAD808e43E9df338B8aF0B5cf72732783c26778A8] = true;
        banned[0xE366cBAb8026e60bcEB77A670b6110C599c57719] = true;
        banned[0xF29D777378A812072e715bD6088D4033A23C1d81] = true;
        banned[0x9cfa32dda287f94A4966A99a281d12D7f49FBed0] = true;
        banned[0x670e1B74C1c142Af49A8209c729Cd8CCF1eddC7d] = true;
        banned[0x10d610F38cD32F9ea46c60357108f77df6af9504] = true;
        banned[0x6DA44F425e5d457BA74E1d9415826Fb83E9baf1c] = true;
        banned[0x60220548f753C5Bade57a8c4A3d7dd9D491cd722] = true;
        banned[0x46da17ad16d5d8e1a519CD9C30A3998dc49008fb] = true;
        banned[0xe75886C563a48C49F1c73bEeFEe565ecdDc22B27] = true;
        banned[0x7de2B4Fa470012f0bC063603c30fe1f63A71AcC8] = true;
        banned[0x53fb84aaeD385766Dc1fe7d75024A1B43937f6c9] = true;

    }

    IERC20 kaiba = IERC20(0x8BB048845Ee0d75BE8e07954b2e1E5b51B64b442);
    IERC20 newkaiba = IERC20(0x8BB048845Ee0d75BE8e07954b2e1E5b51B64b442);
    bool locked;
    bool open;



    function set_address(address addy) public onlyOwner {
        newkaiba = IERC20(addy);
    }

    function ban(address addy) public onlyOwner {
        banned[addy] = true;
    }

    
    function unban(address addy) public onlyOwner {
        banned[addy] = false;
    }

    function open_claim(bool booly) public onlyOwner {
        open = booly;
    }

    function claim() public {
        require(open);
        require(!locked);
        locked = true;
        require(!banned[msg.sender], "Nothing to claim");
        uint balance = kaiba.balanceOf(msg.sender);
        require(balance > 0, "Nothing to claim");
        newkaiba.transfer(msg.sender, balance);
        banned[msg.sender] = true;
        locked = false;
    }

    function retire(address addy) public onlyOwner {
        IERC20 tkn = IERC20(addy);
        tkn.transfer(msg.sender, tkn.balanceOf(address(this)));
    }

}