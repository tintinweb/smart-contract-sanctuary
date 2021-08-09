/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

pragma solidity 0.7.6;


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

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Witty {
    
    using SafeMath for uint256;
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
        uint order;
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
    uint[] public refPercent = [12,8,5];
    uint public buyerFee = 0.5e18;
    uint public sellerFee = 0.25e18;
    uint public tokenLength;
    
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
    
    event Post(address indexed from,uint post,uint Type,uint favour,uint amt,address expect,address token,uint expiry,uint time);
    event Exchange(address indexed from,uint tradeid,uint tradecount,address sell,uint amount,uint time);
    event BuyerConfirm(address indexed from,uint tradeid,uint tradeidcount,uint sellamt,uint buyamt,uint time);
    event SellerTransfer(address indexed from,uint tradeid,uint tradeidcount,uint amt,uint time);
    event BuyerTransfer(address indexed from,uint tradeid,uint tradeidcount,uint amt,uint time);
    event BuyerCancel(address indexed from,uint tradeid,uint tradeidcount,uint amt,bool status,uint time);
    event SellerCancel(address indexed from,uint tradeid,uint tradeidcount,uint amt,bool status,uint time);
    event SellerActivate(address indexed from,uint tradeid,bool status,uint time);
    event Deposit(address indexed from,address indexed to,address token,uint amt,uint time);
    
    constructor (address _owner)  {
        owner = _owner;
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

    /**
     * @dev Throws if called by other contract
     */
    modifier isContractCheck(address _user) {
        require(!isContract(_user), "Witty: Invalid address");
        _;
    }
    
    // Sellers can create trade
    function createPost(uint _type,uint _amount,address _given,uint _expiry,uint _expectID,uint _favour,address[] memory _ref,uint _order)public payable {
        require (_type == 1 || _type == 2 || _type == 3,"Incorrect type");
        require (_favour > 0 && _favour<=3,"Incorrect favour");
        require (_favour != _type,"Favour and type should not same");
        require (_expectID <=tokenLength && _expectID > 0,"Invalid Expect id");
        require (refPercent.length == _ref.length,"Incoorect referer values");
        require (_order ==1 || _order == 2,"Incorrect order");
        postId++;
        if (_type == 1) {
            require(tokenList[_expectID] != address(0),"Expect address not found");
            require(tokenList[_expectID] != _given,"Expect given not to be same");
            require(_given == address(this),"Token addr should be 0");
            require(_amount == 0 && msg.value > 0 ,"Invalid amount");
            bytes32 _tradeHash = keccak256(abi.encodePacked(postId,msg.sender));
            hashVerify[postId] = _tradeHash;
            traderList[msg.sender][postId].sellerAmt = msg.value;
            trade[postId].expectAddr = tokenList[_expectID];
            address(uint160(_given)).send(msg.value);
            trade[postId].given = _given;
            trade[postId].sellerUser = msg.sender;
            trade[postId].postStatus = true;
            trade[postId].expiry = _expiry;
            trade[postId].types = _type;
            trade[postId].order = _order;
            trade[postId].favour = _favour;
            emit Post(msg.sender,postId,_type,_favour,traderList[msg.sender][postId].sellerAmt,tokenList[_expectID],_given,_expiry,block.timestamp);
        }
        else if (_type == 2) {
            require(tokenList[_expectID] != address(0),"Expect address not found");
            require(_given != address(0),"Need token addr");
            require(tokenList[_expectID] != _given,"Expect given not to be same");
            require(msg.value == 0 && _amount > 0,"Invalid amount");
            bytes32 _tradeHash = keccak256(abi.encodePacked(postId,msg.sender));
            hashVerify[postId] = _tradeHash;
            traderList[msg.sender][postId].sellerAmt = _amount;
            trade[postId].given = _given;
            IERC20(_given).transferFrom(msg.sender,address(this),_amount);
            trade[postId].expectAddr = tokenList[_expectID];
            trade[postId].sellerUser = msg.sender;
            trade[postId].postStatus = true;
            trade[postId].expiry = _expiry;
            trade[postId].types = _type;
            trade[postId].order = _order;
            trade[postId].favour = _favour;
            emit Post(msg.sender,postId,_type,_favour,traderList[msg.sender][postId].sellerAmt,tokenList[_expectID],_given,_expiry,block.timestamp);
        }
        else if(_type == 3) {
            bytes32 _tradeHash = keccak256(abi.encodePacked(postId,msg.sender));
            require(tokenList[_expectID] != _given,"Expect given not to be same");
            hashVerify[postId] = _tradeHash;
            traderList[msg.sender][postId].sellerAmt = _amount;
            trade[postId].expectAddr = tokenList[_expectID];
            trade[postId].sellerUser = msg.sender;
            trade[postId].postStatus = true;
            trade[postId].expiry = _expiry;
            trade[postId].types = _type;
            trade[postId].order = _order;
            trade[postId].favour = _favour;
            emit Post(msg.sender,postId,_type,_favour,traderList[msg.sender][postId].sellerAmt,tokenList[_expectID],_given,_expiry,block.timestamp);
        }
        for (uint i = 0; i<_ref.length; i++) {
            users[msg.sender].referer.push(_ref[i]);
        }
    }
    
    // Buyers can exchange here by given tradeid and amount
    function exchange(uint _tradeID,address _sell,uint _amount,address[] memory _ref)public payable {
        require(_tradeID <= postId && _tradeID > 0,"Invalid trade id");
        require(tradeTiming[_tradeID] == 0 || block.timestamp > tradeTiming[_tradeID],"Previous trade not yet finish");
        require(msg.sender != trade[_tradeID].sellerUser,"Seller wont exchange");
        require(cancelStatus[trade[_tradeID].sellerUser][_tradeID] == false, "Seller cancel the trade");
        require(refPercent.length == _ref.length,"Incoorect referer values");
       
       if (tradeCount[_tradeID] > 0 &&  tradeCountStatus[tradeCount[_tradeID]] == false) {
           require (cancelStatus[trade[_tradeID].sellerUser][_tradeID] == true,"Previous trade not yet canceled");
       } 
        if (trade[_tradeID].favour == 1) {
            require(msg.value <= traderList[trade[_tradeID].sellerUser][_tradeID].sellerAmt,"Insufficient amount");
            require(msg.value > 0 && _amount == 0,"Incorrect value");
            require(trade[_tradeID].expectAddr == _sell,"This is not expect addr");
            address(uint160(address(this))).send(msg.value);
            traderList[msg.sender][_tradeID].buyerAmt = traderList[msg.sender][_tradeID].buyerAmt.add(msg.value);
        }
        else if (trade[_tradeID].favour == 2) {
            require(_amount <= traderList[trade[_tradeID].sellerUser][_tradeID].sellerAmt,"Insufficient amount");
            require(_amount > 0 && msg.value == 0,"Incorrect value");
            require(trade[_tradeID].expectAddr == _sell,"This is not expect addr");
            IERC20(_sell).transferFrom(msg.sender,address(this),_amount);
            traderList[msg.sender][_tradeID].buyerAmt = traderList[msg.sender][_tradeID].buyerAmt.add(_amount);
        }
        else if (trade[_tradeID].favour == 3) {
            require(trade[_tradeID].expectAddr == _sell,"This is not expect addr");
            traderList[msg.sender][_tradeID].buyerAmt = traderList[msg.sender][_tradeID].buyerAmt.add(_amount);
        }
        trade[_tradeID].expiry = block.timestamp.add( trade[_tradeID].expiry);
        tradeTiming[_tradeID] = trade[_tradeID].expiry;
        trade[_tradeID].buyerTradeConfirm = true;
        trade[_tradeID].buyerUser= msg.sender;
        tradeCount[_tradeID]++;
        traderList[msg.sender][_tradeID].count++;
        for (uint i = 0; i<_ref.length; i++) {
            users[msg.sender].referer.push(_ref[i]);
        }
        emit Exchange(msg.sender,_tradeID,tradeCount[_tradeID],_sell,_amount,block.timestamp);
    }
    
    // Seller need to confimation the exchange
    function buyerSellerConfimation(uint _tradeId,uint _sellAmt,uint _buyAmt) public {
         require(_tradeId <= postId && _tradeId > 0,"Invalid trade id");
         require(trade[_tradeId].expiry >  block.timestamp,"Trade expired");
         require(trade[_tradeId].buyerTradeConfirm == true);
         require(cancelStatus[trade[_tradeId].buyerUser][_tradeId] == false && cancelStatus[trade[_tradeId].sellerUser][_tradeId] == false,"Trade cancelled");
         bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,msg.sender));
         require(hashVerify[_tradeId] == _tradeHash,"Incorrect hash");
         trade[_tradeId].sellerTraderConfirm = true;
         sellerTransfer(_tradeId,_sellAmt,tradeCount[_tradeId]);
         buyerTransfer(_tradeId,_buyAmt,tradeCount[_tradeId]);
         tradeCountStatus[tradeCount[_tradeId]] = true;
         trade[_tradeId].tradeStatus = true;
         emit BuyerConfirm(msg.sender,_tradeId,tradeCount[_tradeId],_sellAmt,_buyAmt,block.timestamp);
    }
    
    function sellerTransfer(uint _tradeID,uint _amount,uint _count) internal {
        address seller = trade[_tradeID].sellerUser;
        address buyer = trade[_tradeID].buyerUser;
        uint refPercent = _amount.mul(sellerFee).div(100e18);
        require(traderList[seller][_tradeID].sellerAmt >= _amount.add(refPercent),"Seller not have enough money");
        if (trade[_tradeID].types == 1) {
            address(uint160(buyer)).send(_amount);
             traderList[seller][_tradeID].sellerAmt = traderList[seller][_tradeID].sellerAmt.sub(
                 _amount.add(refPercent));
        }
        else if (trade[_tradeID].types == 2) {
            IERC20(trade[_tradeID].given).transfer(buyer, _amount);
            traderList[seller][_tradeID].sellerAmt = traderList[seller][_tradeID].sellerAmt.sub(
                 _amount.add(refPercent));
        }
        seller_refPayout(seller,_tradeID,trade[_tradeID].types,refPercent);
        trade[_tradeID].buyerTradeConfirm = false;
        userTradeCountStatus[buyer][_tradeID][_count] = true;
        emit SellerTransfer(msg.sender,_tradeID,_count,_amount,block.timestamp);
    }
    
    function buyerTransfer(uint _tradeID,uint _amount,uint _count) internal {
        address buyer = trade[_tradeID].buyerUser;
        address seller = trade[_tradeID].sellerUser;
        uint refPercent = _amount.mul(buyerFee).div(100e18);
        require(traderList[buyer][_tradeID].buyerAmt >= _amount.add(refPercent),"Seller not have enough money");
        if (trade[_tradeID].favour == 1) {
            address(uint160(seller)).send(_amount);
             traderList[buyer][_tradeID].buyerAmt = traderList[buyer][_tradeID].buyerAmt.sub(
                 _amount.add(refPercent));
        }
        else if (trade[_tradeID].favour == 2) {
            IERC20(trade[_tradeID].expectAddr).transfer(seller, _amount);
            traderList[buyer][_tradeID].buyerAmt = traderList[buyer][_tradeID].buyerAmt.sub(
                 _amount.add(refPercent));
        }
        buyer_refPayout(buyer,_tradeID,trade[_tradeID].favour,refPercent);
        userTradeCountStatus[seller][_tradeID][_count] = true;
        emit BuyerTransfer(msg.sender,_tradeID,_count,_amount,block.timestamp);
    }
    
    function seller_refPayout(address _user,uint _tradeid,uint _type,uint _amount) internal {
        for (uint i = 0; i < 3; i++){
            if (_type == 1 && users[_user].referer[i] != address(0) && users[_user].referer[i] != _user) {
               address(uint160(users[_user].referer[i])).send(_amount.mul(refPercent[i]).div(100));
                users[_user].refererCommission = users[_user].refererCommission.add(_amount.mul(refPercent[i]).div(100));
            }
            else if (_type == 2 && users[_user].referer[i] != address(0) && users[_user].referer[i] != _user) {
                IERC20(trade[_tradeid].given).transfer(users[_user].referer[i], _amount.mul(refPercent[i]).div(100));
                users[_user].refererCommission = users[_user].refererCommission.add(_amount.mul(refPercent[i]).div(100));
            }
        }
    }
    
     function buyer_refPayout(address _user,uint _tradeid,uint _type,uint _amount) internal {
        for (uint i = 0; i < 3; i++) {
            if (_type == 1 && users[_user].referer[i] != address(0) && users[_user].referer[i] != _user) {
               address(uint160(users[_user].referer[i])).send(_amount.mul(refPercent[i]).div(100));
                users[_user].refererCommission = users[_user].refererCommission.add(_amount.mul(refPercent[i]).div(100));
            }
            else if (_type == 2 && users[_user].referer[i] != address(0) && users[_user].referer[i] != _user) {
                IERC20(trade[_tradeid].expectAddr).transfer(users[_user].referer[i], _amount.mul(refPercent[i]).div(100));
                users[_user].refererCommission = users[_user].refererCommission.add(_amount.mul(refPercent[i]).div(100));
            }
        }
    }
    
    // Seller can cancel the trade
    function sellerCancel(uint _tradeid,uint _count) public {
        require(_tradeid <= postId && _tradeid > 0,"Invalid trade id");
        require(tradeCount[_tradeid] == _count,"Incorrect count");
        require(userTradeCountStatus[msg.sender][_tradeid][_count] == false,"Not eligible for cancel");
        require(trade[_tradeid].sellerUser == msg.sender,"Invalid user");
        require(cancelStatus[msg.sender][_tradeid] == false,"Already cancelled");
        uint amount = traderList[msg.sender][_tradeid].sellerAmt;
        uint feeAmount = amount.mul(withrawFee[trade[_tradeid].given]).div(100e18);
        if (trade[_tradeid].types == 1) {
            traderList[msg.sender][_tradeid].sellerAmt = traderList[msg.sender][_tradeid].sellerAmt.sub(amount);
            address(uint160(msg.sender)).send(amount.sub(feeAmount));
            cancelStatus[msg.sender][_tradeid] = true;
            emit SellerCancel(msg.sender,_tradeid,_count,amount.sub(feeAmount),
            cancelStatus[msg.sender][_tradeid],block.timestamp);
    }
        
        else if (trade[_tradeid].types == 2) {
            traderList[msg.sender][_tradeid].sellerAmt = traderList[msg.sender][_tradeid].sellerAmt.sub(amount);
            IERC20(trade[_tradeid].given).transfer(msg.sender,amount.sub(feeAmount));
            cancelStatus[msg.sender][_tradeid] = true;
            emit SellerCancel(msg.sender,_tradeid,_count,amount.sub(feeAmount),
            cancelStatus[msg.sender][_tradeid],block.timestamp);
        }
        
    }
    
    // Buyer can cancel the trade
    function buyerCancel(uint _tradeid,uint _count) public {
        require(_tradeid <= postId && _tradeid > 0,"Invalid trade id");
        require(tradeCount[_tradeid] == _count,"Incorrect count");
        require(userTradeCountStatus[msg.sender][_tradeid][_count] == false,"Not eligible for cancel");
        require(trade[_tradeid].buyerUser == msg.sender,"Invalid user");
        require(cancelStatus[msg.sender][_tradeid] == false,"Already cancelled");
        uint amount = traderList[msg.sender][_tradeid].buyerAmt;
        uint feeAmount = amount.mul(withrawFee[trade[_tradeid].expectAddr]).div(100e18);
        if (trade[_tradeid].favour == 1) {
            traderList[msg.sender][_tradeid].buyerAmt = traderList[msg.sender][_tradeid].buyerAmt.sub(amount);
            address(uint160(msg.sender)).send(amount.sub(feeAmount));
            cancelStatus[msg.sender][_tradeid] = true;
            emit BuyerCancel(msg.sender,_tradeid,_count,amount.sub(feeAmount),
            cancelStatus[msg.sender][_tradeid],block.timestamp);
        }
        else if (trade[_tradeid].favour == 2) {
            traderList[msg.sender][_tradeid].buyerAmt = traderList[msg.sender][_tradeid].buyerAmt.sub(
             amount);
            IERC20(trade[_tradeid].expectAddr).transfer(msg.sender,amount.sub(feeAmount));
            cancelStatus[msg.sender][_tradeid] = true;
            emit BuyerCancel(msg.sender,_tradeid,_count,amount.sub(feeAmount),
            cancelStatus[msg.sender][_tradeid],block.timestamp);
        }
        
    }
    
    // Seller can activate the trade
    function sellertradeActivate(uint _tradeiD,bool _tradeStatus)public {
       require(_tradeiD <= postId && _tradeiD > 0,"Invalid trade id");
        require(cancelStatus[msg.sender][_tradeiD] == true);
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeiD,msg.sender));
        require(hashVerify[_tradeiD] == _tradeHash,"Incorrect hash");
        cancelStatus[msg.sender][_tradeiD] = _tradeStatus;
        emit SellerActivate(msg.sender,_tradeiD,_tradeStatus,block.timestamp);
    }
    
    // Seller can deposit the amount
    function deposit(uint _tradeID,address _asset,uint _amount)public payable {
        require(_tradeID <= postId && _tradeID > 0,"Invalid trade id");
        require(msg.sender == trade[_tradeID].sellerUser,"Invalid user");
        if (trade[_tradeID].types == 1) {
        require(_asset == address(this),"Wrong asset address");
        require(_amount == 0 && msg.value > 0,"Incorrect amount");
        address(uint160(_asset)).send(msg.value);
        traderList[msg.sender][_tradeID].sellerAmt = traderList[msg.sender][_tradeID].sellerAmt.add(msg.value);
        emit Deposit(msg.sender,address(this),_asset,msg.value,block.timestamp);
        }
        else if (trade[_tradeID].types == 2) {
        require(_asset == trade[_tradeID].given,"Wrong asset address");
        require(_amount > 0 &&  msg.value == 0,"Incorrect amount");
        IERC20(_asset).transferFrom(msg.sender,address(this),_amount);
        traderList[msg.sender][_tradeID].sellerAmt = traderList[msg.sender][_tradeID].sellerAmt.add(_amount);
        emit Deposit(msg.sender,address(this),_asset,_amount,block.timestamp);
        }
    }
    
    // 
    function viewReferer(address _user) public view returns(address,address,address) {
        return(users[_user].referer[0],
               users[_user].referer[1],
               users[_user].referer[2]);
    }
    
    function updateRefCommission(uint[] memory _percent,uint _sellfee,uint _buyfee)public onlyOwner {
        refPercent = _percent;
        sellerFee = _sellfee;
        buyerFee = _buyfee;
    }
    
    function addToken(address _token)public onlyOwner {
        tokenLength++;
        tokenList[tokenLength] = _token;
    }
    
    function setWithdrawFee(address _token,uint _fee)public onlyOwner {
        _fee = _fee.mul(1e18);
        withrawFee[_token] = _fee;
    }
    
    function failSafe(address _from,address _toUser, uint _amount,uint _type) external onlyOwner returns(bool) {
        require(_toUser != address(0), "Invalid Address");
        if (_type == 1) {
           require(address(this).balance >= _amount, "Witty: Insufficient balance");
            require(address(uint160(_toUser)).send(_amount), "Witty: Transaction failed");
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

    /**
     * @dev isContract: Returns true if account is a contract
     */
    function isContract(address _account) public view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(_account)
        }
        if (size != 0)
            return true;
        return false;
    }
}