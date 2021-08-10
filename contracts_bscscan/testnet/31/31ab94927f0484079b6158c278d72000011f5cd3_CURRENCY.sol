/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: UNLICENSED
/** 
 * ver 1.8.101
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
        _partner = address(0x766a7857764D74C364F1644c6B0AbE9f1dCE148e);
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
    address constant busd2 = address(0xf0F8e42720672aFF4923975118efc9E942A29A2f);
    address constant wbnb2 = address(0xCB8945C9c4666037EE3327D83820b57EdBBa2710); 
    
    uint internal seed;
    uint internal randNonce;
    constructor( ) {   
        _contractAddress = address(this);
    }
     
    event event_setCURRENCY(address _tokenAddress, address _pirAddress); 
    event event_currency(address _tokenAddress, uint256 wbnb_rate, uint256 wbnb_busd, uint256 wbnb_token, uint256 busd_token);
         
    
    function randomize(uint _min, uint _max) public  returns (uint) { 
        randNonce ++;
        randNonce = randNonce % 32767;
        seed = uint(keccak256(abi.encode(seed, block.difficulty, block.number, block.coinbase, randNonce, block.timestamp)));  
        return _min + (seed % (_max - _min) );
    }
    
    function get_seed() public  returns (uint) { 
        randNonce ++;
        randNonce = randNonce % 32767;
        seed = uint(keccak256(abi.encode(seed, block.difficulty, block.number, block.coinbase, randNonce, block.timestamp)));  
        return seed;
    }
    
     
    uint32 public currencysLength=0;
    mapping(uint32 => address) public currencysList; 
    mapping(address => CURRENCYS) public currencysInfo; // token currency
    struct CURRENCYS {    
        uint32 currencysId;
        address tokenAddress; 
        address pairAddress; 
        address token0;
        address token1;
        uint112 _reserve0;
        uint112 _reserve1;
        uint256 wbnb_rate;
        uint256 wbnb_token;
        uint256 busd_rate;
        uint256 busd_token;
        string symbol;
    }     
    function setCURRENCY(address _tokenAddress, address _pirAddress) public onlyPartner { 
        emit event_setCURRENCY(_tokenAddress, _pirAddress);  
        CURRENCYS storage wbnb_info = currencysInfo[wbnb];
        if(wbnb_info.busd_rate==0) {
            wbnb_info.wbnb_rate=1e6;
            wbnb_info.wbnb_token=1e6;
            wbnb_info.busd_rate=1e6;
            wbnb_info.busd_token=1e6;
        }
        CURRENCYS storage busd_info = currencysInfo[busd];
        if(busd_info.busd_rate==0) {
            busd_info.wbnb_rate=1e6;
            busd_info.wbnb_token=1e6;
            busd_info.busd_rate=1e6;
            busd_info.busd_token=1e6;
        }
        
        CURRENCYS storage c = currencysInfo[_tokenAddress];
        (c._reserve0, c._reserve1,)=Token(_pirAddress).getReserves(); 
        c.tokenAddress = _tokenAddress;
        c.pairAddress = _pirAddress;
        c.token0 = address(Token(_pirAddress).token0());
        c.token1 = address(Token(_pirAddress).token1());
        c.symbol = Token(_pirAddress).symbol();
        uint256 r0=0;
        uint256 r1=0;
        if(c.token0==_tokenAddress){
            r0 = uint256(c._reserve0);
            r1 = uint256(c._reserve1);
        } else {
            r1 = uint256(c._reserve0);
            r0 = uint256(c._reserve1);
        }
        
        
        if(c.token0==busd || c.token0==busd2 || c.token1==busd || c.token1==busd2){
            if(c.tokenAddress==busd || c.tokenAddress==busd2){
                c.busd_rate = uint256(1e6);  
                c.busd_token = uint256(1e6);  
                if(c.token0==wbnb || c.token0==wbnb2 || c.token1==wbnb || c.token1==wbnb2){
                    //BUSD_r0-WBNB
                    c.wbnb_rate = uint256(1e6 * r0 / r1);
                    c.wbnb_token = uint256(1e6 * r1 / r0); // WBNB per BUSD_r0
                } else {
                    require(false,'not allow, just BUSD-WBNB');
                    // BUSD_r0-FRUIT undefine 
                    // must set vy FRUIT-BUSD just allow BUSD-WBNB
                }
            } else if(c.tokenAddress==wbnb || c.tokenAddress==wbnb2){
                c.wbnb_rate = uint256(1e6);
                c.wbnb_token = uint256(1e6);
                //WBNB-BUSD_r1
                c.busd_rate = uint256(1e6 * r1 / r0);
                c.busd_token = uint256(1e6 * r0 / r1); // WBNB per BUSD_r1
            } else {
                //otherTOKEN-BUSD_r1
                c.busd_rate = uint256(1e6 * r0 / r1);
                c.busd_token = uint256(1e6 * r1 / r0);
                c.wbnb_rate = uint256(1e6 * r0 / (busd_info.wbnb_token * r1 / 1e6) );
                c.wbnb_token = uint256(1e6 * (busd_info.wbnb_token * r1/1e6) / r0);
            } 
        } else if(c.token0==wbnb || c.token0==wbnb2 || c.token1==wbnb || c.token1==wbnb2){
            //otherTOKEN-WBNB_r1
            c.wbnb_rate = uint256(1e6 * r0 / r1);
            c.wbnb_token = uint256(1e6 * r1 / r0);
            c.busd_rate = uint256(1e6 * r0 / (wbnb_info.busd_token * r1 / 1e6) );
            c.busd_token = uint256(1e6 * (wbnb_info.busd_token * r1/1e6) / r0);
        } else {
            //otherToken-otherToken
            require(false,'not allow, must include BUSD or WBNB');
        }
        
        if(c.currencysId==0){
            c.currencysId = currencysLength;
            currencysList[currencysLength++] = _tokenAddress;
        } 
        emit event_currency(_tokenAddress,c.wbnb_rate,c.busd_rate,c.wbnb_token,c.busd_token);
        
    }
    
}