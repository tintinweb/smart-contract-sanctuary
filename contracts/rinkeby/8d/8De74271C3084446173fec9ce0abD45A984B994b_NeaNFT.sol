// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import './Ownable.sol';

interface MintTicketFactory {
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract NeaNFT is ERC721Enumerable, Ownable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    string public baseURI;

    MintTicketFactory public neaMintTicketFactory;

    event Redeemed(address indexed account, uint256[] amounts);

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI, 
        address _mintTicketAddress
    ) ERC721(name, symbol) {
        baseURI = _baseURI;
        neaMintTicketFactory = MintTicketFactory(_mintTicketAddress);
    }

    function setMintTicketAddress(address _mintTicketAddress) external onlyOwner {
        neaMintTicketFactory = MintTicketFactory(_mintTicketAddress);
    }    

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function redeem(uint256[] calldata mtIndexes, uint256[] calldata amounts) public virtual {
        uint256 totalSupply = _owners.length;
        require(_msgSender() == tx.origin, "Redeem: not allowed from contract");

        //check to make sure all are valid then re-loop for redemption 
        for(uint i = 0; i < mtIndexes.length; i++) {
            require(amounts[i] > 0, "Redeem: amount cannot be zero");
            require(neaMintTicketFactory.balanceOf(_msgSender(), mtIndexes[i]) >= amounts[i], "Redeem: insufficient amount of Mint Passports");
        }

        for(uint i = 0; i < mtIndexes.length; i++) {
            neaMintTicketFactory.burnFromRedeem(_msgSender(), mtIndexes[i], amounts[i]);
            for(uint j = 0; j < amounts[i]; j++) {
                _mint(_msgSender(), totalSupply + i);
            }
        }
        emit Redeemed(_msgSender(), amounts);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

}