/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;
// ver 1.8.31
// V1

/**
 * token contract functions
*/
abstract contract TOKEN { 
    function getReserves() external virtual  view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external virtual  view returns (address _token0);
    function token1() external virtual  view returns (address _token1);
    function balanceOf(address who) external virtual  view returns (uint256);
    function approve(address spender, uint256 value) external virtual  returns (bool); 
    function allowance(address owner, address spender) external virtual  view returns (uint256);
    function transfer(address to, uint256 value) external virtual  returns (bool);
    function transferExtent(address to, uint256 tokenId, uint256 Extent) external virtual  returns (bool);
    function transferFrom(address from, address to, uint256 value) external virtual  returns (bool);
    function transferFromExtent(address from, address to, uint256 tokenId, uint Extent) external virtual  returns (bool); 
    function balanceOfExent(address who, uint256 tokenId) external virtual  view returns (uint256);
}
  

// 
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract TransferOwnable {
    address private _owner;
    address private _admin;
    address private _partner;
    address public _contractAddress=address(0);
    uint256 public _lastBlockNumber=0;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event log_contractAddress(address indexed Owner, address indexed contractAddress);
 
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     constructor()   {
        address msgSender = msg.sender;
        _owner = msgSender;
        _admin = address(0);
        _partner = address(0);
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
    modifier onlyAdmin() {
        require(_owner == msg.sender || _admin == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
    modifier onlyPartner() {
        require(_owner == msg.sender || _admin == msg.sender || _partner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
    
    function isPartner(address _address) public view returns(bool){
        if(_address==_owner || _address==_admin || _address==_partner) return true;
        else return false;
    } 
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function transferOwnership_admin(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_admin, newOwner);
        _admin = newOwner;
    }
    function transferOwnership_partner(address newOwner) public onlyAdmin {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_partner, newOwner);
        _partner = newOwner;
    }
    function set_contractAddress(address contractAddress) public onlyOwner {
        require(contractAddress != address(0), 'Ownable: new owner is the zero address');
        emit log_contractAddress(_owner,contractAddress);
        _contractAddress = contractAddress;
    }


}

contract AirdropWithdraw is TransferOwnable {   
    
    constructor() payable { 
        _contractAddress = address(this);
    }
    
    event log_add_withdraw_address(address _address);
    event log_leadout_withdraw_address(address _address);
    event log_set_withdrawAmount(uint256 _amount);
    event log_set_withdrawToken(address _token); 
    event log_withdraw(address _from, address _token, uint256 _amount); 
    event Donate_amount(address _from, uint256 _value);
    event log_Partner_withdraw_BNB(address sender,address withdrawToken, uint256 _amount); 
    event log_attack_address(address attack_address);
    event log_contractAddress(address contractAddress);
    
    //address public withdrawToken = 0x53344C813FbC35890A7304187Dc920358B5ACF4A; 
    address public withdrawToken = 0x4ECfb95896660aa7F54003e967E7b283441a2b0A; 
    address public withdrawPublicKey = 0x50308f467E05C7b503eb834f168D5BE4e4852021;
    address public withdrawAddress =  address(this);

    mapping(address => uint) public userTimestamp;
     
     
    receive() external payable { }
    
    
    function Donate() external payable {    
        emit Donate_amount(msg.sender, msg.value);
    }
    function Partner_withdraw_BNB(uint256 _amount) public onlyPartner { 
        payable(msg.sender).transfer(_amount);  
        emit log_Partner_withdraw_BNB(msg.sender,withdrawToken,_amount);
    }  
    
    function set_withdrawAddress(address _address) public onlyPartner { 
        withdrawAddress = _address; 
    }
    function set_withdrawPublicKey(address _withdrawPublicKey) public onlyPartner { 
        withdrawPublicKey = _withdrawPublicKey; 
    }
    function set_withdrawToken(address _token) public onlyPartner { 
        withdrawToken = _token;
        emit log_set_withdrawToken(_token);
    }
    function set_userTimestamp(address _address,uint256 _timestamp) public onlyPartner { 
        userTimestamp[_address] = _timestamp;
    }
 
    function PartnerWithdrawToken(address _tokenAddress) external onlyPartner {   
        uint256 balance256 = TOKEN(_tokenAddress).balanceOf(address(this));   
        TOKEN(_tokenAddress).transfer(msg.sender, balance256);  
    } 
    function PartnerWithdrawEmergency() external onlyPartner {     
        uint256 balance256 = TOKEN(withdrawToken).balanceOf(address(this));   
        TOKEN(withdrawToken).transfer(msg.sender, balance256);    
    } 
    function PartnerWithdrawETH() external onlyAdmin {   
        uint256 _amount = address(this).balance; 
        require(_amount>0, "PartnerWithdrawETH: no BNB balance.");
        (bool success,) = msg.sender.call{value:_amount}(new bytes(0)); 
        require(success, "PartnerWithdrawETH: call BNB fail.");
    }
    
   
    bytes32 public hash;
    bytes32 public hash2;
    address public ec_recover;
    function withdraw(uint256 _to,uint256 _timestamp, uint256 _amount, uint256 _dateline, uint256 _r,uint256 _s, uint256 _v) external{ 
        
        require(_amount>0,'withdraw:require _amount>0'); 
        require(_to==uint256(uint160(msg.sender)),'withdraw:require to==msg.sender'); 
        require(_dateline>block.timestamp,'withdraw:require _dateline>block.timestamp'); 
        require(_dateline>_timestamp,'withdraw:require _dateline>_timestamp');
        require(_timestamp>userTimestamp[msg.sender],'withdraw:Cannot claim repeatedly');
        uint256 tokenBalance = TOKEN(withdrawToken).balanceOf(withdrawAddress);  
        require(tokenBalance>=_amount,'withdraw:require tokenBalance>=_amount'); 
        userTimestamp[msg.sender]=_timestamp;
        
        hash2= keccak256(abi.encodePacked(_to, _timestamp, _amount, _dateline));
        hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash2));
        ec_recover = ecrecover(hash, uint8(_v), bytes32(_r), bytes32(_s));
        require(ec_recover==withdrawPublicKey,'withdraw:require ec_recover==withdrawPublicKey');  
        if(withdrawAddress == address(this)){
            TOKEN(withdrawToken).transfer(msg.sender,_amount);    
        } else {
            TOKEN(withdrawToken).transferFrom(withdrawAddress,msg.sender,_amount);    
        }
        
    } 
     
    
}