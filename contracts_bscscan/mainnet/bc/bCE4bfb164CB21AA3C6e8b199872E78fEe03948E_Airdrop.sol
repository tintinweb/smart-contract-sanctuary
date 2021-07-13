/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

/**
 *
 * 
 * 
 * 
 * 
 * 
    ____      _____   ______     ______     ______       ____     _____      
  (    )    (_   _) (   __ \   (_  __ \   (   __ \     / __ \   (  __ \     
  / /\ \      | |    ) (__) )    ) ) \ \   ) (__) )   / /  \ \   ) )_) )    
 ( (__) )     | |   (    __/    ( (   ) ) (    __/   ( ()  () ) (  ___/     
  )    (      | |    ) \ \  _    ) )  ) )  ) \ \  _  ( ()  () )  ) )        
 /  /\  \    _| |__ ( ( \ \_))  / /__/ /  ( ( \ \_))  \ \__/ /  ( (         
/__(  )__\  /_____(  )_) \__/  (______/    )_) \__/    \____/   /__\        
                                                                            
 
 
 
 
     gg                                                                     ,ggggggggggg,                                              
    dP8,                                                                   dP"""88""""""Y8,                                            
   dP Yb                                                                   Yb,  88      `8b                                            
  ,8  `8,                                                                   `"  88      ,8P                                            
  I8   Yb                                                                       88aaaad8P"                                             
  `8b, `8,     ,gggg,gg   ,ggg,,ggg,,ggg,    ,ggg,,ggg,,ggg,     ,gggg,gg       88""""Y8ba  ,ggg,     ,gggg,gg   ,ggg,,ggg,     ,g,    
   `"Y88888   dP"  "Y8I  ,8" "8P" "8P" "8,  ,8" "8P" "8P" "8,   dP"  "Y8I       88      `8bi8" "8i   dP"  "Y8I  ,8" "8P" "8,   ,8'8,   
       "Y8   i8'    ,8I  I8   8I   8I   8I  I8   8I   8I   8I  i8'    ,8I       88      ,8PI8, ,8I  i8'    ,8I  I8   8I   8I  ,8'  Yb  
        ,88,,d8,   ,d8b,,dP   8I   8I   Yb,,dP   8I   8I   Yb,,d8,   ,d8b,      88_____,d8'`YbadP' ,d8,   ,d8b,,dP   8I   Yb,,8'_   8) 
    ,ad88888P"Y8888P"`Y88P'   8I   8I   `Y88P'   8I   8I   `Y8P"Y8888P"`Y8     88888888P" 888P"Y888P"Y8888P"`Y88P'   8I   `Y8P' "YY8P8P
  ,dP"'   Yb                                                                                                                           
 ,8'      I8                                                                                                                           
,8'       I8                                                                                                                           
I8,      ,8'                                                                                                                           
`Y8,___,d8'                                                                                                                            
  "Y888P"                                                                                                                              


          Jamma Beans will be used at the entry point of the GAME.
          50% will be added to the pancake swap LP.
          25% will be burnt.
          21% will be used in the air drops.
          2% Marketing fund.
          2% Dev fund.
          
          JammaBeans.com
          https://t.me/jammabeans
          https://t.me/JammaBeansEnglish
          https://twitter.com/beansjamma
          https://discord.gg/T9avyYAbbN
          
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Airdrop is Ownable {
    address public _JammaAddress; 
    mapping (address => uint256) public _TimeTellNextDrop;
    uint256 public AirdropAmount;
    uint256 public AirdropDelay;
    event AirdropSent(address sender , uint amount);
    constructor (){
        
     AirdropAmount = 4000000000000000;
     AirdropDelay = 86400;
    }
    function setJammaAddress(address _address) public onlyOwner {
        _JammaAddress = _address;
    }
    function setAirDropAmount(uint256 _amount) public onlyOwner {
        AirdropAmount = _amount;
    }
    function setAirDropDelay(uint256 _delay) public onlyOwner {
        AirdropDelay = _delay;
    }
  
    modifier OncePerDay() {
        require(_TimeTellNextDrop[msg.sender] <= block.timestamp, "Only one airdrop per day");
        _;
    }
    function ClaimAirdrop() public OncePerDay returns (bool){
        address Sender = msg.sender; 
        _TimeTellNextDrop[Sender] = block.timestamp + AirdropDelay;
       bool sent = IERC20(_JammaAddress).transfer(Sender,AirdropAmount);
       require (sent, "transaction failed");
        emit AirdropSent(Sender , AirdropAmount);
        return true;
    }
   
}