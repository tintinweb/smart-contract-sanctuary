// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./Config.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

interface Gasoline {
    function synthetic(address sender, uint256 amount)  external returns (bool);
}

interface VehicleNft {
    function safeMint(address to)  external returns (uint256);
    function safeMint( address to,bytes memory _data)   external returns (uint256);
    function burn(uint256 tokenId)  external  ;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Vehicle is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    uint256 public tokenCounter;

    Gasoline private gasoline;

    Config private config;
    VehicleNft private vehicleNft;
    string public baseUrl;

    VehicleConfig[] vehicleList;
    
    struct VehicleConfig {
        uint8 id;
        uint8 grade;
        uint256 value;
        string currency;
        uint256 index;
        uint8 status;
    }
    mapping(uint8 => VehicleConfig) public VehicleDetail;
 
    struct SyntheticConfig {
        uint256 grade;
        uint256 need;
        uint256 needGrade;
        uint256 value;
        string currency;
    }
    mapping(uint256 => SyntheticConfig) public SyntheticDetail;

    struct VehicleInfo {
        uint256 tokenId;
        uint8 vehicleId;
        uint8 vehicleGrade;
        uint8 status;
    }
    
    mapping(address=>VehicleInfo[]) public myVehicles;

    mapping(uint256=>VehicleInfo) public tokenVehicles;

    mapping(uint256=>uint256) public VehicleToIndex;


    event BuyVehicle(address indexed _user,
            uint8 vehicleId,
            uint8 grade,
            uint256 _value,
            string  currency);

    event RecycleVehicle(address indexed _user,uint256 tokenId);

    event SyntheticVehicle(address indexed _user,uint256[] tokenIds);

    function addVehicle(uint8 id,
        uint8 grade,
        uint256 value, 
        string memory currency,
        uint8 status) external onlyOwner {
        VehicleConfig  storage Detail = VehicleDetail[id];
        if(Detail.index==0){
            vehicleList.push(VehicleConfig(id, grade,value,currency,vehicleList.length,status));
            VehicleDetail[id]=VehicleConfig(id,grade,value,currency,vehicleList.length,status);
        }else{
            vehicleList[Detail.index.sub(1)]=VehicleConfig(id, grade,value,currency,Detail.index,status);
            VehicleDetail[id]=VehicleConfig(id,grade,value,currency,Detail.index,status);
        }
    }

    function buyVehicle(uint8 id,uint8 num) external {
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

    function recycleVehicle(uint256[] memory tokenIds) external {
        for(uint256 i=0;i<tokenIds.length;i++){
            uint256 tokenId=tokenIds[i];
            uint256 index= VehicleToIndex[tokenId];
            VehicleInfo storage  orderInfo= myVehicles[msg.sender][index];
            require(orderInfo.status==0,"status is error !");
            VehicleInfo storage  vehicleInfo= tokenVehicles[tokenId];
            require(vehicleInfo.status==0,"status is error !");
            orderInfo.status=2;
            vehicleInfo.status=2;
            deleteVehicle(tokenId,msg.sender);
            emit RecycleVehicle(msg.sender,tokenId);
        }
    }

    function syntheticVehicle(uint256[] memory tokenIds,uint256 upGrade) public {
        SyntheticConfig  storage detail= SyntheticDetail[upGrade];
        require(tokenIds.length == detail.need, "synthetic error");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            VehicleInfo storage  vehicleInfo=    myVehicles[msg.sender][VehicleToIndex[tokenIds[i]]];
            require(vehicleInfo.vehicleGrade==detail.needGrade && vehicleInfo.status==0, "need grade error");
        }
        require( gasoline.synthetic(msg.sender,detail.value),"synthetic error");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            deleteVehicle(tokenIds[i],msg.sender);
            delete myVehicles[msg.sender][VehicleToIndex[tokenIds[i]]];
        }
        emit SyntheticVehicle(msg.sender,tokenIds);
    }


    function deleteVehicle(uint256 tokenId, address sender) internal {
        require(vehicleNft.ownerOf(tokenId) == sender, "tokenId not sender");
        vehicleNft.burn(tokenId);
        delete tokenVehicles[tokenId];
    }

    function createOrder(address sender, uint8 id,uint8 grade,string memory currency, uint256 price) private {
        uint256 newTokenId= vehicleNft.safeMint(sender);
        VehicleInfo memory vehicleInfo= VehicleInfo(newTokenId, id, grade, 0);
        tokenVehicles[newTokenId]=vehicleInfo;
        myVehicles[sender].push(vehicleInfo);
        VehicleToIndex[newTokenId] = uint256(myVehicles[sender].length - 1);
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
    function setGasoline(Gasoline _gasoline) external onlyOwner{
        gasoline=_gasoline;
    }
}