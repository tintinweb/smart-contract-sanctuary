pragma solidity ^0.4.18;


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
 function Ownable() public {
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @title Token Loot Contract
/// @author Julia Altenried, Yuriy Kashnikov

contract TokenLoot is Ownable {

  // FIELDS
  /* signer address, verified in &#39;receiveTokenLoot&#39; method, can be set by owner only */
  address neverdieSigner;
  /* SKL token */
  ERC20 sklToken;
  /* XP token */
  ERC20 xpToken;
  /* Gold token */
  ERC20 goldToken;
  /* Silver token */
  ERC20 silverToken;
  /* Scale token */
  ERC20 scaleToken;
  /* Nonces */
  mapping (address => uint) public nonces;


  // EVENTS
  event ReceiveLoot(address indexed sender,
                    uint _amountSKL,
                    uint _amountXP,
                    uint _amountGold,
                    uint _amountSilver,
                    uint _amountScale,
                    uint _nonce);
 

  // SETTERS
  function setSKLContractAddress(address _to) public onlyOwner {
    sklToken = ERC20(_to);
  }

  function setXPContractAddress(address _to) public onlyOwner {
    xpToken = ERC20(_to);
  }

  function setGoldContractAddress(address _to) public onlyOwner {
    goldToken = ERC20(_to);
  }

  function setSilverContractAddress(address _to) public onlyOwner {
    silverToken = ERC20(_to);
  }

  function setScaleContractAddress(address _to) public onlyOwner {
    scaleToken = ERC20(_to);
  }

  function setNeverdieSignerAddress(address _to) public onlyOwner {
    neverdieSigner = _to;
  }

  /// @dev handy constructor to initialize TokenLoot with a set of proper parameters
  /// @param _xpContractAddress XP token address
  /// @param _sklContractAddress SKL token address
  /// @param _goldContractAddress Gold token address
  /// @param _silverContractAddress Silver token address
  /// @param _scaleContractAddress Scale token address
  /// @param _signer signer address, verified further in swap functions
  function TokenLoot(address _xpContractAddress,
                     address _sklContractAddress,
                     address _goldContractAddress,
                     address _silverContractAddress,
                     address _scaleContractAddress,
                     address _signer) {
    xpToken = ERC20(_xpContractAddress);
    sklToken = ERC20(_sklContractAddress);
    goldToken = ERC20(_goldContractAddress);
    silverToken = ERC20(_silverContractAddress);
    scaleToken = ERC20(_scaleContractAddress);
    neverdieSigner = _signer;
  }

  /// @dev withdraw loot tokens
  /// @param _amountSKL the amount of SKL tokens to withdraw
  /// @param _amountXP them amount of XP tokens to withdraw
  /// @param _amountGold them amount of Gold tokens to withdraw
  /// @param _amountSilver them amount of Silver tokens to withdraw
  /// @param _amountScale them amount of Scale tokens to withdraw
  /// @param _nonce incremental index of withdrawal
  /// @param _v ECDCA signature
  /// @param _r ECDSA signature
  /// @param _s ECDSA signature
  function receiveTokenLoot(uint _amountSKL, 
                            uint _amountXP, 
                            uint _amountGold, 
                            uint _amountSilver,
                            uint _amountScale,
                            uint _nonce, 
                            uint8 _v, 
                            bytes32 _r, 
                            bytes32 _s) {

    // reject if the new nonce is lower or equal to the current one
    require(_nonce > nonces[msg.sender]);
    nonces[msg.sender] = _nonce;

    // verify signature
    address signer = ecrecover(keccak256(msg.sender, 
                                         _amountSKL, 
                                         _amountXP, 
                                         _amountGold,
                                         _amountSilver,
                                         _amountScale,
                                         _nonce), _v, _r, _s);
    require(signer == neverdieSigner);

    // transer tokens
    if (_amountSKL > 0) assert(sklToken.transfer(msg.sender, _amountSKL));
    if (_amountXP > 0) assert(xpToken.transfer(msg.sender, _amountXP));
    if (_amountGold > 0) assert(goldToken.transfer(msg.sender, _amountGold));
    if (_amountSilver > 0) assert(silverToken.transfer(msg.sender, _amountSilver));
    if (_amountScale > 0) assert(scaleToken.transfer(msg.sender, _amountScale));

    // emit event
    ReceiveLoot(msg.sender, _amountSKL, _amountXP, _amountGold, _amountSilver, _amountScale, _nonce);
  }

  /// @dev fallback function to reject any ether coming directly to the contract
  function () payable public { 
      revert(); 
  }

  /// @dev withdraw all SKL and XP tokens
  function withdraw() public onlyOwner {
    uint256 allSKL = sklToken.balanceOf(this);
    uint256 allXP = xpToken.balanceOf(this);
    uint256 allGold = goldToken.balanceOf(this);
    uint256 allSilver = silverToken.balanceOf(this);
    uint256 allScale = scaleToken.balanceOf(this);
    if (allSKL > 0) sklToken.transfer(msg.sender, allSKL);
    if (allXP > 0) xpToken.transfer(msg.sender, allXP);
    if (allGold > 0) goldToken.transfer(msg.sender, allGold);
    if (allSilver > 0) silverToken.transfer(msg.sender, allSilver);
    if (allScale > 0) scaleToken.transfer(msg.sender, allScale);
  }

  /// @dev kill contract, but before transfer all SKL and XP tokens 
  function kill() onlyOwner public {
    withdraw();
    selfdestruct(owner);
  }

}