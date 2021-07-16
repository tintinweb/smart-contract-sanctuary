//SourceUnit: Lionshare.sol

/**
 *Submitted for verification at Etherscan.io on 2020-07-14 - ETHEREUM
 *Submitted for verification at Tronscan.org on 2020-09-28 - TRON
*/

// SPDX-License-Identifier: BSD-3-Clause

/** 
*                                                                                                                                  
*       ##### /                                                             #######      /                                         
*    ######  /          #                                                 /       ###  #/                                          
*   /#   /  /          ###                                               /         ##  ##                                          
*  /    /  /            #                                                ##        #   ##                                          
*      /  /                                                               ###          ##                                          
*     ## ##           ###        /###    ###  /###         /###          ## ###        ##  /##      /###    ###  /###       /##    
*     ## ##            ###      / ###  /  ###/ #### /     / #### /        ### ###      ## / ###    / ###  /  ###/ #### /   / ###   
*     ## ##             ##     /   ###/    ##   ###/     ##  ###/           ### ###    ##/   ###  /   ###/    ##   ###/   /   ###  
*     ## ##             ##    ##    ##     ##    ##   k ####                  ### /##  ##     ## ##    ##     ##         ##    ### 
*     ## ##             ##    ##    ##     ##    ##   a   ###                   #/ /## ##     ## ##    ##     ##         ########  
*     #  ##             ##    ##    ##     ##    ##   i     ###                  #/ ## ##     ## ##    ##     ##         #######   
*        /              ##    ##    ##     ##    ##   z       ###                 # /  ##     ## ##    ##     ##         ##        
*    /##/           /   ##    ##    ##     ##    ##   e  /###  ##       /##        /   ##     ## ##    /#     ##         ####    / 
*   /  ############/    ### /  ######      ###   ###  n / #### /       /  ########/    ##     ##  ####/ ##    ###         ######/  
*  /     #########       ##/    ####        ###   ### -    ###/       /     #####       ##    ##   ###   ##    ###         #####   
*  #                                                  w               |                       /                                    
*   ##                                                e                \)                    /                                     
*                                                     b                                     /                                      
*                                                                                          /                                       
*
*
* Lion's Share is the very first true follow-me matrix smart contract ever created. 
* https://www.lionsshare.io
* Get your share, join today!
*/

pragma solidity 0.5.10;

contract Lionshare {
    

    //User details
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeL1Levels;
        mapping(uint8 => bool) activeL2Levels;
        
        mapping(uint8 => L1) l1Matrix;
        mapping(uint8 => L2) l2Matrix;

        uint256 dividendReceived;
    }
    
    // L1 matrix
    struct L1 {
        address Senior;
        address[] Juniors;
        bool blocked;
        uint reinvestCount;
    }
    

    // L2 matrix
    struct L2 {
        address Senior;
        address[] firstLevelJuniors;
        address[] secondLevelJuniors;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 16;
    
    mapping(address => User) public users;
    mapping(uint => address) public userIds; 

    uint public lastUserId = 4;
    address public owner;
    
    //declare prices for each levels
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed Senior, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress, address ID2, address ID3) public {
        //sets first level price
        levelPrice[1] = 100 trx;

        //sets all other levels price by doubling first level prive
        levelPrice[2] = 200 trx;
        levelPrice[3] = 400 trx;
        levelPrice[4] = 600 trx;
        levelPrice[5] = 1000 trx;
        levelPrice[6] = 1500 trx;
        levelPrice[7] = 2000 trx;
        levelPrice[8] = 3000 trx;
        levelPrice[9] = 4000 trx;
        levelPrice[10] = 5000 trx;
        levelPrice[11] = 6000 trx;
        levelPrice[12] = 7000 trx;
        levelPrice[13] = 8000 trx;
        levelPrice[14] = 10000 trx;
        levelPrice[15] = 15000 trx;
        levelPrice[16] = 25000 trx;
        

        //sets owner address 
        owner = ownerAddress;
        

        //Declare first user from struct
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: 2,
            dividendReceived:0
        });
        
        User memory two = User({
            id: 2,
            referrer: ownerAddress,
            partnersCount: uint(0),
            dividendReceived:0
        });
        
        User memory three = User({
            id: 3,
            referrer: ownerAddress,
            partnersCount: uint(0),
            dividendReceived:0
        });
        
        // add first user to users mapping (address to User struct mapping)
        users[ownerAddress] = user;
        users[ID2] = two;
        users[ID3] = three;

        
        
        users[ownerAddress].l1Matrix[1].Juniors.push(ID2);
        users[ownerAddress].l1Matrix[1].Juniors.push(ID3);
        
        users[ownerAddress].l2Matrix[1].firstLevelJuniors.push(ID2);
        users[ownerAddress].l2Matrix[1].firstLevelJuniors.push(ID3);
        
        users[ID2].l1Matrix[1].Senior = ownerAddress;
        users[ID3].l1Matrix[1].Senior = ownerAddress;

        // activeX3Levels is mapping in Users struct (integer to bool)  users is mapping (address to User struct)
        // activate all the levels for x3 and x4 for first user
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeL1Levels[i] = true;
            users[ownerAddress].activeL2Levels[i] = true;
            
            users[ID2].activeL1Levels[i] = true;
            users[ID2].activeL2Levels[i] = true;
            
            users[ID3].activeL1Levels[i] = true;
            users[ID3].activeL2Levels[i] = true;
        }
        
        // userIds is mapping from integer to address
        userIds[1] = ownerAddress;
        userIds[2] = ID2;
        userIds[3] = ID3;
    }


    
    
    function registerFirsttime() public payable returns(bool) {
        registration(msg.sender, owner);
        return true;
    }


    //registration with referral address
    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    

    //buy level function payament
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        //isUserExists is function at line 407 checks if user exists
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        // levelPrice is mapping from integer(level) to integer(price) at line 51
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeL1Levels[level], "level already activated");

            if (users[msg.sender].l1Matrix[level-1].blocked) {
                users[msg.sender].l1Matrix[level-1].blocked = false;
            }
    
            address l1referrer = findl1referrer(msg.sender, level);
            //X3 matrix is mapping from integer to X3 struct
            users[msg.sender].l1Matrix[level].Senior = l1referrer;
            users[msg.sender].activeL1Levels[level] = true;
            updateL1referrer(msg.sender, l1referrer, level);
            
            emit Upgrade(msg.sender, l1referrer, 1, level);

        } else {
            require(!users[msg.sender].activeL2Levels[level], "level already activated"); 

            if (users[msg.sender].l2Matrix[level-1].blocked) {
                users[msg.sender].l2Matrix[level-1].blocked = false;
            }

            address l2referrer = findl2referrer(msg.sender, level);
            
            users[msg.sender].activeL2Levels[level] = true;
            updateL2referrer(msg.sender, l2referrer, level);
            
            emit Upgrade(msg.sender, l2referrer, 2, level);
        }
    }

    function findl1referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            // activeL1Levels is mapping integer to bool
            // if referrer is already there for User return referrer address
            if (users[users[userAddress].referrer].activeL1Levels[level]) {
                return users[userAddress].referrer;
            }
            
            // else set userAddress as referrer address in User struct
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findl2referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeL2Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveL1Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeL1Levels[level];
    }

    function usersActiveL2Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeL2Levels[level];
    }

    function usersL1Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint) {
        return (users[userAddress].l1Matrix[level].Senior,
                users[userAddress].l1Matrix[level].Juniors,
                users[userAddress].l1Matrix[level].blocked,
                users[userAddress].l1Matrix[level].reinvestCount);
    }

    function usersL2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, uint) {
        return (users[userAddress].l2Matrix[level].Senior,
                users[userAddress].l2Matrix[level].firstLevelJuniors,
                users[userAddress].l2Matrix[level].secondLevelJuniors,
                users[userAddress].l2Matrix[level].blocked,
                users[userAddress].l2Matrix[level].reinvestCount);
    }
    
    // checks if user exists from users mapping(address to User struct) and id property of User struct
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 200 trx, "registration cost 200 trx");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer does not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId, 
            referrer: referrerAddress,
            partnersCount: 0,
            dividendReceived:0
        });
        
        users[userAddress] = user;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeL1Levels[1] = true; 
        users[userAddress].activeL2Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address l1referrer = findl1referrer(userAddress, 1);
        users[userAddress].l1Matrix[1].Senior = l1referrer;
        updateL1referrer(userAddress, l1referrer, 1);

        updateL2referrer(userAddress, findl2referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    

    function updateL1referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].l1Matrix[level].Juniors.push(userAddress);

        if (users[referrerAddress].l1Matrix[level].Juniors.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].l1Matrix[level].Juniors.length));
            //sendETHDividends is function accepts arguments (useraddress, _from , matrix, level)
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].l1Matrix[level].Juniors = new address[](0);
        if (!users[referrerAddress].activeL1Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].l1Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findl1referrer(referrerAddress, level);
            if (users[referrerAddress].l1Matrix[level].Senior != freeReferrerAddress) {
                users[referrerAddress].l1Matrix[level].Senior = freeReferrerAddress;
            }
            
            users[referrerAddress].l1Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateL1referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].l1Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateL2referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeL2Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].l2Matrix[level].firstLevelJuniors.length < 2) {
            users[referrerAddress].l2Matrix[level].firstLevelJuniors.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].l2Matrix[level].firstLevelJuniors.length));
            
            //set current level
            users[userAddress].l2Matrix[level].Senior = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].l2Matrix[level].Senior;            
            users[ref].l2Matrix[level].secondLevelJuniors.push(userAddress); 
            
            uint len = users[ref].l2Matrix[level].firstLevelJuniors.length;
            
            if ((len == 2) && 
                (users[ref].l2Matrix[level].firstLevelJuniors[0] == referrerAddress) &&
                (users[ref].l2Matrix[level].firstLevelJuniors[1] == referrerAddress)) {
                if (users[referrerAddress].l2Matrix[level].firstLevelJuniors.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].l2Matrix[level].firstLevelJuniors[0] == referrerAddress) {
                if (users[referrerAddress].l2Matrix[level].firstLevelJuniors.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].l2Matrix[level].firstLevelJuniors[1] == referrerAddress) {
                if (users[referrerAddress].l2Matrix[level].firstLevelJuniors.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateL2referrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].l2Matrix[level].secondLevelJuniors.push(userAddress);

        if (users[referrerAddress].l2Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].l2Matrix[level].firstLevelJuniors[0] == 
                users[referrerAddress].l2Matrix[level].firstLevelJuniors[1]) &&
                (users[referrerAddress].l2Matrix[level].firstLevelJuniors[0] ==
                users[referrerAddress].l2Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateL2referrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].l2Matrix[level].firstLevelJuniors[0] == 
                users[referrerAddress].l2Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateL2referrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateL2referrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].l2Matrix[level].firstLevelJuniors[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateL2referrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].l2Matrix[level].firstLevelJuniors[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateL2referrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].l2Matrix[level].firstLevelJuniors[0]].l2Matrix[level].firstLevelJuniors.length <= 
            users[users[referrerAddress].l2Matrix[level].firstLevelJuniors[1]].l2Matrix[level].firstLevelJuniors.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateL2referrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].l2Matrix[level].firstLevelJuniors[0]].l2Matrix[level].firstLevelJuniors.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].l2Matrix[level].firstLevelJuniors[0], 2, level, uint8(users[users[referrerAddress].l2Matrix[level].firstLevelJuniors[0]].l2Matrix[level].firstLevelJuniors.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].l2Matrix[level].firstLevelJuniors[0]].l2Matrix[level].firstLevelJuniors.length));
            //set current level
            users[userAddress].l2Matrix[level].Senior = users[referrerAddress].l2Matrix[level].firstLevelJuniors[0];
        } else {
            users[users[referrerAddress].l2Matrix[level].firstLevelJuniors[1]].l2Matrix[level].firstLevelJuniors.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].l2Matrix[level].firstLevelJuniors[1], 2, level, uint8(users[users[referrerAddress].l2Matrix[level].firstLevelJuniors[1]].l2Matrix[level].firstLevelJuniors.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].l2Matrix[level].firstLevelJuniors[1]].l2Matrix[level].firstLevelJuniors.length));
            //set current level
            users[userAddress].l2Matrix[level].Senior = users[referrerAddress].l2Matrix[level].firstLevelJuniors[1];
        }
    }
    
    function updateL2referrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].l2Matrix[level].secondLevelJuniors.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].l2Matrix[level].Senior].l2Matrix[level].firstLevelJuniors;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].l2Matrix[level].Senior].l2Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].l2Matrix[level].Senior].l2Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].l2Matrix[level].firstLevelJuniors = new address[](0);
        users[referrerAddress].l2Matrix[level].secondLevelJuniors = new address[](0);
        users[referrerAddress].l2Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeL2Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].l2Matrix[level].blocked = true;
        }

        users[referrerAddress].l2Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findl2referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateL2referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].l1Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].l1Matrix[level].Senior;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].l2Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].l2Matrix[level].Senior;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            users[receiver].dividendReceived = users[receiver].dividendReceived + address(this).balance;
            return address(uint160(receiver)).transfer(address(this).balance);
        }
        users[receiver].dividendReceived = users[receiver].dividendReceived + levelPrice[level];
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
}