/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;
pragma abicoder v2;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

struct Partner {
    string name;
    string role;
    address payable wallet;
    uint256 percentual;
    uint256 lastPayment; //timestamp
}

struct TwinPromess {
    uint256 id;
    address owner;
    uint256 tokenAmount;
    uint256 when; //numero do ciclo no qual ficara disponvivel o twin
    bool isFulfilled;
}

enum ClassType {
    Visitor,
    Apprentice,
    Fellowcraft,
    Master,
    Master33,
    SupremeI,
    SupremeII,
    Gmw
}

struct Class {
    ClassType _class;
    uint256 membershipPrice;
    uint256 minPurchase;
    uint256 invites;
    uint256 membershipPeriod; // quantidade de segundos
    bool lockable;
    uint256 waitPeriod; //time to wait to receive Twin Token .***Not in timestamp but in blocks**
}

struct MemberCard {
    uint256 id;
    address wallet;
    address nodeInstance;
}

struct Member {
    MemberCard memberCard;
    uint256 invites;
    bool isActive;
    ClassType class;
    uint256 initDay;
    uint256 expireDay;
    address[] uncleList;
    uint256 pendigComission; //Quantidade de Gvena ser recebida pelas indicacoes
}

interface ICommunity {
    function isAssoc(address _assocWallet) external view returns (bool _b);

    function initAssoc(address _newAssoc) external payable;

    function isRegisteredService(address _addr) external view returns (bool _b);

    function buyCoins(address _assoc) external payable;

    function classUpgrade(address _assoc) external payable;

    function buyInvitesPackage(address _assoc) external payable;

    function revalidateMember(address _assoc) external payable;

    function claimComissions(address _assoc) external;

    /* */
    function resolvePromise(address member) external payable;

    function registerService(string memory _srvName) external payable;

    function cycleIncreaseCounter() external returns (uint256);

    function soldAmount() external returns (uint256);

    //when Gven is burnned this fuction is called so that community can update members ballance, allowing for retrival of the BNB balance.
    function onTwinBurn(address member, uint256 TokenAmount) external;
}

interface IGvenToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mintForCreators() external;
    //function balanceOf(address who) view external returns (uint256 tokenBalance) ;
}

interface IMemberWallet {
    function lockMw(bool state_, address who_) external payable;

    function makeLockable() external;
}

interface ITwinTokenPromess {
    function mint(
        address account,
        uint256 tokenId,
        uint256 amount,
        uint256 when
    ) external;

    function resolvePromise(address _who) external;

    //transfers the promess partially
    function partialTransferFrom(
        address from,
        address receiver,
        uint256 amount
    ) external;
}

interface ITwinToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract Community is ICommunity {
    using SafeMath for uint256;
    IGvenToken private token;
    ITwinTokenPromess _twinPromess;
    address private twinToken;
    //uint public tokenPrice;
    string _contractName = "Gven Smart Community";

    Splitter creatorsWallet;
    address owner;
    address _adminAddress;
    uint256 _creatorsBalance;
    uint256 creatorsPercentual;
    uint256 refundPercentual;
    address _gmw;
    bool _isSetGmw = false;

    //Mapea a carteira para o nodeInstance;
    MemberCard[] stwrdBook;
    mapping(address => Member) associates; //**//

    uint256 _assocCounter;
    uint256 _totalReceived;
    uint256 _cycleIncreaseCounter;
    uint256 _minCycleToBurn;
    uint256 _currentCycle;
    uint256 _soldAmount;
    // uint256 _totalSales;
    uint256 _refundReserve;
    event newAssociation(address indexed _sm);
    event priceChange(uint256); //By lookng at what cycle we can figure out what is the ne price, as thy are linked
    event walletChanged(address);

    //Affiliates

    //niveis
    uint256 levels;
    uint256 maxCommissions; //Maximmum amount of comission to pay affiliates;

    mapping(ClassType => Class) classes; //ClassType(int) =>Class
    int256 classCounter = 0;
    //percentuais por nivel, em ordem crescente ( nivel1 na posicao 0, nivel 2 na posicao 1, etc)

    mapping(ClassType => uint256[]) rewardsMapping;
    uint256[] reward;
    address[] tempList;
    //Affiliate Invitation
    /*   mapping(uint => uint) public memberRemainingInvites; // Quantidade de convites por membro - member id, numb of invites */
    uint256 invitePackagePrice = 0;
    event invitesPackageBought(address, uint256); //Who, How many invites
    event classUpgraded(address, ClassType);
    event tokenPurchase(address, uint256);
    event membershipRevalidation(address);
    event eventWithdrawal(address, uint256); //member,value
    event serviceRegistered(address, string, uint256); //Contract,serviceId, srvName, tokenAmount
    event comissionDelivered(address, uint256);
    event tokenPurchaseWithBalance(address, uint256);
    //Services
    //mapping (uint => address) public services;
    mapping(address => bool) services;
    //mapping(ClassType => uint256) classMembersCount; //class=> numMembers
    uint256 _serviceBuyGvenAmount;

    ///////////PRICING//////////
    //ToDo: initialize all these variables
    // uint public currentCycle; //start from 0
    uint256 private _initialPrice; // 0.05 usd
    uint256 private _increment; // 0.001
    uint256 private _frequency; // 1M Gven
    //uint256 private _preMint;

    modifier adminOrOwner() {
        require(
            msg.sender == _adminAddress || msg.sender == owner,
            "Only admin can add members"
        );
        _;
    }

    modifier onlyToken() {
        require(
            msg.sender == address(token) || msg.sender == address(twinToken),
            "Froud attempt. Not allowed"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Back off cheater!");
        _;
    }

    modifier onlyMembers() {
        require(
            associates[msg.sender].memberCard.wallet != address(0x0),
            "Sorry, only associates are allowed"
        );
        _;
    }

    //-----------------------------------------------------
    //   Pagar os envolvidos na criacao
    //-----------------------------------------------------
    function fillDevWallet() public {
        if (_creatorsBalance > 23000) {
            creatorsWallet.collect{value: _creatorsBalance}();
            _creatorsBalance = 0;
        }
    }

    //-----------------------------------------------------
    //   Pagar os envolvidos na criacao
    //-----------------------------------------------------

    function setId(uint256 _id) internal view returns (uint256) {
        return (_id.add(SafeMath.sub(block.timestamp, 1620000000)));
    }

    constructor(Splitter _creatorsWallet, address adminAddress_) {
        _minCycleToBurn = 210;
        _totalReceived = 0;
        _cycleIncreaseCounter = 0;
        _currentCycle = 0;
        _soldAmount = 0;
        _refundReserve = 0;
        owner = msg.sender;
        _adminAddress = adminAddress_;
        creatorsWallet = _creatorsWallet;
        _creatorsBalance = 0;
        invitePackagePrice = 6340000000000000;
        _assocCounter = 0;
        creatorsPercentual = 50;
        maxCommissions = 30;
        refundPercentual = 20;
        levels = 10;
        _initialPrice = 31746030000; //
        _increment = 7925000000; //
        _frequency = 3500000; //

        _serviceBuyGvenAmount = 15849780000000000000; // valor minimo q um servicço pode oferecer é ...

        //console.log("Construct:Initializing array of class rewords");

        //Class.boss
        reward = new uint256[](levels);
        reward[0] = 10;
        reward[1] = 7;
        reward[2] = 3;
        reward[3] = 2;
        reward[4] = 2;
        reward[5] = 2;
        reward[6] = 1;
        reward[7] = 1;
        reward[8] = 1;
        reward[9] = 1;
        rewardsMapping[ClassType.Fellowcraft] = reward;

        //Class.associate
        reward = new uint256[](levels);
        reward[0] = 7;
        reward[1] = 4;
        reward[2] = 2;
        reward[3] = 2;
        reward[4] = 2;
        reward[5] = 1;
        reward[6] = 1;
        reward[7] = 1;
        reward[8] = 1;
        reward[9] = 1;
        rewardsMapping[ClassType.Apprentice] = reward;

        //Class.Visitor
        reward = new uint256[](levels);
        reward[0] = 5;
        reward[1] = 1;
        reward[2] = 1;
        reward[3] = 1;
        reward[4] = 1;
        reward[5] = 1;
        reward[6] = 1;
        reward[7] = 1;
        reward[8] = 1;
        reward[9] = 1;
        rewardsMapping[ClassType.Visitor] = reward;

        //Class.gmw
        reward = new uint256[](levels);
        reward[0] = 10;
        reward[1] = 7;
        reward[2] = 3;
        reward[3] = 2;
        reward[4] = 2;
        reward[5] = 2;
        reward[6] = 1;
        reward[7] = 1;
        reward[8] = 1;
        reward[9] = 1;
        rewardsMapping[ClassType.Gmw] = reward;

        //console.log("Construct:Initializing classes");

        //ToDo:  Reformular as classes pra acomodar duas novas classes acima de 500 dolars

        //Classes
        //initClass(ClassType.Visitor,vMBship, _vMin,3,3456000,1,0,0 ); //40 days
        /*teste*/
        initClass(
            ClassType.Visitor, /* ClassType */
            6340000000000000, /* memberShip value */
            100000, /* Minumum amount of token to purchase */
            2, /* num of availabe invites */
            3024000, /* validade da membership */
            false, /* can lock MemberWallet */
            300 /* how many cycles to wait to receive Twin Token. */
        );

        initClass(
            ClassType.Apprentice,
            79250000000000000,
            3000000,
            6,
            7344000,
            false,
            128
        );

        initClass(
            ClassType.Fellowcraft,
            190200000000000000,
            10000000,
            10, //unlimited
            11059200,
            true,
            50
        );

        initClass(
            ClassType.Gmw,
            0,
            1,
            100000000,
            31536000000000000000,
            true,
            0
        ); //centenas de anos
        //console.log("Construct:All done - leaving...");
    }

    
    //Genesis MW
    function initGenesis()  public onlyOwner { 

        require(_isSetGmw == false, "Already done!");

        _gmw = address(
            new MemberWallet(this, msg.sender, classes[ClassType.Gmw].lockable)
        );

        //console.log("GMW Addr: ", _gmw);
        //gmwUncluList
        tempList = new address[](levels);
        tempList[0] = _gmw;
        tempList[1] = _gmw;
        tempList[2] = _gmw;
        tempList[3] = _gmw;
        tempList[4] = _gmw;
        tempList[5] = _gmw;
        tempList[6] = _gmw;
        tempList[7] = _gmw;
        tempList[8] = _gmw;
        tempList[9] = _gmw;
        stwrdBook.push(
            MemberCard(
                setId(_assocCounter),
                address(creatorsWallet), //Splitter
                _gmw
            )
        );

        uint256 initDay = block.timestamp;
        uint256 expireDay = initDay.add(
            classes[ClassType.Gmw].membershipPeriod
        );

        associates[_gmw] = Member(
            stwrdBook[0],
            classes[ClassType.Gmw].invites,
            true,
            ClassType.Gmw,
            initDay,
            expireDay,
            tempList,
            0
        );  

        _assocCounter = 1;
        _isSetGmw = true;
}


    function createAssociate(
        address payable _wallet,
        address payable _mwUncle,
        ClassType _class
    ) public adminOrOwner {
        createNewAssociate(_wallet, _mwUncle, _class);
    }

    //This function must be called immediately after the token reation.
    function setTwinTokenPromessAddr(ITwinTokenPromess twinPromess_)
        public
        onlyOwner
    {
        _twinPromess = twinPromess_;
    }

    //This function must be called immediately after the token reation.
    function setGvenTokenAddr(IGvenToken token_) public onlyOwner {
        token = token_;
        //_preMint = IERC20(address(token)).totalSupply(); //
    }

    function mintForCreators() public {
        token.mintForCreators();
    }

    function createNewAssociate(
        address payable _assocWallet,
        address payable _uncle,
        ClassType _class
    ) private returns (address) {
        address newMember = address(
            new MemberWallet(this, _assocWallet, classes[_class].lockable)
        );
        _assocCounter++;
        stwrdBook.push(
            MemberCard(setId(_assocCounter), _assocWallet, newMember)
        );

        uint256 initDay = block.timestamp;
        uint256 expireDay = initDay.add(classes[_class].membershipPeriod);
        associates[newMember] = Member(
            stwrdBook[stwrdBook.length - 1],
            classes[ClassType(_class)].invites,
            true,
            _class,
            initDay,
            expireDay,
            makeUncleList(_uncle),
            0
        );

        return newMember;
    }

    function initAssoc(address _newAssoc)
        external
        payable
        override
        onlyMembers
    {
        //Verifica se usuário ainda não era membro.
        require(!isAssoc(_newAssoc), "This member is already registered");
        uint256 price = getPrice();

        uint256 creatorsComission = msg.value.percent(creatorsPercentual);
        //atualiza saldo do admin
        _creatorsBalance = _creatorsBalance.add(creatorsComission);
        //atualzia o montante que ser[a usado para devolucao]
        _refundReserve = _refundReserve.add(
            msg.value.percent(refundPercentual)
        );

        uint256 tokenAmount = msg.value.div(price);

        ClassType class = classify(tokenAmount);
        address newMember = createNewAssociate(
            payable(_newAssoc),
            msg.sender,
            class
        );
        associates[msg.sender].invites = associates[msg.sender].invites.sub(
            1,
            "Your sponsor has no invites available"
        );
        _deliverGvenToken(tokenAmount, _newAssoc, _promiseReleaseTime(class)); // Novo associado

        emit newAssociation(newMember);
        //Increments the balances of the uplines
        incrementBalance(newMember, msg.value);
        incrementTotalReceived(msg.value);
    }

    //Incrementa saldo dos uplines mas ainda nao paga
    //_assocAddr é o MW do associado que fez a compra
    function incrementBalance(address _assocAddr, uint256 _amount) internal {
        uint256 percentSpent = 0;
        uint256 auxPercent = 0;

        for (uint256 i = 0; i < levels; i++) {
            address uncleAddr = associates[_assocAddr].uncleList[i];
            if (uncleAddr != _gmw) {
                //GMW will to _creatorsBalance
                Member storage uncle = associates[uncleAddr];
                auxPercent = rewardsMapping[uncle.class][i];

                //If the member is not active they will not be added to the
                //payments queue and the value will later be added to admin
                if (block.timestamp > uncle.expireDay) {
                    uncle.isActive = false;
                    //console.log("Uncle is inactive");
                } else {
                    percentSpent = percentSpent.add(auxPercent);
                    uncle.pendigComission = uncle.pendigComission.add(
                        _amount.percent(auxPercent)
                    );
                    //console.log(
                    //    "Uncle is Active:uncle.pendigComission:",
                    //    uncle.pendigComission
                    //);
                }
            }
        }

        //entrega para a administração o valor q sobrar de usuarios com classes q pagam pouco.
        if (percentSpent < maxCommissions) {
            _creatorsBalance = _creatorsBalance.add(
                _amount.percent(maxCommissions.sub(percentSpent))
            );
        }
    }

    //comissions will be delivered when the user calls this function
    function claimComissions(address _assoc) public override {
        Member storage member = associates[stewardWelcome(_assoc)];
        address wallet = member.memberCard.wallet;

        if (member.pendigComission > 0) {
            payable(wallet).transfer(member.pendigComission);
            //console.log("claimComissions:Value ", member.pendigComission);
            emit comissionDelivered(wallet, member.pendigComission);
            member.pendigComission = 0;
        }
    }

    /********modular >>>>>>>***************/

    //users can buy more invites
    function buyInvitesPackage(address _assoc) public payable override {
        require(
            msg.value.mod(invitePackagePrice) == 0,
            "Wrong amount! Please send the exact amount for the packages price or multiples of it"
        );
        //calcula quantos pacotes
        uint256 numOfPackages = msg.value.div(invitePackagePrice);
        Member storage member = associates[stewardWelcome(_assoc)];
        member.invites = member.invites.add(numOfPackages.mul(5));

        uint256 creatorsComission = msg.value.percent(creatorsPercentual);
        //atualiza saldo do admin
        _creatorsBalance = _creatorsBalance.add(creatorsComission);
        //atualzia o montante que ser[a usado para devolucao]
        _refundReserve = _refundReserve.add(
            msg.value.percent(refundPercentual)
        );
        incrementTotalReceived(msg.value);

        emit invitesPackageBought(_assoc, numOfPackages.mul(5));
    }

    //dade expired memberships
    function revalidateMember(address _assoc) public payable override {
        address buyer = stewardWelcome(_assoc);
        require(
            msg.value == classes[associates[buyer].class].membershipPrice,
            "Wrong value sent for membership revalidation"
        );
        associates[buyer].initDay = block.timestamp;

        uint256 creatorsComission = msg.value.percent(creatorsPercentual);
        //atualiza saldo do admin
        _creatorsBalance = _creatorsBalance.add(creatorsComission);
        //atualzia o montante que ser[a usado para devolucao]
        _refundReserve = _refundReserve.add(
            msg.value.percent(refundPercentual)
        );
        incrementTotalReceived(msg.value);

        emit membershipRevalidation(_assoc);
    }

    //Users must call this fucntion to release the twin after the waitPeriod
    function resolvePromise(address _assoc) public payable override {
        _twinPromess.resolvePromise(_assoc);
    }

    receive() external payable {
        uint256 tokenPrice = getPrice();
        require(isAssoc(msg.sender), "Sorry, only members are welcome!");
        _deliverGvenToken(
            msg.value.div(tokenPrice),
            msg.sender,
            _promiseReleaseTime(associates[stewardWelcome(msg.sender)].class)
        );
        incrementBalance(stewardWelcome(msg.sender), msg.value);
        emit tokenPurchase(msg.sender, msg.value.div(tokenPrice));

        uint256 creatorsComission = msg.value.percent(creatorsPercentual);
        //atualiza saldo do admin
        _creatorsBalance = _creatorsBalance.add(creatorsComission);
        //atualzia o montante que ser[a usado para devolucao]
        _refundReserve = _refundReserve.add(
            msg.value.percent(refundPercentual)
        );
        incrementTotalReceived(msg.value);
    }

    function classUpgrade(address _assoc) public payable override {
        address buyerAddr = stewardWelcome(_assoc);
        Member storage member = associates[buyerAddr];
        ClassType currentClass = member.class;
        require(
            currentClass != ClassType(classCounter - 1),
            "Your class is already the maximum availabe"
        );

        uint256 amountReceived = msg.value;
        bool upgradeSuccesfull = false;

        Class storage newClass;
        bool acceptedValue = false;
        for (int256 i = int256(currentClass) + 1; i < classCounter; i++) {
            if (
                amountReceived ==
                classDiff(ClassType(i), currentClass, getPrice())
            ) {
                newClass = classes[ClassType(i)];
                acceptedValue = true;
                break;
            }
        }

        if (acceptedValue) {
            uint256 time_now = block.timestamp;
            uint256 remainingTime = member.expireDay.sub(time_now);
            if (remainingTime < 0) {
                remainingTime = 0;
            }

            uint256 expireDay = newClass
                .membershipPeriod
                .add(remainingTime)
                .add(time_now);
            member.class = newClass._class;
            member.expireDay = expireDay;

            uint256 creatorsComission = msg.value.percent(creatorsPercentual);
            //atualiza saldo do admin
            _creatorsBalance = _creatorsBalance.add(creatorsComission);
            //atualzia o montante que ser[a usado para devolucao]
            _refundReserve = _refundReserve.add(
                msg.value.percent(refundPercentual)
            );

            //uplines will receive commissins
            incrementBalance(
                stewardWelcome(_assoc),
                /**/
                msg.value
            );

            if (uint256(newClass._class) > 1) {
                IMemberWallet(buyerAddr).makeLockable();
                //console.log("Member Wallet Locker added to this account");
            }

            emit classUpgraded(_assoc, member.class);
            upgradeSuccesfull = true;
            incrementTotalReceived(msg.value);
        }

        if (!upgradeSuccesfull) {
            revert("Upgrade not performed");
        }
    }

    /********<<<<<<<< modular***************/

    function classDiff(
        ClassType _classA,
        ClassType _classB,
        uint256 _price
    ) public view returns (uint256) {
        uint256 weiA = classes[_classA].minPurchase.mul(_price);
        uint256 weiB = classes[_classB].minPurchase.mul(_price);

        uint256 amount = weiA.sub(weiB);
        //console.log("Class Diff", amount);
        return amount;
    }

    function classify(uint256 _tokenAmount)
        internal
        view
        returns (ClassType _class)
    {
        //console.log("classify:tokenAmount: ", _tokenAmount);
        require(
            _tokenAmount >= classes[ClassType.Visitor].minPurchase,
            "The amount sent is smaller the the minimmum allowed"
        );

        _class = ClassType(0);
        for (int256 i = classCounter - 1; i >= 0; i--) {
            //console.log("Analising Class", uint256(i));
            //console.log("Min required is ", classes[ClassType(i)].minPurchase);

            if (_tokenAmount >= classes[ClassType(i)].minPurchase) {
                //console.log("classify:tokenAmount: ", _tokenAmount);
                _class = ClassType(i);
                break;
            }
        }
        //console.log("classify:exit:the class is: ", uint256(_class));
        return _class;
    }

    function isAssoc(address _assocWallet)
        public
        view
        override
        returns (bool _b)
    {
        /*
        uint tokenAmount = token.balanceOf(_assocWallet);
        return tokenAmount > 0;
        */

        _b = false;
        //A o contrato comunidade e o a carteira owner sempre serao considerados mebros.
        if (_assocWallet == address(this)) {
            _b = true;
        } else {
            for (uint256 i = 0; i < stwrdBook.length; i++) {
                if (stwrdBook[i].wallet == _assocWallet) {
                    _b = true;
                    break;
                }
            }
        }

        return _b;
    }

    //calcular lista de uplines a receber
    function makeUncleList(address _firstUncle)
        internal
        view
        returns (address[] memory)
    {
        address[] memory list = new address[](levels);
        list[0] = _firstUncle;

        for (uint8 i = 1; i < levels; i++) {
            list[i] = associates[list[i - 1]].uncleList[0];
        }
        return list;
    }

    function getUncleList(address _who) public view returns (address[] memory) {
        return associates[_who].uncleList;
    }

    //
    function getAssociateByWallet(address _assocWallet)
        public
        view
        returns (Member memory)
    {
        return associates[stewardWelcome(_assocWallet)];
    }

    //by nodeInstance
    function getAssociateByMw(address _nodeIntance)
        public
        view
        returns (Member memory)
    {
        return associates[_nodeIntance];
    }

    /*---------------Stward-------------------*/
    //Retorna o endereço do contrato associado à carteira , ou 0x0 se a carteira estiver registrada
    function stewardWelcome(address _assocWallet)
        public
        view
        returns (address _nodeIntance)
    {
        _nodeIntance = address(0x0);
        for (uint256 i = 0; i < stwrdBook.length; i++) {
            if (stwrdBook[i].wallet == _assocWallet) {
                _nodeIntance = stwrdBook[i].nodeInstance;
                break;
            }
        }
    }

    function stewardIdToWallet(uint256 _memberId)
        public
        view
        returns (address _wallet)
    {
        _wallet = address(0x0);
        for (uint256 i = 0; i < stwrdBook.length; i++) {
            if (stwrdBook[i].id == _memberId) {
                _wallet = stwrdBook[i].wallet;
                break;
            }
        }
    }

    /*
    function changeMyWallet(address _newWallet) public{
        require(!isAssoc(_newWallet), "This wallet is already in another account");
        require(!Address.isContract(msg.sender),"Gven Accounts must be an EOA");

        bool success = false;
        MemberCard  storage mc;
        for(uint i=0; i < stwrdBook.length; i++){

            mc = stwrdBook[i];
            if(mc.wallet == msg.sender){
                mc.wallet = _newWallet;
                success = true;
                emit walletChanged(mc.nodeInstance);
            }
        }
        require(success == true, "Wallet alteration not executed....");
    }

    */

    /*---------------Stward-------------------*/

    //Gven Token has twin brother,
    function _deliverGvenToken(
        uint256 _tokenAmount,
        address _member,
        uint256 when
    ) private {
        token.mint(_member, _tokenAmount);
        _twinPromess.mint(_member, _generateId(), _tokenAmount, when);
        _soldAmount = _soldAmount.add(_tokenAmount); //total Gven sold

        setCycle();
    }

    function buyCoins(address _assoc) external payable override {
        uint256 tokenPrice = getPrice();
        require(msg.value >= tokenPrice, "Value too small!");
        require(isAssoc(_assoc), "Sorry, only members are welcome!");
        _deliverGvenToken(
            msg.value.div(tokenPrice),
            _assoc,
            _promiseReleaseTime(associates[stewardWelcome(_assoc)].class)
        );
        incrementBalance(stewardWelcome(_assoc), msg.value);
        emit tokenPurchase(_assoc, msg.value.div(tokenPrice));

        uint256 creatorsComission = msg.value.percent(creatorsPercentual);
        //atualiza saldo do admin
        _creatorsBalance = _creatorsBalance.add(creatorsComission);
        //atualzia o montante que ser[a usado para devolucao]
        _refundReserve = _refundReserve.add(
            msg.value.percent(refundPercentual)
        );
        incrementTotalReceived(msg.value);
    }

    //Coprarmais GVEN usando o saldo
    function buyFromBalance(uint256 bnbAmount) public {
        Member storage member = associates[stewardWelcome(msg.sender)];
        member.pendigComission = member.pendigComission.sub(
            bnbAmount,
            "No enough balance. Try buying a bit less"
        );
        uint256 tokenAmount = bnbAmount.div(getPrice());

        _deliverGvenToken(
            tokenAmount,
            member.memberCard.wallet,
            _promiseReleaseTime(member.class)
        );
        incrementBalance(member.memberCard.nodeInstance, bnbAmount);
        emit tokenPurchaseWithBalance(member.memberCard.wallet, tokenAmount);

        uint256 creatorsComission = bnbAmount.percent(creatorsPercentual);
        //atualiza saldo do admin
        _creatorsBalance = _creatorsBalance.add(creatorsComission);
        //atualzia o montante que ser[a usado para devolucao]
        _refundReserve = _refundReserve.add(
            bnbAmount.percent(refundPercentual)
        );
    }

    function _promiseReleaseTime(ClassType _class)
        public
        view
        returns (uint256 _when)
    {
        uint256 waitAmount = _frequency.mul(classes[_class].waitPeriod);
        _when = _soldAmount.add(waitAmount);
        //console.log("_promiseReleaseTime:when: ", _when);
    }

    //--------------support functions -------------->>>

    //////////////SERVICES///////////////

    function registerService(string memory _srvName) public payable override {
        uint256 tokenPrice = getPrice();
        require(
            msg.value >= _serviceBuyGvenAmount,
            "Error: Value under minimum"
        );

        uint256 tokenAmount = msg.value.div(tokenPrice);

        //Services must be contracts
        require(
            Address.isContract(msg.sender),
            "EOAs cannot register as service"
        );

        services[msg.sender] = true;

        _deliverGvenToken(
            tokenAmount,
            msg.sender,
            _promiseReleaseTime(ClassType(0))
        );

        emit serviceRegistered(msg.sender, _srvName, msg.value);
        //atualiza contador de total recebido
        incrementTotalReceived(msg.value);

        uint256 creatorsComission = msg.value.percent(creatorsPercentual);
        //atualiza saldo do admin
        _creatorsBalance = _creatorsBalance.add(creatorsComission);
        //atualzia o montante que ser[a usado para devolucao]
        _refundReserve = _refundReserve.add(
            msg.value.percent(refundPercentual)
        );
    }

    function isRegisteredService(address _addr)
        public
        view
        override
        returns (bool _b)
    {
        _b = false;
        //O contrato community e a carteira owner sempre serao considerados membros.
        if (services[_addr] == true) {
            _b = true;
            //console.log("isRegisteredService:True");
        }
        return _b;
    }

    function setCycle() public {
        //console.log("Setting Cycle...");
        uint256 curretCirculation = IERC20(address(token)).totalSupply();
        //uint256 tempCycle = _currentCycle;

        //If everyone burn their token
        if (curretCirculation == 0) {
            _currentCycle = 0;
        } else {
            //_currentCycle = curretCirculation.sub(_preMint).div(_frequency);
            _currentCycle = curretCirculation.div(_frequency);
        }

        if (_currentCycle > _cycleIncreaseCounter) {
            _cycleIncreaseCounter = _currentCycle;
            //new cylce
            emit priceChange(_currentCycle);
        }
    }

    function initialPrice() public view returns (uint256) {
        return _initialPrice;
    }

    function increment() public view returns (uint256) {
        return _increment;
    }

    function frequency() public view returns (uint256) {
        return _frequency;
    }

    function creatorsBalance() public view returns (uint256) {
        return _creatorsBalance;
    }

    /*
    function preMint() public view override returns (uint256) {
        return _preMint;
    }*/

    //The twinPrce = currentCirculation / contractBalance.
    function getTwinPrice() public view returns (uint256) {
        require(_refundReserve > 0, "No balance on the contract");
        uint256 curretCirculation = IERC20(address(token)).totalSupply();
        uint256 price = _refundReserve.div(curretCirculation);
        return price;
    }

    function getPrice() public view returns (uint256) {
        uint256 curretCirculation = IERC20(address(token)).totalSupply();
        uint256 price = _initialPrice;

        if (curretCirculation == 0) {
            price = _initialPrice;
        } else {
            price = _initialPrice.add(_currentCycle.mul(_increment));
        }
        return price;
    }

    function incrementTotalReceived(uint256 _value) private {
        _totalReceived = _totalReceived.add(_value);
    }

    ///garantees that creator will not do any funny thing later
    function renounceOwnerShip() public onlyOwner {
        owner = address(0);
    }

    //Generate NFC ID
    function _generateId() private view returns (uint256) {
        return block.timestamp.add(block.number).add(371);
    }

    function assocCounter() public view returns (uint256) {
        return _assocCounter;
    }

    function totalReceived() public view returns (uint256) {
        return _totalReceived;
    }

    function cycleIncreaseCounter() public view override returns (uint256) {
        return _cycleIncreaseCounter;
    }

    function soldAmount() public view override returns (uint256) {
        return _soldAmount;
    }

    function currentCycle() public view returns (uint256) {
        return _currentCycle;
    }

    function refundReserve() public view returns (uint256) {
        return _refundReserve;
    }

    function minCycleToBurn() public view returns (uint256) {
        return _minCycleToBurn;
    }

    function serviceBuyGvenAmount() public view returns (uint256) {
        return _serviceBuyGvenAmount;
    }

    function twinTokenPrice() public view returns (uint256) {
        if (_refundReserve == 0) {
            return 0;
        }
        return _refundReserve.div(IERC20(address(token)).totalSupply());
    }

    function getCOntractName() public view returns (string memory) {
        return _contractName;
    }

    //when Gven is burnned this fuction is called so that community can update members ballance, allowing for retrival of the BNB balance.
    function onTwinBurn(address member_, uint256 tokenAmount)
        public
        override
        onlyToken
    {
        require(
            _cycleIncreaseCounter >= _minCycleToBurn,
            "Token burn not allowedin this cycle"
        );

        uint256 refundAmount = tokenAmount.mul(twinTokenPrice());
        Member storage member = associates[stewardWelcome(member_)];

        member.pendigComission = member.pendigComission.add(refundAmount);

        _refundReserve = _refundReserve.sub(refundAmount);
        //console.log("onTwinBurn");
        //console.log("Who", member.memberCard.wallet);
        //console.log("TokenAmount", tokenAmount);
        setCycle();
    }

    //<<<<<--------------support functions --------------

    function initClass(
        ClassType _class,
        uint256 _mbShipPrice,
        uint256 _minimmumFee,
        uint256 _invites,
        uint256 _membershipPeriod,
        bool _lockable,
        uint256 _waitPeriod
    ) internal {
        classes[_class] = Class(
            _class,
            _mbShipPrice,
            _minimmumFee,
            _invites,
            _membershipPeriod,
            _lockable,
            _waitPeriod
        );
        if (_class != ClassType.Gmw) {
            classCounter++;
        }
    }

    function gmw() public view returns (address) {
        return _gmw;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 _maxSupply;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 0;
        _maxSupply = maxSupply_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-_maxSupply}.
     */
    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(
            _totalSupply.add(amount) <= _maxSupply,
            "Maximmun supply reached"
        ); //nao emite mais tokens se o máximo for atingido

        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract ERC721 is Context, ERC165, IERC721 {
    using Address for address;
    using SafeMath for uint256;

    ICommunity internal _community;
    bool isCommunitySet = false;

    ITwinToken _twinToken;
    IGvenToken _gvenToken;
    bool isTwinTokenSet = false;
    bool isGvenTokenSet = false;

    uint256 _totalSupply;

    address _owner;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    //dataBase id ==> dados
    mapping(uint256 => TwinPromess) internal _promesses;
    mapping(address => uint256[]) internal _userPromesses;

    // Mapping from token ID to owner adds
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    event communityAddresSet(address);
    event promessFulfullied(address, uint256); //who, how many gven
    event twinTokenAddresSet(address);
    event eventPartialTransfer(address, address, uint256);

    uint256[] tempList;

    modifier onlyCommunity() {
        //console.log(msg.sender);
        require(
            msg.sender == address(_community) || msg.sender == _owner,
            "Back off cheater!!"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can do that!");
        _;
    }

    modifier onlyGven() {
        require(
            msg.sender == address(_gvenToken),
            "Only GvenToken can do that!"
        );
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
        _totalSupply = 0;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        if (to == address(this)) {
            TwinPromess storage prom = _promesses[tokenId];
            if (_community.cycleIncreaseCounter() >= prom.when) {
                _burn(tokenId);
            }
        } else {
            _transfer(from, to, tokenId);
            require(
                _checkOnERC721Received(from, to, tokenId, _data),
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 when
    ) internal virtual {
        _safeMint(to, tokenId, tokenAmount, when, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 when,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId, tokenAmount, when);

        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 when
    ) internal virtual {
        require(
            msg.sender == address(_community) ||
                msg.sender == _owner ||
                msg.sender == address(_gvenToken),
            "Mint not allowed: Back off cheater"
        ); //only community can mint
        require(to != address(0), "ERC721: mint to the zero address");

        _beforeTokenTransfer(address(0), to, tokenId);

        //console.log("ERC721:_transfer:before_makePromise():tokenId: ",tokenId);
        _makePromise(tokenId, to, tokenAmount, when);
        //console.log("ERC721:_transfer:after_makePromise():tokenId: ",tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _totalSupply += 1;
        _approve(address(_gvenToken), tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        _totalSupply -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        _promesses[tokenId].owner = to;
        _userPromesses[to].push(tokenId);
        //console.log("ERC721:_transfer:tokenId: ",tokenId);
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev sets the address of Community.
     */
    function setCommunity(ICommunity community_) public onlyOwner {
        if (!isCommunitySet) {
            _community = community_;
            isCommunitySet = true;
            emit communityAddresSet(address(community_));
        }
    }

    /**
     * @dev sets the address of the twinToken.
     */
    function setTwinToken(ITwinToken twinToken_) public onlyOwner {
        if (!isTwinTokenSet) {
            _twinToken = twinToken_;
            isTwinTokenSet = true;
            emit twinTokenAddresSet(address(twinToken_));
        }
    }

    /**
     * @dev sets the address of the twinToken.
     */
    function setGvenToken(IGvenToken gvenToken_) public onlyOwner {
        if (!isGvenTokenSet) {
            _gvenToken = gvenToken_;
            isGvenTokenSet = true;
            emit twinTokenAddresSet(address(gvenToken_));
        }
    }

    function renounceOwnerShip() public onlyOwner {
        _owner = address(0x0);
    }

    function _makePromise(
        uint256 id,
        address owner,
        uint256 tokenAmount,
        uint256 when
    ) private {
        _promesses[id] = TwinPromess(id, owner, tokenAmount, when, false);
        _userPromesses[owner].push(id);
    }

    //retorna o objeto TwinPromess identified by Id
    function getPromise(uint256 tokenId)
        public
        view
        returns (TwinPromess memory)
    {
        return _promesses[tokenId];
    }

    //retorna uma lista de ids das promesses da carteria informada
    function getPromisesId(address _who)
        public
        view
        returns (uint256[] memory)
    {
        //console.log("getPromessIds: promisses length: ", _userPromesses[_who].length);
        return _userPromesses[_who];
    }

    //retorna uma lista com todos os objetos TwinPromess da carteria informada como parametro
    function getPromises(address _who)
        public
        view
        returns (TwinPromess[] memory)
    {
        uint256[] storage allPromesses = _userPromesses[_who];
        //TwinPromess [] memory userPromisses;
        //console.log("getPromesses:who: ",  _who);
        //console.log("getPromesses:allPromesses.length: " ,allPromesses.length);
        /*
        uint index = 0;

        if(allPromesses.length > 0){

            userPromisses = new TwinPromess[](allPromesses.length);
            TwinPromess storage prom;

            for(uint i = 0; i < allPromesses.length; i++){ 
                prom = _promesses[allPromesses[i]];

                if(prom.owner == _who &&
                    prom.isFulfilled == false &&
                    prom.id != 0
                ){
                    userPromisses[ index ++ ] = prom; 
                }else{
                    //console.log("getPromises: ignoring promise: ",prom.id);
                    //console.log("getPromises: owner is: ",prom.owner);
                }
            } 

            TwinPromess [] memory ret = new TwinPromess[](index);
            for(uint i = 0; i < index; i++){
                ret[i] = userPromisses[i];
            }
*/
        TwinPromess[] memory ret = new TwinPromess[](allPromesses.length);
        for (uint256 i = 0; i < allPromesses.length; i++) {
            ret[i] = _promesses[allPromesses[i]];
        }
        return ret;
        // }
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    /*
    function _reorganizePromise(address _who) internal {
        uint [] memory allPromesses =  _userPromesses[_who];
        uint [] memory aux = new uint[](allPromesses.length); 
        uint [] memory  finalList;

        if(allPromesses.length > 0){ 
            uint counter = 0;

            //console.log("Entered _reorganizePromise");
            

            TwinPromess  memory prom;
            for(uint i = 0; i < allPromesses.length; i++){ 
                //console.log("_reorganizePromise: i= ", i);

                prom = _promesses[allPromesses[i]];
                if(prom.owner == _who){
                    aux[i] = prom.id; 
                    counter ++;
                }
            }

            finalList = new uint[](counter);   
            for(uint i=0; i < aux.length; i++){
                tempList.push(aux[i]);
            }

            _userPromesses[_who] = finalList;
        }else{
            delete _userPromesses[_who];
        } 
    }

    */
}

contract GVENERC20 is ERC20 {
    using SafeMath for uint256;

    uint256 public holders;

    ICommunity internal _community;
    ITwinToken _twinToken;
    ITwinTokenPromess internal _twinPromess;

    address owner;
    address creatorsWallet;
    uint256 maxMintForCreators;

    bool isTwinTokenSet = false;
    bool isTwinTokenPromessSet = false;

    event twinTokenSet(ITwinToken);
    event twinTokenPromssSet(ITwinTokenPromess);

    modifier restrict() virtual {
        require(
            msg.sender == address(_community) ||
                msg.sender == address(_twinToken) ||
                msg.sender == owner,
            "Back off cheater!"
        );
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == address(_community), "Back off cheater!");
        _;
    }

    modifier tokenAndCommunity() {
        require(
            msg.sender == address(_community) ||
                msg.sender == address(_twinToken),
            "GVENERC20:Back off cheater!"
        );
        _;
    }

    constructor(
        ICommunity community_,
        uint256 maxSupply_,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol, maxSupply_) {
        _community = community_;
        owner = msg.sender;
        maxMintForCreators = 50000000; /*************/
        creatorsWallet = 0x6521877b7324586e52e8ad50a0353dc1C81c2a7b;
    }

    /**
     * @dev Returns the address of the twinToken.
     */
    function twinToken() public view virtual returns (address) {
        return address(_twinToken);
    }

    /**
     * @dev sets the address of the twinToken.
     */
    function setTwinToken(ITwinToken twinToken_) public restrict {
        if (!isTwinTokenSet) {
            _twinToken = twinToken_;
            isTwinTokenSet = true;
            emit twinTokenSet(twinToken_);
        }
    }

    function setTwinTokenPromess(ITwinTokenPromess twinPromess_)
        public
        restrict
    {
        if (!isTwinTokenPromessSet) {
            _twinPromess = twinPromess_;
            isTwinTokenPromessSet = true;
            emit twinTokenPromssSet(twinPromess_);
        }
    }

    /*
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        //
        if (recipient == address(this)) {
            //burn token, twin e faz ressarcimento la no contrato community
            burn(amount);
        } else {
            require(
                _community.isAssoc(recipient) == true ||
                    recipient == creatorsWallet,
                "Trying to send to a non member"
            );
            //prmeiramente transfere o twin
            GVENERC20(address(_twinToken)).transferFrom(
                msg.sender,
                recipient,
                amount
            );
            //agora transfere o atual
            _transfer(msg.sender, recipient, amount);
            //approv twin token para o novo dono
            address twtk = address(_twinToken);
            _approve(recipient, twtk, _allowances[recipient][twtk].add(amount));
        }
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        //se o addr de dstino é o deste contrato
        if (recipient == address(this)) {
            if (msg.sender == address(_twinToken)) {
                burnFrom(sender, amount);
            } else {
                _twinToken.burnFrom(sender, amount); //queimar o twin
                super._burn(sender, amount); //queimar o principal
            }
        } else if (msg.sender == address(_twinToken)) {
            _transfer(sender, recipient, amount);
        } else {
            //transfere o twin
            GVENERC20(address(_twinToken)).transferFrom(
                sender,
                recipient,
                amount
            );
            //agora transfere o atual
            _transfer(sender, recipient, amount);
            //approve twin
            address twtk = address(_twinToken);
            _approve(
                recipient,
                twtk,
                _allowances[recipient][twtk].sub(
                    amount,
                    "ERC20: transfer amount exceeds allowance"
                )
            );
            //Atualiza o allowance de quem mandou a mensagem
            _approve(
                sender,
                msg.sender,
                _allowances[sender][msg.sender].sub(
                    amount,
                    "ERC20: transfer amount exceeds allowance"
                )
            );
        }

        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(
            _community.isAssoc(to) ||
                _community.isRegisteredService(to) ||
                to == address(_twinToken) ||
                to == address(this) ||
                to == creatorsWallet ||
                to == address(0),
            "Only members of Gven Community can receive GvenToken"
        );

        if (_balances[to] == 0) holders++;
    }

    ///garantees that creator will not do any funny thing later
    function renounceOwnerShip() public restrict {
        owner = address(0x0);
    }

    /*
     burns the token
     burns the twin
     And calls community to refund the corresponing amount in bnb 
    */
    function burn(uint256 amount) public virtual {
        _twinToken.burnFrom(msg.sender, amount);
        _burn(msg.sender, amount);
        if (
            msg.sender != address(_community) &&
            msg.sender != address(_twinToken)
        ) {
            _community.onTwinBurn(msg.sender, amount);
        }
    }

    /*
     -approved users can request burn.When they do the twintoken will be berned too.
     - 
    */
    function burnFrom(address account, uint256 amount) public virtual {
        bool shouldDcrase = false;
        uint256 decreasedAllowance = 0;

        if (msg.sender != account) {
            decreasedAllowance = allowance(account, msg.sender).sub(
                amount,
                "ERC20: burn amount exceeds allowance"
            );
            shouldDcrase = true;
        }

        if (msg.sender == address(_twinToken)) {
            _burn(account, amount);
            if (shouldDcrase == true) {
                _approve(account, address(_twinToken), decreasedAllowance);
            }
        } else {
            _burn(account, amount);
            _twinToken.burnFrom(account, amount);
            if (shouldDcrase == true) {
                _approve(account, msg.sender, decreasedAllowance);
            }
        }
    }

    function mint(address account, uint256 amount) public virtual restrict {
        _mint(account, amount);

        _approve(
            account,
            address(_twinToken),
            _allowances[account][address(_twinToken)].add(amount)
        );
        //console.log("Twin Approved for ",account);
        //console.log("Amount: ", amount);
        _approve(
            account,
            address(_community),
            _allowances[account][address(_community)].add(amount)
        );
        //console.log("Community Approved for ", address(_community));
        //console.log("Amount: ", amount);
    }
}

contract GvenToken is
    IGvenToken,
    GVENERC20 // , ERC20Burnable{
{
    using SafeMath for uint256;
    ITwinToken _iTwinToken;
    uint256 dueAmountForCreators;

    //The community_ must be deployed before depolying this token
    constructor(uint256 maxSupply_, Community community_)
        GVENERC20(community_, maxSupply_, "Gven Smart Community", "GVEN")
    {
        //console.log("Token:Construtor: Entrou");
        _community = community_;
        //console.log("Token:Construtor: Saiu");
    }

    //transfers the  promisses if there is noenough twin token available
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _twinPromess.resolvePromise(msg.sender);

        if (GVENERC20(address(_twinToken)).balanceOf(msg.sender) >= amount) {
            super.transfer(recipient, amount);
        } else {
            //Se nao tem twin sufiente pede trnasfere a promess ( ou parte dela)

            require(
                recipient != address(this),
                "Token burn not allowed before the promise fulfillment"
            );

            if (IERC721(address(_twinPromess)).balanceOf(msg.sender) > 0) {
                _twinPromess.partialTransferFrom(msg.sender, recipient, amount);
                super._transfer(msg.sender, recipient, amount);
                address twtk = address(_twinToken);
                _approve(
                    recipient,
                    twtk,
                    _allowances[recipient][twtk].add(amount)
                );
            } else {
                revert("No enough balance");
            }
        }
        return true;
    }

    function burnFrom(address account, uint256 amount)
        public
        override(GVENERC20, IGvenToken)
    {
        super.burnFrom(account, amount);
    }

    //refund value sent to this contract by mistake.
    receive() external payable {
        msg.sender.transfer(msg.value);
    }

    function mintForCreators() public override {
        _mintForCreators(dueAmountForCreators);
        dueAmountForCreators = 0;
    }

    //Mint a maximum maxMintForCreators GVEN for the creators
    function _mintForCreators(uint256 _amount) internal {
        if (maxMintForCreators > 0) {
            if (_amount >= maxMintForCreators) {
                _mint(creatorsWallet, maxMintForCreators);
                _twinToken.mint(creatorsWallet, maxMintForCreators);
                maxMintForCreators = 0;

                _approve(
                    creatorsWallet,
                    address(_twinToken),
                    _allowances[creatorsWallet][address(_twinToken)].add(
                        maxMintForCreators
                    )
                );
                _approve(
                    creatorsWallet,
                    address(_community),
                    _allowances[creatorsWallet][address(_community)].add(
                        maxMintForCreators
                    )
                );
            } else if (_amount < maxMintForCreators) {
                _mint(creatorsWallet, _amount);
                _twinToken.mint(creatorsWallet, _amount);
                maxMintForCreators = maxMintForCreators.sub(_amount);

                _approve(
                    creatorsWallet,
                    address(_twinToken),
                    _allowances[creatorsWallet][address(_twinToken)].add(
                        _amount
                    )
                );
                _approve(
                    creatorsWallet,
                    address(_community),
                    _allowances[creatorsWallet][address(_community)].add(
                        _amount
                    )
                );
            }
        }
    }

    function mint(address account, uint256 amount)
        public
        virtual
        override(GVENERC20, IGvenToken)
        restrict
    {
        super.mint(account, amount);
        dueAmountForCreators = dueAmountForCreators.add(amount);
    }

    /*
function balanceOf(address who) public view override(ERC20 , IGvenToken) returns  (uint256 tokenBalance)  {
    return super.balanceOf(who);
}
*/
}

//Contrato de afiliado
contract MemberWallet is
    IMemberWallet 
{
    // uint  minAssocFee;
    ICommunity root;
    address owner;
    bool lockable = false;
    bool locked = false;
    address locker;
    address unlocker;

    constructor(
        ICommunity _root,
        address _owner,
        bool _lockable
    ) {
        // minAssocFee = _minAssocFee;
        root = _root;
        owner = _owner;
        lockable = _lockable;
        locker = address(new Locker(address(this)));
        unlocker = address(new Unlocker(address(this)));
    }

    modifier r() {
        require(msg.sender == address(root), "Back off cheater");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Back off cheater");
        _;
    }

    modifier onlyLockerUnlocker() {
        require(
            msg.sender == owner ||
                msg.sender == locker ||
                msg.sender == unlocker,
            "funct:lockMw(): User Not allowed"
        );
        _;
    }

    function returnFunds() public {
        if (address(this).balance > 0) {
            payable(owner).transfer(address(this).balance);
        }
    }

    function lockMw(bool state_, address who_)
        public
        payable
        override
        onlyLockerUnlocker
    {
        require(
            who_ == owner,
            "Only the owner of a Member Wallet can lock or unlock it"
        );
        require(lockable == true, "Feature not available on this class");
        if (state_ == true) {
            locked = true;
        } else {
            locked = false;
        }

        if (msg.value > 0) {
            payable(owner).transfer(msg.value);
        }
    }

    //quando ha upgrade
    function makeLockable() public override r {
        lockable = true;
        //console.log("Mamberwallet made lockable: contact :",address(this));
    }

    function isLockedMw() public view returns (bool) {
        return locked;
    }

    function getLocker() public view returns (address) {
        return locker;
    }

    function getUnlocker() public view returns (address) {
        return unlocker;
    }

    receive() external payable {
        if (lockable == true) {
            require(locked == false, "This Member Wallet is locked");
        }
        root.initAssoc{value: msg.value}(msg.sender);
    }
}

contract Locker {
    IMemberWallet mw;

    constructor(address mw_) {
        mw = IMemberWallet(mw_);
    }

    receive() external payable {
        mw.lockMw{value: msg.value}(true, msg.sender);
    }
}

contract Unlocker {
    IMemberWallet mw;

    constructor(address mw_) {
        mw = IMemberWallet(mw_);
    }

    receive() external payable {
        mw.lockMw{value: msg.value}(false, msg.sender);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }

    function percent(uint256 _amount, uint256 _percentual)
        internal
        pure
        returns (uint256)
    {
        // Solidity only automatically asserts when dividing by 0
        require(
            _amount > 0 && _percentual > 0,
            "SafeMath:error: Percentual of zero"
        );
        uint256 r = (_amount * _percentual) / 100;
        return r;
    }
}

contract Splitter {
    using SafeMath for uint256;

    address payable owner;
    address attorney;

    address payable wallet;
    Partner[] partners; //lista de todos os membros

    uint256 passFee;

    modifier x() {
        require(
            msg.sender == owner || msg.sender == attorney,
            "Back off cheater"
        );
        _;
    }

    modifier w() {
        require(
            msg.sender == owner,
            "Sorry, you do not have authority for this operation"
        );
        _;
    }

    modifier p() {
        require(
            msg.value >= passFee,
            "Sorry, this is a paid function! Please send the correct fee"
        );
        _;
    }

    constructor(address payable _attorney, uint256 _passFee) {
        owner = msg.sender;
        attorney = _attorney;
        passFee = _passFee;

        //Reis
        partners.push(
            Partner(
                "WhiteNode",
                "Director",
                0x80Ae5Fcd75474b2DEE3e708b0b38832d1a891295,
                100,
                0
            )
        );
    }

    //admin func
    function getOwner() external payable p returns (address) {
        return owner;
    }

    function getAttorney() external payable p returns (address) {
        return attorney;
    }

    function getFee() public view x returns (uint256) {
        return passFee;
    }

    function setFee(uint256 _fee) public payable x p {
        require(_fee > 0, "Fee can not be zero or negative value");
        passFee = _fee;
    }

    function changeOwner(address payable _newOwner) public w {
        require(
            _newOwner != attorney,
            "attorney and owner can not be the same"
        );
        owner = _newOwner;
    }

    function changeAttorney(address _newAttorney) public x {
        require(
            _newAttorney != owner,
            "attorney and owner can not be the same"
        );
        attorney = _newAttorney;
    }

    //lista e todos os parceiros
    function getPartners() public view x returns (Partner[] memory) {
        return partners;
    }

    //Pesquisa um parceiro pela cartira
    function getPartner(address _wallet)
        public
        view
        x
        returns (Partner memory)
    {
        uint256 partnerIndex = 99999999999999999999;

        for (uint256 i = 0; i < partners.length; i++) {
            if (partners[i].wallet == _wallet) {
                partnerIndex = i;
            }
        }

        return partners[partnerIndex];
    }

    //lista e todos os parceiros
    function addPartner(
        string memory _name,
        string memory _role,
        address payable _wallet,
        uint256 _percent
    ) public x {
        for (uint256 i = 0; i < partners.length; i++) {
            if (partners[i].wallet == _wallet) {
                revert("Wallet already registered");
            }
        }
        partners.push(Partner(_name, _role, _wallet, _percent, 0));
    }

    //Owner e attorney can change parters wallet if necessary
    function changePartnersWallet(
        address _oldWallet,
        address payable _newWallet
    ) public x {
        for (uint256 i = 0; i < partners.length; i++) {
            //wallet nao pode repetir
            if (partners[i].wallet == _newWallet) {
                revert("Wallet already registered");
            }
            if (partners[i].wallet == _oldWallet) {
                partners[i].wallet = _newWallet;
                break;
            }
        }
    }

    //Os parceiros podem trocar a carteira a qqr momento.
    //A transaçaõ tem que ser enviada pela carteira antiga
    function changeMyWallet(address payable _newWallet) public payable {
        for (uint256 i = 0; i < partners.length; i++) {
            if (partners[i].wallet == _newWallet) {
                revert("Wallet already registered");
            }
            if (partners[i].wallet == msg.sender) {
                partners[i].wallet = _newWallet;
                break;
            }
        }
    }

    //Tenta enviar eventuais residuos.
    // Se houver fundos suficintes para custear o envio e pelo menos 0.1 eth
    function split() internal {
        //Verifica se o saldo cobre as taxas
        uint256 minnimum = 31700000000000000;
        uint256 balance = address(this).balance;
        if (balance >= minnimum) {
            for (uint256 i = 0; i < partners.length; i++) {
                partners[i].wallet.transfer(
                    balance.percent(partners[i].percentual)
                );
            }
        }
    }

    function silverBullet() public payable x {
        owner.transfer(address(this).balance);
    }

    //Receiver func
    function collect() external payable {
        split();
    }

    receive() external payable {
        split();
    }

    fallback() external payable {
        split();
    }
}

contract TwinTokenPromess is ERC721, ITwinTokenPromess {
    using SafeMath for uint256;

    uint256 internal _decimals;

    constructor(uint256 decimals_) ERC721("Gven Promess", "PGVEN") {
        _decimals = decimals_;
    }

    function mint(
        address account,
        uint256 tokenId,
        uint256 amount,
        uint256 when
    ) public override onlyCommunity {
        _safeMint(account, tokenId, amount, when);
    }

    function resolvePromise(address _who) public override {
        uint256[] storage allPromesses = _userPromesses[_who];
        ////////console.log("resolvePromise:allPromesses.length: " ,allPromesses.length);
        if (allPromesses.length > 0) {
            TwinPromess storage prom;
            uint256[] memory tempIdList = new uint256[](allPromesses.length);
            uint256[] memory promesses;

            uint256 counter = 0;

            for (uint256 i = 0; i < allPromesses.length; i++) {
                prom = _promesses[allPromesses[i]];
                uint256 soldAmount = _community.soldAmount();

                if (prom.owner == _who) {
                    if (prom.isFulfilled == false) {
                        if (prom.when <= soldAmount) {
                            prom.isFulfilled = true;
                            _twinToken.mint(prom.owner, prom.tokenAmount);
                            emit promessFulfullied(
                                prom.owner,
                                prom.tokenAmount
                            );
                            //////console.log("Tanto de Twins liberado: " ,  prom.tokenAmount);
                            _burn(prom.id);
                        } else {
                            tempIdList[counter++] = prom.id;
                        }
                    }
                }
            }

            promesses = new uint256[](counter);
            for (uint256 i = 0; i < counter; i++) {
                promesses[i] = tempIdList[i];
            }
            delete _userPromesses[_who];
            _userPromesses[_who] = promesses;
        }
    }

    //transfers the promess partially
    function partialTransferFrom(
        address from,
        address receiver,
        uint256 amount
    ) public override onlyGven {
        uint256[] memory allPromesses = _userPromesses[from];
        TwinPromess storage prom;

        //////console.log("partialTransferFrom:allPromesses.length is: ",allPromesses.length);
        //////console.log("partialTransferFrom:From is: ", from);
        //////console.log("Amount needed is:" ,amount);

        if (allPromesses.length > 0) {
            uint256 auxAmount = amount;
            uint256 index = 0;
            bool splittedProm = false;
            while (auxAmount > 0 && index < allPromesses.length) {
                prom = _promesses[allPromesses[index]];

                /*           if(prom.owner == from &&
                    prom.isFulfilled == false &&
                    prom.id != 0
                ){ */
                //////console.log("prom.amount" ,prom.tokenAmount);

                if (prom.tokenAmount == auxAmount) {
                    //same size

                    //////console.log("partialTransferFrom: ==, therefore transferring");

                    _transfer(from, receiver, prom.id);

                    auxAmount = 0;
                    //////console.log("partialTransferFrom: ==, finished");
                } else if (prom.tokenAmount > auxAmount) {
                    //otherwise split the promess in two

                    splittedProm = true;
                    //////console.log("partialTransferFrom: >, splitting ");
                    _beforeTokenTransfer(from, receiver, prom.id);
                    // Clear approvals from the previous owner
                    _approve(address(0), prom.id);
                    // mint uma nova para o destinatario
                    _mint(receiver, _generateId(), auxAmount, prom.when);
                    //eles emite evento
                    emit eventPartialTransfer(from, receiver, prom.id);
                    //dimunui esta promessa
                    prom.tokenAmount = prom.tokenAmount.sub(auxAmount);
                    auxAmount = 0;
                    //////console.log("partialTransferFrom: >, finished ");
                } else {
                    //prom.tokenAmount < amount
                    //////console.log("partialTransferFrom: <, transferring");

                    _transfer(from, receiver, prom.id);

                    auxAmount = auxAmount.sub(prom.tokenAmount);
                    //////console.log("partialTransferFrom: <, finished ");
                }
                //  }
                index++;
            }

            if (index > 0) {
                //usuario tinha apenas uma promessa
                if (allPromesses.length == 1) {
                    //////console.log("partialTransferFrom: allPromise == 1");
                    if (!splittedProm) {
                        //e ela foi transferida
                        //O usuario nao tem mais nenhuma promesa. Deleta o array

                        //////console.log("partialTransferFrom: allPromise == 1. Deletando ");
                        delete _userPromesses[from];
                    } //else{ nada precisa fazer
                    //
                    //}
                    //Tinha mais de uma
                } else {
                    //////console.log("partialTransferFrom: Tinha mais de uma promesa");
                    //se todas as promessas foram acessadas
                    if (index == allPromesses.length) {
                        //////console.log("partialTransferFrom: index foi igual total de promesas");

                        if (splittedProm == true) {
                            //a ultima operacao foi partial
                            //deleta todas s priemiras e mantem a ultima
                            uint256[] memory tempList = new uint256[](1);
                            tempList[0] = allPromesses[index - 1];
                            _userPromesses[from] = tempList;
                        } else {
                            //////console.log("partialTransferFrom: index foi igual total de promesas: Deletando todas.");
                            delete _userPromesses[from];
                        }
                    } else {
                        //index = 12 : 11 foi a ultima a mxida
                        //////console.log("partialTransferFrom: index menor que total de prom. ");
                        uint256 auxIndex = index;

                        if (splittedProm == true) {
                            auxIndex = index - 1;
                            //////console.log("partialTransferFrom: index menor que total de prom.: Partial ==true");
                            //////console.log("partialTransferFrom: index menor que total de prom.: Partial ==true, auxIndex: ", auxIndex);
                        }

                        //////console.log("partialTransferFrom: auxIndex is ",auxIndex);

                        uint256[] memory tempList = new uint256[](
                            allPromesses.length - auxIndex
                        );

                        TwinPromess storage tProm;

                        for (
                            uint256 i = auxIndex;
                            i < allPromesses.length;
                            i++
                        ) {
                            uint256 promId = allPromesses[i];
                            tProm = _promesses[promId];

                            if (
                                tProm.owner == from &&
                                tProm.isFulfilled == false &&
                                tProm.id != 0
                            ) {
                                tempList[i - auxIndex] = allPromesses[i];
                            }
                        }

                        delete _userPromesses[from];
                        _userPromesses[from] = tempList;
                    }
                }
            }
        } else {
            revert("No available promess");
        }
        //////console.log("partialTransferFrom:Exit():userpromess[wo].lenght is ", _userPromesses[from].length );
    }

    //Generate NFC ID
    function _generateId() private view returns (uint256) {
        return block.timestamp.add(block.number).add(371);
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    //refund value sent to this contract by mistake.
    receive() external payable {
        msg.sender.transfer(msg.value);
    }
}

contract TwinToken is
    ITwinToken,
    GVENERC20 // , ERC20Burnable{
{
    using SafeMath for uint256;

    modifier onlyTwinPromess() {
        require(msg.sender == address(_twinPromess), "");
        _;
    }
    modifier restrict() override {
        require(
            msg.sender == address(_community) ||
                msg.sender == address(_twinToken) ||
                msg.sender == owner ||
                msg.sender == address(_twinPromess),
            "Back off cheater!"
        );
        _;
    }

    //The community_ must be deployed before depolying this token
    constructor(uint256 maxSupply_, Community community_)
        GVENERC20(community_, maxSupply_, "Gven Twin Token", "GTWIN")
    {
        //console.log("Token:Construtor: Entrou");
        _community = community_;
        //console.log("Token:Construtor: Saiu");
    }

    function burnFrom(address account, uint256 amount)
        public
        override(GVENERC20, ITwinToken)
    {
        super.burnFrom(account, amount);
    }

    function mint(address account, uint256 amount)
        public
        virtual
        override(GVENERC20, ITwinToken)
        restrict
    {
        super.mint(account, amount);
    }

    //refund value sent to this contract by mistake.
    receive() external payable {
        msg.sender.transfer(msg.value);
    }
}