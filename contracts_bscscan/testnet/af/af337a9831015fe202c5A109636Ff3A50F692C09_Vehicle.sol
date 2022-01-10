// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./Config.sol";
import "./SafeERC20.sol";
import "./VehicleNft.sol";
import "./SafeMath.sol";


contract Vehicle is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    uint256 public tokenCounter;

    Config private config;
    VehicleNft private vehicleNft;
    string public baseUrl;

    VehicleConfig[] vehicleList;
    
    struct VehicleConfig {
        uint8 id;
        uint8 grade;
        string name; 
        uint256 value;
        string currency;
        uint256 index;
        uint8 status;
    }
    mapping(uint8 => VehicleConfig) public VehicleDetail;

    struct RecycleConfig {
        uint8 grade;
        uint256 price;
        string currency;
    }
    mapping(uint8 => RecycleConfig) public RecycleDetail;


    struct OrderInfo {
        uint256 tokenId;
        uint8 vehicleId;
        uint8 vehicleGrade;
        uint8 status;
    }

    mapping(address=>OrderInfo[]) public myOrders;
    mapping(uint256=>uint256) public OrderToIndex;


    event BuyVehicle(address indexed _user,
            uint8 vehicleId,
            uint8 grade,
            uint256 _value,
            string  currency);

    event RecycleVehicle(address indexed _user,
            uint8 vehicleId,
            uint8 grade,
            uint256 _value,
            string  currency);

    function addVehicle(uint8 id,
        uint8 grade,
        string memory name,
        uint256 value, 
        string memory currency,
        uint8 status) external onlyOwner {
        VehicleConfig  storage Detail = VehicleDetail[id];
        if(Detail.index==0){
            vehicleList.push(VehicleConfig(id, grade,name,value,currency,vehicleList.length,status));
            VehicleDetail[id]=VehicleConfig(id,grade,name,value,currency,vehicleList.length,status);
        }else{
            vehicleList[Detail.index.sub(1)]=VehicleConfig(id, grade,name,value,currency,Detail.index,status);
            VehicleDetail[id]=VehicleConfig(id,grade,name,value,currency,Detail.index,status);
        }
    }

    function buyVehicle(uint8 id,uint8 num) public {
        VehicleConfig  storage detail = VehicleDetail[id];
        require(detail.status!=1,"Temporary not open !");
        uint256 price=detail.value.mul(num);
        IERC20  currency= config.getToken(detail.currency);
        uint256 amount=price*10**uint256(currency.decimals());
        currency.safeTransferFrom(msg.sender, address(config.getReceiveAddress()), amount);
        for (uint256 i = 1; i <= num; i++) {
           createOrder(msg.sender, id,detail.grade,detail.currency, price);
        } 
    }

    function recycleVehicle(uint256 tokenId) public {
        uint256 index= OrderToIndex[tokenId];
        OrderInfo storage  orderInfo= myOrders[msg.sender][index];
        require(orderInfo.status==0,"Temporary not open !");
        orderInfo.status=2;
        
    }



    function createOrder(address sender, uint8 id,uint8 grade,string memory currency, uint256 price) private {
        uint256 newTokenId= vehicleNft.safeMint(sender);
        myOrders[sender].push(OrderInfo(newTokenId, id, grade, 0));
        OrderToIndex[newTokenId] = uint256(myOrders[sender].length - 1);
        emit BuyVehicle(msg.sender,id,grade,price,currency);
    }

    function getVehicleDetail(uint8 id) external view returns(VehicleConfig memory){
        return VehicleDetail[id];
    }

    function getVehicles() external view returns(VehicleConfig[] memory){
        return vehicleList;
    }

    function setBaseUrl(string memory _url) external onlyOwner {
        baseUrl = _url;
    }

    function getBaseUrl() public view returns (string memory) {
        return baseUrl;
    }

    function setConfig(Config _config) public onlyOwner {
        config = _config;
    }

    function setVehicleNft(VehicleNft _vehicleNft) external onlyOwner{
        vehicleNft=_vehicleNft;
    }
}