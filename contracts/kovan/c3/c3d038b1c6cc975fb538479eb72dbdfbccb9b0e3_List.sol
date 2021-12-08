/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

/// @title Folder -- Folder Management
/// @author BloodMoon - <[email protected]>
/// @version 0.1
/// @date 2021-12-3
pragma solidity ^0.8.0;
contract List{
    struct ItemList {
        uint256 Id;
        string Name;
        address Author;
        bool Status;
        // uint256 FatherNode;
        string Class;
        string Tag;
        string Description;
        uint256[] CourseIds;
        uint256[] ExperimentIds;
        uint256 Time;
        uint256 BlockNum;
    }
    struct LessonList {
        uint256 Id;
        string Name;
        address Author;
        bool Status;
        // uint256 FatherNode;
        string Class;
        string Tag;
        string Description;
        uint256 Time;
        uint256 BlockNum;
    }
    struct StationList {
        uint256 Id;
        string Name;
        address Author;
        bool Status;
        // uint256 FatherNode;
        string Class;
        string Tag;
        string Description;
        uint256 Time;
        uint256 BlockNum;
    }

    //基本存储信息
    StationList[] stationLists;
    LessonList[] lessonLists;
    ItemList[] itemLists;

    //列表结构信息
    mapping(uint256=>uint256[]) ListToLesson;
    mapping(uint256=>uint256[]) LessonToItem;

    //打分信息
    mapping(uint256 => mapping(address => uint256)) stationScores;
    mapping(uint256 => mapping(address => uint256)) LessonScores;
    mapping(uint256 => mapping(address => uint256)) ItemScores;
    mapping(uint256 => address[]) arrayStationScores;
    mapping(uint256 => address[]) arrayLessonScores;
    mapping(uint256 => address[]) arrayItemScores;

    modifier StationListAuthorCheck(uint256 Id){
        require(stationLists[Id].Author==msg.sender);
        _;
    }
    modifier LessonListAuthorCheck(uint256 Id){
        require(lessonLists[Id].Author==msg.sender);
        _;
    }
    modifier ItemListAuthorCheck(uint256 Id){
        require(itemLists[Id].Author==msg.sender);
        _;
    }
    //=================增===================
    function addStationList(string memory _name, string memory _tag, string memory _class, string memory _description) public returns (bool){
        uint nextId = stationLists.length;
        StationList memory stationList = StationList({
        Id : nextId,
        Name : _name,
        Author : msg.sender,
        Status : true,
        Class : _class,
        Tag : _tag,
        Description : _description,
        Time : block.timestamp,
        BlockNum: block.number
        }
        );
        stationLists.push(stationList);
        return true;
    }

    function addLessonList(string memory _name, string memory _tag, string memory _class, string memory _description) public returns (bool){
        uint nextId = lessonLists.length;
        LessonList memory lessonList = LessonList({
        Id : nextId,
        Name : _name,
        Author : msg.sender,
        Status : true,
        Class : _class,
        Tag : _tag,
        Description : _description,
        Time : block.timestamp,
        BlockNum: block.number
        }
        );
        lessonLists.push(lessonList);
        return true;
    }
    function addItemList(string memory _name, string memory _tag, string memory _class, string memory _description) public returns (bool){
        uint nextId = itemLists.length;
        ItemList memory itemList = ItemList({
        Id : nextId,
        Name : _name,
        Author : msg.sender,
        Status : true,
        Class : _class,
        Tag : _tag,
        Description : _description,
        Time : block.timestamp,
        BlockNum: block.number,
        CourseIds:new uint256[](0),
        ExperimentIds:new uint256[](0)
        }
        );
        itemLists.push(itemList);
        return true;
    }

    function addLessonForStation(uint256 stationIndex,uint256 lessonIndex) public returns(bool){
        ListToLesson[stationIndex].push(lessonIndex);
        return true;
    }
    function addItemForLesson(uint256 lessonIndex,uint256 itemIndex) public returns(bool){
        LessonToItem[lessonIndex].push(itemIndex);
        return true;
    }

    function addCourseToItem(uint256 _itemId,uint256 _courseId) public returns(bool){
        itemLists[_itemId].CourseIds.push(_courseId);
        return true;
    }
    function addExperimentToItem(uint256 _itemId,uint256 _experimentId) public returns(bool){
        itemLists[_itemId].ExperimentIds.push(_experimentId);
        return true;
    }
    //=================改===================
    function modifyStationInfo(uint256 _id,string memory _name, string memory _tag, string memory _class, string memory _description) public returns(bool){
        stationLists[_id].Name=_name;
        stationLists[_id].Tag=_tag;
        stationLists[_id].Class=_class;
        stationLists[_id].Description=_description;
        return true;
    }
    function modifyLessonInfo(uint256 _id,string memory _name, string memory _tag, string memory _class, string memory _description) public returns(bool){
        lessonLists[_id].Name=_name;
        lessonLists[_id].Tag=_tag;
        lessonLists[_id].Class=_class;
        lessonLists[_id].Description=_description;
        return true;
    }
    function modifyItemInfo(uint256 _id,string memory _name, string memory _tag, string memory _class, string memory _description) public returns(bool){
        itemLists[_id].Name=_name;
        itemLists[_id].Tag=_tag;
        itemLists[_id].Class=_class;
        itemLists[_id].Description=_description;
        return true;
    }
    //=================删===================
    function removeLessonIndexFromStation(uint256 _stationId, uint256 _lessonIndex) StationListAuthorCheck(_stationId) public {

        uint length = ListToLesson[_stationId].length;
        if (_lessonIndex == length - 1) {
            ListToLesson[_stationId].pop();
        } else {
            ListToLesson[_stationId][_lessonIndex] = ListToLesson[_stationId][length - 1];
            ListToLesson[_stationId].pop();
        }
    }

    function removeLessonIdValueFromStation(uint256 _stationId, uint256 _lessonId) StationListAuthorCheck(_stationId) public {
        uint delIndex;
        for (uint i = 0; i < ListToLesson[_stationId].length; i++) {
            if (ListToLesson[_stationId][i] == _lessonId) {
                delIndex = i;
            }
        }
        removeLessonIndexFromStation(_stationId, delIndex);
    }
    function removeItemIndexFromLesson(uint256 _lessonId, uint256 _itemIndex) LessonListAuthorCheck(_lessonId) public {

        uint length = LessonToItem[_lessonId].length;
        if (_itemIndex == length - 1) {
            LessonToItem[_lessonId].pop();
        } else {
            LessonToItem[_lessonId][_itemIndex] = LessonToItem[_lessonId][length - 1];
            LessonToItem[_lessonId].pop();
        }
    }

    function removeItemIdValueFromLesson(uint256 _lessonId, uint256 _itemId) LessonListAuthorCheck(_lessonId) public {
        uint delIndex;
        for (uint i = 0; i < LessonToItem[_lessonId].length; i++) {
            if (LessonToItem[_lessonId][i] == _itemId) {
                delIndex = i;
            }
        }
        removeItemIndexFromLesson(_lessonId, delIndex);
    }
    function removeCourseIndexFromItem(uint256 _itemId, uint256 _index) ItemListAuthorCheck(_itemId) public {

        uint length = itemLists[_itemId].CourseIds.length;
        if (_index == length - 1) {
            itemLists[_itemId].CourseIds.pop();
        } else {
            itemLists[_itemId].CourseIds[_index] = itemLists[_itemId].CourseIds[length - 1];
            itemLists[_itemId].CourseIds.pop();
        }
    }

    function removeCourseValueFromItem(uint256 _itemId, uint256 _value) ItemListAuthorCheck(_itemId) public {
        uint delIndex;
        for (uint i = 0; i < itemLists[_itemId].CourseIds.length; i++) {
            if (itemLists[_itemId].CourseIds[i] == _value) {
                delIndex = i;
            }
        }
        removeCourseIndexFromItem(_itemId, delIndex);
    }

    function removeExperimentIndexFromItem(uint256 _itemId, uint256 _index) ItemListAuthorCheck(_itemId) public {

        uint length = itemLists[_itemId].ExperimentIds.length;
        if (_index == length - 1) {
            itemLists[_itemId].ExperimentIds.pop();
        } else {
            itemLists[_itemId].ExperimentIds[_index] = itemLists[_itemId].ExperimentIds[length - 1];
            itemLists[_itemId].ExperimentIds.pop();
        }
    }

    function removeExperimentValueFromItem(uint256 _itemId, uint256 _value) ItemListAuthorCheck(_itemId) public {
        uint delIndex;
        for (uint i = 0; i < itemLists[_itemId].ExperimentIds.length; i++) {
            if (itemLists[_itemId].ExperimentIds[i] == _value) {
                delIndex = i;
            }
        }
        removeExperimentIndexFromItem(_itemId, delIndex);
    }
    //=================查===================
    function getLessonsFromStationId(uint256 _stationId) public view returns(LessonList[] memory){
        uint256[] memory lessonIds=ListToLesson[_stationId];
        uint length=lessonIds.length;
        LessonList[] memory retLessonList=new LessonList[](length);
        for(uint i=0;i<length;i++){
            retLessonList[i]=lessonLists[lessonIds[i]];
        }
        return retLessonList;
    }
    function getItemsFromLessonId(uint256 _lessonId) public view returns(ItemList[] memory){
        uint256[] memory itemIds=LessonToItem[_lessonId];
        uint length=itemIds.length;
        ItemList[] memory retItemList=new ItemList[](length);
        for(uint i=0;i<length;i++){
            retItemList[i]=itemLists[itemIds[i]];
        }
        return retItemList;
    }
    function getCoursesIdsFromItemId(uint256 _itemId) public view returns(uint256[] memory){
        uint256[] memory ids=itemLists[_itemId].CourseIds;
        return ids;
    }
    function getExperimentIdsFromItemId(uint256 _itemId) public view returns(uint256[] memory){
        uint256[] memory ids=itemLists[_itemId].ExperimentIds;
        return ids;
    }
    function getAllStation() public view returns(StationList[] memory){
        return stationLists;
    }
    function getStationFromId(uint256 _id) public view returns(StationList memory){
        return stationLists[_id];
    }
    function getLessonnFromId(uint256 _id) public view returns(LessonList memory){
        return lessonLists[_id];
    }
    function getItemFromId(uint256 _id) public view returns(ItemList memory){
        return itemLists[_id];
    }
    function getAllLesson() public view returns(LessonList[] memory){
        return lessonLists;
    }
    function getAllItem() public view returns(ItemList[] memory){
        return itemLists;
    }

    //=================打分===================
    function addScoreForStation(uint256 _stationId,uint256 score) public{
        require(score <= 100 && score >= 0, "score overflow");
        if(checkIfExist(msg.sender,arrayStationScores[_stationId])){
            stationScores[_stationId][msg.sender] = score;
        }
        else{
            stationScores[_stationId][msg.sender] = score;
            arrayStationScores[_stationId].push(msg.sender);
        }
    }
    function addScoreForLesson(uint256 _id,uint256 score) public{
        require(score <= 100 && score >= 0, "score overflow");
        if(checkIfExist(msg.sender,arrayLessonScores[_id])){
            LessonScores[_id][msg.sender] = score;
        }
        else{
            LessonScores[_id][msg.sender] = score;
            arrayLessonScores[_id].push(msg.sender);
        }
    }
    function addScoreForItem(uint256 _id,uint256 score) public{
        require(score <= 100 && score >= 0, "score overflow");
        if(checkIfExist(msg.sender,arrayItemScores[_id])){
            ItemScores[_id][msg.sender] = score;
        }
        else{
            ItemScores[_id][msg.sender] = score;
            arrayItemScores[_id].push(msg.sender);
        }
    }
    //=================打分查询===================
    function getMyStationScore(uint256 _id) public view returns(uint256){
        return stationScores[_id][msg.sender];
    }
    function getMyLessonScore(uint256 _id) public view returns(uint256){
        return LessonScores[_id][msg.sender];
    }
    function getMyItemScore(uint256 _id) public view returns(uint256){
        return ItemScores[_id][msg.sender];
    }
    function calculateStationScore(uint256 _id) public view returns(uint256){
        uint256 sum = 0;
        uint256 length = arrayStationScores[_id].length;
        for (uint i = 0; i < length; i++) {
            uint256 score = stationScores[_id][arrayStationScores[_id][i]];
            sum = sum + score;
        }
        return sum / length;
    }
    function calculateLessonScore(uint256 _id) public view returns(uint256){
        uint256 sum = 0;
        uint256 length = arrayLessonScores[_id].length;
        for (uint i = 0; i < length; i++) {
            uint256 score = LessonScores[_id][arrayLessonScores[_id][i]];
            sum = sum + score;
        }
        return sum / length;
    }
    function calculateItemScore(uint256 _id) public view returns(uint256){
        uint256 sum = 0;
        uint256 length = arrayItemScores[_id].length;
        for (uint i = 0; i < length; i++) {
            uint256 score = ItemScores[_id][arrayItemScores[_id][i]];
            sum = sum + score;
        }
        return sum / length;
    }
    //=================数组工具1===================
    function checkIfExist(address adrs, address[] memory adrss) public returns (bool){
        for (uint i = 0; i < adrss.length; i++) {
            if (adrss[i] == adrs) {
                return true;
            }
        }
        return false;
    }

}