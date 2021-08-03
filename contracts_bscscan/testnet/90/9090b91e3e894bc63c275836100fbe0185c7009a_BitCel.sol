/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity 0.5.17;
interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  
  function mint(address account, uint256 value) external;

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
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract BitCel {
    // Contract lock status
    bool public lockStatus;
    IBEP20 public token;
      // Token value for free token
    uint public tokenValue = 10e18;
        // Token contract status
    bool public tokenStatus;
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint totalEarned;
        mapping(uint8 => bool) activeB3Levels;
        mapping(uint8 => bool) activeB4Levels;
        mapping(uint8 => mapping( uint8 => uint)) levelEarned;
        mapping(uint8 => B3) B3Matrix;
        mapping(uint8 => B4) B4Matrix;
    }
    
    struct B3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct B4 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 12;
    mapping(address => User) public users;
    mapping(uint => address) public userIds;


    uint public lastUserId = 2;
    uint public totalContractEarn;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedBNBReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraBNBDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
        // Add token event
    event AddToken(address indexed from,uint amount,uint time);
    
    constructor(address ownerAddress,address tokenaddress) public {
        levelPrice[1] = 0.025 *1e18;
        levelPrice[2] = 0.05 *1e18;
        levelPrice[3] = 0.1*1e18;
        levelPrice[4] = 0.2*1e18;
        levelPrice[5] = 0.4*1e18;
        levelPrice[6] = 0.6*1e18;
        levelPrice[7] = 1*1e18;
        levelPrice[8] = 2*1e18;
        levelPrice[9] = 3*1e18;
        levelPrice[10]= 4*1e18;
        levelPrice[11]= 5*1e18;
        levelPrice[12]= 10*1e18;
        owner = ownerAddress;
        token = IBEP20(tokenaddress);
          User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            totalEarned:0
        });
        
        users[ownerAddress] = user;
        userIds[1] = ownerAddress;
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeB3Levels[i] = true;
            users[ownerAddress].activeB4Levels[i] = true;
        }
       
        tokenStatus = true;
      
    }
     modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }   
        modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }
    function() external payable isLock {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable isLock {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable isLock {
        require(users[msg.sender].id != 0, "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeB3Levels[level], "level already activated");

            if (users[msg.sender].B3Matrix[level-1].blocked) {
                users[msg.sender].B3Matrix[level-1].blocked = false;
            }
    
            address freeB3Referrer = findFreeB3Referrer(msg.sender, level);
            users[msg.sender].B3Matrix[level].currentReferrer = freeB3Referrer;
            users[msg.sender].activeB3Levels[level] = true;
            updateB3Referrer(msg.sender, freeB3Referrer, level);
            
            emit Upgrade(msg.sender, freeB3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeB4Levels[level], "level already activated"); 

            if (users[msg.sender].B4Matrix[level-1].blocked) {
                users[msg.sender].B4Matrix[level-1].blocked = false;
            }

            address freeB4Referrer = findFreeB4Referrer(msg.sender, level);
            
            users[msg.sender].activeB4Levels[level] = true;
            updateB4Referrer(msg.sender, freeB4Referrer, level);
            
            emit Upgrade(msg.sender, freeB4Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
       require(msg.value == 0.05 *1e18, "registration cost 0.05");
        require(users[userAddress].id == 0, "user exists");
        require(users[referrerAddress].id != 0, "referrer not exists");
        
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
            User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            totalEarned:0
        });
        
        users[userAddress] = user;
        userIds[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeB3Levels[1] = true; 
        users[userAddress].activeB4Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeB3Referrer = findFreeB3Referrer(userAddress, 1);
        users[userAddress].B3Matrix[1].currentReferrer = freeB3Referrer;
        updateB3Referrer(userAddress, freeB3Referrer, 1);

        updateB4Referrer(userAddress, findFreeB4Referrer(userAddress, 1), 1);

         if (tokenStatus == true) {
            token.mint(msg.sender, tokenValue);
        }
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateB3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].B3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].B3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].B3Matrix[level].referrals.length));
            return sendBNBDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].B3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeB3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].B3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeB3Referrer(referrerAddress, level);
            if (users[referrerAddress].B3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].B3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].B3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateB3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendBNBDividends(owner, userAddress, 1, level);
            users[owner].B3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateB4Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeB4Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].B4Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].B4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].B4Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].B4Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendBNBDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].B4Matrix[level].currentReferrer;            
            users[ref].B4Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].B4Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].B4Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].B4Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].B4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].B4Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].B4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].B4Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].B4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateB4ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].B4Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].B4Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].B4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].B4Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].B4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].B4Matrix[level].closedPart)) {

                updateB4(userAddress, referrerAddress, level, true);
                return updateB4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].B4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].B4Matrix[level].closedPart) {
                updateB4(userAddress, referrerAddress, level, true);
                return updateB4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateB4(userAddress, referrerAddress, level, false);
                return updateB4ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].B4Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateB4(userAddress, referrerAddress, level, false);
            return updateB4ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].B4Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateB4(userAddress, referrerAddress, level, true);
            return updateB4ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].B4Matrix[level].firstLevelReferrals[0]].B4Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].B4Matrix[level].firstLevelReferrals[1]].B4Matrix[level].firstLevelReferrals.length) {
            updateB4(userAddress, referrerAddress, level, false);
        } else {
            updateB4(userAddress, referrerAddress, level, true);
        }
        
        updateB4ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateB4(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].B4Matrix[level].firstLevelReferrals[0]].B4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].B4Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].B4Matrix[level].firstLevelReferrals[0]].B4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].B4Matrix[level].firstLevelReferrals[0]].B4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].B4Matrix[level].currentReferrer = users[referrerAddress].B4Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].B4Matrix[level].firstLevelReferrals[1]].B4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].B4Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].B4Matrix[level].firstLevelReferrals[1]].B4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].B4Matrix[level].firstLevelReferrals[1]].B4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].B4Matrix[level].currentReferrer = users[referrerAddress].B4Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateB4ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].B4Matrix[level].secondLevelReferrals.length < 4) {
            return sendBNBDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory B4data = users[users[referrerAddress].B4Matrix[level].currentReferrer].B4Matrix[level].firstLevelReferrals;
        
        if (B4data.length == 2) {
            if (B4data[0] == referrerAddress ||
                B4data[1] == referrerAddress) {
                users[users[referrerAddress].B4Matrix[level].currentReferrer].B4Matrix[level].closedPart = referrerAddress;
            } else if (B4data.length == 1) {
                if (B4data[0] == referrerAddress) {
                    users[users[referrerAddress].B4Matrix[level].currentReferrer].B4Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].B4Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].B4Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].B4Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeB4Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].B4Matrix[level].blocked = true;
        }

        users[referrerAddress].B4Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeB4Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateB4Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendBNBDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeB3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeB3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeB4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeB4Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveB3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeB3Levels[level];
    }

    function usersActiveB4Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeB4Levels[level];
    }

    function usersB3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory,uint,bool) {
        return (users[userAddress].B3Matrix[level].currentReferrer,
                users[userAddress].B3Matrix[level].referrals,
                users[userAddress].B3Matrix[level].reinvestCount,
                users[userAddress].B3Matrix[level].blocked);
    }

    function usersB4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory,uint ,bool, address) {
        return (users[userAddress].B4Matrix[level].currentReferrer,
                users[userAddress].B4Matrix[level].firstLevelReferrals,
                users[userAddress].B4Matrix[level].secondLevelReferrals,
                users[userAddress].B4Matrix[level].reinvestCount,
                users[userAddress].B4Matrix[level].blocked,
                users[userAddress].B4Matrix[level].closedPart);
    }
    function userLevelEarnings( address _user, uint8 _matrix, uint8 _level)public view returns(uint){
        return users[_user].levelEarned[_matrix][_level];
    }


    function findBNBReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].B3Matrix[level].blocked) {
                    emit MissedBNBReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].B3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].B4Matrix[level].blocked) {
                    emit MissedBNBReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].B4Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }
    function sendBNBDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findBNBReceiver(userAddress, _from, matrix, level);

        require(address(uint160(receiver)).send(levelPrice[level]));
        users[receiver].totalEarned += levelPrice[level];
        users[receiver].levelEarned[matrix][level] +=levelPrice[level];
        totalContractEarn += levelPrice[level];
        
        if (isExtraDividends) {
            emit SentExtraBNBDividends(_from, receiver, matrix, level);
        }
    }
    function updateTokenValue(uint _value)public onlyOwner{
        tokenValue = _value;
    }
    
    function addTokens(uint _amount)public onlyOwner{
        token.transferFrom(owner, address(this), _amount);
       
        emit AddToken(owner,_amount,block.timestamp);
    }
      
    function tokenState(bool _status)public onlyOwner{
        tokenStatus = _status;
    }
    
    function tokenBalance(address user) public view returns(uint tokenBal){
        return token.balanceOf(user);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
       function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
       function failSafe(address payable _toUser, uint _amount) public onlyOwner returns(bool) {
        require(_toUser != address(0), "Binanceclub: Invalid Address");
        require(address(this).balance >= _amount, "Binanceclub: Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
}