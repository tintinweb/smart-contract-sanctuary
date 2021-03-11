/*
 勳章階級:每200分跳一階級且稱號改變
 信譽分數:發布者每發佈一則真新聞，信譽分數加50分，假新聞則扣50分
 使用者經驗值:
    1.每則新聞留言，則加經驗值0.1分，限定一次
    2.成功舉發假新聞則加50分
 使用者所有歷程上鏈到區塊鍊中，確保資料無法更改，且使用紀錄可隨意檢視:
    Publisher:新聞機構名稱、成立宗旨、申請結果、申請失敗的原因、發佈的新聞資料
    Reviewer:申請主題、申請原因、申請時間、審查者、審查者的回覆、申請結果、追蹤者
    Vistor:投票紀錄、投票時間、留言紀錄、留言時間、任務紀錄、舉發內容、經驗值紀錄
 發佈新聞規則:
    1.確認是合格發佈者
    2.抵押押金
    3.將新聞內容、留言紀錄進行上鏈發佈
 發錢規則:  
    1.有人質疑新聞，提交相關證據到合約上，付保證金
    2.該則新聞進入待審核區，系統會依據新聞種類隨機推播給符合相關背景的審核者，審核者接取審查任務進行驗證，並給予審查結果與原因後
    3.等待該則新聞觀看人數超過50人，進入投票
    4.如果該則新聞被多數人和審查者同意該則新聞為假新聞，則進行發幣，審查者與檢舉者各得押金50%且經驗值加50分，該則新聞發佈者的信譽份數扣50分，如果投票結果與審核者捨何不同，則從第2項開始
*/
pragma solidity ^0.7.0;
//pragma abicoder v2;
import "./AbPlatform.sol";
import "./Member.sol";
import "./NewsData.sol";

contract Platform is AbPlatform {
    address owner;
    address lastSender;
    Member members;
    NewsData news;
    uint256 postNewsDeposit = 1 wei;
    event applyReviewerEvent(
        address indexed addr,
        uint256 indexed reviewerId,
        uint256 indexed memberDbId,
        uint256 index,
        string applyContents
    );
    event applyPublisherEvent(
        address indexed addr,
        uint256 indexed publisherId,
        uint256 indexed memberDbId,
        uint256 index,
        string personalInformation
    );
    event enrollVistorEvent(
        uint256 indexed memberId,
        address indexed addr,
        string time
    );

    event enrollPublisherEvent(
        uint256 indexed publisherId,
        uint256 indexed memberDbId,
        address indexed addr,
        bool  isAgree,
        string personalInformation,
        string replyContent
    );
   event enrollReviewerEvent(
        uint256 indexed reviewerId,
        uint256 indexed memberDbId,
        address indexed addr,
        bool  isAgree,
        string data,
        string replyContent
    );
   

    event NewsEvent(
        uint256 indexed newsId,
        string indexed title,
        string indexed author,
        uint256 index,
        uint256 newsType,
        string data,
        uint256 deposit
    );
    event NewsEventImage(
        uint256 indexed newsId,
        uint256 indexed index,
        string content1,
        string content2
    );
    event CommentEvent(
        uint256 dbId,
        uint256 articleId,
        address authorAddr,
        string content,
        string time
    );

    modifier onlyOwner {
        //  require(msg.sender == owner);
        _; // 標示哪裡會呼叫函式
    }

    constructor() {
        owner = mockOwner;
        members = new Member(owner);
        news = new NewsData(owner);
        //news = new NewsData();
    }

    function isMember(address addr) public view returns (bool) {
        return members.isMember(addr);
    }

    function isReviewer(address addr) public view returns (bool) {
        return members.isReviewer(addr);
    }

    function isPublisher(address addr) public view returns (bool) {
        return members.isPublisher(addr);
    }

    function applyReviewerIsExist(address addr) public view returns (bool) {
        return members.applyReviewerIsExist(addr);
    }

    function getApplyReviewers() public view returns (address[] memory) {
        return members.getApplyReviewers();
    }

    function applyReviewer(
        uint256 reviewerId,
        uint256 memberId,
        address addr,
        string calldata applyContents
    ) public onlyOwner {
        members.applyReviwer(reviewerId, memberId, addr, applyContents);
        uint256 index = members.getApplyReviewerIndex(addr);
        emit applyReviewerEvent(
            addr,
            reviewerId,
            memberId,
            index,
            applyContents
        );
    }

    

    function enrollVistor(
        uint256 memberId,
        address addr,
        bool isAgree,
        string calldata time
    ) public onlyOwner {
        // lastSender = msg.sender;
        if (members.enrollVistor(memberId, addr, isAgree, time)) {
            emit enrollVistorEvent(memberId, addr, time);
        }
    }

    function enrollReviewer(
        uint reviewerId,uint memberId,address addr,string calldata data,string calldata replyContent,bool isAgree
    ) public onlyOwner {
    
        members.enrollReviewer(
         reviewerId,
         memberId,
         addr,
         isAgree
        );
        emit enrollReviewerEvent(
         reviewerId,
         memberId,
         addr,
         isAgree,
         data,
         replyContent
        );
    }

    function enrollPublisher(
        uint256 publisherId,
        uint256 memberId,
        address addr,
        string calldata personalInformation,
        string calldata replyContent,
        bool isAgree
    ) public onlyOwner {
        members.enrollPublisher(publisherId, memberId, addr, isAgree);
        emit enrollPublisherEvent(
            publisherId,
            memberId,
            addr,
            isAgree,
            personalInformation,
            replyContent
        );
    }

    function getVistors() public view returns (address[] memory) {
        return members.getVistors();
    }

    function getReviewers() public view returns (address[] memory) {
        return members.getReviewers();
    }

    function getApplyPublishers() public view returns (address[] memory) {
        return members.getApplyPublishers();
    }

    function getPublishers() public view returns (address[] memory) {
        return members.getPublishers();
    }

    function applyPublisher(
        uint256 publisherId,
        uint256 memberId,
        address addr,
        string calldata personalInformation
    ) public onlyOwner {
        // require(msg.value >= postNewsDeposit, "you don't paid enough money");

        require(
            members.applyPublisherIsExist(addr) == false,
            "Your apply is underreviwe"
        );
        uint256 index = members.getApplyPublisherIndex(addr);

        emit applyPublisherEvent(
            addr,
            publisherId,
            memberId,
            index,
            personalInformation
        );
        members.applyPublisher(publisherId, memberId, addr);
    }

    function postNews(
        uint256 newsId,
        string calldata title,
        string calldata author,
        string calldata data,
        string calldata img1,
        string calldata img2
    ) public payable {
        require(msg.value >= postNewsDeposit, "you don't paid enough deposit");
        // require(members.isReviewers(msg.sender), "you aren't reviewers");
        uint256 index =
            news.postNews(newsId, author, NewsType.unreview, msg.value);
        emit NewsEvent(
            newsId,
            title,
            author,
            index,
            uint256(NewsType.unreview),
            data,
            msg.value
        );
        emit NewsEventImage(newsId, index, img1, img2);
    }

    function setNewsWantToKnownAmount(address addr, uint256 newsId)
        public
        onlyOwner
    {
        require(news.isNewsExist(newsId), "news is not exist");
        news.setWantToKnownAmount(newsId);
    }

    function comment(
        uint256 dbId,
        uint256 articleId,
        address authorAddr,
        string calldata content,
        string calldata time
    ) public onlyOwner {
        require(members.isMember(msg.sender), "you aren't member");
        news.comment(dbId, articleId, authorAddr, content, time);
    }

    function getNewsAmout() public view returns (uint256) {
        return news.getNewsAmout();
    }

    function getRangeNewsId(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (uint256[maximumAmountOfOneRequest] memory, uint256)
    {
        require(
            (endIndex - startIndex) + 1 < maximumAmountOfOneRequest,
            "over request amout"
        );
        require(
            (endIndex - startIndex)  <= getAllNewsId().length,
            "over newsid amout"
        );
        (uint256[maximumAmountOfOneRequest] memory array, uint256 amount) =
            news.getRangeNewsId(startIndex - 1, endIndex - 1);
        return (array, amount);
    }

    function getOwnerAddr() public view returns (address) {
        return owner;
    }

    function getLastSender() public view returns (address) {
        return lastSender;
    }

    function getAllNewsId() public view returns (uint256[] memory) {
        return news.getAllNewsId();
    }

    function removeAllMember() public onlyOwner {
        members.removeAllMember();
    }

    function getVistorLen() public onlyOwner returns (uint256) {
        return members.getVistorLen();
    }

    /******************************************* */
    uint256 count = 101;
    event TestEvent(uint256 indexed id, uint256 data);
    event TestFunctionEvent(uint256 indexed id, uint256 num, string str);

    function setTestEvent(uint256 data) public returns (uint256) {
        emit TestEvent(count, data);
        count++;
        return data;
    }

    function setTestFunction(uint256 num, string calldata str) public payable {
        require(msg.value >= postNewsDeposit, "you don't paid enough deposit");
        // require(members.isReviewers(msg.sender), "you aren't reviewers");
        emit TestFunctionEvent(count, msg.value, str);
        count++;
    }

    function getTestData() public view returns (uint256, bool) {
        return members.getTestData();
    }
    /* uint count=0;
        for(uint i=endIndex-1;i>=startIndex;i--){
            uint id= newsDataKeys[i];
            if(newsData[id].isExist==true){
                data[count]=newsData[id];
            }
        }*/

    /*  modifier   onlyOwner {
        require(msg.sender == owner);
        _; // 標示哪裡會呼叫函式
    }*/
}