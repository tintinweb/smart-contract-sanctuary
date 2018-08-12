pragma solidity 0.4.24;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract ERC20Basic {
  
  function transfer(address to, uint256 value) public returns (bool);
  
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract payMoney is Ownable{
    event TransferFail(uint256 index, address receiver, uint256 amount);
    event EtherPay(uint256 balance,address[] addressList,uint256[] ratioList);
    event UpdateShare(address[] addressList,uint256[] ratioList);
    event TokenTransfer(address token, address owner, uint256 amount);

    using SafeMath for uint256;
    mapping (address => bool) private isAdmin;
    mapping (address => uint256) private payRatio;

    uint256 constant public GAS_PER_SPLIT_IN_SPLITALL = 10000;
  
    address[] private addressList;
    uint256[] private ratioList;
    address feeWallet; 
    uint256 private OtherAdminCount;
    uint256 private adminFee =  1*(10 **16);//0.01 = 10**16 ,0.1 = 10 ** 17 
    uint256 totalRatio;
    uint256 private addressCount = 0;
    uint256 private balance = 0;
    
    modifier onlyAdmin {
        require(msg.sender == owner || isAdmin[msg.sender]);
        _;
    }

    constructor(address[] _addressList, uint[] _ratio, uint _size, address _adminWallet) public {
        require(_addressList.length==_ratio.length);
        addressList.length = _size;
        ratioList.length = _size;
        addressCount = 0;
        OtherAdminCount = 0;
        totalRatio = 0;
        feeWallet = _adminWallet;
        for (uint256 i = 0; i < _size; i ++) {
            payRatio[_addressList[i]] = _ratio[i];
            addressList[i] = _addressList[i];
            ratioList[i] = _ratio[i];
            totalRatio = totalRatio.add(_ratio[i]);
            addressCount++;
        }
    }

    function ()public payable{
        balance.add(msg.value);
    }
    //admin
    function payEther() external onlyAdmin{
        require(address(this).balance > adminFee);
        uint256 amount = address(this).balance;
        uint256 last = 0;
        uint256 minerFee = GAS_PER_SPLIT_IN_SPLITALL.mul(tx.gasprice);
        for(uint256 i = 0; i < addressCount; i ++){
            uint256 temp =amount.mul(payRatio[addressList[i]]).div(totalRatio).sub(minerFee).sub(adminFee);
            last = last.add(temp);
            if (!addressList[i].send(temp)) {
                emit TransferFail(i, addressList[i], temp);
                return ;
            }
        }
        emit EtherPay(balance,addressList,ratioList);
        feeWallet.transfer(adminFee.sub(minerFee).mul(addressCount));
        last =last.add(adminFee.sub(minerFee).mul(addressCount));
        msg.sender.transfer(amount.sub(last));
    }
    //owner
    function updateShare(address[] _addressList, uint[] _ratio, uint _size) external onlyOwner{
        require(_addressList.length==_ratio.length);
        addressList.length = _size;
        ratioList.length = _size;
        addressCount = 0;
        totalRatio = 0;
        for (uint256 i = 0; i < _size; i ++) {
            payRatio[_addressList[i]] = _ratio[i];
            addressList[i] = _addressList[i];
            ratioList[i] = _ratio[i];
            totalRatio = totalRatio.add(_ratio[i]);
            addressCount++;
        }
        emit UpdateShare(addressList,ratioList);
    }

    //owner
    function transferToken(address token,uint256 amount) external onlyOwner{
      require(amount > 0);
      require(ERC20Basic(token).transfer(msg.sender,amount));
      emit TokenTransfer(token,msg.sender,amount);
    }
    //owner
    function addAdmin(address newAdmin) external onlyOwner{
      isAdmin[newAdmin] = true;
    }
    //owner
    function removeAdmin(address removedAddress) external onlyOwner{
      isAdmin[removedAddress] = false;
    }
    //owner
    function updateAdminFee(uint _newFee)external onlyOwner{
      adminFee = _newFee;
    }

    //admin
    function getBalance() view public  onlyAdmin returns (uint){
      return address(this).balance;
    }
    //admin
    function getAddressCount() view public onlyAdmin returns (uint){
      return addressCount;
    }
    //admin
    function getAddressRatio(address _input) view public onlyAdmin returns (uint){
      return payRatio[_input];
    }
    //admin
    function checkAdmin(address _checkAddress) view public returns (bool){
      return isAdmin[_checkAddress];
    }
    //admin
    function getShareList() view public onlyAdmin  returns (address[]){
      return addressList;
    }
    //admin
    function getOwner() view public returns(address){
      return owner;
    }
    //admin
    function getRatioList() view public onlyAdmin returns (uint[]){
      return ratioList;
    }
    
}