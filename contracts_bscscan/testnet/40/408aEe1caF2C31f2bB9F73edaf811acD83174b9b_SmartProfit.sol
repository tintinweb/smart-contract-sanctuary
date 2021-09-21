/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

/*

  /$$$$$$  /$$      /$$  /$$$$$$  /$$$$$$$  /$$$$$$$$       /$$$$$$$  /$$$$$$$   /$$$$$$  /$$$$$$$$ /$$$$$$ /$$$$$$$$
 /$$__  $$| $$$    /$$$ /$$__  $$| $$__  $$|__  $$__/      | $$__  $$| $$__  $$ /$$__  $$| $$_____/|_  $$_/|__  $$__/
| $$  \__/| $$$$  /$$$$| $$  \ $$| $$  \ $$   | $$         | $$  \ $$| $$  \ $$| $$  \ $$| $$        | $$     | $$
|  $$$$$$ | $$ $$/$$ $$| $$$$$$$$| $$$$$$$/   | $$         | $$$$$$$/| $$$$$$$/| $$  | $$| $$$$$     | $$     | $$
 \____  $$| $$  $$$| $$| $$__  $$| $$__  $$   | $$         | $$____/ | $$__  $$| $$  | $$| $$__/     | $$     | $$
 /$$  \ $$| $$\  $ | $$| $$  | $$| $$  \ $$   | $$         | $$      | $$  \ $$| $$  | $$| $$        | $$     | $$
|  $$$$$$/| $$ \/  | $$| $$  | $$| $$  | $$   | $$         | $$      | $$  | $$|  $$$$$$/| $$       /$$$$$$   | $$
 \______/ |__/     |__/|__/  |__/|__/  |__/   |__/         |__/      |__/  |__/ \______/ |__/      |______/   |__/

Website:     https://smart-profit.info/

 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
  }


  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    return c;
  }
}


contract SmartProfit {
    using SafeMath for uint256;

    struct User {
        address payable wallet;
        uint256 row;
        uint256 col;
        uint256 refId;
        uint256 refCount;
        uint256 upgradedRefs;
        uint256 refBonus;
        uint256 earned;
        uint256 last_row;
        uint8 status;
        bool isForSale;
        uint256 expire;
    }

    mapping (uint256 => User) public users; // привязка адреса пользователя -> карточка пользователя
    mapping (address => uint256) public userId;
    mapping (uint256 => mapping (uint256 => uint256)) globalPlaces;
    mapping (uint256 => uint256) public lastFreePlaceInRow;

    AggregatorV3Interface internal priceFeed;

    uint256[7] private percentage = [11,10,9,8,9,8,10];

    uint256[3] private prices = [30,90,180];

    uint256[3] private terms = [60,180,360];

    uint8[3] private levels = [3,5,7];

    uint256 public lotteryPool;

    uint256 public maxLotteryAmount;

    uint256 public gasPrice = 10 * 10 ** 9;

    uint256 public lastUserId = 1; // последний занятый id юзера (глобальная нумерация)

    uint256 public lastPaymentId;

    uint256 public inactivityPeriod = 7 * 24 * 60 * 60;

    address payable _owner; // владелец контракта

    uint8 public constant MAX_ROW = 93; // макс количество уровней

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FreePlaceFound(uint256 _row, uint256 _col);
    event Register(address indexed _wallet, uint256 _userId, uint256 _row, uint256 _col, uint256 _refId, uint8 _status, uint256 _date);
    event _NewRowLastPlace(uint256 _row, uint256 _col);
    event UplineFound(uint256 userId_, uint256 row_, uint256 col_, uint8 status_, bool isExpired_);
    event RefBonusSent(uint256 _paymentId, uint256 _userId, uint256 _refId, uint256 amount, uint256 date);
    event Upgrade(uint256 _userId, uint8 status, uint256 _date);
    event StartEndRow(uint256 row, uint256 start, uint256 end);
    event PaymentToUpline(uint256 paymentId, uint256 _userId, uint256 _refId, uint8 level, uint256 amount, uint256 date);
    event Transfer(uint256 _userId, uint256 amount);
    event StatusUPdate(uint256 _userId, uint8 status);
    event PlaceSold(uint256 _userId, uint8 status, uint256 expire);
    event AccountExpired(uint256 _userId, bool _expired);
    event Change(uint256 _total, uint256 _change);
    event Values(uint256 v1, uint256 v2,uint256 v3,uint256 v4,uint256 v5,uint256 v6,uint256 v7,uint256 v8,uint256 v9);

    constructor (address payable first) public {
        require(first != address(0), 'Zero addresses are prohibited in parameters');

        //mainnet
        //priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

        //testnet
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);

        User memory user = User({
                                    wallet: first,
                                    row: 1,
                                    col: 1,
                                    refId: 1,
                                    refCount: 0,
                                    upgradedRefs: 0,
                                    refBonus: 0,
                                    earned: 0,
                                    last_row: 2,
                                    status: 0,
                                    isForSale: false,
                                    expire: 0
                                });


        users[1] = user;
        userId[first] = 1;
        globalPlaces[1][1] = 1;
        lastFreePlaceInRow[1] = 2;
        emit Register(first, lastUserId, 1, 1, 1, 0, block.timestamp);
        _owner = first;
        emit OwnershipTransferred(address(0), _owner);

    }


    function getLatestPrice() public view returns (int) {
        //return 300000000000;

        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;

    }

    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        users[1].wallet = newOwner;
        userId[newOwner] = 1;
        userId[_owner] = 0;
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


    // Изменение базовой цены
    function setPrices(uint256[3] memory newPrices) public onlyOwner {
        for (uint256 i = 0; i < newPrices.length; i++) {
          require(newPrices[i] > 0, "Price must not be zero");
        }
        prices = newPrices;
    }


    function setInactivityPeriod(uint256 _period) public onlyOwner {
        inactivityPeriod = _period;
    }

    function setPriceFeed(address _feed) public onlyOwner {
        require(_feed != address(0), "Invalid price feed contract address");
        priceFeed = AggregatorV3Interface(_feed);
    }


    // Изменение сроков действия пакетов
    function setTerms(uint256[3] memory newTerms) public onlyOwner {
        for (uint256 i = 0; i < newTerms.length; i++) {
          require(newTerms[i] > 0, "Term must not be zero");
        }
        terms = newTerms;
    }


    function getTerms() public view returns (uint256[3] memory) {
        uint256[3] memory result = terms;
        return result;
    }

    function getPrices() public view returns (uint256[3] memory) {
        uint256[3] memory result = prices;
        return result;
    }



    function setGasPrice(uint256 _gp) public onlyOwner {
        require(_gp > 0, "Gas price must exceed zero");
        gasPrice = _gp;
    }


    function retriveBNB(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Zero address prohibited");
        uint256 contractBalance = address(this).balance;
        require(amount <= contractBalance, "Insufficient contract BNB balance");
        require(contractBalance.sub(amount) >= lotteryPool, "Remaining contract balance is lower than lottery pool.");
        to.transfer(amount);
    }


    function setMaxLotteryAmount(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Lottery amount must exceed zero");
        maxLotteryAmount = _amount;
    }


    function sendToWinners(uint256[] memory winners) public onlyOwner {
        require(winners.length > 0, "No wallets to send to.");
        require(lotteryPool >= maxLotteryAmount, "Lottery pool is less than required.");
        uint256 amount = lotteryPool.sub(uint256(21000).mul(winners.length).mul(gasPrice)).div(winners.length);
        for (uint256 i = 0; i < winners.length; i++) {
          users[winners[i]].wallet.transfer(amount);
          users[winners[i]].earned = users[winners[i]].earned.add(amount);
        }
        lotteryPool = 0;
    }


    function approveSale(uint256 _id) external {
        require(users[_id].refId == userId[msg.sender], "Only sponsors are allowed to sell places.");
        require(!users[_id].isForSale, "Place is already available for sale.");
        require(isExpired(_id, true), "Place has not expired yet.");
        users[_id].isForSale = true;
    }


    function findFreePlace(uint256 _refId) public returns(uint256, uint256, uint256) {
        uint256 start;
        uint256 end;
        for (uint256 i = users[_refId].last_row; i<=MAX_ROW; i++) {
            start = users[_refId].col.sub(1).mul(5**(i.sub(users[_refId].row)));
            end = start.add(5**(i.sub(users[_refId].row)));
            start = start.add(1);
            if (lastFreePlaceInRow[i] > end) {
                continue;
            }

            if (lastFreePlaceInRow[i] > start && lastFreePlaceInRow[i] < end) {
                start = lastFreePlaceInRow[i];
            }
            emit StartEndRow(i, start, end);

            for (uint256 j=start; j<=end; j++) {
                if (globalPlaces[i][j] == 0) {
                    emit FreePlaceFound(i,j);
                    if (lastFreePlaceInRow[i] == 0 && start == 1) {
                        return (i,j, 2);
                    } else if (start > lastFreePlaceInRow[i]) {
                        return (i,j, lastFreePlaceInRow[i]);
                    } else {
                        return (i,j, j.add(1));
                    }
                }
            }
        }

        return (0, 0, 0);
    }


    function _update(uint256 _userId) external payable {
        require (msg.sender != address(0), "Zero address prohibited.");
        require(lastPaymentId < uint256(-1), "No more registrations allowed");
        require(userId[msg.sender] > 0, "User is not registered");
        require(users[_userId].wallet != address(0), "Invalid user ID");
        uint256 rate = uint256(getLatestPrice());
        require(msg.value >= prices[0].mul(10 ** 26).div(rate), "Insufficient amount of BNB to participate");
        (uint8 st, uint256 change) = checkPayment(msg.value, rate);
        if (change > 0) {
          payable(msg.sender).transfer(change);
        }
        users[userId[msg.sender]].expire = block.timestamp.add(terms[st].mul(86400));
        if (st >= users[userId[msg.sender]].status) {
          users[userId[msg.sender]].status = st;
        } else {
          if (users[userId[msg.sender]].refCount == 5) {
            users[userId[msg.sender]].status = 1;
          } else if (users[userId[msg.sender]].upgradedRefs == 5) {
            users[userId[msg.sender]].status = 2;
          }

        }
        emit Upgrade(_userId, users[userId[msg.sender]].status, block.timestamp);
        processUplines(userId[msg.sender], users[_userId].refId, msg.value.sub(change));

    }


    function _buyPlace(uint256 _id) external payable {
        require (msg.sender != address(0), "Zero address prohibited.");
        require(lastPaymentId < uint256(-1), "No more registrations allowed");
        require((_id > 0 && _id < uint256(-1)), "Invalid user ID");
        require(users[_id].isForSale, "Place is not for sale");
        require(users[_id].wallet != address(0), "Invalid user ID");
        uint256 rate = uint256(getLatestPrice());
        require(msg.value >= prices[0].mul(10 ** 26).div(rate), "Insufficient amount of BNB to participate");
        (uint8 st, uint256 change) = checkPayment(msg.value, rate);
        if (change > 0) {
          payable(msg.sender).transfer(change);
        }
        userId[users[_id].wallet] = 0;
        users[_id].wallet = payable(msg.sender);
        userId[msg.sender] = _id;
        users[_id].expire = block.timestamp.add(terms[st].mul(86400));
        if (st >= users[_id].status) {
          users[_id].status = st;
        } else {
          if (users[_id].refCount == 5) {
            users[_id].status = 1;
          } else if (users[_id].upgradedRefs == 5) {
            users[_id].status = 2;
          }

        }
        emit PlaceSold(_id, users[_id].status, users[_id].expire);
        processUplines(_id, users[_id].refId, msg.value.sub(change));
    }


    function _support(uint256 _refId, uint256 _id) external payable {
        require (msg.sender != address(0), "Zero address prohibited.");
        require(lastPaymentId < uint256(-1), "No more registrations allowed");
        require(userId[msg.sender] == 0, "User already registered");
        require((_refId > 0 && _refId < uint256(-1)), "Invalid referral ID");
        require((_id > 0 && _id < uint256(-1)), "Invalid upper ID");
        require(users[_refId].wallet != address(0), "Invalid referral ID");
        require(users[_id].wallet != address(0), "Invalid upper ID");
        require(lastUserId < uint256(-1), "No more registrations allowed");
        require(users[_id].row > users[_refId].row, "Supported id must be located beneath referal id");
        uint256 rate = uint256(getLatestPrice());
        require(msg.value >= prices[0].mul(10 ** 26).div(rate), "Insufficient amount of BNB to participate");
        (uint8 st, uint256 change) = checkPayment(msg.value, rate);
        if (change > 0) {
          payable(msg.sender).transfer(change);
        }
        (uint256 userRow, uint256 userCol, uint256 newRowLastPlace) = findFreePlace(_id);
        require((userRow != 0 && userCol !=0), "No free places left in global matrix");
        lastUserId += 1;
        User memory user = User({
                                    wallet: payable(msg.sender),
                                    row: userRow,
                                    col: userCol,
                                    refId: _refId,
                                    refCount: 0,
                                    upgradedRefs: 0,
                                    refBonus: 0,
                                    earned: 0,
                                    last_row: userRow.add(1),
                                    status: st,
                                    isForSale: false,
                                    expire: block.timestamp.add(terms[st].mul(86400))
                                  });
        users[lastUserId] = user;
        userId[msg.sender] = lastUserId;
        globalPlaces[userRow][userCol] = lastUserId;
        if (users[_id].last_row < userRow) {
            users[_id].last_row = userRow;
        }
        if (newRowLastPlace > lastFreePlaceInRow[userRow]) {
            lastFreePlaceInRow[userRow] = newRowLastPlace;
            emit _NewRowLastPlace(userRow, newRowLastPlace);
        }
        emit Register(msg.sender, lastUserId, userRow, userCol, _refId, st, block.timestamp);
        processUplines(lastUserId, _refId, msg.value.sub(change));
        upgradeReferals(_refId);
    }


    function checkPayment(uint256 amount, uint256 rate) public view returns (uint8 status, uint256 change) {
      if (amount >= prices[2].mul(10 ** 26).div(rate)) {
        return (2, amount.sub(prices[2].mul(10 ** 26).div(rate)));
      } else if (amount >= prices[1].mul(10 ** 26).div(rate)) {
        return (1, amount.sub(prices[1].mul(10 ** 26).div(rate)));
      } else {
        return (0, amount.sub(prices[0].mul(10 ** 26).div(rate)));
      }

    }


    function isExpired(uint256 _id, bool includeInactivityPeriod) internal returns (bool) {
      if (_id == 1) {
        emit AccountExpired(_id, false);
        return false;
      }
      uint256 expireDate = users[_id].expire;
      bool result;
      if (includeInactivityPeriod) {
        result = block.timestamp > expireDate.add(inactivityPeriod);
      } else {
        result = block.timestamp > expireDate;
      }
      emit AccountExpired(_id, result);
      return result;

    }


    function upgradeReferals(uint256 _id) internal {
          users[_id].refCount += 1;
          if (users[_id].refCount == 5 && users[_id].status == 0) {
            users[_id].status = 1;
            emit StatusUPdate(_id, 1);
            uint256 upperId = users[_id].refId;
            users[upperId].upgradedRefs += 1;
            if (users[upperId].upgradedRefs == 5 && users[upperId].status == 1) {
              users[upperId].status = 2;
              emit StatusUPdate(upperId, 2);
            }

          }
    }


    function findUpline(uint256 col) public pure returns(uint256) {
        return uint256(col.sub(1).div(5).add(1));
    }


    function getValues(uint256 _amount) public view returns(uint256[9] memory) {
        uint256[9] memory result;
        result[0] = _amount.div(10);
        result[1] = _amount.div(4);
        for (uint8 i=2; i<9; i++) {
            result[i] = _amount.mul(percentage[i-2]).div(100);
        }
        return result;

    }


    function checkLevel(uint8 counter_, uint8 status_) public pure returns (bool) {
        if (status_ == 0 && counter_ <=2) {
            return true;
        } else if (status_ == 1 && counter_ <=4) {
            return true;
        } else if (status_ == 2 && counter_ <=6) {
            return true;
        } else {
            return false;
        }

    }


    function processUplines(uint256 _userId, uint256 _refId, uint256 _amount) internal {
        uint256[9] memory values = getValues(_amount);
        emit Values(values[0],values[1],values[2],values[3],values[4],values[5],values[6],values[7],values[8]);
        //  10% fo lottery
        lotteryPool = lotteryPool.add(values[0]);
        //25% for referral
        if (!isExpired(_refId, false) || _refId == 1) {
            users[_refId].wallet.transfer(values[1]);
            lastPaymentId += 1;
            users[_refId].refBonus += values[1];
            emit RefBonusSent(lastPaymentId, _userId, _refId, values[1], block.timestamp);
        }

        uint8 counter = 0;
        uint256 uplineId;
        address payable uplineWallet;
        uint256 _row = users[_userId].row;
        uint256 _col = users[_userId].col;
        while (_row > 1 && counter < 7) {
          _col = findUpline(_col);
          uplineId = globalPlaces[_row.sub(1)][_col];
          emit UplineFound(uplineId, _row.sub(1), _col, users[uplineId].status, isExpired(uplineId, false));
          if ((uplineId == 1) || (!isExpired(uplineId, false) && checkLevel(counter, users[uplineId].status))) {
            uplineWallet = users[uplineId].wallet;
            uplineWallet.transfer(values[counter+2]);
            users[uplineId].earned += values[counter+2];
            lastPaymentId += 1;
            emit PaymentToUpline(lastPaymentId, _userId, uplineId, counter+1, values[counter+2], block.timestamp);
          }
          counter++;
          _row--;
        }
    }


    function _register(uint256 _refId) external payable {
        require (msg.sender != address(0), "Zero address prohibited.");
        require(userId[msg.sender] == 0, "User already registered");
        require((_refId > 0 && _refId < uint256(-1)), "Invalid referral ID");
        require(users[_refId].wallet != address(0), "Invalid referral ID");
        require(lastUserId < uint256(-1), "No more registrations allowed");
        require(lastPaymentId < uint256(-1), "No more registrations allowed");
        uint256 rate = uint256(getLatestPrice());
        require(msg.value >= prices[0].mul(10 ** 26).div(rate), "Insufficient amount of BNB to participate");
        (uint8 st, uint256 change) = checkPayment(msg.value, rate);
        if (change > 0) {
            emit Change(msg.value, change);
            payable(msg.sender).transfer(change);
        }
        (uint256 userRow, uint256 userCol, uint256 newRowLastPlace) = findFreePlace(_refId);
        require((userRow != 0 && userCol !=0), "No free places left in global matrix");
        lastUserId += 1;
        User memory user = User({
                                    wallet: payable(msg.sender),
                                    row: userRow,
                                    col: userCol,
                                    refId: _refId,
                                    refCount: 0,
                                    upgradedRefs: 0,
                                    refBonus: 0,
                                    earned: 0,
                                    last_row: userRow.add(1),
                                    status: st,
                                    isForSale: false,
                                    expire: block.timestamp.add(terms[st].mul(86400))
                                  });
        users[lastUserId] = user;
        userId[msg.sender] = lastUserId;
        globalPlaces[userRow][userCol] = lastUserId;
        if (users[_refId].last_row < userRow) {
            users[_refId].last_row = userRow;
        }
        if (newRowLastPlace > lastFreePlaceInRow[userRow]) {
            lastFreePlaceInRow[userRow] = newRowLastPlace;
            emit _NewRowLastPlace(userRow, newRowLastPlace);
        }
        emit Register(msg.sender, lastUserId, userRow, userCol, _refId, st, block.timestamp);
        processUplines(lastUserId, _refId, msg.value.sub(change));
        upgradeReferals(_refId);
    }

}