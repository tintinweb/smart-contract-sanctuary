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
    bytes4 internal constant Interface_Transfer = 0xa9059cbb;
    // bytes4(keccak256(&#39;transfer(address,uint256)&#39;))
    bytes4 internal constant Interface_TransferFrom = 0x23b872dd;
    // bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;))
    bytes4 internal constant Interface_ERC721SafeTransferFrom = 0x42842e0e;
    // bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;))

    // ownedAssets keeps assets which are delegated to this smart contract
    mapping(address => mapping(uint256 => address)) internal ownedAssets;

    event ERC20TokenWithdraw(address indexed tokenContract, uint256 indexed amount, address indexed to);
    event ERC721TokenDeposit(address indexed tokenContract, uint256 indexed tokenId, address indexed to);
    event ERC721TokenWithdraw(address indexed tokenContract, uint256 indexed tokenId, address indexed to);

    // a magic function that turns bytes into an address
    function bytesToAddress(bytes data) internal pure returns (address result) {
        require(data.length == 20, "incorrect length of address");
        assembly {
            result := div(mload(add(data, 0x20)), 0x1000000000000000000000000)
        }
    }

    // withdrawERC20 is a backup function in case tokens are transferred into the account accidentally
    function withdrawERC20(address tokenContract, uint256 amount, address to) public onlyAuthorized {
        require(tokenContract.call(Interface_Transfer, to, amount));
        emit ERC20TokenWithdraw(tokenContract, amount, to);
    }

    // depositERC721 is used to deposit funds after a token has set approval to this contract.
    function depositERC721(address tokenContract, uint256 tokenId, address to) public {
        require(tokenContract.call(Interface_TransferFrom, msg.sender, address(this), tokenId));
        ownedAssets[tokenContract][tokenId] = to;
        emit ERC721TokenDeposit(tokenContract, tokenId, to);
    }

    // withdrawERC721 will withdraw tokens using transfer function. There is a risk of losing funds
    // if the destination is not a token-transferable address.
    function withdrawERC721(address tokenContract, uint256 tokenId, address from, address to) public onlyAuthorized {
        require(from != 0x0 && ownedAssets[tokenContract][tokenId] == from);
        ownedAssets[tokenContract][tokenId] = 0x0;
        require(tokenContract.call(Interface_Transfer, to, tokenId));
        emit ERC721TokenWithdraw(tokenContract, tokenId, to);
    }

    // withdrawERC721 will withdraw tokens using safeTransferFrom function which guarantees a token is
    // transferable in the next destination.
    function safeWithdrawERC721(address tokenContract, uint256 tokenId, address from, address to) public onlyAuthorized {
        require(from != 0x0 && ownedAssets[tokenContract][tokenId] == from);
        ownedAssets[tokenContract][tokenId] = 0x0;
        require(tokenContract.call(Interface_ERC721SafeTransferFrom, address(this), to, tokenId));
        emit ERC721TokenWithdraw(tokenContract, tokenId, to);
    }

    // onERC721Received follows the SPEC of ERC721 and keeps information about the ownership of the tokens
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