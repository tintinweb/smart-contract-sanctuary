/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity 0.5.17;

/***************
**            **
** INTERFACES **
**            **
***************/

/**
 * @title  Interface for Kong ERC20 Token Contract.
 */
interface KongERC20Interface {

  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function mint(uint256 mintedAmount, address recipient) external;
  function getMintingLimit() external returns(uint256);

}

/**
 * @title Interface for EllipticCurve contract.
 */
interface EllipticCurveInterface {

    function validateSignature(bytes32 message, uint[2] calldata rs, uint[2] calldata Q) external view returns (bool);

}

/****************************
**                         **
** OPEN ZEPPELIN CONTRACTS **
**                         **
****************************/

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

/**********************************
**                               **
**   REGISTER MERKLE CONTRACT    **
**                               **
**********************************/

/**
 * @title Register Contract.
 */
contract RegisterMerkleRoot {
  using SafeMath for uint256;

  // Account with the right to adjust the set of minters.
  address public _owner;

  // Address of the Kong ERC20 account.
  address public _kongERC20Address;

  // Address of future registry.
  address public _upgradeContract;

  // Sum of Kong amounts marked as mintable for registered devices.
  uint256 public _totalMintable;

  // Minters.
  mapping (address => bool) public _minters;

  // Minting caps.
  mapping (address => uint256) public _mintingCaps;

  // Minted device.
  struct Device {
    uint256 kongAmount;
    address contractAddress;
  }

  // Minted devices.
  mapping(bytes32 => Device) internal _devices;

  // Signers.
  mapping(address => bool) public _signers;

  struct DeviceRoot {
    bytes32 deviceRoot;
    uint256 deviceKongAmount;
    uint256 totalDevices;
    uint256 totalMintableKong;   
    uint256 mintableTime;
    string  ipfsCid;
    string  arwId;
    uint256 rootTimestamp;
    uint256 rootIndex;
  }

  mapping(bytes32 => DeviceRoot) internal _deviceRoots;

  uint256 public _deviceRootCount;

  struct DeviceRootIndex {
    bytes32 deviceRoot;
  }


  mapping(uint256 => DeviceRootIndex) internal _deviceRootIndices;

  /**
   * @dev Emit when a device merkle root is added.
   */
  event RootAddition(
    bytes32 deviceRoot,
    uint256 deviceKongAmount,
    uint256 totalDevices,
    uint256 totalMintableKong,    
    uint256 mintableTime,
    string  ipfsCid,
    string  arwId,
    uint256 rootTimestamp,
    uint256 rootIndex
  );


  event MintKong(
    bytes32 hardwareHash,
    uint256 kongAmount
  );

  /**
   * @dev Emit when minting rights are delegated / removed.
   */
  event MinterAddition (
    address minter,
    uint256 mintingCap
  );

  event MinterRemoval (
    address minter
  );

  /**
   * @dev Emit when contract reference added to a device.
   */
  event AddressAdded (
    bytes32 hardwareHash,
    address contractAddress
  );

  /**
   * @dev Emit when contract reference added to a device.
   */
  event UpgradeAddressAdded (
    address upgradeAddress
  );


  /**
   * @dev Emit when signers are added / removed.
   */
  event SignerAddition (
    address signer
  );

  event SignerRemoval (
    address signer
  );  

  /**
   * @dev Constructor.
   */
  constructor(address owner, address kongAddress) public {

    // Set address of owner.
    _owner = owner;

    // Set address of Kong ERC20 contract.
    _kongERC20Address = kongAddress;

    // Set minting cap of owner account.
    _mintingCaps[_owner] = (2 ** 25 + 2 ** 24 + 2 ** 23 + 2 ** 22) * 10 ** 18;

  }

  /**
   * @dev Throws if called by any account but owner.
   */
  modifier onlyOwner() {
    require(_owner == msg.sender, 'Can only be called by owner.');
    _;
  }

  /**
   * @dev Throws if called by any account but owner or registered minter.
   */
  modifier onlyOwnerOrMinter() {
    require(_owner == msg.sender || _minters[msg.sender] == true, 'Can only be called by owner or minter.');
    _;
  }

  /**
   * @dev Throws if called by any account but owner or registered signer.
   */
  modifier onlyOwnerOrSigner() {
    require(_owner == msg.sender || _signers[msg.sender] == true, 'Can only be called by owner or signer.');
    _;
  }

  /**
   * @dev Throws if called by any account but registered signer.
   */
  // modifier onlySigner() {
  //   require(_signers[msg.sender] == true, 'Can only be called by signer.');
  //   _;
  // }

  /**
   * @dev Endow `newMinter` with right to add mintable devices up to `mintingCap`.
   */
  function delegateMintingRights(
    address newMinter,
    uint256 mintingCap
  )
    public
    onlyOwner
  {
    // Delegate minting rights.
    _mintingCaps[_owner] = _mintingCaps[_owner].sub(mintingCap);
    _mintingCaps[newMinter] = _mintingCaps[newMinter].add(mintingCap);

    // Add newMinter to dictionary of minters.
    _minters[newMinter] = true;

    // Emit event.
    emit MinterAddition(newMinter, _mintingCaps[newMinter]);
  }

  /**
   * @dev Remove address from the mapping of _minters.
   */
  function removeMintingRights(
    address minter
  )
    public
    onlyOwner
  {
    // Cannot remove rights from _owner.
    require(_owner != minter, 'Cannot remove owner from minters.');

    // Adjust minting rights.
    _mintingCaps[_owner] = _mintingCaps[_owner].add(_mintingCaps[minter]);
    _mintingCaps[minter] = 0;

    // Deactivate minter.
    _minters[minter] = false;

    // Emit event.
    emit MinterRemoval(minter);
  }

  /**
   * @dev Add a new signer contract which can carry out specific tasks.
   */
  function addSigner(
    address newSigner
  )
    public
    onlyOwner
  {
    // Add newSigner to dictionary of signers.
    _signers[newSigner] = true;

    // Emit event.
    emit SignerAddition(newSigner);
  }

  /**
   * @dev Add a new signer contract which can carry out specific tasks.
   */
  function removeSigner(
    address signer
  )
    public
    onlyOwner
  {
    // Add newSigner to dictionary of signers.
    _signers[signer] = false;

    // Emit event.
    emit SignerRemoval(signer);
  }

  /**
   * @dev Add upgrade contract address.
   */
  function addUpgradeAddress(
    address upgradeAddress
  )
    public
    onlyOwner
  {
    // Add upgrade address.
    _upgradeContract = upgradeAddress;

    // Emit event.
    emit UpgradeAddressAdded(upgradeAddress);
  }

  /**
   * @dev Add a new device merkle root.
   */
  function addRoot(
    bytes32 deviceRootHash,
    bytes32 deviceRoot,
    uint256 deviceKongAmount,
    uint256 totalDevices,
    uint256 totalMintableKong,
    uint256 mintableTime,    
    string memory ipfsCid,
    string memory arwId
  )
    public
    onlyOwnerOrMinter
  {
    // Hash the device root which is the key to the mapping.
    bytes32 calculatedRootHash = sha256(abi.encodePacked(deviceRoot));

    require(deviceRootHash == calculatedRootHash, 'Invalid root hash.');

    // Verify that this root has not been registered yet.
    require(_deviceRoots[deviceRootHash].deviceRoot == 0, 'Already registered.');

    // Verify the cumulative limit for mintable Kong has not been exceeded. We can also register devices that are not Kong mintable.
    if (totalMintableKong > 0 && deviceKongAmount > 0) {

      require(totalMintableKong == deviceKongAmount * totalDevices, 'Incorrect Kong per device.');

      uint256 _maxMinted = KongERC20Interface(_kongERC20Address).getMintingLimit();
      require(_totalMintable.add(totalMintableKong) <= _maxMinted, 'Exceeds cumulative limit.');

      // Increment _totalMintable.
      _totalMintable += totalMintableKong;

      // Adjust minting cap. Throws on underflow / Guarantees minter does not exceed its limit.
      _mintingCaps[msg.sender] = _mintingCaps[msg.sender].sub(totalMintableKong);
    }

    // Increment the device root count.
    _deviceRootCount++;

    // Set rootCount.
    uint256 rootIndex = _deviceRootCount;

    // Set timestamp for when we added this root.
    uint256 rootTimestamp = block.timestamp;

    // Create device struct.
    _deviceRoots[deviceRootHash] = DeviceRoot(
      deviceRoot,
      deviceKongAmount,
      totalDevices,
      totalMintableKong,
      mintableTime,    
      ipfsCid,
      arwId,
      rootTimestamp,
      rootIndex
    );

     // Create device index struct.
    _deviceRootIndices[rootIndex] = DeviceRootIndex(
      deviceRoot
    );   

    emit RootAddition(
      deviceRoot,
      deviceKongAmount,
      totalDevices,
      totalMintableKong,    
      mintableTime,
      ipfsCid,
      arwId,
      rootTimestamp,
      rootIndex
    );
  }  

  /**
   * @dev Mint root Kong amount to `recipient`.
   */
  function mintKong(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32 hardwareHash,
    address recipient
  )
    external
    onlyOwnerOrMinter
  {
    // Hash the device root which is the key to the mapping.
    bytes32 rootHash = sha256(abi.encodePacked(root));

    // Get associated device root.
    DeviceRoot memory r = _deviceRoots[rootHash];

    require(r.deviceRoot == root, 'Invalid root.');

    // Make sure proof time is mintable
    require(block.timestamp >= r.mintableTime, 'Cannot mint yet.');

    // Verify device is in proof.
    require(verifyProof(proof, r.deviceRoot, hardwareHash, r.deviceKongAmount), 'Device not found in root.');

    // Check minter contract to see if device is minted.
    require(_devices[hardwareHash].kongAmount == 0, 'Already minted.');

    // Set value of Kong amount, implicitly indicating minted.
    _devices[hardwareHash].kongAmount = r.deviceKongAmount;

    // Get associated device root to store changes.
    DeviceRoot storage s = _deviceRoots[rootHash];

    // Decrement totalMintableKong and devices.
    s.totalMintableKong = s.totalMintableKong.sub(r.deviceKongAmount);
    s.totalDevices = s.totalDevices.sub(1);

    // Mint.
    KongERC20Interface(_kongERC20Address).mint(r.deviceKongAmount, recipient);

    emit MintKong(
      hardwareHash,
      r.deviceKongAmount
    );   
  }

  /**
   * @dev Associate a smart contract address with the device.
   */
  function addAddress(
    bytes32 primaryPublicKeyHash,
    bytes32 secondaryPublicKeyHash,
    bytes32 tertiaryPublicKeyHash,    
    bytes32 hardwareSerial,
    address contractAddress
  )
    external
    onlyOwnerOrSigner
  {
    // Hash all the keys in order to calculate the hardwareHash.
    bytes32 hardwareHash = sha256(abi.encodePacked(primaryPublicKeyHash, secondaryPublicKeyHash, tertiaryPublicKeyHash, hardwareSerial));    
    
    require(_devices[hardwareHash].contractAddress == address(0), 'Already has address.');

    _devices[hardwareHash].contractAddress = contractAddress;

    emit AddressAdded(
      hardwareHash,
      contractAddress
    );    
  }

  function isDeviceMintable(
    bytes32 hardwareHash
  )
    public
    view
    returns (bool)
  {
    require(_devices[hardwareHash].kongAmount == 0, 'Device already minted.');

    return true;
  }

  function getDeviceAddress(
    bytes32 hardwareHash
  )
    external
    view
    returns (address)
  {
    return _devices[hardwareHash].contractAddress;
  } 

  function verifyRoot(bytes32 root
  )
    public
    view
    returns (bytes32)
  {
    // Hash the device root which is the key to the mapping.
    bytes32 rootHash = sha256(abi.encodePacked(root));

    // Get associated device root.
    DeviceRoot memory r = _deviceRoots[rootHash];

    return r.deviceRoot;   
  } 

  function verifyProof(
    bytes32[] memory proof, 
    bytes32 root, 
    bytes32 hardwareHash, 
    uint256 kongAmount
  )
    public
    view
    returns (bool)
  {
    // Hash the device root which is the key to the mapping.
    bytes32 rootHash = sha256(abi.encodePacked(root));

    // Get associated device root.
    DeviceRoot memory r = _deviceRoots[rootHash];

    require(r.deviceRoot == root, 'Invalid root.');    

    bytes32 encodeLeaf = keccak256(abi.encodePacked(hardwareHash));

    require(r.deviceKongAmount == kongAmount, 'Invalid Kong amount.');

    return MerkleProof.verify(proof, r.deviceRoot, encodeLeaf);
  }

  /**
   * @dev Return root registration information.
   */
  function getRootDetails(
    bytes32 root
  )
    external
    view
    returns (uint256, uint256, uint256, uint256, string memory, string memory, uint256, uint256)
  {
    // Hash the device root which is the key to the mapping.
    bytes32 rootHash = sha256(abi.encodePacked(root));

    // Get associated device root.
    DeviceRoot memory r = _deviceRoots[rootHash];

    return (
      r.deviceKongAmount,
      r.totalDevices,
      r.totalMintableKong,
      r.mintableTime,
      r.ipfsCid,
      r.arwId,
      r.rootTimestamp,
      r.rootIndex
    );
  }

  /**
   * @dev Return root registration information.
   */
  function getRootByIndex(
    uint256 rootIndex
  )
    external
    view
    returns (bytes32)
  {
    // Get associated device root.
    DeviceRootIndex memory i = _deviceRootIndices[rootIndex];

    return (
      i.deviceRoot
    );  
  }  
}