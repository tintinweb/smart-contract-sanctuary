// SPDX-License-Identifier: MIT

// Into the Metaverse NFTs are governed by the following terms and conditions: https://a.did.as/into_the_metaverse_tc

pragma solidity ^0.8.9;

import "./Counters.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

import './AbstractERC1155Factory.sol';
import "./PaymentSplitter.sol";



/*
* @title ERC1155 token for Adidas cards
* @author Niftydude
*/
contract AdidasOriginals is AbstractERC1155Factory, PaymentSplitter  {

    uint256 constant MAX_SUPPLY = 30000;
    uint256 constant MAX_EARLY_ACCESS = 20380;

    uint8 maxPerTx = 2;
    uint8 maxTxPublic = 2;
    uint8 maxTxEarly = 1;

    uint256 public mintPrice = 2000000000000000;
    uint256 public cardIdToMint = 1;

    uint256 public earlyAccessWindowOpens = 32533921476;
    uint256 public purchaseWindowOpens    = 32533921477;
    uint256 public purchaseWindowCloses   = 32533921478;

    uint256 public burnWindowOpens  = 32533921479;
    uint256 public burnWindowCloses = 32533921480;

    bytes32 public merkleRoot;
    mapping(address => uint256) public purchaseTxs;

    event RedeemedForCard(uint256 indexed indexToRedeem, uint256 indexed indexToMint, address indexed account, uint256 amount);
    event Purchased(uint256 indexed index, address indexed account, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        //bytes32 _merkleRoot,
        address[] memory payees,
        uint256[] memory shares_
    ) ERC1155(_uri) PaymentSplitter(payees, shares_) {
        name_ = _name;
        symbol_ = _symbol;

        //merkleRoot = _merkleRoot;

        _mint(0x8c685C44fACB8Bf246fCb0E383CCa4Bd46634bF8, 0, 380, "");
    }

    /**
    * @notice set card id that can be minted by burning previous cards
    */
    function startNextStage() external onlyOwner {
        cardIdToMint += 1;
    }

    /**
    * @notice emergency function to return to previous stage
    */
    function returnToPreviousStage() external onlyOwner {
        require(cardIdToMint > 1, "Cannot go below stage 1");

        cardIdToMint -= 1;
    }

    /**
    * @notice edit the merkle root for early access sale
    *
    * @param _merkleRoot the new merkle root
    */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
    * @notice edit the mint price
    *
    * @param _mintPrice the new price in wei
    */
    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
    * @notice edit sale restrictions
    *
    * @param _maxPerTx the new max amount of tokens allowed to buy in one tx
    * @param _maxTxEarly the max amount of txs allowed during early access
    * @param _maxTxPublic the max amount of txs allowed during public sale
    */
    function editSaleRestrictions(uint8 _maxPerTx, uint8 _maxTxEarly, uint8 _maxTxPublic) external onlyOwner {
        maxPerTx = _maxPerTx;
        maxTxEarly = _maxTxEarly;
        maxTxPublic = _maxTxPublic;
    }

    /**
    * @notice edit windows
    *
    * @param _purchaseWindowOpens UNIX timestamp for purchasing window opening time
    * @param _purchaseWindowCloses UNIX timestamp for purchasing window close time
    * @param _earlyAccessWindowOpens UNIX timestamp for early access window opening time
    * @param _burnWindowOpens UNIX timestamp for burn window opening time
    * @param _burnWindowCloses UNIX timestamp for burn window close time
    */
    function editWindows(
        uint256 _purchaseWindowOpens,
        uint256 _purchaseWindowCloses,
        uint256 _earlyAccessWindowOpens,
        uint256 _burnWindowOpens,
        uint256 _burnWindowCloses
    ) external onlyOwner {
        require(
            _burnWindowOpens > _purchaseWindowCloses &&
            _purchaseWindowOpens > _earlyAccessWindowOpens &&
            _purchaseWindowCloses > _purchaseWindowOpens &&
            _burnWindowCloses > _burnWindowOpens,
            "window combination not allowed"
        );

        purchaseWindowOpens = _purchaseWindowOpens;
        purchaseWindowCloses = _purchaseWindowCloses;
        earlyAccessWindowOpens = _earlyAccessWindowOpens;

        burnWindowOpens = _burnWindowOpens;
        burnWindowCloses = _burnWindowCloses;
    }

    /**
    * @notice purchase cards during early access sale
    *
    * @param amount the amount of cards to purchase
    * @param index the index of the merkle proof
    * @param merkleProof the valid merkle proof of sender
    */
    function earlyAccessSale(
        uint256 amount,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        require(block.timestamp >= earlyAccessWindowOpens && block.timestamp <= purchaseWindowCloses, "Early access: window closed");
        require(totalSupply(0) + amount <= MAX_EARLY_ACCESS, "Early access: max supply reached");
        require(purchaseTxs[msg.sender] < maxTxEarly , "max tx amount exceeded");

        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, uint256(2)));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        _purchase(amount);
    }

    /**
    * @notice purchase cards during public sale
    *
    * @param amount the amount of tokens to purchase
    */
    function purchase(uint256 amount) external payable whenNotPaused {
        require(block.timestamp >= purchaseWindowOpens && block.timestamp <= purchaseWindowCloses, "Purchase: window closed");
        require(purchaseTxs[msg.sender] < maxTxPublic , "max tx amount exceeded");

        _purchase(amount);

    }

    /**
    * @notice global purchase function used in early access and public sale
    *
    * @param amount the amount of tokens to purchase
    */
    function _purchase(uint256 amount) private {
        require(amount > 0 && amount <= maxPerTx, "Purchase: amount prohibited");
        require(totalSupply(0) + amount <= MAX_SUPPLY, "Purchase: Max supply reached");
        require(msg.value == amount * mintPrice, "Purchase: Incorrect payment");

        purchaseTxs[msg.sender] += 1;

        _mint(msg.sender, 0, amount, "");
        emit Purchased(0, msg.sender, amount);
    }

    /**
    * @notice burn card for other
    *
    * @param cardIdToRedeem the token id of the card to burn
    * @param amount the amount to burn
    */
    function redeemCardForOther(uint256 cardIdToRedeem, uint256 amount) external whenNotPaused {
        require(balanceOf(msg.sender, cardIdToRedeem) >= amount && amount > 0, "BurnCardForOther: amount not allowed");
        require(block.timestamp >= burnWindowOpens && block.timestamp <= burnWindowCloses, "BurnCardForOther: window closed");
        require(cardIdToRedeem < cardIdToMint, "BurnCardForOther: card cannot be burned");

        _burn(msg.sender, cardIdToRedeem, amount);
        _mint(msg.sender, cardIdToMint, amount, "");

        emit RedeemedForCard(cardIdToRedeem, cardIdToMint, msg.sender, amount);
    }

    /**
     * @notice Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     *
     * @param account the payee to release funds for
     */
    function release(address payable account) public override {
        require(msg.sender == account || msg.sender == owner(), "Release: no permission");

        super.release(account);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override {
        require(block.timestamp > purchaseWindowCloses || totalSupply(0) == MAX_SUPPLY, "Burn: not allowed during sale");

        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        require(block.timestamp > purchaseWindowCloses || totalSupply(0) == MAX_SUPPLY, "Burn: not allowed during sale");

        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    /**
    * @notice returns the metadata uri for a given id
    *
    * @param _id the card id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");

            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }
}