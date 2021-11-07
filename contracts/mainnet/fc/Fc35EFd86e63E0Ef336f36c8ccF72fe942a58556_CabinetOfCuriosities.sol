// SPDX-License-Identifier: MIT

/*
*
* Society of the Hourglass: Cabinet of Curiosities
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* Website: https://www.societyofthehourglass.com/
* Mint Page: https://app.hashku.com/team/society-of-the-hourglass/cabinet-of-curiosities/mint
*
*/

pragma solidity 0.8.9;

import "./VerifySignature.sol";
import "./Withdraw.sol";
import "./Group.sol";
import "./ExternalAccount.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";

contract CabinetOfCuriosities is 
    Ownable, 
    Withdraw, 
    Group, 
    VerifySignature, 
    ExternalAccount,
    ERC1155, 
    ERC1155Burnable
{
    mapping(uint256 => uint256) private _totalSupply;

    struct CabinetItem {
        uint256 price;
        uint256 amountMinted;
        uint256 amountAllowed;
        uint256 maxMintPerAddress;
        uint256 mainCollectionQty;
    }
    mapping(uint256 => CabinetItem) public items;

    /// @notice How many items someone can mint
    uint256 public maxMintEachAddress = 2;
    mapping(address => uint) public hasMinted;

    string private cabinetUri = "https://storage.hashku.com/api/soth/cabinet/{id}.json";

    uint256 constant private DUST = 0;
    uint256 constant private SCOPE = 1;
    uint256 constant private BOOK = 2;
    uint256 constant private BOT = 3;
    uint256 constant private POSTER = 4;
    uint256 constant private BOOK_CLOSED = 5;
    uint256 constant private BOT_ACTIVE = 6;

    uint256 public currentRaffleIndex = 11;

    mapping(uint256 => bool) public nigelWinners;

    constructor() ERC1155("https://storage.hashku.com/soth/cabinet/{id}.json") {
        // forget me dust
        items[DUST] = CabinetItem(60000000000000000, 0, 222, 2, 2);

        // pocket spectroscope
        items[SCOPE] = CabinetItem(120000000000000000, 0, 166, 2, 4);

        // book of epochs
        items[BOOK] = CabinetItem(170000000000000000, 0, 99, 2, 4);

        // autotranslator bot
        items[BOT] = CabinetItem(170000000000000000, 0, 99, 2, 4);

        // wanted poster of nigel
        items[POSTER] = CabinetItem(180000000000000000, 0, 99, 2, 4);

        // opened book of epochs
        items[BOOK_CLOSED] = CabinetItem(0, 0, 99, 2, 0);

        // activated autotranslator bot
        items[BOT_ACTIVE] = CabinetItem(0, 0, 99, 2, 0);

        // Raffle tickets will be IDs 11-99
    }

    /*
    * @notice Total supply of a given item
    */
    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /*
    * @notice Set overall quanitity a user is allowed to mint
    */
    function setMaxMintEachAddress(uint256 _amt) public onlyOwner {
        maxMintEachAddress = _amt;
    }

    /*
    * @notice Set a Nigel raffle ticket as a winner
    */
    function setNigelWinner(uint256 _id) public onlyOwner {
        nigelWinners[_id] = true;
    }

    /*
    * @notice Allow updating the item data
    */
    function setItem( uint256 _id, uint256 _price, uint256 _amountAllowed, uint256 _maxMintPerAddress, uint256 _mainCollectionQty ) public onlyOwner {
        items[_id].price = _price;
        items[_id].amountAllowed = _amountAllowed;
        items[_id].maxMintPerAddress = _maxMintPerAddress;
        items[_id].mainCollectionQty = _mainCollectionQty;
    }

    function uri(uint256) public view override returns (string memory) {
        return cabinetUri;
    }
    
    function setURI(string memory _newuri) public onlyOwner {
        cabinetUri = _newuri;
    }

    /*
    * @notice Shop for a single item of varyiable quantity
    */
    function shop( uint256 _id, uint256 _qty, bytes memory _signature ) public payable {
        // check signature - will be provided by Hashku
        require(verifySignature("SHOP", group, _id, _qty, _signature), "invsig");
        require(_id < 5, "invitm");
        require(_qty * items[_id].price == msg.value, "incfnds");

        mintInternal(msg.sender, _id, _qty);
    }

    /*
    * @notice Shop for more than a single item
    */
    function shopMultiple( uint256[] memory _ids, uint256[] memory _qtys, bytes memory _signature ) public payable {
        // check signature - will be provided by Hashku
        require(verifySignature("SHOP", group, _ids[0], _qtys[0], _signature), "invsig");
        require(_ids.length == _qtys.length, "idqtymm");
        require(_ids.length < 6, "maxitms");

        uint256 _totalPrice;
        for (uint256 _i = 0; _i < _ids.length; _i++) {
            require(_ids[_i] < 5, "invitm");
            _totalPrice += items[_ids[_i]].price * _qtys[_i];
        }

        require(_totalPrice == msg.value, "incfnds");

        for (uint256 _i = 0; _i < _ids.length; _i++) {
            mintInternal(msg.sender, _ids[_i], _qtys[_i]);
        }
    }

    /*
    * @notice Mint an item, used by other functions only
    */
    function mintInternal(address _to, uint256 _id, uint256 _qty) internal {
        require(hasMinted[_to] + _qty <= maxMintEachAddress, "mintmax");
        require(items[_id].amountMinted + _qty <= items[_id].amountAllowed, "itmunv");
        require(_qty + balanceOf(_to, _id) <= items[_id].maxMintPerAddress, "itmmax");

        hasMinted[_to] += _qty;
        items[_id].amountMinted += _qty;
        _mint(_to, _id, _qty, "");
    }

    /*
    * @notice Send tokens to an address (to be used for rewarding community members and partners)
    */
    function send(address _to, uint256[] memory _ids, uint256[] memory _qtys) public onlyOwner {
        require(_ids.length == _qtys.length, "idqtymm");
        require(_ids.length < 6, "maxitms");

        for (uint256 _i = 0; _i < _ids.length; _i++) {
            require(_ids[_i] < 5, "invitm");
        }

        for (uint256 _i = 0; _i < _ids.length; _i++) {
            mintInternal(_to, _ids[_i], _qtys[_i]);
        }
    }

    /*
    * @notice Mint BOOK_CLOSED or BOT_ACTIVE from redemption contract
    */
    function mintExternal(address _to, uint256 _id, uint256 _qty) external onlyExternalAccount {
        require(_id > 4, "invitm");
        require(_id < 7, "invitm");
        items[_id].amountMinted += _qty;
        _mint(_to, _id, _qty, "");
    }

    /*
    * @notice Mint Nigel raffle ticket (IDs 11+)
    */
    function mintNigelRaffle(address _to, uint256 _qty) external onlyExternalAccount {
        for (uint256 _i = 0; _i < _qty; _i++) {
            _mint(_to, currentRaffleIndex, 1, "");
            currentRaffleIndex += 1;
        }
    }

    /*
    * @notice Burn token from redemption account
    */
    function burnExternal(address _to, uint256 _id, uint256 _qty) external onlyExternalAccount {
        _burn(_to, _id, _qty);
    }

    /*
    * @notice Shortcut for retrieving number of main collection NFTs are redemeed from a Cabinet item
    */
    function itemMainCollectionQuantity(uint256 _id) public view returns (uint256) {
        return items[_id].mainCollectionQty;
    }

    function burn(
        address _account,
        uint256 _id,
        uint256 _value
    ) override public virtual onlyOwner {}

    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _values
    ) override public virtual onlyOwner {}
}