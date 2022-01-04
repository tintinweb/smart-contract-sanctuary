// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";


contract Cyborg86 is ERC721, Ownable, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;

    enum WorkflowStatus {
        Before,
        FirstSale,
        SecondSale,
        Sale,
        SoldOut,
        Reveal
    }

    struct GiveawayWallet {
        address recipient;
        bool eligible;
        uint[] claimableIds;
        bool minted;
    }

    string internal baseTokenURI;
    string internal unrevealedURI;
    string internal uriSuffix = ".json";

    uint nonce = 0;
    bool public firstSaleActive = false;
    bool public secondSaleActive = false;
    bool public saleActive = false;
    bool internal revealed = false;
    uint public totalSupply = 8600;
    uint public price = 0.25 ether;
    uint public whitelistPrice = 0.22 ether;
    uint public whitelist2Price = 0.25 ether;
    uint public maxMintPublic = 100;
    uint public maxMintFirst = 10;
    uint public maxMintSecond = 8;

    WorkflowStatus public workflow;

    address[] private _team = [0x486992EC99a2e81875E7feC7FAa170dEDF2497Dc, 0x9Fe16f720bF0447C9EcFeB6F1f6d7d5893996519];
    uint256[] private _teamShares = [2, 98];

    mapping(address => bool) public whitelist1Wallets;
    mapping(address => bool) public whitelist2Wallets;

    mapping(address => uint256) public mintPublicSale;
    mapping(address => uint256) public mintWhitelist1;
    mapping(address => uint256) public mintWhitelist2;

    GiveawayWallet[] public giveawayWallets;
    mapping(uint256 => bool) public reservedTokensGiveaway;

    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event Mint(address owner, uint qty);
    event MintFirstSale(address owner, uint qty);
    event MintSecondSale(address owner, uint qty);
    event Giveaway(address to, uint qty);
    event Withdraw(uint amount);


    constructor() ERC721("C86 Cyborg", "C86") PaymentSplitter(_team, _teamShares) {
        workflow = WorkflowStatus.Before;
    }

    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }

    function setWhitelistPrice(uint newPrice) external onlyOwner {
        whitelistPrice = newPrice;
    }

    function setWhitelist2Price(uint newPrice) external onlyOwner {
        whitelist2Price = newPrice;
    }

    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }

    function setSaleActive(bool val) public onlyOwner {
        require(!firstSaleActive, "Cyborg86: First sale still running");
        require(!secondSaleActive, "Cyborg86: second sale still running");
        saleActive = val;
        workflow = WorkflowStatus.Sale;

        emit WorkflowStatusChange(WorkflowStatus.SecondSale, WorkflowStatus.Sale);
    }

    function setFirstSaleActive(bool val) public onlyOwner {
        require(!saleActive, "Cyborg86: Sale already running");
        require(!secondSaleActive, "Cyborg86: Second sale already running");
        firstSaleActive = val;
        workflow = WorkflowStatus.FirstSale;

        emit WorkflowStatusChange(WorkflowStatus.Before, WorkflowStatus.FirstSale);
    }

    function setSecondSaleActive(bool val) public onlyOwner {
        require(!firstSaleActive, "Cyborg86: First sale still running");
        require(!saleActive, "Cyborg86: Sale already running");
        secondSaleActive = val;
        workflow = WorkflowStatus.SecondSale;

        emit WorkflowStatusChange(WorkflowStatus.FirstSale, WorkflowStatus.SecondSale);
    }

    function addGiveawayWallet(address[] memory _a, uint[][] memory _ids) public onlyOwner {
        require(_a.length == _ids.length, "Cyborg86: Different parameters length");

        for(uint256 i; i < _a.length; i++) {
            GiveawayWallet memory wallet = GiveawayWallet(_a[i], true, _ids[i], false);
            giveawayWallets.push(wallet);
            for(uint256 j; j < _ids[i].length; j++) {
                reservedTokensGiveaway[_ids[i][j]] = true;
            }
        }
    }

    function removeAllGiveawayWallets() public onlyOwner {
        for(uint256 i = 0; i < giveawayWallets.length; i++) {
            for(uint256 j = 0; j < giveawayWallets[i].claimableIds.length; j++) {
                delete reservedTokensGiveaway[giveawayWallets[i].claimableIds[j]];
            }
        }
        delete giveawayWallets;
    }

    function addWalletsToFirstWhitelist(address[] memory _a) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            whitelist1Wallets[_a[i]] = true;
        }
    }

    function removeWalletsFromFirstWhitelist(address[] memory _a) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            whitelist1Wallets[_a[i]] = false;
        }
    }

    function addWalletsToSecondWhitelist(address[] memory _a) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            whitelist2Wallets[_a[i]] = true;
        }
    }

    function removeWalletsFromSecondWhitelist(address[] memory _a) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            whitelist2Wallets[_a[i]] = false;
        }
    }

    function setMaxPublicMint(uint newMax) external onlyOwner {
        maxMintPublic = newMax;
    }

    function setMaxFirstMint(uint newMax) external onlyOwner {
        maxMintFirst = newMax;
    }

    function setMaxSecondMint(uint newMax) external onlyOwner {
        maxMintSecond = newMax;
    }

    function getAssetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;

        for (uint i = 1; i <= nonce; i++) {
            if (_exists(i)) {
                if (ownerOf(i) == _owner) {
                    result[counter] = i;
                    counter++;
                }
            }
        }
        return result;
    }

    function getMyAssets() external view returns(uint[] memory){
        return getAssetsByOwner(tx.origin);
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function getCountGiveawayWallet() public view returns(uint) {
       return giveawayWallets.length;
    }

    function getGiveawayWallet(address _a) public view returns(GiveawayWallet memory) {
        GiveawayWallet memory wallet;
        for (uint i = 0; i < giveawayWallets.length; i++) {
            if (giveawayWallets[i].recipient == _a) {
                wallet = giveawayWallets[i];
                break;
            }
        }

        return wallet;
    }

    function setGiveawayWalletMinted(address _a) private {
        for(uint i = 0; i < giveawayWallets.length; i++){
            if(giveawayWallets[i].recipient == _a) {
                giveawayWallets[i].minted = true;
            }
        }
    }

    function giveaway() external nonReentrant {
        GiveawayWallet memory wallet = getGiveawayWallet(msg.sender);
        require(wallet.eligible, "Cyborg86: Not eligible to giveaway");
        require(!wallet.minted, "Cyborg86: Already claimed");

        for(uint i = 0; i < wallet.claimableIds.length; i++){
            if (!_exists(wallet.claimableIds[i])) {
                _safeMint(msg.sender, wallet.claimableIds[i]);
            }
        }
        setGiveawayWalletMinted(msg.sender);
    }

    function getSumQtyReservedTokens(uint qty) internal view returns(uint) {
        uint count = 0;
        for(uint i = 1; i + count <= qty; i++) {
            if (reservedTokensGiveaway[nonce+i]) {
                count++;
            }
        }
        return count + qty;
    }

    function buy(uint qty) external payable nonReentrant {
        uint256 sumQtyReserved = getSumQtyReservedTokens(qty);
        require(saleActive || firstSaleActive || secondSaleActive , "TRANSACTION: No sale active");
        require(sumQtyReserved + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");

        if (workflow == WorkflowStatus.FirstSale) {
            _mintFirstSale(qty);
        } else if (workflow == WorkflowStatus.SecondSale) {
            _mintSecondSale(qty);
        } else if (workflow == WorkflowStatus.Sale) {
            require(saleActive, "TRANSACTION: Sale is not active");
            require(msg.value == price * qty, "PAYMENT: invalid value");
            require(mintPublicSale[msg.sender] + qty <= maxMintPublic, "PUBLIC SALE: Max 100 mint");
            mintPublicSale[msg.sender] += qty;

            for(uint i = 0; i < qty; i++){
                nonce++;
                while(reservedTokensGiveaway[nonce] || _exists(nonce)) {
                    nonce++;
                }
                _safeMint(msg.sender, nonce);
            }
            emit Mint(msg.sender, qty);
        }
    }

    function _mintFirstSale(uint qty) private {
        require(msg.value == whitelistPrice * qty, "PAYMENT: invalid value");
        require(whitelist1Wallets[msg.sender], "FIRST SALE: Sender not allowed");
        require(mintWhitelist1[msg.sender] + qty <= maxMintFirst, "FIRST SALE: Max 10 mint");
        mintWhitelist1[msg.sender] += qty;

        for(uint i = 0; i < qty; i++){
            nonce++;
            while(reservedTokensGiveaway[nonce] || _exists(nonce)) {
                nonce++;
            }
            _safeMint(msg.sender, nonce);
        }
        emit MintFirstSale(msg.sender, qty);
    }

    function _mintSecondSale(uint qty) private {
        require(secondSaleActive, "TRANSACTION: Second sale is not active");
        require(msg.value == whitelist2Price * qty, "PAYMENT: invalid value");
        require(whitelist2Wallets[msg.sender], "SECOND SALE: Sender not allowed");
        require(mintWhitelist2[msg.sender] + qty <= maxMintSecond, "SECOND SALE: Max 8 mint");
        mintWhitelist2[msg.sender] += qty;

        for(uint i = 0; i < qty; i++){
            nonce++;
            while(reservedTokensGiveaway[nonce] || _exists(nonce)) {
                nonce++;
            }
            _safeMint(msg.sender, nonce);
        }
        emit MintSecondSale(msg.sender, qty);
    }

    /**
    @dev Base URI setter
     */
    function _setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function _setUnrevealedURI(string memory _newUnrevealedURI) public onlyOwner {
        unrevealedURI = _newUnrevealedURI;
    }

    function _setURISuffix(string memory _newUriSuffix) public onlyOwner {
        uriSuffix = _newUriSuffix;
    }

    function setRevealed(bool isRevealed) external onlyOwner {
        revealed = isRevealed;
        if (isRevealed) {
            emit WorkflowStatusChange(WorkflowStatus.SoldOut, WorkflowStatus.Reveal);
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
              return bytes(unrevealedURI).length > 0
                ? string(abi.encodePacked(unrevealedURI, tokenId.toString(), uriSuffix))
                : "";
        }

        string memory base = _baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString(), uriSuffix))
                : "";
    }
}