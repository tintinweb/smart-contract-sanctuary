//SourceUnit: IERC20.sol

pragma solidity >=0.5.4 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: ITreasury.sol

pragma solidity >=0.5.4 <0.8.0;

interface ITreasury {

    function accumulationOf(address userAddress) external view returns (uint);

    function balanceOf(address userAddress) external view returns (uint);

    function referrerOf(address userAddress) external view returns (address);

    function childsOf(address userAddress) external view returns (address[] memory);

    function levelOf(address userAddress) external view returns (uint);

    function levelSteps() external view returns (uint[] memory);

    function selfCommisions() external view returns (uint[] memory);

    function refCommisions() external view returns (uint[] memory);

    function blockTimeDuration() external view returns (uint);
    
}

//SourceUnit: Treasury.sol

pragma solidity >=0.5.4 <0.8.0;

import "./IERC20.sol";
import "./ITreasury.sol";

contract Treasury {
    uint private _totalHolders;
    address private owner;
    
    ITreasury private oldTreasury = ITreasury(0x411611872cfbf70e61a626070108403db1ae204cd7);
    IERC20 private usdt = IERC20(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c);
    
    uint[] levelStep = [100000000000, 500000000000];
    uint[] selfCommision = [8, 10, 12];
    uint[] refCommision = [100, 50, 30, 10, 10];

    mapping (address => bool ) private holderExists;
    mapping (uint => address ) private holders;
    mapping (address => bool) private blockUser;
    mapping (address => User) private users;
    mapping (address => uint) private accumulation;
    mapping (uint256 => bool) private depositHash;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event UserDeposit(address indexed user, uint256 indexed hash, uint256 amount, uint indexed timestamp);
    event AutoWithdrawal(address indexed user, uint256 indexed hash, uint256 amount, uint interest);
    event ReferralBonus(address indexed fromAddress, address indexed toAddress, uint level, uint amount);
    event UserUpgradeLevel(address indexed user, uint indexed level);

    struct User { 
        TXRecord[] txs;
        address referrer;
        uint level;
    }
    
    struct TXRecord {
        uint256 hash;
        uint256 amount;
        uint timestamp;
    }

    constructor () public {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function accumulationOf(address userAddress) public view returns (uint) {
        return accumulation[userAddress] + oldTreasury.accumulationOf(userAddress);
    }

    function balanceOf(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        TXRecord[] memory txs = user.txs;
        uint sum = 0;
        for(uint i = 0; i<txs.length;i++) {
            TXRecord memory txr = txs[i];
            sum += txr.amount;
        }
        return sum + oldTreasury.balanceOf(userAddress);
    }

    function levelOf(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        if(user.level < 1)
            return 1;
        else
            return user.level;
    }

    function referrerOf(address userAddress) public view returns (address) {
        return oldTreasury.referrerOf(userAddress);
    }

    function childsOf(address userAddress) external view returns (address[] memory) {
        return oldTreasury.childsOf(userAddress);
    }

    function isBlocked(address userAddress) public view returns (bool) {
        return blockUser[userAddress];
    }
    
    function blockTimeDuration() external view returns (uint) {
        return oldTreasury.blockTimeDuration();
    } 

    function withdrawalCountdown(address userAddress) public view returns (uint) {
        uint countDown = 9999999999;
        if(!blockUser[userAddress]) {
            User storage user = users[userAddress];
            TXRecord[] storage txs = user.txs;
            for(uint j=0;j<txs.length;j++) {
                TXRecord storage utx = txs[j];
                if(block.timestamp - utx.timestamp >= oldTreasury.blockTimeDuration()) { 
                    return 0;
                } else {
                    uint remainTime = oldTreasury.blockTimeDuration() - (block.timestamp - utx.timestamp);
                    if(remainTime < countDown) {
                        countDown = remainTime;
                    }
                }
            }
        }
        return countDown;
    }

    function withdrawableUsers() external view returns (address[] memory) {
        uint n = 0;
        for(uint i=0;i<_totalHolders;i++) {
            address userAddress = holders[i];
            if(!blockUser[userAddress]) {
                User storage user = users[userAddress];
                TXRecord[] storage txs = user.txs;
                for(uint j=0;j<txs.length;j++) {
                    TXRecord storage utx = txs[j];
                    if(block.timestamp - utx.timestamp >= oldTreasury.blockTimeDuration()) {
                        n++;
                        break;
                    }
                }
            }
        }
        address[] memory withdrawableUserList = new address[](n);
        n = 0;
        for(uint i=0;i<_totalHolders;i++) {
            address userAddress = holders[i];
            if(!blockUser[userAddress]) {
                User storage user = users[userAddress];
                TXRecord[] storage txs = user.txs;
                for(uint j=0;j<txs.length;j++) {
                    TXRecord storage utx = txs[j];
                    if(block.timestamp - utx.timestamp >= oldTreasury.blockTimeDuration()) {
                        withdrawableUserList[n] = userAddress;
                        n++;
                        break;
                    }
                }
            }
        }
        return withdrawableUserList;
    }

    function getDepositsCount(address userAddress) public view returns (uint) {
        User memory user = users[userAddress];
        TXRecord[] memory txs = user.txs;
        return txs.length;
    }
    
    function getDepositAmount(address userAddress, uint index) public view returns (uint256) {
        User memory user = users[userAddress];
        TXRecord[] memory txs = user.txs;
        require(index < txs.length, "Index Outbound Of TXs Array"); 
        return txs[index].amount;
    }
    
    function getDepositTimestamp(address userAddress, uint index) public view returns (uint) {
        User memory user = users[userAddress];
        TXRecord[] memory txs = user.txs;
        require(index < txs.length, "Index Outbound Of TXs Array"); 
        return txs[index].timestamp;
    }

    ////////////////////////// Fee Function //////////////////////////////

    function deposit(address userAddress, uint256 hash, uint256 amount) public returns (bool) {
        require(msg.sender == owner, "Caller is not owner"); 
        require(depositHash[hash] != true, "Hash Already Deposit"); 
        emit UserDeposit(userAddress, hash, amount, block.timestamp); 
        checkUser(userAddress); 
        TXRecord memory txr = TXRecord(hash, amount , block.timestamp); 
        User storage user = users[userAddress]; 
        user.txs.push(txr); 
        depositHash[hash] = true;
        accumulation[userAddress] += amount; 
        checkUserLevelUp(userAddress); 
        address referrerAddress = user.referrer; 
        checkUserLevelUp(referrerAddress); 

        return true;
    }

    function urgentFix(address userAddress, uint256 hash, uint256 amount, uint timestamp) public returns (bool) {
        require(msg.sender == owner, "Caller is not owner"); 
        require(depositHash[hash] != true, "Hash Already Deposit"); 
        emit UserDeposit(userAddress, hash, amount, timestamp); 
        checkUser(userAddress); 
        TXRecord memory txr = TXRecord(hash, amount , timestamp); 
        User storage user = users[userAddress]; 
        user.txs.push(txr); 
        depositHash[hash] = true;
        accumulation[userAddress] += amount; 
        checkUserLevelUp(userAddress); 
        address referrerAddress = user.referrer; 
        checkUserLevelUp(referrerAddress); 

        return true;
    }

    function withdrawal(address userAddress) public returns (bool) {
        require(msg.sender == owner, "Caller is not owner"); 
        require(!blockUser[userAddress], "User has been blocked"); 
        User storage user = users[userAddress]; 
        TXRecord[] storage txs = user.txs; 
        for(uint j=0;j<txs.length;j++) { 
            TXRecord storage utx = txs[j]; 
            if(block.timestamp - utx.timestamp >= oldTreasury.blockTimeDuration()) { 
                uint commission = selfCommision[0];
                if (user.level == 2) {
                    commission = selfCommision[1];
                } else if (user.level == 3) {
                    commission = selfCommision[2];
                }
                uint afterCommission = utx.amount * commission / 1000; 
                uint totalWithdrawal = utx.amount + afterCommission; 
                require(totalWithdrawal <= usdt.balanceOf(address(this)), "Inventory shortage");
                emit AutoWithdrawal(userAddress, utx.hash, utx.amount, afterCommission); 
                txs[j] = txs[txs.length-1];
                txs.pop();
                usdt.transfer(userAddress, totalWithdrawal);
                address tmpAddr = userAddress; 
                for(uint k=1;k<=5;k++) { 
                    if(tmpAddr == address(0x4106A1A3C7CFFE121A3A6E3A23A8C9C642016B5A62)) {
                        break;
                    }
                    address refOfuser = oldTreasury.referrerOf(tmpAddr);
                    uint acc = oldTreasury.accumulationOf(refOfuser) + accumulation[refOfuser];
                    if(acc > 0) { 
                        uint cm2 = refCommision[4];
                        if(k == 1) {
                            cm2 = refCommision[0];
                        } else if(k == 2) {
                            cm2 = refCommision[1];
                        } else if(k == 3) {
                            cm2 = refCommision[2];
                        } else if(k == 4) {
                            cm2 = refCommision[3];
                        } else if(k == 5) {
                            cm2 = refCommision[4];
                        }
                        uint bonus = afterCommission * cm2 / 1000;
                        require(bonus <= usdt.balanceOf(address(this)), "Inventory shortage");
                        emit ReferralBonus(userAddress, refOfuser, k, bonus); 
                        usdt.transfer(refOfuser, bonus); 
                        tmpAddr = refOfuser;
                    } else {
                        break;
                    }
                }
                break; 
            }
        }
        return true;
    }

    function blockUserAddress(address blockAddress) public returns (bool) {
        require(msg.sender == owner, "Caller is not owner");
        blockUser[blockAddress] = true;
        return true;
    }
    
    function unblockUserAddress(address unblockAddress) public returns (bool) {
        require(msg.sender == owner, "Caller is not owner");
        blockUser[unblockAddress] = false;
        return true;
    }

    ////////////////////////// Private Function //////////////////////////////

    function checkUserLevelUp(address userAddress) private {
        User storage user = users[userAddress];
        uint sum = accumulation[userAddress] + oldTreasury.accumulationOf(userAddress); 
        address[] memory childList = oldTreasury.childsOf(userAddress); 
        for(uint i=0;i<childList.length;i++) { 
            address childAddress = childList[i]; 
            sum += accumulation[childAddress] + oldTreasury.accumulationOf(childAddress); 
        }
        
        if(sum >= levelStep[1] && user.level < 3) { 
            user.level = 3;
            emit UserUpgradeLevel(userAddress, 3);
        } else if(sum >= levelStep[0] && user.level < 2) {
            user.level = 2;
            emit UserUpgradeLevel(userAddress, 2);
        }
    }

    function checkUser(address userAddress) private {
        if(!holderExists[userAddress]) {
            holderExists[userAddress] = true;
            holders[_totalHolders] = userAddress;
            accumulation[userAddress] = 0;
            _totalHolders++;
        }
    }
}