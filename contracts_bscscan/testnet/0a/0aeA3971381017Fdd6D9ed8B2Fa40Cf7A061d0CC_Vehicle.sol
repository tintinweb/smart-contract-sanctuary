// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./Config.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

interface Gasoline {
    function transfer(address sender,address to, uint256 amount)  external returns (bool);
}

interface VehicleNft {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function safeMint(address to)  external returns (uint256);
    function safeMint( address to,bytes memory _data)   external returns (uint256);
    function burn(uint256 tokenId)  external  ;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
        function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
        uint256 id;
        uint256 grade;
        uint256  gasAmount;
        uint256 value;
        string currency;
        uint256 index;
        uint256 status;
    }
    mapping(uint256 => VehicleConfig) private VehicleDetail;
 
     SyntheticConfig[] SyntheticConfigList;
    struct SyntheticConfig {
        uint256 grade;
        uint256 need;
        uint256 needGrade;
        uint256 value;
        string currency;
        uint256 index;
    }

    mapping(uint256 => SyntheticConfig) private SyntheticDetail;

    struct VehicleInfo {
        uint256 tokenId;
        uint256 vehicleId;
        uint256 vehicleGrade;
        uint256 status;
    }
    mapping(uint256=>VehicleInfo) private tokenVehicles;

    event BuyVehicle(address indexed _user,
            uint256 tokenId,
            uint256 vehicleId,
            uint256 grade,
            uint256 _value,
            string  currency);

    event RecycleVehicle(address indexed _user,uint256 tokenIds);

    event SyntheticVehicle(address indexed _user,uint256[] tokenIds,uint256 tokenId,uint256 vehicleId);

    event AddGasoline(address indexed _user,uint256 tokenId,uint256 value);

    function addVehicle(uint256 id,
        uint256 grade,
        uint256 value, 
        uint256 gasAmount,
        string memory currency,
        uint256 status) external onlyOwner {
        VehicleConfig  storage Detail = VehicleDetail[id];
        if(Detail.index==0){
            vehicleList.push(VehicleConfig(id, grade,gasAmount,value,currency,vehicleList.length,status));
            VehicleDetail[id]=VehicleConfig(id,grade,gasAmount,value,currency,vehicleList.length,status);
        }else{
            vehicleList[Detail.index.sub(1)]=VehicleConfig(id, grade,gasAmount,value,currency,Detail.index,status);
            VehicleDetail[id]=VehicleConfig(id,grade,gasAmount,value,currency,Detail.index,status);
        }
    }


    function addSyntheticConfig(uint256 grade,uint256 need, uint256 needGrade,uint256 value,string memory currency) external onlyOwner {
        SyntheticConfig  storage Detail = SyntheticDetail[grade];
        if(Detail.index==0){
            SyntheticConfigList.push(SyntheticConfig(grade,need,needGrade,value,currency,SyntheticConfigList.length));
            SyntheticDetail[grade]=SyntheticConfig(grade,need,needGrade,value,currency,SyntheticConfigList.length);
        }else{
            SyntheticConfigList[Detail.index.sub(1)]=SyntheticConfig(grade,need,needGrade,value,currency,Detail.index);
            SyntheticDetail[grade]=SyntheticConfig(grade,need,needGrade,value,currency,Detail.index);
        }
    }

    function buyVehicle(uint256 id,uint256 num) external {
        VehicleConfig  storage detail = VehicleDetail[id];
        require(detail.status!=1,"Temporary not open !");
        uint256 price=detail.value.mul(num);
        IERC20  currency= config.getToken(detail.currency);
        currency.safeTransferFrom(msg.sender, address(config.getReceiveAddress()), price);
        for (uint256 i = 1; i <= num; i++) {
           createOrder(msg.sender, id,detail.grade,detail.currency, detail.value);
        } 
    }

    function createOrder(address sender, uint256 id,uint256 grade,string memory currency, uint256 price) private {
        uint256 newTokenId= vehicleNft.safeMint(sender);
        VehicleInfo memory vehicleInfo= VehicleInfo(newTokenId, id, grade, 0);
        tokenVehicles[newTokenId]=vehicleInfo;
        emit BuyVehicle(msg.sender,newTokenId,id,grade,price,currency);
    }

    function recycleVehicle(uint256[] memory tokenIds) external {
        for(uint256 i=0;i<tokenIds.length;i++){
            uint256 tokenId=tokenIds[i];
            VehicleInfo storage  vehicleInfo= tokenVehicles[tokenId];
            require(vehicleInfo.status==0 &&vehicleInfo.tokenId==tokenId,"status is error !");
            vehicleInfo.status=2;
            deleteVehicle(tokenId,msg.sender);
            emit RecycleVehicle(msg.sender,tokenId);
        }
    }

    function syntheticVehicle(uint256[] memory tokenIds,uint256 upGrade,uint256 vehicleId) public {
        SyntheticConfig  storage detail= SyntheticDetail[upGrade];
        require(tokenIds.length == detail.need, "synthetic error");
         for (uint256 i = 0; i < tokenIds.length; i++) {
            VehicleInfo storage  Info=   tokenVehicles[tokenIds[i]];
            require(Info.vehicleGrade==detail.needGrade && Info.status==0, "need grade error");
        }
        require( gasoline.transfer(msg.sender,address(gasoline),detail.value),"transfer error");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            deleteVehicle(tokenIds[i],msg.sender);
        }
        uint256 newTokenId= vehicleNft.safeMint(msg.sender);
        VehicleInfo memory vehicleInfo= VehicleInfo(newTokenId, vehicleId, upGrade, 0);
        tokenVehicles[newTokenId]=vehicleInfo;
        emit SyntheticVehicle(msg.sender,tokenIds,newTokenId,vehicleId);
    }

     function addGasoline(uint256 tokenId,uint256 value) public {
        require(vehicleNft.ownerOf(tokenId) == msg.sender, "tokenId not sender");
        VehicleInfo storage  vehicleInfo= tokenVehicles[tokenId];
        require(vehicleInfo.status<2&&vehicleInfo.tokenId==tokenId,"status is error !");
        VehicleConfig storage vehicleConfig=  VehicleDetail[vehicleInfo.vehicleId];
        require(value>0 && value.mod(vehicleConfig.gasAmount)==0 && value>0 ,"value error!");
        require(gasoline.transfer(msg.sender,address(gasoline),value),"transfer error");
        emit AddGasoline(msg.sender,tokenId,value);
    }

    function deleteVehicle(uint256 tokenId, address sender) internal {
        require(vehicleNft.ownerOf(tokenId) == sender, "tokenId not sender");
        vehicleNft.burn(tokenId);
        delete tokenVehicles[tokenId];
    }


    function getVehicleDetail(uint8 id) external view returns(VehicleConfig memory){
        return VehicleDetail[id];
    }

    function getVehicles() external view returns(VehicleConfig[] memory){
        return vehicleList;
    }

    function getSyntheticConfig() external view returns(SyntheticConfig[] memory){
        return SyntheticConfigList;
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