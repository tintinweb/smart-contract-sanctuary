pragma solidity ^0.4.18;

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="94f0f1e0f1d4f5ecfdfbf9eef1fabaf7fb">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function implementsERC721() public pure returns (bool);
    // ERC20 compatible methods
    function name() public pure returns (string);
    function symbol() public pure returns (string);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function totalSupply() public view returns (uint256 total);
    // Methods defining ownership
    function ownerOf(uint256 _tokenId) public view returns (address addr);
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    // Events
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}

contract YTIcons is ERC721 {

    /* CONSTANTS */

    /// Name and symbol of the non-fungible token (ERC721)
    string public constant NAME = "YTIcons";
    string public constant SYMBOL = "YTIcon";

    /// The corporation address that will be used for its development (giveaway, game events...)
    address private _utilityFund = 0x6B06a2a15dCf3AE45b9F133Be6FD0Be5a9FAedC2;

    /// When a card isn&#39;t verified, the normal share given to the beneficiary linked
    /// to the card is given to the charity fund&#39;s address instead.
    address private _charityFund = 0xF9864660c4aa89E241d7D44903D3c8A207644332;

    uint16 public _generation = 0;
    uint256 private _defaultPrice = 0.001 ether;
    uint256 private firstLimit =  0.05 ether;
    uint256 private secondLimit = 0.5 ether;
    uint256 private thirdLimit = 1 ether;


    /* STORAGE */

    /// An array containing all of the owners addresses :
    /// those addresses are the only ones that can execute actions requiring an admin.
    address private _owner0x = 0x8E787E0c0B05BE25Ec993C5e109881166b675b31;
    address private _ownerA =  0x97fEA5464539bfE3810b8185E9Fa9D2D6d68a52c;
    address private _ownerB =  0x0678Ecc4Db075F89B966DE7Ea945C4A866966b0e;
    address private _ownerC =  0xC39574B02b76a43B03747641612c3d332Dec679B;
    address private _ownerD =  0x1282006521647ca094503219A61995C8142a9824;

    Card[] private _cards;

    /// A mapping from cards&#39; IDs to their prices [0], the last investment* [1] and their highest price [2].
    /// *If someone buys an icon for 0.001 ETH, then the last investment of the card will be 0.001 ETH. If someone else buys it back at 0.002 ETH,
    /// then the last investment will be 0.002 ETH.
    mapping (uint256 => uint256[3]) private _cardsPrices;

    /// A mapping from cards&#39; names to the beneficiary addresses
    mapping (uint256 => address) private _beneficiaryAddresses;

    /// A mapping from cards&#39; IDs to their owners
    mapping (uint256 => address) private _cardsOwners;

    /// A mapping from owner address to count of tokens that address owns.
    /// Used for ERC721&#39;s method &#39;balanceOf()&#39; to resolve ownership count.
    mapping (address => uint256) private _tokenPerOwners;

    /// A mapping from cards&#39; ids to an address that has been approved to call
    /// transferFrom(). Each Card can only have one approved address for transfer
    /// at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public _allowedAddresses;


    /* STRUCTURES */

    struct Card {
        uint16  generation;
        string  name;
        bool    isLocked;
    }

    /* EVENTS */
    event YTIconSold(uint256 tokenId, uint256 newPrice, address newOwner);
    event PriceModified(uint256 tokenId, uint256 newPrice);



    /* ACCESS MODIFIERS */

    /// Access modifier for owner&#39;s functionalities and actions only
    modifier ownerOnly() {
        require(msg.sender == _owner0x || msg.sender == _ownerA || msg.sender == _ownerB || msg.sender == _ownerC || msg.sender == _ownerD);
        _;
    }


    /* PROTOCOL METHODS (ERC721) */

    function implementsERC721() public pure returns (bool) {
        return true;
    }

        /**************/
        /* ERC20 compatible methods */
        /**************/

    /// This function is used to tell outside contracts and applications the name of this token.
    function name() public pure returns (string) {
        return NAME;
    }

    /// It provides outside programs with the token’s shorthand name, or symbol.
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

    /// This function returns the total number of coins available on the blockchain.
    /// The supply does not have to be constant.
    function totalSupply() public view returns (uint256 supply) {
        return _cards.length;
    }

    /// This function is used to find the number of tokens that a given address owns.
    function balanceOf(address _owner) public view returns (uint balance) {
        return _tokenPerOwners[_owner];
    }

        /**************/
        /* Ownership methods */
        /**************/

    /// This function returns the address of the owner of a token. Because each ERC721 token is non-fungible and,
    /// therefore, unique, it’s referenced on the blockchain via a unique ID.
    /// We can determine the owner of a token using its ID.
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        require(_addressNotNull(_cardsOwners[_tokenId]));
        return _cardsOwners[_tokenId];
    }

    /// This function approves, or grants, another entity permission to transfer a token on the owner’s behalf.
    function approve(address _to, uint256 _tokenId) public {
        require(bytes(_cards[_tokenId].name).length != 0);
        require(!_cards[_tokenId].isLocked);
        require(_owns(msg.sender, _tokenId));
        require(msg.sender != _to);
        _allowedAddresses[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    /// This function acts like a withdraw function, since an outside party can call it in order
    /// to take tokens out of another user’s account.
    /// Therefore, takeOwnership can be used to when a user has been approved to own a certain amount of
    /// tokens and wishes to withdraw said tokens from another user’s balance.
    function takeOwnership(uint256 _tokenId) public {
        require(bytes(_cards[_tokenId].name).length != 0);
        require(!_cards[_tokenId].isLocked);
        address newOwner = msg.sender;
        address oldOwner = _cardsOwners[_tokenId];
        require(_addressNotNull(newOwner));
        require(newOwner != oldOwner);
        require(_isAllowed(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

    /// "transfer" lets the owner of a token send it to another user, similar to a standalone cryptocurrency.
    function transfer(address _to, uint256 _tokenId) public {
        require(bytes(_cards[_tokenId].name).length != 0);
        require(!_cards[_tokenId].isLocked);
        require(_owns(msg.sender, _tokenId));
        require(msg.sender != _to);
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) private {
        // Transfer ownership to the new owner
        _cardsOwners[tokenId] = to;
        // Increase the number of tokens own by the new owner
        _tokenPerOwners[to] += 1;

        // When creating new cards, from is address(0)
        if (from != address(0)) {
            _tokenPerOwners[from] -= 1;
            // clear any previously approved ownership exchange
            delete _allowedAddresses[tokenId];
        }

        // Emit the transfer event.
        Transfer(from, to, tokenId);
    }

    /// Third-party initiates transfer of token from address from to address to
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(!_cards[tokenId].isLocked);
        require(_owns(from, tokenId));
        require(_isAllowed(to, tokenId));
        require(_addressNotNull(to));

        _transfer(from, to, tokenId);
    }


    /* MANAGEMENT FUNCTIONS -- ONLY USABLE BY ADMINS */

    function createCard(string cardName, uint price, address cardOwner, address beneficiary, bool isLocked) public ownerOnly {
        require(bytes(cardName).length != 0);
        price = price == 0 ? _defaultPrice : price;
        _createCard(cardName, price, cardOwner, beneficiary, isLocked);
    }

    function createCardFromName(string cardName) public ownerOnly {
        require(bytes(cardName).length != 0);
        _createCard(cardName, _defaultPrice, address(0), address(0), false);
    }

    /// Create card
    function _createCard(string cardName, uint price, address cardOwner, address beneficiary, bool isLocked) private {
        require(_cards.length < 2^256 - 1);
        Card memory card = Card({
                                    generation: _generation,
                                    name: cardName,
                                    isLocked: isLocked
                                });
        _cardsPrices[_cards.length][0] = price; // Current price
        _cardsPrices[_cards.length][1] = price; // Last bought price
        _cardsPrices[_cards.length][2] = price; // Highest
        _cardsOwners[_cards.length] = cardOwner;
        _beneficiaryAddresses[_cards.length] = beneficiary;
        _tokenPerOwners[cardOwner] += 1;
        _cards.push(card);
    }


    /// Change the current generation
    function evolveGeneration(uint16 newGeneration) public ownerOnly {
        _generation = newGeneration;
    }

    /// Change the address of one owner.
    function setOwner(address currentAddress, address newAddress) public ownerOnly {
        require(_addressNotNull(newAddress));

        if (currentAddress == _ownerA) {
            _ownerA = newAddress;
        } else if (currentAddress == _ownerB) {
            _ownerB = newAddress;
        } else if (currentAddress == _ownerC) {
            _ownerC = newAddress;
        } else if (currentAddress == _ownerD) {
            _ownerD = newAddress;
        }
    }

    /// Set the charity fund.
    function setCharityFund(address newCharityFund) public ownerOnly {
        _charityFund = newCharityFund;
    }

    /// Set the beneficiary ETH address.
    function setBeneficiaryAddress(uint256 tokenId, address beneficiaryAddress) public ownerOnly {
        require(bytes(_cards[tokenId].name).length != 0);
        _beneficiaryAddresses[tokenId] = beneficiaryAddress;
    }

    /// Lock a card and make it unusable
    function lock(uint256 tokenId) public ownerOnly {
        require(!_cards[tokenId].isLocked);
        _cards[tokenId].isLocked = true;
    }

    /// Unlock a YTIcon and make it usable
    function unlock(uint256 tokenId) public ownerOnly {
        require(_cards[tokenId].isLocked);
        _cards[tokenId].isLocked = false;
    }

    /// Get the smart contract&#39;s balance out of the contract and transfers it to every related account.
    function payout() public ownerOnly {
        _payout();
    }

    function _payout() private {
        uint256 balance = this.balance;
        _ownerA.transfer(SafeMath.div(SafeMath.mul(balance, 20), 100));
        _ownerB.transfer(SafeMath.div(SafeMath.mul(balance, 20), 100));
        _ownerC.transfer(SafeMath.div(SafeMath.mul(balance, 20), 100));
        _ownerD.transfer(SafeMath.div(SafeMath.mul(balance, 20), 100));
        _utilityFund.transfer(SafeMath.div(SafeMath.mul(balance, 20), 100));
    }


    /* UTILS */

    /// Check if the address is valid by checking if it is not equal to 0x0.
    function _addressNotNull(address target) private pure returns (bool) {
        return target != address(0);
    }

    /// Check for token ownership
    function _owns(address pretender, uint256 tokenId) private view returns (bool) {
        return pretender == _cardsOwners[tokenId];
    }

    function _isAllowed(address claimant, uint256 tokenId) private view returns (bool) {
        return _allowedAddresses[tokenId] == claimant;
    }

    /* PUBLIC FUNCTIONS */

    /// Get all of the useful card&#39;s informations.
    function getCard(uint256 tokenId) public view returns (string cardName, uint16 generation, bool isLocked, uint256 price, address owner, address beneficiary, bool isVerified) {
        Card storage card = _cards[tokenId];
        cardName = card.name;
        require(bytes(cardName).length != 0);
        generation = card.generation;
        isLocked = card.isLocked;
        price = _cardsPrices[tokenId][0];
        owner = _cardsOwners[tokenId];
        beneficiary = _beneficiaryAddresses[tokenId];
        isVerified = _addressNotNull(_beneficiaryAddresses[tokenId]) ? true : false;
    }

    /// Set a lower price if the sender is the card&#39;s owner.
    function setPrice(uint256 tokenId, uint256 newPrice) public {
        require(!_cards[tokenId].isLocked);
        // If new price > 0
        // If the new price is higher or equal to the basic investment of the owner (e.g. if someone buys a card 0.001 ETH, then the default investment will be 0.001)
        // If the new price is lower or equal than the highest price set by the algorithm.
        require(newPrice > 0 && newPrice >= _cardsPrices[tokenId][1] && newPrice <= _cardsPrices[tokenId][2]);
        require(msg.sender == _cardsOwners[tokenId]);

        _cardsPrices[tokenId][0] = newPrice;
        PriceModified(tokenId, newPrice);
    }

    function purchase(uint256 tokenId) public payable {
        require(!_cards[tokenId].isLocked);
        require(_cardsPrices[tokenId][0] > 0);

        address oldOwner = _cardsOwners[tokenId];
        address newOwner = msg.sender;

        uint256 sellingPrice = _cardsPrices[tokenId][0];

        // Making sure the token owner isn&#39;t trying to purchase his/her own token.
        require(oldOwner != newOwner);

        require(_addressNotNull(newOwner));

        // Making sure the amount sent is greater than or equal to the sellingPrice.
        require(msg.value >= sellingPrice);

        uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 92), 100));
        uint256 beneficiaryPayment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 3), 100));
        uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
        uint256 newPrice = 0;

        // Update prices
        if (sellingPrice < firstLimit) {
            newPrice = SafeMath.div(SafeMath.mul(sellingPrice, 200), 92);
        } else if (sellingPrice < secondLimit) {
            newPrice = SafeMath.div(SafeMath.mul(sellingPrice, 150), 92);
        } else if (sellingPrice < thirdLimit) {
            newPrice = SafeMath.div(SafeMath.mul(sellingPrice, 125), 92);
        } else {
            newPrice = SafeMath.div(SafeMath.mul(sellingPrice, 115), 92);
        }

        _cardsPrices[tokenId][0] = newPrice; // New price
        _cardsPrices[tokenId][1] = sellingPrice; // Last bought price
        _cardsPrices[tokenId][2] = newPrice; // New highest price

        _transfer(oldOwner, newOwner, tokenId);

        // Pay previous owner
        if (oldOwner != address(this) && oldOwner != address(0)) {
            oldOwner.transfer(payment);
        }

        if (_beneficiaryAddresses[tokenId] != address(0)) {
            _beneficiaryAddresses[tokenId].transfer(beneficiaryPayment);
        } else {
            _charityFund.transfer(beneficiaryPayment);
        }

        YTIconSold(tokenId, newPrice, newOwner);

        msg.sender.transfer(purchaseExcess);
    }

    function getOwnerCards(address owner) public view returns(uint256[] ownerTokens) {
        uint256 balance = balanceOf(owner);
        if (balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](balance);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;

            uint256 cardId;
            for (cardId = 0; cardId <= total; cardId++) {
                if (_cardsOwners[cardId] == owner) {
                    result[resultIndex] = cardId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function getHighestPrice(uint256 tokenId) public view returns(uint256 highestPrice) {
        highestPrice = _cardsPrices[tokenId][1];
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

}