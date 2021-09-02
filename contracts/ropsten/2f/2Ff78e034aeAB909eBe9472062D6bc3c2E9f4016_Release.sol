/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity ^0.7.0; 

interface IERC20 {
    function transferFrom(address _token, address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _token, address _to, uint256 _value) external returns (bool success);
}

interface ERC20 {
    function allowance(address owner, address spender) external returns (uint256 amount);
    function balanceOf(address account) external view returns (uint256);
}

contract Release{
    
    mapping(address => uint256[]) productIdxs;
    
    mapping(uint256 => Lock) locks;
    
    mapping(uint256 => uint256[]) releasess;
    
    mapping(uint256 => uint256[]) amountss;

    uint256 productIdx = 0;
    
    address auer;
    
    address transferAddress = address(0);
    
    struct Lock{
        address tokenAddress;
        address toAddress;
        uint256 amountMax;
        uint256 amountWithDraw;
    }
    
    constructor(){
        auer = msg.sender;
    }
    
    function initRelease(address transfer) public {
        require(auer == msg.sender, "no author");
        transferAddress = transfer;
    }
  
    function lockPosition(
        address tokenAddress,
        address toAddress,
        uint256[] memory releases,
        uint256[] memory amounts) public{
        require(auer == msg.sender, "no author");
        require(toAddress != address(0),"no owner");
        require(releases.length>0 && releases.length == amounts.length,"releases or amounts error");
        for(uint256 j = 0;j < releases.length;j++){
            require(releases[j] > block.timestamp * 1000,"releases error");
        }
        uint256 amountMax = 0;
        for(uint256 i = 0;i < amounts.length;i++){
            amountMax = amountMax + amounts[i]; 
        }
        require(amountMax > 0,"amounts error");
        require(ERC20(tokenAddress).allowance(msg.sender,transferAddress) >= amountMax,"approve error");
        IERC20(transferAddress).transferFrom(tokenAddress,msg.sender, transferAddress , amountMax);
        Lock memory lk = Lock(tokenAddress,toAddress,amountMax,0);
        locks[productIdx] = lk;
        releasess[productIdx] = releases;
        amountss[productIdx] = amounts;
        if(productIdxs[toAddress].length > 0){
            productIdxs[toAddress].push(productIdx);
        }else{
            productIdxs[toAddress] = [productIdx];
        }
        productIdx = productIdx + 1;
    }

    function withdraw(address tokenAddress) public {
        require(productIdxs[msg.sender].length > 0,"no release");
        bool flag = false;
        for(uint256 i = 0;i < getLockLength(msg.sender);i++){
            Lock memory lk = locks[productIdxs[msg.sender][i]];
            if(lk.tokenAddress == tokenAddress){
                uint256 total = ERC20(tokenAddress).balanceOf(transferAddress);
                uint256[] memory releases = releasess[productIdxs[msg.sender][i]];
                uint256[] memory amounts = amountss[productIdxs[msg.sender][i]];
                uint256 amountNow = 0;
                for(uint256 j = 0;j < releases.length;j++){
                    if(block.timestamp * 1000 >= releases[j]){
                        amountNow = amountNow + amounts[j];
                    }
                }
                if(lk.amountWithDraw < lk.amountMax && lk.amountWithDraw < amountNow && total >= amountNow - lk.amountWithDraw){
                    flag = true;
                    locks[productIdxs[msg.sender][i]].amountWithDraw = amountNow;
                    IERC20(transferAddress).transfer(tokenAddress,msg.sender, amountNow - lk.amountWithDraw);
                }
            }
        }
        require(flag,"no withdraw");
    }
    
    function getBlockTime() public view virtual returns (uint256){
        return block.timestamp * 1000;
    }

    function getLockLength(address fromAddress) public view virtual returns (uint256){
        return productIdxs[fromAddress].length;
    }
    
    function getReleases(address fromAddress,uint256 idx) public view virtual returns (uint256[] memory){
        require(getLockLength(fromAddress) > idx,"no lockPosition");
        return releasess[productIdxs[fromAddress][idx]];
    }
    
    function getAmounts(address fromAddress,uint256 idx) public view virtual returns (uint256[] memory){
        require(getLockLength(fromAddress) > idx,"no lockPosition");
        return amountss[productIdxs[fromAddress][idx]];
    }
     
    function getLocks(address fromAddress,uint256 idx) public view virtual returns (uint256[] memory){
        require(getLockLength(fromAddress) > idx,"no lockPosition");
        Lock memory lk = locks[productIdxs[fromAddress][idx]];
        uint256[] memory lock = new uint256[](2);
        lock[0] = lk.amountMax;
        lock[1] = lk.amountWithDraw;
        return lock;
    }
    
    function getTokenAddress(address fromAddress,uint256 idx) public view virtual returns (address){
        require(getLockLength(fromAddress) > idx,"no lockPosition");
        Lock memory lk = locks[productIdxs[fromAddress][idx]];
        return lk.tokenAddress;
    }
    
    function getLastRelease(address fromAddress,address tokenAddress) public view virtual returns (uint256){
        uint256 release = 0;
        for(uint256 i = 0;i < getLockLength(fromAddress);i++){
            Lock memory lk = locks[productIdxs[fromAddress][i]];
            if(lk.tokenAddress == tokenAddress){
                if(lk.amountMax > lk.amountWithDraw){
                    release = release + lk.amountMax - lk.amountWithDraw;
                }
            }
        }
        return release;
    }
}