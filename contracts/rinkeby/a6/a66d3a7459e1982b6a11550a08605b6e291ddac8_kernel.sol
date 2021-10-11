/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract kernel {
    enum State {
        COMING_SOON, // 未上市 -> 廠商新增商品
        SELLING, // 販售中 -> 通路拿到商品並註冊進ERP
        PROXY, // 代理中 -> 平台第三方託管模式
        TRANSFERABLE, // 可轉移 -> 消費者購買商品後的模式
        TRANSFERING, // 轉移中 -> 尚未定義
        BAN, // 黑名單 -> 大量複製真鞋序號
        DELETE // 刪除   -> 因某些狀況需要進行刪除(誤加)
    }

    struct Shoes {
        string CID; // 星際網路的編號
        string SN; // 商品編號
        string name; // 商品名稱
        string company; // 出產公司
        string bornFrom; // 商品產地
        uint256 bornDate; // 生產時間
        State state; // 紀錄商品狀態
        address agent; // 代理者
        address owner; // 持有者
        address buyer; // 下一個持有者(buyer)
        string lastBuyerLocation; // 最後一次轉移位置(目標位置)
        address[] ownerHistory; // 持有者歷史
    }

    // at here manager is include distributor
    struct Manager {
        string UID; // 公司編號
        address chainAddress; // 區塊鏈位址
        string country; // 隸屬國家
        uint256 bornDate; // 新增時間
        bool isBan; // 是否被禁用
    }

    event addShoesEvent(bytes32 id, address who);
    event delShoesEvent(bytes32 id, address who, string reason);
    event addManagerEvent(
        string UID,
        address manager,
        string country,
        uint256 bornDate
    );
    event addDistributorEvent(
        string UID,
        address distributor,
        string country,
        uint256 bornDate
    );
    event transferShoesEvent(
        bytes32 id,
        address from,
        address to,
        string location
    );
    event empowerShoesEvent(bytes32 shoesId, address distributor);
    event shoesRandomValueEvent(
        address distributor,
        bytes32 shoesId,
        bytes32 randomValue
    );
    event shoesRegisterEvent(bytes32 shoesId, address buyer, string location);
    event addShoesToBlackListEvent(bytes32 id, address manager, string reason);
    event modifyShoesSNEvent(bytes32 id, string newSN, address who);
    event modifyShoesNameEvent(bytes32 id, string newName, address who);
    event modifyShoesCompanyEvent(bytes32 id, string newCompany, address who);
    event modifyShoesBornFromEvent(bytes32 id, string newBornFrom, address who);
    event modifyShoesBornDateEvent(
        bytes32 id,
        uint256 newBornDate,
        address who
    );

    // ------------ admin code start ------------

    // contract owner === Headquarters
    address public contractOwner;

    // third part platform, in future it will be changed
    // I think one product mapping one agent
    address public agent;

    // total created shoes
    uint64 public shoesCount;

    // agent will change in future
    constructor() {
        contractOwner = msg.sender;
        agent = contractOwner;
        shoesCount = 0;
    }

    // record shoes data before empower
    uint64 shoesBeforeEmpowerCount = 0;
    bytes32[] public shoesInfoBeforeEmpower;

    // record shoes data before customer register
    uint64 shoesBeforeRegisterCount = 0;
    bytes32[] public shoesInfoBeforeRegister;

    // use unique id to mapping product
    mapping(bytes32 => Shoes) public shoesList;

    // use unique id to mapping manager shoesManager === sub-company
    mapping(address => Manager) public managerList;

    // use unique id to mapping manager shoesDistributor === store
    mapping(address => Manager) public distributorList;

    // shoesDistributor === distributor
    mapping(address => bool) public shoesDistributors;

    modifier isContractOwner() {
        require(msg.sender == contractOwner, "You are not Contract Owner");
        _;
    }

    // headquarters can assign management to its sub-company
    function addShoesManager(
        string memory _UID,
        address _targetAddress,
        string memory _country
    ) public isContractOwner {
        require(
            managerList[_targetAddress].bornDate == 0,
            "target is already a manager"
        );
        Manager memory shoesManager;
        shoesManager.UID = _UID;
        shoesManager.chainAddress = _targetAddress;
        shoesManager.country = _country;
        shoesManager.bornDate = block.timestamp;
        shoesManager.isBan = false;

        managerList[_targetAddress] = shoesManager;
        emit addManagerEvent(
            shoesManager.UID,
            shoesManager.chainAddress,
            shoesManager.country,
            shoesManager.bornDate
        );
    }

    function delShoesManager(address targetAddress) public isContractOwner {
        require(
            (managerList[targetAddress].isBan == false &&
                managerList[targetAddress].bornDate > 0),
            "target is not a manager"
        );

        managerList[targetAddress].isBan = true;
    }

    // ------------ manager code start ------------
    // managers usually are sub-company
    modifier isShoesManager() {
        require(
            (managerList[msg.sender].bornDate > 0 &&
                managerList[msg.sender].isBan == false),
            "You are not shoes manager"
        );
        _;
    }

    function getShoesIdByShoesAttribute(
        string memory SN,
        string memory name,
        string memory company
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(SN, name, company));
    }

    function addShoes(
        string memory _CID,
        string memory _SN,
        string memory _name,
        string memory _company,
        string memory _bornFrom
    ) public isShoesManager returns (bytes32) {
        Shoes memory newShoes;

        // use sn, name, company to create unique id
        bytes32 shoesId = getShoesIdByShoesAttribute(_SN, _name, _company);

        // check shoes is exist
        require(shoesList[shoesId].bornDate == 0, "Shose is already exist");

        // init
        newShoes.CID = _CID;
        newShoes.SN = _SN;
        newShoes.name = _name;
        newShoes.company = _company;
        newShoes.bornFrom = _bornFrom;
        newShoes.bornDate = block.timestamp;
        newShoes.state = State.COMING_SOON;
        newShoes.owner = payable(msg.sender);
        shoesList[shoesId] = newShoes;
        shoesCount++;
        emit addShoesEvent(shoesId, msg.sender);

        shoesInfoBeforeEmpower.push(shoesId);
        shoesBeforeEmpowerCount++;
        return shoesId;
    }

    modifier isShoesExist(bytes32 shoesId) {
        // use bornDate to check data is exist
        require(shoesList[shoesId].bornDate != 0, "Shoes not exist !");
        _;
    }

    function modifyShoesSN(string memory _SN, bytes32 shoesId)
        public
        isShoesManager
        isShoesExist(shoesId)
    {
        shoesList[shoesId].SN = _SN;
        emit modifyShoesSNEvent(shoesId, shoesList[shoesId].SN, msg.sender);
    }

    function modifyShoesName(string memory _name, bytes32 shoesId)
        public
        isShoesManager
        isShoesExist(shoesId)
    {
        shoesList[shoesId].name = _name;
        emit modifyShoesNameEvent(shoesId, shoesList[shoesId].name, msg.sender);
    }

    function modifyShoesCompany(string memory _company, bytes32 shoesId)
        public
        isShoesManager
        isShoesExist(shoesId)
    {
        shoesList[shoesId].company = _company;
        emit modifyShoesCompanyEvent(
            shoesId,
            shoesList[shoesId].company,
            msg.sender
        );
    }

    function modifyShoesBornFrom(string memory _bornFrom, bytes32 shoesId)
        public
        isShoesManager
        isShoesExist(shoesId)
    {
        shoesList[shoesId].bornFrom = _bornFrom;
        emit modifyShoesBornFromEvent(
            shoesId,
            shoesList[shoesId].bornFrom,
            msg.sender
        );
    }

    function modifyShoesBornDate(uint256 _bornDate, bytes32 shoesId)
        public
        isShoesManager
        isShoesExist(shoesId)
    {
        shoesList[shoesId].bornDate = _bornDate;
        emit modifyShoesBornDateEvent(
            shoesId,
            shoesList[shoesId].bornDate,
            msg.sender
        );
    }

    function delShoes(bytes32 shoesId, string memory reason)
        public
        isShoesManager
        isShoesExist(shoesId)
    {
        // set state to delete
        shoesList[shoesId].state = State.DELETE;
        emit delShoesEvent(shoesId, msg.sender, reason);
    }

    // if the seller sell fake shoes, add it to black list
    mapping(bytes32 => bool) shoesBlackList;

    function addToBlackList(bytes32 targetId, string memory reason)
        public
        isShoesManager
        isShoesNotInBlackList(targetId)
    {
        // set state to BAN
        shoesList[targetId].state = State.BAN;
        shoesBlackList[targetId] = true;

        emit addShoesToBlackListEvent(targetId, msg.sender, reason);
    }

    function addShoesDistributor(
        string memory _UID,
        address _targetAddress,
        string memory _country
    ) public isShoesManager {
        require(
            distributorList[_targetAddress].bornDate == 0,
            "Target is already a Distributor"
        );

        Manager memory shoesDistributor;
        shoesDistributor.UID = _UID;
        shoesDistributor.chainAddress = _targetAddress;
        shoesDistributor.country = _country;
        shoesDistributor.bornDate = block.timestamp;
        shoesDistributor.isBan = false;

        distributorList[_targetAddress] = shoesDistributor;
        emit addDistributorEvent(
            shoesDistributor.UID,
            shoesDistributor.chainAddress,
            shoesDistributor.country,
            shoesDistributor.bornDate
        );
    }

    function delShoesDistributor(address targetAddress) public isShoesManager {
        require(
            (distributorList[targetAddress].isBan == false &&
                distributorList[targetAddress].bornDate > 0),
            "Target is not a Distributor"
        );

        distributorList[targetAddress].isBan = true;
    }

    modifier isDistributor(address target) {
        require(
            (distributorList[target].bornDate > 0 &&
                distributorList[target].isBan == false),
            "Target is not shoes distributor"
        );
        _;
    }

    // distributor get the shoes from manager
    // the state will chage from COMMING_SOON to SELLING
    function empowerShoesToDistributor(bytes32 shoesId, address distributor)
        public
        isShoesManager
        isDistributor(distributor)
    {
        shoesList[shoesId].owner = distributor;
        shoesList[shoesId].state = State.SELLING;
        emit empowerShoesEvent(shoesId, distributor);

        uint64 empowerIndex = indexOf(shoesInfoBeforeEmpower, shoesId);
        delete shoesInfoBeforeEmpower[empowerIndex];
        shoesBeforeEmpowerCount--;

        shoesInfoBeforeRegister.push(shoesId);
        shoesBeforeRegisterCount++;
    }

    function indexOf(bytes32[] memory arr, bytes32 shoesId)
        public
        pure
        returns (uint64)
    {
        uint64 i = 0;
        while (arr[i] != shoesId && i < arr.length) {
            i++;
        }
        return i;
    }

    // ------------ distributor code start ------------

    // distributor how to sell the shoes?
    // local server create a random value and upload it to blockchain after hash
    // finally use that hash to register the shoes
    mapping(bytes32 => bytes32) public randomValueOfShoes;

    modifier isShoesCanSell(bytes32 shoesId) {
        require(
            shoesList[shoesId].state == State.SELLING,
            "The shoes state is not correct !"
        );
        _;
    }

    // this function is called when buyer buy the shoes
    // rv need to hash before input into contract or everybody will know the rv
    function setShoesRandomValue(bytes32 shoesId, bytes32 randomValueHash)
        public
        isDistributor(msg.sender)
        isShoesCanSell(shoesId)
    {
        randomValueOfShoes[shoesId] = randomValueHash;
        emit shoesRandomValueEvent(msg.sender, shoesId, randomValueHash);
    }

    // ------------ distributor code end ------------

    // ------------ buyer code start ------------

    // user need to input the randomValue to register his shoes
    // the state will chage from SELLING to TRANSFERABLE
    function registerShoes(
        bytes32 shoesId,
        string memory randomValue,
        string memory location
    ) public isShoesCanSell(shoesId) {
        if (
            randomValueOfShoes[shoesId] ==
            keccak256(abi.encodePacked(randomValue))
        ) {
            shoesList[shoesId].owner = payable(msg.sender);
            shoesList[shoesId].state = State.TRANSFERABLE;
            shoesList[shoesId].ownerHistory.push(msg.sender);
            shoesList[shoesId].lastBuyerLocation = location;
            emit shoesRegisterEvent(shoesId, msg.sender, location);

            uint64 index = indexOf(shoesInfoBeforeRegister, shoesId);
            delete shoesInfoBeforeRegister[index];
            shoesBeforeRegisterCount--;
        }
    }

    function getByte32Hash(string memory temp) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(temp));
    }

    // ------------ buyer code end ------------

    // ------------ seller code start ------------

    mapping(bytes32 => uint64) public shoesPrice;

    // The modifier is use to pretreatment before call function
    // so it won't return any data
    modifier isProductOwner(bytes32 shoesId) {
        require(
            shoesList[shoesId].owner == msg.sender,
            "You are not product owner !"
        );
        _;
    }

    modifier isBuyer(bytes32 shoesId) {
        require(
            shoesList[shoesId].buyer == msg.sender,
            "You are not next owner !"
        );
        _;
    }

    modifier isShoesNotInBlackList(bytes32 shoesId) {
        require(!shoesBlackList[shoesId], "This shoes is in black list !");
        _;
    }

    modifier isShoesTransferable(bytes32 shoesId) {
        require(
            shoesList[shoesId].state == State.TRANSFERABLE,
            "This shoes can't be transfer !"
        );
        _;
    }

    modifier isShoesInProxyState(bytes32 shoesId) {
        require(
            shoesList[shoesId].state == State.PROXY,
            "You didn't transfer asset to platform"
        );
        _;
    }

    modifier isAgent() {
        require(agent == msg.sender, "You are not angent !");
        _;
    }

    modifier isBuyerNotExist(bytes32 shoesId) {
        require(
            shoesList[shoesId].buyer == address(0),
            "Other Buyer is buying"
        );
        _;
    }

    // case1: face to face trade
    function transferShoesByOwner(
        bytes32 shoesId,
        address payable buyer,
        string memory location
    )
        public
        isProductOwner(shoesId)
        isShoesNotInBlackList(shoesId)
        isShoesTransferable(shoesId)
    {
        shoesList[shoesId].owner = buyer;
        shoesList[shoesId].lastBuyerLocation = location;
        shoesList[shoesId].ownerHistory.push(buyer);

        emit transferShoesEvent(shoesId, msg.sender, buyer, location);
    }

    // case2: shopping on online
    // setting the price that user want to sell
    function setShoesPrice(bytes32 shoesId, uint64 price)
        internal
        returns (bool)
    {
        // if price alredy set return false
        if (shoesPrice[shoesId] != 0) {
            return false;
        } else {
            shoesPrice[shoesId] = price;
            return true;
        }
    }

    // seller transfer asset to contract
    function transferShoesToContract(
        bytes32 shoesId,
        uint64 price,
        string memory location
    )
        public
        isProductOwner(shoesId)
        isShoesNotInBlackList(shoesId)
        isShoesTransferable(shoesId)
        returns (bool)
    {
        if (setShoesPrice(shoesId, price)) {
            // set shoes to agent state
            shoesList[shoesId].state = State.PROXY;
            shoesList[shoesId].agent = agent;
            shoesList[shoesId].lastBuyerLocation = location;
            return true;
        }
        return false;
    }

    // ------------ buyer code start ------------

    // need to set a time limit for buyer if other people want to buy
    // the buyer will call this function
    function buyShoesFromProxy(bytes32 shoesId)
        public
        isShoesInProxyState(shoesId)
        isBuyerNotExist(shoesId)
    {
        shoesList[shoesId].buyer = msg.sender;
    }

    // buyer transfer money to contract
    function payForShoes(bytes32 shoesId) public payable isBuyer(shoesId) {
        // check the price that is more than 0
        require(
            shoesPrice[shoesId] != 0,
            "The shoes price can't be 0, please check the price"
        );

        require(shoesPrice[shoesId] == msg.value, "Price not match!");
        // @todo 付款應該改成這樣，就可以省去判斷
        // msg.sender.transfer(shoesPrice[shoesId]);
    }

    // before pay the money
    function cancelOrderByBuyer(bytes32 shoesId) public isBuyer(shoesId) {
        shoesList[shoesId].buyer = address(0);
    }

    // buyer already check the product and confirm money to seller
    function confirmOrder(bytes32 shoesId) public payable isBuyer(shoesId) {
        // @todo
        // 合約發錢到賣家帳戶，可能需要加個判斷
        payable(shoesList[shoesId].owner).transfer(shoesPrice[shoesId]);

        emit transferShoesEvent(
            shoesId,
            shoesList[shoesId].owner,
            shoesList[shoesId].buyer,
            shoesList[shoesId].lastBuyerLocation
        );

        // set new owner to buyer and init other attribute
        shoesList[shoesId].owner = shoesList[shoesId].buyer;
        shoesList[shoesId].buyer = address(0);
        shoesList[shoesId].agent = address(0);
        shoesList[shoesId].ownerHistory.push(shoesList[shoesId].owner);
        shoesList[shoesId].state = State.TRANSFERABLE;
        shoesPrice[shoesId] = 0;
    }

    bytes32[] reportList;
    mapping(bytes32 => string) reportReason;

    // report order
    function reportOrder(bytes32 shoesId, string memory reason)
        public
        isBuyer(shoesId)
    {
        reportReason[shoesId] = reason;
        reportList.push(shoesId);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getAddressBalance(address target) public view returns (uint256) {
        return target.balance;
    }

    function getShoesOwnersHistory(bytes32 shoesId)
        public
        view
        returns (address[] memory)
    {
        return shoesList[shoesId].ownerHistory;
    }
}