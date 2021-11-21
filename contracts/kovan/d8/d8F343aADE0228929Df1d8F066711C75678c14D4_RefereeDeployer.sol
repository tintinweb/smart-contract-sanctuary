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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IBettingOperator.sol";

/// @title Referee that bound OBPToken for injecting results in betting Operator
/// @notice This contract should only be deployed through calling RefereeDeployer
contract Referee {
    constructor(uint256 _arbitrationTime, address _court, address _owner, address _OBPToken) {
        court = _court;
        arbitrationTime = _arbitrationTime;
        owner = _owner;
        OBPToken = _OBPToken;
    }

    /// @dev bettingOperator => item (uint112) + payOutResult (uint112) + payoutLastUpdatedTime (uint32)
    mapping(address => bytes) public results;
    
    address OBPToken;
    uint256 arbitrationTime;
    address owner;
    address court;
    mapping(address => uint) public stakers;

    uint256 public totalStaked;
    uint256 public freezedUnderReferee;
    /// @dev operator => amountOBPInStake for safeguarding
    mapping(address => uint) public operatorUnderReferee;


    modifier onlyCourt() {
        require(msg.sender == court);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function _getCurrentFreezeRatio() internal view returns(uint256 currentFreezeRatio) {
        currentFreezeRatio = (freezedUnderReferee * 1000 / totalStaked);
    }
    
    function encodeResult(uint112 _item, uint112 _payout, uint32 _lastupdatedTime) public pure returns(bytes memory) {
        return abi.encodePacked(_item, _payout, _lastupdatedTime);
    }

    function decodeResult(uint256 _encodedResult) public pure returns(uint112 item, uint112 payout, uint32 lastupdatedtime){
        item = uint112(_encodedResult >> 144);
        payout = uint112(_encodedResult >> 32);
        lastupdatedtime = uint32(_encodedResult);
    }
    function participate(uint256 _amount) external {
        address sender = msg.sender;
        bool success = IERC20(OBPToken).transferFrom(sender, address(this), _amount);
        require(success , 'participate: TRANSFER_FAILED');
        stakers[msg.sender] = _amount;
        totalStaked += _amount;
    }
    function withdraw(address _to, uint256 _amount) external {
        require(stakers[msg.sender] > 0, "withdraw:: YOU HAVE NO STAKE"); 
        require(totalStaked - freezedUnderReferee > _amount, "withdraw::AVAILABLE STAKE FOR WITHDRAW NOT ENOUGH");
        uint256 withdrawAmount;

    // if freezed ratio > 90%, withdraw takes a 1% fee.
        if (_getCurrentFreezeRatio() > 900) {
            withdrawAmount = _amount * 99 / 100;
        } else {
            withdrawAmount = _amount;
        }
        //remove the bet before transferring
        stakers[msg.sender] -= _amount;
        totalStaked -= _amount;
        (bool result) = IERC20(OBPToken).transfer(_to, withdrawAmount);
        require(result, "withdraw: TRANSFER_FAILED");
    }

    function anounceResult(address bettingOperator, bytes calldata data) external onlyOwner {
        results[bettingOperator] = abi.encodePacked(results[bettingOperator], data);
    }

    function pushResult(address bettingOperator, uint256 item_index) external onlyOwner {
        uint256 item;
        bytes memory result = results[bettingOperator];
        uint256 indexBytes = 32*item_index;
        assembly {
                item := mload(add(result, indexBytes))
                }
        (, , uint32 parsedPayoutLastUpdatedTime) = decodeResult(item);
        // only push result that passes the arbitration window
        if (block.timestamp > arbitrationTime + parsedPayoutLastUpdatedTime) {
            IBettingOperator(bettingOperator).injectResult(item);
    }
}
    function pushResultBatch(address bettingOperator) external onlyOwner {//(bytes memory data){
        
        uint256 item;
        bytes memory result = results[bettingOperator];
        //return result.length;
         bytes memory data;
         for (uint256 i = 0; i < result.length; i+=32) {
             assembly {
                 item := mload(add(result, add(32, i)))
                 }
         (uint112 parsedItem, uint112 parsedPayout, uint32 parsedPayoutLastUpdatedTime) = decodeResult(item);
            // only push result that passes the arbitration window
            if (block.timestamp > arbitrationTime + parsedPayoutLastUpdatedTime) {
                data = abi.encodePacked(data, item);
            }
            require(parsedItem > 0, "DEBUG: parseItem shd > 0");
         }
        // push result
        IBettingOperator(bettingOperator).injectResultBatch(data);
    }

    /// @dev wipe out the whole entry, then you can push again, the original result in operator would be overrided as the result is read sequentially in a list. For example result in operator {item, payout, lastupdatedtime} = [1,1000, xxxx], [1,0, xxxx] => pool for Item1 would end up with 0.
    function revokeResult(address bettingOperator, uint256 item) external onlyOwner {
        results[bettingOperator][item] = 0;
    }

   function closeItem(address bettingOperator, uint256 item) external onlyOwner {
        IBettingOperator(bettingOperator).closeItem(item);
   }
    function closeItemBatch(address bettingOperator) external onlyOwner {
        bytes memory result = results[bettingOperator];
        // push result
        IBettingOperator(bettingOperator).closeItemBatch(result);
    }
    function verify(address bettingOperator, uint256 _refereeValueAtStake, uint256 maxBet, uint256 refereeIds) external onlyOwner {
        freezedUnderReferee += _refereeValueAtStake;
        require(freezedUnderReferee <= totalStaked);
        IBettingOperator(bettingOperator).verify(_refereeValueAtStake, maxBet, refereeIds);
        operatorUnderReferee[bettingOperator] = _refereeValueAtStake;
    }

    /// @notice this function exposes the referee to confiscation from the court. OBP staked for that operator would be confiscated and transferred to the operator.
    function confiscate(address operator) external onlyCourt {
        uint256 amount = operatorUnderReferee[operator];
        totalStaked -= amount;
        freezedUnderReferee -= amount;
        IERC20(OBPToken).transfer(operator, amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IRefereeDeployer.sol';
import './Referee.sol';

/// @title RefereeDeployer is called from OBPMain to deploy a referee
/// @notice RefereeDeployer should NOT be called directly as referee deployed is not recognized by OBPMain
contract RefereeDeployer is IRefereeDeployer {
    address public arbitrationTimeSetter;
    uint256 arbitrationTime = 1 seconds;

    event RefereesCreated(address operator);


    function refereeCodeHash() public pure returns (bytes memory) {
        return type(Referee).creationCode;
    }

    function refereeByteCode(uint256 _arbitrationTime, address court, address owner, address OBPToken) public pure returns (bytes memory) {
         return abi.encodePacked(refereeCodeHash(), abi.encode(_arbitrationTime, court, owner, OBPToken));
     }

     function refereeSalt(uint256 _arbitrationTime, address court, address owner, address OBPToken) public pure returns (bytes32){
         return keccak256(abi.encodePacked(_arbitrationTime, court, owner, OBPToken));
     }

    function getcreatedAddress(address court, address owner, address OBPToken) public view returns(address referee) {
        bytes memory bytecode  = refereeByteCode(arbitrationTime, court, owner, OBPToken);
        bytes32 salt = refereeSalt(arbitrationTime, court, owner, OBPToken);
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );
        return address(uint160(uint(hash)));
    }

    /// @dev a 0x0 would be returned in case create2 fails due to insuffiicent gas
    function createReferee(address court, address owner, address OBPToken) external override returns(address referee){
        bytes memory bytecode = refereeByteCode(arbitrationTime, court, owner, OBPToken);
        bytes32 salt = refereeSalt(arbitrationTime, court, owner, OBPToken);
        assembly {
            referee := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        
        emit RefereesCreated(referee);
    }

    function setArbitrationWindow(uint256 _arbitrationTime) external override {
        require(msg.sender == arbitrationTimeSetter, 'setArbitrationWindow: FORBIDDEN');
        arbitrationTime = _arbitrationTime;
    }


}

pragma solidity ^0.8.0;

interface IBettingOperator {


    function withdraw(uint item, address _to)  external ;
    function verify(uint256 _refereeValueAtStake, uint256 _maxBet, uint256 refereeIds) external;
    function placeBet(uint item, uint amount, address bettor) external;
    function withdrawOperatorFee(uint256 _amount, address _to)  external;
    function injectResultBatch(bytes calldata) external;
    function injectResult(uint256) external;
    function closeItem(uint256 item) external;
    // the more gas-efficient way; 
    function closeItemBatch(bytes calldata) external;
    function setTotalUnclaimedPayoutAfterConfiscation() external;
    function withdrawFromFailedReferee(uint256 item, address _to) external;
    
    
}

pragma solidity ^0.8.0;

interface IRefereeDeployer {

    function createReferee(address owner, address court, address OBPToken) external returns(address);
    function setArbitrationWindow(uint256 _arbitrationTime) external;

}