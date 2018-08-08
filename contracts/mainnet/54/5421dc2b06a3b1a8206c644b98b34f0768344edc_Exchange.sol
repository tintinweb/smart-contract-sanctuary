pragma solidity ^0.4.22;


contract DSAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
        ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

contract Exchange is DSAuth {

    ERC20 public daiToken;
    mapping(address => uint) public dai;
    mapping(address => uint) public eth;

    mapping(address => uint) public totalEth;
    mapping(address => uint) public totalDai;

    mapping(bytes32 => mapping(address => uint)) public callsOwned;
    mapping(bytes32 => mapping(address => uint)) public putsOwned;
    mapping(bytes32 => mapping(address => uint)) public callsSold;
    mapping(bytes32 => mapping(address => uint)) public putsSold;

    mapping(bytes32 => uint) public callsAssigned;
    mapping(bytes32 => uint) public putsAssigned;
    mapping(bytes32 => uint) public callsExercised;
    mapping(bytes32 => uint) public putsExercised;

    mapping(address => mapping(bytes32 => bool)) public cancelled;
    mapping(address => mapping(bytes32 => uint)) public filled;

    // fee values are actually in DAI, ether is just a keyword
    uint public flatFee       = 7 ether;
    uint public contractFee   = 1 ether;
    uint public exerciseFee   = 20 ether;
    uint public settlementFee = 20 ether;
    uint public feesCollected = 0;

    string precisionError = "Precision";

    constructor(address daiAddress) public {
        require(daiAddress != 0x0);
        daiToken = ERC20(daiAddress);
    }

    function() public payable {
        revert();
    }

    event Deposit(address indexed account, uint amount);
    event Withdraw(address indexed account, uint amount, address to);
    event DepositDai(address indexed account, uint amount);
    event WithdrawDai(address indexed account, uint amount, address to);

    function deposit() public payable {
        _addEth(msg.value, msg.sender);
        emit Deposit(msg.sender, msg.value);
    }

    function depositDai(uint amount) public {
        require(daiToken.transferFrom(msg.sender, this, amount));
        _addDai(amount, msg.sender);
        emit DepositDai(msg.sender, amount);
    }

    function withdraw(uint amount, address to) public {
        require(to != 0x0);
        _subEth(amount, msg.sender);
        to.transfer(amount);
        emit Withdraw(msg.sender, amount, to);
    }

    function withdrawDai(uint amount, address to) public {
        require(
            to != 0x0 &&
            daiToken.transfer(to, amount)
        );
        _subDai(amount, msg.sender);
        emit WithdrawDai(msg.sender, amount, to);
    }

    function depositDaiFor(uint amount, address account) public {
        require(
            account != 0x0 &&
            daiToken.transferFrom(msg.sender, this, amount)
        );
        _addDai(amount, account);
        emit DepositDai(account, amount);
    }

    function _addEth(uint amount, address account) private {
        eth[account] += amount;
        totalEth[account] += amount;
    }

    function _subEth(uint amount, address account) private {
        require(eth[account] >= amount);
        eth[account] -= amount;
        totalEth[account] -= amount;
    }

    function _addDai(uint amount, address account) private {
        dai[account] += amount;
        totalDai[account] += amount;
    }

    function _subDai(uint amount, address account) private {
        require(dai[account] >= amount);
        dai[account] -= amount;
        totalDai[account] -= amount;
    }

    // ===== Admin functions ===== //

    function setFeeSchedule(
        uint _flatFee,
        uint _contractFee,
        uint _exerciseFee,
        uint _settlementFee
    ) public auth {
        flatFee = _flatFee;
        contractFee = _contractFee;
        exerciseFee = _exerciseFee;
        settlementFee = _settlementFee;

        require(
            contractFee < 5 ether &&
            flatFee < 6.95 ether &&
            exerciseFee < 20 ether &&
            settlementFee < 20 ether
        );
    }

    function withdrawFees(address to) public auth {
        require(to != 0x0);
        uint amount = feesCollected;
        feesCollected = 0;
        daiToken.transfer(to, amount);
    }

    // ===== End Admin Functions ===== //

    modifier hasFee(uint amount) {
        _;
        _collectFee(msg.sender, calculateFee(amount));
    }

    enum Action {
        BuyCallToOpen,
        BuyCallToClose,
        SellCallToOpen,
        SellCallToClose,
        BuyPutToOpen,
        BuyPutToClose,
        SellPutToOpen,
        SellPutToClose
    }

    event CancelOrder(address indexed account, bytes32 h);
    function cancelOrder(bytes32 h) public {
        cancelled[msg.sender][h] = true;
        emit CancelOrder(msg.sender, h);
    }

    function callBtoWithSto(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.SellCallToOpen, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _bcto(amount, expiration, price, strike, msg.sender);
        _scto(amount, expiration, price, strike, maker);
    }

    function callBtoWithStc(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.SellCallToClose, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _bcto(amount, expiration, price, strike, msg.sender);
        _sctc(amount, expiration, price, strike, maker);
    }

    function callBtcWithSto(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.SellCallToOpen, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _bctc(amount, expiration, price, strike, msg.sender);
        _scto(amount, expiration, price, strike, maker);
    }

    function callBtcWithStc(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.SellCallToClose, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _bctc(amount, expiration, price, strike, msg.sender);
        _sctc(amount, expiration, price, strike, maker);
    }

    function callStoWithBto(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.BuyCallToOpen, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _scto(amount, expiration, price, strike, msg.sender);
        _bcto(amount, expiration, price, strike, maker);
    }

    function callStoWithBtc(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.BuyCallToClose, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _scto(amount, expiration, price, strike, msg.sender);
        _bctc(amount, expiration, price, strike, maker);
    }

    function callStcWithBto(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.BuyCallToOpen, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _sctc(amount, expiration, price, strike, msg.sender);
        _bcto(amount, expiration, price, strike, maker);
    }

    function callStcWithBtc(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.BuyCallToClose, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _sctc(amount, expiration, price, strike, msg.sender);
        _bctc(amount, expiration, price, strike, maker);
    }

    event BuyCallToOpen(address indexed account, uint amount, uint expiration, uint price, uint strike);
    event SellCallToOpen(address indexed account, uint amount, uint expiration, uint price, uint strike);
    event BuyCallToClose(address indexed account, uint amount, uint expiration, uint price, uint strike);
    event SellCallToClose(address indexed account, uint amount, uint expiration, uint price, uint strike);

    function _bcto(uint amount, uint expiration, uint price, uint strike, address buyer) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount * price / 1 ether;
        _subDai(premium, buyer);

        require(callsOwned[series][buyer] + amount >= callsOwned[series][buyer]);
        callsOwned[series][buyer] += amount;
        emit BuyCallToOpen(buyer, amount, expiration, price, strike);
    }

    function _bctc(uint amount, uint expiration, uint price, uint strike, address buyer) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount * price / 1 ether;

        _subDai(premium, buyer);
        eth[buyer] += amount;
        require(callsSold[series][buyer] >= amount);
        callsSold[series][buyer] -= amount;
        emit BuyCallToClose(buyer, amount, expiration, price, strike);
    }

    function _scto(uint amount, uint expiration, uint price, uint strike, address seller) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount * price / 1 ether;

        _addDai(premium, seller);
        require(
            eth[seller] >= amount &&
            callsSold[series][seller] + amount >= callsSold[series][seller]
        );
        eth[seller] -= amount;
        callsSold[series][seller] += amount;
        emit SellCallToOpen(seller, amount, expiration, price, strike);
    }

    function _sctc(uint amount, uint expiration, uint price, uint strike, address seller) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount * price / 1 ether;

        _addDai(premium, seller);
        require(callsOwned[series][seller] >= amount);
        callsOwned[series][seller] -= amount;
        emit SellCallToClose(seller, amount, expiration, price, strike);
    }

    event ExerciseCall(address indexed account, uint amount, uint expiration, uint strike);
    function exerciseCall(
        uint amount,
        uint expiration,
        uint strike
    ) public {
        uint cost = amount * strike / 1 ether;
        bytes32 series = keccak256(expiration, strike);

        require(
            now < expiration &&
            amount % 1 finney == 0 &&
            callsOwned[series][msg.sender] >= amount &&
            amount > 0
        );

        callsOwned[series][msg.sender] -= amount;
        callsExercised[series] += amount;

        _collectFee(msg.sender, exerciseFee);
        _subDai(cost, msg.sender);
        _addEth(amount, msg.sender);
        emit ExerciseCall(msg.sender, amount, expiration, strike);
    }

    event AssignCall(address indexed account, uint amount, uint expiration, uint strike);
    event SettleCall(address indexed account, uint expiration, uint strike);
    function settleCall(uint expiration, uint strike, address writer) public {
        bytes32 series = keccak256(expiration, strike);

        require(
            (msg.sender == writer || isAuthorized(msg.sender, msg.sig)) &&
            now > expiration &&
            callsSold[series][writer] > 0
        );

        if (callsAssigned[series] < callsExercised[series]) {
            uint maximum = callsSold[series][writer];
            uint needed = callsExercised[series] - callsAssigned[series];
            uint assignment = needed > maximum ? maximum : needed;

            totalEth[writer] -= assignment;
            callsAssigned[series] += assignment;
            callsSold[series][writer] -= assignment;

            uint value = strike * assignment / 1 ether;
            _addDai(value, writer);
            emit AssignCall(msg.sender, assignment, expiration, strike);
        }

        _collectFee(writer, settlementFee);
        eth[writer] += callsSold[series][writer];
        callsSold[series][writer] = 0;
        emit SettleCall(writer, expiration, strike);
    }


    // ========== PUT OPTIONS EXCHANGE ========== //

    function putBtoWithSto(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.SellPutToOpen, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _bpto(amount, expiration, price, strike, msg.sender);
        _spto(amount, expiration, price, strike, maker);
    }

    function putBtoWithStc(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.SellPutToClose, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _bpto(amount, expiration, price, strike, msg.sender);
        _sptc(amount, expiration, price, strike, maker);
    }

    function putBtcWithSto(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.SellPutToOpen, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _bptc(amount, expiration, price, strike, msg.sender);
        _spto(amount, expiration, price, strike, maker);
    }

    function putBtcWithStc(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.SellPutToClose, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _bptc(amount, expiration, price, strike, msg.sender);
        _sptc(amount, expiration, price, strike, maker);
    }

    function putStoWithBto(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.BuyPutToOpen, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _spto(amount, expiration, price, strike, msg.sender);
        _bpto(amount, expiration, price, strike, maker);
    }

    function putStoWithBtc(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.BuyPutToClose, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _spto(amount, expiration, price, strike, msg.sender);
        _bptc(amount, expiration, price, strike, maker);
    }

    function putStcWithBto(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.BuyPutToOpen, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _sptc(amount, expiration, price, strike, msg.sender);
        _bpto(amount, expiration, price, strike, maker);
    }

    function putStcWithBtc(
        uint    amount,
        uint    expiration,
        bytes32 nonce,
        uint    price,
        uint    size,
        uint    strike,
        uint    validUntil,
        bytes32 r,
        bytes32 s,
        uint8   v
    ) public hasFee(amount) {
        address maker = _validate(Action.BuyPutToClose, amount, expiration, nonce, price, size, strike, validUntil, r, s, v);
        _sptc(amount, expiration, price, strike, msg.sender);
        _bptc(amount, expiration, price, strike, maker);
    }

    event BuyPutToOpen(address indexed account, uint amount, uint expiration, uint price, uint strike);
    event SellPutToOpen(address indexed account, uint amount, uint expiration, uint price, uint strike);
    event BuyPutToClose(address indexed account, uint amount, uint expiration, uint price, uint strike);
    event SellPutToClose(address indexed account, uint amount, uint expiration, uint price, uint strike);

    function _bpto(uint amount, uint expiration, uint price, uint strike, address buyer) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount * price / 1 ether;

        _subDai(premium, buyer);
        require(putsOwned[series][buyer] + amount >= putsOwned[series][buyer]);
        putsOwned[series][buyer] += amount;
        emit BuyPutToOpen(buyer, amount, expiration, price, strike);
    }

    function _bptc(uint amount, uint expiration, uint price, uint strike, address buyer) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount * price / 1 ether;

        dai[buyer] += strike * amount / 1 ether;
        _subDai(premium, buyer);
        require(putsSold[series][buyer] >= amount);
        putsSold[series][buyer] -= amount;
        emit BuyPutToClose(buyer, amount, expiration, price, strike);
    }

    function _spto(uint amount, uint expiration, uint price, uint strike, address seller) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount * price / 1 ether;
        uint escrow = strike * amount / 1 ether;

        _addDai(premium, seller);
        require(dai[seller] >= escrow);
        dai[seller] -= escrow;
        putsSold[series][seller] += amount;
        emit SellPutToOpen(seller, amount, expiration, price, strike);
    }

    function _sptc(uint amount, uint expiration, uint price, uint strike, address seller) private {
        bytes32 series = keccak256(expiration, strike);
        uint premium = amount * price / 1 ether;

        _addDai(premium, seller);
        require(putsOwned[series][seller] >= amount);
        putsOwned[series][seller] -= amount;
        emit SellPutToClose(seller, amount, expiration, price, strike);
    }

    event ExercisePut(address indexed account, uint amount, uint expiration, uint strike);
    function exercisePut(
        uint amount,
        uint expiration,
        uint strike
    ) public {
        uint yield = amount * strike / 1 ether;
        bytes32 series = keccak256(expiration, strike);

        require(
            now < expiration &&
            amount % 1 finney == 0 &&
            putsOwned[series][msg.sender] >= amount &&
            amount > 0
        );

        putsOwned[series][msg.sender] -= amount;
        putsExercised[series] += amount;

        _subEth(amount, msg.sender);
        _addDai(yield, msg.sender);
        _collectFee(msg.sender, exerciseFee);
        emit ExercisePut(msg.sender, amount, expiration, strike);
    }

    event AssignPut(address indexed account, uint amount, uint expiration, uint strike);
    event SettlePut(address indexed account, uint expiration, uint strike);
    function settlePut(uint expiration, uint strike, address writer) public {

        bytes32 series = keccak256(expiration, strike);

        require(
            (msg.sender == writer || isAuthorized(msg.sender, msg.sig)) &&
            now > expiration &&
            putsSold[series][writer] > 0
        );

        if (putsAssigned[series] < putsExercised[series]) {
            uint maximum = putsSold[series][writer];
            uint needed = putsExercised[series] - putsAssigned[series];
            uint assignment = maximum > needed ? needed : maximum;

            totalDai[writer] -= assignment * strike / 1 ether;
            putsSold[series][writer] -= assignment;
            putsAssigned[series] += assignment;

            _addEth(assignment, writer);
            emit AssignPut(writer, assignment, expiration, strike);
        }

        uint yield = putsSold[series][writer] * strike / 1 ether;
        _collectFee(writer, settlementFee);
        dai[writer] += yield;
        putsSold[series][writer] = 0;
        emit SettlePut(writer, expiration, strike);
    }

    function calculateFee(uint amount) public view returns (uint) {
        return amount * contractFee / 1 ether + flatFee;
    }

    function _validate(
        Action action,
        uint amount,
        uint expiration,
        bytes32 nonce,
        uint price,
        uint size,
        uint strike,
        uint validUntil,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) private returns (address) {
        bytes32 h = keccak256(action, expiration, nonce, price, size, strike, validUntil, this);
        address maker = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", h), v, r, s);
        _validateOrder(amount, expiration, h, maker, price, validUntil, size, strike);
        return maker;
    }

    event TakeOrder(address indexed account, address maker, uint amount, bytes32 h);
    function _validateOrder(uint amount, uint expiration, bytes32 h, address maker, uint price, uint validUntil, uint size, uint strike) internal {
        require(
            strike % 1 ether == 0 &&
            amount % 1 finney == 0 &&
            price % 1 finney == 0 &&
            expiration % 86400 == 0 &&
            cancelled[maker][h] == false &&
            amount <= size - filled[maker][h] &&
            now < validUntil &&
            now < expiration &&
            strike > 10 ether &&
            price < 1200000 ether &&
            size < 1200000 ether &&
            strike < 1200000 ether &&
            price >= 1 finney
        );

        filled[maker][h] += amount;
        emit TakeOrder(msg.sender, maker, amount, h);
    }

    function _collectFee(address account, uint amount) private {
        _subDai(amount, account);
        feesCollected += amount;
    }
}

contract ERC20 {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}