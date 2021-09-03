/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-05-20
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: UNLICENSED
interface IaddressController {
    function isManager(address _mAddr) external view returns(bool);
    function isMarket(address _mAddr) external view returns(bool);
    function getAddr(string calldata _name) external view returns(address);
}

interface IBrand{
    function getBrand(uint256 _bID) external view returns(string memory _description,address _feeToken,uint256 _fee,bool _isRegester );
}

interface IAuthor{
    function getAuthor(address _author) external view returns(bool _isAuthor,string memory _url,string  memory _name,string memory _introduction);
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract Commodity{
    IaddressController public addrc;
    
    
    mapping(uint256 => mapping(uint256 => bool)) public cid_sid_saleFlage; // this cid ->serial number -> tokenID;
    mapping(uint256 => mapping(uint256 => uint256)) public cid_sid_tokenID; // this cid ->serial number -> tokenID;
    mapping(uint256 => mapping(uint256 => uint256)) public cid_tokenID_sid; // this cid ->serial number -> tokenID;
    mapping(uint256 => uint256[]) public cid_tokenList;
    mapping(uint256 => Commodity_S) public commodity;
    
    bool public isOpen;
    
    event CreateCommodity(
        uint256 _aid,
        uint256 _bID,
        string _name,
        address _author,
        string  _pDescription,
        string  _url,
        string[] _cAttributeS,
        uint256[] _cAttributeU,
        uint256 _totalSupply,
        uint256 _authorFeeRate);
    
    event CommidityStateChange(uint256 _aid,uint256 _cstate);
    
    //address 
    struct Commodity_S{
        uint256 bID;
        address author;
        string name;
        string  pDescription;
        string url;
        string[] cAttributeS; //1-2
        uint256[] cAttributeU;//3-6
        uint256 totalSupply;
        uint256 authorFeeRate; // this is rate if 1%, this value is 100, 100/10000 = 1%
        uint8 cState;// 0:not regist,1 create,2 upsale, 3 already sale
    }
    
    constructor(IaddressController _addrc) public{
        addrc = _addrc;
        isOpen = false;
    }
    
    function createCommodity(
        uint256 _cid,
        uint256 _bID,
        address _author,
        string memory _name,
        string memory _pDescription,
        string  memory _url,
        string[] calldata _cAttributeS,
        uint256[] memory _cAttributeU,
        uint256 _totalSupply,
        uint256 _authorFeeRate) public  payable{
        require(addrc.isManager(msg.sender) || isOpen,"only manager or is open");
        require(_cid >= 1,"start 1 ");
        require(_authorFeeRate<=10000,"can not big then 10000");
        require(commodity[_cid].cState == 0,"alread create commodity");
        require(checkBrandAndAuthor(_bID,_author),"brand or author not regist");
        require(_totalSupply >0,"must big then zero totalsupply");
        require(_cAttributeS.length <= 2, "_cAttributeS length less than 3");
        require(_cAttributeU.length <= 4, "_cAttributeU length less than 5");

        payBrandFee(_bID);
        
        commodity[_cid].bID =_bID;
        commodity[_cid].author =_author;
        commodity[_cid].pDescription =_pDescription;
        commodity[_cid].url =_url;
        commodity[_cid].totalSupply =_totalSupply;
        commodity[_cid].authorFeeRate =_authorFeeRate;
        commodity[_cid].cState =1;

        for(uint256 i=0;i<_cAttributeS.length;i++){
            commodity[_cid].cAttributeS.push(_cAttributeS[i]);
        }
        for(uint256 j=0;j<_cAttributeU.length;j++){
            commodity[_cid].cAttributeU.push(_cAttributeU[j]);
        }
        emit CreateCommodity(
            _cid,
            _bID,
            _name,
            _author,
            _pDescription,
            _url,
            _cAttributeS,
            _cAttributeU,
            _totalSupply,
            _authorFeeRate
            );
        emit CommidityStateChange(_cid,commodity[_cid].cState);
    }
    
    
    function delCommodity(uint256 _cid) public {
        require(commodity[_cid].cState == 1,"commodity state not 1");
        require(addrc.isManager(msg.sender) || isOpen,"only manager or is open");
        commodity[_cid].cState = 0;
        uint256 lenS = commodity[_cid].cAttributeS.length;
        if(lenS>0){
            for(uint256 i=0;i<=lenS;i++){
                commodity[_cid].cAttributeS.pop();
                if(i == lenS-1){
                    break;
                }
            }
        }
        
        uint256 lenU = commodity[_cid].cAttributeU.length;
        if(lenU >0){
            for(uint256 j=0;j<=lenU;j++){
                commodity[_cid].cAttributeU.pop();
                if(j == lenU-1){
                    break;
                }
            }
        }
        
        emit CommidityStateChange(_cid,commodity[_cid].cState);
    }
    
    function setIsOpen(bool _isOpen) public onlyManager{
        isOpen = _isOpen;
    }
    
    function upsale(uint256 _cid) public onlyMarket{
        
        
        Commodity_S storage cs = commodity[_cid];
        require(cs.cState == 1,"  commodity state must 1");
        
        cs.cState = 2;
        emit CommidityStateChange(_cid,cs.cState);
    }
    
    function downSale(uint256 _cid) public onlyMarket {
        
        Commodity_S storage cs = commodity[_cid];
        require(cs.cState == 2,"commodity state not 2");
        cs.cState = 1;
    }
    
    
    function saleOne(uint256 _cid,uint256 _sid,uint256 _tokenID) public  onlyMarket{
        
        Commodity_S storage cs = commodity[_cid];
        require(cs.cState == 2 || cs.cState == 3," commodity id not state 2-3");
        require(!cid_sid_saleFlage[_cid][_sid],"this sid are saleed");
        require(_sid <= cs.totalSupply && _sid>=1 ,"sid big then totalSupply");
        cid_sid_saleFlage[_cid][_sid] = true;
        cid_sid_tokenID[_cid][_sid] = _tokenID;
        cid_tokenList[_cid].push(_tokenID);
        cid_tokenID_sid[_cid][_tokenID] = _sid; 
        cs.cState = 3;
        if(cs.cState == 2){
            emit CommidityStateChange(_cid,cs.cState);
        }
    }
    
    function getCommodityAttribute_S(uint256 _cid) public view returns(string[] memory _cAttributeS,uint256 _len){
        _len = commodity[_cid].cAttributeS.length;
        if(_len != 0 ){
            _cAttributeS = new string[](_len);
            for(uint256 i=0;i<_len;i++){
                _cAttributeS[i] = commodity[_cid].cAttributeS[i];
            }
            
        }
    }
    function getCommodityAttribute_U(uint256 _cid) public view returns(uint256[] memory _cAttributeU){
        _cAttributeU  = new uint256[](commodity[_cid].cAttributeU.length);
        for(uint256 j=0;j<commodity[_cid].cAttributeU.length;j++){
            _cAttributeU[j] = commodity[_cid].cAttributeU[j];
        }
    }
    
    function getUrlByCid(uint256 _cid) public view returns(string memory _url){
        _url = commodity[_cid].url;
    }
    
    function cidTokenListLength(uint256 _cid) public view returns(uint256){
        return cid_tokenList[_cid].length;
    }
    
    function getSaleInfo(uint256 _cid) public view returns(uint256 _totalSupply,uint256 _saleedAmount){
        if(commodity[_cid].cState == 0){
            return (_totalSupply,_saleedAmount);
        } 
        _totalSupply = commodity[_cid].totalSupply;
        _saleedAmount = cid_tokenList[_cid].length;
    }
    
    function canBuy(uint256 _cid) public view returns(bool){
        if(commodity[_cid].cState == 2 || commodity[_cid].cState == 3){
            return true;
        }else{
           return false;
        }
    }
    
    function getAuthorAndBrandByCid(uint256 _cid) public view returns(address _author,uint256 _bID){
        _author = commodity[_cid].author;
        _bID = commodity[_cid].bID;
    }
    
    function payBrandFee(uint256 _bID) internal {
        address brandAddr = nameAddr("BRAND");
        (,address _token,uint256 _fee,) = IBrand(brandAddr).getBrand(_bID);
        if(_fee >0){
            if(_token == address(1)){
                payable(nameAddr("FEETO")).transfer(_fee);
                if(address(this).balance > 0 ){
                    payable(msg.sender).transfer(address(this).balance);
                }
            }else{
                TransferHelper.safeTransferFrom(_token,msg.sender,nameAddr("FEETO"),_fee);
            }
        }
    }
    
    function checkBrandAndAuthor(uint256 _bID,address _author) internal view returns(bool){
        address brandAddr = nameAddr("BRAND");
        address authorAddr = nameAddr("AUTHOR");
        (,,,bool _isRegester) = IBrand(brandAddr).getBrand(_bID);
        (bool isAuthor,,,) = IAuthor(authorAddr).getAuthor(_author);
        
        if(_isRegester && isAuthor){
            return true;
        }else{
            return false;
        }
        
    }
    
    function nameAddr(string memory _name) public view returns(address){
        return addrc.getAddr(_name);
    }
    
    modifier onlyManager(){
        require(addrc.isManager(msg.sender),"onlyManager");
        _;
    }
    modifier onlyMarket(){
        require(addrc.isMarket(msg.sender),"only maket");
        _;
    }
}