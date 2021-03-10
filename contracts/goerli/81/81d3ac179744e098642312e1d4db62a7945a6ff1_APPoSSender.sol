/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

interface IStateSender {
  function syncState(address receiver, bytes calldata data) external;
}

interface RootChainManager {
  function depositFor(
    address user,
    address rootToken,
    bytes calldata depositData
  ) external;

  function depositEtherFor(address user) external payable;
}

interface IStateReceiver {
  function onStateReceive(uint256 id, bytes calldata data) external;
}

interface ChildChainManager {
  function rootToChildToken(address) external returns (address);
}

interface IERC20 {
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);
}

interface ILendingPoolAddressesProvider {
  function getLendingPool() external view returns (address);
}

interface ILendingPool {
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract APPoSSender is Ownable {
  address public immutable RECEIVER;
  IStateSender public immutable STATE_SENDER;
  RootChainManager public immutable ROOT_CHAIN_MANAGER;

  address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  constructor(
    address receiver,
    IStateSender stateSender,
    RootChainManager rootChainManager,
    address erc20Predicate,
    IERC20[] memory tokens
  ) {
    RECEIVER = receiver;
    STATE_SENDER = stateSender;
    ROOT_CHAIN_MANAGER = rootChainManager;
    _batchApprove(tokens, erc20Predicate);
  }

  function batchApprove(IERC20[] calldata tokens, address spender) public onlyOwner {
    _batchApprove(tokens, spender);
  }

  function _batchApprove(IERC20[] memory tokens, address spender) internal {
    for (uint256 i = 0; i < tokens.length; i++) {
      tokens[i].approve(spender, type(uint256).max);
    }
  }

  function deposit(
    address user,
    IERC20 token,
    uint256 amount,
    address aaveMarket
  ) external payable {
    bool isEthDeposit = address(token) == ETH_ADDRESS;
    if (isEthDeposit) {
      require(msg.value == amount, 'INCONSISTENT_ETH_VALUE');
    } else {
      require(msg.value == 0, 'NO_ETH_ALLOWED_ON_TOKEN_DEPOSIT');
    }

    bytes memory depositData = abi.encode(amount);

    if (isEthDeposit) {
      ROOT_CHAIN_MANAGER.depositEtherFor{value: amount}(RECEIVER);
    } else {
      token.transferFrom(msg.sender, address(this), amount);
      ROOT_CHAIN_MANAGER.depositFor(RECEIVER, address(token), depositData);
    }

    bytes memory extraData = abi.encode(aaveMarket, user, token, amount);

    STATE_SENDER.syncState(RECEIVER, extraData);
  }
}

contract LendingPool is ILendingPool {
    event DepositedInPool(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    );
    
    uint256 public totalDeposited = 0;
    address public receiver;
    
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external override {
        require(msg.sender == receiver, "ONLU RECEIVER");
        totalDeposited = totalDeposited + amount;
        IERC20(asset).transferFrom(receiver, address(this), amount);
        emit DepositedInPool(asset, amount, onBehalfOf, referralCode);
    }
    
    function setReceiver(address _receiver) public {
        require(receiver == address(0x0));
        receiver = _receiver;
    }
}

contract APPoSReceiver is IStateReceiver {
  address public immutable STATE_RECEIVER;
  ChildChainManager public immutable CHILD_CHAIN_MANAGER;

  constructor(ChildChainManager childChainManager, address stateReceiver) {
    CHILD_CHAIN_MANAGER = childChainManager;
    STATE_RECEIVER = stateReceiver;
  }

  function onStateReceive(uint256, bytes calldata data) external override {
    require(msg.sender == STATE_RECEIVER, 'NOT_VALID_STATE_RECEIVER');

    (ILendingPoolAddressesProvider aaveMarket, address user, address rootToken, uint256 amount) =
      abi.decode(data, (ILendingPoolAddressesProvider, address, address, uint256));
    address childToken = CHILD_CHAIN_MANAGER.rootToChildToken(rootToken);

    ILendingPool aaveLendingPool = ILendingPool(aaveMarket.getLendingPool());
    IERC20(childToken).approve(address(aaveLendingPool), amount);
    aaveLendingPool.deposit(childToken, amount, user, 0);
  }
  
}