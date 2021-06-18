// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Ownable.sol";

contract Stake is Ownable{
    event UserDepositEvent(address indexed Stacker, uint indexed StackID);
    event UserWithdrawEvent(address indexed receiver, uint256 indexed amount);

    struct UserStackInfo {
        uint StackID;
        address Stacker;
        uint StackPlan;
        uint AvailableWithdrawTime;
        uint256 Amount;
    }

    struct StackPlan {
        address ERC20ContractAddress; //ERC20 token address
        uint StackTime;  // How long for this stacking
    }

    uint public StackPlanCount;
    uint internal StackID;

    mapping(address => UserStackInfo[]) public mappingUserStacking ;
    mapping(uint => StackPlan)  public  mappingStackPlan;

    function addStackPlan(address ERC20 , uint StackTime) public onlyOwner {
        require(ERC20 != address(0) && StackTime > 0, "Please input correct params.");
        mappingStackPlan[StackPlanCount].ERC20ContractAddress = ERC20;
        mappingStackPlan[StackPlanCount].StackTime = StackTime;
        StackPlanCount+=1;
    }


    function deposit(uint stackPlanNumber, uint256 amount) public {
         IERC20 erc20 = IERC20(mappingStackPlan[stackPlanNumber].ERC20ContractAddress);
         erc20.transferFrom(msg.sender,address(this),amount);

        UserStackInfo memory UserStackInfoStructData;
        UserStackInfoStructData.Stacker = msg.sender;
        UserStackInfoStructData.StackID = StackID;
        UserStackInfoStructData.Amount = amount;
        UserStackInfoStructData.StackPlan = stackPlanNumber;
        UserStackInfoStructData.AvailableWithdrawTime = block.timestamp + mappingStackPlan[stackPlanNumber].StackTime;
        mappingUserStacking[msg.sender].push(UserStackInfoStructData);
        emit UserDepositEvent(msg.sender , StackID);
        StackID += 1;
    }

    function withdraw(address receiver, uint256 amount,uint stackPlanNumber) public onlyOwner {
        IERC20 erc20 = IERC20(mappingStackPlan[stackPlanNumber].ERC20ContractAddress);
        erc20.transfer(receiver,amount);
        emit UserWithdrawEvent(receiver, amount);
    }

    function checkAllValidDeposit(address stacker) public view returns(UserStackInfo[] memory) {
        if (msg.sender != owner) {
            require(msg.sender == stacker, "Only can check yourself.");
        }
        UserStackInfo[] memory data = new UserStackInfo[](mappingUserStacking[stacker].length);
        for (uint i = 0; i < mappingUserStacking[stacker].length; i++) {
            UserStackInfo memory Temp = mappingUserStacking[stacker][i];
            data[i] = Temp;
        }
        return data;
    }

//    function checkAvailableWithdraw(address receiver) public view returns(uint256) {
//        uint256 AvailableWithdraw = 0;
//        for(uint i = 0;i < mappingUserStacking[receiver].length; i++) {
//            if (block.timestamp >= mappingUserStacking[receiver][i].WithdrawTime) {
//                avaliableWithdraw += mappingUserStacking[receiver][i].Amount;
//            }
//        }
//        return AvailableWithdraw;
//    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract OwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract Ownable is OwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}