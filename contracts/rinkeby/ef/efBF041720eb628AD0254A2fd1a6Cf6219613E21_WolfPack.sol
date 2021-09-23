// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC2981Upgradeable.sol";

contract WolfPack is Initializable, OwnableUpgradeable, ERC721Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;
    CountersUpgradeable.Counter internal _tokenIds;

    string private baseURIcid;
    uint16 private preMinted;
    uint16 private mintingSupply = 5405 - preMinted;
    bool private _isPreRelease;
    bool private saleIsActive;
    address _royaltiesReceiver;

    mapping(uint256 => address) private mintedBy;
    mapping(uint256 => address) private tokenHolder;
    mapping(address => bool) private whitelisted;
    mapping(address => bool) private blacklisted;
    event Mint(uint256 indexed tokenId, address indexed minter);

    function initialize(address[] calldata _whitelisted, address[] calldata _airDrop) public initializer {
        __ERC721_init("The Wolf Pack", "WPTK");
        __Ownable_init();
        _tokenIds.increment();
        _isPreRelease = false;
        saleIsActive = false;
        whitelistBatch(_whitelisted);
        airdropNFT(_airDrop);
    }

    function getSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    // URI:
    function setBaseURIcid(string calldata cid) public onlyOwner {
        baseURIcid = cid;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURIcid).length > 0 ? 
        string(abi.encodePacked("ipfs://", baseURIcid, "/", tokenId.toString(), ".json")) : 
        "https://ipfs.io/ipfs/bafkreifnt37vtfgo53mfrfn6oipdxzpcxp3ocoumuuuukgoijk7ei3isvi/";
    }

    // withdraw:
    function withdraw(address payable _address) external onlyOwner {
        _address.transfer(address(this).balance);
    }

    // pre sale / sale states:
    function preSaleState() external view returns (bool) {
        return _isPreRelease;
    }

    function saleState() external view returns (bool) {
        return saleIsActive;
    }

    function togglePreSaleState() external onlyOwner {
        _isPreRelease = !_isPreRelease;
        preMinted = uint16(_tokenIds.current());
    }

    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function getOwnerTokenBalance(address _owner) external view returns (uint256) {
        return balanceOf(_owner);
    }

    function getTokenMinter(uint256 _tokenId) external view returns (address) {
        return mintedBy[_tokenId]; // no error handling for invalid hashes
    }

    function getTokenMinters() external view returns (address[] memory result) {
        uint256 tokenCount = _tokenIds.current();
        result = new address[](tokenCount); // the size is not accurate to the incremented token count; will give either invalid hashes or invalid indices

        if (tokenCount == 0) {
            return new address[](0);
        } else {
            for (uint256 i = 0; i < tokenCount; i++) {
                result[i] = getTokenHolder(i);
            }
            return result;
        }
    }

    function getTokenHolder(uint256 _tokenId) public view returns (address) {
        return tokenHolder[_tokenId]; // no error handling for invalid hashes
    }

    function getTokenHolders() external view returns (address[] memory result) {
        uint256 tokenCount = _tokenIds.current();
        result = new address[](tokenCount); // the size is not accurate to the incremented token count; will give either invalid hashes or invalid indices

        if (tokenCount == 0) {
            return new address[](0);
        } else {
            for (uint256 i = 0; i < tokenCount; i++) {
                result[i] = getTokenHolder(i);
            }
            return result;
        }
    }

    function preMint(uint8 _amount) public payable {
        require(whitelisted[msg.sender], "You are not whitelisted");
        require(!blacklisted[msg.sender], "You are blacklisted");
        require(_isPreRelease, "Sale must be active to mint Wolf");
        require(
            _amount > 0 && _amount <= 3,
            "Exceeds Maximum Mints Per Transaction"
        );
        require(
            _tokenIds.current() + _amount <= 1500,
            "Purchase Would Exceed Max Pre Mint Supply!"
        );
        require(
            msg.value == 100000000000000000 * _amount,
            "Ether value sent is not correct"
        );

        handleMint(msg.sender, _amount);
    }

    function mint(uint8 _amount) public payable {
        uint256 tokenCount = _tokenIds.current();
        require(!blacklisted[msg.sender], "You are blacklisted");
        require(saleIsActive, "Sale must be active to mint Wolf");
        require(
            _amount > 0 && _amount <= 20,
            "Exceeds Maximum Mints Per Transaction"
        );
        require(
            tokenCount + _amount <= mintingSupply,
            "Purchase Would Exceed Max Supply of The Pack"
        );
        require(
            msg.value == 100000000000000000 * _amount,
            "Ether value sent is not correct"
        );

        handleMint(msg.sender, _amount);
    }

    function handleMint(address _to, uint8 _amount) private {
        for (uint256 i = 0; i < _amount; i++) {
            if (_tokenIds.current() < 5405) {
                mintedBy[_tokenIds.current()] = _to;
                tokenHolder[_tokenIds.current()] = _to;
                _safeMint(_to, _tokenIds.current());
                emit Mint(_tokenIds.current(), _to);
                _tokenIds.increment();
            }
        }
    }

    function mintFromReserve(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= 150, "Amount will exceed reserve amount!");
        require(
            _tokenIds.current() + _amount <= 150,
            "Purchase would exceed max supply of The reserve!"
        );

        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, _tokenIds.current());
            tokenHolder[_tokenIds.current()] = _to;
            emit Mint(_tokenIds.current(), _to);
            _tokenIds.increment();
        }
    }

    function airdropNFT(address[] memory _addresses) public onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            _safeMint(_addresses[i], _tokenIds.current());
            tokenHolder[_tokenIds.current()] = _addresses[i];
            emit Mint(_tokenIds.current(), _addresses[i]);
            _tokenIds.increment();
        }
    }

    function whitelistBatch(address[] memory _to) public onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            whitelisted[_to[i]] = true;
        }
    }

    function addBlacklist(address _addr) public onlyOwner {
        blacklisted[_addr] = true;
    }

    function setMinters(address[] memory _minters, uint[] memory _tokenId) external onlyOwner {
        require(_minters.length == _tokenId.length, "Array length missmatch! Please verify inputs");
        for (uint256 i; i < _minters.length; i++) {
            mintedBy[_tokenId[i]] = _minters[i];
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) {
        // call after the super call
        // should not transfer address if the lower method fails 
      	// will remove tokens regardless of success
        tokenHolder[tokenId] = to;
        super._transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal override(ERC721Upgradeable) {
        // call after the super call
        // should not transfer address if the lower method fails 
        // will remove tokens regardless of success
        tokenHolder[tokenId] = to;
        super._safeTransfer(from, to, tokenId, _data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets the royalty recieving address to:
     * @param newRoyaltiesReceiver the address the royalties are sent to
     * @notice Setting the recieving address to the zero address will result in an error
     */
    function setRoyaltiesReceiver(address newRoyaltiesReceiver) external onlyOwner {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }

    /**
     * @dev Royalty info for the exchange to read (using EIP-2981 royalty standard)
     * @param tokenId the token Id 
     * @param salePrice the price the NFT was sold for
     * @dev returns: send a percent of the sale price to the royalty recievers address
     * @notice this function is to be called by exchanges to get the royalty information
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "ERC2981RoyaltyStandard: Royalty info for nonexistent token");
        return (_royaltiesReceiver, (salePrice * 7) / 100);
    }


}