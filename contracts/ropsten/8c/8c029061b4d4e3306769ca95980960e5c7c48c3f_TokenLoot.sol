pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20.sol

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

// File: contracts/TokenLoot.sol

/// @title Token Loot Contract
/// @author Julia Altenried, Yuriy Kashnikov

contract TokenLoot is Ownable {

  // FIELDS
  /* signer address, verified in &#39;receiveTokenLoot&#39; method, can be set by owner only */
  address public neverdieSigner;
  /* SKL token */
  ERC20 public sklToken;
  /* XP token */
  ERC20 public xpToken;
  /* Gold token */
  ERC20 public goldToken;
  /* Silver token */
  ERC20 public silverToken;
  /* Scale token */
  ERC20 public scaleToken;
  /* Strength token */
  ERC20 public stgToken;
  /* Magic token */
  ERC20 public magToken;
  /* Dexterity token */
  ERC20 public dexToken;
  /* Luck token */
  ERC20 public luckToken;
  /* Nonces */
  mapping (address => uint256) public nonces;


  // EVENTS
  event ReceiveLoot(address indexed sender,
                    uint256 _amountSKL,
                    uint256 _amountXP,
                    uint256 _amountGold,
                    uint256 _amountSilver,
                    uint256 _amountScale,
                    uint256 _amountSTG,
                    uint256 _amountMAG,
                    uint256 _amountDEX,
                    uint256 _amountLUCK,
                    uint256 _nonce);


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

  function setSTGContractAddress(address _to) public onlyOwner {
    stgToken = ERC20(_to);
  }

  function setLUCKContractAddress(address _to) public onlyOwner {
    luckToken = ERC20(_to);
  }

  function setMAGContractAddress(address _to) public onlyOwner {
    magToken = ERC20(_to);
  }

  function setDEXContractAddress(address _to) public onlyOwner {
    dexToken = ERC20(_to);
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
                     address _stgContractAddress,
                     address _magContractAddress,
                     address _dexContractAddress,
                     address _luckContractAddress,
                     address _signer) {
    xpToken = ERC20(_xpContractAddress);
    sklToken = ERC20(_sklContractAddress);
    goldToken = ERC20(_goldContractAddress);
    silverToken = ERC20(_silverContractAddress);
    scaleToken = ERC20(_scaleContractAddress);
    stgToken = ERC20(_stgContractAddress);
    magToken = ERC20(_magContractAddress);
    dexToken = ERC20(_dexContractAddress);
    luckToken = ERC20(_luckContractAddress);
    
    neverdieSigner = _signer;
  }

  /// @dev withdraw loot tokens
  /// @param _amounts the amounts of tokens to withdraw
  /// @param _nonce incremental index of withdrawal
  /// @param _v ECDCA signature
  /// @param _r ECDSA signature
  /// @param _s ECDSA signature
  function receiveTokenLoot(uint256[9] _amounts,
                            uint256 _nonce, 
                            uint8 _v, 
                            bytes32 _r, 
                            bytes32 _s) {

    // reject if the new nonce is lower or equal to the current one
    require(_nonce > nonces[msg.sender]);
    nonces[msg.sender] = _nonce;

    // verify signature
    //address signer = ecrecover(keccak256(abi.encodePacked(msg.sender, 
    //                                     _amounts, 
    //                                     _nonce)), _v, _r, _s);
    //require(signer == neverdieSigner);

    // _amounts[0] -> SKL
    // _amounts[1] -> XP
    // _amounts[2] -> Gold
    // _amounts[3] -> Silver
    // _amounts[4] -> Scale
    // _amounts[5] -> STG
    // _amounts[6] -> MAG
    // _amounts[7] -> DEX
    // _amounts[8] -> LUCK
    // transer tokens
    if (_amounts[0] > 0) assert(sklToken.transfer(msg.sender, _amounts[0]));
    if (_amounts[1] > 0) assert(xpToken.transfer(msg.sender, _amounts[1]));
    if (_amounts[2] > 0) assert(goldToken.transfer(msg.sender, _amounts[2]));
    if (_amounts[3] > 0) assert(silverToken.transfer(msg.sender, _amounts[3]));
    if (_amounts[4] > 0) assert(scaleToken.transfer(msg.sender, _amounts[4]));
    if (_amounts[5] > 0) assert(stgToken.transfer(msg.sender, _amounts[5]));
    if (_amounts[6] > 0) assert(magToken.transfer(msg.sender, _amounts[6]));
    if (_amounts[7] > 0) assert(dexToken.transfer(msg.sender, _amounts[7]));
    if (_amounts[8] > 0) assert(luckToken.transfer(msg.sender, _amounts[8]));

    // emit event
    emit ReceiveLoot(msg.sender, 
                     _amounts[0], 
                     _amounts[1], 
                     _amounts[2], 
                     _amounts[3], 
                     _amounts[4], 
                     _amounts[5], 
                     _amounts[6], 
                     _amounts[7], 
                     _amounts[8], 
                     _nonce);

                     /*
 uint256 _amountSKL,
                    uint256 _amountXP,
                    uint256 _amountGold,
                    uint256 _amountSilver,
                    uint256 _amountScale,
                    uint256 _amountSTG,
                    uint256 _amountDEX,
                    uint256 _amountMAG,
                    uint256 _amountLUCK,
                   */

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
    uint256 allSTG = stgToken.balanceOf(this);
    uint256 allDEX = dexToken.balanceOf(this);
    uint256 allMAG = magToken.balanceOf(this);
    uint256 allLUCK = luckToken.balanceOf(this);
    if (allSKL > 0) sklToken.transfer(msg.sender, allSKL);
    if (allXP > 0) xpToken.transfer(msg.sender, allXP);
    if (allGold > 0) goldToken.transfer(msg.sender, allGold);
    if (allSilver > 0) silverToken.transfer(msg.sender, allSilver);
    if (allScale > 0) scaleToken.transfer(msg.sender, allScale);
    if (allSTG > 0) stgToken.transfer(msg.sender, allSTG);
    if (allDEX > 0) dexToken.transfer(msg.sender, allDEX);
    if (allMAG > 0) magToken.transfer(msg.sender, allMAG);
    if (allLUCK > 0) luckToken.transfer(msg.sender, allLUCK);
  }

  /// @dev kill contract, but before transfer all SKL and XP tokens 
  function kill() onlyOwner public {
    withdraw();
    selfdestruct(owner);
  }

}