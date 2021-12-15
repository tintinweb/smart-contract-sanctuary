// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./ECDSA.sol";

contract PugApesSociety is ERC721, IERC2981 {

    event newMint(address minter, uint id);

    address public devWallet;
    address public teamWallet;

    bool public mintingEnabled;
    bool public preMintingEnabled;

    uint16 public totalSupply; // total amount of minted tokens
    uint16 public maxSupply;
    uint16 public reserveAmount;
    uint16 public mintSupply;
    uint public mintPrice;
    uint public whitelistPrice;

    // uint16 public _tokenId;

    mapping(address => bool) claimedWithSKEY;
    mapping(address => uint8) amountPreMinted;
    mapping(bytes => bool) sigUsed;

    IERC721 constant old = IERC721(0x0D631e48f63C4d014667920d4a5a171A5Ab792Da);
    IERC721 constant baycContract = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    IERC721 constant maycContract = IERC721(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
    IERC20 constant sKeysContractERC20 = IERC20(0xb849C1077072466317cE9d170119A6e68C0879E7);

    constructor(
        uint _whitelistPriceInWei, 
        uint _mintPriceInWei,
        uint16 _maxSupply,
        uint16 _reserveAmount
    ) ERC721("PugApe Society", "PUGAPES") {
        whitelistPrice = _whitelistPriceInWei;
        mintPrice = _mintPriceInWei;
        maxSupply = _maxSupply;
        reserveAmount = _reserveAmount;
        mintSupply = maxSupply - reserveAmount;
    }

    function migrateOld(address[] memory addresses, uint8[] memory amounts) external onlyOwner {
      for (uint8 i; i < addresses.length; i++) {
          address addr = addresses[i];
          uint8 amount = amounts[i];

          for (uint8 j; j < amount; j++) {
              _mintFunc(addr);
          }

          amountPreMinted[addr] = amounts[i];
      }
  }

    function setWhitelistPriceWei(uint price) external onlyOwner {
        whitelistPrice = price;
    }

    function setMintPriceWei(uint price) external onlyOwner {
        mintPrice = price;
    }

    function releaseReserve(uint8 amountToRelease) external onlyOwner {
        uint newMintSupplyAmount = mintSupply + amountToRelease;
        uint newReserveAmount = reserveAmount - amountToRelease;

        require(newMintSupplyAmount <= maxSupply);
        require(newReserveAmount >= 0);

        reserveAmount -= amountToRelease;
        mintSupply = maxSupply - reserveAmount;
    }

    function addToReserve(uint8 amountToAdd) external onlyOwner {
        require(mintSupply - amountToAdd > totalSupply);

        reserveAmount += amountToAdd;
        mintSupply = maxSupply - reserveAmount;
    }

    function withdraw() external onlyOwner {
        uint bal = address(this).balance;
        payable(teamWallet).transfer(bal * 4 / 10);
        payable(devWallet).transfer(bal * 4 / 10);
        payable(owner()).transfer(bal * 2 / 10);
    }

    function setDevWallet(address _devWalletAddress) external onlyOwner {
        devWallet = _devWalletAddress;
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

    function canPreMint(address _address, bytes memory _signature) public view returns(uint8 result) {
        bool inWhitelist = 
          baycContract.balanceOf(_address) > 0 ||
          maycContract.balanceOf(_address) > 0 ||
          old.balanceOf(_address) > 0 ||
          sKeysContractERC20.balanceOf(_address) > 0 ||
          _validiateSig(_address, "whitelist", _signature);

        if (inWhitelist) {
            result = 15;
        }

        require(result >= amountPreMinted[_address], "PugApes: Address is not eligible to pre mint!");

        result -= amountPreMinted[_address];

        require(result > 0, "PugApes: Address is not eligible to pre mint!");
    }

    function togglePreMinting() public onlyOwner {
        preMintingEnabled = !preMintingEnabled;
    }

    function togglePublicMinting() public onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function _validiateSig(address _wallet, string memory s, bytes memory _signature) private view returns(bool) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_wallet, s))),
            _signature
        ) == owner();
    }

    function mint(uint8 amount) public payable {
        mint(amount, "");
    }

    function mint(uint8 amount, bytes memory sig) public payable {
        require(totalSupply + amount < mintSupply, "Purchace will exceed the token supply!");
        if (!mintingEnabled) {
            require(preMintingEnabled, "Pre mint phase is over!");
            require(msg.value == whitelistPrice * amount, "Ether value sent is not correct");
            uint amountToPreMint = canPreMint(msg.sender, sig);
            require(amountToPreMint > 0, "Caller not eligable for a pre mint");
            require(amount <= amountToPreMint, "Requested amount exeeds the amount the address can pre mint!");
            _mintFuncLoop(msg.sender, amount);
            amountPreMinted[msg.sender] += amount;
            return;
        }
        require(msg.value == mintPrice * amount, "Ether value sent is not correct");
        require(amount <= 10 && amount != 0, "Invalid requested amount!");
        _mintFuncLoop(msg.sender, amount); 
    }

    /**
     * @dev checks if an address is eligable to free mint (claim an airdrop)
     * @param _address the address to claim
     */
    function canFreeMint(address _address, bytes memory _signature) public view returns(bool) {
        return _validiateSig(_address, "freemint", _signature);
    }

    function ownerMintFromReserve(uint8 amount) external onlyOwner {
        require(reserveAmount >= amount, "Not enough tokens left in reserve!");
        _mintFuncLoop(msg.sender, amount);
        reserveAmount -=  amount;
    }
    
    function claim(address to, uint8 amount, bytes calldata _signature) public {
        require(reserveAmount > 0, "No more tokens left to claim!");
        require(reserveAmount >= amount, "Not enough tokens to claim!");
        require(canFreeMint(to, _signature), "Caller is not eligable for an airdrop!");

        _mintFuncLoop(to, amount);
        reserveAmount -= amount;
    }

    function getMessageData(address _address, string memory s) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(_address, s));
    }

    function _mintFuncLoop(address to, uint8 amount) private {
        for (uint8 i; amount > i; i++) _mintFunc(to);
    }

    function _mintFunc(address to) private {
        _safeMint(to, totalSupply);
        emit newMint(to, totalSupply);
        totalSupply++;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

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