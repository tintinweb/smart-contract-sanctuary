/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

pragma solidity 0.5.14;

interface LGCY {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 value) external returns(bool);
    function burn(address account, uint256 value) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);
        return a % b;
    }
}

contract LGCYstaking{
    using SafeMath for uint;
    
    address owner;
    address contractWallet;
    
    uint USDLPrice = 10000e6; // in LGCY decimals
    uint freezeTimeline = 10;
    
    uint freezeSequenceID;
    
    struct FreezeStruct{
        uint freeze;
        uint receivedLGCY;
        uint itimeLine;
        uint etimeLine;
        address holder;
        bool isFreezeExist;
    }
    
    mapping(address => mapping(uint => FreezeStruct)) public Freeze;
    
    LGCY public _LGCY;
    
    event FreezeEvent( address _addr, uint _freezeAmount, uint _receivedUSDL);
    event UnFreezeEvent( address _addr, uint _givenUSDL);
    
    constructor( address _LGCYToken) public {
        _LGCY =  LGCY(_LGCYToken);
        owner = msg.sender;
        contractWallet = address(this);
    }
    
    modifier OnlyOwner(){
        assert(msg.sender == owner);
        _;
    }
    
    function () external payable{
        
    }
    
    function updateLGCYPrice( uint _minTokens) public OnlyOwner returns(bool){
        assert(_minTokens > 0);
        USDLPrice = _minTokens;
        return true;
    }
    
    function updateFreezeTimeline( uint _freezeTimeline) public OnlyOwner returns(bool){
        assert(_freezeTimeline > 0);
        freezeTimeline = _freezeTimeline;
        return true;
    }
    
    // uint _freezeAmount
    function freeze( uint _lgcy) public returns(bool){
        assert(_LGCY.balanceOf(msg.sender) >= _lgcy);
        assert(_LGCY.allowance(msg.sender, address(this)) >= _lgcy);
        // assert(Freeze[msg.sender].freeze == 0);
        
        require(_LGCY.transferFrom(msg.sender, address(this), _lgcy));
        
        uint mining = calculateUSDLForLGCY( _lgcy);
        
        freezeSequenceID++;
        
        FreezeStruct memory _FreezeStruct;
        
        _FreezeStruct = FreezeStruct({
            freeze: _lgcy,
            receivedLGCY: mining,
            itimeLine: block.timestamp,
            etimeLine: block.timestamp.add(freezeTimeline),
            holder: msg.sender,
            isFreezeExist: true
        });
        
        Freeze[msg.sender][freezeSequenceID] = _FreezeStruct;

        msg.sender.transfer(mining);
        
        emit FreezeEvent( msg.sender, _lgcy, mining);
        
        return true;
    }
    
    function unfreeze(uint _freezeSequenceID) public payable returns(bool){
        assert(Freeze[msg.sender][_freezeSequenceID].holder == msg.sender);
        assert(Freeze[msg.sender][_freezeSequenceID].isFreezeExist);
        assert(Freeze[msg.sender][_freezeSequenceID].etimeLine < now);
        
        uint LGCYReceived = calculateUSDLForLGCY( Freeze[msg.sender][_freezeSequenceID].freeze);
        
        assert(msg.value == LGCYReceived);
        
        burnTheSupplies( msg.sender, _freezeSequenceID);
        
        emit UnFreezeEvent( msg.sender, LGCYReceived);
        
        return true;
    }
    
    function calculateUSDLForLGCY( uint _lgcy) public view returns(uint _mining){
        _mining = _lgcy.mul(1e6).div(USDLPrice);
    }
    
    function burnTheSupplies( address _owner, uint _freezeSequenceID) internal returns(bool){
        assert(_LGCY.transfer(msg.sender, Freeze[_owner][_freezeSequenceID].freeze));
        
        Freeze[_owner][_freezeSequenceID].isFreezeExist = false;
        
        return true;
    }
    
    function getContractBalance() public view returns(uint){
        return contractWallet.balance;
    }
 
}