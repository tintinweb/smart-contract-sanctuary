/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Witty is ReentrancyGuard {
    
    //using SafeMath for uint256;
    struct proposals{
        address sellerUser;
        address buyerUser;
        uint expiry;
        bool postStatus;
        bool tradeStatus;
        uint types;
        uint favour;
        address given;
        address expectAddr;
        uint escrowAmt;
        bool sellerTraderConfirm;
        bool buyerTradeConfirm;
    }
    
    struct tradingDetails {
        uint expiryTime;
        uint count;
        bool status;
        uint sellerAmt;
        uint buyerAmt;
    }
    
    struct userDetails {
        address[] referer;
        uint refererCommission;
    }
    
    address public owner;
    uint public postId;
    bool public lockStatus;
    uint[3] public refPercent = [12,8,5];
    uint public buyerFee = 0.5e18;
    uint public sellerFee = 0.25e18;
    uint8 public tokenLength;
    address public token;
    
    mapping(uint => proposals)public trade;
    mapping(uint => bytes32)public hashVerify;
    mapping(address => mapping(uint => bool))public cancelStatus;
    mapping(uint => uint)public tradeTiming;
    mapping(uint => uint)public tradeCount;
    mapping(uint => bool)public tradeCountStatus;
    mapping(address => mapping(uint => tradingDetails))public traderList;
    mapping(address => mapping(uint => mapping(uint => bool)))public userTradeCountStatus;
    mapping(address => userDetails)public users;
    mapping(uint => address)public tokenList;
    mapping(address => uint)public withrawFee;
    mapping(address => uint)public wittyBalance;
    
    //Fiat
    mapping(uint => uint)public inrCount;
    mapping(uint => mapping(uint => bool))public inrStatus;
    mapping(uint => mapping(uint => bool))public disputeStatus;
    mapping(address => mapping(uint => bool))public disputeAgainst;
    mapping(uint => bool)public escrowStatus;

    event Post(address indexed from,uint post,uint Type,uint favour,uint amt,address expect,address token,uint expiry,uint time);
    event Exchange(address indexed from,uint tradeid,uint tradecount,address sell,uint amount,uint time);
    event BuyerConfirm(address indexed from,uint tradeid,uint tradeidcount,uint sellamt,uint buyamt,uint time);
    event SellerTransfer(address indexed from,uint tradeid,uint tradeidcount,uint amt,uint time);
    event BuyerTransfer(address indexed from,uint tradeid,uint tradeidcount,uint amt,uint time);
    event BuyerCancel(address indexed from,uint tradeid,uint tradeidcount,uint amt,bool status,uint time);
    event SellerCancel(address indexed from,uint tradeid,uint tradeidcount,uint amt,bool status,uint time);
    event SellerActivate(address indexed from,uint tradeid,bool status,uint time);
    event Deposit(address indexed from,address indexed to,address token,uint amt,uint time);
    event Dispute(address indexed from,uint id,uint time);
    event DisputeConfirm(address indexed from,address indexed to,uint amount,uint id);
    
    constructor (address _owner,address _witty)  {
        owner = _owner;
        token = _witty;
    }
    
     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
    /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, "Witty: Contract Locked");
        _;
    }
    
    modifier Trade(uint _tradeID) {
        require(_tradeID <= postId && _tradeID > 0,"Invalid trade id");
         _;
    }
    
    
    receive()payable external {}

    function depositWitty(uint amount)public {
        require(amount > 0,"Invalid params");
        IERC20(token).transferFrom(msg.sender,address(this),amount);
        wittyBalance[msg.sender] += amount;
    }
    
    // Sellers can create trade
    function createPost(uint _type,uint _amount,address _given,uint _expiry,uint _expectID,uint _favour,address[] memory _ref)public isLock payable {
        require (_type == 1 || _type == 2,"Incorrect type");
        require (_favour > 0 && _favour<=3,"Incorrect favour");
        require (_expectID <=tokenLength && _expectID > 0,"Invalid Expect id");
        require (refPercent.length == _ref.length,"Incoorect referer values");
        postId++;
        proposals storage _Trade = trade[postId];
        if (_type == 1) {
            if (_favour != 3) {
            require(tokenList[_expectID] != address(0),"Expect address not found");
            require(tokenList[_expectID] != _given,"Expect given not to be same");
            }
            require(_given == address(this),"Token addr should be 0");
            require(_amount == 0 && msg.value > 0 ,"Invalid amount");
            bytes32 _tradeHash = keccak256(abi.encodePacked(postId,msg.sender));
            hashVerify[postId] = _tradeHash;
            traderList[msg.sender][postId].sellerAmt = msg.value;
            if (_favour != 3) {
            _Trade.expectAddr = tokenList[_expectID];
            }
            require(payable(_given).send(msg.value),"Type1 Failed");
            _Trade.given = _given;
            _Trade.sellerUser = msg.sender;
            _Trade.postStatus = true;
            _Trade.expiry = _expiry;
            _Trade.types = _type;
            _Trade.favour = _favour;
            emit Post(msg.sender,postId,_type,_favour,traderList[msg.sender][postId].sellerAmt,tokenList[_expectID],_given,_expiry,block.timestamp);
        }
        else if (_type == 2) {
            if (_favour != 3) {
            require(tokenList[_expectID] != address(0),"Expect address not found");
            require(tokenList[_expectID] != _given,"Expect given not to be same");
            }
            require(_given != address(0),"Need token addr");
            require(msg.value == 0 && _amount > 0,"Invalid amount");
            bytes32 _tradeHash = keccak256(abi.encodePacked(postId,msg.sender));
            hashVerify[postId] = _tradeHash;
            traderList[msg.sender][postId].sellerAmt = _amount;
            _Trade.given = _given;
            require(IERC20(_given).transferFrom(msg.sender,address(this),_amount),"Type 2 failed");
            if (_favour != 3) {
            _Trade.expectAddr = tokenList[_expectID];
            }
            _Trade.sellerUser = msg.sender;
            _Trade.postStatus = true;
            _Trade.expiry = _expiry;
            _Trade.types = _type;
            _Trade.favour = _favour;
            emit Post(msg.sender,postId,_type,_favour,traderList[msg.sender][postId].sellerAmt,tokenList[_expectID],_given,_expiry,block.timestamp);
        }
        if (users[msg.sender].referer.length == 0) {
            for (uint i = 0; i<_ref.length; i++) {
            users[msg.sender].referer.push(_ref[i]);
            }
        }
    }
    
    // Buyers can exchange here by given tradeid and amount
    function exchange(uint _tradeID,address _sell,uint _amount,address[] memory _ref)public isLock Trade(_tradeID)  payable {
        proposals storage _Trade = trade[_tradeID];
        require(_Trade.favour != 3,"Revert for INR");
        require(tradeTiming[_tradeID] == 0 || block.timestamp > tradeTiming[_tradeID],"Previous trade not yet finish");
        require(msg.sender != _Trade.sellerUser,"Seller wont exchange");
        require(cancelStatus[_Trade.sellerUser][_tradeID] == false, "Seller cancel the trade");
        require(refPercent.length == _ref.length,"Incoorect referer values");
       
       if (tradeCount[_tradeID] > 0 &&  tradeCountStatus[tradeCount[_tradeID]] == false) {
           require (cancelStatus[_Trade.sellerUser][_tradeID] == true,"Previous trade not yet canceled");
       } 
        if (_Trade.favour == 1) {
            require(msg.value > 0 && _amount == 0,"Incorrect value");
            require(_Trade.expectAddr == _sell,"This is not expect addr");
            require(payable(address(this)).send(msg.value),"Favour 1 failed");
            traderList[msg.sender][_tradeID].buyerAmt += msg.value;
        }
        else if (_Trade.favour == 2) {
            require(_amount > 0 && msg.value == 0,"Incorrect value");
            require(_Trade.expectAddr == _sell,"This is not expect addr");
            require(IERC20(_sell).transferFrom(msg.sender,address(this),_amount),"Favour 2 failed");
            traderList[msg.sender][_tradeID].buyerAmt += _amount;
        }
        _Trade.expiry = block.timestamp + _Trade.expiry;
        tradeTiming[_tradeID] = _Trade.expiry;
        _Trade.buyerTradeConfirm = true;
        _Trade.buyerUser= msg.sender;
        tradeCount[_tradeID]++;
        traderList[msg.sender][_tradeID].count++;
        if (users[msg.sender].referer.length == 0) {
        for (uint i = 0; i<_ref.length; i++) {
            users[msg.sender].referer.push(_ref[i]);
        }
        }
        emit Exchange(msg.sender,_tradeID,tradeCount[_tradeID],_sell,_amount,block.timestamp);
    }
    
    // Seller need to confimation the exchange
    function buyerSellerConfimation(uint _tradeId,uint _sellAmt,uint _buyAmt,uint8 sellchoice,uint8 buychoice) public isLock nonReentrant Trade(_tradeId)  {
         proposals storage _Trade = trade[_tradeId];
         require(_Trade.favour != 3,"Revert for INR");
         require(_Trade.expiry >  block.timestamp,"Trade expired");
         require(_Trade.buyerTradeConfirm == true);
         require(cancelStatus[_Trade.buyerUser][_tradeId] == false && cancelStatus[_Trade.sellerUser][_tradeId] == false,"Trade cancelled");
         bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,msg.sender));
         require(hashVerify[_tradeId] == _tradeHash,"Incorrect hash");
         _Trade.sellerTraderConfirm = true;
         sellerTransfer(_tradeId,_sellAmt,tradeCount[_tradeId],sellchoice);
         buyerTransfer(_tradeId,_buyAmt,tradeCount[_tradeId],buychoice);
         tradeCountStatus[tradeCount[_tradeId]] = true;
         _Trade.tradeStatus = true;
         emit BuyerConfirm(msg.sender,_tradeId,tradeCount[_tradeId],_sellAmt,_buyAmt,block.timestamp);
    }
    
    function createEscrow(address _buyer,uint _tradeid,uint _sellAmt,uint8 _choice) public isLock {
        proposals storage _Trade = trade[_tradeid];
        tradingDetails storage _tradingDetail = traderList[msg.sender][_tradeid];
        require(_buyer != msg.sender,"Incorrect buyer");
        require(escrowStatus[_tradeid] == false,"Escrow not yet settled");
        if (inrCount[_tradeid] > 0 && inrStatus[_tradeid][inrCount[_tradeid]] == false) {
            require(disputeStatus[_tradeid][inrCount[_tradeid]] == true,"Previous trade not settled");
        }
        uint _refPercent = _sellAmt*sellerFee/100e18;
        if (_choice == 0) {
            require(_tradingDetail.sellerAmt >= _sellAmt + _refPercent,"Seller not have enough money");
        }
        else {
            require(_tradingDetail.sellerAmt >= _sellAmt,"Seller not have enough money");
        }
        require(_Trade.favour == 3,"Revert");
        require(_Trade.sellerUser == msg.sender,"Invalid user");
        inrCount[_tradeid]++;
        _tradingDetail.sellerAmt -= _sellAmt;
        _Trade.escrowAmt = _sellAmt;
        _Trade.buyerUser = _buyer;
        escrowStatus[_tradeid] = true;
    }
    
    function _buyerSellerConfimationFiat(uint _tradeId,uint _amt,address _buyer,uint _time,uint8 sellchoice) public isLock nonReentrant{
        proposals storage _Trade = trade[_tradeId];
        tradingDetails storage _tradingDetail = traderList[msg.sender][_tradeId];
        require(escrowStatus[_tradeId] == true,"Escrow not created");
        require(_buyer == _Trade.buyerUser,"Incorrrect buyer");
        require(_amt ==  _Trade.escrowAmt,"Incorrrect amount");
        require(block.timestamp <= _Trade.expiry + _time,"Trade expired");
        require(_Trade.sellerUser == msg.sender,"Invalid user");
        require(_Trade.favour == 3,"Revert");
        uint _refPercent = _amt*sellerFee/100e18;
        if (_Trade.types == 1) {
            require(payable(_buyer).send(_amt),"Fiat buyeraddress Failed");
            if (sellchoice == 0) {
            _tradingDetail.sellerAmt -= _refPercent;
            
            }
            _Trade.escrowAmt -= _amt;
        }
        else if (_Trade.types == 2) {
            require(IERC20(_Trade.given).transfer(_buyer, _amt),"Fiat Token Failed");
             if (sellchoice == 0) {
            _tradingDetail.sellerAmt -= _refPercent;
             }
            _Trade.escrowAmt -= _amt;
        }
        inrStatus[_tradeId][inrCount[_tradeId]] = true;
        escrowStatus[_tradeId] = false;
        seller_refPayout(msg.sender,_tradeId,_Trade.types,_refPercent,sellchoice);
    }
    
    function sellerTransfer(uint _tradeID,uint _amount,uint _count,uint8 choice) internal {
        proposals storage _Trade = trade[_tradeID];
        address seller = _Trade.sellerUser;
        address buyer = _Trade.buyerUser;
        uint _refPercent = _amount*sellerFee/100e18;
        require(traderList[seller][_tradeID].sellerAmt >= _amount + _refPercent,"Seller not have enough money");
        if (choice == 0) {
        if (_Trade.types == 1) {
            require(payable(buyer).send(_amount),"Type 1 Sellertransfer failed");
             traderList[seller][_tradeID].sellerAmt -= (_amount + _refPercent);
        }
        else if (_Trade.types == 2) {
            require(IERC20(_Trade.given).transfer(buyer, _amount),"Type 2 buyertransfer failed");
            traderList[seller][_tradeID].sellerAmt -= (_amount + _refPercent);
        }
        }
        else{
             if (_Trade.types == 1) {
            require(payable(buyer).send(_amount),"Type 1 Sellertransfer failed");
             traderList[seller][_tradeID].sellerAmt -= _amount;
        }
        else if (_Trade.types == 2) {
            require(IERC20(trade[_tradeID].given).transfer(buyer, _amount),"Type 2 buyertransfer failed");
            traderList[seller][_tradeID].sellerAmt -= _amount;
        }
        }
        seller_refPayout(seller,_tradeID,_Trade.types,_refPercent,choice);
        _Trade.buyerTradeConfirm = false;
        userTradeCountStatus[buyer][_tradeID][_count] = true;
        emit SellerTransfer(msg.sender,_tradeID,_count,_amount,block.timestamp);
    }
    
    function buyerTransfer(uint _tradeID,uint _amount,uint _count,uint8 choice) internal {
        proposals storage _Trade = trade[_tradeID];
        address buyer = _Trade.buyerUser;
        address seller = _Trade.sellerUser;
        uint _refPercent = _amount*buyerFee/100e18;
        require(traderList[buyer][_tradeID].buyerAmt >= _amount + _refPercent,"Seller not have enough money");
        if (choice == 0) {
        if (_Trade.favour == 1) {
            require(payable(seller).send(_amount),"Type 1 buyertransfer failed");
            traderList[buyer][_tradeID].buyerAmt -= (_amount + _refPercent);
        }
        else if (_Trade.favour == 2) {
            require(IERC20(_Trade.expectAddr).transfer(seller, _amount),"Type 2 buyertransfer failed");
            traderList[buyer][_tradeID].buyerAmt -= (_amount + _refPercent);
        }
        }
        else {
             if (_Trade.favour == 1) {
            require(payable(seller).send(_amount),"Type 1 buyertransfer failed");
            traderList[buyer][_tradeID].buyerAmt -= _amount;
        }
        else if (_Trade.favour == 2) {
            require(IERC20(_Trade.expectAddr).transfer(seller, _amount),"Type 2 buyertransfer failed");
             traderList[buyer][_tradeID].buyerAmt -= _amount;
        }
        }
        buyer_refPayout(buyer,_tradeID,_Trade.favour,_refPercent,choice);
        userTradeCountStatus[seller][_tradeID][_count] = true;
        emit BuyerTransfer(msg.sender,_tradeID,_count,_amount,block.timestamp);
    }
    
    function seller_refPayout(address _user,uint _tradeid,uint _type,uint _amount,uint8 choice) internal {
        for (uint i = 0; i < 3; i++){
            if (choice == 0) {
            if (_type == 1 && users[_user].referer[i] != address(0) && users[_user].referer[i] != _user) {
               require(payable(users[_user].referer[i]).send(_amount*refPercent[i]/100),"Type1 SellerReferer failed");
                users[users[_user].referer[i]].refererCommission += _amount*refPercent[i]/100;
            }
            else if (_type == 2 && users[_user].referer[i] != address(0) && users[_user].referer[i] != _user) {
                require(IERC20(trade[_tradeid].given).transfer(users[_user].referer[i], _amount*refPercent[i]/100),"Type2 BuyerReferer failed");
                users[users[_user].referer[i]].refererCommission += _amount*refPercent[i]/100;
            }
            }
            else {
                uint _convert = _amount*1e8/1e18;
                IERC20(token).transfer(users[_user].referer[i], _convert*refPercent[i]/100);
                wittyBalance[_user] -= _convert*refPercent[i]/100;
                users[users[_user].referer[i]].refererCommission += _convert*refPercent[i]/100;
            }
        }
    }

     function buyer_refPayout(address _user,uint _tradeid,uint _type,uint _amount,uint8 choice) internal {
        for (uint i = 0; i < 3; i++) {
            if (choice == 0) {
            if (_type == 1 && users[_user].referer[i] != address(0) && users[_user].referer[i] != _user) {
               require(payable(users[_user].referer[i]).send(_amount*refPercent[i]/100),"Type 1 Buyer referer failed");
                users[users[_user].referer[i]].refererCommission += _amount*refPercent[i]/100;
            }
            else if (_type == 2 && users[_user].referer[i] != address(0) && users[_user].referer[i] != _user) {
                require(IERC20(trade[_tradeid].expectAddr).transfer(users[_user].referer[i], _amount*refPercent[i]/100),"Type 2 Buyer referer failed");
                users[users[_user].referer[i]].refererCommission += _amount*refPercent[i]/100;
            }
            }
            else {
                uint _convert = _amount*1e8/1e18;
                IERC20(token).transfer(users[_user].referer[i], _convert*refPercent[i]/100);
                 wittyBalance[_user] -= _convert*refPercent[i]/100;
                 users[users[_user].referer[i]].refererCommission += _convert*refPercent[i]/100;
            }
        }
    }
    
    // Seller can cancel the trade
    function sellerCancel(uint _tradeid,uint _count) public isLock Trade(_tradeid) nonReentrant {
         proposals storage _Trade = trade[_tradeid];
        require(tradeCount[_tradeid] == _count || inrCount[_tradeid] == _count ,"Incorrect count");
        require(userTradeCountStatus[msg.sender][_tradeid][_count] == false || inrStatus[_tradeid][inrCount[_tradeid]] == false,"Not eligible for cancel");
        require(_Trade.sellerUser == msg.sender,"Invalid user");
        require(cancelStatus[msg.sender][_tradeid] == false,"Already cancelled");
        uint amount = traderList[msg.sender][_tradeid].sellerAmt;
        uint feeAmount = amount*withrawFee[_Trade.given]/100e18;
        if (_Trade.types == 1) {
            traderList[msg.sender][_tradeid].sellerAmt -= amount;
            require(payable(msg.sender).send(amount - feeAmount),"Type 1 failed");
            cancelStatus[msg.sender][_tradeid] = true;
            _Trade.postStatus = false;
            emit SellerCancel(msg.sender,_tradeid,_count,amount - feeAmount,
            cancelStatus[msg.sender][_tradeid],block.timestamp);
        }
        
        else if (_Trade.types == 2) {
            traderList[msg.sender][_tradeid].sellerAmt -= amount;
            require(IERC20(_Trade.given).transfer(msg.sender,amount - feeAmount),"Type 2 failed");
            cancelStatus[msg.sender][_tradeid] = true;
            _Trade.postStatus = false;
            emit SellerCancel(msg.sender,_tradeid,_count,amount - feeAmount,
            cancelStatus[msg.sender][_tradeid],block.timestamp);
        }
        
    }
    
    // Buyer can cancel the trade
    function buyerCancel(uint _tradeid,uint _count) public isLock Trade(_tradeid) nonReentrant {
         proposals storage _Trade = trade[_tradeid];
        require(tradeCount[_tradeid] == _count,"Incorrect count");
        require(userTradeCountStatus[msg.sender][_tradeid][_count] == false,"Not eligible for cancel");
        require(_Trade.buyerUser == msg.sender,"Invalid user");
        require(cancelStatus[msg.sender][_tradeid] == false,"Already cancelled");
        uint amount = traderList[msg.sender][_tradeid].buyerAmt;
        uint feeAmount = amount*withrawFee[_Trade.expectAddr]/100e18;
        if (_Trade.favour == 1) {
            traderList[msg.sender][_tradeid].buyerAmt -= amount;
            require(payable(msg.sender).send(amount - feeAmount),"Type 1 failed");
            cancelStatus[msg.sender][_tradeid] = true;
            emit BuyerCancel(msg.sender,_tradeid,_count,amount - feeAmount,
            cancelStatus[msg.sender][_tradeid],block.timestamp);
        }
        else if (_Trade.favour == 2) {
            traderList[msg.sender][_tradeid].buyerAmt -= amount;
            require(IERC20(_Trade.expectAddr).transfer(msg.sender,amount - feeAmount),"Type 2 failed");
            cancelStatus[msg.sender][_tradeid] = true;
            emit BuyerCancel(msg.sender,_tradeid,_count,amount - feeAmount,
            cancelStatus[msg.sender][_tradeid],block.timestamp);
        }
        
    }
    
    function dispute(uint _tradeid,uint _time) public isLock {
        require(block.timestamp > trade[_tradeid].expiry + _time,"Trade expired");
        require(inrStatus[_tradeid][inrCount[_tradeid]] == false,"Payment transfered");
        require (msg.sender == trade[_tradeid].sellerUser || msg.sender == trade[_tradeid].buyerUser,"Invalid user");
        disputeAgainst[msg.sender][_tradeid] = true;
        disputeStatus[_tradeid][inrCount[_tradeid]] = true;
        emit Dispute(msg.sender,_tradeid,block.timestamp);
    }
    
    function disputeConfirm(uint _type,uint _tradeid,address _user) public  onlyOwner {
        address seller = trade[_tradeid].sellerUser;
        address buyer = trade[_tradeid].buyerUser;
        require(disputeAgainst[seller][_tradeid] == true ||
        disputeAgainst[buyer][_tradeid] == true,"Not yet raise");
        require(trade[_tradeid].escrowAmt > 0,"Escarrow wallet has no amount");
        uint amt = trade[_tradeid].escrowAmt;
        trade[_tradeid].escrowAmt -= amt;
        if (_type == 1) {
            require(payable(_user).send(amt),"Type 1 failed");
            disputeAgainst[_user][_tradeid] = false;
            disputeStatus[_tradeid][inrCount[_tradeid]] = false;
            inrStatus[_tradeid][inrCount[_tradeid]] = true;
            emit DisputeConfirm(_user,address(this),amt,_tradeid);
        }
        else if (_type == 2) {
            require(IERC20(trade[_tradeid].given).transfer(_user,amt),"Type 2 failed");
            disputeAgainst[_user][_tradeid] = false;
            disputeStatus[_tradeid][inrCount[_tradeid]] = false;
            inrStatus[_tradeid][inrCount[_tradeid]] = true;
            emit DisputeConfirm(_user,trade[_tradeid].given,amt,_tradeid);
        }
    }
    
    // Seller can activate the trade
    function sellertradeActivate(uint _tradeiD,bool _tradeStatus)public isLock Trade(_tradeiD){
        require(cancelStatus[msg.sender][_tradeiD] == true);
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeiD,msg.sender));
        require(hashVerify[_tradeiD] == _tradeHash,"Incorrect hash");
        cancelStatus[msg.sender][_tradeiD] = _tradeStatus;
        emit SellerActivate(msg.sender,_tradeiD,_tradeStatus,block.timestamp);
    }
    
    // Seller can deposit the amount
    function deposit(uint _tradeID,address _asset,uint _amount)public isLock Trade(_tradeID) payable {
        require(msg.sender == trade[_tradeID].sellerUser,"Invalid user");
        if (trade[_tradeID].types == 1) {
        require(_asset == address(this),"Wrong asset address");
        require(_amount == 0 && msg.value > 0,"Incorrect amount");
        require(payable(_asset).send(msg.value),"Type 1 failed");
        traderList[msg.sender][_tradeID].sellerAmt += msg.value;
        emit Deposit(msg.sender,address(this),_asset,msg.value,block.timestamp);
        }
        else if (trade[_tradeID].types == 2) {
        require(_asset == trade[_tradeID].given,"Wrong asset address");
        require(_amount > 0 &&  msg.value == 0,"Incorrect amount");
        require(IERC20(_asset).transferFrom(msg.sender,address(this),_amount),"Type 2 failed");
        traderList[msg.sender][_tradeID].sellerAmt += _amount;
        emit Deposit(msg.sender,address(this),_asset,_amount,block.timestamp);
        }
    }
    
    function viewReferer(address _user) public view returns(address,address,address) {
        userDetails storage user = users[_user];
        return(user.referer[0],
               user.referer[1],
               user.referer[2]);
    }
    
    function updateRefCommission(uint[3] memory _percent,uint _sellfee,uint _buyfee)public onlyOwner {
        refPercent = _percent;
        sellerFee = _sellfee;
        buyerFee = _buyfee;
    }
    
    function addToken(address _token)public onlyOwner {
        tokenLength++;
        tokenList[tokenLength] = _token;
    }
    
    function setWithdrawFee(address _token,uint _fee)public onlyOwner {
        _fee = _fee*1e18;
        withrawFee[_token] = _fee;
    }
    
    function failSafe(address _from,address _toUser, uint _amount,uint _type) public onlyOwner returns(bool) {
        require(_toUser != address(0), "Invalid Address");
        if (_type == 1) {
           require(address(this).balance >= _amount, "Witty: Insufficient balance");
            require(payable(_toUser).send(_amount), "Witty: Transaction failed");
            return true;
        }
        else if (_type == 2) {
           require(IERC20(_from).balanceOf(address(this)) >= _amount, "Witty: insufficient amount");
            IERC20(_from).transfer(_toUser, _amount);
            return true;
        }
    }
    
    /**
     * @dev contractLock: For contract status
     */
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

}