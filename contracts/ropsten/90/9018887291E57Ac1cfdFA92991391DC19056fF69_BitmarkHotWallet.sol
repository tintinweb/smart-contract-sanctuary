pragma solidity ^0.4.24;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/BitmarkHotWallet.sol

contract Authorizable is Ownable {
    address public trustee;

    constructor() public {
        trustee = 0x0;
    }

    modifier onlyAuthorized() {
        require(msg.sender == trustee || msg.sender == owner);
        _;
    }

    function setTrustee(address _newTrustee) public onlyOwner {
        trustee = _newTrustee;
    }
}


contract BitmarkHotWallet is Authorizable, Pausable {
    // mapping(address => mapping(address => uint256)) ownedTokens;
    mapping(address => mapping(uint256 => address)) internal ownedAssets;

    event ERC20TokenWithdraw(address indexed tokenContract, uint256 indexed amount, address indexed to);
    event ERC721TokenDeposit(address indexed tokenContract, uint256 indexed tokenId, address indexed to);
    event ERC721TokenWithdraw(address indexed tokenContract, uint256 indexed tokenId, address indexed to);

    function bytesToBytes32(bytes data) internal pure returns (bytes32 result) {
        require(data.length == 32, "incorrect length of bytes32");
        assembly {
            result := mload(add(data, 0x20))
        }
    }

    function bytesToAddress(bytes data) internal pure returns (address result) {
        require(data.length == 20, "incorrect length of address");
        assembly {
            result := div(mload(add(data, 0x20)), 0x1000000000000000000000000)
        }
    }

    function withdrawERC20(address tokenContract, uint256 amount, address to) public onlyAuthorized {
        require(tokenContract.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount)));
        emit ERC20TokenWithdraw(tokenContract, amount, to);
    }

    function withdrawERC721(address tokenContract, uint256 tokenId, address from, address to) public onlyAuthorized {
        require(from != 0x0 && ownedAssets[tokenContract][tokenId] == from);
        ownedAssets[tokenContract][tokenId] = 0x0;
        require(tokenContract.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(this), to, tokenId)));
        emit ERC721TokenWithdraw(tokenContract, tokenId, to);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes data
    )
        public whenNotPaused
        returns(bytes4)
    {
        // msg.sender here will be the token contract itself.
        address to = bytesToAddress(data);
        ownedAssets[msg.sender][tokenId] = to;
        emit ERC721TokenDeposit(msg.sender, tokenId, to);
        return this.onERC721Received.selector;
    }
}