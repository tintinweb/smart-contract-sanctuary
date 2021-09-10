/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity <0.9.0;

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
    function depositProfit(address _tokenAddress, uint256 _amount) external;
}


interface IUniswapV2Router02 {
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract swapContract is AdminsContract{
    uint256 liquidityFee = 10;
    uint256 liquidityProviderFee = 25;
    uint256 myProfit = 15;
    
    mapping(address=>uint256) totalTokenLiquidity;
    
    mapping(address=>mapping(address=>uint256)) tokenHoldAmount;
    
    mapping(address=>mapping(address=>uint256)) tokenProfitAmount;
    
    mapping(address=>bool) isholding;
    mapping(uint256=>address) userId;
    uint256 userIDCounter;
    
    address internal USDTAddress = 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02;
    address internal USDCAddress = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
    address internal UNISWAP_R_V2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal shareContractAddress = 0xf1375b8fA90E8791342e13686dAaDB13592b01e5;
    
    IERC20 USDTtoken = IERC20(USDTAddress);
    IERC20 USDCtoken = IERC20(USDCAddress);
    ISC shareContract = ISC(shareContractAddress);
    IUniswapV2Router02 Uniswap = IUniswapV2Router02(UNISWAP_R_V2);
    
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
            shareContract = ISC(shareContractAddress);
            approveForShare();
        }else if(ID == 4){
            UNISWAP_R_V2 = _to;
            Uniswap = IUniswapV2Router02(UNISWAP_R_V2);
        }else{revert("Id is not found!");}
    }
    
    function showMyStake(address _token) external view returns(uint256){
        return (tokenHoldAmount[_token][msg.sender]);
    }
    
    function showMyProfit(address _token) external view returns(uint256){
        return (tokenProfitAmount[_token][msg.sender]);
    }
    
    function showMyID() external view returns(bool){
        return isholding[msg.sender];
    }
    
    function withdrawProfit(address _token) public{
        require(tokenProfitAmount[_token][msg.sender] > 0, "You did not earn any profit for this token!");
        IERC20 token_ = IERC20(_token);
        token_.transfer(msg.sender, tokenProfitAmount[_token][msg.sender]);
    }
    
    //liquidity
    
    function addLiquidity(address _address, uint256 _amount) public{
        require(_amount > 0, "You need to send some token!");
        IERC20 _token = IERC20(_address);
        uint256 approved = _token.allowance(msg.sender, address(this));
        require(approved >= _amount, "Check your allowance!");
        _token.transferFrom(msg.sender, address(this), _amount);
        if (isholding[msg.sender]){
            tokenHoldAmount[_address][msg.sender] += _amount;
        }else{
            userId[userIDCounter] = msg.sender;
            userIDCounter ++;
            isholding[msg.sender] = true;
            tokenHoldAmount[_address][msg.sender] += _amount;
        }
        totalTokenLiquidity[_address] += _amount;
    }
    
    function removeLiquidity(address _address, uint256 _amount) public{
        require(_amount <= tokenHoldAmount[_address][msg.sender], "You provided 0 liquidity with this token!");
        IERC20 _token = IERC20(_address);
        _token.transfer(msg.sender, _amount);
        tokenHoldAmount[_address][msg.sender] -= _amount;
        totalTokenLiquidity[_address] -= _amount;
    }
    
    function showuserProfitamount(address _address, uint256 _num) external view returns(uint256){
        return tokenProfitAmount[_address][userId[_num]];
    }
    
    function showuserHoldamount(address _address, uint256 _num) external view returns(uint256){
        return tokenHoldAmount[_address][userId[_num]];
    }
    
    function showuser(uint256 _num) external view returns(address){
        return userId[_num];
    }
    
    function spreadTokenGain(address _address, uint256 _amount) internal{
        for (uint256 i = 0; i < userIDCounter; i++){
            tokenProfitAmount[_address][userId[i]] += _amount * tokenHoldAmount[_address][userId[i]]/totalTokenLiquidity[_address];
        }
    }
    
    function swapStableToStable(address _from, address _to, uint256 _amount) public{
        IERC20 _tokenFrom = IERC20(_from);
        IERC20 _tokenTo = IERC20(_to);
        require(_amount >= 10**_tokenFrom.decimals(), "You need to exchange at least 1 token!");
        uint256 approved = _tokenFrom.allowance(msg.sender, address(this));
        require(_amount <= approved, "Please first approve!");
        _tokenFrom.transferFrom(msg.sender, address(this), _amount);
        if (_tokenFrom.decimals() >= _tokenTo.decimals()){
            require(_amount / 100000 / 10**(_tokenFrom.decimals() - _tokenTo.decimals()) <= totalTokenLiquidity[_to],
                "not enough liquidity for this swap");
            //_tokenTo.transfer(msg.sender, _amount * (100000 - liquidityFee - liquidityProviderFee - myProfit) / 100000 /
             //   10**(_tokenFrom.decimals() - _tokenTo.decimals()));
            spreadTokenGain(_to, _amount * liquidityProviderFee / 100000 / 10**(_tokenFrom.decimals() - _tokenTo.decimals()));
        }else{
            require(_amount / 100000 * 10**(_tokenTo.decimals() - _tokenFrom.decimals()) <= totalTokenLiquidity[_to],
            "not enough liquidity for this swap");
            //_tokenTo.transfer(msg.sender, _amount * (100000 - liquidityFee - liquidityProviderFee - myProfit) / 100000 *
            //    10**(_tokenTo.decimals() - _tokenFrom.decimals()));
            spreadTokenGain(_to, _amount * liquidityProviderFee / 100000 * 10**(_tokenTo.decimals() - _tokenFrom.decimals()));
        }
        //shareContract.depositProfit(_to, _amount * myProfit / 100000);
    }   
}