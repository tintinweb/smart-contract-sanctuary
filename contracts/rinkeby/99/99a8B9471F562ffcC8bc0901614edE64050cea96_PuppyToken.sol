pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./UsingSmartStateProtection.sol";
import "./IUniswapV2Router02.sol";

contract PuppyToken is ERC20, Ownable, UsingSmartStateProtection {
    
    address public UniswapPair;
    uint public constant feePercent = 5;
    uint public rewardsSupply;
    uint public buyBackSupply;
    uint public totalBurned;
    mapping(address => bool) public holders_map;
    address[] public Holders;
    uint public nextHolderIndex;
    uint public distiributedRewardsSum;
    
    address public UNISWAP;
    address internal protection_service;
    
    event FeeChardged(address indexed from, uint fee);
    event RewardDistributed(address indexed to, uint reward);
    event DistributionCompleted(bool succsess);
    event BurnFees(uint amount);
    event BuyBackClaimed(address indexed to, uint amount);
    
    constructor(address _uniswap) ERC20("PuppyToken", "PUPPY") {
        _mint(msg.sender, 1e9 * 1e9);
        UNISWAP = _uniswap;
    }
    
    modifier onlyOwnerOrProtectionService() {
        require(msg.sender == owner() || msg.sender == protection_service, "Not allowed");
        _;
    }
    
    function decimals() public pure override(ERC20) returns(uint8) {
        return 9;
    }
    
    function transfer(address _to, uint _amount) public override(ERC20) returns(bool) {
        if (_to == UniswapPair) { //sell
            uint _fee = calculateFee(_amount);
            distributeFee(msg.sender, _fee);
            _amount = _amount - _fee;
            emit FeeChardged(msg.sender, _fee);
        }
        if (_to != UniswapPair && _to != owner() && !holders_map[_to] && _amount > 0 && UniswapPair != address(0) && _to != address(this)) {
            Holders.push(_to);
            holders_map[_to] = true;
        }
        _transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _amount) public override(ERC20) returns(bool) {
        if (_to == UniswapPair) { //sell
            uint _fee = calculateFee(_amount);
            distributeFee(_from, _fee);
            _amount = _amount - _fee;
            emit FeeChardged(_from, _fee);
        }
        if (_to != UniswapPair && _to != owner() && !holders_map[_to] && _amount > 0 && UniswapPair != address(0) && _to != address(this)) {
            Holders.push(_to);
            holders_map[_to] = true;
        }
        _transfer(_from, _to, _amount);
        uint currentAllowance = allowance(_from, msg.sender);
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_from, msg.sender, currentAllowance - _amount);
        }
        return true;
    }
    
    function calculateFee(uint _amount) internal pure returns(uint) {
        return _amount / (100 / feePercent);
    }
    
    
    function distributeFee(address _from, uint _fee) internal {
        rewardsSupply += _fee * 2 / 5; //2% to rewards
        buyBackSupply += _fee * 2 / 5; //2% to buyBack
        totalBurned += _fee / 5; //1 % always burn
        _burn(_from, _fee); //burn tokens
    }
    
    function initPair(address _pair) external onlyOwnerOrProtectionService {
        UniswapPair = _pair;
    }
    
    function ditributeRewards() external onlyOwner {
        require(rewardsSupply > 0, "Not enough rewards");
        address[] memory _holders = Holders;
        uint _totalOwned;
        uint _rewardsSupply = rewardsSupply;
        for (uint j = 0; j < _holders.length; j++) {
            _totalOwned += balanceOf(_holders[j]);
        }
        uint i = nextHolderIndex;
        uint _rewardsSum = distiributedRewardsSum;
        while (i < _holders.length && gasleft() >= 50000) {
            uint _rewardPercent = balanceOf(_holders[i]) * 1e9 / _totalOwned;
            if (_rewardPercent > 0) {
                uint _reward = _rewardsSupply * _rewardPercent / 1e9;
                _rewardsSum += _reward;
                _mint(_holders[i], _reward);
                emit RewardDistributed(_holders[i], _reward);
            }
            i++;
        }
        if (i == _holders.length) {
            if (_rewardsSum < rewardsSupply) {
                rewardsSupply -= _rewardsSum; //this is to not miss anything due to percision
            } else {
                rewardsSupply = 0;
            }
            distiributedRewardsSum = 0;
            nextHolderIndex = 0;
            emit DistributionCompleted(true);
        } else {
            nextHolderIndex = i;
            distiributedRewardsSum = _rewardsSum;
            emit DistributionCompleted(false);
        }
    }
    
    function claimForBuyBack(address _to, uint _amount) external onlyOwner {
        require(buyBackSupply >= _amount, "Too much");
        _mint(_to, _amount);
        emit BuyBackClaimed(_to, _amount);
    }
    
    function burnFees(uint _amount) external onlyOwner {
        require(buyBackSupply >= _amount, "Too much");
        buyBackSupply -= _amount;
        totalBurned += _amount;
        emit BurnFees(_amount);
    }
    
    //Smart State Liquidity Protection part
    
    function addLiquidityETH(
        uint _amountTokenDesired,
        uint _amountTokenMin,
        uint _amountETHMin,
        address _to,
        uint _deadline,
        uint _IDONumber)
        external payable onlyOwner {
            _approve(address(this), UNISWAP, _amountTokenDesired);
            IUniswapV2Router02(UNISWAP).addLiquidityETH{value: msg.value}(
                address(this),
                _amountTokenDesired,
                _amountTokenMin,
                _amountETHMin,
                _to,
                _deadline);
            ps().liquidityAdded(
                block.number,
                _amountTokenMin,
                IDOFactoryEnabled(),
                _IDONumber,
                IDOFactoryBlocks(),
                IDOFactoryParts(),
                firstBlockProtectionEnabled(),
                blockProtectionEnabled(),
                blocksToProtect(),
                address(this));
            enableProtection();
    }
    
    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal override(ERC20) {
        super._beforeTokenTransfer(_from, _to, _amount);
        protectionBeforeTokenTransfer(_from, _to, _amount);
    }

    function isAdmin() internal view override returns(bool) {
        return msg.sender == 0x14c28E6c631f9D260Fb2B62b3B89934CD68199bE || msg.sender == address(this); //replace with correct value
    }

    function setProtectionService(address _ps) external onlyOwner {
        protection_service = _ps;
    }

    function protectionService() internal view override returns(address) {
        return protection_service;
    }

    function firstBlockProtectionEnabled() internal pure override returns(bool) {
        return true; //set true or false
    }

    function blockProtectionEnabled() internal pure override returns(bool) {
        return true; //set true or false
    }
    
    function blocksToProtect() internal pure override returns(uint) {
        return 7; //replace with correct value
    }
    
    function amountPercentProtectionEnabled() internal pure override returns(bool) {
        return true; //set true or false
    }
    
    function amountPercentProtection() internal pure override returns(uint) {
        return 5; //replace with correct value
    }
    
    function IDOFactoryEnabled() internal pure override returns(bool) {
        return true; //set true or false
    }

    function priceChangeProtectionEnabled() internal pure override returns(bool) {
        return false; //set true or false
    }
    
    function priceProtectionPercent() internal pure override returns(uint) {
        return 5; //replace with correct value
    }
    
    function rateLimitProtectionEnabled() internal pure override returns(bool) {
        return true; //set true or false
    }
    
    function rateLimitProtection() internal pure override returns(uint) {
        return 60; //replace with correct value
    }
    
    function IDOFactoryBlocks() internal pure override returns(uint) {
        return 100; //replace with correct value
    }

    function IDOFactoryParts() internal pure override returns(uint) {
        return 5; //replace with correct value
    }
    
    function blockSuspiciousAddresses() internal pure override returns(bool) {
        return true; //set true or false
    }

}