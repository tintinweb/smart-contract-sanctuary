// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Config.sol";

contract BlindBox  is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    Config private config;
    uint256 MAX_PAGE_SIZE = 50;
    uint256 public MAX_BOX = 100;
    address GasolineContract;

    Box[] private BoxList;
    struct Box {
        uint8 id;
        uint8 boxType;
        uint256 amount; 
        string  currency;
        uint8 status;
        uint64[][]  chacnce;
        uint256 index;
    }
    mapping(uint8 => Box) private BoxDetail;

    struct BoxOrder {
        uint8 boxId;
        uint8 boxType;
        uint256 amount; 
        uint256 value; 
        string  currency;
        uint256 blockTime;
    }
    mapping(address => BoxOrder[]) private BoxOrderList;
  

    event BuyBox(address indexed _user,uint8 boxId,uint8 boxType,uint256 num,uint256 amount, IERC20 currency);

   function setBox(
        uint8 boxId,
        uint8 boxType,
        uint256 amount, 
        string memory currency,
        uint64[][] memory chacnce,
        uint8 status) external onlyOwner {
        require(amount>0,"Is too small !");
        Box  storage Detail = BoxDetail[boxId];
        if(Detail.index==0){
            BoxList.push(Box(boxId,boxType,amount,currency,status,chacnce,BoxList.length));
            BoxDetail[boxId]=Box(boxId,boxType,amount,currency,status,chacnce,BoxList.length);
        }else{
            BoxList[Detail.index.sub(1)]=Box(boxId,boxType,amount,currency,status,chacnce,Detail.index);
            BoxDetail[boxId]=Box(boxId,boxType,amount,currency,status,chacnce,Detail.index);
        }
    }

    function buyBox(uint8 boxId,uint256 num,address _user) public  returns (uint256){
        //require(msg.sender==GasolineContract,"error!");
        Box  storage detail = BoxDetail[boxId];
        require(detail.status==1,"Temporary not open !");
        uint256 price=detail.amount.mul(num);
        IERC20  currency= config.getToken(detail.currency);
        currency.safeTransferFrom(_user, address(config.getReceiveAddress()), price);
        uint256 value=0;
        for (uint256 i = 1; i <= num; i++) {
         uint256 _value=   getValue(detail.chacnce,i);
            value=value.add(_value);
            BoxOrderList[_user].push(BoxOrder(boxId,detail.boxType,detail.amount,_value,detail.currency,block.timestamp));
        } 
        emit BuyBox(_user,boxId,detail.boxType,num, price,currency);
        return value;
    }
   function getValue(uint64[][] memory chacnce, uint256 randomId) private view returns (uint256) {
        uint64 length = 0;
        for (uint256 i = 0; i < chacnce.length; i++) {
            length += chacnce[i][1];
        }
        uint256 value = 0;
        uint256 randoms = random(length, randomId);
        for (uint256 j = 0; j < chacnce.length; j++) {
            if (randoms < chacnce[j][1]) {
                value = uint256(chacnce[j][0]);
                break;
            } else {
                randoms -= chacnce[j][1];
            }
        }
        return value;
    }

   function random(uint256 length, uint256 value) private view returns (uint256) {
        uint256 randoms = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp + value)));
        return randoms % length;
    }



    function setConfig(Config _config) public onlyOwner {
        config = _config;
    }

    function getBox(uint8 boxId) external view returns(Box memory){
        return BoxDetail[boxId];
    }

    function getBoxList() external view returns(Box[] memory){
        return BoxList;
    }

    function setMaxBox(uint256 num) public onlyOwner {
        MAX_BOX = num;
    }
    function getBoxOrderList(address account,uint256 page,uint256 size) external view returns(BoxOrder[] memory,uint256 total){
        if (size > MAX_PAGE_SIZE) {
            size = MAX_PAGE_SIZE;
        }
        
        BoxOrder[] memory  orders=  BoxOrderList[account];
        uint256 start = (page - 1) * size;
        uint256 end = page * size;
        uint256 length = size;
        if (orders.length < end) {
            end = orders.length;
            length = end - start;
        }
        uint256 tempindex = 0;
        uint256 startIndex=orders.length-1;
        BoxOrder[] memory BoxOrderVo = new BoxOrder[](length);
        for (uint256 index = start; index < end; index++) {
            BoxOrder  memory s =  orders[startIndex-index];
            BoxOrderVo[tempindex] = s;
            tempindex++;
        }
        return (BoxOrderVo, orders.length);
    }


    function setGasolineContract(address _gasolineContract) external onlyOwner{
        GasolineContract=_gasolineContract;
    }
}