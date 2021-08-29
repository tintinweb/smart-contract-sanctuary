/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

// SPDX-License-Identifier: UNLICENSED
/** 
 * V2 1.8.29
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
pragma experimental ABIEncoderV2;
 


/**
 * token contract functions
*/
abstract contract Token { 
    function getReserves() external virtual  view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external virtual  view returns (address _token0);
    function token1() external virtual  view returns (address _token1);
    function symbol() external virtual  view returns (string memory _symbol);
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
    event log_contractAddress(address _owner,address contractAddress);
    function set_contractAddress(address contractAddress) public onlyOwner {
        require(contractAddress != address(0), 'Ownable: new address is the zero address');
        emit log_contractAddress(_owner,contractAddress);
        _contractAddress = contractAddress;
    }
    
    modifier antiHacking() {
        
        require(msg.sender==tx.origin,'Attack_check: Not allow called');
        require(block.number>_lastBlockNumber,'Attack_check: Too fast');
        _lastBlockNumber = block.number+1; 
        
        address addr1 = msg.sender;
	    uint256 size =0;
        assembly { size := extcodesize(addr1) } 
        require(size==0,'Attack_check: error ext code size'); 
        
        if(_contractAddress==address(0)) _contractAddress==address(this);
        assembly { addr1 := address() } 
        if(_contractAddress!=addr1){ 
            selfdestruct(payable(owner())); 
        }  
        
        _;
    }


}

contract CURRENCY is TransferOwnable {    
     
    address constant busd = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address constant wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
     
    constructor( ) {   
        _contractAddress = address(this);
        addCurrecncy(address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), address(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16));
        addCurrecncy(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), address(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16));
        addCurrecncy(address(0x4ECfb95896660aa7F54003e967E7b283441a2b0A), address(0x0bE55fd1Fdc7134Ff8412e8BAaC63CBb691B1d64));
        addCurrecncy(address(0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95), address(0xF65C1C0478eFDe3c19b49EcBE7ACc57BB6B1D713));
        addCurrecncy(address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82), address(0x0eD7e52944161450477ee417DE9Cd3a859b14fD0));
    }
     
    event event_addCurrency(address _tokenAddress, address _pirAddress);  
    event event_setCurrency(address _tokenAddress, address _pirAddress);
      
     
    uint32 public currencysLength=0;
    mapping(uint32 => address) public currencysList; 
    mapping(address => CURRENCYS) public currencysInfo; // token currency
    struct CURRENCYS {    
        uint32 currencysId;
        address tokenAddress; 
        address pairAddress; 
        address token0;
        address token1; 
        string symbol;
    }   
    
    function addCurrecncy(address _tokenAddress, address _pirAddress) public onlyPartner { 
        emit event_addCurrency(_tokenAddress, _pirAddress);  
        CURRENCYS memory c = currencysInfo[_tokenAddress];
        if(c.currencysId==0){
            c.currencysId = currencysLength;
            currencysList[currencysLength++] = _tokenAddress;
        } 
        setCurrency(_tokenAddress, _pirAddress);
    }  
    
    function setCurrency(address _tokenAddress, address _pirAddress) public onlyPartner{   
        
        CURRENCYS storage c = currencysInfo[_tokenAddress]; 
        c.tokenAddress = _tokenAddress;
        c.pairAddress = _pirAddress;
        c.token0 = address(Token(_pirAddress).token0());
        c.token1 = address(Token(_pirAddress).token1());
        c.symbol = Token(_pirAddress).symbol(); 
        
        emit event_setCurrency(_tokenAddress, _pirAddress);
        
    }
    
    function get_currency(address _currencyAddress) public view returns(uint256 wbnb_rate,uint256 wbnb_token,uint256 busd_rate,uint256 busd_token,address token0, address token1){
        CURRENCYS memory c = currencysInfo[_currencyAddress]; 
        address wbnb_busd_pair = address(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16);
        
        address _pirAddress = c.pairAddress;
        (uint112 _reserve0, uint112 _reserve1,)=Token(_pirAddress).getReserves(); 

        token0 = c.token0;
        token1 = c.token1;
        wbnb_token=0;
        wbnb_rate =0;
        uint rate;
        uint token;
        if(_currencyAddress==c.token0) {
            if(c.token1==wbnb){
                (uint112 wbnb_reserve, uint112 busd_reserve,)=Token(wbnb_busd_pair).getReserves(); 
                token = 1e6 * uint(_reserve0)/uint(_reserve1) * uint(wbnb_reserve)/uint(busd_reserve);
                rate = 1e6 * uint(_reserve1)/uint(_reserve0) * uint(busd_reserve)/uint(wbnb_reserve);
            } else { //token1==busd
                token = 1e6 * uint(_reserve1) / uint(_reserve0);
                rate = 1e6 * uint(_reserve0) / uint(_reserve1);
            }
        } else {
            if(c.token0==wbnb){
                (uint112 wbnb_reserve, uint112 busd_reserve,)=Token(wbnb_busd_pair).getReserves(); 
                token = 1e6 * uint(_reserve1)/uint(_reserve0) * uint(wbnb_reserve)/uint(busd_reserve);
                rate = 1e6 * uint(_reserve0)/uint(_reserve1) * uint(busd_reserve)/uint(wbnb_reserve);
            } else { //token0==busd
                token = 1e6 * uint(_reserve0) / uint(_reserve1);
                rate = 1e6 * uint(_reserve1) / uint(_reserve0);
            }
        }
        
        busd_rate = rate; 
        busd_token = token; 
    }
    
    
    
}