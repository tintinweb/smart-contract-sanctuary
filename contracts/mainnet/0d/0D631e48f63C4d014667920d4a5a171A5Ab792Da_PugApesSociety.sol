// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @author Roi Di Segni (aka @sheeeev66)
 * In collaboration with "Core Devs" 
 */

import './ERC721.sol';
import "./IERC2981.sol";
import "./IERC20.sol";
import "./Strings.sol";

contract PugApesSociety is ERC721, IERC2981 {
    using Strings for uint256;

    event newMint(address minter, uint id);

    address public developmentWallet;
    address public teamWallet;

    bool public mintingEnabled;
    bool public preMintingEnabled;

    uint16 private reserveId = 8887; // reserve: 650
    uint16 private reserveAmount = 888;
    uint16 private availableToMint = 8888 - reserveAmount;

    uint16 public _tokenId;

    mapping(address => bool) claimedWithSKEY;
    mapping(address => bool) whitelisted;
    mapping(address => bool) isOg;
    mapping(address => uint8) canClaim;
    mapping(address => uint8) amountPreMinted;

    IERC721 constant baycContract = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    IERC721 constant maycContract = IERC721(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
    IERC20 sKeysContractERC20;

    constructor() ERC721("PugApe Society", "PUGAPES") { }

    function releaseReserve(uint8 amountToRelease) external onlyOwner {
        reserveAmount -= amountToRelease;
        availableToMint = 8888 - reserveAmount;
    }

    function addToReserve(uint8 amountToAdd) external onlyOwner {
        reserveAmount += amountToAdd;
        availableToMint = 8888 - reserveAmount;
    }

    function getReserve() external view returns(uint16) {
        return reserveAmount;
    }

    function setSkeysContractERC20(address _address) external onlyOwner {
        sKeysContractERC20 = IERC20(_address);
    }

    function withdraw() external onlyOwner {
        uint bal = address(this).balance;
        require(
            payable(teamWallet).send(bal * 4 / 10) &&
            payable(developmentWallet).send(bal * 4 / 10) &&
            payable(msg.sender).send(bal * 2 / 10),
            "Transfer to one of the wallets failed!"
        );
    }

    function totalSupply() external pure returns(uint) {
        return 8888;
    }

    function setDevelopmentWallet(address _developmentWalletAddress) external onlyOwner {
        developmentWallet = _developmentWalletAddress;
    }

    function setTeamWallet(address _teamWalletAddress) external onlyOwner {
        teamWallet = _teamWalletAddress;
    }

    function getPreMintingState() external view returns(bool) {
        return preMintingEnabled;
    }

    function getMintingState() external view returns(bool) {
        return mintingEnabled;
    }

    function canPreMint(address _address) public view returns(uint8 result) {
        if (
            baycContract.balanceOf(_address) > 0 ||
            maycContract.balanceOf(_address) > 0
        ) {
            result += 5;
        }
        if (isOg[_address]) {
            result += 10;
        }
        if (whitelisted[_address]) {
            result += 5;
        }
        if (sKeysContractERC20.balanceOf(_address) > 0) {
            result += 5;
        }
        result -= amountPreMinted[_address];
    }

    function addToPreMintWhitelist(address[] memory addresses) external onlyOwner {
        for (uint16 i; addresses.length > i; i++) whitelisted[addresses[i]] = true;
    }

    function removeFromPreMint(address _address) external onlyOwner {
        require(whitelisted[_address], "Address is not on the whitelist!");
        whitelisted[_address] = false;
    }

    function addToOgList(address[] memory addresses) external onlyOwner {
        for (uint16 i; addresses.length > i; i++) isOg[addresses[i]] = true;
    }

    function removeFromOgList(address _address) external onlyOwner {
        require(isOg[_address], "Address is not on the OG list!");
        isOg[_address] = false;
    }

    function togglePreMinting() public onlyOwner {
        preMintingEnabled = !preMintingEnabled;
    }

    function togglePublicMinting() public onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function mint(uint8 amount) public payable {
        require(_tokenId + amount < availableToMint, "Purchace will exceed the token supply!");
        uint cost = uint(6e16) * uint(amount);
        require(msg.value == cost, "Ether value sent is not correct");

        if (!mintingEnabled) {
            require(preMintingEnabled, "Pre mint phase is over!");
            uint amountToPreMint = canPreMint(msg.sender);
            require(amountToPreMint > 0, "Caller not eligable for a pre mint");
            require(amount <= amountToPreMint, "Requested amount exeeds the amount an address can pre mint!");
            _mintFuncLoop(msg.sender, amount);
            amountPreMinted[msg.sender] += amount;
            return;
        }

        require(amount <= 10 && amount != 0, "Invalid requested amount!");
        _mintFuncLoop(msg.sender, amount);
    }

    function canFreeMint(address _address) public view returns(uint8) {
        return canClaim[_address];
    }

    function addToFreeMint(address _address, uint8 amount) external onlyOwner {
        require(
            canClaim[_address] + amount <= 2,
            "Cannot allow to a person to claim more than 2 at once!"
        );
        canClaim[_address] += amount;
    }

    function removeFromFreeMint(address _address) external onlyOwner {
        delete canClaim[_address];
    }

    function claim(address to, uint8 amount) public {
        require(reserveId - 1 >= 8888 - reserveAmount, "No more tokens left to claim!");
        
        if (!claimedWithSKEY[to] && (sKeysContractERC20.balanceOf(to) == 3)) {
            _safeMint(to, reserveId);
            emit newMint(to, reserveId);
            claimedWithSKEY[to] = true;
            reserveId--;
        }

        require(canFreeMint(to) > 0, "Caller is not eligable for an airdrop!");
        require(amount <= canFreeMint(to), "Cannot claim that many tokens!");

        for (uint8 i; i < amount; i++) {
            _safeMint(to, reserveId);
            emit newMint(to, reserveId);
            canClaim[to]--;
            reserveId--;
        }
    }

    function _mintFuncLoop(address to, uint8 amount) private {
        for (uint8 i; i < amount; i++) {
            _mintFunc(to);
        } 
    }

    function _mintFunc(address to) private {
        _safeMint(to, _tokenId);
        emit newMint(to, _tokenId);
        _tokenId++;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    ////////// the following implementaiton is by @sheeeev66 //////////
    /**
     * @dev See {IERC2981-royaltyInfo}.
     * @dev Royalty info for the exchange to read (using EIP-2981 royalty standard)
     * @param tokenId the token Id 
     * @param salePrice the price the NFT was sold for
     * @dev returns: send a percent of the sale price to the royalty recievers address
     * @notice this function is to be called by exchanges to get the royalty information
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "ERC2981RoyaltyStandard: Royalty info for nonexistent token");
        return (address(this), (salePrice * 75) / 1000);
    }
}