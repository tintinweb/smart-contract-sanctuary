/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

pragma solidity 0.6.12;

interface INFTContract {
    function getNftId(uint256 _tokenId) external view returns (uint8);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function mint(address _to, string calldata _tokenURI, uint8 _nftId) external returns (uint256);
    function burn(uint256 _tokenId) external;
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


contract NFTMinter is Ownable {
    
    INFTContract oldnft = INFTContract(0xb50e08270b6f77c9ee9A3cd863660cC097Aa6C2D); // CCAKENFT Old
    INFTContract newnft = INFTContract(0xb107949A297555D713bb403b7f96223c6EF97Be7); // CcakeNFT New


    constructor() public {}
    
    function mintReplace(uint256 tokenIDReplace) external onlyOwner {

        uint8 _nftId = oldnft.getNftId(tokenIDReplace);
        address to = oldnft.ownerOf(tokenIDReplace);
        string memory tokenURI = string(abi.encodePacked(itod(_nftId), ".json"));
        newnft.mint(to, tokenURI, _nftId);
    }
    
    function mint4Replace(uint256 tokenIDReplace1, uint256 tokenIDReplace2, uint256 tokenIDReplace3, uint256 tokenIDReplace4) external onlyOwner {

        uint8 _nftId1 = oldnft.getNftId(tokenIDReplace1);
        address to1 = oldnft.ownerOf(tokenIDReplace1);
        string memory tokenURI1 = string(abi.encodePacked(itod(_nftId1), ".json"));
        newnft.mint(to1, tokenURI1, _nftId1);
        
        uint8 _nftId2 = oldnft.getNftId(tokenIDReplace2);
        address to2 = oldnft.ownerOf(tokenIDReplace2);
        string memory tokenURI2 = string(abi.encodePacked(itod(_nftId2), ".json"));
        newnft.mint(to2, tokenURI2, _nftId2);
        
        uint8 _nftId3 = oldnft.getNftId(tokenIDReplace3);
        address to3 = oldnft.ownerOf(tokenIDReplace3);
        string memory tokenURI3 = string(abi.encodePacked(itod(_nftId3), ".json"));
        newnft.mint(to3, tokenURI3, _nftId3);
        
        uint8 _nftId4 = oldnft.getNftId(tokenIDReplace4);
        address to4 = oldnft.ownerOf(tokenIDReplace4);
        string memory tokenURI4 = string(abi.encodePacked(itod(_nftId4), ".json"));
        newnft.mint(to4, tokenURI4, _nftId4);
    }
    
    function burnOldNFTs(uint256 tokenID1, uint256 tokenID2, uint256 tokenID3, uint256 tokenID4, uint256 tokenID5, uint256 tokenID6, uint256 tokenID7, uint256 tokenID8, uint256 tokenID9, uint256 tokenID10) external onlyOwner {

        oldnft.burn(tokenID1);
        oldnft.burn(tokenID2);
        oldnft.burn(tokenID3);
        oldnft.burn(tokenID4);
        oldnft.burn(tokenID5);
        oldnft.burn(tokenID6);
        oldnft.burn(tokenID7);
        oldnft.burn(tokenID8);
        oldnft.burn(tokenID9);
        oldnft.burn(tokenID10);
    }
    
    function itod(uint256 x) private pure returns (string memory) {
        if (x > 0) {
            string memory str;
            while (x > 0) {
                str = string(abi.encodePacked(uint8(x % 10 + 48), str));
                x /= 10;
            }
            return str;
        }
        return "0";
    }
}