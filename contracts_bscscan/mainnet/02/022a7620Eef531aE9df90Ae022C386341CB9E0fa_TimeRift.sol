// SPDX-License-Identifier: I-I-N-N-N-N-NFINITYYY!!
pragma solidity ^0.7.6;

import "./OctaDahlia.sol";
import "./ITimeRift.sol";
import "./IFlowerFeeSplitter.sol";
import "./IUniswapV2Factory.sol";

contract TimeRift is MultiOwned, ITimeRift {

    address private dev6;
    address private dev9;
    IUniswapV2Factory public uniswapFactory;
    IFlowerFeeSplitter public splitter;
    uint256 public dabPercent;

    uint256 public lastNonce;
    mapping (uint256 => OctaDahlia) public nonces; // nonce -> flower
    mapping (address => IUniswapV2Pair) public pools; // flower -> pool
    mapping (address => bool) public MGEs; // MGE Contract -> y/n
    mapping (address => bool) public balancers; // address that can call BalancePrices

    event OctaDahliaCreated(address indexed flower, address paired, address pool);

    constructor(address _dev6, address _dev9, IUniswapV2Factory _uniswapFactory) { 
        dev6 = _dev6;
        dev9 = _dev9;
        uniswapFactory = _uniswapFactory;
        setInitialOwners(msg.sender, _dev6, _dev9);
        dictator = true;
    }

    // Enable mint and burn for Market Generation Contracts that launch upOnly tokens
    function enableMge(address _mge, bool _enable) public ownerSOnly() {
        MGEs[_mge] = _enable;
    }

    function enableBalancer(address _balancer, bool _enable) public ownerSOnly() {
        balancers[_balancer] = _enable;
    }

    function setFlowerFeeSplitter(IFlowerFeeSplitter _flowerFeeSplitter) public ownerSOnly() {
        splitter = _flowerFeeSplitter;
    }
    
    function setDabPercent(uint256 _dabPercent) public ownerSOnly() {
        dabPercent = _dabPercent;
    }

    function OctaDahliaGrowsBrighter(IERC20 pairedToken, uint256 startingLiquidity, uint256 startingTokenSupply, bool dictate, uint256 burnRate, uint256 maxBuyPercent) public override ownerSOnly() returns (address) {
        OctaDahlia Dahlia = new OctaDahlia();
        lastNonce++;
        nonces[lastNonce] = Dahlia;
        IUniswapV2Pair pool = IUniswapV2Pair(uniswapFactory.createPair(address(Dahlia), address(pairedToken)));
        pools[address(Dahlia)] = pool;
        Dahlia.balanceAdjustment(true, startingTokenSupply, address(pool));
        pairedToken.transferFrom(msg.sender, address(pool), startingLiquidity);
        Dahlia.balanceAdjustment(true, startingTokenSupply, msg.sender);
        pool.mint(address(this));
        address mge = MGEs[msg.sender] ? msg.sender : address(0);
        Dahlia.setUp(pool, dev6, dev9, mge, dictate, burnRate, maxBuyPercent);
        splitter.registerFlower(address(Dahlia), address(pairedToken));
        pairedToken.approve(address(splitter), uint(-1));
        emit OctaDahliaCreated(address(Dahlia), address(pairedToken), address(pool));
        return address(Dahlia);
    }

    function balancePrices(uint256[] memory noncesToBalance) public {
        require (balancers[msg.sender] || MGEs[msg.sender]);
        uint256 safeLength = noncesToBalance.length;
        OctaDahlia Dahlia;
        uint256 amount;
        for (uint i = 0; i < safeLength; i++) {
            Dahlia = nonces[noncesToBalance[i]];
            amount = Dahlia.alignPrices();
            if (Dahlia.mge() == address(0)) {
                splitter.depositFees(address(Dahlia), amount);
            }
        }
    }

    function whoNeedsBalance() public view returns (uint256[] memory) {
        uint256[] memory toBalance = new uint256[](lastNonce);
        OctaDahlia dahlia;
        uint256 poolBalance;
        uint256 trueSupply;
        uint256 dif;
        uint256 count = 0;
        for (uint256 i = 1; i <= lastNonce; i++) {
            dahlia = nonces[i];
            poolBalance = dahlia.balanceOf(address(pools[address(dahlia)]));
            trueSupply = dahlia.totalSupply() - poolBalance;
            dif = trueSupply > poolBalance ? trueSupply - poolBalance : poolBalance - trueSupply;
            if (dif * 9970 / trueSupply > dabPercent) {
                toBalance[count++] = i;
            }
        }
        return toBalance;
    }

    function recoverTokens(IERC20 token) public ownerSOnly() {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}