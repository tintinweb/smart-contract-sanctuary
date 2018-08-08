pragma solidity ^0.4.23;

interface token {
    function promoCode() external returns (bytes16);
    function specialSend(uint amount, address buyer) external;
    function promoEthCommission() external returns (uint);
    function owner() external returns (address);
    function ethPromoHelpers(address input) external returns (address);
    function balanceOf(address who) external returns (uint256);
    function transfer(address receiver, uint amount) external;
}

contract UppercaseCheck {
    function areAllUppercase(bytes16 str) internal pure returns (bool) {
    if(str == 0){return false;}
    for (uint j = 0; j < 16; j++) {
    byte char = byte(bytes16(uint(str) * 2 ** (8 * j)));
    if (char != 0 && !((char >= 97) && (char <= 122))){return false;}}return true;}
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256){if(a == 0){return 0;}uint256 c = a * b;assert(c / a == b);return c;}
    function div(uint256 a, uint256 b) internal pure returns (uint256){return a / b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256){assert(b <= a);return a - b;}
    function add(uint256 a, uint256 b) internal pure returns (uint256){uint256 c = a + b;assert(c >= a);return c;}
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    mapping(address => address) ethPromoHelpers_;
    mapping(address => address) fishPromoHelpers_;
    
    uint256 totalSupply_;
    function totalSupply() public view returns (uint256) {return totalSupply_;}
    function ethPromoHelpers(address _input) public view returns (address) {return ethPromoHelpers_[_input];}
    function fishPromoHelpers(address _input) public view returns (address) {return fishPromoHelpers_[_input];}
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_to != address(this));
        require(ethPromoHelpers(_to) == 0 && fishPromoHelpers(_to) == 0);
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {return balances[_owner];}
}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_to != address(this));
        require(ethPromoHelpers(_to) == 0 && fishPromoHelpers(_to) == 0);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if(_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;} 
        else {allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);}
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Ownable {
    address owner_;
    constructor() public {owner_ = msg.sender;}
    modifier onlyOwner() {require(msg.sender == owner_);_;}
    function transferOwnership(address newOwner) public onlyOwner {require(newOwner != address(0));owner_ = newOwner;}
    function owner() public view returns (address) {return owner_;}
}

contract Factory is UppercaseCheck, StandardToken{
    
   uint contractCount = 0;
   bytes16[2][] ethReceived;
   mapping(bytes16 => address) promoCodeToContractAddress_;
   mapping(address => uint) contractAddressToIndex;
   
   function returnEthReceived() public view returns (bytes16[2][]){return ethReceived;}
   function promoCodeToContractAddress(bytes16 _input) public view returns (address){return promoCodeToContractAddress_[_input];}
   
   function getPromoCodeForEther(bytes16 PromoCode) external {
       require(areAllUppercase(PromoCode));
       require(promoCodeToContractAddress(PromoCode) == 0);
       address myContract = new PromoContract(PromoCode);
       promoCodeToContractAddress_[PromoCode] = myContract;
       ethPromoHelpers_[myContract] = msg.sender;
   }
   function getPromoCodeForFish(bytes16 PromoCode) external {
       require(areAllUppercase(PromoCode));
       require(promoCodeToContractAddress(PromoCode) == 0);
       address myContract = new PromoContract(PromoCode);
       promoCodeToContractAddress_[PromoCode] = myContract;
       fishPromoHelpers_[myContract] = msg.sender;
   }
}

contract Fish is Ownable, Factory{
     
    string public constant name = "Fish";
    string public constant symbol = "FISH";
    uint8 public constant decimals = 0;
    
    uint unitsOneEthCanBuy_ = 10000;
    uint promoFishCommission_ = 100;
    uint promoEthCommission_ = 40;
    uint promoBonus_ = 20;
    uint sizeBonus_ = 100;
    
    constructor() public{totalSupply_ = 0;}
    function unitsOneEthCanBuy() public view returns (uint) {return unitsOneEthCanBuy_;}
    function promoFishCommission() public view returns (uint) {return promoFishCommission_;}
    function promoEthCommission() public view returns (uint) {return promoEthCommission_;}
    function promoBonus() public view returns (uint) {return promoBonus_;}
    function sizeBonus() public view returns (uint) {return sizeBonus_;}
    function updateUnitsOneEthCanBuy(uint _unitsOneEthCanBuy) external onlyOwner {unitsOneEthCanBuy_ = _unitsOneEthCanBuy;}
    function updatePromoFishCommission(uint _promoFishCommission) external onlyOwner {promoFishCommission_ = _promoFishCommission;}
    function updatePromoEthCommission(uint _promoEthCommission) external onlyOwner {require(_promoEthCommission < 100);promoEthCommission_ = _promoEthCommission;}
    function updatePromoBonus(uint _promoBonus) external onlyOwner{promoBonus_ = _promoBonus;}
    function updateSizeBonus(uint _sizeBonus) external onlyOwner {sizeBonus_ = _sizeBonus;}

   function() payable public{
        owner().transfer(msg.value);
        if(unitsOneEthCanBuy() == 0){return;}
        uint256 amount =  msg.value.mul(unitsOneEthCanBuy()).mul(msg.value.mul(sizeBonus()).add(10**22)).div(10**40);
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalSupply_ = totalSupply_.add(amount);
        emit Transfer(address(this), msg.sender, amount); 
    }
    
   function getLostTokens(address _tokenContractAddress) public {
        if(token(_tokenContractAddress).balanceOf(address(this)) != 0){
        token(_tokenContractAddress).transfer(owner(), token(_tokenContractAddress).balanceOf(address(this)));}
   }
    
   function sendToken(address _to, uint _value) external onlyOwner {
        require(_to != address(0));
        require(_to != address(this));
        require(ethPromoHelpers(_to)==0 && fishPromoHelpers(_to)==0);
        balances[_to] = balances[_to].add(_value);
        totalSupply_ = totalSupply_.add(_value);
        emit Transfer(address(this), _to, _value); 
   }
   
   function delToken() external onlyOwner {
        totalSupply_ = totalSupply_.sub(balances[msg.sender]);
        emit Transfer(msg.sender, address(this), balances[msg.sender]); 
        balances[msg.sender] = 0;
   }
 
    function specialSend(uint amount, address buyer) external {
        require(ethPromoHelpers(msg.sender) != 0 || fishPromoHelpers(msg.sender) != 0);
        if(contractAddressToIndex[msg.sender] == 0){
        ethReceived.push([token(msg.sender).promoCode(),bytes16(amount)]);
        contractCount = contractCount.add(1);
        contractAddressToIndex[msg.sender] = contractCount;}
        else{ethReceived[contractAddressToIndex[msg.sender].sub(1)][1] = bytes16(  uint( ethReceived[contractAddressToIndex[msg.sender].sub(1)][1] ).add(amount));}
        if(unitsOneEthCanBuy() == 0){return;}
        uint amountFishToGive = amount.mul(unitsOneEthCanBuy()).mul(amount.mul(sizeBonus()).add(10**22)).mul(promoBonus().add(100)).div(10**42);
        balances[buyer] = balances[buyer].add(amountFishToGive);
        totalSupply_ = totalSupply_.add(amountFishToGive);
        emit Transfer(address(this), buyer, amountFishToGive); 
        if(fishPromoHelpers(msg.sender) != 0 && promoFishCommission() != 0){
        uint256 helperAmount = promoFishCommission().mul(amountFishToGive).div(100);
        balances[fishPromoHelpers_[msg.sender]] = balances[fishPromoHelpers(msg.sender)].add(helperAmount);
        totalSupply_ = totalSupply_.add(helperAmount);
        emit Transfer(address(this), fishPromoHelpers(msg.sender), helperAmount);}  
   }
}

contract PromoContract{
    using SafeMath for uint256;
    
    address masterContract = msg.sender;
    bytes16 promoCode_;
    
    constructor(bytes16 _promoCode) public{promoCode_ = _promoCode;}
    function promoCode() public view returns (bytes16){return promoCode_;}
    function() payable public{
        if(token(masterContract).ethPromoHelpers(address(this)) != 0 && token(masterContract).promoEthCommission() != 0){
        uint amountToGive = token(masterContract).promoEthCommission().mul(msg.value).div(100);
        token(masterContract).owner().transfer(msg.value.sub(amountToGive)); 
        token(masterContract).ethPromoHelpers(address(this)).transfer(amountToGive);}
        else{token(masterContract).owner().transfer(msg.value);}
        token(masterContract).specialSend(msg.value, msg.sender);
    }
}