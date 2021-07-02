/**
 *Submitted for verification at Etherscan.io on 2021-07-01
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

interface INFT{
    function setApprovalForAll(address _operator,bool _approved) external;
    function safeTransferFrom(address _from,address _to,uint256 _tokenId) external;
}


contract Business{
    using Address for address;
    using SafeMath for *;
    IaddressController public addrc;
    
    uint256 public feeRate;
    
     mapping(uint256 => bool) public isCreateOrder;
    mapping(uint256 => order_S) public order;

    struct order_S{
        uint256 price;
        uint256 tokenId;
        address saler;
        address reciveToken;
    }
    
    
    
    constructor(IaddressController _addrc) public{
        addrc = _addrc;
    }
    
    function ApprovalForAll() external{
        INFT systemNFT= INFT(nameAddr("SNFT")); 
        systemNFT.setApprovalForAll(address(this),true);
    }
    
    
    function upsale(uint256 _tokenId,uint256 _price,address _reciveToken) public  payable{
        require(!isCreateOrder[_tokenId],"token exist");
        INFT systemNFT= INFT(nameAddr("SNFT")); 
        systemNFT.safeTransferFrom(msg.sender,address(this),_tokenId);
        isCreateOrder[_tokenId] =true;
         order[_tokenId] = order_S({
            price : _price,
            tokenId:_tokenId,
            saler:msg.sender,
            reciveToken:_reciveToken
            });
    }    

    function  downsale(uint256 _tokenId) public  payable{
        order_S memory orderdata = order[_tokenId];
        require(isCreateOrder[_tokenId],"token not exist");
        require(orderdata.saler==msg.sender,"not owner");
        
        isCreateOrder[_tokenId] =false;
        INFT systemNFT=INFT(nameAddr("SNFT")); 
        systemNFT.safeTransferFrom(address(this),orderdata.saler,_tokenId);
    }  
    
      
     function buyOne(uint256 _tokenId,uint256 _sid) public  payable  {
        require(isCreateOrder[_tokenId],"token not exist");
        INFT systemNFT=INFT(nameAddr("SNFT")); 
        
        address _feeTo = nameAddr("FEETO");
        require(_feeTo != address(0),"not set feeto address");
        
        order_S memory orderdata = order[_tokenId];
        uint256 feeAmount = orderdata.price.mul(feeRate).div(10000);
        uint256 autorAmount  = orderdata.price.sub(feeAmount);
       
        
        bool isHostCoin = orderdata.reciveToken == address(1)? true:false;
        if(feeAmount > 0){
            if(!isHostCoin){
                TransferHelper.safeTransferFrom(orderdata.reciveToken,msg.sender,_feeTo,feeAmount);
            }else{
                _feeTo.toPayable().transfer(feeAmount);
            }
        }
        if(autorAmount > 0){
            if(!isHostCoin){
                TransferHelper.safeTransferFrom(orderdata.reciveToken,msg.sender,orderdata.saler,autorAmount);
            }else{
                orderdata.saler.toPayable().transfer(autorAmount);
            }
        }
    }
    
    function setFeeRate(uint256 _feeRate) public onlyManager{
        require(_feeRate <= 10000,"can not big the 10000");
        feeRate = _feeRate;
    }  
     
    function nameAddr(string memory _name) public view returns(address){
        return addrc.getAddr(_name);
    }
    
    modifier onlyManager(){
        require(addrc.isManager(msg.sender),"only_Manager");
        _;
    }
    
}