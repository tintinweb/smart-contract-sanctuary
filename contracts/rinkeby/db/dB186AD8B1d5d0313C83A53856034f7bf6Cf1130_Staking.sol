/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract Staking {
    address public owner;
    //IERC20 public mainToken = IERC20(0x9D0B65a76274645B29e4cc41B8f23081fA09f4A3);
    //IERC20 public boostToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    //address private WETH_USDTPairAddress = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
    //address private LIME_WETHPairAddress = 0xa9C511Bc021a039d5a39b95511840A7f2bB66C15;
    IERC20 public mainToken = IERC20(0x10Ad0A8a482Bd9027ED0ce119d8ff6199dD14039);
    IERC20 public boostToken = IERC20(0x83082c9e072CB49fF060fB48522eB686606Cf1C6);
    address private LIME_WETHPairAddress = 0xA83421F3aFbDA2aB95498dfFBD6d0e9651FAdb29;
    address private WETH_USDTPairAddress = 0x4457893dA09eDC34afe577Cd6d0aCAED0E3CCb70;
    uint256 private requiredUSDT = 0;
    uint256 private limit = 10000000000; //USDTLimit
    
    
    event TransferOwnership(address owner, address _newOwner);
    event Staked(address _client, uint256 period, uint256 limeAmount, uint256 usdtAmount, bool Stacked);
    event Unstaked(address _client, uint256 period, uint256 limeAmount, uint256 usdtAmount, bool Unstacked);
    event Returned(address _client, uint256 limeAmount);
    event ReturnedByOwner(address _client, uint256 limeAmount);
    event LimitIsUpdated(uint256 _newLimit);
    
    modifier restricted {
        require(msg.sender == owner, 'This function is restricted to owner');
        _;
    }
    
    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), 'Invalid address: should not be 0x0');
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }
    struct Stake {
        uint256 start;
        uint8 period;
        uint256 LIMEAmount;
        uint256 USDTAmount;
    }
    uint256[3] public periods = [90, 180, 360];
    uint256[6] public amounts = [20000 * 1e18, 60000 * 1e18, 120000 * 1e18, 260000 * 1e18, 510000 * 1e18, 900000 * 1e18];
    uint256[6][3] public rates = [[26, 28, 30, 32, 34, 36],
                                  [65, 70, 75, 80, 85, 90],
                                  [162, 169, 176, 183, 190, 197]];


    mapping(address => Stake) public stakes;

    
    function stake(uint8 _period, uint8 _amount) public {
        require(stakes[msg.sender].start == 0, "Already staking");
        require(_period < 3, "Invalid period, should be < 3");
        require(_amount < 6, "Invalid amount, should be < 6");
        uint256 limeBonusAmount = amounts[_amount] * rates[_period][_amount] / 1e3 ;
        uint256 usdtAmount = getUSDTPrice(LIME_WETHPairAddress,WETH_USDTPairAddress, limeBonusAmount);
        require(requiredUSDT + usdtAmount <= limit, "USDT limit exceeded, connect with owner");
        require(mainToken.transferFrom(msg.sender, address(this), amounts[_amount]), "Transfer is failed check your wallet balance");
        stakes[msg.sender] = Stake({start : block.timestamp, period: _period, LIMEAmount : amounts[_amount], USDTAmount : usdtAmount});
        requiredUSDT += usdtAmount;
        emit Staked(msg.sender, periods[_period], amounts[_amount], usdtAmount, true);
    }
    
    function unstake() public{
        require(stakes[msg.sender].start != 0, "Not staking!");
        Stake storage _s = stakes[msg.sender];
        require(block.timestamp >= _s.start + periods[_s.period], "Period not passed yet");
        require(mainToken.transfer(msg.sender, _s.LIMEAmount), "Transfer failed, check contract balance");
        require(boostToken.transfer(msg.sender, _s.USDTAmount), "Transfer failed, check contract balance");
        requiredUSDT -= _s.USDTAmount;
        emit Unstaked(msg.sender, periods[_s.period], _s.LIMEAmount, _s.USDTAmount, true);
        delete stakes[msg.sender];
    }
    
    function getUSDTPrice(address _LIME_WETHPairAddress, address _WETH_USDTPairAddress, uint256 _amount) public view returns(uint256){
        IUniswapV2Pair lime_weth = IUniswapV2Pair(_LIME_WETHPairAddress);
        (uint256 ml, uint256 me,) = lime_weth.getReserves();
        IUniswapV2Pair weth_usdt = IUniswapV2Pair(_WETH_USDTPairAddress);
        (uint256 ne, uint256 nu,) = weth_usdt.getReserves();
        
        uint256 usdtAmount = (_amount * me * nu) / (ml * ne);
        
        return usdtAmount;
    }
    
    function returnLimebyOwner(address _client) public restricted{
        require(stakes[_client].start != 0, "Not staking!");
        Stake storage _s = stakes[_client];
        require(mainToken.transfer(_client, _s.LIMEAmount), "Transfer failed, check contract balance");
        requiredUSDT -= _s.USDTAmount;
        emit ReturnedByOwner(_client, _s.LIMEAmount);
        delete stakes[_client];
    }
    function getBoostBalance() public view restricted returns(uint256, uint256){
        return (boostToken.balanceOf(address(this)), requiredUSDT);
    }
    function changeRates(uint8 _period, uint8 _amount, uint256 _newValue) public restricted{
        rates[_period][_amount] = _newValue;
     }
     function dispenceUSDT(address _to, uint256 _amount) public restricted{
         require(_to != address(0), "Address can't be 0x0");
         require(_amount > 0, "Amount must be > 0");
         require(_amount <= boostToken.balanceOf(address(this)), "Contract balance is not enough");
         require(boostToken.transfer(_to,_amount), "transferFailed");
     }
     function getRates() public view returns(uint256[6][3] memory){
         return rates;
     }
     function updateLimit(uint256 _newLimit) public restricted{
         limit = _newLimit;
         emit LimitIsUpdated(_newLimit);
     }
     function getLimit() public view restricted returns(uint256){
         return limit;
     }
     function returnLime() public {
        require(stakes[msg.sender].start != 0, "Not staking!");
        Stake storage _s = stakes[msg.sender];
        require(mainToken.transfer(msg.sender, _s.LIMEAmount), "Transfer failed, check contract balance");
        requiredUSDT -= _s.USDTAmount;
        emit Returned(msg.sender, _s.LIMEAmount);
        delete stakes[msg.sender];
     }
    
    constructor(){
        owner = msg.sender;
    }
}