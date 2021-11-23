/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



interface INova {

    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function mint(address account, uint96 amount) external ;
    function burn(address account, uint96 amount) external ;

    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}



// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}


interface IERC20 {
  function decimals() external view returns (uint8);
  function balanceOf(address owner) external view returns (uint);
}

// transfer Owner to Gover After initMembers.
contract NovaDao is Ownable {

  uint constant INIT_MEMBER_COUNT = 50;

  address public immutable usdt;
  uint8 private immutable decimals;

  uint constant FEE_PERCENT  = 200;  
  uint constant BASE_PERCENT = 10000;   
  uint public feePercent = FEE_PERCENT;

  INova public nova;
  uint96 private deltaFund;

  address public feeReceiver;
  uint public maxBalance = 5;

  uint96 private lastJoinfund;
  
  uint contributed;
  uint withdrawed;

  mapping (address => bool) public candidates;

  event Withdrawal(address indexed receiver, uint256 amount);
  event AddCandidate(address indexed user);
  event Deposit(address indexed receiver, uint256 amount);
  event Quit(address indexed user, address receiver, uint256 amount);
  event SetFeeReceiver(address indexed receiver);

  constructor(address _receiver, address _usdt) {
    feeReceiver = _receiver;
    emit SetFeeReceiver(_receiver);

    uint8 dec = IERC20(_usdt).decimals();
    decimals = dec;

    uint96 _fund  = uint96(10000 * 10 ** dec);
    uint96 _delta = uint96(200 * 10 ** dec);

    lastJoinfund = _fund;

    deltaFund = _delta;
    usdt = _usdt;

  }

  function initNova() public {
    require(address(nova) == address(0), "inited");
    nova = INova(msg.sender);
  }


  function initMembers(address[] memory members) external onlyOwner {
    require(nova.totalSupply() + members.length <= INIT_MEMBER_COUNT, "Invalid members");

    uint needFund = members.length * lastJoinfund;
    contributed += needFund;
    
    for (uint i = 0; i < members.length; i++) {
      nova.mint(members[i], 1);
    }
  }

  function setMaxBalance(uint _maxBalance) external onlyOwner {
    require(_maxBalance < nova.totalSupply() / 4, "too big");
    maxBalance = _maxBalance;
  }

  function setFeeReceiver(address _receiver) external onlyOwner {
    require(_receiver != address(0), "zero address");

    require(_receiver != feeReceiver, "same receiver");
    feeReceiver = _receiver;
    emit SetFeeReceiver(_receiver);
  }

  function setFeePercent(uint _percent) external onlyOwner {
    require(_percent < BASE_PERCENT / 10, "percent too big");
    feePercent = _percent;
  }

  function setDeltaFund(uint96 delta) external onlyOwner {
    deltaFund = delta;
  }

  function fundInfo() external view returns (uint , uint, uint, uint ) {
    return (lastJoinfund, deltaFund, contributed, withdrawed);
  } 

  function addCandidate(address user) external onlyOwner returns (bool success) {
    require(!candidates[user], "Candidate Aleady");
    candidates[user] = true;
    return true;
  }

  function joinMember(address user) public {
    require(candidates[user], "Invalid Candidate");

    if(nova.totalSupply() < INIT_MEMBER_COUNT) {
      TransferHelper.safeTransferFrom(usdt, user, address(this), lastJoinfund);
    } else {
      lastJoinfund = lastJoinfund + deltaFund;
      TransferHelper.safeTransferFrom(usdt, user, address(this), lastJoinfund);

      uint fee = lastJoinfund * feePercent / BASE_PERCENT;
      TransferHelper.safeTransfer(usdt, feeReceiver, fee);
    }

    contributed += lastJoinfund;
    
    candidates[user] = false;
    nova.mint(user, 1);
  }

  function addMemberFund(uint number) public {
    uint share = nova.balanceOf(msg.sender);
    require(share >= 1, "Not Member");
    require(share + number <= maxBalance, "Need under maxBalance");

    uint joinFund = lastJoinfund * number;
    TransferHelper.safeTransferFrom(usdt, msg.sender, address(this), joinFund);

    uint fee = joinFund * feePercent / BASE_PERCENT;
    TransferHelper.safeTransfer(usdt, feeReceiver, fee);

    contributed += joinFund;
    nova.mint(msg.sender, uint96(number));
  }

	function withdraw(address receiver, uint256 amount) external onlyOwner {
    emit Withdrawal(receiver, amount);
    TransferHelper.safeTransfer(usdt, receiver, amount);
    withdrawed += amount;
	}

  function rageQuit(address receiver) external {
    uint share = nova.balanceOf(msg.sender);
    uint balance = IERC20(usdt).balanceOf(address(this));
    require(share >= 1, "Not Member");
    uint amount = share * balance * 9 / nova.totalSupply() / 10;
    emit Quit(msg.sender, receiver, amount);
    nova.burn(msg.sender, uint96(share));
    TransferHelper.safeTransfer(usdt, receiver, amount);
  }

}