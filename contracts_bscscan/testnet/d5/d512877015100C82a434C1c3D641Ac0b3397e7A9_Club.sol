// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Config.sol";

contract Club is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
   
    Config public config;
    ClubConfig[] public clubConfigList;
    struct ClubConfig {
        uint8 grade;
        uint256 amount;
        IERC20 currency;
        uint256 index;
    }
    mapping(uint8 => ClubConfig) public clubConfigs;

    mapping(address => uint8) public userGrade;


    event UpGrade(address indexed _user,
            uint8 grade,
            uint256 _value,
            IERC20 currency);

    function setClubConfig(
        uint8 grade,
        uint256 amount, 
        IERC20 currency) external onlyOwner {
        ClubConfig  storage Detail = clubConfigs[grade];
        if(Detail.index==0){
            clubConfigList.push(ClubConfig( grade,amount,currency,clubConfigList.length));
            clubConfigs[grade]=ClubConfig(grade,amount,currency,clubConfigList.length);
        }else{
            clubConfigList[Detail.index.sub(1)]=ClubConfig(grade,amount,currency,Detail.index);
            clubConfigs[grade]=ClubConfig(grade,amount,currency,Detail.index);
        }
    }

    function upGrade(uint8 grade) public {
        require(grade==userGrade[msg.sender]+1,"grade error!");
        ClubConfig  storage detail = clubConfigs[grade];
        require(detail.grade==grade,"Temporary not open !");
        IERC20  currency= detail.currency;
        uint256 value=detail.amount*10**uint256(currency.decimals());
        //config.getAddressMap("receiveAddress")
        currency.safeTransferFrom(msg.sender, address(this), value);
        userGrade[msg.sender]=detail.grade;
        emit UpGrade(msg.sender,detail.grade,detail.amount,currency);
    }


    function getClubConfigList() external view returns(ClubConfig[] memory){
        return clubConfigList;
    }


 
 

}