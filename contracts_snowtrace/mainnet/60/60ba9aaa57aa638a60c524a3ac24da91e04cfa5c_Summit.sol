/**
 *Submitted for verification at snowtrace.io on 2021-12-21
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract Summit is Ownable {

    address public MIM;
    uint public maxWLsale;
    uint public maxPublicSale;
    bool public presaleActive;
    bool public presalePublic;
    uint public whitelistsQ;
    uint public maxSold;
    uint public price;
    uint public sold;
    uint public claimRatio;
    address public snow;
    bool public claimingActive;

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public blacklisted;
    mapping(address => uint) public invested;
    mapping(address => bool) public claimed;

    modifier onlyWhitelisted(){
        require(whitelisted[msg.sender]==true);
        _;
    }

    constructor(){
        maxSold = 100000e18;
        maxWLsale = 200e18;
        maxPublicSale = 100e18;
        price = 5;
        claimRatio = 10;
        MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;//avax mainnet mim 
    }

    function buySnow(uint256 amount) external {
        require(presaleActive,"presale has ended");
        require(!blacklisted[msg.sender],"blacklisted");
        require(amount+sold <= maxSold);
        if(whitelisted[msg.sender]){
            require(amount+invested[msg.sender]<=maxWLsale,"exceeds max contribution");    
        } else if (presalePublic) {
            require(amount+invested[msg.sender]<=maxPublicSale,"exceeds max contribution");
        }
        IERC20(MIM).transferFrom(msg.sender, address(this), amount*price);
        invested[msg.sender]+=amount;
        sold+=amount;
    }

    function claimSnow() public {
        require(claimingActive, "cannot claim yet");
        require(!claimed[msg.sender], "already claimed");
        require(!blacklisted[msg.sender], "blacklisted");
        IERC20(snow).transfer(msg.sender, invested[msg.sender]*claimRatio/10);
        claimed[msg.sender] = true;
    }

    function addToWhitelist(address[] memory addresses) external onlyOwner returns(uint quantityOfAddedAddresses){
        uint quantity = 0;
        for(uint i=0;i<addresses.length;i++){
            if(!whitelisted[addresses[i]]) {
                whitelisted[addresses[i]]=true;
                quantity++;
            }
        }
        whitelistsQ+=quantity;
        require(whitelistsQ<=500);
        return quantity;
    }

    function removeFromWhitelist(address[] memory addresses) external onlyOwner returns(uint quantityOfRemovedWhitelists){
        uint quantity = 0;
        for(uint i=0;i<addresses.length;i++){
            if(whitelisted[addresses[i]]) {
                delete whitelisted[addresses[i]];
                quantity++;
            }
        }
        whitelistsQ-=quantity;
        return quantity;
    }

    function addToBlacklist(address[] memory addresses) external onlyOwner returns(uint quantityOfRemovedWhitelists){
        uint quantity = 0;
        for(uint i=0;i<addresses.length;i++){
            if(!blacklisted[addresses[i]]) {
                blacklisted[addresses[i]]=true;
            }
            if(whitelisted[addresses[i]]) {
                delete whitelisted[addresses[i]];
                quantity++;
            }
        }
        whitelistsQ-=quantity;
        return quantity;
    }

    function removeFromBlacklist(address[] memory addresses) external onlyOwner returns(uint quantityOfRemovedBlacklists){
        uint quantity = 0;
        for(uint i=0;i<addresses.length;i++){
            if(blacklisted[addresses[i]]) {
                delete blacklisted[addresses[i]];
                quantity++;
            }
        }
        return quantity;
    }

    function withdrawForLiquidity() external onlyOwner {
        require(presaleActive==false);
        if(IERC20(MIM).balanceOf(address(this))>0){
            IERC20(MIM).transfer(msg.sender, IERC20(MIM).balanceOf(address(this)));    
        }
        if(address(this).balance>0){
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function setClaimingActive(address a,uint claimRatio_) public onlyOwner {
        snow = a;
        claimRatio = claimRatio_;
        claimingActive = true;
    }

    function togglePresale(bool b) external onlyOwner {
        presaleActive = b;
    }

    function togglePublicSale(bool b) external onlyOwner {
        presalePublic = b;
    }

    function amountBuyable(address a) public view returns (uint) {
        uint256 max;
        if (whitelisted[a]) {
            max = maxWLsale;
        } else if (presalePublic) {
            max = maxPublicSale;
        }
        return max - invested[a];
    }

    function maxSoldPerAccount(address a) public view returns (uint) {
        uint max;
        if(whitelisted[a]) {
            max=maxWLsale;
        } else {
            if (presalePublic){
                max = maxPublicSale;
            }
        }
        return max;
    }
}