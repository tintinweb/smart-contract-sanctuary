// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "./libs/fota/Auth.sol";
import "./libs/zeppelin/token/BEP20/IBEP20.sol";

contract PrivateSale is Auth {

  struct Buyer {
    uint allocated;
    uint price; // decimal 3
    uint boughtAtBlock;
    uint lastClaimed;
    uint totalClaimed;
  }
  enum USDCurrency {
    busd,
    usdt
  }

  address public fundAdmin;
  IBEP20 public fotaToken;
  IBEP20 public busdToken;
  IBEP20 public usdtToken;
  uint public constant privateSaleAllocation = 665e23;
//  uint public constant blockInOneMonth = 864000; // 30 * 24 * 60 * 20
  uint public constant blockInOneMonth = 200; // 30 * 24 * 60 * 20
  uint constant decimal3 = 1000;
  uint totalAllocated;
  mapping(address => Buyer) buyers;

  event UserAllocated(address buyer, uint amount, uint price, uint timestamp);
  event Bought(address buyer, uint amount, uint price, uint timestamp);
  event Claimed(address buyer, uint amount, uint timestamp);

  function initialize(address _mainAdmin, address _fundAdmin, address _fotaToken) public initializer {
    Auth.initialize(_mainAdmin);
    fundAdmin = _fundAdmin;
    fotaToken = IBEP20(_fotaToken);
    busdToken = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    usdtToken = IBEP20(0x55d398326f99059fF775485246999027B3197955);
  }

  // TODO for testing purpose
  function setUsdToken(address _busdToken, address _usdtToken) external onlyMainAdmin {
    busdToken = IBEP20(_busdToken);
    usdtToken = IBEP20(_usdtToken);
  }

  function updateFundAdmin(address _address) onlyMainAdmin external {
    require(_address != address(0), "PrivateSale: invalid address");
    fundAdmin = _address;
  }

  function setUserAllocations(address[] calldata _buyers, uint[] calldata _amounts, uint[] calldata _prices) external onlyMainAdmin {
    require(_buyers.length == _amounts.length && _amounts.length == _prices.length, "PrivateSale: invalid data input");
    address buyer;
    uint amount;
    uint price;
    for(uint i = 0; i < _buyers.length; i++) {
      buyer = _buyers[i];
      amount = _amounts[i];
      price = _prices[i];
      if (_buyers[i] != address(0)) {
        if (buyers[buyer].allocated == 0) {
          totalAllocated += amount;
        }
        buyers[buyer] = Buyer(amount, price, 0, 0, 0);
        emit UserAllocated(buyer, amount, price, block.timestamp);
      }
    }
    require(totalAllocated <= privateSaleAllocation, "PrivateSale: amount invalid");
  }

  function removeBuyerAllocation(address _buyer) external onlyMainAdmin {
    require(buyers[_buyer].allocated > 0, "PrivateSale: User have no allocation");
    require(buyers[_buyer].lastClaimed == 0, "PrivateSale: User have bought already");
    delete buyers[_buyer];
  }

  function buy(USDCurrency _usdCurrency) external {
    Buyer storage buyer = buyers[msg.sender];
    require(buyer.allocated > 0, "PrivateSale: You have no allocation");
    require(buyer.boughtAtBlock == 0, "PrivateSale: You had bought");
    require(buyer.allocated <= fotaToken.balanceOf(address(this)), "PrivateSale: sale is not start or ended");
    _takeFund(_usdCurrency, buyer.allocated * buyer.price / decimal3);
    uint tgeAmount = buyer.allocated * 20 / 100;
    require(fotaToken.transfer(msg.sender, tgeAmount), "PrivateSale: transfer fota failed");
    buyer.boughtAtBlock = block.number;
    buyer.lastClaimed = block.number;
    buyer.totalClaimed = tgeAmount;
    emit Bought(msg.sender, buyer.allocated, buyer.price, block.timestamp);
    emit Claimed(msg.sender, tgeAmount, block.timestamp);
   }

  function claim() external {
    Buyer storage buyer = buyers[msg.sender];
    require(buyer.boughtAtBlock > 0, "PrivateSale: You have no allocation");
    uint maxBlockNumber = buyer.boughtAtBlock + blockInOneMonth * 12;
    require(maxBlockNumber > buyer.lastClaimed, "PrivateSale: your allocation had released");
    uint blockPass;
    if (block.number < maxBlockNumber) {
      blockPass = block.number - buyer.lastClaimed;
      buyer.lastClaimed = block.number;
    } else {
      blockPass = maxBlockNumber - buyer.lastClaimed;
      buyer.lastClaimed = maxBlockNumber;
    }
    uint releaseAmount = buyer.allocated * 80 / 100 * blockPass / (blockInOneMonth * 12);
    buyer.totalClaimed = buyer.totalClaimed + releaseAmount;

    require(fotaToken.transfer(msg.sender, releaseAmount), "PrivateSale: transfer token failed");
    emit Claimed(msg.sender, releaseAmount, block.timestamp);
  }

  function getBuyer(address _address) external view returns (uint, uint, uint, uint, uint) {
    Buyer storage buyer = buyers[_address];
    return(
    buyer.allocated,
    buyer.price,
    buyer.boughtAtBlock,
    buyer.lastClaimed,
    buyer.totalClaimed
    );
  }

  function _takeFund(USDCurrency _usdCurrency, uint _amount) private {
    IBEP20 usdToken = _usdCurrency == USDCurrency.busd ? busdToken : usdtToken;
    require(usdToken.allowance(msg.sender, address(this)) >= _amount, "PrivateSale: please approve usd token first");
    require(usdToken.balanceOf(msg.sender) >= _amount, "PrivateSale: please fund your account");
    require(usdToken.transferFrom(msg.sender, address(this), _amount), "PrivateSale: transfer usd token failed");
    require(usdToken.transfer(fundAdmin, _amount), "PrivateSale: transfer usd token failed");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Auth is Initializable {

  address internal mainAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  function initialize(address _mainAdmin) virtual public initializer {
    mainAdmin = _mainAdmin;
  }

  modifier onlyMainAdmin() {
    require(isMainAdmin(), "onlyMainAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin external {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
abstract contract IBEP20 {
    function transfer(address to, uint256 value) external virtual returns (bool);

    function approve(address spender, uint256 value) external virtual returns (bool);

    function transferFrom(address from, address to, uint256 value) external virtual returns (bool);

    function balanceOf(address who) external virtual view returns (uint256);

    function allowance(address owner, address spender) external virtual view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

