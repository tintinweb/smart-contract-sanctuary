/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title Contracts that should not own Tokens
 * @dev This blocks incoming ERC23 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is Ownable {

 /**
  * @dev Reject all ERC23 compatible tokens
  * @param from_ address The address that is transferring the tokens
  * @param value_ Uint the amount of the specified token
  * @param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address from_, uint value_, bytes data_) external {
    throw;
  }

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param tokenAddr address The address of the token contract
   */
  function reclaimToken(address tokenAddr) external onlyOwner {
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(owner, balance);
  }
}

// @dev Contract to hold ETH raised during a token sale.
// Prevents attack in which the Multisig sends raised ether to the
// sale contract to mint tokens to itself, and getting the
// funds back immediately.
contract AbstractSale {
  function saleFinalized() constant returns (bool);
}

contract Escrow is HasNoTokens {

  address public beneficiary;
  uint public finalBlock;
  AbstractSale public tokenSale;

  // @dev Constructor initializes public variables
  // @param _beneficiary The address of the multisig that will receive the funds
  // @param _finalBlock Block after which the beneficiary can request the funds
  function Escrow(address _beneficiary, uint _finalBlock, address _tokenSale) {
    beneficiary = _beneficiary;
    finalBlock = _finalBlock;
    tokenSale = AbstractSale(_tokenSale);
  }

  // @dev Receive all sent funds without any further logic
  function() public payable {}

  // @dev Withdraw function sends all the funds to the wallet if conditions are correct
  function withdraw() public {
    if (msg.sender != beneficiary) throw;
    if (block.number > finalBlock) return doWithdraw();
    if (tokenSale.saleFinalized()) return doWithdraw();
  }

  function doWithdraw() internal {
    if (!beneficiary.send(this.balance)) throw;
  }
}