/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

pragma solidity ^0.5.4;

contract LuckyCupCNR {
    //address constant TokenContractAddress = address(0x41E7B0D7CAD84E731F436C724A5549F0887E34EFDB);//TX6GwdmA67pzDA1pgnj8Be4vRqhxTysema  shasta
    address TokenContractAddress = address(0x6278147FDAEa8BA689cA23ee710535D2D402a092);//TYLrbh1pVcx95bop33XQ1iYdh7r3ogEQ8Q CNR Mainnet
    address payable _owner;
    //address payable partner = address(0);
    address payable Dev = address(0);
    address payable ROI = address(0x1d8A7f26c39776bEf9FfcEf2BF4C5FB3270A9CCc);
    uint constant decimals = 8;                        //CNR decimal = 8

    //10% feeds Daily ROI game, 5% to me, 5% referral
    address[] players;
    struct Variables {
        uint64 nounce;
        uint256 minBet;
        uint256 maxBet;
        uint32 comRef;          //Affiliate
        uint32 comHouse;        //owner
        uint32 comROI;
        uint32 comDev;
        uint32 comPartner;
        
        uint256 totalWin;
        uint256 totalPlayed;
        
        uint256 totalFeedROI;
        uint32 Multiplier;
        
        
    }
    Variables public vars;
    mapping (address => bool) partners;
    
    event LoseBet(address _address,uint8 _ran,uint8 mySelect,uint256 _betTRX);
    event Rewarded(address _address,uint8 _ran,uint8 mySelect,uint256 _reward,uint256 _betTRX);
    
    //Construction
    constructor () public //creation settings
    { 
        _owner = msg.sender;
        
        vars.minBet = 10 * (10**decimals);
        vars.maxBet = 1000 * (10**decimals);
        vars.nounce = 0;
        vars.comRef = 500;          //Affiliate 5%
        vars.comHouse=500;        //owner 5%
        vars.comROI=1000;           //ROI 10%
        vars.comDev=0;
        vars.comPartner=0; 
        vars.totalWin = 0;
        vars.totalPlayed = 0;
        vars.totalFeedROI = 0;
        vars.Multiplier = 2;
    }

    function play(uint256 TOKENamount, uint8 mySelect,address payable ref,address payable partner) external returns (uint8 _mySelect,uint8 _ran,uint256 _reward){
        require(ref != address(0),"error no ref");
        require(TOKENamount >= vars.minBet,'minBet required');
        require(TOKENamount <= vars.maxBet,'maxBet required');
        require(mySelect<3,'only 0 1 2');
        require(_owner != msg.sender,"owner cant play");
        vars.totalPlayed += TOKENamount;
        
        TokenContract token = TokenContract(TokenContractAddress);
        
        uint256 allowance = token.allowance(msg.sender,address(this));
        require (allowance>=TOKENamount,'allowance error');
        token.transferFrom(msg.sender,_owner,TOKENamount);
        //send token to contract owner address
        
        // uint256 totalCom = 0;
        // if (ref != msg.sender)
        // {
        //     uint256 comRef = vars.comRef * TOKENamount / 10000;
        //     if (comRef>0)
        //         ref.transfer(comRef);
        //     totalCom += comRef;
        // }
        
        // uint256 comHouse = vars.comHouse * TOKENamount / 10000;
        // if (comHouse>0)
        //     _owner.transfer(comHouse);
        // totalCom += comHouse;

        
        // if (Dev != address(0))
        // {
        //     uint256 comDev = vars.comDev * TOKENamount / 10000;
        //     if (comDev>0)
        //         Dev.transfer(comDev);
        //     totalCom += comDev;
        // }
        
        // if (partner != address(0) && partnerValid(partner))
        // {
        //     uint256 comPartner = vars.comPartner * TOKENamount / 10000;
        //     if (comPartner>0)
        //         partner.transfer(comPartner);
        //     totalCom += comPartner;
            
        // }
        
        uint8 ran = random();
        uint256 reward =0;
        if (ran == mySelect) //WIN
        {
            reward = vars.Multiplier * TOKENamount;
            token.transferFrom(_owner,msg.sender,reward);
            vars.totalWin += reward;
            emit Rewarded(msg.sender,ran,mySelect,reward,TOKENamount);
        }
        else    //LOSE
        {
            emit LoseBet(msg.sender,ran,mySelect,TOKENamount);
            
        }
        
        return (mySelect,ran,reward);
        
    }
    function partnerValid(address payable _partner) public view returns (bool _valid){
        if (partners[_partner] == true)
            return true;
        else
            return false;
    }
    function setPartner(address payable _partner,bool pay) onlyOwner public {
        require(_partner != address(0),"non zero");
        partners[_partner] = pay;
    }
    function getPartner(address index) public view returns(bool _exist) {
        return partners[index];
    }  
    //setters getters variables
    // uint256 minBet;
    function setminBet(uint256 _minBet) onlyOwner public {
        vars.minBet = _minBet;
    }
    function getminBet() public view returns(uint256 _minBet) {
        return vars.minBet;
    }
    // uint256 maxBet;
    function setmaxBet(uint256 _maxBet) onlyOwner public {
        vars.maxBet = _maxBet;
    }
    function getmaxBet() public view returns(uint256 _maxBet) {
        return vars.maxBet;
    }
    // uint32 comRef;          //Affiliate
    function setComRef(uint32 _comRef) onlyOwner public {
        vars.comRef = _comRef;
    }
    function getComRef() public view returns(uint32 _comRef) {
        return vars.comRef;
    }
    // uint32 comHouse;        //owner
    function setComHouse(uint32 _comHouse) onlyOwner public {
        vars.comHouse = _comHouse;
    }
    function getComHouse() public view returns(uint32 _comHouse) {
        return vars.comHouse;
    } 
    // uint32 comROI;
    function setComROI(uint32 _comROI) onlyOwner public {
        vars.comROI = _comROI;
    }
    function getComROI() public view returns(uint32 _comROI) {
        return vars.comROI;
    }
    // uint32 comDev;
    function setComDev(uint32 _comDev) onlyOwner public {
        vars.comDev = _comDev;
    }
    function getComDev() public view returns(uint32 _comDev) {
        return vars.comDev;
    } 
    // uint32 comPartner;
    function setComPartner(uint32 _comPartner) onlyOwner public {
        vars.comPartner = _comPartner;
    }
    function getComPartner() public view returns(uint32 _comPartner) {
        return vars.comPartner;
    }
    function getTotalFeedROI() public view returns(uint256 _totalFeedROI) {
        return vars.totalFeedROI;
    } 
    // uint256 totalWin;
    function gettotalWin() public view returns(uint256 _totalWin) {
        return vars.totalWin;
    }
    // uint256 totalPlayed;
    function gettotalPlayed() public view returns(uint256 _totalPlayed) {
        return vars.totalPlayed;
    }
    // uint32 Multiplier;
    function setMultiplier(uint32 _Multiplier) onlyOwner public {
        vars.Multiplier = _Multiplier;
    }
    function getMultiplier() public view returns(uint32 _Multiplier) {
        return vars.Multiplier;
    }
   
    function setDev(address payable _dev) onlyOwner public {
        Dev = _dev;
    }
    function getDev() public view returns(address _dev) {
        return Dev;
    }  
    function setROI(address payable _ROI) onlyOwner public {
        ROI = _ROI;
    }
    function getROI() public view returns(address _ROI) {
        return ROI;
    }  
    function random() internal returns (uint8) {
        uint result = uint(keccak256(abi.encodePacked(now, vars.nounce))) % 3;
        vars.nounce++;
        if (vars.nounce > 99999999) vars.nounce = 0;
        return uint8(result);
    }
    modifier onlyOwner(){
        require(msg.sender==_owner,'Not Owner');
        _;
    }  
    function getOwner() public view returns(address _oAddress) {
        return _owner;
    }
    function getOwnerBalance() public view returns(uint256 _balance) {
        return _owner.balance;
    }
    function getContractBalance() public view returns(uint256 _contractBalance) {    
        return address(this).balance;
    }
    function getContractBalanceUPDC() public view returns(uint256 _contractBalance) {    
        TokenContract token = TokenContract(TokenContractAddress);
        return token.balanceOf(address(this));
    }
    //Protect the pool in case of hacking
    function kill() onlyOwner public {
        _owner.transfer(address(this).balance);
        selfdestruct(_owner);
    }
    function transferFund(uint256 amount) onlyOwner public {
        require(amount<=address(this).balance,'exceed contract balance');
        _owner.transfer(amount);
    }
    function transferOwnership(address payable _newOwner) onlyOwner external {
        require(_newOwner != address(0) && _newOwner != _owner);
        _owner = _newOwner;
    }
}
contract TokenContract
{
    function getOwner() public returns(address);
    function transferFrom(address, address, uint256) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function balanceOf(address) external view returns (uint256);
    function allowance(address _owner, address _spender) public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function gettotalSupply() public returns(uint256);
}