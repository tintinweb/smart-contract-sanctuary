// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PurseDistribution {
    event claimReward(address indexed owner, uint256 amount, uint256 indexed Iteration);
    event claimAllReward(address indexed owner, uint256 amount, uint256 Iteration_End);
    event addHolder(address indexed sender, uint256 iteration);
    event updateHolder(address indexed sender, uint256 iteration);

    string public name = "Purse Distribution";
    IERC20 public purseToken;
    address public owner;
    uint256 public constant validDuration = 91 days;
    uint256 public endDistribution;
    bool public isClaimStart;

    mapping(address => mapping(uint256 => holderInfo)) public holder;   //address->index
    mapping(uint256 => uint256) public numOfHolder;

    struct holderInfo {
        uint256 distributeAmount;
        bool isRedeem;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(IERC20 _purseToken) {
        purseToken = _purseToken;
        owner = msg.sender;
    }

    function addHolderInfo(address[] calldata _holder, uint256[] calldata _amount , uint256 iteration) public onlyOwner {
        uint256 i = 0;
        require(_holder.length == _amount.length, "length difference");
        for (i; i < _holder.length; i++) {
            if (_amount[i] > 0 && holder[_holder[i]][iteration].distributeAmount == 0) {
                holder[_holder[i]][iteration] = holderInfo(_amount[i], false);
                numOfHolder[iteration] += 1;
            }
        }
        emit addHolder(msg.sender, iteration);
    }

    function updateHolderInfo(address[] calldata _holder, uint256[] calldata _amount , uint256 iteration) public onlyOwner {
        uint256 i = 0;
        require(_holder.length == _amount.length, "length difference");
        for (i; i < _holder.length; i++) {
            if (holder[_holder[i]][iteration].isRedeem == true) {
                continue;
            }
            holder[_holder[i]][iteration] = holderInfo(_amount[i], false);
        }
        emit updateHolder(msg.sender, iteration);
    }

    function startClaim(bool check, uint256 _startClaim) public onlyOwner {
        if (check) {
            endDistribution = _startClaim + validDuration;
            isClaimStart = true;
        } else {
            isClaimStart = false;
        }
    }

    function updateEndDistribution(uint256 _endDistribution) public onlyOwner {
        endDistribution = _endDistribution;
    }

    function checkData(address[] calldata _holder, uint256[] calldata _amount, uint256 iteration) public view returns (uint256, bool) {
        uint256 i = 0;
        for (i; i < _holder.length; i++) {
            if (holder[_holder[i]][iteration].distributeAmount != _amount[i]) {
                return (i, false);
            }
        }
        return (i, true);
    }

    // Notice Transfers tokens held by timelock to beneficiary.
    function claim(uint256 iteration) public {
        require (isClaimStart == true, "Claim is false");
        require(block.timestamp < endDistribution, "Distribution window over");
        require(holder[msg.sender][iteration].isRedeem == false, 'Have been redeem');

        holder[msg.sender][iteration].isRedeem = true;
        uint256 claimAmount = holder[msg.sender][iteration].distributeAmount;
        purseToken.transfer(msg.sender, claimAmount);
        emit claimReward(msg.sender, claimAmount, iteration);
    }

    function claimAll(uint256 iteration_end) public {
        require (isClaimStart == true, "Claim is false");
        require(block.timestamp < endDistribution, "Distribution window over");
        uint256 claimAmount = 0;
        for (uint256 i = 0; i <= iteration_end; i++) {
                if (holder[msg.sender][i].isRedeem == false) {
                    require(holder[msg.sender][i].isRedeem == false, 'have been redeem');
                    holder[msg.sender][i].isRedeem = true;
                    uint256 holderAmount = holder[msg.sender][i].distributeAmount;
                    claimAmount += holderAmount;                    
                }
        }
        if (claimAmount > 0) {
            purseToken.transfer(msg.sender, claimAmount);
        }
        emit claimAllReward(msg.sender, claimAmount, iteration_end);
    }
    
    function returnPurseToken(address _to) public onlyOwner {
        require(_to != address(0), "send to the zero address");
        uint256 remainingAmount = purseToken.balanceOf(address(this));
        purseToken.transfer(_to, remainingAmount);
    }

    function returnAnyToken(address token, uint256 amount, address _to) public onlyOwner{
        require(_to != address(0), "send to the zero address");
        IERC20(token).transfer(_to, amount);
    } 

    function updateOwner(address _owner) public onlyOwner{
        require(_owner != address(0), "not valid address");
        require(_owner != owner, "same owner address");
        owner = _owner;
    } 
}

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