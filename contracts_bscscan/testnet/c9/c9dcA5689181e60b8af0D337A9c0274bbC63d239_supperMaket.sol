/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-05-20
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: UNLICENSED
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
library Address {
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}
library SafeMath {
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

  
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IaddressController {
    function isManager(address _mAddr) external view returns(bool);
    function getAddr(string calldata _name) external view returns(address);
}

interface ICommodity{
    function canBuy(uint256 _cid) external view returns(bool);
    function getSaleInfo(uint256 _cid) external view returns(uint256 _totalSupply,uint256 _saleedAmount);
    function saleOne(uint256 _cid,uint256 _sid,uint256 _tokenID) external;
    function upsale(uint256 _cid) external;
    function downSale(uint256 _cid) external;
    function getCommodityAttribute_S(uint256 _cid) external view returns(string[] memory _cAttributeS,uint256 _len);
    function getCommodityAttribute_U(uint256 _cid) external view returns(uint256[] memory _cAttributeU);
    function getAuthorAndBrandByCid(uint256 _cid) external view returns(address _author,uint256 _bID);
    function getUrlByCid(uint256 _cid) external view returns(string memory _url);
}

interface INFT{
    function viewTokenID() view external returns(uint256);
    function mint(address _to,uint256 _tokenId,string calldata _uri) external;
    function setTokenAttributes(uint256 _tokenId,uint8 _typeAttributes,string calldata _tvalue,uint256 _tUintValue) external;
}
contract supperMaket{
    using Address for address;
    using SafeMath for *;
    IaddressController public addrc;
    
    uint256 public feeRate;
    
    mapping(uint256 => order_S) public order;
    mapping(uint256 => bool) public isCreateOrder;
    
    struct order_S{
        uint256 cid;
        uint256 starTime;
        uint256 price;
        address reciveToken;
    }
    
    
    event CreateOrder(
        uint256 _aid, // this is orderid 
        uint256 _startTime,
        uint256 _price,
        address _reciveToken);
        
    event CancelOrder(uint256 _aid);
    
    event BuyOne(uint256 _aid,uint256 _gnum,uint256 _tokenID,address _buyer);
    
    constructor(IaddressController _addrc) public{
        addrc = _addrc;
    }
    
    function createOrder(
        uint256 _cid, // this is orderid 
        uint256 _startTime,
        uint256 _price,
        address _reciveToken
        ) public onlyManager{
        
        require(!isCreateOrder[_cid],"order already create");
        isCreateOrder[_cid] = true;
        
        address cAddr = nameAddr("COM");
        
        ICommodity(cAddr).upsale(_cid);
        
        order[_cid] = order_S({
            cid : _cid,
            starTime:_startTime,
            price:_price,
            reciveToken:_reciveToken
            });
        
        
        emit CreateOrder(
            _cid,
            _startTime,
            _price,
            _reciveToken
            );
    }
    
    function cancelOrder(uint256 _cid) public onlyManager{
        require(isCreateOrder[_cid],"order not create");
        isCreateOrder[_cid] = false;
        
        ICommodity(nameAddr("COM")).downSale(_cid);
        emit CancelOrder(_cid);
    }
    
    function buyOne(uint256 _cid,uint256 _sid) public  payable  {
        require(isCreateOrder[_cid],"order not create");
        require(checkOderCid(_cid),"check cid fail");
        address com = nameAddr("COM");
        
        salePay(_cid);
        uint256 _tokenID = createNFT(_cid,msg.sender);
        ICommodity(com).saleOne(_cid,_sid,_tokenID);
        
        emit BuyOne( _cid, _sid, _tokenID, msg.sender);
    }
    
    function buyOne_to(uint256 _cid,uint256 _sid,address _to) public  payable  {
        require(isCreateOrder[_cid],"order not create");
        require(checkOderCid(_cid),"check cid fail");
        require(_to!= address(0),"to can not be zero");
        address com = nameAddr("COM");
        
        salePay(_cid);
        uint256 _tokenID = createNFT(_cid,_to);
        ICommodity(com).saleOne(_cid,_sid,_tokenID);
        
        emit BuyOne( _cid, _sid, _tokenID, _to);
    }
    
    function createNFT(uint256 _cid,address _to) internal returns(uint256 _tokenID){
        INFT systemNFT= INFT(nameAddr("SNFT")); // this is system NFT
        _tokenID = systemNFT.viewTokenID()+1;
        address com = nameAddr("COM");
        string memory url = ICommodity(com).getUrlByCid(_cid);
        
        systemNFT.mint(_to,_tokenID,url);
        
        (string[] memory ass ,uint256 _lenS)= ICommodity(com).getCommodityAttribute_S(_cid);
        if(_lenS ==2){
            systemNFT.setTokenAttributes(_tokenID,1,ass[0],0);
            systemNFT.setTokenAttributes(_tokenID,2,ass[1],0);
        }else if(_lenS ==1){
            systemNFT.setTokenAttributes(_tokenID,1,ass[0],0);
        }
        
        (uint256[] memory asU) =  ICommodity(com).getCommodityAttribute_U(_cid);
        uint256 _lenU = asU.length;
        if(_lenU == 3){
            systemNFT.setTokenAttributes(_tokenID,4,"",asU[0]);
            systemNFT.setTokenAttributes(_tokenID,5,"",asU[1]);
            systemNFT.setTokenAttributes(_tokenID,6,"",asU[2]);
        }else if(_lenU == 2){
            systemNFT.setTokenAttributes(_tokenID,4,"",asU[0]);
            systemNFT.setTokenAttributes(_tokenID,5,"",asU[1]);
        }else if(_lenU == 1){
            systemNFT.setTokenAttributes(_tokenID,1,"",asU[0]);
        }
        systemNFT.setTokenAttributes(_tokenID,3,"",_cid);
    }
    
    function salePay(uint256 _cid) internal  {
        
        address _feeTo = nameAddr("FEETO");  //Addresscontroll addaddree  加入注册brand的_feeToken， 即代币合约地址
    
        require(_feeTo != address(0),"not set feeto address");
        
        order_S memory os = order[_cid];
        uint256 feeAmount = os.price.mul(feeRate).div(10000);       // 费用 
        uint256 autorAmount  = os.price.sub(feeAmount);             // 作者 所 得 
        (address _auctor,) = ICommodity(nameAddr("COM")).getAuthorAndBrandByCid(_cid);
        
        bool isHostCoin = os.reciveToken == address(1)? true:false;
        if(feeAmount > 0){
            if(!isHostCoin){
                TransferHelper.safeTransferFrom(os.reciveToken,msg.sender,_feeTo,feeAmount);
            }else{
                _feeTo.toPayable().transfer(feeAmount);
            }
        }
        if(autorAmount > 0){
            if(!isHostCoin){
                TransferHelper.safeTransferFrom(os.reciveToken,msg.sender,_auctor,autorAmount);
            }else{
                _auctor.toPayable().transfer(autorAmount);
            }
        }
        if (isHostCoin && address(this).balance > 0){
            msg.sender.transfer(address(this).balance);
        }
    }
    
    
    
    function checkOderCid(uint256 _cid) internal view returns(bool ) {
        address comAddr = nameAddr("COM");
        (uint256 _totalSupply,uint256 _saleedAmount) = ICommodity(comAddr).getSaleInfo(_cid);
        
        if( !ICommodity(comAddr).canBuy(_cid)){
            return false;
        }
        if(_totalSupply ==  _saleedAmount){
            return  false;
        }
        
        if(block.timestamp <= order[_cid].starTime){
            return false; 
        }
        
        return true;
        
    }
    
    function setFeeRate(uint256 _feeRate) public onlyManager{
        require(_feeRate <= 10000,"can not big the 10000");
        feeRate = _feeRate;
    }
    
    function nameAddr(string memory _name) public view returns(address){
        return addrc.getAddr(_name);
    }
    
    modifier onlyManager(){
        require(addrc.isManager(msg.sender),"onlyManager");
        _;
    }
    
}