// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ownable.sol";
import "./safe-math.sol";
import "./strings-utils.sol";

interface EggInfinityInterface {
    function extMint(address _to,uint256 _tokenId,string memory _uri) external;
}

contract EggInfinityActivity is Ownable {

    //connect contract EggInfinityNFT by address
    EggInfinityInterface contractObj = EggInfinityInterface(0x25206F51f184D34e7f1b98c530c66Fdf387eaFBb);
    
    using SafeMath for uint256;
    
    struct activityStruct {
        uint256 id;
        uint256 price;
        uint256 count;
        uint256 remain;
        uint256 startTokenId;
        uint256 startUrlId;
        string urlRoot;
        bool enable;
    }
    mapping (uint256=>activityStruct) public activityMap;
    uint256[] private activityIds;

    address public activityCFOAddress;

    function setActivityCFOAddress(address _val) external onlyOwner {
        require(_val != address(0));//,"Invalid address");

        activityCFOAddress = _val;
    }

    function getActivityIds() view external onlyOwner returns(uint256[] memory) {
        return activityIds;
    }

    function addActivity(
        uint256 _id, 
        uint256 _price,
        uint256 _count, 
        uint256 _startTokenId,
        uint256 _startUrlId,
        string memory _urlRoot,
        bool _enable) external onlyOwner{
        require(activityMap[_id].id==0);//,"id has exist");

        activityMap[_id] = activityStruct(_id,_price,_count,_count,_startTokenId,_startUrlId,_urlRoot,_enable);
        activityIds.push(_id);
    }
    
    function resetActivity(uint256 _id, uint256 _price, uint256 _count) external onlyOwner {
        _checkActivityExist(_id);
        if (_count > activityMap[_id].count) activityMap[_id].remain = activityMap[_id].remain.add( _count.sub(activityMap[_id].count) );
        if (_count < activityMap[_id].count && _count < activityMap[_id].remain) activityMap[_id].remain = _count;
        activityMap[_id].price = _price;
        activityMap[_id].count = _count;
    }
    
    function setActivityEnable(uint256 _id, bool enable) external onlyOwner {
        _checkActivityExist(_id);
        activityMap[_id].enable = enable;
    }

    function getActivity(uint256 _id) external view returns(uint256 id, uint256 price, uint256 count, uint256 remain) {
        _checkActivityExist(_id);
        id = activityMap[_id].id;
        price = activityMap[_id].price;
        count = activityMap[_id].count;
        remain = activityMap[_id].remain;
    }
    
    function activityBuy(uint256 _id) payable external {
        _checkActivityExist(_id);
        require(activityMap[_id].enable);   //,"activity is disabled");
        require(activityMap[_id].remain > 0 && activityMap[_id].remain <= activityMap[_id].count);   //,"activity has ended");
        require(activityCFOAddress != address(0));   //,"activity cfo address is empty");
        require(msg.value >= activityMap[_id].price);   //,"amount low than price"
        payable(activityCFOAddress).transfer(msg.value);
        
        uint256 countCost = activityMap[_id].count.sub( activityMap[_id].remain );
        uint256 tokenId = activityMap[_id].startTokenId.add( countCost );
        uint256 tokenUrlId = activityMap[_id].startUrlId.add( countCost );
        string memory tokenUrl = Strings.concatString(activityMap[_id].urlRoot,Strings.toString(tokenUrlId));

        contractObj.extMint(msg.sender, tokenId, tokenUrl);
        
        activityMap[_id].remain = activityMap[_id].remain.sub(1);
    }
    
    function _checkActivityExist(uint256 _id) internal view {
        require(activityMap[_id].id!=0);//,"id not exist");
    }  
}