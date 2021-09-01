pragma solidity ^0.8.6;

// SPDX-License-Identifier: Apache-2.0

import "./UniswapRouter.sol";

contract Isolde {
    
    modifier onlyOwner {
        require(msg.sender == _owner, "caller is not the owner");
        _;
    }
    
    // tier struct
    struct Tier {
        string name;
        uint8 level;
        uint256 price;
    }
    
    // events
    event Subscribed(address wallet, uint8 level, uint256 time);
    event Buyback(uint256 ethAmount, uint256 tokenAmount);
    event Beacon(uint256 timestamp);

    // router
    IUniswapV2Router public router;
    
    // addresses & allocation
    uint public revenueAllocation = 30;
    address private DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD; 
    address public token;
    address payable public treasury;
    address private _owner;
    
    // subs and tiers
    Tier[] private _tiers;
    uint public lastSubTime = block.timestamp;

    
    constructor (address routerAddress, address tokenAddress, address payable treasuryAddress) {
        _owner = msg.sender;
        
        router = IUniswapV2Router(routerAddress);
        token = tokenAddress;
        treasury = treasuryAddress;
    }
    
    function setTiers(Tier[] memory tiers) public onlyOwner {
        delete _tiers;
        
        for (uint i = 0; i < tiers.length; ++i) {
            Tier memory tier = tiers[i];
            _tiers.push(Tier(tier.name, tier.level, tier.price));
        }
    }

    function getTiers() public view returns (Tier[] memory) {
        return _tiers;
    }
    
    function viewTier(uint level) public view returns (string memory, uint, uint) {
        require(level > 0 && level <= _tiers.length, 'wrong tier');
        Tier memory tier = _tiers[level - 1];
        return (tier.name, tier.level, tier.price);
    }
    
    function subscribe(address who, uint8 level) public payable { // since who isn't msg.sender someone can possibly gift a subscribtion
        require(level > 0 && level <= _tiers.length, 'wrong tier');
        require(msg.value == _tiers[level - 1].price, 'sent ether is different from tier price');
        
        lastSubTime = block.timestamp;
        emit Subscribed(who, level, 30);
    }
    
    function _swapEthForTokens(uint256 ethAmount, uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        
        path[0] = router.WETH();
        path[1] = token;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount} (
            tokenAmount,
            path,
            address(DEAD_ADDRESS),
            block.timestamp
        );
    }
    
    function _sendEthToTreasury(uint256 amount) private {
        treasury.transfer(amount);
    }
    
    function rescueEth() public onlyOwner {
        require(block.timestamp - lastSubTime >= 30 days, 'less than a month since last sub');
        _sendEthToTreasury(address(this).balance);
    }
    
    function buyback(uint256 ethAmount, uint256 tokenAmount) public onlyOwner {
        require(address(this).balance >= 1 ether, 'balance for min threshold not met');
        require(address(this).balance >= ethAmount, 'low balance');
        require(token != address(0), 'buyback address not set');

        uint256 treasuryAllocation = ethAmount * revenueAllocation / 100;
        ethAmount = ethAmount - treasuryAllocation;
        
        _swapEthForTokens(ethAmount, tokenAmount);
        _sendEthToTreasury(treasuryAllocation);
        
        emit Buyback(ethAmount, tokenAmount);
    }
    
    function sendBeacon() public onlyOwner {
        emit Beacon(block.timestamp);
    }
    
    function setRouter(address payable newRouter) public onlyOwner {
        router = IUniswapV2Router(newRouter);
    }
    
    function setToken(address newToken) public onlyOwner {
        token = newToken;
    }
    
    function setTreasury(address payable newTreasury) public onlyOwner {
        treasury = newTreasury;
    }
    
    function setRevenueAllocation(uint newAllocation) public onlyOwner {
        require(newAllocation > 0, 'revenue allocation should be greater than 0');
        require(newAllocation <= 90, 'maximum allocation exceeded');
        revenueAllocation = newAllocation;
    }
    
    receive() external payable {}
}