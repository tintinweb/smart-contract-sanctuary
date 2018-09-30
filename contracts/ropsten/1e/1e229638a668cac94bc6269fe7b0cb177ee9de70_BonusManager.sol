pragma solidity ^0.4.18;


contract BonusManager {

    constructor() public {

        
            
    }
    
    enum InequalityValue {LessThan, GreaterThan}
    
    struct BonusName {
        bytes32 bonusName;
    }

    struct  Bonus {
        bytes32 bonusName;
        bytes32 bonusType;
        uint bonusTarget;
        uint bonusEndYear;
        uint bonusEndMonth;
        uint bonusEndDay;
        bytes32 bonusToken;
        uint bonusAmount;
        bool bonusExists;
        InequalityValue ineq;
    }

    struct PaymentDetail {
        uint totalPaid;
    }
 
    struct WalletBonus {
        bool bonusExists;
    }

    struct WalletBonusList {
        bytes32 bonusname;
    }
    
    struct WalletDetail {
        bytes32 walletEmailAddress;
    }


 // map wallet to wallet details
    mapping (address => WalletDetail) public WalletDetails;
 
     // map wallet and token to bonus payment
    mapping (address => mapping (bytes32 => WalletBonus) ) public WalletBonuses;

    mapping (address => WalletBonusList[]) public WalletBonusLists;
    
    // map wallet and token to bonus payment
    mapping (address => mapping (bytes32 => PaymentDetail) ) public PaymentDetails; 
     // map bonus name to bonus 
    mapping  (bytes32 => Bonus)  public Bonuses;
    
    address[] public Wallets;
    BonusName[] public BonusNamesArray;
    bytes32[] public BonusNamesBytes;


    uint k;

    function addK(uint k1) public {
        k =k1;
    }
    

    
    function getWallets() public view returns (address[]) {
        return Wallets;
    }
    
    function getBonusNames() public view returns (bytes32[]) {
        return BonusNamesBytes;
    }
    
    
    function addBonus( string bonusType, uint bonusTarget,  uint bonusEndYear,
        uint bonusEndMonth, uint bonusEndDay, 
        string bonusToken, uint bonusAmount, string bonusName, uint ineq ) public {
        bytes32 bonusTokenBytes = stringToBytes32(bonusToken);
        bytes32 bonusTypeBytes = stringToBytes32(bonusType);
        bytes32 bonusNameBytes = stringToBytes32(bonusName);
        
        Bonuses[bonusNameBytes].bonusName=bonusNameBytes;
        Bonuses[bonusNameBytes].bonusType=bonusTypeBytes;
        Bonuses[bonusNameBytes].bonusTarget=bonusTarget;
        Bonuses[bonusNameBytes].bonusEndYear=bonusEndYear;
        Bonuses[bonusNameBytes].bonusEndMonth=bonusEndMonth;
        Bonuses[bonusNameBytes].bonusEndDay=bonusEndDay;
        Bonuses[bonusNameBytes].bonusToken=bonusTokenBytes;
        Bonuses[bonusNameBytes].bonusAmount=bonusAmount;
        Bonuses[bonusNameBytes].bonusExists=true;
        Bonuses[bonusNameBytes].ineq=InequalityValue(ineq);
        
        BonusName memory b;
        b.bonusName=bonusNameBytes;
        BonusNamesArray.push(b);
    
        BonusNamesBytes.push(bonusNameBytes);
        
    }

    function addWalletBonus( address wallet, string bonusName ) public {
        bytes32 bonusNameBytes = stringToBytes32(bonusName);
        require (Bonuses[bonusNameBytes].bonusExists);
        WalletBonuses[wallet][bonusNameBytes].bonusExists =true;
        
        WalletBonusList memory b;
        b.bonusname=bonusNameBytes;
        
        WalletBonusList memory wb = WalletBonusList(bonusNameBytes); 
        
        WalletBonusLists[wallet].push(wb);
 
    }

    function getWalletBonuses(address wallet) public view returns (bytes32[] bonusNames) {
 
        uint length = WalletBonusLists[wallet].length;
        bonusNames = new bytes32[](length);

        for(uint i = 0; i < length; i++)
        {
            bonusNames[i] =  WalletBonusLists[wallet][i].bonusname;
        }   
    }

    function getNumberWallets() public view returns(uint) {
        return Wallets.length;
    }


    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
           return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 x)   public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function addPaymentDetail (address wallet, bytes32 token, uint payment) public {
        uint totalPaid = PaymentDetails[wallet][token].totalPaid;
        totalPaid=totalPaid+payment;
        PaymentDetails[wallet][token].totalPaid=totalPaid;
    }

    function addWalletEmail (address wallet, string emailAddress) public {
        bytes32 emailAddressBytes = stringToBytes32(emailAddress);
        require(WalletDetails[wallet].walletEmailAddress==0x00);
      
        if (WalletDetails[wallet].walletEmailAddress == emailAddressBytes ) {
            // already exists
        } else {
             WalletDetails[wallet].walletEmailAddress=emailAddressBytes;
             Wallets.push(wallet);
        }
       
    }

    function addWallet(address wallet) public {
       Wallets.push(wallet);
    }

    function isBonusPayable(address wallet, string bonusName, uint targetReached, uint endYear, uint endMonth, uint endDay)
    public view returns (bool payBonus, uint bonusAmount, string bonusToken)  
 
    {
        bytes32 bonusNameBytes32 = stringToBytes32(bonusName);
        require(Bonuses[bonusNameBytes32].bonusExists);
        require(WalletBonuses[wallet][bonusNameBytes32].bonusExists);
        
        bool beforeEnd=false;
        payBonus=false;
        bytes32 bonusTokenBytes;
        bonusAmount=0;
        bonusToken="";
        
        if ((endYear <= Bonuses[bonusNameBytes32].bonusEndYear)
        && (endMonth <= Bonuses[bonusNameBytes32].bonusEndMonth)
        && (endDay <= Bonuses[bonusNameBytes32].bonusEndDay)) {
            beforeEnd = true;
        }

        if ((targetReached >= Bonuses[bonusNameBytes32].bonusTarget) && beforeEnd) {
            payBonus = true;
            bonusAmount = Bonuses[bonusNameBytes32].bonusAmount;
            bonusTokenBytes = Bonuses[bonusNameBytes32].bonusToken;
            bonusToken = bytes32ToString(bonusTokenBytes);
        }
        
        return (payBonus, bonusAmount,  bonusToken);
        
    }

    function () payable public {
    }

}