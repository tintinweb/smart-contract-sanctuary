/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MoneyCar {
    
    struct User {
        address wallet;
        uint256 row;
        uint256 col;
        uint256 refId;
        uint256 refCount;
        uint256 refBonus;
        uint256 last_row;
        uint8 cycle;
        uint256 reinvests;
    }

    mapping (uint256 => bool) clones;
    mapping (address => uint256) public balances;
    mapping (uint256 => uint256[3]) public earned;
    mapping (uint256 => mapping (uint256 => uint256[3])) heldForNextCycle;
    mapping (uint256 => mapping (uint256 => uint256[3])) userLockedRev;
    mapping (uint256 => mapping (uint256 => uint256[3])) txCount;
    mapping (uint256 => User) public users; // привязка адреса пользователя -> карточка пользователя
    mapping (address => uint256) public userId;
    mapping (uint256 => mapping (uint256 => uint256)) globalPlaces;
    mapping (uint256 => uint256) public lastFreePlaceInRow;

    uint8 defaultCycle = 1;

    uint8[5] public levelPercentage = [50, 15, 10, 5, 20];

    uint256 public lastUserId; // последний занятый id юзера (глобальная нумерация)

    uint256 public lastPaymentId;

    uint256 public totalPayout; // общая сумма выплаченных средств

    uint256 private price = 0.03 ether; // базовая цена входа
    address _owner; // владелец контракта

    address payable _clnWithdraw;
    address payable _creator;
    

    address payable[3] private externalAddresses;

    uint8 public constant MAX_ROW = 110; // макс количество уровней

    uint256 public totalClones;
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FreePlaceFound(uint256 _row, uint256 _col);
    event Register(address indexed _wallet, uint256 _userId, uint256 _row, uint256 _col, uint256 _refId);
    event _NewRowLastPlace(uint256 _row, uint256 _col);
    event UplinesFound(uint256 id1, uint256 id2, uint256 id3,uint256 id4,uint256 id5);
    event RefBonusSent(uint256 _refId, uint256 amount);
    event Upgrade(uint256 _userId);
    event Reinvest(uint256 _userId, uint256 _reinvest);
    event NewCycle(uint256 _userId, uint8 cycle);
    event StartEndRow(uint256 row, uint256 start, uint256 end);
    event PaymentToUpline(uint256 paymentId, uint256 _refId, uint256 amount);
    event Locked(uint256 _refId, uint256 userReinvests, uint8 userCycle, uint256 amount);
    event Clone(uint256 _userId, uint256 _row, uint256 _col);
    event Withdraw(uint256 _userId, uint256 amount);
    event Transfer(uint256 _userId, uint256 amount);
    event Held(uint256 _userId, uint256 amount);

    constructor (address payable first) {
        require(first != address(0), 'Zero addresses are prohibited in parameters');
         _status = _NOT_ENTERED;
        User memory user = User({
                                    wallet: first,
                                    row: 1,
                                    col: 1,
                                    refId: 1,
                                    refCount: 30,
                                    refBonus: 0,
                                    last_row: 4,
                                    cycle: defaultCycle,
                                    reinvests: 0
                                });
        users[1] = user;
        txCount[1][0] = [30, 0, 0];
        userId[first] = 1;
        globalPlaces[1][1] = 1;
        lastFreePlaceInRow[1] = 2;
        lastUserId = 1;
        emit Register(first, lastUserId, 1, 1, 1);
        _owner = msg.sender;
        
        emit OwnershipTransferred(address(0), _owner);

    }

    function owner() public view returns (address) {
        return _owner;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;

    }


    function setExternal(address payable[3] memory _externalAddresses) public onlyOwner {
        for (uint8 i = 0; i < _externalAddresses.length; i++) {
            require(_externalAddresses[i] != address(0), 'Zero addresses are prohibited in parameters');
            externalAddresses[i] = _externalAddresses[i];
        }
    }


    function setInitial(address payable[5] memory _initialAddresses) public onlyOwner {
        for (uint8 i = 0; i < _initialAddresses.length; i++) {
            require(_initialAddresses[i] != address(0), 'Zero addresses are prohibited in parameters');
            require(userId[_initialAddresses[i]]==0 , "User already exists" );
            User memory user = User({
                                        wallet: _initialAddresses[i],
                                        row: 2,
                                        col: i + 1,
                                        refId: 1,
                                        refCount: 0,
                                        refBonus: 0,
                                        last_row: 4,
                                        cycle: defaultCycle,
                                        reinvests: 0
                                    });
            users[i+2] = user;
            txCount[i+2][0] = [5, 0, 0];
            userId[_initialAddresses[i]] = i+2;
            globalPlaces[2][i+1] = i+2;
            emit Register(_initialAddresses[i], i+2, 2, i+1,1);
        }
        lastUserId = lastUserId + _initialAddresses.length;
        lastFreePlaceInRow[2] = 6;
    }


    function setFirstClones() public onlyOwner {
        for (uint8 i = 1; i <= 25 ; i++) {
            User memory user = User({
                                        wallet: address(0),
                                        row: 3,
                                        col: i,
                                        refId: 1,
                                        refCount: 0,
                                        refBonus: 0,
                                        last_row: 4,
                                        cycle: defaultCycle,
                                        reinvests: 0
                                    });
            users[i+6] = user;
            globalPlaces[3][i] = i+6;
            clones[i+6] = true;
            emit Register(address(0), i+6, 3, i, 1);
        }
        lastFreePlaceInRow[3] = 26;
        lastUserId = 31;
        totalClones = 25;
    }


    function setCreator(address payable _newCreator) public onlyOwner {
        require (_newCreator != address(0), "Zero address prohibited.");
	    _creator = _newCreator;
    }

    function setWithdrawal(address payable _newWithdrawal) public onlyOwner {
        require (_newWithdrawal != address(0), "Zero address prohibited.");
        _clnWithdraw = _newWithdrawal;
    }


    // Просмотр базовой цены
    function getPrice() public view returns (uint256) {
        return price;
    }

    // Изменение базовой цены
    function setPrice(uint256 newPrice) external {
        require(_owner == msg.sender || userId[msg.sender] == 4, "Ownable: caller is not the owner");
        require(newPrice > 0, "Price must not be zero");
        price = newPrice;
    }

    
    function getUserData(uint256 _userId) public view returns
    (
        uint256[9] memory
    )
    {
        uint256[9] memory userdata;
        userdata[0] = heldForNextCycle[_userId][users[_userId].reinvests][users[_userId].cycle-1];
        userdata[1] = balances[users[_userId].wallet];
        userdata[2] = txCount[_userId][users[_userId].reinvests][users[_userId].cycle-1];
        userdata[3] = users[_userId].refCount;
        userdata[4] = uint256(users[_userId].cycle);
        userdata[5] = earned[_userId][0];
        userdata[6] = earned[_userId][1];
        userdata[7] = earned[_userId][2];
        userdata[8] = users[_userId].refBonus;
        return (
            userdata
        );
    }

    function withdraw() external nonReentrant{
        require(balances[msg.sender] > 0, "Insufficient amount to withdraw.");
         //payable(msg.sender).transfer(balances[msg.sender]);
        // emit Withdraw(userId[msg.sender], balances[msg.sender]);
        balances[msg.sender] = 0;
        withdrawToId(userId[msg.sender], balances[msg.sender]);
        
    }


    function showPartnersByLevel(uint256 _userId) public view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256[5] memory partners;
        uint256 userCycle = users[_userId].cycle;
        uint256 userReinvests = users[_userId].reinvests;
        uint256 id;
        uint256 start;
        uint256 end;
        uint256 row = users[_userId].row;
        uint256 col = users[_userId].col;
        for (uint256 i = row + 1; i<=row +5; i++) {
            id = 0;
            start = (col - 1) * 5**(i - row );
            end = start +  5 ** (i - row);
            start = start + 1;

            for (uint256 j=start; j<=end; j++) {
                if (globalPlaces[i][j] > 0 && userCycle == users[globalPlaces[i][j]].cycle && userReinvests == users[globalPlaces[i][j]].reinvests) {
                    id += 1;
                }
            }
            partners[i - row - 1] = id;
        }

        return (partners[0],partners[1],partners[2],partners[3],partners[4]);

    }


    function getMatrix(uint256 _userId) public view returns (uint256[3905] memory) {
        uint256[3905] memory partners;
        uint256 userCycle = users[_userId].cycle;
        uint256 userReinvests = users[_userId].reinvests;
        uint256 count = 0;
        uint256 start;
        uint256 end;
        uint256 row = users[_userId].row;
        uint256 col = users[_userId].col;
        for (uint256 i = row + 1; i<=row + 5; i++) {
            start = (col - 1) * 5** (i- row);
            end = start + 5** (i -row);
            start = start + 1;
            for (uint256 j=start; j<=end; j++) {
                if (globalPlaces[i][j] > 0 && userCycle == users[globalPlaces[i][j]].cycle && userReinvests == users[globalPlaces[i][j]].reinvests) {
                    partners[count] = globalPlaces[i][j];
                } else {
                    partners[count] = 0;
                }
                count +=1 ;
            }
        }
        return partners;

    }


    function findFreePlace(uint256 _refId) public returns(uint256, uint256, uint256) {
        uint256 start;
        uint256 end;
        for (uint256 i = users[_refId].last_row; i<=MAX_ROW; i++) {
            start = (users[_refId].col - 1) * (5**(i - (users[_refId].row)));
            end = start + (5**(i - users[_refId].row));
            start = start + 1;
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
                        return (i,j, j + 1);
                    }
                }
            }
        }

        return (0, 0, 0);
    }


    function _register(uint256 _refId) external payable nonReentrant {
        require (msg.value == price, "Insufficient amount of ETH to participate");
        require (msg.sender != address(0), "Zero address prohibited.");
        
        require(userId[msg.sender] == 0, "User already registered");
        require(_refId > 0 && _refId < uint256(int256(-1)), "Invalid referral ID");
        require(users[_refId].wallet != address(0), "Invalid referral ID");
        require(!clones[_refId], "Invalid referral ID");
        require(lastUserId < uint256(int256(-1)), "No more registrations allowed");
        require(lastPaymentId < uint256(int256(-1)), "No more registrations allowed");
        (uint256 userRow, uint256 userCol, uint256 newRowLastPlace) = findFreePlace(_refId);
        require(userRow != 0 && userCol !=0, "No free places left in global matrix");
        lastUserId += 1;

        User memory user = User({
                                    wallet: msg.sender,
                                    row: userRow,
                                    col: userCol,
                                    refId: _refId,
                                    refCount: 0,
                                    refBonus: 0,
                                    last_row: userRow + 1,
                                    cycle: 1,
                                    reinvests: 0
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
        emit Register(msg.sender, lastUserId, userRow, userCol, _refId);
        processUplines(lastUserId, price);
        users[_refId].refCount += 1;
    }


    function findUplineCol(uint256 col) public pure returns(uint256) {
        return uint256( (col - 1)/ 5 +1);
    }

    function findUplineByCol(uint256 _userId)internal view returns(uint256[5] memory){
        uint256[5] memory uplines;
        uint8 counter = 0;
        uint256 _row = users[_userId].row;
        uint256 _col  = users[_userId].col;
        while (_row > 1 && counter <= 4) {
            _col = findUplineCol(_col);
            uplines[counter] = globalPlaces[_row - 1][_col];
            counter++;
            _row--;
        }
        return uplines;
    }
    
    function getUplines(uint256 _userId) public view returns (uint256[5] memory) {
        uint256[5] memory uplines;
        /*uint8 counter = 0;
        uint256 _row = users[_userId].row;
        uint256 _col  = users[_userId].col;
        while (_row > 1 && counter <= 4) {
            _col = findUplineCol(_col);
            uplines[counter] = globalPlaces[_row - 1][_col];
            counter++;
            _row--;
        }*/
        //remove dublicate 
        uplines = findUplineByCol(_userId);
        return (uplines);
    }


    function processUplines(uint256 _userId, uint256 _amount) internal {
        uint256[5] memory uplines;
        /*uint8 counter = 0;
        uint256 _row = users[_userId].row;
        uint256 _col  = users[_userId].col;
        while (_row > 1 && counter <= 4) {
            _col = findUplineCol(_col);
            uplines[counter] = globalPlaces[_row - 1][_col];
            counter++;
            _row--;
        }*/
        //remove dublicate 
        uplines = findUplineByCol(_userId);
        emit UplinesFound(uplines[0], uplines[1], uplines[2], uplines[3], uplines[4]);
        uint8 percentage;
        uint256 toPay = _amount;
        for (uint8 i = 0; i < 4; i++) {
            percentage = levelPercentage[i];
            if (users[_userId].cycle == 1 && i == 0) {
                percentage -= 10;
                processRefBonus(_amount/10, users[_userId].refId);
                toPay = toPay - _amount/10;
            }

            if (uplines[i+1] > 0) {
                makePayment(uplines[i], _amount * percentage / 100, _userId);
                toPay = toPay - _amount * percentage/100;
            } else {
                for (uint8 x = i+1; x < uplines.length; x++) {
                    percentage += levelPercentage[x];
                }
                makePayment(uplines[i], _amount * percentage/100, _userId);
                toPay = toPay - _amount * percentage/100;
                break;
                }
        }

        if (toPay > 0 && uplines[4] != 0) {
            makePayment(uplines[4], toPay, _userId);
        }

    }
    
    function distribute(uint256 _refId, uint256 amount) internal {
        if (_refId == 1) {
                id1Distribute(amount);
            } else if (_refId == 6) {
                processID6Payment(amount);
            } else if (_refId > 1 && _refId < 6) {
                balances[users[_refId].wallet] = balances[users[_refId].wallet] + amount;
            } else {
                transferToId(_refId, amount); 
            }
    }


    function makePayment(uint256 _refId, uint256 amount, uint256 _userId) internal {
        uint8 userCycle = users[_userId].cycle;
        uint256 userReinvests = users[_userId].reinvests;
        uint256 userRow = users[_userId].row;
        uint256 refRow = users[_refId].row;
        uint256 userCol = users[_userId].col;
        uint256 refCol = users[_refId].col;

        if (users[_refId].cycle == userCycle && users[_refId].reinvests == userReinvests && txCount[_refId][userReinvests][userCycle-1] == 3904) {
            emit Upgrade(_refId);
        }

        txCount[_refId][userReinvests][userCycle-1] = txCount[_refId][userReinvests][userCycle-1] + 1;

        if (userCycle < 3 && userRow - refRow == 5) {
            heldForNextCycle[_refId][userReinvests][userCycle-1] =
            heldForNextCycle[_refId][userReinvests][userCycle-1] + amount/2;
            emit Held(_refId, amount/2);
            amount = amount - amount/2;

        } else if (userCycle == 3 && userCol == refCol * 5 ** 5 && userRow - refRow == 5) {
            heldForNextCycle[_refId][userReinvests][userCycle-1] =
            heldForNextCycle[_refId][userReinvests][userCycle-1] + price;
            amount = amount - price;
            emit Held(_refId, price);

        }

        if (users[_refId].cycle == userCycle && users[_refId].reinvests == userReinvests && amount > 0) {
            if (clones[_refId]) {
                processClone(amount);
            } else /* if (_refId == 1) {
                id1Distribute(amount);
            } else if (_refId == 6) {
                processID6Payment(amount);
            } else if (_refId > 1 && _refId < 6) {
                balances[users[_refId].wallet] = balances[users[_refId].wallet] + amount;
            } else {
                //payable(users[_refId].wallet).transfer(amount);
                //emit Transfer(_refId, amount);
                transferToId(_refId, amount); 
            }*/
            //remove dublicate 
            distribute(_refId, amount);
            
            earned[_refId][userCycle-1] = earned[_refId][userCycle-1] + amount;
            totalPayout = totalPayout + amount;
            lastPaymentId += 1;
            emit PaymentToUpline(lastPaymentId, _refId, amount);
        } else {
            userLockedRev[_refId][userReinvests][userCycle-1] = userLockedRev[_refId][userReinvests][userCycle-1] + amount;
            emit Locked(_refId, userReinvests, userCycle, amount);
        }

    }

    function transferToId(uint256 _refId, uint256 amount) internal {
        (bool sent, ) = payable(users[_refId].wallet).call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Transfer(_refId, amount);
    }
    function transferToAddr(address addr, uint256 amount) internal {
        (bool sent, ) = payable(addr).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawToId(uint256 _refId, uint256 amount) internal {
        (bool sent, ) = payable(users[_refId].wallet).call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Withdraw(_refId, amount);
    }
    
    function processID6Payment(uint256 amount) internal {
        uint256 toExternal = amount * 22/100;
        balances[users[6].wallet] = balances[users[6].wallet] + amount- toExternal/3;
        
        for (uint8 x = 0; x < externalAddresses.length;x++) {
            //externalAddresses[x].transfer(toExternal);
            transferToAddr(externalAddresses[x], toExternal);
        }
        
    }


    function processRefBonus(uint256 amount, uint256 _userId) internal {
        users[_userId].refBonus = users[_userId].refBonus + amount;
        totalPayout = totalPayout + amount;
        
        /* if (_userId == 1) {
            id1Distribute(amount);
        } else if (_userId == 6) {
            processID6Payment(amount);
        } else if (_userId > 1 && _userId < 6) {
            balances[users[_userId].wallet] = balances[users[_userId].wallet] + amount;
        } else {
            //payable(users[_userId].wallet).transfer(amount);
            //emit Transfer(_userId, amount);
            transferToId(_userId, amount);
        }*/
        distribute(_userId, amount);
        emit RefBonusSent(_userId, amount);

    }


    function id1Distribute(uint256 amount) internal {
        uint256 percentage1 = amount/5;
        uint256 percentage2 = amount/10;
        balances[users[2].wallet] = balances[users[2].wallet] + percentage1;
        balances[users[3].wallet] = balances[users[3].wallet] + percentage1;
        balances[users[4].wallet] = balances[users[4].wallet] + percentage2;
        balances[users[5].wallet] = balances[users[5].wallet] + percentage2;
        processID6Payment(percentage2);
        balances[users[1].wallet] = balances[users[1].wallet] + amount - percentage1*2 - percentage2*3 ;
    }


    function _upgrade(uint256 _userId) external nonReentrant {
        require(msg.sender == _creator, "You're not authorized to call this function");
        uint8 userCycle = users[_userId].cycle;
        uint256 userReinvests = users[_userId].reinvests;
        require(txCount[_userId][userReinvests][userCycle-1] == 3905, "User doesn't have 3905 partners to be upgraded");
        if (userCycle < 3) {
            users[_userId].cycle += 1;
            emit NewCycle(_userId, users[_userId].cycle);
        } else {
            users[_userId].cycle = 1;
            users[_userId].reinvests += 1;
            emit Reinvest(_userId, users[_userId].reinvests);
        }
        processUplines(_userId, heldForNextCycle[_userId][userReinvests][userCycle-1]);
        heldForNextCycle[_userId][userReinvests][userCycle-1] = 0;
        uint256 locked = userLockedRev[_userId][users[_userId].reinvests][userCycle-1];
        if (locked > 0) {
            if (clones[_userId]) {
                processClone(locked);
            } else if (_userId == 1) {
                id1Distribute(locked);
            } else if (_userId == 6) {
                processID6Payment(locked);
            } else if (_userId > 1 && _userId < 6) {
                balances[users[_userId].wallet] = balances[users[_userId].wallet] + locked;
            } else {
                //payable(users[_userId].wallet).transfer(locked);
                //emit Transfer(_userId, locked);
                transferToId(_userId, locked);
            }
            userLockedRev[_userId][users[_userId].reinvests][userCycle-1] = 0;
        }

    }

    function processClone(uint256 amount) internal {
        if (amount > price) {
            //_clnWithdraw.transfer(amount - price);
            transferToAddr(_clnWithdraw, amount - price);
            amount = price;
        }
        //_creator.transfer(amount);
        transferToAddr(_creator, amount);
    }


    function createCln() public payable  {
        require(msg.value == price, "Insufficient amount to create clone");
        require(msg.sender == _creator, "Invalid caller address");
        require(lastUserId > 156);
        require(lastUserId < uint256(int256(-1)), "No more registrations allowed");
        (uint256 userRow, uint256 userCol, uint256 newRowLastPlace) = findFreePlace(1);
        require(userRow != 0 && userCol !=0, "No free places left in global matrix");
        lastUserId += 1;
        User memory user = User({
                                wallet: address(0),
                                row: userRow,
                                col: userCol,
                                refId: 1,
                                refCount: 0,
                                refBonus: 0,
                                last_row: userRow + 1,
                                cycle: 1,
                                reinvests: 0
                            });
        users[lastUserId] = user;
        clones[lastUserId] = true;
        globalPlaces[userRow][userCol] = lastUserId;
        if (users[1].last_row < userRow) {
            users[1].last_row = userRow;
        }
        if (newRowLastPlace > lastFreePlaceInRow[userRow]) {
            lastFreePlaceInRow[userRow] = newRowLastPlace;
            emit _NewRowLastPlace(userRow, newRowLastPlace);
        }
        emit Clone(lastUserId, userRow, userCol);
        totalClones += 1;
        processUplines(lastUserId, price);
    }

}