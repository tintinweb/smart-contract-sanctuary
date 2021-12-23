//SourceUnit: HKT_Exchange_Card.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface HKT721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function cardIdMap(uint tokenId) external view returns (uint256 cardId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function mint(address player_, uint cardId_, bool uriInTokenId_) external returns (uint256);
}

interface routers {
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory);
}

interface HKT_Mining {
    function getTokenPrice(address addr_) external view returns (uint);

    function U() external view returns (address);

    function NFT() external view returns (address);
}

contract HKT_Exhcange_Card is Ownable {
    uint public cardPrice = 30e18;
    HKT721 public NFT;
    mapping(address => bool) public cardList;
    uint public catId = 1000;
    address public wallet;
    HKT_Mining public main;

    function setAddress(address main_) external onlyOwner {
        main = HKT_Mining(main_);
        NFT = HKT721(main.NFT());
    }

    function setCardPrice(uint price) public onlyOwner {
        cardPrice = price;
    }

    function setWallet(address addr_) public onlyOwner {
        wallet = addr_;
    }

    function editCard(address token, bool com) public onlyOwner {
        cardList[token] = com;
    }

    function getTokenPrice(address token) public view returns (uint){
        return main.getTokenPrice(token);
    }

    function coutingTokenNeed(address token) public view returns (uint){
        uint price = getTokenPrice(token);
        uint dec = IERC20(token).decimals();
        uint out = cardPrice * 1e18 / (price * (10 ** (18 - dec)));
        return out;
    }

    function buyCard(address token, uint amount_, address recipient) public {
        require(cardList[token], 'wrong token');
        uint need = coutingTokenNeed(token);
        IERC20(token).transferFrom(msg.sender, wallet, need * amount_);
        for (uint i = 0; i < amount_; i++) {
            NFT.mint(recipient, catId, false);
        }

    }

    function setCatId(uint catId_) public onlyOwner {
        catId = catId_;
    }

    function safePull(address token_, address wallet_, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet_, amount_);
    }


}