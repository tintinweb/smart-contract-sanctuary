/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

  function metadata(uint256 tokenId) external view returns (address creator);
}


interface BuyNFT {
    function tokensFiat(address token) external view returns (string memory symbol, bool existed);

    function tokenId2wei(
        address _game,
        uint256 _tokenId,
        address _fiatBuy
    ) external view returns (uint256);

    function Games(address _game)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getGame(address _game)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getGameFees(address _game)
        external
        view
        returns (
            string[] memory,
            address[] memory,
            uint256[] memory,
            uint256
        );

    function getGameFeePercent(address _game, string memory _fee) external view returns (uint256);

    function getTokensFiat(address _fiat) external view returns (string memory _symbol, bool _existed);

    function Percen() external view returns (uint256);

    function resetPrice4sub(address _game, uint256 _tokenId) external;

    function ceoAddress() external view returns (address);

    function fiatContract() external view returns (address);

    function getTokenPrice(address _game, uint256 _orderId)
        external
        view
        returns (
            address _maker,
            uint256[] memory _tokenIds,
            uint256 _Price2JPY,
            address[] memory _fiat,
            address _buyByFiat,
            bool _isBuy
        );
}

interface FIATContract {
  function getToken2Fiat(string memory __symbol) external view returns (string memory _symbolToken, uint256 _token2JPY);
}

contract BuyNFTSub is Ownable {
    using SafeMath for uint256;
    address private buynftAddress = address(0x55ea4d2F77d1ebc87aa7eaA43b8C3181f03ef745);
    BuyNFT public buynft = BuyNFT(buynftAddress);

    modifier isValidFiatBuy(address _fiat) {
        bool existed;
        (, existed) = buynft.getTokensFiat(_fiat);
        require(existed, "Invalid buy fit");
        _;
    }

    function setBuyNFT(address _buyNFT) public onlyOwner {
        buynftAddress = _buyNFT;
        buynft = BuyNFT(buynftAddress);
    }

    function tobuySub2(
        address _game,
        address _fiatBuy,
        uint256 weiPrice
    ) internal {
        address[] memory takers;
        uint256[] memory percents;
        (, takers, percents, ) = buynft.getGameFees(_game);
        for (uint256 i = 0; i < takers.length; i++) {
            uint256 gameProfit = (weiPrice.mul(percents[i])).div(buynft.Percen());
            if (_fiatBuy == address(0)) {
                payable(takers[i]).transfer(gameProfit);
            } else {
                IERC20 erc20 = IERC20(_fiatBuy);
                erc20.transfer(takers[i], gameProfit);
            }
        }
    }

    function tobuySub(
        address _game,
        address _fiatBuy,
        uint256 weiPrice,
        address payable _maker,
        uint256 ownerProfit,
        uint256 businessProfit,
        uint256 creatorProfit,
        uint256 tokenId
    ) internal {
        IERC721 erc721Address = IERC721(_game);
        address payable ceo = payable(buynft.ceoAddress());

        if (_fiatBuy == address(0)) {
            require(weiPrice <= msg.value, "BuyNFTSub: Insufficent MATIC!");
            if (ownerProfit > 0) _maker.transfer(ownerProfit);
            if (businessProfit > 0) ceo.transfer(businessProfit);
            if (creatorProfit > 0) {
                address payable creator;
                (creator) = payable(erc721Address.metadata(tokenId));
                creator.transfer(creatorProfit);
            }
        } else {
            IERC20 trc21 = IERC20(_fiatBuy);
            require(trc21.transferFrom(msg.sender, address(this), weiPrice), "BuyNFTSub: Insufficent buy token!");
            if (ownerProfit > 0) trc21.transfer(_maker, ownerProfit);
            if (businessProfit > 0) trc21.transfer(ceo, businessProfit);
            if (creatorProfit > 0) {
                address creatorr;
                (creatorr) = erc721Address.metadata(tokenId);
                trc21.transfer(creatorr, creatorProfit);
            }
        }
    }

    function calBusinessFee(
        address _game,
        string memory _symbolFiatBuy,
        uint256 weiPrice
    ) public view returns (uint256 _businessProfit, uint256 _creatorProfit) {
        uint256 Fee;
        uint256 limitFee;
        uint256 CreatorFee;
        (Fee, limitFee, CreatorFee) = buynft.Games(_game);
        uint256 businessProfit = (weiPrice.mul(Fee)).div(buynft.Percen());
        FIATContract fiatCT = FIATContract(buynft.fiatContract());
        uint256 tokenOnJPY;
        (, tokenOnJPY) = fiatCT.getToken2Fiat(_symbolFiatBuy);
        uint256 limitFee2Token = (tokenOnJPY.mul(limitFee)).div(1 ether);
        if (weiPrice > 0 && businessProfit < limitFee2Token) businessProfit = limitFee2Token;
        uint256 creatorProfit = (weiPrice.mul(CreatorFee)).div(buynft.Percen());
        return (businessProfit, creatorProfit);
    }

    function tobuy(
        address _game,
        uint256 _orderId,
        address _fiatBuy,
        string memory _symbolFiatBuy,
        address payable _maker,
        uint256 tokenId
    ) internal {
        uint256 weiPrice = buynft.tokenId2wei(_game, _orderId, _fiatBuy);
        uint256 businessProfit;
        uint256 creatorProfit;
        uint256 sumGamePercent;
        (businessProfit, creatorProfit) = calBusinessFee(_game, _symbolFiatBuy, weiPrice);
        (, , , sumGamePercent) = buynft.getGameFees(_game);
        uint256 sumGameProfit = (weiPrice.mul(sumGamePercent)).div(buynft.Percen());
        uint256 ownerProfit = (weiPrice.sub(businessProfit)).sub(creatorProfit).sub(sumGameProfit);

        tobuySub(_game, _fiatBuy, weiPrice, _maker, ownerProfit, businessProfit, creatorProfit, tokenId);
        tobuySub2(_game, _fiatBuy, weiPrice);
    }

    function buy(
        address _game,
        uint256 _orderId,
        address _fiatBuy,
        string memory _symbolFiatBuy
    ) public payable isValidFiatBuy(_fiatBuy) {
        // address[] _fiat luon luon truyen empty .
        address _maker;
        uint256[] memory _tokenIds;
        (_maker, _tokenIds, , , , ) = buynft.getTokenPrice(_game, _orderId);
        IERC721 erc721Address = IERC721(_game);
        require(erc721Address.isApprovedForAll(_maker, address(this)), "BuyNFTSub: User is not approveForAll");
        tobuy(_game, _orderId, _fiatBuy, _symbolFiatBuy, payable(_maker), _tokenIds[0]);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            erc721Address.transferFrom(_maker, msg.sender, _tokenIds[i]);
        }

        buynft.resetPrice4sub(_game, _orderId);
    }
}