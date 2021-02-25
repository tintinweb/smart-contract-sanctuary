/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// contracts/Promo.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface ERC721{
    enum MintType { AirdropNFT, RaffleNFT, PromoNFT }
    function mintTicketPayable(address from, MintType NFTType, address referrer, uint256 quota) external payable returns(uint256 _newTokenId);
    function ticketCardInfo(uint256 tokenId) external view returns (address referrer, uint256 quota, MintType tokenType, address promo);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function createPromoCharge(address promo, uint256 num) payable external returns (uint256);
    function setPromoOfTokenId(uint256 tokenId, address promo) external;
    function PromoCallback(uint256 tokenId, uint256 quota, uint256 promoPrice) external;
}

interface CodeOfPromo{
    function isPromoCode(bytes32 code, uint256 index) external view returns(bool b);
    function setPromoInfo(address promo, uint256 num) external returns(bool);
}

contract Promo is Owned{
    uint256 public promoPrice;                                  //合伙人分销单价 * 10**8
    
    mapping (bytes32 => uint256) public tokenIdOfCode;           // tokenId of code
    mapping(address => bool) public isPromo;                    //是否是合伙人
    mapping(address => uint256) public totalOfPromoCharge;       //合伙人认领总数

    
    mapping(address => bool) public isPromoCodeAddr;                //code合约地址
    
    // 合伙人认领
    function createPromoCharge(uint256 num, ERC721 ticketContract, CodeOfPromo promoCodeAddr) payable public returns (uint256) {
        require(msg.value == promoPrice * num / 5);
        ticketContract.createPromoCharge{value: msg.value}(msg.sender, num);
        isPromo[msg.sender] = true;
        totalOfPromoCharge[msg.sender] = totalOfPromoCharge[msg.sender] + num;
        promoCodeAddr.setPromoInfo(msg.sender, num);
        return num;
    }

    // 代理人购买门票，生成分销类门票
    function createPromoCard(address to, address promo, bytes32 code, uint256 index, ERC721 ticketContract, CodeOfPromo promoCodeAddr) payable public returns (uint256 _newTokenId){
        require(msg.value == promoPrice);
        require(isPromoCodeAddr[address(promoCodeAddr)]);
        require(promoCodeAddr.isPromoCode(code, index));
        require(isPromo[promo]);
        
        _newTokenId = ticketContract.mintTicketPayable{value: promoPrice}(to, ERC721.MintType.PromoNFT, promo, 1 ether);
        ticketContract.setPromoOfTokenId(_newTokenId, promo);
        tokenIdOfCode[code] = _newTokenId;
    }

    // 配置代理人购买单价
    function setPromoPrice(uint _promoPrice) public onlyOwner {
        promoPrice = _promoPrice;
    }
    
    // 配置代理人购买单价
    function setPromoCodeAddr(address _codeAddr, bool approved) public onlyOwner {
        isPromoCodeAddr[_codeAddr] = approved;
    }
    
    // string转uint
    function safeParseInt(string memory _a, uint _b) public pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    // bytes转String
    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    // uint转string
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