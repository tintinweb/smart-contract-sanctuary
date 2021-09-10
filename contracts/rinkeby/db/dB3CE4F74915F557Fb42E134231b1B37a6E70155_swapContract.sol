/**
 *Submitted for verification at Etherscan.io on 2021-09-10
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
    
    function removeAdmin(address _address) public isOwner{
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
    
    address internal shareContractAddress = 0xf1375b8fA90E8791342e13686dAaDB13592b01e5;
    
    ISC shareContract = ISC(shareContractAddress);
    
    function approveForShare(IERC20 _token) public{
        _token.approve(shareContractAddress, 999999**12);
    }
    
    function showShareContractAddresses() external view returns(address ShareAddress){
        return (shareContractAddress);
    }
    
    function showFees() external view returns(uint256 _liquidityFee, uint256 _liquidityProviderFee, uint256 _myProfit){
        return(liquidityFee, liquidityProviderFee, myProfit);
    }
    
    function changeShareContractAddress(address _to) external isAdmin{
        shareContractAddress = _to;
        shareContract = ISC(shareContractAddress);
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
        tokenProfitAmount[_token][msg.sender] = 0;
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
    
    //external view functions
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
        if (_amount > 0){
            for (uint256 i = 0; i < userIDCounter; i++){
                tokenProfitAmount[_address][userId[i]] += _amount * tokenHoldAmount[_address][userId[i]]/totalTokenLiquidity[_address];
            }
        }
    }
    
    //swap
    
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
            _tokenTo.transfer(msg.sender, _amount * (100000 - liquidityFee - liquidityProviderFee - myProfit) / 100000 /
               10**(_tokenFrom.decimals() - _tokenTo.decimals()));
            spreadTokenGain(_to, _amount * liquidityProviderFee / 100000 / 10**(_tokenFrom.decimals() - _tokenTo.decimals()));
            if (_tokenTo.balanceOf(address(this)) >= 1000000000 * _tokenTo.decimals()){
                approveForShare(_tokenTo);
                shareContract.depositProfit(_to, _amount * liquidityFee / 100000 / 10**(_tokenFrom.decimals() - _tokenTo.decimals()));
            }
        }else{
            require(_amount / 100000 * 10**(_tokenTo.decimals() - _tokenFrom.decimals()) <= totalTokenLiquidity[_to],
            "not enough liquidity for this swap");
            _tokenTo.transfer(msg.sender, _amount * (100000 - liquidityFee - liquidityProviderFee - myProfit) / 100000 *
                10**(_tokenTo.decimals() - _tokenFrom.decimals()));
            spreadTokenGain(_to, _amount * liquidityProviderFee / 100000 * 10**(_tokenTo.decimals() - _tokenFrom.decimals()));
            if (_tokenTo.balanceOf(address(this)) >= 1000000000 * _tokenTo.decimals()){
                approveForShare(_tokenTo);
                shareContract.depositProfit(_to, _amount * liquidityFee / 100000 * 10**(_tokenTo.decimals() - _tokenFrom.decimals()));
            }
        }
        approveForShare(_tokenFrom);
        shareContract.depositProfit(_from, _amount * myProfit / 100000);
        
    }
    
    //estimate
    function estimateSwap(address _from, address _to, uint256 _amount) external view returns(uint256 estimate){
        IERC20 _tokenFrom = IERC20(_from);
        IERC20 _tokenTo = IERC20(_to);
        if (_amount < 10**_tokenFrom.decimals()){
            return (0);
        }
        uint256 approved = _tokenFrom.allowance(msg.sender, address(this));
        if (_amount > approved){
            return (0);
        }
        if (_tokenFrom.decimals() >= _tokenTo.decimals()){
            if (_amount / 100000 / 10**(_tokenFrom.decimals() - _tokenTo.decimals()) > totalTokenLiquidity[_to]){
                return (0);
            }else{
                return (_amount * (100000 - liquidityFee - liquidityProviderFee - myProfit) / 100000 /
               10**(_tokenFrom.decimals() - _tokenTo.decimals()));
            }
        } else{
            if(_amount / 100000 * 10**(_tokenTo.decimals() - _tokenFrom.decimals()) > totalTokenLiquidity[_to]){
                return (0);
            }else {
                return(_amount * (100000 - liquidityFee - liquidityProviderFee - myProfit) / 100000 *
                10**(_tokenTo.decimals() - _tokenFrom.decimals()));
            }
        }
    }
}