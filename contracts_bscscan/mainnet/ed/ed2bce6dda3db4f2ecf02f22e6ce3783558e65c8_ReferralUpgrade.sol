/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

// SPDX-License-Identifier: GPL-v3.0

pragma solidity >=0.4.0;

contract Context {

    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.6.2;

interface IReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

pragma solidity >=0.6.2;

contract ReferralUpgrade is Ownable {
    
    IReferral public referral;
    
     //all top leader
    mapping(address=>bool) public mapTopLeader;
    //all leader
    mapping(address=>bool) public mapLeader;
    
    mapping(address=>uint256) public sales;
    
    mapping(address=>uint256) public topSales1;
    
    mapping(address=>uint256) public topSales2;
    
    mapping(address=>uint256) public topSales3;
    
    uint256 public targetSale1 = 10000;
    
    uint256 public targetSale2 = 100000;
    
    uint256 public targetSale3 = 100000;
    
    mapping(address => bool) public smartChef;
    
    modifier onlyMasterChef() {
        require(smartChef[msg.sender] == true, "Only MasterChef can call this function");
        _;
    }
    
    function addSmartChef(address _smartChef) external onlyOwner {
        smartChef[_smartChef] = true;
    }
    
    constructor(IReferral _referral) public {
        referral = _referral;
    }
    
    function setReferralAddress(IReferral _referral) external onlyOwner {
        referral = _referral;
    }
    
    function setTargetSale1(uint256 _targetSale1) external onlyOwner {
        targetSale1 = _targetSale1;
    }
    
    function setTargetSale2(uint256 _targetSale2) external onlyOwner {
        targetSale2 = _targetSale2;
    }
    
    function setTargetSale3(uint256 _targetSale3) external onlyOwner {
        targetSale3 = _targetSale3;
    }
    
    function getReferralAddress()  public view returns (IReferral) {
        return referral;
    }
    
    function getTopLeader(address _user) public view returns (bool) {
        return mapTopLeader[_user];
    }
    
    function getLeader(address _user) public view returns (bool) {
        return mapLeader[_user];
    }
    
    //assign top leader
    function assignTopLeader(address _topLeader) public onlyOwner{
        mapTopLeader[_topLeader] = true;
    }
    
    //remove top leader
    function removeTopLeader(address _topLeader) public onlyOwner{
        delete mapTopLeader[_topLeader];
    }
    
    //assign leader
    function assignLeader(address _leader) public onlyOwner{
        mapLeader[_leader] = true;
    }
    
    //remove leader
    function removeLeader(address _leader) public onlyOwner{
        delete mapLeader[_leader];
    }
    
    //update sales
    function updateSales(address _user,uint256 _amount) public onlyMasterChef{
        address _refer = referral.getReferrer(_user);
        while(_refer != address(0)){
            sales[_refer] = sales[_refer] + _amount;
            if(sales[_refer]>=targetSale3){
                topSales3[_refer] = sales[_refer];
            }else if(sales[_refer]>=targetSale2){
                topSales2[_refer] = sales[_refer];
            }else if(sales[_refer]>=targetSale1){
                topSales1[_refer] = sales[_refer];
            }
        }
    }
    
    //find top leader if exist
    function getTopLeaderByUser(address _user) public view returns (address) {
        address _refer = referral.getReferrer(_user);
        while(_refer != address(0)){
            if(mapTopLeader[_refer]){
                return _refer;
            }else{
                _refer = referral.getReferrer(_refer);
            }
        }
        return address(0);
    }
    
    //find leader if exist
    function getLeaderByUser(address _user) public view returns (address) {
        address _refer = referral.getReferrer(_user);
        while(_refer != address(0)){
            if(mapLeader[_refer]){
                return _refer;
            }else{
                _refer = referral.getReferrer(_refer);
            }
        }
        return address(0);
    }
    
    
    function isNetwork(address sender,address user) public view returns (bool){
        address _refer = referral.getReferrer(user);
        while(_refer != address(0)){
            if(sender == _refer){
                return true;
            }else{
                _refer = referral.getReferrer(_refer);
            }
        }
        return false;
    }
    
    
}