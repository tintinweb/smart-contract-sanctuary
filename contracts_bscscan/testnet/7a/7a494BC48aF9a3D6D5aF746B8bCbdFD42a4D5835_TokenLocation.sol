/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-06-04
*/

// Verified by Darwinia Network

// hevm: flattened sources of contracts/TokenLocation.sol

pragma solidity >=0.4.24 <0.5.0;

////// contracts/interfaces/IAuthority.sol
/* pragma solidity ^0.4.24; */

contract IAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

////// contracts/DSAuth.sol
/* pragma solidity ^0.4.24; */

/* import './interfaces/IAuthority.sol'; */

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

/**
 * @title DSAuth
 * @dev The DSAuth contract is reference implement of https://github.com/dapphub/ds-auth
 * But in the isAuthorized method, the src from address(this) is remove for safty concern.
 */
contract DSAuth is DSAuthEvents {
    IAuthority   public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(IAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == owner) {
            return true;
        } else if (authority == IAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

////// contracts/LocationCoder.sol
/* pragma solidity ^0.4.24; */

library LocationCoder {
    // the allocation of the [x, y, z] is [0<1>, x<21>, y<21>, z<21>]
    uint256 constant CLEAR_YZ = 0x0fffffffffffffffffffff000000000000000000000000000000000000000000;
    uint256 constant CLEAR_XZ = 0x0000000000000000000000fffffffffffffffffffff000000000000000000000;
    uint256 constant CLEAR_XY = 0x0000000000000000000000000000000000000000000fffffffffffffffffffff;

    uint256 constant NOT_ZERO = 0x1000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant APPEND_HIGH =  0xfffffffffffffffffffffffffffffffffffffffffff000000000000000000000;

    uint256 constant MAX_LOCATION_ID =    0x2000000000000000000000000000000000000000000000000000000000000000;

    int256 constant HMETER_DECIMAL  = 10 ** 8;

    // x, y, z should between -2^83 (-9671406556917033397649408) and 2^83 - 1 (9671406556917033397649407).
    int256 constant MIN_Location_XYZ = -9671406556917033397649408;
    int256 constant MAX_Location_XYZ = 9671406556917033397649407;
    // 96714065569170334.50000000
    int256 constant MAX_HM_DECIMAL  = 9671406556917033450000000;
    int256 constant MAX_HM  = 96714065569170334;

    function encodeLocationIdXY(int _x, int _y) internal pure  returns (uint result) {
        return encodeLocationId3D(_x, _y, 0);
    }

    function decodeLocationIdXY(uint _positionId) internal pure  returns (int _x, int _y) {
        (_x, _y, ) = decodeLocationId3D(_positionId);
    }

    function encodeLocationId3D(int _x, int _y, int _z) internal pure  returns (uint result) {
        return _unsafeEncodeLocationId3D(_x, _y, _z);
    }

    function _unsafeEncodeLocationId3D(int _x, int _y, int _z) internal pure returns (uint) {
        require(_x >= MIN_Location_XYZ && _x <= MAX_Location_XYZ, "Invalid value.");
        require(_y >= MIN_Location_XYZ && _y <= MAX_Location_XYZ, "Invalid value.");
        require(_z >= MIN_Location_XYZ && _z <= MAX_Location_XYZ, "Invalid value.");

        // uint256 constant FACTOR_2 = 0x1000000000000000000000000000000000000000000; // <16 ** 42> or <2 ** 168>
        // uint256 constant FACTOR = 0x1000000000000000000000; // <16 ** 21> or <2 ** 84>
        return ((uint(_x) << 168) & CLEAR_YZ) | (uint(_y << 84) & CLEAR_XZ) | (uint(_z) & CLEAR_XY) | NOT_ZERO;
    }

    function decodeLocationId3D(uint _positionId) internal pure  returns (int, int, int) {
        return _unsafeDecodeLocationId3D(_positionId);
    }

    function _unsafeDecodeLocationId3D(uint _value) internal pure  returns (int x, int y, int z) {
        require(_value >= NOT_ZERO && _value < MAX_LOCATION_ID, "Invalid Location Id");

        x = expandNegative84BitCast((_value & CLEAR_YZ) >> 168);
        y = expandNegative84BitCast((_value & CLEAR_XZ) >> 84);
        z = expandNegative84BitCast(_value & CLEAR_XY);
    }

    function toHM(int _x) internal pure returns (int) {
        return (_x + MAX_HM_DECIMAL)/HMETER_DECIMAL - MAX_HM;
    }

    function toUM(int _x) internal pure returns (int) {
        return _x * LocationCoder.HMETER_DECIMAL;
    }

    function expandNegative84BitCast(uint _value) internal pure  returns (int) {
        if (_value & (1<<83) != 0) {
            return int(_value | APPEND_HIGH);
        }
        return int(_value);
    }

    function encodeLocationIdHM(int _x, int _y) internal pure  returns (uint result) {
        return encodeLocationIdXY(toUM(_x), toUM(_y));
    }

    function decodeLocationIdHM(uint _positionId) internal pure  returns (int, int) {
        (int _x, int _y) = decodeLocationIdXY(_positionId);
        return (toHM(_x), toHM(_y));
    }
}

////// contracts/interfaces/ITokenLocation.sol
/* pragma solidity ^0.4.24; */

contract ITokenLocation {

    function hasLocation(uint256 _tokenId) public view returns (bool);

    function getTokenLocation(uint256 _tokenId) public view returns (int, int);

    function setTokenLocation(uint256 _tokenId, int _x, int _y) public;

    function getTokenLocationHM(uint256 _tokenId) public view returns (int, int);

    function setTokenLocationHM(uint256 _tokenId, int _x, int _y) public;
}

////// contracts/TokenLocation.sol
/* pragma solidity ^0.4.24; */

/* import "./interfaces/ITokenLocation.sol"; */
/* import "./DSAuth.sol"; */
/* import "./LocationCoder.sol"; */

contract TokenLocation is DSAuth, ITokenLocation {
    using LocationCoder for *;
    
    bool private singletonLock = false;

    // token id => encode(x,y) postiion in map, the location is in micron.
    mapping (uint256 => uint256) public tokenId2LocationId;

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract() public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function hasLocation(uint256 _tokenId) public view returns (bool) {
        return tokenId2LocationId[_tokenId] != 0;
    }

    function getTokenLocationHM(uint256 _tokenId) public view returns (int, int){
        (int _x, int _y) = getTokenLocation(_tokenId);
        return (LocationCoder.toHM(_x), LocationCoder.toHM(_y));
    }

    function setTokenLocationHM(uint256 _tokenId, int _x, int _y) public auth {
        setTokenLocation(_tokenId, LocationCoder.toUM(_x), LocationCoder.toUM(_y));
    }

    // decode tokenId to get (x,y)
    function getTokenLocation(uint256 _tokenId) public view returns (int, int) {
        uint locationId = tokenId2LocationId[_tokenId];
        return LocationCoder.decodeLocationIdXY(locationId);
    }

    function setTokenLocation(uint256 _tokenId, int _x, int _y) public auth {
        tokenId2LocationId[_tokenId] = LocationCoder.encodeLocationIdXY(_x, _y);
    }
}