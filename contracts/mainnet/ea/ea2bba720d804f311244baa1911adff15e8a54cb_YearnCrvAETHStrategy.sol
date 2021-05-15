/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: MIT

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}


interface StandardToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IStakeAndYield {
    function getRewardToken() external view returns(address);
    function totalSupply(uint256 stakeType) external view returns(uint256);
    function totalYieldWithdrawed() external view returns(uint256);
    function notifyRewardAmount(uint256 reward, uint256 stakeType) external;
}

interface IController {
    function withdrawETH(uint256 amount) external;

    function depositTokenForStrategy(
        uint256 amount, 
        address yearnVault
    ) external;

    function buyForStrategy(
        uint256 amount,
        address rewardToken,
        address recipient
    ) external;

    function withdrawForStrategy(
        uint256 sharesToWithdraw, 
        address yearnVault
        ) external;

    function strategyBalance(address stra) external view returns(uint256);
}

interface IYearnVault{
    function balanceOf(address account) external view returns (uint256);
    function withdraw(uint256 amount) external;
    function getPricePerFullShare() external view returns(uint256);
    function deposit(uint256 _amount) external returns(uint256);
}

interface IWETH is StandardToken{
    function withdraw(uint256 amount) external returns(uint256);
}

interface ICurve{
    function get_virtual_price() external view returns(uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_amounts) external payable returns(uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns(uint256);
}


contract YearnCrvAETHStrategy is Ownable {
    using SafeMath for uint256;

     uint256 public lastEpochTime;
     uint256 public lastBalance;
     uint256 public lastYieldWithdrawed;

     uint256 public yearnFeesPercent;

     uint256 public ethPushedToYearn;

     IStakeAndYield public vault;


    IController public controller;
    
    //crvAETH 
    address yearnDepositableToken = 0xaA17A236F2bAdc98DDc0Cf999AbB47D47Fc0A6Cf;

    IYearnVault public yearnVault = IYearnVault(0xE625F5923303f1CE7A43ACFEFd11fd12f30DbcA4);
    
    //IWETH public weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    StandardToken crvAETH = StandardToken(0xaA17A236F2bAdc98DDc0Cf999AbB47D47Fc0A6Cf);

    ICurve curve = ICurve(0xA96A65c051bF88B4095Ee1f2451C2A9d43F53Ae2);

    address public operator;


    uint256 public minRewards = 0.01 ether;
    uint256 public minDepositable = 0.05 ether;

    modifier onlyOwnerOrOperator(){
        require(
            msg.sender == owner() || msg.sender == operator,
            "!owner"
        );
        _;
    }

    constructor(
        address _vault,
        address _controller
    ) public{
        vault = IStakeAndYield(_vault);
        controller = IController(_controller);
    }

    // Since Owner is calling this function, we can pass
    // the ETHPerToken amount
    function epoch(uint256 ETHPerToken) public onlyOwnerOrOperator{
        uint256 balance = pendingBalance();
        //require(balance > 0, "balance is 0");
        uint256 withdrawable = harvest(balance.mul(ETHPerToken).div(1 ether));
        lastEpochTime = block.timestamp;
        lastBalance = lastBalance.add(balance);

        uint256 currentWithdrawd = vault.totalYieldWithdrawed();
        uint256 withdrawAmountToken = currentWithdrawd.sub(lastYieldWithdrawed);
        if(withdrawAmountToken > 0){
            lastYieldWithdrawed = currentWithdrawd;
            uint256 ethWithdrawed = withdrawAmountToken.mul(
                ETHPerToken
            ).div(1 ether);
            
            withdrawFromYearn(ethWithdrawed.add(withdrawable));
            ethPushedToYearn = ethPushedToYearn.sub(ethWithdrawed);
        }else{
            if(withdrawable > 0){
                withdrawFromYearn(withdrawable);
            }
        }
    }

    function harvest(uint256 ethBalance) private returns(
        uint256 withdrawable
    ){
        uint256 rewards = calculateRewards();
        uint256 depositable = ethBalance > rewards ? ethBalance.sub(rewards) : 0;
        if(depositable >= minDepositable){
            //deposit to yearn
            controller.depositTokenForStrategy(
                depositable,
                address(yearnVault));
            
            ethPushedToYearn = ethPushedToYearn.add(
                depositable
            );
        }

        if(rewards > minRewards){
            withdrawable = rewards > ethBalance ? rewards.sub(ethBalance) : 0;
            // get DEA and send to Vault
            controller.buyForStrategy(
                rewards,
                vault.getRewardToken(),
                address(vault)
            );
        }else{
            withdrawable = 0;
        }
    }

    function withdrawFromYearn(uint256 ethAmount) private returns(uint256){
        uint256 yShares = controller.strategyBalance(address(this));

        uint256 sharesToWithdraw = ethAmount.mul(1 ether).div(
            yearnVault.getPricePerFullShare()
        );

        uint256 curveVirtualPrice = curve.get_virtual_price();
        sharesToWithdraw = sharesToWithdraw.mul(curveVirtualPrice).div(
            1 ether
        );

        require(yShares >= sharesToWithdraw, "Not enough shares");

        controller.withdrawForStrategy(
            sharesToWithdraw, 
           address(yearnVault)
        );
        return ethAmount;
    }

    
    function calculateRewards() public view returns(uint256){
        uint256 yShares = controller.strategyBalance(address(this));
        uint256 yETHBalance = yShares.mul(
            yearnVault.getPricePerFullShare()
        ).div(1 ether);

        uint256 curveVirtualPrice = curve.get_virtual_price();
        yETHBalance = yETHBalance.mul(curveVirtualPrice).div(
            1 ether
        );

        yETHBalance = yETHBalance.mul(1000 - yearnFeesPercent).div(1000);
        if(yETHBalance > ethPushedToYearn){
            return yETHBalance - ethPushedToYearn;
        }
        return 0;
    }

    function pendingBalance() public view returns(uint256){
        uint256 vaultBalance = vault.totalSupply(2);
        if(vaultBalance < lastBalance){
            return 0;
        }
        return vaultBalance.sub(lastBalance);
    }

    function getLastEpochTime() public view returns(uint256){
        return lastEpochTime;
    }

    function setYearnFeesPercent(uint256 _val) public onlyOwner{
        yearnFeesPercent = _val;
    }

    function setOperator(address _addr) public onlyOwner{
        operator = _addr;
    }

    function setMinRewards(uint256 _val) public onlyOwner{
        minRewards = _val;
    }

    function setMinDepositable(uint256 _val) public onlyOwner{
        minDepositable = _val;
    }

    function setController(address _controller, address _vault) public onlyOwner{
        if(_controller != address(0)){
            controller = IController(_controller);
        }
        if(_vault != address(0)){
            vault = IStakeAndYield(_vault);
        }
    }

    function emergencyWithdrawETH(uint256 amount, address addr) public onlyOwner{
        require(addr != address(0));
        payable(addr).transfer(amount);
    }

    function emergencyWithdrawERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        StandardToken(_tokenAddr).transfer(_to, _amount);
    }
}