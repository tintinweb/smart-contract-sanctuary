/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity 0.6.12;


// def _update_liquidity_limit(addr: address, l: uint256, L: uint256):
//     """
//     @notice Calculate limits which depend on the amount of CRV token per-user.
//             Effectively it calculates working balances to apply amplification
//             of CRV production by CRV
//     @param addr User address
//     @param l User's amount of liquidity (LP tokens)
//     @param L Total amount of liquidity (LP tokens)
//     """
//     # To be called after totalSupply is updated
//     _voting_escrow: address = self.voting_escrow
//     voting_balance: uint256 = ERC20(_voting_escrow).balanceOf(addr)
//     voting_total: uint256 = ERC20(_voting_escrow).totalSupply()

//     lim: uint256 = l * TOKENLESS_PRODUCTION / 100
//     if (voting_total > 0) and (block.timestamp > self.period_timestamp[0] + BOOST_WARMUP):
//         lim += L * voting_balance / voting_total * (100 - TOKENLESS_PRODUCTION) / 100

//     lim = min(l, lim)
//     old_bal: uint256 = self.working_balances[addr]
//     self.working_balances[addr] = lim
//     _working_supply: uint256 = self.working_supply + lim - old_bal
//     self.working_supply = _working_supply

//     log UpdateLiquidityLimit(addr, l, L, lim, _working_supply)

contract MockTestCurve {
    uint256 public TOKENLESS_PRODUCTION = 40;
    // uint256 public BOOST_WARMUP = 2 * 7 * 86400;
    uint256 public BOOST_WARMUP = 10 minutes;
    uint256[] public period_timestamp = [100000000000000000000000000000];
    
    uint256 public working_supply;
    
    mapping(address => uint256) public working_balances;
    
    
    event UpdateLiquidityLimit(address user,uint256 original_balance,uint256 original_supply,uint256 working_balance,uint256 working_supply);
    
    constructor() public {
        period_timestamp[0] = block.timestamp;
    }
    
    function update_liquidity_limit(address addr, uint256 l, uint256 L) public {
        uint256 voting_balance = 2000 * 1e18;
        uint256 voting_total = 2000 * 1e18;
        
        uint256 lim = l * TOKENLESS_PRODUCTION / 100;
        
        if (voting_total > 0 && block.timestamp > period_timestamp[0] + BOOST_WARMUP) {
            lim += L * voting_balance / voting_total * (100 - TOKENLESS_PRODUCTION) / 100;
        }
        
        lim = min(l, lim);
        
        uint256 old_bal = working_balances[addr];
        working_balances[addr] = lim;
        uint256 _working_supply = working_supply + lim - old_bal;
        working_supply = _working_supply;
        
       emit UpdateLiquidityLimit(addr, l, L, lim, _working_supply);
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}