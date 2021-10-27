// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(_msgSender());
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
  function balanceOf(address owner) external view returns (uint256 balance);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId) external view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

interface FIATContract {
  function getToken2Fiat(string memory __symbol) external view returns (string memory _symbolToken, uint256 _token2JPY);
}

contract BuyNFT is Ownable {
  event SetFiat(string[] _symbols, address[] _address, address _from);
  event _setPrice(address _game, uint256[] _tokenIds, uint256 _Price, uint8 _type);
  event _resetPrice(address _game, uint256 _orderId);
  using SafeMath for uint256;

  // Struct
  struct Token {
    string symbol;
    bool existed;
  }

  address[] public fiat = [
    address(0), // MATIC
    address(0x6edFA332F68B2ED045fe0e045554CeD910253784) // Fanyyanyy
  ];
  mapping(address => Token) public tokensFiat;

  struct GameFee {
    string fee;
    address taker;
    uint256 percent;
    bool existed;
  }

  struct Price {
    uint256[] tokenIds;
    address maker;
    uint256 Price2JPY;
    address[] fiat;
    address buyByFiat;
    bool isBuy;
  }

  struct Game {
    uint256 fee;
    uint256 limitFee;
    uint256 creatorFee;
    uint256[] tokenIdSale;
    mapping(uint256 => Price) tokenPrice;
    GameFee[] arrFees;
    mapping(string => GameFee) fees;
  }

  address[] public arrGames;
  mapping(address => Game) public Games;

  // Contract
  address public BuyNFTSub = address(0x0000000000000000000000000000000000000000);
  address payable public ceoAddress = payable(0x64470E5F5DD38e497194BbcAF8Daa7CA578926F6);
  uint256 public Percen = 1000;
  FIATContract public fiatContract;

  modifier onlyCeoAddress() {
    require(msg.sender == ceoAddress, "BuyNFT: caller is not CEO");
    _;
  }

  modifier onlySub() {
    require(msg.sender == BuyNFTSub, "BuyNFT: caller is not BuyNFTSub");
    _;
  }

  constructor() {
    tokensFiat[address(0)] = Token("MATIC", true);
    tokensFiat[address(0x6edFA332F68B2ED045fe0e045554CeD910253784)] = Token("F", true);
    fiatContract = FIATContract(0xefc20b5d721836E55f56131D30198d20FdfD6D12);
  }

  receive() external payable {}

  function checkIsOwnerOf(address _game, uint256[] memory _tokenIds) public view returns (bool) {
    bool flag = true;
    IERC721 erc721Address = IERC721(_game);
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      if (erc721Address.ownerOf(_tokenIds[i]) != msg.sender) flag = false;
    }
    return flag;
  }

  modifier isOwnerOf(address _game, uint256[] memory _tokenIds) {
    require(checkIsOwnerOf(_game, _tokenIds), "BuyNFT: caller is not CEO");
    _;
  }

  modifier isValidFiat(address[] memory _fiat) {
    require(_fiat.length > 0, "BuyNFT: Invalid fiat length");
    bool isValid = true;
    for (uint256 i = 0; i < _fiat.length; i++) {
      bool isExist = tokensFiat[_fiat[i]].existed;
      if (!isExist) {
        isValid = false;
        break;
      }
    }
    require(isValid, "BuyNFT: Invalid buy fiat");
    _;
  }

  function setFiat(string[] memory _symbols, address[] memory addresses) public onlyOwner {
    for (uint256 i = 0; i < _symbols.length; i++) {
      tokensFiat[addresses[i]].symbol = _symbols[i];
      if (!tokensFiat[addresses[i]].existed) {
        fiat.push(addresses[i]);
        tokensFiat[addresses[i]].existed = true;
      }
    }
    emit SetFiat(_symbols, addresses, msg.sender);
  }

  function getTokensFiat(address _fiat) public view returns (string memory _symbol, bool _existed) {
    return (tokensFiat[_fiat].symbol, tokensFiat[_fiat].existed);
  }

  function getFiat() public view returns (address[] memory) {
    return fiat;
  }

  function setBuyNFTSub(address _sub) public onlyOwner {
    BuyNFTSub = _sub;
  }

  function price2wei(uint256 _price, address _fiatBuy) public view returns (uint256) {
    uint256 weitoken;
    (, weitoken) = fiatContract.getToken2Fiat(tokensFiat[_fiatBuy].symbol);
    return _price.mul(weitoken).div(1 ether);
  }

  function tokenId2wei(
    address _game,
    uint256 _orderId,
    address _fiatBuy
  ) public view returns (uint256) {
    uint256 weitoken;
    uint256 _price = Games[_game].tokenPrice[_orderId].Price2JPY;
    (, weitoken) = fiatContract.getToken2Fiat(tokensFiat[_fiatBuy].symbol);
    return _price.mul(weitoken).div(1 ether);
  }

  function setFiatContract(address _fiatContract) public onlyOwner {
    fiatContract = FIATContract(_fiatContract);
  }

  function getTokenPrice(address _game, uint256 _orderId)
    public
    view
    returns (
      address _maker,
      uint256[] memory _tokenIds,
      uint256 _Price2JPY,
      address[] memory _fiat,
      address _buyByFiat,
      bool _isBuy
    )
  {
    return (Games[_game].tokenPrice[_orderId].maker, Games[_game].tokenPrice[_orderId].tokenIds, Games[_game].tokenPrice[_orderId].Price2JPY, Games[_game].tokenPrice[_orderId].fiat, Games[_game].tokenPrice[_orderId].buyByFiat, Games[_game].tokenPrice[_orderId].isBuy);
  }

  function getArrGames() public view returns (address[] memory) {
    return arrGames;
  }

  function ownerOf(address _game, uint256 _tokenId) public view returns (address) {
    IERC721 erc721Address = IERC721(_game);
    return erc721Address.ownerOf(_tokenId);
  }

  function balanceOf() public view returns (uint256) {
    return address(this).balance;
  }

  function updateArrGames(address _game) internal {
    bool flag = false;
    for (uint256 i = 0; i < arrGames.length; i++) {
      if (arrGames[i] == _game) {
        flag = true;
        break;
      }
    }
    if (!flag) arrGames.push(_game);
  }

  function setPrice(
    uint256 _orderId,
    address _game,
    uint256[] memory _tokenIds,
    uint256 _price,
    address[] memory _fiat
  ) internal {
    require(Games[_game].tokenPrice[_orderId].maker == address(0) || Games[_game].tokenPrice[_orderId].maker == msg.sender, "BuyNFT: caller is not Maker");
    Games[_game].tokenPrice[_orderId] = Price(_tokenIds, msg.sender, _price, _fiat, address(0), false);
    Games[_game].tokenIdSale.push(_orderId);
    updateArrGames(_game);
  }

  function calFee(
    address _game,
    string memory _fee,
    uint256 _price
  ) public view returns (uint256) {
    uint256 amount = _price.mul(Games[_game].fees[_fee].percent).div(Percen);
    return amount;
  }

  function calPrice(address _game, uint256 _orderId)
    public
    view
    returns (
      address _tokenOwner,
      uint256 _Price2JPY,
      address[] memory _fiat,
      address _buyByFiat,
      bool _isBuy
    )
  {
    return (Games[_game].tokenPrice[_orderId].maker, Games[_game].tokenPrice[_orderId].Price2JPY, Games[_game].tokenPrice[_orderId].fiat, Games[_game].tokenPrice[_orderId].buyByFiat, Games[_game].tokenPrice[_orderId].isBuy);
  }

  function setPriceFee(
    uint256 _orderId,
    address _game,
    uint256[] memory _tokenIds,
    uint256 _Price,
    address[] memory _fiat
  ) public isOwnerOf(_game, _tokenIds) isValidFiat(_fiat) {
    setPrice(_orderId, _game, _tokenIds, _Price, _fiat);
    emit _setPrice(_game, _tokenIds, _Price, 1);
  }

  function getGame(address _game)
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (Games[_game].fee, Games[_game].limitFee, Games[_game].creatorFee);
  }

  function getGameFees(address _game)
    public
    view
    returns (
      string[] memory,
      address[] memory,
      uint256[] memory,
      uint256
    )
  {
    uint256 length = Games[_game].arrFees.length;
    string[] memory fees = new string[](length);
    address[] memory takers = new address[](length);
    uint256[] memory percents = new uint256[](length);
    uint256 sumGamePercent = 0;
    for (uint256 i = 0; i < length; i++) {
      GameFee storage gameFee = Games[_game].arrFees[i];
      fees[i] = gameFee.fee;
      takers[i] = gameFee.taker;
      percents[i] = gameFee.percent;
      sumGamePercent += gameFee.percent;
    }

    return (fees, takers, percents, sumGamePercent);
  }

  function getGameFeePercent(address _game, string memory _fee) public view returns (uint256) {
    return Games[_game].fees[_fee].percent;
  }

  function setLimitFee(
    address _game,
    uint256 _fee,
    uint256 _limitFee,
    uint256 _creatorFee,
    string[] memory _gameFees,
    address[] memory _takers,
    uint256[] memory _percents
  ) public onlyOwner {
    require(_fee >= 0 && _limitFee >= 0, "BuyNFT: fee or litmit is 0");
    Games[_game].fee = _fee;
    Games[_game].limitFee = _limitFee;
    Games[_game].creatorFee = _creatorFee;

    for (uint256 i = 0; i < _gameFees.length; i++) {
      if (!Games[_game].fees[_gameFees[i]].existed) {
        GameFee memory newFee = GameFee({ fee: _gameFees[i], taker: _takers[i], percent: _percents[i], existed: true });
        Games[_game].fees[_gameFees[i]] = newFee;
        Games[_game].arrFees.push(newFee);
      } else {
        Games[_game].fees[_gameFees[i]].percent = _percents[i];
        Games[_game].fees[_gameFees[i]].taker = _takers[i];
        Games[_game].arrFees[i].percent = _percents[i];
        Games[_game].arrFees[i].taker = _takers[i];
      }
    }
    updateArrGames(_game);
  }

  function setLimitFeeAll(
    address[] memory _games,
    uint256[] memory _fees,
    uint256[] memory _limitFees,
    uint256[] memory _creatorFees,
    string[][] memory _gameFees,
    address[][] memory _takers,
    uint256[][] memory _percents
  ) public onlyOwner {
    require(_games.length == _fees.length, "Game and fees length miss match");
    for (uint256 i = 0; i < _games.length; i++) {
      setLimitFee(_games[i], _fees[i], _limitFees[i], _creatorFees[i], _gameFees[i], _takers[i], _percents[i]);
    }
  }

  function _withdraw(uint256 amount) internal {
    require(address(this).balance >= amount, "Insufficent balance to withdraw");
    if (amount > 0) {
      ceoAddress.transfer(amount);
    }
  }

  function withdraw(uint256 amount, address[] memory _tokens) public onlyOwner {
    _withdraw(amount);
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_tokens[i] != address(0)) {
        IERC20 erc20 = IERC20(_tokens[i]);
        uint256 erc20Balance = erc20.balanceOf(address(this));
        if (erc20Balance > 0) {
          erc20.transfer(ceoAddress, erc20Balance);
        }
      }
    }
  }

  function cancelBussinessByGameId(address _game, uint256 _tokenId) private {
    IERC721 erc721Address = IERC721(_game);
    if (Games[_game].tokenPrice[_tokenId].maker == erc721Address.ownerOf(_tokenId)) {
      resetPrice(_game, _tokenId);
    }
  }

  function cancelBussinessByGame(address _game) private {
    uint256[] memory _arrTokenId = Games[_game].tokenIdSale;
    for (uint256 i = 0; i < _arrTokenId.length; i++) {
      cancelBussinessByGameId(_game, _arrTokenId[i]);
    }
  }

  function cancelBussiness() public onlyOwner {
    for (uint256 j = 0; j < arrGames.length; j++) {
      address _game = arrGames[j];
      cancelBussinessByGame(_game);
    }
    withdraw(address(this).balance, fiat);
  }

  function changeCeo(address payable _address) public onlyCeoAddress {
    require(_address != address(0), "New CEO is zero address");
    ceoAddress = _address;
  }

  // Move the last element to the deleted spot.
  // Delete the last element, then correct the length.
  function _burnArrayTokenIdSale(address _game, uint256 index) internal {
    if (index >= Games[_game].tokenIdSale.length) return;

    for (uint256 i = index; i < Games[_game].tokenIdSale.length - 1; i++) {
      Games[_game].tokenIdSale[i] = Games[_game].tokenIdSale[i + 1];
    }
    delete Games[_game].tokenIdSale[Games[_game].tokenIdSale.length - 1];
    Games[_game].tokenIdSale.pop();
  }

  function removePrice(address _game, uint256 _orderId) public {
    require(msg.sender == Games[_game].tokenPrice[_orderId].maker, "Caller is not the maker");
    resetPrice(_game, _orderId);
  }

  function resetPrice(address _game, uint256 _orderId) internal {
    Price storage _price = Games[_game].tokenPrice[_orderId];
    _price.maker = address(0);
    _price.Price2JPY = 0;
    _price.buyByFiat = address(0);
    _price.isBuy = false;
    for (uint8 i = 0; i < Games[_game].tokenIdSale.length; i++) {
      if (Games[_game].tokenIdSale[i] == _orderId) {
        _burnArrayTokenIdSale(_game, i);
      }
    }
    emit _resetPrice(_game, _orderId);
  }

  function resetPrice4sub(address _game, uint256 _tokenId) public onlySub {
    resetPrice(_game, _tokenId);
  }
}