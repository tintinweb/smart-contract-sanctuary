pragma solidity ^0.4.24;


contract BrickAccessControl {

    constructor() public {
        admin = msg.sender;
        nodeToId[admin] = 1;
    }

    address public admin;
    address[] public nodes;
    mapping (address => uint) nodeToId;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized admin");
        _;
    }

    modifier onlyNode() {
        require(nodeToId[msg.sender] != 0, "Not authorized node");
        _;
    }

    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0));

        admin = _newAdmin;
    }

    function getNodes() public view returns (address[]) {
        return nodes;
    }

    function addNode(address _newNode) public onlyAdmin {
        require(_newNode != address(0), "Cannot set to empty address");

        nodeToId[_newNode] = nodes.push(_newNode);
    }

    function removeNode(address _node) public onlyAdmin {
        require(_node != address(0), "Cannot set to empty address");

        uint index = nodeToId[_node] - 1;
        delete nodes[index];
        delete nodeToId[_node];
    }

}

contract BrickBase is BrickAccessControl {

    /**************
       Events
    ***************/

    // S201. 대출 계약 생성
    event ContractCreated(bytes32 loanId);

    // S201. 대출중
    event ContractStarted(bytes32 loanId);

    // S301. 상환 완료
    event RedeemCompleted(bytes32 loanId);

    // S302. 청산 완료
    event LiquidationCompleted(bytes32 loanId);


    /**************
       Data Types
    ***************/

    struct Contract {
        bytes32 loanId;         // 계약 번호
        uint16 productId;       // 상품 번호
        bytes8 coinName;        // 담보 코인 종류
        uint256 coinAmount;     // 담보 코인양
        uint32 coinUnitPrice;   // 1 코인당 금액
        string collateralAddress;  // 담보 입금 암호화폐 주소
        uint32 loanAmount;      // 대출원금
        uint64 createAt;        // 계약일
        uint64 openAt;          // 원화지급일(개시일)
        uint64 expireAt;        // 만기일
        bytes8 feeRate;         // 이자율
        bytes8 overdueRate;     // 연체이자율
        bytes8 liquidationRate; // 청산 조건(담보 청산비율)
        uint32 prepaymentFee;   // 중도상환수수료
        bytes32 extra;          // 기타 정보
    }

    struct ClosedContract {
        bytes32 loanId;         // 계약 번호
        bytes8 status;          // 종료 타입(S301, S302)
        uint256 returnAmount;   // 반환코인량(유저에게 돌려준 코인)
        uint32 returnCash;      // 반환 현금(유저에게 돌려준 원화)
        string returnAddress;   // 담보 반환 암호화폐 주소
        uint32 feeAmount;       // 총이자(이자 + 연체이자 + 운영수수료 + 조기상환수수료)
        uint32 evalUnitPrice;   // 청산시점 평가금액(1 코인당 금액)
        uint64 evalAt;          // 청산시점 평가일
        uint64 closeAt;         // 종료일자
        bytes32 extra;          // 기타 정보
    }


    /**************
        Storage
    ***************/

    // 계약 번호 => 대출 계약서
    mapping (bytes32 => Contract) loanIdToContract;
    // 계약 번호 => 종료된 대출 계약서
    mapping (bytes32 => ClosedContract) loanIdToClosedContract;

    bytes32[] contracts;
    bytes32[] closedContracts;

}

contract BrickInterface is BrickBase {

    function createContract(
        bytes32 _loanId, uint16 _productId, bytes8 _coinName, uint256 _coinAmount, uint32 _coinUnitPrice,
        string _collateralAddress, uint32 _loanAmount, uint64[] _times, bytes8[] _rates, uint32 _prepaymentFee, bytes32 _extra)
        public;

    function closeContract(
        bytes32 _loanId, bytes8 _status, uint256 _returnAmount, uint32 _returnCash, string _returnAddress,
        uint32 _feeAmount, uint32 _evalUnitPrice, uint64 _evalAt, uint64 _closeAt, bytes32 _extra)
        public;

    function getContract(bytes32 _loanId)
        public
        view
        returns (
        bytes32 loanId,
        uint16 productId,
        bytes8 coinName,
        uint256 coinAmount,
        uint32 coinUnitPrice,
        string collateralAddress,
        uint32 loanAmount,
        uint32 prepaymentFee,
        bytes32 extra);

    function getContractTimestamps(bytes32 _loanId)
        public
        view
        returns (
        bytes32 loanId,
        uint64 createAt,
        uint64 openAt,
        uint64 expireAt);

    function getContractRates(bytes32 _loanId)
        public
        view
        returns (
        bytes32 loanId,
        bytes8 feeRate,
        bytes8 overdueRate,
        bytes8 liquidationRate);

    function getClosedContract(bytes32 _loanId)
        public
        view
        returns (
        bytes32 loanId,
        bytes8 status,
        uint256 returnAmount,
        uint32 returnCash,
        string returnAddress,
        uint32 feeAmount,
        uint32 evalUnitPrice,
        uint64 evalAt,
        uint64 closeAt,
        bytes32 extra);

    function totalContracts() public view returns (uint);

    function totalClosedContracts() public view returns (uint);

}



contract Brick is BrickInterface {

    /// @dev 대출 계약서 생성하기
    /// @param _loanId 계약 번호
    /// @param _productId 상품 번호
    /// @param _coinName 담보 코인 종류
    /// @param _coinAmount 담보 코인양
    /// @param _coinUnitPrice 1 코인당 금액
    /// @param _collateralAddress 담보 입금 암호화폐 주소
    /// @param _loanAmount 대출원금
    /// @param _times 계약 시간 정보[createAt, openAt, expireAt]
    /// @param _rates 이자율[feeRate, overdueRate, liquidationRate]
    /// @param _prepaymentFee 중도상환수수료
    /// @param _extra 기타 정보
    function createContract(
        bytes32 _loanId, uint16 _productId, bytes8 _coinName, uint256 _coinAmount, uint32 _coinUnitPrice,
        string _collateralAddress, uint32 _loanAmount, uint64[] _times, bytes8[] _rates, uint32 _prepaymentFee, bytes32 _extra)
        public
        onlyNode
    {
        require(loanIdToContract[_loanId].loanId == 0, "Already exists in Contract.");
        require(loanIdToClosedContract[_loanId].loanId == 0, "Already exists in ClosedContract.");

        Contract memory _contract = Contract({
            loanId: _loanId,
            productId: _productId,
            coinName: _coinName,
            coinAmount: _coinAmount,
            coinUnitPrice: _coinUnitPrice,
            collateralAddress: _collateralAddress,
            loanAmount: _loanAmount,
            createAt: _times[0],
            openAt: _times[1],
            expireAt: _times[2],
            feeRate: _rates[0],
            overdueRate: _rates[1],
            liquidationRate: _rates[2],
            prepaymentFee: _prepaymentFee,
            extra: _extra
        });
        loanIdToContract[_loanId] = _contract;
        contracts.push(_loanId);

        emit ContractCreated(_loanId);
    }

    /// @dev 대출 계약 종료하기
    /// @param _loanId 계약 번호
    /// @param _status 종료 타입(S301, S302)
    /// @param _returnAmount 반환코인량(유저에게 돌려준 코인)
    /// @param _returnCash 반환 현금(유저에게 돌려준 원화)
    /// @param _returnAddress 담보 반환 암호화폐 주소
    /// @param _feeAmount 총이자(이자 + 연체이자 + 운영수수료 + 조기상환수수료)
    /// @param _evalUnitPrice 청산시점 평가금액(1 코인당 금액)
    /// @param _evalAt 청산시점 평가일
    /// @param _closeAt 종료일자
    /// @param _extra 기타 정보
    function closeContract(
        bytes32 _loanId, bytes8 _status, uint256 _returnAmount, uint32 _returnCash, string _returnAddress,
        uint32 _feeAmount, uint32 _evalUnitPrice, uint64 _evalAt, uint64 _closeAt, bytes32 _extra)
        public
        onlyNode
    {
        require(loanIdToContract[_loanId].loanId != 0, "Not exists in Contract.");
        require(loanIdToClosedContract[_loanId].loanId == 0, "Already exists in ClosedContract.");

        ClosedContract memory closedContract = ClosedContract({
            loanId: _loanId,
            status: _status,
            returnAmount: _returnAmount,
            returnCash: _returnCash,
            returnAddress: _returnAddress,
            feeAmount: _feeAmount,
            evalUnitPrice: _evalUnitPrice,
            evalAt: _evalAt,
            closeAt: _closeAt,
            extra: _extra
        });
        loanIdToClosedContract[_loanId] = closedContract;
        closedContracts.push(_loanId);

        if (_status == bytes16("S301")) {
            emit RedeemCompleted(_loanId);
        } else if (_status == bytes16("S302")) {
            emit LiquidationCompleted(_loanId);
        }
    }

    /// @dev 진행중인 대출 계약서 조회하기
    /// @param _loanId 계약 번호
    /// @return The contract of given loanId
    function getContract(bytes32 _loanId)
        public
        view
        returns (
        bytes32 loanId,
        uint16 productId,
        bytes8 coinName,
        uint256 coinAmount,
        uint32 coinUnitPrice,
        string collateralAddress,
        uint32 loanAmount,
        uint32 prepaymentFee,
        bytes32 extra)
    {
        require(loanIdToContract[_loanId].loanId != 0, "Not exists in Contract.");

        Contract storage c = loanIdToContract[_loanId];
        loanId = c.loanId;
        productId = uint16(c.productId);
        coinName = c.coinName;
        coinAmount = uint256(c.coinAmount);
        coinUnitPrice = uint32(c.coinUnitPrice);
        collateralAddress = c.collateralAddress;
        loanAmount = uint32(c.loanAmount);
        prepaymentFee = uint32(c.prepaymentFee);
        extra = c.extra;
    }

    function getContractTimestamps(bytes32 _loanId)
        public
        view
        returns (
        bytes32 loanId,
        uint64 createAt,
        uint64 openAt,
        uint64 expireAt)
    {
        require(loanIdToContract[_loanId].loanId != 0, "Not exists in Contract.");

        Contract storage c = loanIdToContract[_loanId];
        loanId = c.loanId;
        createAt = uint64(c.createAt);
        openAt = uint64(c.openAt);
        expireAt = uint64(c.expireAt);
    }

    function getContractRates(bytes32 _loanId)
        public
        view
        returns (
        bytes32 loanId,
        bytes8 feeRate,
        bytes8 overdueRate,
        bytes8 liquidationRate)
    {
        require(loanIdToContract[_loanId].loanId != 0, "Not exists in Contract.");

        Contract storage c = loanIdToContract[_loanId];
        loanId = c.loanId;
        feeRate = c.feeRate;
        overdueRate = c.overdueRate;
        liquidationRate = c.liquidationRate;
    }

    /// @dev 종료된 대출 계약서 조회하기
    /// @param _loanId 계약 번호
    /// @return The closed contract of given loanId
    function getClosedContract(bytes32 _loanId)
        public
        view
        returns (
        bytes32 loanId,
        bytes8 status,
        uint256 returnAmount,
        uint32 returnCash,
        string returnAddress,
        uint32 feeAmount,
        uint32 evalUnitPrice,
        uint64 evalAt,
        uint64 closeAt,
        bytes32 extra)
    {
        require(loanIdToClosedContract[_loanId].loanId != 0, "Not exists in ClosedContract.");

        ClosedContract storage c = loanIdToClosedContract[_loanId];

        loanId = c.loanId;
        status = c.status;
        returnAmount = uint256(c.returnAmount);
        returnCash = uint32(c.returnCash);
        returnAddress = c.returnAddress;
        feeAmount = uint32(c.feeAmount);
        evalUnitPrice = uint32(c.evalUnitPrice);
        evalAt = uint64(c.evalAt);
        closeAt = uint64(c.closeAt);
        extra = c.extra;
    }

    function totalContracts() public view returns (uint) {
        return contracts.length;
    }

    function totalClosedContracts() public view returns (uint) {
        return closedContracts.length;
    }

}