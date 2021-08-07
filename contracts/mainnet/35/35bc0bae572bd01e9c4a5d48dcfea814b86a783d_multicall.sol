/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface erc20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function allowance(address, address) external view returns (uint);
}

interface ve {
    function locked__end(address) external view returns (uint);
    function deposit_for(address, uint) external;
    function locked(address) external view returns (uint);
    function get_last_user_slope(address) external view returns (uint);
}

interface proxy {
    function weights(address) external view returns (uint);
    function gauges(address) external view returns (address);
    function votes(address, address) external view returns (uint);
    function totalWeight() external view returns (uint);
    function usedWeights(address) external view returns (uint);
}

interface gauge {
    function earned(address) external view returns (uint);
}

interface pool {
    function get_balances() external view returns (uint[2] memory);
    function get_virtual_price() external view returns (uint);
    function coins(uint) external view returns (address);
}

interface faucet {
    function earned(address) external view returns (uint);
    function getRewardForDuration() external view returns (uint);
}

interface fee {
    function time_cursor() external view returns (uint);
    function ve_for_at(address, uint) external view returns (uint);
    function token_last_balance() external view returns (uint);
    function ve_supply(uint) external view returns (uint);
}

interface dist {
    function claimable(address) external view returns (uint);
}

contract multicall {
    address constant _proxy = 0x90aAb6C9D887A7Ff8320e56fbd1F4Ff80A0811d5;
    address constant _faucet = 0x7d254d9aDC588126edaEE52a1029278180A802E8;
    address constant _fee = 0x27761EfEb0C7b411e71d0fd0AeE5DDe35c810CC2;
    address constant _dist = 0x15E61581AFa2707bca42Bae529387eEa11f68E6e;
    
    struct call {
        uint balanceOf;
        address gaugeContract;
        uint userRewards;
        uint userGaugeBalance;
        uint gaugeVotes;
        uint userGaugeVotes;
        uint[2] poolBalances;
        uint userPoolBalance;
        string poolSymbol;
        uint virtualPrice;
        uint poolGaugeAllowance;
        address coin0;
        string coin0Symbol;
        uint8 coin0Decimals;
        uint coin0Balance;
        uint coin0GaugeAllowance;
        address coin1;
        string coin1Symbol;
        uint8 coin1Decimals;
        uint coin1Balance;
        uint coin1GaugeAllowance;
    }
    
    struct info {
        string symbol;
        string name;
        uint8 decimals;
        uint balanceOf;
        uint approvalAmount;
    }
    
    struct vesting {
        uint locked;
        uint balanceOf;
        uint lastUserSlope;
        uint totalSupply;
        uint totalGaugeVotes;
        uint totalUserVotes;
        uint earned;
        uint totalRewards;
        uint faucetTotalSupply;
        uint faucetBalanceOf;
        uint timeCursor;
        uint veAtSnapshot;
        uint tokenLastBalance;
        uint veTotalSupply;
        uint claimable;
    }
    
    function _getAssetInfos(address[] memory _asset, address[] memory _account, address[] memory _dest) external view returns (info[] memory _i) {
        _i = new info[](_asset.length);
        for (uint i = 0; i < _asset.length; i++) {
            _i[i] = _getAssetInfo(_asset[i], _account[i], _dest[i]);
        }
    }
    
    function _getAssetInfo(address _asset, address _account, address _dest) public view returns (info memory _i) {
        _i.symbol = erc20(_asset).symbol();
        _i.name = erc20(_asset).name();
        _i.decimals = erc20(_asset).decimals();
        _i.balanceOf = erc20(_asset).balanceOf(_account);
        _i.approvalAmount = erc20(_asset).allowance(_account, _dest);
    }
    
    function _getVestingInfo(address _contract, address _account) external view returns (vesting memory _v) {
        _v.locked = ve(_contract).locked(_account);
        _v.balanceOf = erc20(_contract).balanceOf(_account);
        _v.lastUserSlope = ve(_contract).get_last_user_slope(_account);
        _v.totalSupply = erc20(_contract).totalSupply();
        _v.totalGaugeVotes = proxy(_proxy).totalWeight();
        _v.totalUserVotes = proxy(_proxy).usedWeights(_account);
        _v.earned = faucet(_faucet).earned(_account);
        _v.totalRewards = faucet(_faucet).getRewardForDuration();
        _v.faucetTotalSupply = erc20(_faucet).totalSupply();
        _v.faucetBalanceOf = erc20(_faucet).balanceOf(_account);
        _v.timeCursor = fee(_fee).time_cursor();
        _v.veAtSnapshot = fee(_fee).ve_for_at(_account, _v.timeCursor);
        _v.tokenLastBalance = fee(_fee).token_last_balance();
        _v.veTotalSupply = fee(_fee).ve_supply(_v.timeCursor);
        _v.claimable = dist(_dist).claimable(_account);
    }
    
    function asset_balances(address _account, address _asset, address _pool) external view returns (call memory _c) {
       _c.balanceOf = erc20(_asset).balanceOf(_account); 
       _c.gaugeContract = proxy(_proxy).gauges(_asset);
       _c.userRewards = gauge(_c.gaugeContract).earned(_account);
       _c.userGaugeBalance = erc20(_c.gaugeContract).balanceOf(_account);
       _c.gaugeVotes = proxy(_proxy).weights(_c.gaugeContract);
       _c.userGaugeVotes = proxy(_proxy).votes(_account, _pool);
       _c.poolBalances = pool(_pool).get_balances();
       _c.userPoolBalance = erc20(_pool).balanceOf(_account);
       _c.poolSymbol = erc20(_pool).symbol();
       _c.virtualPrice = pool(_pool).get_virtual_price();
       _c.poolGaugeAllowance = erc20(_pool).allowance(_account, _c.gaugeContract);
       _c.coin0 = pool(_pool).coins(0);
       _c.coin0Symbol = erc20(_c.coin0).symbol();
       _c.coin0Decimals = erc20(_c.coin0).decimals();
       _c.coin0Balance = erc20(_c.coin0).balanceOf(_account);
       _c.coin0GaugeAllowance = erc20(_c.coin0).allowance(_account, _pool);
       _c.coin1 = pool(_pool).coins(1);
       _c.coin1Symbol = erc20(_c.coin1).symbol();
       _c.coin1Decimals = erc20(_c.coin1).decimals();
       _c.coin1Balance = erc20(_c.coin1).balanceOf(_account);
       _c.coin1GaugeAllowance = erc20(_c.coin1).allowance(_account, _pool);
    }
}