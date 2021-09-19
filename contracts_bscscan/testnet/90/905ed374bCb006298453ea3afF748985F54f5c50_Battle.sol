/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

pragma solidity 0.7.6;
//SPDX-License-Identifier: UNLICENSED

interface IERC721 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
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
    bytes32 public constant SIGNATURE_PERMIT_TYPEHASH = keccak256("verify(address _receiver, uint _characterName, uint _level, uint _rarity, uint _baseAccuracy, uint _power, uint _nonces, uint _deadline, bytes memory signature)");
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
        uint _roasterIndex,
        uint _addedOn
    );
    
    event CoolDown (
        address _player,
        uint _keyID,
        uint _index,
        uint _coolDownTime
    );
    
    event swapCharRoaster (
        uint _index,
        address oldOwner,
        uint oldKeyID,
        address _addBy,
        uint _keyID,
        uint _roasterIndex,
        uint _addedOn
    );
    
    event Combat (
        uint _charKey,
        uint _oppoCharKey,
        address _charOwner,
        address _oppoCharOwner,
        uint _chanceOfWin,
        uint _reward,
        uint _battleTime
    );
    
    event revertCharacters (
        uint _charKey,
        uint _index,
        address _owner,
        uint _revertTime
    );
    
    IDefPaceCharacters public DefPaceCharacter;
    IERC20 public Defpace;
    IERC721 public Characters;
    
    struct RoasterStruct { // Roaster Info
        uint _keyID;
        string _characterName;
        uint8 _level;
        uint _skillRarity;
        uint _accuracy;
        uint _power;
        uint8 _attackStacks;
        uint _finalAccuracy;
        uint _skillMultiplier;
        bool _onRoaster;
        uint _onListTimeStamp;
    }
    
    struct EnemyStruct { // Enemy Info
        string _enemyName;
        uint8 _level;
        uint _defence;
        uint _finalDefence;
    }
    
    struct UserInfoStruct { // User Info
        uint8 _charIndexRoaster;
        uint _totalCombat;
        uint _lastCombatTimestamp;   
        uint nonces;
    }
    
    struct KeyInfo {
        uint _index;
        address _owner;
    }
    
    uint totalCombat;
    uint totalRoasters;
    uint maxCharInRoaster = 10;
    uint minCharInRoaster = 1;
    uint coolDownHrs = 3 hours;
    uint masterMultiplier;
    uint defaultReward;
    
    mapping(address => mapping(uint => RoasterStruct)) public userRoaster;
    mapping(address => UserInfoStruct) public userInfo;
    mapping(address => mapping(uint => uint)) public _coolDown;
    mapping(uint => KeyInfo) keyInfo;
    mapping(bytes => bool) public isSigned;
    
    constructor( address _masterAdmin, address _DefPaceCharacter, IERC20 _defpace, uint _masterMultiplier, uint _defaultReward) Pausable( _masterAdmin) {
        DefPaceCharacter = IDefPaceCharacters(_DefPaceCharacter);
        Characters = IERC721(_DefPaceCharacter);
        Defpace = _defpace;
        masterMultiplier = _masterMultiplier;
        defaultReward = _defaultReward;
    }
    
    function addCharToRoaster( uint keyID, bool coolDown) external {
        require(userInfo[_msgSender()]._charIndexRoaster < maxCharInRoaster, "addCharToRoaster : only 10 characters must be in the roaster");
        
        uint8 _index = ++userInfo[_msgSender()]._charIndexRoaster;
        (,string memory characterName,uint8 level,uint skill,uint baseAccuracy,uint power,uint skillValue) = DefPaceCharacter.characterInfo(keyID);
    
        Characters.transferFrom(_msgSender(),address(this),keyID);
    
        userRoaster[_msgSender()][_index] = RoasterStruct({
            _keyID : keyID,
            _characterName : characterName,
            _level : level,
            _skillRarity : skill,
            _accuracy : baseAccuracy,
            _power : power,
            _attackStacks : 0,
            _finalAccuracy : baseAccuracy*level,
            _skillMultiplier : skillValue,
            _onRoaster : true,
            _onListTimeStamp : block.timestamp
        });
        
        keyInfo[keyID] = KeyInfo(_index, _msgSender());
        
        if(coolDown) _coolDown[_msgSender()][keyID] = block.timestamp+coolDownHrs;
        
        emit AddCharRoaster (
            _msgSender(),
            keyID,
            _index,
            block.timestamp
        );
    }
    
    function startPrepration() external {
        require(userInfo[_msgSender()]._charIndexRoaster > 0);
        
        for(uint8 i=1; i<=userInfo[_msgSender()]._charIndexRoaster; i++) {
            uint keyID = userRoaster[_msgSender()][i]._keyID; 
            
            if(!userRoaster[_msgSender()][i]._onRoaster) continue;
            
            if((_coolDown[_msgSender()][keyID] == 0) && (userRoaster[_msgSender()][i]._attackStacks != 0)) {
                revert("Characters on roaster must be on the cool down period before first stack");
            }
            
            if((_coolDown[_msgSender()][keyID] != 0) && (userRoaster[_msgSender()][i]._attackStacks == 0)) // character already in cool down period
                continue;
            
            _coolDown[_msgSender()][keyID] = block.timestamp+coolDownHrs;
            
            emit CoolDown (
                _msgSender(),
                keyID,
                i,
                _coolDown[_msgSender()][keyID]
            );
        }
    }
    
    function swapCharacter( uint keyID, uint _index, bool coolDown) external {
        require((_index <= userInfo[_msgSender()]._charIndexRoaster) && (_index > 0));
        
        uint _oldKeyId = userRoaster[_msgSender()][_index]._keyID;

        delete userRoaster[_msgSender()][_index];

        if(keyID > 0) {
            Characters.transferFrom(_msgSender(),address(this),keyID);
            
            (,string memory characterName,uint8 level,uint skill,uint baseAccuracy,uint power,uint skillValue) = DefPaceCharacter.characterInfo(keyID);
            userRoaster[_msgSender()][_index] = RoasterStruct({
                _keyID : keyID,
                _characterName : characterName,
                _level : level,
                _skillRarity : skill,
                _accuracy : baseAccuracy,
                _power : power,
                _attackStacks : 0,
                _finalAccuracy : baseAccuracy*level,
                _skillMultiplier : skillValue,
                _onRoaster : true,
                _onListTimeStamp : block.timestamp
            });
            
            
        }
        else{
            _swappingCharacters(_msgSender(), _index,userInfo[_msgSender()]._charIndexRoaster);    
        }
        
        address _oldMsgSender = keyInfo[_oldKeyId]._owner;
        
        require(_oldMsgSender != address(0));
        require((_coolDown[_oldMsgSender][_oldKeyId]) == 0 || (_coolDown[_oldMsgSender][_oldKeyId] > block.timestamp));
        
        Characters.approve(_oldMsgSender, _oldKeyId);
        Characters.transferFrom(address(this),_oldMsgSender,_oldKeyId);
        
        keyInfo[_oldKeyId] = KeyInfo(0,address(0));
        _coolDown[_oldMsgSender][_oldKeyId] = 0;
        
        if(keyID > 0) {
            if(coolDown) { _coolDown[_msgSender()][keyID] = block.timestamp+coolDownHrs; }
            keyInfo[keyID] = KeyInfo(_index, _msgSender());
        }
        
        emit swapCharRoaster (
            _index,
            _oldMsgSender,
            _oldKeyId,
            _msgSender(),
            keyID,
            _index,
            block.timestamp
        );
    }
    
    function _swappingCharacters( address _owner, uint _fromIndex, uint8 _toIndex) private {
        for(uint i=_fromIndex; i<_toIndex; i++) {
            userRoaster[_owner][i] = userRoaster[_owner][i+1];
            keyInfo[userRoaster[_owner][i]._keyID]._index = i;
        }
        
        delete userRoaster[_owner][_toIndex];
        userInfo[_owner]._charIndexRoaster--;
    }
    
    struct CombatParams {
        uint _index;
        address _owner;
        uint _finalAccuracy;
    }
    
    function combat(uint _keyID, uint _oppKeyID, uint _deadline, bytes memory signature) external {
        CombatParams memory _charCombatParams ;
        CombatParams memory _oppCombatParams;
        
        (_charCombatParams._index, _charCombatParams._owner) = (keyInfo[_keyID]._index,keyInfo[_keyID]._owner);
        (_oppCombatParams._index, _oppCombatParams._owner) = (keyInfo[_oppKeyID]._index,keyInfo[_oppKeyID]._owner);
        
        require(userRoaster[_charCombatParams._owner][_charCombatParams._index]._keyID >= minCharInRoaster, "there must be atleast one character in the roaster");
        require(_charCombatParams._owner == _msgSender(), "Is not a owner or the character may removed");
        require(_oppCombatParams._owner != address(0), "Opponent character may removed from the roaster");
        
        _validateSignature( 
            _keyID,
            _oppKeyID,
            _deadline,
            signature
        );
        
        require(_charCombatParams._owner != _oppCombatParams._owner, "Opponent must not be owner of character");
        require(userRoaster[_charCombatParams._owner][_charCombatParams._index]._onRoaster, "Character is not on the roaster");
        require(_coolDown[_charCombatParams._owner][_keyID] != 0, "Character should go on the cooldown period to participate in combat");
        require(_coolDown[_charCombatParams._owner][_keyID] < block.timestamp, "Character should wait till combat period ends");
        
        _charCombatParams._finalAccuracy = userRoaster[_charCombatParams._owner][_charCombatParams._index]._finalAccuracy;
        _oppCombatParams._finalAccuracy = userRoaster[_oppCombatParams._owner][_oppCombatParams._index]._finalAccuracy;
        
        require((_charCombatParams._finalAccuracy > 0) && (_oppCombatParams._finalAccuracy > 0), "combat :: _finalAccuracy must be greater than zero");
        
        uint _chanceOfWin = _chanceOfWining( _charCombatParams._finalAccuracy, _oppCombatParams._finalAccuracy);
        
        if(_chanceOfWin == 0) return;
        
        uint _reward = _winingReward(_charCombatParams._owner, _charCombatParams._index, _chanceOfWin*1e18/100e18);
        
        Defpace.transfer(_msgSender(), _reward);
        userRoaster[_charCombatParams._owner][_charCombatParams._index]._attackStacks++;
        _coolDown[_charCombatParams._owner][_keyID] = block.timestamp+coolDownHrs;
        
        if(userRoaster[_charCombatParams._owner][_charCombatParams._index]._attackStacks == 2){
            _coolDown[_charCombatParams._owner][_keyID] = 0;
            userRoaster[_charCombatParams._owner][_charCombatParams._index]._onRoaster = false;
        }
        
        userInfo[_msgSender()]._totalCombat++;
        userInfo[_msgSender()]._lastCombatTimestamp = block.timestamp;
        
        emit Combat (
            _keyID,
            _oppKeyID,
            _charCombatParams._owner,
            _oppCombatParams._owner,
            _chanceOfWin,
            _reward,
            block.timestamp
        );
        
    }
    
    function revertCharacter(uint _keyID) external onlyOwner { // in case of any failure.
        uint _index = keyInfo[_keyID]._index;
        address _owner = keyInfo[_keyID]._owner;
        
        require(_owner != address(0) && (_index != 0), "Character already removed from the roaster");
        
        delete userRoaster[_msgSender()][_index];
        
        keyInfo[_keyID] = KeyInfo(0,address(0));
        _coolDown[_owner][_keyID] = 0;
        
        Characters.approve(_owner, _keyID);
        Characters.transferFrom(address(this),_owner,_keyID);
        
        emit revertCharacters (
            _keyID,
            _index,
            _owner,
            block.timestamp
        );
    }
    
    function setMasterMultiplier( uint _masterMultiplier) external onlyOwner {
        masterMultiplier = _masterMultiplier;
    }
    
    function setDefaultReward( uint _defaultReward) external onlyOwner {
        defaultReward = _defaultReward;
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
       
       _var[0] = userRoaster[_owner][_index]._skillMultiplier;
       _var[1] = userRoaster[_owner][_index]._power;
       
       _var[2] = defaultReward*_var[0]/1e2;
       _var[3] = defaultReward*_var[1];
       _var[4] = defaultReward;
       _var[5] = (defaultReward*(1e18+(1e18 - _winChance)))/1e18;
       _reward = masterMultiplier*(_var[4]+_var[2]+_var[3]+_var[5]);
    }
    
    function _validateSignature( uint _keyID, uint _oppoKey, uint _deadline, bytes memory signature) private {
        require(_deadline >= block.timestamp, 'DefPaceCharacters :: createCharacterBatch : deadline expired');
        require(!isSigned[signature], "DefPaceCharacters :: createCharacterWithURl : message already signed");
        address _signer = verify( _msgSender(), _keyID, _oppoKey, ++userInfo[_msgSender()].nonces, _deadline, signature);
        require(_signer == _msgSender(), "DefPaceCharacters :: _validateSignature : invalid signature");
        
        isSigned[signature] = true;
    }
    
}