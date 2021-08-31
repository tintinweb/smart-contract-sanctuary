/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity ^0.7.0; 

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Release{
    
    mapping(address => uint256[]) private productIdxs;
    
    mapping(uint256 => Lock) private locks;
    
    mapping(uint256 => uint256[]) private releasess;
    
    mapping(uint256 => uint256[]) private amountss;

    uint256 productIdx = 0;
    
    address auer;
    
    struct Lock{
        address tokenAddress;
        address toAddress;
        uint256 amountMax;
        uint256 amountWithDraw;
    }
    
    constructor(){
        auer = msg.sender;
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
        require(IERC20(tokenAddress).allowance(msg.sender,address(this)) >= amountMax,"approve error");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this) , amountMax);
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
                uint256 total = IERC20(tokenAddress).balanceOf(address(this));
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
                    IERC20(tokenAddress).transfer(msg.sender, amountNow - lk.amountWithDraw);
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