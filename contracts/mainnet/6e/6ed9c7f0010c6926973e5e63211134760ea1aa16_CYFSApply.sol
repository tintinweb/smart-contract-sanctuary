pragma solidity ^0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


pragma experimental ABIEncoderV2;
contract CYFSApply is Ownable {
    struct ApplyInfo {
        string email;
        string desc;
        string phone;
        uint balance;
        bool select;
        bool refund;
        address addr;
    }
    
    mapping(address => ApplyInfo) public applyList;
    address[] userList;
    address centre;
    
    function setCentre(address c) public onlyOwner {
        centre = c;
    }
    
    function getCentre() public view returns (address){
        return centre;
    }
    
    function apply(string email, string phone, string desc, address addr) public payable {
        require(applyList[addr].balance == 0);
        require(centre == msg.sender);

        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(addr)}
        require(_codeLength == 0, "sorry humans only");

        applyList[addr] = ApplyInfo({ 
            email: email, 
            desc: desc, 
            phone: phone, 
            balance: 
            msg.value, 
            select: false, 
            addr: addr,
            refund: false
        });
        userList.push(addr);
    }

    function getApply(address addr) public view returns (ApplyInfo) {
        return applyList[addr];
    }
    
    function select(address[] addr, bool sel) public onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            require(applyList[addr[i]].balance > 0);
            applyList[addr[i]].select = sel;    
        }
    }
    
    function refund(uint fee) public onlyOwner {
        for (uint i = 0; i < userList.length; i++) {
            ApplyInfo storage applyInfo = applyList[userList[i]];
            if (!applyInfo.refund) {
                applyInfo.refund = true;

                if (applyInfo.select) { 
                    applyInfo.addr.transfer(applyInfo.balance - fee);
                    applyInfo.balance = fee;
                } else {
                    if (applyInfo.balance > 0) {
                        applyInfo.addr.transfer(applyInfo.balance);
                        applyInfo.balance = 0;
                    }
                    
                }
            }
            
        }
    }
    
    function withdraw() public onlyOwner {
        uint balance = 0;
        for (uint i = 0; i < userList.length; i++) {
            ApplyInfo storage applyInfo = applyList[userList[i]];
            balance = balance + applyInfo.balance;
            applyInfo.balance = 0;
        }
        if (balance > 0) {
            owner.transfer(balance);
        }
        
    }
}