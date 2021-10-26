// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OwnerHelper {
    address private _owner;

    modifier onlyOwner {
        require(msg.sender == _owner, "should be onwer");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}

contract TokenLock is OwnerHelper {
    struct Beneficiary {
        uint256 totalAmount;
        uint256 withdrawedAmount;
        uint256[12] releaseTimes;
        uint256[12] releaseAmounts;
    }
    mapping (address => Beneficiary) internal beneficiaries;
    address internal token;

    constructor(address _contract){
        token = _contract;
    }

    function lockTokens(address _target, uint256 _amount) public onlyOwner {
        require(_target != address(0x0), "Invalid Address");
        require(_amount > 0, "Not Enough Amount");
        require(beneficiaries[_target].totalAmount == 0, "Exist Beneficary");

        uint256 currentTime = block.timestamp;

        uint256 monthInterval = 2592000;  // 60*60*24*30
        uint256 yearInterval = 31536000;  // 60*60*24*365
        uint256 addYearTime = currentTime + yearInterval;

        beneficiaries[_target].totalAmount = _amount;
        beneficiaries[_target].withdrawedAmount = 0;
        uint256 dividened = 0;
        uint256 dividen = _amount / 12;
        for (uint i=0; i <= 11; i++){
          beneficiaries[_target].releaseTimes[i] = addYearTime + (i * monthInterval);
          if (i < 11) {
            beneficiaries[_target].releaseAmounts[i] = dividen;
            dividened += dividen;
          } else {
            beneficiaries[_target].releaseAmounts[i] = _amount - dividened;
            dividened += dividen;
          }
        }
    }

    function withdrawToken() public {
        require(beneficiaries[msg.sender].totalAmount > 0, "Not Exist Beneficary");

        uint256 amount = 0;
        uint256 currentTime = block.timestamp;

        for (uint i=0; i <= 11; i++){
            if (beneficiaries[msg.sender].releaseTimes[i] < currentTime) {
                amount += beneficiaries[msg.sender].releaseAmounts[i];
                beneficiaries[msg.sender].releaseAmounts[i] = 0;
            }
        }
        require(amount > 0, "Not Enough Amount");

        beneficiaries[msg.sender].withdrawedAmount += amount;
        IERC20(token).transfer(msg.sender, amount);
    }

    function retrieve(address _target) public onlyOwner {
        beneficiaries[_target].totalAmount = 0;
        for (uint i=0; i <= 11; i++){
            beneficiaries[_target].releaseAmounts[i] = 0;
            beneficiaries[_target].releaseTimes[i] = 0;
        }
    }

    function getBeneficiary(address _target) public view returns (Beneficiary memory) {
        return beneficiaries[_target];
    }

    function changeOwner(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
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