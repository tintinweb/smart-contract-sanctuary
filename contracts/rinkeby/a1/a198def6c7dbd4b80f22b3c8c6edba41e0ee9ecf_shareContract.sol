/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity <0.8.6;

abstract contract OwnerContract{
    address internal owner;
    
    event ownershipTransfered(address from, address to);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier isOwner(){
        require(msg.sender==owner, "Access denied!");
        _;
    }
    
    function transferOwnership(address _to) public isOwner{
        owner = _to;
        emit ownershipTransfered(msg.sender, owner);
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract tokensContract is OwnerContract{
    address shareTokenAddress = 0xab0a4d65f7Bc603a6E702D6c358Dc5075f13B845;
    address USDTTokenAddress = 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02;
    address USDCTokenAddress = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
    
    mapping(address=>uint256) profitUSDTAmount;
    mapping(address=>uint256) profitUSDCAmount;
    mapping(address=>uint256) holdAmount;
    mapping(uint256=>address) holderId;
    mapping(address=>bool) isHolder;
    
    uint256 holderIdCounter;
    uint256 public totalValueLocked;
    uint256 public totalProfitMade;
    
    IERC20 shareToken = IERC20(shareTokenAddress);
    IERC20 USDTToken = IERC20(USDTTokenAddress);
    IERC20 USDCToken = IERC20(USDCTokenAddress);
    
    function setProfitTokenAddress(uint256 _Id, address _address) public isOwner{
        if (_Id == 1){
            USDTTokenAddress = _address;
            USDTToken = IERC20(USDTTokenAddress);
        }else if(_Id == 2){
            USDCTokenAddress = _address;
            USDCToken = IERC20(USDCTokenAddress);
        }else{revert("ID not found");}
    }
    
    function changeTokenAddress(address _address) public isOwner{
        shareTokenAddress = _address;
        shareToken = IERC20(shareTokenAddress);
    }
}

contract shareContract is tokensContract{
    
    
    function depositShare(uint256 _amount) public{
        require(_amount > 1, "Tou need to send some tokens");
        uint256 allowanceAmount = shareToken.allowance(msg.sender, address(this));
        require(allowanceAmount > _amount, "ERC20: sending exceeds allowance");
        shareToken.transferFrom(msg.sender, address(this), _amount);
        if (isHolder[msg.sender]){
            holdAmount[msg.sender] +=_amount;
            totalValueLocked += _amount;
        }else{
            holdAmount[msg.sender] += _amount;
            totalValueLocked += _amount;
            holderId[holderIdCounter] = msg.sender;
            holderIdCounter++;
            isHolder[msg.sender] = true;
        }
    }
    
    function spreadUSDTProfit(uint256 _amount) internal{
        for(uint256 i = 0; i<holderIdCounter; i++){
            profitUSDTAmount[holderId[i]] += _amount * holdAmount[holderId[i]] / totalValueLocked;
        }
    }
    
    function spreadUSDCProfit(uint256 _amount) internal{
        for(uint256 i = 0; i<holderIdCounter; i++){
            profitUSDCAmount[holderId[i]] += _amount * holdAmount[holderId[i]] / totalValueLocked;
        }
    }
    
    function depositUSDTProfit(uint256 _amount) public{
        require(_amount > 1, "Tou need to send some tokens");
        uint256 allowanceAmount = USDTToken.allowance(msg.sender, address(this));
        require(allowanceAmount > _amount, "ERC20: sending exceeds allowance");
        USDTToken.transferFrom(msg.sender, address(this), _amount);
        spreadUSDTProfit(_amount);
        totalProfitMade += _amount;
    }
    
    function depositUSDCProfit(uint256 _amount) public{
        require(_amount > 1, "Tou need to send some tokens");
        uint256 allowanceAmount = USDCToken.allowance(msg.sender, address(this));
        require(allowanceAmount > _amount, "ERC20: sending exceeds allowance");
        USDCToken.transferFrom(msg.sender, address(this), _amount);
        spreadUSDCProfit(_amount);
        totalProfitMade += _amount;
    }
    
    function widthrawProfit() public{
        if(profitUSDTAmount[msg.sender] > 0){
        USDTToken.transfer(msg.sender, profitUSDTAmount[msg.sender]);
        profitUSDTAmount[msg.sender] = 0;}
        if(profitUSDCAmount[msg.sender] > 0){
        USDCToken.transfer(msg.sender, profitUSDCAmount[msg.sender]);
        profitUSDCAmount[msg.sender] = 0;}
        
    }
    
    function myProfit() external view returns(uint256 USDT, uint256 USDC){
        return (profitUSDTAmount[msg.sender], profitUSDCAmount[msg.sender]);
    }
    
    function TVL() external view returns(uint256){
        return totalValueLocked;
    }
    
    function totalProfitGained() external view returns(uint256){
        return totalProfitMade;
    }
    
    function receiveOtherTokensLocked(address _tokenAddress, uint256 _amount) public isOwner{
        require(_tokenAddress != USDTTokenAddress && _tokenAddress != shareTokenAddress && _tokenAddress != USDCTokenAddress, "Nobody is allowed!");
        IERC20 lockedToken = IERC20(_tokenAddress);
        lockedToken.transfer(msg.sender, _amount);
    }
}