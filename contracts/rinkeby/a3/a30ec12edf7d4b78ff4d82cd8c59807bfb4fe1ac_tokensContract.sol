/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity <0.8.6;

contract AdminsContract{
    address internal owner;
    mapping(address=>bool) admins;
    
    constructor(){
        owner = msg.sender;
        admins[msg.sender] = true;
    }
    
    modifier isOwner(){
        require(msg.sender == owner, "Access denied!");
        _;
    }
    
    modifier isAdmin(){
        require(admins[msg.sender] || msg.sender == owner, "Access denied!");
        _;
    }
    
    function addAmin(address _address) public isOwner{
        admins[_address] = true;
    }
    
    function removeAmin(address _address) public isOwner{
        admins[_address] = false;
    }
    
    function showOwner() external view returns(address){
        return owner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);
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

interface ISC{
    function depositUSDTProfit(uint256 _amount) external;
    function depositUSDCProfit(uint256 _amount) external;
}

contract tokensContract is AdminsContract{
    uint256 liquidityFee = 10;
    uint256 liquidityProviderFee = 25;
    uint256 myProfit = 15;
    
    uint256 totalUSDTLiquidity;
    uint256 totalUSDCLiquidity;
    
    mapping(address=>uint256) USDTHoldAmount;
    mapping(address=>uint256) USDCHoldAmount;
    
    mapping(address=>uint256) USDTProfitAmount;
    mapping(address=>uint256) USDCProfitAmount;
    
    mapping(address=>bool) isholding;
    mapping(uint256=>address) userId;
    uint256 userIDCounter;
    
    address internal USDTAddress = 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02;
    address internal USDCAddress = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
    address internal shareContractAddress = 0x6E23Af06C1bd931B2D9bd3D64a583464e917E002;
    
    IERC20 USDTtoken = IERC20(USDTAddress);
    IERC20 USDCtoken = IERC20(USDCAddress);
    ISC shareContract = ISC(shareContractAddress);
    
    constructor(){
        USDTtoken.approve(shareContractAddress, 999999**12);
        USDCtoken.approve(shareContractAddress, 999999**12);
    }
    
    function approveForShare() public{
        USDTtoken.approve(shareContractAddress, 999999**12);
        USDCtoken.approve(shareContractAddress, 999999**12);
    }
    
    function showAddresses() external view returns(address _USDTAddress, address _USDCAddress, address _ShareAddress){
        return (USDTAddress, USDCAddress, shareContractAddress);
    }
    
    function showFees() external view returns(uint256 _liquidityFee, uint256 _liquidityProviderFee, uint256 _myProfit){
        return(liquidityFee, liquidityProviderFee, myProfit);
    }
    
    function changeAddress(uint ID, address _to) external isOwner{
        if(ID == 1){
            USDTAddress = _to;
            USDTtoken = IERC20(USDTAddress);
        }else if(ID == 2){
            USDCAddress = _to;
            USDCtoken = IERC20(USDCAddress);
        }else if(ID == 3){
            shareContractAddress = _to;
            USDCtoken = IERC20(USDCAddress);
            approveForShare();
        }else{revert("Id is not found!");}
    }
    
    function addLiquidityUSDT(uint256 _amount) public{
        require(_amount > 10**(USDTtoken.decimals()), "You need to send at least 1 USDT");
        uint allowed = USDTtoken.allowance(msg.sender, address(this));
        require(allowed >= _amount, "ERC20: You must approve USDT");
        USDTtoken.transferFrom(msg.sender, address(this), _amount);
        if (isholding[msg.sender]){
            USDTHoldAmount[msg.sender] += _amount;
        }else if(isholding[msg.sender] == false){
            userIDCounter ++;
            userId[userIDCounter] = msg.sender;
            isholding[msg.sender] = true;
            USDTHoldAmount[msg.sender] += _amount;
        }
        totalUSDTLiquidity += _amount;
    }
    
    function addLiquidityUSDC(uint256 _amount) public{
        require(_amount > 10**(USDCtoken.decimals()), "You need to send at least 1 USDC");
        uint allowed = USDCtoken.allowance(msg.sender, address(this));
        require(allowed >= _amount, "ERC20: You must approve USDC");
        USDCtoken.transferFrom(msg.sender, address(this), _amount);
        if (isholding[msg.sender]){
            USDCHoldAmount[msg.sender] += _amount;
        }else if(isholding[msg.sender] == false){
            userId[userIDCounter] = msg.sender;
            isholding[msg.sender] = true;
            USDCHoldAmount[msg.sender] += _amount;
            userIDCounter ++;
        }
        totalUSDCLiquidity += _amount;
    }
    
    function removeLiquidityUSDT(uint256 _amount) public{
        require(_amount <= (USDTHoldAmount[msg.sender] + USDTProfitAmount[msg.sender]), "You can't withdraw more than amount you liquidated and made profit!");
        require(_amount <= USDTtoken.balanceOf(address(this)), "Not enough amount of liquidity to withdraw");
        USDTtoken.transfer(msg.sender, _amount);
        if (USDCProfitAmount[msg.sender] <= _amount){
            USDTHoldAmount[msg.sender] -= (_amount - USDCProfitAmount[msg.sender]);
            USDCProfitAmount[msg.sender] = 0;
        }else{
            USDTProfitAmount[msg.sender] -= _amount;
        }
        totalUSDTLiquidity -= _amount;
    }
    
    function removeLiquidityUSDC(uint256 _amount) public{
        require(_amount <= (USDCHoldAmount[msg.sender] + USDCProfitAmount[msg.sender]), "You can't withdraw more than amount you liquidated and made profit!");
        require(_amount <= USDCtoken.balanceOf(address(this)), "Not enough amount of liquidity to withdraw");
        USDCtoken.transfer(msg.sender, _amount);
        if (USDCProfitAmount[msg.sender] <= _amount){
            USDCHoldAmount[msg.sender] -= (_amount - USDCProfitAmount[msg.sender]);
            USDCProfitAmount[msg.sender] = 0;
        }else{
            USDCProfitAmount[msg.sender] -= _amount;
        }
        totalUSDCLiquidity -= _amount;
    }
    
    function showMyStake() external view returns(uint256 USDT, uint256 USDC){
        return (USDTHoldAmount[msg.sender], USDCHoldAmount[msg.sender]);
    }
    
    function showMyProfit() external view returns(uint256 USDT, uint256 USDC){
        return (USDTProfitAmount[msg.sender], USDCProfitAmount[msg.sender]);
    }
    
    function spreadTheLiquidityProviderUSDT(uint256 _amount) internal{
        for (uint256 i = 0; i <= userIDCounter; i++){
            address user = userId[i];
            USDTProfitAmount[user] += _amount * (USDTHoldAmount[user]/totalUSDTLiquidity);
        }
    }
    
    function spreadTheLiquidityProviderUSDC(uint256 _amount) internal{
        for (uint256 i = 0; i <= userIDCounter; i++){
            USDCProfitAmount[userId[i]] += _amount * (USDCHoldAmount[userId[i]]/totalUSDCLiquidity);
        }
    }
    
    function swapUSDTforUSDC(uint256 _amount) public{
        require(_amount >= 10000000000000000, "You need to swap at least 0.001 USDT");
        uint allowed = USDTtoken.allowance(msg.sender, address(this));
        require(allowed >= _amount, "ERC20: You must approve USDT");
        require(USDCtoken.balanceOf(address(this)) >= _amount / 10**(USDTtoken.decimals() - USDCtoken.decimals()), "insufficient liquidity of USDC");
        USDTtoken.transferFrom(msg.sender, address(this), _amount);
        USDCtoken.transfer(msg.sender, (_amount * (10000 - liquidityFee - liquidityProviderFee - myProfit)/10000) / 10**(USDTtoken.decimals() - USDCtoken.decimals()));
        spreadTheLiquidityProviderUSDC((liquidityProviderFee/2) * _amount / 10000 / 10**(USDTtoken.decimals() - USDCtoken.decimals()));
        spreadTheLiquidityProviderUSDT((liquidityProviderFee/2) * _amount / 10000);
        shareContract.depositUSDTProfit(_amount * (myProfit/2) / 10000);
        shareContract.depositUSDCProfit(_amount * (myProfit/2) / 10000 / 10**(USDTtoken.decimals() - USDCtoken.decimals()));
    }
    
    function swapUSDCforUSDT(uint256 _amount) public{
        require(_amount >= 10000, "You need to swap at least 0.001 USDC");
        uint allowed = USDCtoken.allowance(msg.sender, address(this));
        require(allowed >= _amount, "ERC20: You must approve USDC");
        require(USDTtoken.balanceOf(address(this)) >= _amount* 10**(USDTtoken.decimals() - USDCtoken.decimals()), "insufficient liquidity of USDT");
        USDCtoken.transferFrom(msg.sender, address(this), _amount);
        USDTtoken.transfer(msg.sender, (_amount * (10000 - liquidityFee - liquidityProviderFee - myProfit)/10000) * 10**(USDTtoken.decimals() - USDCtoken.decimals()));
        spreadTheLiquidityProviderUSDC((liquidityProviderFee/2) * _amount / 10000);
        spreadTheLiquidityProviderUSDT((liquidityProviderFee/2) * _amount / 10000 * 10**(USDTtoken.decimals() - USDCtoken.decimals()));
        shareContract.depositUSDTProfit(_amount * (myProfit/2) / 10000 * 10**(USDTtoken.decimals() - USDCtoken.decimals()));
        shareContract.depositUSDCProfit(_amount * (myProfit/2) / 10000);
    }
    
    function withdrawProfit() public{
        require(USDCProfitAmount[msg.sender] > 0 || USDTProfitAmount[msg.sender] > 0, "You did not earn any profit! If you think this is a mistake contact us");
        if (USDCProfitAmount[msg.sender] > 0){
            USDCProfitAmount[msg.sender] = 0;
            USDCtoken.transfer(msg.sender, USDCProfitAmount[msg.sender]);
        }
        if (USDTProfitAmount[msg.sender] > 0){
            USDTProfitAmount[msg.sender] = 0;
            USDTtoken.transfer(msg.sender, USDTProfitAmount[msg.sender]);
        }
    }
}