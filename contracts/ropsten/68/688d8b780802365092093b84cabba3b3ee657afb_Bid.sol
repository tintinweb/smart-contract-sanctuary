/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// contracts/Bid.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;


contract Owned{
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

interface AggregateApiI{
    function getPostUrl(string calldata _url, string calldata _postParam)  payable external returns (bytes32 _id);
}

interface ERC721{
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Bid is Owned{

    address public aggregateAddr;           //预言机合约地址
    address private oracleCallbackAddr;     //预言机回调合约地址
    uint256 public oraclePrice;             //预言机单次调用价格
    string public bidURL;                   //链下价格验证URL

    struct RequestData{                     //请求预言机数据结构体
        address tokenContractAddr;
        address tokenIdOfOwner;
        address bidSender;
        uint256 tokenId;
        uint256 bidAmount;
        bool status;
    }

    mapping (bytes32 => RequestData) public requestIdToData;    //请求预言机数据存储

    event LogRequest(bytes32 _requestId, address indexed addr, uint256 tokenId, uint256 bidAmount);                                 //请求预言机日志
    event LogCallBack(bytes32 requestId, address contractAddr, address from, uint256 num, address to, string price,bool success);   //预言机回调日志

    // 构造函数
    constructor () public {}

    // 预言机回调
    function __callback(bytes32 _requestId, string memory _result, bool _success) public{
        require(msg.sender == oracleCallbackAddr);
        RequestData storage _requestData = requestIdToData[_requestId];
        require(_requestData.status);
        _requestData.status = false;

        uint256 _amount = safeParseInt(_result, 0);
        require(_amount == _requestData.bidAmount);
        address payable seller = address(uint160(_requestData.tokenIdOfOwner));
        address payable bidSender = address(uint160(_requestData.bidSender));
        ERC721 candidateContract = ERC721(_requestData.tokenContractAddr);
        if(_amount == _requestData.bidAmount){
            candidateContract.safeTransferFrom(seller, _requestData.bidSender, _requestData.tokenId, abi.encodePacked(_amount));
            seller.transfer(_amount);
        }else{
            bidSender.transfer(_requestData.bidAmount);   
        }
        emit LogCallBack(_requestId, _requestData.tokenContractAddr, seller, _amount, bidSender, _result, _success);
    }

    //  买方发起购买操作
    function bid(address tokenContractAddr, address tokenIdOfOwner, uint256 tokenId, uint256 bidAmount) payable public returns (bool){
        require(msg.value == oraclePrice + bidAmount);
        require(ERC721(tokenContractAddr).ownerOf(tokenId) == tokenIdOfOwner);
        string memory _postParam = string(abi.encodePacked('{"address": "', toString(abi.encodePacked(tokenIdOfOwner)), '","id": "',uint2str(tokenId), '","price": "', uint2str(bidAmount),'"}'));
        _requestURL(tokenContractAddr, tokenIdOfOwner, msg.sender, tokenId, bidAmount, bidURL, _postParam);
        return true;
    }

    //  请求预言机操作
    function _requestURL(address tokenContractAddr,address tokenIdOfOwner,address bidSender, uint256 tokenId, uint256 bidAmount, string memory apiURL, string memory postParam) private returns(bytes32 _id) {
        AggregateApiI aggregate = AggregateApiI(aggregateAddr);
        _id = aggregate.getPostUrl{value: oraclePrice}(apiURL, postParam);
        RequestData memory _requestData = RequestData(tokenContractAddr, tokenIdOfOwner, bidSender, tokenId, bidAmount, true);
        requestIdToData[_id] = _requestData;
        emit LogRequest(_id, bidSender, tokenId, bidAmount);
    }

    // 配置参数
    function setConfig(address _aggregateAddr, address _oracleCallbackAddr, uint256 _oraclePrice, string memory _bidURL) public onlyOwner{
        aggregateAddr = _aggregateAddr;
        oracleCallbackAddr = _oracleCallbackAddr;
        oraclePrice = _oraclePrice;
        bidURL = _bidURL;
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

    // 合约余额提取
    function withdrawBalance(address cfoAddr) external onlyOwner {
        uint256 balance = address(this).balance;
        address payable _cfoAddr = address(uint160(cfoAddr));
        _cfoAddr.transfer(balance);
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