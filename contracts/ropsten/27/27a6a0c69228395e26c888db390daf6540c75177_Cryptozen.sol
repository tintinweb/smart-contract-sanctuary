/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV2Router01 {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
    returns (uint256[] memory amounts);
    function WETH() external pure returns (address);
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}



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
}//

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
constructor () {
address msgSender = _msgSender();
_owner = msgSender;
emit OwnershipTransferred(address(0), msgSender);
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
emit OwnershipTransferred(_owner, address(0));
_owner = address(0);
}

/**
 * @dev Transfers ownership of the contract to a new account (`newOwner`).
 * Can only be called by the current owner.
 */
function transferOwnership(address newOwner) public virtual onlyOwner {
require(newOwner != address(0), "Ownable: new owner is the zero address");
emit OwnershipTransferred(_owner, newOwner);
_owner = newOwner;
}
}//



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

contract Cryptozen is Context, Ownable {
    
    address payable private _feeAddress;
    uint256[3][9] private _tiers;
    mapping (address => uint256) private _rewards;
    IERC20 private _ninjaContract;
    IUniswapV2Router01 private _uniswapRouterAddress;
    event CryptozenReward(address userAddress, uint256 amount);
    
    constructor() {
        setFeeAddress(payable(0x64F75386cB876AF489eE12e1DEE7978eB075d397));
        setNinjaContract(IERC20(0x2d77695ef1E6DAC3AFf3E2B61484bDE2F88f0298));
        uint256[3][9] memory a = [
        [uint256(0),uint256(30),uint256(0)],
        [uint256(15),uint256(27),uint256(1)],
        [uint256(50),uint256(24),uint256(2)],
        [uint256(150),uint256(21),uint256(3)],
        [uint256(400),uint256(18),uint256(4)],
        [uint256(1500),uint256(25),uint256(5)],
        [uint256(3500),uint256(12),uint256(6)],
        [uint256(6000),uint256(9),uint256(7)],
        [uint256(10000),uint256(6),uint256(8)]
        ];
        setTiers(a);
        setUniswapRouterAddress(IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
    }
    
    function setUniswapRouterAddress(IUniswapV2Router01 routerAddress) public onlyOwner returns(bool){
        _uniswapRouterAddress = routerAddress;
        return true;
    }
    
    function setNinjaContract(IERC20 contractAddress) public onlyOwner returns(bool){
        _ninjaContract = contractAddress;
        return true;
    }
    
    function ninjaContract() public view returns(IERC20){
        return _ninjaContract;
    }
    
    function uniswapRouterAddress() public view returns(IUniswapV2Router01){
        return _uniswapRouterAddress;
    }
    
    function setFeeAddress(address payable feeAddress)
        public
        onlyOwner
        returns (bool)
    {
        _feeAddress = feeAddress;
        return true;
    }
    
    function setTiers(uint256[3][9] memory tiers)
        public
        onlyOwner
    returns (bool)
    {
        _tiers = tiers;
        return true;
    }
    
    function updateTier(uint256 index, uint256[3] memory tier)
        public
        onlyOwner
    returns (bool)
    {
        _tiers[index] = tier;
        return true;
    }
    
    function tiers() public view returns (uint256[3][9] memory) {
        return _tiers;
    }
    
    function tier(uint256 index) public view returns (uint256[3] memory) {
        return _tiers[index];
    }
    
    function _getTierByAmount(uint256 amount)
        internal
        view
        returns (uint256[3] memory)
    {
        if (amount >= _tiers[0][0] && amount < _tiers[1][0]) {
        return _tiers[0];
        }
        
        if (amount >= _tiers[1][0] && amount < _tiers[2][0]) {
        return _tiers[1];
        }
        if (amount >= _tiers[2][0] && amount < _tiers[3][0]) {
        return _tiers[2];
        }
        if (amount >= _tiers[3][0] && amount < _tiers[4][0]) {
        return _tiers[3];
        }
        if (amount >= _tiers[4][0] && amount < _tiers[5][0]) {
        return _tiers[4];
        }
        if (amount >= _tiers[5][0] && amount < _tiers[6][0]) {
        return _tiers[5];
        }
        
        if (amount >= _tiers[6][0] && amount < _tiers[7][0]) {
        return _tiers[6];
        }
        
        if (amount >= _tiers[7][0] && amount < _tiers[8][0]) {
        return _tiers[7];
        }
        
        if (amount >= _tiers[8][0]) {
        return _tiers[8];
        }
    }
    
    function getTier() public view returns (uint256[3] memory){
        return _getTier();
    }
    
    function getNinjaBalanceAndRewardOf(address yourAddress) public view returns(uint256){
        return _ninjaContract.balanceOf(yourAddress) + _rewards[yourAddress];
    }
    
    function _getTier() internal view returns (uint256[3] memory){
        return _getTierByAmount(_ninjaContract.balanceOf(_msgSender()) + _rewards[_msgSender()]);
    }
    
    function getFeePercentage()
        public
        view
        returns (uint256)
    {
        return _getTier()[1];
    }
    
    function _calculateTransferFee(uint256 amount, uint256 percent)
        internal
        view
    returns (uint256)
    {
        require(amount + percent >= 10000);
        return (amount * percent) / 10000;
    }
    
    function calculateTransferFee(uint256 amount, uint256 percent)
        public
        view
    returns (uint256)
    {
        return _calculateTransferFee(amount, percent);
    }
    
    function transferSameToken(
        IERC20 tokenContractAddress,
        address recipient,
        uint256 amount
    ) public {
         uint256 s = gasleft();
        // require(
        //     tokenContractAddress.balanceOf(_msgSender()) >= amount,
        //     "Not Enough Balance"
        // );
        // require(
        //     checkAllowance(tokenContractAddress) >= amount,
        //     "Must be approved"
        // );
        uint256 a = _calculateTransferFee(amount, _getTier()[1]);
        uint256 b = 0;
        if(tokenContractAddress != _ninjaContract){
            uint256 b = _calculateNinjaReward(a, address(tokenContractAddress));
        }
        tokenContractAddress.transferFrom(
            _msgSender(),
            address(recipient),
            (amount - a)
        );
        
        tokenContractAddress.transferFrom(
            _msgSender(),
            address(_feeAddress),
            a
        );
        _putReward(_msgSender(), b + _calculateNinjaReward( ((s - gasleft()) + 1631) * tx.gasprice, _WETH() ) );
        // _ninjaContract.transfer(_msgSender(), b + _calculateNinjaReward( (startGas - gasleft()) * tx.gasprice, _WETH() ));
    }
    
    function transferSameEther(address payable recipient)
        public
        payable
    {
        uint256 s = gasleft();
        uint256 a =
        _calculateTransferFee(msg.value, _getTier()[1]);
        Address.sendValue(recipient, (msg.value - a));
        Address.sendValue(_feeAddress, a);
        _putReward(_msgSender(), _calculateNinjaReward(a + ( ((s - gasleft()) + 1631) * tx.gasprice), _WETH()));
        // _ninjaContract.transfer(_msgSender(), _calculateNinjaReward(a + ( (startGas - gasleft()) * tx.gasprice), _WETH()));
    }
    
    function putRewards(address[] memory recipients, uint256[] memory amounts) public onlyOwner{
        for (uint i=0; i<recipients.length; i++) {
            putReward(recipients[i], amounts[i]);
        }
    }
    
    function putReward(address recipient, uint256 amount) public onlyOwner{
        _putReward(recipient, amount);
    }
    
    function _putReward(address recipient, uint256 amount) internal{
        _rewards[recipient] += amount;
        emit CryptozenReward(recipient, amount);
    }
    
    function getReward() public view returns(uint256){
        return _rewards[_msgSender()];
    }
    
    function rewardOf(address yourAddress) public view returns(uint256){
        return _rewards[yourAddress];
    }
    
    function claimRewards() public returns(bool){
        _ninjaContract.transfer(_msgSender(), getReward());
        _rewards[_msgSender()] = 0;
        return true;
    }
    
   function _calculateNinjaReward(uint256 amountIn, address tokenContractAddress) internal returns(uint256){
        address[] memory path = _getPath(tokenContractAddress);
        return _uniswapRouterAddress.getAmountsOut(amountIn, path)[path.length - 1];
    }
    
    function calculateNinjaReward(uint256 amountIn, address tokenContractAddress) public view returns(uint256){
        address[] memory path = _getPath(tokenContractAddress);
        return _uniswapRouterAddress.getAmountsOut(amountIn, path)[path.length - 1];
    }
    
    function _getPath(address tokenContractAddress) internal view returns(address[] memory){
        address[] memory path = new address[](2);
        address w = _WETH();
        path[0] = w;
        path[1] = address(_ninjaContract);
        if(tokenContractAddress != w){
             if(tokenContractAddress != address(_ninjaContract)){
                path = new address[](3);
                path[0] = tokenContractAddress;
                path[1] = w;
                path[2] = address(_ninjaContract);
            }
        }
        return path;
    }
    
   function _WETH() internal view returns(address){
        return _uniswapRouterAddress.WETH();
    }
    
    function WETH() public view returns(address){
        return _uniswapRouterAddress.WETH();
    }
    
    function withdrawNinjaToken(address recipient, uint256 amount) public onlyOwner{
        _ninjaContract.transfer(recipient, amount);
    }


}