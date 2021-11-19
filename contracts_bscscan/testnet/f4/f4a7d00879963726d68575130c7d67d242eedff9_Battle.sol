/**
 *Submitted for verification at BscScan.com on 2021-11-18
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

interface IDefPaceCharacters {
    function characterInfo( uint _key) external view returns (address _owner,string memory _characterName,uint8 _level,uint _skill,uint _baseAccuracy,uint _power,uint _skillValue);
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
    
    function verify(address _owner, uint _keyID, uint _oppoKey, uint _nonces, uint _deadline, bytes memory signature) public view returns (address){
      // This recreates the message hash that was signed on the client.
      bytes32 hash = keccak256(abi.encodePacked(SIGNATURE_PERMIT_TYPEHASH, _owner, _keyID, _oppoKey, chainId, _nonces, _deadline));
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
    
    IERC20 public Defpace;
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
    uint[3] public coolDownHrs = [3 hours, 7 days, 24 hours];
    uint public masterMultiplier;
    uint public defaultReward;
    uint[2] public taxLimit = [2000 /* tax */, type(uint256).max /* tax limit */]; // 2000 = 20%
    
    mapping(address => UserInfoStruct) public userInfo;
    mapping(uint => address) public keyOwner;
    mapping(bytes => bool)  public isSigned;
    mapping(address => bool) public blackList;
    
    constructor( address _masterAdmin, address _DefPaceCharacter, IERC20 _defpace, uint _masterMultiplier, uint _defaultReward) Pausable( _masterAdmin) {
        Characters = IERC721(_DefPaceCharacter);
        Defpace = _defpace;
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
        require((_index <= userInfo[_msgSender()]._charIndexRoaster) && (_index > 0));
        require(userInfo[_msgSender()].roasterInfo[_index]._onListTimeStamp < block.timestamp, "characters can only removed after 24 hrs from added time");
        
        if(blackList[_msgSender()]) require(keyID == 0, "Blacklist user can only remove character if exist");
        
        uint _oldKeyId = userInfo[_msgSender()].roasterInfo[_index]._keyID;
        require(userInfo[_msgSender()].roasterInfo[_oldKeyId]._coolDown < block.timestamp, "cannot swap token on the cool down period");
        
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
    
    struct CombatParams {
        uint _index;
        address _owner;
        uint _finalAccuracy;
    }
    
    function combat(uint _keyID, uint _oppKeyID, uint _deadline, bytes memory signature) external _isBlackList {
        CombatParams memory _charCombatParams ;
        CombatParams memory _oppCombatParams;
        
        (_charCombatParams._index, _charCombatParams._owner) = (userInfo[_msgSender()]._keyIndex[_keyID], keyOwner[_keyID]);
        (_oppCombatParams._index, _oppCombatParams._owner) = (userInfo[keyOwner[_oppKeyID]]._keyIndex[_oppKeyID], keyOwner[_oppKeyID]);
        
        require(userInfo[_charCombatParams._owner]._charIndexRoaster > 0, "there must be atleast one character in the roaster");
        require(_charCombatParams._owner == _msgSender(), "Is not a owner or the character may removed");
        require(_oppCombatParams._owner != address(0), "Opponent character may removed from the roaster");
        
        _validateSignature( 
            _keyID,
            _oppKeyID,
            _deadline,
            signature
        );
        
        require(_charCombatParams._owner != _oppCombatParams._owner, "Opponent must not be owner of character");
        require(userInfo[_charCombatParams._owner].roasterInfo[_charCombatParams._index]._onRoaster, "Character is not on the roaster");
        require(userInfo[_charCombatParams._owner].roasterInfo[_keyID]._coolDown != 0, "Character should go on the cooldown period to participate in combat");
        require(userInfo[_charCombatParams._owner].roasterInfo[_keyID]._coolDown < block.timestamp, "Character should wait till combat period ends");
        
        (,,uint8 level,,uint baseAccuracy,,) = IDefPaceCharacters(address(Characters)).characterInfo(_keyID);
        (,,uint8 levelOpp,,uint baseAccuracyOpp,,) = IDefPaceCharacters(address(Characters)).characterInfo(_oppKeyID);
        
        _charCombatParams._finalAccuracy = baseAccuracy*level;
        _oppCombatParams._finalAccuracy = baseAccuracyOpp*levelOpp;
        
        require((_charCombatParams._finalAccuracy > 0) && (_oppCombatParams._finalAccuracy > 0), "combat :: _finalAccuracy must be greater than zero");
        
        uint _chanceOfWin = _chanceOfWining( _charCombatParams._finalAccuracy, _oppCombatParams._finalAccuracy);
        
        if(_chanceOfWin == 0) return;
        
        uint _reward = _winingReward(_charCombatParams._owner, _charCombatParams._index, _chanceOfWin*1e18/100e18);
        
        userInfo[_msgSender()]._avlClaimAmt += _reward;
        userInfo[_charCombatParams._owner].roasterInfo[_charCombatParams._index]._attackStacks++;
        userInfo[_charCombatParams._owner].roasterInfo[_keyID]._coolDown = block.timestamp+coolDownHrs[0];
        
        if(userInfo[_charCombatParams._owner].roasterInfo[_charCombatParams._index]._attackStacks == 2){
            userInfo[_charCombatParams._owner].roasterInfo[_keyID]._coolDown = 0;
            userInfo[_charCombatParams._owner].roasterInfo[_charCombatParams._index]._onRoaster = false;
        }
        
        emit Combat (
            _keyID,
            _oppKeyID,
            _charCombatParams._owner,
            _oppCombatParams._owner,
            _chanceOfWin,
            _reward
        );
        
    }
    
    function claim() external _isBlackList {
        require(userInfo[_msgSender()]._avlClaimAmt > 0);
        
        uint[3] memory _amount;
        _amount[0] = userInfo[_msgSender()]._avlClaimAmt;
        userInfo[_msgSender()]._avlClaimAmt = 0;
        
        userInfo[_msgSender()]._lastClaim = block.timestamp;
        
        if((userInfo[_msgSender()]._lastClaim+coolDownHrs[1]) < block.timestamp) {
            require(userInfo[_msgSender()]._taxableLimit < taxLimit[1]);
            userInfo[_msgSender()]._taxableLimit++;
            _amount[1] = _amount[0]*taxLimit[0]/10**4;
            _amount[2] = _amount[0] - _amount[1];
        } else {
            _amount[1] = _amount[0];
            userInfo[_msgSender()]._avlClaimAmt = 0;
        }
        
        if(_amount[2] > 0) Defpace.transfer(taxAddr, _amount[2]);
        
        Defpace.transfer(_msgSender(), _amount[1]);
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
        require(Defpace.balanceOf( address(this)) > _amount);
        Defpace.transfer(owner(), _amount);
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
    
    function _validateSignature( uint _keyID, uint _oppoKey, uint _deadline, bytes memory signature) private {
        require(_deadline >= block.timestamp, 'DefPaceCharacters :: createCharacterBatch : deadline expired');
        require(!isSigned[signature], "DefPaceCharacters :: createCharacterWithURl : message already signed");
        address _signer = verify( _msgSender(), _keyID, _oppoKey, ++userInfo[_msgSender()].nonces, _deadline, signature);
        require(_signer == _msgSender(), "DefPaceCharacters :: _validateSignature : invalid signature");
        
        isSigned[signature] = true;
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
    
    function _winingReward(address _owner, uint _index, uint _winChance) private view returns (uint _reward){
       uint[6] memory _var;
       
        (,,,,,uint power,uint skillValue) = IDefPaceCharacters(address(Characters)).characterInfo(userInfo[_owner].roasterInfo[_index]._keyID);
       
       _var[0] = skillValue;
       _var[1] = power;
       
       _var[2] = defaultReward*_var[0]/1e2;
       _var[3] = defaultReward*_var[1];
       _var[4] = defaultReward;
       _var[5] = (defaultReward*(1e18+(1e18 - _winChance)))/1e18;
       _reward = masterMultiplier*(_var[4]+_var[2]+_var[3]+_var[5]);
    }
    
    
}