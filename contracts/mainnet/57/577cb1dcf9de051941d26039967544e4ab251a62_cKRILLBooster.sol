/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0<0.9.0;

interface IERC20 {
    function approve(address _spender, uint256 _tokens) external returns (bool);
    function balanceOf(address who) external returns (uint256);
}

interface ICompounder {
    function buy(uint256 _amount) external returns (uint256);
    function disburse(uint256 _amount) external;
    function withdraw() external returns (uint256);
    function dividendsOf(address _user) external returns (uint256);
}

interface IClaimable {
    function claim() external;
}

interface IStakingRewards {
    function deposit(uint256 _amount) external;
}

contract cKRILLBooster {
    address public krill;       // address of the KRILL token
    address public cKrill;      // address of the cKRILL token
    address public liquidity;   // address of the LP token
    address public whalesGame;  // address of the whales game contract
    address public staking;     // address of the LP staking contract

    constructor (address _krill, address _cKrill, address _liquidity, address _whalesGame, address _staking) {
        krill = _krill;
        cKrill = _cKrill;
        liquidity = _liquidity;
        whalesGame = _whalesGame;
        staking = _staking;

        IERC20(krill).approve(cKrill, type(uint256).max);       // max out approval for KRILL tokens
        IERC20(liquidity).approve(staking, type(uint256).max);  // max out approval for LP tokens
    }

    // if any applicable tokens are held by this contract, it should be able to deposit them
    function _depositAssets ()
    internal {
        uint LPBalance = IERC20(liquidity).balanceOf(address(this));    // load LP balance into memory

        if(LPBalance > 0)                                               // are there any LP tokens?
            IStakingRewards(staking).deposit(LPBalance);             // deposit the entire amount into the StakingRewards contract

        uint krillBalance = IERC20(krill).balanceOf(address(this));      // load KRILL balance into memory

        if(krillBalance > 0 )                                           // is there any krill here dumped from another contract?
            ICompounder(cKrill).buy(krillBalance);                          // buy cKRILL with whatever balance is held
    }

    // claim rewards from NFTs, staking, and cKRILL position (creating an 'echo' of rewards)
    function _claimRewardsAndDisburse()
    internal {
        IClaimable(staking).claim();    // Claim rewards from the LP staking contract
        IClaimable(whalesGame).claim(); // Claim rewards from the whales game contract

        if(ICompounder(cKrill).dividendsOf(address(this)) > 0)      // If this contract has rewards to claim
            ICompounder(cKrill).withdraw();                         // Claim rewards from the cKRILL held by this contract

        uint krillBalance = IERC20(krill).balanceOf(address(this)); // load KRILL balance into memory
        
        if(krillBalance > 0)                                // is there any krill here dumped from another contract?
            ICompounder(cKrill).disburse(krillBalance);     // disburse KRILL balance into compounder - the booster earns rewards from its own position creating an 'echo' of rewards
    }

    // process() function for additional incentive layer
    // however, anyone with a cKRILL position will be incentivized once the contract earns enough
    function process()
    external {
        _depositAssets();
        _claimRewardsAndDisburse();
    }
 }