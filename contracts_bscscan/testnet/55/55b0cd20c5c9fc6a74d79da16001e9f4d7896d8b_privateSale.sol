/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

contract privateSale is Ownable {
    using SafeMath for uint256;

    address[] public participants; 
    address public tokenContract; 
    mapping(address => uint256) balances;
    mapping(address => uint256) withdrawCounter; 

    uint256 public vestingStartDate; 
    uint256 public vestingTimeToSecondRelease = 2 weeks; 
    uint256 public vestingTimeToThirdRelease = 4 weeks;

    uint256 public tokensPerBNB = 100 * (10 ** 18); 

    function getSecondReleaseTime() public view returns(uint256) {
        return vestingStartDate.add(vestingTimeToSecondRelease); 
    }

    function getThirdReleaseTime() public view returns(uint256) {
        return vestingStartDate.add(vestingTimeToThirdRelease);
    }

    receive() external payable {
        require(msg.value == 1 ether, "Contribution is 1BNB, not more and not less");
        require(balances[msg.sender] ==0, "You already contributed");
        require(address(this).balance <50 ether); 
        balances[msg.sender] = 1; 
        participants.push(msg.sender);
    }

    function updateTokensPerBNB(uint256 _tokensPerBNB) public onlyOwner {
        tokensPerBNB = _tokensPerBNB.mul(1e18); 
    }

    function updateTokenContract (address _tokenContract) public onlyOwner {
        tokenContract = _tokenContract;
    }

    function setVestingStartTime() internal {
        vestingStartDate = block.timestamp; 
    }

    function releaseFirstBadge() external {
        require(msg.sender == tokenContract);
        setVestingStartTime(); 
    }

    function releaseFirstBadgeManually() public onlyOwner {
        setVestingStartTime(); 
    }


    function transferERC20(address _receiver, uint256 _amount) internal {
        IERC20(tokenContract).transfer(_receiver, _amount); 
    }

    function getTokenBalance() public view onlyOwner returns(uint256) {
        return IERC20(tokenContract).balanceOf(address(this));
    }

    function updateTimeToSecondRelease(uint256 _timeInSeconds) public onlyOwner {
        vestingTimeToSecondRelease = _timeInSeconds; 
    }

    function updateTimeToThirdRelease(uint256 _timeInSeconds) public onlyOwner {
        vestingTimeToThirdRelease = _timeInSeconds; 
    }

    function withdrawBNB(address _recipient) public onlyOwner {
        payable(_recipient).transfer(address(this).balance); 
    }

    function withdrawERC20(address _tokenCA, address _recipient, uint256 _amount) public onlyOwner {
        IERC20(_tokenCA).transfer(_recipient, _amount);
    }

    function withdrawVestedTokens() public {
        require(balances[msg.sender]>0);
        require(withdrawCounter[msg.sender]<3);
        

        if (withdrawCounter[msg.sender] == 0){
        uint256 transferAmount = tokensPerBNB.div(2);
        transferERC20(msg.sender, transferAmount);
        withdrawCounter[msg.sender] +=1; 
        }
        else if (withdrawCounter[msg.sender] == 1){
        require(block.timestamp > getSecondReleaseTime(), "Vesting Time for second withdrawl not over, yet");
        uint256 transferAmount = tokensPerBNB.mul(100).div(400);
        transferERC20(msg.sender, transferAmount);
        withdrawCounter[msg.sender] +=1; 
        }
        else {
        require(block.timestamp > getThirdReleaseTime(), "Vesting Time for third withdrawl not over, yet");
        uint256 transferAmount = tokensPerBNB.mul(100).div(400);
        transferERC20(msg.sender, transferAmount);
        withdrawCounter[msg.sender] +=1; 
        }

        
        
        }

    function removeFromParticipants(address _address) public onlyOwner {
        require(balances[msg.sender] ==1, "Can't exclude this address");
        payable(_address).transfer(1 ether);
        balances[_address] = 0;
    }

}