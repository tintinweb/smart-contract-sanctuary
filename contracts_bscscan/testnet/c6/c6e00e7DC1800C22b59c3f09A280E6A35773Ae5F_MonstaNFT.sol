// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./ERC721Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./TransferHelper.sol";

contract MonstaNFT is ERC721Pausable, AccessControl, Ownable {
    bytes32 public constant UPDATE_TOKEN_URI_ROLE =
        keccak256("UPDATE_TOKEN_URI_ROLE");
    bytes32 public constant PAUSED_ROLE = keccak256("PAUSED_ROLE");
    uint256 public nextTokenId = 1;
    address public mintFeeAddr;
    uint256 public mintFeeAmount;
    event Burn(address indexed sender, uint256 tokenId);
    event MintFeeAddressTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SetMintFeeAmount(
        address indexed seller,
        uint256 oldMintFeeAmount,
        uint256 newMintFeeAmount
    );

    constructor(
        string memory name,
        string memory symbol,
        address _mintFeeAddr,
        uint256 _mintFeeAmount
    ) public ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(UPDATE_TOKEN_URI_ROLE, _msgSender());
        _setupRole(PAUSED_ROLE, _msgSender());
        mintFeeAddr = _mintFeeAddr;
        mintFeeAmount = _mintFeeAmount;
        emit MintFeeAddressTransferred(address(0), mintFeeAddr);
        emit SetMintFeeAmount(_msgSender(), 0, mintFeeAmount);
    }

    receive() external payable {}

    function mint(address to, string memory _tokenURI)
        public
        payable
        returns (uint256 tokenId)
    {
        require(msg.value >= mintFeeAmount, "msg value too low");
        TransferHelper.safeTransferETH(mintFeeAddr, mintFeeAmount);
        tokenId = nextTokenId;
        _mint(to, tokenId);
        nextTokenId++;
        _setTokenURI(tokenId, _tokenURI);
        if (msg.value > mintFeeAmount)
            TransferHelper.safeTransferETH(
                msg.sender,
                msg.value - mintFeeAmount
            );
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public {
        require(
            hasRole(UPDATE_TOKEN_URI_ROLE, _msgSender()),
            "Must have update token uri role"
        );
        _setTokenURI(tokenId, tokenURI);
    }

    function setBaseURI(string memory baseURI) public {
        require(
            hasRole(UPDATE_TOKEN_URI_ROLE, _msgSender()),
            "Must have update token uri role"
        );
        _setBaseURI(baseURI);
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
        emit Burn(_msgSender(), tokenId);
    }

    function pause() public whenNotPaused {
        require(hasRole(PAUSED_ROLE, _msgSender()), "Must have pause role");
        _pause();
    }

    function unpause() public whenPaused {
        require(hasRole(PAUSED_ROLE, _msgSender()), "Must have pause role");
        _unpause();
    }

    function transferMintFeeAddress(address _mintFeeAddr) public {
        require(_msgSender() == mintFeeAddr, "FORBIDDEN");
        mintFeeAddr = _mintFeeAddr;
        emit MintFeeAddressTransferred(_msgSender(), mintFeeAddr);
    }

    function setMintFeeAmount(uint256 _mintFeeAmount) public onlyOwner {
        require(mintFeeAmount != _mintFeeAmount, "FEE NO CHANGE");
        emit SetMintFeeAmount(_msgSender(), mintFeeAmount, _mintFeeAmount);
        mintFeeAmount = _mintFeeAmount;
    }
}