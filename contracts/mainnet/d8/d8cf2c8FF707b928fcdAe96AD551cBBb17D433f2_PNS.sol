pragma solidity ^0.4.24;

/**
 * @title SafeMath from zeppelin-solidity
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title PNS - Physical Form of CryptoCurrency Name System
 * @dev Physical form cryptocurrency name system smart contract is implemented 
 * to manage and record physical form cryptocurrency manufacturers&#39; 
 * informations, such as the name of the manufacturer, the public key 
 * of the key pair whose private key signed the certificate of the physical 
 * form cryptocurrency, etc.
 * 
 * @author Hui Xie - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="066e736f2831323435303f46616b676f6a2865696b">[email&#160;protected]</a>>
 */
contract PNS {

    using SafeMath for uint256; 

    // Event of register
    event Register(address indexed _from, string _mfr, bytes32 _mid);

    // Event of transfer ownership
    event Transfer(address indexed _from, string _mfr, bytes32 _mid, address _owner);

    // Event of push a new batch
    event Push(address indexed _from, string _mfr, bytes32 _mid, string _bn, bytes32 _bid, bytes _key);

    // Event of set batch number
    event SetBn(address indexed _from, string _mfr, bytes32 _mid, string _bn, bytes32 _bid, bytes _key);

    // Event of set public key
    event SetKey(address indexed _from, string _mfr, bytes32 _mid, string _bn, bytes32 _bid, bytes _key);

    // Event of lock a batch
    event Lock(address indexed _from, string _mfr, bytes32 _mid, string _bn, bytes32 _bid, bytes _key);

    // Manufacturer informations
    struct Manufacturer {
        address owner; // owner address
        string mfr; // manufacturer name
        mapping (bytes32 => Batch) batchmapping; // mapping of batch: mapping (batch ID => batch structure)
        mapping (uint256 => bytes32) bidmapping; // mapping of batch ID: mapping (storage index => batch ID), batch ID = keccak256(batch number)
        uint256 bidcounter; // storage index counter of bidmapping
    }

    // Product batch informations
    struct Batch {
        string bn; // batch number
        bytes key; // public key
        bool lock; // is changeable or not
    }

    // Mapping of manufactures: mapping (manufacturer ID => manufacturer struct), Manufacturer ID = keccak256(uppercaseOf(manufacturer name))
    mapping (bytes32 => Manufacturer) internal mfrmapping;

    // Mapping of manufacturer ID: mapping (storage index => manufacturer ID)
    mapping (uint256 => bytes32) internal midmapping;

    // Storage index counter of midmapping
    uint256 internal midcounter;
    
    /**
     * @dev Register a manufacturer.
     * 
     * @param _mfr Manufacturer name
     * @return Manufacturer ID
     */
    function register(string _mfr) public returns (bytes32) {
        require(lengthOf(_mfr) > 0);
        require(msg.sender != address(0));

        bytes32 mid = keccak256(bytes(uppercaseOf(_mfr)));
        require(mfrmapping[mid].owner == address(0));

        midcounter = midcounter.add(1);
        midmapping[midcounter] = mid;

        mfrmapping[mid].owner = msg.sender;
        mfrmapping[mid].mfr = _mfr;
        
        emit Register(msg.sender, _mfr, mid);

        return mid;
    }

    /**
     * @dev Transfer ownership of a manufacturer.
     * 
     * @param _mid Manufacturer ID
     * @param _owner Address of new owner
     * @return Batch ID
     */
    function transfer(bytes32 _mid, address _owner) public returns (bytes32) {
        require(_mid != bytes32(0));
        require(_owner != address(0));

        require(mfrmapping[_mid].owner != address(0));
        require(msg.sender == mfrmapping[_mid].owner);

        mfrmapping[_mid].owner = _owner;

        emit Transfer(msg.sender, mfrmapping[_mid].mfr, _mid, _owner);

        return _mid;
    }
    
    /**
     * @dev Push(add) a batch.
     * 
     * @param _mid Manufacturer ID
     * @param _bn Batch number
     * @param _key Public key
     * @return Batch ID
     */
    function push(bytes32 _mid, string _bn, bytes _key) public returns (bytes32) {
        require(_mid != bytes32(0));
        require(lengthOf(_bn) > 0);
        require(_key.length == 33 || _key.length == 65);

        require(mfrmapping[_mid].owner != address(0));
        require(msg.sender == mfrmapping[_mid].owner);

        bytes32 bid = keccak256(bytes(_bn));
        require(lengthOf(mfrmapping[_mid].batchmapping[bid].bn) == 0);
        require(mfrmapping[_mid].batchmapping[bid].key.length == 0);
        require(mfrmapping[_mid].batchmapping[bid].lock == false);

        mfrmapping[_mid].bidcounter = mfrmapping[_mid].bidcounter.add(1);
        mfrmapping[_mid].bidmapping[mfrmapping[_mid].bidcounter] = bid;
        mfrmapping[_mid].batchmapping[bid].bn = _bn;
        mfrmapping[_mid].batchmapping[bid].key = _key;
        mfrmapping[_mid].batchmapping[bid].lock = false;

        emit Push(msg.sender, mfrmapping[_mid].mfr, _mid, _bn, bid, _key);

        return bid;
    }

    /**
     * @dev Set(change) batch number of an unlocked batch.
     * 
     * @param _mid Manufacturer ID
     * @param _bid Batch ID
     * @param _bn Batch number
     * @return Batch ID
     */
    function setBn(bytes32 _mid, bytes32 _bid, string _bn) public returns (bytes32) {
        require(_mid != bytes32(0));
        require(_bid != bytes32(0));
        require(lengthOf(_bn) > 0);

        require(mfrmapping[_mid].owner != address(0));
        require(msg.sender == mfrmapping[_mid].owner);

        bytes32 bid = keccak256(bytes(_bn));
        require(bid != _bid);
        require(lengthOf(mfrmapping[_mid].batchmapping[_bid].bn) > 0);
        require(mfrmapping[_mid].batchmapping[_bid].key.length > 0);
        require(mfrmapping[_mid].batchmapping[_bid].lock == false);
        require(lengthOf(mfrmapping[_mid].batchmapping[bid].bn) == 0);
        require(mfrmapping[_mid].batchmapping[bid].key.length == 0);
        require(mfrmapping[_mid].batchmapping[bid].lock == false);

        uint256 counter = 0;
        for (uint256 i = 1; i <= mfrmapping[_mid].bidcounter; i++) {
            if (mfrmapping[_mid].bidmapping[i] == _bid) {
                counter = i;
                break;
            }
        }
        require(counter > 0);

        mfrmapping[_mid].bidmapping[counter] = bid;
        mfrmapping[_mid].batchmapping[bid].bn = _bn;
        mfrmapping[_mid].batchmapping[bid].key = mfrmapping[_mid].batchmapping[_bid].key;
        mfrmapping[_mid].batchmapping[bid].lock = false;
        delete mfrmapping[_mid].batchmapping[_bid];

        emit SetBn(msg.sender, mfrmapping[_mid].mfr, _mid, _bn, bid, mfrmapping[_mid].batchmapping[bid].key);

        return bid;
    }

    /**
     * @dev Set(change) public key of an unlocked batch.
     * 
     * @param _mid Manufacturer ID
     * @param _bid Batch ID
     * @param _key Public key
     * @return Batch ID
     */
    function setKey(bytes32 _mid, bytes32 _bid, bytes _key) public returns (bytes32) {
        require(_mid != bytes32(0));
        require(_bid != bytes32(0));
        require(_key.length == 33 || _key.length == 65);

        require(mfrmapping[_mid].owner != address(0));
        require(msg.sender == mfrmapping[_mid].owner);

        require(lengthOf(mfrmapping[_mid].batchmapping[_bid].bn) > 0);
        require(mfrmapping[_mid].batchmapping[_bid].key.length > 0);
        require(mfrmapping[_mid].batchmapping[_bid].lock == false);

        mfrmapping[_mid].batchmapping[_bid].key = _key;

        emit SetKey(msg.sender, mfrmapping[_mid].mfr, _mid, mfrmapping[_mid].batchmapping[_bid].bn, _bid, _key);

        return _bid;
    }

    /**
     * @dev Lock batch. Batch number and public key is unchangeable after it is locked.
     * 
     * @param _mid Manufacturer ID
     * @param _bid Batch ID
     * @return Batch ID
     */
    function lock(bytes32 _mid, bytes32 _bid) public returns (bytes32) {
        require(_mid != bytes32(0));
        require(_bid != bytes32(0));

        require(mfrmapping[_mid].owner != address(0));
        require(msg.sender == mfrmapping[_mid].owner);

        require(lengthOf(mfrmapping[_mid].batchmapping[_bid].bn) > 0);
        require(mfrmapping[_mid].batchmapping[_bid].key.length > 0);

        mfrmapping[_mid].batchmapping[_bid].lock = true;

        emit Lock(msg.sender, mfrmapping[_mid].mfr, _mid, mfrmapping[_mid].batchmapping[_bid].bn, _bid, mfrmapping[_mid].batchmapping[_bid].key);

        return _bid;
    }

    /**
     * @dev Check batch by its batch ID and public key.
     * 
     * @param _mid Manufacturer ID
     * @param _bid Batch ID
     * @param _key Public key
     * @return True or false
     */
    function check(bytes32 _mid, bytes32 _bid, bytes _key) public view returns (bool) {
        if (mfrmapping[_mid].batchmapping[_bid].key.length != _key.length) {
            return false;
        }
        for (uint256 i = 0; i < _key.length; i++) {
            if (mfrmapping[_mid].batchmapping[_bid].key[i] != _key[i]) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Get total number of manufacturers.
     * 
     * @return Total number of manufacturers
     */
    function totalMfr() public view returns (uint256) {
        return midcounter;
    }

    /**
     * @dev Get manufacturer ID.
     * 
     * @param _midcounter Storage index counter of midmapping
     * @return Manufacturer ID
     */
    function midOf(uint256 _midcounter) public view returns (bytes32) {
        return midmapping[_midcounter];
    }

    /**
     * @dev Get manufacturer owner.
     * 
     * @param _mid Manufacturer ID
     * @return Manufacturer owner
     */
    function ownerOf(bytes32 _mid) public view returns (address) {
        return mfrmapping[_mid].owner;
    }
    
    /**
     * @dev Get manufacturer name.
     * 
     * @param _mid Manufacturer ID
     * @return Manufacturer name (Uppercase)
     */
    function mfrOf(bytes32 _mid) public view returns (string) {
        return mfrmapping[_mid].mfr;
    }
    
    /**
     * @dev Get total batch number of a manufacturer.
     * 
     * @param _mid Manufacturer ID
     * @return Total batch number
     */
    function totalBatchOf(bytes32 _mid) public view returns (uint256) {
        return mfrmapping[_mid].bidcounter;
    }

    /**
     * @dev Get batch ID.
     * 
     * @param _mid Manufacturer ID
     * @param _bidcounter Storage index counter of bidmapping
     * @return Batch ID
     */
    function bidOf(bytes32 _mid, uint256 _bidcounter) public view returns (bytes32) {
        return mfrmapping[_mid].bidmapping[_bidcounter];
    }

    /**
     * @dev Get batch number.
     * 
     * @param _mid Manufacturer ID
     * @param _bid Batch ID
     * @return Batch number
     */
    function bnOf(bytes32 _mid, bytes32 _bid) public view returns (string) {
        return mfrmapping[_mid].batchmapping[_bid].bn;
    }
    
    /**
     * @dev Get batch public key.
     * 
     * @param _mid Manufacturer ID
     * @param _bid Batch ID
     * @return bytes Batch public key
     */
    function keyOf(bytes32 _mid, bytes32 _bid) public view returns (bytes) {
        if (mfrmapping[_mid].batchmapping[_bid].lock == true) {
            return mfrmapping[_mid].batchmapping[_bid].key;
        }
    }

    /**
     * @dev Convert string to uppercase.
     * 
     * @param _s String to convert
     * @return Converted string
     */
    function uppercaseOf(string _s) internal pure returns (string) {
        bytes memory b1 = bytes(_s);
        uint256 l = b1.length;
        bytes memory b2 = new bytes(l);
        for (uint256 i = 0; i < l; i++) {
            if (b1[i] >= 0x61 && b1[i] <= 0x7A) {
                b2[i] = bytes1(uint8(b1[i]) - 32);
            } else {
                b2[i] = b1[i];
            }
        }
        return string(b2);
    }

    /**
     * @dev Get string length.
     * 
     * @param _s String
     * @return length
     */
    function lengthOf(string _s) internal pure returns (uint256) {
        return bytes(_s).length;
    }
}