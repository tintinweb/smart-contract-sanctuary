/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

pragma solidity 0.8.4;
//SPDX-License-Identifier: UNLICENSED

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint value) external returns (bool);
}


contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ( address ownerAdd) {
        _owner = ownerAdd;
        emit OwnershipTransferred(address(0), ownerAdd);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;
  
  constructor( address _master) Ownable( _master) { }


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

contract SignatureVerifier {
    bytes32 public constant SIGNATURE_PERMIT_TYPEHASH = keccak256("verify(address _owner, uint _keyID, uint _oppoKey, uint _nonces, uint _deadline, bytes memory signature)");
    uint public chainId;
    
    using ECDSA for bytes32;
    
    constructor() {
        uint _chainId;
        assembly {
            _chainId := chainid()
        }
        
        chainId = _chainId;
    }

    function verify(
        uint _keyID,
        uint _oppKeyID,
        address _owner,
        uint _finalAccuracy,
        uint _skill,
        uint _power,
        uint _nonces,
        uint _deadline,
        bytes memory signature
    ) public view returns (address){
      // This recreates the message hash that was signed on the client.
      bytes32 hash = keccak256(abi.encodePacked(SIGNATURE_PERMIT_TYPEHASH, _keyID, _oppKeyID, _owner, _finalAccuracy, _skill, _power, chainId, _nonces, _deadline));
      bytes32 messageHash = hash.toSignedMessageHash();
    
      // Verify that the message's signer is the owner of the order
      return messageHash.recover(signature);
    }
}

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables with inline assembly.
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

contract Battle is Pausable,SignatureVerifier{
    
    event AddCharRoaster (
        address _addBy,
        uint _keyID,
        uint _roasterIndex
    );
    
    event swapCharRoaster (
        uint _index,
        address owner,
        uint swapKeyID,
        uint _keyID
    );
    
    event Combat (
        uint _charKey,
        uint _oppoCharKey,
        address _charOwner,
        address _oppoCharOwner,
        uint _chanceOfWin,
        uint _reward
    );
    
    event revertCharacters (
        uint _charKey,
        uint _index,
        address _owner
    );
    
    IERC20 public Defverse;
    IERC721 public Characters;
    
    struct UserInfoStruct { // User Info
        uint8 _charIndexRoaster;
        uint _avlClaimAmt;
        uint _lastClaim;
        uint _taxableLimit;
        uint nonces;
        mapping(uint => RoasterStruct) roasterInfo;
        mapping(uint => uint) _keyIndex;
    }
    
    struct RoasterStruct { // Roaster Info
        uint _keyID;
        uint _attackStacks;
        bool _onRoaster;
        uint _onListTimeStamp;
        uint _coolDown;
    }
    
    address public taxAddr;
    
    uint public maxCharInRoaster = 10;
    uint[3] public coolDownHrs = [3 minutes, 30 minutes, 24 hours];
    uint public masterMultiplier;
    uint public defaultReward;
    uint[2] public taxLimit = [2000 /* tax */, type(uint256).max /* tax limit */]; // 2000 = 20%
    
    mapping(address => UserInfoStruct) public userInfo;
    mapping(uint => address) public keyOwner;
    mapping(bytes => bool)  public isSigned;
    mapping(address => bool) public blackList;
    
    constructor( address _masterAdmin, address _DefverseCharacter, IERC20 _defverse, uint _masterMultiplier, uint _defaultReward) Pausable( _masterAdmin) {
        Characters = IERC721(_DefverseCharacter);
        Defverse = _defverse;
        masterMultiplier = _masterMultiplier;
        defaultReward = _defaultReward;
        taxAddr = _masterAdmin;
    }
    
    modifier _isBlackList() {
        require(!blackList[_msgSender()], "Blacklist user");
        _;
    }
    
    function addCharToRoaster( uint keyID) external _isBlackList {
        require(userInfo[_msgSender()]._charIndexRoaster < maxCharInRoaster, "addCharToRoaster : only 10 characters must be in the roaster");
        
        uint8 _index = ++userInfo[_msgSender()]._charIndexRoaster;
        _addCharacter(_index, keyID);
        
        emit AddCharRoaster ( _msgSender(), keyID, _index);
    }
    
    function swapCharacter( uint keyID, uint _index) external {
        require((_index <= userInfo[_msgSender()]._charIndexRoaster) && (_index > 0), "invalid index");
        require(userInfo[_msgSender()].roasterInfo[_index]._onListTimeStamp < block.timestamp, "characters can only removed after 24 hrs from added time");
        
        if(blackList[_msgSender()]) require(keyID == 0, "Blacklist user can only remove character if exist");
        
        uint _oldKeyId = userInfo[_msgSender()].roasterInfo[_index]._keyID;
        require(userInfo[_msgSender()].roasterInfo[_index]._coolDown < block.timestamp, "cannot swap token on the cool down period");
        
        _removeChar( _msgSender(), _oldKeyId, _index);
        
        if(keyID > 0) {
            _addCharacter(_index, keyID);
        } else{
            _swappingCharacters(_msgSender(), _index,userInfo[_msgSender()]._charIndexRoaster);    
        }
        
        emit swapCharRoaster (
            _index,
            _msgSender(),
            _oldKeyId,
            keyID
        );
    }

    struct Player {
        uint _keyID;
        address _owner;
        uint _finalAccuracy;
    }
    
    struct CombatParams {
        Player player;
        Player opponent;
        uint skill;
        uint power;
        uint deadline;
        bytes signature;
    }
    
    function combat(CombatParams memory combatParams ) external _isBlackList {
        (uint playerIndex, address playAdd) = (userInfo[_msgSender()]._keyIndex[combatParams.player._keyID], keyOwner[combatParams.player._keyID]);        
        
        require(userInfo[combatParams.player._owner]._charIndexRoaster > 0, "there must be atleast one character in the roaster");
        require((combatParams.player._owner == _msgSender()) && (playAdd == _msgSender()), "Is not a owner or the character may removed");
        require(combatParams.opponent._owner != address(0), "Opponent character may removed from the roaster");
        
        _validateSignature( 
            combatParams
        );
        
        require(combatParams.player._owner != combatParams.opponent._owner, "Opponent must not be owner of character");
        require(userInfo[combatParams.player._owner].roasterInfo[playerIndex]._onRoaster, "Character is not on the roaster");
        require(userInfo[combatParams.player._owner].roasterInfo[playerIndex]._coolDown != 0, "Character should go on the cooldown period to participate in combat");
        require(userInfo[combatParams.player._owner].roasterInfo[playerIndex]._coolDown < block.timestamp, "Character should wait till combat period ends");
        require((combatParams.player._finalAccuracy > 0) && (combatParams.opponent._finalAccuracy > 0), "combat :: _finalAccuracy must be greater than zero");
        
        uint _chanceOfWin = _chanceOfWining( combatParams.player._finalAccuracy, combatParams.opponent._finalAccuracy);
        
        if(_chanceOfWin == 0) return;
        
        uint _reward = _winingReward( _chanceOfWin*1e18/100e18, combatParams.skill, combatParams.power);
        
        userInfo[_msgSender()]._avlClaimAmt += _reward;
        userInfo[combatParams.player._owner].roasterInfo[playerIndex]._attackStacks++;
        userInfo[combatParams.player._owner].roasterInfo[playerIndex]._coolDown = block.timestamp+coolDownHrs[0];
        
        if(userInfo[combatParams.player._owner].roasterInfo[playerIndex]._attackStacks == 2){
            userInfo[combatParams.player._owner].roasterInfo[playerIndex]._coolDown = 0;
            userInfo[combatParams.player._owner].roasterInfo[playerIndex]._onRoaster = false;
        }
        
        emit Combat (
            combatParams.player._keyID,
            combatParams.opponent._keyID,
            combatParams.player._owner,
            combatParams.opponent._owner,
            _chanceOfWin,
            _reward
        );
        
    }
    
    function claim() external _isBlackList {
        require(userInfo[_msgSender()]._avlClaimAmt > 0, "claim : no available amount");
        
        uint[3] memory _amount;
        _amount[0] = userInfo[_msgSender()]._avlClaimAmt;
        userInfo[_msgSender()]._avlClaimAmt = 0;
        
        if((userInfo[_msgSender()]._lastClaim+coolDownHrs[1]) > block.timestamp) {
            require(userInfo[_msgSender()]._taxableLimit < taxLimit[1], "claim : exceed taxable");
            userInfo[_msgSender()]._taxableLimit++;
            _amount[1] = _amount[0]*taxLimit[0]/10**4;
            _amount[2] = _amount[0] - _amount[1];
        } else {
            _amount[2] = _amount[0];
        }
        
        userInfo[_msgSender()]._lastClaim = block.timestamp;
        
        if(_amount[1] > 0) Defverse.transfer(taxAddr, _amount[1]);
        
        Defverse.transfer(_msgSender(), _amount[2]);
    }
    
    function revertCharacter(uint _keyID) external onlyOwner { // in case of any failure.
        address _owner = keyOwner[_keyID];
        uint _index = userInfo[_owner]._keyIndex[_keyID];
        
        require(_owner != address(0) && (_index != 0), "Character already removed from the roaster");
        
        _removeChar( _owner, _keyID, _index);
        
        emit revertCharacters (
            _keyID,
            _index,
            _owner
        );
    }

    function setDverse( IERC20 _defverse) external onlyOwner {
        Defverse = _defverse;
    }
    
    function setAccBlackList( address[] memory _acc) external onlyOwner {
        for(uint i=0; i<_acc.length;i++) {
            blackList[_acc[i]] = true;
        }
    }
    
    function removeAccBlackList( address[] memory _acc) external onlyOwner {
        for(uint i=0; i<_acc.length;i++) {
            blackList[_acc[i]] = false;
        }
    }
    
    function setMaxCharInRoaster( uint _maxCharInRoaster) external onlyOwner {
        maxCharInRoaster = _maxCharInRoaster;
    }
    
    function setMasterMultiplier( uint _masterMultiplier) external onlyOwner {
        masterMultiplier = _masterMultiplier;
    }
    
    function setDefaultReward( uint _defaultReward) external onlyOwner {
        defaultReward = _defaultReward;
    }
    
    function setCoolDown( uint8 _index, uint _coolDown) external onlyOwner {
        require((_index >= 0) && (_index <= 2));
        coolDownHrs[_index] = _coolDown;
    }
    
    function setTax( uint8 _index, uint _tax) external onlyOwner {
        require((_index == 0) || (_index == 1));
        taxLimit[_index] = _tax;
    }
    
    function setTaxAdd( address _taxAddr) external onlyOwner {
        taxAddr = _taxAddr;
    }
    
    function emergencyRewardWithdrawal( uint _amount) external onlyOwner {
        require(Defverse.balanceOf( address(this)) > _amount);
        Defverse.transfer(owner(), _amount);
    } 
    
    function _swappingCharacters( address _owner, uint _fromIndex, uint8 _toIndex) private {
        for(uint i=_fromIndex; i<_toIndex; i++) {
            userInfo[_owner].roasterInfo[i] = userInfo[_owner].roasterInfo[i+1];
            userInfo[_owner]._keyIndex[userInfo[_owner].roasterInfo[i]._keyID] = i;
        }
        
        delete userInfo[_owner].roasterInfo[_toIndex];
        userInfo[_owner]._charIndexRoaster--;
    }
    
    function _addCharacter( uint _index, uint keyID)  private {
        Characters.transferFrom(_msgSender(),address(this),keyID);
    
        userInfo[_msgSender()].roasterInfo[_index] = RoasterStruct({
            _keyID : keyID,
            _attackStacks : 0,
            _onRoaster : true,
            _onListTimeStamp : block.timestamp+coolDownHrs[2],
            _coolDown : block.timestamp+coolDownHrs[0]
        });
        
        userInfo[_msgSender()]._keyIndex[keyID] = _index;
        keyOwner[keyID] = _msgSender();
    }
    
    function _removeChar( address _owner, uint key, uint _index) private {
        delete userInfo[_owner].roasterInfo[_index];
        delete userInfo[_owner]._keyIndex[key];
        delete keyOwner[key];
        
        Characters.approve(_owner, key);
        Characters.transferFrom(address(this),_owner,key);
    }
    
    function _validateSignature(CombatParams memory combatParams) private {
        require(combatParams.deadline >= block.timestamp, "_validateSignature : deadline expired");
        require(!isSigned[combatParams.signature], "_validateSignature : message already signed");
        address _signer = verify(
            combatParams.player._keyID,
            combatParams.opponent._keyID,
            combatParams.player._owner,
            combatParams.player._finalAccuracy,
            combatParams.skill,
            combatParams.power,
            ++userInfo[_msgSender()].nonces,
            combatParams.deadline,
            combatParams.signature
        );
        require(_signer == _msgSender(), "_validateSignature : invalid signature");
        isSigned[combatParams.signature] = true;
    }
    
    function getRoasterInfo( address _user, uint8 _index) public view returns (RoasterStruct memory) {
        return userInfo[_user].roasterInfo[_index];
    }
    
    function getKeyIndex( address _user, uint _key) public view returns (uint) {
        return userInfo[_user]._keyIndex[_key];
    }
    
    function _chanceOfWining( uint _finalAcc, uint _finalDef) private pure returns (uint _chance) {
        if(_finalAcc > _finalDef) {
            uint numerator = _finalDef+1;
            uint denaminator = 2*(_finalAcc+1);
            _chance = ((numerator*1e18)/denaminator)*100;
        }
        else if(_finalDef > _finalAcc) {
            uint numerator = _finalAcc;
            uint denaminator = 2*(_finalDef+1);
            _chance = ((numerator*1e18)/denaminator)*100;
        }
    }
    
    function _winingReward( uint _winChance, uint power, uint skillValue) private view returns (uint _reward){
       uint[6] memory _var;
       
       _var[0] = skillValue;
       _var[1] = power;
       
       _var[2] = defaultReward*_var[0]/1e2;
       _var[3] = defaultReward*_var[1];
       _var[4] = defaultReward;
       _var[5] = (defaultReward*(1e18+(1e18 - _winChance)))/1e18;
       _reward = masterMultiplier*(_var[4]+_var[2]+_var[3]+_var[5]);
    }
    
    
}