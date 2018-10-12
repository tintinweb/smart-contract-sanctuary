pragma solidity ^0.4.24;


contract BrickAccessControl {

    constructor() public {
        admin = msg.sender;
        nodeToId[admin] = 1;
    }

    address public admin;
    mapping (address => uint) nodeToId;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized admin.");
        _;
    }

    modifier onlyNode() {
        require(nodeToId[msg.sender] == 1, "Not authorized node.");
        _;
    }

    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0));

        admin = _newAdmin;
    }

    function addNode(address _newNode) public onlyAdmin {
        require(_newNode != address(0));
        require(nodeToId[_newNode] == 0);

        nodeToId[_newNode] = 1;
    }

    function removeNode(address _node) public onlyAdmin {
        require(_node != address(0));
        require(nodeToId[_node] == 1);

        delete nodeToId[_node];
    }

}

contract BrickBase is BrickAccessControl {

    /**************
       Events
    ***************/

    // S100. 대출 계약 생성
    event ContractCreated(bytes32 loanId);

    // S201. 대출중
    event ContractStarted(bytes32 loanId);

    // S301. 상환 완료
    event RedeemCompleted(bytes32 loanId);

    // S302. 청산 완료
    event LiquidationCompleted(bytes32 loanId);

    // S303. 담보 미입금 완료
    event UndepositCompleted(bytes32 loanId);


    /**************
       Data Types
    ***************/

    struct Contract {
        bytes32 loanId;         // 계약 번호
        uint16 productId;       // 상품 번호
        bytes32 coinName;       // 담보 코인 종류
        uint256 coinAmount;     // 담보 코인양
        uint64 coinUnitPrice;   // 1 코인당 금액
        bytes32 collateralAddress;  // 담보 입금 암호화폐 주소
        uint64 collateralDueAt;     // 담보 입금 마감 시간
        bytes32 recommendationCode; // 추천인 코드
        uint64 createAt;       // 계약일
        uint64 startAt;        // 개시일
    }

    struct ClosedContract {
        bytes32 loanId;         // 계약 번호
        bytes32 status;         // 종료 타입(S301, S302, S303)
        uint256 returnAmount;   // 유저에게 돌려준 코인
        uint256 feeAmount;      // 더널리에게 이체한 코인
        uint64 evalUnitPrice;   // 1 코인당 금액
        uint64 evalAt;          // 코인 평가 시간
        bytes32 feeRate;        // 이자
        bytes32 prepaymentRate; // 중도상환이자
        bytes32 overdueRate;    // 연체이자
        uint64 closeAt;         // 종료일
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


contract Brick is BrickBase {

    /// @dev 대출 계약서 생성하기
    /// @param _loanId 계약 번호
    /// @param _productId 상품 번호
    /// @param _coinName 담보 코인 종류
    /// @param _coinAmount 담보 코인양
    /// @param _coinUnitPrice 1 코인당 금액
    /// @param _collateralAddress 담보 입금 암호화폐 주소
    /// @param _collateralDueAt 담보 입금 마감 시간
    /// @param _recommendationCode 추천인 코드
    /// @param _createAt 계약일
    function createContract(
        bytes32 _loanId, uint16 _productId, bytes32 _coinName, uint256 _coinAmount, uint64 _coinUnitPrice,
        bytes32 _collateralAddress, uint64 _collateralDueAt, bytes32 _recommendationCode, uint64 _createAt)
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
            collateralDueAt: _collateralDueAt,
            recommendationCode: _recommendationCode,
            createAt: _createAt,
            startAt: 0
        });
        loanIdToContract[_loanId] = _contract;
        contracts.push(_loanId);

        emit ContractCreated(_loanId);
    }


    /// @dev 대출 계약서 생성하기
    /// @param _loanId 계약 번호
    /// @param _startAt 개시일
    function startContract(bytes32 _loanId, uint64 _startAt) public onlyNode {
        require(loanIdToContract[_loanId].loanId != 0, "Not exists in Contract.");
        require(loanIdToContract[_loanId].startAt == 0, "Already started Contract.");
        require(loanIdToClosedContract[_loanId].loanId == 0, "Already exists in ClosedContract.");

        Contract storage c = loanIdToContract[_loanId];
        c.startAt = _startAt;

        emit ContractStarted(_loanId);
    }

    /// @dev 대출 계약 종료하기
    /// @param _loanId 계약 번호
    /// @param _status 종료 타입(S301, S302, S303)
    /// @param _returnAmount 유저에게 돌려준 코인
    /// @param _feeAmount 더널리에게 이체한 코인
    /// @param _evalUnitPrice 1 코인당 평가 금액
    /// @param _evalAt 코인 평가 시간
    /// @param _feeRate 이자
    /// @param _prepaymentRate 중도상환이자
    /// @param _overdueRate 연체이자
    /// @param _closeAt 종료일
    function closeContract(
        bytes32 _loanId, bytes32 _status, uint256 _returnAmount, uint256 _feeAmount, uint64 _evalUnitPrice,
        uint64 _evalAt, bytes32 _feeRate, bytes32 _prepaymentRate, bytes32 _overdueRate, uint64 _closeAt)
        public
        onlyNode
    {
        require(loanIdToContract[_loanId].loanId != 0, "Not exists in Contract.");
        require(loanIdToContract[_loanId].startAt != 0, "Not started Contract.");
        require(loanIdToClosedContract[_loanId].loanId == 0, "Already exists in ClosedContract.");

        ClosedContract memory closedContract = ClosedContract({
            loanId: _loanId,
            status: _status,
            returnAmount: _returnAmount,
            feeAmount: _feeAmount,
            evalUnitPrice: _evalUnitPrice,
            evalAt: _evalAt,
            feeRate: _feeRate,
            prepaymentRate: _prepaymentRate,
            overdueRate: _overdueRate,
            closeAt: _closeAt
        });
        loanIdToClosedContract[_loanId] = closedContract;
        closedContracts.push(_loanId);

        if (_status == bytes32("S301")) {
            emit RedeemCompleted(_loanId);
        } else if (_status == bytes32("S302")) {
            emit LiquidationCompleted(_loanId);
        } else if (_status == bytes32("S303")) {
            emit UndepositCompleted(_loanId);
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
        bytes32 coinName,
        uint256 coinAmount,
        uint64 coinUnitPrice,
        bytes32 collateralAddress,
        uint64 collateralDueAt,
        bytes32 recommendationCode,
        uint64 createAt,
        uint64 startAt)
    {
        require(loanIdToContract[_loanId].loanId != 0, "Not exists in Contract.");

        Contract storage c = loanIdToContract[_loanId];
        loanId = c.loanId;
        productId = uint16(c.productId);
        coinName = c.coinName;
        coinAmount = uint256(c.coinAmount);
        coinUnitPrice = uint64(c.coinUnitPrice);
        collateralAddress = c.collateralAddress;
        collateralDueAt = uint64(c.collateralDueAt);
        recommendationCode = c.recommendationCode;
        createAt = uint64(c.createAt);
        startAt = uint64(c.startAt);
    }

    /// @dev 종료된 대출 계약서 조회하기
    /// @param _loanId 계약 번호
    /// @return The closed contract of given loanId
    function getClosedContract(bytes32 _loanId)
        public
        view
        returns (
        bytes32 loanId,
        bytes32 status,
        uint256 returnAmount,
        uint256 feeAmount,
        uint64 evalUnitPrice,
        uint64 evalAt,
        bytes32 feeRate,
        bytes32 prepaymentRate,
        bytes32 overdueRate,
        uint64 closeAt)
    {
        require(loanIdToClosedContract[_loanId].loanId != 0, "Not exists in ClosedContract.");

        ClosedContract storage c = loanIdToClosedContract[_loanId];

        loanId = c.loanId;
        status = c.status;
        returnAmount = uint256(c.returnAmount);
        feeAmount = uint256(c.feeAmount);
        evalUnitPrice = uint64(c.evalUnitPrice);
        evalAt = uint64(c.evalAt);
        feeRate = c.feeRate;
        prepaymentRate = c.prepaymentRate;
        overdueRate = c.overdueRate;
        closeAt = uint64(c.closeAt);
    }

    function totalContracts() public view returns (uint) {
        return contracts.length;
    }

    function totalClosedContracts() public view returns (uint) {
        return closedContracts.length;
    }

}