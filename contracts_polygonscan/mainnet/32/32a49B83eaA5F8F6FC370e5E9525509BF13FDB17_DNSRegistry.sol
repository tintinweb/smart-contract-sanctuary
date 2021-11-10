// SPDX-License-Identifier: None
pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 */
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract DNSRegistry is Ownable {
    using SafeMath for uint256;

    struct DomainInfo {
        bytes32 name;
        address owner;
        uint256 expires;
        bool isVerified;
    }

    uint256 public domainExpirationPeriod;
    uint8 public domainNameMinLength;

    mapping(bytes32 => DomainInfo) public domainNames;
    mapping(address => mapping(uint256 => DomainInfo)) public userRegisteredDomain;
    mapping(address => uint256) public userTotalDomainRegistered;

    modifier isDomainAvailable(bytes32 domain) {
        bytes32 domainHash = getDomainHash(domain);
        require(
            domainNames[domainHash].expires < block.timestamp,
            "Domain name is not available."
        );
        _;
    }

    modifier isDomainOwner(bytes32 domain) {
        bytes32 domainHash = getDomainHash(domain);
        require(
            domainNames[domainHash].owner == msg.sender,
            "You are not the owner of this domain."
        );
        _;
    }

    modifier isDomainNameLengthAllowed(bytes32 domain) {
        (, uint256 byteLength) = bytes32ToString(domain);
        require(byteLength >= domainNameMinLength, "Domain name is too short.");
        _;
    }

    modifier registrySpecCheck(uint8 minLengthDomain) {
        require(minLengthDomain > 0, "Domain Minimum length cant be Zero");
        _;
    }

    event DomainNameRegistered(
        uint256 indexed timestamp,
        bytes32 domainName,
        address indexed owner
    );

    event DomainNameRenewed(
        uint256 indexed timestamp,
        bytes32 domainName,
        address indexed owner
    );

    event DomainNameTransferred(
        uint256 indexed timestamp,
        bytes32 domainName,
        address indexed currentOwner,
        address newOwner
    );

    event DomainVerified(uint256 indexed timestamp, bytes32 domainName);

    /*
     * @dev - constructor (being called at contract deployment)
     * @param expirationPeriod - domain name to be registered
     * @param minLengthDomain - minimum length allowed for the domain name
     */
    constructor(uint256 expirationPeriod, uint8 minLengthDomain)
        public
        registrySpecCheck(minLengthDomain)
    {
        domainExpirationPeriod = expirationPeriod;
        domainNameMinLength = minLengthDomain;
    }

    /*
     * @dev - register domain name
     * @param domain - domain name to be registered
     * @return domainHash
     */
    function domainRegister(bytes32 domainName)
        external
        isDomainNameLengthAllowed(domainName)
        isDomainAvailable(domainName)
        returns (bytes32 domainHash)
    {
        // calculate the domain hash
        domainHash = getDomainHash(domainName);

        // create a new domain entry with the provided parameters
        DomainInfo memory newDomain =
            DomainInfo({
                name: domainName,
                owner: msg.sender,
                expires: block.timestamp + domainExpirationPeriod,
                isVerified: false
            });

        // save the domain to the storage
        domainNames[domainHash] = newDomain;

        userRegisteredDomain[msg.sender][
            userTotalDomainRegistered[msg.sender]
        ] = newDomain;
        userTotalDomainRegistered[msg.sender]++;

        // log domain name registered
        emit DomainNameRegistered(block.timestamp, domainName, msg.sender);
    }

    /*
     * @dev - function to extend domain expiration date
     * @param domainName
     * @param registeredAtIndex - index where the domain is registered
     */
    function renewDomainName(bytes32 domain, uint256 registeredAtIndex)
        external
        isDomainOwner(domain)
    {
        DomainInfo storage domainInfo =
            userRegisteredDomain[msg.sender][registeredAtIndex];
        // calculate the domain hash
        bytes32 domainHash = getDomainHash(domain);

        // domain hash of current domain should match with that of the passed index
        require(
            domainHash == getDomainHash(domainInfo.name),
            "Unmatched index"
        );

        // add domainExpirationPeriod to the domain expiration date
        domainNames[domainHash].expires += domainExpirationPeriod;
        domainInfo.expires += domainExpirationPeriod;

        // log domain name Renewed
        emit DomainNameRenewed(block.timestamp, domain, msg.sender);
    }

    /*
     * @dev - function to get a User's info of its registered domain
     * @param user - address of user
     * @param index - index position
     * @return domain info of the user like(domainName,owner,expirationPeriod,verification status)
     */
    function getUserRegisteredDomainInfo(address user, uint256 index)
        external
        view
        returns (
            bytes32,
            address,
            uint256,
            bool
        )
    {
        DomainInfo memory domainInfo = userRegisteredDomain[user][index];
        return (
            domainInfo.name,
            domainInfo.owner,
            domainInfo.expires,
            domainInfo.isVerified
        );
    }

    /*
     * @dev - Transfer domain ownership
     * @param domainName
     * @param newOwner - address of the new owner
     * @param registeredAtIndex - index where the domain is registered
     */
    function transferDomain(
        bytes32 domainName,
        address newOwner,
        uint256 registeredAtIndex
    ) external isDomainOwner(domainName) {
        // prevent assigning domain ownership to the 0x0 address
        require(newOwner != address(0));
        DomainInfo memory domainInfo =
            userRegisteredDomain[msg.sender][registeredAtIndex];

        // calculate the hash of the current domain
        bytes32 domainHash = getDomainHash(domainName);
        // domain hash of current domain should match with that of the passed index
        require(
            domainHash == getDomainHash(domainInfo.name),
            "Unmatched index"
        );
        // assign the new owner of the domain
        domainNames[domainHash].owner = newOwner;

        userRegisteredDomain[newOwner][
            userTotalDomainRegistered[newOwner]
        ] = domainInfo;
        userTotalDomainRegistered[newOwner]++;

        delete userRegisteredDomain[msg.sender][registeredAtIndex];

        // emits the log of transfer of ownership
        emit DomainNameTransferred(
            block.timestamp,
            domainName,
            msg.sender,
            newOwner
        );
    }

    /*
     * @dev - Get (domain name) hash used for unique identifier
     * @param domain
     * @return domainHash
     */
    function getDomainHash(bytes32 domain) public pure returns (bytes32) {
        // @dev - tightly pack parameters in struct for keccak256
        return keccak256(abi.encodePacked(domain));
    }

    /*
     * @dev - Verifies a registered Domain
     * @param domainName
     * @param domainOwner - owner of the registered domain
     * @param registeredAtIndex - index where the domain is registered
     * @return true
     */
    function verifyDomain(bytes32 domainName,address domainOwner, uint256 registeredAtIndex)
        public
        onlyOwner
        returns (bool)
    {   
        require(domainOwner != address(0),"Registered Domain Owner can't be zero address");

        // calculate the domain hash
        bytes32 domainHash = getDomainHash(domainName);
        require(
            domainOwner == domainNames[domainHash].owner,
            "Unmatched domain owner"
        );
        require(!domainNames[domainHash].isVerified, "Domain already verified");

        DomainInfo storage domainInfo =
            userRegisteredDomain[domainOwner][registeredAtIndex];

        // domain hash of current domain should match with that of the passed index
        require(
            domainHash == getDomainHash(domainInfo.name),
            "Unmatched index"
        );

        // assign the new owner of the domain
        domainNames[domainHash].isVerified = true;
        domainInfo.isVerified = true;

        // emits the log of Domain Verification
        emit DomainVerified(block.timestamp, domainName);

        return true;
    }

    /*
     * @dev - Change Registry Specification
     * @param expirationPeriod
     * @param minLengthDomain - Domain name minimum length
     */
    function changeRegistrySpecs(
        uint256 _expirationPeriod,
        uint8 _minLengthDomain
    ) external onlyOwner registrySpecCheck(_minLengthDomain) {
        domainExpirationPeriod = _expirationPeriod;
        domainNameMinLength = _minLengthDomain;
    }

    /*
     * @dev - converts string to bytes32
     * @param string
     * @return bytes32 - converted bytes
     */
    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    /*
     * @dev - converts bytes32 to string
     * @param bytes32
     * @return string - converted string
     */
    function bytes32ToString(bytes32 x)
        public
        pure
        returns (string memory, uint256)
    {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = bytes1(bytes32(uint256(x) * 2**(8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return (string(bytesStringTrimmed), charCount);
    }
}