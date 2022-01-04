pragma solidity >=0.5.0 <0.6.0;

import "./AccessControl.sol";
import "./ERC721.sol";
import "./SafeMath.sol";

contract DetailedERC721 is ERC721 {

    function name() public view returns (string memory _name);
    function symbol() public view returns (string memory _symbol);

}
contract CryptoBirdos is AccessControl, DetailedERC721 {
    using SafeMath for uint256;

    event TokenCreated(uint256 tokenId, uint256 dna, uint256 price, address owner);
    event TokenSold(
        uint256 indexed tokenId,
        uint256 dna,
        uint256 sellingPrice,
        uint256 newPrice,
        address payable indexed oldOwner,
        address payable indexed newOwner
    );

    mapping (uint256 => address payable) private tokenIdToOwner;
    mapping (uint256 => uint256) private tokenIdToPrice;
    mapping (address => uint256) private ownershipTokenCount;
    mapping (uint256 => address payable) private tokenIdToApproved;
    mapping (uint256 => address payable) private dnaToOwner;
    mapping (uint256 => bool) public tokenIdToSellable;
    mapping (uint256 => uint256) public tokenIdToSellPrice;

    struct Birdo {
        uint256 dna;
        uint256 firstParentDna;
        uint256 secondParentDna;
        uint64 readyTime;
        uint16 puppyCount;
    }

    Birdo[] private birdos;

    bool private erc721Enabled = false;
    bool breedingEnabled = false;
    bool sellingEnabled = false;

    uint256 private startingPrice = 0.001 ether;
    uint256 private initialSalePrice = 0 ether;
    uint256 breedingFee = 0.005 ether;

    uint256 oneBirdoPrice = 0.002 ether;
    uint256 threeBirdoPrice = 0.05 ether;
    uint256 fiveBirdoPrice = 0.0075 ether;


    uint256 dnaDigits = 33; //alterar tbm concatenateDNA
    uint256 dnaModulus = 10 ** dnaDigits;

    uint cooldownTime = 2 days;

    // string baseURI = "https://crypto-birdos.web.app/image/";


    modifier onlyERC721() {
        require(erc721Enabled);
        _;
    }

    function _setBreedingFee(uint256 fee) public onlyCLevel {
        breedingFee = fee;
    }
    function _breedingFee() public view returns (uint256) {
        return breedingFee;
    }

    function _setBreedingEnabled(bool enabled) public onlyCLevel {
        breedingEnabled = enabled;
    }
    function _isBreedingEnabled() public view returns (bool) {
        return breedingEnabled;
    }

    function _setSellingEnabled(bool enabled) public onlyCLevel {
        sellingEnabled = enabled;
    }
    function _isSellingEnabled() public view returns (bool) {
        return sellingEnabled;
    }

    function _setOneBirdoPrice(uint256 fee) public onlyCLevel {
        oneBirdoPrice = fee;
    }
    function _oneBirdoPrice() public view returns (uint256) {
        return oneBirdoPrice;
    }
    function _setThreeBirdoPrice(uint256 fee) public onlyCLevel {
        threeBirdoPrice = fee;
    }
    function _threeBirdoPrice() public view returns (uint256) {
        return threeBirdoPrice;
    }
    function _setFiveBirdoPrice(uint256 fee) public onlyCLevel {
        fiveBirdoPrice = fee;
    }
    function _fiveBirdoPrice() public view returns (uint256) {
        return fiveBirdoPrice;
    }

    function _triggerCooldown(Birdo storage _birdo) internal {
        _birdo.readyTime = uint64(now + cooldownTime);
    }

    function _isReady(Birdo storage _birdo) internal view returns (bool) {
        return (_birdo.readyTime <= now);
    }

   function _generateRandomDna(uint256 _block) public view returns (uint256) {
        uint256 rand = uint(keccak256(abi.encodePacked(uint(msg.sender) * _block)));
        uint256 dna = rand % 10**dnaDigits;
        return dna;
    }

    function createBirdoToken() public onlyCLevel {
        uint256 blockNumber = block.number - 1;
        uint256 _dna = _generateRandomDna(blockNumber);
        address payable thisAddress = address(uint160(address(this)));
        _createToken(thisAddress, _dna, startingPrice, 0, 0);
    }

    function _getNthDigit(uint256 number, uint256 position) internal view returns (uint8) {
        return uint8(
            ((number % 10**position) - (number % 10**(position-1)))/10**(position-1)
        );
    }

    function _genePriority(uint256 firstParentDna, uint256 secondParentDna, uint256 seed, uint8 digit) internal view returns (uint8) {
        return _geneSelection(_getNthDigit(firstParentDna, digit), _getNthDigit(secondParentDna, digit), _getNthDigit(seed, digit));
    }

    function _geneSelection(uint8 a, uint8 b, uint8 seed) internal view returns(uint8) {
        int intA = int(a);
        int intB = int(b);
        int intSeed = int(seed);
        int resultA = intA - intSeed;
        int resultB = intB - intSeed;

        if (resultA < 0) {
            resultA = -resultA;
        }
        if (resultB < 0) {
            resultB = -resultB;
        }

        if (resultA > resultB) {
            return a;
        } else {
            return b;
        }
    }

    function _concatenateDna(uint8[33] memory genes) internal view returns(uint256 dna) {
        dna = 0;
        for (uint256 i = 0; i < 33; i++) {
            dna = dna + uint256(genes[i])*(10**i);
        }
    }

    function _getRarity(uint256 _dna) public view returns(uint8) {
        uint8 rarity = 0;
        for (uint8 i = 24; i < 30; i++) {
            // puppyDnaStarter[20 - i] = _genePriority(birdos[seed, seed, seed, (21 - i));
            rarity += _getNthDigit(_dna, (30 - i));
        }
        if (rarity < 25) {
            return 0; // common
        } else if (rarity < 32) {
            return 1; //uncommon
        } else if (rarity < 38) {
            return 2; //rare
        } else {
            return 3; //epic
        }
    }

    function breedBirdos(address payable _owner, uint256 _firstBirdoId, uint256 _secondBirdoId) public payable {
        if (_isBreedingEnabled()) {
            require(_owner != address(0));
            require(_owner == msg.sender);
            require(tokenIdToOwner[_firstBirdoId] == _owner);
            require(tokenIdToOwner[_secondBirdoId] == _owner);

            require(_isReady(birdos[_firstBirdoId]));
            require(_isReady(birdos[_secondBirdoId]));

            require(msg.value >= breedingFee);

            uint256 blockNumber = block.number - 1;
            uint256 seed = _generateRandomDna(blockNumber);

            uint8[33] memory puppyDnaStarter;

            for (uint8 i = 1; i < 29; i++) {
                puppyDnaStarter[33 - i] = _genePriority(birdos[_firstBirdoId].dna, birdos[_secondBirdoId].dna, seed, (34 - i));
            }
            // for (uint8 i = 29; i < 34; i++) {
            //     puppyDnaStarter[33 - i] = _getNthDigit(seed, (34 - i));
            // }

            puppyDnaStarter[0] = _getNthDigit(seed, 1) + _getRarity(birdos[_firstBirdoId].dna);
            puppyDnaStarter[2] = _getNthDigit(seed, 3) + _getRarity(birdos[_secondBirdoId].dna);


            if (_getRarity(birdos[_firstBirdoId].dna) == 3 && _getRarity(birdos[_secondBirdoId].dna) == 3) {
                puppyDnaStarter[4] = _getNthDigit(seed, 4) + 3;
            }

            for (uint8 i = 29; i < 34; i++) {
                if (puppyDnaStarter[33 - i] > 9) {
                    puppyDnaStarter[33 - i] = 9;
                }
            }

            uint256 newDna = _concatenateDna(puppyDnaStarter);

            uint256 newPrice = tokenIdToPrice[_firstBirdoId].add(tokenIdToPrice[_secondBirdoId]).div(2);
            require(newPrice >= startingPrice);

            // uint256 newDna = birdos[_firstBirdoId].dna.add(birdos[_secondBirdoId].dna).div(2);

            _createToken(_owner, newDna, newPrice, birdos[_firstBirdoId].dna, birdos[_secondBirdoId].dna);

            birdos[_firstBirdoId].puppyCount++;
            birdos[_secondBirdoId].puppyCount++;

            _triggerCooldown(birdos[_firstBirdoId]);
            _triggerCooldown(birdos[_secondBirdoId]);
        }
    }

    function getChest(address payable _owner, uint8 size) public payable {
        if (birdos.length < 5001) {
            require(_owner != address(0));
            require(_owner == msg.sender);

            require(size == 1 || size == 3 || size == 5);

            if (size == 1) {
                require(msg.value >= oneBirdoPrice);
            } else if (size == 3) {
                require(msg.value >= threeBirdoPrice);
            } else if (size == 5) {
                require(msg.value >= fiveBirdoPrice);
            }

            for (uint256 i = 0; i < size; i++) {
                uint256 blockNumber = block.number - 1 - i;
                _createToken(_owner, _generateRandomDna(blockNumber), startingPrice, 0, 0);
            }
        }
    }

    function _createToken(address payable _owner, uint256 _dna, uint256 _price, uint256 _firstParentDna, uint256 _secondParentDna) private {

        require(dnaToOwner[_dna] == address(0));
        Birdo memory _birdo = Birdo({
            dna: _dna,
            firstParentDna: _firstParentDna,
            secondParentDna: _secondParentDna,
            readyTime: uint64(now),
            puppyCount: 0
        });

        uint256 newTokenId = birdos.push(_birdo) - 1;
        tokenIdToPrice[newTokenId] = _price;
        dnaToOwner[_dna] = _owner;
        tokenIdToSellable[newTokenId] = false;
        emit TokenCreated(newTokenId, _dna, _price, _owner);

        _transfer(address(0), _owner, newTokenId);
    }

    // function _makeSellable(uint256 _tokenId,  bool _isSellable, uint256 _price) public {
    //     require(tokenIdToOwner[_tokenId] == msg.sender);
    //     require(_price >= tokenIdToPrice[_tokenId]);
    //     tokenIdToSellable[_tokenId] = _isSellable;
    //     tokenIdToSellPrice[_tokenId] = _price;
    // }

    // function _isSellable(uint _tokenId) public view returns(bool, uint256) {
    //     return (tokenIdToSellable[_tokenId], priceOf(_tokenId));
    // }

    function getToken(uint256 _tokenId) public view returns (
        uint256 _dna,
        uint256 _firstParentDna,
        uint256 _secondParentDna,
        uint256 _price,
        uint256 _nextPrice,
        uint64 _readyTime,
        uint16 _puppyCount,
        address payable _owner
    ) {
        _dna = birdos[_tokenId].dna;
        _firstParentDna = birdos[_tokenId].firstParentDna;
        _secondParentDna = birdos[_tokenId].secondParentDna;
        _readyTime = birdos[_tokenId].readyTime;
        _puppyCount = birdos[_tokenId].puppyCount;

        _price = tokenIdToPrice[_tokenId];
        _nextPrice = nextPriceOf(_tokenId);
        _owner = tokenIdToOwner[_tokenId];
    }

    function getAllTokens() public view returns (
        uint256[] memory,
        uint256[] memory,
        address[] memory
    ) {
        uint256 total = totalSupply();
        uint256[] memory prices = new uint256[](total);
        uint256[] memory nextPrices = new uint256[](total);
        address[] memory owners = new address[](total);

        for (uint256 i = 0; i < total; i++) {
            prices[i] = tokenIdToPrice[i];
            nextPrices[i] = nextPriceOf(i);
            owners[i] = tokenIdToOwner[i];
        }

        return (prices, nextPrices, owners);
    }

    function tokensOf(address payable _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;

            for (uint256 i = 0; i < total; i++) {
                if(tokenIdToOwner[i] == _owner) {
                    result[resultIndex] = i;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function withdrawBalance(address payable _to, uint256 _amount) public onlyCEO {
        require(_amount <= address(this).balance);

        if(_amount == 0) {
            _amount = address(this).balance;
        }
        if(_to == address(0)) {
            ceoAddress.transfer(_amount);
        } else {
            _to.transfer(_amount);
        }
    }

    // function purchase(uint256 _tokenId) public payable whenNotPaused {
    //     address payable oldOwner = ownerOf(_tokenId);
    //     address payable newOwner = msg.sender;
    //     uint256 sellingPrice = priceOf(_tokenId);
    //     require(oldOwner != address(0));
    //     require(newOwner != address(0));
    //     require(newOwner != oldOwner);
    //     require(!_isContract(newOwner));
    //     require(tokenIdToSellable[_tokenId] == true);
    //     require(sellingPrice > 0);
    //     require(msg.value >= sellingPrice);
    //     //tokenIdToSellable[_tokenId] = _isSellable;
    //     // tokenIdToSellPrice[_tokenId] = _price;

    //     _transfer(oldOwner, newOwner, _tokenId);
    //     emit TokenSold(
    //         _tokenId,
    //         birdos[_tokenId].dna,
    //         sellingPrice,
    //         priceOf(_tokenId),
    //         oldOwner,
    //         newOwner
    //     );

    //     uint256 excess = msg.value.sub(sellingPrice);
    //     uint256 contractCut = sellingPrice.mul(25).div(1000);

    //     if (oldOwner != address(this)) {
    //         oldOwner.transfer(sellingPrice.sub(contractCut));
    //     }

    //     if (excess > 0) {
    //         newOwner.transfer(excess);
    //     }
    // }

    function priceOf(uint256 _tokenId) public view returns (uint256 _price) {
        if (tokenIdToSellPrice[_tokenId] > 0) {
            return tokenIdToSellPrice[_tokenId];
        } else {
            return tokenIdToPrice[_tokenId];
        }
    }

    uint256 private increaseLimit1 = 0.01 ether;
    uint256 private increaseLimit2 = 0.25 ether;
    uint256 private increaseLimit3 = 2.0 ether;
    uint256 private increaseLimit4 = 5.0 ether;

    function nextPriceOf(uint256 _tokenId) public view returns (uint256 _nextPrice) {
        uint256 _price = priceOf(_tokenId);
        if (_price == initialSalePrice) {
            return(startingPrice);
        } else if (_price < increaseLimit1) {
            return(_price.mul(205).div(90));
        } else if (_price < increaseLimit2) {
            return(_price.mul(140).div(95));
        } else if (_price < increaseLimit3) {
            return(_price.mul(130).div(98));
        } else if (_price < increaseLimit3) {
            return(_price.mul(120).div(100));
        } else {
            return(_price.mul(110).div(105));
        }
    }

    function enableERC721() public onlyCEO {
        erc721Enabled = true;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        _totalSupply = birdos.length;
    }

    function balanceOf(address payable _owner) public view returns (uint256 _balance) {
        _balance = ownershipTokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address payable _owner) {
        _owner = tokenIdToOwner[_tokenId];
    }

    function approve(address payable _to, uint256 _tokenId) public whenNotPaused onlyERC721 {
        require(_owns(msg.sender, _tokenId));
        tokenIdToApproved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address payable _from, address payable _to, uint256 _tokenId) public whenNotPaused onlyERC721 {
        if (sellingEnabled) {
            require(_to != address(0));
            require(_owns(_from, _tokenId));
            require(_approved(msg.sender, _tokenId));

            _transfer(_from, _to, _tokenId);
        }
    }

    function transfer(address payable _to, uint256 _tokenId) public whenNotPaused onlyERC721 {
        require(_to != address(0));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    function implementsERC721() public view whenNotPaused returns (bool) {
        return erc721Enabled;
    }

    function takeOwnership(uint256 _tokenId) public whenNotPaused onlyERC721 {
        require(_approved(msg.sender, _tokenId));
        _transfer(tokenIdToOwner[_tokenId], msg.sender, _tokenId);
    }

    function name() public view returns (string memory _name) {
        _name = "Crypto Birdos Ancient Chest";
    }

    function symbol() public view returns (string memory _symbol) {
        _symbol = "ANCIENTCHEST";
    }

    function _owns(address _claimant, uint256 _tokenId) private view returns (bool) {
        return tokenIdToOwner[_tokenId] == _claimant;
    }

    function _approved(address payable _to, uint256 _tokenId) private view returns (bool) {
        return tokenIdToApproved[_tokenId] == _to;
    }

    function _transfer(address payable _from, address payable _to, uint256 _tokenId) private {
        if (sellingEnabled) {
            ownershipTokenCount[_to]++;
            tokenIdToOwner[_tokenId] = _to;

            if (_from != address(0)) {
                ownershipTokenCount[_from]--;
                delete tokenIdToApproved[_tokenId];
            }

            emit Transfer(_from, _to, _tokenId);
        }
    }

    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getAllBirdosForSale() public view returns (
        uint256[] memory,
        uint256[] memory,
        address[] memory
    ) {
        uint256 total = totalSupply();
        uint256[] memory tokenIds = new uint256[](total);
        uint256[] memory prices = new uint256[](total);
        address[] memory owners = new address[](total);

        for (uint256 i = 0; i < total; i++) {
            tokenIds[i] = i;
            prices[i] = priceOf(i);
            owners[i] = tokenIdToOwner[i];
        }

        return (tokenIds, prices, owners);
    }

    struct Offer {
        address payable buyer;
        uint256 price;
    }

    mapping (uint256 => Offer) private tokenIdToOffer;

    function makeOffer(uint256 _tokenId, uint256 _price) public payable {
        if (sellingEnabled) {
            require(msg.sender != address(0));
            require(msg.sender != tokenIdToOwner[_tokenId]);
            require(_price >= tokenIdToPrice[_tokenId]);
            require(msg.value >= _price);

            if (tokenIdToOffer[_tokenId].price > 0) {
                require(_price > tokenIdToOffer[_tokenId].price);
            }


            Offer memory _offer = Offer({
                buyer: msg.sender,
                price: uint256(_price)
            });
            tokenIdToOffer[_tokenId] = _offer;
        }
    }

    function cancelOffer( uint256 _tokenId ) public {
        Offer memory offer = tokenIdToOffer[_tokenId];

        require(offer.buyer == msg.sender);

        (offer.buyer).transfer(offer.price);

        delete tokenIdToOffer[_tokenId];
    }

    function acceptOffer(uint256 _tokenId, address payable _owner) public {
        if (sellingEnabled) {
            require(_owner == msg.sender);
            require(tokenIdToOwner[_tokenId] == msg.sender);

            Offer memory offer = tokenIdToOffer[_tokenId];
            uint256 price = offer.price;

            uint256 contractCut = price.mul(25).div(1000);

            tokenIdToOwner[_tokenId].transfer(offer.price.sub(contractCut));
            _transfer(_owner, offer.buyer, _tokenId);
            delete tokenIdToOffer[_tokenId];
        }
    }

    function getAllOffers() public view returns (
        uint256[] memory
    ) {
        uint256 total = totalSupply();
        uint256[] memory prices = new uint256[](total);

        for (uint256 i = 0; i < total; i++) {
            prices[i] = tokenIdToOffer[i].price;
        }

        return (prices);
    }



}

pragma solidity >=0.5.0 <0.6.0;

library Strings {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint j = 0; j < _bb.length; j++) babcde[k++] = _bb[j];
      for (uint ii = 0; ii < _bc.length; ii++) babcde[k++] = _bc[ii];
      for (uint ij = 0; ij < _bd.length; ij++) babcde[k++] = _bd[ij];
      for (uint jj = 0; jj < _be.length; jj++) babcde[k++] = _be[jj];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity >=0.5.0 <0.6.0;

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.5.0 <0.6.0;

import './Strings.sol';

/**
 * Interface for required functionality in the ERC721 standard
 * for non-fungible tokens.
 *
 * Author: Nadav Hollander (nadav at dharma.io)
 * https://github.com/dharmaprotocol/NonFungibleToken/blob/master/contracts/ERC721.sol
 */
contract ERC721 {

    using Strings for string;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /// For querying totalSupply of token.
    function totalSupply() public view returns (uint256 _totalSupply);

    /// For querying balance of a particular account.
    /// @param _owner The address for balance query.
    /// @dev Required for ERC-721 compliance.
    function balanceOf(address payable _owner) public view returns (uint256 _balance);

    /// For querying owner of token.
    /// @param _tokenId The tokenID for owner inquiry.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId) public view returns (address payable _owner);

    /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom()
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(address payable _to, uint256 _tokenId) public;

    // NOT IMPLEMENTED
    // function getApproved(uint256 _tokenId) public view returns (address _approved);

    /// Third-party initiates transfer of token from address _from to address _to.
    /// @param _from The address for the token to be transferred from.
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(address payable _from, address payable _to, uint256 _tokenId) public;

    /// Owner initates the transfer of the token to another account.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the token to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(address payable _to, uint256 _tokenId) public;

    ///
    function implementsERC721() public view returns (bool _implementsERC721);

    // EXTRA
    /// @notice Allow pre-approved user to take ownership of a token.
    /// @param _tokenId The ID of the token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _tokenId) public;

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }

    string public baseURI = "https://us-central1-crypto-birdos.cloudfunctions.net/metadata?id=";

    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    function setBaseTokenURI(string memory newURI) public returns (string memory) {
        baseURI = newURI;
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return Strings.strConcat(baseTokenURI(),Strings.uint2str(_tokenId));
    }

}

pragma solidity >=0.5.0 <0.6.0;


// inspired by
// https://github.com/axiomzen/cryptokitties-bounty/blob/master/contracts/KittyAccessControl.sol
contract AccessControl {
    /// @dev The addresses of the accounts (or contracts) that can execute actions within each roles
    address payable public ceoAddress;
    address payable public cooAddress;

    /// @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev The AccessControl constructor sets the original C roles of the contract to the sender account
    constructor() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Access modifier for any CLevel functionality
    modifier onlyCLevel() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO
    /// @param _newCEO The address of the new CEO
    function setCEO(address payable _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO
    /// @param _newCOO The address of the new COO
    function setCOO(address payable _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Pause the smart contract. Only can be called by the CEO
    function pause() public onlyCEO whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Only can be called by the CEO
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}