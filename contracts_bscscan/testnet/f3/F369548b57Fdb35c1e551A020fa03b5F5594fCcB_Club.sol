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
   
    Config private config;
    ClubConfig[] private clubConfigList;
    struct ClubConfig {
        uint8 grade;
        uint256 amount;
        string currency;
        uint256 index;
    }
    mapping(uint8 => ClubConfig) private clubConfigs;
    mapping(address => uint8) private userGrade;
    event UpGrade(address indexed _user,
            uint8 grade,
            uint256 _value,
            IERC20 currency);

    function setClubConfig(
        uint8 grade,
        uint256 amount, 
        string memory currency) external onlyOwner {
        require(amount>0,"Is too small !");
        ClubConfig  storage Detail = clubConfigs[grade];
        if(Detail.index==0){
            clubConfigList.push(ClubConfig(grade,amount,currency,clubConfigList.length));
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
        IERC20  currency= config.getToken(detail.currency);
        currency.safeTransferFrom(msg.sender, address(config.getReceiveAddress()), detail.amount);
        userGrade[msg.sender]=detail.grade;
        emit UpGrade(msg.sender,detail.grade,detail.amount,currency);
    }

   function setConfig(Config _config) public onlyOwner {
        config = _config;
    }

    function getClubConfig(uint8 grade) external view returns(ClubConfig memory){
        return clubConfigs[grade];
    }

    function getClubConfigList() external view returns(ClubConfig[] memory){
        return clubConfigList;
    }

    function getUserGrade(address account) external view returns(uint256){
        return userGrade[account];
    }


}