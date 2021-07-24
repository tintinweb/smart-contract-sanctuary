// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./YERC20.sol";
import "./SafeMath.sol";

contract YukiNetworkToken is ERC20, ERC20Burnable, Pausable, Ownable {
    
    using SafeMath for uint256;
    
    constructor() ERC20("Wrapped Yuki Network Token", "WYUKI") {
        _mint(msg.sender, 10 * 10 ** decimals());
        maxBuy=1 * 10 ** decimals();
        buyFee=1 * 10 ** 15;
        canBuy=false;
        
        maxSale=1 * 10 ** decimals();
        saleFee=1 * 10 ** decimals();
        saleFee2=uint256(1 * 10 ** 18).div(saleFee);
        canSale=false;
    }
    
    uint256 maxBuy; 
    uint256 buyFee;
    bool canBuy;
    
    uint256 maxSale; 
    uint256 saleFee;
    uint256 saleFee2;
    bool canSale;
    
    //Buy Functions
    function setMaxBuy(uint256 max) public onlyOwner {
        maxBuy=max;
    }
    
    function getMaxBuy() public view returns (uint256) {
        return maxBuy;
    }
    
    function setBuyFee(uint256 fee) public onlyOwner {
        buyFee=fee;
    }
    
    function getBuyFee() public view returns(uint256){
        return buyFee;
    }
    
    function setCanBuy(bool value) public onlyOwner {
        canBuy=value;
    }   

    function getCanBuy() public view returns (bool) {
        return canBuy;
    }
    
    //Sale Functions
    function setMaxSale(uint256 max) public onlyOwner {
        maxSale=max;
    }
    
    function getMaxSale() public view returns (uint256) {
        return maxSale;
    }
    
    function setSaleFee(uint256 fee) public onlyOwner {
        saleFee=fee;
		saleFee2=uint256(1 * 10 ** 18).div(saleFee);
    }
    
    function getSaleFee() public view returns(uint256){
        return saleFee;
    }
    
    function setCanSale(bool value) public onlyOwner {
        canSale=value;
    }   

    function getCanSale() public view returns (bool) {
        return canSale;
    }
    
    // ERC20 Logics
    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {        
        bool ret= super.transfer(recipient, amount);
        
        address sender=msg.sender;
        uint256 val=amount;
        
        if(canSale){
            if(recipient==address(this)){
                if(val>=saleFee){
                    val=val.sub(saleFee);
                    uint256 tokenGet=val.mul(saleFee2).div(1 * 10 ** decimals());
                    if(val <= maxSale){
                        if(tokenGet<=address(this).balance){
                            transferBalanceToUser(sender,tokenGet);
                        }
                        else{
                            transferTokenToUser(sender,val);
                        }
                    }
                    else{
                        uint left=val.sub(maxSale);
                        if(left<=address(this).balance){
                            transferTokenToUser(sender,left);
                            transferBalanceToUser(sender,maxSale.mul(saleFee2).div(1 * 10 ** decimals()));
                        }
                        else{
                            transferTokenToUser(sender,val);
                        }
                    }
                }
            }
        }
        
        return ret;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        bool ret= super.transferFrom(sender,recipient,amount);

        uint256 val=amount;
        
        if(canSale){
            if(recipient==address(this)){
                if(val>=saleFee){
                    val=val.sub(saleFee);
                    uint256 tokenGet=val.mul(saleFee2).div(1 * 10 ** decimals());
                    if(val <= maxSale){
                        if(tokenGet<=address(this).balance){
                            transferBalanceToUser(sender,tokenGet);
                        }
                        else{
                            transferTokenToUser(sender,val);
                        }
                    }
                    else{
                        uint left=val.sub(maxSale);
                        if(left<=address(this).balance){
                            transferTokenToUser(sender,left);
                            transferBalanceToUser(sender,maxSale.mul(saleFee2).div(1 * 10 ** decimals()));
                        }
                        else{
                            transferTokenToUser(sender,val);
                        }
                    }
                }
            }
        }

        return ret;
    }
	
    //Functions below is used for recovery
    function generator() public pure returns (string memory){
        return "Remix 0.4.1 with Solidity 0.8.4 based on Yuki Chain Wallet V2";
    }
    
    function license() public pure returns (string memory){
        return "MIT License";
    }
    
    function authorIdentifier() public pure returns (string memory){
        return "Yuki Kurosawa (@YukiKurosawaDev)";
    }
    
    function authorTwitter() public pure returns (string memory){
        return "https://twitter.com/YukiKurosawaDev";
    }
    
    function balanceOfWallet() public view returns (uint256){
        return address(this).balance;
    }
    
    function balanceOfWalletToken(address token) public view returns (uint256){
        YERC20 yerc20=YERC20(token);
        return yerc20.balanceOf(address(this));
    }
    
    
    receive () external payable{
        
        if(!canBuy) return;
        
        YERC20 yerc20=YERC20(address(this));       
        
        uint256 val=msg.value;
        if(val>=buyFee){
            val=val.sub(buyFee);
            uint256 tokenGet=val.mul(1 * 10 ** decimals()).div(buyFee);
            if(tokenGet <= maxBuy){
                if(tokenGet<=yerc20.balanceOf(address(this))){
                    transferTokenToUser(msg.sender,tokenGet);
                }
                else{
                    transferBalanceToUser(msg.sender,val);
                }
            }
            else{
                uint left=tokenGet.sub(maxBuy);
                if(maxBuy<=yerc20.balanceOf(address(this))){
                    transferBalanceToUser(msg.sender,left.div(1 * 10 ** decimals()).mul(buyFee));
                    transferTokenToUser(msg.sender,maxBuy);
                }
                else{
                    transferBalanceToUser(msg.sender,val);
                }
            }
        }
    }
    
    function transferBalanceToYuki(uint256 money) public {
        require(money<=address(this).balance);
        payable(owner()).transfer(money);
    }
    
    function transferBalanceToUser(address user,uint256 money) private {
        require(money<=address(this).balance);
        payable(user).transfer(money);
    }
    
    function transferTokenToUser(address user,uint256 money) private {
        YERC20 yerc20=YERC20(address(this));
        require(money<=yerc20.balanceOf(address(this)));
        yerc20.transfer(user,money);
    }
    
    function transferTokenToYuki(address token,uint256 money) public{
        YERC20 yerc20=YERC20(token);
        require(money<=yerc20.balanceOf(address(this)));
        yerc20.transfer(address(owner()),money);
    }
    
    function nameOfToken(address token) public view returns(string memory) {
        YERC20 yerc20=YERC20(token);
        return yerc20.name();
    }
    
    function symbolOfToken(address token) public view returns(string memory) {
        YERC20 yerc20=YERC20(token);
        return yerc20.symbol();
    }
}