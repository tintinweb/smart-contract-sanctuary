pragma solidity ^0.4.24;

contract Sacrific3d {

    struct Stage {
        uint8 cnt;//人数
        uint256 blocknumber;//区块号
        bool isFinish;//是否完成
        mapping (uint8 => address) playerMap;//这一轮参加的人数，key是第几个，内容是地址
        mapping (address => bool)  isBuyMap;//主要是判断这个人是否参与过，一轮里一个地址只能参加一次
    }

    //P3d的地址
    HourglassInterface constant p3dContract = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);

    uint8 constant public MAX_PLAYERS = 3;
    uint256 constant public OFFER_SIZE = 0.1 ether;

    uint256 private p3dValue_ = 0.019 ether;
    uint256 private referredValue_ = 0.007 ether;
    uint256 public winValue_ = 0.13 ether;

    mapping(address => uint256) private valueMap_;//记录参加人的余额
    mapping(address => uint256) private referredMap_;//介绍奖励账本
    mapping(address => address) private addressMap_;//介绍奖励账本
    mapping(uint256 => Stage) private stageMap_;//关卡Map
    uint256 private indexFinish;//完成的关卡数
    uint256 public  index;//关卡数

    event SacrificeOffered(address indexed player);
    event SacrificeChosen(address indexed sarifice);
    event EarningsWithdrawn(address indexed player, uint256 indexed amount);
    event StageInvalidated(uint256 indexed stage);

    modifier isValidOffer() //检查发送是否为0.1
    {
        require(msg.value == OFFER_SIZE);
        _;
    }

    modifier canPayFromVault()//地址余额大于0.1
    {
        require(valueMap_[msg.sender] >= OFFER_SIZE);
        _;
    }

    modifier hasEarnings()//有收入
    {
        require(valueMap_[msg.sender] > 0);
        _;
    }

    modifier prepareStage() //检查上一轮是否完成，完成则进行新轮的初始化
    {
        //create a new stage if current has reached max amount of isBuyMap
        if(stageMap_[index - 1].cnt == MAX_PLAYERS) {
            stageMap_[index] = Stage(0, 0, false);
            index++;
        }
        _;
    }

    modifier isNewToStage() //检查现在这轮参加的玩家是否有发送者，一轮里一个地址只能参加一次
    {
        require(stageMap_[index - 1].isBuyMap[msg.sender] == false);
        _;
    }

    constructor()
    public
    {
        stageMap_[index] = Stage(0, 0, false);
        index++;
    }

    function() external payable {}

    function offerAsSacrifice(address _referredBy)//购买牺牲用ETH
    external
    payable
    isValidOffer//检查是否有效
    prepareStage//检查是否重启
    isNewToStage//这轮是否参与了
    {
        acceptOffer();

        //try to choose a sacrifice in an already full stage (finalize a stage)
        tryFinalizeStage();

        if(addressMap_[msg.sender] == 0){
            if(_referredBy != 0x0000000000000000000000000000000000000000 && _referredBy != msg.sender && valueMap_[_referredBy] >= 0){
                addressMap_[msg.sender] = _referredBy;
            } else {
                addressMap_[msg.sender] = 0x0000000000000000000000000000000000000000;//官方推荐地址
            }
        }
    }

    function offerAsSacrificeFromVault()//购买牺牲用在智能合约里的余额
    external
    canPayFromVault//余额里大于0.1Eth
    prepareStage//检查是否重启
    isNewToStage//这轮是否参与了
    {
        valueMap_[msg.sender] -= OFFER_SIZE;

        acceptOffer();

        tryFinalizeStage();
    }

    function withdraw()//体现
    external
    hasEarnings//余额是否大于0
    {
        tryFinalizeStage();

        uint256 amount = valueMap_[msg.sender];
        valueMap_[msg.sender] = 0;

        emit EarningsWithdrawn(msg.sender, amount);

        msg.sender.transfer(amount);
    }

    function myEarnings()//查询余额
    external
    view
    hasEarnings//余额是否大于0
    returns(uint256)
    {
        return valueMap_[msg.sender];
    }

    function currentPlayers()//当前关卡参加的人数
    external
    view
    returns(uint256)
    {
        return stageMap_[index - 1].cnt;
    }

    function acceptOffer()//购买 牺牲用ETH或者余额
    private
    {
        Stage storage currentStage = stageMap_[index - 1];

        //当前轮的人数，必须小于5
        assert(currentStage.cnt < MAX_PLAYERS);

        address player = msg.sender;

        //add player to current stage
        currentStage.playerMap[currentStage.cnt] = player;
        currentStage.cnt++;
        currentStage.isBuyMap[player] = true;

        emit SacrificeOffered(player);

        //add blocknumber to current stage when the last player is added
        if(currentStage.cnt == MAX_PLAYERS) {
            currentStage.blocknumber = block.number;
        }
    }

    //试着在一个完整的阶段选择一个祭品（完成一个阶段）
    //算出哪一个是祭品
    function tryFinalizeStage()
    private
    {
        assert(index >= indexFinish);

        //there are no stageMap_ to finalize
        if(index == indexFinish) {return;}

        Stage storage stageToFinalize = stageMap_[indexFinish];

        assert(!stageToFinalize.isFinish);

        //stage is not ready to be isFinish
        if(stageToFinalize.cnt < MAX_PLAYERS) {return;}

        assert(stageToFinalize.blocknumber != 0);

        //check if blockhash can be determined
        //检查是否可以确定块哈希值
        if(block.number - 256 <= stageToFinalize.blocknumber) {
            //blocknumber of stage can not be equal to current block number -> blockhash() won&#39;t work
            if(block.number == stageToFinalize.blocknumber) {return;}

            //determine sacrifice
            uint8 sacrificeSlot = uint8(blockhash(stageToFinalize.blocknumber)) % MAX_PLAYERS;
            address sacrifice = stageToFinalize.playerMap[sacrificeSlot];

            emit SacrificeChosen(sacrifice);

            //allocate winnings to survivors
            allocateSurvivorWinnings(sacrifice);

            //allocate p3d dividends to sacrifice if existing
            uint256 dividends = p3dContract.myDividends(true);
            if(dividends > 0) {
                p3dContract.withdraw();
                valueMap_[sacrifice]+= dividends;
            }

            //purchase p3d (using ref)
            p3dContract.buy.value(p3dValue_)(address(0x1EB2acB92624DA2e601EEb77e2508b32E49012ef));


        } else {
            invalidateStage(indexFinish);

            emit StageInvalidated(indexFinish);
        }
        //finalize stage
        stageToFinalize.isFinish = true;
        indexFinish++;
    }

    //分配给幸存者
    function allocateSurvivorWinnings(address sacrifice)//参数：祭品地址
    private
    {
        for (uint8 i = 0; i < MAX_PLAYERS; i++) {
            address survivor = stageMap_[indexFinish].playerMap[i];
            if(survivor != sacrifice) {
                valueMap_[survivor] += winValue_;
            }
            //增加分享奖励逻辑
            address referred= addressMap_[survivor];
            valueMap_[referred] += referredValue_;
        }
    }

    //无效的关卡
    function invalidateStage(uint256 stageIndex)
    private
    {
        Stage storage stageToInvalidate = stageMap_[stageIndex];

        for (uint8 i = 0; i < MAX_PLAYERS; i++) {
            address player = stageToInvalidate.playerMap[i];
            valueMap_[player] += OFFER_SIZE;
        }
    }
}

interface HourglassInterface {
    function buy(address _playerAddress) payable external returns(uint256);
    function withdraw() external;
    function myDividends(bool _includeReferralBonus) external view returns(uint256);
}