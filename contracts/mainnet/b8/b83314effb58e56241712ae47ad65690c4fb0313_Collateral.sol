pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: contracts/Collateral.sol

contract Collateral is Ownable {
    // 抵押品合约

    using SafeMath for SafeMath;
    using SafeERC20 for ERC20;

    address public BondAddress;
    address public DepositAddress; // 抵押品充值，退还地址
    address public VoceanAddress;  // 违约时，扣除部分转入 VoceanAddress

    uint public DeductionRate;  // 0~100  退回部分抵押物时计算给VoceanAddress部分的比例
    uint public Total = 100;

    uint public AllowWithdrawAmount;

    ERC20 public BixToken;

    event SetBondAddress(address bond_address);
    event RefundAllCollateral(uint amount);
    event RefundPartCollateral(address addr, uint amount);
    event PayByBondContract(address addr, uint amount);
    event SetAllowWithdrawAmount(uint amount);
    event WithdrawBix(uint amount);

    constructor(address _DepositAddress, ERC20 _BixToken, address _VoceanAddress, uint _DeductionRate) public{
        require(_DeductionRate < 100);
        DepositAddress = _DepositAddress;
        BixToken = _BixToken;
        VoceanAddress = _VoceanAddress;
        DeductionRate = _DeductionRate;

    }

    // 设置 债券合约地址
    function setBondAddress(address _BondAddress) onlyOwner public {
        BondAddress = _BondAddress;
        emit SetBondAddress(BondAddress);
    }


    // 退回全部抵押物
    // 只允许 债券合约地址 调用
    function refundAllCollateral() public {
        require(msg.sender == BondAddress);
        uint current_bix = BixToken.balanceOf(address(this));

        if (current_bix > 0) {
            BixToken.transfer(DepositAddress, current_bix);

            emit RefundAllCollateral(current_bix);
        }


    }

    // 退回部分抵押物
    // 另一部分转给 VoceanAddress
    function refundPartCollateral() public {

        require(msg.sender == BondAddress);

        uint current_bix = BixToken.balanceOf(address(this));

        if (current_bix > 0) {
            // 计算各自数量
            uint refund_deposit_addr_amount = get_refund_deposit_addr_amount(current_bix);
            uint refund_vocean_addr_amount = get_refund_vocean_addr_amount(current_bix);

            // 退给 充值地址
            BixToken.transfer(DepositAddress, refund_deposit_addr_amount);
            emit RefundPartCollateral(DepositAddress, refund_deposit_addr_amount);

            // 退给 VoceanAddress
            BixToken.transfer(VoceanAddress, refund_vocean_addr_amount);
            emit RefundPartCollateral(VoceanAddress, refund_vocean_addr_amount);
        }


    }

    function get_refund_deposit_addr_amount(uint current_bix) internal view returns (uint){
        return SafeMath.div(SafeMath.mul(current_bix, SafeMath.sub(Total, DeductionRate)), Total);
    }

    function get_refund_vocean_addr_amount(uint current_bix) internal view returns (uint){
        return SafeMath.div(SafeMath.mul(current_bix, DeductionRate), Total);
    }

    // 债券合约使用抵押品赔付
    function pay_by_bond_contract(address addr, uint amount) public {
        require(msg.sender == BondAddress);
        BixToken.transfer(addr, amount);
        emit PayByBondContract(addr, amount);

    }

    // 设置 允许发行方提取的数量
    function set_allow_withdraw_amount(uint amount) public {
        require(msg.sender == BondAddress);
        AllowWithdrawAmount = amount;
        emit SetAllowWithdrawAmount(amount);
    }

    // 允许发行方提取 BIX
    function withdraw_bix() public {
        require(msg.sender == DepositAddress);
        require(AllowWithdrawAmount > 0);
        BixToken.transfer(msg.sender, AllowWithdrawAmount);
        // 提取完后 将额度设置为 0
        AllowWithdrawAmount = 0;
        emit WithdrawBix(AllowWithdrawAmount);
    }

}