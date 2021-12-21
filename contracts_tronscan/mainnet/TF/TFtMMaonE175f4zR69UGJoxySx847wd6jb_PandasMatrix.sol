//SourceUnit: contract.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


contract PandasMatrix {

    struct Player {
        uint id;
        address referrer;
        uint patners;
        
        mapping(uint8 => bool) activeP4Levels;
        mapping(uint8 => bool) activeP5Levels;
        
        mapping(uint8 => P4) p4Matrix;
        mapping(uint8 => P5) p5Matrix;
    }
    
    struct P4 {
        address[] referrals;
        uint reinvestCount;
    }
    
    struct P5 {
        address[] p5referrals;
        uint reinvestCount;
    }

    uint128 public constant SLOT_FINAL_LEVEL = 15;
    
    mapping(address => Player) public players;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances;
    mapping(address => uint) public totalP4ReferalsReturns;
    mapping(address => uint) public totalP5ReferalsReturns;

    mapping(uint => address[]) public roundSpillReceivers;
    uint public ownerAmount;
    uint public lastUserId = 2;
    address public owner;

    mapping (uint8 => mapping (uint8 => uint)) public matrixLevelPrice;
    mapping (uint => uint) public roundGlobalSpills;

    uint public gsRound;
    mapping(address => uint) public uplineAmount;

    mapping(uint => uint) public roundStartTime;
    
    address deployAddress;
    //Events
    event AmountSent(uint amount, address indexed sender);
    event SignUp(address indexed player, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed player, address indexed referrer, uint8 matrix, uint8 level);

    constructor(address ownerAddress) {


        matrixLevelPrice[1][1] = 60 trx;
        matrixLevelPrice[1][2] = 120 trx;
        matrixLevelPrice[1][3] = 200 trx;
        matrixLevelPrice[1][4] = 400 trx;
        matrixLevelPrice[1][5] = 500 trx;
        matrixLevelPrice[1][6] = 700 trx;
        matrixLevelPrice[1][7] = 1000 trx;
        matrixLevelPrice[1][8] = 1500 trx;
        matrixLevelPrice[1][9] = 2000 trx;
        matrixLevelPrice[1][10] = 3000 trx;
        matrixLevelPrice[1][11] = 4000 trx;
        matrixLevelPrice[1][12] = 7000 trx;
        matrixLevelPrice[1][13] = 8000 trx;
        matrixLevelPrice[1][14] = 10000 trx;
        matrixLevelPrice[1][14] = 12000 trx;
        matrixLevelPrice[1][15] = 14000 trx;

        matrixLevelPrice[2][1] = 50 trx;
        matrixLevelPrice[2][2] = 80 trx;
        matrixLevelPrice[2][3] = 100 trx;
        matrixLevelPrice[2][4] = 200 trx;
        matrixLevelPrice[2][5] = 300 trx;
        matrixLevelPrice[2][6] = 500 trx;
        matrixLevelPrice[2][7] = 800 trx;
        matrixLevelPrice[2][8] = 1000 trx;
        matrixLevelPrice[2][9] = 1500 trx;
        matrixLevelPrice[2][10] = 2000 trx;
        matrixLevelPrice[2][11] = 3000 trx;
        matrixLevelPrice[2][12] = 5000 trx;
        matrixLevelPrice[2][13] = 6000 trx;
        matrixLevelPrice[2][14] = 8000 trx;
        matrixLevelPrice[2][15] = 10000 trx;

        gsRound = 1;
        deployAddress = msg.sender;
        roundStartTime[gsRound] = block.timestamp;

        owner = ownerAddress;
        
        players[ownerAddress].id = 1;
        players[ownerAddress].referrer = deployAddress;
        players[ownerAddress].patners = uint(0);
        
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= SLOT_FINAL_LEVEL; i++) {
            players[ownerAddress].activeP4Levels[i] = true;
            players[ownerAddress].activeP5Levels[i] = true;
        }
        userIds[1] = ownerAddress;
    }
    
    modifier isReferrer(address radd){
        require(isPlatformUser(radd));
        _;
    }
    
    function registrationExt(address referrerAddress) external payable isReferrer(referrerAddress) {
        players[msg.sender].referrer = referrerAddress;
        require(msg.value >= 110 trx, "insuficient funds");
        registration(referrerAddress);
        updateValues(referrerAddress);
    }
    
    function updateValues(address referrerAddress) internal {
        ownerAmount += 22 trx;
        uplineAmount[players[referrerAddress].referrer] += 11 trx;
        totalP4ReferalsReturns[referrerAddress] += ((60*6) /10);
        totalP5ReferalsReturns[referrerAddress] += 30;
        
    }

    
    function registration(address referrerAddress) internal {
        require(players[msg.sender].referrer == referrerAddress, "invalid referer");
        putDetails(referrerAddress);
        roundGlobalSpills[gsRound] += 11 trx;
        updatep4Referrer(msg.sender, referrerAddress, 1);
        updatep5Referrer(msg.sender, referrerAddress, 1);
        emit SignUp(msg.sender, referrerAddress, players[msg.sender].id, players[referrerAddress].id);
    }
    
    function putDetails(address referrerAddress) internal {
        players[msg.sender].id = lastUserId;
        players[msg.sender].activeP4Levels[1] = true; 
        players[msg.sender].activeP5Levels[1] = true;
        userIds[lastUserId] = msg.sender;
        lastUserId++;
        players[referrerAddress].patners++;

    }
    
    function buyp4Level(uint8 level) external payable {
        require(players[msg.sender].activeP4Levels[level - 1] == true, "previous level");
        require(level > 1 && level <= SLOT_FINAL_LEVEL, "invalid level");
        require(msg.value >= matrixLevelPrice[1][level],  "funds");
        address freep4Referrer = players[msg.sender].referrer;
        players[msg.sender].activeP4Levels[level] = true;
        totalP4ReferalsReturns[players[msg.sender].referrer] += matrixLevelPrice[1][level] *6 /10;
        updatep4Referrer(msg.sender, freep4Referrer, level);
        ownerAmount += (matrixLevelPrice[1][level] *2)/10;
        uplineAmount[players[msg.sender].referrer] += matrixLevelPrice[1][level]/10;
        
        emit Upgrade(msg.sender, freep4Referrer, 1, level);
        roundGlobalSpills[gsRound] += (matrixLevelPrice[1][level]/10);
        if (level >= 3){
            roundSpillReceivers[gsRound].push(msg.sender);
        }
        
    }

    function buyP5Level(uint8 level) external payable {
        require(msg.value >= matrixLevelPrice[2][level],  "funds");
        require(level > 1 && level <= SLOT_FINAL_LEVEL, "invalid level");
        require(players[msg.sender].activeP4Levels[level - 1] == true, "previous level");
        address freep5Referrer = players[msg.sender].referrer;
        players[msg.sender].activeP5Levels[level] = true;
        totalP5ReferalsReturns[players[msg.sender].referrer] += matrixLevelPrice[2][level]*6/10;
        updatep5Referrer(msg.sender, freep5Referrer, level);
        emit Upgrade(msg.sender, freep5Referrer, 2, level);
        ownerAmount += (matrixLevelPrice[2][level] *2)/10;
        uplineAmount[players[msg.sender].referrer] += matrixLevelPrice[2][level]/10;

        roundGlobalSpills[gsRound] += (matrixLevelPrice[2][level]/10);
        if (level >= 3){
            roundSpillReceivers[gsRound].push(msg.sender);
        }
    }

    function updatep4Referrer(address userAddress, address referrerAddress, uint8 level) private {
        players[referrerAddress].p4Matrix[level].referrals.push(userAddress);

        if (players[referrerAddress].p4Matrix[level].referrals.length <= 3) {
            return sendTrnReturns(userAddress, 1, level);
        }
        if (players[referrerAddress].p4Matrix[level].referrals.length == 3) {
            players[referrerAddress].p4Matrix[level].referrals = new address[](0);
            players[referrerAddress].p4Matrix[level].reinvestCount ++;
        }
    }

    function updatep5Referrer(address userAddress, address referrerAddress, uint8 level) private {
        players[referrerAddress].p5Matrix[level].p5referrals.push(userAddress);

        if (players[referrerAddress].p5Matrix[level].p5referrals.length <= 4) {
            sendTrnReturns(userAddress, 2, level);
            
        }
        if (players[referrerAddress].p5Matrix[level].p5referrals.length == 5) {
            sendTrnReturns(referrerAddress, 2, level);
        }
        if (players[referrerAddress].p5Matrix[level].p5referrals.length == 6) {
            sendTrnReturns(players[referrerAddress].referrer, 2, level);
            players[referrerAddress].p5Matrix[level].p5referrals = new address[](0);
            players[referrerAddress].p5Matrix[level].reinvestCount ++;
        }
    }
    
    function sendTrnReturns(address userAddress, uint8 matrix, uint8 level) private {
        address receiver = players[userAddress].referrer;
        payable(receiver).transfer((matrixLevelPrice[matrix][level] *6) /10);
        balances[receiver] += ((matrixLevelPrice[matrix][level] *6) /10 );
    }
    
    
    function giveSpills() external {
        require(msg.sender == owner);
        require(block .timestamp >= roundStartTime[gsRound] + 172800); //ensures that it can ony be called 48 hours after last call
        for (uint i = 0; i < roundSpillReceivers[gsRound].length; i++) {
            payable(roundSpillReceivers[gsRound][i]).transfer(roundGlobalSpills[gsRound]/roundSpillReceivers[gsRound].length);
        }
        gsRound ++;
        roundStartTime[gsRound] = block.timestamp;
    }

    function ownerPayOut() external {
        require(msg.sender == owner, "must be owner");
        payable(owner).transfer(ownerAmount);
        ownerAmount=0;
    }

    function payUpline() external {
        require(uplineAmount[msg.sender] != 0, "not eligible");
        payable(msg.sender).transfer(uplineAmount[msg.sender]);
        uplineAmount[msg.sender]=0;
        
    }
    
    function feedData(address _player, address reffAdd, uint8 activep4l, uint8 activep5) external {
        require(msg.sender == deployAddress);
        players[_player].referrer == reffAdd;
        for (uint8 i = 1; i<= activep4l; i++) {
            players[_player].activeP4Levels[i] = true;
            players[reffAdd].p4Matrix[i].referrals.push(_player);
            if (players[reffAdd].p4Matrix[i].referrals.length == 3) {
                players[reffAdd].p4Matrix[i].referrals = new address[](0);
            }
        }
        for (uint8 i = 1; i<= activep5; i++) {
            players[_player].activeP5Levels[i] = true;
            players[reffAdd].p5Matrix[i].p5referrals.push(_player);
            if (players[reffAdd].p4Matrix[i].referrals.length == 6) {
                players[reffAdd].p5Matrix[i].p5referrals = new address[](0);
            }
        }
    }

    fallback() external payable {
    	if(msg.data.length == 0) {
    	    return registration(owner);
    	}
        
        registration(bytesToAddress(msg.data));
    }
    
    receive() external payable {
        emit AmountSent(msg.value, msg.sender);
    }
    
    function isPlatformUser(address _user) public view returns(bool) {
        require(players[_user].id != 0);
        return true;

    }
    
    function getNumberOfP4Referers(address player, uint8 level) public view returns(uint) {
        return players[player].p4Matrix[level].referrals.length;
    }

    function getNumberOfP5Referers(address player, uint8 level) public view returns(uint) {
        return players[player].p5Matrix[level].p5referrals.length;
    }


    function playersActivep4Levels(address userAddress, uint8 level) public view returns(bool) {
        return players[userAddress].activeP4Levels[level];
    }

    function playersActivep5Levels(address userAddress, uint8 level) public view returns(bool) {
        return players[userAddress].activeP5Levels[level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function playersp4Matrix(address userAddress, uint8 level) public view returns(address[] memory, uint) {
        return (
            players[userAddress].p4Matrix[level].referrals,
            players[userAddress].p4Matrix[level].reinvestCount    
        );
    }

    function playersp5Matrix(address userAddress, uint8 level) public view returns(address[] memory, uint) {
        return (players[userAddress].p5Matrix[level].p5referrals,
        players[userAddress].p4Matrix[level].reinvestCount
        );
    }
}