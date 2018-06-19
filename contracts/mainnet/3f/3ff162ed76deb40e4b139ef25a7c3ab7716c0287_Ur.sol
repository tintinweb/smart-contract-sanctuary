pragma solidity ^0.4.8;
contract Owned {

    address public owner;
    enum StatusEditor{DisableEdit, EnableEdit}
    mapping(address => StatusEditor) public editors;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }

    function addNewEditor(address _editorAddress) onlyOwner{
        editors[_editorAddress] = StatusEditor.EnableEdit;
    }

    function deleteEditor(address _editorAddress) onlyOwner{
        editors[_editorAddress] = StatusEditor.DisableEdit;
    }

    modifier onlyEditor{
        if (editors[msg.sender] != StatusEditor.EnableEdit) throw;
        _;
    }

    modifier onlyOwnerOrEditor{
        if (msg.sender != owner && editors[msg.sender] != StatusEditor.EnableEdit) throw;
        _;
    }

}

contract Ur is Owned {

    struct Group{

        uint percentageBonus;
        uint price;
    }

    struct User{

        address userAddress;
        bool splitReceived;
        //bytes32 userGroup;
        uint userGroupID;
        bool convertedToCoins;
        uint currentPrice;
        uint currentDifficulty;
        uint currentTime;
    }

    uint256 public totalBalance;
    string public standard = &#39;UrToken&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    bool public contractPays;

    uint public Price;
    uint public Difficulty;
    uint balanceTemp;
    bool incrementPriceAndDifficulty;
    uint public difficultyBalance;
    uint public increaseStep;

    mapping(bytes32 => Group) public userGroups;
    mapping(address => User) public users;
    mapping(address => uint256) public balanceOf;

    address[] public userAddresses;
    bytes32[] public groupArray;

    uint public sizeOfUserAddresses;

    event Transfer(address indexed from, address indexed to, int256 value);

    Group Beginner;
    Group Advanced;
    Group Certified;
    Group Trader;
    Group Master;
    Group Ultimate;
    Group BegAdvCertif;
    Group AdvCertifTrader;
    Group CertifiedTrader;
    Group CertifiedMaster;
    Group CertifTradMast;
    Group TradMastUltim;

    function Ur(){
        totalBalance = 10000000000000000000000000000;
        balanceOf[msg.sender] = 10000000000000000000000000000;
        name = &#39;UrToken&#39;;
        symbol = &#39;URT&#39;;
        decimals = 16;
        contractPays = false;

        Price = 1;
        Difficulty = 10;
        balanceTemp = 0;
        incrementPriceAndDifficulty = true;
        increaseStep = 1000000;

        sizeOfUserAddresses = 0;
    }
    
    function install() onlyOwner {
        Beginner = Group({percentageBonus: 100, price: 99});
        Advanced = Group({percentageBonus: 100, price: 600});
        Certified = Group({percentageBonus: 100, price: 1500});
        Trader = Group({percentageBonus: 300, price: 5500});
        Master = Group({percentageBonus: 700, price: 11750});
        Ultimate = Group({percentageBonus: 1500, price: 22500});
        BegAdvCertif = Group({percentageBonus: 700, price: 2299});
        AdvCertifTrader = Group({percentageBonus: 700, price: 7700});
        CertifiedTrader = Group({percentageBonus: 700, price: 7100});
        CertifiedMaster = Group({percentageBonus: 1500, price: 13350});
        CertifTradMast = Group({percentageBonus: 6300, price: 18850});
        TradMastUltim = Group({percentageBonus: 12700, price: 39750});

        userGroups[0x426567696e6e6572] = Beginner;                          //000000000000000000000000000000000000000000000000426567696e6e6572
        userGroups[0x416476616e636564] = Advanced;                          //000000000000000000000000000000000000000000000000416476616e636564
        userGroups[0x436572746966696564] = Certified;                       //0000000000000000000000000000000000000000000000436572746966696564
        userGroups[0x547261646572] = Trader;                                //0000000000000000000000000000000000000000000000000000547261646572
        userGroups[0x4d6173746572] = Master;                                //00000000000000000000000000000000000000000000000000004d6173746572
        userGroups[0x556c74696d617465] = Ultimate;                          //000000000000000000000000000000000000000000000000556c74696d617465
        userGroups[0x426567416476436572746966] = BegAdvCertif;              //0000000000000000000000000000000000000000426567416476436572746966
        userGroups[0x416476436572746966547261646572] = AdvCertifTrader;     //0000000000000000000000000000000000416476436572746966547261646572
        userGroups[0x436572746966696564547261646572] = CertifiedTrader;     //0000000000000000000000000000000000436572746966696564547261646572
        userGroups[0x4365727469666965644d6173746572] = CertifiedMaster;     //00000000000000000000000000000000004365727469666965644d6173746572
        userGroups[0x436572746966547261644d617374] = CertifTradMast;        //000000000000000000000000000000000000436572746966547261644d617374
        userGroups[0x547261644d617374556c74696d] = TradMastUltim;           //00000000000000000000000000000000000000547261644d617374556c74696d

        groupArray.push(0x426567696e6e6572);                                //Beginner
        groupArray.push(0x416476616e636564);                                //Advanced
        groupArray.push(0x436572746966696564);                              //Certified
        groupArray.push(0x547261646572);                                    //Trader
        groupArray.push(0x4d6173746572);                                    //Master
        groupArray.push(0x556c74696d617465);                                //Ultimate
        groupArray.push(0x426567416476436572746966);                        //Beginner+Advanced+Certified
        groupArray.push(0x416476436572746966547261646572);                  //Advanced+Certified+Trader
        groupArray.push(0x436572746966696564547261646572);                  //Certified+Trader
        groupArray.push(0x4365727469666965644d6173746572);                  //Certified+Master
        groupArray.push(0x436572746966547261644d617374);                    //Certified+Trader+Master
        groupArray.push(0x547261644d617374556c74696d);                      //Trader+Master+Ultimate

    }                                                                         

    function addCoins(uint256 _value) onlyOwner{

        balanceOf[owner] += _value; 
        totalBalance += _value;
        Transfer(0, owner, int256(_value));
    }

    function addUser(address _userAddress, uint _userGroupID) onlyOwnerOrEditor returns(bool){ 

        if(groupArray[_userGroupID] == &#39;0x&#39;)
            return false;

        for(uint i=0;i<groupArray.length;i++){

            if(i == _userGroupID){
                difficultyBalance += userGroups[groupArray[i]].price;
            }
        }

        users[_userAddress].userGroupID = _userGroupID;
        users[_userAddress].splitReceived = false;
        users[_userAddress].userAddress = _userAddress;
        users[_userAddress].convertedToCoins = false;
        users[_userAddress].currentPrice = 0;
        users[_userAddress].currentTime = 0;

        userAddresses.push(_userAddress);

        //if(difficultyBalance>balanceTemp){
        //    incrementPriceAndDifficulty = false;
        //    increasePriceAndDifficulty();
        //}

        sizeOfUserAddresses = userAddresses.length;
                
        return true;
    }

    function addNewGroup(bytes32 _groupName, uint _percentageBonus, uint _price) onlyOwnerOrEditor returns (bool){ 

        userGroups[_groupName].percentageBonus = _percentageBonus;
        userGroups[_groupName].price = _price;

        groupArray.push(_groupName);

        return true;
    }

    function changeUserGroup(address _userAddress, uint _newUserGroupID) onlyOwner returns (bool){

        if(groupArray[_newUserGroupID] == &#39;0x&#39;)
            return false;

        for(uint i=0;i<groupArray.length;i++){

            if(i == _newUserGroupID){
                users[_userAddress].userGroupID = _newUserGroupID;
            }
        }

        return true;
    }

    function switchSplitBonusValue(address _userAddress, bool _newSplitValue) onlyOwner{

        users[_userAddress].splitReceived = _newSplitValue;
    }

    function increasePriceAndDifficulty() onlyOwnerOrEditor{
        if((difficultyBalance - balanceTemp) >= increaseStep){            
            balanceTemp = difficultyBalance;
            Difficulty += 10;
            Price += 1;           
        }
    }

    function changeDifficultyAndPrice(uint _newDifficulty, uint _newPrice) onlyOwner{
        Difficulty = _newDifficulty;
        Price = _newPrice;
        difficultyBalance = 0;
        balanceTemp = 0;
    }
    
    function changeIncreaseStep (uint _increaseStep) onlyOwner {
        increaseStep = _increaseStep;
    }

    function convert(address _userAddress) onlyOwnerOrEditor{

        users[_userAddress].convertedToCoins = true;
        users[_userAddress].currentPrice = Price;
        users[_userAddress].currentDifficulty = Difficulty;
        users[_userAddress].currentTime = block.timestamp;
    }

    function transfer(address _to, uint256 _value) {

        if (_value < 0 || balanceOf[msg.sender] < _value)
            throw;

        if (users[msg.sender].convertedToCoins) throw;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, int256(_value));
        if (contractPays && !msg.sender.send(tx.gasprice))
            throw;
    }

    function switchFeePolicy(bool _contractPays) onlyOwner {
        contractPays = _contractPays;
    }

    function showUser(address _userAddress) constant returns(address, bool, bytes32, bool, uint, uint, uint){

        return (users[_userAddress].userAddress, users[_userAddress].splitReceived, groupArray[users[_userAddress].userGroupID],
                users[_userAddress].convertedToCoins, users[_userAddress].currentPrice, users[_userAddress].currentDifficulty, users[_userAddress].currentTime);
    }

}