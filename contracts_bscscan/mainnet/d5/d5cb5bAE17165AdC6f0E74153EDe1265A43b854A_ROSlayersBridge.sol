/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
        );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
            );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
        );
}

contract ROSlayersBridge is Ownable{

  // Receiving Addresses
  address public RewardPool;
  address public Liquidity;
  address public Charity;
  address public Development;

  IBEP20 SLYR = IBEP20(0x2988810A56eDCf3840871695D587A5AFF280D37b);

  constructor(address _RewardPool, address _Liquidity, address  _Charity, address _Development){
    RewardPool = _RewardPool;
    Liquidity = _Liquidity;
    Charity = _Charity;
    Development = _Development;

    emit RewardPoolAddressUpdated(address(0), RewardPool);
    emit LiquidityAddressUpdated(address(0), Liquidity);
    emit CharityAddressUpdated(address(0), Charity);
    emit DevelopmentAddressUpdated(address(0), Development);
  }

  // Receiving Shares
  uint256 public RewardpoolShare = 5500;
  uint256 public LiquidityShare = 2000;
  uint256 public CharityShare = 1500;
  uint256 public DevelopmentShare = 1000;

  // Percent Divider
  uint256 constant Divider = 10000;

  // events
  event RewardPoolAddressUpdated(address oldAdd, address newAdd);
  event LiquidityAddressUpdated(address oldAdd, address newAdd);
  event CharityAddressUpdated(address oldAdd, address newAdd);
  event DevelopmentAddressUpdated(address oldAdd, address newAdd);
  event UpdateSharePercent(uint256 RewardpoolShare, uint256 LiquidityShare, uint256 CharityShare, uint256 DevelopmentShare);

  // update share for each Address
  function updateSharePercent(
    uint256 _rewardpoolShare,
    uint256 _liquidityShare,
    uint256 _charityShare,
    uint256 _developmentShare
  ) external onlyOwner() returns(bool){
    require((_rewardpoolShare + _liquidityShare + _charityShare + _developmentShare) == Divider, "Invalid amounts");
    RewardpoolShare = _rewardpoolShare;
    LiquidityShare = _liquidityShare;
    CharityShare = _charityShare;
    DevelopmentShare = _developmentShare;
    emit UpdateSharePercent(RewardpoolShare, LiquidityShare, CharityShare, DevelopmentShare);
    return true;
  }

  function update_RewardPool_Address(address newAdd) external onlyOwner() returns (bool){
    require(newAdd != RewardPool, "Identical Addresses");
    emit RewardPoolAddressUpdated(RewardPool, newAdd);
    RewardPool = newAdd;
    return true;
  }

  function update_Liquidity_Address(address newAdd) external onlyOwner() returns (bool){
    require(newAdd != Liquidity, "Identical Addresses");
    emit LiquidityAddressUpdated(Liquidity, newAdd);
    Liquidity = newAdd;
    return true;
  }

  function update_Charity_Address(address newAdd) external onlyOwner() returns (bool){
    require(newAdd != Charity, "Identical Addresses");
    emit CharityAddressUpdated(Charity, newAdd);
    Charity = newAdd;
    return true;
  }

  function update_Development_Address(address newAdd) external onlyOwner() returns (bool){
    require(newAdd != Development, "Identical Addresses");
    emit DevelopmentAddressUpdated(Development, newAdd);
    Development = newAdd;
    return true;
  }

  // Deposit Tokens
  function deposit(uint256 amount) public returns (bool){
    require(SLYR.balanceOf(_msgSender()) >= amount, "Insufficient SLYR Balance");
    require(SLYR.allowance(_msgSender(), address(this)) >= amount, "Check SLYR Allowance");
    SLYR.transferFrom(_msgSender(), address(this), amount);

    // transfer the shares
    SLYR.transfer(RewardPool, (amount*RewardpoolShare)/Divider);
    SLYR.transfer(Liquidity, (amount*LiquidityShare)/Divider);
    SLYR.transfer(Charity, (amount*CharityShare)/Divider);
    SLYR.transfer(Development, (amount*DevelopmentShare)/Divider);

    return true;
  }

}