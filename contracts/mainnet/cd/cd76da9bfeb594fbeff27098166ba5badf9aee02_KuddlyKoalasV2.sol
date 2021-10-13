// SPDX-License-Identifier: MIT
 
// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721Burnable.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "Counters.sol";
import "ERC721Pausable.sol";
import "IKuddlyKoalas.sol";

contract KuddlyKoalasV2 is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    //Original Kuddly Koalas Contract
    address public kuddlyOriginalAddress = 0xF179cb4d1369C9972b3fa7F6bBcf01d3aAf9a051;
    kuddlyOriginalInterface kuddlyOriginalContract = kuddlyOriginalInterface(kuddlyOriginalAddress);

    Counters.Counter private _tokenIdTracker;


    uint256 public MAX_ELEMENTS = 8888;
    uint256 public constant MAX_BY_MINT = 20;
    uint256 public GAS_BACK_AMOUNT = 6435 * 10**12;
    uint256 public GAS_BACK_QUANTITY = 1000;
    address public constant safeAddress = 0xC8E868E9c922d50bC48DB05b77274E0Fc1eCd440;
    string public baseTokenURI;
    bool public canChangeSupply = true;

    event CreateKoalas(uint256 indexed id);

    constructor(string memory baseURI) ERC721("KuddlyKoalasV2", "KKL") {
        setBaseURI(baseURI); // use original sketch as baseURI egg
        pause(true); // contract starts paused
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mintMultipleAsKoalaOwner(address _to, uint256[] memory _multipleTokenIds) public saleIsOpen {
        uint quantity = _multipleTokenIds.length;
        uint gasBack = 0;
        require(quantity <= MAX_BY_MINT, "Trying to mint more than 20");
        for (uint i = 0; i < quantity; i++) {
          require(!_exists(_multipleTokenIds[i]), "TokenId already exists");
          require(msg.sender == kuddlyOriginalContract.ownerOf(_multipleTokenIds[i]), "Not the owner of this Koala");
          _mintTokenId(_to, _multipleTokenIds[i]);
          if(_totalSupply() < GAS_BACK_QUANTITY) {
            gasBack++;
          }
        }
        if(gasBack > 0) {
          _gasBack(msg.sender, gasBack);
        }
    }

    function backupMint(address _to, uint256[] memory _multipleTokenIds) public onlyOwner {
        uint quantity = _multipleTokenIds.length;
        require(quantity <= MAX_BY_MINT, "Trying to mint too many");
        for (uint i = 0; i < quantity; i++) {
          require(!_exists(_multipleTokenIds[i]), "This token has already been minted");
          _mintTokenId(_to, _multipleTokenIds[i]);
        }
    }

    function saleIsActive() public view returns (bool) {
        if(paused()) {
            return false;
        } else {
            return true;
        }
    }

    function _mintTokenId(address _to, uint _tokenId) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenId);
        emit CreateKoalas(_tokenId);
    }

    // This function allows the total supply to be reduced
    // There are NO other methods to increase the cap, the final cap is 8888 - this can never be altered

    function enableHardLimit(uint256 _limit) public onlyOwner {
        require(canChangeSupply, "Cannot change supply");
        require(_limit <= 8888, "Cannot raise limit over 8888");
        MAX_ELEMENTS = _limit;
    }

    function relinquishMintSupplyControl() public onlyOwner {
        // Sets canChangeSupply to false (off)
        // This is a one-way switch
        // There is no other possible method to re-enable control of max Mint Supply
        require(canChangeSupply, "Cannot change supply");
        canChangeSupply = false;
    }

    function price() public pure returns (uint256) {
        return 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _gasBack(address _to, uint256 _quantity) private {
        if(address(this).balance > GAS_BACK_AMOUNT) {
          payable(_to).transfer(GAS_BACK_AMOUNT * _quantity);
        }
    }

    function setGasBack(uint256 _amount) public onlyOwner {
        GAS_BACK_AMOUNT = _amount;
    }

    function setGasBackQuantity(uint256 _quantity) public onlyOwner {
        GAS_BACK_QUANTITY = _quantity;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "There is no Ether in this contract");
        _withdraw(safeAddress, address(this).balance);
    }

    function withdrawSome(uint _amount) public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > _amount, "There is no Ether in this contract");
        _withdraw(safeAddress, _amount);
    }

    function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function receiveEther() public payable {
    }

    fallback() external payable {
    }
}