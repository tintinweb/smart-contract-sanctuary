// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Creator.sol";
import "./Deployer.sol";
import "./ControlToken.sol";

contract VanityToken is Ownable, ERC721, Creator {
    ControlToken immutable controlToken;
    Deployer immutable deployer;
    bytes32 immutable initHash;

    uint256 public fee;
    uint256 public nextFee;
    uint256 public feeActivationBlock;
    uint256 immutable public feeDelay;

    // Mapping from token ID to salt
    mapping (uint256 => bytes32) private salts;

    address[256] private minters;

    function saltOf(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), "ERC721: salt query for nonexistent token");
        return salts[tokenId];
    }

    function addressOf(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: address query for nonexistent token");
        return address(tokenId);
    }

    function minterById(uint8 minterId) external view returns (address) {
        return minters[minterId];
    }

    function registerMinter(uint8 minterId, address addr) external {
        address current = minters[minterId];
        address sender = _msgSender();
        bool valid = ((current == address(0)) && (sender == owner())) || (sender == current);
        require(valid, "VFA: not owner or current");
        minters[minterId] = addr;
    }

    function remint(address addr, address dest) external {
        require(ControlToken(msg.sender) == controlToken, "VFA: control token only");
        _safeMint(dest, uint256(addr));
    }

    function mint(bytes32 salt, address recipient) external {
        require(bytes32(0) != salt, "VFA: zero salt");

        uint8 minterId = uint8(salt[0]);
        require(_msgSender() == minters[minterId], "VFA: incorrect minterId");

        uint256 tokenId = uint256(_calculateAddress(address(deployer), salt, initHash));
        require(bytes32(0) == salts[tokenId], "VFA: double mint");

        salts[tokenId] = salt;
        _safeMint(recipient, tokenId);
    }

    function safeRedeem(uint256 tokenId, address delegatecallTarget, bytes32 codehash) external payable returns (address) {
        bytes32 actualhash;
        assembly {
            actualhash := extcodehash(delegatecallTarget)
        }
        require(codehash == actualhash, "VFA: code hash not equal");

        return redeem(tokenId, delegatecallTarget);
    }

    function redeem(uint256 tokenId, address delegatecallTarget) public payable returns (address) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: redeem caller is not owner nor approved");
        require(fee <= msg.value, "VFA: msg value not enough to cover fee");
        bytes32 salt = saltOf(tokenId);
        _burn(tokenId);
        address addr = deployer.deploy{value: msg.value-fee}(salt, delegatecallTarget);
        controlToken.mint(tokenId, _msgSender());
        return addr;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setFee(uint256 newFee) external onlyOwner {
        require(newFee < 0.1 ether, "VFA: don't be greedy");

        nextFee = newFee;

        if (fee < nextFee) {
            feeActivationBlock = block.number + feeDelay;
        } else {
            feeActivationBlock = 0;
        }
    }

    function activateFee() external {
        require(feeActivationBlock < block.number, "VFA: fee cannot be activated before activation block");
        fee = nextFee;
    }

    function withdraw() external onlyOwner {
        (bool result, bytes memory data) = payable(owner())
            .call{value: address(this).balance}("");

        if (!result) {
            assembly {
                revert(add(data, 0x20), mload(data))
            }
        }
    }

    constructor(Deployer _deployer, ControlToken _control, uint256 _feeDelay) ERC721("VanityFarmAddress", "VFA") {
        controlToken = _control;
        deployer = _deployer;
        initHash = _deployer.initHash();
        feeDelay = _feeDelay;
    }
}