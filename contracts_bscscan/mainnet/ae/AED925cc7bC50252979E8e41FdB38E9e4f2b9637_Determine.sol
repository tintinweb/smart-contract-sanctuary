/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBCL{
    function holder_n() external view returns(uint256);
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface Pool{
    function AssetUserRequired(address token, address user) external view returns(uint256);
    function BNBrequired(address user) external view returns(uint256);
    function queryUserSlot(address user, uint slotId) external view returns(
        uint weightedPower,
        uint amount_bcl,
        uint amount_main,
        uint timestamp,
        uint portion,
        uint assetId,
        uint valueInU);
}

contract Determine{
    
    mapping(uint=>address) public Assets;
    address public bcl_mining;
    
    
    constructor(){
        
        bcl_mining = 0x3629B40e58Be0A64bED0bDD118296EB0A082Aa01; 
        
        Assets[1] = 0x55d398326f99059fF775485246999027B3197955; // bsc-USD
        Assets[2] = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c; // wBTC
        Assets[3] = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8; // wETH
        Assets[4] = 0x4338665CBB7B2485A8855A139b75D5e34AB0DB94; // LTC
        Assets[5] = 0xBf5140A22578168FD562DCcF235E5D43A02ce9B1; // UNI 
        Assets[6] = 0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153; // FIL
        Assets[7] = 0x8fF795a6F4D97E7887C79beA79aba5cc76444aDf; // BCH
        Assets[8] = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43; // DOGE caveat: 8 decimals
        Assets[9] = 0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402; // DOT
        Assets[10] = 0x85EAC5Ac2F758618dFa09bDbe0cf174e7d574D5B; // TRX
        Assets[11] = 0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE; // XRP
        Assets[12] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // wBNB
        Assets[14] = 0x0C9cd9A6Bb56eE16cbD00e55B5e7d33CbB4855cd; // SYNC_BSC
        Assets[15] = 0xc1cE98E2A2E95F626D62a240E8a55cC96A610D2C;
    }
    
    /*
    * check if user possesses sufficient main tokens or BNB for participanting in lp mining
        return 10 if no slot info or valid.
        return slotId 0-9 for invalid slot.
    */
    function CheckValidility(address user) public view returns(uint){

        for(uint slotId=0; slotId<10; ++slotId){
            
            (,,,,,uint id,) = (Pool(bcl_mining).queryUserSlot(user, slotId));
            if(id==0){continue;}
            
            if(id==13){
                if(payable(user).balance < Pool(bcl_mining).BNBrequired(user)){return slotId;}
            }
            else{
                if(IBCL(Assets[id]).balanceOf(user) < Pool(bcl_mining).AssetUserRequired(Assets[id], user)){
                    return slotId;
                }
            }
        }
        return 10;
    }
    
    function changeMiningAddr(address mining) public {
        bcl_mining = mining;
    }
    
    function setAssets(uint256 id, address addr) public {
        Assets[id] = addr;
    }
        
        
        
        
        
}