/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
 * token contract functions
*/
abstract contract Token { 
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     constructor() internal  {
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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


}

contract AirdropWithdraw is TransferOwnable {   
    
    constructor( ) public payable {   
        transferOwnership_admin(address(0x39a73DB5A197d9229715Ed15EF2827adde1B0838));
        transferOwnership_partner(address(0x1999E454be73Bc3842b0855Eb83Ef7D880bF8C43));
    }
    
    event log_add_withdraw_address(address _address);
    event log_leadout_withdraw_address(address _address);
    event log_set_withdrawAmount(uint256 _amount);
    event log_set_withdrawToken(address _token); 
    event log_withdraw(address _from, address _token, uint256 _amount); 
    event Donate_amount(address _from, uint256 _value);
    event log_Partner_withdraw_BNB(address sender,address withdrawToken, uint256 _amount); 
    
    //address public airdropAddress = 0x3c7631DCD85Dfe994096cF1c3e26B81c38DaA2A4;
    //address public withdrawToken = 0x4ECfb95896660aa7F54003e967E7b283441a2b0A;
    address public airdropAddress = 0x288aE6c4fcB11771359f9Ee33855043E76C0a8fa;
    address public withdrawToken = 0x31508f0098A2566074EcCC94a0900721386D0C4b;
    uint public withdrawAmount = 300*10**18;
    uint private withdrawPassword = 32767;
    uint32 public withdrawLength = 0;
    uint32 public addressLength = 0;
    mapping(address => uint) public addressInfo;
     
     
    receive() external payable { }
    
    
    function Donate() external payable {    
        emit Donate_amount(msg.sender, msg.value);
    }
 
    function get_withdrawPassword() public view returns(uint256) { 
        require(isPartner(msg.sender));
        return withdrawPassword;
    }
    function get_addressPassword(address _address) public view returns(uint256) { 
        require(isPartner(msg.sender));
        return uint256(_address)*withdrawPassword; 
    }
    function set_airdropAddress(address _address) public onlyPartner { 
        airdropAddress = _address; 
    }
    function set_withdrawPassword(uint256 _amount) public onlyPartner { 
        withdrawPassword = _amount; 
    }
    function set_withdrawAmount(uint256 _amount) public onlyPartner { 
        withdrawAmount = _amount;
        emit log_set_withdrawAmount(_amount);
    }
    function set_withdrawToken(address _token) public onlyPartner { 
        withdrawToken = _token;
        emit log_set_withdrawToken(_token);
    }
    function add_withdraw_address(address[] memory _address) public onlyPartner { 
        for(uint i=0; i<_address.length;i++){
            address addr = _address[i];
            if(addressInfo[addr]==1){
                emit log_add_withdraw_address(addr);
            } else {
                addressInfo[addr] = 0; 
                addressLength++;
            }
        }
    }
  
    function leadout_withdraw_address(address[] memory _address) public onlyPartner { 
        for(uint i=0; i<_address.length;i++){
            address addr = _address[i];
            if(addressInfo[addr]==0){
                emit log_leadout_withdraw_address(addr);
            } else {
                addressInfo[addr] = 1; 
                addressLength--;
            }
        }
    } 
    
     
    function Partner_withdraw_BNB(uint256 _amount) public onlyPartner { 
        msg.sender.transfer(_amount);  
        emit log_Partner_withdraw_BNB(msg.sender,withdrawToken,_amount);
    }  
    
    function withdraw(uint256 _password) external { 
        uint256 password = uint256(msg.sender)*withdrawPassword;
        require(_password==password,'withdraw: error password');
        require(addressInfo[msg.sender]==0,'withdraw: address not allow');  
        require(Token(withdrawToken).transferFrom(airdropAddress, msg.sender, withdrawAmount));
        addressInfo[msg.sender] = 1; 
        emit log_withdraw(msg.sender, withdrawToken, withdrawAmount);  
        withdrawLength++;
    } 
     
    
}