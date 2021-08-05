pragma solidity >=0.6.0 <0.8.0;

import "ERC20.sol";
import "Ownable.sol";


contract V3Token is ERC20,Ownable {
    
    address public adminAddr;
    mapping(address=>uint256) map_eth; 
    
    event receive_pay(address sender_, uint256 amount_);
    event fallback_pay(address sender_,uint256 amount_);
    event withdraw_eth(address target_,uint256 amount_);
    
    constructor(string memory name_, string memory symbol_,uint256 total) public ERC20(name_, symbol_) {
        _setupDecimals(6);
        _mint(msg.sender, total* 10 ** uint256(decimals()));
         adminAddr = msg.sender;
    }
    
    modifier isAdmin() {
        require(msg.sender == adminAddr);
        _;
    }
    
    fallback() external payable {
        emit fallback_pay(msg.sender, msg.value);
    }
    
    receive() external payable {
        map_eth[msg.sender] = msg.value;
        emit receive_pay(msg.sender, msg.value);
    }
    
    function setAdmin(address newAdmin_) external onlyOwner {
        require(newAdmin_ != address(0),"invaild admin address");
        adminAddr = newAdmin_;
    }
    
    function withdrawEther() public payable isAdmin{
        
        address payable target = address(uint160(adminAddr));
        target.transfer(msg.value);
        emit withdraw_eth(target,msg.value);
    }
    
    function balanceOfEther() public view returns (uint256){
       return address(this).balance;
    }
    
    
    
    
}
