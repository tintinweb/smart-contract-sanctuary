/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

// File: contracts/core/HEnv.sol

pragma solidity >=0.4.21 <0.6.0;


contract HEnv is Ownable{

  address public token_addr;

  address public fee_pool_addr;

  uint256 public ratio_base;
  uint256 public bid_fee_ratio;
  uint256 public withdraw_fee_ratio;
  uint256 public cancel_fee_ratio;

  constructor(address _target_token) public{
    token_addr = _target_token;
    ratio_base = 100000000;
  }

  function changeFeePoolAddr(address _new) public onlyOwner{
    fee_pool_addr = _new;
  }

  function changeBidFeeRatio(uint256 _ratio) public onlyOwner{
    bid_fee_ratio = _ratio;
  }

  function changeWithdrawFeeRatio(uint256 _ratio) public onlyOwner{
    withdraw_fee_ratio = _ratio;
  }

  function changeCancelFeeRatio(uint256 _ratio) public onlyOwner{
    cancel_fee_ratio = _ratio;
  }
}


contract HEnvFactory{
  event NewHEnv(address addr);
  function createHEnv(address _target_token) public returns (address){
    HEnv env = new HEnv(_target_token);
    env.transferOwnership(msg.sender);
    emit NewHEnv(address(env));
    return address(env);
  }
}