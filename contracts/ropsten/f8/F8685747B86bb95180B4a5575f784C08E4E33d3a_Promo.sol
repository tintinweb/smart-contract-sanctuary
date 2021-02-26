/**
 *Submitted for verification at Etherscan.io on 2021-02-26
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
    function mintTicket(address from, MintType NFTType, address referrer, uint256 quota) external returns(uint256 _newTokenId);
    function ticketCardInfo(uint256 tokenId) external view returns (address referrer, uint256 quota, MintType tokenType, address promo);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function createPromoCharge(address promo, uint256 num) payable external returns (uint256);
    function setPromoOfTokenId(uint256 tokenId, address promo) external;
    function setQuotaOfTokenId(uint256 tokenId, uint256 quota) external;
    function PromoCallback(uint256 tokenId, uint256 quota, uint256 promoPrice) external;
}

interface AggregateApiI{
    function getPostUrl(string calldata _url, string calldata _postParam)  payable external returns (bytes32 _id);
}

contract Promo is Owned{
    uint256 public promoPrice;              //合伙人分销单价 * 10**8
    address private oracleCallbackAddr;     //预言机回调地址
    uint256 public oraclePrice;             //预言机单次调用价格
    AggregateApiI public aggregate;         //预言机合约
    ERC721 public ticketContract;           //门票合约
    string private _promoUrl;               //推广获取额度URL
    
    struct RequestData{                     //请求预言机数据结构体
        address userAddr;
        address middle;
        uint256 tokenId;
        uint256 price;
    }
    
    mapping (string => uint256) public tokenIdOfCode;              // tokenId of code
    mapping (bytes32 => RequestData) public requestIdToData;        //请求预言机数据存储
    mapping(address => bool) public isPromo;                        //是否是合伙人
    mapping(address => bool) public isMiddle;                        //是否是代理人
    
    event LogRequest(bytes32 _requestId, address indexed addr, uint256 num, uint256 price, bytes data);             //请求预言机日志
    event LogCallBack(bytes32 requestId, address owner, uint256 num, uint256 mPrice,string price,bool success);                    //预言机回调日志
    event LogMiddleCharge(address indexed promo, address indexed middle, uint256 num);                              //代理人购买日志
    
    // 预言机回调
    function __callback(bytes32 _requestId, string memory _result, bool _success) public{
        require(msg.sender == oracleCallbackAddr || msg.sender == owner);
        RequestData storage _requestData = requestIdToData[_requestId];

        uint256 _amount = safeParseInt(_result, 0);
        uint256 id = _requestData.tokenId;
        uint256 price = _requestData.price;
        address ownerAddr = _requestData.userAddr;
        if(_amount != 0){
            address payable _middleAddr = address(uint160(_requestData.middle));
            _middleAddr.transfer(price);
            ticketContract.setQuotaOfTokenId(id, _amount * 0.01 ether);
        }else{
            address payable _ownerAddr = address(uint160(ownerAddr));
            _ownerAddr.transfer(price);
        }
        emit LogCallBack(_requestId, ownerAddr, _amount, price, _result, _success);
    }
    
    // 合伙人认领
    function createPromoCharge(uint256 num) payable public returns (uint256) {
        require(msg.value == promoPrice * num / 5);
        ticketContract.createPromoCharge{value: msg.value}(msg.sender, num);
        isPromo[msg.sender] = true;
        return num;
    }
    
    // 代理人购买门票
    function createMiddleCharge(address promo, uint256 num) payable public returns (uint256) {
        require(msg.value == promoPrice * num);
        require(isPromo[promo]);
        
        address payable _promoAddr = address(uint160(promo));
        _promoAddr.transfer(msg.value / 10);
        ticketContract.createPromoCharge{value: msg.value * 9 / 10}(msg.sender, num);
        isMiddle[msg.sender] = true;
        emit LogMiddleCharge(promo, msg.sender, num);
        return num;
    }

    // 普通用户想向代理人购买门票，生成分销类门票
    function createPromoCard(address to, address promo, address middle, uint256 mPrice, string memory code) payable public returns (uint256 _newTokenId, bytes32 _id){
        require(msg.value == oraclePrice + mPrice);
        require(isPromo[promo]);
        require(isMiddle[middle]);
        
        _newTokenId = ticketContract.mintTicket(to, ERC721.MintType.PromoNFT, middle, 0);
        ticketContract.setPromoOfTokenId(_newTokenId, promo);
        tokenIdOfCode[code] = _newTokenId;

        string memory _postParam = string(abi.encodePacked('{"md": "', toString(abi.encodePacked(promo)), toString(abi.encodePacked(middle)), code, toString(abi.encodePacked(to)), uint2str(mPrice), '"}'));

        _id = _requestURL(to, middle, mPrice,_promoUrl, _postParam, _newTokenId, "");
    }

    // 请求预言机方法
    function _requestURL(address from, address middle, uint256 mPrice, string memory apiURL, string memory postParam, uint256 tokenId, bytes memory extraData) private returns(bytes32 _id) {
        _id = aggregate.getPostUrl{value: oraclePrice}(apiURL, postParam);
        requestIdToData[_id] =  RequestData(from, middle, tokenId, mPrice);
        emit LogRequest(_id, from, tokenId, oraclePrice, extraData);
    }

    // 配置预言机、门票、预言机回调地址
    function setAddr(address _aggregateAddr, address _ticketContract, address _oracleCallbackAddr) public onlyOwner {
        aggregate = AggregateApiI(_aggregateAddr);
        ticketContract = ERC721(_ticketContract);
        oracleCallbackAddr = _oracleCallbackAddr;
    }
    
    // 配置链下数据URL
    function setAPIBaseUrl(string memory __promoUrl) public onlyOwner {
        _promoUrl = __promoUrl;
    }

    // 配置代理人购买单价
    function setPromoPrice(uint _promoPrice) public onlyOwner {
        promoPrice = _promoPrice;
    }

    // 配置预言机价格
    function setOraclePrice(uint _price) public onlyOwner {
        oraclePrice = _price;
    }
    
    // 合约余额提取
    function withdrawBalance(address cfoAddr) external onlyOwner {
        uint256 balance = address(this).balance;
        address payable _cfoAddr = address(uint160(cfoAddr));
        _cfoAddr.transfer(balance);
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