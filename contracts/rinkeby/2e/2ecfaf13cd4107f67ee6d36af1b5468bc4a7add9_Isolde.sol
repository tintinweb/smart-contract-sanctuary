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
    event Buyback();

    // router
    IUniswapV2Router public router;
    
    // addresses & fees
    uint public platformFee = 30;
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
        require(address(this).balance >= 0.01 ether, 'min threshold not met');
        require(address(this).balance >= ethAmount, 'low balance');
        require(token != address(0), 'buyback address not set');

        uint256 fee = ethAmount * platformFee / 100;
        ethAmount = ethAmount - fee;
        
        _swapEthForTokens(ethAmount, tokenAmount);
        _sendEthToTreasury(fee);
        
        emit Buyback();
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
    
    function setPlatformFee(uint newFee) public onlyOwner {
        require(newFee <= 30, 'maximum fee exceeded');
        platformFee = newFee;
    }
}