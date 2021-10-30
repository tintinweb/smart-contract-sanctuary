/**
 *Submitted for verification at polygonscan.com on 2021-10-29
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/interfaces/IShare.sol

interface IShare is IERC20{
    function mint(address to, uint _amount) external returns(bool);
    function burn(address from, uint _amount) external returns(bool);
    function initialize() external;
    function initializeERC20(string memory name_, string memory symbol_) external;
    function getSharesGFIWorthAtLastSnapshot(address _address) view external returns(uint);
    function takeSnapshot() external;
    function getSharesGFICurrentWorth(address _address) view external returns(uint shareValuation);
}


// File contracts/interfaces/iGovernance.sol


interface iGovernance {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function delegateFee(address reciever) external returns (uint256);

    function claimFee() external returns (uint256);

    function tierLedger(address user, uint index) external returns(uint);

    function depositFee(uint256 amountWETH, uint256 amountWBTC) external;

    function Tiers(uint index) external view returns(uint);
}


// File contracts/interfaces/ICompounderFactory.sol

struct ShareInfo{
    address depositToken;
    address rewardToken;
    address shareToken;
    uint vaultFee;
    uint minHarvest;
    uint maxCallerReward;
    uint callerFeePercent;
    bool lpFarm;
    address lpA; //only applies to lpFarms
    address lpB;
}

interface ICompounderFactory {

    function farmAddressToShareInfo(address farm) external view returns(ShareInfo memory);
    function tierManager() external view returns(address);
    function getFarm(address shareToken) external view returns(address);
    function gfi() external view returns(address);
    function swapFactory() external view returns(address);
    function createCompounder(address _farmAddress, address _depositToken, address _rewardToken, uint _vaultFee, uint _maxCallerReward, uint _callerFee, uint _minHarvest, bool _lpFarm, address _lpA, address _lpB) external;
}


// File @openzeppelin/contracts/utils/[email protected]

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/core/TierManager.sol






contract TierManager is Ownable {
    address[] public supportedShareTokens;
    IERC20 GFI;
    iGovernance Governor;
    ICompounderFactory Factory;
    constructor(){
        supportedShareTokens.push(0xBcCd20990CeFD07f725409F80a41648126aBefC7);//GFI
        supportedShareTokens.push(0xfa37d42f497e0890315645a4650439471Ede1C50);//WMATIC-GFI
        supportedShareTokens.push(0xA4F39A2c5D7b0437df06fF6f434f20b012673A34);//WBTC-GFI
        supportedShareTokens.push(0xdBF9047AdF8A5147028A47Cf95922277C43e5C55);//USDC-GFI
        supportedShareTokens.push(0x6e6D10584f078210D199873A54Ac31da9bC3Decf);//WETH-GFI
        GFI = IERC20(0x874e178A2f3f3F9d34db862453Cd756E7eAb0381);
        Governor = iGovernance(0xEe5578a3Bab33F7A56575785bb4846B90Be37d50);
        Factory = ICompounderFactory(0xDc15F68E5F80ACD5966c84f518B1504A7E1772CA);

    }

    function updateSupportedShareTokens(address shareToken, uint index) external onlyOwner{
        if(index < supportedShareTokens.length){
            supportedShareTokens[index] = shareToken;
        }
        else{
            supportedShareTokens.push(shareToken);
        }
    }

    function takeSnapshotOfAllSupportedShareTokens() external onlyOwner{
        for(uint i=0; i<supportedShareTokens.length; i++){
            IShare(supportedShareTokens[i]).takeSnapshot();
        }
    }

    /*
     * @dev returns the highest tier the caller address has, based off current GFI and share holdings
     */
    function checkTier(address caller) external view returns(uint){
        uint bigBal = GFI.balanceOf(caller);
        uint userLPBal;
        ShareInfo memory info;
        for(uint i=0; i<supportedShareTokens.length; i++){
            bigBal += IShare(supportedShareTokens[i]).getSharesGFICurrentWorth(caller);
            info = Factory.farmAddressToShareInfo(Factory.getFarm(supportedShareTokens[i]));
            userLPBal = IERC20(info.depositToken).balanceOf(caller);
            bigBal += userLPBal * GFI.balanceOf(info.depositToken) / IERC20(info.depositToken).totalSupply();
        }
        for(uint i=3; i>0; i--){
            if(bigBal >= Governor.Tiers(i-1)){
                return i;
            }
        }
        return 0;
    }

    function viewAllGFIBalances(address caller) external view returns(uint[] memory){
        uint[] memory balances = new uint[](supportedShareTokens.length + 2);
        balances[0] = (GFI.balanceOf(caller));
        balances[1] = (GFI.balanceOf(caller));
        uint userLPBal;
        ShareInfo memory info;
        for(uint i=0; i<supportedShareTokens.length; i++){
            balances[i+2] = IShare(supportedShareTokens[i]).getSharesGFICurrentWorth(caller);
            balances[0] += IShare(supportedShareTokens[i]).getSharesGFICurrentWorth(caller);
            info = Factory.farmAddressToShareInfo(Factory.getFarm(supportedShareTokens[i]));
            userLPBal = IERC20(info.depositToken).balanceOf(caller);
            balances[i+2] += userLPBal * GFI.balanceOf(info.depositToken) / IERC20(info.depositToken).totalSupply();
            balances[0] += userLPBal * GFI.balanceOf(info.depositToken) / IERC20(info.depositToken).totalSupply();
        }
        return balances;
    }

    //for IDOs
    function checkTierIncludeSnapshot(address caller) external view returns(uint){
        uint bigBal;
        for(uint i=0; i<supportedShareTokens.length; i++){
            bigBal += IShare(supportedShareTokens[i]).getSharesGFIWorthAtLastSnapshot(caller);
        }
        for(uint i=3; i>0; i--){
            if(bigBal >= Governor.Tiers(i-1)){
                return i;
            }
        }
        return 0;
    }

    function viewIDOTier(address caller) external view returns(uint){
        uint bigBal;
        for(uint i=0; i<supportedShareTokens.length; i++){
            bigBal += IShare(supportedShareTokens[i]).getSharesGFICurrentWorth(caller);
        }
        for(uint i=3; i>0; i--){
            if(bigBal >= Governor.Tiers(i-1)){
                return i;
            }
        }
        return 0;
    }

}