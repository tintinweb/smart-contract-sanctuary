/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity >=0.4.21 <0.6.0;
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


contract PMBParams is Ownable{
  uint256 public ratio_base;
  uint256 public withdraw_fee_ratio;

  uint256 public mortgage_ratio;
  uint256 public liquidate_fee_ratio;
  uint256 public minimum_deposit_amount;

  address payable public plut_fee_pool;

  constructor() public{
    ratio_base = 1000000;
    minimum_deposit_amount = 0;
  }

  function changeWithdrawFeeRatio(uint256 _ratio) public onlyOwner{
    require(_ratio < ratio_base, "too large");
    withdraw_fee_ratio = _ratio;
  }

  function changeMortgageRatio(uint256 _ratio) public onlyOwner{
    require(_ratio > ratio_base, "too small");
    mortgage_ratio = _ratio;
  }

  function changeLiquidateFeeRatio(uint256 _ratio) public onlyOwner{
    require(_ratio < ratio_base, "too large");
    liquidate_fee_ratio = _ratio;
  }
  function changeMinimumDepositAmount(uint256 _amount) public onlyOwner{
    minimum_deposit_amount = _amount;
  }
  function changePlutFeePool(address payable _pool) public onlyOwner{
    plut_fee_pool = _pool;
  }
}