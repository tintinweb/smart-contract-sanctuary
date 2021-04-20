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
import "./Article.sol";
import "./PixelGame.sol";

contract Platform is AbPlatform {
    address owner;
    address lastSender;
    Member members;
    Article article;
    PixelGame pixelGame;
    uint256 postNewsDeposit = 2 wei;
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
        bool isAgree,
        string personalInformation,
        string replyContent
    );
    event enrollReviewerEvent(
        uint256 indexed reviewerId,
        uint256 indexed memberDbId,
        address indexed addr,
        bool isAgree,
        string data,
        string replyContent
    );

    // event NewsEvent(
    //     uint256 indexed newsId,
    //     string indexed title,
    //     string indexed author,
    //     uint256 index,
    //     uint256 newsType,
    //     string data,//title author
    //     uint256 deposit
    // );
    event PixelGameEvent(
       uint id,
       address[] authorAddr,
       uint[] pos,
       PixelColor[] color
    );
    event NewsEvent(
        uint256 indexed newsId,
        uint256 indexed memberId,
        address indexed authorAddr,
        ArticleType articleType,
        NewsType newsType,
        uint256 index,
        string data, //title authorName content time tags
        uint256 deposit,
        bytes img
    );
    event NewsEventImage(
        uint256 indexed newsId,
        uint256 indexed index,
        string content1,
        string content2
    );
    event CommentEvent(
        uint256 indexed articleId,
        uint256 indexed memberId,
        address authorAddr,
        string content,
        string time
    );
    event LikeArticleEvent(
        uint256 indexed articleId,
        uint256 indexed memberId,
        address authorAddr
    );
    event ApplyReportedNewsEvent(
        uint256 indexed dbId,
        uint256 indexed articleId,
        string evidence
    );
    event ApplyReportedNewsResultEvent(
        uint256 indexed dbId,
        uint256 indexed articleId,
        string evidence,
        ArticleReportStatus status,
        string decisionReason
    );
    event LotteryEvent(
         address indexed addr,
         uint256 indexed memberId,
         uint256 indexed lotteryNumber
    );


    modifier onlyOwner {
        //  require(msg.sender == owner);
        _; // 標示哪裡會呼叫函式
    }

    constructor() {
        owner = 0xaAa5Ade1E5949F1192D688703E7B9f290A043803;
        members = new Member(owner);
        article = new Article(owner);
        pixelGame=new PixelGame(owner);
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
        uint256 reviewerId,
        uint256 memberId,
        address addr,
        string calldata data,
        string calldata replyContent,
        bool isAgree
    ) public onlyOwner {
        members.enrollReviewer(reviewerId, memberId, addr, isAgree);
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

   
    function paidArticleDeposit(uint256 articleId) public payable {
        require(msg.value >= postNewsDeposit, "you don't paid enough deposit");
        article.paidArticleDeposit(articleId, msg.sender, msg.value);
    }

    function getPaidArticleDepositKeys()
        public
        view
        returns (uint256[] memory)
    {
        return article.getPaidArticleDepositKeys();
    }

    function postNews(
        uint256 articleId,
        uint256 memberId,
        address authorAddr,
        uint256 index,
        string calldata data, //title authorName content time tags
        bytes calldata img
    ) public onlyOwner {
        //    require(msg.value >= postNewsDeposit, "you don't paid enough deposit");
        uint256 deposit = article.getPaidArticleDeposit(articleId);
        (uint256 index, bool isSucessfulPostNews, bool isFirstPostNews) =
            article.postNews(
                articleId,
                memberId,
                msg.sender,
                NewsType.unreview,
                deposit
            );

        if (isSucessfulPostNews) {
            if (isFirstPostNews) {
                members.postNews(authorAddr, articleId);
            }

            emit NewsEvent(
                articleId,
                memberId,
                authorAddr,
                ArticleType.news,
                NewsType.unreview,
                index,
                data,
                deposit,
                img
            );
            article.removePaidArticleDeposit(articleId);
        }
    }

    function setNewsWantToKnownAmount(address addr, uint256 newsId)
        public
        onlyOwner
    {
        require(article.isNewsExist(newsId), "article is not exist");
        article.setWantToKnownAmount(newsId);
    }

    function comment(
        uint256 articleId,
        uint256 memberId,
        address authorAddr,
        string calldata content,
        string calldata time
    ) public onlyOwner {
        require(members.isMember(authorAddr), "you aren't member");
        emit CommentEvent(articleId,memberId,authorAddr,content,time);
    }
    function likeArticle(
        uint256 articleId,
        uint256 memberId,
        address authorAddr
    ) public onlyOwner {
        require(members.isMember(authorAddr), "you aren't member");
        emit LikeArticleEvent(articleId,memberId,authorAddr);
    }
    function getNewsAmout() public view returns (uint256) {
        return article.getNewsAmout();
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
            (endIndex - startIndex) <= getAllNewsId().length,
            "over newsid amout"
        );
        (uint256[maximumAmountOfOneRequest] memory array, uint256 amount) =
            article.getRangeNewsId(startIndex - 1, endIndex - 1);
        return (array, amount);
    }
    function getAllNewsDataKeys() public view returns(uint[] memory){
        return article.getAllNewsDataKeys();
    }

    function getOwnerAddr() public view returns (address) {
        return owner;
    }

    function getLastSender() public view returns (address) {
        return lastSender;
    }

    function getAllNewsId() public view returns (uint256[] memory) {
        return article.getAllNewsId();
    }

    function clearAllData() public onlyOwner {
        members.removeAllMember();
        article.removeAllArticle();
    }

    function getVistorLen() public onlyOwner returns (uint256) {
        return members.getVistorLen();
    }

    function applyReportedNews(
        uint256 dbId,
        uint256 articleId,
        string calldata evidence
    ) public onlyOwner {
        emit ApplyReportedNewsEvent(dbId, articleId, evidence);
    }

    function applyReportedNewsResult(
        uint256 dbId,
        uint256 articleId,
        string calldata evidence,
        ArticleReportStatus status,
        string calldata decisionReason
    ) public onlyOwner {
        emit ApplyReportedNewsResultEvent(
            dbId,
            articleId,
            evidence,
            status,
            decisionReason
        );
    }


    function setPixelGame( address[] calldata authorAddr,
        uint[] calldata pos,
        PixelColor[] calldata color) public   onlyOwner {
        uint256 pixelGameKey=pixelGame.setPixelGame();
        emit PixelGameEvent(pixelGameKey,authorAddr,pos,color);
       
    }
     function getPixelGameKeys()public view returns(uint256[] memory){
        return pixelGame.getPixelGameKeys();
    }
     function random(uint256 nonce) private view returns (uint256) {
        uint256 randomnumber =
            uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
            ) % nonce;
      
        return randomnumber;
    }
    function lottery(uint memberId)
       public  onlyOwner

        returns (uint)
    {
        uint lotteryNumber=random(4);
        emit  LotteryEvent(msg.sender,memberId,lotteryNumber);
        return  lotteryNumber;
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

    function nothing1() public view returns (uint256, bool) {
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