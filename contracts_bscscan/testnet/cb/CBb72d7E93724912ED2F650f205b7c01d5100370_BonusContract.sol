// SPDX-License-Identifier: MIT
/*
https://dars.one/
*/
pragma solidity 0.7.6;
import "./IBEP20.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./TransferHelper.sol";

pragma experimental ABIEncoderV2;

contract BonusContract{

    using SafeMath for uint256;
    using ECDSA for bytes32;
    using TransferHelper for IBEP20;

    struct User {
        uint128 id;
        uint128 bonusNonce;
        uint256 totalBuy;
        uint256 totalBuyOutside;
        uint256 totalBuySpecial;
        uint256 affectedBuySpecial;
        uint256 totalUpgrade;
        uint256 totalBonus;  
    }

    struct Packet{
        uint256 id;
        uint256 packetType;
        uint256 qty;
        uint256 packetPrice;
        address target;
        bool upgradable;
        bool affecting;
        bool cartDependent;
    }
    mapping(bytes32=>Packet) private packets;
    mapping(address=>bool) public migrated;
    bytes32[] private allPackets;
    
    IBEP20 immutable public bonusToken;
    address immutable public darsBasis;
    uint256 immutable public chainId;
    uint256 immutable public darsPercent;
    address immutable public companyOwner;
    address immutable public darsSigner;
    address public companySigner;
    address public migrationsAdmin;
    uint256 public bonusPercent;
    address public companyContract;
    string  public darsName;
    string  public Url;  
    uint128 public lastUserId = 0;
    uint128 public lastPacketId = 0;
    bool public lowBalance = false;
    bool public salesStopped = false;
    uint256 public totalWithdrawBonus;
    uint256 public totalBuy;
    uint256 public totalBuyOutside;
    uint256 public totalBuySpecial;
    uint256 public totalUpgrade;
    uint256 public lastWithdrawalTimestamp;
    uint256 constant public maxTermWithoutCompanySignature = 15552000;//180 days

    

    mapping(address => User) public users;
    mapping(uint128 => address) private usersID;
    
    modifier onlyCompanyOwner() {
        require(companyOwner == msg.sender, "caller is not the owner");
        _;
    }

    modifier onlyDarsSigner() {
        require(darsSigner == msg.sender, "caller is not darsSigner");
        _;
    }


    event PacketAdded(uint256 id,
                uint256 packetType,
                uint256 qty,
                uint256 packetPrice,
                address targetContract,
                bytes32 singlePacketUID,
                bool upgradeable,
                bool affecting,
                bool cartDependent);

    event PacketUpdated(uint256 id,
                uint256 qty,
                uint256 packetPrice,
                address targetContract,
                bytes32 singlePacketUID,
                bool upgradeable,
                bool affecting,
                bool cartDependent);

    event Migrations(address user, 
                    uint256 totalBuy,
                    uint256 totalBuyOutside,
                    uint256 totalBuySpecial,
                    uint256 affectedBuySpecial,
                    uint256 totalUpgrade);

    event Withdraw(address user, uint256 amount,uint128 nextnonce);
    event Registration(address user, uint128 userId);
    event Buy(address user,uint256 price,bytes32 orderUID);
    event BuyOutside(address user,uint256 price,uint256 marketing);
    event BuySpecial(address user,uint256 price,bytes32 singlePacketUID);
    event UpgradeSpecial(address user,uint256 price,bytes32 singlePacketUID);

    constructor(address _companyOwner,
                address _companySigner,
                address _darsSigner,
                address _companyContract,
                address _bonusToken,
                uint256 _darsPercent,
                uint256 _bonusPercent,
                string memory _darsName, 
                string memory _Url) {

        darsBasis = msg.sender;//parent, Dars platform base contract
        companyOwner = _companyOwner;
        darsSigner = _darsSigner;
        companySigner = _companySigner;
        companyContract = _companyContract;
        darsName = _darsName;
        Url = _Url;
        bonusPercent = _bonusPercent;
        darsPercent = _darsPercent;
        bonusToken=IBEP20(_bonusToken);
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        chainId=_chainId;
        lastWithdrawalTimestamp=block.timestamp;
    }

    function antiSabotage(bool _lowBalance) external onlyDarsSigner {
       lowBalance=_lowBalance; 
    }

    function withdrawBonus(uint256 amount, bytes calldata signatureDars,bytes calldata signatureCompany) external {
        uint128 id=users[msg.sender].id;
        require(id>0,"The user doesn't exist!");
        require(amount>0,"bonus must be greater than 0");
        bytes32 hash=createHash(id,amount,users[msg.sender].bonusNonce);
        hash=hash.toEthSignedMessageHash();
        require(hash.recover(signatureDars)==darsSigner,"dars signature is wrong");
        bool isSolvent=bonusToken.balanceOf(address(this))>=amount;
        
        if((block.timestamp-lastWithdrawalTimestamp)<maxTermWithoutCompanySignature){
            require(hash.recover(signatureCompany)==companySigner,"company signature is wrong");
            lastWithdrawalTimestamp=block.timestamp;
        }else{
            salesStopped=true;
        }
        
        if(isSolvent){
            users[msg.sender].bonusNonce++;
            users[msg.sender].totalBonus=users[msg.sender].totalBonus.add(amount);
            totalWithdrawBonus=totalWithdrawBonus.add(amount);
            lowBalance=false;                     
            bonusToken.safeTransfer(address(msg.sender), amount);
            emit Withdraw(msg.sender,amount,users[msg.sender].bonusNonce);
        }else{
            require(lowBalance==false,"low contract balance..Please contact to support of company.");
            lowBalance=true;
        }

    }


    function dbMigrations(address _user,
                        uint256 _totalBuy,
                        uint256 _totalBuyOutside,
                        uint256 _totalBuySpecial,
                        uint256 _affectedBuySpecial,
                        uint256 _totalUpgrade) external {
        
        require(migrationsAdmin==msg.sender,"this caller is not a migration admin");
        require(migrated[_user]==false,"this user already migrated");                    
        if(users[_user].id==0){
            _registration(_user);
        }
        migrated[_user]=true;
        User storage user = users[_user];
        user.totalBuy=user.totalBuy.add(_totalBuy);
        user.totalBuyOutside=user.totalBuyOutside.add(_totalBuyOutside);
        user.totalBuySpecial=user.totalBuySpecial.add(_totalBuySpecial);
        user.affectedBuySpecial=user.affectedBuySpecial.add(_affectedBuySpecial);
        user.totalUpgrade=user.totalUpgrade.add(_totalUpgrade);
        
        emit Migrations(_user, 
                    user.totalBuy,
                    user.totalBuyOutside,
                    user.totalBuySpecial,
                    user.affectedBuySpecial,
                    user.totalUpgrade);

    }

    function _registration(address newUser) internal {

        User memory user = User({
            id: ++lastUserId,
            bonusNonce: uint128(0),
            totalBuy: 0,
            totalBuyOutside:0,
            totalBuySpecial: 0,
            affectedBuySpecial:0,
            totalUpgrade:0,
            totalBonus: 0
        });
        users[newUser] = user;
        usersID[lastUserId]=newUser;
        emit Registration(newUser, lastUserId);

    } 

    function _buy(address payer,uint256 price) internal {
        
        require(price > 0, "price must be greater than 0");
        require(!lowBalance, "operations suspended, low balance for bonuses");
        require(!salesStopped, "this company under liquidation, the sale is stopped");
        require(
            bonusToken.allowance(payer, address(this)) >=
                price,
            "Increase the allowance first,call the approve method"
        );
        
        bonusToken.safeTransferFrom(
            payer,
            address(this),
            price
        );
        uint256 toDarsAmount=price.mul(darsPercent).div(100);
        uint256 toBonusAmount=price.mul(bonusPercent).div(100);
        uint256 toCompanyAmount=price.sub(toDarsAmount.add(toBonusAmount));
        
        if(toDarsAmount>0){
            bonusToken.safeTransfer(darsBasis, toDarsAmount);
        }

        if(toCompanyAmount>0){
            bonusToken.safeTransfer(companyContract, toCompanyAmount);
        }

    }

    //marketing 0-DEFAULT
    function buyOutside(address user,uint256 price,uint256 marketing) external {
        require(users[user].id>0,"user not exist");
        _buy(msg.sender,price);
        totalBuyOutside=totalBuyOutside.add(price);       
        users[user].totalBuyOutside=users[user].totalBuyOutside.add(price);
        emit BuyOutside(user,price,marketing);
    }

    function buy(uint256 price,bytes32 orderUID) external {
        _buy(msg.sender,price);
        if(users[msg.sender].id==0){
            _registration(msg.sender);
        }
        totalBuy=totalBuy.add(price);       
        users[msg.sender].totalBuy=users[msg.sender].totalBuy.add(price);
        emit Buy(msg.sender,price,orderUID);
    }

    function buySpecial(uint256 price,bytes32 singlePacketUID) external {

        require(price > 0 && packets[singlePacketUID].packetPrice==price,"bad packet price or packet not avaible");
        _buy(msg.sender,price); 
        if(users[msg.sender].id==0){
            _registration(msg.sender);
        }
        totalBuySpecial=totalBuySpecial.add(price);
        users[msg.sender].totalBuySpecial=users[msg.sender].totalBuySpecial.add(price);

        if(packets[singlePacketUID].affecting){
            users[msg.sender].affectedBuySpecial=users[msg.sender].affectedBuySpecial.add(price);
        }

        if(packets[singlePacketUID].target!=address(0)){
            (bool success,) = packets[singlePacketUID].target
            .call(abi.encodeWithSignature("delivery(address,uint256,uint256,uint256,uint256)",
            msg.sender,packets[singlePacketUID].packetType,packets[singlePacketUID].qty,packets[singlePacketUID].id,price));
            require(success,"delivery call FAIL");
        }
        
        emit BuySpecial(msg.sender,price,singlePacketUID);
    }

    function upgradeSpecial(uint256 maxPrice,bytes32 singlePacketUID) external {
        require(users[msg.sender].id>0,"user not exist");

        (bool success,uint256 price) = getUpgradePriceIfAvailable(msg.sender,singlePacketUID);
        require(success,"This upgrade is not available");
        require(price <= maxPrice,"bad upgrade price, maybe the packet price was changed");
        _buy(msg.sender,price);
        totalUpgrade=totalUpgrade.add(price);
        users[msg.sender].totalUpgrade=users[msg.sender].totalUpgrade.add(price);
        
        if(packets[singlePacketUID].affecting){
            users[msg.sender].affectedBuySpecial=users[msg.sender].affectedBuySpecial.add(price);
        }      

        if(packets[singlePacketUID].target!=address(0)){
            (success,) = packets[singlePacketUID].target
            .call(abi.encodeWithSignature("upgradeDelivery(address,uint256,uint256,uint256,uint256)",
            msg.sender,packets[singlePacketUID].packetType,packets[singlePacketUID].qty,packets[singlePacketUID].id,price));
            require(success,"upgradeDelivery call FAIL");
        }
        
        emit UpgradeSpecial(msg.sender,price,singlePacketUID);

    }

    function getUpgradePriceIfAvailable(address user,bytes32 singlePacketUID) public view returns (bool,uint256) {

        if(users[user].id > 0 && packets[singlePacketUID].packetPrice>0 && packets[singlePacketUID].upgradable){
            uint256 affected=users[user].affectedBuySpecial;
            if(packets[singlePacketUID].cartDependent){
                affected = affected.add(users[user].totalBuy).add(users[user].totalBuyOutside);
            }
            if(packets[singlePacketUID].packetPrice>affected){
                return (true,packets[singlePacketUID].packetPrice.sub(affected)); 
            }
        }
        return (false,0);
    }

    function getPacketsList() public view returns (bytes32[] memory) {
        return allPackets;
    }

    function uidToId(bytes32 singlePacketUID) external view returns (uint256){
        return packets[singlePacketUID].id;
    }

    function getPacketByUID(bytes32 singlePacketUID) external view returns (Packet memory){
        
        return packets[singlePacketUID];
    }

    function getPacketByID(uint256 packetId) external view returns (Packet memory){
        require(packetId > 0 && packetId <= lastPacketId, "wrong Id");
        bytes32 id = allPackets[packetId-1];
        return packets[id];
    }

    function isPacketActive(bytes32 singlePacketUID) external view returns(bool){
        return (packets[singlePacketUID].target != address(0));
    } 

    function createHash(uint128 to, uint256 amount, uint128 nonce) internal view returns (bytes32)
    {
        return keccak256(abi.encodePacked(chainId, this, to, amount, nonce));
    }
    
    function isUserExists(address user) external view returns (bool) {
        return (users[user].id > 0);
    }

    function getUserNonce(address user) external view returns (uint128) {
        return users[user].bonusNonce;
    }

    function addressToId(address user) external view returns (uint128) {
        require(users[user].id>0,"The user doesn't exist!");
        return users[user].id;
    }

    function idToAddress(uint128 id) external view returns (address) {
        require(id>0 && id<=lastUserId,"The user doesn't exist!");
        return usersID[id];
    }
    /*
        TYPE_PACKAGE = 1;
        TYPE_ACTIVITY = 2;
        TYPE_ONE_TIME_FEE = 3;
    */
    function addPacket(uint256 _qty,
                    uint256 _packetType,
                    uint256 _packetPrice, 
                    address _target,
                    bytes32 singlePacketUID,
                    bool _upgradable,
                    bool _affecting,
                    bool _cartDependent) external onlyCompanyOwner {
        
        if(_target!=address(0)){
            uint32 size;
            assembly {
                size := extcodesize(_target)
            }
            require(size != 0, "The target must be a contract or zero address");
        }
        

        if(packets[singlePacketUID].id>0){
            require(packets[singlePacketUID].packetType==_packetType,"type change not available");
            packets[singlePacketUID].qty=_qty;
            packets[singlePacketUID].packetPrice=_packetPrice;
            packets[singlePacketUID].target=_target;
            packets[singlePacketUID].upgradable=_upgradable;
            packets[singlePacketUID].affecting=_affecting;
            packets[singlePacketUID].cartDependent=_cartDependent;
            emit PacketUpdated(packets[singlePacketUID].id,_qty,_packetPrice, _target, singlePacketUID,_upgradable,_affecting,_cartDependent);
        }else{
            packets[singlePacketUID]=Packet(
            {id:++lastPacketId,
            packetType:_packetType,
            qty:_qty,
            packetPrice:_packetPrice,
            target:_target,
            upgradable:_upgradable,
            affecting:_affecting,
            cartDependent:_cartDependent
            });
            allPackets.push(singlePacketUID);
            emit PacketAdded(lastPacketId,_packetType,_qty,_packetPrice, _target, singlePacketUID,_upgradable,_affecting,_cartDependent);
        }
        
    }

    function setMigrationsAdmin(address _migrationsAdmin) external onlyCompanyOwner {
        migrationsAdmin = _migrationsAdmin;
    }

    function setBonusPercent(uint256 newPercent) external onlyCompanyOwner {
        require(newPercent>0 && newPercent <= uint256(100).sub(darsPercent),"bad percent");
        bonusPercent = newPercent;
    }
    
    function setCompanyUrl(string calldata _Url) external onlyCompanyOwner {
        Url = _Url;
    }
    function setCompanyContract(address _companyContract) external onlyCompanyOwner {
        companyContract = _companyContract;
    }

    function setCompanySigner(address _companySigner) external onlyCompanyOwner {
        companySigner = _companySigner;
    }
}