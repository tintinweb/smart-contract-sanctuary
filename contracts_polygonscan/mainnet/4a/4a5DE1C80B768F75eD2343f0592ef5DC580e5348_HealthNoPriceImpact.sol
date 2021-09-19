/**
 *Submitted for verification at polygonscan.com on 2021-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Part: Uniswap/[email protected]/IUniswapV2Pair

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
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


interface IBorrow{
    function shares(uint) external view returns(uint);
    function vaultAddress() external view returns(address);
    function lpToken() external view returns(IUniswapV2Pair);
    function bankcurrency() external view returns(address);
}

interface IVault{
    function getPricePerFullShare() external view returns(uint);
}

contract HealthNoPriceImpact{
    address public owner = 0x2981bb8f2883a462C5c413DE604C3B3e36884800;
    
    mapping(address=>address) public contracts;
    
    function setContract(address _b, address _c) external{
        require(msg.sender == owner, "not owner");
        contracts[_b] = _c;
    }
    
    function health(address _borrow, uint id) external view returns(uint256){
        if(contracts[_borrow] == address(0)){
            IBorrow borrow = IBorrow(_borrow);
            uint shares = borrow.shares(id);
            address vault = borrow.vaultAddress();
            IUniswapV2Pair lpToken = borrow.lpToken();
            address bankcurrency = borrow.bankcurrency();
            uint pps = IVault(vault).getPricePerFullShare();
            uint lps = shares*pps/1e18;
            uint lpSupply = lpToken.totalSupply(); // Ignore pending mintFee as it is insignificant
        
            // 2. Get the pool's total supply of WBNB and farming token.
            (uint r0, uint r1, ) = lpToken.getReserves();
            (uint totalBankCurrency, uint totalBtc) = lpToken.token0() == bankcurrency ? (r0, r1) : (r1, r0);
            // 3. Convert the position's LP tokens to the underlying assets.
            uint userBankCurrency = lps*totalBankCurrency/lpSupply;
            uint userBtc = lps*totalBtc/lpSupply;
            // 4. Convert all farming tokens to BNB and return total BNB.
            return(userBtc*totalBankCurrency/totalBtc+userBankCurrency);
        }
        return HealthNoPriceImpact(contracts[_borrow]).health(_borrow, id);
    }
}