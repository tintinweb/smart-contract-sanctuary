/**
 *Submitted for verification at Etherscan.io on 2020-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
 
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
   /**
    * @dev Throws if called by any account other than the owner.
    */ 
   modifier onlyOwner(){
        require(msg.sender == owner, 'Operation is for owner only');
        _;
    }
 
   /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */ 
   function transferOwnership(address newOwner) onlyOwner public{
        require(newOwner != address(0), 'Wrong new owner address');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title ITPLeader
 * @dev ITP entrance contract.
 */
contract ITPLeader is Ownable{

    struct User{
        uint32 id;
        uint32 level;
        address referrer;
    }

    struct Tree{
        uint64 parent;       // Id of parent tree node.
        uint64[] childs;     // Tree child node ids.
        address userAddress; // Node owner address.
    }

    struct Slot{
        bool isActive;       // Is slot activated (fully upgraded).
        uint toUpgrade;      // Amount of ether reserved to upgrade from first slot
        uint64[] treeIds;    // Ids of tree nodes in ascending order. Length - 1 is reinvest count.
    }
    
    // Prvious and current rate in cents.
    uint private previousRate;
    uint public currentRate;

    // Base users structure
    mapping(address => User) public users;
    // Getting address for internal user id
    mapping(uint32 => address) public addressById;
    uint32 private lastUserId;
    
    // Tree map is matrix => (level => (id => TreeNode))
    mapping(uint32 => mapping(uint32 => mapping(uint64 => Tree))) private tree;
    // Slot map is matrix => (level => (address => TreeNode))
    mapping(uint32 => mapping(uint32 => mapping(address => Slot))) private slots;
    uint64 public currentNode;

    // Maximum number of level
    uint32 public maxLevel;
    mapping(uint32 => uint32) public levelPriceUSDCent;

    address private rateAddress;
    address private topAddress;
    bytes32 private signPhrase;
    
    event NewRate(uint value, uint timestamp);
    event Register(address indexed userAddress, address indexed referrerAddress, uint32 userId);
    event Reinvest(address indexed userAddress, address indexed referrerAddress, uint32 matrix, uint32 level);
    event UnderUpgrade(address indexed userAddress, uint32 matrix, uint32 level);
    event Upgrade(address indexed userAddress, address indexed referrerAddress, uint32 matrix, uint32 level);
    event Transfer(address indexed from, address indexed to, uint amount, uint32 matrix, uint32 level);

    constructor(){
        owner = msg.sender;

        // Set constant level costs
        maxLevel = 14;
        uint32 price = 1250;
        for(uint32 i = 1; i <= maxLevel; i++){
            levelPriceUSDCent[i] = price;
            price = price * 2;
        }
    }

    /** 
     * @dev Convert cent price to wei by the given rate.
     * @param cents Price in USD cents.
     * @param rate rate used to convert.
     * @return An uint representing wei amount for supplied cent price.
     */
    function _toWeiPrice(uint cents, uint rate) private pure returns (uint){
        if(cents == 0 || rate == 0){
            return 0;
        }
        
        uint centswei = cents * 1 ether;
        require(cents == centswei / 1 ether);

        return centswei / rate;
    }

    /** 
     * @dev Convert cent price to wei using current rate.
     * @param priceCent Price in USD cents.
     * @return An uint representing wei amount for supplied cent price.
     */
    function toWeiPrice(uint priceCent) public view returns (uint){
        return _toWeiPrice(priceCent, currentRate);
    }

    /** 
     * @dev Check correspondence USD cent to wei price historically up to two rates ago.
     * @param priceCent Price in USD cents.
     * @param priceWei Price in Wei.
     * @return True if price corresponds to current or previouse wei cost.
     */
    function checkPrice(uint priceCent, uint priceWei) private view returns (bool){
        if(_toWeiPrice(priceCent, currentRate) == priceWei || _toWeiPrice(priceCent, previousRate) == priceWei){
            return true;
        }
        return false;
    }
  
    /** 
     * @dev Set new ETH to USD rate.
     * @param rate New rate value (1 ETH cost in cents).
     */
    function setRate(uint rate) public{
        require(msg.sender == rateAddress, 'Operation is not permitted');
        previousRate = currentRate;
        currentRate = rate;
        NewRate(rate, block.timestamp);
    }

    /** 
     * @dev Set the phrase required for the sign.
     * @param phrase The phrase itself.
     */
    function setSignPhrase(bytes32 phrase) onlyOwner public{
        signPhrase = phrase;
    }

    /** 
     * @dev Get user upline.
     * @param userAddress User address.
     * @return Array of upline addresses starting from referrer.
     */
    function getUpline(address userAddress) public view returns (address[]  memory){
        address[] memory upline = new address[](users[userAddress].level);
        
        uint32 i = 0;
        while(users[userAddress].id > 0){
            upline[i++] = users[userAddress].referrer;
            userAddress = users[userAddress].referrer;
        }

        return upline;
    }

    /** 
     * @dev Get user code to register in other blockchains.
     * @param userAddress User address.
     * @param signature Signed message by the user (ask to ITP how to obtain this message).
     * @return Hash that could be provided to other contracts.
     */
    function getCode(address userAddress, bytes memory signature) public view returns (bytes32){
        require(users[userAddress].id > 0, "User is not registered yet");
        
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(userAddress, users[userAddress].id, signPhrase))));
        require(recoverSigner(message, signature) == userAddress, "Wrong signature");

        return keccak256(abi.encodePacked(userAddress, users[userAddress].id, signPhrase));
    }

    /** 
     * @dev Get the message signer.
     * @param message Signed message.
     * @param signature Signature provided by the signer.
     * @return Signer address.
     */
    function recoverSigner(bytes32 message, bytes memory signature) private pure returns (address){
        require(signature.length == 65);
        
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly{
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return ecrecover(message, v, r, s);
    }

    /** 
     * @dev Init first node for each matrix and set to owner unlimited abilities. Could be called once. Owner can change parameters separately thereafter.
     * @param ownerAddress Address of person who is top referrer.
     */
    function init(address ownerAddress) onlyOwner public{
        require(lastUserId == 0, "Contract has already been initialized");
        
        topAddress = ownerAddress;

        uint32 _lastUserId = lastUserId + 1;
        users[ownerAddress].id = _lastUserId;
        users[ownerAddress].level = 1;
        addressById[_lastUserId] = ownerAddress;
        lastUserId = _lastUserId;

        // Init all matrix levels / top nodes with top address
        uint64 _currentNode = currentNode;
        for(uint32 i = 1; i <= maxLevel; i++){
            _currentNode ++;
            tree[3][i][_currentNode].userAddress = ownerAddress;
            slots[3][i][ownerAddress].isActive = true;
            slots[3][i][ownerAddress].treeIds.push(_currentNode);

            _currentNode ++;
            tree[6][i][_currentNode].userAddress = ownerAddress;
            slots[6][i][ownerAddress].isActive = true;
            slots[6][i][ownerAddress].treeIds.push(_currentNode);
        }
        currentNode = _currentNode;
    }

    /** 
     * @dev Change the address that receives fund from top account.
     * @param addr Top address that receives funds.
     */
    function setTopAddress(address addr) onlyOwner public{
        require(addr != address(0), "Top address cannot be null");
        topAddress = addr;
    }

    /** 
     * @dev Change the address that provide ETH to USD rates.
     * @param addr Allowed address.
     */
    function setRateAddress(address addr) onlyOwner public{
        require(addr != address(0), "Rate address cannot be null");
        rateAddress = addr;
    }

    /** 
     * @dev Default etrance method. Most registrations start here.
     */
    receive() external payable{
        if(msg.data.length == 0) {
            register(msg.sender, tree[3][1][1].userAddress);
        }else{
            register(msg.sender, bytesToAddress(msg.data));
        }
    }

    /** 
     * @dev Alternative user registration with certain referrer.
     * @param referrerAddress Address of user referrer.
     */
    function start(address referrerAddress) external payable{
        register(msg.sender, referrerAddress);
    }

    /** 
     * @dev Register user in both matrixes and referral contract as well.
     * @param userAddress Address of the user.
     * @param referrerAddress Address of user referrer.
     */
    function register(address userAddress, address referrerAddress) private{
        // Check user and partner and register them if required
        require(tx.origin == msg.sender, "Address cannot be a contract");
        require(users[userAddress].id == 0, "User has already activated");
        require(users[referrerAddress].id > 0, "Referrer partner has not activated yet");

        // Check provided cost for two matrixes for first level
        uint requiredCost = levelPriceUSDCent[1] * 2;
        bool isCostValid = checkPrice(requiredCost, msg.value);
        require(isCostValid && msg.value > 0, "Invalid or out to date level cost");

        // Store user to referral tree
        uint32 userId = lastUserId + 1;
        users[userAddress].id = userId;
        users[userAddress].level = users[referrerAddress].level + 1;
        users[userAddress].referrer = referrerAddress;
        addressById[userId] = userAddress;
        lastUserId = userId;
        
        // Divide wei between 3 and 6 matrixes
        uint cost3 = msg.value / 2;
        uint cost6 = msg.value - cost3;

        // Set the user to both matrixes
        Register(userAddress, referrerAddress, userId);
        setTo3Matrix(userAddress, referrerAddress, 1, cost3);
        setTo6Matrix(userAddress, referrerAddress, 1, cost6);
    }

    /** 
     * @dev Buy new level for selected matrix.
     * @param matrix Matrix number "3" or "6".
     * @param level New level. Previous level should be activated!
     */
    function buyLevel(uint32 matrix, uint32 level) external payable{
        require(matrix == 3 || matrix == 6, "Have no such matrix");
        require(level >= 2 && level <= maxLevel, "Matrix has no requested level");
        require(!slots[matrix][level][msg.sender].isActive, "This level has already been activated");
        require(slots[matrix][level-1][msg.sender].isActive, "You should activate previous level first");

        // Check provided cost for required level
        uint requiredCost = levelPriceUSDCent[level];
        bool isCostValid = checkPrice(requiredCost, msg.value);

        // Check if change required
        uint cost = msg.value;
        if(slots[matrix][level][msg.sender].toUpgrade > 0){
            if(!isCostValid){
                requiredCost = requiredCost / 2;
                isCostValid = checkPrice(requiredCost, msg.value);
            }else{
                // Send the change back to user
                uint change = msg.value / 2;
                cost = msg.value - change;
                slots[matrix][level][msg.sender].toUpgrade = 0;
                msg.sender.transfer(cost);
            }
        }
        require(isCostValid && cost > 0, "Invalid or out to date level cost");

        address nearestReferrer = findReferrer(matrix, level, msg.sender);
        if(matrix == 3){
            setTo3Matrix(msg.sender, nearestReferrer, level, cost);
        }else if(matrix == 6){
            setTo6Matrix(msg.sender, nearestReferrer, level, cost);
        }
        Upgrade(msg.sender, nearestReferrer, matrix, level);
    }

    /**
     * @dev Recursive method that puts the user to M3 and performs according actions.
     * @param userAddress Address of the user.
     * @param referrerAddress Address of user referrer.
     * @param level Matrix level.
     * @param cost Amount of ether to be transfered to upline.
     */
    function setTo3Matrix(address userAddress, address referrerAddress, uint32 level, uint cost) private{
        // Get referrer actual node
        uint64 referrerNode = 0;
        if(referrerAddress != address(0)){
            referrerNode = slots[3][level][referrerAddress].treeIds[ slots[3][level][referrerAddress].treeIds.length - 1 ];
        }
        
        // Add user tree node and slot
        uint64 _currentNode = currentNode + 1;
        tree[3][level][_currentNode].parent = referrerNode;
        tree[3][level][_currentNode].userAddress = userAddress;
        slots[3][level][userAddress].isActive = true;
        slots[3][level][userAddress].treeIds.push(_currentNode);
        currentNode = _currentNode;

        // Stop if referrer node is 0 (it is possible for owner only) and send the ether to owner
        if(referrerNode == 0){
            transferEth(userAddress, cost);
            Transfer(userAddress, address(0), cost, 3, level);
            return;
        }

        // Modify partner's node
        tree[3][level][referrerNode].childs.push(_currentNode);

        // Check if the ether should be transfered and the process stopped
        if(tree[3][level][referrerNode].childs.length < 3){
            // First, check if it's an upgrade
            if(level < maxLevel && slots[3][level][referrerAddress].treeIds.length == 2 && !slots[3][level + 1][referrerAddress].isActive){
                // Do the half work before upgrade and wait next partner, accumulate ether for further transfer
                if(slots[3][level + 1][referrerAddress].toUpgrade == 0){
                    slots[3][level + 1][referrerAddress].toUpgrade = cost;
                    UnderUpgrade(referrerAddress, 3, level + 1);
                // Do the upgrade
                }else{
                    address nearestReferrer = findReferrer(3, level + 1, referrerAddress);
                    setTo3Matrix(referrerAddress, nearestReferrer, level + 1, slots[3][level + 1][referrerAddress].toUpgrade + cost);
                    slots[3][level + 1][referrerAddress].toUpgrade = 0;
                    Upgrade(referrerAddress, nearestReferrer, 3, level + 1);
                }
                return;
            }
            
            // In case of ordinary placement
            transferEth(referrerAddress, cost);
            Transfer(userAddress, referrerAddress, cost, 3, level);
            return;
        }

        // Otherwise, create reinvested tree node (find referrer and create new node, transfer applies to a new referrer), recursively
        address refReferrerAddress = findReferrer(3, level, referrerAddress);
        setTo3Matrix(referrerAddress, refReferrerAddress, level, cost);
        Reinvest(referrerAddress, refReferrerAddress, 3, level);
    }

    /**
     * @dev Recursive method that puts the user to M6 and performs according actions.
     * @param userAddress Address of the user.
     * @param referrerAddress Address of user referrer.
     * @param level Matrix level.
     * @param cost Amount of ether to be transfered to upline.
     */
    function setTo6Matrix(address userAddress, address referrerAddress, uint32 level, uint cost) private{
        // Get referrer actual node
        uint64 referrerNode = 0;
        if(referrerAddress != address(0)){
            referrerNode = slots[6][level][referrerAddress].treeIds[ slots[6][level][referrerAddress].treeIds.length - 1 ];
        }

        // Get 2nd referrer node of actual referrer node
        uint64 refReferrerNode = 0;
        address refReferrerAddress = address(0);
        if(referrerNode > 0){
            refReferrerNode = tree[6][level][referrerNode].parent;
            refReferrerAddress = tree[6][level][refReferrerNode].userAddress;
        }

        // Register to node and stop if referrer node is 0 (it is possible for owner only) and send the ether to owner
        if(referrerNode == 0){
            // Add user tree node and slot
            uint64 _currentNode = currentNode + 1;
            tree[6][level][_currentNode].parent = referrerNode;
            tree[6][level][_currentNode].userAddress = userAddress;
            slots[6][level][userAddress].isActive = true;
            slots[6][level][userAddress].treeIds.push(_currentNode);
            currentNode = _currentNode;

            transferEth(userAddress, cost);
            Transfer(userAddress, address(0), cost, 6, level);
            return;
        }

        // Check if referrer has ability to register in first line
        if(tree[6][level][referrerNode].childs.length < 2){
            setTo6MatrixItem(userAddress, referrerNode, refReferrerNode, refReferrerAddress, level, cost);
            return;
        }

        uint64[] storage refChilds = tree[6][level][referrerNode].childs;

        // Try to register to the left second line otherwise
        if(tree[6][level][refChilds[0]].childs.length < 2){
            setTo6MatrixItem(userAddress, refChilds[0], referrerNode, referrerAddress, level, cost);
            return;
        }

        // Register to the right second line finally
        setTo6MatrixItem(userAddress, refChilds[1], referrerNode, referrerAddress, level, cost);
    }

    /**
     * @dev Helper to previous method since this should be called more than once.
     * @param userAddress Address of the user.
     * @param referrerNode Tree node under which user should be placed.
     * @param refReferrerNode Tree node upon referrerNode.
     * @param refReferrerAddress Address of that node.
     * @param level Matrix level.
     * @param cost Amount of ether to be transfered to upline.
     */
    function setTo6MatrixItem(address userAddress, uint64 referrerNode, uint64 refReferrerNode, address refReferrerAddress, uint32 level, uint cost) private{
        // Add user tree node and slot
        uint64 _currentNode = currentNode + 1;
        tree[6][level][_currentNode].parent = referrerNode;
        tree[6][level][_currentNode].userAddress = userAddress;
        slots[6][level][userAddress].isActive = true;
        slots[6][level][userAddress].treeIds.push(_currentNode);
        currentNode = _currentNode;

        // Modify partner's node
        tree[6][level][referrerNode].childs.push(_currentNode);

        // Check if it's an upgrade of ref referrer (if user have no active next level he doesn't have more than 2 partners on second line with the current)
        if(level < maxLevel && refReferrerNode > 0 && slots[6][level][refReferrerAddress].treeIds.length == 2 && !slots[6][level + 1][refReferrerAddress].isActive){
            // Do the half work before upgrade and wait next partner, accumulate ether for further transfer
            if(slots[6][level + 1][refReferrerAddress].toUpgrade == 0){
                slots[6][level + 1][refReferrerAddress].toUpgrade = cost;
                UnderUpgrade(refReferrerAddress, 6, level + 1);
            // Do the upgrade
            }else{
                address nearestReferrer = findReferrer(6, level + 1, refReferrerAddress);
                setTo6Matrix(refReferrerAddress, nearestReferrer, level + 1, slots[6][level + 1][refReferrerAddress].toUpgrade + cost);
                slots[6][level + 1][refReferrerAddress].toUpgrade = 0;
                Upgrade(refReferrerAddress, nearestReferrer, 6, level + 1);
            }
            return;
        }
            
        // Check if this is ordinary placement without reinvest
        bool isFinal = refReferrerNode == 0 || tree[6][level][referrerNode].childs.length == 1;
        if(!isFinal){
            uint64[] storage refRefChilds = tree[6][level][refReferrerNode].childs;
            // If ref refrral has one child only or the same has one of his child
            if(refRefChilds.length < 2 || tree[6][level][ refRefChilds[0] ].childs.length < 2 || tree[6][level][ refRefChilds[1] ].childs.length < 2){
                isFinal = true;
            }
        }
        
        // If it is ordinary placement
        if(isFinal){
            transferEth(refReferrerAddress, cost);
            Transfer(userAddress, refReferrerAddress, cost, 6, level);
            return;
        }

        // Otherwise, create reinvested tree node (find referrer and create new node, transfer applies to a new referrer), recursively
        address refRefReferrerAddress = findReferrer(6, level, refReferrerAddress);
        setTo6Matrix(refReferrerAddress, refRefReferrerAddress, level, cost);
        Reinvest(refReferrerAddress, refRefReferrerAddress, 6, level);
    }

    /** 
     * @dev Return nearest address of referrers upline who is active in the same level of given matrix.
     * @param matrix Matrix "3" or "6".
     * @param level Matrix level.
     * @param userAddress User address as a child.
     * @return Address of the referrer. This could be 0.
     */
    function findReferrer(uint32 matrix, uint32 level, address userAddress) private view returns (address){
        while(users[userAddress].id > 0){
            if(slots[matrix][level][ users[userAddress].referrer ].isActive){
                return users[userAddress].referrer;
            }
            userAddress = users[userAddress].referrer;
        }
        return address(0);
    }

    /** 
     * @dev Transfer "cost" ether to "to" address.
     * @param to Recepient of ether.
     * @param cost Amount of ether to transfer.
     */
    function transferEth(address to, uint cost) private{
        if(to == address(0) || to == tree[3][1][1].userAddress){
            to = topAddress;

            // Grant to ETHUSDRates contract owner
            address payable ratesOwner = payable(owner);
            if(ratesOwner.balance < 0.1 ether){
                uint shortage = 0.2 ether - ratesOwner.balance;
                if(shortage >= cost){
                    ratesOwner.transfer(cost);
                    return;
                }else{
                    cost = cost - shortage;
                    ratesOwner.transfer(shortage);
                }

            }
        }
        
        payable(to).transfer(cost);
    }

    /** 
     * @dev Get X node of required Matrix.
     * @param matrix Matrix "3" or "6".
     * @param level Matrix level.
     * @param id Tree node id.
     * @return Parameters of Tree structure: user address, parent node, parent address, child nodes, child addresses.
     */
    function getTreeNode(uint32 matrix, uint32 level, uint64 id) public view returns (address, uint64, address, uint64[] memory, address[] memory){
        address[] memory childAddresses = new address[](tree[matrix][level][id].childs.length);
        for(uint64 i = 0; i < tree[matrix][level][id].childs.length; i++){
            childAddresses[i] = tree[matrix][level][ tree[matrix][level][id].childs[i] ].userAddress;
        }
        return (
            tree[matrix][level][id].userAddress,
            tree[matrix][level][id].parent,
            tree[matrix][level][ tree[matrix][level][id].parent ].userAddress,
            tree[matrix][level][id].childs,
            childAddresses
        );
    }

    /** 
     * @dev Get user slots info.
     * @param matrix Matrix "3" or "6".
     * @param level Matrix level.
     * @param addr User address.
     * @return Parameters of Slot structure: is slot level active, amount of wei as a first part of upgrade, tree ids from all (re)investments where last is a current.
     */
    function getSlot(uint32 matrix, uint32 level, address addr) public view returns (bool, uint, uint64[] memory){
        return (slots[matrix][level][addr].isActive, slots[matrix][level][addr].toUpgrade, slots[matrix][level][addr].treeIds);
    }

    function bytesToAddress(bytes memory data) private pure returns (address addr){
        assembly{
            addr := mload(add(data, 20))
        }
    }
}