/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/// @title IDistTld.
/// @dev This interface communidates with the DistTld contract.
interface IDistTld {
    function tldExists(string memory tld) external view returns(bool);
    function getTldIndex(string memory tld) external view returns(uint256); 
    function getMintingFee(address payable sender, string memory tld) external view returns (uint256 fee, uint256 commission, address tldOwnerAdd);   
}

/// @title IDistDomain.
/// @dev This interface communidates with the DistDomain contract.
interface IDistDomain {
    function createDomain(uint256 tokenId, bool useSafeMint, address domainOwner) external;
    function createSubdomain(uint256 tokenId, uint256 subTokenId) external;
    function domainExists(uint256 tokenId) external view returns(bool);
    function isDomainOwner(uint256 tokenId, address domainOwner) external returns(bool);
}

/// @title DistRegistrar.
/// @dev This contract allows domain registration.
contract DistRegistrar is Ownable {

    // Address of external contracts
    address private _tldContract;
    address private _domainContract;

    // Mapping from tokenId to URI
    mapping(uint256 => string) private _tokenURIs;

    // Mapping from tokenId to preset id to key to value
    mapping(uint256 => mapping(uint256 => mapping(string => string))) private _records;

    // Mapping from ttokenId to current preset id
    mapping(uint256 => uint256) private _tokenPresets;

    // events
    event CreateURI(string domain, uint256 tokenId, address owner);
    event Debug(string msg);

    /// @notice Constructor
    constructor() {

    }

    /// @notice Set TLD contract address.
    /// @dev This function is only callable by the contract owner (i.e. DistRegistrar contract).
    /// @dev Reverts if sender is not the contract owner.
    /// @param tldContract Address of the DistTld contract.
    function setTldContact(address tldContract) public onlyOwner {
        require (_tldContract == address(0), "TLD contract address already set");
        _tldContract = tldContract;
    }

    /// @notice Set domain contract address.
    /// @dev This function is only callable by the contract owner (i.e. DistRegistrar contract).
    /// @dev Reverts if sender is not the contract owner.
    /// @param domainContract Address of the DistDomain contract.
    function setDomainContact(address domainContract) public onlyOwner {
        require (_domainContract == address(0), "Domain contract address already set");
        _domainContract = domainContract;
    }

    /// @notice Check whether a domain is already registered.
    /// @dev Check whether a domain is already registered.
    /// @param tokenId Address of the DistDomain contract.
    /// @return registered True if domain is already registered.
    function isRegistered(uint256 tokenId) public view returns(bool registered) {
        string memory uri = _tokenURIs[tokenId];
        return bytes(uri).length > 0;
    }

    /// @notice Function to mint a single domain name using ERC721 _mint.
    /// @dev Transfers ownership of new token to msg.sender.
    /// @dev Ownership is based on tokenId which is a keccak256 hash of a domain name string e.g. 'example.dcom'.
    /// @dev Returns excess wei to msg.sender. e.g. If too much is paid the change will be returned to msg.sender.
    /// @dev Reverts if msg.sender is zero address.
    /// @dev Reverts if msg.value is less than the minting fee.
    /// @dev Reverts if sld or tld contain invalid characters or are an invalid length.
    /// @dev Reverts if tld does not exist.
    /// @dev Reverts if not enough msg.value to cover fees and commission.
    /// @dev Emits CreateURI event.
    /// @param sld Second level domain label e.g. 'example' from 'example.dcom'.
    /// @param tld Top level domain label e.g. 'dcom' from 'example.dcom'.
    function mintDomain(string memory sld, string memory tld) public payable {
        _validSld(sld);
        require(IDistTld(_tldContract).tldExists(tld), "TLD does not exist");
        uint256 tokenId = uint256(keccak256(abi.encodePacked(sld, ".", tld)));
        (uint256 fee, uint256 commission, address tldOwnerAdd) = IDistTld(_tldContract).getMintingFee(msg.sender, tld);

        // Check there's enough wei to pay fee and commission
        require(msg.value >= fee+commission, "Not enough funds to mint this domain");

        // Transfer minting fee to the TLD owner's address
        if (fee > 0) {
            address payable tldPayableOwnerAdd = payable(tldOwnerAdd);
            tldPayableOwnerAdd.transfer(fee);
        }

        // Transfer commission to contract owner
        address payable ownerAdd = payable(owner());
        ownerAdd.transfer(commission);

        // Transfer excess payment back to msg.sender
        if (msg.value > fee+commission) {
            msg.sender.transfer(msg.value - (fee+commission));
        }
        _tokenURIs[tokenId] = string(abi.encodePacked(sld, ".", tld));
        IDistDomain(_domainContract).createDomain(tokenId, false, msg.sender);
        _tokenPresets[tokenId] = block.timestamp;
        emit CreateURI(_tokenURIs[tokenId], tokenId, msg.sender);
    }

    /// @notice Function to mint a single domain name using ERC721 _safeMint.
    /// @dev Transfers ownership of new token to msg.sender.
    /// @dev Ownership is based on tokenId which is a keccak256 hash of a domain name string e.g. 'example.dcom'.
    /// @dev Returns excess wei to msg.sender. e.g. If too much is paid the change will be returned to msg.sender.
    /// @dev Reverts if msg.sender is zero address.
    /// @dev Reverts if msg.value is less than the minting fee.
    /// @dev Reverts if sld or tld contain invalid characters or are an invalid length.
    /// @dev Reverts if tld does not exist.
    /// @dev Reverts if not enough msg.value to cover fees and commission.
    /// @dev Emits CreateURI event.
    /// @param sld Second level domain label e.g. 'example' from 'example.dcom'.
    /// @param tld Top level domain label e.g. 'dcom' from 'example.dcom'.
    function safeMintDomain(string memory sld, string memory tld) public payable {
        _validSld(sld);
        require(IDistTld(_tldContract).tldExists(tld), "TLD does not exist");
        
        uint256 tokenId = uint256(keccak256(abi.encodePacked(sld, ".", tld)));
        (uint256 fee, uint256 commission, address tldOwnerAdd) = IDistTld(_tldContract).getMintingFee(msg.sender, tld);

        // Check there's enough wei to pay fee and commission
        require(msg.value >= fee+commission, "Not enough funds to mint this domain");

        // Transfer minting fee to the TLD owner's address
        if (fee > 0) {
            address payable tldPayableOwnerAdd = payable(tldOwnerAdd);
            tldPayableOwnerAdd.transfer(fee);
        }

        // Transfer commission to contract owner
        address payable ownerAdd = payable(owner());
        ownerAdd.transfer(commission);

        // Transfer excess payment back to msg.sender
        if (msg.value > fee+commission) {
            msg.sender.transfer(msg.value - (fee+commission));
        }

        _tokenURIs[tokenId] = string(abi.encodePacked(sld, ".", tld));
        IDistDomain(_domainContract).createDomain(tokenId, true, msg.sender);
        _tokenPresets[tokenId] = block.timestamp;
        emit CreateURI(_tokenURIs[tokenId], tokenId, msg.sender);
    }

    /// @notice Function to mint a single subdomain.
    /// @dev Ownership of subdomains remains with the parent domain.
    /// @dev Subdomains are based upon the keccak256 hash of the domain's full name string e.g. 'subdomain.example.dcom'.
    /// @dev Minting subdomains does not incur any fee or commission.
    /// @dev Reverts if msg.sender does not own tokenId (parent domain).
    /// @dev Reverts if label contains invalid characters or is of invalid length.
    /// @dev Reverts if subdomain already exists.
    /// @dev Emits a CreatURI event.
    /// @param tokenId Parent domain tokenId.
    /// @param label Subdomain label e.g. 'subdomain' from 'subdomain.example.dcom'.
    function mintSubdomain(uint256 tokenId, string memory label) public {
        bool isDomainOwner = IDistDomain(_domainContract).isDomainOwner(tokenId, msg.sender);
        require (isDomainOwner == true, "Only domain owners can mint subdomains");
        _validSld(label);
        uint256 childId = uint256(keccak256(abi.encodePacked(label, ".", _tokenURIs[tokenId])));
        require(!IDistDomain(_domainContract).domainExists(childId), "Subdomain already exists");
        IDistDomain(_domainContract).createSubdomain(tokenId, childId);
        _tokenPresets[childId] = block.timestamp;
        _tokenURIs[childId] = string(abi.encodePacked(label, ".", _tokenURIs[tokenId]));
        emit CreateURI(_tokenURIs[childId], childId, msg.sender);
    }

    /// @notice Checks for valid label characters.
    function _validSld(string memory label) private pure returns (bool) {
        require(bytes(label).length > 1, "Must be longer than 1 character");
        require(bytes(label).length <= 63, "Must be less than 64 characters");
        for (uint256 i = 0; i < bytes(label).length; i++) {
            if (bytes(label)[i] == "-") {
                if (i == 0) {
                    revert("Cannot start with '-'");
                } else if (i == bytes(label).length - 1) {
                    revert("Cannot contain adjacent '-'");
                } else if (i > 0 && bytes(label)[i - 1] == "-") {
                    revert("Cannot end with '-'");
                }
            } else {
                require(
                    ((bytes(label)[i] >= "a" && bytes(label)[i] <= "z") ||
                        (bytes(label)[i] >= "0" && bytes(label)[i] <= "9")),
                    "All characters must be one of: 0-9, a-z, or '-'"
                );
            }
        }
        return true;
    }
}