pragma solidity ^0.4.21;

contract colors {
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    
    mapping (uint => string) private messageLog;
    mapping (uint => address) private senderLog;
    mapping (uint => string) private senderColor;
    mapping (address => string) private myColor;
    mapping (address => uint) private colorCount;
    uint private messageCount;
    
    uint private red;
    uint private orange;
    uint private yellow;
    uint private green;
    uint private blue;
    uint private teal;
    uint private purple;
    uint private pink;
    uint private black;
    uint private white;
    
    function colors () public {
        owner = msg.sender;
        messageCount = 20;
    }
      
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function withdraw() external onlyOwner {
	    owner.transfer(this.balance);
	}
	
	modifier onlyRegistered () {
	    require (colorCount[msg.sender] > 0);
	    _;
	}
	
	function sendMessage (string _message) external onlyRegistered {
	    if (messageCount == 70) {
	        messageCount = 20;
	    }
	    messageCount++;
	    senderLog[messageCount] = (msg.sender);
	    senderColor[messageCount] = (myColor[msg.sender]);
	    messageLog[messageCount] = (_message);
	}
	
	
	function view22 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[21], senderColor[21], messageLog[21], senderLog[22], senderColor[22], messageLog[22]);
	}
	
	function view24 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[23], senderColor[23], messageLog[23], senderLog[24], senderColor[24], messageLog[24]);
	}
	
	function view26 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[25], senderColor[25], messageLog[25], senderLog[26], senderColor[26], messageLog[26]);
	}
	
	function view28 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[27], senderColor[27], messageLog[27], senderLog[28], senderColor[28], messageLog[28]);
	}
	
	function view30 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[29], senderColor[29], messageLog[29], senderLog[30], senderColor[30], messageLog[30]);
	}
	
	function view32 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[31], senderColor[31], messageLog[31], senderLog[32], senderColor[32], messageLog[32]);
	}
	
	function view34 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[33], senderColor[33], messageLog[33], senderLog[34], senderColor[34], messageLog[34]);
	}
	
	function view36 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[35], senderColor[35], messageLog[35], senderLog[36], senderColor[36], messageLog[36]);
	}
	
	function view38 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[37], senderColor[37], messageLog[37], senderLog[38], senderColor[38], messageLog[38]);
	}
	
	function view40 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[39], senderColor[39], messageLog[39], senderLog[40], senderColor[40], messageLog[40]);
	}
	
	function view42 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[41], senderColor[41], messageLog[41], senderLog[42], senderColor[42], messageLog[42]);
	}
	
	function view44 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[43], senderColor[43], messageLog[43], senderLog[44], senderColor[44], messageLog[44]);
	}
	
	function view46 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[45], senderColor[45], messageLog[45], senderLog[46], senderColor[46], messageLog[46]);
	}
	
	function view48 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[47], senderColor[47], messageLog[47], senderLog[48], senderColor[48], messageLog[48]);
	}
	
	function view50 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[49], senderColor[49], messageLog[49], senderLog[50], senderColor[50], messageLog[50]);
	}
	
	function view52 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[51], senderColor[51], messageLog[51], senderLog[52], senderColor[52], messageLog[52]);
	}
	
	function view54 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[53], senderColor[53], messageLog[53], senderLog[54], senderColor[54], messageLog[54]);
	}
	
	function view56 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[55], senderColor[55], messageLog[55], senderLog[56], senderColor[56], messageLog[56]);
	}
	
	function view58 () view public returns (address, string, string, address, string, string) {
	   return (senderLog[57], senderColor[57], messageLog[57], senderLog[58], senderColor[58], messageLog[58]);
	}
	
	function view60 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[59], senderColor[59], messageLog[59], senderLog[60], senderColor[60], messageLog[60]);
	}
	
	function view62 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[61], senderColor[61], messageLog[61], senderLog[62], senderColor[62], messageLog[62]);
	}
	
	function view64 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[63], senderColor[63], messageLog[63], senderLog[64], senderColor[64], messageLog[64]);
	}
	
	function view66 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[65], senderColor[65], messageLog[65], senderLog[66], senderColor[66], messageLog[66]);
	}
	
	function view68 () view public returns (address, string, string, address, string, string) {
	   return (senderLog[67], senderColor[67], messageLog[67], senderLog[68], senderColor[68], messageLog[68]);
	}
	
	function view70 () view public returns (address, string, string, address, string, string) {
	    return (senderLog[69], senderColor[69], messageLog[69], senderLog[70], senderColor[70], messageLog[70]);
	}
	
	modifier noColor () {
	    require (colorCount[msg.sender] == 0);
	    require (msg.value == 0.0025 ether);
	    _;
	}
	
	function setColorRed () external payable noColor {
	    red++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#ff383b";
	}
	
	function setColorOrange () external payable noColor {
	    orange++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#f8ac28";
	}
	
	function setColorYellow () external payable noColor {
	    yellow++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#ead353";
	}
	
	function setColorGreen () external payable noColor {
	    green++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#67d75c";
	}
	
	function setColorBlue () external payable noColor {
	    blue++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#476ef2";
	}
	
	function setColorTeal () external payable noColor {
	    teal++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#86e3db";
	}
	
	function setColorPurple () external payable noColor {
	    purple++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#9b5aea";
	}
	
	function setColorPink () external payable noColor {
	    pink++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#e96de8";
	}
	
	function setColorBlack () external payable noColor {
	    black++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#212121";
	}
	
	function setColorWhite () external payable noColor {
	    white++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#cecece";
	}
	
	modifier hasColor () {
	    require (colorCount[msg.sender] > 0);
	    require (msg.value == 0.00125 ether);
	    _;
	}
	
	function changeColorRed () external payable hasColor {
	    red++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#ff383b";
	}
	
	function changeColorOrange () external payable hasColor {
	    orange++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#f8ac28";
	}
	
	function changeColorYellow () external payable hasColor {
	    yellow++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#ead353";
	}
	
	function changeColorGreen () external payable hasColor {
	    green++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#67d75c";
	}
	
	function changeColorBlue () external payable hasColor {
	    blue++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#476ef2";
	}
	
	function changeColorTeal () external payable hasColor {
	    teal++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#86e3db";
	}
	
	function changeColorPurple () external payable hasColor {
	    purple++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#9b5aea";
	}
	
	function changeColorPink () external payable hasColor {
	    pink++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#e96de8";
	}
	
	function changeColorBlack () external payable hasColor {
	    black++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#212121";
	}
	
	function changeColorWhite () external payable hasColor {
	    white++;
	    colorCount[msg.sender]++;
	    myColor[msg.sender] = "#cecece";
	}
	
	function myColorIs () public view returns (string) {
        return myColor[msg.sender];
    }
    
    function colorLeaderboard () public view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (colorCount[msg.sender], red, orange, yellow, green, blue, teal, purple, pink, black, white, messageCount);
    }
}