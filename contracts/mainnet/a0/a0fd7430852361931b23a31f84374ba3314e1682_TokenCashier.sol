/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// File: contracts/ownership/Ownable.sol

pragma solidity <6.0 >=0.4.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
// File: contracts/lifecycle/Pausable.sol

pragma solidity <0.6 >=0.4.24;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/iotube/TokenCashier.sol

pragma solidity <6.0 >=0.4.24;


interface ITokenList {
    function isAllowed(address) external returns (bool);
    function maxAmount(address) external returns (uint256);
    function minAmount(address) external returns (uint256);
}

interface IWrappedCoin {
    function deposit() external payable;
}

contract TokenCashier is Pausable {
    event Receipt(address indexed token, uint256 indexed id, address sender, address recipient, uint256 amount, uint256 fee);

    ITokenList[] public tokenLists;
    address[] public tokenSafes;
    mapping(address => uint256) public counts;
    uint256 public depositFee;
    IWrappedCoin public wrappedCoin;

    constructor(IWrappedCoin _wrappedCoin, ITokenList[] memory _tokenLists, address[] memory _tokenSafes) public {
        require(_tokenLists.length == _tokenSafes.length, "# of token lists is not equal to # of safes");
        wrappedCoin = _wrappedCoin;
        tokenLists = _tokenLists;
        tokenSafes = _tokenSafes;
    }

    function() external {
        revert();
    }

    function count(address _token) public view returns (uint256) {
        return counts[_token];
    }

    function setDepositFee(uint256 _fee) public onlyOwner {
        depositFee = _fee;
    }

    function depositTo(address _token, address _to, uint256 _amount) public whenNotPaused payable {
        require(_to != address(0), "invalid destination");
        bool isCoin = false;
        uint256 fee = msg.value;
        if (_token == address(0)) {
            require(msg.value >= _amount, "insufficient msg.value");
            fee = msg.value - _amount;
            wrappedCoin.deposit.value(_amount)();
            _token = address(wrappedCoin);
            isCoin = true;
        }
        require(fee >= depositFee, "insufficient fee");
        for (uint256 i = 0; i < tokenLists.length; i++) {
            if (tokenLists[i].isAllowed(_token)) {
                require(_amount >= tokenLists[i].minAmount(_token), "amount too low");
                require(_amount <= tokenLists[i].maxAmount(_token), "amount too high");
                if (tokenSafes[i] == address(0)) {
                    require(!isCoin && safeTransferFrom(_token, msg.sender, address(this), _amount), "fail to transfer token to cashier");
                    // selector = bytes4(keccak256(bytes('burn(uint256)')))
                    (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x42966c68, _amount));
                    require(success && (data.length == 0 || abi.decode(data, (bool))), "fail to burn token");
                } else {
                    if (isCoin) {
                        require(safeTransfer(_token, tokenSafes[i], _amount), "failed to put into safe");
                    } else {
                        require(safeTransferFrom(_token, msg.sender, tokenSafes[i], _amount), "failed to put into safe");
                    }
                }
                counts[_token] += 1;
                emit Receipt(_token, counts[_token], msg.sender, _to, _amount, fee);
                return;
            }
        }
        revert("not a whitelisted token");
    }

    function deposit(address _token, uint256 _amount) public payable {
        depositTo(_token, msg.sender, _amount);
    }

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawToken(address _token) public onlyOwner {
        // selector = bytes4(keccak256(bytes('balanceOf(address)')))
        (bool success, bytes memory balance) = _token.call(abi.encodeWithSelector(0x70a08231, address(this)));
        require(success, "failed to call balanceOf");
        uint256 bal = abi.decode(balance, (uint256));
        if (bal > 0) {
            require(safeTransfer(_token, msg.sender, bal), "failed to withdraw token");
        }
    }

    function safeTransferFrom(address _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        // selector = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')))
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _amount));
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }

    function safeTransfer(address _token, address _to, uint256 _amount) internal returns (bool) {
        // selector = bytes4(keccak256(bytes('transfer(address,uint256)')))
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, _to, _amount));
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }
}