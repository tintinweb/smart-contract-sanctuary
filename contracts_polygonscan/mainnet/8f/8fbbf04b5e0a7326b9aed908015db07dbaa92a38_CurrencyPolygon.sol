/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

// SPDX-License-Identifier: UNLICENSED
/** 
 * V2 1.8.31
 * telegram
 * Community
 * https://t.me/fruitsadventures_com
 * 
 * FruitsAdventures News & Announcements
 * https://t.me/fruitsadventures
 * 
 * twitter
 * https://twitter.com/FruitsAdventure
 *
 * medium
 * https://fruitsadventures.medium.com
*/

pragma solidity ^0.8.4; 
 
/**
 * token contract functions
*/
abstract contract Token { 
    function getReserves() external virtual  view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external virtual  view returns (address _token0);
    function token1() external virtual  view returns (address _token1);
    function symbol() external virtual  view returns (string memory _symbol);
    function decimals() external virtual  view returns (uint256 _decimals);
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
    address public _contractAddress;
    uint256 public _lastBlockNumber=0;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     constructor()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        _admin = address(0x39a73DB5A197d9229715Ed15EF2827adde1B0838);
        _partner = address(0x01d06F63518eA24808Da5A4E0997C34aF90495b4);
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

contract CurrencyPolygon is TransferOwnable {    
      
    address constant usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address constant wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address wmatic_usdc_pair = address(0x019011032a7ac3A87eE885B6c08467AC46ad11CD);
     
    constructor( ) {   
        _contractAddress = address(this);
        addCurrecncy(address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270), address(0x019011032a7ac3A87eE885B6c08467AC46ad11CD)); //wmatic
        addCurrecncy(address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174), address(0x019011032a7ac3A87eE885B6c08467AC46ad11CD)); //usdc
        addCurrecncy(address(0xA649325Aa7C5093d12D6F98EB4378deAe68CE23F), address(0x0359001070cF696D5993E0697335157a6f7dB289)); //bnb
        addCurrecncy(address(0x5d47bAbA0d66083C52009271faF3F50DCc01023C), address(0x034293F21F1cCE5908BC605CE5850dF2b1059aC0)); //Banana
    }
     
    event event_addCurrency(address _tokenAddress, address _pairAddress);  
    event event_setCurrency(address _tokenAddress, address _pairAddress);
      
     
    uint32 public currencysLength=0;
    mapping(uint32 => address) public currencysList; 
    mapping(address => CURRENCYS) public currencysInfo; // token currency
    struct CURRENCYS {    
        uint32 currencysId;
        address tokenAddress; 
        address pairAddress; 
        address token0;
        address token1; 
        uint256 decimals0;
        uint256 decimals1; 
        string symbol;
    }   
    
    function addCurrecncy(address _tokenAddress, address _pairAddress) public onlyPartner { 
        emit event_addCurrency(_tokenAddress, _pairAddress);  
        CURRENCYS memory c = currencysInfo[_tokenAddress];
        if(c.currencysId==0){
            c.currencysId = currencysLength;
            currencysList[currencysLength++] = _tokenAddress;
        } 
        setCurrency(_tokenAddress, _pairAddress);
    }  
    
    function setCurrency(address _tokenAddress, address _pairAddress) public onlyPartner{   
        
        CURRENCYS storage c = currencysInfo[_tokenAddress]; 
        c.tokenAddress = _tokenAddress;
        c.pairAddress = _pairAddress;
        c.token0 = address(Token(_pairAddress).token0());
        c.token1 = address(Token(_pairAddress).token1());
        c.decimals0 = Token(c.token0).decimals();
        c.decimals1 = Token(c.token1).decimals();
        c.symbol = Token(_pairAddress).symbol(); 
        
        emit event_setCurrency(_tokenAddress, _pairAddress);
        
    }
    function getReserves(address _pairAddress) internal view returns(uint112 _reserve0,uint112 _reserve1,uint256 symbol){
        address token0 = address(Token(_pairAddress).token0());
        address token1 = address(Token(_pairAddress).token1());
        uint decimals0 = Token(token0).decimals();
        uint decimals1 = Token(token1).decimals();
        (_reserve0, _reserve1,)=Token(_pairAddress).getReserves();  
        if(decimals0<18) {
            _reserve0 *= uint112(10 ** (18-decimals0));
        }
        if(decimals1<18) {
            _reserve1 *= uint112(10 ** (18-decimals1));
        }
        symbol = 0; 
    }
    
    function get_currency(address _currencyAddress) public view returns(uint256 wmatic_rate,uint256 wmatic_token,uint256 usdc_rate,uint256 usdc_token,address token0, address token1){
        CURRENCYS memory c = currencysInfo[_currencyAddress];  
        
        address _pairAddress = c.pairAddress;
        (uint112 _reserve0, uint112 _reserve1,)=getReserves(_pairAddress);  
         

        token0 = c.token0;
        token1 = c.token1;
        wmatic_token=0;
        wmatic_rate =0;
        uint rate;
        uint token;
        if(_currencyAddress==usdc) {
            rate = 1e6;
            token = 1e6;
            wmatic_token = 1e6 * uint(_reserve1) / uint(_reserve0);
            wmatic_rate = 1e6 * uint(_reserve0) / uint(_reserve1);
        } else if(_currencyAddress==wmatic) {
            wmatic_rate = 1e6;
            wmatic_token = 1e6;
            token = 1e6 * uint(_reserve0) / uint(_reserve1);
            rate = 1e6 * uint(_reserve1) / uint(_reserve0);
        } else if(_currencyAddress==c.token0) {
            if(c.token1==wmatic){
                (uint112 wmatic_reserve, uint112 usdc_reserve,)=getReserves(wmatic_usdc_pair); 
                token = 1e6 * uint(_reserve0)/uint(_reserve1) * uint(wmatic_reserve)/uint(usdc_reserve);
                rate = 1e6 * uint(_reserve1)/uint(_reserve0) * uint(usdc_reserve)/uint(wmatic_reserve);
                wmatic_rate = 1e6 * uint(_reserve1) / uint(_reserve0);
                wmatic_token = 1e6 * uint(_reserve0) / uint(_reserve1);
            } else { //token1==usdc
                token = 1e6 * uint(_reserve1) / uint(_reserve0);
                rate = 1e6 * uint(_reserve0) / uint(_reserve1);
                (uint112 wmatic_reserve, uint112 usdc_reserve,)=getReserves(wmatic_usdc_pair); 
                wmatic_token = 1e6 * uint(_reserve0)/uint(_reserve1) * uint(usdc_reserve)/uint(wmatic_reserve);
                wmatic_rate = 1e6 * uint(_reserve1)/uint(_reserve0) * uint(wmatic_reserve)/uint(usdc_reserve);
            }
        } else {
            if(c.token0==wmatic){
                (uint112 wmatic_reserve, uint112 usdc_reserve,)=getReserves(wmatic_usdc_pair); 
                token = 1e6 * uint(_reserve1)/uint(_reserve0) * uint(wmatic_reserve)/uint(usdc_reserve);
                rate = 1e6 * uint(_reserve0)/uint(_reserve1) * uint(usdc_reserve)/uint(wmatic_reserve);
                wmatic_rate = 1e6 * uint(_reserve0) / uint(_reserve1);
                wmatic_token = 1e6 * uint(_reserve1) / uint(_reserve0);
            } else { //token0==usdc
                token = 1e6 * uint(_reserve0) / uint(_reserve1);
                rate = 1e6 * uint(_reserve1) / uint(_reserve0);
                (uint112 wmatic_reserve, uint112 usdc_reserve,)=getReserves(wmatic_usdc_pair); 
                wmatic_token = 1e6 * uint(_reserve1)/uint(_reserve0) * uint(usdc_reserve)/uint(wmatic_reserve);
                wmatic_rate = 1e6 * uint(_reserve0)/uint(_reserve1) * uint(wmatic_reserve)/uint(usdc_reserve);
            }
        }
        
        usdc_rate = rate; 
        usdc_token = token; 
    }
    
    
    
}