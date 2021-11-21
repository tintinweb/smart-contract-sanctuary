/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

pragma solidity ^0.8.10;




//                 Coded by
//
//                                            __                        
//                         | |__ |_  __ _    |_  o __  _ __  _  o  _  | 
//                         |_|||||_) | (_| o |   | | |(_|| |(_  | (_| | 
//
//  
//
//                                      On Behalf Of
//
//    _______       _ _ _       _     _                          __ _                            
//   |__   __|     (_) (_)     | |   | |                        / _(_)                           
//      | |_      ___| |_  __ _| |__ | |_ _______  _ __   ___  | |_ _ _ __   __ _ _ __   ___ ___ 
//      | \ \ /\ / / | | |/ _` | '_ \| __|_  / _ \| '_ \ / _ \ |  _| | '_ \ / _` | '_ \ / __/ _ \
//      | |\ V  V /| | | | (_| | | | | |_ / / (_) | | | |  __/_| | | | | | | (_| | | | | (_|  __/
//      |_| \_/\_/ |_|_|_|\__, |_| |_|\__/___\___/|_| |_|\___(_)_| |_|_| |_|\__,_|_| |_|\___\___|
//                         __/ |                                                                 
//                        |___/                                                                  



contract TwilightZoneWhitelist{
    
    
    //Initialize Variables
    uint256 public totalRaisedCapital;
    mapping (address => uint256) public depositedAmount;
    bool public contractLocked;
    address public masterAddress;
    address[] private addressList;
    User[] private whitelist;
    bool private listGenerated;
    uint256 public lockCap;
    
    
    //Deployment
    constructor(address _address) {
       
       masterAddress = _address;
       
       contractLocked = false;
       listGenerated = false;
       
       lockCap = 250 ether;
        
    }
    
    
    //Recieve Funds Function
    receive() external payable {
        
        require(contractLocked == false);
        
        if (msg.value > 0){
            
            //1 BNB = 100000000
            //1 BNB = 1 ETHER for some reason
            
            require(msg.value <= 6 ether);
            require((msg.value + depositedAmount[msg.sender]) <= 6 ether);
            
            //Creates an Addres List
            if(depositedAmount[msg.sender] == 0){
                addressList.push(msg.sender);
            }
            
            depositedAmount[msg.sender] += msg.value;
            
            totalRaisedCapital += msg.value;
            emit Deposit(msg.sender, msg.value);
            
            if(totalRaisedCapital >= lockCap){
                contractLocked = true;
            }
            
        }
    }
    
    function generateWhitelist() public isMaster returns(bool success){
        
        require(contractLocked == true);
        require(listGenerated == false);
        
        //Generates List
        for (uint i = 0; i <= addressList.length - 1; i++) {
            whitelist.push(User(addressList[i], depositedAmount[addressList[i]]));
        }
        
        listGenerated = true;
        
        return true;
    }
    
    //Shows Whitelist
    function getWhitelist() public view returns(User[] memory _whitelist) {
        return whitelist;
    }
    
    
    //Empty The Bank
    function transferToMultiSig() public isMaster returns(bool success) {
        
        payable(masterAddress).transfer((address(this).balance));
        
        return true;
    }
    
    function freeze() public isMaster returns(bool success) {
        contractLocked = true;
        return true;
    }
    
    function increaseLockCap(uint256 _amount) public isMaster returns(bool succes) {
        
        require(contractLocked == true);
        require(listGenerated == false);
        lockCap += _amount;
        emit CapIncrease(_amount);
        
        return true;
    }
    
    
    //Useful For Storing Information
    struct User{
        address wallet;
        uint256 value;
    }
    
    
    
    //Let Everyone Know
    event Deposit(address indexed sender, uint256 value);
    event CapIncrease(uint256 value);
    
    
    //Admin Stuff
    modifier isMaster() {
        require(msg.sender == masterAddress);
        _;
    }
    
    
}